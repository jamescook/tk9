# frozen_string_literal: true

# Comprehensive test for Tk::Toplevel and Tk::Root widget options.
# Runs in a single subprocess to minimize overhead.
#
# See: https://www.tcl-lang.org/man/tcl/TkCmd/toplevel.html

require_relative '../test_helper'
require_relative '../tk_test_helper'

class TestToplevelWidget < Minitest::Test
  include TkTestHelper

  def test_toplevel_comprehensive
    assert_tk_app("Toplevel widget comprehensive test", method(:toplevel_app))
  end

  def toplevel_app
    require 'tk'
    require 'tk/toplevel'
    require 'tk/label'
    require 'tk/button'

    root = TkRoot.new { withdraw }
    errors = []

    # --- Root window options ---
    root.configure(width: 400, height: 300)
    errors << "root width failed" unless root.cget(:width).to_i == 400
    errors << "root height failed" unless root.cget(:height).to_i == 300

    root.configure(padx: 10, pady: 10)
    errors << "root padx failed" unless root.cget(:padx).to_i == 10
    errors << "root pady failed" unless root.cget(:pady).to_i == 10

    # --- Create a Toplevel window ---
    top = TkToplevel.new(root) { withdraw }

    # --- Size options ---
    top.configure(width: 300, height: 200)
    errors << "toplevel width failed" unless top.cget(:width).to_i == 300
    errors << "toplevel height failed" unless top.cget(:height).to_i == 200

    # --- Border and relief ---
    top.configure(borderwidth: 2)
    errors << "borderwidth failed" unless top.cget(:borderwidth).to_i == 2

    top.configure(relief: "raised")
    errors << "relief failed" unless top.cget(:relief) == "raised"

    # --- Padding ---
    top.configure(padx: 15, pady: 15)
    errors << "padx failed" unless top.cget(:padx).to_i == 15
    errors << "pady failed" unless top.cget(:pady).to_i == 15

    # --- Container option (DSL-declared boolean) ---
    # Note: container can only be set at creation time, so we test a new toplevel
    container_top = TkToplevel.new(root, container: false) { withdraw }
    errors << "container false failed" if container_top.cget(:container)
    errors << "container not boolean" unless container_top.cget(:container).is_a?(FalseClass)
    container_top.destroy

    # --- Add content to toplevel ---
    TkLabel.new(top, text: "This is a Toplevel window").pack(pady: 20)
    TkButton.new(top, text: "Close", command: proc { top.destroy }).pack(pady: 10)

    # --- Multiple toplevels ---
    top2 = TkToplevel.new(root) { withdraw }
    top2.configure(width: 200, height: 150)
    TkLabel.new(top2, text: "Second window").pack(pady: 10)

    errors << "top2 width failed" unless top2.cget(:width).to_i == 200

    # --- Highlight thickness ---
    top.configure(highlightthickness: 2)
    errors << "highlightthickness failed" unless top.cget(:highlightthickness).to_i == 2

    # Clean up
    top2.destroy

    # Check errors before tk_end
    unless errors.empty?
      top.destroy rescue nil
      root.destroy
      raise "Toplevel test failures:\n  " + errors.join("\n  ")
    end

    top.destroy
    tk_end(root)
  end
end
