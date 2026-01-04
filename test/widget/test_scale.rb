# frozen_string_literal: true

# Comprehensive test for Tk::Scale widget options.
# Runs in a single subprocess to minimize overhead.
#
# See: https://www.tcl-lang.org/man/tcl/TkCmd/scale.html

require_relative '../test_helper'
require_relative '../tk_test_helper'

class TestScaleWidget < Minitest::Test
  include TkTestHelper

  def test_scale_comprehensive
    assert_tk_app("Scale widget comprehensive test", method(:scale_app))
  end

  def scale_app
    require 'tk'
    require 'tk/scale'
    require 'tk/frame'
    require 'tk/label'

    root = TkRoot.new { withdraw }
    errors = []

    frame = TkFrame.new(root, padx: 20, pady: 20)
    frame.pack(fill: "both", expand: true)

    # --- Horizontal scale with range ---
    TkLabel.new(frame, text: "Volume:").pack(anchor: "w")
    h_scale = TkScale.new(frame,
      orient: "horizontal",
      from: 0,
      to: 100,
      length: 300,
      label: "Volume"
    )
    h_scale.pack(fill: "x", pady: 5)

    errors << "orient failed" unless h_scale.cget(:orient) == "horizontal"
    errors << "from failed" unless h_scale.cget(:from) == 0.0
    errors << "to failed" unless h_scale.cget(:to) == 100.0
    errors << "length failed" unless h_scale.cget(:length).to_i == 300
    errors << "label failed" unless h_scale.cget(:label) == "Volume"

    # --- Vertical scale ---
    v_scale = TkScale.new(frame,
      orient: "vertical",
      from: 0,
      to: 50,
      length: 150
    )
    v_scale.pack(side: "right", fill: "y", padx: 10)
    errors << "vertical orient failed" unless v_scale.cget(:orient) == "vertical"

    # --- Set and get value ---
    h_scale.set(50)
    errors << "set/get failed" unless h_scale.get == 50.0

    h_scale.value = 75
    errors << "value= failed" unless h_scale.value == 75.0

    # --- Resolution ---
    h_scale.configure(resolution: 5)
    errors << "resolution failed" unless h_scale.cget(:resolution) == 5.0

    # --- Tick interval ---
    h_scale.configure(tickinterval: 20)
    errors << "tickinterval failed" unless h_scale.cget(:tickinterval) == 20.0

    # --- Show value ---
    h_scale.configure(showvalue: false)
    errors << "showvalue false failed" if h_scale.cget(:showvalue)
    h_scale.configure(showvalue: true)
    errors << "showvalue true failed" unless h_scale.cget(:showvalue)

    # --- Slider appearance ---
    h_scale.configure(sliderlength: 30, sliderrelief: "raised")
    errors << "sliderlength failed" unless h_scale.cget(:sliderlength).to_i == 30
    errors << "sliderrelief failed" unless h_scale.cget(:sliderrelief) == "raised"

    # --- Width ---
    h_scale.configure(width: 20)
    errors << "width failed" unless h_scale.cget(:width).to_i == 20

    # --- Big increment ---
    h_scale.configure(bigincrement: 10)
    errors << "bigincrement failed" unless h_scale.cget(:bigincrement) == 10.0

    # --- Digits ---
    h_scale.configure(digits: 3)
    errors << "digits failed" unless h_scale.cget(:digits) == 3

    # --- State ---
    h_scale.configure(state: "disabled")
    errors << "disabled state failed" unless h_scale.cget(:state) == "disabled"
    h_scale.configure(state: "normal")
    errors << "normal state failed" unless h_scale.cget(:state) == "normal"

    # --- Colors ---
    h_scale.configure(troughcolor: "gray80", activebackground: "gray70")
    errors << "troughcolor failed" if h_scale.cget(:troughcolor).to_s.empty?

    # --- Relief and border ---
    h_scale.configure(relief: "sunken", borderwidth: 2)
    errors << "relief failed" unless h_scale.cget(:relief) == "sunken"
    errors << "borderwidth failed" unless h_scale.cget(:borderwidth).to_i == 2

    # --- Repeat timing ---
    h_scale.configure(repeatdelay: 400, repeatinterval: 100)
    errors << "repeatdelay failed" unless h_scale.cget(:repeatdelay) == 400
    errors << "repeatinterval failed" unless h_scale.cget(:repeatinterval) == 100

    # Check errors before tk_end
    unless errors.empty?
      root.destroy
      raise "Scale test failures:\n  " + errors.join("\n  ")
    end

    tk_end(root)
  end
end
