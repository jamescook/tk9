# frozen_string_literal: true

# Tests for TkMenubar - declarative menubar creation from spec arrays
#
# TkMenubar lets you define menu structure as nested arrays/hashes:
#   menu_spec = [
#     [['File', 0],
#       ['Open', proc{...}, 0],
#       '---',
#       ['Quit', proc{exit}, 0]],
#     [['Edit', 0],
#       ['Cut', proc{...}, 2]]
#   ]
#   menubar = TkMenubar.new(nil, menu_spec)
#
# See: sample/menubar1.rb, sample/menubar3.rb

require_relative 'test_helper'
require_relative 'tk_test_helper'

class TestMenubar < Minitest::Test
  include TkTestHelper

  # ===========================================
  # Basic creation
  # ===========================================

  def test_create_empty
    assert_tk_app("Menubar create empty", method(:create_empty_app))
  end

  def create_empty_app
    require 'tk'
    require 'tk/menubar'

    errors = []

    menubar = TkMenubar.new
    errors << "should be a Frame" unless menubar.is_a?(Tk::Frame)
    errors << "should have no menus" unless menubar[0].nil?

    raise errors.join("\n") unless errors.empty?
  end

  def test_create_with_spec
    assert_tk_app("Menubar create with spec", method(:create_with_spec_app))
  end

  def create_with_spec_app
    require 'tk'
    require 'tk/menubar'

    errors = []

    menu_spec = [
      [['File', 0],
        ['Open', proc{}, 0],
        ['Quit', proc{}, 0]]
    ]

    menubar = TkMenubar.new(nil, menu_spec)
    errors << "should have one menu" if menubar[0].nil?

    # [0] returns [menubutton, menu] pair
    mbtn, menu = menubar[0]
    errors << "first element should be menubutton" unless mbtn.is_a?(TkMenubutton)
    errors << "second element should be menu" unless menu.is_a?(TkMenu)

    raise errors.join("\n") unless errors.empty?
  end

  def test_create_with_options
    assert_tk_app("Menubar create with options", method(:create_with_options_app))
  end

  def create_with_options_app
    require 'tk'
    require 'tk/menubar'

    errors = []

    menu_spec = [
      [['File', 0], ['Open', proc{}, 0]]
    ]

    menubar = TkMenubar.new(nil, menu_spec,
                            'tearoff' => false,
                            'foreground' => 'red')

    mbtn, menu = menubar[0]
    errors << "tearoff should be false" unless menu.cget(:tearoff) == false
    errors << "foreground should be red" unless mbtn.cget(:foreground) == 'red'

    raise errors.join("\n") unless errors.empty?
  end

  # ===========================================
  # add_menu
  # ===========================================

  def test_add_menu
    assert_tk_app("Menubar add_menu", method(:add_menu_app))
  end

  def add_menu_app
    require 'tk'
    require 'tk/menubar'

    errors = []

    menubar = TkMenubar.new

    menubar.add_menu([['File', 0],
                      ['Open', proc{}, 0],
                      ['Quit', proc{}, 0]])

    menubar.add_menu([['Edit', 0],
                      ['Cut', proc{}, 0]])

    errors << "should have 2 menus" unless menubar[1]
    errors << "should not have 3rd menu" if menubar[2]

    raise errors.join("\n") unless errors.empty?
  end

  # ===========================================
  # Entry types
  # ===========================================

  def test_command_entry
    assert_tk_app("Menubar command entry", method(:command_entry_app))
  end

  def command_entry_app
    require 'tk'
    require 'tk/menubar'

    errors = []
    clicked = false

    menu_spec = [
      [['File', 0],
        ['Click Me', proc{ clicked = true }, 0]]
    ]

    menubar = TkMenubar.new(nil, menu_spec)
    _, menu = menubar[0]

    menu.invoke(0)
    errors << "command should have been invoked" unless clicked

    raise errors.join("\n") unless errors.empty?
  end

  def test_checkbutton_entry
    assert_tk_app("Menubar checkbutton entry", method(:checkbutton_entry_app))
  end

  def checkbutton_entry_app
    require 'tk'
    require 'tk/menubar'

    errors = []

    check_var = TkVariable.new(false)

    menu_spec = [
      [['Options', 0],
        ['Enable Feature', check_var, 0]]
    ]

    menubar = TkMenubar.new(nil, menu_spec)
    _, menu = menubar[0]

    errors << "should start false" unless check_var.bool == false

    menu.invoke(0)
    errors << "should be true after invoke" unless check_var.bool == true

    menu.invoke(0)
    errors << "should be false after second invoke" unless check_var.bool == false

    raise errors.join("\n") unless errors.empty?
  end

  def test_radiobutton_entry
    assert_tk_app("Menubar radiobutton entry", method(:radiobutton_entry_app))
  end

  def radiobutton_entry_app
    require 'tk'
    require 'tk/menubar'

    errors = []

    radio_var = TkVariable.new('a')

    menu_spec = [
      [['Choice', 0],
        ['Option A', [radio_var, 'a'], 0],
        ['Option B', [radio_var, 'b'], 0],
        ['Option C', [radio_var, 'c'], 0]]
    ]

    menubar = TkMenubar.new(nil, menu_spec)
    _, menu = menubar[0]

    errors << "should start as 'a'" unless radio_var.string == 'a'

    menu.invoke(1)  # Option B
    errors << "should be 'b' after invoke" unless radio_var.string == 'b'

    menu.invoke(2)  # Option C
    errors << "should be 'c' after invoke" unless radio_var.string == 'c'

    raise errors.join("\n") unless errors.empty?
  end

  def test_separator_entry
    assert_tk_app("Menubar separator entry", method(:separator_entry_app))
  end

  def separator_entry_app
    require 'tk'
    require 'tk/menubar'

    errors = []

    menu_spec = [
      [['File', 0],
        ['Open', proc{}, 0],
        '---',
        ['Quit', proc{}, 0]]
    ]

    menubar = TkMenubar.new(nil, menu_spec)
    _, menu = menubar[0]

    errors << "entry 1 should be separator" unless menu.menutype(1) == 'separator'

    raise errors.join("\n") unless errors.empty?
  end

  def test_cascade_entry
    assert_tk_app("Menubar cascade entry", method(:cascade_entry_app))
  end

  def cascade_entry_app
    require 'tk'
    require 'tk/menubar'

    errors = []
    sub_clicked = false

    menu_spec = [
      [['File', 0],
        ['Recent', [
          ['File 1', proc{ sub_clicked = true }, 0],
          ['File 2', proc{}, 0]
        ], 0]]
    ]

    menubar = TkMenubar.new(nil, menu_spec)
    _, menu = menubar[0]

    errors << "entry 0 should be cascade" unless menu.menutype(0) == 'cascade'

    # Get the submenu and invoke an item
    submenu = menu.entrycget(0, 'menu')
    errors << "should have submenu" unless submenu.is_a?(TkMenu)

    submenu.invoke(0)
    errors << "submenu command should work" unless sub_clicked

    raise errors.join("\n") unless errors.empty?
  end

  # ===========================================
  # Hash syntax
  # ===========================================

  def test_hash_syntax_entry
    assert_tk_app("Menubar hash syntax", method(:hash_syntax_app))
  end

  def hash_syntax_app
    require 'tk'
    require 'tk/menubar'

    errors = []
    clicked = false

    menu_spec = [
      [['File', 0],
        {:label => 'Open', :command => proc{ clicked = true }, :underline => 0}]
    ]

    menubar = TkMenubar.new(nil, menu_spec)
    _, menu = menubar[0]

    menu.invoke(0)
    errors << "hash syntax command should work" unless clicked

    raise errors.join("\n") unless errors.empty?
  end

  def test_hash_syntax_checkbutton
    assert_tk_app("Menubar hash checkbutton", method(:hash_checkbutton_app))
  end

  def hash_checkbutton_app
    require 'tk'
    require 'tk/menubar'

    errors = []

    check_var = TkVariable.new(false)

    menu_spec = [
      [['Options', 0],
        {:type => 'checkbutton', :label => 'Enable', :variable => check_var}]
    ]

    menubar = TkMenubar.new(nil, menu_spec)
    _, menu = menubar[0]

    menu.invoke(0)
    errors << "hash checkbutton should toggle" unless check_var.bool == true

    raise errors.join("\n") unless errors.empty?
  end

  # ===========================================
  # Underline handling
  # ===========================================

  def test_underline_integer
    assert_tk_app("Menubar underline integer", method(:underline_integer_app))
  end

  def underline_integer_app
    require 'tk'
    require 'tk/menubar'

    errors = []

    menu_spec = [
      [['File', 0],  # underline F (index 0)
        ['Open', proc{}, 1]]  # underline p (index 1)
    ]

    menubar = TkMenubar.new(nil, menu_spec)
    mbtn, menu = menubar[0]

    errors << "menubutton underline should be 0" unless mbtn.cget(:underline) == 0
    errors << "entry underline should be 1" unless menu.entrycget(0, :underline) == 1

    raise errors.join("\n") unless errors.empty?
  end

  def test_underline_ampersand
    assert_tk_app("Menubar underline ampersand", method(:underline_ampersand_app))
  end

  def underline_ampersand_app
    require 'tk'
    require 'tk/menubar'

    errors = []

    menu_spec = [
      [['&File', true],  # & before F, underline index 0
        ['&Open', proc{}, true]]  # & before O, underline index 0
    ]

    menubar = TkMenubar.new(nil, menu_spec)
    mbtn, menu = menubar[0]

    # The & should be removed from the text
    errors << "menubutton text should be 'File'" unless mbtn.cget(:text) == 'File'
    errors << "menubutton underline should be 0" unless mbtn.cget(:underline) == 0

    errors << "entry label should be 'Open'" unless menu.entrycget(0, :label) == 'Open'
    errors << "entry underline should be 0" unless menu.entrycget(0, :underline) == 0

    raise errors.join("\n") unless errors.empty?
  end

  def test_underline_string_match
    assert_tk_app("Menubar underline string", method(:underline_string_app))
  end

  def underline_string_app
    require 'tk'
    require 'tk/menubar'

    errors = []

    menu_spec = [
      [['File', 'i'],  # match 'i' at index 1
        ['Open', proc{}, 'e']]  # match 'e' at index 2
    ]

    menubar = TkMenubar.new(nil, menu_spec)
    mbtn, menu = menubar[0]

    errors << "menubutton underline should be 1" unless mbtn.cget(:underline) == 1
    errors << "entry underline should be 2" unless menu.entrycget(0, :underline) == 2

    raise errors.join("\n") unless errors.empty?
  end

  # ===========================================
  # Configuration delegation
  # ===========================================

  def test_configure_foreground
    assert_tk_app("Menubar configure foreground", method(:configure_foreground_app))
  end

  def configure_foreground_app
    require 'tk'
    require 'tk/menubar'

    errors = []

    menu_spec = [
      [['File', 0], ['Open', proc{}, 0]]
    ]

    menubar = TkMenubar.new(nil, menu_spec)
    menubar.configure('foreground', 'blue')

    mbtn, menu = menubar[0]
    errors << "menubutton foreground should be blue" unless mbtn.cget(:foreground) == 'blue'
    errors << "menu foreground should be blue" unless menu.cget(:foreground) == 'blue'

    raise errors.join("\n") unless errors.empty?
  end

  def test_configure_background
    assert_tk_app("Menubar configure background", method(:configure_background_app))
  end

  def configure_background_app
    require 'tk'
    require 'tk/menubar'

    errors = []

    menu_spec = [
      [['File', 0], ['Open', proc{}, 0]]
    ]

    menubar = TkMenubar.new(nil, menu_spec)
    menubar.configure('background', 'yellow')

    mbtn, menu = menubar[0]
    errors << "menubutton background should be yellow" unless mbtn.cget(:background) == 'yellow'
    errors << "menu background should be yellow" unless menu.cget(:background) == 'yellow'

    raise errors.join("\n") unless errors.empty?
  end

  def test_configure_font
    assert_tk_app("Menubar configure font", method(:configure_font_app))
  end

  def configure_font_app
    require 'tk'
    require 'tk/menubar'

    errors = []

    menu_spec = [
      [['File', 0], ['Open', proc{}, 0]]
    ]

    menubar = TkMenubar.new(nil, menu_spec)
    menubar.configure('font', 'Helvetica 14 bold')

    mbtn, _ = menubar[0]
    font = mbtn.cget(:font)
    # Font might be returned as a TkFont object or string
    font_str = font.respond_to?(:to_s) ? font.to_s : font
    errors << "font should include Helvetica" unless font_str.downcase.include?('helvetica')

    raise errors.join("\n") unless errors.empty?
  end

  def test_configure_tearoff
    assert_tk_app("Menubar configure tearoff", method(:configure_tearoff_app))
  end

  def configure_tearoff_app
    require 'tk'
    require 'tk/menubar'

    errors = []

    menu_spec = [
      [['File', 0], ['Open', proc{}, 0]]
    ]

    # Default tearoff is true
    menubar = TkMenubar.new(nil, menu_spec)
    _, menu = menubar[0]

    # Now configure it off
    menubar.configure('tearoff', false)
    errors << "tearoff should be false" unless menu.cget(:tearoff) == false

    raise errors.join("\n") unless errors.empty?
  end

  def test_configure_active_colors
    assert_tk_app("Menubar configure active colors", method(:configure_active_colors_app))
  end

  def configure_active_colors_app
    require 'tk'
    require 'tk/menubar'

    errors = []

    menu_spec = [
      [['File', 0], ['Open', proc{}, 0]]
    ]

    menubar = TkMenubar.new(nil, menu_spec)
    menubar.configure('activeforeground', 'white')
    menubar.configure('activebackground', 'navy')

    mbtn, menu = menubar[0]
    errors << "activeforeground should be white" unless mbtn.cget(:activeforeground) == 'white'
    errors << "activebackground should be navy" unless mbtn.cget(:activebackground) == 'navy'
    errors << "menu activeforeground should be white" unless menu.cget(:activeforeground) == 'white'
    errors << "menu activebackground should be navy" unless menu.cget(:activebackground) == 'navy'

    raise errors.join("\n") unless errors.empty?
  end

  # ===========================================
  # Cascade submenu delegation
  # ===========================================

  def test_cascade_inherits_config
    assert_tk_app("Menubar cascade inherits config", method(:cascade_config_app))
  end

  def cascade_config_app
    require 'tk'
    require 'tk/menubar'

    errors = []

    menu_spec = [
      [['File', 0],
        ['Recent', [
          ['File 1', proc{}, 0]
        ], 0]]
    ]

    menubar = TkMenubar.new(nil, menu_spec, 'foreground' => 'green')

    _, menu = menubar[0]
    submenu = menu.entrycget(0, 'menu')

    errors << "submenu should inherit foreground" unless submenu.cget(:foreground) == 'green'

    raise errors.join("\n") unless errors.empty?
  end

  # ===========================================
  # Index access
  # ===========================================

  def test_index_access
    assert_tk_app("Menubar index access", method(:index_access_app))
  end

  def index_access_app
    require 'tk'
    require 'tk/menubar'

    errors = []

    menu_spec = [
      [['File', 0], ['Open', proc{}, 0]],
      [['Edit', 0], ['Cut', proc{}, 0]],
      [['Help', 0], ['About', proc{}, 0]]
    ]

    menubar = TkMenubar.new(nil, menu_spec)

    errors << "[0] should return array" unless menubar[0].is_a?(Array)
    errors << "[1] should return array" unless menubar[1].is_a?(Array)
    errors << "[2] should return array" unless menubar[2].is_a?(Array)
    errors << "[3] should be nil" unless menubar[3].nil?

    # Verify we get the right menus
    file_btn, _ = menubar[0]
    edit_btn, _ = menubar[1]
    help_btn, _ = menubar[2]

    errors << "first menu should be File" unless file_btn.cget(:text) == 'File'
    errors << "second menu should be Edit" unless edit_btn.cget(:text) == 'Edit'
    errors << "third menu should be Help" unless help_btn.cget(:text) == 'Help'

    raise errors.join("\n") unless errors.empty?
  end

  # ===========================================
  # Multiple menus
  # ===========================================

  def test_multiple_menus
    assert_tk_app("Menubar multiple menus", method(:multiple_menus_app))
  end

  def multiple_menus_app
    require 'tk'
    require 'tk/menubar'

    errors = []

    file_clicked = false
    edit_clicked = false

    menu_spec = [
      [['File', 0],
        ['New', proc{ file_clicked = true }, 0]],
      [['Edit', 0],
        ['Undo', proc{ edit_clicked = true }, 0]]
    ]

    menubar = TkMenubar.new(nil, menu_spec)

    _, file_menu = menubar[0]
    _, edit_menu = menubar[1]

    file_menu.invoke(0)
    errors << "File menu command should work" unless file_clicked

    edit_menu.invoke(0)
    errors << "Edit menu command should work" unless edit_clicked

    raise errors.join("\n") unless errors.empty?
  end
end
