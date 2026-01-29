# frozen_string_literal: false
#
#   tk/msgcat.rb : methods for Tcl message catalog
#                     by Hidetoshi Nagai <nagai@ai.kyutech.ac.jp>
#

#class TkMsgCatalog
class TkMsgCatalog < TkObject
  include TkCore
  extend Tk
  #extend TkMsgCatalog

  TkCommandNames = [
    '::msgcat::mc'.freeze,
    '::msgcat::mcmax'.freeze,
    '::msgcat::mclocale'.freeze,
    '::msgcat::mcpreferences'.freeze,
    '::msgcat::mcload'.freeze,
    '::msgcat::mcset'.freeze,
    '::msgcat::mcmset'.freeze,
    '::msgcat::mcunknown'.freeze
  ].freeze

  # Note: Removed legacy 'package require Tcl 8.2' check.
  # We require Tcl 8.6+ in our C bridge, and Tcl 9's package system
  # doesn't consider itself compatible with 8.x version requirements.

  PACKAGE_NAME = 'msgcat'.freeze
  def self.package_name
    PACKAGE_NAME
  end

  if self.const_defined? :FORCE_VERSION
    tk_call_without_enc('package', 'require', 'msgcat', FORCE_VERSION)
  else
    tk_call_without_enc('package', 'require', 'msgcat')
  end

  MSGCAT_EXT = '.msg'

  # Table of unknown translation callbacks indexed by [interp][namespace]
  UNKNOWN_CBTBL = Hash.new{|hash,key| hash[key] = {}}

  # Callback invoked from Tcl unknowncmd procs
  def self.unknown_callback(namespace, locale, src_str, *args)
    src_str = sprintf(src_str, *args) unless args.empty?
    cmd_tbl = TkMsgCatalog::UNKNOWN_CBTBL[TkCore::INTERP.__getip]
    cmd = cmd_tbl[namespace]
    return src_str unless cmd  # no cmd -> return src-str (default action)
    begin
      cmd.call(locale, src_str)
    rescue SystemExit
      exit(0)
    rescue Interrupt
      exit!(1)
    rescue StandardError => e
      begin
        msg = e.class.inspect + ': ' +
              e.message + "\n" +
              "\n---< backtrace of Ruby side >-----\n" +
              e.backtrace.join("\n") +
              "\n---< backtrace of Tk side >-------"
        msg.force_encoding('utf-8')
      rescue StandardError
        msg = e.class.inspect + ': ' + e.message + "\n" +
              "\n---< backtrace of Ruby side >-----\n" +
              e.backtrace.join("\n") +
              "\n---< backtrace of Tk side >-------"
      end
      fail(e, msg)
    end
  end

  def initialize(namespace = nil)
    if namespace.kind_of?(TkNamespace)
      @namespace = namespace
    elsif namespace == nil
      @namespace = TkNamespace.new('::')  # global namespace
    else
      @namespace = TkNamespace.new(namespace)
    end
    @path = @namespace.path

    @msgcat_ext = '.msg'
  end
  attr_accessor :msgcat_ext

  def method_missing(id, *args)
    # locale(src, trans) ==> set_translation(locale, src, trans)
    loc = id.id2name
    case args.length
    when 0 # set locale
      self.locale=(loc)

    when 1 # src only, or trans_list
      if args[0].kind_of?(Array)
        # trans_list
        #list = args[0].collect{|src, trans|
        #  [ Tk::UTF8_String.new(src), Tk::UTF8_String.new(trans) ]
        #}
        self.set_translation_list(loc, args[0])
      else
        # src
        #self.set_translation(loc, Tk::UTF8_String.new(args[0]))
        self.set_translation(loc, args[0])
      end

    when 2 # src and trans, or, trans_list and enc
      if args[0].kind_of?(Array)
        # trans_list
        self.set_translation_list(loc, *args)
      else
        #self.set_translation(loc, args[0], Tk::UTF8_String.new(args[1]))
        self.set_translation(loc, *args)
      end

    when 3 # src and trans and enc
      self.set_translation(loc, *args)

    else
      super(id, *args)
