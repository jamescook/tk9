# frozen_string_literal: true

# Test for TkComposite module
# Used for building compound widgets from multiple sub-widgets

require_relative '../test_helper'
require_relative '../tk_test_helper'

class TestTkComposite < Minitest::Test
  include TkTestHelper

  def test_composite_basic_creation
    assert_tk_app("TkComposite basic creation", method(:composite_basic_app))
  end

  def composite_basic_app
    require 'tk'
    require 'tk/composite'

    errors = []

    # Create a simple composite widget (inherit TkFrame + include TkComposite)
    labeled_entry_class = Class.new(TkFrame) do
      include TkComposite

      attr_reader :label, :entry

      def initialize_composite(keys = {})
        @label = TkLabel.new(@frame, text: keys.delete('label') || 'Label:')
        @label.pack(side: 'left')

        @entry = TkEntry.new(@frame, width: 20)
        @entry.pack(side: 'left', fill: 'x', expand: true)

        # Delegate options
        delegate('text', @label)
        delegate('width', @entry)
        delegate('DEFAULT', @entry)
      end
    end

    widget = labeled_entry_class.new(root, 'label' => 'Name:')
    widget.pack

    errors << "composite creation failed" if widget.nil?
    errors << "frame not created" if widget.instance_variable_get(:@frame).nil?
    errors << "epath not set" if widget.epath.nil? || widget.epath.empty?

    raise "TkComposite basic test failures:\n  " + errors.join("\n  ") unless errors.empty?
  end

  def test_composite_delegate
    assert_tk_app("TkComposite delegate", method(:composite_delegate_app))
  end

  def composite_delegate_app
    require 'tk'
    require 'tk/composite'

    errors = []

    composite_class = Class.new(TkFrame) do
      include TkComposite

      attr_reader :label, :button

      def initialize_composite(keys = {})
        @label = TkLabel.new(@frame, text: 'Initial')
        @label.pack(side: 'left')

        @button = TkButton.new(@frame, text: 'Click')
        @button.pack(side: 'left')

        delegate('text', @label)
        delegate('command', @button)
      end
    end

    widget = composite_class.new(root)
    widget.pack

    # Test configure via delegation
    widget.configure('text', 'Updated')
    label_text = widget.label.cget(:text)
    errors << "delegate configure failed: expected 'Updated', got '#{label_text}'" unless label_text == 'Updated'

    # Test cget via delegation
    result = widget.cget('text')
    errors << "delegate cget failed: expected 'Updated', got '#{result}'" unless result == 'Updated'

    raise "TkComposite delegate test failures:\n  " + errors.join("\n  ") unless errors.empty?
  end

  def test_composite_delegate_alias
    assert_tk_app("TkComposite delegate_alias", method(:composite_delegate_alias_app))
  end

  def composite_delegate_alias_app
    require 'tk'
    require 'tk/composite'

    errors = []

    composite_class = Class.new(TkFrame) do
      include TkComposite

      attr_reader :label

      def initialize_composite(keys = {})
        @label = TkLabel.new(@frame, text: 'Test', background: 'white')
        @label.pack

        # Alias 'bg' to 'background' on label
        delegate_alias('bg', 'background', @label)
        delegate('background', @label)
      end
    end

    widget = composite_class.new(root)
    widget.pack

    # Configure using alias
    widget.configure('bg', 'yellow')

    # Verify via the real option name
    bg = widget.label.cget(:background)
    errors << "delegate_alias failed: expected 'yellow', got '#{bg}'" unless bg == 'yellow'

    # cget using alias should also work
    result = widget.cget('bg')
    errors << "delegate_alias cget failed: expected 'yellow', got '#{result}'" unless result == 'yellow'

    raise "TkComposite delegate_alias test failures:\n  " + errors.join("\n  ") unless errors.empty?
  end

  def test_composite_default_delegate
    assert_tk_app("TkComposite DEFAULT delegate", method(:composite_default_delegate_app))
  end

  def composite_default_delegate_app
    require 'tk'
    require 'tk/composite'

    errors = []

    composite_class = Class.new(TkFrame) do
      include TkComposite

      attr_reader :entry

      def initialize_composite(keys = {})
        @entry = TkEntry.new(@frame)
        @entry.pack(fill: 'x')

        # All unknown options go to entry
        delegate('DEFAULT', @entry)
      end
    end

    widget = composite_class.new(root)
    widget.pack

    # Configure width (not explicitly delegated, should go to DEFAULT)
    widget.configure('width', 30)
    width = widget.entry.cget(:width)
    errors << "DEFAULT delegate failed: expected 30, got #{width}" unless width == 30

    raise "TkComposite DEFAULT delegate test failures:\n  " + errors.join("\n  ") unless errors.empty?
  end

  def test_composite_option_methods
    assert_tk_app("TkComposite option_methods", method(:composite_option_methods_app))
  end

  def composite_option_methods_app
    require 'tk'
    require 'tk/composite'

    errors = []

    composite_class = Class.new(TkFrame) do
      include TkComposite

      attr_reader :internal_value

      def initialize_composite(keys = {})
        @internal_value = 0
        @label = TkLabel.new(@frame, text: '0')
        @label.pack

        # Register custom option methods (array style - preferred)
        # Method name becomes the option name
        option_methods([:value, :get_value])
      end

      def value(val)
        @internal_value = val.to_i
        @label.configure(text: @internal_value.to_s)
      end

      def get_value
        @internal_value
      end
    end

    widget = composite_class.new(root)
    widget.pack

    # Configure using option_methods (option name is 'value' - the setter name)
    widget.configure('value', 42)
    errors << "option_methods set failed" unless widget.internal_value == 42

    # cget using option_methods
    result = widget.cget('value')
    errors << "option_methods cget failed: expected 42, got #{result}" unless result == 42

    raise "TkComposite option_methods test failures:\n  " + errors.join("\n  ") unless errors.empty?
  end

  def test_composite_configinfo
    assert_tk_app("TkComposite configinfo", method(:composite_configinfo_app))
  end

  def composite_configinfo_app
    require 'tk'
    require 'tk/composite'

    errors = []

    composite_class = Class.new(TkFrame) do
      include TkComposite

      def initialize_composite(keys = {})
        @label = TkLabel.new(@frame, text: 'Test')
        @label.pack

        delegate('text', @label)
      end
    end

    widget = composite_class.new(root)
    widget.pack

    # configinfo for delegated option
    info = widget.configinfo('text')
    errors << "configinfo returned nil" if info.nil?
    errors << "configinfo should be array" unless info.is_a?(Array)
    errors << "configinfo[0] should be 'text'" unless info[0] == 'text'

    # configinfo with no args returns all options
    all_info = widget.configinfo
    errors << "configinfo() should return array" unless all_info.is_a?(Array)
    errors << "configinfo() should have entries" if all_info.empty?

    raise "TkComposite configinfo test failures:\n  " + errors.join("\n  ") unless errors.empty?
  end

  def test_composite_with_classname
    assert_tk_app("TkComposite with classname", method(:composite_classname_app))
  end

  def composite_classname_app
    require 'tk'
    require 'tk/composite'

    errors = []

    composite_class = Class.new(TkFrame) do
      include TkComposite

      def initialize_composite(keys = {})
        TkLabel.new(@frame, text: 'Custom class').pack
      end
    end

    # Create with custom class name
    widget = composite_class.new(root, 'classname' => 'MyCustomWidget')
    widget.pack

    # database_classname should return the class
    classname = widget.database_classname
    errors << "database_classname failed" if classname.nil?

    raise "TkComposite classname test failures:\n  " + errors.join("\n  ") unless errors.empty?
  end

  def test_composite_hash_configure
    assert_tk_app("TkComposite hash configure", method(:composite_hash_configure_app))
  end

  def composite_hash_configure_app
    require 'tk'
    require 'tk/composite'

    errors = []

    composite_class = Class.new(TkFrame) do
      include TkComposite

      attr_reader :label

      def initialize_composite(keys = {})
        @label = TkLabel.new(@frame, text: 'Initial', foreground: 'black')
        @label.pack

        delegate('text', @label)
        delegate('foreground', @label)
      end
    end

    widget = composite_class.new(root)
    widget.pack

    # Configure multiple options at once via hash
    widget.configure('text' => 'Updated', 'foreground' => 'blue')

    text = widget.label.cget(:text)
    fg = widget.label.cget(:foreground)

    errors << "hash configure text failed" unless text == 'Updated'
    errors << "hash configure foreground failed" unless fg == 'blue'

    raise "TkComposite hash configure test failures:\n  " + errors.join("\n  ") unless errors.empty?
  end

  # Tests for _choice_classname_of_baseframe branches

  def test_composite_named_class
    assert_tk_app("TkComposite named class", method(:composite_named_class_app))
  end

  def composite_named_class_app
    require 'tk'
    require 'tk/composite'

    errors = []

    # Define a named class (not anonymous) - should use class name for base frame
    # Must be defined at top level or with explicit name
    Object.const_set(:TestNamedComposite, Class.new(TkFrame) do
      include TkComposite

      def initialize_composite(keys = {})
        TkLabel.new(@frame, text: 'Named').pack
      end
    end) unless defined?(::TestNamedComposite)

    widget = TestNamedComposite.new(root)
    widget.pack

    # database_classname should return the class name
    classname = widget.database_classname
    errors << "named class: database_classname should be 'TestNamedComposite', got '#{classname}'" unless classname == 'TestNamedComposite'

    raise "TkComposite named class test failures:\n  " + errors.join("\n  ") unless errors.empty?
  end

  def test_composite_custom_widget_classname
    assert_tk_app("TkComposite custom WidgetClassName", method(:composite_custom_widgetclassname_app))
  end

  def composite_custom_widgetclassname_app
    require 'tk'
    require 'tk/composite'

    errors = []

    # Define a class with custom WidgetClassName constant
    unless defined?(::TestCustomWidgetClassName)
      klass = Class.new(TkFrame) do
        include TkComposite

        def initialize_composite(keys = {})
          TkLabel.new(@frame, text: 'Custom WidgetClassName').pack
        end
      end
      klass.const_set(:WidgetClassName, 'MyCustomClassName'.freeze)
      Object.const_set(:TestCustomWidgetClassName, klass)
    end

    widget = TestCustomWidgetClassName.new(root)
    widget.pack

    # database_classname should use the custom WidgetClassName
    classname = widget.database_classname
    errors << "custom WidgetClassName: expected 'MyCustomClassName', got '#{classname}'" unless classname == 'MyCustomClassName'

    raise "TkComposite custom WidgetClassName test failures:\n  " + errors.join("\n  ") unless errors.empty?
  end

  def test_composite_anonymous_class_fallback
    assert_tk_app("TkComposite anonymous class fallback", method(:composite_anonymous_fallback_app))
  end

  def composite_anonymous_fallback_app
    require 'tk'
    require 'tk/composite'

    errors = []

    # Anonymous class should fall back (empty name -> nil -> TkFrame)
    anon_class = Class.new(TkFrame) do
      include TkComposite

      def initialize_composite(keys = {})
        TkLabel.new(@frame, text: 'Anonymous').pack
      end
    end

    widget = anon_class.new(root)
    widget.pack

    # For anonymous class, database_classname falls back to Frame
    classname = widget.database_classname
    # Should be 'Frame' or 'TkFrame' - the default
    errors << "anonymous class: expected Frame-like classname, got '#{classname}'" unless classname =~ /Frame/i

    raise "TkComposite anonymous fallback test failures:\n  " + errors.join("\n  ") unless errors.empty?
  end

  def test_composite_subclass_of_composite
    assert_tk_app("TkComposite subclass of composite", method(:composite_subclass_app))
  end

  def composite_subclass_app
    require 'tk'
    require 'tk/composite'

    errors = []

    # Base composite class
    Object.const_set(:TestBaseComposite, Class.new(TkFrame) do
      include TkComposite

      def initialize_composite(keys = {})
        @label = TkLabel.new(@frame, text: 'Base')
        @label.pack
        delegate('text', @label)
      end
    end) unless defined?(::TestBaseComposite)

    # Subclass of composite
    Object.const_set(:TestSubComposite, Class.new(TestBaseComposite) do
      def initialize_composite(keys = {})
        super
        @label.configure(text: 'Subclass')
      end
    end) unless defined?(::TestSubComposite)

    widget = TestSubComposite.new(root)
    widget.pack

    # Should use subclass name
    classname = widget.database_classname
    errors << "subclass: expected 'TestSubComposite', got '#{classname}'" unless classname == 'TestSubComposite'

    # Delegation should still work
    widget.configure('text', 'Updated')
    text = widget.cget('text')
    errors << "subclass delegation failed" unless text == 'Updated'

    raise "TkComposite subclass test failures:\n  " + errors.join("\n  ") unless errors.empty?
  end

  # --- Additional coverage tests ---

  def test_composite_cget_strict
    assert_tk_app("TkComposite cget_strict", method(:composite_cget_strict_app))
  end

  def composite_cget_strict_app
    require 'tk'
    require 'tk/composite'

    errors = []

    composite_class = Class.new(TkFrame) do
      include TkComposite

      attr_reader :label

      def initialize_composite(keys = {})
        @label = TkLabel.new(@frame, text: 'Strict Test')
        @label.pack
        delegate('text', @label)
      end
    end

    widget = composite_class.new(root)
    widget.pack

    # cget_strict should work like cget for delegated options
    result = widget.cget_strict('text')
    errors << "cget_strict failed: expected 'Strict Test', got '#{result}'" unless result == 'Strict Test'

    raise errors.join("\n") unless errors.empty?
  end

  def test_composite_cget_tkstring
    assert_tk_app("TkComposite cget_tkstring", method(:composite_cget_tkstring_app))
  end

  def composite_cget_tkstring_app
    require 'tk'
    require 'tk/composite'

    errors = []

    composite_class = Class.new(TkFrame) do
      include TkComposite

      attr_reader :label

      def initialize_composite(keys = {})
        @label = TkLabel.new(@frame, text: 'TkString Test')
        @label.pack
        delegate('text', @label)
      end
    end

    widget = composite_class.new(root)
    widget.pack

    # cget_tkstring returns string representation
    result = widget.cget_tkstring('text')
    errors << "cget_tkstring failed: expected string, got #{result.class}" unless result.is_a?(String)
    errors << "cget_tkstring value wrong: expected 'TkString Test', got '#{result}'" unless result == 'TkString Test'

    raise errors.join("\n") unless errors.empty?
  end

  def test_composite_database_class
    assert_tk_app("TkComposite database_class", method(:composite_database_class_app))
  end

  def composite_database_class_app
    require 'tk'
    require 'tk/composite'

    errors = []

    composite_class = Class.new(TkFrame) do
      include TkComposite

      def initialize_composite(keys = {})
        TkLabel.new(@frame, text: 'DB Class').pack
      end
    end

    widget = composite_class.new(root)
    widget.pack

    # database_class delegates to @frame.database_class
    result = widget.database_class
    errors << "database_class should return something" if result.nil?

    raise errors.join("\n") unless errors.empty?
  end

  def test_composite_inspect
    assert_tk_app("TkComposite inspect", method(:composite_inspect_app))
  end

  def composite_inspect_app
    require 'tk'
    require 'tk/composite'

    errors = []

    composite_class = Class.new(TkFrame) do
      include TkComposite

      def initialize_composite(keys = {})
        TkLabel.new(@frame, text: 'Inspect').pack
      end
    end

    widget = composite_class.new(root)
    widget.pack

    # inspect should include @epath
    result = widget.inspect
    errors << "inspect should be a string" unless result.is_a?(String)
    errors << "inspect should include @epath" unless result.include?('@epath=')
    errors << "inspect should include the path" unless result.include?(widget.epath)

    raise errors.join("\n") unless errors.empty?
  end

  def test_composite_option_methods_without_getter
    assert_tk_app("TkComposite option_methods without getter", method(:composite_option_no_getter_app))
  end

  def composite_option_no_getter_app
    require 'tk'
    require 'tk/composite'

    errors = []

    # Test option_methods where there's no cget method - value stored in @option_setting
    composite_class = Class.new(TkFrame) do
      include TkComposite

      def initialize_composite(keys = {})
        @label = TkLabel.new(@frame, text: '0')
        @label.pack
        # Register option with only setter (no getter)
        option_methods(:my_option)
      end

      def my_option(val)
        @label.configure(text: val.to_s)
      end
    end

    widget = composite_class.new(root)
    widget.pack

    # Configure the option
    widget.configure('my_option', 'stored_value')

    # cget should return the stored value from @option_setting
    result = widget.cget('my_option')
    errors << "option without getter should store value, got '#{result}'" unless result == 'stored_value'

    raise errors.join("\n") unless errors.empty?
  end

  def test_composite_delegate_alias_error
    assert_tk_app("TkComposite delegate_alias errors", method(:composite_delegate_alias_error_app))
  end

  def composite_delegate_alias_error_app
    require 'tk'
    require 'tk/composite'

    errors = []

    composite_class = Class.new(TkFrame) do
      include TkComposite

      attr_reader :label

      def initialize_composite(keys = {})
        @label = TkLabel.new(@frame, text: 'Test')
        @label.pack
      end
    end

    widget = composite_class.new(root)
    widget.pack

    # delegate_alias with no widgets should raise ArgumentError
    begin
      widget.send(:delegate_alias, 'alias', 'option')
      errors << "delegate_alias with no widgets should raise ArgumentError"
    rescue ArgumentError => e
      errors << "wrong error message" unless e.message.include?("target widgets")
    end

    # Cannot alias DEFAULT
    begin
      widget.send(:delegate_alias, 'DEFAULT', 'other', widget.label)
      errors << "aliasing DEFAULT should raise ArgumentError"
    rescue ArgumentError => e
      errors << "wrong error message for DEFAULT" unless e.message.include?("DEFAULT")
    end

    raise errors.join("\n") unless errors.empty?
  end
end
