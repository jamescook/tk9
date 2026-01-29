# frozen_string_literal: true

# Test for Tk::BWidget::Entry widget options.
#
# See: https://core.tcl-lang.org/bwidget/doc/bwidget/BWman/Entry.html

require_relative '../../../../test/test_helper'
require_relative '../../../../test/tk_test_helper'

class TestBWidgetEntry < Minitest::Test
  include TkTestHelper

  def test_entry_comprehensive
    assert_tk_app("BWidget Entry test", method(:entry_app))
  end

  def entry_app
    require 'tk'
    require 'tkextlib/bwidget'

    errors = []

    # --- Basic entry ---
    entry = Tk::BWidget::Entry.new(root, width: 30)
    entry.pack

    errors << "width failed" unless entry.cget(:width).to_i == 30

    # --- helptext (BWidget-specific string option) ---
    entry.configure(helptext: "Enter your name")
    errors << "helptext failed" unless entry.cget(:helptext) == "Enter your name"

    # --- editable (BWidget-specific boolean option) ---
    entry.configure(editable: true)
    errors << "editable true failed" unless entry.cget(:editable) == true

    entry.configure(editable: false)
    errors << "editable false failed" unless entry.cget(:editable) == false

    entry.configure(editable: true)

    # --- dragenabled/dropenabled (BWidget-specific boolean options) ---
    entry.configure(dragenabled: true)
    errors << "dragenabled failed" unless entry.cget(:dragenabled) == true

    entry.configure(dropenabled: true)
    errors << "dropenabled failed" unless entry.cget(:dropenabled) == true

    # --- insertbackground (BWidget-specific string option) ---
    entry.configure(insertbackground: "red")
    errors << "insertbackground failed" if entry.cget(:insertbackground).to_s.empty?

    # --- state ---
    entry.configure(state: "disabled")
    errors << "state disabled failed" unless entry.cget(:state) == "disabled"

    entry.configure(state: "normal")
    errors << "state normal failed" unless entry.cget(:state) == "normal"

    # --- text content ---
    entry.delete(0, 'end')
    entry.insert(0, "Hello World")
    errors << "insert/get failed" unless entry.get == "Hello World"

    # --- helpvar (TkVariable) ---
    helpvar = TkVariable.new("entry help variable")
    entry.configure(helpvar: helpvar)
    hv = entry.cget(:helpvar)
    errors << "helpvar cget failed" if hv.nil?

    raise "BWidget Entry test failures:\n  " + errors.join("\n  ") unless errors.empty?
  end
end