#      fail NameError, "undefined method `#{name}' for #{self.to_s}", error_at

    end
  end

  # *args ::= form, arg, arg, ...
  def self.translate(*args)
    dst = args.collect{|src|
      tk_call_without_enc('::msgcat::mc', _get_eval_string(src, true))
    }
    sprintf(*dst)
  end
  class << self
    alias mc translate
    alias [] translate
  end
  def translate(*args)
    dst = args.collect{|src|
      @namespace.eval{tk_call_without_enc('::msgcat::mc',
                                          _get_eval_string(src, true))}
    }
    sprintf(*dst)
  end
  alias mc translate
  alias [] translate

  def self.maxlen(*src_strings)
    tk_call('::msgcat::mcmax', *src_strings).to_i
  end
  def maxlen(*src_strings)
    @namespace.eval{tk_call('::msgcat::mcmax', *src_strings).to_i}
  end

  def self.locale
    tk_call('::msgcat::mclocale')
  end
  def locale
    @namespace.eval{tk_call('::msgcat::mclocale')}
  end

  def self.locale=(locale)
    tk_call('::msgcat::mclocale', locale)
  end
  def locale=(locale)
    @namespace.eval{tk_call('::msgcat::mclocale', locale)}
  end

  def self.preferences
    tk_split_simplelist(tk_call('::msgcat::mcpreferences'))
  end
  def preferences
    tk_split_simplelist(@namespace.eval{tk_call('::msgcat::mcpreferences')})
  end

  def self.load_tk(dir)
    number(tk_call('::msgcat::mcload', dir))
  end

  def self.load_rb(dir)
    count = 0
    preferences().each{|loc|
      file = File.join(dir, loc + self::MSGCAT_EXT)
      if File.readable?(file)
        count += 1
        eval(IO.read(file, encoding: "ASCII-8BIT"))
      end
    }
    count
  end

  def load_tk(dir)
    number(@namespace.eval{tk_call('::msgcat::mcload', dir)})
  end

  def load_rb(dir)
    count = 0
    preferences().each{|loc|
      file = File.join(dir, loc + @msgcat_ext)
      if File.readable?(file)
        count += 1
        @namespace.eval(IO.read(file, encoding: "ASCII-8BIT"))
      end
    }
    count
  end

  def self.load(dir)
    self.load_rb(dir)
  end
  alias load load_rb

  def self.set_translation(locale, src_str, trans_str=None, enc='utf-8')
    if trans_str && trans_str != None
      tk_call_without_enc('::msgcat::mcset', locale,
                          _get_eval_string(src_str, true), trans_str)
    else
      tk_call_without_enc('::msgcat::mcset', locale,
                          _get_eval_string(src_str, true))
    end
  end
  def set_translation(locale, src_str, trans_str=None, enc='utf-8')
    # ScopeArgs overrides tk_call_without_enc to wrap with namespace eval
    if trans_str && trans_str != None
      @namespace.eval{
        tk_call_without_enc('::msgcat::mcset', locale,
                            _get_eval_string(src_str, true), trans_str)
      }
    else
      @namespace.eval{
        tk_call_without_enc('::msgcat::mcset', locale,
                            _get_eval_string(src_str, true))
      }
    end
  end

  def self.set_translation_list(locale, trans_list, enc='utf-8')
    # trans_list ::= [ [src, trans], [src, trans], ... ]
    list = []
    trans_list.each{|src, trans|
      if trans && trans != None
        list << _get_eval_string(src, true)
        list << trans.to_s
      else
        list << _get_eval_string(src, true) << ''
      end
    }
    number(tk_call_without_enc('::msgcat::mcmset', locale, list))
  end
  def set_translation_list(locale, trans_list, enc='utf-8')
    # trans_list ::= [ [src, trans], [src, trans], ... ]
    # ScopeArgs overrides tk_call_without_enc to wrap with namespace eval
    list = []
    trans_list.each{|src, trans|
      if trans && trans != None
        list << _get_eval_string(src, true)
        list << trans.to_s
      else
        list << _get_eval_string(src, true) << ''
      end
    }
    number(@namespace.eval{
             tk_call_without_enc('::msgcat::mcmset', locale, list)
           })
  end

  # Register a callback for unknown (missing) translations.
  # Uses msgcat 1.5+ mcpackageconfig unknowncmd API.
  def self.def_unknown_proc(cmd=nil, &block)
    ns_path = '::'
    TkMsgCatalog::UNKNOWN_CBTBL[TkCore::INTERP.__getip][ns_path] = cmd || block
    _setup_unknowncmd(ns_path)
  end

  def def_unknown_proc(cmd=nil, &block)
    ns_path = @namespace.path
    TkMsgCatalog::UNKNOWN_CBTBL[TkCore::INTERP.__getip][ns_path] = cmd || block
    _setup_unknowncmd(ns_path)
  end

  private

  # Set up mcpackageconfig unknowncmd for the given namespace
  def _setup_unknowncmd(ns_path)
    self.class._setup_unknowncmd(ns_path)
  end

  # Callback IDs indexed by interpreter (like UNKNOWN_CBTBL)
  UNKNOWN_CB_IDS = {}

  def self._setup_unknowncmd(ns_path)
    # Create a unique Tcl proc name for this namespace's unknown handler
    # Replace :: with _ to make a valid proc name
    proc_suffix = ns_path.gsub('::', '_').sub(/^_/, '')
    proc_suffix = 'global' if proc_suffix.empty?
    proc_name = "::ruby_tk::msgcat_unknown_#{proc_suffix}"

    # Register Ruby callback if not already done (per-interpreter)
    ip = TkCore::INTERP.__getip
    UNKNOWN_CB_IDS[ip] ||= TkCore::INTERP.register_callback(
      proc { |*args| TkMsgCatalog.unknown_callback(*args) }
    )
    cb_id = UNKNOWN_CB_IDS[ip]

    # Create the Tcl proc that will call back to Ruby
    tk_call_without_enc('namespace', 'eval', '::ruby_tk', '')
    TkCore::INTERP._invoke_without_enc('proc', proc_name, 'args',
      "ruby_callback #{cb_id} {#{ns_path}} {*}$args")

    # Register it as the unknowncmd for this namespace
    TkCore::INTERP._invoke_without_enc(
      'namespace', 'eval', ns_path,
      "::msgcat::mcpackageconfig set unknowncmd #{proc_name}")
  end
end

TkMsgCat = TkMsgCatalog
