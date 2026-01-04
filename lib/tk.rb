# frozen_string_literal: false
#
#               tk.rb - Tk interface module using tcltklib
#                       by Yukihiro Matsumoto <matz@netlab.jp>

# use Shigehiro's tcltklib
require 'tcltklib'
require_relative 'tcltkip'             # TclTkIp Ruby extensions
require_relative 'tkcomm'
require_relative 'tk/tk_kernel'        # TkKernel base class
require_relative 'tk/tk_callback_entry' # TkCallbackEntry marker class
require_relative 'tk/util'             # TkUtil module (pure Ruby)
require_relative 'tkcore'              # TkCore module

# autoload
require 'tk/autoload'

# for Mutex
require 'thread'

# TclTkLib encoding methods - all UTF-8 now
module TclTkLib
  class << self
    def force_default_encoding=(mode); end
    def force_default_encoding? = true
    def default_encoding=(name); end
    def encoding=(name); end
    def encoding_name = 'utf-8'
    def encoding_obj = ::Encoding::UTF_8
    alias encoding encoding_name
    alias default_encoding encoding_name
  end
end

module Tk
  include TkCore
  extend Tk

  TCL_VERSION = INTERP._invoke_without_enc("info", "tclversion").freeze
  TCL_PATCHLEVEL = INTERP._invoke_without_enc("info", "patchlevel").freeze

  major, minor = TCL_VERSION.split('.')
  TCL_MAJOR_VERSION = major.to_i
  TCL_MINOR_VERSION = minor.to_i

  TK_VERSION  = INTERP._invoke_without_enc("set", "tk_version").freeze
  TK_PATCHLEVEL  = INTERP._invoke_without_enc("set", "tk_patchLevel").freeze

  major, minor = TK_VERSION.split('.')
  TK_MAJOR_VERSION = major.to_i
  TK_MINOR_VERSION = minor.to_i

  JAPANIZED_TK = (INTERP._invoke_without_enc("info", "commands",
                                             "kanji") != "").freeze

  def Tk.const_missing(sym)
    case(sym)
    when :TCL_LIBRARY
      INTERP._invoke_without_enc('global', 'tcl_library')
      INTERP._invoke("set", "tcl_library").freeze

    when :TK_LIBRARY
      INTERP._invoke_without_enc('global', 'tk_library')
      INTERP._invoke("set", "tk_library").freeze

    when :LIBRARY
      INTERP._invoke("info", "library").freeze

    #when :PKG_PATH, :PACKAGE_PATH, :TCL_PACKAGE_PATH
    #  INTERP._invoke_without_enc('global', 'tcl_pkgPath')
    #  tk_split_simplelist(INTERP._invoke('set', 'tcl_pkgPath'))

    #when :LIB_PATH, :LIBRARY_PATH, :TCL_LIBRARY_PATH
    #  INTERP._invoke_without_enc('global', 'tcl_libPath')
    #  tk_split_simplelist(INTERP._invoke('set', 'tcl_libPath'))

    when :PLATFORM, :TCL_PLATFORM
      INTERP._invoke_without_enc('global', 'tcl_platform')
      Hash[*tk_split_simplelist(INTERP._invoke_without_enc('array', 'get',
                                                           'tcl_platform'))]

    when :ENV
      INTERP._invoke_without_enc('global', 'env')
      Hash[*tk_split_simplelist(INTERP._invoke('array', 'get', 'env'))]

    #when :AUTO_PATH   #<===
    #  tk_split_simplelist(INTERP._invoke('set', 'auto_path'))

    #when :AUTO_OLDPATH
    #  tk_split_simplelist(INTERP._invoke('set', 'auto_oldpath'))

    when :AUTO_INDEX
      INTERP._invoke_without_enc('global', 'auto_index')
      Hash[*tk_split_simplelist(INTERP._invoke('array', 'get', 'auto_index'))]

    when :PRIV, :PRIVATE, :TK_PRIV
      priv = {}
      if INTERP._invoke_without_enc('info', 'vars', 'tk::Priv') != ""
        var_nam = 'tk::Priv'
      else
        var_nam = 'tkPriv'
      end
      INTERP._invoke_without_enc('global', var_nam)
      Hash[*tk_split_simplelist(INTERP._invoke('array', 'get',
                                               var_nam))].each{|k,v|
        k.freeze
        case v
        when /^-?\d+$/
          priv[k] = v.to_i
        when /^-?\d+\.?\d*(e[-+]?\d+)?$/
          priv[k] = v.to_f
        else
          priv[k] = v.freeze
        end
      }
      priv

    else
      raise NameError, 'uninitialized constant Tk::' + sym.id2name
    end
  end

  def Tk.errorInfo
    INTERP._invoke_without_enc('global', 'errorInfo')
    INTERP._invoke_without_enc('set', 'errorInfo')
  end

  def Tk.errorCode
    INTERP._invoke_without_enc('global', 'errorCode')
    code = tk_split_simplelist(INTERP._invoke_without_enc('set', 'errorCode'))
    case code[0]
    when 'CHILDKILLED', 'CHILDSTATUS', 'CHILDSUSP'
      begin
        pid = Integer(code[1])
        code[1] = pid
      rescue
      end
    end
    code
  end

  def Tk.has_mainwindow?
    INTERP.has_mainwindow?
  end

  def root
    Tk::Root.new
  end

  def Tk.load_tclscript(file, enc=nil)
    if enc
      # TCL_VERSION >= 8.5
      tk_call('source', '-encoding', enc, file)
    else
      tk_call('source', file)
    end
  end

  def Tk.load_tcllibrary(file, pkg_name=None, interp=None)
    tk_call('load', file, pkg_name, interp)
  end

  def Tk.unload_tcllibrary(*args)
    if args[-1].kind_of?(Hash)
      keys = _symbolkey2str(args.pop)
      nocomp = (keys['nocomplain'])? '-nocomplain': None
      keeplib = (keys['keeplibrary'])? '-keeplibrary': None
      tk_call('unload', nocomp, keeplib, '--', *args)
    else
      tk_call('unload', *args)
    end
  end

  def Tk.pkgconfig_list(mod)
    # Tk8.5 feature
    if mod.kind_of?(Module)
      if mod.respond_to?(:package_name)
        pkgname = mod.package_name
      elsif mod.const_defined?(:PACKAGE_NAME)
        pkgname = mod::PACKAGE_NAME
      else
        fail NotImplementedError, 'may not be a module for a Tcl extension'
      end
    else
      pkgname = mod.to_s
    end

    pkgname = '::' << pkgname unless pkgname =~ /^::/

    tk_split_list(tk_call(pkgname + '::pkgconfig', 'list'))
  end

  def Tk.pkgconfig_get(mod, key)
    # Tk8.5 feature
    if mod.kind_of?(Module)
      if mod.respond_to?(:package_name)
        pkgname = mod.package_name
      else
        fail NotImplementedError, 'may not be a module for a Tcl extension'
      end
    else
      pkgname = mod.to_s
    end

    pkgname = '::' << pkgname unless pkgname =~ /^::/

    tk_call(pkgname + '::pkgconfig', 'get', key)
  end

  def Tk.tcl_pkgconfig_list
    # Tk8.5 feature
    Tk.pkgconfig_list('::tcl')
  end

  def Tk.tcl_pkgconfig_get(key)
    # Tk8.5 feature
    Tk.pkgconfig_get('::tcl', key)
  end

  def Tk.tk_pkgconfig_list
    # Tk8.5 feature
    Tk.pkgconfig_list('::tk')
  end

  def Tk.tk_pkgconfig_get(key)
    # Tk8.5 feature
    Tk.pkgconfig_get('::tk', key)
  end

  def Tk.bell(nice = false)
    if nice
      tk_call_without_enc('bell', '-nice')
    else
      tk_call_without_enc('bell')
    end
    nil
  end

  def Tk.bell_on_display(win, nice = false)
    if nice
      tk_call_without_enc('bell', '-displayof', win, '-nice')
    else
      tk_call_without_enc('bell', '-displayof', win)
    end
    nil
  end

  def Tk.destroy(*wins)
    #tk_call_without_enc('destroy', *wins)
    tk_call_without_enc('destroy', *(wins.collect{|win|
                                       if win.kind_of?(TkWindow)
                                         win.epath
                                       else
                                         win
                                       end
                                     }))
  end

  def Tk.exit
    TkCore::INTERP.has_mainwindow? && tk_call_without_enc('destroy', '.')
  end

  ################################################

  def Tk.sleep(ms = nil, id = nil)
    if id
      var = (id.kind_of?(TkVariable))? id: TkVarAccess.new(id.to_s)
    else
      var = TkVariable.new
    end

    var.value = tk_call_without_enc('after', ms, proc{ var.value = 0 }) if ms
    var.thread_wait
    ms
  end

  def Tk.wakeup(id)
    ((id.kind_of?(TkVariable))? id: TkVarAccess.new(id.to_s)).value = 0
    nil
  end

  ################################################

  def Tk.pack(*args)
    TkPack.configure(*args)
  end
  def Tk.pack_forget(*args)
    TkPack.forget(*args)
  end
  def Tk.unpack(*args)
    TkPack.forget(*args)
  end

  def Tk.grid(*args)
    TkGrid.configure(*args)
  end
  def Tk.grid_forget(*args)
    TkGrid.forget(*args)
  end
  def Tk.ungrid(*args)
    TkGrid.forget(*args)
  end

  def Tk.place(*args)
    TkPlace.configure(*args)
  end
  def Tk.place_forget(*args)
    TkPlace.forget(*args)
  end
  def Tk.unplace(*args)
    TkPlace.forget(*args)
  end

  def Tk.update(idle=nil)
    if idle
      tk_call_without_enc('update', 'idletasks')
    else
      tk_call_without_enc('update')
    end
  end
  def Tk.update_idletasks
    update(true)
  end
  def update(idle=nil)
    # only for backward compatibility (This never be recommended to use)
    Tk.update(idle)
    self
  end

  # NOTE::
  #   If no eventloop-thread is running, "thread_update" method is same
  #   to "update" method. Else, "thread_update" method waits to complete
  #   idletask operation on the eventloop-thread.
  def Tk.thread_update(idle=nil)
    if idle
      tk_call_without_enc('thread_update', 'idletasks')
    else
      tk_call_without_enc('thread_update')
    end
  end
  def Tk.thread_update_idletasks
    thread_update(true)
  end

  def Tk.lower_window(win, below=None)
    tk_call('lower', _epath(win), _epath(below))
    nil
  end
  def Tk.raise_window(win, above=None)
    tk_call('raise', _epath(win), _epath(above))
    nil
  end

  def Tk.current_grabs(win = nil)
    if win
      window(tk_call_without_enc('grab', 'current', win))
    else
      tk_split_list(tk_call_without_enc('grab', 'current'))
    end
  end

  def Tk.focus(display=nil)
    if display == nil
      window(tk_call_without_enc('focus'))
    else
      window(tk_call_without_enc('focus', '-displayof', display))
    end
  end

  def Tk.focus_to(win, force=false)
    if force
      tk_call_without_enc('focus', '-force', win)
    else
      tk_call_without_enc('focus', win)
    end
  end

  def Tk.focus_lastfor(win)
    window(tk_call_without_enc('focus', '-lastfor', win))
  end

  def Tk.focus_next(win)
    TkManageFocus.next(win)
  end

  def Tk.focus_prev(win)
    TkManageFocus.prev(win)
  end

  def Tk.strictMotif(mode=None)
    bool(tk_call_without_enc('set', 'tk_strictMotif', mode))
  end

  def Tk.show_kinsoku(mode='both')
    begin
      if /^8\.*/ === TK_VERSION  && JAPANIZED_TK
        tk_split_simplelist(tk_call('kinsoku', 'show', mode))
      end
    rescue
    end
  end
  def Tk.add_kinsoku(chars, mode='both')
    begin
      if /^8\.*/ === TK_VERSION  && JAPANIZED_TK
        tk_split_simplelist(tk_call('kinsoku', 'add', mode,
                                    *(chars.split(''))))
      else
        []
      end
    rescue
      []
    end
  end
  def Tk.delete_kinsoku(chars, mode='both')
    begin
      if /^8\.*/ === TK_VERSION  && JAPANIZED_TK
        tk_split_simplelist(tk_call('kinsoku', 'delete', mode,
                            *(chars.split(''))))
      end
    rescue
    end
  end

  def Tk.toUTF8(str, encoding = nil)
    _toUTF8(str, encoding)
  end

  def Tk.fromUTF8(str, encoding = nil)
    _fromUTF8(str, encoding)
  end
