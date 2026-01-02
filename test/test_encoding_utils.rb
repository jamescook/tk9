# frozen_string_literal: true

# Tests for UTF-8 string handling through the Tcl bridge
#
# Modern Ruby and Tcl both use UTF-8 internally, so no conversion is needed.
# These tests verify strings survive the round-trip correctly.

require 'minitest/autorun'
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
