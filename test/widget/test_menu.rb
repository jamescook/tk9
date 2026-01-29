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

    errors = []

    frame = TkFrame.new(root, padx: 20, pady: 20)
    frame.pack(fill: "both", expand: true)

    # --- Basic menu ---
    menu = TkMenu.new(root, tearoff: false)

    # Test tearoff boolean (DSL-declared)
    errors << "tearoff false failed" if menu.cget(:tearoff)
    errors << "tearoff not boolean" unless menu.cget(:tearoff).is_a?(FalseClass)

    # Add menu items
    menu.add_command(label: "New", accelerator: "Ctrl+N")
    menu.add_command(label: "Open", accelerator: "Ctrl+O")
    menu.add_separator
    menu.add_command(label: "Exit")

    # --- Menu appearance ---
    menu.configure(activebackground: "blue")
    errors << "activebackground failed" unless menu.cget(:activebackground).to_s == "blue"

    menu.configure(activeforeground: "white")
    errors << "activeforeground failed" unless menu.cget(:activeforeground).to_s == "white"

    # Test selectcolor (DSL-declared color)
    menu.configure(selectcolor: "green")
    errors << "menu selectcolor failed" unless menu.cget(:selectcolor).to_s == "green"

    menu.configure(activeborderwidth: 2)
    errors << "activeborderwidth failed" unless menu.cget(:activeborderwidth).to_i == 2

    # activerelief is Tk 9.0+ only
    if Tk::TK_MAJOR_VERSION >= 9
      menu.configure(activerelief: "raised")
      errors << "activerelief failed on Tk 9+" unless menu.cget(:activerelief) == "raised"
    end

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

    # --- Cascade menu val2ruby conversion ---
    # Tests that entrycget(:menu) returns a TkMenu object, not a string path
    # This exercises __item_val2ruby_optkeys conversion
    cascade_index = menu.index("More Options")
    retrieved_submenu = menu.entrycget(cascade_index, :menu)
    errors << "cascade menu should return same menu path, got #{retrieved_submenu.inspect}" unless retrieved_submenu&.path == submenu.path

    # ========================================
    # Menu Entry Configuration Tests (entryconfigure/entrycget)
    # ========================================

    # Create a fresh menu for entry tests
    entry_menu = TkMenu.new(root, tearoff: false)
    entry_menu.add_command(label: "Test Entry", accelerator: "Ctrl+T")
    entry_menu.add_command(label: "Another Entry")
    entry_menu.add_separator
    entry_menu.add_checkbutton(label: "Check Option")
    entry_menu.add_radiobutton(label: "Radio Option")

    # --- entrycget label ---
    label = entry_menu.entrycget(0, :label)
    errors << "entrycget label failed" unless label == "Test Entry"

    # --- entryconfigure label ---
    entry_menu.entryconfigure(0, label: "Modified Entry")
    errors << "entryconfigure label failed" unless entry_menu.entrycget(0, :label) == "Modified Entry"

    # --- entrycget/configure accelerator ---
    accel = entry_menu.entrycget(0, :accelerator)
    errors << "entrycget accelerator failed" unless accel == "Ctrl+T"

    entry_menu.entryconfigure(0, accelerator: "Ctrl+M")
    errors << "entryconfigure accelerator failed" unless entry_menu.entrycget(0, :accelerator) == "Ctrl+M"

    # --- entryconfigure state ---
    entry_menu.entryconfigure(0, state: "disabled")
    errors << "entryconfigure state disabled failed" unless entry_menu.entrycget(0, :state) == "disabled"

    entry_menu.entryconfigure(0, state: "normal")
    errors << "entryconfigure state normal failed" unless entry_menu.entrycget(0, :state) == "normal"

    # --- entryconfigure underline ---
    entry_menu.entryconfigure(0, underline: 0)
    errors << "entryconfigure underline failed" unless entry_menu.entrycget(0, :underline) == 0

    # --- entryconfigure command ---
    cmd_called = false
    entry_menu.entryconfigure(1, command: proc { cmd_called = true })
    entry_menu.invoke(1)
    errors << "entryconfigure command failed" unless cmd_called

    # --- checkbutton entry variable ---
    check_var = TkVariable.new(false)
    entry_menu.entryconfigure(3, variable: check_var)
    entry_menu.invoke(3)
    errors << "checkbutton entry invoke failed" unless check_var.bool

    # --- radiobutton entry value ---
    radio_var = TkVariable.new("")
    entry_menu.entryconfigure(4, variable: radio_var, value: "selected")
    entry_menu.invoke(4)
    errors << "radiobutton entry invoke failed" unless radio_var.value == "selected"

    # --- entryconfigure selectcolor (DSL-declared string option) ---
    entry_menu.entryconfigure(3, selectcolor: "blue")
    errors << "entryconfigure selectcolor failed" unless entry_menu.entrycget(3, :selectcolor).to_s == "blue"

    # --- entryconfigure foreground/background (colors) ---
    entry_menu.entryconfigure(0, foreground: "red")
    errors << "entryconfigure foreground failed" unless entry_menu.entrycget(0, :foreground).to_s == "red"

    entry_menu.entryconfigure(0, background: "yellow")
    errors << "entryconfigure background failed" unless entry_menu.entrycget(0, :background).to_s == "yellow"

    # --- entryconfigure columnbreak ---
    entry_menu.entryconfigure(1, columnbreak: true)
    errors << "entryconfigure columnbreak failed" unless entry_menu.entrycget(1, :columnbreak)

    # --- entry index ---
    idx = entry_menu.index("Another Entry")
    errors << "menu index failed" unless idx == 1

    # --- entry type ---
    type = entry_menu.menutype(0)
    errors << "menutype command failed" unless type == "command"

    type = entry_menu.menutype(2)
    errors << "menutype separator failed" unless type == "separator"

    # Check errors before tk_end
    unless errors.empty?
      raise "Menu test failures:\n  " + errors.join("\n  ")
    end

  end
end