end

# Tk::Encoding module loaded after TkCore is defined
require_relative 'tk/encoding'
require_relative 'tk/bind_core'

module TkTreatFont
  def __font_optkeys
    ['font']
  end
  private :__font_optkeys

  def __pathname
    self.path
  end
  private :__pathname

  ################################

  def font_configinfo(key = nil)
    optkeys = __font_optkeys
    if key && !optkeys.find{|opt| opt.to_s == key.to_s}
      fail ArgumentError, "unknown font option name `#{key}'"
    end

    win, tag = __pathname.split(':')

    if key
      pathname = [win, tag, key].join(';')
      TkFont.used_on(pathname) ||
        TkFont.init_widget_font(pathname, *__confinfo_cmd)
    elsif optkeys.size == 1
      pathname = [win, tag, optkeys[0]].join(';')
      TkFont.used_on(pathname) ||
        TkFont.init_widget_font(pathname, *__confinfo_cmd)
    else
      fonts = {}
      optkeys.each{|k|
        k = k.to_s
        pathname = [win, tag, k].join(';')
        fonts[k] =
          TkFont.used_on(pathname) ||
          TkFont.init_widget_font(pathname, *__confinfo_cmd)
      }
      fonts
    end
  end
  alias fontobj font_configinfo

  def font_configure(slot)
    pathname = __pathname

    slot = _symbolkey2str(slot)

    __font_optkeys.each{|optkey|
      optkey = optkey.to_s
      l_optkey = 'latin' << optkey
      a_optkey = 'ascii' << optkey
      k_optkey = 'kanji' << optkey

      if slot.key?(optkey)
        fnt = slot.delete(optkey)
        if fnt.kind_of?(TkFont)
          slot.delete(l_optkey)
          slot.delete(a_optkey)
          slot.delete(k_optkey)

          fnt.call_font_configure([pathname, optkey], *(__config_cmd << {}))
          next
        else
          if fnt
            if (slot.key?(l_optkey) ||
                slot.key?(a_optkey) ||
                slot.key?(k_optkey))
              fnt = TkFont.new(fnt)

              lfnt = slot.delete(l_optkey)
              lfnt = slot.delete(a_optkey) if slot.key?(a_optkey)
              kfnt = slot.delete(k_optkey)

              fnt.latin_replace(lfnt) if lfnt
              fnt.kanji_replace(kfnt) if kfnt

              fnt.call_font_configure([pathname, optkey],
                                      *(__config_cmd << {}))
              next
            else
              fnt = hash_kv(fnt) if fnt.kind_of?(Hash)
              unless TkConfigMethod.__IGNORE_UNKNOWN_CONFIGURE_OPTION__
                tk_call(*(__config_cmd << "-#{optkey}" << fnt))
              else
                begin
                  tk_call(*(__config_cmd << "-#{optkey}" << fnt))
                rescue
                  # ignore
                end
              end
            end
          end
          next
        end
      end

      lfnt = slot.delete(l_optkey)
      lfnt = slot.delete(a_optkey) if slot.key?(a_optkey)
      kfnt = slot.delete(k_optkey)

      if lfnt && kfnt
        TkFont.new(lfnt, kfnt).call_font_configure([pathname, optkey],
                                                   *(__config_cmd << {}))
      elsif lfnt
        latinfont_configure([lfnt, optkey])
      elsif kfnt
        kanjifont_configure([kfnt, optkey])
      end
    }

    # configure other (without font) options
    tk_call(*(__config_cmd.concat(hash_kv(slot)))) if slot != {}
    self
  end

  def latinfont_configure(ltn, keys=nil)
    if ltn.kind_of?(Array)
      key = ltn[1]
      ltn = ltn[0]
    else
      key = nil
    end

    optkeys = __font_optkeys
    if key && !optkeys.find{|opt| opt.to_s == key.to_s}
      fail ArgumentError, "unknown font option name `#{key}'"
    end

    win, tag = __pathname.split(':')

    optkeys = [key] if key

    optkeys.each{|optkey|
      optkey = optkey.to_s

      pathname = [win, tag, optkey].join(';')

      if (fobj = TkFont.used_on(pathname))
        fobj = TkFont.new(fobj) # create a new TkFont object
      elsif Tk::JAPANIZED_TK
        fobj = fontobj          # create a new TkFont object
      else
        ltn = hash_kv(ltn) if ltn.kind_of?(Hash)
        unless TkConfigMethod.__IGNORE_UNKNOWN_CONFIGURE_OPTION__
          tk_call(*(__config_cmd << "-#{optkey}" << ltn))
        else
          begin
            tk_call(*(__config_cmd << "-#{optkey}" << ltn))
          rescue
            # ignore
          end
        end
        next
      end

      if fobj.kind_of?(TkFont)
        if ltn.kind_of?(TkFont)
          conf = {}
          ltn.latin_configinfo.each{|k,val| conf[k] = val}
          if keys
            fobj.latin_configure(conf.update(keys))
          else
            fobj.latin_configure(conf)
          end
        else
          fobj.latin_replace(ltn)
        end
      end

      fobj.call_font_configure([pathname, optkey], *(__config_cmd << {}))
    }
    self
  end
  alias asciifont_configure latinfont_configure

  def kanjifont_configure(knj, keys=nil)
    if knj.kind_of?(Array)
      key = knj[1]
      knj = knj[0]
    else
      key = nil
    end

    optkeys = __font_optkeys
    if key && !optkeys.find{|opt| opt.to_s == key.to_s}
      fail ArgumentError, "unknown font option name `#{key}'"
    end

    win, tag = __pathname.split(':')

    optkeys = [key] if key

    optkeys.each{|optkey|
      optkey = optkey.to_s

      pathname = [win, tag, optkey].join(';')

      if (fobj = TkFont.used_on(pathname))
        fobj = TkFont.new(fobj) # create a new TkFont object
      elsif Tk::JAPANIZED_TK
        fobj = fontobj          # create a new TkFont object
      else
        knj = hash_kv(knj) if knj.kind_of?(Hash)
        unless TkConfigMethod.__IGNORE_UNKNOWN_CONFIGURE_OPTION__
          tk_call(*(__config_cmd << "-#{optkey}" << knj))
        else
          begin
            tk_call(*(__config_cmd << "-#{optkey}" << knj))
          rescue
            # ignore
          end
        end
        next
      end

      if fobj.kind_of?(TkFont)
        if knj.kind_of?(TkFont)
          conf = {}
          knj.kanji_configinfo.each{|k,val| conf[k] = val}
          if keys
            fobj.kanji_configure(conf.update(keys))
          else
            fobj.kanji_configure(conf)
          end
        else
          fobj.kanji_replace(knj)
        end
      end

      fobj.call_font_configure([pathname, optkey], *(__config_cmd << {}))
    }
    self
  end

  def font_copy(win, wintag=nil, winkey=nil, targetkey=nil)
    if wintag
      if winkey
        fnt = win.tagfontobj(wintag, winkey).dup
      else
        fnt = win.tagfontobj(wintag).dup
      end
    else
      if winkey
        fnt = win.fontobj(winkey).dup
      else
        fnt = win.fontobj.dup
      end
    end

    if targetkey
      fnt.call_font_configure([__pathname, targetkey], *(__config_cmd << {}))
    else
      fnt.call_font_configure(__pathname, *(__config_cmd << {}))
    end
    self
  end

  def latinfont_copy(win, wintag=nil, winkey=nil, targetkey=nil)
    if targetkey
      fontobj(targetkey).dup.call_font_configure([__pathname, targetkey],
                                                 *(__config_cmd << {}))
    else
      fontobj.dup.call_font_configure(__pathname, *(__config_cmd << {}))
    end

    if wintag
      if winkey
        fontobj.latin_replace(win.tagfontobj(wintag, winkey).latin_font_id)
      else
        fontobj.latin_replace(win.tagfontobj(wintag).latin_font_id)
      end
    else
      if winkey
        fontobj.latin_replace(win.fontobj(winkey).latin_font_id)
      else
        fontobj.latin_replace(win.fontobj.latin_font_id)
      end
    end
    self
  end
  alias asciifont_copy latinfont_copy

  def kanjifont_copy(win, wintag=nil, winkey=nil, targetkey=nil)
    if targetkey
      fontobj(targetkey).dup.call_font_configure([__pathname, targetkey],
                                                 *(__config_cmd << {}))
    else
        fontobj.dup.call_font_configure(__pathname, *(__config_cmd << {}))
    end

    if wintag
      if winkey
        fontobj.kanji_replace(win.tagfontobj(wintag, winkey).kanji_font_id)
      else
        fontobj.kanji_replace(win.tagfontobj(wintag).kanji_font_id)
      end
    else
      if winkey
        fontobj.kanji_replace(win.fontobj(winkey).kanji_font_id)
      else
        fontobj.kanji_replace(win.fontobj.kanji_font_id)
      end
    end
    self
  end
end


