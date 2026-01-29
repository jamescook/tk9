# frozen_string_literal: true

# Thread-based background work for Tk applications.
# Always available, works on all Ruby versions.
# Uses GVL so not true parallelism, but keeps UI responsive.

module TkBackgroundThread
  # Default poll interval: 16ms ≈ 60fps
  DEFAULT_POLL_MS = 16

  # High-level API for background work with messaging support.
  #
  # Example:
  #   task = TkBackgroundThread::BackgroundWork.new(data) do |t|
  #     data.each do |item|
  #       break if t.check_message == :stop
  #       t.yield(process(item))
  #     end
  #   end.on_progress { |r| update_ui(r) }
  #     .on_done { puts "Done!" }
  #
  #   task.send_message(:pause)
  #   task.send_message(:resume)
  #   task.stop
  #
  class BackgroundWork
    def initialize(data, &block)
      @data = data
      @work_block = block
      @callbacks = { progress: nil, done: nil, message: nil }
      @started = false
      @done = false

      # Communication channels
      @output_queue = Thread::Queue.new    # Worker -> Main
      @message_queue = Thread::Queue.new   # Main -> Worker
      @worker_thread = nil
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

    # Called when worker sends a non-result message back
    def on_message(&block)
      @callbacks[:message] = block
      self
    end

    # Send a message to the worker (pause, resume, stop, or custom)
    def send_message(msg)
      @message_queue << msg
      self
    end

    # Convenience methods
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

      @worker_thread = Thread.new do
        Thread.current[:tk_in_background_work] = true
        task = TaskContext.new(@output_queue, @message_queue)
        begin
          @work_block.call(task, @data)
        rescue StopIteration
          # Clean exit via stop
        end
        @output_queue << [:done]
      end

      start_polling
      self
    end

    private

    def maybe_start
      start unless @started
    end

    def start_polling
      poll = proc do
        next if @done

        # Drain output queue
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
            end
          end
        rescue ThreadError
          # Queue empty
        end

        Tk.after(DEFAULT_POLL_MS, &poll) unless @done
      end

      Tk.after(0, &poll)
    end

    # Context passed to the work block
    class TaskContext
      def initialize(output_queue, message_queue)
        @output_queue = output_queue
        @message_queue = message_queue
        @paused = false
      end

      # Yield a result to the main thread
      def yield(value)
        @output_queue << [:result, value]
      end

      # Non-blocking check for messages from main thread.
      # Returns the message or nil if none.
      def check_message
        msg = @message_queue.pop(true)
        handle_control_message(msg)
        msg
      rescue ThreadError
        nil
      end

      # Blocking wait for next message
      def wait_message
        msg = @message_queue.pop
        handle_control_message(msg)
        msg
      end

      # Send a message back to main thread (not a result)
      def send_message(msg)
        @output_queue << [:message, msg]
      end

      # Check pause state, blocking if paused
      def check_pause
        # First drain any pending messages (non-blocking)
        loop do
          msg = @message_queue.pop(true)
          handle_control_message(msg)
        rescue ThreadError
          break  # Queue empty
        end

        # Then block while paused
        while @paused
          msg = @message_queue.pop  # Blocking wait
          handle_control_message(msg)
        end
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
    end
  end
end
