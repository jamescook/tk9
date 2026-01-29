# frozen_string_literal: true
#
# tk/warnings.rb - Centralized warning management for ruby-tk
#
# Usage:
#   Tk::Warnings.warn_once(:pickplace, "xview_pickplace is deprecated...")
#
# User control:
#   Tk::Warnings.disable(:pickplace)   # silence specific warning
#   Tk::Warnings.disable_all           # silence all ruby-tk warnings
#   Tk::Warnings.enable(:pickplace)    # re-enable specific warning
#   Tk::Warnings.enable_all            # re-enable all warnings
#   Tk::Warnings.suppress(:key) { }    # temporarily suppress in block
#

module Tk
  module Warnings
    @disabled = {}
    @fired = {}

    class << self
      # Issue a warning that only fires once per key.
      # @param key [Symbol] unique identifier for this warning
      # @param message [String] warning message (will be prefixed with [ruby-tk])
      def warn_once(key, message)
        return if @disabled[:all] || @disabled[key] || @fired[key]
        @fired[key] = true
        warn "[ruby-tk] #{message}"
      end

      # Issue a warning every time (no dedup).
      # Respects disabled state.
      # @param key [Symbol] category for this warning (for filtering)
      # @param message [String] warning message
      def warn_always(key, message)
        return if @disabled[:all] || @disabled[key]
        warn "[ruby-tk] #{message}"
      end

      # Disable specific warning(s) by key.
      # @param keys [Symbol...] warning keys to disable
      def disable(*keys)
        keys.each { |k| @disabled[k] = true }
      end

      # Disable all ruby-tk warnings.
      def disable_all
        @disabled[:all] = true
      end

      # Re-enable specific warning(s) by key.
      # @param keys [Symbol...] warning keys to enable
      def enable(*keys)
        keys.each { |k| @disabled.delete(k) }
      end

      # Temporarily disable warning(s) for the duration of a block.
      # @param keys [Symbol...] warning keys to suppress
      # @yield block to execute with warnings suppressed
      def suppress(*keys)
        previously_disabled = keys.select { |k| @disabled[k] }
        disable(*keys)
        yield
      ensure
        keys.each { |k| @disabled.delete(k) unless previously_disabled.include?(k) }
      end

      # Re-enable all ruby-tk warnings.
      def enable_all
        @disabled.clear
      end

      # Check if a warning key is disabled.
      # @param key [Symbol] warning key
      # @return [Boolean]
      def disabled?(key)
        @disabled[:all] || @disabled[key]
      end

      # Reset all state (for testing).
      def reset!
        @disabled.clear
        @fired.clear
      end
    end
  end
end
