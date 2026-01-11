#!/usr/bin/env ruby
# frozen_string_literal: true
#
# Binding Demo - demonstrates Tk event bindings and bindtags
#
# Features demonstrated:
#   - bindtags (viewing and manipulating binding tag order)
#   - bind with event substitution (%x, %y, %K, etc.)
#   - bind_append (adding to existing bindings)
#   - TkBindTag (custom binding tags)
#   - TkCallbackBreak (stopping event propagation)
#
# Run: ruby -I lib sample/binding_demo.rb

require 'tk'

class BindingDemo
  def initialize
    @root = TkRoot.new { title "Binding Demo" }

    # Log area to show binding events
    @log = TkText.new(@root) do
      width 60
      height 15
      font TkFont.new(family: 'Monaco', size: 11)
      pack(side: 'bottom', fill: 'both', expand: true, padx: 5, pady: 5)
    end

    setup_demo_widgets
    setup_bindtags_demo
    setup_custom_bindtag

    log("=== Binding Demo Ready ===")
    log("Try: clicking buttons, hovering, pressing keys")
    log("")
  end

  def setup_demo_widgets
    frame = TkFrame.new(@root) { pack(side: 'top', fill: 'x', padx: 5, pady: 5) }

    # Button with multiple bindings
    @button1 = TkButton.new(frame) do
      text "Click Me (event info)"
      pack(side: 'left', padx: 5)
    end

    # Bind with full event object
    @button1.bind('Button-1') do |event|
      log("Button-1: x=#{event.x}, y=#{event.y}, widget=#{event.widget}")
    end

    # Append another binding (both fire)
    @button1.bind_append('Button-1') do |event|
      log("  (appended): state=#{event.state}, time=#{event.time}")
    end

    # Enter/Leave
    @button1.bind('Enter') { log("Enter: mouse entered button") }
    @button1.bind('Leave') { log("Leave: mouse left button") }

    # Button that stops propagation
    @button2 = TkButton.new(frame) do
      text "Click (stops propagation)"
      pack(side: 'left', padx: 5)
    end

    @button2.bind('Button-1') do
      log("Button2: this binding raises TkCallbackBreak")
      raise TkCallbackBreak  # Stops further bindings from firing
    end

    # This append should NOT fire due to break above
    @button2.bind_append('Button-1') do
      log("Button2 APPEND: this should NOT appear!")
    end

    # Key binding demo (focus required)
    @entry = TkEntry.new(frame) do
      width 20
      pack(side: 'left', padx: 5)
    end
    @entry.insert(0, "Type here...")

    @entry.bind('KeyPress') do |event|
      log("KeyPress: keysym=#{event.keysym}, char='#{event.char}', keycode=#{event.keycode}")
    end
  end

  def setup_bindtags_demo
    frame = TkFrame.new(@root) { pack(side: 'top', fill: 'x', padx: 5, pady: 5) }

    TkLabel.new(frame) { text "Bindtags:"; pack(side: 'left') }

    @tags_label = TkLabel.new(frame) do
      font TkFont.new(family: 'Monaco', size: 10)
      pack(side: 'left', padx: 5)
    end

    TkButton.new(frame) do
      text "Show Tags"
      pack(side: 'left', padx: 2)
    end.command { show_bindtags }

    TkButton.new(frame) do
      text "Reverse Tags"
      pack(side: 'left', padx: 2)
    end.command { reverse_bindtags }

    TkButton.new(frame) do
      text "Reset Tags"
      pack(side: 'left', padx: 2)
    end.command { reset_bindtags }

    show_bindtags
  end

  def setup_custom_bindtag
    frame = TkFrame.new(@root) { pack(side: 'top', fill: 'x', padx: 5, pady: 5) }

    # Create a custom binding tag
    @highlight_tag = TkBindTag.new
    @highlight_tag.bind('Enter') { |e| e.widget.configure(bg: 'yellow') }
    @highlight_tag.bind('Leave') { |e| e.widget.configure(bg: 'SystemButtonFace') }

    TkLabel.new(frame) { text "Custom TkBindTag:"; pack(side: 'left') }

    # Buttons that share the custom tag
    3.times do |i|
      btn = TkButton.new(frame) { text "Hover #{i+1}"; pack(side: 'left', padx: 2) }
      # Insert custom tag at front
      btn.bindtags = [@highlight_tag] + btn.bindtags
    end
  end

  def show_bindtags
    tags = @button1.bindtags
    @tags_label.configure(text: tags.map(&:to_s).join(" -> "))
    log("bindtags: #{tags.inspect}")
  end

  def reverse_bindtags
    tags = @button1.bindtags.reverse
    @button1.bindtags = tags
    @tags_label.configure(text: tags.map(&:to_s).join(" -> "))
    log("Reversed bindtags: #{tags.inspect}")
  end

  def reset_bindtags
    # Reset to default: [widget, class, toplevel, all]
    @button1.bindtags = [@button1, TkButton, @root, TkBindTag::ALL]
    show_bindtags
    log("Reset to default bindtags")
  end

  def log(msg)
    @log.insert('end', "#{msg}\n")
    @log.see('end')
  end

  def run
    Tk.mainloop
  end
end

if __FILE__ == $0
  # Support smoke test infrastructure
  if ENV['TK_READY_FD']
    # Signal ready after UI is set up
    TkAfter.new(100, 1) {
      IO.for_fd(ENV['TK_READY_FD'].to_i, 'w').tap { |io| io.write('.'); io.close }
    }.start

    # Handle SIGTERM gracefully
    Signal.trap('TERM') { Tk.root.destroy }
  end

  BindingDemo.new.run
end
