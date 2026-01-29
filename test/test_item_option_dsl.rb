# frozen_string_literal: true

require_relative 'test_helper'
require 'tk/option_dsl'
require 'tk/item_option_dsl'

class TestItemOptionDSL < Minitest::Test
  def setup
    # Create a fresh test class for each test
    @klass = Class.new do
      extend Tk::ItemOptionDSL
    end
  end

  # --- Basic item_option declaration ---

  def test_item_option_declares_option
    @klass.item_option :fill
    assert @klass.item_options.key?(:fill)
  end

  def test_item_option_returns_option_object
    @klass.item_option :fill
    opt = @klass.item_options[:fill]
    assert_instance_of Tk::Option, opt
  end

  def test_item_option_default_type_is_string
    @klass.item_option :fill
    opt = @klass.item_options[:fill]
    assert_equal :string, opt.type.name
  end

  def test_item_option_with_explicit_type
    @klass.item_option :width, type: :integer
    opt = @klass.item_options[:width]
    assert_equal :integer, opt.type.name
  end

  def test_item_option_with_tcl_name
    @klass.item_option :fill_color, tcl_name: 'fill'
    opt = @klass.item_options[:fill_color]
    assert_equal 'fill', opt.tcl_name
  end

  def test_item_option_default_tcl_name_is_ruby_name
    @klass.item_option :outline
    opt = @klass.item_options[:outline]
    assert_equal 'outline', opt.tcl_name
  end

  # --- Aliases ---

  def test_item_option_with_aliases
    @klass.item_option :background, aliases: [:bg]
    assert @klass.item_options.key?(:background)
    assert @klass.item_options.key?(:bg)
  end

  def test_alias_points_to_same_option
    @klass.item_option :background, aliases: [:bg]
    assert_same @klass.item_options[:background], @klass.item_options[:bg]
  end

  def test_multiple_aliases
    @klass.item_option :foreground, aliases: [:fg, :fgcolor]
    assert @klass.item_options.key?(:foreground)
    assert @klass.item_options.key?(:fg)
    assert @klass.item_options.key?(:fgcolor)
    assert_same @klass.item_options[:foreground], @klass.item_options[:fg]
    assert_same @klass.item_options[:foreground], @klass.item_options[:fgcolor]
  end

  # --- resolve_item_option ---

  def test_resolve_item_option_by_name
    @klass.item_option :fill
    opt = @klass.resolve_item_option(:fill)
    assert_instance_of Tk::Option, opt
    assert_equal :fill, opt.name
  end

  def test_resolve_item_option_by_alias
    @klass.item_option :background, aliases: [:bg]
    opt = @klass.resolve_item_option(:bg)
    assert_instance_of Tk::Option, opt
    assert_equal :background, opt.name
  end

  def test_resolve_item_option_returns_nil_for_unknown
    assert_nil @klass.resolve_item_option(:unknown)
  end

  def test_resolve_item_option_accepts_string
    @klass.item_option :fill
    opt = @klass.resolve_item_option('fill')
    assert_instance_of Tk::Option, opt
  end

  # --- item_option_names ---

  def test_item_option_names_returns_canonical_names
    @klass.item_option :fill
    @klass.item_option :outline
    @klass.item_option :background, aliases: [:bg]

    names = @klass.item_option_names
    assert_includes names, :fill
    assert_includes names, :outline
    assert_includes names, :background
    refute_includes names, :bg  # alias excluded
  end

  # --- Inheritance ---

  def test_subclass_inherits_item_options
    @klass.item_option :fill

    subclass = Class.new(@klass)
    assert subclass.item_options.key?(:fill)
  end

  def test_subclass_can_add_item_options
    @klass.item_option :fill

    subclass = Class.new(@klass)
    subclass.item_option :outline

    assert subclass.item_options.key?(:fill)
    assert subclass.item_options.key?(:outline)
    refute @klass.item_options.key?(:outline)  # parent unchanged
  end

  def test_subclass_item_options_independent_of_parent
    @klass.item_option :fill

    subclass = Class.new(@klass)
    subclass.item_option :outline

    # Modifying subclass doesn't affect parent
    assert_equal 1, @klass.item_options.values.uniq.size
    assert_equal 2, subclass.item_options.values.uniq.size
  end

  # --- Alias methods ---

  def test_declared_item_optkey_aliases
    @klass.item_option :background, aliases: [:bg]
    @klass.item_option :foreground, aliases: [:fg, :fgcolor]

    aliases = @klass.declared_item_optkey_aliases
    assert_equal :background, aliases[:bg]
    assert_equal :foreground, aliases[:fg]
    assert_equal :foreground, aliases[:fgcolor]
  end

  def test_declared_item_optkey_aliases_empty_when_no_aliases
    @klass.item_option :fill
    @klass.item_option :outline

    aliases = @klass.declared_item_optkey_aliases
    assert_empty aliases
  end

  # --- Multiple item options ---

  def test_multiple_item_options_different_types
    @klass.item_option :fill, type: :string
    @klass.item_option :width, type: :integer
    @klass.item_option :smooth, type: :boolean
    @klass.item_option :dash, type: :list

    assert_equal 4, @klass.item_options.values.uniq.size
    assert_equal :string, @klass.item_options[:fill].type.name
    assert_equal :integer, @klass.item_options[:width].type.name
    assert_equal :boolean, @klass.item_options[:smooth].type.name
    assert_equal :list, @klass.item_options[:dash].type.name
  end

  # --- Coexistence with OptionDSL ---

  def test_item_options_separate_from_widget_options
    klass = Class.new do
      extend Tk::OptionDSL
      extend Tk::ItemOptionDSL

      option :width, type: :integer       # widget option
      item_option :fill, type: :string    # item option
    end

    # Both registries should be independent
    assert klass.options.key?(:width)
    refute klass.options.key?(:fill)

    assert klass.item_options.key?(:fill)
    refute klass.item_options.key?(:width)
  end

  def test_same_name_in_widget_and_item_options
    klass = Class.new do
      extend Tk::OptionDSL
      extend Tk::ItemOptionDSL

      option :width, type: :integer       # widget's width
      item_option :width, type: :integer  # item's width (different option)
    end

    widget_opt = klass.options[:width]
    item_opt = klass.item_options[:width]

    # These should be different Option instances
    refute_same widget_opt, item_opt
  end

  # --- Item Command Pattern DSL ---

  def test_item_commands_sets_simple_config
    @klass.item_commands cget: 'entrycget', configure: 'entryconfigure'

    config = @klass.item_command_config
    assert_equal 'entrycget', config[:cget]
    assert_equal 'entryconfigure', config[:configure]
  end

  def test_item_command_config_returns_nil_when_not_configured
    assert_nil @klass.item_command_config
  end

  def test_subclass_inherits_item_commands
    @klass.item_commands cget: 'entrycget', configure: 'entryconfigure'

    subclass = Class.new(@klass)

    config = subclass.item_command_config
    assert_equal 'entrycget', config[:cget]
    assert_equal 'entryconfigure', config[:configure]
  end

  def test_subclass_can_override_item_commands
    @klass.item_commands cget: 'itemcget', configure: 'itemconfigure'

    subclass = Class.new(@klass)
    subclass.item_commands cget: 'entrycget', configure: 'entryconfigure'

    # Parent unchanged
    assert_equal 'itemcget', @klass.item_command_config[:cget]

    # Subclass has new config
    assert_equal 'entrycget', subclass.item_command_config[:cget]
  end

  # --- Proc-based item commands ---

  def test_item_cget_cmd_with_proc
    @klass.item_cget_cmd { |id| ['custom', 'cget', id] }

    config = @klass.item_command_config
    assert config[:cget_proc].is_a?(Proc)
  end

  def test_item_configure_cmd_with_proc
    @klass.item_cget_cmd { |id| ['cget', id] }  # need at least one for config to exist
    @klass.item_configure_cmd { |id| ['custom', 'configure', id] }

    config = @klass.item_command_config
    assert config[:configure_proc].is_a?(Proc)
  end

  def test_subclass_inherits_item_cmd_procs
    @klass.item_cget_cmd { |id| ['parent', 'cget', id] }

    subclass = Class.new(@klass)

    config = subclass.item_command_config
    assert config[:cget_proc].is_a?(Proc)
  end
end
