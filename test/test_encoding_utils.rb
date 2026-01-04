# frozen_string_literal: true

# Tests for UTF-8 string handling through the Tcl bridge
#
# Modern Ruby and Tcl both use UTF-8 internally, so no conversion is needed.
# These tests verify strings survive the round-trip correctly.

require_relative 'test_helper'
require 'tcltklib'

class TestEncodingRoundTrip < Minitest::Test
  def setup
    @interp = TclTkIp.new
  end

  def teardown
    @interp.delete if @interp && !@interp.deleted?
  end

  def test_ascii_round_trip
    str = "hello world"
    @interp.tcl_set_var("test", str)
    result = @interp.tcl_get_var("test")
    assert_equal str, result
    assert_equal Encoding::UTF_8, result.encoding
  end

  def test_unicode_round_trip
    str = "日本語テスト"
    @interp.tcl_set_var("test", str)
    result = @interp.tcl_get_var("test")
    assert_equal str, result
    assert result.valid_encoding?
  end

  def test_emoji_round_trip
    str = "🎉 Party! 👋🏽"
    @interp.tcl_set_var("test", str)
    result = @interp.tcl_get_var("test")
    assert_equal str, result
    assert result.valid_encoding?
  end

  def test_mixed_content_round_trip
    str = "Hello 世界 🌍 Emoji 👨‍👩‍👧‍👦 Done"
    @interp.tcl_set_var("test", str)
    result = @interp.tcl_get_var("test")
    assert_equal str, result
  end

  def test_tcl_eval_unicode
    result = @interp.tcl_eval('return "日本語"')
    assert_equal "日本語", result
    assert_equal Encoding::UTF_8, result.encoding
  end

  def test_tcl_invoke_unicode
    @interp.tcl_invoke("set", "test", "カタカナ")
    result = @interp.tcl_invoke("set", "test")
    assert_equal "カタカナ", result
  end

  def test_special_chars
    # Tcl special chars that need proper handling
    str = "braces {} brackets [] dollar $var backslash \\"
    @interp.tcl_set_var("test", str)
    result = @interp.tcl_get_var("test")
    assert_equal str, result
  end
end

# Tests for Tk::Encoding functions
class TestTkEncodingConversion < Minitest::Test
  def setup
    require 'tk'
  end

  # Deprecated but should still work as passthrough
  def test_encoding_convertto_deprecated_but_works
    _out, err = capture_io do
      result = Tk::Encoding.encoding_convertto("hello")
      assert_equal "hello", result
      assert_equal ::Encoding::UTF_8, result.encoding
    end
    assert_match(/deprecated/, err)
  end

  def test_encoding_convertto_unicode_passthrough
    _out, err = capture_io do
      result = Tk::Encoding.encoding_convertto("日本語")
      assert_equal "日本語", result
      assert result.valid_encoding?
    end
    assert_match(/deprecated/, err)
  end

  def test_encoding_convertfrom_deprecated_but_works
    _out, err = capture_io do
      result = Tk::Encoding.encoding_convertfrom("hello")
      assert_equal "hello", result
      assert_equal ::Encoding::UTF_8, result.encoding
    end
    assert_match(/deprecated/, err)
  end

  def test_encoding_names
    names = Tk::Encoding.encoding_names
    assert names.is_a?(Array)
    assert names.include?("utf-8")
  end

  def test_encoding_system
    enc = Tk::Encoding.encoding_system_name
    assert enc.is_a?(String)
    # Modern Tcl uses utf-8 by default
    assert_equal "utf-8", enc
  end
end
