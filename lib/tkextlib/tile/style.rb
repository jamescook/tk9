# frozen_string_literal: false
#
#  style commands
#                               by Hidetoshi NAGAI (nagai@ai.kyutech.ac.jp)
#
# Ttk Style System
# ================
# Wraps the ttk::style command for themed widget styling.
#
# History:
#   - Tile 0.x was a standalone extension for Tcl/Tk 8.4
#   - Tile was integrated into Tk 8.5 as Ttk (TIP 248, October 2006)
#   - Tk 8.5+ bundles Ttk 8.5.0+ as a core package
#
# Since we require Tcl/Tk 8.6+, TILE_SPEC_VERSION_ID is always 8.
#
# Sources:
#   - TIP 248: https://core.tcl-lang.org/tips/doc/trunk/tip/248.md
#   - Tk 8.5 Changes: https://wiki.tcl-lang.org/page/Changes+in+Tcl/Tk+8.5
#   - Tile Wiki: https://wiki.tcl-lang.org/page/Tile
#   - ttk::style manual: https://www.tcl-lang.org/man/tcl/TkCmd/ttk_style.html
#
require 'tk'
require 'tkextlib/tile.rb'

module Tk
  module Tile
    module Style
    end
  end
end

module Tk::Tile::Style
  extend TkCore
end

