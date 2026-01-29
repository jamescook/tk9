# frozen_string_literal: true

# Ruby 4.x Ractor-based background work for Tk applications.
# Uses Ractor::Port for streaming and Ractor.shareable_proc for blocks.
# Uses thread-inside-ractor pattern for non-blocking message handling.

module TkBackgroundRactor4x
  # Default poll interval: 16ms ≈ 60fps
  DEFAULT_POLL_MS = 16

  class BackgroundWork
    def initialize(data, &block)
      @data = data
      @work_block = block
      @callbacks = { progress: nil, done: nil, message: nil }
      @started = false
      @done = false

      # Communication
      @output_queue = Thread::Queue.new
      @control_port = nil  # Set by worker, received back
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
      @control_port&.send(msg)
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

      # Create shareable proc - Ruby 4.x guarantees this works
      shareable_block = Ractor.shareable_proc(&@work_block)

      start_ractor(shareable_block)
      start_polling
      self
    end

    private

    def maybe_start
      start unless @started
    end

    def start_ractor(shareable_block)
      data = @data
      output_port = Ractor::Port.new

      @worker_ractor = Ractor.new(data, output_port, shareable_block) do |d, out, blk|
        # Worker creates its own control port for receiving messages
        control_port = Ractor::Port.new
        msg_queue = Thread::Queue.new

        # Send control port back to main thread
        out.send([:control_port, control_port])

        # Background thread receives from control port, forwards to queue
        Thread.new do
          loop do
            begin
              msg = control_port.receive
              msg_queue << msg
              break if msg == :stop
            rescue Ractor::ClosedError
              break
            end
          end
        end

        Thread.current[:tk_in_background_work] = true
        task = TaskContext.new(out, msg_queue)
        begin
          blk.call(task, d)
          out.send([:done])
        rescue StopIteration
          out.send([:done])
        rescue => e
          out.send([:error, "#{e.class}: #{e.message}\n#{e.backtrace.first(3).join("\n")}"])
          out.send([:done])
        end
      end

      # Bridge thread: Port.receive -> Queue
      @bridge_thread = Thread.new do
        loop do
          begin
            result = output_port.receive
            if result.is_a?(Array) && result[0] == :control_port
              @control_port = result[1]
            else
              @output_queue << result
              break if result[0] == :done
            end
          rescue Ractor::ClosedError
            @output_queue << [:done]
            break
          end
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
      def initialize(output_port, msg_queue)
        @output_port = output_port
        @msg_queue = msg_queue
        @paused = false
      end

      def yield(value)
        check_pause_loop
        @output_port.send([:result, value])
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
        @output_port.send([:message, msg])
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
  end
end
