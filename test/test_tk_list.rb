# frozen_string_literal: true

# Tests for Tcl list conversion functions in TkComm
#
# These functions convert between Ruby arrays and Tcl list strings.
# The dead Ruby 1.8 encoding branches can be removed once these tests pass.

require_relative 'test_helper'
require 'tk'

class TestArray2TkList < Minitest::Test
  # Include TkComm to access array2tk_list
  include TkComm

  def test_empty_array
    assert_equal "", array2tk_list([])
  end

  def test_simple_strings
    result = array2tk_list(["a", "b", "c"])
    # Should produce space-separated list
    assert_equal "a b c", result
  end

  def test_strings_with_spaces
    result = array2tk_list(["hello world", "foo bar"])
    # Strings with spaces should be braced
    assert_match(/\{hello world\}/, result)
    assert_match(/\{foo bar\}/, result)
  end

  def test_nested_arrays
    result = array2tk_list([["a", "b"], ["c", "d"]])
    # Nested arrays become nested Tcl lists
    assert_includes result, "a b"
    assert_includes result, "c d"
  end

  def test_hash_conversion
    result = array2tk_list([{foo: "bar", baz: "qux"}])
    # Hash keys become -key value pairs
    assert_match(/-foo/, result)
    assert_match(/bar/, result)
    assert_match(/-baz/, result)
    assert_match(/qux/, result)
  end

  def test_mixed_types
    result = array2tk_list([1, "two", :three])
    assert_match(/1/, result)
    assert_match(/two/, result)
    assert_match(/three/, result)
  end

  def test_unicode_strings
    result = array2tk_list(["héllo", "wörld", "日本語"])
    assert_includes result, "héllo"
    assert_includes result, "wörld"
    assert_includes result, "日本語"
  end

  def test_result_encoding
    result = array2tk_list(["hello", "world"])
    # Result should be UTF-8 encoded
    assert_equal Encoding::UTF_8, result.encoding
  end

  def test_special_tcl_chars
    # Braces, brackets, dollar signs need proper handling
    result = array2tk_list(["$var", "[cmd]", "{brace}"])
    # Should be properly escaped/braced
    assert result.is_a?(String)
  end

  def test_nil_elements
    result = array2tk_list(["a", nil, "b"])
    # nil should become empty string
    assert result.is_a?(String)
  end

  def test_boolean_elements
    result = array2tk_list([true, false])
    # Booleans become 1/0
    assert_match(/1/, result)
    assert_match(/0/, result)
  end
end

class TestTkSplitList < Minitest::Test
  include TkComm

  def test_simple_list
    result = tk_split_list("a b c")
    assert_equal ["a", "b", "c"], result
  end

  def test_braced_elements
    result = tk_split_list("{hello world} foo")
    # Braced elements are recursively parsed
    assert_equal [["hello", "world"], "foo"], result
  end

  def test_nested_list
    result = tk_split_list("{a b} {c d}")
    # Nested lists are recursively parsed
    assert_equal [["a", "b"], ["c", "d"]], result
  end

  def test_empty_string
    result = tk_split_list("")
    assert_equal [], result
  end

  def test_unicode
    result = tk_split_list("hello 世界")
    assert_equal ["hello", "世界"], result
  end
end
