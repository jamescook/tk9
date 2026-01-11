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

  # --- min_version tests ---

  def test_min_version_default_nil
    opt = Tk::Option.new(name: :text)

    assert_nil opt.min_version
  end

  def test_min_version_set
    opt = Tk::Option.new(name: :activerelief, type: :relief, min_version: 9)

    assert_equal 9, opt.min_version
  end

  def test_available_when_no_min_version
    opt = Tk::Option.new(name: :text)

    assert opt.available?
  end

  def test_available_when_version_satisfied
    # Stub Tk::TK_MAJOR_VERSION for test
    unless defined?(Tk::TK_MAJOR_VERSION)
      Tk.const_set(:TK_MAJOR_VERSION, 9)
      @cleanup_tk_version = true
    end

    opt = Tk::Option.new(name: :foo, min_version: 8)
    assert opt.available?

    opt9 = Tk::Option.new(name: :bar, min_version: 9)
    assert opt9.available? if Tk::TK_MAJOR_VERSION >= 9
  ensure
    Tk.send(:remove_const, :TK_MAJOR_VERSION) if @cleanup_tk_version
  end

  def test_version_required_when_available
    opt = Tk::Option.new(name: :text)

    assert_nil opt.version_required
  end

  def test_version_required_when_unavailable
    # Create option requiring version 99 (definitely not available)
    opt = Tk::Option.new(name: :future_option, min_version: 99)

    assert_equal 99, opt.version_required
  end

  def test_inspect_includes_min_version
    opt = Tk::Option.new(name: :activerelief, type: :relief, min_version: 9)

    assert_includes opt.inspect, "min_version=9"
  end

  def test_inspect_omits_min_version_when_nil
    opt = Tk::Option.new(name: :text)

    refute_includes opt.inspect, "min_version"
  end

  # --- Custom from_tcl/to_tcl callback tests ---

  def test_custom_from_tcl_callback
    # Simulate converting a Tcl path to an object
    opt = Tk::Option.new(
      name: :menu,
      type: :string,
      from_tcl: ->(v, widget:) { "WindowObject(#{v})" }
    )

    assert_equal "WindowObject(.menu)", opt.from_tcl(".menu")
  end

  def test_custom_to_tcl_callback
    # Simulate converting an object to a Tcl path
    opt = Tk::Option.new(
      name: :menu,
      type: :string,
      to_tcl: ->(v, widget:) { v.respond_to?(:path) ? v.path : v.to_s }
    )

    fake_menu = Struct.new(:path).new(".menu")
    assert_equal ".menu", opt.to_tcl(fake_menu)
  end

  def test_custom_callback_receives_widget
    received_widget = nil
    opt = Tk::Option.new(
      name: :test,
      from_tcl: ->(v, widget:) { received_widget = widget; v }
    )

    fake_widget = Object.new
    opt.from_tcl("value", widget: fake_widget)

    assert_same fake_widget, received_widget
  end

  def test_callback_overrides_type_converter
    # Type would convert "42" to integer 42, but callback returns string
    opt = Tk::Option.new(
      name: :special,
      type: :integer,
      from_tcl: ->(v, widget:) { "custom:#{v}" }
    )

    assert_equal "custom:42", opt.from_tcl("42")
  end

  def test_no_callback_uses_type_converter
    opt = Tk::Option.new(name: :width, type: :integer)

    # Without callback, delegates to type
    assert_equal 42, opt.from_tcl("42")
    assert_equal "42", opt.to_tcl(42)
  end
end
