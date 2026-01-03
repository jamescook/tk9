# frozen_string_literal: true

# Unit tests for TkUtil::CallbackSubst (pure Ruby implementation)
#
# CallbackSubst handles Tk's % substitution mechanism for event callbacks.
# When you bind an event like:
#   btn.bind('Button-1') { |e| puts e.x, e.y }
#
# Tk sends back values like "%x %y" which get substituted with actual values.
# CallbackSubst maps these % codes to Ruby attributes and type conversions.

$LOAD_PATH.unshift(File.expand_path('../lib', __dir__))

require 'minitest/autorun'
require 'tk/util'  # Pure Ruby implementation

class TestCallbackSubstRuby < Minitest::Test
  # Create a test subclass with known substitution table
  class TestSubst < TkUtil::CallbackSubst
    # [ char_code, type_char, ivar_symbol ]
    KEY_TBL = [
      [ ?x, ?n, :x ],           # %x -> @x, convert to number
      [ ?y, ?n, :y ],           # %y -> @y, convert to number
      [ ?W, ?s, :widget ],      # %W -> @widget, keep as string
      [ ?K, ?s, :keysym ],      # %K -> @keysym, keep as string
      [ ?s, ?n, :state ],       # %s -> @state, convert to number
      [ ?b, ?b, :button ],      # %b -> @button, convert to bool
    ]

    # [ type_char, conversion_proc ]
    PROC_TBL = [
      [ ?n, proc { |v| v.to_i } ],
      [ ?s, proc { |v| v.to_s } ],
      [ ?b, proc { |v| v != '0' && v != '' } ],
    ]

    _setup_subst_table(KEY_TBL, PROC_TBL)
  end

  def test_setup_subst_table_creates_class
    assert_kind_of Class, TestSubst
    assert TestSubst < TkUtil::CallbackSubst
  end

  # _get_subst_key returns a packed key string where each byte is the
  # character code of the substitution (e.g., "xy" for "%x %y")
  def test_get_subst_key_returns_packed_string
    keys = TestSubst._get_subst_key("%x %y")
    assert_kind_of String, keys
    assert_equal 2, keys.length
    assert_equal [?x.ord, ?y.ord], keys.bytes
  end

  def test_get_subst_key_with_more_substitutions
    keys = TestSubst._get_subst_key("%x %y %W %K")
    assert_equal 4, keys.length
    assert_equal [?x.ord, ?y.ord, ?W.ord, ?K.ord], keys.bytes
  end

  def test_get_subst_key_unknown_keeps_char
    # Unknown substitution keeps its character code
    keys = TestSubst._get_subst_key("%x %Z %y")
    assert_equal 3, keys.length
    assert_equal [?x.ord, ?Z.ord, ?y.ord], keys.bytes
  end

  # scan_args converts string values using the type procs from PROC_TBL
  def test_scan_args_converts_numbers
    keys = TestSubst._get_subst_key("%x %y")
    result = TestSubst.scan_args(keys, ["100", "200"])

    assert_equal 2, result.length
    assert_equal 100, result[0]
    assert_equal 200, result[1]
    assert_kind_of Integer, result[0]
    assert_kind_of Integer, result[1]
  end

  def test_scan_args_keeps_strings
    keys = TestSubst._get_subst_key("%W %K")
    result = TestSubst.scan_args(keys, [".btn", "Return"])

    assert_equal 2, result.length
    assert_equal ".btn", result[0]
    assert_equal "Return", result[1]
  end

  def test_scan_args_mixed_types
    keys = TestSubst._get_subst_key("%x %W %y %K")
    result = TestSubst.scan_args(keys, ["50", ".frame.btn", "75", "space"])

    assert_equal 4, result.length
    assert_equal 50, result[0]            # number
    assert_equal ".frame.btn", result[1]  # string
    assert_equal 75, result[2]            # number
    assert_equal "space", result[3]       # string
  end

  def test_scan_args_bool_conversion
    keys = TestSubst._get_subst_key("%b")

    result_true = TestSubst.scan_args(keys, ["1"])
    assert_equal true, result_true[0]

    result_false = TestSubst.scan_args(keys, ["0"])
    assert_equal false, result_false[0]

    result_empty = TestSubst.scan_args(keys, [""])
    assert_equal false, result_empty[0]
  end

  def test_scan_args_unknown_key_passes_through
    # Unknown substitution (Z) has no type proc, value passes through
    keys = TestSubst._get_subst_key("%x %Z %y")
    result = TestSubst.scan_args(keys, ["10", "unknown_value", "20"])

    assert_equal 10, result[0]
    assert_equal "unknown_value", result[1]  # passed through unchanged
    assert_equal 20, result[2]
  end

  # _sym2subst converts a symbol to its % substitution string
  def test_sym2subst_converts_known_symbols
    result = TestSubst._sym2subst(:x)
    # C version includes trailing space for Tcl list building
    assert_equal "%x ", result
  end

  def test_sym2subst_returns_unknown_symbols_unchanged
    result = TestSubst._sym2subst(:unknown_field)
    assert_equal :unknown_field, result
  end

  def test_sym2subst_returns_non_symbols_unchanged
    result = TestSubst._sym2subst("string")
    assert_equal "string", result
  end

  # _get_all_subst_keys returns [keys_string, subst_string]
  # keys_string has char codes in table order (sorted by char code)
  # subst_string has the % patterns to send to Tcl
  def test_get_all_subst_keys_returns_array
    result = TestSubst._get_all_subst_keys
    assert_kind_of Array, result
    assert_equal 2, result.length

    keys_str, subst_str = result
    assert_kind_of String, keys_str
    assert_kind_of String, subst_str

    # Keys are sorted by char code: K(75), W(87), b(98), s(115), x(120), y(121)
    assert_equal [?K.ord, ?W.ord, ?b.ord, ?s.ord, ?x.ord, ?y.ord], keys_str.bytes
  end

  # ret_val is a hook for subclasses to convert return values
  def test_ret_val_returns_value_unchanged
    assert_equal "test", TestSubst.ret_val("test")
    assert_equal 42, TestSubst.ret_val(42)
    assert_nil TestSubst.ret_val(nil)
  end

  # initialize assigns args to ivars in table order (by char code)
  def test_initialize_assigns_ivars_in_table_order
    # Get all keys in table order
    keys_str, _subst_str = TestSubst._get_all_subst_keys
    # Simulate values from Tcl for each key in order
    # Order is: K, W, b, s, x, y
    values = ["Return", ".btn", "1", "0", "100", "200"]
    args = TestSubst.scan_args(keys_str, values)

    obj = TestSubst.new(*args)

    # Check ivars are set (they're assigned in table order)
    assert_equal "Return", obj.instance_variable_get(:@keysym)
    assert_equal ".btn", obj.instance_variable_get(:@widget)
    assert_equal true, obj.instance_variable_get(:@button)
    assert_equal 0, obj.instance_variable_get(:@state)
    assert_equal 100, obj.instance_variable_get(:@x)
    assert_equal 200, obj.instance_variable_get(:@y)
  end

  # Test with aliases
  class TestSubstWithAliases < TkUtil::CallbackSubst
    KEY_TBL = [
      [ ?b, ?n, :num ],
    ]
    PROC_TBL = [
      [ ?n, proc { |v| v.to_i } ],
    ]
    _setup_subst_table(KEY_TBL, PROC_TBL)
    _define_attribute_aliases({ button: :num })
  end

  def test_define_attribute_aliases
    # :button should map to :num which maps to %b
    result = TestSubstWithAliases._sym2subst(:button)
    assert_equal "%b ", result
  end

  def test_aliased_sym2subst_original_still_works
    result = TestSubstWithAliases._sym2subst(:num)
    assert_equal "%b ", result
  end
end
