#!/usr/bin/env ruby
# frozen_string_literal: false
# tk-record: screen_size=320x240
require 'tk'

Tk.root.geometry('320x240')

TkLabel.new(:text=>"Please click the bottom frame").pack

f = TkFrame.new(:width=>400, :height=>100, :background=>'yellow',
                :relief=>'ridge', :borderwidth=>5).pack

# TkPack.propagate(f, false) # <== important!!
f.pack_propagate(false)      # <== important!!

list = (1..3).collect{|n|
  TkButton.new(f, :text=>"button#{'-X'*n}"){
    command proc{
      puts "button#{'-X'*n}"
      self.unpack
    }
  }
}

list.unshift(nil)

f.bind('1', proc{
         w = list.shift
         w.unpack if w
         list.push(w)
         list[0].pack(:expand=>true, :anchor=>:center) if list[0]
       })

# Automated demo support (testing and recording)
require 'tk/demo_support'

if TkDemo.active?
  TkDemo.on_visible {
    puts "UI loaded"
    f.event_generate('1', x: 50, y: 50)
    Tk.update
    puts "button 1 shown"

    Tk.after(TkDemo.delay(test: 150)) {
      f.event_generate('1', x: 50, y: 50)
      Tk.update
      puts "button 2 shown"

      Tk.after(TkDemo.delay(test: 150)) {
        f.event_generate('1', x: 50, y: 50)
        Tk.update
        puts "button 3 shown"
        TkDemo.finish
      }
    }
  }
end

Tk.mainloop
