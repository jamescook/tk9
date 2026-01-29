# frozen_string_literal: true

# Tests for TkWindow class - widget introspection, geometry management, grabs
#
# See: lib/tkwindow.rb

require_relative 'test_helper'
require_relative 'tk_test_helper'
require 'tk'

class TestTkWindow < Minitest::Test
  include TkTestHelper

  # --- inspect (L117-124) ---

  def test_inspect
    assert_tk_app("inspect returns widget path info", method(:app_inspect))
  end

  def app_inspect
    require 'tk'

    errors = []

    btn = TkButton.new(root, text: 'Test')
    str = btn.inspect

    errors << "inspect should return String, got #{str.class}" unless str.is_a?(String)
    errors << "inspect should contain @path=, got '#{str}'" unless str.include?('@path=')
    errors << "inspect should contain widget path" unless str.include?('.')

    raise errors.join("\n") unless errors.empty?
  end

  # --- exist? (L126-128) ---

  def test_exist
    assert_tk_app("exist? returns whether widget exists", method(:app_exist))
  end

  def app_exist
    require 'tk'

    errors = []

    btn = TkButton.new(root, text: 'Test')
    errors << "exist? should be true for new widget" unless btn.exist?

    btn.destroy
    errors << "exist? should be false after destroy" if btn.exist?

    raise errors.join("\n") unless errors.empty?
  end

  # --- bind_class (L132-134) ---

  def test_bind_class
    assert_tk_app("bind_class returns binding class", method(:app_bind_class))
  end

  def app_bind_class
    require 'tk'

    errors = []

    btn = TkButton.new(root)
    bc = btn.bind_class

    errors << "bind_class should return a Class, got #{bc.class}" unless bc.is_a?(Class)

    raise errors.join("\n") unless errors.empty?
  end

  # --- database_classname (L136-138) ---

  def test_database_classname
    assert_tk_app("database_classname returns Tk class name", method(:app_database_classname))
  end

  def app_database_classname
    require 'tk'

    errors = []

    btn = TkButton.new(root)
    name = btn.database_classname

    errors << "database_classname should return String, got #{name.class}" unless name.is_a?(String)
    errors << "database_classname for button should be 'Button', got '#{name}'" unless name == 'Button'

    raise errors.join("\n") unless errors.empty?
  end

  # --- grid_in (L237-247) ---

  def test_grid_in
    assert_tk_app("grid_in places widget in target container", method(:app_grid_in))
  end

  def app_grid_in
    require 'tk'

    errors = []

    frame = TkFrame.new(root)
    btn = TkButton.new(root, text: 'Test')

    # Grid the button into the frame
    result = btn.grid_in(frame, row: 0, column: 0)
    errors << "grid_in should return self" unless result == btn

    # Verify it's gridded
    info = TkGrid.info(btn)
    errors << "grid_in should set the 'in' option" unless info && info['in']

    raise errors.join("\n") unless errors.empty?
  end

  # --- grid_anchor (L249-256) ---

  def test_grid_anchor
    assert_tk_app("grid_anchor sets/gets anchor for grid", method(:app_grid_anchor))
  end

  def app_grid_anchor
    require 'tk'

    errors = []

    frame = TkFrame.new(root)

    # Set anchor
    result = frame.grid_anchor('center')
    errors << "grid_anchor setter should return self" unless result == frame

    # Get anchor
    anchor = frame.grid_anchor
    errors << "grid_anchor should return 'center', got '#{anchor}'" unless anchor.to_s == 'center'

    raise errors.join("\n") unless errors.empty?
  end

  # --- grid_forget (L258-262) ---

  def test_grid_forget
    assert_tk_app("grid_forget removes widget from grid", method(:app_grid_forget))
  end

  def app_grid_forget
    require 'tk'

    errors = []

    btn = TkButton.new(root, text: 'Test')
    btn.grid(row: 0, column: 0)

    # Verify it's gridded
    info = TkGrid.info(btn)
    errors << "button should be gridded" unless info

    # Forget it
    result = btn.grid_forget
    errors << "grid_forget should return self" unless result == btn

    # Verify it's no longer gridded
    info = TkGrid.info(btn)
    errors << "button should not be gridded after forget" if info && !info.empty?

    raise errors.join("\n") unless errors.empty?
  end

  # --- place (L381-385) ---

  def test_place
    assert_tk_app("place positions widget with place geometry", method(:app_place))
  end

  def app_place
    require 'tk'

    errors = []

    btn = TkButton.new(root, text: 'Test')
    result = btn.place(x: 10, y: 20)

    errors << "place should return self" unless result == btn

    # Verify placement
    info = TkPlace.info(btn)
    errors << "place should set x coordinate" unless info && info['x']

    raise errors.join("\n") unless errors.empty?
  end

  # --- place_in (L387-397) ---

  def test_place_in
    assert_tk_app("place_in places widget in target container", method(:app_place_in))
  end

  def app_place_in
    require 'tk'

    errors = []

    frame = TkFrame.new(root)
    btn = TkButton.new(root, text: 'Test')

    result = btn.place_in(frame, x: 5, y: 5)
    errors << "place_in should return self" unless result == btn

    info = TkPlace.info(btn)
    errors << "place_in should set the 'in' option" unless info && info['in']

    raise errors.join("\n") unless errors.empty?
  end

  # --- place_forget (L399-403) ---

  def test_place_forget
    assert_tk_app("place_forget removes widget from place", method(:app_place_forget))
  end

  def app_place_forget
    require 'tk'

    errors = []

    btn = TkButton.new(root, text: 'Test')
    btn.place(x: 10, y: 10)

    # Verify placed
    info = TkPlace.info(btn)
    errors << "button should be placed" unless info && !info.empty?

    # Forget it
    result = btn.place_forget
    errors << "place_forget should return self" unless result == btn

    # Verify no longer placed
    info = TkPlace.info(btn)
    errors << "button should not be placed after forget" if info && !info.empty?

    raise errors.join("\n") unless errors.empty?
  end

  # --- grab_status (L501-503) ---

  def test_grab_status
    assert_tk_app("grab_status returns grab state", method(:app_grab_status))
  end

  def app_grab_status
    require 'tk'

    errors = []
    root.deiconify

    btn = TkButton.new(root, text: 'Test')
    btn.pack

    Tk.update

    # Initially no grab
    status = btn.grab_status
    errors << "grab_status should return 'none' initially, got '#{status}'" unless status == 'none' || status.nil?

    raise errors.join("\n") unless errors.empty?
  end

  # --- lower (L505-510) ---

  def test_lower
    assert_tk_app("lower changes stacking order", method(:app_lower))
  end

  def app_lower
    require 'tk'

    errors = []

    btn1 = TkButton.new(root, text: 'Button 1')
    btn2 = TkButton.new(root, text: 'Button 2')
    btn1.place(x: 0, y: 0, width: 100, height: 50)
    btn2.place(x: 0, y: 0, width: 100, height: 50)

    # Lower btn2 below btn1
    result = btn2.lower(btn1)
    errors << "lower should return self" unless result == btn2

    raise errors.join("\n") unless errors.empty?
  end

  # --- raise (L512-517) ---

  def test_raise
    assert_tk_app("raise changes stacking order", method(:app_raise))
  end

  def app_raise
    require 'tk'

    errors = []

    btn1 = TkButton.new(root, text: 'Button 1')
    btn2 = TkButton.new(root, text: 'Button 2')
    btn1.place(x: 0, y: 0, width: 100, height: 50)
    btn2.place(x: 0, y: 0, width: 100, height: 50)

    # Raise btn1 above btn2
    result = btn1.raise(btn2)
    errors << "raise should return self" unless result == btn1

    raise errors.join("\n") unless errors.empty?
  end

  # --- command (L520-528) ---

  def test_command_set
    assert_tk_app("command sets widget command callback", method(:app_command_set))
  end

  def app_command_set
    require 'tk'

    errors = []

    called = false
    btn = TkButton.new(root, text: 'Test')

    # Set command
    btn.command { called = true }

    # Invoke and check
    btn.invoke
    errors << "command callback should have been called" unless called

    raise errors.join("\n") unless errors.empty?
  end

  def test_command_get
    assert_tk_app("command gets widget command", method(:app_command_get))
  end

  def app_command_get
    require 'tk'

    errors = []

    btn = TkButton.new(root, text: 'Test')
    btn.configure(command: proc { 'test' })

    # Get command - returns the callback ID or proc
    cmd = btn.command
    errors << "command should return something, got nil" if cmd.nil?

    raise errors.join("\n") unless errors.empty?
  end
end
