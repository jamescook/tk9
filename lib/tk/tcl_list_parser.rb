# frozen_string_literal: true

#
# Pure Ruby Tcl list parser
#
# Parses Tcl list strings into Ruby arrays using byte-level operations.
# Optimized for YJIT - benchmarks show 1.22x faster than C FFI with YJIT enabled.
#
# Tcl list format:
# - Elements separated by whitespace (space, tab, newline)
# - Braces {like this} group elements containing whitespace or special chars
# - Nested braces are supported: {outer {inner} more}
# - Backslash escapes: \{ \} \\ etc.
#
# Examples:
#   "a b c"              => ["a", "b", "c"]
#   "{hello world} foo"  => ["hello world", "foo"]
#   "{a {b c} d}"        => ["a {b c} d"]
#

module Tk
  module TclListParser
    module_function

    # Parse a Tcl list string into a Ruby array of strings.
    # Does not recursively parse nested lists - returns them as strings.
    #
    # @param str [String] Tcl list string
    # @return [Array<String>] array of list elements
    def parse(str)
      return [] if str.nil?

      result = []
      i = 0
      len = str.bytesize

      while i < len
        # Skip whitespace (space, tab, newline, carriage return)
        while i < len && str.getbyte(i) <= 32
          i += 1
        end
        break if i >= len

        byte = str.getbyte(i)

        if byte == 123 # '{'
          # Braced element - find matching close brace
          depth = 1
          start = i + 1
          i += 1
          while i < len && depth > 0
            b = str.getbyte(i)
            if b == 123      # '{'
              depth += 1
            elsif b == 125   # '}'
              depth -= 1
            elsif b == 92    # '\' backslash escape
              i += 1         # skip next byte
            end
            i += 1
          end
          result << str.byteslice(start, i - start - 1)
        elsif byte == 34 # '"'
          # Quoted element - find matching close quote
          start = i + 1
          i += 1
          while i < len
            b = str.getbyte(i)
            if b == 34       # '"'
              break
            elsif b == 92    # '\' backslash escape
              i += 1         # skip next byte
            end
            i += 1
          end
          result << str.byteslice(start, i - start)
          i += 1 # skip closing quote
        else
          # Unbraced element - read until whitespace
          start = i
          while i < len
            b = str.getbyte(i)
            break if b <= 32 # whitespace
            if b == 92       # '\' backslash escape
              i += 1         # skip next byte
            end
            i += 1
          end
          result << str.byteslice(start, i - start)
        end
      end

      result
    end

    # Parse a Tcl list string recursively into nested Ruby arrays.
    # Each element that looks like a Tcl list is recursively parsed.
    #
    # @param str [String] Tcl list string
    # @return [Array] nested array structure
    def parse_nested(str)
      elements = parse(str)
      elements.map do |elem|
        if elem.include?(' ') || elem.start_with?('{')
          # Might be a nested list, try to parse it
          begin
            parse_nested(elem)
          rescue
            elem
          end
        else
          elem
        end
      end
    end
  end
end
