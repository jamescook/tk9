#!/usr/bin/env ruby
# frozen_string_literal: false
# tk-record: screen_size=320x240
# This script generates a counter with start and stop buttons.

require "tk"

Tk.root.geometry('320x240')

# Container centered using place
container = TkFrame.new
container.place(:relx=>0.5, :rely=>0.5, :anchor=>'center')

$label = TkLabel.new(container) {
  text '0.00'
  relief 'raised'
  width 10
  pack('side'=>'bottom', 'fill'=>'x')
}

$start_btn = TkButton.new(container) {
  text 'Start'
  command proc {
    if $stopped
      $stopped = false
      tick
    end
  }
  pack('side'=>'left', 'padx'=>3, 'pady'=>2)
}
$stop_btn = TkButton.new(container) {
  text 'Stop'
  command proc{
    exit if $stopped
    $stopped = true
  }
  pack('side'=>'left', 'padx'=>3, 'pady'=>2)
}

$seconds=0
$hundredths=0
$stopped=true

def tick
  if $stopped then return end
  Tk.after 50, proc{tick}
  $hundredths+=5
  if $hundredths >= 100
    $hundredths=0
    $seconds+=1
  end
  $label.text format("%d.%02d", $seconds, $hundredths)
end

root = Tk.root
root.bind "Control-c", proc{root.destroy}
root.bind "Control-q", proc{root.destroy}
Tk.root.focus

# Automated demo support (testing and recording)
require 'tk/demo_support'

if TkDemo.active?
  TkDemo.on_visible {
    puts 'start clicked'
    $start_btn.invoke
    Tk.after(TkDemo.delay(test: 300, record: 2000)) {
      puts 'stop clicked'
      $stop_btn.invoke
      TkDemo.finish
    }
  }
end

Tk.mainloop
