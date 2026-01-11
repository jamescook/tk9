# frozen_string_literal: true

#
# Tk::Bridge::Button - Button widget using Tk::Bridge
#
# Drop-in replacement pattern for TkButton, but using Bridge instead of INTERP.
#
# Usage (same as TkButton):
#   require 'tk/bridge'
#   require 'tk/bridge/button'
#
#   bridge = Tk::Bridge.new
#
#   Tk::Bridge::Button.new(bridge, text: "Click me") {
#     command { puts "clicked!" }
#     pack pady: 10
#   }
#
#   bridge.mainloop
#

module Tk
  class Bridge
    class Button
      @@counter = 0

      attr_reader :bridge, :path

      # Block form with instance_exec (like TkKernel)
      def self.new(*args, **kwargs, &block)
        obj = allocate
        obj.send(:initialize, *args, **kwargs)
        obj.instance_exec(&block) if block
        obj
      end

      def initialize(bridge, parent: ".", **options)
        @bridge = bridge
        @path = generate_path(parent)
        @callback_ids = []

        create_widget(options)
      end

      # Set command callback (DSL method for block form)
      def command(cmd = nil, &block)
        callback = cmd || block
        raise ArgumentError, "no callback given" unless callback

        id = @bridge.register_callback(&callback)
        @callback_ids << id
        configure_raw("-command", @bridge.tcl_callback_command(id))
        self
      end

      # Configure options (hash form)
      def configure(options = {})
        options.each do |key, value|
          if key == :command
            command(value)
          else
            configure_raw("-#{key}", value.to_s)
          end
        end
        self
      end

      # Get an option value
      def cget(option)
        @bridge.invoke(@path, "cget", "-#{option}")
      end

      # Programmatically invoke the button (like clicking it)
      def invoke
        @bridge.invoke(@path, "invoke")
        @bridge.dispatch_pending_callbacks
      end

      # Geometry managers (DSL methods for block form)
      def pack(options = {})
        args = hash_to_args(options)
        @bridge.invoke("pack", @path, *args)
        self
      end

      def grid(options = {})
        args = hash_to_args(options)
        @bridge.invoke("grid", @path, *args)
        self
      end

      def place(options = {})
        args = hash_to_args(options)
        @bridge.invoke("place", @path, *args)
        self
      end

      # Destroy the widget
      def destroy
        @callback_ids.each { |id| @bridge.unregister_callback(id) }
        @bridge.eval("destroy #{@path}")
      end

      # Property accessors
      def text
        cget(:text)
      end

      def text=(value)
        configure(text: value)
      end

      def state
        cget(:state)
      end

      def state=(value)
        configure(state: value)
      end

      def disable
        self.state = "disabled"
      end

      def enable
        self.state = "normal"
      end

      private

      def generate_path(parent)
        @@counter += 1
        if parent == "."
          ".btn#{@@counter}"
        else
          "#{parent}.btn#{@@counter}"
        end
      end

      def create_widget(options)
        args = ["button", @path]

        options.each do |key, value|
          next if key == :command  # handled separately after creation
          args << "-#{key}" << value.to_s
        end

        @bridge.invoke(*args)

        # Handle command option after widget exists
        if options[:command]
          command(options[:command])
        end
      end

      def configure_raw(option, value)
        @bridge.invoke(@path, "configure", option, value)
      end

      def hash_to_args(options)
        args = []
        options.each do |key, value|
          args << "-#{key}" << value.to_s
        end
        args
      end
    end
  end
end
