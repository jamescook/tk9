# frozen_string_literal: true

require_relative 'test_helper'
require 'tk/item_type_registry'

class TestItemTypeRegistry < Minitest::Test
  # Test type_for without widget context
  def test_type_for_boolean_option
    assert_equal :boolean, Tk::ItemTypeRegistry.type_for("smooth")
    assert_equal :boolean, Tk::ItemTypeRegistry.type_for("columnbreak")
  end

  def test_type_for_integer_option
    assert_equal :integer, Tk::ItemTypeRegistry.type_for("underline")
    assert_equal :integer, Tk::ItemTypeRegistry.type_for("splinesteps")
  end

  def test_type_for_float_option
    assert_equal :float, Tk::ItemTypeRegistry.type_for("extent")
    assert_equal :float, Tk::ItemTypeRegistry.type_for("width")
  end

  def test_type_for_callback_option
    assert_equal :callback, Tk::ItemTypeRegistry.type_for("command")
  end

  def test_type_for_tkvariable_option
    assert_equal :tkvariable, Tk::ItemTypeRegistry.type_for("variable")
  end

  def test_type_for_widget_option
    assert_equal :widget, Tk::ItemTypeRegistry.type_for("menu")
    assert_equal :widget, Tk::ItemTypeRegistry.type_for("window")
  end

  def test_type_for_unknown_option_defaults_to_string
    assert_equal :string, Tk::ItemTypeRegistry.type_for("unknown_option")
    assert_equal :string, Tk::ItemTypeRegistry.type_for("fill")
  end

  def test_type_for_accepts_symbol
    assert_equal :boolean, Tk::ItemTypeRegistry.type_for(:smooth)
    assert_equal :string, Tk::ItemTypeRegistry.type_for(:fill)
  end

  # Test widget-specific type overrides
  def test_type_for_with_widget_type_override
    # Canvas tags get special :canvas_tags type
    assert_equal :canvas_tags, Tk::ItemTypeRegistry.type_for("tags", widget_type: :canvas)
  end

  def test_type_for_without_widget_type_falls_back_to_string
    # Without widget context, tags is just a string
    assert_equal :string, Tk::ItemTypeRegistry.type_for("tags")
    assert_equal :string, Tk::ItemTypeRegistry.type_for("tags", widget_type: nil)
  end

  def test_type_for_with_widget_type_no_override_uses_mapping
    # Menu widget has no override for "command", uses global mapping
    assert_equal :callback, Tk::ItemTypeRegistry.type_for("command", widget_type: :menu)
  end

  def test_type_for_with_unknown_widget_type_uses_mapping
    # Unknown widget falls back to global mapping
    assert_equal :boolean, Tk::ItemTypeRegistry.type_for("smooth", widget_type: :unknown)
    assert_equal :string, Tk::ItemTypeRegistry.type_for("fill", widget_type: :unknown)
  end

  # Test needs_conversion?
  def test_needs_conversion_for_mapped_options
    assert Tk::ItemTypeRegistry.needs_conversion?("smooth")
    assert Tk::ItemTypeRegistry.needs_conversion?("command")
    assert Tk::ItemTypeRegistry.needs_conversion?("variable")
  end

  def test_needs_conversion_for_unmapped_options
    refute Tk::ItemTypeRegistry.needs_conversion?("fill")
    refute Tk::ItemTypeRegistry.needs_conversion?("tags")
    refute Tk::ItemTypeRegistry.needs_conversion?("unknown")
  end

  # Test known_options_for
  def test_known_options_for_menu
    options = Tk::ItemTypeRegistry.known_options_for(:menu)
    assert_includes options, "label"
    assert_includes options, "command"
    assert_includes options, "state"
    assert_includes options, "variable"
  end

  def test_known_options_for_unknown_widget
    assert_empty Tk::ItemTypeRegistry.known_options_for(:unknown)
  end

  # Test Ruby aliases
  def test_ruby_aliases_for_tags
    aliases = Tk::ItemTypeRegistry.ruby_aliases_for("tags")
    assert_equal ["tag"], aliases
  end

  def test_ruby_aliases_for_option_without_aliases
    assert_empty Tk::ItemTypeRegistry.ruby_aliases_for("fill")
    assert_empty Tk::ItemTypeRegistry.ruby_aliases_for("unknown")
  end

  def test_ruby_aliases_for_accepts_symbol
    aliases = Tk::ItemTypeRegistry.ruby_aliases_for(:tags)
    assert_equal ["tag"], aliases
  end
end
