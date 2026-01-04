# frozen_string_literal: true

# Comprehensive test for Tk::Frame widget options.
# Runs in a single subprocess to minimize overhead.
#
# See: https://www.tcl-lang.org/man/tcl/TkCmd/frame.html

require_relative '../test_helper'
require_relative '../tk_test_helper'

class TestFrameWidget < Minitest::Test
  include TkTestHelper

  def test_frame_comprehensive
    assert_tk_app("Frame widget comprehensive test", method(:frame_app))
  end

  def frame_app
    require 'tk'
    require 'tk/frame'

    root = TkRoot.new { withdraw }
    errors = []

    # --- Basic creation ---
    frame_default = TkFrame.new(root)
    errors << "frame not created" unless frame_default.path

    # --- Size options (width/height in pixels) ---
    frame_sized = TkFrame.new(root, width: 200, height: 100)
    errors << "width mismatch" unless frame_sized.cget(:width).to_i == 200
    errors << "height mismatch" unless frame_sized.cget(:height).to_i == 100

    # --- Relief options ---
    %w[flat raised sunken groove ridge solid].each do |relief|
      frame = TkFrame.new(root, relief: relief, borderwidth: 2)
      errors << "relief #{relief} not set" unless frame.cget(:relief) == relief
    end

    # --- Borderwidth ---
    frame_border = TkFrame.new(root, borderwidth: 5, relief: "raised")
    errors << "borderwidth not set" unless frame_border.cget(:borderwidth).to_i == 5

    # --- Padding ---
    frame_padded = TkFrame.new(root, padx: 10, pady: 20)
    errors << "padx not set" if frame_padded.cget(:padx).to_i == 0
    errors << "pady not set" if frame_padded.cget(:pady).to_i == 0

    # --- Dynamic configure ---
    frame_dynamic = TkFrame.new(root)
    frame_dynamic.configure(width: 150, height: 75, relief: "groove")
    errors << "dynamic width failed" unless frame_dynamic.cget(:width).to_i == 150
    errors << "dynamic height failed" unless frame_dynamic.cget(:height).to_i == 75
    errors << "dynamic relief failed" unless frame_dynamic.cget(:relief) == "groove"

    # --- Nested frames ---
    outer = TkFrame.new(root, borderwidth: 2, relief: "raised")
    inner = TkFrame.new(outer, borderwidth: 1, relief: "sunken")
    errors << "nested frame parent wrong" unless inner.path.start_with?(outer.path)

    # Check errors before tk_end (which may block in visual mode)
    unless errors.empty?
      root.destroy
      raise "Frame test failures:\n  " + errors.join("\n  ")
    end

    tk_end(root)
  end
end
