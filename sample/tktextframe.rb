# frozen_string_literal: false
# tk-record: screen_size=500x450
#
#  tktextframe.rb : a sample of TkComposite
#
#                         by Hidetoshi NAGAI (nagai@ai.kyutech.ac.jp)
#
require 'tk'

module Tk::ScrollbarComposite
  include TkComposite

  def component_construct_keys
    # If a component requires options for construction,
    # return an Array of option-keys.
    []
  end
  private :component_construct_keys

  def create_component(keys={})
    # This method must return the created component widget.
  end
  private :create_component

  def component_delegates
    # if want to override default option-methods or delegates,
    # please define here.
  end
  private :component_delegates

  def define_delegates
    # option methods for scrollbars
    option_methods([:scrollbarwidth, :get_scrollbarwidth])

    # set receiver widgets for configure methods (with alias)
    delegate_alias('scrollbarrelief', 'relief', @h_scroll, @v_scroll)
    delegate_alias('framebackground', 'background',
                   @frame, @h_scroll, @v_scroll)
    delegate_alias('activeframebackground', 'activebackground',
                   @h_scroll, @v_scroll)

    # set receiver widgets for configure methods
    delegate('DEFAULT', @component)
    delegate('troughcolor', @h_scroll, @v_scroll)
    delegate('repeatdelay', @h_scroll, @v_scroll)
    delegate('repeatinterval', @h_scroll, @v_scroll)
    delegate('borderwidth', @frame)
    delegate('relief', @frame)

    component_delegates
  end
  private :define_delegates

  DEFAULT_VSCROLL = true
  DEFAULT_HSCROLL = true

  def initialize_composite(keys={})
    keys = _symbolkey2str(keys)

    # create scrollbars
    @v_scroll = TkScrollbar.new(@frame, 'orient'=>'vertical')
    @h_scroll = TkScrollbar.new(@frame, 'orient'=>'horizontal')

    # create a component
    construct_keys = {}
    ((component_construct_keys.map{|k| k.to_s}) & keys.keys).each{|k|
      construct_keys[k] = keys.delete(k)
    }

    # create a component (the component must be scrollable)
    @component = create_component(construct_keys)

    # set default receiver of method calls
    @path = @component.path

    # assign scrollbars
    @component.xscrollbar(@h_scroll)
    @component.yscrollbar(@v_scroll)

    # alignment
    TkGrid.rowconfigure(@frame, 0, 'weight'=>1, 'minsize'=>0)
    TkGrid.columnconfigure(@frame, 0, 'weight'=>1, 'minsize'=>0)
    @component.grid('row'=>0, 'column'=>0, 'sticky'=>'news')

    # scrollbars ON
    vscroll(keys.delete('vscroll'){self.class::DEFAULT_VSCROLL})
    hscroll(keys.delete('hscroll'){self.class::DEFAULT_HSCROLL})

    # do configure
    define_delegates

    # do configure
    configure keys unless keys.empty?
  end
  private :initialize_composite

  # get/set width of scrollbar
  def get_scrollbarwidth
    @v_scroll.width
  end
  def set_scrollbarwidth(width)
    @v_scroll.width(width)
    @h_scroll.width(width)
  end
  alias :scrollbarwidth :set_scrollbarwidth

  def hook_vscroll_on(*args); end
  def hook_vscroll_off(*args); end
  def hook_hscroll_on(*args); end
  def hook_hscroll_off(*args); end
  private :hook_vscroll_on,:hook_vscroll_off,:hook_hscroll_on,:hook_hscroll_off

  # vertical scrollbar : ON/OFF
  def vscroll(mode, *args)
    st = TkGrid.info(@v_scroll)
    if mode && st.size == 0 then
      @v_scroll.grid('row'=>0, 'column'=>1, 'sticky'=>'ns')
      hook_vscroll_on(*args)
    elsif !mode && st.size != 0 then
      @v_scroll.ungrid
      hook_vscroll_off(*args)
    end
    self
  end

  # horizontal scrollbar : ON/OFF
  def hscroll(mode, *args)
    st = TkGrid.info(@h_scroll)
    if mode && st.size == 0 then
      @h_scroll.grid('row'=>1, 'column'=>0, 'sticky'=>'ew')
      hook_hscroll_on(*args)
    elsif !mode && st.size != 0 then
      @h_scroll.ungrid
      hook_hscroll_off(*args)
    end
    self
  end
end

################################################

class TkTextFrame < TkText
  include Tk::ScrollbarComposite

  # def component_construct_keys; []; end
  # private :component_construct_keys

  def create_component(keys={})
    # keys has options which are listed by component_construct_keys method.
    @text = TkText.new(@frame, 'wrap'=>'none')
    @text.configure(keys) unless keys.empty?

    # option methods for component
    option_methods(
       [:textbackground, nil, :textbg_info],
       :textborderwidth,
       :textrelief
    )

    # return the created component
    @text
  end
  private :create_component

  # def component_delegates; end
  # private :component_delegates

  def hook_hscroll_on(wrap_mode=nil)
    if wrap_mode
      wrap wrap_mode
    else
      wrap 'none'  # => self.wrap('none')
    end
  end
  def hook_hscroll_off(wrap_mode)
    wrap wrap_mode  # => self.wrap(wrap_mode)
  end
  def hscroll(mode, wrap_mode="char")
    super
  end

  # set background color of text widget
  def textbackground(color = nil)
    if color
      @text.background(color)
    else
      @text.background
    end
  end

  def textbg_info
    info = @text.configinfo(:background)
    info[0] = 'textbackground'
    info
  end

  # get/set borderwidth of text widget
  def set_textborderwidth(width)
    @text.borderwidth(width)
  end
  def get_textborderwidth
    @text.borderwidth
  end
  def textborderwidth(width = nil)
    if width
      set_textborderwidth(width)
    else
      get_textborderwidth
    end
  end

  # set relief of text widget
  def textrelief(type)
    @text.relief(type)
  end
