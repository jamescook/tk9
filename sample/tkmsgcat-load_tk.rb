#!/usr/bin/env ruby
# frozen_string_literal: false
# tk-record: screen_size=480x400

require 'tk'

Tk.root.geometry('480x400')

demo_dir = File.dirname($0)
msgcat_dir = [demo_dir, 'msgs_tk'].join(File::Separator)
top_win = nil
#msgcat = TkMsgCatalog.new('::tk')
msgcat = TkMsgCatalog.new('::tkmsgcat_demo')
default_locale = msgcat.locale
msgcat.load_tk(msgcat_dir)

col_proc = TkComm.install_bind(proc{|w, color, frame, label|
                                 TkComm.window(frame).background(color)
                                 Tk.update
                                 TkComm.window(label).text(
                                          msgcat.mc("%1$s:: %2$s", 'Color',
                                                    color.capitalize))
                                 w.flash; w.flash
                                 Tk.callback_break;
                              }, "%W")

del_proc = TkComm.install_cmd(proc{top_win.destroy; top_win = nil})

err_proc = TkComm.install_cmd(proc{fail(RuntimeError,
                                        msgcat.mc('Application Error'))})

show_sample = proc{|loc|
  top_win = TkToplevel.new(:title=>loc)

  msgcat.locale = loc
  msgcat.load_tk(msgcat_dir)

  TkLabel.new(top_win){
    text "preferences:: #{msgcat.preferences.join(' ')}"
    pack(:pady=>10, :padx=>10)
  }

  lbl = TkLabel.new(top_win, :text=>msgcat.mc("%1$s:: %2$s",
                                              'Color', '')).pack(:anchor=>'w')

  # Use classic Tk::Frame (not Ttk) so background color works when recording
  bg = Tk::Frame.new(top_win).pack(:ipadx=>20, :ipady=>10,
                                   :expand=>true, :fill=>:both)

  color_buttons = {}
  color_procs = {}
  TkFrame.new(bg){|f|
    ['blue', 'green', 'red'].each{|col|
      btn = nil
      # Extract color change into a proc we can call from button AND demo
      color_procs[col] = proc {
        bg.background(col)
        Tk.update
        lbl.text(msgcat.mc("%1$s:: %2$s", 'Color', col.capitalize))
        btn.flash rescue nil  # flash not available on Ttk buttons
      }
      btn = TkButton.new(f, :text=>msgcat.mc(col), :command=>color_procs[col]).pack(:fill=>:x)
      color_buttons[col] = btn
    }
  }.pack(:anchor=>'center', :pady=>15)
  top_win.instance_variable_set(:@color_buttons, color_buttons)
  top_win.instance_variable_set(:@color_procs, color_procs)

  TkFrame.new(top_win){|f|
    TkButton.new(f, :text=>msgcat.mc('Delete'),
                 :command=>del_proc).pack(:side=>:right, :padx=>5)
    TkButton.new(f, :text=>msgcat.mc('Error'),
                 :command=>err_proc).pack(:side=>:left, :padx=>5)
=begin
    TkButton.new(f, :text=>msgcat.mc('Delete'),
                 :command=>proc{
                   top_win.destroy
                   top_win = nil
                 }).pack(:side=>:right, :padx=>5)
    TkButton.new(f, :text=>msgcat.mc('Error'),
                 :command=>proc{
                   fail RuntimeError, msgcat.mc('Application Error')
                 }).pack(:side=>:left, :padx=>5)
=end
  }.pack(:side=>:bottom, :fill=>:x)

  top_win
}


#  listbox for locale list
TkLabel.new(:text=>"Please click a locale.").pack(:padx=>5, :pady=>3)

TkFrame.new{|f|
  TkButton.new(f, :text=>msgcat.mc('Exit'),
               :command=>proc{exit}).pack(:side=>:right, :padx=>5)
}.pack(:side=>:bottom, :fill=>:x)

f = TkFrame.new.pack(:side=>:top, :fill=>:both, :expand=>true)
lbox = TkListbox.new(f).pack(:side=>:left, :fill=>:both, :expand=>true)
lbox.yscrollbar(TkScrollbar.new(f, :width=>12).pack(:side=>:right, :fill=>:y))

lbox.bind('ButtonRelease-1'){|ev|
  idx = lbox.index("@#{ev.x},#{ev.y}")
  if idx == 0
    loc = default_locale
  else
    loc = lbox.get(idx)
  end
  if top_win != nil && top_win.exist?
    top_win.destroy
  end
  top_win = show_sample.call(loc)
}

lbox.insert('end', 'default')

Dir.entries(msgcat_dir).sort.each{|f|
  if f =~ /^(.*).msg$/
    lbox.insert('end', $1)
  end
}

top_win = show_sample.call(default_locale)

# Automated demo support (testing and recording)
require 'tk/demo_support'

if TkDemo.active?
  TkDemo.on_visible {
    puts "UI loaded"
    puts "locales: #{lbox.size}"

    delay = TkDemo.delay
    locales_to_demo = ['en', 'de', 'ja', 'ru']

    demo_locale = proc { |idx|
      if idx >= locales_to_demo.length
        Tk.after(delay) { TkDemo.finish }
      else
        loc = locales_to_demo[idx]
        puts "switching to #{loc}"

        # Destroy old window and create new one for this locale
        top_win.destroy if top_win && top_win.exist?
        top_win = show_sample.call(loc)
        Tk.update

        procs = top_win.instance_variable_get(:@color_procs)

        Tk.after(delay) {
          procs['blue'].call
          Tk.update
          puts "  clicked blue"

          Tk.after(delay) {
            procs['green'].call
            Tk.update
            puts "  clicked green"

            Tk.after(delay) {
              procs['red'].call
              Tk.update
              puts "  clicked red"

              Tk.after(delay) { demo_locale.call(idx + 1) }
            }
          }
        }
      end
    }

    Tk.after(delay) { demo_locale.call(0) }
  }
end

#  start eventloop
Tk.mainloop
