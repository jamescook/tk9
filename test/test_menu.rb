# frozen_string_literal: true

# Tests for Tk::Menu - menu widget
#
# See: https://www.tcl-lang.org/man/tcl/TkCmd/menu.html

require_relative 'test_helper'
require_relative 'tk_test_helper'

class TestTkMenu < Minitest::Test
  include TkTestHelper

  # --- Basic menu creation and entry types ---

  def test_menu_creation
    assert_tk_app("Menu creation", method(:app_menu_creation))
  end

  def app_menu_creation
    require 'tk'
    require 'tk/menu'

    errors = []

    # TIP 161: tearoff default is false in Tcl 9.0, true in 8.6
    menu = TkMenu.new(root, tearoff: false)
    errors << "menu should be TkMenu" unless menu.is_a?(Tk::Menu)
    errors << "menu path should start with ." unless menu.path.start_with?(".")

    raise errors.join("\n") unless errors.empty?
  end

  def test_add_command
    assert_tk_app("Menu add_command", method(:app_add_command))
  end

  def app_add_command
    require 'tk'
    require 'tk/menu'

    errors = []

    menu = TkMenu.new(root, tearoff: false)
    menu.add_command(label: 'Test Command')

    errors << "should have 1 entry" unless menu.index('last') == 0
    errors << "entry type should be command" unless menu.menutype(0) == 'command'

    raise errors.join("\n") unless errors.empty?
  end

  def test_add_separator
    assert_tk_app("Menu add_separator", method(:app_add_separator))
  end

  def app_add_separator
    require 'tk'
    require 'tk/menu'

    errors = []

    menu = TkMenu.new(root, tearoff: false)
    menu.add_command(label: 'Before')
    menu.add_separator
    menu.add_command(label: 'After')

    errors << "should have 3 entries" unless menu.index('last') == 2
    errors << "middle entry should be separator" unless menu.menutype(1) == 'separator'

    raise errors.join("\n") unless errors.empty?
  end

  def test_add_checkbutton
    assert_tk_app("Menu add_checkbutton", method(:app_add_checkbutton))
  end

  def app_add_checkbutton
    require 'tk'
    require 'tk/menu'

    errors = []

    menu = TkMenu.new(root, tearoff: false)
    var = TkVariable.new(false)
    menu.add_checkbutton(label: 'Check Me', variable: var)

    errors << "entry type should be checkbutton" unless menu.menutype(0) == 'checkbutton'

    raise errors.join("\n") unless errors.empty?
  end

  def test_add_radiobutton
    assert_tk_app("Menu add_radiobutton", method(:app_add_radiobutton))
  end

  def app_add_radiobutton
    require 'tk'
    require 'tk/menu'

    errors = []

    menu = TkMenu.new(root, tearoff: false)
    var = TkVariable.new("opt1")
    menu.add_radiobutton(label: 'Option 1', variable: var, value: 'opt1')
    menu.add_radiobutton(label: 'Option 2', variable: var, value: 'opt2')

    errors << "first entry should be radiobutton" unless menu.menutype(0) == 'radiobutton'
    errors << "second entry should be radiobutton" unless menu.menutype(1) == 'radiobutton'

    raise errors.join("\n") unless errors.empty?
  end

  def test_add_cascade
    assert_tk_app("Menu add_cascade", method(:app_add_cascade))
  end

  def app_add_cascade
    require 'tk'
    require 'tk/menu'

    errors = []

    menu = TkMenu.new(root, tearoff: false)
    submenu = TkMenu.new(menu, tearoff: false)
    submenu.add_command(label: 'Sub Item')

    menu.add_cascade(label: 'Submenu', menu: submenu)

    errors << "entry type should be cascade" unless menu.menutype(0) == 'cascade'

    raise errors.join("\n") unless errors.empty?
  end

  # --- Entry manipulation ---

  def test_insert
    assert_tk_app("Menu insert", method(:app_insert))
  end

  def app_insert
    require 'tk'
    require 'tk/menu'

    errors = []

    menu = TkMenu.new(root, tearoff: false)
    menu.add_command(label: 'First')
    menu.add_command(label: 'Third')

    # Insert at index 1 (between First and Third)
    menu.insert(1, 'command', label: 'Second')

    errors << "should have 3 entries" unless menu.index('last') == 2
    label = menu.entrycget(1, :label)
    errors << "inserted entry should be 'Second', got '#{label}'" unless label == 'Second'

    raise errors.join("\n") unless errors.empty?
  end

  def test_delete
    assert_tk_app("Menu delete", method(:app_delete))
  end

  def app_delete
    require 'tk'
    require 'tk/menu'

    errors = []

    menu = TkMenu.new(root, tearoff: false)
    menu.add_command(label: 'One')
    menu.add_command(label: 'Two')
    menu.add_command(label: 'Three')

    # Delete middle entry
    menu.delete(1)

    errors << "should have 2 entries after delete" unless menu.index('last') == 1
    label = menu.entrycget(1, :label)
    errors << "remaining should be 'Three', got '#{label}'" unless label == 'Three'

    raise errors.join("\n") unless errors.empty?
  end

  def test_delete_range
    assert_tk_app("Menu delete range", method(:app_delete_range))
  end

  def app_delete_range
    require 'tk'
    require 'tk/menu'

    errors = []

    menu = TkMenu.new(root, tearoff: false)
    menu.add_command(label: 'One')
    menu.add_command(label: 'Two')
    menu.add_command(label: 'Three')
    menu.add_command(label: 'Four')

    # Delete entries 1 through 2 (Two and Three)
    menu.delete(1, 2)

    errors << "should have 2 entries after range delete" unless menu.index('last') == 1
    label = menu.entrycget(1, :label)
    errors << "remaining should be 'Four', got '#{label}'" unless label == 'Four'

    raise errors.join("\n") unless errors.empty?
  end

  # --- Index and position ---

  def test_index
    assert_tk_app("Menu index", method(:app_index))
  end

  def app_index
    require 'tk'
    require 'tk/menu'

    errors = []

    menu = TkMenu.new(root, tearoff: false)
    menu.add_command(label: 'First')
    menu.add_command(label: 'Second')
    menu.add_command(label: 'Third')

    # Index by number
    errors << "index(0) should be 0" unless menu.index(0) == 0
    errors << "index('last') should be 2" unless menu.index('last') == 2
    errors << "index('end') should be 2" unless menu.index('end') == 2

    raise errors.join("\n") unless errors.empty?
  end

  def test_xposition_yposition
    assert_tk_app("Menu xposition/yposition", method(:app_positions))
  end

  def app_positions
    require 'tk'
    require 'tk/menu'

    errors = []

    menu = TkMenu.new(root, tearoff: false)
    menu.add_command(label: 'Item')

    # These return pixel positions - just verify they return numbers
    x = menu.xposition(0)
    y = menu.yposition(0)

    errors << "xposition should be Integer, got #{x.class}" unless x.is_a?(Integer)
    errors << "yposition should be Integer, got #{y.class}" unless y.is_a?(Integer)

    raise errors.join("\n") unless errors.empty?
  end

  # --- Entry configuration ---

  def test_entryconfigure
    assert_tk_app("Menu entryconfigure", method(:app_entryconfigure))
  end

  def app_entryconfigure
    require 'tk'
    require 'tk/menu'

    errors = []

    menu = TkMenu.new(root, tearoff: false)
    menu.add_command(label: 'Original')

    # Change label
    menu.entryconfigure(0, label: 'Changed')
    label = menu.entrycget(0, :label)

    errors << "label should be 'Changed', got '#{label}'" unless label == 'Changed'

    raise errors.join("\n") unless errors.empty?
  end

  # --- Commands ---

  def test_postcommand
    assert_tk_app("Menu postcommand", method(:app_postcommand))
  end

  def app_postcommand
    require 'tk'
    require 'tk/menu'

    errors = []

    menu = TkMenu.new(root, tearoff: false)
    menu.postcommand { }  # callback not invoked in this test

    # Just verify it configures without error
    errors << "postcommand should accept block" unless menu

    raise errors.join("\n") unless errors.empty?
  end

  def test_tearoffcommand
    assert_tk_app("Menu tearoffcommand", method(:app_tearoffcommand))
  end

  def app_tearoffcommand
    require 'tk'
    require 'tk/menu'

    errors = []

    menu = TkMenu.new(root, tearoff: true)
    menu.tearoffcommand { |m, t| }

    # Just verify it configures without error
    errors << "tearoffcommand should accept block" unless menu

    raise errors.join("\n") unless errors.empty?
  end

  # --- Clone menu ---

  def test_clone_menu
    assert_tk_app("Menu clone", method(:app_clone_menu))
  end

  def app_clone_menu
    require 'tk'
    require 'tk/menu'

    errors = []

    menu = TkMenu.new(root, tearoff: false)
    menu.add_command(label: 'Item 1')
    menu.add_command(label: 'Item 2')

    clone = menu.clone_menu
    errors << "clone should be MenuClone" unless clone.is_a?(Tk::MenuClone)
    errors << "clone should have same entries" unless clone.index('last') == 1
    errors << "clone source_menu should be original" unless clone.source_menu == menu

    raise errors.join("\n") unless errors.empty?
  end

  # --- Activate ---

  def test_activate
    assert_tk_app("Menu activate", method(:app_activate))
  end

  def app_activate
    require 'tk'
    require 'tk/menu'

    errors = []

    menu = TkMenu.new(root, tearoff: false)
    menu.add_command(label: 'Item')

    # activate returns self for chaining
    result = menu.activate(0)
    errors << "activate should return self" unless result == menu

    raise errors.join("\n") unless errors.empty?
  end

  # --- Invoke ---

  def test_invoke
    assert_tk_app("Menu invoke", method(:app_invoke))
  end

  def app_invoke
    require 'tk'
    require 'tk/menu'

    errors = []

    invoked = false
    menu = TkMenu.new(root, tearoff: false)
    menu.add_command(label: 'Click Me', command: proc { invoked = true })

    menu.invoke(0)
    errors << "command should have been invoked" unless invoked

    raise errors.join("\n") unless errors.empty?
  end

  # --- Menubutton ---

  def test_menubutton
    assert_tk_app("Menubutton widget", method(:app_menubutton))
  end

  def app_menubutton
    require 'tk'
    require 'tk/menu'

    errors = []

    mb = TkMenubutton.new(root, text: 'File')
    errors << "menubutton should be TkMenubutton" unless mb.is_a?(Tk::Menubutton)

    menu = TkMenu.new(mb, tearoff: false)
    menu.add_command(label: 'New')
    mb.menu(menu)

    errors << "menubutton should have menu configured" unless mb.cget(:menu)

    raise errors.join("\n") unless errors.empty?
  end

  # --- Post/unpost ---

  def test_unpost
    assert_tk_app("Menu unpost", method(:app_unpost))
  end

  def app_unpost
    require 'tk'
    require 'tk/menu'

    errors = []

    menu = TkMenu.new(root, tearoff: false)
    menu.add_command(label: 'Item')

    # unpost returns self
    result = menu.unpost
    errors << "unpost should return self" unless result == menu

    raise errors.join("\n") unless errors.empty?
  end

  # --- Postcascade ---

  def test_postcascade
    assert_tk_app("Menu postcascade", method(:app_postcascade))
  end

  def app_postcascade
    require 'tk'
    require 'tk/menu'

    errors = []

    menu = TkMenu.new(root, tearoff: false)
    submenu = TkMenu.new(menu, tearoff: false)
    submenu.add_command(label: 'Sub Item')
    menu.add_cascade(label: 'Cascade', menu: submenu)

    # postcascade returns self
    result = menu.postcascade(0)
    errors << "postcascade should return self" unless result == menu

    raise errors.join("\n") unless errors.empty?
  end
end
