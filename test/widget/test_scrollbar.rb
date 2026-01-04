# frozen_string_literal: true

# Comprehensive test for Tk::Scrollbar widget options.
# Runs in a single subprocess to minimize overhead.
#
# See: https://www.tcl-lang.org/man/tcl/TkCmd/scrollbar.html

require_relative '../test_helper'
require_relative '../tk_test_helper'

class TestScrollbarWidget < Minitest::Test
  include TkTestHelper

  def test_scrollbar_comprehensive
    assert_tk_app("Scrollbar widget comprehensive test", method(:scrollbar_app))
  end

  def scrollbar_app
    require 'tk'
    require 'tk/scrollbar'
    require 'tk/frame'
    require 'tk/listbox'

    root = TkRoot.new { withdraw }
    errors = []

    frame = TkFrame.new(root, padx: 10, pady: 10)
    frame.pack(fill: "both", expand: true)

    # --- Create a listbox with scrollbar ---
    listbox = TkListbox.new(frame, width: 30, height: 10)
    scrollbar = TkScrollbar.new(frame)

    # Pack them side by side
    listbox.pack(side: "left", fill: "both", expand: true)
    scrollbar.pack(side: "right", fill: "y")

    # Connect them
    listbox.yscrollcommand(proc { |*args| scrollbar.set(*args) })
    scrollbar.command(proc { |*args| listbox.yview(*args) })

    # Add items to make scrollbar active
    50.times { |i| listbox.insert("end", "Item #{i + 1}") }

    # --- Orient options ---
    errors << "default orient failed" unless scrollbar.cget(:orient) == "vertical"

    # --- Width ---
    scrollbar.configure(width: 20)
    errors << "width failed" unless scrollbar.cget(:width).to_i == 20

    # --- Relief ---
    scrollbar.configure(relief: "sunken")
    errors << "relief failed" unless scrollbar.cget(:relief) == "sunken"

    # --- Border ---
    scrollbar.configure(borderwidth: 2)
    errors << "borderwidth failed" unless scrollbar.cget(:borderwidth).to_i == 2

    # --- Element border width ---
    scrollbar.configure(elementborderwidth: 2)
    errors << "elementborderwidth failed" unless scrollbar.cget(:elementborderwidth).to_i == 2

    # --- Repeat delay/interval ---
    scrollbar.configure(repeatdelay: 400, repeatinterval: 100)
    errors << "repeatdelay failed" unless scrollbar.cget(:repeatdelay) == 400
    errors << "repeatinterval failed" unless scrollbar.cget(:repeatinterval) == 100

    # --- Colors ---
    scrollbar.configure(troughcolor: "gray80", activebackground: "gray70")
    errors << "troughcolor failed" if scrollbar.cget(:troughcolor).to_s.empty?
    errors << "activebackground failed" if scrollbar.cget(:activebackground).to_s.empty?

    # --- Active relief ---
    scrollbar.configure(activerelief: "raised")
    errors << "activerelief failed" unless scrollbar.cget(:activerelief) == "raised"

    # --- Jump mode ---
    scrollbar.configure(jump: true)
    errors << "jump failed" unless scrollbar.cget(:jump)

    # --- Scrollbar methods ---
    scrollbar.set(0.0, 0.5)
    pos = scrollbar.get
    errors << "get failed" unless pos.is_a?(Array) && pos.size == 2

    # --- Test XScrollbar and YScrollbar ---
    xscroll = TkXScrollbar.new(frame)
    errors << "XScrollbar orient failed" unless xscroll.cget(:orient) == "horizontal"

    yscroll = TkYScrollbar.new(frame)
    errors << "YScrollbar orient failed" unless yscroll.cget(:orient) == "vertical"

    # Check errors before tk_end
    unless errors.empty?
      root.destroy
      raise "Scrollbar test failures:\n  " + errors.join("\n  ")
    end

    tk_end(root)
  end
end
