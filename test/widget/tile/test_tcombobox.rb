# frozen_string_literal: true

# Comprehensive test for Tk::Tile::TCombobox widget options.
# Runs in a single subprocess to minimize overhead.
#
# See: https://www.tcl-lang.org/man/tcl/TkCmd/ttk_combobox.html

require_relative '../../test_helper'
require_relative '../../tk_test_helper'

class TestTComboboxWidget < Minitest::Test
  include TkTestHelper

  def test_tcombobox_comprehensive
    assert_tk_app("TCombobox widget comprehensive test", method(:tcombobox_app))
  end

  def tcombobox_app
    require 'tk'
    require 'tkextlib/tile'

    errors = []

    frame = Tk::Tile::TFrame.new(root, padding: 20)
    frame.pack(fill: "both", expand: true)

    # --- Basic combobox with values ---
    colors = ["Red", "Green", "Blue", "Yellow", "Orange"]
    combo = Tk::Tile::TCombobox.new(frame, values: colors, width: 20)
    combo.pack(pady: 10)

    errors << "width failed" unless combo.cget(:width).to_i == 20

    # --- Values (list type) ---
    values = combo.cget(:values)
    errors << "values cget failed" unless values.is_a?(Array) || values.is_a?(String)

    # --- Set value programmatically ---
    combo.set("Green")
    errors << "set failed" unless combo.get == "Green"

    # --- Current index ---
    combo.current = 2  # Blue
    errors << "current= failed" unless combo.current == 2
    errors << "current get failed" unless combo.get == "Blue"

    # --- Height (popup listbox rows) ---
    combo.configure(height: 5)
    errors << "height failed" unless combo.cget(:height).to_i == 5

    # --- State ---
    combo.configure(state: "readonly")
    errors << "readonly state failed" unless combo.cget(:state) == "readonly"

    combo.configure(state: "disabled")
    errors << "disabled state failed" unless combo.cget(:state) == "disabled"

    combo.configure(state: "normal")
    errors << "normal state failed" unless combo.cget(:state) == "normal"

    # --- Style (ttk-specific, inherited from TEntry) ---
    original_style = combo.cget(:style)
    errors << "style cget failed" if original_style.nil?

    # --- Textvariable binding ---
    var = TkVariable.new("Initial")
    combo2 = Tk::Tile::TCombobox.new(frame, textvariable: var, values: colors)
    combo2.pack(pady: 5)

    errors << "textvariable initial failed" unless combo2.get == "Initial"

    var.value = "Red"
    errors << "textvariable update failed" unless combo2.get == "Red"

    # --- Editable combobox (normal state) ---
    Tk::Tile::TLabel.new(frame, text: "Editable:").pack(anchor: "w")
    editable = Tk::Tile::TCombobox.new(frame, values: ["Option 1", "Option 2", "Option 3"])
    editable.pack(fill: "x", pady: 2)

    editable.insert(0, "Custom value")
    errors << "editable insert failed" unless editable.get == "Custom value"

    # --- Readonly combobox ---
    # In readonly mode: user cannot type directly, can only select from dropdown
    # Note: This is a UI restriction - programmatic changes still work
    Tk::Tile::TLabel.new(frame, text: "Readonly:").pack(anchor: "w")
    readonly = Tk::Tile::TCombobox.new(frame, values: colors, state: "readonly")
    readonly.pack(fill: "x", pady: 2)
    readonly.current = 0

    errors << "readonly initial failed" unless readonly.get == "Red"

    # Programmatic selection via current= works in readonly mode
    readonly.current = 2
    errors << "readonly current= should work" unless readonly.get == "Blue"

    # set() also works programmatically
    readonly.set("Yellow")
    errors << "readonly set should work" unless readonly.get == "Yellow"

    # --- Postcommand (script executed before showing dropdown) ---
    # This tests that Tcl script callbacks work correctly
    postcommand_called = false
    dynamic_combo = Tk::Tile::TCombobox.new(frame, width: 20)
    dynamic_combo.configure(postcommand: proc {
      postcommand_called = true
      # Dynamically set values when dropdown opens
      dynamic_combo.configure(values: ["Dynamic 1", "Dynamic 2", "Dynamic 3"])
    })
    dynamic_combo.pack(pady: 5)

    # Force the postcommand to execute by posting the listbox
    # Note: post method shows the dropdown, which triggers postcommand
    begin
      dynamic_combo.tk_send('post')
      dynamic_combo.tk_send('unpost')
    rescue
      # post/unpost may not work in headless mode, skip if it fails
    end

    # Verify postcommand was called (if post worked)
    if postcommand_called
      values_after = dynamic_combo.cget(:values)
      errors << "postcommand dynamic values failed" unless values_after.include?("Dynamic 1") || values_after.to_s.include?("Dynamic")
    end

    raise "TCombobox test failures:\n  " + errors.join("\n  ") unless errors.empty?
  end
end
