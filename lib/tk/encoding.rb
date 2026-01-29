# frozen_string_literal: true
#
# Tk::Encoding - UTF-8 encoding support
#
# DEPRECATED: This file is no longer needed. Modern Tcl (8.1+) and Ruby use
# UTF-8 natively. Simply use `require 'tk'` instead.

Tk::Warnings.warn_once(:encoding_require,
  "require 'tk/encoding' is deprecated. Encoding methods are now part of 'tk'. " \
  "Simply use `require 'tk'` instead.")

# :nocov:
module Tk
  module Encoding
    extend Encoding

    TkCommandNames = ['encoding'.freeze].freeze

    RubyEncoding = ::Encoding
    BINARY_NAME  = 'binary'.freeze
    UTF8_NAME    = 'utf-8'.freeze
    DEFAULT_EXTERNAL_NAME = RubyEncoding.default_external.name.freeze
    DEFAULT_INTERNAL_NAME = RubyEncoding.default_internal.name.freeze rescue nil
    BINARY  = RubyEncoding.find(BINARY_NAME)
    UNKNOWN = RubyEncoding.find('ASCII-8BIT')

    def force_default_encoding(mode)
      TkCore::INTERP.force_default_encoding = mode
    end

    def force_default_encoding?
      TkCore::INTERP.force_default_encoding?
    end

    def default_encoding=(enc)
      Tk::Warnings.warn_once(:default_encoding_setter,
        "Tk.default_encoding= is deprecated: modern Tcl/Ruby use UTF-8 natively")
      TkCore::INTERP.default_encoding = 'utf-8'
    end

    def encoding=(enc)
      Tk::Warnings.warn_once(:encoding_setter,
        "Tk.encoding= is deprecated: modern Tcl/Ruby use UTF-8 natively")
      TkCore::INTERP.encoding = 'utf-8'
    end

    def encoding_name
      'utf-8'
    end

    def encoding_obj
      RubyEncoding::UTF_8
    end

    alias encoding encoding_name
    alias default_encoding encoding_name

    def tk_encoding_names
      TkComm.simplelist(TkCore::INTERP._invoke_without_enc('encoding', 'names'))
    end

    def encoding_names
      self.tk_encoding_names
    end

    def encoding_objs
      [RubyEncoding::UTF_8]
    end

    def encoding_system=(enc)
      Tk::Warnings.warn_once(:encoding_system_setter,
        "Tk.encoding_system= is deprecated: modern Tcl/Ruby use UTF-8 natively")
    end

    def encoding_system_name
      'utf-8'
    end

    def encoding_system_obj
      RubyEncoding::UTF_8
    end

    alias encoding_system encoding_system_name

    def encoding_convertfrom(str, enc=nil)
      Tk::Warnings.warn_once(:encoding_convertfrom,
        "Tk::Encoding.encoding_convertfrom is deprecated: modern Ruby/Tcl use UTF-8 natively")
      str = str.dup
      str.force_encoding(::Encoding::UTF_8)
      str
    end
    alias encoding_convert_from encoding_convertfrom

    def encoding_convertto(str, enc=nil)
      Tk::Warnings.warn_once(:encoding_convertto,
        "Tk::Encoding.encoding_convertto is deprecated: modern Ruby/Tcl use UTF-8 natively")
      str = str.dup
      str.force_encoding(::Encoding::UTF_8)
      str
    end
    alias encoding_convert_to encoding_convertto

    def encoding_dirs
      TkComm.simplelist(Tk.tk_call_without_enc('encoding', 'dirs'))
    end

    def encoding_dirs=(dir_list)
      Tk.tk_call_without_enc('encoding', 'dirs', dir_list)
    end
  end

  extend Encoding
end
# :nocov:
