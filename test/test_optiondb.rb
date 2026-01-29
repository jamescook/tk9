# frozen_string_literal: true

# Tests for TkOptionDB - Tk's option (resource) database
#
# What is the Option Database?
# ============================
# The option database is Tk's mechanism for configuring widget defaults.
# It comes from X11's resource database concept. You can set defaults like:
#
#   *Button.background: blue      # All buttons get blue background
#   *quit.text: Quit              # Widget named "quit" gets this text
#   MyApp*font: Helvetica         # Widgets under MyApp class get this font
#
# Priority levels control which settings win when multiple match:
#   WidgetDefault (20) < StartupFile (40) < UserDefault (60) < Interactive (80)
#
# See: https://www.tcl-lang.org/man/tcl/TkCmd/option.html

require_relative 'test_helper'
require_relative 'tk_test_helper'

class TestOptionDB < Minitest::Test
  include TkTestHelper

  def test_add_and_get
    assert_tk_app("OptionDB add and get", method(:add_and_get_app))
  end

  def add_and_get_app
    require 'tk'
    require 'tk/optiondb'

    errors = []

    # Add an option to the database
    TkOptionDB.add('*testWidget.background', 'red')

    # Create a frame with matching class to test retrieval
    frame = TkFrame.new(root, widgetname: 'testWidget')

    # Get the option value - need window path, option name, class name
    result = TkOptionDB.get(frame.path, 'background', 'Background')
    errors << "expected 'red', got '#{result}'" unless result == 'red'

    # Test with priority - higher priority should override
    TkOptionDB.add('*testWidget.background', 'blue', TkOptionDB::Priority::Interactive)
    result = TkOptionDB.get(frame.path, 'background', 'Background')
    errors << "priority override failed: expected 'blue', got '#{result}'" unless result == 'blue'

    raise errors.join("\n") unless errors.empty?
  end

  def test_priority_constants
    assert_tk_app("OptionDB priority constants", method(:priority_constants_app))
  end

  def priority_constants_app
    require 'tk'
    require 'tk/optiondb'

    errors = []

    # Verify priority constants exist and have expected relative values
    errors << "WidgetDefault missing" unless TkOptionDB::Priority::WidgetDefault == 20
    errors << "StartupFile missing" unless TkOptionDB::Priority::StartupFile == 40
    errors << "UserDefault missing" unless TkOptionDB::Priority::UserDefault == 60
    errors << "Interactive missing" unless TkOptionDB::Priority::Interactive == 80

    # Verify ordering
    wd = TkOptionDB::Priority::WidgetDefault
    sf = TkOptionDB::Priority::StartupFile
    ud = TkOptionDB::Priority::UserDefault
    ia = TkOptionDB::Priority::Interactive

    errors << "priority ordering wrong" unless wd < sf && sf < ud && ud < ia

    raise errors.join("\n") unless errors.empty?
  end

  def test_clear
    assert_tk_app("OptionDB clear", method(:clear_app))
  end

  def clear_app
    require 'tk'
    require 'tk/optiondb'

    errors = []

    # Add something
    TkOptionDB.add('*clearTest.foreground', 'green')
    frame = TkFrame.new(root, widgetname: 'clearTest')

    result = TkOptionDB.get(frame.path, 'foreground', 'Foreground')
    errors << "add failed before clear" unless result == 'green'

    # Clear the database
    TkOptionDB.clear

    # After clear, should get empty string
    result = TkOptionDB.get(frame.path, 'foreground', 'Foreground')
    errors << "clear failed: expected '', got '#{result}'" unless result == ''

    raise errors.join("\n") unless errors.empty?
  end

  def test_readfile
    assert_tk_app("OptionDB readfile", method(:readfile_app))
  end

  def readfile_app
    require 'tk'
    require 'tk/optiondb'
    require 'tempfile'

    errors = []

    # Create a temporary resource file
    resource_content = <<~RESOURCE
      ! Comment line - should be ignored
      # Another comment style
      *readfileTest.background: yellow
      *readfileTest.foreground: black
      *readfileTest.borderWidth: 5
    RESOURCE

    Tempfile.create(['test_resource', '.db']) do |f|
      f.write(resource_content)
      f.flush

      # Read the file
      TkOptionDB.readfile(f.path)

      # Create widget and verify options were loaded
      frame = TkFrame.new(root, widgetname: 'readfileTest')

      bg = TkOptionDB.get(frame.path, 'background', 'Background')
      errors << "background: expected 'yellow', got '#{bg}'" unless bg == 'yellow'

      fg = TkOptionDB.get(frame.path, 'foreground', 'Foreground')
      errors << "foreground: expected 'black', got '#{fg}'" unless fg == 'black'

      bw = TkOptionDB.get(frame.path, 'borderWidth', 'BorderWidth')
      errors << "borderWidth: expected '5', got '#{bw}'" unless bw == '5'
    end

    raise errors.join("\n") unless errors.empty?
  end

  def test_read_entries
    assert_tk_app("OptionDB read_entries", method(:read_entries_app))
  end

  def read_entries_app
    require 'tk'
    require 'tk/optiondb'
    require 'tempfile'

    errors = []

    # Create a resource file with various patterns
    resource_content = <<~RESOURCE
      ! This is a comment
      # This is also a comment
      *Button.text: Click Me
      *Label.font: Helvetica
      MyApp*background: white
      .frame.button.foreground: blue
      *multiline: this is a \\
      continued line
    RESOURCE

    Tempfile.create(['test_entries', '.db']) do |f|
      f.write(resource_content)
      f.flush

      entries = TkOptionDB.read_entries(f.path)

      # Should have 5 entries (comments excluded, continuation joined)
      errors << "expected 5 entries, got #{entries.size}" unless entries.size == 5

      # Check specific entries
      expected = [
        ['*Button.text', 'Click Me'],
        ['*Label.font', 'Helvetica'],
        ['MyApp*background', 'white'],
        ['.frame.button.foreground', 'blue'],
        ['*multiline', 'this is a continued line']
      ]

      expected.each_with_index do |(pat, val), i|
        if entries[i] != [pat, val]
          errors << "entry #{i}: expected #{[pat, val].inspect}, got #{entries[i].inspect}"
        end
      end
    end

    raise errors.join("\n") unless errors.empty?
  end

  def test_read_with_encoding
    assert_tk_app("OptionDB read_with_encoding", method(:read_with_encoding_app))
  end

  def read_with_encoding_app
    require 'tk'
    require 'tk/optiondb'
    require 'tempfile'

    errors = []

    # Create a resource file
    resource_content = <<~RESOURCE
      *encodingTest.text: Hello World
    RESOURCE

    Tempfile.create(['test_encoding', '.db']) do |f|
      f.write(resource_content)
      f.flush

      # read_with_encoding should parse and add to database
      TkOptionDB.read_with_encoding(f.path, 'utf-8')

      frame = TkFrame.new(root, widgetname: 'encodingTest')
      result = TkOptionDB.get(frame.path, 'text', 'Text')
      errors << "expected 'Hello World', got '#{result}'" unless result == 'Hello World'
    end

    raise errors.join("\n") unless errors.empty?
  end

  def test_widget_styling
    assert_tk_app("OptionDB widget styling", method(:widget_styling_app))
  end

  def widget_styling_app
    require 'tk'
    require 'tk/optiondb'

    errors = []

    # Set up styling via option database
    TkOptionDB.add('*StyledFrame.background', '#336699')
    TkOptionDB.add('*StyledFrame.Button.background', '#99ccff')
    TkOptionDB.add('*StyledFrame.Button.foreground', '#003366')

    # Create a frame with class StyledFrame
    frame = TkFrame.new(root, class: 'StyledFrame')
    frame.pack

    # The frame should pick up the background
    # (Note: actual widget config may differ from database - this tests the DB itself)
    bg = TkOptionDB.get(frame.path, 'background', 'Background')
    errors << "frame background: expected '#336699', got '#{bg}'" unless bg == '#336699'

    raise errors.join("\n") unless errors.empty?
  end

  def test_aliases
    assert_tk_app("OptionDB aliases", method(:aliases_app))
  end

  def aliases_app
    require 'tk'
    require 'tk/optiondb'

    errors = []

    # TkOption and TkResourceDB should be aliases
    errors << "TkOption not defined" unless defined?(TkOption)
    errors << "TkResourceDB not defined" unless defined?(TkResourceDB)
    errors << "TkOption != TkOptionDB" unless TkOption == TkOptionDB
    errors << "TkResourceDB != TkOptionDB" unless TkResourceDB == TkOptionDB

    # read_file should be alias for readfile
    errors << "read_file method missing" unless TkOptionDB.respond_to?(:read_file)

    raise errors.join("\n") unless errors.empty?
  end
end
