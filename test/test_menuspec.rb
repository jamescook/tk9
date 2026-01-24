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

  # --- Hash argument forms (lines 64-71) ---

  def test_create_menu_hash_tearoff_arg
    assert_tk_app("Hash tearoff argument form", method(:app_hash_tearoff_arg))
  end

  def app_hash_tearoff_arg
    require 'tk'
    require 'tk/menu'

    errors = []

    menu_spec = [
      ['File', 0],
      ['New', proc { }]
    ]

    # Pass tearoff as hash (line 64-65 path)
    menu = TkMenu.new_menuspec(menu_spec, root, {tearoff: true})
    tearoff_val = menu.cget('tearoff')
    errors << "tearoff should be enabled via hash, got #{tearoff_val}" unless tearoff_val == true || tearoff_val == 1 || tearoff_val == '1'

    raise errors.join("\n") unless errors.empty?
  end

  # --- Named menus (line 86) ---

  def test_create_named_menu
    assert_tk_app("Create menu with explicit name", method(:app_named_menu))
  end

  def app_named_menu
    require 'tk'
    require 'tk/menu'

    errors = []

    # TkMenu.new_menuspec takes entries only (no menu button header)
    menu_spec = [
      ['Open', proc { }, 0],
      ['Save', proc { }, 0],
      '---',
      ['Exit', proc { }]
    ]

    # widgetname in keys maps to menu_name parameter (line 86)
    menu = TkMenu.new_menuspec(menu_spec, root, false, {widgetname: 'helpmenu'})

    # Verify path contains the widget name
    path = menu.path
    errors << "menu path should contain 'helpmenu', got '#{path}'" unless path.include?('helpmenu')

    # Verify menu has the entries
    label0 = menu.entrycget(0, 'label')
    errors << "entry 0 should be 'Open', got '#{label0}'" unless label0 == 'Open'

    label1 = menu.entrycget(1, 'label')
    errors << "entry 1 should be 'Save', got '#{label1}'" unless label1 == 'Save'

    # Entry 2 is separator, entry 3 is Exit
    label3 = menu.entrycget(3, 'label')
    errors << "entry 3 should be 'Exit', got '#{label3}'" unless label3 == 'Exit'

    raise errors.join("\n") unless errors.empty?
  end

  # --- Hash items with String/Regexp underline (lines 109-121) ---

  def test_hash_item_with_string_underline
    assert_tk_app("Hash item with string underline pattern", method(:app_hash_string_underline))
  end

  def app_hash_string_underline
    require 'tk'
    require 'tk/menu'

    errors = []

    menu_spec = [
      {type: 'command', label: 'File', underline: 'i'},  # String pattern -> index 1
      {type: 'command', label: 'Edit', underline: /d/},  # Regexp pattern -> index 1
      {type: 'command', label: '&New', underline: true}  # & removed, underline 0
    ]

    menu = TkMenu.new_menuspec(menu_spec, root)

    # Verify entries and underline values
    last_idx = menu.index('last')
    errors << "should have 3 entries (last=2), got last=#{last_idx}" unless last_idx == 2

    underline0 = menu.entrycget(0, 'underline').to_i
    errors << "File underline should be 1, got #{underline0}" unless underline0 == 1

    underline1 = menu.entrycget(1, 'underline').to_i
    errors << "Edit underline should be 1, got #{underline1}" unless underline1 == 1  # /d/ matches at index 1

    label2 = menu.entrycget(2, 'label')
    underline2 = menu.entrycget(2, 'underline').to_i
    errors << "New label should have & removed, got '#{label2}'" unless label2 == 'New'
    errors << "New underline should be 0, got #{underline2}" unless underline2 == 0

    raise errors.join("\n") unless errors.empty?
  end

  def test_hash_item_underline_not_found
    assert_tk_app("Hash item underline pattern not found", method(:app_hash_underline_not_found))
  end

  def app_hash_underline_not_found
    require 'tk'
    require 'tk/menu'

    errors = []

    # Pattern won't match - code sets underline to -1, Tk returns nil for -1
    menu_spec = [
      {type: 'command', label: 'File', underline: 'z'},  # 'z' not in 'File' -> -1 -> nil
      {type: 'command', label: 'Edit', underline: true}  # no & in 'Edit' -> -1 -> nil
    ]

    menu = TkMenu.new_menuspec(menu_spec, root)

    # Tk returns nil when underline is -1 (no underline)
    underline0 = menu.entrycget(0, 'underline')
    errors << "File underline should be nil (not found), got #{underline0.inspect}" unless underline0.nil?

    underline1 = menu.entrycget(1, 'underline')
    errors << "Edit underline should be nil (no &), got #{underline1.inspect}" unless underline1.nil?

    raise errors.join("\n") unless errors.empty?
  end

  # --- Array cascade with menu_config (lines 152-176) ---

  def test_array_cascade_with_menu_config
    assert_tk_app("Array cascade with menu_config option", method(:app_cascade_menu_config))
  end

  def app_cascade_menu_config
    require 'tk'
    require 'tk/menu'

    errors = []

    submenu_items = [
      ['Sub1', proc { }],
      ['Sub2', proc { }]
    ]

    # Array format cascade with menu_config in 5th element (lines 152-158)
    menu_spec = [
      ['Edit', 0],
      ['Submenu', submenu_items, 0, nil, {menu_name: 'mysub', menu_config: {tearoff: true}}]
    ]

    menu = TkMenu.new_menuspec(menu_spec, root)

    found_cascade = false
    (0..menu.index('last')).each do |idx|
      if menu.menutype(idx) == 'cascade'
        found_cascade = true
        submenu = menu.entrycget(idx, 'menu')
        # Verify submenu was configured with tearoff
        tearoff = submenu.cget('tearoff')
        errors << "submenu tearoff should be true" unless tearoff == true || tearoff == 1 || tearoff == '1'
        break
      end
    end
    errors << "should have cascade entry" unless found_cascade

    raise errors.join("\n") unless errors.empty?
  end

  def test_array_item_underline_not_found
    assert_tk_app("Array item underline pattern not found", method(:app_array_underline_not_found))
  end

  def app_array_underline_not_found
    require 'tk'
    require 'tk/menu'

    errors = []

    # Array format: [label, command, underline, accelerator, configs]
    # String/true underline patterns that won't match (lines 185, 193)
    menu_spec = [
      ['File', proc { }, 0],         # explicit underline 0
      ['Open', proc { }, 'z'],       # 'z' not in 'Open' -> -1 -> nil
      ['Save', proc { }, true]       # no & in 'Save' -> -1 -> nil
    ]

    menu = TkMenu.new_menuspec(menu_spec, root)

    # Entry 0 has underline 0 (explicit)
    underline0 = menu.entrycget(0, 'underline')
    errors << "File underline should be 0, got #{underline0.inspect}" unless underline0 == 0

    # Entry 1: 'z' not found in 'Open' -> nil (Tk returns nil for -1)
    underline1 = menu.entrycget(1, 'underline')
    errors << "Open underline should be nil (pattern not found), got #{underline1.inspect}" unless underline1.nil?

    # Entry 2: no & in 'Save' -> nil
    underline2 = menu.entrycget(2, 'underline')
    errors << "Save underline should be nil (no &), got #{underline2.inspect}" unless underline2.nil?

    raise errors.join("\n") unless errors.empty?
  end

  # --- Layout proc options (lines 247-275) ---

  def test_menubutton_vertical_layout
    assert_tk_app("Menubutton with vertical layout", method(:app_menubutton_vertical))
  end

  def app_menubutton_vertical
    require 'tk'
    require 'tk/menubar'

    errors = []

    menu_spec = [
      [['File', 0], ['New', proc { }], ['Open', proc { }]],
      [['Edit', 0], ['Cut', proc { }]]
    ]

    # TkMenubar uses menubuttons, :vertical layout_proc (lines 257-265)
    mbar = TkMenubar.new(root, menu_spec, 'layout_proc' => :vertical)

    mbtn, menu = mbar[0]
    # Vertical layout sets direction to :right
    direction = mbtn.cget('direction')
    errors << "vertical layout should set direction to 'right', got '#{direction}'" unless direction.to_s == 'right'

    # Verify menu has correct entries
    last_idx = menu.index('last')
    errors << "menu should have 2 entries (last=1), got last=#{last_idx}" unless last_idx == 1

    raise errors.join("\n") unless errors.empty?
  end

  def test_menubutton_vertical_right_layout
    assert_tk_app("Menubutton with vertical_right layout", method(:app_menubutton_vertical_right))
  end

  def app_menubutton_vertical_right
    require 'tk'
    require 'tk/menubar'

    errors = []

    menu_spec = [
      [['Edit', 0], ['Cut', proc { }]]
    ]

    # :vertical_right layout_proc (lines 266-274) sets direction to :left
    mbar = TkMenubar.new(root, menu_spec, 'layout_proc' => :vertical_right)

    mbtn, menu = mbar[0]
    direction = mbtn.cget('direction')
    errors << "vertical_right should set direction to 'left', got '#{direction}'" unless direction.to_s == 'left'

    raise errors.join("\n") unless errors.empty?
  end

  def test_menubutton_horizontal_layout
    assert_tk_app("Menubutton with horizontal layout", method(:app_menubutton_horizontal))
  end

  def app_menubutton_horizontal
    require 'tk'
    require 'tk/menubar'

    errors = []

    menu_spec = [
      [['Help', 0], ['About', proc { }]]
    ]

    # :horizontal layout_proc (lines 275-276) - packs side left
    mbar = TkMenubar.new(root, menu_spec, 'layout_proc' => :horizontal)

    mbtn, menu = mbar[0]
    text = mbtn.cget('text')
    errors << "menubutton text should be 'Help', got '#{text}'" unless text == 'Help'

    # Verify menu entry
    label = menu.entrycget(0, 'label')
    errors << "menu entry label should be 'About', got '#{label}'" unless label == 'About'

    raise errors.join("\n") unless errors.empty?
  end

  # --- Hash btn_info in menubar (lines 293-305) ---

  def test_menubar_hash_btn_info_underline
    assert_tk_app("Menubar hash btn_info with underline patterns", method(:app_menubar_hash_btn_underline))
  end

  def app_menubar_hash_btn_underline
    require 'tk'
    require 'tk/menubar'

    errors = []

    # TkMenubar uses Frame, so menubutton path (lines 363-382) is used
    # Menubutton path uses 'label' key (converted to 'text')
    menu1 = [
      {label: 'File', underline: 'i'},  # 'i' at index 1
      ['New', proc { }]
    ]

    menu2 = [
      {label: '&Edit', underline: true},  # & removed, underline at 0
      ['Cut', proc { }]
    ]

    menu3 = [
      {label: 'Help', underline: 'z'},  # Not found -> -1
      ['About', proc { }]
    ]

    mbar = TkMenubar.new(root, [menu1, menu2, menu3])

    # Verify underline values on menubuttons
    mbtn1, _ = mbar[0]
    underline1 = mbtn1.cget('underline').to_i
    errors << "File underline should be 1 ('i' position), got #{underline1}" unless underline1 == 1

    mbtn2, _ = mbar[1]
    text2 = mbtn2.cget('text')
    underline2 = mbtn2.cget('underline').to_i
    errors << "Edit text should have & removed, got '#{text2}'" unless text2 == 'Edit'
    errors << "Edit underline should be 0, got #{underline2}" unless underline2 == 0

    mbtn3, _ = mbar[2]
    underline3 = mbtn3.cget('underline')
    errors << "Help underline should be nil (pattern not found), got #{underline3.inspect}" unless underline3.nil?

    raise errors.join("\n") unless errors.empty?
  end

  # --- Custom layout_proc (lines 419-422) ---

  def test_menubutton_custom_layout_proc
    assert_tk_app("Menubutton with custom layout proc", method(:app_menubutton_custom_layout))
  end

  def app_menubutton_custom_layout
    require 'tk'
    require 'tk/menubar'

    errors = []

    menu_spec = [
      [['Custom', 0], ['Item', proc { }]]
    ]

    # Custom proc that sets a specific direction (lines 419-422)
    custom_proc = proc { |parent, btn|
      btn.configure('direction', 'flush')
      btn.pack(side: :bottom)
    }

    mbar = TkMenubar.new(root, menu_spec, 'layout_proc' => custom_proc)

    mbtn, menu = mbar[0]
    # Verify custom proc was called by checking direction we set
    direction = mbtn.cget('direction')
    errors << "custom layout should set direction to 'flush', got '#{direction}'" unless direction.to_s == 'flush'

    # Verify menu entry
    label = menu.entrycget(0, 'label')
    errors << "menu entry should be 'Item', got '#{label}'" unless label == 'Item'

    raise errors.join("\n") unless errors.empty?
  end
end