class << Tk::Tile::Style
  TkCommandNames = ['::ttk::style'.freeze].freeze

  # Define compatibility wrapper for old Tile 0.x style command format.
  # This allows scripts written for older Tile versions to work with Ttk.
  def __define_wrapper_proc_for_compatibility__!
    __define_themes_and_setTheme_proc__!

    unless Tk.info(:commands, '::style').empty?
      warn "Warning: can't define '::style' command (already exist)" if $DEBUG
      return
    end
    TkCore::INTERP.add_tk_procs('::style', 'args', <<-'EOS')
      if [string equal [lrange $args 0 1] {element create}] {
        if [string equal [lindex $args 3] image] {
          set name [lindex $args 4]
          set opts [lrange $args 5 end]
          set idx [lsearch $opts -map]
          if {$idx >= 0 && [expr $idx % 2 == 0]} {
            return [uplevel 1 [list ::ttk::style element create [lindex $args 2] image [concat $name [lindex $opts [expr $idx + 1]]]] [lreplace $opts $idx [expr $idx + 1]]]
          }
        }
      } elseif [string equal [lindex $args 0] default] {
        return [uplevel 1 ::ttk::style [lreplace $args 0 0 configure]]
      }
      return [uplevel 1 ::ttk::style $args]
    EOS
  end

  def __define_themes_and_setTheme_proc__!
    TkCore::INTERP.add_tk_procs('::ttk::themes', '{ptn *}', <<-'EOS')
      set themes [::ttk::style theme names]
      foreach pkg [lsearch -inline -all -glob [package names] ttk::theme::$ptn] {
          set theme [namespace tail $pkg]
          if {[lsearch -exact $themes $theme] < 0} {
              lappend themes $theme
          }
      }
      foreach pkg [lsearch -inline -all -glob [package names] tile::theme::$ptn] {
          set theme [namespace tail $pkg]
          if {[lsearch -exact $themes $theme] < 0} {
              lappend themes $theme
          }
      }
      return $themes
    EOS
    TkCore::INTERP.add_tk_procs('::ttk::setTheme', 'theme', <<-'EOS')
      variable currentTheme
      if {[lsearch -exact [::ttk::style theme names] $theme] < 0} {
          package require [lsearch -inline -regexp [package names] (ttk|tile)::theme::$theme]
      }
      ::ttk::style theme use $theme
      set currentTheme $theme
    EOS
  end
  private :__define_themes_and_setTheme_proc__!

  def configure(style=nil, keys=nil)
    if style.kind_of?(Hash)
      keys = style
      style = nil
    end
    style = '.' unless style

    if keys && keys != None
      tk_call(TkCommandNames[0], 'configure', style, *hash_kv(keys))
    else
      tk_call(TkCommandNames[0], 'configure', style)
    end
  end
  alias default configure

  def map(style=nil, keys=nil)
    if style.kind_of?(Hash)
      keys = style
      style = nil
    end
    style = '.' unless style

    if keys && keys != None
      if keys.kind_of?(Hash)
        tk_call(TkCommandNames[0], 'map', style, *hash_kv(keys))
      else
        simplelist(tk_call(TkCommandNames[0], 'map', style, '-' << keys.to_s))
      end
    else
      ret = {}
      Hash[*(simplelist(tk_call(TkCommandNames[0], 'map', style)))].each{|k, v|
        ret[k[1..-1]] = list(v)
      }
      ret
    end
  end
  alias map_configure map

  def map_configinfo(style=nil, key=None)
    style = '.' unless style
    map(style, key)
  end

  def map_default_configinfo(key=None)
    map('.', key)
  end

  def lookup(style, opt, state=None, fallback_value=None)
    tk_call(TkCommandNames[0], 'lookup', style,
            '-' << opt.to_s, state, fallback_value)
  end

  include Tk::Tile::ParseStyleLayout

  def layout(style=nil, spec=nil)
    if style.kind_of?(Hash)
      spec = style
      style = nil
    end
    style = '.' unless style

    if spec
      tk_call(TkCommandNames[0], 'layout', style, spec)
    else
      _style_layout(list(tk_call(TkCommandNames[0], 'layout', style)))
    end
  end

  def element_create(name, type, *args)
    if type == 'image' || type == :image
      element_create_image(name, *args)
    elsif type == 'vsapi' || type == :vsapi
      element_create_vsapi(name, *args)
    else
      tk_call(TkCommandNames[0], 'element', 'create', name, type, *args)
    end
  end

  def element_create_image(name, *args)
    fail ArgumentError, 'Must supply a base image' unless (spec = args.shift)
    if (opts = args.shift)
      if opts.kind_of?(Hash)
        opts = _symbolkey2str(opts)
      else
        fail ArgumentError, 'bad option'
      end
    end
    fail ArgumentError, 'too many arguments' unless args.empty?

    if spec.kind_of?(Array)
      # Tk 8.5+ array format: [base_image, state1, img1, state2, img2, ...]
      if opts
        tk_call(TkCommandNames[0],
                'element', 'create', name, 'image', spec, opts)
      else
        tk_call(TkCommandNames[0], 'element', 'create', name, 'image', spec)
      end
    else
      # Single image with optional -map option
      spec = [spec, *(opts.delete('map'))] if opts && opts.key?('map')
      if opts
        tk_call(TkCommandNames[0],
                'element', 'create', name, 'image', spec, opts)
      else
        tk_call(TkCommandNames[0], 'element', 'create', name, 'image', spec)
      end
    end
  end

  def element_create_vsapi(name, class_name, part_id, *args)
    # Windows Visual Styles API element (Tcl/Tk 8.6+)
    if (state_map = args.shift || None)
      if state_map.kind_of?(Hash)
        opts = _symbolkey2str(state_map)
        state_map = None
      end
    end
    opts = args.shift || None
    fail ArgumentError, "too many arguments" unless args.empty?

    tk_call(TkCommandNames[0], 'element', 'create', name, 'vsapi',
            class_name, part_id, state_map, opts)
  end

  def element_names()
    list(tk_call(TkCommandNames[0], 'element', 'names'))
  end

  def element_options(elem)
    simplelist(tk_call(TkCommandNames[0], 'element', 'options', elem))
  end

  def theme_create(name, keys=nil)
    name = name.to_s
    if keys && keys != None
      tk_call(TkCommandNames[0], 'theme', 'create', name, *hash_kv(keys))
    else
      tk_call(TkCommandNames[0], 'theme', 'create', name)
    end
    name
  end

  def theme_settings(name, cmd=nil, &b)
    name = name.to_s
    cmd = b if !cmd && b
    tk_call(TkCommandNames[0], 'theme', 'settings', name, cmd)
    name
  end

  def theme_names()
    list(tk_call(TkCommandNames[0], 'theme', 'names'))
  end

  def theme_use(name)
    name = name.to_s
    tk_call(TkCommandNames[0], 'theme', 'use', name)
    name
  end
end
