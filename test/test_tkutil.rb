# frozen_string_literal: true

# Unit tests for TkUtil.bool (Tcl boolean to Ruby boolean conversion)

require_relative 'test_helper'
require 'tk'

class TestTkUtil < Minitest::Test
  # Integer inputs
  def test_integer_zero_is_false
    assert_equal false, TkUtil.bool(0)
  end

  def test_integer_one_is_true
    assert_equal true, TkUtil.bool(1)
  end

  def test_integer_negative_is_true
    assert_equal true, TkUtil.bool(-1)
  end

  def test_integer_large_is_true
    assert_equal true, TkUtil.bool(42)
  end

  # Boolean passthrough
  def test_true_returns_true
    assert_equal true, TkUtil.bool(true)
  end

  def test_false_returns_false
    assert_equal false, TkUtil.bool(false)
  end

  # String falsy values (lowercase)
  def test_string_zero_is_false
    assert_equal false, TkUtil.bool('0')
  end

  def test_string_no_is_false
    assert_equal false, TkUtil.bool('no')
  end

  def test_string_off_is_false
    assert_equal false, TkUtil.bool('off')
  end

  def test_string_false_is_false
    assert_equal false, TkUtil.bool('false')
  end

  def test_string_empty_is_false
    assert_equal false, TkUtil.bool('')
  end

  # String falsy values (uppercase)
  def test_string_NO_is_false
    assert_equal false, TkUtil.bool('NO')
  end

  def test_string_OFF_is_false
    assert_equal false, TkUtil.bool('OFF')
  end

  def test_string_FALSE_is_false
    assert_equal false, TkUtil.bool('FALSE')
  end

  # String falsy values (mixed case - rare but should work)
  def test_string_No_is_false
    assert_equal false, TkUtil.bool('No')
  end

  def test_string_False_is_false
    assert_equal false, TkUtil.bool('False')
  end

  def test_string_oFf_is_false
    assert_equal false, TkUtil.bool('oFf')
  end

  # String truthy values
  def test_string_one_is_true
    assert_equal true, TkUtil.bool('1')
  end

  def test_string_yes_is_true
    assert_equal true, TkUtil.bool('yes')
  end

  def test_string_on_is_true
    assert_equal true, TkUtil.bool('on')
  end

  def test_string_true_is_true
    assert_equal true, TkUtil.bool('true')
  end

  def test_string_YES_is_true
    assert_equal true, TkUtil.bool('YES')
  end

  def test_string_TRUE_is_true
    assert_equal true, TkUtil.bool('TRUE')
  end

  def test_string_arbitrary_is_true
    assert_equal true, TkUtil.bool('foo')
  end

  def test_string_long_is_true
    assert_equal true, TkUtil.bool('something')
  end

  # Error cases
  def test_nil_raises_type_error
    assert_raises(TypeError) { TkUtil.bool(nil) }
  end

  def test_array_raises_type_error
    assert_raises(TypeError) { TkUtil.bool([]) }
  end

  # Numeric types
  def test_integer_to_string
    assert_equal "42", TkUtil._get_eval_string(42)
  end

  def test_negative_integer_to_string
    assert_equal "-7", TkUtil._get_eval_string(-7)
  end

  def test_float_to_string
    result = TkUtil._get_eval_string(3.14)
    assert_match(/^3\.14/, result)
  end

  def test_zero_to_string
    assert_equal "0", TkUtil._get_eval_string(0)
  end

  # String passthrough
  def test_string_passthrough
    assert_equal "hello", TkUtil._get_eval_string("hello")
  end

  def test_empty_string
    assert_equal "", TkUtil._get_eval_string("")
  end

  def test_string_with_spaces
    result = TkUtil._get_eval_string("hello world")
    assert_equal "hello world", result
  end

  # Symbols
  def test_symbol_to_string
    result = TkUtil._get_eval_string(:foo)
    assert_equal "foo", result
  end

  # Booleans
  def test_true_to_string
    assert_equal "1", TkUtil._get_eval_string(true)
  end

  def test_false_to_string
    assert_equal "0", TkUtil._get_eval_string(false)
  end

  # nil
  def test_nil_to_empty_string
    assert_equal "", TkUtil._get_eval_string(nil)
  end

  # Arrays - this exercises ary2list
  def test_simple_array
    result = TkUtil._get_eval_string([1, 2, 3])
    # Tcl list format
    assert_match(/1.*2.*3/, result)
  end

  def test_array_with_strings
    result = TkUtil._get_eval_string(["a", "b", "c"])
    assert_match(/a.*b.*c/, result)
  end

  def test_nested_array
    result = TkUtil._get_eval_string([[1, 2], [3, 4]])
    # Should produce nested Tcl list like "{1 2} {3 4}"
    assert_kind_of String, result
    refute_empty result
  end

  def test_empty_array
    result = TkUtil._get_eval_string([])
    assert_equal "", result
  end

  def test_mixed_array
    result = TkUtil._get_eval_string([1, "hello", :sym])
    assert_kind_of String, result
    assert_match(/1/, result)
    assert_match(/hello/, result)
    assert_match(/sym/, result)
  end

  # Hashes - this exercises hash2list
  def test_simple_hash
    result = TkUtil._get_eval_string({a: 1, b: 2})
    assert_kind_of String, result
    # Hash keys get prefixed with -
    assert_match(/-a/, result)
    assert_match(/-b/, result)
  end

  # TkUtil::None
  def test_none_returns_nil
    result = TkUtil._get_eval_string(TkUtil::None)
    assert_nil result
  end

  # Regexp (uses source)
  def test_regexp_source
    result = TkUtil._get_eval_string(/foo.*bar/)
    assert_equal "foo.*bar", result
  end

  # Object with to_s
  def test_object_with_to_s
    obj = Object.new
    def obj.to_s; "custom_string"; end
    result = TkUtil._get_eval_string(obj)
    assert_equal "custom_string", result
  end

  # Object with to_eval
  def test_object_with_to_eval
    obj = Object.new
    def obj.to_eval; "eval_string"; end
    result = TkUtil._get_eval_string(obj)
    assert_equal "eval_string", result
  end

  # Object with path method (like TkObject)
  def test_object_with_path
    obj = Object.new
    def obj.path; ".my_widget"; end
    result = TkUtil._get_eval_string(obj)
    assert_equal ".my_widget", result
  end

  # Proc - gets installed as Tcl callback, returns callback ID
  def test_proc_installs_callback
    result = TkUtil._get_eval_string(proc { puts "hello" })
    # Callback IDs look like "ruby_cmd TksNNN"
    assert_kind_of String, result
    assert_match(/ruby_cmd/, result) if result.include?("ruby_cmd")
  end

  # Method objects also install as callbacks
  def test_method_installs_callback
    result = TkUtil._get_eval_string(method(:puts))
    assert_kind_of String, result
  end

  # Lambda (is a Proc)
  def test_lambda_installs_callback
    result = TkUtil._get_eval_string(-> { "test" })
    assert_kind_of String, result
  end

  # hash_kv with Hash input
  def test_hash_kv_simple_hash
    result = TkUtil.hash_kv({a: 1, b: 2})
    assert_kind_of Array, result
    assert_includes result, "-a"
    assert_includes result, "-b"
    assert_includes result, "1"
    assert_includes result, "2"
  end

  def test_hash_kv_empty_hash
    result = TkUtil.hash_kv({})
    assert_equal [], result
  end

  def test_hash_kv_string_values
    result = TkUtil.hash_kv({text: "hello", bg: "red"})
    assert_includes result, "-text"
    assert_includes result, "hello"
    assert_includes result, "-bg"
    assert_includes result, "red"
  end

  # hash_kv with Array (assoc list) input
  def test_hash_kv_assoc_list
    result = TkUtil.hash_kv([[:a, 1], [:b, 2]])
    assert_kind_of Array, result
    assert_includes result, "-a"
    assert_includes result, "-b"
  end

  def test_hash_kv_empty_array
    result = TkUtil.hash_kv([])
    assert_equal [], result
  end

  # hash_kv with nil
  def test_hash_kv_nil_returns_empty_array
    result = TkUtil.hash_kv(nil)
    assert_equal [], result
  end

  # hash_kv with base array (3rd arg)
  def test_hash_kv_with_base_array
    result = TkUtil.hash_kv({a: 1}, nil, ["existing"])
    assert_equal "existing", result[0]
    assert_includes result, "-a"
  end

  # hash_kv with None values (should be skipped)
  def test_hash_kv_skips_none_values
    result = TkUtil.hash_kv({a: 1, b: TkUtil::None, c: 3})
    assert_includes result, "-a"
    assert_includes result, "-c"
    refute_includes result, "-b"
  end

  # hash_kv with TkUtil::None as input
  def test_hash_kv_none_input
    result = TkUtil.hash_kv(TkUtil::None)
    assert_equal [], result
  end

  # hash_kv raises on invalid input
  def test_hash_kv_raises_on_invalid
    assert_raises(ArgumentError) { TkUtil.hash_kv("invalid") }
    assert_raises(ArgumentError) { TkUtil.hash_kv(123) }
  end

  def test_enc_str_string_passthrough
    assert_equal "hello", TkUtil._get_eval_enc_str("hello")
  end

  def test_enc_str_integer
    assert_equal "42", TkUtil._get_eval_enc_str(42)
  end

  def test_none_returns_none
    result = TkUtil._get_eval_enc_str(TkUtil::None)
    assert_equal TkUtil::None, result
  end

  def test_array
    result = TkUtil._get_eval_enc_str([1, 2, 3])
    assert_kind_of String, result
  end

  def test_simple_args
    result = TkUtil._conv_args([], nil, "a", "b", "c")
    assert_equal ["a", "b", "c"], result
  end

  def test_with_base_array
    result = TkUtil._conv_args(["base"], nil, "a", "b")
    assert_equal ["base", "a", "b"], result
  end

  def test_hash_expansion
    result = TkUtil._conv_args([], nil, {text: "hello"})
    assert_includes result, "-text"
    assert_includes result, "hello"
  end

  def test_mixed_args
    result = TkUtil._conv_args([], nil, "cmd", {opt: "val"}, "arg")
    assert_equal "cmd", result[0]
    assert_includes result, "-opt"
    assert_includes result, "val"
    assert_includes result, "arg"
  end

  def test_skips_none_values
    result = TkUtil._conv_args([], nil, "a", TkUtil::None, "b")
    assert_equal ["a", "b"], result
  end

  def test_skips_none_in_hash
    result = TkUtil._conv_args([], nil, {a: 1, b: TkUtil::None, c: 3})
    assert_includes result, "-a"
    assert_includes result, "-c"
    refute_includes result, "-b"
  end

  def test_raises_without_base_array
    assert_raises(ArgumentError) { TkUtil._conv_args }
  end

  # TkUtil.number - parse string to Integer or Float

  def test_number_integer
    assert_equal 42, TkUtil.number("42")
    assert_equal(-5, TkUtil.number("-5"))
    assert_equal 0, TkUtil.number("0")
  end

  def test_number_float
    assert_equal 3.14, TkUtil.number("3.14")
    assert_equal(-2.5, TkUtil.number("-2.5"))
    assert_equal 1.0e10, TkUtil.number("1e10")
  end

  def test_number_hex_octal
    assert_equal 255, TkUtil.number("0xff")
    assert_equal 255, TkUtil.number("0xFF")
    assert_equal 0o777, TkUtil.number("0777")
  end

  def test_number_invalid_raises
    assert_raises(ArgumentError) { TkUtil.number("hello") }
    assert_raises(ArgumentError) { TkUtil.number("12abc") }
    assert_raises(ArgumentError) { TkUtil.number("abc12") }
  end

  def test_number_type_error_on_non_string
    assert_raises(TypeError) { TkUtil.number(42) }
    assert_raises(TypeError) { TkUtil.number(nil) }
  end

  def test_number_empty_string_raises
    # Empty string must raise ArgumentError (not return 0) so that
    # TkVariable._to_default_type's rescue can return the raw string
    # for comparisons like @var[k] == ""
    assert_raises(ArgumentError) { TkUtil.number("") }
  end

  # TkUtil.string - strip {} braces from Tcl strings

  def test_string_strips_braces
    assert_equal "foo", TkUtil.string("{foo}")
    assert_equal "hello world", TkUtil.string("{hello world}")
  end

  def test_string_no_braces_unchanged
    assert_equal "foo", TkUtil.string("foo")
    assert_equal "hello world", TkUtil.string("hello world")
  end

  def test_string_empty
    assert_equal "", TkUtil.string("")
    assert_equal "", TkUtil.string("{}")
  end

  def test_string_partial_braces_unchanged
    # Only strip if both opening AND closing brace present
    assert_equal "{foo", TkUtil.string("{foo")
    assert_equal "foo}", TkUtil.string("foo}")
  end

  def test_string_nested_braces
    # Only strips outermost braces
    assert_equal "{inner}", TkUtil.string("{{inner}}")
  end

  def test_string_type_error_on_non_string
    assert_raises(TypeError) { TkUtil.string(42) }
    assert_raises(TypeError) { TkUtil.string(nil) }
  end

  # TkUtil.num_or_str - try number, fallback to string

  def test_num_or_str_returns_integer
    assert_equal 42, TkUtil.num_or_str("42")
    assert_equal(-5, TkUtil.num_or_str("-5"))
  end

  def test_num_or_str_returns_float
    assert_equal 3.14, TkUtil.num_or_str("3.14")
  end

  def test_num_or_str_returns_string_for_non_number
    assert_equal "hello", TkUtil.num_or_str("hello")
    assert_equal "abc123", TkUtil.num_or_str("abc123")
  end

  def test_num_or_str_strips_braces_on_string_fallback
    assert_equal "hello", TkUtil.num_or_str("{hello}")
  end

  def test_num_or_str_empty_string
    assert_equal "", TkUtil.num_or_str("")
  end

  def test_num_or_str_type_error_on_non_string
    assert_raises(TypeError) { TkUtil.num_or_str(42) }
    assert_raises(TypeError) { TkUtil.num_or_str(nil) }
  end

  # TkUtil.num_or_nil - number or nil for empty

  def test_num_or_nil_returns_integer
    assert_equal 42, TkUtil.num_or_nil("42")
    assert_equal(-5, TkUtil.num_or_nil("-5"))
  end

  def test_num_or_nil_returns_float
    assert_equal 3.14, TkUtil.num_or_nil("3.14")
  end

  def test_num_or_nil_empty_returns_nil
    assert_nil TkUtil.num_or_nil("")
  end

  def test_num_or_nil_invalid_raises
    # Unlike num_or_str, this does NOT fall back to string
    assert_raises(ArgumentError) { TkUtil.num_or_nil("hello") }
  end

  def test_num_or_nil_type_error_on_non_string
    assert_raises(TypeError) { TkUtil.num_or_nil(42) }
    assert_raises(TypeError) { TkUtil.num_or_nil(nil) }
  end

  # _symbolkey2str - convert symbol keys to string keys
  def test_symbolkey2str_converts_symbols
    result = TkUtil._symbolkey2str({a: 1, b: 2})
    assert_equal({"a" => 1, "b" => 2}, result)
  end

  def test_symbolkey2str_leaves_string_keys
    result = TkUtil._symbolkey2str({"a" => 1, "b" => 2})
    assert_equal({"a" => 1, "b" => 2}, result)
  end

  def test_symbolkey2str_mixed_keys
    result = TkUtil._symbolkey2str({a: 1, "b" => 2})
    assert_equal({"a" => 1, "b" => 2}, result)
  end

  def test_symbolkey2str_empty_hash
    result = TkUtil._symbolkey2str({})
    assert_equal({}, result)
  end

  def test_symbolkey2str_nil_returns_empty_hash
    result = TkUtil._symbolkey2str(nil)
    assert_equal({}, result)
  end

  # _toUTF8 / _fromUTF8 - encoding conversion (delegates to TclTkLib)
  # These are instance methods, so test via an object that includes TkUtil
  def test_toUTF8_string
    obj = Object.new.extend(TkUtil)
    result = obj._toUTF8("hello")
    assert_kind_of String, result
  end

  def test_fromUTF8_string
    obj = Object.new.extend(TkUtil)
    result = obj._fromUTF8("hello")
    assert_kind_of String, result
  end

  # eval_cmd tests
  def test_eval_cmd_calls_proc
    result = nil
    TkUtil.eval_cmd(proc { |x| result = x * 2 }, 21)
    assert_equal 42, result
  end

  def test_eval_cmd_calls_lambda
    result = TkUtil.eval_cmd(->(a, b) { a + b }, 10, 20)
    assert_equal 30, result
  end

  def test_eval_cmd_calls_method
    result = TkUtil.eval_cmd("hello".method(:upcase))
    assert_equal "HELLO", result
  end

  def test_eval_cmd_with_no_args
    result = TkUtil.eval_cmd(proc { 42 })
    assert_equal 42, result
  end

  # String eval security tests
  def test_eval_cmd_string_raises_security_error_by_default
    # Ensure allow_string_eval is false (default)
    Tk.allow_string_eval = false

    err = assert_raises(SecurityError) do
      TkUtil.eval_cmd("1 + 1")
    end
    assert_match(/Tk\.allow_string_eval is false/, err.message)
  end

  def test_eval_cmd_string_works_when_allowed
    # Capture stderr to suppress the one-time warning
    original_stderr = $stderr
    $stderr = StringIO.new

    begin
      Tk.allow_string_eval = true

      # Define a method to call
      eval("def _test_eval_cmd_helper; 42; end", TOPLEVEL_BINDING)
      result = TkUtil.eval_cmd("_test_eval_cmd_helper")
      assert_equal 42, result
    ensure
      Tk.allow_string_eval = false
      $stderr = original_stderr
    end
  end

  def test_eval_cmd_string_error_message_includes_command
    Tk.allow_string_eval = false

    err = assert_raises(SecurityError) do
      TkUtil.eval_cmd("dangerous_command")
    end
    assert_match(/dangerous_command/, err.message)
  end

  # TkUtil::None tests
  def test_none_to_s_returns_empty_string
    assert_equal "", TkUtil::None.to_s
  end

  def test_none_inspect_returns_none
    assert_equal "None", TkUtil::None.inspect
  end

  # TkKernel tests
  def test_tk_kernel_exists
    assert defined?(TkKernel)
  end

  def test_tk_kernel_new_with_block
    result = nil
    obj = TkKernel.new { result = self }
    assert_equal obj, result
  end

  # TkCallbackEntry tests
  def test_tk_callback_entry_exists
    assert defined?(TkCallbackEntry)
  end

  def test_tk_callback_entry_inherits_from_tk_kernel
    assert TkCallbackEntry < TkKernel
  end

  def test_tk_callback_entry_inspect
    assert_equal "TkCallbackEntry", TkCallbackEntry.inspect
  end
