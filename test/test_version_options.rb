# frozen_string_literal: true

require_relative 'test_helper'
require_relative 'tk_test_helper'
require 'tk/version_options'

class TestVersionOptions < Minitest::Test
  def test_min_version_returns_version_string
    assert_equal '9.0', Tk::VersionOptions.min_version('ttk::entry', 'placeholder')
  end

  def test_min_version_returns_nil_for_universal_options
    assert_nil Tk::VersionOptions.min_version('ttk::entry', 'width')
  end

  def test_available_true_when_version_sufficient
    assert Tk::VersionOptions.available?('ttk::entry', 'placeholder', '9.0')
  end

  def test_available_false_when_version_insufficient
    refute Tk::VersionOptions.available?('ttk::entry', 'placeholder', '8.6')
  end

  def test_future_option_dsl_registers_option
    require 'tk/option_dsl'

    klass = Class.new do
      extend Tk::OptionDSL
      future_option :placeholder, min_version: '9.0'
    end

    assert_includes klass.future_option_names, :placeholder
  end

  def test_future_option_knows_min_version
    require 'tk/option_dsl'

    klass = Class.new do
      extend Tk::OptionDSL
      future_option :placeholder, min_version: '9.0'
    end

    info = klass.future_option_info(:placeholder)
    assert_equal '9.0', info[:min_version]
  end

  def test_generator_emits_future_option_for_old_version
    require 'tk/option_generator'

    entry = Tk::OptionGenerator::OptionEntry.new(
      name: 'placeholder',
      db_name: 'placeHolder',
      db_class: 'PlaceHolder',
      default: ''
    )

    # When generating for 8.6 and option requires 9.0, emit future_option
    dsl = entry.to_dsl(widget_cmd: 'ttk::entry', target_version: '8.6')
    assert_includes dsl, "future_option :placeholder"
    assert_includes dsl, "min_version: '9.0'"
  end

  def test_generator_emits_regular_option_for_current_version
    require 'tk/option_generator'

    entry = Tk::OptionGenerator::OptionEntry.new(
      name: 'placeholder',
      db_name: 'placeHolder',
      db_class: 'PlaceHolder',
      default: ''
    )

    # When generating for 9.0 and option requires 9.0, emit regular option
    dsl = entry.to_dsl(widget_cmd: 'ttk::entry', target_version: '9.0')
    assert_includes dsl, "option :placeholder"
    refute_includes dsl, "future_option"
  end

  # Verify the system works for any future version, not just 8.6/9.0
  def test_generator_handles_future_versions
    require 'tk/option_generator'

    # Simulate a 9.1 option
    Tk::VersionOptions::OPTION_VERSIONS['ttk::entry']['hypothetical'] = { min_version: '9.1' }

    entry = Tk::OptionGenerator::OptionEntry.new(
      name: 'hypothetical',
      db_name: 'hypothetical',
      db_class: 'Hypothetical',
      default: ''
    )

    # 8.6 -> future_option
    dsl_86 = entry.to_dsl(widget_cmd: 'ttk::entry', target_version: '8.6')
    assert_includes dsl_86, "future_option :hypothetical, min_version: '9.1'"

    # 9.0 -> future_option (still not available)
    dsl_90 = entry.to_dsl(widget_cmd: 'ttk::entry', target_version: '9.0')
    assert_includes dsl_90, "future_option :hypothetical, min_version: '9.1'"

    # 9.1 -> regular option
    dsl_91 = entry.to_dsl(widget_cmd: 'ttk::entry', target_version: '9.1')
    assert_includes dsl_91, "option :hypothetical"
    refute_includes dsl_91, "future_option"

    # 10.0 -> regular option
    dsl_100 = entry.to_dsl(widget_cmd: 'ttk::entry', target_version: '10.0')
    assert_includes dsl_100, "option :hypothetical"
  ensure
    Tk::VersionOptions::OPTION_VERSIONS['ttk::entry'].delete('hypothetical')
  end
end

class TestVersionMismatchBehavior < Minitest::Test
  include TkTestHelper

  def test_version_mismatch_default_is_warn
    assert_tk_app("version_mismatch default", method(:app_default_mode))
  end

  def app_default_mode
    require 'tk'
    actual = Tk.version_mismatch
    raise "expected :warn, got #{actual.inspect}" unless actual == :warn
  end

  def test_version_mismatch_can_be_set
    assert_tk_app("version_mismatch setter", method(:app_set_mode))
  end

  def app_set_mode
    require 'tk'
    Tk.version_mismatch = :ignore
    raise "expected :ignore" unless Tk.version_mismatch == :ignore

    Tk.version_mismatch = :raise
    raise "expected :raise" unless Tk.version_mismatch == :raise
  end

  def test_version_mismatch_rejects_invalid
    assert_tk_app("version_mismatch invalid", method(:app_invalid_mode))
  end

  def app_invalid_mode
    require 'tk'
    begin
      Tk.version_mismatch = :invalid
      raise "should have raised ArgumentError"
    rescue ArgumentError
      # expected
    end
  end
end
