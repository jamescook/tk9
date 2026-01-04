# frozen_string_literal: true

# Comprehensive test for Tk::Button widget options.
# Runs in a single subprocess to minimize overhead.
#
# See: https://www.tcl-lang.org/man/tcl/TkCmd/button.html

require_relative '../test_helper'
require_relative '../tk_test_helper'

class TestButtonWidget < Minitest::Test
  include TkTestHelper

  def test_button_comprehensive
    assert_tk_app("Button widget comprehensive test", method(:button_app))
  end

  def button_app
    require 'tk'
    require 'tk/button'

    root = TkRoot.new { withdraw }
    errors = []

    # --- Basic creation and text ---
    btn_default = TkButton.new(root, text: "Default Button")
    errors << "text not set" unless btn_default.cget(:text) == "Default Button"

    # --- Size options (width/height) ---
    btn_sized = TkButton.new(root, text: "Sized", width: 20, height: 2)
    errors << "width mismatch: got #{btn_sized.cget(:width)}" unless btn_sized.cget(:width) == 20
    errors << "height mismatch: got #{btn_sized.cget(:height)}" unless btn_sized.cget(:height) == 2

    # --- State option ---
    btn_normal = TkButton.new(root, text: "Normal", state: "normal")
    btn_disabled = TkButton.new(root, text: "Disabled", state: "disabled")
    errors << "normal state wrong" unless btn_normal.cget(:state) == "normal"
    errors << "disabled state wrong" unless btn_disabled.cget(:state) == "disabled"

    # --- Dynamic configure ---
    btn_dynamic = TkButton.new(root, text: "Original")
    btn_dynamic.configure(text: "Updated", width: 15)
    errors << "dynamic text failed" unless btn_dynamic.cget(:text) == "Updated"
    errors << "dynamic width failed" unless btn_dynamic.cget(:width) == 15

    # --- Configure with hash ---
    btn_hash = TkButton.new(root)
    btn_hash.configure(text: "Hash Config", width: 10, height: 1)
    errors << "hash text failed" unless btn_hash.cget(:text) == "Hash Config"

    # --- Command callback and invoke ---
    invoke_count = 0
    btn_cmd = TkButton.new(root, text: "Click Me", command: proc { invoke_count += 1 })
    btn_cmd.invoke
    btn_cmd.invoke
    errors << "invoke count wrong: #{invoke_count}" unless invoke_count == 2

    # --- Flash (should not error) ---
    btn_flash = TkButton.new(root, text: "Flash")
    btn_flash.flash  # Just verify it doesn't raise

    # --- Relief options ---
    %w[flat raised sunken groove ridge solid].each do |relief|
      btn = TkButton.new(root, text: relief, relief: relief)
      errors << "relief #{relief} not set" unless btn.cget(:relief) == relief
    end

    # --- Anchor options ---
    %w[n ne e se s sw w nw center].each do |anchor|
      btn = TkButton.new(root, text: anchor, anchor: anchor, width: 8, height: 2)
      errors << "anchor #{anchor} not set" unless btn.cget(:anchor) == anchor
    end

    # --- Padding ---
    btn_padded = TkButton.new(root, text: "Padded", padx: 20, pady: 10)
    # padx/pady may return different types, just verify they're set
    errors << "padx not set" if btn_padded.cget(:padx).to_i == 0
    errors << "pady not set" if btn_padded.cget(:pady).to_i == 0

    # --- Default option (button-specific) ---
    btn_default_opt = TkButton.new(root, text: "Default Active", default: "active")
    errors << "default option wrong" unless btn_default_opt.cget(:default) == "active"

    # --- Underline ---
    btn_underline = TkButton.new(root, text: "Underline", underline: 0)
    errors << "underline wrong" unless btn_underline.cget(:underline) == 0

    # Check errors before tk_end (which may block in visual mode)
    unless errors.empty?
      root.destroy
      raise "Button test failures:\n  " + errors.join("\n  ")
    end

    tk_end(root)
  end
end
