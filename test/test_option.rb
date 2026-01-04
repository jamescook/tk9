# frozen_string_literal: true

require_relative 'test_helper'
require 'tk/option'

class TestOption < Minitest::Test
  def test_basic_creation
    opt = Tk::Option.new(name: :text)

    assert_equal :text, opt.name
    assert_equal "text", opt.tcl_name
    assert_equal :string, opt.type.name
    assert_empty opt.aliases
  end

  def test_custom_tcl_name
    opt = Tk::Option.new(name: :bg, tcl_name: 'background')

    assert_equal :bg, opt.name
    assert_equal "background", opt.tcl_name
  end

  def test_type_by_symbol
    opt = Tk::Option.new(name: :width, type: :integer)

    assert_equal :integer, opt.type.name
  end

  def test_type_by_instance
    custom_type = Tk::OptionType.new(:custom, to_tcl: :to_s, from_tcl: :itself)
    opt = Tk::Option.new(name: :foo, type: custom_type)

    assert_equal :custom, opt.type.name
  end

  def test_aliases
    opt = Tk::Option.new(name: :background, aliases: [:bg, :bgcolor])

    assert_equal [:bg, :bgcolor], opt.aliases
  end

  def test_to_tcl_delegates_to_type
    opt = Tk::Option.new(name: :width, type: :integer)

    assert_equal "42", opt.to_tcl(42)
  end

  def test_from_tcl_delegates_to_type
    opt = Tk::Option.new(name: :width, type: :integer)

    assert_equal 42, opt.from_tcl("42")
  end

  def test_boolean_conversion
    opt = Tk::Option.new(name: :takefocus, type: :boolean)

    assert_equal "1", opt.to_tcl(true)
    assert_equal "0", opt.to_tcl(false)
    assert_equal true, opt.from_tcl("1")
    assert_equal false, opt.from_tcl("0")
  end

  def test_inspect
    opt = Tk::Option.new(name: :bg, tcl_name: 'background', type: :color, aliases: [:background])

    inspect_str = opt.inspect
    assert_includes inspect_str, "Tk::Option"
    assert_includes inspect_str, "bg"
    assert_includes inspect_str, "background"
    assert_includes inspect_str, "color"
  end

  def test_inspect_without_aliases
    opt = Tk::Option.new(name: :text)

    refute_includes opt.inspect, "aliases"
  end
end
