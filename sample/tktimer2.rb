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

start_btn = TkButton.new(container, :text=>'Start') {
  command proc{ timer.continue unless timer.running? }
  pack(:side=>:left, :padx=>2, :pady=>2)
}
restart_btn = TkButton.new(container, :text=>'Restart') {
  command proc{ timer.restart(0, proc{ label.text('0.00'); 0 }) }
  pack(:side=>:left, :padx=>2, :pady=>2)
}
stop_btn = TkButton.new(container, :text=>'Stop') {
  command proc{ timer.stop if timer.running? }
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
      stop_btn.invoke
      Tk.after(TkDemo.delay(test: 100, record: 500)) {
        puts "restart clicked"
        restart_btn.invoke
        Tk.after(TkDemo.delay(test: 200, record: 1000)) {
          puts "stop clicked"
          stop_btn.invoke
          TkDemo.finish
        }
      }
    }
  }
end

Tk.mainloop
