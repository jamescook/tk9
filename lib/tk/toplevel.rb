# frozen_string_literal: false
#
# tk/toplevel.rb : treat toplevel widget
#
# See: https://www.tcl-lang.org/man/tcl/TkCmd/toplevel.html
#
require 'tk/wm'
require 'tk/menuspec'
require 'tk/option_dsl'

class Tk::Toplevel<TkWindow
  include Wm
  include TkMenuSpec
  include Tk::Generated::Toplevel
  # @generated:options:start
  # Available options (auto-generated from Tk introspection):
  #
  #   :background
  #   :backgroundimage
  #   :borderwidth
  #   :class
  #   :colormap
  #   :container
  #   :cursor
  #   :height
  #   :highlightbackground
  #   :highlightcolor
  #   :highlightthickness
  #   :menu
  #   :padx
  #   :pady
  #   :relief
  #   :screen
  #   :takefocus
  #   :tile
  #   :use
  #   :visual
  #   :width
  # @generated:options:end



  TkCommandNames = ['toplevel'.freeze].freeze
  WidgetClassName = 'Toplevel'.freeze
  WidgetClassNames[WidgetClassName] ||= self

  # Window manager properties - these are NOT real Tcl configure options.
  # They are wm commands that the original ruby-tk exposed via cget/configure.
  # This shim maintains backwards compatibility by routing them to tk_call('wm', ...).
  # TODO: Confirm if we have tests around `wm` commands
  WM_PROPERTIES = %w[
    aspect attributes client colormapwindows wm_command focusmodel
    geometry wm_grid group iconbitmap iconphoto iconmask iconname
    iconposition iconwindow maxsize minsize overrideredirect
    positionfrom protocols resizable sizefrom state title transient
  ].freeze

  # Backwards-compat shim: intercept wm properties and route to tk_call('wm', ...)
  def cget(slot)
    slot_s = slot.to_s
    if WM_PROPERTIES.include?(slot_s)
      # Route to wm command directly - no method indirection
      tk_call('wm', slot_s.sub(/^wm_/, ''), path)
    else
      super
    end
  end

  # Backwards-compat shim: intercept wm properties in configinfo
  def configinfo(slot = nil)
    if slot
      slot_s = slot.to_s
      if WM_PROPERTIES.include?(slot_s)
        wm_cmd = slot_s.sub(/^wm_/, '')
        val = tk_call('wm', wm_cmd, path)
        [slot_s, '', '', '', val]
      else
        super
      end
    else
      # Full configinfo - get real options and add wm properties
      result = super
      WM_PROPERTIES.each do |prop|
        begin
          val = tk_call('wm', prop.sub(/^wm_/, ''), path)
          result << [prop, '', '', '', val]
        rescue
          # Some wm commands may not be available, skip them
        end
      end
      result
    end
  end

  # Backwards-compat shim: intercept wm properties and route to tk_call('wm', ...)
  def configure(slot, value = None)
    if slot.is_a?(Hash)
      slot = _symbolkey2str(slot)
      wm_opts, real_opts = slot.partition { |k, _| WM_PROPERTIES.include?(k.to_s) }
      # Handle wm properties directly
      wm_opts.each do |k, v|
        wm_cmd = k.to_s.sub(/^wm_/, '')
        if v.is_a?(Array)
          tk_call('wm', wm_cmd, path, *v)
        else
          tk_call('wm', wm_cmd, path, v)
        end
      end
      # Pass real options to parent
      super(real_opts.to_h) unless real_opts.empty?
      self
    elsif WM_PROPERTIES.include?(slot.to_s)
      wm_cmd = slot.to_s.sub(/^wm_/, '')
      if value.is_a?(Array)
        tk_call('wm', wm_cmd, path, *value)
      else
        tk_call('wm', wm_cmd, path, value)
      end
      self
    else
      super
    end
  end

