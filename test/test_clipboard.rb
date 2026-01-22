# frozen_string_literal: true

# Tests for TkClipboard - system clipboard access
#
# TkClipboard wraps Tcl's clipboard command for copy/paste operations.
#
# See: https://www.tcl-lang.org/man/tcl/TkCmd/clipboard.html

require_relative 'test_helper'
require_relative 'tk_test_helper'

class TestClipboard < Minitest::Test
  include TkTestHelper

  # ===========================================
  # Basic set/get
  # ===========================================

  def test_set_and_get
    assert_tk_app("Clipboard set and get", method(:set_and_get_app))
  end

  def set_and_get_app
    require 'tk'
    require 'tk/clipboard'

    errors = []

    # Set clipboard content
    TkClipboard.set("Hello from Ruby/Tk")

    # Get it back
    result = TkClipboard.get
    errors << "expected 'Hello from Ruby/Tk', got '#{result}'" unless result == "Hello from Ruby/Tk"

    raise errors.join("\n") unless errors.empty?
  end

  def test_set_overwrites
    assert_tk_app("Clipboard set overwrites", method(:set_overwrites_app))
  end

  def set_overwrites_app
    require 'tk'
    require 'tk/clipboard'

    errors = []

    TkClipboard.set("First")
    TkClipboard.set("Second")

    result = TkClipboard.get
    errors << "set should overwrite, got '#{result}'" unless result == "Second"

    raise errors.join("\n") unless errors.empty?
  end

  # ===========================================
  # clear
  # ===========================================

  def test_clear
    assert_tk_app("Clipboard clear", method(:clear_app))
  end

  def clear_app
    require 'tk'
    require 'tk/clipboard'

    errors = []

    TkClipboard.set("Something")
    TkClipboard.clear

    # After clear, get should raise TclError (clipboard empty)
    begin
      TkClipboard.get
      errors << "get after clear should raise error"
    rescue TclTkLib::TclError => e
      # Expected - clipboard is empty
      errors << "wrong error: #{e.message}" unless e.message.include?("selection") || e.message.include?("CLIPBOARD")
    end

    raise errors.join("\n") unless errors.empty?
  end

  # ===========================================
  # append
  # ===========================================

  def test_append
    assert_tk_app("Clipboard append", method(:append_app))
  end

  def append_app
    require 'tk'
    require 'tk/clipboard'

    errors = []

    TkClipboard.clear
    TkClipboard.append("Hello")
    TkClipboard.append(" World")

    result = TkClipboard.get
    errors << "append should concatenate, got '#{result}'" unless result == "Hello World"

    raise errors.join("\n") unless errors.empty?
  end

  # ===========================================
  # Unicode/special characters
  # ===========================================

  def test_unicode
    assert_tk_app("Clipboard unicode", method(:unicode_app))
  end

  def unicode_app
    require 'tk'
    require 'tk/clipboard'

    errors = []

    # Test various unicode characters
    test_string = "Hello \u4e16\u754c \u{1F600}"  # "Hello 世界 😀"
    TkClipboard.set(test_string)

    result = TkClipboard.get
    errors << "unicode failed: expected '#{test_string}', got '#{result}'" unless result == test_string

    raise errors.join("\n") unless errors.empty?
  end

  def test_newlines
    assert_tk_app("Clipboard newlines", method(:newlines_app))
  end

  def newlines_app
    require 'tk'
    require 'tk/clipboard'

    errors = []

    test_string = "Line 1\nLine 2\nLine 3"
    TkClipboard.set(test_string)

    result = TkClipboard.get
    errors << "newlines failed" unless result == test_string

    raise errors.join("\n") unless errors.empty?
  end

  # ===========================================
  # get with type
  # ===========================================

  def test_get_with_type
    assert_tk_app("Clipboard get with type", method(:get_with_type_app))
  end

  def get_with_type_app
    require 'tk'
    require 'tk/clipboard'

    errors = []

    TkClipboard.set("Test data")

    # Get as STRING type (default text type)
    result = TkClipboard.get('STRING')
    errors << "get with STRING type failed" unless result == "Test data"

    # UTF8_STRING is another common type
    begin
      result = TkClipboard.get('UTF8_STRING')
      errors << "get with UTF8_STRING failed" unless result == "Test data"
    rescue TclTkLib::TclError
      # UTF8_STRING might not be available on all platforms - that's ok
    end

    raise errors.join("\n") unless errors.empty?
  end

  # ===========================================
  # append with options
  # ===========================================

  def test_append_with_format
    assert_tk_app("Clipboard append with format", method(:append_with_format_app))
  end

  def append_with_format_app
    require 'tk'
    require 'tk/clipboard'

    errors = []

    TkClipboard.clear
    # Append with type option
    TkClipboard.append("formatted", type: 'STRING')

    result = TkClipboard.get
    errors << "append with format failed" unless result == "formatted"

    raise errors.join("\n") unless errors.empty?
  end

  # ===========================================
  # on_display variants (for X11 multi-display)
  # ===========================================

  def test_on_display_methods
    assert_tk_app("Clipboard on_display methods", method(:on_display_app))
  end

  def on_display_app
    require 'tk'
    require 'tk/clipboard'

    errors = []

    # The on_display methods take a window to determine which display
    # On single-display systems, this just uses the default display

    TkClipboard.set_on_display(root, "Display test")
    result = TkClipboard.get_on_display(root)
    errors << "set/get_on_display failed" unless result == "Display test"

    TkClipboard.clear_on_display(root)

    begin
      TkClipboard.get_on_display(root)
      errors << "clear_on_display should clear"
    rescue TclTkLib::TclError
      # Expected - clipboard empty
    end

    # Set it back for append test
    TkClipboard.set_on_display(root, "Part1")
    TkClipboard.append_on_display(root, "Part2")
    result = TkClipboard.get_on_display(root)
    errors << "append_on_display failed" unless result == "Part1Part2"

    raise errors.join("\n") unless errors.empty?
  end

  # ===========================================
  # Instance methods (for mixing into widgets)
  # ===========================================

  def test_instance_methods
    assert_tk_app("Clipboard instance methods", method(:instance_methods_app))
  end

  def instance_methods_app
    require 'tk'
    require 'tk/clipboard'

    errors = []

    # TkClipboard can be included in widgets for instance method access
    # The root window can use these methods
    class << root
      include TkClipboard
    end

    root.set("Instance method test")
    result = root.get
    errors << "instance set/get failed" unless result == "Instance method test"

    root.clear
    begin
      root.get
      errors << "instance clear should work"
    rescue TclTkLib::TclError
      # Expected
    end

    root.set("For append")
    root.append(" more")
    result = root.get
    errors << "instance append failed" unless result == "For append more"

    raise errors.join("\n") unless errors.empty?
  end

  # ===========================================
  # Empty string
  # ===========================================

  def test_empty_string
    assert_tk_app("Clipboard empty string", method(:empty_string_app))
  end

  def empty_string_app
    require 'tk'
    require 'tk/clipboard'

    errors = []

    # Setting empty string should work
    TkClipboard.set("")
    result = TkClipboard.get
    errors << "empty string failed, got '#{result}'" unless result == ""

    raise errors.join("\n") unless errors.empty?
  end
end
