# frozen_string_literal: true

require_relative 'test_helper'
require 'tk/option_dsl'

class TestOptionDSL < Minitest::Test
  def setup
    # Create fresh test classes for each test
    @base_class = Class.new do
      extend Tk::OptionDSL

      option :text
      option :width, type: :integer
      option :bg, type: :color, aliases: [:background]
    end
  end

  def test_option_declaration
    assert_instance_of Tk::Option, @base_class.options[:text]
    assert_equal :text, @base_class.options[:text].name
  end

  def test_option_with_type
    opt = @base_class.options[:width]

    assert_equal :integer, opt.type.name
  end

  def test_option_with_aliases
    opt = @base_class.options[:bg]

    assert_equal [:background], opt.aliases
  end

  def test_alias_points_to_same_option
    assert_same @base_class.options[:bg], @base_class.options[:background]
  end

  def test_resolve_option_by_name
    opt = @base_class.resolve_option(:text)

    assert_instance_of Tk::Option, opt
    assert_equal :text, opt.name
  end

  def test_resolve_option_by_alias
    opt = @base_class.resolve_option(:background)

    assert_instance_of Tk::Option, opt
    assert_equal :bg, opt.name
  end

  def test_resolve_option_unknown_returns_nil
    assert_nil @base_class.resolve_option(:unknown)
  end

  def test_resolve_option_accepts_string
    opt = @base_class.resolve_option("text")

    assert_equal :text, opt.name
  end

  def test_option_names_excludes_aliases
    names = @base_class.option_names

    assert_includes names, :text
    assert_includes names, :width
    assert_includes names, :bg
    refute_includes names, :background  # alias, not canonical name
  end

  def test_options_returns_copy
    options1 = @base_class.options
    options2 = @base_class.options

    refute_same options1, options2
  end

  def test_inheritance
    subclass = Class.new(@base_class) do
      option :height, type: :integer
    end

    # Subclass has parent options
    assert_instance_of Tk::Option, subclass.options[:text]
    assert_instance_of Tk::Option, subclass.options[:width]

    # Subclass has its own option
    assert_instance_of Tk::Option, subclass.options[:height]

    # Parent doesn't have subclass option
    assert_nil @base_class.options[:height]
  end

  def test_inheritance_doesnt_modify_parent
    subclass = Class.new(@base_class) do
      option :extra
    end

    refute @base_class.options.key?(:extra)
    assert subclass.options.key?(:extra)
  end

  def test_subclass_can_override_parent_option
    subclass = Class.new(@base_class) do
      option :width, type: :float  # override with different type
    end

    assert_equal :integer, @base_class.options[:width].type.name
    assert_equal :float, subclass.options[:width].type.name
  end

  def test_multiple_inheritance_levels
    child = Class.new(@base_class) do
      option :child_opt
    end

    grandchild = Class.new(child) do
      option :grandchild_opt
    end

    # Grandchild has all options
    assert grandchild.options.key?(:text)
    assert grandchild.options.key?(:child_opt)
    assert grandchild.options.key?(:grandchild_opt)

    # Child doesn't have grandchild option
    refute child.options.key?(:grandchild_opt)

    # Parent doesn't have child or grandchild options
    refute @base_class.options.key?(:child_opt)
    refute @base_class.options.key?(:grandchild_opt)
  end

  # Bridge method tests

  def test_declared_boolval_optkeys
    klass = Class.new do
      extend Tk::OptionDSL
      option :enabled, type: :boolean
      option :visible, type: :boolean
      option :name, type: :string
    end

    assert_equal %w[enabled visible], klass.declared_boolval_optkeys.sort
  end

  def test_declared_numval_optkeys
    klass = Class.new do
      extend Tk::OptionDSL
      option :width, type: :integer
      option :height, type: :integer
      option :ratio, type: :float
      option :name, type: :string
    end

    assert_equal %w[height ratio width], klass.declared_numval_optkeys.sort
  end

  def test_declared_strval_optkeys
    klass = Class.new do
      extend Tk::OptionDSL
      option :text, type: :string
      option :label, type: :string
      option :count, type: :integer
    end

    assert_equal %w[label text], klass.declared_strval_optkeys.sort
  end

  def test_declared_listval_optkeys
    klass = Class.new do
      extend Tk::OptionDSL
      option :items, type: :list
      option :tags, type: :list
      option :name, type: :string
    end

    assert_equal %w[items tags], klass.declared_listval_optkeys.sort
  end

  def test_declared_optkey_aliases
    klass = Class.new do
      extend Tk::OptionDSL
      option :background, type: :color, aliases: [:bg]
      option :foreground, type: :color, aliases: [:fg, :fgcolor]
    end

    aliases = klass.declared_optkey_aliases

    assert_equal :background, aliases[:bg]
    assert_equal :foreground, aliases[:fg]
    assert_equal :foreground, aliases[:fgcolor]
  end

  def test_bridge_uses_tcl_name
    klass = Class.new do
      extend Tk::OptionDSL
      option :active, type: :boolean, tcl_name: 'isactive'
    end

    assert_equal ['isactive'], klass.declared_boolval_optkeys
  end
end