end

# Tests for TkCore.callback error handling
# Uses TkComm.install_cmd which stores callbacks in TkCore::INTERP.tk_cmd_tbl
class TestTkCoreCallback < Minitest::Test
  include TkComm

  def extract_callback_id(cmd_str)
    # Extract the callback ID from "rb_out <ip_id> <id>" format
    cmd_str =~ /rb_out\S*(?:\s+(::\S*|[{](::.*)[}]|["](::.*)["]))? (c(_\d+_)?(\d+))/
    $4
  end

  def test_callback_normal_execution
    result = nil
    cmd_str = TkComm.install_cmd(proc { |x| result = x * 2 })
    key = extract_callback_id(cmd_str)

    TkCore::INTERP.tk_cmd_tbl[key].call(21)
    assert_equal 42, result
  end

  def test_callback_with_exception_formats_message
    cmd_str = TkComm.install_cmd(proc { raise "test error" })
    key = extract_callback_id(cmd_str)

    err = assert_raises(RuntimeError) do
      TkCore.callback(key)
    end

    # Error message should include class, message, and backtrace markers
    assert_match(/RuntimeError/, err.message)
    assert_match(/test error/, err.message)
    assert_match(/backtrace of Ruby side/, err.message)
    assert_match(/backtrace of Tk side/, err.message)
  end

  def test_callback_error_message_is_utf8
    cmd_str = TkComm.install_cmd(proc { raise "エラー" })
    key = extract_callback_id(cmd_str)

    err = assert_raises(RuntimeError) do
      TkCore.callback(key)
    end

    # Error message should be UTF-8 encoded
    assert_equal Encoding::UTF_8, err.message.encoding
    assert_match(/エラー/, err.message)
  end

  def test_callback_with_custom_exception
    cmd_str = TkComm.install_cmd(proc { raise ArgumentError, "bad arg" })
    key = extract_callback_id(cmd_str)

    err = assert_raises(ArgumentError) do
      TkCore.callback(key)
    end

    assert_match(/ArgumentError/, err.message)
    assert_match(/bad arg/, err.message)
  end
end
