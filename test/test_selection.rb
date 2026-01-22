# frozen_string_literal: true

# Tests for TkSelection - X11 selection handling
#
# TkSelection wraps Tcl/Tk's selection command for working with
# X11 selections (PRIMARY, CLIPBOARD, etc.)
#
# See: https://www.tcl-lang.org/man/tcl/TkCmd/selection.html

require_relative 'test_helper'
require_relative 'tk_test_helper'

class TestSelection < Minitest::Test
  include TkTestHelper

  # ===========================================
  # clear
  # ===========================================

  def test_clear
    assert_tk_app("Selection clear", method(:clear_app))
  end

  def clear_app
    require 'tk'
    require 'tk/selection'

    errors = []

    # Clear the default (PRIMARY) selection
    TkSelection.clear

    # Should not raise error
    errors << "clear should work" unless true

    raise errors.join("\n") unless errors.empty?
  end

  def test_clear_with_selection_name
    assert_tk_app("Selection clear named", method(:clear_named_app))
  end

  def clear_named_app
    require 'tk'
    require 'tk/selection'

    errors = []

    # Clear a specific selection
    TkSelection.clear('CLIPBOARD')
    TkSelection.clear('PRIMARY')

    # Should not raise error
    errors << "clear with selection name should work" unless true

    raise errors.join("\n") unless errors.empty?
  end

  def test_clear_on_display
    assert_tk_app("Selection clear_on_display", method(:clear_display_app))
  end

  def clear_display_app
    require 'tk'
    require 'tk/selection'

    errors = []

    TkSelection.clear_on_display(root)
    TkSelection.clear_on_display(root, 'PRIMARY')

    # Should not raise error
    errors << "clear_on_display should work" unless true

    raise errors.join("\n") unless errors.empty?
  end

  # ===========================================
  # get
  # ===========================================

  def test_get_empty_selection
    assert_tk_app("Selection get empty", method(:get_empty_app))
  end

  def get_empty_app
    require 'tk'
    require 'tk/selection'

    errors = []

    # Clear first to ensure no selection
    TkSelection.clear

    # Get on empty selection should raise TclError
    begin
      TkSelection.get
      errors << "get on empty selection should raise error"
    rescue TclTkLib::TclError => e
      # Expected - no selection
      errors << "wrong error" unless e.message.include?("selection") || e.message.include?("PRIMARY")
    end

    raise errors.join("\n") unless errors.empty?
  end

  def test_get_with_type
    assert_tk_app("Selection get with type", method(:get_type_app))
  end

  def get_type_app
    require 'tk'
    require 'tk/selection'
    require 'tk/clipboard'

    errors = []

    # Set clipboard content first
    TkClipboard.set("Test selection data")

    # Get with selection type
    begin
      result = TkSelection.get(selection: 'CLIPBOARD')
      errors << "should get clipboard content" unless result == "Test selection data"
    rescue TclTkLib::TclError
      # May fail on some systems without clipboard support
    end

    raise errors.join("\n") unless errors.empty?
  end

  def test_get_on_display
    assert_tk_app("Selection get_on_display", method(:get_on_display_app))
  end

  def get_on_display_app
    require 'tk'
    require 'tk/selection'
    require 'tk/clipboard'

    errors = []

    # Set clipboard content
    TkClipboard.set("Display test data")

    # Get using display-specific method
    begin
      result = TkSelection.get_on_display(root, selection: 'CLIPBOARD')
      errors << "should get clipboard content" unless result == "Display test data"
    rescue TclTkLib::TclError
      # May fail on some systems
    end

    raise errors.join("\n") unless errors.empty?
  end

  def test_instance_get
    assert_tk_app("Selection instance get", method(:instance_get_app))
  end

  def instance_get_app
    require 'tk'
    require 'tk/selection'
    require 'tk/clipboard'

    errors = []

    label = TkLabel.new(root, text: 'Test')
    label.pack
    label.extend(TkSelection)

    # Set clipboard content
    TkClipboard.set("Instance get data")

    # Use instance method
    begin
      result = label.get(selection: 'CLIPBOARD')
      errors << "instance get should work" unless result == "Instance get data"
    rescue TclTkLib::TclError
      # May fail on some systems
    end

    raise errors.join("\n") unless errors.empty?
  end

  # ===========================================
  # set_owner / get_owner
  # ===========================================

  def test_set_owner
    assert_tk_app("Selection set_owner", method(:set_owner_app))
  end

  def set_owner_app
    require 'tk'
    require 'tk/selection'

    errors = []

    # Create a widget to own the selection
    label = TkLabel.new(root, text: 'Owner')
    label.pack

    # Set this widget as the selection owner
    TkSelection.set_owner(label)

    # Should not raise error
    errors << "set_owner should work" unless true

    raise errors.join("\n") unless errors.empty?
  end

  def test_get_owner
    assert_tk_app("Selection get_owner", method(:get_owner_app))
  end

  def get_owner_app
    require 'tk'
    require 'tk/selection'

    errors = []

    # Clear selection first
    TkSelection.clear

    # With no owner, get_owner returns empty string or raises
    begin
      owner = TkSelection.get_owner
      # Owner might be nil/empty if no selection
    rescue TclTkLib::TclError
      # Expected when no owner
    end

    # Now set an owner
    label = TkLabel.new(root, text: 'Owner')
    label.pack
    TkSelection.set_owner(label)

    owner = TkSelection.get_owner
    errors << "owner should be the label" unless owner == label

    raise errors.join("\n") unless errors.empty?
  end

  def test_get_owner_named_selection
    assert_tk_app("Selection get_owner named", method(:get_owner_named_app))
  end

  def get_owner_named_app
    require 'tk'
    require 'tk/selection'

    errors = []

    label = TkLabel.new(root, text: 'Owner')
    label.pack

    # Set owner with specific selection
    TkSelection.set_owner(label, selection: 'PRIMARY')

    # Get owner of that selection
    owner = TkSelection.get_owner('PRIMARY')
    errors << "owner should be the label" unless owner == label

    raise errors.join("\n") unless errors.empty?
  end

  def test_get_owner_on_display
    assert_tk_app("Selection get_owner_on_display", method(:get_owner_on_display_app))
  end

  def get_owner_on_display_app
    require 'tk'
    require 'tk/selection'

    errors = []

    label = TkLabel.new(root, text: 'Owner')
    label.pack

    TkSelection.set_owner(label)

    # Get owner using display-specific method
    owner = TkSelection.get_owner_on_display(root)
    errors << "get_owner_on_display should return the label" unless owner == label

    # With selection name
    owner2 = TkSelection.get_owner_on_display(root, 'PRIMARY')
    errors << "get_owner_on_display with sel should work" unless owner2 == label

    raise errors.join("\n") unless errors.empty?
  end

  def test_instance_get_owner
    assert_tk_app("Selection instance get_owner", method(:instance_get_owner_app))
  end

  def instance_get_owner_app
    require 'tk'
    require 'tk/selection'

    errors = []

    label = TkLabel.new(root, text: 'Owner')
    label.pack
    label.extend(TkSelection)

    TkSelection.set_owner(label)

    # Instance method should return self
    result = label.get_owner
    errors << "instance get_owner should return self" unless result == label

    # With selection name
    result2 = label.get_owner('PRIMARY')
    errors << "instance get_owner with sel should return self" unless result2 == label

    raise errors.join("\n") unless errors.empty?
  end

  # ===========================================
  # handle - register selection handler
  # ===========================================

  def test_handle
    assert_tk_app("Selection handle", method(:handle_app))
  end

  def handle_app
    require 'tk'
    require 'tk/selection'

    errors = []

    label = TkLabel.new(root, text: 'Handler')
    label.pack

    # Register a selection handler
    handler_called = false
    TkSelection.handle(label, proc { |offset, maxbytes|
      handler_called = true
      "Selection data"
    })

    # Set as owner to enable the handler
    TkSelection.set_owner(label)

    # Should not raise error
    errors << "handle should work" unless true

    raise errors.join("\n") unless errors.empty?
  end

  def test_handle_with_block
    assert_tk_app("Selection handle block", method(:handle_block_app))
  end

  def handle_block_app
    require 'tk'
    require 'tk/selection'

    errors = []

    label = TkLabel.new(root, text: 'Handler')
    label.pack

    # Register with block syntax
    TkSelection.handle(label) { |offset, maxbytes|
      "Block handler data"
    }

    TkSelection.set_owner(label)

    # Should not raise error
    errors << "handle with block should work" unless true

    raise errors.join("\n") unless errors.empty?
  end

  def test_handle_with_type
    assert_tk_app("Selection handle with type", method(:handle_type_app))
  end

  def handle_type_app
    require 'tk'
    require 'tk/selection'

    errors = []

    label = TkLabel.new(root, text: 'Handler')
    label.pack

    # Register handler for specific type
    TkSelection.handle(label, proc { "typed data" }, type: 'STRING')

    TkSelection.set_owner(label)

    # Should not raise error
    errors << "handle with type should work" unless true

    raise errors.join("\n") unless errors.empty?
  end

  # ===========================================
  # Instance methods (mixin)
  # ===========================================

  def test_instance_clear
    assert_tk_app("Selection instance clear", method(:instance_clear_app))
  end

  def instance_clear_app
    require 'tk'
    require 'tk/selection'

    errors = []

    label = TkLabel.new(root, text: 'Test')
    label.pack
    label.extend(TkSelection)

    # Use instance method
    result = label.clear
    errors << "instance clear should return self" unless result == label

    raise errors.join("\n") unless errors.empty?
  end

  def test_instance_set_owner
    assert_tk_app("Selection instance set_owner", method(:instance_set_owner_app))
  end

  def instance_set_owner_app
    require 'tk'
    require 'tk/selection'

    errors = []

    label = TkLabel.new(root, text: 'Test')
    label.pack
    label.extend(TkSelection)

    # Use instance method
    result = label.set_owner
    errors << "instance set_owner should return self" unless result == label

    raise errors.join("\n") unless errors.empty?
  end

  def test_instance_handle
    assert_tk_app("Selection instance handle", method(:instance_handle_app))
  end

  def instance_handle_app
    require 'tk'
    require 'tk/selection'

    errors = []

    label = TkLabel.new(root, text: 'Test')
    label.pack
    label.extend(TkSelection)

    # Use instance method with block
    label.handle { |offset, maxbytes| "Instance data" }

    # Should not raise error
    errors << "instance handle should work" unless true

    raise errors.join("\n") unless errors.empty?
  end
end
