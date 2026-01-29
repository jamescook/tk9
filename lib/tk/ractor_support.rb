# frozen_string_literal: true

# Ractor and background work support for Tk applications.
#
# This module provides a unified API across Ruby versions:
# - Ruby 3.x: Uses Ractor.yield/take, bridge threads for messaging
# - Ruby 4.x: Uses Ractor::Port, Ractor.shareable_proc
# - Thread fallback: Always available, works everywhere
#
# The implementation is selected automatically based on Ruby version.

require_relative 'background_thread'

# Feature detection
RUBY_4_OR_LATER = RUBY_VERSION.split('.').first.to_i >= 4
RACTOR_PORT_API = defined?(Ractor::Port)
RACTOR_SHAREABLE_PROC = Ractor.respond_to?(:shareable_proc)

if RACTOR_SHAREABLE_PROC
  require_relative 'background_ractor4x'
else
  require_relative 'background_ractor3x'
end

module TkRactorSupport
  # Default poll interval: 16ms ≈ 60fps
  DEFAULT_POLL_MS = 16

  # Re-export feature flags
  RACTOR_PORT_API = ::RACTOR_PORT_API
  RACTOR_SHAREABLE_PROC = ::RACTOR_SHAREABLE_PROC

  # Available modes
  MODES = [:thread, :ractor].freeze

  # Select the appropriate Ractor implementation
  RactorImpl = if RACTOR_SHAREABLE_PROC
    TkBackgroundRactor4x
  else
    TkBackgroundRactor3x
  end

  # Unified BackgroundWork API
  #
  # Creates background work with the specified mode.
  # Mode :ractor uses true parallel execution (Ruby version appropriate impl).
  # Mode :thread uses traditional threading (GVL limited but always works).
  #
  # Example:
  #   task = TkRactorSupport::BackgroundWork.new(data, mode: :ractor) do |t, d|
  #     d.each do |item|
  #       t.check_pause
  #       t.yield(process(item))
  #     end
  #   end.on_progress { |r| update_ui(r) }
  #     .on_done { puts "Done!" }
  #
  #   task.pause   # Send pause message
  #   task.resume  # Send resume message
  #   task.stop    # Send stop message
  #
  class BackgroundWork
    def initialize(data, mode: :ractor, &block)
      impl_class = case mode
      when :ractor
        RactorImpl::BackgroundWork
      when :thread
        TkBackgroundThread::BackgroundWork
      else
        raise ArgumentError, "Unknown mode: #{mode}. Use :ractor or :thread"
      end

      @impl = impl_class.new(data, &block)
    end

    def on_progress(&block)
      @impl.on_progress(&block)
      self
    end

    def on_done(&block)
      @impl.on_done(&block)
      self
    end

    def on_message(&block)
      @impl.on_message(&block)
      self
    end

    def send_message(msg)
      @impl.send_message(msg)
      self
    end

    def pause
      @impl.pause
      self
    end

    def resume
      @impl.resume
      self
    end

    def stop
      @impl.stop
      self
    end

    def start
      @impl.start
      self
    end
  end

  # Simple streaming API (no pause support, simpler interface)
  #
  # Example:
  #   TkRactorSupport::RactorStream.new(files) do |yielder, data|
  #     data.each { |f| yielder.yield(process(f)) }
  #   end.on_progress { |r| update_ui(r) }
  #     .on_done { puts "Done!" }
  #
  class RactorStream
    def initialize(data, &block)
      # For Ruby 4.x, we need to make the block shareable before wrapping
      # because captured procs become nil when the wrapper is made shareable
      if RACTOR_SHAREABLE_PROC
        shareable_block = Ractor.shareable_proc(&block)
        wrapped_block = Ractor.shareable_proc do |task, d|
          yielder = StreamYielder.new(task)
          shareable_block.call(yielder, d)
        end
      else
        wrapped_block = proc do |task, d|
          yielder = StreamYielder.new(task)
          block.call(yielder, d)
        end
      end

      @impl = RactorImpl::BackgroundWork.new(data, &wrapped_block)
    end

    def on_progress(&block)
      @impl.on_progress(&block)
      self
    end

    def on_done(&block)
      @impl.on_done(&block)
      self
    end

    def cancel
      @impl.stop
    end

    # Adapter for old yielder API
    class StreamYielder
      def initialize(task)
        @task = task
      end

      def yield(value)
        @task.yield(value)
      end
    end
  end
end
