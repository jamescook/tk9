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

  # Test that numeric options return proper types (not strings)
  def test_tprogressbar_numeric_types
    assert_tk_app("TProgressbar numeric types", method(:tprogressbar_numeric_types_app))
  end

  def tprogressbar_numeric_types_app
    require 'tk'
    require 'tkextlib/tile'

    errors = []

    progress = Tk::Tile::TProgressbar.new(root,
      maximum: 100,
      value: 42
    )
    progress.pack

    # maximum should be Float, not String
    max = progress.cget(:maximum)
    errors << "maximum should be Float, got #{max.class}" unless max.is_a?(Float)

    # value should be Float, not String
    val = progress.cget(:value)
    errors << "value should be Float, got #{val.class}" unless val.is_a?(Float)

    # Arithmetic should work without manual conversion
    begin
      result = max - val
      errors << "arithmetic failed: expected 58.0, got #{result}" unless result == 58.0
    rescue NoMethodError => e
      errors << "arithmetic failed with NoMethodError: #{e.message}"
    end

    # phase should be Integer
    phase = progress.cget(:phase)
    errors << "phase should be Integer, got #{phase.class}" unless phase.is_a?(Integer)

    raise errors.join("\n") unless errors.empty?
  end
end