################# old version
#  def initialize(parent=nil, screen=nil, classname=nil, keys=nil)
#    if screen.kind_of? Hash
#      keys = screen.dup
#    else
#      @screen = screen
#    end
#    @classname = classname
#    if keys.kind_of? Hash
#      keys = keys.dup
#      @classname = keys.delete('classname') if keys.key?('classname')
#      @colormap  = keys.delete('colormap')  if keys.key?('colormap')
#      @container = keys.delete('container') if keys.key?('container')
#      @screen    = keys.delete('screen')    if keys.key?('screen')
#      @use       = keys.delete('use')       if keys.key?('use')
#      @visual    = keys.delete('visual')    if keys.key?('visual')
#    end
#    super(parent, keys)
#  end
#
#  def create_self
#    s = []
#    s << "-class"     << @classname if @classname
#    s << "-colormap"  << @colormap  if @colormap
#    s << "-container" << @container if @container
#    s << "-screen"    << @screen    if @screen
#    s << "-use"       << @use       if @use
#    s << "-visual"    << @visual    if @visual
#    tk_call 'toplevel', @path, *s
#  end
#################

  def _wm_command_option_chk(keys)
    keys = {} unless keys
    new_keys = {}
    wm_cmds = {}

    keys.each do |k, v|
      k_s = k.to_s
      # Normalize wm_ prefix (e.g., wm_command -> command)
      wm_cmd = k_s.sub(/^wm_/, '')
      if WM_PROPERTIES.include?(k_s) || WM_PROPERTIES.include?(wm_cmd)
        wm_cmds[wm_cmd] = v
      else
        new_keys[k] = v
      end
    end
    [new_keys, wm_cmds]
  end
  private :_wm_command_option_chk

  def initialize(parent=nil, screen=nil, classname=nil, keys=nil)
    my_class_name = nil
    if self.class < WidgetClassNames[WidgetClassName]
      my_class_name = self.class.name
      my_class_name = nil if my_class_name == ''
    end
    if parent.kind_of? Hash
      keys = _symbolkey2str(parent)
      if keys.key?('classname')
        keys['class'] = keys.delete('classname')
      end
      @classname = keys['class']
      @colormap  = keys['colormap']
      @container = keys['container']
      @screen    = keys['screen']
      @use       = keys['use']
      @visual    = keys['visual']
      if !@classname && my_class_name
        keys['class'] = @classname = my_class_name
      end
      if @classname.kind_of? TkBindTag
        @db_class = @classname
        keys['class'] = @classname = @classname.id
      elsif @classname
        @db_class = TkDatabaseClass.new(@classname)
        keys['class'] = @classname
      else
        @db_class = self.class
        @classname = @db_class::WidgetClassName
      end
      keys, cmds = _wm_command_option_chk(keys)
      super(keys)
      cmds.each do |k, v|
        if v.kind_of?(Array)
          tk_call('wm', k, path, *v)
        else
          tk_call('wm', k, path, v)
        end
      end
      return
    end

    if screen.kind_of? Hash
      keys = screen
    else
      @screen = screen
      if classname.kind_of? Hash
        keys = classname
      else
        @classname = classname
      end
    end
    if keys.kind_of? Hash
      keys = _symbolkey2str(keys)
      if keys.key?('classname')
        keys['class'] = keys.delete('classname')
      end
      @classname = keys['class']  unless @classname
      @colormap  = keys['colormap']
      @container = keys['container']
      @screen    = keys['screen'] unless @screen
      @use       = keys['use']
      @visual    = keys['visual']
    else
      keys = {}
    end
    if !@classname && my_class_name
      keys['class'] = @classname = my_class_name
    end
    if @classname.kind_of? TkBindTag
      @db_class = @classname
      keys['class'] = @classname = @classname.id
    elsif @classname
      @db_class = TkDatabaseClass.new(@classname)
      keys['class'] = @classname
    else
      @db_class = self.class
      @classname = @db_class::WidgetClassName
    end
    keys, cmds = _wm_command_option_chk(keys)
    super(parent, keys)
    cmds.each do |k, v|
      if v.kind_of?(Array)
        tk_call('wm', k, path, *v)
      else
        tk_call('wm', k, path, v)
      end
    end
  end

  #def create_self(keys)
  #  if keys and keys != None
  #    tk_call_without_enc('toplevel', @path, *hash_kv(keys, true))
  #  else
  #    tk_call_without_enc('toplevel', @path)
  #  end
  #end
  #private :create_self

  def specific_class
    @classname
  end

  def add_menu(menu_info, tearoff=false, opts=nil)
    # See tk/menuspec.rb for menu_info.
    # opts is a hash of default configs for all of cascade menus.
    # Configs of menu_info can override it.
    if tearoff.kind_of?(Hash)
      opts = tearoff
      tearoff = false
    end
    _create_menubutton(self, menu_info, tearoff, opts)
  end

  def add_menubar(menu_spec, tearoff=false, opts=nil)
    # See tk/menuspec.rb for menu_spec.
    # opts is a hash of default configs for all of cascade menus.
    # Configs of menu_spec can override it.
    menu_spec.each{|info| add_menu(info, tearoff, opts)}
    self.menu
  end

  def self.database_class
    if self == WidgetClassNames[WidgetClassName] || self.name == ''
      self
    else
      TkDatabaseClass.new(self.name)
    end
  end
  def self.database_classname
    self.database_class.name
  end

  def self.bind(*args, &b)
    if self == WidgetClassNames[WidgetClassName] || self.name == ''
      super(*args, &b)
    else
      TkDatabaseClass.new(self.name).bind(*args, &b)
    end
  end
  def self.bind_append(*args, &b)
    if self == WidgetClassNames[WidgetClassName] || self.name == ''
      super(*args, &b)
    else
      TkDatabaseClass.new(self.name).bind_append(*args, &b)
    end
  end
  def self.bind_remove(*args)
    if self == WidgetClassNames[WidgetClassName] || self.name == ''
      super(*args)
    else
      TkDatabaseClass.new(self.name).bind_remove(*args)
    end
  end
  def self.bindinfo(*args)
    if self == WidgetClassNames[WidgetClassName] || self.name == ''
      super(*args)
    else
      TkDatabaseClass.new(self.name).bindinfo(*args)
    end
  end
end

#TkToplevel = Tk::Toplevel unless Object.const_defined? :TkToplevel
#Tk.__set_toplevel_aliases__(:Tk, Tk::Toplevel, :TkToplevel)
Tk.__set_loaded_toplevel_aliases__('tk/toplevel.rb', :Tk, Tk::Toplevel,
                                   :TkToplevel)
