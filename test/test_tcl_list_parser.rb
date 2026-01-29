# frozen_string_literal: true

# Tests for the pure Ruby Tcl list parser
#
# The parser handles Tcl list format:
# - Whitespace-separated elements
# - Braced grouping for elements with spaces
# - Quoted strings
# - Backslash escapes
# - Nested braces

require_relative 'test_helper'
require 'tk/tcl_list_parser'

class TestTclListParser < Minitest::Test
  def parse(str)
    Tk::TclListParser.parse(str)
  end

  # Basic whitespace-separated elements
  def test_simple_elements
    assert_equal %w[a b c], parse("a b c")
    assert_equal %w[foo bar baz], parse("foo bar baz")
    assert_equal %w[one], parse("one")
  end

  def test_empty_input
    assert_equal [], parse("")
    assert_equal [], parse(nil)
    assert_equal [], parse("   ")
    assert_equal [], parse("\t\n")
  end

  def test_various_whitespace
    assert_equal %w[a b c], parse("a  b  c")
    assert_equal %w[a b c], parse("a\tb\tc")
    assert_equal %w[a b c], parse("a\nb\nc")
    assert_equal %w[a b c], parse("  a  b  c  ")
  end

  # Braced elements
  def test_braced_element
    assert_equal ["hello world"], parse("{hello world}")
    assert_equal ["hello world", "foo"], parse("{hello world} foo")
    assert_equal ["a", "b c", "d"], parse("a {b c} d")
  end

  def test_nested_braces
    assert_equal ["a {b c} d"], parse("{a {b c} d}")
    assert_equal ["{nested}"], parse("{{nested}}")
    assert_equal ["a {b {c}} d"], parse("{a {b {c}} d}")
  end

  def test_empty_braces
    assert_equal [""], parse("{}")
    assert_equal ["", "a"], parse("{} a")
    assert_equal ["a", "", "b"], parse("a {} b")
  end

  # Quoted strings
  def test_quoted_element
    assert_equal ["hello world"], parse('"hello world"')
    assert_equal ["hello world", "foo"], parse('"hello world" foo')
  end

  # Backslash escapes
  def test_backslash_in_braces
    # Backslash prevents brace from being interpreted
    assert_equal ['a \{ b'], parse('{a \{ b}')
    assert_equal ['a \} b'], parse('{a \} b}')
  end

  def test_backslash_in_unbraced
    # Backslash in unbraced element
    assert_equal ['a\ b'], parse('a\ b')
  end

  # Real-world Tcl output patterns
  def test_widget_list
    # Output from [winfo children .]
    assert_equal %w[.frame .button .label], parse(".frame .button .label")
  end

  def test_option_list
    # Output from [.button configure -text]
    assert_equal ["-text", "text", "Text", "", "Click Me"],
                 parse("-text text Text {} {Click Me}")
  end

  def test_callback_queue_entry
    # Format used by our callback queue: {callback_id arg1 arg2}
    assert_equal ["cb_1", ".button", "42", "100"],
                 parse("{cb_1 .button 42 100}").then { |a| parse(a.first) }
  end

  def test_multiple_callback_entries
    # Multiple callbacks queued: {cb_1 args} {cb_2 args}
    queue = "{cb_1 .btn1} {cb_2 .btn2 123}"
    entries = parse(queue)
    assert_equal 2, entries.length
    assert_equal "cb_1 .btn1", entries[0]
    assert_equal "cb_2 .btn2 123", entries[1]
  end

  # Edge cases
  def test_numbers
    assert_equal %w[1 2 3], parse("1 2 3")
    assert_equal %w[3.14 2.718], parse("3.14 2.718")
  end

  def test_special_characters
    assert_equal %w[$ @ # %], parse("$ @ # %")
    assert_equal ["[expr 1+1]"], parse("{[expr 1+1]}")
  end

  def test_unicode
    assert_equal %w[hello 世界 foo], parse("hello 世界 foo")
    assert_equal ["日本語 テスト"], parse("{日本語 テスト}")
  end

  def test_long_list
    # Simulate a list with many elements (like widget children)
    elements = (1..100).map { |i| "item#{i}" }
    input = elements.join(" ")
    assert_equal elements, parse(input)
  end
end
