# frozen_string_literal: false
#
#  Tile theme engine (tile widget set) support
#                               by Hidetoshi NAGAI (nagai@ai.kyutech.ac.jp)
#

require 'tk'
require 'tk/ttk_selector'

# call setup script for general 'tkextlib' libraries
require 'tkextlib/setup.rb'

# library directory
require 'tkextlib/tile/setup.rb'

# Ttk is built into Tcl/Tk 8.5+ (we require 8.6+)
TkPackage.require('Ttk')

module Tk
  module Tile
    USE_TILE_NAMESPACE = false
    USE_TTK_NAMESPACE  = true
    TILE_SPEC_VERSION_ID = 8
    PACKAGE_NAME = 'Ttk'.freeze
  end
end

# autoload
module Tk
  module Tile
    TkComm::TkExtlibAutoloadModule.unshift(self)

    def self.package_name
      PACKAGE_NAME
    end

    def self.package_version
      begin
        TkPackage.require(PACKAGE_NAME)
      rescue
        ''
      end
    end

    def self.__Import_Tile_Widgets__!
      Tk::Warnings.warn_once(:tile_import_obsolete,
        '"Tk::Tile::__Import_Tile_Widgets__!" is obsolete. ' \
        'To control default widget set, use "Tk.default_widget_set = :Ttk"')
      Tk.tk_call('namespace', 'import', '-force', 'ttk::*')
    end

    # Define LoadImages proc in Tcl namespace for old Tcl/Tk scripts
    def self.__define_LoadImages_proc_for_compatibility__!
      tcl_script = <<-'TCL'
        namespace eval ::tile {
          if {[info commands ::tile::LoadImages] eq ""} {
            proc LoadImages {imgdir {patterns {*.gif}}} {
              foreach pattern $patterns {
                foreach file [glob -directory $imgdir $pattern] {
                  set img [file tail [file rootname $file]]
                  if {![info exists images($img)]} {
                    set images($img) [image create photo -file $file]
                  }
                }
              }
              return [array get images]
            }
          }
        }
        namespace eval ::ttk {
          if {[info commands ::ttk::LoadImages] eq ""} {
            proc LoadImages {imgdir {patterns {*.gif}}} {
              foreach pattern $patterns {
                foreach file [glob -directory $imgdir $pattern] {
                  set img [file tail [file rootname $file]]
                  if {![info exists images($img)]} {
                    set images($img) [image create photo -file $file]
                  }
                }
              }
              return [array get images]
            }
          }
        }
      TCL
      Tk.tk_call('eval', tcl_script)
    end

    def self.load_images(imgdir, pat=nil)
      pat ||= '*.gif'
      pat_list = pat.kind_of?(Array) ? pat : [pat]

      Dir.chdir(imgdir) {
        pat_list.each { |pattern|
          Dir.glob(pattern).each { |f|
            img = File.basename(f, '.*')
            unless TkComm.bool(Tk.info('exists', "images(#{img})"))
              Tk.tk_call('set', "images(#{img})",
                         Tk.tk_call('image', 'create', 'photo', '-file', f))
            end
          }
        }
      }

      images = Hash[*TkComm.simplelist(Tk.tk_call('array', 'get', 'images'))]
      images.keys.each { |k|
        images[k] = TkPhotoImage.new(:imagename => images[k],
                                     :without_creating => true)
      }
      images
    end

    def self.style(*args)
      args.map!{|arg| TkComm._get_eval_string(arg)}.join('.')
    end

    def self.themes(glob_ptn = '*')
      begin
        TkComm.simplelist(Tk.tk_call_without_enc('::ttk::themes', glob_ptn))
      rescue
        TkComm.simplelist(Tk.tk_call('lsearch', '-all', '-inline',
                                     Tk::Tile::Style.theme_names,
                                     glob_ptn))
      end
    end

    def self.set_theme(theme)
      begin
        Tk.tk_call_without_enc('::ttk::setTheme', theme)
      rescue
        Tk::Tile::Style.theme_use(theme)
      end
    end

    # KeyNav was for ancient Tile - these are no-ops on modern Ttk
    module KeyNav
      def self.enableMnemonics(w)
        ""
      end
      def self.defaultButton(w)
        ""
      end
    end

    module Font
      Default      = 'TkDefaultFont'
      Text         = 'TkTextFont'
      Heading      = 'TkHeadingFont'
      Caption      = 'TkCaptionFont'
      Tooltip      = 'TkTooltipFont'

      Fixed        = 'TkFixedFont'
      Menu         = 'TkMenuFont'
      SmallCaption = 'TkSmallCaptionFont'
      Icon         = 'TkIconFont'
    end

    module ParseStyleLayout
      def _style_layout(lst)
        ret = []
        until lst.empty?
          sub = [lst.shift]
          keys = {}

          until lst.empty?
            if lst[0][0] == ?-
              k = lst.shift[1..-1]
              children = lst.shift
              children = _style_layout(children) if children.kind_of?(Array)
              keys[k] = children
            else
              break
            end
          end

          sub << keys unless keys.empty?
          ret << sub
        end
        ret
      end
      private :_style_layout
    end

    # Translates Tk options to Ttk equivalents (e.g., padx/pady -> padding)
    # Prepended to widget classes via TileWidget inclusion
    module OptionTranslator
      def self.translate_options(keys, widget_class: nil)
        keys = keys.dup

        padx = keys.delete('padx') || keys.delete(:padx)
        pady = keys.delete('pady') || keys.delete(:pady)

        if padx || pady
          unless keys.key?('padding') || keys.key?(:padding)
            keys['padding'] = [padx || 0, pady || 0]
            class_name = widget_class ? widget_class.name : 'Ttk widget'
            Tk::Warnings.warn_once(:"tile_padding_#{class_name}",
              "Translated padx/pady to padding for #{class_name}. " \
              "Consider using -padding directly for Ttk widgets.")
          end
        end

        keys
      end

      def configure(slot, value=TkUtil::None)
        if slot.kind_of?(Hash)
          slot = OptionTranslator.translate_options(slot, widget_class: self.class)
        end
        super
      end
    end

    module TileWidget
      include Tk::Tile::ParseStyleLayout

      def self.included(base)
        base.prepend(OptionTranslator)
      end

      def ttk_instate(state, script=nil, &b)
        if script
          tk_send('instate', state, script)
        elsif b
          tk_send('instate', state, b)
        else
          bool(tk_send('instate', state))
        end
      end
      alias tile_instate ttk_instate

      def ttk_state(state=nil)
        if state
          tk_send('state', state)
        else
          list(tk_send('state'))
        end
      end
      alias tile_state ttk_state

      def ttk_identify(x, y)
        ret = tk_send_without_enc('identify', x, y)
        (ret.empty?)? nil: ret
      end
      alias tile_identify ttk_identify

      # remove instate/state/identify method
      # to avoid the conflict with widget options
      if Tk.const_defined?(:USE_OBSOLETE_TILE_STATE_METHOD) && Tk::USE_OBSOLETE_TILE_STATE_METHOD
        alias instate  ttk_instate
        alias state    ttk_state
        alias identify ttk_identify
      end
    end

    ######################################

    autoload :TButton,       'tkextlib/tile/tbutton'
    autoload :Button,        'tkextlib/tile/tbutton'

    autoload :TCheckButton,  'tkextlib/tile/tcheckbutton'
    autoload :CheckButton,   'tkextlib/tile/tcheckbutton'
    autoload :TCheckbutton,  'tkextlib/tile/tcheckbutton'
    autoload :Checkbutton,   'tkextlib/tile/tcheckbutton'

    autoload :Dialog,        'tkextlib/tile/dialog'

    autoload :TEntry,        'tkextlib/tile/tentry'
    autoload :Entry,         'tkextlib/tile/tentry'

    autoload :TCombobox,     'tkextlib/tile/tcombobox'
    autoload :Combobox,      'tkextlib/tile/tcombobox'

    autoload :TFrame,        'tkextlib/tile/tframe'
    autoload :Frame,         'tkextlib/tile/tframe'

    autoload :TLabelframe,   'tkextlib/tile/tlabelframe'
    autoload :Labelframe,    'tkextlib/tile/tlabelframe'
    autoload :TLabelFrame,   'tkextlib/tile/tlabelframe'
    autoload :LabelFrame,    'tkextlib/tile/tlabelframe'

    autoload :TLabel,        'tkextlib/tile/tlabel'
    autoload :Label,         'tkextlib/tile/tlabel'

    autoload :TMenubutton,   'tkextlib/tile/tmenubutton'
    autoload :Menubutton,    'tkextlib/tile/tmenubutton'
    autoload :TMenuButton,   'tkextlib/tile/tmenubutton'
    autoload :MenuButton,    'tkextlib/tile/tmenubutton'

    autoload :TNotebook,     'tkextlib/tile/tnotebook'
    autoload :Notebook,      'tkextlib/tile/tnotebook'

    autoload :TPaned,        'tkextlib/tile/tpaned'
    autoload :Paned,         'tkextlib/tile/tpaned'
    autoload :PanedWindow,   'tkextlib/tile/tpaned'
    autoload :Panedwindow,   'tkextlib/tile/tpaned'

    autoload :TProgressbar,  'tkextlib/tile/tprogressbar'
    autoload :Progressbar,   'tkextlib/tile/tprogressbar'

    autoload :TRadioButton,  'tkextlib/tile/tradiobutton'
    autoload :RadioButton,   'tkextlib/tile/tradiobutton'
    autoload :TRadiobutton,  'tkextlib/tile/tradiobutton'
    autoload :Radiobutton,   'tkextlib/tile/tradiobutton'

    autoload :TScale,        'tkextlib/tile/tscale'
    autoload :Scale,         'tkextlib/tile/tscale'
    autoload :TProgress,     'tkextlib/tile/tscale'
    autoload :Progress,      'tkextlib/tile/tscale'

    autoload :TScrollbar,    'tkextlib/tile/tscrollbar'
    autoload :Scrollbar,     'tkextlib/tile/tscrollbar'
    autoload :XScrollbar,    'tkextlib/tile/tscrollbar'
    autoload :YScrollbar,    'tkextlib/tile/tscrollbar'

    autoload :TSeparator,    'tkextlib/tile/tseparator'
    autoload :Separator,     'tkextlib/tile/tseparator'

    autoload :TSpinbox,      'tkextlib/tile/tspinbox'
    autoload :Spinbox,       'tkextlib/tile/tspinbox'

    autoload :TSquare,       'tkextlib/tile/tsquare'
    autoload :Square,        'tkextlib/tile/tsquare'

    autoload :SizeGrip,      'tkextlib/tile/sizegrip'
    autoload :Sizegrip,      'tkextlib/tile/sizegrip'

    autoload :Treeview,      'tkextlib/tile/treeview'

    autoload :Style,         'tkextlib/tile/style'
  end
end

Ttk = Tk::Tile
