# frozen_string_literal: false
#
# tk/root.rb : treat root widget
#
# See: https://www.tcl-lang.org/man/tcl/TkCmd/toplevel.html
#
require 'tk/wm'
require 'tk/menuspec'
require 'tk/option_dsl'

class Tk::Root<TkWindow
  include Wm
  include TkMenuSpec
  include Tk::Generated::Toplevel  # Root shares options with Toplevel

  # Window manager properties - these are NOT real Tcl configure options.
  # They are wm commands that the original ruby-tk exposed via cget/configure.
  # This shim maintains backwards compatibility by routing them to tk_call('wm', ...).
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

  def Root.new(keys=nil, &b)
    unless TkCore::INTERP.tk_windows['.']
      TkCore::INTERP.tk_windows['.'] =
        super(:without_creating=>true, :widgetname=>'.'){}
    end
    root = TkCore::INTERP.tk_windows['.']

    keys = _symbolkey2str(keys)

    # Separate wm properties from real widget options
    wm_cmds = {}
    real_keys = {}
    keys.each do |k, v|
      k_s = k.to_s
      wm_cmd = k_s.sub(/^wm_/, '')
      if WM_PROPERTIES.include?(k_s) || WM_PROPERTIES.include?(wm_cmd)
        wm_cmds[wm_cmd] = v
      else
        real_keys[k] = v
      end
    end if keys

    # Execute wm commands directly
    wm_cmds.each do |k, v|
      if v.kind_of?(Array)
        root.tk_call('wm', k, '.', *v)
      else
        root.tk_call('wm', k, '.', v)
      end
    end

    # Apply real widget options
    root.configure(real_keys) unless real_keys.empty?

    root.instance_exec(root, &b) if block_given?
    root
  end

  WidgetClassName = 'Tk'.freeze
  WidgetClassNames[WidgetClassName] ||= self

  def self.to_eval
    # self::WidgetClassName
    '.'
  end

  def create_self
    @path = '.'
  end
  private :create_self

  def path
    "."
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

  def Root.destroy
    TkCore::INTERP._invoke('destroy', '.')
  end
end

TkRoot = Tk::Root unless Object.const_defined? :TkRoot
