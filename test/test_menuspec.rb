# frozen_string_literal: true

# Tests for TkMenuSpec - menu specification DSL
#
# TkMenuSpec provides a DSL for creating menus from arrays/hashes.
# It's used by TkMenu and TkMenubar to build menus declaratively.
#
# See: https://www.tcl.tk/man/tcl8.6/TkCmd/menu.htm

require_relative 'test_helper'
require_relative 'tk_test_helper'
require 'tk'

class TestTkMenuSpec < Minitest::Test
  include TkTestHelper

  # --- Basic menu creation ---

  def test_create_menu_with_commands
    assert_tk_app("Create menu with command entries", method(:app_menu_commands))
  end

  def app_menu_commands
    require 'tk'
    require 'tk/menu'

    errors = []

    menu_spec = [
      ['File', 0],
      ['New', proc { }, 0, 'Ctrl+N'],
      ['Open', proc { }, 0, 'Ctrl+O'],
      '---',
      ['Exit', proc { }, 0]
    ]

    menu = TkMenu.new_menuspec(menu_spec, root)
    errors << "menu should be TkMenu, got #{menu.class}" unless menu.is_a?(Tk::Menu) || menu.is_a?(TkMenu)

    # Check the menu has entries
    last_idx = menu.index('last')
    errors << "menu should have entries, got last=#{last_idx}" if last_idx.nil?

    raise errors.join("\n") unless errors.empty?
  end

  def test_create_menu_with_separator
    assert_tk_app("Create menu with separator", method(:app_menu_separator))
  end

  def app_menu_separator
    require 'tk'
    require 'tk/menu'

    errors = []

    menu_spec = [
      ['Menu', 0],
      ['Item1', proc { }],
      '---',
      ['Item2', proc { }]
    ]

    menu = TkMenu.new_menuspec(menu_spec, root)

    # Separator should be present
    found_separator = false
    (0..menu.index('last')).each do |idx|
      if menu.menutype(idx) == 'separator'
        found_separator = true
        break
      end
    end

    errors << "menu should contain a separator" unless found_separator

    raise errors.join("\n") unless errors.empty?
  end

  def test_create_menu_with_checkbutton
    assert_tk_app("Create menu with checkbutton entry", method(:app_menu_checkbutton))
  end

  def app_menu_checkbutton
    require 'tk'
    require 'tk/menu'

    errors = []

    var = TkVariable.new(false)
    menu_spec = [
      ['Options', 0],
      ['Enable Feature', var, 0]
    ]

    menu = TkMenu.new_menuspec(menu_spec, root)

    # Find checkbutton entry
    found_check = false
    (0..menu.index('last')).each do |idx|
      if menu.menutype(idx) == 'checkbutton'
        found_check = true
        break
      end
    end

    errors << "menu should contain a checkbutton" unless found_check

    raise errors.join("\n") unless errors.empty?
  end

  def test_create_menu_with_radiobutton
    assert_tk_app("Create menu with radiobutton entry", method(:app_menu_radiobutton))
  end

  def app_menu_radiobutton
    require 'tk'
    require 'tk/menu'

    errors = []

    var = TkVariable.new("option1")
    menu_spec = [
      ['View', 0],
      ['Option 1', [var, 'option1'], 0],
      ['Option 2', [var, 'option2'], 0]
    ]

    menu = TkMenu.new_menuspec(menu_spec, root)

    # Find radiobutton entries
    radio_count = 0
    (0..menu.index('last')).each do |idx|
      radio_count += 1 if menu.menutype(idx) == 'radiobutton'
    end

    errors << "menu should contain 2 radiobuttons, got #{radio_count}" unless radio_count == 2

    raise errors.join("\n") unless errors.empty?
  end

  def test_create_menu_with_cascade
    assert_tk_app("Create menu with cascade (submenu)", method(:app_menu_cascade))
  end

  def app_menu_cascade
    require 'tk'
    require 'tk/menu'

    errors = []

    submenu_items = [
      ['Sub Item 1', proc { }],
      ['Sub Item 2', proc { }]
    ]

    menu_spec = [
      ['Edit', 0],
      ['Cut', proc { }],
      ['Submenu', submenu_items, 0]
    ]

    menu = TkMenu.new_menuspec(menu_spec, root)

    # Find cascade entry
    found_cascade = false
    (0..menu.index('last')).each do |idx|
      if menu.menutype(idx) == 'cascade'
        found_cascade = true
        break
      end
    end

    errors << "menu should contain a cascade" unless found_cascade

    raise errors.join("\n") unless errors.empty?
  end

  # --- Underline handling ---

  def test_underline_with_ampersand
    assert_tk_app("Underline via & character", method(:app_underline_ampersand))
  end

  def app_underline_ampersand
    require 'tk'
    require 'tk/menu'

    errors = []

    # Using true for underline triggers & parsing
    menu_spec = [
      ['&File', true],  # & before F means underline at 0
      ['&New', proc { }, true]
    ]

    menu = TkMenu.new_menuspec(menu_spec, root)

    # The & should be removed and underline set
    # Can't easily verify the underline value, but verify no crash
    errors << "menu should be created" unless menu

    raise errors.join("\n") unless errors.empty?
  end

  def test_underline_with_string_pattern
    assert_tk_app("Underline via string pattern", method(:app_underline_string))
  end

  def app_underline_string
    require 'tk'
    require 'tk/menu'

    errors = []

    # Using a string/regex for underline finds its position
    menu_spec = [
      ['File', 'i'],  # underline at 'i' position (1)
      ['Open', proc { }, 'p']  # underline at 'p' position (1)
    ]

    menu = TkMenu.new_menuspec(menu_spec, root)
    errors << "menu should be created" unless menu

    raise errors.join("\n") unless errors.empty?
  end

  # --- Hash-based menu spec ---

  def test_menu_spec_with_hash
    assert_tk_app("Menu spec using hash format", method(:app_menu_hash))
  end

  def app_menu_hash
    require 'tk'
    require 'tk/menu'

    errors = []

    menu_spec = [
      {type: 'command', label: 'File', underline: 0},
      {type: 'command', label: 'New', command: proc { }, accelerator: 'Ctrl+N'},
      {type: 'separator'},
      {type: 'command', label: 'Exit', command: proc { }}
    ]

    menu = TkMenu.new_menuspec(menu_spec, root)
    errors << "menu should be created from hash spec" unless menu

    # Verify separator exists
    found_separator = false
    (0..menu.index('last')).each do |idx|
      if menu.menutype(idx) == 'separator'
        found_separator = true
        break
      end
    end
    errors << "hash spec should create separator" unless found_separator

    raise errors.join("\n") unless errors.empty?
  end

  def test_menu_spec_hash_with_cascade
    assert_tk_app("Hash spec with cascade menu", method(:app_menu_hash_cascade))
  end

  def app_menu_hash_cascade
    require 'tk'
    require 'tk/menu'

    errors = []

    submenu = [
      {type: 'command', label: 'Sub1'},
      {type: 'command', label: 'Sub2'}
    ]

    menu_spec = [
      {type: 'command', label: 'Edit'},
      {type: 'cascade', label: 'More', menu: submenu}
    ]

    menu = TkMenu.new_menuspec(menu_spec, root)

    found_cascade = false
    (0..menu.index('last')).each do |idx|
      if menu.menutype(idx) == 'cascade'
        found_cascade = true
        break
      end
    end
    errors << "hash spec should create cascade" unless found_cascade

    raise errors.join("\n") unless errors.empty?
  end

  # --- Tearoff option ---

  def test_menu_with_tearoff
    assert_tk_app("Menu with tearoff enabled", method(:app_menu_tearoff))
  end

  def app_menu_tearoff
    require 'tk'
    require 'tk/menu'

    errors = []

    menu_spec = [
      ['File', 0],
      ['New', proc { }]
    ]

    # Create with tearoff = true
    menu = TkMenu.new_menuspec(menu_spec, root, true)
    tearoff_val = menu.cget('tearoff')

    errors << "tearoff should be enabled, got #{tearoff_val}" unless tearoff_val == true || tearoff_val == 1 || tearoff_val == '1'

    raise errors.join("\n") unless errors.empty?
  end

  # --- Simple string entry ---

  def test_menu_with_string_entry
    assert_tk_app("Menu with simple string entry", method(:app_menu_string_entry))
  end

  def app_menu_string_entry
    require 'tk'
    require 'tk/menu'

    errors = []

    # Simple strings become command entries with that label
    menu_spec = [
      'Simple Item',
      'Another Item'
    ]

    menu = TkMenu.new_menuspec(menu_spec, root)

    # Should have 2 command entries (the simple strings)
    command_count = 0
    (0..menu.index('last')).each do |idx|
      command_count += 1 if menu.menutype(idx) == 'command'
    end

    errors << "should have 2 command entries, got #{command_count}" unless command_count == 2

    raise errors.join("\n") unless errors.empty?
  end

  # --- Menubar creation ---

  def test_menubar_creation
    assert_tk_app("Create menubar from spec", method(:app_menubar))
  end

  def app_menubar
    require 'tk'
    require 'tk/menubar'

    errors = []
    root.deiconify

    file_menu = [
      ['File', 0],
      ['New', proc { }, 0],
      ['Open', proc { }, 0],
      '---',
      ['Exit', proc { }, 0]
    ]

    edit_menu = [
      ['Edit', 0],
      ['Cut', proc { }, 0],
      ['Copy', proc { }, 0],
      ['Paste', proc { }, 0]
    ]

    mbar = TkMenubar.new(root, [file_menu, edit_menu])
    errors << "menubar should be created" unless mbar
    errors << "menubar should be TkMenubar" unless mbar.is_a?(TkMenubar)

    raise errors.join("\n") unless errors.empty?
  end

  # --- Default opts ---

  def test_menu_with_default_opts
    assert_tk_app("Menu with default options", method(:app_menu_default_opts))
  end

  def app_menu_default_opts
    require 'tk'
    require 'tk/menu'

    errors = []

    menu_spec = [
      ['Test', 0],
      ['Item', proc { }]
    ]

    # Pass default options
    menu = TkMenu.new_menuspec(menu_spec, root, false, {foreground: 'black'})
    errors << "menu should be created with opts" unless menu

    raise errors.join("\n") unless errors.empty?
  end
end
