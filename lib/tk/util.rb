# frozen_string_literal: true
#
# Pure Ruby implementations of TkUtil methods
# Replaces C versions from tkutil.c for improved maintainability
#
# Performance notes:
# - With YJIT enabled, Ruby implementations are competitive with C
# - Easier to maintain than complex C code with manual memory management
#
# YJIT optimizations used:
# - Frozen string literals for comparisons
# - case/when for type dispatch (YJIT optimizes this well)
# - Avoid intermediate object creation where possible

require_relative 'warnings'

module TkUtil
  # Tcl boolean string to Ruby boolean
  # Handles: integers, true/false, and strings like "yes", "no", "on", "off", "true", "false"
  #
  # YJIT-friendly: uses case/when, frozen strings, minimal allocations
  # Falsy string values - include both cases to avoid downcase allocation
  BOOL_FALSE_STRINGS = {
    '' => true,
    '0' => true,
    'no' => true, 'NO' => true,
    'off' => true, 'OFF' => true,
    'false' => true, 'FALSE' => true,
  }.freeze

  def self.bool(value)
    case value
    when Integer
      value != 0
    when true, false
      value
    when String
      # Fast path: direct lookup covers lowercase, uppercase, and empty
      return false if BOOL_FALSE_STRINGS.key?(value)

      # Length check: "false"/"FALSE" is longest at 5 chars
      return true if value.bytesize > 5

      # Rare: mixed case like "False" or "oFf" - downcase and check
      !BOOL_FALSE_STRINGS.key?(value.downcase)
    else
      raise TypeError, "no implicit conversion of #{value.class} into String"
    end
  end

  # Instance method version (for modules that include TkUtil)
  def bool(value)
    TkUtil.bool(value)
  end

  # Parse Tcl string to Ruby Integer or Float
  # C version: tcl2rb_number (tkutil.c)
  #
  # Tries Integer first (handles decimal, hex 0x, octal 0), falls back to Float.
  # Raises ArgumentError for invalid number strings.
  def self.number(value)
    raise TypeError, "no implicit conversion of #{value.class} into String" unless String === value

    # Empty string must raise - TkVariable._to_default_type rescues this
    # to return the raw string for comparison (e.g., @STEP[k] == "")
    raise ArgumentError, "invalid value for Number: '#{value}'" if value.empty?

    begin
      Integer(value, 0)
    rescue ArgumentError
      begin
        Float(value)
      rescue ArgumentError
        raise ArgumentError, "invalid value for Number: '#{value}'"
      end
    end
  end

  def number(value)
    TkUtil.number(value)
  end

  # Strip {} braces from Tcl string
  # C version: tcl2rb_string (tkutil.c)
  #
  # If string starts with { and ends with }, strips them.
  # Otherwise returns string unchanged.
  def self.string(value)
    raise TypeError, "no implicit conversion of #{value.class} into String" unless String === value

    return '' if value.empty?

    len = value.bytesize
    if len > 1 && value.getbyte(0) == 123 && value.getbyte(len - 1) == 125  # '{' = 123, '}' = 125
      value.byteslice(1, len - 2)
    else
      value
    end
  end

  def string(value)
    TkUtil.string(value)
  end

  # Try to parse as number, fallback to string (with braces stripped)
  # C version: tcl2rb_num_or_str (tkutil.c)
  def self.num_or_str(value)
    raise TypeError, "no implicit conversion of #{value.class} into String" unless String === value

    return '' if value.empty?

    begin
      Integer(value, 0)
    rescue ArgumentError
      begin
        Float(value)
      rescue ArgumentError
        string(value)
      end
    end
  end

  def num_or_str(value)
    TkUtil.num_or_str(value)
  end

  # Parse as number, or return nil for empty string
  # C version: tcl2rb_num_or_nil (tkutil.c)
  #
  # Unlike num_or_str, this raises on invalid number (no string fallback).
  def self.num_or_nil(value)
    raise TypeError, "no implicit conversion of #{value.class} into String" unless String === value

    return nil if value.empty?

    number(value)
  end

  def num_or_nil(value)
    TkUtil.num_or_nil(value)
  end

  # Convert symbol keys to string keys
  # C version: tk_symbolkey2str (tkutil.c)
  def self._symbolkey2str(keys)
    return {} if keys.nil?
    keys.to_hash.transform_keys(&:to_s)
  end

  def _symbolkey2str(keys)
    TkUtil._symbolkey2str(keys)
  end

  # Legacy encoding methods - no-ops since modern Ruby/Tcl use UTF-8 natively
  def _toUTF8(str, encoding = nil)
    Tk::Warnings.warn_once(:util_to_utf8,
      "_toUTF8 is deprecated. Ruby strings are already UTF-8.")
    str.to_s
  end

  def _fromUTF8(str, encoding = nil)
    Tk::Warnings.warn_once(:util_from_utf8,
      "_fromUTF8 is deprecated. Ruby strings are already UTF-8.")
    str.to_s
  end

  # Sentinel for "no value" - used to skip values in conversions
  # This is set after tkutil C extension loads TK::None
  @none_value = nil

  def self.none_value=(val)
    @none_value = val
  end

  def self.none_value
    @none_value
  end

  # Convert Ruby object to Tcl string representation
  # This is the Ruby equivalent of get_eval_string_core in C (tkutil.c:675)
  #
  # Performance vs C (with YJIT):
  #   Overall: Ruby is faster or comparable to C
  #
  #   Faster in Ruby: integers, arrays, hashes (less C API overhead)
  #   Similar: booleans, nil, floats
  #   Slower in Ruby: strings (C returns directly), symbols, regexp, None sentinel
  #
  # Design notes:
  #   - case/when is YJIT-friendly for type dispatch
  #   - Symbol#name (not to_s) avoids allocation
  #   - Encoding handling removed: Tcl 8.6+ and Ruby 3.x both use UTF-8
  #   - @none_value sentinel avoids defined? overhead in hot path
  #   - Proc/Method in case/when avoids else branch for common callback case
  #
  # Tradeoffs:
  #   - Simpler: ~100 lines Ruby vs ~400 lines C (with ary2list, hash2list)
  #   - No manual memory management or encoding juggling
  #   - Requires TclTkLib._merge_tklist for proper Tcl list escaping
  #
  def self._get_eval_string(obj, enc_flag = nil)
    case obj
    when Integer, Float
      obj.to_s
    when String
      obj
    when Symbol
      obj.name  # Returns frozen string, no allocation
    when Hash
      _hash2list_ruby(obj)
    when Array
      _ary2list_ruby(obj)
    when false
      '0'
    when true
      '1'
    when nil
      ''
    when Regexp
      obj.source
    when Proc, Method
      # Install as Tcl callback
      TkCore.install_cmd(obj)
    else
      # Check for TkUtil::None (sentinel for "no value")
      return nil if @none_value && obj.equal?(@none_value)

      # TkObject with path method
      if obj.respond_to?(:path)
        return _get_eval_string(obj.path, enc_flag)
      end

      # Object with to_eval method
      if obj.respond_to?(:to_eval)
        return _get_eval_string(obj.to_eval, enc_flag)
      end

      # Fallback: to_s
      obj.to_s
    end
  end

  # Convert Ruby array to Tcl list string
  # Uses TclTkLib._merge_tklist for proper Tcl escaping
  #
  # When a Hash appears in the array, its key-value pairs are expanded inline.
  # This is required for Tcl commands like ttk::style layout where:
  #   ["element", {:children => [...]}]
  # must become:
  #   element -children {...}
  # NOT:
  #   element {-children {...}}
  #
  def self._ary2list_ruby(ary)
    return '' if ary.empty?

    none = @none_value
    elements = []

    ary.each do |elem|
      case elem
      when Array
        elements << _ary2list_ruby(elem)
      when Hash
        # Expand hash inline as -key value pairs
        elem.each do |key, value|
          next if none && value.equal?(none)
          elements << "-#{key}"
          case value
          when Array
            elements << _ary2list_ruby(value)
          when Hash
            elements << _hash2list_ruby(value)
          else
            result = _get_eval_string(value)
            elements << result unless result.nil?
          end
        end
      else
        result = _get_eval_string(elem)
        elements << result unless result.nil?
      end
    end

    TclTkLib._merge_tklist(*elements)
  end

  # Convert Ruby hash to Tcl key-value list
  # Keys are prefixed with - (Tcl option style)
  def self._hash2list_ruby(hash)
    return '' if hash.empty?

    none = @none_value
    elements = []
    hash.each do |key, value|
      next if none && value.equal?(none)

      elements << "-#{key}"

      case value
      when Array
        elements << _ary2list_ruby(value)
      when Hash
        elements << _hash2list_ruby(value)
      else
        result = _get_eval_string(value)
        elements << result unless result.nil?
      end
    end

    TclTkLib._merge_tklist(*elements)
  end

  # Instance method versions
  def _get_eval_string(obj, enc_flag = nil)
    TkUtil._get_eval_string(obj, enc_flag)
  end

  def _ary2list_ruby(ary)
    TkUtil._ary2list_ruby(ary)
  end

  def _hash2list_ruby(hash)
    TkUtil._hash2list_ruby(hash)
  end

  # _get_eval_enc_str - same as _get_eval_string (encoding now irrelevant with UTF-8)
  # C version: tkutil.c:778
  def self._get_eval_enc_str(obj)
    return obj if @none_value && obj.equal?(@none_value)
    _get_eval_string(obj)
  end

  def _get_eval_enc_str(obj)
    TkUtil._get_eval_enc_str(obj)
  end

  # Convert hash to key-value array with -key prefixes
  # C version: tkutil.c:617 (tk_hash_kv)
  #
  # hash_kv(hash, enc_flag=nil, ary=nil)
  #   hash: Hash or Array (assoc list)
  #   enc_flag: ignored (was for encoding, now UTF-8 everywhere)
  #   ary: optional base array to append to
  def self.hash_kv(hash, enc_flag = nil, ary = nil)
    none = @none_value

    case hash
    when Hash
      # Pre-allocate for 2 elements per key (key + value)
      result = ary ? ary.dup : Array.new(hash.size * 2)
      result.clear unless ary
      hash.each do |key, val|
        next if none && val.equal?(none)
        result << "-#{key}" << _get_eval_string(val)
      end
      result

    when Array
      # Assoc list format: [[key, val], [key, val], ...]
      result = ary ? ary.dup : Array.new(hash.size * 2)
      result.clear unless ary
      hash.each do |pair|
        # Fast type check without method call
        next unless ::Array === pair && pair.length > 0
        result << "-#{pair[0]}"
        if pair.length > 1
          val = pair[1]
          result << _get_eval_string(val) unless none && val.equal?(none)
        end
      end
      result

    when nil
      ary ? ary.dup : []

    else
      return (ary ? ary.dup : []) if none && hash.equal?(none)
      raise ArgumentError, "Hash is expected for 1st argument"
    end
  end

  def hash_kv(hash, enc_flag = nil, ary = nil)
    TkUtil.hash_kv(hash, enc_flag, ary)
  end

  # Convert arguments for Tcl command
  # C version: tkutil.c:788 (tk_conv_args)
  #
  # _conv_args(base_array, enc_mode, *args)
  #   base_array: array to prepend to result
  #   enc_mode: ignored (was for encoding)
  #   args: values to convert (hashes expanded to -key val pairs)
  def self._conv_args(base_array, enc_mode, *args)
    raise ArgumentError, "too few arguments" if base_array.nil?

    none = @none_value
    # Start with copy of base_array, append in place
    result = base_array.dup

    args.each do |arg|
      if ::Hash === arg
        arg.each do |key, val|
          next if none && val.equal?(none)
          result << "-#{key}" << _get_eval_string(val)
        end
      else
        next if none && arg.equal?(none)
        result << _get_eval_string(arg)
      end
    end

    result
  end

  def _conv_args(base_array, enc_mode, *args)
    TkUtil._conv_args(base_array, enc_mode, *args)
  end

  # Handles Tk's % substitution for event callbacks
  class CallbackSubst
    class << self
      # Internal storage - inherited by subclasses
      def subst_table
        @subst_table ||= {}
      end

      def type_procs
        @type_procs ||= {}
      end

      def aliases
        @aliases ||= {}
      end

      def ivar_order
        @ivar_order ||= []
      end

      # Setup substitution table from KEY_TBL format:
      # [ [char_code, type_char, ivar_symbol], ... ]
      def _setup_subst_table(key_tbl, longkey_tbl_or_proc_tbl = [], proc_tbl = nil)
        # Handle 2-arg vs 3-arg form
        if proc_tbl.nil?
          proc_tbl = longkey_tbl_or_proc_tbl
          longkey_tbl = []
        else
          longkey_tbl = longkey_tbl_or_proc_tbl
        end

        @subst_table = {}
        @type_procs = {}
        @aliases = {}

        # Collect all ivars for accessor definition
        all_ivars = []

        # Process single-char keys
        key_tbl.each do |entry|
          next unless entry
          char, type_char, ivar = entry
          next unless char && type_char && ivar

          char_code = char.is_a?(Integer) ? char : char.ord
          type_str = type_char.is_a?(Integer) ? type_char.chr : type_char.to_s

          @subst_table[char_code] = [ivar, type_str]
          all_ivars << ivar
        end

        # Process long keys (stored at indices 128+)
        longkey_tbl.each_with_index do |entry, idx|
          next unless entry
          key_str, type_char, ivar = entry
          next unless key_str && type_char && ivar

          # Long keys use index 128+ as their "char code"
          char_code = 128 + idx
          type_str = type_char.is_a?(Integer) ? type_char.chr : type_char.to_s

          @subst_table[char_code] = [ivar, type_str, key_str]
          all_ivars << ivar
        end

        # Build ivar_order sorted by char code (for initialize)
        @ivar_order = @subst_table.keys.sort.map { |k| @subst_table[k][0] }

        # YJIT optimization: Generate initialize with literal @ivar = assignments
        # This is much faster than instance_variable_set because YJIT can optimize it
        param_list = @ivar_order.map.with_index { |_iv, i| "arg#{i} = nil" }
        assign_list = @ivar_order.map.with_index { |iv, i| "@#{iv} = arg#{i}" }

        class_eval <<-RUBY, __FILE__, __LINE__ + 1
          def initialize(#{param_list.join(', ')})
            #{assign_list.join("\n            ")}
          end
        RUBY

        # Define attr_accessors for all ivars
        all_ivars.uniq.each do |ivar|
          attr_accessor ivar unless method_defined?(ivar)
        end

        # Process type conversion procs
        proc_tbl.each do |entry|
          next unless entry
          type_char, proc_or_method = entry
          next unless type_char && proc_or_method

          key = type_char.is_a?(Integer) ? type_char.chr : type_char.to_s
          @type_procs[key] = proc_or_method
        end
      end

      def _define_attribute_aliases(hash)
        @aliases ||= {}
        @aliases.merge!(hash)
      end

      # Convert a substitution string like "%x %y %W" to a packed key string
      # Each byte is the char code of the substitution key
      # Returns binary string like "xy" for "%x %y"
      def _get_subst_key(str)
        parts = str.split
        result = String.new(encoding: Encoding::ASCII_8BIT, capacity: parts.size)

        parts.each do |part|
          if part.getbyte(0) == 37  # '%'
            if part.bytesize == 2
              # Single char key - use char code directly (e.g., "%x" -> 'x')
              result << part.getbyte(1)
            else
              # Long key - find its index in table (iterate without allocating keys array)
              key = part.byteslice(1..-1)
              found = nil
              @subst_table.each do |k, v|
                if k >= 128 && v[2] == key
                  found = k
                  break
                end
              end
              result << (found || 32)  # 32 = ' '.ord
            end
          else
            result << 32  # ' '.ord
          end
        end

        result
      end

      # Convert callback arguments using the key string from _get_subst_key
      def scan_args(keys, values)
        return values if keys.nil? || keys.empty?

        len = keys.bytesize
        result = Array.new(len)
        idx = 0

        keys.each_byte do |char_code|
          val = values[idx]

          if (entry = @subst_table[char_code])
            type_char = entry[1]
            if type_char && (prc = @type_procs[type_char])
              result[idx] = prc.call(val)
            else
              result[idx] = val
            end
          else
            # Unknown key - pass through
            result[idx] = val
          end
          idx += 1
        end

        result
      end

      # Convert symbol to substitution string (e.g., :x -> "%x ")
      def _sym2subst(sym)
        return sym unless sym.is_a?(Symbol)

        # Check aliases first
        if @aliases && (aliased = @aliases[sym])
          sym = aliased
        end

        # Find the substitution key for this ivar
        @subst_table.each do |char_code, (ivar, _type, long_key)|
          if ivar == sym
            if long_key
              return "%#{long_key} "
            elsif char_code < 128
              return "%#{char_code.chr} "
            end
          end
        end

        sym  # Return as-is if not found
      end

      # Return [keys_string, subst_string] for all registered substitutions
      # Keys are sorted by char code
      def _get_all_subst_keys
        sorted_codes = @subst_table.keys.sort

        keys_str = String.new(encoding: Encoding::ASCII_8BIT)
        subst_str = String.new

        sorted_codes.each do |char_code|
          keys_str << char_code

          entry = @subst_table[char_code]
          if entry[2]  # long key
            subst_str << "%#{entry[2]} "
          else
            subst_str << "%#{char_code.chr} "
          end
        end

        [keys_str, subst_str]
      end

      # Hook for subclasses to convert return values
      def ret_val(val)
        val
      end

      # Get extra args table (stub for compatibility)
      def _get_extra_args_tbl
        []
      end

      # subst_arg - build substitution string from symbols
      def subst_arg(*syms)
        result = String.new
        syms.each do |sym|
          result << _sym2subst(sym)
        end
        result
      end
    end

    # Note: initialize is generated dynamically by _setup_subst_table
    # with literal @ivar = argN assignments for YJIT optimization
  end
end

# TkUtil::None - sentinel value for "no value" in Tk option handling
# Returns empty string for to_s (becomes empty Tcl string)
module TkUtil
  class None
    def self.to_s
      ""
    end

    def self.inspect
      "None"
    end
  end

  # Evaluate a command (proc/method/lambda/string) with arguments
  # C version: tk_eval_cmd (tkutil.c) - was using rb_eval_cmd C API
  #
  # String commands require Tk.allow_string_eval = true (off by default for security)
  def self.eval_cmd(cmd, *args)
    if cmd.is_a?(String)
      if Tk.allow_string_eval
        eval(cmd)
      else
        raise SecurityError, "String command #{cmd.inspect} passed but Tk.allow_string_eval is false. " \
                             "Use a Proc/block instead, or set Tk.allow_string_eval = true if you trust " \
                             "all command strings in your application."
      end
    else
      cmd.call(*args)
    end
  end

  def eval_cmd(cmd, *args)
    TkUtil.eval_cmd(cmd, *args)
  end
end

# Initialize none_value now that TkUtil::None is defined
TkUtil.none_value = TkUtil::None
