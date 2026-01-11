#!/usr/bin/env ruby
# frozen_string_literal: true

# Manual e2e test for tkdnd drag-and-drop functionality.
# Run with: bundle exec ruby lib/tkextlib/tkDND/examples/drop_target.rb
#
# Test by dragging text or files from other apps onto the window.
# Uses the modern tkdnd API (not the compat layer) for reliability.

require 'tk'
require 'tkextlib/tkDND'

# Trigger autoload
Tk::TkDND::DND

root = TkRoot.new(title: "TkDND Drop Target Test")
root.geometry("400x300")

# Status label at top
status = TkLabel.new(root, text: "Drag text or files here", font: "Helvetica 14")
status.pack(side: 'top', fill: 'x', pady: 10)

# Drop zone - use ttk::button like the working demo
drop_zone = Tk::Tile::TButton.new(root, text: "Drop Zone\n(accepts text and files)")
drop_zone.pack(expand: true, fill: 'both', padx: 20, pady: 20)

# Result display
result_frame = TkFrame.new(root)
result_frame.pack(side: 'bottom', fill: 'x', padx: 10, pady: 10)

TkLabel.new(result_frame, text: "Last drop:", anchor: 'w').pack(side: 'left')
result_var = TkVariable.new("")
result_label = TkLabel.new(result_frame, textvariable: result_var, anchor: 'w', wraplength: 350)
result_label.pack(side: 'left', fill: 'x', expand: true)

puts "Platform: #{Tk.windowingsystem}"

# Register drop target using modern API (accepts all types)
path = drop_zone.path
Tk.ip_eval("tkdnd::drop_target register #{path} *")

# Visual feedback - use <<virtual event>> syntax
Tk.ip_eval("bind #{path} <<DropEnter>> {#{path} state active}")
Tk.ip_eval("bind #{path} <<DropLeave>> {#{path} state !active}")

# Handle drops using raw Tcl bindings with %D substitution
# This matches the working official demo pattern exactly

# Position handler - must return action to accept drop
Tk.ip_eval(<<~TCL)
  bind #{path} <<DropPosition>> {
    return copy
  }
TCL

# Generic drop handler
Tk.ip_eval(<<~TCL)
  bind #{path} <<Drop>> {
    puts "Generic drop: \\"%D\\""
    #{path} state !active
    return %A
  }
TCL

# Text-specific drop handler
Tk.ip_eval(<<~TCL)
  bind #{path} <<Drop:DND_Text>> {
    puts "Text drop: \\"%D\\""
    #{path} state !active
    return %A
  }
TCL

# File-specific drop handler
Tk.ip_eval(<<~TCL)
  bind #{path} <<Drop:DND_Files>> {
    puts "File drop: \\"%D\\""
    #{path} state !active
    return %A
  }
TCL

puts "\nWindow ready. Drag text or files onto the drop zone."
puts "Press Ctrl+C or close window to exit.\n\n"

Tk.mainloop
