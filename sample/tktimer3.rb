#!/usr/bin/env ruby
# frozen_string_literal: false
# tk-record: screen_size=320x240
# This script is a re-implementation of tktimer.rb with TkTimer(TkAfter) class.

require "tk"

Tk.root.geometry('320x240')
Tk.root.title('timer sample')

# Container centered using place
container = TkFrame.new
container.place(:relx=>0.5, :rely=>0.5, :anchor=>'center')

label = TkLabel.new(container, :relief=>:raised, :width=>10) \
               .pack(:side=>:bottom, :fill=>:x)

# define the procedure repeated by the TkTimer object
tick = proc{|aobj| #<== TkTimer object
  cnt = aobj.return_value + 5 # return_value keeps a result of the last proc
  label.text format("%d.%02d", *(cnt.divmod(100)))
  cnt #==> return value is kept by TkTimer object
      #    (so, can be send to the next repeat-proc)
}

timer = TkTimer.new(50, -1, tick).start(0, proc{ label.text('0.00'); 0 })
        # ==> repeat-interval : (about) 50 ms,
        #     repeat : infinite (-1) times,
        #     repeat-procedure : tick (only one, in this case)
        #
        # ==> wait-before-call-init-proc : 0 ms,
        #     init_proc : proc{ label.text('0.00'); 0 }
        #
        # (0ms)-> init_proc ->(50ms)-> tick ->(50ms)-> tick ->....

b_start = TkButton.new(container, :text=>'Start', :state=>:disabled) {
  pack(:side=>:left, :padx=>2, :pady=>2)
}

b_stop = TkButton.new(container, :text=>'Stop', :state=>:normal) {
  pack(:side=>:left, :padx=>2, :pady=>2)
}

b_start.command {
  timer.continue
  b_stop.state(:normal)
  b_start.state(:disabled)
}

b_stop.command {
  timer.stop
  b_start.state(:normal)
  b_stop.state(:disabled)
}

TkButton.new(container, :text=>'Reset', :state=>:normal) {
  command { timer.reset }
  pack(:side=>:left, :padx=>2, :pady=>2)
}

ev_quit = TkVirtualEvent.new('Control-c', 'Control-q')
Tk.root.bind(ev_quit, proc{Tk.exit}).focus

# Automated demo support (testing and recording)
require 'tk/demo_support'

if TkDemo.active?
  TkDemo.on_visible {
    puts "timer running"
    # Timer already started, let it run
    Tk.after(TkDemo.delay(test: 300, record: 2000)) {
      puts "stop clicked"
      b_stop.invoke
      Tk.after(TkDemo.delay(test: 100, record: 500)) {
        puts "start clicked"
        b_start.invoke
        Tk.after(TkDemo.delay(test: 200, record: 1000)) {
          puts "stop clicked"
          b_stop.invoke
          TkDemo.finish
        }
      }
    }
  }
end

Tk.mainloop
