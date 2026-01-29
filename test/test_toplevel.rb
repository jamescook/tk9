# frozen_string_literal: true

# Tests for Tk::Toplevel (lib/tk/toplevel.rb)
# See: https://www.tcl-lang.org/man/tcl/TkCmd/toplevel.html

require_relative 'test_helper'
require_relative 'tk_test_helper'

class TestToplevel < Minitest::Test
  include TkTestHelper

  # --- Basic toplevel creation ---

  def test_toplevel_create
    assert_tk_app("Toplevel create", method(:app_toplevel_create))
  end

  def app_toplevel_create
    require 'tk'
    require 'tk/toplevel'

    errors = []

    top = Tk::Toplevel.new(root)
    Tk.update
    errors << "toplevel should exist" unless top.winfo_exist?
    errors << "toplevel should be a TkWindow" unless top.is_a?(TkWindow)

    top.destroy
    raise errors.join("\n") unless errors.empty?
  end

  # --- Toplevel with hash options ---

  def test_toplevel_with_hash_options
    assert_tk_app("Toplevel with hash options", method(:app_toplevel_hash_options))
  end

  def app_toplevel_hash_options
    require 'tk'
    require 'tk/toplevel'

    errors = []

    top = Tk::Toplevel.new(width: 300, height: 200, background: 'red')
    Tk.update

    # Verify options were set
    w = top.cget('width')
    errors << "width should be 300, got #{w}" unless w == 300

    h = top.cget('height')
    errors << "height should be 200, got #{h}" unless h == 200

    bg = top.cget('background')
    errors << "background should contain red" unless bg.to_s.include?('red') || bg.to_s == '#ff0000'

    top.destroy
    raise errors.join("\n") unless errors.empty?
  end

  # --- WM_PROPERTIES shim: cget ---

  def test_toplevel_cget_wm_property
    assert_tk_app("Toplevel cget wm property", method(:app_toplevel_cget_wm))
  end

  def app_toplevel_cget_wm
    require 'tk'
    require 'tk/toplevel'

    errors = []

    top = Tk::Toplevel.new
    top.title("Test Title")

    # cget should route 'title' to wm title
    title = top.cget('title')
    errors << "cget('title') should return 'Test Title', got '#{title}'" unless title == "Test Title"

    # Test other wm properties
    top.iconname("TestIcon")
    iconname = top.cget('iconname')
    errors << "cget('iconname') should return 'TestIcon', got '#{iconname}'" unless iconname == "TestIcon"

    top.destroy
    raise errors.join("\n") unless errors.empty?
  end

  # --- WM_PROPERTIES shim: configure ---

  def test_toplevel_configure_wm_property
    assert_tk_app("Toplevel configure wm property", method(:app_toplevel_configure_wm))
  end

  def app_toplevel_configure_wm
    require 'tk'
    require 'tk/toplevel'

    errors = []

    top = Tk::Toplevel.new

    # configure with wm property
    top.configure('title', "New Title")
    errors << "title should be 'New Title'" unless top.title == "New Title"

    # configure with hash containing both wm and real options
    top.configure(title: "Hash Title", background: 'blue')
    errors << "title should be 'Hash Title'" unless top.title == "Hash Title"
    bg = top.cget('background')
    errors << "background should be blue-ish" unless bg.to_s.include?('blue') || bg.to_s == '#0000ff'

    top.destroy
    raise errors.join("\n") unless errors.empty?
  end

  # --- WM_PROPERTIES shim: configinfo ---

  def test_toplevel_configinfo_wm_property
    assert_tk_app("Toplevel configinfo wm property", method(:app_toplevel_configinfo_wm))
  end

  def app_toplevel_configinfo_wm
    require 'tk'
    require 'tk/toplevel'

    errors = []

    top = Tk::Toplevel.new
    top.title("ConfigInfo Test")

    # configinfo for specific wm property
    info = top.configinfo('title')
    errors << "configinfo('title') should be array" unless info.is_a?(Array)
    errors << "configinfo('title') value should be 'ConfigInfo Test'" unless info.last == "ConfigInfo Test"

    # Full configinfo should include wm properties
    all_info = top.configinfo
    errors << "full configinfo should be array" unless all_info.is_a?(Array)
    title_entry = all_info.find { |e| e[0] == 'title' }
    errors << "full configinfo should include title entry" unless title_entry

    top.destroy
    raise errors.join("\n") unless errors.empty?
  end

  # --- specific_class method ---

  def test_toplevel_specific_class
    assert_tk_app("Toplevel specific_class", method(:app_toplevel_specific_class))
  end

  def app_toplevel_specific_class
    require 'tk'
    require 'tk/toplevel'

    errors = []

    # Default class is 'Toplevel'
    top = Tk::Toplevel.new
    errors << "specific_class should be 'Toplevel'" unless top.specific_class == 'Toplevel'
    top.destroy

    # Custom class name
    top2 = Tk::Toplevel.new(classname: 'MyCustomClass')
    errors << "specific_class should be 'MyCustomClass', got '#{top2.specific_class}'" unless top2.specific_class == 'MyCustomClass'
    top2.destroy

    raise errors.join("\n") unless errors.empty?
  end

  # --- Initialization with wm options ---

  def test_toplevel_init_with_wm_options
    assert_tk_app("Toplevel init with wm options", method(:app_toplevel_init_wm))
  end

  def app_toplevel_init_wm
    require 'tk'
    require 'tk/toplevel'

    errors = []

    # Initialize with title (wm property)
    top = Tk::Toplevel.new(title: "Init Title", iconname: "InitIcon")
    Tk.update

    errors << "title should be 'Init Title'" unless top.title == "Init Title"
    errors << "iconname should be 'InitIcon'" unless top.iconname == "InitIcon"

    top.destroy
    raise errors.join("\n") unless errors.empty?
  end

  # --- add_menu method ---

  def test_toplevel_add_menu
    assert_tk_app("Toplevel add_menu", method(:app_toplevel_add_menu))
  end

  def app_toplevel_add_menu
    require 'tk'
    require 'tk/toplevel'

    errors = []

    top = Tk::Toplevel.new(root)
    Tk.update

    # Add a menu - format is [menubutton_info, entry_info, entry_info, ...]
    # menubutton_info: [text, underline]
    # entry_info: [label, command, underline]
    menu_info = [
      ['File', 0],         # menubutton: text='File', underline=0
      ['Open', proc { }],  # command entry
      ['Exit', proc { }]   # command entry
    ]
    top.add_menu(menu_info)

    # Verify menu was added
    menu = top.menu
    errors << "menu should be set after add_menu" unless menu

    top.destroy
    raise errors.join("\n") unless errors.empty?
  end

  # --- add_menubar method ---

  def test_toplevel_add_menubar
    assert_tk_app("Toplevel add_menubar", method(:app_toplevel_add_menubar))
  end

  def app_toplevel_add_menubar
    require 'tk'
    require 'tk/toplevel'

    errors = []

    top = Tk::Toplevel.new(root)
    Tk.update

    # Add a menubar with multiple menus
    # menu_spec is array of menu_info arrays
    # Each menu_info: [menubutton_info, entry_info, entry_info, ...]
    menu_spec = [
      [['File', 0],      # menubutton
        ['New', proc { }],   # command entry
        ['Open', proc { }]], # command entry
      [['Edit', 0],      # menubutton
        ['Cut', proc { }],   # command entry
        ['Copy', proc { }]]  # command entry
    ]
    result = top.add_menubar(menu_spec)

    # Should return the menu
    errors << "add_menubar should return menu" unless result

    # Menu should be set
    menu = top.menu
    errors << "menu should be set after add_menubar" unless menu

    top.destroy
    raise errors.join("\n") unless errors.empty?
  end

  # --- Class methods ---

  def test_toplevel_database_class
    assert_tk_app("Toplevel database_class", method(:app_toplevel_database_class))
  end

  def app_toplevel_database_class
    require 'tk'
    require 'tk/toplevel'

    errors = []

    # For Tk::Toplevel itself, returns self
    db_class = Tk::Toplevel.database_class
    errors << "database_class should return Tk::Toplevel" unless db_class == Tk::Toplevel

    db_name = Tk::Toplevel.database_classname
    errors << "database_classname should be 'Tk::Toplevel'" unless db_name == 'Tk::Toplevel'

    raise errors.join("\n") unless errors.empty?
  end

  def test_toplevel_class_bind
    assert_tk_app("Toplevel class bind", method(:app_toplevel_class_bind))
  end

  def app_toplevel_class_bind
    require 'tk'
    require 'tk/toplevel'

    errors = []

    # Class-level binding
    Tk::Toplevel.bind('Enter') { }

    # Get binding info
    info = Tk::Toplevel.bindinfo('Enter')
    errors << "bindinfo should return binding" unless info && !info.empty?

    # bind_append should add to existing binding
    Tk::Toplevel.bind_append('Enter') { }
    info_append = Tk::Toplevel.bindinfo('Enter')
    errors << "bindinfo after bind_append should exist" unless info_append && !info_append.empty?

    # Remove binding - just verify it doesn't raise
    Tk::Toplevel.bind_remove('Enter')

    raise errors.join("\n") unless errors.empty?
  end

  # --- Toplevel with screen parameter ---

  def test_toplevel_with_screen
    assert_tk_app("Toplevel with screen parameter", method(:app_toplevel_with_screen))
  end

  def app_toplevel_with_screen
    require 'tk'
    require 'tk/toplevel'

    errors = []

    # Get current screen
    current_screen = root.winfo_screen

    # Create toplevel on same screen using hash syntax
    top = Tk::Toplevel.new(root, screen: current_screen)
    Tk.update
    errors << "toplevel should exist" unless top.winfo_exist?

    # Verify it's on the right screen
    top_screen = top.winfo_screen
    errors << "toplevel screen should match #{current_screen}, got #{top_screen}" unless top_screen == current_screen

    top.destroy
    raise errors.join("\n") unless errors.empty?
  end

  # --- Toplevel with classname ---

  def test_toplevel_with_classname
    assert_tk_app("Toplevel with classname", method(:app_toplevel_with_classname))
  end

  def app_toplevel_with_classname
    require 'tk'
    require 'tk/toplevel'

    errors = []

    # Using classname in hash
    top = Tk::Toplevel.new(classname: 'MyApp')
    classname = top.specific_class
    errors << "classname should be 'MyApp', got '#{classname}'" unless classname == 'MyApp'

    # Verify winfo class
    winfo_class = top.winfo_class
    errors << "winfo_class should be 'MyApp', got '#{winfo_class}'" unless winfo_class == 'MyApp'

    top.destroy
    raise errors.join("\n") unless errors.empty?
  end

  # --- TkCommandNames and WidgetClassName constants ---

  def test_toplevel_constants
    assert_tk_app("Toplevel constants", method(:app_toplevel_constants))
  end

  def app_toplevel_constants
    require 'tk'
    require 'tk/toplevel'

    errors = []

    errors << "TkCommandNames should include 'toplevel'" unless Tk::Toplevel::TkCommandNames.include?('toplevel')
    errors << "WidgetClassName should be 'Toplevel'" unless Tk::Toplevel::WidgetClassName == 'Toplevel'

    raise errors.join("\n") unless errors.empty?
  end

  # --- WM_PROPERTIES constant ---

  def test_wm_properties_constant
    assert_tk_app("WM_PROPERTIES constant", method(:app_wm_properties_constant))
  end

  def app_wm_properties_constant
    require 'tk'
    require 'tk/toplevel'

    errors = []

    props = Tk::Toplevel::WM_PROPERTIES
    errors << "WM_PROPERTIES should be an array" unless props.is_a?(Array)
    errors << "WM_PROPERTIES should include 'title'" unless props.include?('title')
    errors << "WM_PROPERTIES should include 'geometry'" unless props.include?('geometry')
    errors << "WM_PROPERTIES should include 'state'" unless props.include?('state')
    errors << "WM_PROPERTIES should include 'resizable'" unless props.include?('resizable')
    errors << "WM_PROPERTIES should be frozen" unless props.frozen?

    raise errors.join("\n") unless errors.empty?
  end

  # --- Configure with array value (for wm properties that take multiple args) ---

  def test_toplevel_configure_array_value
    assert_tk_app("Toplevel configure with array value", method(:app_toplevel_configure_array))
  end

  def app_toplevel_configure_array
    require 'tk'
    require 'tk/toplevel'

    errors = []

    top = Tk::Toplevel.new

    # minsize takes two values - test as single property
    top.configure('minsize', [100, 80])
    Tk.update

    min = top.minsize
    errors << "minsize should be [100, 80], got #{min.inspect}" unless min == [100, 80]

    # Also test via hash
    top.configure(maxsize: [400, 300])
    max = top.maxsize
    errors << "maxsize should be [400, 300], got #{max.inspect}" unless max == [400, 300]

    top.destroy
    raise errors.join("\n") unless errors.empty?
  end

  # --- TkToplevel alias ---

  def test_tktoplevel_alias
    assert_tk_app("TkToplevel alias", method(:app_tktoplevel_alias))
  end

  def app_tktoplevel_alias
    require 'tk'
    require 'tk/toplevel'

    errors = []

    # TkToplevel should be defined as alias
    errors << "TkToplevel should be defined" unless defined?(TkToplevel)
    errors << "TkToplevel should equal Tk::Toplevel" unless TkToplevel == Tk::Toplevel

    # Should be able to create via alias
    top = TkToplevel.new(root)
    Tk.update
    errors << "TkToplevel.new should create toplevel" unless top.winfo_exist?
    top.destroy

    raise errors.join("\n") unless errors.empty?
  end
end