module TkConfigMethod
  include TkUtil
  include TkTreatFont

  def TkConfigMethod.__IGNORE_UNKNOWN_CONFIGURE_OPTION__
    @mode || false
  end
  def TkConfigMethod.__set_IGNORE_UNKNOWN_CONFIGURE_OPTION__!(mode)
    @mode = (mode)? true: false
  end

  def __cget_cmd
    [self.path, 'cget']
  end
  private :__cget_cmd

  def __config_cmd
    [self.path, 'configure']
  end
  private :__config_cmd

  def __confinfo_cmd
    __config_cmd
  end
  private :__confinfo_cmd

  def __configinfo_struct
    {:key=>0, :alias=>1, :db_name=>1, :db_class=>2,
      :default_value=>3, :current_value=>4}
  end
  private :__configinfo_struct

  def __optkey_aliases
    {}
  end
  private :__optkey_aliases

  def __numval_optkeys
    []
  end
  private :__numval_optkeys

  def __numstrval_optkeys
    []
  end
  private :__numstrval_optkeys

  def __boolval_optkeys
    ['exportselection', 'jump', 'setgrid', 'takefocus']
  end
  private :__boolval_optkeys

  def __strval_optkeys
    [
      'text', 'label', 'show', 'data', 'file',
      'activebackground', 'activeforeground', 'background',
      'disabledforeground', 'disabledbackground', 'foreground',
      'highlightbackground', 'highlightcolor', 'insertbackground',
      'selectbackground', 'selectforeground', 'troughcolor'
    ]
  end
  private :__strval_optkeys

  def __listval_optkeys
    []
  end
  private :__listval_optkeys

  def __numlistval_optkeys
    []
  end
  private :__numlistval_optkeys

  def __tkvariable_optkeys
    ['variable', 'textvariable']
  end
  private :__tkvariable_optkeys

  def __val2ruby_optkeys  # { key=>proc, ... }
    # The method is used to convert a opt-value to a ruby's object.
    # When get the value of the option "key", "proc.call(value)" is called.
    {}
  end
  private :__val2ruby_optkeys

  def __ruby2val_optkeys  # { key=>proc, ... }
    # The method is used to convert a ruby's object to a opt-value.
    # When set the value of the option "key", "proc.call(value)" is called.
    # That is, "-#{key} #{proc.call(value)}".
    {}
  end
  private :__ruby2val_optkeys

  def __methodcall_optkeys  # { key=>method, ... }
    # The method is used to both of get and set.
    # Usually, the 'key' will not be a widget option.
    {}
  end
  private :__methodcall_optkeys

  def __keyonly_optkeys  # { def_key=>undef_key or nil, ... }
    {}
  end
  private :__keyonly_optkeys

  def __conv_keyonly_opts(keys)
    return keys unless keys.kind_of?(Hash)
    keyonly = __keyonly_optkeys
    keys2 = {}
    keys.each{|k, v|
      optkey = keyonly.find{|kk,vv| kk.to_s == k.to_s}
      if optkey
        defkey, undefkey = optkey
        if v
          keys2[defkey.to_s] = None
        elsif undefkey
          keys2[undefkey.to_s] = None
        else
          # remove key
        end
      else
        keys2[k.to_s] = v
      end
    }
    keys2
  end
  private :__conv_keyonly_opts

  def config_hash_kv(keys, enc_mode = nil, conf = nil)
    hash_kv(__conv_keyonly_opts(keys), enc_mode, conf)
  end

  ################################

  def [](id)
    cget(id)
  end

  def []=(id, val)
    configure(id, val)
    val
  end

  def cget_tkstring(option)
    opt = option.to_s
    fail ArgumentError, "Invalid option `#{option.inspect}'" if opt.length == 0
    tk_call_without_enc(*(__cget_cmd << "-#{opt}"))
  end

  def __cget_core(slot)
    orig_slot = slot
    slot = slot.to_s

    if slot.length == 0
      fail ArgumentError, "Invalid option `#{orig_slot.inspect}'"
    end

    _, real_name = __optkey_aliases.find{|k, v| k.to_s == slot}
    if real_name
      slot = real_name.to_s
    end

    if ( method = _symbolkey2str(__val2ruby_optkeys())[slot] )
      optval = tk_call_without_enc(*(__cget_cmd << "-#{slot}"))
      begin
        return method.call(optval)
      rescue => e
        warn("Warning:: #{e.message} (when #{method}.call(#{optval.inspect})") if $DEBUG
        return optval
      end
    end

    if ( method = _symbolkey2str(__methodcall_optkeys)[slot] )
      return self.__send__(method)
    end

    case slot
    when /^(#{__numval_optkeys.join('|')})$/
      begin
        number(tk_call_without_enc(*(__cget_cmd << "-#{slot}")))
      rescue
        nil
      end

    when /^(#{__numstrval_optkeys.join('|')})$/
      num_or_str(tk_call_without_enc(*(__cget_cmd << "-#{slot}")))

    when /^(#{__boolval_optkeys.join('|')})$/
      begin
        bool(tk_call_without_enc(*(__cget_cmd << "-#{slot}")))
      rescue
        nil
      end

    when /^(#{__listval_optkeys.join('|')})$/
      simplelist(tk_call_without_enc(*(__cget_cmd << "-#{slot}")))

    when /^(#{__numlistval_optkeys.join('|')})$/
      conf = tk_call_without_enc(*(__cget_cmd << "-#{slot}"))
      if conf =~ /^[0-9+-]/
        list(conf)
      else
        conf
      end

    when /^(#{__strval_optkeys.join('|')})$/
      _fromUTF8(tk_call_without_enc(*(__cget_cmd << "-#{slot}")))

    when /^(|latin|ascii|kanji)(#{__font_optkeys.join('|')})$/
      fontcode = $1
      fontkey  = $2
      fnt = tk_tcl2ruby(tk_call_without_enc(*(__cget_cmd << "-#{fontkey}")), true)
      unless fnt.kind_of?(TkFont)
        fnt = fontobj(fontkey)
      end
      if fontcode == 'kanji' && JAPANIZED_TK && TK_VERSION =~ /^4\.*/
        # obsolete; just for compatibility
        fnt.kanji_font
      else
        fnt
      end

    when /^(#{__tkvariable_optkeys.join('|')})$/
      v = tk_call_without_enc(*(__cget_cmd << "-#{slot}"))
      (v.empty?)? nil: TkVarAccess.new(v)

    else
      tk_tcl2ruby(tk_call_without_enc(*(__cget_cmd << "-#{slot}")), true)
    end
  end
  private :__cget_core

  def cget(slot)
    unless TkConfigMethod.__IGNORE_UNKNOWN_CONFIGURE_OPTION__
      __cget_core(slot)
    else
      begin
        __cget_core(slot)
      rescue => e
        if current_configinfo.has_key?(slot.to_s)
          # error on known option
          fail e
        else
          # unknown option
          nil
        end
      end
    end
  end
  def cget_strict(slot)
    # never use TkConfigMethod.__IGNORE_UNKNOWN_CONFIGURE_OPTION__
    __cget_core(slot)
  end

  def __configure_core(slot, value=None)
    if slot.kind_of? Hash
      slot = _symbolkey2str(slot)

      __optkey_aliases.each{|alias_name, real_name|
        alias_name = alias_name.to_s
        if slot.has_key?(alias_name)
          slot[real_name.to_s] = slot.delete(alias_name)
        end
      }

      __methodcall_optkeys.each{|key, method|
        value = slot.delete(key.to_s)
        self.__send__(method, value) if value
      }

      __ruby2val_optkeys.each{|key, method|
        key = key.to_s
        slot[key] = method.call(slot[key]) if slot.has_key?(key)
      }

      __keyonly_optkeys.each{|defkey, undefkey|
        conf = slot.find{|kk, vv| kk == defkey.to_s}
        if conf
          k, v = conf
          if v
            slot[k] = None
          else
            slot[undefkey.to_s] = None if undefkey
            slot.delete(k)
          end
        end
      }

      if (slot.find{|k, v| k =~ /^(|latin|ascii|kanji)(#{__font_optkeys.join('|')})$/})
        font_configure(slot)
      elsif slot.size > 0
        tk_call(*(__config_cmd.concat(hash_kv(slot))))
      end

    else
      orig_slot = slot
      slot = slot.to_s
      if slot.length == 0
        fail ArgumentError, "Invalid option `#{orig_slot.inspect}'"
      end

      _, real_name = __optkey_aliases.find{|k, v| k.to_s == slot}
      if real_name
        slot = real_name.to_s
      end

      if ( conf = __keyonly_optkeys.find{|k, v| k.to_s == slot} )
        defkey, undefkey = conf
        if value
          tk_call(*(__config_cmd << "-#{defkey}"))
        elsif undefkey
          tk_call(*(__config_cmd << "-#{undefkey}"))
        end
      elsif ( method = _symbolkey2str(__ruby2val_optkeys)[slot] )
        tk_call(*(__config_cmd << "-#{slot}" << method.call(value)))
      elsif ( method = _symbolkey2str(__methodcall_optkeys)[slot] )
        self.__send__(method, value)
      elsif (slot =~ /^(|latin|ascii|kanji)(#{__font_optkeys.join('|')})$/)
        if value == None
          fontobj($2)
        else
          font_configure({slot=>value})
        end
      else
        tk_call(*(__config_cmd << "-#{slot}" << value))
      end
    end
    self
  end
  private :__configure_core

  def __check_available_configure_options(keys)
    availables = self.current_configinfo.keys

    # add non-standard keys
    availables |= __font_optkeys.map{|k|
      [k.to_s, "latin#{k}", "ascii#{k}", "kanji#{k}"]
    }.flatten
    availables |= __methodcall_optkeys.keys.map{|k| k.to_s}
    availables |= __keyonly_optkeys.keys.map{|k| k.to_s}

    keys = _symbolkey2str(keys)
    keys.delete_if{|k, v| !(availables.include?(k))}
  end

  def configure(slot, value=None)
    unless TkConfigMethod.__IGNORE_UNKNOWN_CONFIGURE_OPTION__
      __configure_core(slot, value)
    else
      if slot.kind_of?(Hash)
        begin
          __configure_core(slot)
        rescue
          slot = __check_available_configure_options(slot)
          __configure_core(slot) unless slot.empty?
        end
      else
        begin
          __configure_core(slot, value)
        rescue => e
          if current_configinfo.has_key?(slot.to_s)
            # error on known option
            fail e
          else
            # unknown option
            nil
          end
        end
      end
    end
    self
  end

  def configure_cmd(slot, value)
    configure(slot, install_cmd(value))
  end

  def __configinfo_core(slot = nil)
    if TkComm::GET_CONFIGINFO_AS_ARRAY
      if (slot &&
          slot.to_s =~ /^(|latin|ascii|kanji)(#{__font_optkeys.join('|')})$/)
        fontkey  = $2
        # conf = tk_split_simplelist(_fromUTF8(tk_call_without_enc(*(__confinfo_cmd << "-#{fontkey}"))))
        conf = tk_split_simplelist(tk_call_without_enc(*(__confinfo_cmd << "-#{fontkey}")), false, true)
        conf[__configinfo_struct[:key]] =
          conf[__configinfo_struct[:key]][1..-1]
        if ( ! __configinfo_struct[:alias] \
            || conf.size > __configinfo_struct[:alias] + 1 )
          fnt = conf[__configinfo_struct[:default_value]]
          if TkFont.is_system_font?(fnt)
            conf[__configinfo_struct[:default_value]] = TkNamedFont.new(fnt)
          end
          conf[__configinfo_struct[:current_value]] = fontobj(fontkey)
        elsif ( __configinfo_struct[:alias] \
               && conf.size == __configinfo_struct[:alias] + 1 \
               && conf[__configinfo_struct[:alias]][0] == ?- )
          conf[__configinfo_struct[:alias]] =
            conf[__configinfo_struct[:alias]][1..-1]
        end
        conf
      else
        if slot
          slot = slot.to_s

          _, real_name = __optkey_aliases.find{|k, v| k.to_s == slot}
          if real_name
            slot = real_name.to_s
          end

          case slot
          when /^(#{__val2ruby_optkeys().keys.join('|')})$/
            method = _symbolkey2str(__val2ruby_optkeys())[slot]
            conf = tk_split_simplelist(tk_call_without_enc(*(__confinfo_cmd() << "-#{slot}")), false, true)
            if ( __configinfo_struct[:default_value] \
                && conf[__configinfo_struct[:default_value]] )
              optval = conf[__configinfo_struct[:default_value]]
              begin
                val = method.call(optval)
              rescue => e
                warn("Warning:: #{e.message} (when #{method}.call(#{optval.inspect})") if $DEBUG
                val = optval
              end
              conf[__configinfo_struct[:default_value]] = val
            end
            if ( conf[__configinfo_struct[:current_value]] )
              optval = conf[__configinfo_struct[:current_value]]
              begin
                val = method.call(optval)
              rescue => e
                warn("Warning:: #{e.message} (when #{method}.call(#{optval.inspect})") if $DEBUG
                val = optval
              end
              conf[__configinfo_struct[:current_value]] = val
            end

          when /^(#{__methodcall_optkeys.keys.join('|')})$/
            method = _symbolkey2str(__methodcall_optkeys)[slot]
            return [slot, '', '', '', self.__send__(method)]

          when /^(#{__numval_optkeys.join('|')})$/
            # conf = tk_split_simplelist(_fromUTF8(tk_call_without_enc(*(__confinfo_cmd << "-#{slot}"))))
            conf = tk_split_simplelist(tk_call_without_enc(*(__confinfo_cmd << "-#{slot}")), false, true)

            if ( __configinfo_struct[:default_value] \
                && conf[__configinfo_struct[:default_value]])
              begin
                conf[__configinfo_struct[:default_value]] =
                  number(conf[__configinfo_struct[:default_value]])
              rescue
                conf[__configinfo_struct[:default_value]] = nil
              end
            end
            if ( conf[__configinfo_struct[:current_value]] )
              begin
                conf[__configinfo_struct[:current_value]] =
                  number(conf[__configinfo_struct[:current_value]])
              rescue
                conf[__configinfo_struct[:current_value]] = nil
              end
            end

          when /^(#{__numstrval_optkeys.join('|')})$/
            # conf = tk_split_simplelist(_fromUTF8(tk_call_without_enc(*(__confinfo_cmd << "-#{slot}"))))
            conf = tk_split_simplelist(tk_call_without_enc(*(__confinfo_cmd << "-#{slot}")), false, true)

            if ( __configinfo_struct[:default_value] \
                && conf[__configinfo_struct[:default_value]])
              conf[__configinfo_struct[:default_value]] =
                num_or_str(conf[__configinfo_struct[:default_value]])
            end
            if ( conf[__configinfo_struct[:current_value]] )
              conf[__configinfo_struct[:current_value]] =
                num_or_str(conf[__configinfo_struct[:current_value]])
            end

          when /^(#{__boolval_optkeys.join('|')})$/
            # conf = tk_split_simplelist(_fromUTF8(tk_call_without_enc(*(__confinfo_cmd << "-#{slot}"))))
            conf = tk_split_simplelist(tk_call_without_enc(*(__confinfo_cmd << "-#{slot}")), false, true)

            if ( __configinfo_struct[:default_value] \
                && conf[__configinfo_struct[:default_value]])
              begin
                conf[__configinfo_struct[:default_value]] =
                  bool(conf[__configinfo_struct[:default_value]])
              rescue
                conf[__configinfo_struct[:default_value]] = nil
              end
            end
            if ( conf[__configinfo_struct[:current_value]] )
              begin
                conf[__configinfo_struct[:current_value]] =
                  bool(conf[__configinfo_struct[:current_value]])
              rescue
                conf[__configinfo_struct[:current_value]] = nil
              end
            end

          when /^(#{__listval_optkeys.join('|')})$/
            # conf = tk_split_simplelist(_fromUTF8(tk_call_without_enc(*(__confinfo_cmd << "-#{slot}"))))
            conf = tk_split_simplelist(tk_call_without_enc(*(__confinfo_cmd << "-#{slot}")), false, true)

            if ( __configinfo_struct[:default_value] \
                && conf[__configinfo_struct[:default_value]])
              conf[__configinfo_struct[:default_value]] =
                simplelist(conf[__configinfo_struct[:default_value]])
            end
            if ( conf[__configinfo_struct[:current_value]] )
              conf[__configinfo_struct[:current_value]] =
                simplelist(conf[__configinfo_struct[:current_value]])
            end

          when /^(#{__numlistval_optkeys.join('|')})$/
            # conf = tk_split_simplelist(_fromUTF8(tk_call_without_enc(*(__confinfo_cmd << "-#{slot}"))))
            conf = tk_split_simplelist(tk_call_without_enc(*(__confinfo_cmd << "-#{slot}")), false, true)

            if ( __configinfo_struct[:default_value] \
                && conf[__configinfo_struct[:default_value]] \
                && conf[__configinfo_struct[:default_value]] =~ /^[0-9]/ )
              conf[__configinfo_struct[:default_value]] =
                list(conf[__configinfo_struct[:default_value]])
            end
            if ( conf[__configinfo_struct[:current_value]] \
                && conf[__configinfo_struct[:current_value]] =~ /^[0-9]/ )
              conf[__configinfo_struct[:current_value]] =
                list(conf[__configinfo_struct[:current_value]])
            end

          when /^(#{__strval_optkeys.join('|')})$/
            # conf = tk_split_simplelist(_fromUTF8(tk_call_without_enc(*(__confinfo_cmd << "-#{slot}"))))
            conf = tk_split_simplelist(tk_call_without_enc(*(__confinfo_cmd << "-#{slot}")), false, true)

          when /^(#{__tkvariable_optkeys.join('|')})$/
            conf = tk_split_simplelist(tk_call_without_enc(*(__confinfo_cmd << "-#{slot}")), false, true)

            if ( __configinfo_struct[:default_value] \
                && conf[__configinfo_struct[:default_value]])
              v = conf[__configinfo_struct[:default_value]]
              if v.empty?
                conf[__configinfo_struct[:default_value]] = nil
              else
                conf[__configinfo_struct[:default_value]] = TkVarAccess.new(v)
              end
            end
            if ( conf[__configinfo_struct[:current_value]] )
              v = conf[__configinfo_struct[:current_value]]
              if v.empty?
                conf[__configinfo_struct[:current_value]] = nil
              else
                conf[__configinfo_struct[:current_value]] = TkVarAccess.new(v)
              end
            end

          else
            # conf = tk_split_list(_fromUTF8(tk_call_without_enc(*(__confinfo_cmd << "-#{slot}"))))
            # conf = tk_split_list(tk_call_without_enc(*(__confinfo_cmd << "-#{slot}")), 0, false, true)
            conf = tk_split_list(tk_call_without_enc(*(__confinfo_cmd << "-#{slot}")), 1, false, true)
          end
          conf[__configinfo_struct[:key]] =
            conf[__configinfo_struct[:key]][1..-1]

          if ( __configinfo_struct[:alias] \
              && conf.size == __configinfo_struct[:alias] + 1 \
              && conf[__configinfo_struct[:alias]][0] == ?- )
            conf[__configinfo_struct[:alias]] =
              conf[__configinfo_struct[:alias]][1..-1]
          end

          conf

        else
          # ret = tk_split_simplelist(_fromUTF8(tk_call_without_enc(*__confinfo_cmd))).collect{|conflist|
          #  conf = tk_split_simplelist(conflist)
          ret = tk_split_simplelist(tk_call_without_enc(*__confinfo_cmd), false, false).collect{|conflist|
            conf = tk_split_simplelist(conflist, false, true)
            conf[__configinfo_struct[:key]] =
              conf[__configinfo_struct[:key]][1..-1]

            optkey = conf[__configinfo_struct[:key]]
            case optkey
            when /^(#{__val2ruby_optkeys().keys.join('|')})$/
              method = _symbolkey2str(__val2ruby_optkeys())[optkey]
              if ( __configinfo_struct[:default_value] \
                  && conf[__configinfo_struct[:default_value]] )
                optval = conf[__configinfo_struct[:default_value]]
                begin
                  val = method.call(optval)
                rescue => e
                  warn("Warning:: #{e.message} (when #{method}.call(#{optval.inspect})") if $DEBUG
                  val = optval
                end
                conf[__configinfo_struct[:default_value]] = val
              end
              if ( conf[__configinfo_struct[:current_value]] )
                optval = conf[__configinfo_struct[:current_value]]
                begin
                  val = method.call(optval)
                rescue => e
                  warn("Warning:: #{e.message} (when #{method}.call(#{optval.inspect})") if $DEBUG
                  val = optval
                end
                conf[__configinfo_struct[:current_value]] = val
              end

            when /^(#{__strval_optkeys.join('|')})$/
              # do nothing

            when /^(#{__numval_optkeys.join('|')})$/
              if ( __configinfo_struct[:default_value] \
                  && conf[__configinfo_struct[:default_value]] )
                begin
                  conf[__configinfo_struct[:default_value]] =
                    number(conf[__configinfo_struct[:default_value]])
                rescue
                  conf[__configinfo_struct[:default_value]] = nil
                end
              end
              if ( conf[__configinfo_struct[:current_value]] )
                begin
                  conf[__configinfo_struct[:current_value]] =
                    number(conf[__configinfo_struct[:current_value]])
                rescue
                  conf[__configinfo_struct[:current_value]] = nil
                end
              end

            when /^(#{__numstrval_optkeys.join('|')})$/
              if ( __configinfo_struct[:default_value] \
                  && conf[__configinfo_struct[:default_value]] )
                conf[__configinfo_struct[:default_value]] =
                  num_or_str(conf[__configinfo_struct[:default_value]])
              end
              if ( conf[__configinfo_struct[:current_value]] )
                conf[__configinfo_struct[:current_value]] =
                  num_or_str(conf[__configinfo_struct[:current_value]])
              end

            when /^(#{__boolval_optkeys.join('|')})$/
              if ( __configinfo_struct[:default_value] \
                  && conf[__configinfo_struct[:default_value]] )
                begin
                  conf[__configinfo_struct[:default_value]] =
                    bool(conf[__configinfo_struct[:default_value]])
                rescue
                  conf[__configinfo_struct[:default_value]] = nil
                end
              end
              if ( conf[__configinfo_struct[:current_value]] )
                begin
                  conf[__configinfo_struct[:current_value]] =
                    bool(conf[__configinfo_struct[:current_value]])
                rescue
                  conf[__configinfo_struct[:current_value]] = nil
                end
              end

            when /^(#{__listval_optkeys.join('|')})$/
              if ( __configinfo_struct[:default_value] \
                  && conf[__configinfo_struct[:default_value]] )
                conf[__configinfo_struct[:default_value]] =
                  simplelist(conf[__configinfo_struct[:default_value]])
              end
              if ( conf[__configinfo_struct[:current_value]] )
                conf[__configinfo_struct[:current_value]] =
                  simplelist(conf[__configinfo_struct[:current_value]])
              end

            when /^(#{__numlistval_optkeys.join('|')})$/
              if ( __configinfo_struct[:default_value] \
                  && conf[__configinfo_struct[:default_value]] \
                  && conf[__configinfo_struct[:default_value]] =~ /^[0-9]/ )
                conf[__configinfo_struct[:default_value]] =
                  list(conf[__configinfo_struct[:default_value]])
              end
              if ( conf[__configinfo_struct[:current_value]] \
                  && conf[__configinfo_struct[:current_value]] =~ /^[0-9]/ )
                conf[__configinfo_struct[:current_value]] =
                  list(conf[__configinfo_struct[:current_value]])
              end

            when /^(#{__tkvariable_optkeys.join('|')})$/
              if ( __configinfo_struct[:default_value] \
                  && conf[__configinfo_struct[:default_value]] )
                v = conf[__configinfo_struct[:default_value]]
                if v.empty?
                  conf[__configinfo_struct[:default_value]] = nil
                else
                  conf[__configinfo_struct[:default_value]] = TkVarAccess.new(v)
                end
              end
              if ( conf[__configinfo_struct[:current_value]] )
                v = conf[__configinfo_struct[:current_value]]
                if v.empty?
                  conf[__configinfo_struct[:current_value]] = nil
                else
                  conf[__configinfo_struct[:current_value]] = TkVarAccess.new(v)
                end
              end

            else
              if ( __configinfo_struct[:default_value] \
                  && conf[__configinfo_struct[:default_value]] )
                if conf[__configinfo_struct[:default_value]].index('{')
                  conf[__configinfo_struct[:default_value]] =
                    tk_split_list(conf[__configinfo_struct[:default_value]])
                else
                  conf[__configinfo_struct[:default_value]] =
                    tk_tcl2ruby(conf[__configinfo_struct[:default_value]])
                end
              end
              if conf[__configinfo_struct[:current_value]]
                if conf[__configinfo_struct[:current_value]].index('{')
                  conf[__configinfo_struct[:current_value]] =
                    tk_split_list(conf[__configinfo_struct[:current_value]])
                else
                  conf[__configinfo_struct[:current_value]] =
                    tk_tcl2ruby(conf[__configinfo_struct[:current_value]])
                end
              end
            end

            if ( __configinfo_struct[:alias] \
                && conf.size == __configinfo_struct[:alias] + 1 \
                && conf[__configinfo_struct[:alias]][0] == ?- )
              conf[__configinfo_struct[:alias]] =
                conf[__configinfo_struct[:alias]][1..-1]
            end

            conf
          }

          __font_optkeys.each{|optkey|
            optkey = optkey.to_s
            fontconf = ret.assoc(optkey)
            if fontconf && fontconf.size > 2
              ret.delete_if{|inf| inf[0] =~ /^(|latin|ascii|kanji)#{optkey}$/}
              fnt = fontconf[__configinfo_struct[:default_value]]
              if TkFont.is_system_font?(fnt)
                fontconf[__configinfo_struct[:default_value]] \
                  = TkNamedFont.new(fnt)
              end
              fontconf[__configinfo_struct[:current_value]] = fontobj(optkey)
              ret.push(fontconf)
            end
          }

          __methodcall_optkeys.each{|optkey, m|
            ret << [optkey.to_s, '', '', '', self.__send__(m)]
          }

          ret
        end
      end

    else # ! TkComm::GET_CONFIGINFO_AS_ARRAY
      if (slot &&
          slot.to_s =~ /^(|latin|ascii|kanji)(#{__font_optkeys.join('|')})$/)
        fontkey  = $2
        # conf = tk_split_simplelist(_fromUTF8(tk_call_without_enc(*(__confinfo_cmd << "-#{fontkey}"))))
        conf = tk_split_simplelist(tk_call_without_enc(*(__confinfo_cmd << "-#{fontkey}")), false, true)
        conf[__configinfo_struct[:key]] =
          conf[__configinfo_struct[:key]][1..-1]

        if ( ! __configinfo_struct[:alias] \
            || conf.size > __configinfo_struct[:alias] + 1 )
          fnt = conf[__configinfo_struct[:default_value]]
          if TkFont.is_system_font?(fnt)
            conf[__configinfo_struct[:default_value]] = TkNamedFont.new(fnt)
          end
          conf[__configinfo_struct[:current_value]] = fontobj(fontkey)
          { conf.shift => conf }
        elsif ( __configinfo_struct[:alias] \
               && conf.size == __configinfo_struct[:alias] + 1 )
          if conf[__configinfo_struct[:alias]][0] == ?-
            conf[__configinfo_struct[:alias]] =
              conf[__configinfo_struct[:alias]][1..-1]
          end
          { conf[0] => conf[1] }
        else
          { conf.shift => conf }
        end
      else
        if slot
          slot = slot.to_s

          _, real_name = __optkey_aliases.find{|k,var| k.to_s == slot}
          if real_name
            slot = real_name.to_s
          end

          case slot
          when /^(#{__val2ruby_optkeys().keys.join('|')})$/
            method = _symbolkey2str(__val2ruby_optkeys())[slot]
            conf = tk_split_simplelist(tk_call_without_enc(*(__confinfo_cmd << "-#{slot}")), false, true)
            if ( __configinfo_struct[:default_value] \
                && conf[__configinfo_struct[:default_value]] )
              optval = conf[__configinfo_struct[:default_value]]
              begin
                val = method.call(optval)
              rescue => e
                warn("Warning:: #{e.message} (when #{method}.call(#{optval.inspect})") if $DEBUG
                val = optval
              end
              conf[__configinfo_struct[:default_value]] = val
            end
            if ( conf[__configinfo_struct[:current_value]] )
              optval = conf[__configinfo_struct[:current_value]]
              begin
                val = method.call(optval)
              rescue => e
                warn("Warning:: #{e.message} (when #{method}.call(#{optval.inspect})") if $DEBUG
                val = optval
              end
              conf[__configinfo_struct[:current_value]] = val
            end

          when /^(#{__methodcall_optkeys.keys.join('|')})$/
            method = _symbolkey2str(__methodcall_optkeys)[slot]
            return {slot => ['', '', '', self.__send__(method)]}

          when /^(#{__numval_optkeys.join('|')})$/
            # conf = tk_split_simplelist(_fromUTF8(tk_call_without_enc(*(__confinfo_cmd << "-#{slot}"))))
            conf = tk_split_simplelist(tk_call_without_enc(*(__confinfo_cmd << "-#{slot}")), false, true)

            if ( __configinfo_struct[:default_value] \
                && conf[__configinfo_struct[:default_value]] )
              begin
                conf[__configinfo_struct[:default_value]] =
                  number(conf[__configinfo_struct[:default_value]])
              rescue
                conf[__configinfo_struct[:default_value]] = nil
              end
            end
            if ( conf[__configinfo_struct[:current_value]] )
              begin
                conf[__configinfo_struct[:current_value]] =
                  number(conf[__configinfo_struct[:current_value]])
              rescue
                conf[__configinfo_struct[:current_value]] = nil
              end
            end

          when /^(#{__numstrval_optkeys.join('|')})$/
            # conf = tk_split_simplelist(_fromUTF8(tk_call_without_enc(*(__confinfo_cmd << "-#{slot}"))))
            conf = tk_split_simplelist(tk_call_without_enc(*(__confinfo_cmd << "-#{slot}")), false, true)

            if ( __configinfo_struct[:default_value] \
                && conf[__configinfo_struct[:default_value]] )
              conf[__configinfo_struct[:default_value]] =
                num_or_str(conf[__configinfo_struct[:default_value]])
            end
            if ( conf[__configinfo_struct[:current_value]] )
              conf[__configinfo_struct[:current_value]] =
                num_or_str(conf[__configinfo_struct[:current_value]])
            end

          when /^(#{__boolval_optkeys.join('|')})$/
            # conf = tk_split_simplelist(_fromUTF8(tk_call_without_enc(*(__confinfo_cmd << "-#{slot}"))))
            conf = tk_split_simplelist(tk_call_without_enc(*(__confinfo_cmd << "-#{slot}")), false, true)

            if ( __configinfo_struct[:default_value] \
                && conf[__configinfo_struct[:default_value]] )
              begin
                conf[__configinfo_struct[:default_value]] =
                  bool(conf[__configinfo_struct[:default_value]])
              rescue
                conf[__configinfo_struct[:default_value]] = nil
              end
            end
            if ( conf[__configinfo_struct[:current_value]] )
              begin
                conf[__configinfo_struct[:current_value]] =
                  bool(conf[__configinfo_struct[:current_value]])
              rescue
                conf[__configinfo_struct[:current_value]] = nil
              end
            end

          when /^(#{__listval_optkeys.join('|')})$/
            # conf = tk_split_simplelist(_fromUTF8(tk_call_without_enc(*(__confinfo_cmd << "-#{slot}"))))
            conf = tk_split_simplelist(tk_call_without_enc(*(__confinfo_cmd << "-#{slot}")), false, true)

            if ( __configinfo_struct[:default_value] \
                && conf[__configinfo_struct[:default_value]] )
              conf[__configinfo_struct[:default_value]] =
                simplelist(conf[__configinfo_struct[:default_value]])
            end
            if ( conf[__configinfo_struct[:current_value]] )
              conf[__configinfo_struct[:current_value]] =
                simplelist(conf[__configinfo_struct[:current_value]])
            end

          when /^(#{__numlistval_optkeys.join('|')})$/
            # conf = tk_split_simplelist(_fromUTF8(tk_call_without_enc(*(__confinfo_cmd << "-#{slot}"))))
            conf = tk_split_simplelist(tk_call_without_enc(*(__confinfo_cmd << "-#{slot}")), false, true)

            if ( __configinfo_struct[:default_value] \
                && conf[__configinfo_struct[:default_value]] \
                && conf[__configinfo_struct[:default_value]] =~ /^[0-9]/ )
              conf[__configinfo_struct[:default_value]] =
                list(conf[__configinfo_struct[:default_value]])
            end
            if ( conf[__configinfo_struct[:current_value]] \
                && conf[__configinfo_struct[:current_value]] =~ /^[0-9]/ )
              conf[__configinfo_struct[:current_value]] =
                list(conf[__configinfo_struct[:current_value]])
            end

          when /^(#{__tkvariable_optkeys.join('|')})$/
            conf = tk_split_simplelist(tk_call_without_enc(*(__confinfo_cmd << "-#{slot}")), false, true)

            if ( __configinfo_struct[:default_value] \
                && conf[__configinfo_struct[:default_value]] )
              v = conf[__configinfo_struct[:default_value]]
              if v.empty?
                conf[__configinfo_struct[:default_value]] = nil
              else
                conf[__configinfo_struct[:default_value]] = TkVarAccess.new(v)
              end
            end
            if ( conf[__configinfo_struct[:current_value]] )
              v = conf[__configinfo_struct[:current_value]]
              if v.empty?
                conf[__configinfo_struct[:current_value]] = nil
              else
                conf[__configinfo_struct[:current_value]] = TkVarAccess.new(v)
              end
            end

          when /^(#{__strval_optkeys.join('|')})$/
            # conf = tk_split_simplelist(_fromUTF8(tk_call_without_enc(*(__confinfo_cmd << "-#{slot}"))))
            conf = tk_split_simplelist(tk_call_without_enc(*(__confinfo_cmd << "-#{slot}")), false, true)
          else
            # conf = tk_split_list(_fromUTF8(tk_call_without_enc(*(__confinfo_cmd << "-#{slot}"))))
            conf = tk_split_list(tk_call_without_enc(*(__confinfo_cmd << "-#{slot}")), 0, false, true)
          end
          conf[__configinfo_struct[:key]] =
            conf[__configinfo_struct[:key]][1..-1]

          if ( __configinfo_struct[:alias] \
              && conf.size == __configinfo_struct[:alias] + 1 )
            if conf[__configinfo_struct[:alias]][0] == ?-
              conf[__configinfo_struct[:alias]] =
                conf[__configinfo_struct[:alias]][1..-1]
            end
            { conf[0] => conf[1] }
          else
            { conf.shift => conf }
          end

        else
          ret = {}
          # tk_split_simplelist(_fromUTF8(tk_call_without_enc(*__confinfo_cmd))).each{|conflist|
          #  conf = tk_split_simplelist(conflist)
          tk_split_simplelist(tk_call_without_enc(*__confinfo_cmd), false, false).each{|conflist|
            conf = tk_split_simplelist(conflist, false, true)
            conf[__configinfo_struct[:key]] =
              conf[__configinfo_struct[:key]][1..-1]

            optkey = conf[__configinfo_struct[:key]]
            case optkey
            when /^(#{__val2ruby_optkeys().keys.join('|')})$/
              method = _symbolkey2str(__val2ruby_optkeys())[optkey]
              if ( __configinfo_struct[:default_value] \
                  && conf[__configinfo_struct[:default_value]] )
                optval = conf[__configinfo_struct[:default_value]]
                begin
                  val = method.call(optval)
                rescue => e
                  warn("Warning:: #{e.message} (when #{method}.call(#{optval.inspect})") if $DEBUG
                  val = optval
                end
                conf[__configinfo_struct[:default_value]] = val
              end
              if ( conf[__configinfo_struct[:current_value]] )
                optval = conf[__configinfo_struct[:current_value]]
                begin
                  val = method.call(optval)
                rescue => e
                  warn("Warning:: #{e.message} (when #{method}.call(#{optval.inspect})") if $DEBUG
                  val = optval
                end
                conf[__configinfo_struct[:current_value]] = val
              end

            when /^(#{__strval_optkeys.join('|')})$/
              # do nothing

            when /^(#{__numval_optkeys.join('|')})$/
              if ( __configinfo_struct[:default_value] \
                  && conf[__configinfo_struct[:default_value]] )
                begin
                  conf[__configinfo_struct[:default_value]] =
                    number(conf[__configinfo_struct[:default_value]])
                rescue
                  conf[__configinfo_struct[:default_value]] = nil
                end
              end
              if ( conf[__configinfo_struct[:current_value]] )
                begin
                  conf[__configinfo_struct[:current_value]] =
                    number(conf[__configinfo_struct[:current_value]])
                rescue
                  conf[__configinfo_struct[:current_value]] = nil
                end
              end

            when /^(#{__numstrval_optkeys.join('|')})$/
              if ( __configinfo_struct[:default_value] \
                  && conf[__configinfo_struct[:default_value]] )
                conf[__configinfo_struct[:default_value]] =
                  num_or_str(conf[__configinfo_struct[:default_value]])
              end
              if ( conf[__configinfo_struct[:current_value]] )
                conf[__configinfo_struct[:current_value]] =
                  num_or_str(conf[__configinfo_struct[:current_value]])
              end

            when /^(#{__boolval_optkeys.join('|')})$/
              if ( __configinfo_struct[:default_value] \
                  && conf[__configinfo_struct[:default_value]] )
                begin
                  conf[__configinfo_struct[:default_value]] =
                    bool(conf[__configinfo_struct[:default_value]])
                rescue
                  conf[__configinfo_struct[:default_value]] = nil
                end
              end
              if ( conf[__configinfo_struct[:current_value]] )
                begin
                  conf[__configinfo_struct[:current_value]] =
                    bool(conf[__configinfo_struct[:current_value]])
                rescue
                  conf[__configinfo_struct[:current_value]] = nil
                end
              end

            when /^(#{__listval_optkeys.join('|')})$/
              if ( __configinfo_struct[:default_value] \
                  && conf[__configinfo_struct[:default_value]] )
                conf[__configinfo_struct[:default_value]] =
                  simplelist(conf[__configinfo_struct[:default_value]])
              end
              if ( conf[__configinfo_struct[:current_value]] )
                conf[__configinfo_struct[:current_value]] =
                  simplelist(conf[__configinfo_struct[:current_value]])
              end

            when /^(#{__numlistval_optkeys.join('|')})$/
              if ( __configinfo_struct[:default_value] \
                  && conf[__configinfo_struct[:default_value]] \
                  && conf[__configinfo_struct[:default_value]] =~ /^[0-9]/ )
                conf[__configinfo_struct[:default_value]] =
                  list(conf[__configinfo_struct[:default_value]])
              end
              if ( conf[__configinfo_struct[:current_value]] \
                  && conf[__configinfo_struct[:current_value]] =~ /^[0-9]/ )
                conf[__configinfo_struct[:current_value]] =
                  list(conf[__configinfo_struct[:current_value]])
              end

            when /^(#{__tkvariable_optkeys.join('|')})$/
              if ( __configinfo_struct[:default_value] \
                  && conf[__configinfo_struct[:default_value]] )
                v = conf[__configinfo_struct[:default_value]]
                if v.empty?
                  conf[__configinfo_struct[:default_value]] = nil
                else
                  conf[__configinfo_struct[:default_value]] = TkVarAccess.new
                end
              end
              if ( conf[__configinfo_struct[:current_value]] )
                v = conf[__configinfo_struct[:current_value]]
                if v.empty?
                  conf[__configinfo_struct[:current_value]] = nil
                else
                  conf[__configinfo_struct[:current_value]] = TkVarAccess.new
                end
              end

            else
              if ( __configinfo_struct[:default_value] \
                  && conf[__configinfo_struct[:default_value]] )
                if conf[__configinfo_struct[:default_value]].index('{')
                  conf[__configinfo_struct[:default_value]] =
                    tk_split_list(conf[__configinfo_struct[:default_value]])
                else
                  conf[__configinfo_struct[:default_value]] =
                    tk_tcl2ruby(conf[__configinfo_struct[:default_value]])
                end
              end
              if conf[__configinfo_struct[:current_value]]
                if conf[__configinfo_struct[:current_value]].index('{')
                  conf[__configinfo_struct[:current_value]] =
                    tk_split_list(conf[__configinfo_struct[:current_value]])
                else
                  conf[__configinfo_struct[:current_value]] =
                    tk_tcl2ruby(conf[__configinfo_struct[:current_value]])
                end
              end
            end

            if ( __configinfo_struct[:alias] \
                && conf.size == __configinfo_struct[:alias] + 1 )
              if conf[__configinfo_struct[:alias]][0] == ?-
                conf[__configinfo_struct[:alias]] =
                  conf[__configinfo_struct[:alias]][1..-1]
              end
              ret[conf[0]] = conf[1]
            else
              ret[conf.shift] = conf
            end
          }

          __font_optkeys.each{|optkey|
            optkey = optkey.to_s
            fontconf = ret[optkey]
            if fontconf.kind_of?(Array)
              ret.delete(optkey)
              ret.delete('latin' << optkey)
              ret.delete('ascii' << optkey)
              ret.delete('kanji' << optkey)
              fnt = fontconf[__configinfo_struct[:default_value]]
              if TkFont.is_system_font?(fnt)
                fontconf[__configinfo_struct[:default_value]] \
                  = TkNamedFont.new(fnt)
              end
              fontconf[__configinfo_struct[:current_value]] = fontobj(optkey)
              ret[optkey] = fontconf
            end
          }

          __methodcall_optkeys.each{|optkey, m|
            ret[optkey.to_s] = ['', '', '', self.__send__(m)]
          }

          ret
        end
      end
    end
  end
  private :__configinfo_core

  def configinfo(slot = nil)
    if slot && TkConfigMethod.__IGNORE_UNKNOWN_CONFIGURE_OPTION__
      begin
        __configinfo_core(slot)
      rescue
        Array.new(__configinfo_struct.values.max).unshift(slot.to_s)
      end
    else
      __configinfo_core(slot)
    end
  end

  def current_configinfo(slot = nil)
    if TkComm::GET_CONFIGINFO_AS_ARRAY
      if slot
        org_slot = slot
        begin
          conf = configinfo(slot)
          if ( ! __configinfo_struct[:alias] \
              || conf.size > __configinfo_struct[:alias] + 1 )
            return {conf[0] => conf[-1]}
          end
          slot = conf[__configinfo_struct[:alias]]
        end while(org_slot != slot)
        fail RuntimeError,
          "there is a configure alias loop about '#{org_slot}'"
      else
        ret = {}
        configinfo().each{|cnf|
          if ( ! __configinfo_struct[:alias] \
              || cnf.size > __configinfo_struct[:alias] + 1 )
            ret[cnf[0]] = cnf[-1]
          end
        }
        ret
      end
    else # ! TkComm::GET_CONFIGINFO_AS_ARRAY
      ret = {}
      configinfo(slot).each{|key, cnf|
        ret[key] = cnf[-1] if cnf.kind_of?(Array)
      }
      ret
    end
  end
end

class TkObject<TkKernel
  extend  TkCore
  include Tk
  include TkConfigMethod
  include TkBindCore

  # Returns the Tk widget path (e.g., ".frame1.button2")
  # Used by Tcl/Tk commands to identify this widget
  def path
    @path
  end

  # Escaped path - currently same as path
  # Historical: was used for paths needing escape sequences
  def epath
    @path
  end

  def to_eval
    @path
  end

  def tk_send(cmd, *rest)
    tk_call(path, cmd, *rest)
  end
  def tk_send_without_enc(cmd, *rest)
    tk_call_without_enc(path, cmd, *rest)
  end
  def tk_send_with_enc(cmd, *rest)
    tk_call_with_enc(path, cmd, *rest)
  end
  # private :tk_send, :tk_send_without_enc, :tk_send_with_enc

  def tk_send_to_list(cmd, *rest)
    tk_call_to_list(path, cmd, *rest)
  end
  def tk_send_to_list_without_enc(cmd, *rest)
    tk_call_to_list_without_enc(path, cmd, *rest)
  end
  def tk_send_to_list_with_enc(cmd, *rest)
    tk_call_to_list_with_enc(path, cmd, *rest)
  end
  def tk_send_to_simplelist(cmd, *rest)
    tk_call_to_simplelist(path, cmd, *rest)
  end
  def tk_send_to_simplelist_without_enc(cmd, *rest)
    tk_call_to_simplelist_without_enc(path, cmd, *rest)
  end
  def tk_send_to_simplelist_with_enc(cmd, *rest)
    tk_call_to_simplelist_with_enc(path, cmd, *rest)
  end

  def method_missing(id, *args)
    name = id.id2name
    case args.length
    when 1
      if name[-1] == ?=
        configure name[0..-2], args[0]
        args[0]
      else
        configure name, args[0]
        self
      end
    when 0
      begin
        cget(name)
      rescue
        if self.kind_of?(TkWindow) && name != "to_ary" && name != "to_str"
          fail NameError,
               "unknown option '#{id}' for #{self.inspect} (deleted widget?)"
        else
          super(id, *args)
        end
#        fail NameError,
#             "undefined local variable or method `#{name}' for #{self.to_s}",
#             error_at
      end
    else
      super(id, *args)
#      fail NameError, "undefined method `#{name}' for #{self.to_s}", error_at
    end
  end

  def event_generate(context, keys=nil)
    if context.kind_of?(TkEvent::Event)
      context.generate(self, ((keys)? keys: {}))
    elsif keys
      #tk_call('event', 'generate', path,
      #       "<#{tk_event_sequence(context)}>", *hash_kv(keys))
      tk_call_without_enc('event', 'generate', path,
                          "<#{tk_event_sequence(context)}>",
                          *hash_kv(keys, true))
    else
      #tk_call('event', 'generate', path, "<#{tk_event_sequence(context)}>")
      tk_call_without_enc('event', 'generate', path,
                          "<#{tk_event_sequence(context)}>")
    end
  end

  def tk_trace_variable(v)
    #unless v.kind_of?(TkVariable)
    #  fail(ArgumentError, "type error (#{v.class}); must be TkVariable object")
    #end
    v
  end
  private :tk_trace_variable

  def destroy
    #tk_call 'trace', 'vdelete', @tk_vn, 'w', @var_id if @var_id
  end
end


class TkWindow<TkObject
  include TkWinfo
  extend TkBindCore
  include Tk::Wm_for_General
  include Tk::Busy

  @@WIDGET_INSPECT_FULL = false
  def TkWindow._widget_inspect_full_?
    @@WIDGET_INSPECT_FULL
  end
  def TkWindow._widget_inspect_full_=(mode)
    @@WIDGET_INSPECT_FULL = (mode && true) || false
  end

  TkCommandNames = [].freeze
  ## ==> If TkCommandNames[0] is a string (not a null string),
  ##     assume the string is a Tcl/Tk's create command of the widget class.
  WidgetClassName = ''.freeze
  # WidgetClassNames[WidgetClassName] = self
  ## ==> If self is a widget class, entry to the WidgetClassNames table.
  def self.to_eval
    self::WidgetClassName
  end

  def initialize(parent=nil, keys=nil)
    if parent.kind_of? Hash
      keys = _symbolkey2str(parent)
      parent = keys.delete('parent')
      widgetname = keys.delete('widgetname')
      install_win(if parent then parent.path end, widgetname)
      without_creating = keys.delete('without_creating')
      # if without_creating && !widgetname
      #   fail ArgumentError,
      #        "if set 'without_creating' to true, need to define 'widgetname'"
      # end
    elsif keys
      keys = _symbolkey2str(keys)
      widgetname = keys.delete('widgetname')
      install_win(if parent then parent.path end, widgetname)
      without_creating = keys.delete('without_creating')
      # if without_creating && !widgetname
      #   fail ArgumentError,
      #        "if set 'without_creating' to true, need to define 'widgetname'"
      # end
    else
      install_win(if parent then parent.path end)
    end
    if self.method(:create_self).arity == 0
      p 'create_self has no arg' if $DEBUG
      create_self unless without_creating
      if keys
        # tk_call @path, 'configure', *hash_kv(keys)
        configure(keys)
      end
    else
      p 'create_self has args' if $DEBUG
      fontkeys = {}
      methodkeys = {}
      if keys
        #['font', 'kanjifont', 'latinfont', 'asciifont'].each{|key|
        #  fontkeys[key] = keys.delete(key) if keys.key?(key)
        #}
        __font_optkeys.each{|key|
          fkey = key.to_s
          fontkeys[fkey] = keys.delete(fkey) if keys.key?(fkey)

          fkey = "kanji#{key}"
          fontkeys[fkey] = keys.delete(fkey) if keys.key?(fkey)

          fkey = "latin#{key}"
          fontkeys[fkey] = keys.delete(fkey) if keys.key?(fkey)

          fkey = "ascii#{key}"
          fontkeys[fkey] = keys.delete(fkey) if keys.key?(fkey)
        }

        __optkey_aliases.each{|alias_name, real_name|
          alias_name = alias_name.to_s
          if keys.has_key?(alias_name)
            keys[real_name.to_s] = keys.delete(alias_name)
          end
        }

        __methodcall_optkeys.each{|key|
          key = key.to_s
          methodkeys[key] = keys.delete(key) if keys.key?(key)
        }

        __ruby2val_optkeys.each{|key, method|
          key = key.to_s
          keys[key] = method.call(keys[key]) if keys.has_key?(key)
        }
      end
      if without_creating && keys
        #configure(keys)
        configure(__conv_keyonly_opts(keys))
      else
        #create_self(keys)
        create_self(__conv_keyonly_opts(keys))
      end
      font_configure(fontkeys) unless fontkeys.empty?
      configure(methodkeys) unless methodkeys.empty?
    end
  end

  def create_self(keys)
    # may need to override
    begin
      cmd = self.class::TkCommandNames[0]
      fail unless (cmd.kind_of?(String) && cmd.length > 0)
    rescue
      fail RuntimeError, "class #{self.class} may be an abstract class"
    end

    if keys and keys != None
      unless TkConfigMethod.__IGNORE_UNKNOWN_CONFIGURE_OPTION__
        tk_call_without_enc(cmd, @path, *hash_kv(keys, true))
      else
        begin
          tk_call_without_enc(cmd, @path, *hash_kv(keys, true))
        rescue => e
          tk_call_without_enc(cmd, @path)
          keys = __check_available_configure_options(keys)
          unless keys.empty?
            begin
              # try to configure
              configure(keys)
            rescue
              # fail => includes options adaptable when creation only?
              begin
                tk_call_without_enc('destroy', @path)
              rescue
                # cannot rescue options error
                fail e
              else
                # re-create widget
                tk_call_without_enc(cmd, @path, *hash_kv(keys, true))
              end
            end
          end
        end
      end
    else
      tk_call_without_enc(cmd, @path)
    end
  end
  private :create_self

  def inspect
    if @@WIDGET_INSPECT_FULL
      super
    else
      str = super
      str[0..(str.index(' '))] << '@path=' << @path.inspect << '>'
    end
  end

  def exist?
    TkWinfo.exist?(self)
  end

  alias subcommand tk_send

  def bind_class
    @db_class || self.class()
  end

  def database_classname
    TkWinfo.classname(self)
  end
  def database_class
    name = database_classname()
    if WidgetClassNames[name]
      WidgetClassNames[name]
    else
      TkDatabaseClass.new(name)
    end
  end
  def self.database_classname
    self::WidgetClassName
  end
  def self.database_class
    WidgetClassNames[self::WidgetClassName]
  end

  def pack(keys = nil)
    #tk_call_without_enc('pack', epath, *hash_kv(keys, true))
    if keys
      TkPack.configure(self, keys)
    else
      TkPack.configure(self)
    end
    self
  end

  def pack_in(target, keys = nil)
    if keys
      keys = keys.dup
      keys['in'] = target
    else
      keys = {'in'=>target}
    end
    #tk_call 'pack', epath, *hash_kv(keys)
    TkPack.configure(self, keys)
    self
  end

  def pack_forget
    #tk_call_without_enc('pack', 'forget', epath)
    TkPack.forget(self)
    self
  end
  alias unpack pack_forget

  def pack_config(slot, value=None)
    #if slot.kind_of? Hash
    #  tk_call 'pack', 'configure', epath, *hash_kv(slot)
    #else
    #  tk_call 'pack', 'configure', epath, "-#{slot}", value
    #end
    if slot.kind_of? Hash
      TkPack.configure(self, slot)
    else
      TkPack.configure(self, slot=>value)
    end
  end
  alias pack_configure pack_config

  def pack_info()
    #ilist = list(tk_call('pack', 'info', epath))
    #info = {}
    #while key = ilist.shift
    #  info[key[1..-1]] = ilist.shift
    #end
    #return info
    TkPack.info(self)
  end

  def pack_propagate(mode=None)
    #if mode == None
    #  bool(tk_call('pack', 'propagate', epath))
    #else
    #  tk_call('pack', 'propagate', epath, mode)
    #  self
    #end
    if mode == None
      TkPack.propagate(self)
    else
      TkPack.propagate(self, mode)
      self
    end
  end

  def pack_slaves()
    #list(tk_call('pack', 'slaves', epath))
    TkPack.slaves(self)
  end

  def grid(keys = nil)
    #tk_call 'grid', epath, *hash_kv(keys)
    if keys
      TkGrid.configure(self, keys)
    else
      TkGrid.configure(self)
    end
    self
  end

  def grid_in(target, keys = nil)
    if keys
      keys = keys.dup
      keys['in'] = target
    else
      keys = {'in'=>target}
    end
    #tk_call 'grid', epath, *hash_kv(keys)
    TkGrid.configure(self, keys)
    self
  end

  def grid_anchor(anchor=None)
    if anchor == None
      TkGrid.anchor(self)
    else
      TkGrid.anchor(self, anchor)
      self
    end
  end

  def grid_forget
    #tk_call('grid', 'forget', epath)
    TkGrid.forget(self)
    self
  end
  alias ungrid grid_forget

  def grid_bbox(*args)
    #list(tk_call('grid', 'bbox', epath, *args))
    TkGrid.bbox(self, *args)
  end

  def grid_config(slot, value=None)
    #if slot.kind_of? Hash
    #  tk_call 'grid', 'configure', epath, *hash_kv(slot)
    #else
    #  tk_call 'grid', 'configure', epath, "-#{slot}", value
    #end
    if slot.kind_of? Hash
      TkGrid.configure(self, slot)
    else
      TkGrid.configure(self, slot=>value)
    end
  end
  alias grid_configure grid_config

  def grid_columnconfig(index, keys)
    #tk_call('grid', 'columnconfigure', epath, index, *hash_kv(keys))
    TkGrid.columnconfigure(self, index, keys)
  end
  alias grid_columnconfigure grid_columnconfig

  def grid_rowconfig(index, keys)
    #tk_call('grid', 'rowconfigure', epath, index, *hash_kv(keys))
    TkGrid.rowconfigure(self, index, keys)
  end
  alias grid_rowconfigure grid_rowconfig

  def grid_columnconfiginfo(index, slot=nil)
    #if slot
    #  tk_call('grid', 'columnconfigure', epath, index, "-#{slot}").to_i
    #else
    #  ilist = list(tk_call('grid', 'columnconfigure', epath, index))
    #  info = {}
    #  while key = ilist.shift
    #   info[key[1..-1]] = ilist.shift
    #  end
    #  info
    #end
    TkGrid.columnconfiginfo(self, index, slot)
  end

  def grid_rowconfiginfo(index, slot=nil)
    #if slot
    #  tk_call('grid', 'rowconfigure', epath, index, "-#{slot}").to_i
    #else
    #  ilist = list(tk_call('grid', 'rowconfigure', epath, index))
    #  info = {}
    #  while key = ilist.shift
    #   info[key[1..-1]] = ilist.shift
    #  end
    #  info
    #end
    TkGrid.rowconfiginfo(self, index, slot)
  end

  def grid_column(index, keys=nil)
    if keys.kind_of?(Hash)
      grid_columnconfigure(index, keys)
    else
      grid_columnconfiginfo(index, keys)
    end
  end

  def grid_row(index, keys=nil)
    if keys.kind_of?(Hash)
      grid_rowconfigure(index, keys)
    else
      grid_rowconfiginfo(index, keys)
    end
  end

  def grid_info()
    #list(tk_call('grid', 'info', epath))
    TkGrid.info(self)
  end

  def grid_location(x, y)
    #list(tk_call('grid', 'location', epath, x, y))
    TkGrid.location(self, x, y)
  end

  def grid_propagate(mode=None)
    #if mode == None
    #  bool(tk_call('grid', 'propagate', epath))
    #else
    #  tk_call('grid', 'propagate', epath, mode)
    #  self
    #end
    if mode == None
      TkGrid.propagate(self)
    else
      TkGrid.propagate(self, mode)
      self
    end
  end

  def grid_remove()
    #tk_call 'grid', 'remove', epath
    TkGrid.remove(self)
    self
  end

  def grid_size()
    #list(tk_call('grid', 'size', epath))
    TkGrid.size(self)
  end

  def grid_slaves(keys = nil)
    #list(tk_call('grid', 'slaves', epath, *hash_kv(args)))
    TkGrid.slaves(self, keys)
  end

  def place(keys)
    #tk_call 'place', epath, *hash_kv(keys)
    TkPlace.configure(self, keys)
    self
  end

  def place_in(target, keys = nil)
    if keys
      keys = keys.dup
      keys['in'] = target
    else
      keys = {'in'=>target}
    end
    #tk_call 'place', epath, *hash_kv(keys)
    TkPlace.configure(self, keys)
    self
  end

  def  place_forget
    #tk_call 'place', 'forget', epath
    TkPlace.forget(self)
    self
  end
  alias unplace place_forget

  def place_config(slot, value=None)
    #if slot.kind_of? Hash
    #  tk_call 'place', 'configure', epath, *hash_kv(slot)
    #else
    #  tk_call 'place', 'configure', epath, "-#{slot}", value
    #end
    TkPlace.configure(self, slot, value)
  end
  alias place_configure place_config

  def place_configinfo(slot = nil)
    # for >= Tk8.4a2 ?
    #if slot
    #  conf = tk_split_list(tk_call('place', 'configure', epath, "-#{slot}") )
    #  conf[0] = conf[0][1..-1]
    #  conf
    #else
    #  tk_split_simplelist(tk_call('place',
    #                             'configure', epath)).collect{|conflist|
    #   conf = tk_split_simplelist(conflist)
    #   conf[0] = conf[0][1..-1]
    #   conf
    #  }
    #end
    TkPlace.configinfo(self, slot)
  end

  def place_info()
    #ilist = list(tk_call('place', 'info', epath))
    #info = {}
    #while key = ilist.shift
    #  info[key[1..-1]] = ilist.shift
    #end
    #return info
    TkPlace.info(self)
  end

  def place_slaves()
    #list(tk_call('place', 'slaves', epath))
    TkPlace.slaves(self)
  end

  def set_focus(force=false)
    if force
      tk_call_without_enc('focus', '-force', path)
    else
      tk_call_without_enc('focus', path)
    end
    self
  end
  alias focus set_focus

  def grab(opt = nil)
    unless opt
      tk_call_without_enc('grab', 'set', path)
      return self
    end

    case opt
    when 'set', :set
      tk_call_without_enc('grab', 'set', path)
      return self
    when 'global', :global
      #return(tk_call('grab', 'set', '-global', path))
      tk_call_without_enc('grab', 'set', '-global', path)
      return self
    when 'release', :release
      #return tk_call('grab', 'release', path)
      tk_call_without_enc('grab', 'release', path)
      return self
    when 'current', :current
      return window(tk_call_without_enc('grab', 'current', path))
    when 'status', :status
      return tk_call_without_enc('grab', 'status', path)
    else
      return tk_call_without_enc('grab', opt, path)
    end
  end

  def grab_current
    grab('current')
  end
  alias current_grab grab_current
  def grab_release
    grab('release')
  end
  alias release_grab grab_release
  def grab_set
    grab('set')
  end
  alias set_grab grab_set
  def grab_set_global
    grab('global')
  end
  alias set_global_grab grab_set_global
  def grab_status
    grab('status')
  end

  def lower(below=None)
    # below = below.epath if below.kind_of?(TkObject)
    below = _epath(below)
    tk_call 'lower', epath, below
    self
  end
  alias lower_window lower
  def raise(above=None)
    #above = above.epath if above.kind_of?(TkObject)
    above = _epath(above)
    tk_call 'raise', epath, above
    self
  end
  alias raise_window raise

  def command(cmd=nil, &b)
    if cmd
      configure_cmd('command', cmd)
    elsif b
      configure_cmd('command', b)
    else
      cget('command')
    end
  end

  def colormodel(model=None)
    tk_call('tk', 'colormodel', path, model)
    self
  end

  def caret(keys=nil)
    TkXIM.caret(path, keys)
  end

  def destroy
    super
    children = []
    rexp = /^#{self.path}\.[^.]+$/
    TkCore::INTERP.tk_windows.each{|path, obj|
      children << [path, obj] if path =~ rexp
    }
    if defined?(@cmdtbl)
      for id in @cmdtbl
        uninstall_cmd id
      end
    end

    children.each{|path, obj|
      obj.instance_eval{
        if defined?(@cmdtbl)
          for id in @cmdtbl
            uninstall_cmd id
          end
        end
      }
      TkCore::INTERP.tk_windows.delete(path)
    }

    begin
      tk_call_without_enc('destroy', epath)
    rescue
    end
    uninstall_win
  end

  def wait_visibility(on_thread = true)
    on_thread &= (Thread.list.size != 1)
    if on_thread
      INTERP._thread_tkwait('visibility', path)
    else
      INTERP._invoke('tkwait', 'visibility', path)
    end
  end
  def eventloop_wait_visibility
    wait_visibility(false)
  end
  def thread_wait_visibility
    wait_visibility(true)
  end
  alias wait wait_visibility
  alias tkwait wait_visibility
  alias eventloop_wait eventloop_wait_visibility
  alias eventloop_tkwait eventloop_wait_visibility
  alias eventloop_tkwait_visibility eventloop_wait_visibility
  alias thread_wait thread_wait_visibility
  alias thread_tkwait thread_wait_visibility
  alias thread_tkwait_visibility thread_wait_visibility

  def wait_destroy(on_thread = true)
    on_thread &= (Thread.list.size != 1)
    if on_thread
      INTERP._thread_tkwait('window', epath)
    else
      INTERP._invoke('tkwait', 'window', epath)
    end
  end
  alias wait_window wait_destroy
  def eventloop_wait_destroy
    wait_destroy(false)
  end
  alias eventloop_wait_window eventloop_wait_destroy
  def thread_wait_destroy
    wait_destroy(true)
  end
  alias thread_wait_window thread_wait_destroy

  alias tkwait_destroy wait_destroy
  alias tkwait_window wait_destroy

  alias eventloop_tkwait_destroy eventloop_wait_destroy
  alias eventloop_tkwait_window eventloop_wait_destroy

  alias thread_tkwait_destroy thread_wait_destroy
  alias thread_tkwait_window thread_wait_destroy

  def bindtags(taglist=nil)
    if taglist
      fail ArgumentError, "taglist must be Array" unless taglist.kind_of? Array
      tk_call('bindtags', path, taglist)
      taglist
    else
      list(tk_call('bindtags', path)).collect{|tag|
        if tag.kind_of?(String)
          if cls = WidgetClassNames[tag]
            cls
          elsif btag = TkBindTag.id2obj(tag)
            btag
          else
            tag
          end
        else
          tag
        end
      }
    end
  end

  def bindtags=(taglist)
    bindtags(taglist)
    taglist
  end

  def bindtags_shift
    taglist = bindtags
    tag = taglist.shift
    bindtags(taglist)
    tag
  end

  def bindtags_unshift(tag)
    bindtags(bindtags().unshift(tag))
  end
end
TkWidget = TkWindow

# freeze core modules
#TclTkLib.freeze
#TclTkIp.freeze
#TkUtil.freeze
#TkKernel.freeze
#TkComm.freeze
#TkComm::Event.freeze
#TkCore.freeze
#Tk.freeze

module Tk
  RELEASE_DATE = '2014-10-19'.freeze

  autoload :AUTO_PATH,        'tk/variable'
  autoload :TCL_PACKAGE_PATH, 'tk/variable'
  autoload :PACKAGE_PATH,     'tk/variable'
  autoload :TCL_LIBRARY_PATH, 'tk/variable'
  autoload :LIBRARY_PATH,     'tk/variable'
  autoload :TCL_PRECISION,    'tk/variable'
end

# call setup script for Tk extension libraries (base configuration)
begin
  require 'tkextlib/version.rb'
  require 'tkextlib/setup.rb'
rescue LoadError
  # ignore
end
