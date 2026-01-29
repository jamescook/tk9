# frozen_string_literal: true

require_relative 'test_helper'
require_relative 'tk_test_helper'
require 'tk/option_generator'

class TestOptionGenerator < Minitest::Test
  include TkTestHelper
  # Test TypeRegistry mapping
  def test_type_registry_known_types
    assert_equal :tkvariable, Tk::TypeRegistry.type_for("Variable")
    assert_equal :callback, Tk::TypeRegistry.type_for("Command")
    assert_equal :boolean, Tk::TypeRegistry.type_for("Boolean")
    assert_equal :integer, Tk::TypeRegistry.type_for("Int")
    assert_equal :float, Tk::TypeRegistry.type_for("Double")
  end

  def test_type_registry_fallback_to_string
    assert_equal :string, Tk::TypeRegistry.type_for("Relief")
    assert_equal :string, Tk::TypeRegistry.type_for("Anchor")
    assert_equal :string, Tk::TypeRegistry.type_for("UnknownThing")
  end

  # Test parsing raw Tk configure output
  def test_parse_option_entry_full
    # Full option: {-borderwidth borderWidth BorderWidth 2 2}
    raw = "-borderwidth borderWidth BorderWidth 2 2"
    entry = Tk::OptionGenerator::OptionEntry.parse(raw)

    assert_equal "borderwidth", entry.name
    assert_equal "borderWidth", entry.db_name
    assert_equal "BorderWidth", entry.db_class
    assert_equal "2", entry.default
    refute entry.alias?
  end

  def test_parse_option_entry_alias
    # Alias: {-bd -borderwidth}
    raw = "-bd -borderwidth"
    entry = Tk::OptionGenerator::OptionEntry.parse(raw)

    assert_equal "bd", entry.name
    assert_equal "borderwidth", entry.alias_target
    assert entry.alias?
  end

  def test_option_entry_ruby_type
    # Variable option -> :tkvariable
    raw = "-textvariable textVariable Variable {} {}"
    entry = Tk::OptionGenerator::OptionEntry.parse(raw)
    assert_equal :tkvariable, entry.ruby_type

    # Command option -> :callback
    raw = "-command command Command {} {}"
    entry = Tk::OptionGenerator::OptionEntry.parse(raw)
    assert_equal :callback, entry.ruby_type

    # Unknown dbClass -> :string
    raw = "-relief relief Relief raised raised"
    entry = Tk::OptionGenerator::OptionEntry.parse(raw)
    assert_equal :string, entry.ruby_type
  end

  def test_option_entry_to_dsl_simple
    raw = "-text text Text {} {}"
    entry = Tk::OptionGenerator::OptionEntry.parse(raw)
    assert_equal "option :text", entry.to_dsl
  end

  def test_option_entry_to_dsl_with_type
    raw = "-command command Command {} {}"
    entry = Tk::OptionGenerator::OptionEntry.parse(raw)
    assert_equal "option :command, type: :callback", entry.to_dsl
  end

  def test_option_entry_to_dsl_with_single_alias
    raw = "-borderwidth borderWidth BorderWidth 2 2"
    entry = Tk::OptionGenerator::OptionEntry.parse(raw)
    # BorderWidth dbClass maps to :integer in TypeRegistry
    assert_equal "option :borderwidth, type: :integer, alias: :bd", entry.to_dsl(aliases: ["bd"])
  end

  def test_option_entry_to_dsl_with_multiple_aliases
    raw = "-background background Background #fff #fff"
    entry = Tk::OptionGenerator::OptionEntry.parse(raw)
    assert_equal "option :background, aliases: [:bg, :bgcolor]", entry.to_dsl(aliases: ["bg", "bgcolor"])
  end

  def test_option_entry_to_dsl_with_type_and_alias
    raw = "-textvariable textVariable Variable {} {}"
    entry = Tk::OptionGenerator::OptionEntry.parse(raw)
    assert_equal "option :textvariable, type: :tkvariable, alias: :tv", entry.to_dsl(aliases: ["tv"])
  end

  # Test generating output for a widget
  def test_generate_widget_module
    # Simulate raw configure output for a minimal "button"
    raw_options = [
      "-activebackground activeBackground Foreground #ececec #ececec",
      "-background background Background #fff #fff",
      "-bd -borderwidth",
      "-bg -background",
      "-borderwidth borderWidth BorderWidth 2 2",
      "-command command Command {} {}",
      "-state state State normal normal",
      "-takefocus takeFocus TakeFocus {} {}",
      "-text text Text {} {}",
      "-textvariable textVariable Variable {} {}"
    ]

    generator = Tk::OptionGenerator.new(tcl_version: "9.0")
    output = generator.generate_widget_module("Button", raw_options)

    assert_includes output, "module Button"
    assert_includes output, "option :activebackground"
    assert_includes output, "option :background, alias: :bg"
    assert_includes output, "option :borderwidth, type: :integer, alias: :bd"
    assert_includes output, "option :command, type: :callback"
    assert_includes output, "option :state"
    assert_includes output, "option :text"
    assert_includes output, "option :textvariable, type: :tkvariable"
    # Aliases should NOT appear as separate entries
    refute_includes output, "alias_for:"
  end

  # Integration test - actually introspect Tk (requires display)
  def test_introspect_button_widget
    assert_tk_app("introspect button widget", method(:introspect_button_app))
  end

  def introspect_button_app
    require 'tk/option_generator'

    generator = Tk::OptionGenerator.new(tcl_version: Tk::TCL_VERSION)
    options = generator.introspect_widget("button")

    # Should have common button options
    option_names = options.map(&:name)
    raise "missing text option" unless option_names.include?("text")
    raise "missing command option" unless option_names.include?("command")
    raise "missing state option" unless option_names.include?("state")

    # Should have aliases
    aliases = options.select(&:alias?)
    alias_names = aliases.map(&:name)
    raise "missing bd alias" unless alias_names.include?("bd")
    raise "missing bg alias" unless alias_names.include?("bg")
  end

  # ============================================================
  # Ttk widget generation tests
  # ============================================================

  def test_generate_ttk_widget_module
    # Simulate raw configure output for ttk::label
    raw_options = [
      "-background background Background {} {}",
      "-foreground foreground Foreground {} {}",
      "-padding padding Padding {} {}",
      "-text text Text {} {}",
    ]

    generator = Tk::OptionGenerator.new(tcl_version: "9.0")
    output = generator.generate_widget_module("TtkLabel", raw_options)

    assert_includes output, "module TtkLabel"
    assert_includes output, "option :background"
    assert_includes output, "option :padding"
    assert_includes output, "option :text"
  end

  def test_introspect_ttk_label_widget
    assert_tk_app("introspect ttk::label widget", method(:introspect_ttk_label_app))
  end

  def introspect_ttk_label_app
    require 'tk/option_generator'

    generator = Tk::OptionGenerator.new(tcl_version: Tk::TCL_VERSION)
    options = generator.introspect_widget("ttk::label")

    option_names = options.map(&:name)
    raise "missing text option" unless option_names.include?("text")
    raise "missing padding option" unless option_names.include?("padding")
    raise "missing style option" unless option_names.include?("style")

    # Ttk label should NOT have padx/pady (they don't exist in Tcl)
    raise "should not have padx" if option_names.include?("padx")
    raise "should not have pady" if option_names.include?("pady")
  end
end
