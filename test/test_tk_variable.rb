# frozen_string_literal: true

# Tests for TkVariable - Tcl variable wrapper
#
# TkVariable wraps Tcl variables for use in Ruby. It supports both scalar
# variables and associative arrays (hashes).
#
# These tests exercise the USE_TCLs_SET_VARIABLE_FUNCTIONS=true code path
# which uses direct Tcl C API calls (tcl_get_var, tcl_set_var, etc.)
# rather than eval-based variable access.

require_relative 'test_helper'
require_relative 'tk_test_helper'
require 'tk'

class TestTkVariable < Minitest::Test
  def setup
    @created_vars = []
  end

  def teardown
    # Clean up any variables created during the test
    @created_vars.each { |var| var.unset }
  end

  # Helper to create and track a TkVariable for cleanup
  def make_var(*args)
    var = TkVariable.new(*args)
    @created_vars << var
    var
  end

  # --- Scalar Variables ---

  def test_new_with_string
    var = make_var("hello")
    assert_equal "hello", var.value
  end

  def test_new_with_empty_string
    var = make_var
    assert_equal "", var.value
  end

  def test_new_with_integer
    var = make_var(42)
    assert_equal "42", var.value
  end

  def test_value_assignment
    var = make_var("initial")
    var.value = "changed"
    assert_equal "changed", var.value
  end

  def test_is_scalar
    var = make_var("hello")
    assert var.is_scalar?
    refute var.is_hash?
  end

  def test_to_s
    var = make_var("hello")
    assert_equal "hello", var.to_s
  end

  def test_to_i
    var = make_var("42")
    assert_equal 42, var.to_i
  end

  def test_to_f
    var = make_var("3.14")
    assert_in_delta 3.14, var.to_f, 0.001
  end

  def test_numeric
    var = make_var("42")
    assert_equal 42, var.numeric
  end

  def test_exist_scalar
    var = make_var("hello")
    assert var.exist?
  end

  def test_unset_scalar
    var = make_var("hello")
    var.unset
    refute var.exist?
  end

  # --- Hash/Array Variables ---

  def test_new_with_hash
    var = make_var({})
    assert var.is_hash?
    refute var.is_scalar?
  end

  def test_hash_set_and_get
    var = make_var({})
    var["key1"] = "value1"
    var["key2"] = "value2"
    assert_equal "value1", var["key1"]
    assert_equal "value2", var["key2"]
  end

  def test_hash_keys
    var = make_var({})
    var["a"] = "1"
    var["b"] = "2"
    assert_equal ["a", "b"], var.keys.sort
  end

  def test_hash_size
    var = make_var({})
    var["a"] = "1"
    var["b"] = "2"
    var["c"] = "3"
    assert_equal 3, var.size
  end

  def test_hash_clear
    var = make_var({})
    var["a"] = "1"
    var["b"] = "2"
    var.clear
    assert_equal 0, var.size
  end

  def test_hash_unset_element
    var = make_var({})
    var["a"] = "1"
    var["b"] = "2"
    var.unset("a")
    assert_equal 1, var.size
    assert var.exist?("b")
    refute var.exist?("a")
  end

  def test_hash_with_initial_values
    var = make_var({"x" => "10", "y" => "20"})
    assert_equal 2, var.size
    assert_equal "10", var["x"]
    assert_equal "20", var["y"]
  end

  def test_hash_update
    var = make_var({})
    var["a"] = "1"
    var.update({"b" => "2", "c" => "3"})
    assert_equal 3, var.size
  end

  def test_to_hash
    var = make_var({"a" => "1", "b" => "2"})
    h = var.to_hash
    assert_kind_of Hash, h
    assert_equal 2, h.size
  end

  # --- Multi-index element access ---

  def test_multi_index_set_and_get
    var = make_var({})
    var["x", "y"] = "coord"
    assert_equal "coord", var["x", "y"]
  end

  # --- Variable ID and reference ---

  def test_id
    var = make_var("test")
    assert var.id.start_with?("v")
  end

  def test_inspect
    var = make_var("test")
    assert_includes var.inspect, "TkVariable"
  end

  # --- TkVarAccess ---

  def test_tkvaraccess_new
    var = make_var("hello")
    access = TkVarAccess.new(var.id)
    @created_vars << access  # track for cleanup
    assert_equal var.value, access.value
  end

  def test_tkvaraccess_set_value
    var = make_var("initial")
    access = TkVarAccess.new(var.id)
    @created_vars << access  # track for cleanup
    access.value = "changed"
    assert_equal "changed", var.value
  end

  # --- Bool type ---

  def test_bool_true_values
    var = make_var("1")
    assert_equal true, var.bool

    var.value = "true"
    assert_equal true, var.bool

    var.value = "yes"
    assert_equal true, var.bool

    var.value = "on"
    assert_equal true, var.bool
  end

  def test_bool_false_values
    var = make_var("0")
    assert_equal false, var.bool

    var.value = "false"
    assert_equal false, var.bool

    var.value = "no"
    assert_equal false, var.bool

    var.value = "off"
    assert_equal false, var.bool
  end

  def test_set_bool
    var = make_var("")
    var.bool = true
    assert_equal "1", var.value

    var.bool = false
    assert_equal "0", var.value
  end

  # --- List operations ---

  def test_list
    var = make_var("a b c")
    assert_equal ["a", "b", "c"], var.list
  end

  def test_lappend
    var = make_var("a b")
    var.lappend("c", "d")
    assert_equal ["a", "b", "c", "d"], var.list
  end

  # --- Comparison and equality ---

  def test_equality_with_string
    var = make_var("hello")
    assert_equal "hello", var
    refute_equal "world", var
  end

  def test_equality_with_integer
    var = make_var("42")
    assert_equal 42, var
  end

  def test_spaceship_operator
    var = make_var("5")
    assert_operator var, :<, 10
    assert_operator var, :>, 3
    assert_equal 0, var <=> 5
  end

  # --- Type System ---
  # TkVariable can auto-convert values to specific Ruby types

  def test_default_value_type_numeric
    var = make_var("42")
    var.default_value_type = :numeric
    assert_equal :numeric, var.default_value_type
    # value should now return a number, not string
    assert_kind_of Numeric, var.value
    assert_equal 42, var.value
  end

  def test_default_value_type_bool
    var = make_var("1")
    var.default_value_type = :bool
    assert_equal :bool, var.default_value_type
    assert_equal true, var.value

    var.value = "0"
    assert_equal false, var.value
  end

  def test_default_value_type_string
    var = make_var("hello")
    var.default_value_type = :string
    assert_equal :string, var.default_value_type
    assert_kind_of String, var.value
  end

  def test_default_value_type_symbol
    var = make_var("hello")
    var.default_value_type = :symbol
    assert_equal :symbol, var.default_value_type
    assert_kind_of Symbol, var.value
    assert_equal :hello, var.value
  end

  def test_default_value_type_list
    var = make_var("a b c")
    var.default_value_type = :list
    assert_equal :list, var.default_value_type
    assert_kind_of Array, var.value
    assert_equal ["a", "b", "c"], var.value
  end

  def test_default_value_type_numlist
    var = make_var("1 2 3")
    var.default_value_type = :numlist
    assert_equal :numlist, var.default_value_type
    assert_kind_of Array, var.value
    assert_equal [1, 2, 3], var.value
  end

  def test_default_value_type_nil_returns_raw
    var = make_var("42")
    var.default_value_type = nil
    assert_nil var.default_value_type
    # Without type, returns raw string
    assert_kind_of String, var.value
    assert_equal "42", var.value
  end

  def test_set_numeric_type
    var = make_var("")
    var.set_numeric_type(123)
    assert_equal :numeric, var.default_value_type
    assert_equal 123, var.value
  end

  def test_set_bool_type
    var = make_var("")
    var.set_bool_type(true)
    assert_equal :bool, var.default_value_type
    assert_equal true, var.value
  end

  def test_set_string_type
    var = make_var("")
    var.set_string_type("hello")
    assert_equal :string, var.default_value_type
    assert_equal "hello", var.value
  end

  def test_set_symbol_type
    var = make_var("")
    var.set_symbol_type(:world)
    assert_equal :symbol, var.default_value_type
    assert_equal :world, var.value
  end

  def test_set_list_type
    var = make_var("")
    var.set_list_type(["a", "b", "c"])
    assert_equal :list, var.default_value_type
    assert_equal ["a", "b", "c"], var.value
  end

  def test_set_numlist_type
    var = make_var("")
    var.set_numlist_type([1, 2, 3])
    assert_equal :numlist, var.default_value_type
    assert_equal [1, 2, 3], var.value
  end

  # --- Element-level type system (for hash variables) ---

  def test_default_element_value_type
    var = make_var({})
    var["count"] = "42"
    var["name"] = "test"

    # Set type for specific element
    var.set_default_element_value_type("count", :numeric)

    # count should return as number
    assert_equal 42, var["count"]
    # name should still return as string (no type set)
    assert_equal "test", var["name"]
  end

  def test_element_type_independence
    var = make_var({})
    var["num"] = "100"
    var["flag"] = "1"
    var["items"] = "a b c"

    var.set_default_element_value_type("num", :numeric)
    var.set_default_element_value_type("flag", :bool)
    var.set_default_element_value_type("items", :list)

    assert_equal 100, var["num"]
    assert_equal true, var["flag"]
    assert_equal ["a", "b", "c"], var["items"]
  end

  def test_set_numeric_element_type
    var = make_var({})
    var.set_numeric_element_type("x", 42)
    assert_equal 42, var["x"]
    assert_equal :numeric, var.default_element_value_type("x")
  end

  def test_set_bool_element_type
    var = make_var({})
    var.set_bool_element_type("enabled", true)
    assert_equal true, var["enabled"]
    assert_equal :bool, var.default_element_value_type("enabled")
  end

  def test_set_string_element_type
    var = make_var({})
    var.set_string_element_type("name", "hello")
    assert_equal "hello", var["name"]
    assert_equal :string, var.default_element_value_type("name")
  end

  def test_set_symbol_element_type
    var = make_var({})
    var.set_symbol_element_type("status", :active)
    assert_equal :active, var["status"]
    assert_equal :symbol, var.default_element_value_type("status")
  end

  def test_set_list_element_type
    var = make_var({})
    var.set_list_element_type("items", ["a", "b"])
    assert_equal ["a", "b"], var["items"]
    assert_equal :list, var.default_element_value_type("items")
  end

  # --- Type coercion from Class constants ---

  def test_type_from_numeric_class
    var = make_var("42")
    var.default_value_type = Numeric
    assert_equal 42, var.value
  end

  def test_type_from_string_class
    var = make_var("hello")
    var.default_value_type = String
    assert_equal "hello", var.value
  end

  def test_type_from_symbol_class
    var = make_var("hello")
    var.default_value_type = Symbol
    assert_equal :hello, var.value
  end

  def test_type_from_array_class
    var = make_var("a b c")
    var.default_value_type = Array
    assert_equal ["a", "b", "c"], var.value
  end

  def test_type_from_trueclass
    var = make_var("1")
    var.default_value_type = TrueClass
    assert_equal true, var.value
  end

  def test_type_from_falseclass
    var = make_var("0")
    var.default_value_type = FalseClass
    assert_equal false, var.value
  end

  # --- Default values for hash variables ---
  # The default_value feature provides fallbacks when Tcl raises an error
  # accessing a non-existent array element. Note: Tcl may return empty string
  # for missing elements rather than raising, so this mainly works when the
  # variable itself doesn't exist or for true array errors.

  def test_default_value_returns_self
    var = make_var({})
    result = var.default_value("fallback")
    assert_same var, result  # Returns self for chaining
  end

  def test_default_value_sets_def_default_to_val
    var = make_var({})
    var.default_value("test")
    # Internal state should be set (we can't directly test @def_default)
    # but we can verify the method runs without error
    assert_kind_of TkVariable, var
  end

  def test_default_proc_returns_self
    var = make_var({})
    result = var.default_proc { |v, *keys| "default" }
    assert_same var, result
  end

  def test_default_value_assignment_returns_self
    var = make_var({})
    result = var.set_default_value("assigned default")
    assert_same var, result
  end

  def test_undef_default_returns_self
    var = make_var({})
    var.default_value("fallback")
    result = var.undef_default
    assert_same var, result
  end

  # --- Arithmetic Operators ---

  def test_unary_plus
    var = make_var("42")
    assert_equal 42, +var
  end

  def test_unary_minus
    var = make_var("42")
    assert_equal(-42, -var)
  end

  def test_addition_with_number
    var = make_var("10")
    assert_equal 15, var + 5
  end

  def test_addition_with_string
    var = make_var("hello")
    assert_equal "hello world", var + " world"
  end

  def test_addition_with_array
    var = make_var("a b")
    result = var + ["c"]
    assert_equal ["a", "b", "c"], result
  end

  def test_subtraction_with_number
    var = make_var("10")
    assert_equal 5, var - 5
  end

  def test_subtraction_with_array
    var = make_var("a b c")
    result = var - ["b"]
    assert_equal ["a", "c"], result
  end

  def test_multiplication_with_number
    var = make_var("5")
    assert_equal 25, var * 5
  end

  def test_multiplication_with_string_repeat
    var = make_var("ab")
    assert_equal "ababab", var * 3
  end

  def test_division
    var = make_var("20")
    assert_equal 4, var / 5
  end

  def test_modulo_with_number
    var = make_var("17")
    assert_equal 2, var % 5
  end

  def test_modulo_with_string_format
    var = make_var("value: %d")
    assert_equal "value: 42", var % 42
  end

  def test_exponentiation
    var = make_var("2")
    assert_equal 8, var ** 3
  end

  def test_bitwise_and_with_integers
    var = make_var("7")  # binary: 111
    assert_equal 3, var & 3  # binary: 011, result: 011 = 3
  end

  def test_bitwise_and_with_arrays
    var = make_var("a b c d")
    result = var & ["b", "d", "e"]
    assert_equal ["b", "d"], result
  end

  def test_bitwise_or_with_integers
    var = make_var("5")  # binary: 101
    assert_equal 7, var | 2  # binary: 010, result: 111 = 7
  end

  def test_bitwise_or_with_arrays
    var = make_var("a b")
    result = var | ["b", "c"]
    assert_equal ["a", "b", "c"], result
  end

  def test_coerce_with_numeric
    var = make_var("10")
    a, b = var.coerce(5)
    assert_equal 5, a
    assert_equal 10, b
  end

  def test_coerce_with_string
    var = make_var("hello")
    a, b = var.coerce("world")
    assert_equal "world", a
    assert_equal "hello", b
  end

  def test_coerce_with_symbol
    var = make_var("test")
    a, b = var.coerce(:foo)
    assert_equal :foo, a
    assert_equal :test, b
  end

  def test_coerce_with_array
    var = make_var("a b c")
    a, b = var.coerce([1, 2])
    assert_equal [1, 2], a
    assert_equal ["a", "b", "c"], b
  end

  def test_coerce_enables_reverse_operations
    var = make_var("10")
    # Ruby calls coerce when left operand doesn't know how to handle right
    assert_equal 15, 5 + var
    assert_equal 50, 5 * var
  end

  # --- Zero/Nonzero ---

  def test_zero_true
    var = make_var("0")
    assert var.zero?
  end

  def test_zero_false
    var = make_var("42")
    refute var.zero?
  end

  def test_nonzero_true
    var = make_var("42")
    assert var.nonzero?
  end

  def test_nonzero_false
    var = make_var("0")
    refute var.nonzero?
  end

  # --- Pattern matching ---

  def test_regex_match
    var = make_var("hello world")
    assert_match(/world/, var)
    assert var =~ /hello/
    assert_nil var =~ /xyz/
  end

  # --- Case equality ---

  def test_case_equality_same_id
    var1 = make_var("test")
    # Same variable (same id) should be ===
    assert var1 === var1
  end

  def test_case_equality_different_vars
    var1 = make_var("test")
    var2 = make_var("test")
    # Different variables (different ids) should not be ===
    refute var1 === var2
  end

  # --- List operations ---

  def test_lindex
    var = make_var("a b c d")
    assert_equal "b", var.lindex(1)
    assert_equal "d", var.lindex(3)
  end

  def test_lset
    var = make_var("a b c")
    var.lset(1, "X")
    assert_equal ["a", "X", "c"], var.list
  end

  def test_numlist
    var = make_var("1 2 3 4")
    result = var.numlist
    assert_equal [1, 2, 3, 4], result
    assert result.all? { |v| v.is_a?(Numeric) }
  end

  def test_lget_i
    var = make_var("10 20 30")
    assert_equal 20, var.lget_i(1)
    assert_kind_of Integer, var.lget_i(1)
  end

  def test_lget_f
    var = make_var("1.5 2.5 3.5")
    assert_in_delta 2.5, var.lget_f(1), 0.001
    assert_kind_of Float, var.lget_f(1)
  end

  # --- Ref method ---

  def test_ref
    var = make_var({})
    var["x"] = "10"

    ref = var.ref("x")
    assert_kind_of TkVarAccess, ref
    assert_equal "10", ref.value
  end

  def test_ref_multi_index
    var = make_var({})
    var["a", "b"] = "multi"

    ref = var.ref("a", "b")
    assert_kind_of TkVarAccess, ref
    assert_equal "multi", ref.value
  end

  # --- to_a and to_ary aliases ---

  def test_to_a
    var = make_var("x y z")
    assert_equal ["x", "y", "z"], var.to_a
  end

  def test_to_ary
    var = make_var("1 2 3")
    assert_equal ["1", "2", "3"], var.to_ary
  end

  # --- to_sym and symbol ---

  def test_to_sym
    var = make_var("my_symbol")
    assert_equal :my_symbol, var.to_sym
  end

  def test_symbol_alias
    var = make_var("test_sym")
    assert_equal :test_sym, var.symbol
  end

  # --- Numeric element operations ---

  def test_numeric_element
    var = make_var({})
    var["count"] = "42"
    assert_equal 42, var.numeric_element("count")
  end

  def test_set_numeric
    var = make_var("")
    var.set_numeric(100)
    assert_equal 100, var.numeric
  end

  def test_set_numeric_from_tkvariable
    var1 = make_var("50")
    var2 = make_var("")
    var2.set_numeric(var1)
    assert_equal 50, var2.numeric
  end

  def test_set_numeric_rejects_non_numeric
    var = make_var("")
    assert_raises(ArgumentError) { var.set_numeric("not a number") }
  end

  # --- Bool element operations ---

  def test_bool_element
    var = make_var({})
    var["flag"] = "1"
    assert_equal true, var.bool_element("flag")

    var["other"] = "0"
    assert_equal false, var.bool_element("other")
  end

  def test_set_bool_element
    var = make_var({})
    var.set_bool_element("enabled", true)
    assert_equal "1", var["enabled"]

    var.set_bool_element("disabled", false)
    assert_equal "0", var["disabled"]
  end

  # --- String element operations ---

  def test_string_element
    var = make_var({})
    var["name"] = "test"
    assert_equal "test", var.string_element("name")
  end

  def test_element_to_s
    var = make_var({})
    var["key"] = "value"
    assert_equal "value", var.element_to_s("key")
  end

  # --- Symbol element operations ---

  def test_symbol_element
    var = make_var({})
    var["status"] = "active"
    assert_equal :active, var.symbol_element("status")
  end

  def test_element_to_sym
    var = make_var({})
    var["type"] = "widget"
    assert_equal :widget, var.element_to_sym("type")
  end

  # --- List element operations ---

  def test_list_element
    var = make_var({})
    var["items"] = "a b c"
    assert_equal ["a", "b", "c"], var.list_element("items")
  end

  def test_numlist_element
    var = make_var({})
    var["nums"] = "1 2 3"
    assert_equal [1, 2, 3], var.numlist_element("nums")
  end

  def test_element_lappend
    var = make_var({})
    var["list"] = "a b"
    var.element_lappend("list", "c", "d")
    assert_equal ["a", "b", "c", "d"], var.list_element("list")
  end

  def test_element_lindex
    var = make_var({})
    var["items"] = "x y z"
    assert_equal "y", var.element_lindex("items", 1)
  end

  def test_element_lget_i
    var = make_var({})
    var["nums"] = "10 20 30"
    assert_equal 20, var.element_lget_i("nums", 1)
  end

  def test_element_lget_f
    var = make_var({})
    var["floats"] = "1.5 2.5 3.5"
    assert_in_delta 2.5, var.element_lget_f("floats", 1), 0.001
  end

  # --- Element to_i and to_f ---

  def test_element_to_i
    var = make_var({})
    var["num"] = "42"
    assert_equal 42, var.element_to_i("num")
  end

  def test_element_to_f
    var = make_var({})
    var["num"] = "3.14"
    assert_in_delta 3.14, var.element_to_f("num"), 0.001
  end

  # --- set_value and set_element_value ---

  def test_set_value_returns_self
    var = make_var("")
    result = var.set_value("test")
    assert_same var, result
    assert_equal "test", var.value
  end

  def test_set_element_value
    var = make_var({})
    result = var.set_element_value("key", "val")
    assert_same var, result
    assert_equal "val", var["key"]
  end

  def test_set_element_value_with_array_index
    var = make_var({})
    var.set_element_value(["a", "b"], "multi")
    assert_equal "multi", var["a", "b"]
  end

  # --- set_value_type and set_element_value_type ---
  # Note: set_value_type uses val.class to infer type. The type mapping
  # checks for exact class matches (e.g., type == Numeric), so Integer/Float
  # don't auto-map to :numeric since Integer != Numeric. This is a limitation.

  def test_set_value_type_sets_value
    var = make_var("")
    var.set_value_type(42)
    # Value is set correctly
    assert_equal "42", var.to_s
  end

  def test_set_value_type_returns_self
    var = make_var("")
    result = var.set_value_type("hello")
    assert_same var, result
  end

  def test_value_type_assignment_with_string
    var = make_var("")
    var.value_type = "test"
    # String class maps to :string
    assert_equal :string, var.default_value_type
    assert_equal "test", var.value
  end

  def test_set_element_value_type_sets_value
    var = make_var({})
    var.set_element_value_type("key", "value")
    # String class maps to :string
    assert_equal :string, var.default_element_value_type("key")
    assert_equal "value", var["key"]
  end

  # --- Equality with various types ---

  def test_equality_with_float
    var = make_var("3.14")
    assert_in_delta 3.14, var.to_f, 0.001
  end

  def test_equality_with_array
    var = make_var("a b c")
    assert_equal ["a", "b", "c"], var
  end

  def test_equality_with_tkvariable
    var1 = make_var("test")
    var2 = make_var("test")
    assert_equal var1, var2  # same value
  end

  def test_equality_with_hash
    var = make_var({"a" => "1", "b" => "2"})
    # Comparing to hash
    assert_equal({"a" => "1", "b" => "2"}, var)
  end

  # --- Spaceship with various types ---

  def test_spaceship_with_tkvariable
    var1 = make_var("10")
    var2 = make_var("20")
    assert_equal(-1, var1 <=> var2)
    assert_equal 1, var2 <=> var1
  end

  def test_spaceship_with_array
    var = make_var("a b c")
    assert_equal 0, var <=> ["a", "b", "c"]
  end

  def test_spaceship_with_string
    var = make_var("hello")
    assert_equal 0, var <=> "hello"
    assert_equal(-1, var <=> "world")
  end

  # --- new_hash class method ---

  def test_new_hash_with_hash
    var = TkVariable.new_hash({"a" => "1"})
    @created_vars << var
    assert var.is_hash?
    assert_equal "1", var["a"]
  end

  def test_new_hash_rejects_non_hash
    assert_raises(ArgumentError) { TkVariable.new_hash("not a hash") }
  end

  # --- to_eval ---

  def test_to_eval
    var = make_var("test")
    assert_equal var.id, var.to_eval
  end

  # --- Trace Callbacks ---
  # Traces allow registering callbacks that fire when a variable is
  # read ('r'), written ('w'), unset ('u'), or array-accessed ('a').

  def test_trace_write_callback
    var = make_var("initial")
    trace_log = []

    # Can use legacy 'w' or modern 'write' - both work
    var.trace('w') { |v, elem, op| trace_log << [op, v.value] }

    var.value = "changed"
    var.value = "again"

    assert_equal 2, trace_log.size
    # Callback receives Tcl's format: 'write' (not 'w')
    assert_equal ['write', 'changed'], trace_log[0]
    assert_equal ['write', 'again'], trace_log[1]
  end

  def test_trace_with_proc
    var = make_var("test")
    trace_log = []

    callback = proc { |v, elem, op| trace_log << op }
    var.trace('w', callback)

    var.value = "new"
    assert_equal ['write'], trace_log
  end

  def test_trace_returns_self
    var = make_var("test")
    result = var.trace('w') { }
    assert_same var, result
  end

  def test_trace_info_empty
    var = make_var("test")
    assert_equal [], var.trace_info
  end

  def test_trace_info_returns_traces
    var = make_var("test")
    callback1 = proc { }
    callback2 = proc { }

    var.trace('w', callback1)
    var.trace('r', callback2)

    info = var.trace_info
    assert_equal 2, info.size
    # Most recent trace is first (unshift)
    assert_same callback2, info[0][1]
    assert_same callback1, info[1][1]
  end

  def test_trace_vinfo_alias
    var = make_var("test")
    assert_equal var.trace_info, var.trace_vinfo
  end

  def test_trace_remove
    var = make_var("test")
    trace_log = []
    callback = proc { |v, elem, op| trace_log << op }

    var.trace('w', callback)
    var.value = "first"
    assert_equal ['write'], trace_log

    var.trace_remove('w', callback)
    var.value = "second"
    # Should not have triggered after removal
    assert_equal ['write'], trace_log
  end

  def test_trace_remove_returns_self
    var = make_var("test")
    callback = proc { }
    var.trace('w', callback)

    result = var.trace_remove('w', callback)
    assert_same var, result
  end

  def test_trace_delete_alias
    var = make_var("test")
    assert var.respond_to?(:trace_delete)
    assert var.respond_to?(:trace_vdelete)
  end

  def test_trace_multiple_operations
    var = make_var("test")
    trace_log = []

    # Track both read and write (using legacy 'rw' format)
    var.trace('rw') { |v, elem, op| trace_log << op }

    _ = var.value  # read
    var.value = "new"  # write

    # Both operations should be logged (in Tcl's format)
    assert_includes trace_log, 'read'
    assert_includes trace_log, 'write'
  end

  def test_trace_element_on_hash
    var = make_var({})
    var["key"] = "initial"
    trace_log = []

    var.trace_element("key", 'w') { |v, elem, op| trace_log << [elem, op] }

    var["key"] = "changed"
    var["other"] = "something"  # Different element, shouldn't trigger

    # Only "key" element should trigger the trace (op is 'write' in modern Tcl)
    assert trace_log.any? { |elem, op| elem == "key" && op == 'write' }
  end

  def test_trace_element_returns_self
    var = make_var({})
    result = var.trace_element("key", 'w') { }
    assert_same var, result
  end

  def test_trace_info_for_element_empty
    var = make_var({})
    assert_equal [], var.trace_info_for_element("key")
  end

  def test_trace_info_for_element_returns_traces
    var = make_var({})
    callback = proc { }

    var.trace_element("mykey", 'w', callback)

    info = var.trace_info_for_element("mykey")
    assert_equal 1, info.size
    assert_same callback, info[0][1]
  end

  def test_trace_vinfo_for_element_alias
    var = make_var({})
    assert_equal var.trace_info_for_element("key"), var.trace_vinfo_for_element("key")
  end

  def test_trace_remove_for_element
    var = make_var({})
    var["key"] = "initial"
    trace_log = []
    callback = proc { |v, elem, op| trace_log << op }

    var.trace_element("key", 'w', callback)
    var["key"] = "first"
    assert_equal ['write'], trace_log

    var.trace_remove_for_element("key", 'w', callback)
    var["key"] = "second"
    # Should not have triggered after removal
    assert_equal ['write'], trace_log
  end

  def test_trace_remove_for_element_returns_self
    var = make_var({})
    callback = proc { }
    var.trace_element("key", 'w', callback)

    result = var.trace_remove_for_element("key", 'w', callback)
    assert_same var, result
  end

  def test_trace_with_new_style_options
    var = make_var("test")
    trace_log = []

    # New style uses 'write' instead of 'w'
    var.trace('write') { |v, elem, op| trace_log << op }

    var.value = "changed"
    assert trace_log.size >= 1
  end

  def test_trace_with_array_options
    var = make_var("test")
    trace_log = []

    var.trace(['write']) { |v, elem, op| trace_log << op }

    var.value = "changed"
    assert trace_log.size >= 1
  end

  def test_trace_unset_callback
    var = make_var("test")
    trace_log = []

    var.trace('u') { |v, elem, op| trace_log << op }

    var.unset

    assert_includes trace_log, 'unset'
  end

  def test_check_trace_opt_rejects_empty
    var = make_var("test")
    assert_raises(ArgumentError) { var.trace('') { } }
  end

  # --- Default value with block (proc) ---

  def test_default_value_with_block_returns_self
    var = make_var({})
    result = var.default_value { |v, *keys| "default" }
    assert_same var, result
  end

  def test_default_value_with_block_sets_def_default_to_proc
    var = make_var({})
    var["exists"] = "real_value"

    # Set a proc as the default value generator
    var.default_value { |v, *keys| "default_for_#{keys.join('_')}" }

    # Existing key returns real value
    assert_equal "real_value", var["exists"]

    # Accessing missing element should use the proc
    result = var["missing_key"]
    assert_equal "default_for_missing_key", result
  end

  def test_default_proc_is_called_with_correct_args
    var = make_var({})
    var["exists"] = "x"  # Make it a hash
    call_log = []

    var.default_proc { |v, *keys|
      call_log << [v.object_id, keys]
      "generated"
    }

    result = var["nonexistent"]
    assert_equal "generated", result
    assert_equal 1, call_log.size
    assert_equal var.object_id, call_log[0][0]
    assert_equal ["nonexistent"], call_log[0][1]
  end

  # --- Default value fallback for missing elements ---

  def test_set_default_value_used_for_missing_element
    var = make_var({})
    var["present"] = "here"  # Make it a hash
    var.set_default_value("fallback_value")

    # Existing element returns its value
    assert_equal "here", var["present"]

    # Missing element returns the default value
    result = var["missing"]
    assert_equal "fallback_value", result
  end

  # --- Error cases for scalar operations ---

  def test_keys_on_scalar_raises_error
    var = make_var("scalar_value")
    assert_raises(RuntimeError) { var.keys }
  end

  def test_clear_on_scalar_raises_error
    var = make_var("scalar_value")
    assert_raises(RuntimeError) { var.clear }
  end

  def test_update_on_scalar_raises_error
    var = make_var("scalar_value")
    assert_raises(RuntimeError) { var.update({"a" => "1"}) }
  end

  # --- variable and variable_element methods ---

  def test_variable_returns_tkvaraccess
    var = make_var({})
    var["ref"] = "some_var_name"

    # variable_element should return a TkVarAccess wrapping the element value
    result = var.variable_element("ref")
    assert_kind_of TkVarAccess, result
    @created_vars << result
  end

  def test_set_variable_with_tkvariable
    var1 = make_var("source")
    var2 = make_var("")

    var2.set_variable(var1)
    # Should store var1's id, not its value
    assert_equal var1.id, var2.value
  end

  def test_set_variable_element
    var = make_var({})
    source = make_var("source_value")

    var.set_variable_element("key", source)
    assert_equal source.id, var["key"]
  end

  def test_set_variable_type
    var = make_var("")
    source = make_var("referenced")

    result = var.set_variable_type(source)
    assert_same var, result
    assert_equal :variable, var.default_value_type
    assert_equal source.id, var.to_s
  end

  # --- Type coercion with NilClass ---

  def test_type_from_nilclass_resets_type
    var = make_var("42")
    var.default_value_type = :numeric
    assert_equal 42, var.value

    # NilClass should reset to no type conversion
    var.default_value_type = NilClass
    assert_nil var.default_value_type
    assert_equal "42", var.value  # Back to raw string
  end

  # --- Type coercion with TkVariable class ---

  def test_type_from_tkvariable_class
    var = make_var("some_var_name")
    var.default_value_type = TkVariable

    assert_equal :variable, var.default_value_type
    result = var.value
    assert_kind_of TkVarAccess, result
    @created_vars << result
  end

  # --- Procedure methods ---

  def test_set_procedure
    var = make_var("")
    result = var.set_procedure("some_command")
    assert_same var, result
    assert_equal "some_command", var.value
  end

  def test_set_procedure_element
    var = make_var({})
    result = var.set_procedure_element("cmd", "my_proc")
    assert_same var, result
    assert_equal "my_proc", var["cmd"]
  end

  def test_set_procedure_element_with_tkvariable
    var = make_var({})
    source = make_var("source_cmd")
    var.set_procedure_element("key", source)
    assert_equal "source_cmd", var["key"]
  end

  def test_set_procedure_element_with_array_index
    var = make_var({})
    var.set_procedure_element(["a", "b"], "multi_cmd")
    assert_equal "multi_cmd", var["a", "b"]
  end

  def test_set_procedure_type
    var = make_var("")
    result = var.set_procedure_type("my_command")
    assert_same var, result
    assert_equal :procedure, var.default_value_type
    assert_equal "my_command", var.to_s
  end

  def test_to_proc_with_symbol_value
    var = make_var("upcase")
    # to_proc converts the string to a symbol, then to a proc
    p = var.to_proc
    assert_respond_to p, :call
    assert_equal "HELLO", p.call("hello")
  end

  # --- Window methods (basic, without actual Tk windows) ---

  def test_set_window_with_string
    var = make_var("")
    result = var.set_window(".mywindow")
    assert_same var, result
    assert_equal ".mywindow", var.value
  end

  def test_set_window_with_tkvariable
    var = make_var("")
    source = make_var(".button1")
    var.set_window(source)
    assert_equal ".button1", var.value
  end

  def test_set_window_element
    var = make_var({})
    result = var.set_window_element("win", ".frame")
    assert_same var, result
    assert_equal ".frame", var["win"]
  end

  def test_set_window_element_with_array_index
    var = make_var({})
    var.set_window_element(["x", "y"], ".canvas")
    assert_equal ".canvas", var["x", "y"]
  end

  def test_set_window_element_with_tkvariable
    var = make_var({})
    source = make_var(".label")
    var.set_window_element("ref", source)
    assert_equal ".label", var["ref"]
  end

  def test_set_window_type
    var = make_var("")
    result = var.set_window_type(".toplevel")
    assert_same var, result
    assert_equal :window, var.default_value_type
    assert_equal ".toplevel", var.to_s
  end

  # --- Type coercion for procedure/window string literals ---

  def test_default_value_type_procedure_string
    var = make_var("my_proc")
    var.default_value_type = :procedure
    assert_equal :procedure, var.default_value_type
  end

  def test_default_value_type_window_string
    var = make_var(".mywin")
    var.default_value_type = :window
    assert_equal :window, var.default_value_type
  end

  def test_default_value_type_procedure_from_string_literal
    var = make_var("cmd")
    var.default_value_type = 'procedure'
    assert_equal :procedure, var.default_value_type
  end

  def test_default_value_type_window_from_string_literal
    var = make_var(".win")
    var.default_value_type = 'window'
    assert_equal :window, var.default_value_type
  end

  def test_default_value_type_variable_from_string_literal
    var = make_var("varname")
    var.default_value_type = 'variable'
    assert_equal :variable, var.default_value_type
  end

  # --- Window/Procedure tests requiring Tk runtime ---

  include TkTestHelper

  def test_window_returns_tk_window
    assert_tk_app("window method returns TkWindow", method(:app_window_returns_tk_window))
  end

  def app_window_returns_tk_window
    require 'tk'
    btn = TkButton.new(root)
    var = TkVariable.new(btn.path)

    win = var.window
    raise "expected TkWindow, got #{win.class}" unless win.is_a?(TkWindow)
    raise "paths should match" unless win.path == btn.path
  end

  def test_window_element_returns_tk_window
    assert_tk_app("window_element returns TkWindow", method(:app_window_element_returns_tk_window))
  end

  def app_window_element_returns_tk_window
    require 'tk'
    btn = TkButton.new(root)
    var = TkVariable.new({})
    var["widget"] = btn.path

    win = var.window_element("widget")
    raise "expected TkWindow, got #{win.class}" unless win.is_a?(TkWindow)
    raise "paths should match" unless win.path == btn.path
  end

  def test_set_window_element_type
    assert_tk_app("set_window_element_type sets type and value", method(:app_set_window_element_type))
  end

  def app_set_window_element_type
    require 'tk'
    btn = TkButton.new(root)
    var = TkVariable.new({})

    var.set_window_element_type("ref", btn.path)

    raise "type should be :window" unless var.default_element_value_type("ref") == :window
    win = var["ref"]
    raise "expected TkWindow, got #{win.class}" unless win.is_a?(TkWindow)
  end

  def test_window_type_coercion
    assert_tk_app("window type auto-converts value", method(:app_window_type_coercion))
  end

  def app_window_type_coercion
    require 'tk'
    btn = TkButton.new(root)
    var = TkVariable.new(btn.path)
    var.default_value_type = :window

    val = var.value
    raise "expected TkWindow, got #{val.class}" unless val.is_a?(TkWindow)
    raise "paths should match" unless val.path == btn.path
  end

  def test_procedure_method_runs
    assert_tk_app("procedure method executes", method(:app_procedure_method_runs))
  end

  def app_procedure_method_runs
    require 'tk'
    # TkComm.procedure returns a callable only for rb_out pattern commands,
    # otherwise returns the string. Test that it runs without error.
    var = TkVariable.new("some_command")
    result = var.procedure

    # For non-rb_out values, procedure returns the string as-is
    raise "expected string, got #{result.class}" unless result.is_a?(String)
    raise "expected 'some_command', got '#{result}'" unless result == "some_command"
  end

  def test_procedure_element_runs
    assert_tk_app("procedure_element executes", method(:app_procedure_element_runs))
  end

  def app_procedure_element_runs
    require 'tk'
    var = TkVariable.new({})
    var["cmd"] = "my_command"

    result = var.procedure_element("cmd")
    raise "expected string, got #{result.class}" unless result.is_a?(String)
    raise "expected 'my_command', got '#{result}'" unless result == "my_command"
  end

  def test_procedure_type_coercion
    assert_tk_app("procedure type coercion works", method(:app_procedure_type_coercion))
  end

  def app_procedure_type_coercion
    require 'tk'
    var = TkVariable.new("test_cmd")
    var.default_value_type = :procedure

    # With :procedure type, value method calls TkComm.procedure
    # For non-rb_out values, it returns the string as-is
    result = var.value
    raise "expected 'test_cmd', got '#{result}'" unless result == "test_cmd"
  end

  def test_type_from_tkwindow_class
    assert_tk_app("TkWindow class sets :window type", method(:app_type_from_tkwindow_class))
  end

  def app_type_from_tkwindow_class
    require 'tk'
    btn = TkButton.new(root)
    var = TkVariable.new(btn.path)
    var.default_value_type = TkWindow

    raise "type should be :window" unless var.default_value_type == :window

    val = var.value
    raise "expected TkWindow, got #{val.class}" unless val.is_a?(TkWindow)
  end
end
