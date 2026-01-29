# frozen_string_literal: true
#
# Transparency Demo - shows Tk's built-in window transparency features
#
# -alpha: Overall window transparency (works on all platforms)
# -transparentcolor: Make a specific color see-through (Windows only)
#
# Run with: ruby -Ilib sample/transparency_demo.rb

require 'tk'

root = TkRoot.new(title: 'Transparency Demo')
root.geometry('380x180')

# Current alpha value
alpha_var = TkVariable.new(1.0)

# Frame for controls
controls = TkFrame.new(root).pack(fill: 'x', padx: 10, pady: 10)

TkLabel.new(controls, text: 'Alpha:').pack(side: 'left')

# Alpha slider (0.2 to 1.0 - don't go fully invisible!)
TkScale.new(controls,
  from: 0.2,
  to: 1.0,
  resolution: 0.05,
  orient: 'horizontal',
  variable: alpha_var,
  length: 150,
  command: proc { |val| root.wm_attributes(:alpha, val.to_f) }
).pack(side: 'left', padx: 5)

TkButton.new(controls,
  text: 'Reset',
  command: proc {
    alpha_var.value = 1.0
    root.wm_attributes(:alpha, 1.0)
  }
).pack(side: 'left', padx: 5)

# Info
platform = Tk::TCL_PLATFORM['platform']
TkLabel.new(root,
  text: "Platform: #{platform}\n\n-alpha: Drag slider to fade entire window\n-transparentcolor: Windows only",
  justify: 'left'
).pack(padx: 10, pady: 10)

Tk.mainloop