end

################################################
# test
################################################
if __FILE__ == $0
  TkLabel.new(:text=>'TkTextFrame is an example of Tk::ScrollbarComposite module.').pack
  f = TkFrame.new.pack('fill'=>'x')
  #t = TkTextFrame.new.pack
  t = TkTextFrame.new(:textborderwidth=>3,
                      :textrelief=>:ridge,
                      :scrollbarrelief=>:ridge).pack

  # Insert placeholder text so there's something to scroll
  lorem = "Lorem ipsum dolor sit amet, consectetur adipiscing elit. " * 3
  (1..15).each { |i| t.insert('end', "#{i}: #{lorem}\n") }
  p t.configinfo

  # Store toggle procs for demo
  vscroll_off = proc { t.vscroll(false) }
  vscroll_on = proc { t.vscroll(true) }
  hscroll_on = proc { t.hscroll(true) }
  hscroll_off = proc { t.hscroll(false) }

  TkButton.new(f, 'text'=>'vscr OFF', 'command'=>vscroll_off).pack('side'=>'right')
  TkButton.new(f, 'text'=>'vscr ON', 'command'=>vscroll_on).pack('side'=>'right')
  TkButton.new(f, 'text'=>'hscr ON', 'command'=>hscroll_on).pack('side'=>'left')
  TkButton.new(f, 'text'=>'hscr OFF', 'command'=>hscroll_off).pack('side'=>'left')

  ############################################

  # Tk.default_widget_set = :Ttk

  TkFrame.new.pack(:pady=>10)
  TkLabel.new(:text=>'The following is another example of Tk::ScrollbarComposite module.').pack

  #----------------------------------
  class ScrListbox < TkListbox
    include Tk::ScrollbarComposite

    DEFAULT_HSCROLL = false

    def create_component(keys={})
      TkListbox.new(@frame, keys)
    end
    private :create_component
  end
  #----------------------------------

  f = TkFrame.new.pack(:pady=>5)
  lbox = ScrListbox.new(f).pack(:side=>:left)
  lbox.value = %w(aa bb cc dd eeeeeeeeeeeeeeeeeeeeeeeeee ffffffffff gg hh ii jj kk ll mmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmm nn oo pp qq)
  fb = TkFrame.new(f).pack(:expand=>true, :fill=>:y, :padx=>5)

  # Store listbox toggle procs for demo
  lbox_hscroll_off = proc { lbox.hscroll(false) }
  lbox_hscroll_on = proc { lbox.hscroll(true) }
  lbox_vscroll_off = proc { lbox.vscroll(false) }
  lbox_vscroll_on = proc { lbox.vscroll(true) }

  TkButton.new(fb, 'text'=>'lbox hscr OFF',
               'command'=>lbox_hscroll_off).pack(:side=>:bottom, :fill=>:x)
  TkButton.new(fb, 'text'=>'lbox hscr ON',
               'command'=>lbox_hscroll_on).pack(:side=>:bottom, :fill=>:x)
  TkFrame.new(fb).pack(:pady=>5, :side=>:bottom)
  TkButton.new(fb, 'text'=>'lbox vscr OFF',
               'command'=>lbox_vscroll_off).pack(:side=>:bottom, :fill=>:x)
  TkButton.new(fb, 'text'=>'lbox vscr ON',
               'command'=>lbox_vscroll_on).pack(:side=>:bottom, :fill=>:x)

  ############################################

  # Automated demo support (testing and recording)
  require 'tk/demo_support'

  if TkDemo.active?
    TkDemo.on_visible {
      puts "UI loaded"
      puts "TkComposite scrollbar demo"

      delay = TkDemo.delay

      # Demo: toggle scrollbars on text widget
      Tk.after(delay) {
        vscroll_off.call
        Tk.update
        puts "text vscroll off"

        Tk.after(delay) {
          hscroll_off.call
          Tk.update
          puts "text hscroll off"

          Tk.after(delay) {
            vscroll_on.call
            Tk.update
            puts "text vscroll on"

            Tk.after(delay) {
              hscroll_on.call
              Tk.update
              puts "text hscroll on"

              Tk.after(delay) {
                # Toggle listbox scrollbars
                lbox_hscroll_on.call
                Tk.update
                puts "listbox hscroll on"

                Tk.after(delay) {
                  lbox_vscroll_off.call
                  Tk.update
                  puts "listbox vscroll off"

                  Tk.after(delay) {
                    lbox_vscroll_on.call
                    Tk.update
                    puts "listbox vscroll on"

                    Tk.after(delay) { TkDemo.finish }
                  }
                }
              }
            }
          }
        }
      }
    }
  end

  Tk.mainloop
end
