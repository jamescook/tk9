# frozen_string_literal: true

# Comprehensive test for Tk::Spinbox widget options.
# Runs in a single subprocess to minimize overhead.
#
# See: https://www.tcl-lang.org/man/tcl/TkCmd/spinbox.html

require_relative '../test_helper'
require_relative '../tk_test_helper'

class TestSpinboxWidget < Minitest::Test
  include TkTestHelper

  def test_spinbox_comprehensive
    assert_tk_app("Spinbox widget comprehensive test", method(:spinbox_app))
  end

  def spinbox_app
    require 'tk'
    require 'tk/spinbox'
    require 'tk/frame'
    require 'tk/label'

    root = TkRoot.new { withdraw }
    errors = []

    frame = TkFrame.new(root, padx: 20, pady: 20)
    frame.pack(fill: "both", expand: true)

    # --- Numeric spinbox with range ---
    TkLabel.new(frame, text: "Quantity (1-100):").pack(anchor: "w")
    num_spin = TkSpinbox.new(frame,
      from: 1,
      to: 100,
      increment: 1,
      width: 10,
      repeatinterval: 10
    )
    num_spin.pack(fill: "x", pady: 5)

    errors << "from failed" unless num_spin.cget(:from) == 1.0
    errors << "to failed" unless num_spin.cget(:to) == 100.0
    errors << "increment failed" unless num_spin.cget(:increment) == 1.0

    # --- Values-based spinbox ---
    TkLabel.new(frame, text: "Day of Week:").pack(anchor: "w")
    days = %w[Monday Tuesday Wednesday Thursday Friday Saturday Sunday]
    day_spin = TkSpinbox.new(frame, values: days, width: 15)
    day_spin.pack(fill: "x", pady: 5)

    # Check values returns a list
    val_list = day_spin.cget(:values)
    errors << "values failed" unless val_list.is_a?(Array) && val_list.size == 7

    # --- Wrap option ---
    num_spin.configure(wrap: true)
    errors << "wrap true failed" unless num_spin.cget(:wrap)

    num_spin.configure(wrap: false)
    errors << "wrap false failed" if num_spin.cget(:wrap)

    # --- Format ---
    TkLabel.new(frame, text: "Price:").pack(anchor: "w")
    price_spin = TkSpinbox.new(frame,
      from: 0.0,
      to: 999.99,
      increment: 0.01,
      format: "%6.2f",
      width: 10
    )
    price_spin.pack(fill: "x", pady: 5)

    errors << "format failed" unless price_spin.cget(:format) == "%6.2f"

    # --- Button appearance ---
    num_spin.configure(buttondownrelief: "sunken")
    errors << "buttondownrelief failed" unless num_spin.cget(:buttondownrelief) == "sunken"

    num_spin.configure(buttonuprelief: "raised")
    errors << "buttonuprelief failed" unless num_spin.cget(:buttonuprelief) == "raised"

    # --- Set value and read ---
    num_spin.set("50")
    errors << "set/get failed" unless num_spin.get == "50"

    # --- Spinup/spindown methods ---
    num_spin.set("50")
    num_spin.spinup
    errors << "spinup failed" unless num_spin.get.to_i > 50

    num_spin.spindown
    num_spin.spindown
    errors << "spindown failed" unless num_spin.get.to_i < 50

    # --- State (inherited from Entry) ---
    num_spin.configure(state: "disabled")
    errors << "disabled state failed" unless num_spin.cget(:state) == "disabled"

    num_spin.configure(state: "normal")
    errors << "normal state failed" unless num_spin.cget(:state) == "normal"

    # Check errors before tk_end
    unless errors.empty?
      root.destroy
      raise "Spinbox test failures:\n  " + errors.join("\n  ")
    end

    tk_end(root)
  end
end
