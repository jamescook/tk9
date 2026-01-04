# frozen_string_literal: true

# Comprehensive test for Tk::Entry widget options.
# Runs in a single subprocess to minimize overhead.
#
# See: https://www.tcl-lang.org/man/tcl/TkCmd/entry.html

require_relative '../test_helper'
require_relative '../tk_test_helper'

class TestEntryWidget < Minitest::Test
  include TkTestHelper

  def test_entry_comprehensive
    assert_tk_app("Entry widget comprehensive test", method(:entry_app))
  end

  def entry_app
    require 'tk'
    require 'tk/entry'
    require 'tk/frame'
    require 'tk/label'

    root = TkRoot.new { withdraw }
    errors = []

    # Create a form-like layout
    main_frame = TkFrame.new(root, padx: 10, pady: 10)
    main_frame.pack(fill: "both", expand: true)

    # --- Row 1: Basic text entry ---
    row1 = TkFrame.new(main_frame)
    row1.pack(fill: "x", pady: 5)
    TkLabel.new(row1, text: "Name:", width: 15, anchor: "e").pack(side: "left")
    entry_name = TkEntry.new(row1, width: 30)
    entry_name.pack(side: "left", padx: 5)
    entry_name.value = "John Doe"
    errors << "basic value failed" unless entry_name.value == "John Doe"

    # --- Row 2: Password entry with masking ---
    row2 = TkFrame.new(main_frame)
    row2.pack(fill: "x", pady: 5)
    TkLabel.new(row2, text: "Password:", width: 15, anchor: "e").pack(side: "left")
    entry_password = TkEntry.new(row2, width: 30, show: "*")
    entry_password.pack(side: "left", padx: 5)
    entry_password.value = "secret123"
    errors << "show option failed" unless entry_password.cget(:show) == "*"

    # --- Row 3: Centered text with custom relief ---
    row3 = TkFrame.new(main_frame)
    row3.pack(fill: "x", pady: 5)
    TkLabel.new(row3, text: "Title:", width: 15, anchor: "e").pack(side: "left")
    entry_title = TkEntry.new(row3, width: 30, justify: "center", relief: "groove")
    entry_title.pack(side: "left", padx: 5)
    entry_title.value = "Centered Title"
    errors << "justify failed" unless entry_title.cget(:justify) == "center"
    errors << "relief failed" unless entry_title.cget(:relief) == "groove"

    # --- Row 4: Disabled entry ---
    row4 = TkFrame.new(main_frame)
    row4.pack(fill: "x", pady: 5)
    TkLabel.new(row4, text: "Read Only:", width: 15, anchor: "e").pack(side: "left")
    entry_readonly = TkEntry.new(row4, width: 30, state: "readonly")
    entry_readonly.pack(side: "left", padx: 5)
    errors << "readonly state failed" unless entry_readonly.cget(:state) == "readonly"

    # --- Row 5: Entry with custom cursor appearance ---
    row5 = TkFrame.new(main_frame)
    row5.pack(fill: "x", pady: 5)
    TkLabel.new(row5, text: "Custom Cursor:", width: 15, anchor: "e").pack(side: "left")
    entry_cursor = TkEntry.new(row5,
      width: 30,
      insertwidth: 4,
      insertofftime: 250,
      insertontime: 500,
      insertbackground: "red"
    )
    entry_cursor.pack(side: "left", padx: 5)
    errors << "insertwidth failed" unless entry_cursor.cget(:insertwidth).to_i == 4
    errors << "insertofftime failed" unless entry_cursor.cget(:insertofftime) == 250
    errors << "insertontime failed" unless entry_cursor.cget(:insertontime) == 500

    # --- Row 6: Entry with selection colors ---
    row6 = TkFrame.new(main_frame)
    row6.pack(fill: "x", pady: 5)
    TkLabel.new(row6, text: "Select Colors:", width: 15, anchor: "e").pack(side: "left")
    entry_select = TkEntry.new(row6,
      width: 30,
      selectbackground: "navy",
      selectforeground: "white"
    )
    entry_select.pack(side: "left", padx: 5)
    entry_select.value = "Select this text"
    entry_select.selection_range(0, 6)
    errors << "selection_present failed" unless entry_select.selection_present
    errors << "selectbackground failed" if entry_select.cget(:selectbackground).to_s.empty?

    # --- Verify all validation modes work ---
    %w[none focus focusin focusout key all].each do |mode|
      entry = TkEntry.new(main_frame, validate: mode)
      errors << "validate #{mode} failed" unless entry.cget(:validate) == mode
    end

    # --- Verify all relief types ---
    %w[flat raised sunken groove ridge solid].each do |relief|
      entry = TkEntry.new(main_frame, relief: relief)
      errors << "relief #{relief} failed" unless entry.cget(:relief) == relief
    end

    # --- Verify state types ---
    %w[normal disabled readonly].each do |state|
      entry = TkEntry.new(main_frame, state: state)
      errors << "state #{state} failed" unless entry.cget(:state) == state
    end

    # --- Test entry methods ---
    entry_methods = TkEntry.new(main_frame)
    entry_methods.insert(0, "hello")
    entry_methods.insert(5, " world")
    errors << "insert failed" unless entry_methods.value == "hello world"
    entry_methods.delete(0, 6)
    errors << "delete failed" unless entry_methods.value == "world"

    # --- Test exportselection ---
    entry_export = TkEntry.new(main_frame, exportselection: false)
    errors << "exportselection failed" if entry_export.cget(:exportselection)

    # --- Test dynamic configure ---
    entry_dynamic = TkEntry.new(main_frame, width: 20)
    entry_dynamic.configure(width: 40, relief: "sunken")
    errors << "dynamic configure width failed" unless entry_dynamic.cget(:width) == 40
    errors << "dynamic configure relief failed" unless entry_dynamic.cget(:relief) == "sunken"

    # Check errors before tk_end (which may block in visual mode)
    unless errors.empty?
      root.destroy
      raise "Entry test failures:\n  " + errors.join("\n  ")
    end

    tk_end(root)
  end
end
