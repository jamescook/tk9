# frozen_string_literal: true

# Tests for tk_tcl2ruby - the Tcl->Ruby type coercion function
#
# This function converts Tcl string values to appropriate Ruby objects.
# It's on the hot path for all Tk widget property access.

require_relative 'test_helper'
require 'tk'

class TestTkTcl2Ruby < Minitest::Test
  include TkComm

  # --- Integer conversion ---

  def test_positive_integer
    assert_equal 42, tk_tcl2ruby("42")
  end

  def test_negative_integer
    assert_equal(-7, tk_tcl2ruby("-7"))
  end

  def test_zero
    assert_equal 0, tk_tcl2ruby("0")
  end

  def test_large_integer
    assert_equal 123456789, tk_tcl2ruby("123456789")
  end

  # --- Float conversion ---

  def test_simple_float
    assert_equal 3.14, tk_tcl2ruby("3.14")
  end

  def test_negative_float
    assert_equal(-2.5, tk_tcl2ruby("-2.5"))
  end

  def test_float_no_decimal
    # "42." should match float pattern
    assert_equal 42.0, tk_tcl2ruby("42.")
  end

  def test_scientific_notation
    assert_equal 1.5e10, tk_tcl2ruby("1.5e10")
  end

  def test_scientific_notation_negative_exponent
    assert_equal 1.5e-10, tk_tcl2ruby("1.5e-10")
  end

  def test_scientific_notation_positive_exponent
    assert_equal 1.5e+10, tk_tcl2ruby("1.5e+10")
  end

  # --- Plain string passthrough ---

  def test_plain_string
    assert_equal "hello", tk_tcl2ruby("hello")
  end

  def test_empty_string
    assert_equal "", tk_tcl2ruby("")
  end

  def test_string_with_special_chars
    assert_equal "foo-bar_baz", tk_tcl2ruby("foo-bar_baz")
  end

  # --- Escaped space handling ---

  def test_escaped_space
    assert_equal "hello world", tk_tcl2ruby("hello\\ world")
  end

  def test_multiple_escaped_spaces
    assert_equal "a b c", tk_tcl2ruby("a\\ b\\ c")
  end

  # --- List conversion (unescaped spaces) ---

  def test_simple_list
    result = tk_tcl2ruby("a b c")
    assert_equal ["a", "b", "c"], result
  end

  def test_list_with_integers
    result = tk_tcl2ruby("1 2 3")
    assert_equal [1, 2, 3], result
  end

  def test_list_with_mixed_types
    result = tk_tcl2ruby("hello 42 3.14")
    assert_equal ["hello", 42, 3.14], result
  end

  def test_list_disabled_returns_string
    # When listobj=false, don't parse as list
    result = tk_tcl2ruby("a b c", false, false)
    assert_equal "a b c", result
  end

  def test_deeply_nested_list
    result = tk_tcl2ruby("{a b} {c d}")
    assert_equal [["a", "b"], ["c", "d"]], result
  end

  # --- Callback reference (mock the lookup table) ---

  def test_callback_reference
    # Directly inject into callback table
    mock_proc = proc { "test" }
    TkCore::INTERP.tk_cmd_tbl["c99999"] = mock_proc

    result = tk_tcl2ruby("rb_out c99999")
    assert_same mock_proc, result
  ensure
    TkCore::INTERP.tk_cmd_tbl.delete("c99999")
  end

  def test_callback_with_namespace
    mock_proc = proc { "namespaced" }
    TkCore::INTERP.tk_cmd_tbl["c88888"] = mock_proc

    result = tk_tcl2ruby("rb_out ::myns c88888")
    assert_same mock_proc, result
  ensure
    TkCore::INTERP.tk_cmd_tbl.delete("c88888")
  end

  def test_callback_with_braced_namespace
    mock_proc = proc { "braced" }
    TkCore::INTERP.tk_cmd_tbl["c77777"] = mock_proc

    result = tk_tcl2ruby("rb_out {::my::ns} c77777")
    assert_same mock_proc, result
  ensure
    TkCore::INTERP.tk_cmd_tbl.delete("c77777")
  end

  # --- Widget path conversion (mock the lookup table) ---

  def test_widget_path_returns_registered_widget
    mock_widget = Object.new
    TkCore::INTERP.tk_windows[".mock_widget"] = mock_widget

    result = tk_tcl2ruby(".mock_widget")
    assert_same mock_widget, result
  ensure
    TkCore::INTERP.tk_windows.delete(".mock_widget")
  end

  def test_nested_widget_path
    mock_widget = Object.new
    TkCore::INTERP.tk_windows[".frame.button"] = mock_widget

    result = tk_tcl2ruby(".frame.button")
    assert_same mock_widget, result
  ensure
    TkCore::INTERP.tk_windows.delete(".frame.button")
  end

  def test_unregistered_widget_path_calls_genobj
    # Path looks like widget but not registered - should try to create wrapper
    # We can't easily test _genobj_for_tkwidget without real Tk, so just verify
    # it doesn't crash and returns something
    result = tk_tcl2ruby(".nonexistent_widget_xyz")
    assert result
  end

  # --- Image conversion (mock the lookup table) ---

  def test_image_reference
    mock_image = Object.new
    TkImage::Tk_IMGTBL.mutex.synchronize do
      TkImage::Tk_IMGTBL["i12345"] = mock_image
    end

    result = tk_tcl2ruby("i12345")
    assert_same mock_image, result
  ensure
    TkImage::Tk_IMGTBL.mutex.synchronize do
      TkImage::Tk_IMGTBL.delete("i12345")
    end
  end

  def test_image_with_underscore_format
    mock_image = Object.new
    TkImage::Tk_IMGTBL.mutex.synchronize do
      TkImage::Tk_IMGTBL["i_1_999"] = mock_image
    end

    result = tk_tcl2ruby("i_1_999")
    assert_same mock_image, result
  ensure
    TkImage::Tk_IMGTBL.mutex.synchronize do
      TkImage::Tk_IMGTBL.delete("i_1_999")
    end
  end

  def test_unregistered_image_returns_string
    # Image name pattern but not in table - returns the string
    result = tk_tcl2ruby("i99999")
    assert_equal "i99999", result
  end

  # --- Font conversion removed ---
  # TkFont class was removed - fonts are now just strings passed through to Tcl/Tk.
  # The @fontXXX pattern is no longer handled specially.

  def test_font_string_passthrough
    # Font strings are now returned as-is (no TkFont lookup)
    result = tk_tcl2ruby("@font12345")
    assert_equal "@font12345", result
  end

  # --- Edge cases ---

  def test_string_starting_with_dot_but_not_widget_pattern
    # ".5" matches widget pattern (\.\S*), not float
    # This is arguably a bug but documents current behavior
    result = tk_tcl2ruby(".5")
    # Will try to look up as widget, fail, call _genobj_for_tkwidget
    assert result
  end

  def test_leading_zeros_become_integer
    # "007" converts to integer 7
    result = tk_tcl2ruby("007")
    assert_equal 7, result
  end

  def test_hex_string_not_converted
    # "0xff" should NOT be converted to integer (doesn't match -?\d+)
    result = tk_tcl2ruby("0xff")
    assert_equal "0xff", result
  end

  def test_boolean_strings_not_converted
    # Tcl uses 1/0 for booleans, not true/false strings
    assert_equal "true", tk_tcl2ruby("true")
    assert_equal "false", tk_tcl2ruby("false")
  end

  def test_string_with_backslash_not_space
    # Backslash followed by something other than space
    result = tk_tcl2ruby("hello\\nworld")
    assert_equal "hello\\nworld", result
  end
end
