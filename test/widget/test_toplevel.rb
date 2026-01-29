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

    # --- Screen option (DSL-declared string) ---
    # Screen is read-only after creation, just verify we can read it
    screen_val = top.cget(:screen)
    errors << "screen should be string" unless screen_val.is_a?(String)

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

    # --- wm_attributes (window manager attributes) ---
    # Test alpha transparency - may not work in headless/Xvfb environments
    # Per Tk docs: "Where not supported, the -alpha value remains at 1.0"
    top.wm_attributes(:alpha, 0.8)
    alpha_val = top.wm_attributes(:alpha).to_f
    if alpha_val == 1.0
      # Environment doesn't support alpha (e.g., Xvfb in Docker) - skip test
      $stderr.puts "Note: alpha transparency not supported in this environment, skipping alpha test"
    else
      errors << "wm_attributes alpha set failed" unless alpha_val.between?(0.79, 0.81)
      # Reset alpha
      top.wm_attributes(:alpha, 1.0)
      errors << "wm_attributes alpha reset failed" unless top.wm_attributes(:alpha).to_f == 1.0
    end

    # Test reading all attributes as hash
    all_attrs = top.wm_attributes
    errors << "wm_attributes should return hash" unless all_attrs.is_a?(Hash)
    errors << "wm_attributes hash should include alpha" unless all_attrs.key?('alpha')

    # --- Menu option val2ruby conversion ---
    # Tests that cget(:menu) returns a TkMenu object, not a string path
    # This exercises __val2ruby_optkeys conversion
    require 'tk/menu'
    menubar = TkMenu.new(top)
    menubar.add_command(label: "File")
    top.configure(menu: menubar)
    retrieved_menu = top.cget(:menu)
    errors << "menu val2ruby should return TkMenu" unless retrieved_menu.is_a?(TkMenu) || retrieved_menu.is_a?(Tk::Menu)
    errors << "menu val2ruby should return same menu" unless retrieved_menu.path == menubar.path

    # Clean up
    top2.destroy

    # Check errors before tk_end
    unless errors.empty?
      top.destroy rescue nil
      raise "Toplevel test failures:\n  " + errors.join("\n  ")
    end

    top.destroy
  end

  # --- WM_PROPERTIES shim tests ---

  def test_toplevel_wm_properties_cget
    assert_tk_app("Toplevel WM properties via cget", method(:app_wm_cget))
  end

  def app_wm_cget
    require 'tk'
    require 'tk/toplevel'

    errors = []

    top = TkToplevel.new(root) { withdraw }

    # cget with wm property should route to wm command
    top.wm_title("Test Title")
    title = top.cget(:title)
    errors << "cget(:title) should return 'Test Title', got #{title.inspect}" unless title == "Test Title"

    # geometry is a wm property - need to deiconify for size to take effect
    top.deiconify
    top.wm_geometry("300x200+100+100")
    Tk.update
    geom = top.cget(:geometry)
    errors << "cget(:geometry) should include '300x200', got #{geom.inspect}" unless geom.include?("300x200")
    top.withdraw

    # state is a wm property
    state = top.cget(:state)
    errors << "cget(:state) should return withdrawn" unless state == "withdrawn"

    top.destroy
    raise errors.join("\n") unless errors.empty?
  end

  def test_toplevel_wm_properties_configure
    assert_tk_app("Toplevel WM properties via configure", method(:app_wm_configure))
  end

  def app_wm_configure
    require 'tk'
    require 'tk/toplevel'

    errors = []

    top = TkToplevel.new(root) { withdraw }

    # configure with wm property should route to wm command
    top.configure(title: "Configured Title")
    title = top.wm_title
    errors << "configure(:title) should set wm title" unless title == "Configured Title"

    # configure with hash containing wm properties
    top.configure(minsize: [200, 150])
    minsize = top.wm_minsize
    errors << "configure minsize should work" unless minsize[0] == 200 && minsize[1] == 150

    # configure with mixed wm and real options
    top.configure(title: "Mixed Test", width: 400, height: 300)
    errors << "mixed configure title" unless top.wm_title == "Mixed Test"
    errors << "mixed configure width" unless top.cget(:width).to_i == 400

    top.destroy
    raise errors.join("\n") unless errors.empty?
  end

  def test_toplevel_wm_properties_configinfo
    assert_tk_app("Toplevel WM properties via configinfo", method(:app_wm_configinfo))
  end

  def app_wm_configinfo
    require 'tk'
    require 'tk/toplevel'

    errors = []

    top = TkToplevel.new(root) { withdraw }
    top.wm_title("ConfigInfo Test")

    # configinfo for specific wm property
    info = top.configinfo(:title)
    errors << "configinfo(:title) should return array" unless info.is_a?(Array)
    errors << "configinfo(:title) should have 5 elements" unless info.size == 5
    errors << "configinfo(:title) value should be title" unless info[4] == "ConfigInfo Test"

    # configinfo for real option
    top.configure(width: 500)
    real_info = top.configinfo(:width)
    errors << "configinfo(:width) should return array" unless real_info.is_a?(Array)

    top.destroy
    raise errors.join("\n") unless errors.empty?
  end

  # --- specific_class tests ---

  def test_toplevel_specific_class
    assert_tk_app("Toplevel specific_class", method(:app_specific_class))
  end

  def app_specific_class
    require 'tk'
    require 'tk/toplevel'

    errors = []

    # Default classname
    top1 = TkToplevel.new(root) { withdraw }
    errors << "default specific_class should be 'Toplevel'" unless top1.specific_class == "Toplevel"
    top1.destroy

    # Custom classname via hash
    top2 = TkToplevel.new(root, classname: "MyCustomClass") { withdraw }
    errors << "custom specific_class should be 'MyCustomClass'" unless top2.specific_class == "MyCustomClass"
    top2.destroy

    # Custom classname via 'class' key
    top3 = TkToplevel.new(root, class: "AnotherClass") { withdraw }
    errors << "class key specific_class should be 'AnotherClass'" unless top3.specific_class == "AnotherClass"
    top3.destroy

    raise errors.join("\n") unless errors.empty?
  end

  # --- add_menu tests ---

  def test_toplevel_add_menu
    assert_tk_app("Toplevel add_menu", method(:app_add_menu))
  end

  def app_add_menu
    require 'tk'
    require 'tk/toplevel'
    require 'tk/menu'

    errors = []

    top = TkToplevel.new(root) { withdraw }

    # add_menu creates a menubutton from spec
    # Format: ['Label', underline_index] for menu title, ['Label', command, underline_index] for items
    menu_info = [['File', 0],
                 ['Open', proc {}, 0],
                 ['Save', proc {}, 0],
                 '---',
                 ['Exit', proc {}, 0]]
    top.add_menu(menu_info)

    # Verify menu was created
    menu = top.cget(:menu)
    errors << "add_menu should create menu" unless menu

    top.destroy
    raise errors.join("\n") unless errors.empty?
  end

  def test_toplevel_add_menubar
    assert_tk_app("Toplevel add_menubar", method(:app_add_menubar))
  end

  def app_add_menubar
    require 'tk'
    require 'tk/toplevel'
    require 'tk/menu'

    errors = []

    top = TkToplevel.new(root) { withdraw }

    # add_menubar creates full menubar from spec array
    # Format: each element is [['MenuTitle', underline], ['Item', cmd, underline], ...]
    menu_spec = [
      [['File', 0], ['New', proc {}, 0], ['Open', proc {}, 0]],
      [['Edit', 0], ['Cut', proc {}, 0], ['Copy', proc {}, 0], ['Paste', proc {}, 0]]
    ]
    result = top.add_menubar(menu_spec)

    # Should return the menu
    errors << "add_menubar should return menu" unless result

    # Verify menu was set
    menu = top.cget(:menu)
    errors << "add_menubar should set menu" unless menu

    top.destroy
    raise errors.join("\n") unless errors.empty?
  end

  # --- database_class methods ---

  def test_toplevel_database_class
    assert_tk_app("Toplevel database_class", method(:app_database_class))
  end

  def app_database_class
    require 'tk'
    require 'tk/toplevel'

    errors = []

    # Base class returns itself
    db_class = Tk::Toplevel.database_class
    errors << "database_class should return class" unless db_class == Tk::Toplevel

    db_name = Tk::Toplevel.database_classname
    errors << "database_classname should be 'Tk::Toplevel'" unless db_name == "Tk::Toplevel"

    raise errors.join("\n") unless errors.empty?
  end

  # --- initialization with wm options ---

  def test_toplevel_init_with_wm_options
    assert_tk_app("Toplevel init with wm options", method(:app_init_wm_options))
  end

  def app_init_wm_options
    require 'tk'
    require 'tk/toplevel'

    errors = []

    # Create toplevel with wm options in hash
    top = TkToplevel.new(root, title: "Init Title", minsize: [300, 200]) { withdraw }

    errors << "init title should be set" unless top.wm_title == "Init Title"

    minsize = top.wm_minsize
    errors << "init minsize should be set" unless minsize[0] == 300 && minsize[1] == 200

    top.destroy
    raise errors.join("\n") unless errors.empty?
  end
end
