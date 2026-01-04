# frozen_string_literal: true

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
      TkCore::INTERP._thread_tkwait('visibility', path)
    else
      TkCore::INTERP._invoke('tkwait', 'visibility', path)
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
      TkCore::INTERP._thread_tkwait('window', epath)
    else
      TkCore::INTERP._invoke('tkwait', 'window', epath)
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
