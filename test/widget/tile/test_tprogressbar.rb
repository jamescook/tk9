# frozen_string_literal: true

# Comprehensive test for Tk::Tile::TProgressbar widget options.
# Runs in a single subprocess to minimize overhead.
#
# See: https://www.tcl-lang.org/man/tcl/TkCmd/ttk_progressbar.html

require_relative '../../test_helper'
require_relative '../../tk_test_helper'

class TestTProgressbarWidget < Minitest::Test
  include TkTestHelper

  def test_tprogressbar_comprehensive
    assert_tk_app("TProgressbar widget comprehensive test", method(:tprogressbar_app))
  end

  def tprogressbar_app
    require 'tk'
    require 'tkextlib/tile'

    errors = []

    frame = Tk::Tile::TFrame.new(root, padding: 20)
    frame.pack(fill: "both", expand: true)

    # --- Determinate horizontal progressbar ---
    Tk::Tile::TLabel.new(frame, text: "Determinate (0-100):").pack(anchor: "w")
    progress = Tk::Tile::TProgressbar.new(frame,
      orient: "horizontal",
      length: 300,
      mode: "determinate",
      maximum: 100,
      value: 0
    )
    progress.pack(fill: "x", pady: 5)

    errors << "orient failed" unless progress.cget(:orient) == "horizontal"
    errors << "length failed" unless progress.cget(:length).to_i == 300
    errors << "mode failed" unless progress.cget(:mode) == "determinate"
    errors << "maximum failed" unless progress.cget(:maximum).to_f == 100.0
    errors << "initial value failed" unless progress.cget(:value).to_f == 0.0

    # --- Set value ---
    progress.configure(value: 50)
    errors << "configure value failed" unless progress.cget(:value).to_f == 50.0

    # --- Step method ---
    progress.step(10)
    errors << "step failed" unless progress.cget(:value).to_f == 60.0

    # --- Variable binding ---
    var = TkVariable.new(25)
    bound_progress = Tk::Tile::TProgressbar.new(frame,
      orient: "horizontal",
      length: 300,
      mode: "determinate",
      variable: var
    )
    bound_progress.pack(fill: "x", pady: 5)

    errors << "variable initial failed" unless bound_progress.cget(:value).to_f == 25.0

    var.value = 75
    errors << "variable update failed" unless bound_progress.cget(:value).to_f == 75.0

    # --- Indeterminate mode ---
    Tk::Tile::TLabel.new(frame, text: "Indeterminate:").pack(anchor: "w")
    indeterminate = Tk::Tile::TProgressbar.new(frame,
      orient: "horizontal",
      length: 300,
      mode: "indeterminate"
    )
    indeterminate.pack(fill: "x", pady: 5)

    errors << "indeterminate mode failed" unless indeterminate.cget(:mode) == "indeterminate"

    # Start/stop animation (just verify methods exist)
    indeterminate.start(50)  # 50ms interval
    indeterminate.stop

    # --- Vertical progressbar ---
    Tk::Tile::TLabel.new(frame, text: "Vertical:").pack(anchor: "w")
    vertical = Tk::Tile::TProgressbar.new(frame,
      orient: "vertical",
      length: 100,
      mode: "determinate",
      value: 30
    )
    vertical.pack(pady: 5)

    errors << "vertical orient failed" unless vertical.cget(:orient) == "vertical"
    errors << "vertical value failed" unless vertical.cget(:value).to_f == 30.0

    # --- Style (ttk-specific) ---
    original_style = progress.cget(:style)
    errors << "style cget failed" if original_style.nil?

    raise "TProgressbar test failures:\n  " + errors.join("\n  ") unless errors.empty?
  end
end
