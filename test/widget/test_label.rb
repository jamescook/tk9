# frozen_string_literal: true

# Comprehensive test for Tk::Label widget options.
# Runs in a single subprocess to minimize overhead.
#
# See: https://www.tcl-lang.org/man/tcl/TkCmd/label.html

require_relative '../test_helper'
require_relative '../tk_test_helper'

class TestLabelWidget < Minitest::Test
  include TkTestHelper

  def test_label_comprehensive
    assert_tk_app("Label widget comprehensive test", method(:label_app))
  end

  def label_app
    require 'tk'
    require 'tk/label'

    root = TkRoot.new { withdraw }
    errors = []

    # --- Basic creation and text ---
    lbl_default = TkLabel.new(root, text: "Default Label")
    errors << "text not set" unless lbl_default.cget(:text) == "Default Label"

    # --- Size options (width/height) ---
    lbl_sized = TkLabel.new(root, text: "Sized", width: 20, height: 2)
    errors << "width mismatch: got #{lbl_sized.cget(:width)}" unless lbl_sized.cget(:width) == 20
    errors << "height mismatch: got #{lbl_sized.cget(:height)}" unless lbl_sized.cget(:height) == 2

    # --- State option ---
    lbl_normal = TkLabel.new(root, text: "Normal", state: "normal")
    lbl_disabled = TkLabel.new(root, text: "Disabled", state: "disabled")
    errors << "normal state wrong" unless lbl_normal.cget(:state) == "normal"
    errors << "disabled state wrong" unless lbl_disabled.cget(:state) == "disabled"

    # --- Dynamic configure ---
    lbl_dynamic = TkLabel.new(root, text: "Original")
    lbl_dynamic.configure(text: "Updated", width: 15)
    errors << "dynamic text failed" unless lbl_dynamic.cget(:text) == "Updated"
    errors << "dynamic width failed" unless lbl_dynamic.cget(:width) == 15

    # --- Relief options (Label supports all relief types) ---
    %w[flat raised sunken groove ridge solid].each do |relief|
      lbl = TkLabel.new(root, text: relief, relief: relief)
      errors << "relief #{relief} not set" unless lbl.cget(:relief) == relief
    end

    # --- Anchor options ---
    %w[n ne e se s sw w nw center].each do |anchor|
      lbl = TkLabel.new(root, text: anchor, anchor: anchor, width: 8, height: 2)
      errors << "anchor #{anchor} not set" unless lbl.cget(:anchor) == anchor
    end

    # --- Justify options ---
    %w[left center right].each do |justify|
      lbl = TkLabel.new(root, text: "Multi\nLine", justify: justify)
      errors << "justify #{justify} not set" unless lbl.cget(:justify) == justify
    end

    # --- Padding ---
    lbl_padded = TkLabel.new(root, text: "Padded", padx: 20, pady: 10)
    errors << "padx not set" if lbl_padded.cget(:padx).to_i == 0
    errors << "pady not set" if lbl_padded.cget(:pady).to_i == 0

    # --- Underline ---
    lbl_underline = TkLabel.new(root, text: "Underline", underline: 0)
    errors << "underline wrong" unless lbl_underline.cget(:underline) == 0

    # --- Wraplength ---
    lbl_wrap = TkLabel.new(root, text: "This is a long text that should wrap", wraplength: 100)
    errors << "wraplength not set" if lbl_wrap.cget(:wraplength).to_i == 0

    # --- Compound (text + image positioning) ---
    %w[none bottom top left right center].each do |compound|
      lbl = TkLabel.new(root, text: "Text", compound: compound)
      errors << "compound #{compound} not set" unless lbl.cget(:compound) == compound
    end

    # Check errors before tk_end (which may block in visual mode)
    unless errors.empty?
      root.destroy
      raise "Label test failures:\n  " + errors.join("\n  ")
    end

    tk_end(root)
  end
end
