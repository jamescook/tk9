# frozen_string_literal: true
#
# TkDemo - Helper module for automated sample testing and recording
#
# Two independent modes:
#   - Test mode (TK_READY_FD): Quick verification that sample loads/runs
#   - Record mode (TK_RECORD): Video capture with longer delays
#
# Usage:
#   require 'tk/demo_support'
#
#   if TkDemo.active?
#     TkDemo.on_visible {
#       button.invoke
#       Tk.after(TkDemo.delay(test: 200, record: 500)) {
#         button.invoke
#         TkDemo.finish
#       }
#     }
#   end
#
module TkDemo
  # When recording, use Ttk for modern themed look and hide cursor
  if ENV['TK_RECORD']
    require 'tkextlib/tile'
    Tk.default_widget_set = :Ttk
    Tk.root.configure(:cursor => 'none')
  end

  class << self
    # Check if running in test mode (quick smoke test)
    def testing?
      !!ENV['TK_READY_FD']
    end

    # Check if running in record mode (video capture)
    def recording?
      !!ENV['TK_RECORD']
    end

    # Check if either automated mode is active
    def active?
      testing? || recording?
    end

    # Get appropriate delay for current mode
    # @param test [Integer] delay in ms for test mode (default: 100)
    # @param record [Integer] delay in ms for record mode (default: 1000)
    # @return [Integer] delay in milliseconds
    def delay(test: 100, record: 1000)
      recording? ? record : test
    end

    # Capture a thumbnail screenshot using tkimg
    # @param window [TkWindow] window to capture (default: Tk.root)
    # @param path [String] output path (default: TK_THUMBNAIL_PATH env var)
    def capture_thumbnail(window: Tk.root, path: ENV['TK_THUMBNAIL_PATH'])
      return unless path

      begin
        require 'tkextlib/tkimg/window'
        require 'tkextlib/tkimg/png'

        # Ensure all widgets are fully drawn
        Tk.update

        img = TkPhotoImage.new(:format => 'window', :data => window.path)
        img.write(path, :format => 'png')
        $stderr.puts "TkDemo: thumbnail saved to #{path}"
      rescue => e
        $stderr.puts "TkDemo: thumbnail capture failed: #{e.message}"
      end
    end

    # Run block once when window becomes visible
    # Handles the Visibility binding, "run once" guard, and safety timeout
    # @param timeout [Integer] safety timeout in seconds (default: 60)
    def on_visible(timeout: 60, &block)
      return unless active?
      raise ArgumentError, "block required" unless block

      @demo_started = false
      Tk.root.bind('Visibility') {
        next if @demo_started
        @demo_started = true

        # Capture thumbnail when recording
        capture_thumbnail if recording?

        # Safety timeout to prevent stuck demos
        Tk.after(timeout * 1000) {
          $stderr.puts "TkDemo: timeout after #{timeout}s, forcing exit"
          finish
        }

        Tk.after(50) { block.call }
      }
    end

    # Signal completion and exit cleanly
    # Handles both TK_READY_FD (test) and TK_STOP_PIPE (record)
    def finish
      $stdout.flush

      # Signal test harness
      if (fd = ENV.delete('TK_READY_FD'))
        begin
          IO.for_fd(fd.to_i).tap { |io| io.write("1"); io.close }
        rescue StandardError
          # Ignore errors (fd may be invalid)
        end
      end

      # Signal recording harness
      if (pipe = ENV['TK_STOP_PIPE'])
        begin
          File.write(pipe, "1")
        rescue StandardError
          # Ignore errors (pipe may not exist)
        end
      end

      # Exit cleanly outside of event processing
      Tk.after_idle { Tk.root.destroy }
    end
  end
end
