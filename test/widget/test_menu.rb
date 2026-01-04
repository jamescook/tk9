# frozen_string_literal: true

# Comprehensive test for Tk::Menu and Tk::Menubutton widget options.
# Runs in a single subprocess to minimize overhead.
#
# See: https://www.tcl-lang.org/man/tcl/TkCmd/menu.html
# See: https://www.tcl-lang.org/man/tcl/TkCmd/menubutton.html

require_relative '../test_helper'
require_relative '../tk_test_helper'

class TestMenuWidget < Minitest::Test
  include TkTestHelper

  def test_menu_comprehensive
    assert_tk_app("Menu widget comprehensive test", method(:menu_app))
  end

  def menu_app
    require 'tk'
    require 'tk/menu'
    require 'tk/frame'
    require 'tk/label'

    root = TkRoot.new { withdraw }
    errors = []

    frame = TkFrame.new(root, padx: 20, pady: 20)
    frame.pack(fill: "both", expand: true)

    # --- Basic menu ---
    menu = TkMenu.new(root, tearoff: false)

    errors << "tearoff failed" if menu.cget(:tearoff)

    # Add menu items
    menu.add_command(label: "New", accelerator: "Ctrl+N")
    menu.add_command(label: "Open", accelerator: "Ctrl+O")
    menu.add_separator
    menu.add_command(label: "Exit")

    # --- Menu appearance ---
    menu.configure(activebackground: "blue")
    errors << "activebackground failed" if menu.cget(:activebackground).to_s.empty?

    menu.configure(activeforeground: "white")
    errors << "activeforeground failed" if menu.cget(:activeforeground).to_s.empty?

    menu.configure(activeborderwidth: 2)
    errors << "activeborderwidth failed" unless menu.cget(:activeborderwidth).to_i == 2

    menu.configure(activerelief: "raised")
    errors << "activerelief failed" unless menu.cget(:activerelief) == "raised"

    # --- Border and relief ---
    menu.configure(borderwidth: 1)
    errors << "borderwidth failed" unless menu.cget(:borderwidth).to_i == 1

    menu.configure(relief: "raised")
    errors << "relief failed" unless menu.cget(:relief) == "raised"

    # --- Title ---
    menu.configure(title: "File Menu")
    errors << "title failed" unless menu.cget(:title) == "File Menu"

    # --- Menubutton ---
    TkLabel.new(frame, text: "Click the menubutton:").pack(anchor: "w")

    menubutton = TkMenubutton.new(frame,
      text: "Options",
      relief: "raised",
      indicatoron: true
    )
    menubutton.pack(pady: 10)

    # Test indicatoron boolean (DSL-declared option)
    errors << "menubutton indicatoron true failed" unless menubutton.cget(:indicatoron)
    errors << "menubutton indicatoron not boolean" unless menubutton.cget(:indicatoron).is_a?(TrueClass)

    menubutton.configure(indicatoron: false)
    errors << "menubutton indicatoron false failed" if menubutton.cget(:indicatoron)
    errors << "menubutton indicatoron false not boolean" unless menubutton.cget(:indicatoron).is_a?(FalseClass)

    menubutton.configure(indicatoron: true)

    # Create menu for the menubutton
    mb_menu = TkMenu.new(menubutton, tearoff: false)
    mb_menu.add_command(label: "Option 1")
    mb_menu.add_command(label: "Option 2")
    mb_menu.add_command(label: "Option 3")

    menubutton.configure(menu: mb_menu)

    # --- Menubutton direction (DSL-declared option) ---
    menubutton.configure(direction: "below")
    errors << "direction below failed" unless menubutton.cget(:direction) == "below"

    menubutton.configure(direction: "above")
    errors << "direction above failed" unless menubutton.cget(:direction) == "above"

    # --- Menubutton state (inherited from Label) ---
    menubutton.configure(state: "disabled")
    errors << "menubutton disabled state failed" unless menubutton.cget(:state) == "disabled"

    menubutton.configure(state: "normal")
    errors << "menubutton normal state failed" unless menubutton.cget(:state) == "normal"

    # --- OptionMenubutton ---
    TkLabel.new(frame, text: "Select a color:").pack(anchor: "w", pady: 10)

    color_var = TkVariable.new("Red")
    option_menu = TkOptionMenubutton.new(frame, color_var, "Red", "Green", "Blue", "Yellow")
    option_menu.pack(pady: 5)

    # OptionMenubutton inherits indicatoron from Menubutton
    errors << "optionmenu indicatoron failed" unless option_menu.cget(:indicatoron).is_a?(TrueClass) || option_menu.cget(:indicatoron).is_a?(FalseClass)

    # Test variable binding
    errors << "optionmenu variable failed" unless color_var.value == "Red"

    # --- Menu with checkbuttons and radiobuttons ---
    view_menu = TkMenu.new(root, tearoff: false)
    view_menu.add_checkbutton(label: "Show Toolbar")
    view_menu.add_checkbutton(label: "Show Status Bar")
    view_menu.add_separator
    view_menu.add_radiobutton(label: "Small Icons")
    view_menu.add_radiobutton(label: "Large Icons")

    # --- Cascade menu ---
    submenu = TkMenu.new(root, tearoff: false)
    submenu.add_command(label: "Submenu Item 1")
    submenu.add_command(label: "Submenu Item 2")
    menu.add_cascade(label: "More Options", menu: submenu)

    # Check errors before tk_end
    unless errors.empty?
      root.destroy
      raise "Menu test failures:\n  " + errors.join("\n  ")
    end

    tk_end(root)
  end
end
