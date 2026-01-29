# frozen_string_literal: true
require_relative 'test_helper'
require_relative 'tk_test_helper'

# Tests for lib/tk/validation.rb
# TkValidation module provides entry/spinbox validation support
class TestTkValidation < Minitest::Test
  include TkTestHelper

  # --- TkValidateCommand::ValidateArgs constants ---

  def test_validate_args_key_table
    require 'tk/validation'

    key_tbl = TkValidateCommand::ValidateArgs::KEY_TBL
    assert_includes key_tbl.flatten.compact, :action
    assert_includes key_tbl.flatten.compact, :index
    assert_includes key_tbl.flatten.compact, :current
    assert_includes key_tbl.flatten.compact, :value
    assert_includes key_tbl.flatten.compact, :string
    assert_includes key_tbl.flatten.compact, :widget
    assert_includes key_tbl.flatten.compact, :type
    assert_includes key_tbl.flatten.compact, :triggered
  end

  def test_validate_args_proc_table
    require 'tk/validation'

    proc_tbl = TkValidateCommand::ValidateArgs::PROC_TBL
    # Check that methods/procs are defined for conversions
    assert proc_tbl.any? { |entry| entry.is_a?(Array) && entry[1].respond_to?(:call) }
  end

  def test_validate_args_ret_val
    require 'tk/validation'

    # true returns '1', false returns '0'
    assert_equal '1', TkValidateCommand::ValidateArgs.ret_val(true)
    assert_equal '0', TkValidateCommand::ValidateArgs.ret_val(false)
    assert_equal '0', TkValidateCommand::ValidateArgs.ret_val(nil)
    assert_equal '1', TkValidateCommand::ValidateArgs.ret_val('anything')
  end

  # --- TkValidateCommand._config_keys ---

  def test_config_keys
    require 'tk/validation'

    keys = TkValidateCommand._config_keys
    assert_includes keys, 'vcmd'
    assert_includes keys, 'validatecommand'
    assert_includes keys, 'invcmd'
    assert_includes keys, 'invalidcommand'
    assert_equal 4, keys.size
  end

  # --- TkValidation::ValidateCmd::Action constants ---

  def test_validate_action_constants
    require 'tk/validation'

    assert_equal 1, TkValidation::ValidateCmd::Action::Insert
    assert_equal 0, TkValidation::ValidateCmd::Action::Delete
    assert_equal(-1, TkValidation::ValidateCmd::Action::Others)
    assert_equal(-1, TkValidation::ValidateCmd::Action::Focus)
    assert_equal(-1, TkValidation::ValidateCmd::Action::Forced)
    assert_equal(-1, TkValidation::ValidateCmd::Action::Textvariable)
    assert_equal(-1, TkValidation::ValidateCmd::Action::TextVariable)
  end

  # --- TkValidateCommand initialization and to_eval ---

  def test_validate_command_with_block
    assert_tk_app("ValidateCommand with block", method(:app_validate_command_with_block))
  end

  def app_validate_command_with_block
    require 'tk'
    require 'tk/entry'
    require 'tk/validation'

    errors = []

    vcmd = TkValidateCommand.new { |*args| true }
    id = vcmd.to_eval
    errors << "to_eval should return a string, got #{id.class}" unless id.is_a?(String)
    errors << "to_eval should not be empty" if id.empty?

    raise errors.join("\n") unless errors.empty?
  end

  def test_validate_command_with_proc
    assert_tk_app("ValidateCommand with proc", method(:app_validate_command_with_proc))
  end

  def app_validate_command_with_proc
    require 'tk'
    require 'tk/entry'
    require 'tk/validation'

    errors = []

    my_proc = proc { |*args| args.length > 0 }
    vcmd = TkValidateCommand.new(my_proc)
    id = vcmd.to_eval
    errors << "to_eval should return a string, got #{id.class}" unless id.is_a?(String)
    errors << "to_eval should not be empty" if id.empty?

    raise errors.join("\n") unless errors.empty?
  end

  def test_validate_command_with_string
    assert_tk_app("ValidateCommand with string command", method(:app_validate_command_with_string))
  end

  def app_validate_command_with_string
    require 'tk'
    require 'tk/entry'
    require 'tk/validation'

    errors = []

    # String command is passed through directly
    vcmd = TkValidateCommand.new("my_tcl_proc %P")
    id = vcmd.to_eval
    errors << "to_eval should be 'my_tcl_proc %P', got '#{id}'" unless id == "my_tcl_proc %P"

    raise errors.join("\n") unless errors.empty?
  end

  # --- Entry with validation ---

  def test_entry_with_validatecommand
    assert_tk_app("Entry with validatecommand", method(:app_entry_validatecommand))
  end

  def app_entry_validatecommand
    require 'tk'
    require 'tk/entry'

    errors = []

    valid_called = false
    entry = TkEntry.new(root,
      validate: 'key',
      validatecommand: proc { |*args|
        valid_called = true
        true
      }
    )
    entry.pack

    # Insert text - validation should be called
    entry.insert(0, 'test')

    # Check entry has content
    value = entry.get
    errors << "Entry should have 'test', got '#{value}'" unless value == 'test'

    # Validation should have been called
    errors << "validatecommand should have been called" unless valid_called

    raise errors.join("\n") unless errors.empty?
  end

  def test_entry_with_vcmd_shorthand
    assert_tk_app("Entry with vcmd shorthand", method(:app_entry_vcmd))
  end

  def app_entry_vcmd
    require 'tk'
    require 'tk/entry'

    errors = []

    entry = TkEntry.new(root,
      validate: 'all',
      vcmd: proc { true }
    )
    entry.pack

    # Should be able to insert text (validation passes)
    entry.insert(0, 'hello')
    value = entry.get
    errors << "Entry should have 'hello', got '#{value}'" unless value == 'hello'

    raise errors.join("\n") unless errors.empty?
  end

  def test_entry_validation_rejects_input
    assert_tk_app("Entry validation rejects input", method(:app_entry_rejects))
  end

  def app_entry_rejects
    require 'tk'
    require 'tk/entry'

    errors = []

    # Validation that only allows digits
    entry = TkEntry.new(root,
      validate: 'key',
      validatecommand: proc { |args|
        args.value =~ /^\d*$/
      }
    )
    entry.pack

    # Insert digits - should work
    entry.insert(0, '123')
    value = entry.get
    errors << "Entry should accept digits '123', got '#{value}'" unless value == '123'

    raise errors.join("\n") unless errors.empty?
  end

  def test_entry_invalidcommand
    assert_tk_app("Entry with invalidcommand", method(:app_entry_invalidcommand))
  end

  def app_entry_invalidcommand
    require 'tk'
    require 'tk/entry'

    errors = []

    invalid_called = false
    entry = TkEntry.new(root,
      validate: 'key',
      validatecommand: proc { false },  # Always reject
      invalidcommand: proc {
        invalid_called = true
      }
    )
    entry.pack

    # Try to insert - validation will reject
    entry.insert(0, 'test')

    # Entry should be empty (validation rejected)
    value = entry.get
    errors << "Entry should be empty after rejected input, got '#{value}'" unless value == ''

    # Invalid command should have been called
    errors << "invalidcommand should have been called" unless invalid_called

    raise errors.join("\n") unless errors.empty?
  end

  # --- ValidateConfigure module ---

  def test_validation_class_list
    assert_tk_app("__validation_class_list includes ValidateCmd", method(:app_validation_class_list))
  end

  def app_validation_class_list
    require 'tk'
    require 'tk/entry'

    errors = []

    entry = TkEntry.new(root)
    list = entry.__validation_class_list
    errors << "__validation_class_list should include ValidateCmd" unless list.include?(TkValidation::ValidateCmd)

    raise errors.join("\n") unless errors.empty?
  end

  def test_entry_configure_validation_hash
    assert_tk_app("Entry configure with validation hash", method(:app_entry_configure_validation_hash))
  end

  def app_entry_configure_validation_hash
    require 'tk'
    require 'tk/entry'

    errors = []

    entry = TkEntry.new(root)
    entry.pack

    # Configure with hash containing validation
    entry.configure(
      validate: 'focusout',
      validatecommand: proc { true }
    )

    validate = entry.cget('validate')
    errors << "validate should be 'focusout', got '#{validate}'" unless validate == 'focusout'

    raise errors.join("\n") unless errors.empty?
  end

  def test_entry_vcmd_method
    assert_tk_app("Entry vcmd convenience method", method(:app_entry_vcmd_method))
  end

  def app_entry_vcmd_method
    require 'tk'
    require 'tk/entry'

    errors = []

    entry = TkEntry.new(root)
    entry.pack

    # Use vcmd method to set validation command
    entry.vcmd { true }

    # vcmd() without args should return current command
    # (returns the callback, which is truthy)
    result = entry.vcmd
    errors << "vcmd should return callback, got #{result.inspect}" if result.nil?

    raise errors.join("\n") unless errors.empty?
  end

  def test_entry_validatecommand_method
    assert_tk_app("Entry validatecommand convenience method", method(:app_entry_validatecommand_method))
  end

  def app_entry_validatecommand_method
    require 'tk'
    require 'tk/entry'

    errors = []

    entry = TkEntry.new(root)
    entry.pack

    # Use validatecommand method to set validation command
    entry.validatecommand { true }

    # validatecommand() without args should return current command
    result = entry.validatecommand
    errors << "validatecommand should return callback, got #{result.inspect}" if result.nil?

    raise errors.join("\n") unless errors.empty?
  end

  def test_entry_invcmd_method
    assert_tk_app("Entry invcmd convenience method", method(:app_entry_invcmd_method))
  end

  def app_entry_invcmd_method
    require 'tk'
    require 'tk/entry'

    errors = []

    entry = TkEntry.new(root)
    entry.pack

    # Use invcmd method to set invalid command
    entry.invcmd { puts "invalid" }

    # invcmd() without args should return current command
    result = entry.invcmd
    errors << "invcmd should return callback, got #{result.inspect}" if result.nil?

    raise errors.join("\n") unless errors.empty?
  end

  # --- Validate modes ---

  def test_entry_validate_modes
    assert_tk_app("Entry validate mode options", method(:app_entry_validate_modes))
  end

  def app_entry_validate_modes
    require 'tk'
    require 'tk/entry'

    errors = []

    # Test different validation modes
    modes = ['none', 'focus', 'focusin', 'focusout', 'key', 'all']
    modes.each do |mode|
      entry = TkEntry.new(root, validate: mode)
      actual = entry.cget('validate')
      errors << "validate mode should be '#{mode}', got '#{actual}'" unless actual == mode
      entry.destroy
    end

    raise errors.join("\n") unless errors.empty?
  end

  # --- ValidateCmd with extra args ---

  def test_validate_command_with_subst_args
    assert_tk_app("ValidateCommand with substitution args", method(:app_validate_with_subst_args))
  end

  def app_validate_with_subst_args
    require 'tk'
    require 'tk/entry'
    require 'tk/validation'

    errors = []

    # Create command with specific substitution args
    vcmd = TkValidation::ValidateCmd.new(proc { true }, :value, :action)
    id = vcmd.to_eval
    errors << "to_eval should contain substitution codes" unless id.include?('%')

    raise errors.join("\n") unless errors.empty?
  end

  # --- get_validate_key2class ---

  def test_get_validate_key2class
    assert_tk_app("__get_validate_key2class returns key to class mapping", method(:app_get_validate_key2class))
  end

  def app_get_validate_key2class
    require 'tk'
    require 'tk/entry'

    errors = []

    entry = TkEntry.new(root)
    k2c = entry.__get_validate_key2class

    # Should map validation keys to ValidateCmd class
    errors << "vcmd should map to ValidateCmd" unless k2c['vcmd'] == TkValidation::ValidateCmd
    errors << "validatecommand should map to ValidateCmd" unless k2c['validatecommand'] == TkValidation::ValidateCmd
    errors << "invcmd should map to ValidateCmd" unless k2c['invcmd'] == TkValidation::ValidateCmd
    errors << "invalidcommand should map to ValidateCmd" unless k2c['invalidcommand'] == TkValidation::ValidateCmd

    raise errors.join("\n") unless errors.empty?
  end

  # --- Array form of validation commands ---

  def test_entry_validatecommand_array_form
    assert_tk_app("Entry validatecommand array form", method(:app_entry_validatecommand_array))
  end

  def app_entry_validatecommand_array
    require 'tk'
    require 'tk/entry'

    errors = []

    # Array form: [proc, args...]
    entry = TkEntry.new(root,
      validate: 'key',
      validatecommand: [proc { |args| true }, :value, :action]
    )
    entry.pack

    # Should be able to insert
    entry.insert(0, 'test')
    value = entry.get
    errors << "Entry should have 'test', got '#{value}'" unless value == 'test'

    raise errors.join("\n") unless errors.empty?
  end
end
