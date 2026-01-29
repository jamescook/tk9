#!/usr/bin/env ruby
# frozen_string_literal: false
# tk-record: screen_size=640x480
# This script is a re-implementation of tktimer.rb with TkTimer(TkAfter) class.

require "tk"

Tk.root.geometry('640x480')

root = TkRoot.new(:title=>'realtime timer sample')

f1 = TkFrame.new(:borderwidth=>2, :relief=>:ridge)
f1.pack(:side=>:bottom, :fill=>:both)
TkLabel.new(f1, :text=>'use TkTimer (TkAfter) class').pack(:anchor=>:center)
label1 = TkLabel.new(:parent=>f1, :relief=>:raised,
                     :width=>10).pack(:fill=>:both)

f2 = TkFrame.new(:borderwidth=>2, :relief=>:ridge)
f2.pack(:side=>:bottom, :fill=>:both)
TkLabel.new(f2, :text=>'use TkRTTimer class').pack
label2 = TkLabel.new(:parent=>f2, :relief=>:raised,
                     :width=>10).pack(:fill=>:both)

TkLabel.new(:padx=>10, :pady=>5, :justify=>'left', :text=><<EOT).pack
Interval setting of each timer object is 10 ms.
Each timer object counts up the value on each callback
(the value is not the clock data).
The count of the TkTimer object is delayed by execution
time of callbacks and inaccuracy of interval.
On the other hand, the count of the TkRTTimer object is
not delayed. Its callback interval is not accurate too.
But it can compute error correction about the time when
a callback should start.
EOT

# define the procedure repeated by the TkTimer object
tick = proc{|aobj| #<== TkTimer object
  cnt = aobj.return_value + 1  # return_value keeps a result of the last proc
  label = aobj.current_args[0]
  label.text format("%d.%02d", *(cnt.divmod(100)))
  cnt #==> return value is kept by TkTimer object
      #    (so, can be send to the next repeat-proc)
}

timer1 = TkTimer.new(10, -1, [tick, label1])    # 10 ms interval
timer2 = TkRTTimer.new(10, -1, [tick, label2])  # 10 ms interval

timer1.start(0, proc{ label1.text('0.00'); 0 })
timer2.start(0, proc{ label2.text('0.00'); 0 })

b_start = TkButton.new(:text=>'Start', :state=>:disabled) {
  pack(:side=>:left, :fill=>:both, :expand=>true)
}

b_stop  = TkButton.new(:text=>'Stop', :state=>:normal) {
  pack('side'=>'left', 'fill'=>'both', 'expand'=>'yes')
}

b_start.command {
  timer1.continue
  timer2.continue
  b_stop.state(:normal)
  b_start.state(:disabled)
}

b_stop.command {
  timer1.stop
  timer2.stop
  b_start.state(:normal)
  b_stop.state(:disabled)
}

TkButton.new(:text=>'Reset', :state=>:normal) {
  command { timer1.reset; timer2.reset }
  pack(:side=>:right, :fill=>:both, :expand=>:yes)
}

ev_quit = TkVirtualEvent.new('Control-c', 'Control-q')
Tk.root.bind(ev_quit, proc{Tk.exit}).focus

# Automated demo support (testing and recording)
require 'tk/demo_support'

if TkDemo.active?
  TkDemo.on_visible {
    puts "timers running"
    # Timers already started, let them run
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
