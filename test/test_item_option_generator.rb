# frozen_string_literal: true

require_relative 'test_helper'
require 'tk'
require 'tk/item_option_generator'

class TestItemOptionGenerator < Minitest::Test
  # Test ITEM_TYPES registry
  def test_item_types_registry_has_canvas
    config = Tk::ItemOptionGenerator::ITEM_TYPES[:canvas]
    assert_equal 'canvas', config[:widget_cmd]
    assert config[:item_types].key?(:line)
    assert config[:item_types].key?(:rectangle)
    assert config[:item_types].key?(:oval)
    assert config[:item_types].key?(:text)
  end

  def test_item_types_registry_has_menu
    config = Tk::ItemOptionGenerator::ITEM_TYPES[:menu]
    assert_equal 'menu', config[:widget_cmd]
    assert config[:item_types].key?(:command)
    assert config[:item_types].key?(:checkbutton)
    assert config[:item_types].key?(:radiobutton)
    assert config[:item_types].key?(:separator)
    assert config[:item_types].key?(:cascade)
  end

  def test_item_types_registry_has_text
    config = Tk::ItemOptionGenerator::ITEM_TYPES[:text]
    assert_equal 'text', config[:widget_cmd]
    assert config[:item_types].key?(:tag)
  end

  def test_item_types_registry_has_listbox
    config = Tk::ItemOptionGenerator::ITEM_TYPES[:listbox]
    assert_equal 'listbox', config[:widget_cmd]
    assert config[:item_types].key?(:item)
  end

  # Test parsing (requires Tk - integration test)
  def test_parse_configure_output
    generator = Tk::ItemOptionGenerator.new(tcl_version: Tk::TCL_VERSION)

    # Use actual Tcl list format
    raw = "{-fill fill Fill {} {}} {-outline outline Outline black black} {-width width Width 1.0 1.0}"
    entries = generator.parse_configure_output(raw)

    assert_equal 3, entries.size
    assert_equal "fill", entries[0].name
    assert_equal "outline", entries[1].name
    assert_equal "width", entries[2].name
  end

  def test_parse_configure_output_with_alias
    generator = Tk::ItemOptionGenerator.new(tcl_version: Tk::TCL_VERSION)

    raw = "{-background background Background white white} {-bg -background}"
    entries = generator.parse_configure_output(raw)

    assert_equal 2, entries.size
    refute entries[0].alias?
    assert entries[1].alias?
    assert_equal "background", entries[1].alias_target
  end

  def test_parse_configure_output_with_nested_braces
    generator = Tk::ItemOptionGenerator.new(tcl_version: Tk::TCL_VERSION)

    # This is the real format that caused the bug - nested braces in default value
    raw = "{-arrowshape {} {} {8 10 3} {8 10 3}} {-fill fill Fill {} {}}"
    entries = generator.parse_configure_output(raw)

    assert_equal 2, entries.size
    assert_equal "arrowshape", entries[0].name
    assert_equal "fill", entries[1].name
  end

  # Test to_item_dsl on OptionEntry
  def test_option_entry_to_item_dsl_simple
    raw = "-fill fill Fill {} {}"
    entry = Tk::OptionGenerator::OptionEntry.parse(raw)
    assert_equal "item_option :fill", entry.to_item_dsl
  end

  def test_option_entry_to_item_dsl_with_type
    raw = "-smooth smooth Boolean 0 0"
    entry = Tk::OptionGenerator::OptionEntry.parse(raw)
    assert_equal "item_option :smooth, type: :boolean", entry.to_item_dsl
  end

  def test_option_entry_to_item_dsl_with_single_alias
    raw = "-background background Background white white"
    entry = Tk::OptionGenerator::OptionEntry.parse(raw)
    assert_equal "item_option :background, alias: :bg", entry.to_item_dsl(aliases: ["bg"])
  end

  def test_option_entry_to_item_dsl_with_multiple_aliases
    raw = "-foreground foreground Foreground black black"
    entry = Tk::OptionGenerator::OptionEntry.parse(raw)
    assert_equal "item_option :foreground, aliases: [:fg, :fgcolor]", entry.to_item_dsl(aliases: ["fg", "fgcolor"])
  end

  # Test module generation
  def test_generate_module_from_entries
    generator = Tk::ItemOptionGenerator.new(tcl_version: "9.0")

    # Simulate entries for canvas items
    raw_entries = [
      "-fill fill Fill {} {}",
      "-outline outline Outline black black",
      "-width width Width 1.0 1.0",
      "-smooth smooth Boolean 0 0",
      "-bg -background",
      "-background background Background white white",
    ]
    entries = raw_entries.map { |r| Tk::OptionGenerator::OptionEntry.parse(r) }

    output = generator.generate_module_from_entries("Canvas", entries)

    assert_includes output, "module CanvasItems"
    assert_includes output, "base.extend Tk::ItemOptionDSL"
    assert_includes output, "item_option :fill"
    assert_includes output, "item_option :outline"
    assert_includes output, "item_option :smooth, type: :boolean"
    assert_includes output, "item_option :background, alias: :bg"
    # Aliases should NOT appear as separate entries
    refute_match(/item_option :bg\b/, output)
  end

  # Test unknown widget raises error
  def test_introspect_unknown_widget_raises
    generator = Tk::ItemOptionGenerator.new(tcl_version: "9.0")
    assert_raises(ArgumentError) { generator.introspect_widget_items(:unknown) }
  end

  # Integration test - actually introspect Tk
  def test_introspect_canvas_items
    generator = Tk::ItemOptionGenerator.new(tcl_version: Tk::TCL_VERSION)
    entries = generator.introspect_widget_items(:canvas)

    # Should have common canvas item options
    option_names = entries.map(&:name)
    assert_includes option_names, "fill"
    assert_includes option_names, "outline"
    assert_includes option_names, "width"
    assert_includes option_names, "state"
    assert_includes option_names, "tags"
  end

  def test_introspect_menu_entries
    generator = Tk::ItemOptionGenerator.new(tcl_version: Tk::TCL_VERSION)
    entries = generator.introspect_widget_items(:menu)

    option_names = entries.map(&:name)
    if Tk::TCL_MAJOR_VERSION >= 9
      # Tcl 9.0+ returns full set of menu entry options
      assert_includes option_names, "label"
      assert_includes option_names, "command"
      assert_includes option_names, "state"
    else
      # Tcl 8.6 returns minimal options in headless/xvfb environments
      assert_includes option_names, "background"
      assert_includes option_names, "state"
    end
  end

  def test_introspect_text_tags
    generator = Tk::ItemOptionGenerator.new(tcl_version: Tk::TCL_VERSION)
    entries = generator.introspect_widget_items(:text)

    option_names = entries.map(&:name)
    assert_includes option_names, "foreground"
    assert_includes option_names, "background"
  end

  def test_introspect_listbox_items
    generator = Tk::ItemOptionGenerator.new(tcl_version: Tk::TCL_VERSION)
    entries = generator.introspect_widget_items(:listbox)

    option_names = entries.map(&:name)
    assert_includes option_names, "background"
    assert_includes option_names, "foreground"
  end
end
