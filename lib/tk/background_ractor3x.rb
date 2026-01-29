# frozen_string_literal: true

# Ruby 3.x Ractor-based background work for Tk applications.
# Uses Ractor.yield/take for streaming (no Port API).
# Uses bridge thread pattern for non-blocking communication.
#
# Note: In Ruby 3.x, procs cannot be passed to Ractors unless they
# are written without capturing outer scope variables or self.
# If the proc can't be made shareable, falls back to thread mode.

module TkBackgroundRactor3x
  # Default poll interval: 16ms ≈ 60fps
  DEFAULT_POLL_MS = 16

  class BackgroundWork
    def initialize(data, &block)
      @data = data
      @work_block = block
      @callbacks = { progress: nil, done: nil, message: nil }
      @started = false
      @done = false
      @fell_back_to_thread = false

      # Communication
      @output_queue = Thread::Queue.new
      @control_ractor = nil
      @worker_ractor = nil
      @bridge_thread = nil
    end

    def on_progress(&block)
      @callbacks[:progress] = block
      maybe_start
      self
    end

    def on_done(&block)
      @callbacks[:done] = block
      maybe_start
      self
    end

    def on_message(&block)
      @callbacks[:message] = block
      self
    end

    def send_message(msg)
      if @fell_back_to_thread
        @message_queue << msg
      else
        @control_ractor&.send(msg)
      end
      self
    end

    def pause
      send_message(:pause)
      self
    end

    def resume
      send_message(:resume)
      self
    end

    def stop
      send_message(:stop)
      self
    end

    def start
      return self if @started
      @started = true

      # Try to make the block shareable
      shareable_block = begin
        Ractor.make_shareable(@work_block)
      rescue Ractor::IsolationError
        # Block captures non-shareable state - fall back to thread mode
        nil
      end

      if shareable_block
        start_ractor(shareable_block)
      else
        warn "TkBackgroundRactor3x: Block not shareable, falling back to thread mode"
        start_thread_fallback
      end

      start_polling
      self
    end

    private

    def maybe_start
      start unless @started
    end

    def start_ractor(shareable_block)
      data = @data

      # Control ractor forwards messages to worker
      @control_ractor = Ractor.new { loop { Ractor.yield(Ractor.receive) } }

      @worker_ractor = Ractor.new(data, @control_ractor, shareable_block) do |d, ctrl, blk|
        # Message queue bridged from control ractor via thread
        msg_queue = Thread::Queue.new

        Thread.new do
          loop do
            begin
              msg = ctrl.take
              msg_queue << msg
              break if msg == :stop
            rescue Ractor::ClosedError
              break
            end
          end
        end

        Thread.current[:tk_in_background_work] = true
        task = TaskContext.new(msg_queue)
        begin
          blk.call(task, d)
          Ractor.yield([:done])
        rescue StopIteration
          Ractor.yield([:done])
        rescue => e
          Ractor.yield([:error, "#{e.class}: #{e.message}\n#{e.backtrace.first(3).join("\n")}"])
          Ractor.yield([:done])
        end
      end

      # Bridge thread: Ractor.take -> Queue
      @bridge_thread = Thread.new do
        loop do
          begin
            result = @worker_ractor.take
            @output_queue << result
            break if result[0] == :done
          rescue Ractor::ClosedError
            @output_queue << [:done]
            break
          end
        end
      end
    end

    def start_thread_fallback
      @fell_back_to_thread = true
      @message_queue = Thread::Queue.new

      Thread.new do
        Thread.current[:tk_in_background_work] = true
        task = ThreadTaskContext.new(@output_queue, @message_queue)
        begin
          @work_block.call(task, @data)
          @output_queue << [:done]
        rescue StopIteration
          @output_queue << [:done]
        rescue => e
          @output_queue << [:error, "#{e.class}: #{e.message}\n#{e.backtrace.first(3).join("\n")}"]
          @output_queue << [:done]
        end
      end
    end

    def start_polling
      poll = proc do
        next if @done

        begin
          while (msg = @output_queue.pop(true))
            type, value = msg
            case type
            when :done
              @done = true
              @callbacks[:done]&.call
              break
            when :result
              @callbacks[:progress]&.call(value)
            when :message
              @callbacks[:message]&.call(value)
            when :error
              if Tk.abort_on_ractor_error
                raise RuntimeError, "[Ractor] Background work error: #{value}"
              else
                warn "[Ractor] Background work error: #{value}"
              end
            end
          end
        rescue ThreadError
          # Queue empty
        end

        Tk.after(DEFAULT_POLL_MS, &poll) unless @done
      end

      Tk.after(0, &poll)
    end

    # Task context for Ractor mode (runs inside Ractor)
    class TaskContext
      def initialize(msg_queue)
        @msg_queue = msg_queue
        @paused = false
      end

      def yield(value)
        check_pause_loop
        Ractor.yield([:result, value])
      end

      def check_message
        msg = @msg_queue.pop(true)
        handle_control_message(msg)
        msg
      rescue ThreadError
        nil
      end

      def wait_message
        msg = @msg_queue.pop
        handle_control_message(msg)
        msg
      end

      def send_message(msg)
        Ractor.yield([:message, msg])
      end

      def check_pause
        check_pause_loop
      end

      private

      def handle_control_message(msg)
        case msg
        when :pause
          @paused = true
        when :resume
          @paused = false
        when :stop
          raise StopIteration
        end
      end

      def check_pause_loop
        while @paused
          msg = @msg_queue.pop
          handle_control_message(msg)
        end
      end
    end

    # Thread fallback context (same as BackgroundThread)
    class ThreadTaskContext
      def initialize(output_queue, message_queue)
        @output_queue = output_queue
        @message_queue = message_queue
        @paused = false
      end

      def yield(value)
        check_pause_loop
        @output_queue << [:result, value]
      end

      def check_message
        msg = @message_queue.pop(true)
        handle_control_message(msg)
        msg
      rescue ThreadError
        nil
      end

      def wait_message
        msg = @message_queue.pop
        handle_control_message(msg)
        msg
      end

      def send_message(msg)
        @output_queue << [:message, msg]
      end

      def check_pause
        check_pause_loop
      end

      private

      def handle_control_message(msg)
        case msg
        when :pause
          @paused = true
        when :resume
          @paused = false
        when :stop
          raise StopIteration
        end
      end

      def check_pause_loop
        while @paused
          msg = @message_queue.pop
          handle_control_message(msg)
        end
      end
    end
  end
end
