# frozen_string_literal: true

# Test for TkDialog and related dialog classes
# These wrap the Tcl/Tk tk_dialog command

require_relative '../test_helper'
require_relative '../tk_test_helper'

class TestTkDialog < Minitest::Test
  include TkTestHelper

  def test_dialog_obj_creation
    assert_tk_app("TkDialogObj creation", method(:dialog_obj_creation_app))
  end

  def dialog_obj_creation_app
    require 'tk'
    require 'tk/dialog'

    errors = []

    # Create a custom dialog subclass for testing
    dialog_class = Class.new(TkDialogObj) do
      def title
        "Test Dialog"
      end

      def message
        "This is a test message"
      end

      def bitmap
        "info"
      end

      def default_button
        0
      end

      def buttons
        ["OK", "Cancel"]
      end
    end

    # Create but don't show (TkDialogObj doesn't auto-show)
    dialog = dialog_class.new(root)
    errors << "dialog creation failed" if dialog.nil?

    # Value should be nil before showing
    errors << "value should be nil before show" unless dialog.value.nil?

    # Name should be nil before showing
    errors << "name should be nil before show" unless dialog.name.nil?

    raise "TkDialogObj test failures:\n  " + errors.join("\n  ") unless errors.empty?
  end

  def test_dialog_with_hash_config
    assert_tk_app("TkDialogObj hash config", method(:dialog_hash_config_app))
  end

  def dialog_hash_config_app
    require 'tk'
    require 'tk/dialog'

    errors = []

    # Create dialog with hash configuration
    dialog = TkDialogObj.new(root,
      'title' => 'Hash Config Dialog',
      'message' => 'Configured via hash',
      'bitmap' => 'question',
      'buttons' => ['Yes', 'No', 'Cancel'],
      'default' => 1
    )

    errors << "hash config dialog creation failed" if dialog.nil?

    raise "TkDialogObj hash config test failures:\n  " + errors.join("\n  ") unless errors.empty?
  end

  def test_dialog_button_array_config
    assert_tk_app("TkDialogObj button array", method(:dialog_button_array_app))
  end

  def dialog_button_array_app
    require 'tk'
    require 'tk/dialog'

    errors = []

    # Buttons can be array of [name, config_hash] pairs
    dialog = TkDialogObj.new(root,
      'title' => 'Button Array Test',
      'message' => 'Testing button configurations',
      'bitmap' => 'info',
      'buttons' => [
        ['OK', {foreground: 'green'}],
        ['Cancel', {foreground: 'red'}]
      ],
      'default' => 0
    )

    errors << "button array dialog creation failed" if dialog.nil?

    raise "TkDialogObj button array test failures:\n  " + errors.join("\n  ") unless errors.empty?
  end

  def test_warning_dialog_creation
    assert_tk_app("TkWarningObj creation", method(:warning_dialog_app))
  end

  def warning_dialog_app
    require 'tk'
    require 'tk/dialog'

    errors = []

    # TkWarningObj is a pre-configured warning dialog
    warning = TkWarningObj.new(root, "This is a warning message")
    errors << "warning dialog creation failed" if warning.nil?

    # Can also create without parent
    warning2 = TkWarningObj.new("Warning without parent")
    errors << "warning dialog without parent failed" if warning2.nil?

    raise "TkWarningObj test failures:\n  " + errors.join("\n  ") unless errors.empty?
  end

  def test_dialog_class_exists
    assert_tk_app("Dialog classes exist", method(:dialog_classes_app))
  end

  def dialog_classes_app
    require 'tk'
    require 'tk/dialog'

    errors = []

    # Verify all dialog classes are defined
    errors << "TkDialogObj not defined" unless defined?(TkDialogObj)
    errors << "TkDialog not defined" unless defined?(TkDialog)
    errors << "TkDialog2 not defined" unless defined?(TkDialog2)
    errors << "TkWarningObj not defined" unless defined?(TkWarningObj)
    errors << "TkWarning not defined" unless defined?(TkWarning)
    errors << "TkWarning2 not defined" unless defined?(TkWarning2)

    # TkDialog2 should be alias for TkDialogObj
    errors << "TkDialog2 should equal TkDialogObj" unless TkDialog2 == TkDialogObj

    # TkWarning2 should be alias for TkWarningObj
    errors << "TkWarning2 should equal TkWarningObj" unless TkWarning2 == TkWarningObj

    # TkDialog should inherit from TkDialogObj
    errors << "TkDialog should inherit TkDialogObj" unless TkDialog < TkDialogObj

    # TkWarning should inherit from TkWarningObj
    errors << "TkWarning should inherit TkWarningObj" unless TkWarning < TkWarningObj

    raise "Dialog classes test failures:\n  " + errors.join("\n  ") unless errors.empty?
  end

  def test_dialog_show_class_method
    assert_tk_app("TkDialogObj.show class method", method(:dialog_show_method_app))
  end

  def dialog_show_method_app
    require 'tk'
    require 'tk/dialog'

    errors = []

    # Verify show class method exists
    errors << "TkDialogObj.show not defined" unless TkDialogObj.respond_to?(:show)
    errors << "TkDialog.show not defined" unless TkDialog.respond_to?(:show)
    errors << "TkWarningObj.show not defined" unless TkWarningObj.respond_to?(:show)
    errors << "TkWarning.show not defined" unless TkWarning.respond_to?(:show)

    raise "Dialog show method test failures:\n  " + errors.join("\n  ") unless errors.empty?
  end

  def test_dialog_show_and_close_programmatically
    assert_tk_app("TkDialogObj show and close", method(:dialog_show_close_app))
  end

  def dialog_show_close_app
    require 'tk'
    require 'tk/dialog'

    errors = []

    # Create a dialog with known buttons
    dialog = TkDialogObj.new(root,
      'title' => 'Programmatic Close Test',
      'message' => 'This dialog will close automatically',
      'bitmap' => 'info',
      'buttons' => ['OK', 'Cancel', 'Help'],
      'default' => 0
    )

    # Schedule button1 (Cancel) to be invoked after a short delay
    # This will close the dialog programmatically
    Tk.after(50) { Tk.ip_eval("#{dialog.path}.button1 invoke") }

    # Show the dialog - it will block until the scheduled invoke fires
    dialog.show

    # Verify the dialog returned the correct button index
    errors << "value should be 1 (Cancel), got #{dialog.value}" unless dialog.value == 1

    # Verify name returns the button name
    errors << "name should be 'Cancel', got #{dialog.name}" unless dialog.name == "Cancel"

    raise "Dialog show/close test failures:\n  " + errors.join("\n  ") unless errors.empty?
  end

  def test_dialog_show_default_button
    assert_tk_app("TkDialogObj default button", method(:dialog_default_button_app))
  end

  def dialog_default_button_app
    require 'tk'
    require 'tk/dialog'

    errors = []

    # Test clicking button 0 (OK)
    dialog = TkDialogObj.new(root,
      'title' => 'Default Button Test',
      'message' => 'Testing button 0',
      'bitmap' => 'question',
      'buttons' => ['Yes', 'No'],
      'default' => 0
    )

    Tk.after(50) { Tk.ip_eval("#{dialog.path}.button0 invoke") }
    dialog.show

    errors << "clicking button0: value should be 0, got #{dialog.value}" unless dialog.value == 0
    errors << "clicking button0: name should be 'Yes', got #{dialog.name}" unless dialog.name == "Yes"

    raise "Dialog default button test failures:\n  " + errors.join("\n  ") unless errors.empty?
  end
end
