# frozen_string_literal: true

require_relative 'test_helper'
require 'tk/option_type'

class TestOptionType < Minitest::Test
  # String type
  def test_string_to_tcl
    assert_equal "hello", Tk::OptionType[:string].to_tcl("hello")
    assert_equal "123", Tk::OptionType[:string].to_tcl(123)
  end

  def test_string_from_tcl
    assert_equal "hello", Tk::OptionType[:string].from_tcl("hello")
  end

  # Integer type
  def test_integer_to_tcl
    assert_equal "42", Tk::OptionType[:integer].to_tcl(42)
    assert_equal "42", Tk::OptionType[:integer].to_tcl("42")
    assert_equal "0", Tk::OptionType[:integer].to_tcl("not a number")
  end

  def test_integer_from_tcl
    assert_equal 42, Tk::OptionType[:integer].from_tcl("42")
    assert_equal(-5, Tk::OptionType[:integer].from_tcl("-5"))
    assert_nil Tk::OptionType[:integer].from_tcl("")
  end

  # Float type
  def test_float_to_tcl
    assert_equal "3.14", Tk::OptionType[:float].to_tcl(3.14)
  end

  def test_float_from_tcl
    assert_in_delta 3.14, Tk::OptionType[:float].from_tcl("3.14"), 0.001
    assert_nil Tk::OptionType[:float].from_tcl("")
  end

  # Boolean type
  def test_boolean_to_tcl
    assert_equal "1", Tk::OptionType[:boolean].to_tcl(true)
    assert_equal "0", Tk::OptionType[:boolean].to_tcl(false)
    assert_equal "1", Tk::OptionType[:boolean].to_tcl("yes")
    assert_equal "0", Tk::OptionType[:boolean].to_tcl(nil)
  end

  def test_boolean_from_tcl
    assert_equal true, Tk::OptionType[:boolean].from_tcl("1")
    assert_equal true, Tk::OptionType[:boolean].from_tcl("true")
    assert_equal true, Tk::OptionType[:boolean].from_tcl("yes")
    assert_equal false, Tk::OptionType[:boolean].from_tcl("0")
    assert_equal false, Tk::OptionType[:boolean].from_tcl("false")
    assert_equal false, Tk::OptionType[:boolean].from_tcl("no")
    assert_equal false, Tk::OptionType[:boolean].from_tcl("off")
    assert_equal false, Tk::OptionType[:boolean].from_tcl("")
  end

  # List type
  def test_list_to_tcl
    assert_equal "a b c", Tk::OptionType[:list].to_tcl(%w[a b c])
    assert_equal "single", Tk::OptionType[:list].to_tcl("single")
  end

  def test_list_from_tcl
    assert_equal %w[a b c], Tk::OptionType[:list].from_tcl("a b c")
    assert_equal [], Tk::OptionType[:list].from_tcl("")
  end

  # Pixels type
  def test_pixels_to_tcl
    assert_equal "100", Tk::OptionType[:pixels].to_tcl(100)
    assert_equal "10p", Tk::OptionType[:pixels].to_tcl("10p")
  end

  def test_pixels_from_tcl
    assert_equal 100, Tk::OptionType[:pixels].from_tcl("100")
    assert_equal "10p", Tk::OptionType[:pixels].from_tcl("10p")
    assert_equal "2c", Tk::OptionType[:pixels].from_tcl("2c")
  end

  # Color type
  def test_color_to_tcl
    assert_equal "red", Tk::OptionType[:color].to_tcl("red")
    assert_equal "#ff0000", Tk::OptionType[:color].to_tcl("#ff0000")
  end

  def test_color_from_tcl
    assert_equal "red", Tk::OptionType[:color].from_tcl("red")
  end

  # Anchor type
  def test_anchor_to_tcl
    assert_equal "center", Tk::OptionType[:anchor].to_tcl(:center)
    assert_equal "nw", Tk::OptionType[:anchor].to_tcl("nw")
  end

  def test_anchor_from_tcl
    assert_equal :center, Tk::OptionType[:anchor].from_tcl("center")
    assert_equal :nw, Tk::OptionType[:anchor].from_tcl("nw")
  end

  # Relief type
  def test_relief_to_tcl
    assert_equal "raised", Tk::OptionType[:relief].to_tcl(:raised)
    assert_equal "sunken", Tk::OptionType[:relief].to_tcl("sunken")
  end

  def test_relief_from_tcl
    assert_equal :raised, Tk::OptionType[:relief].from_tcl("raised")
    assert_equal :flat, Tk::OptionType[:relief].from_tcl("flat")
  end

  # Registry
  def test_registry_lookup
    assert_instance_of Tk::OptionType, Tk::OptionType[:string]
    assert_instance_of Tk::OptionType, Tk::OptionType[:integer]
    assert_instance_of Tk::OptionType, Tk::OptionType[:boolean]
  end

  def test_registry_unknown_returns_string
    assert_equal Tk::OptionType[:string], Tk::OptionType[:unknown_type]
  end

  def test_registered?
    assert Tk::OptionType.registered?(:string)
    assert Tk::OptionType.registered?(:integer)
    refute Tk::OptionType.registered?(:unknown_type)
  end

  # Custom type
  def test_custom_type
    upcase_type = Tk::OptionType.new(:upcase,
      to_tcl: ->(v) { v.to_s.upcase },
      from_tcl: ->(v) { v.to_s.downcase }
    )

    assert_equal "HELLO", upcase_type.to_tcl("hello")
    assert_equal "hello", upcase_type.from_tcl("HELLO")
  end

  def test_inspect
    assert_match(/OptionType:string/, Tk::OptionType[:string].inspect)
  end
end
