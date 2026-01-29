# frozen_string_literal: false
# tk-record: screen_size=320x240

require "tkclass"

Tk.root.geometry('320x240')

$tkline_init = false
def start_random
  return if $tkline_init
  $tkline_init = true
  if defined? Thread
    Thread.start do
      loop do
        sleep 2
        Line.new($c, rand(400), rand(200), rand(400), rand(200))
      end
    end
  end
end

Label.new('text'=>'Please press or drag button-1').pack

$c = Canvas.new
$c.pack
$start_x = start_y = 0

def do_press(x, y)
  $start_x = x
  $start_y = y
  $current_line = Line.new($c, x, y, x, y)
  start_random
end
def do_motion(x, y)
  if $current_line
    $current_line.coords $start_x, $start_y, x, y
  end
end

def do_release(x, y)
  if $current_line
    $current_line.coords $start_x, $start_y, x, y
    $current_line.fill 'black'
    $current_line = nil
  end
end

$c.bind("1", proc{|e| do_press e.x, e.y})
$c.bind("B1-Motion", proc{|x, y| do_motion x, y}, "%x %y")
$c.bind("ButtonRelease-1", proc{|x, y| do_release x, y}, "%x %y")

# Automated demo support (testing and recording)
require 'tk/demo_support'

if TkDemo.active?
  TkDemo.on_visible {
    puts "UI loaded"
    # Draw a line
    $c.event_generate('1', :x => 50, :y => 50)
    Tk.update
    $c.event_generate('Motion', :x => 150, :y => 100, :state => 256)  # B1-Motion
    Tk.update
    $c.event_generate('ButtonRelease-1', :x => 150, :y => 100)
    Tk.update
    puts "line drawn"

    Tk.after(TkDemo.delay) { TkDemo.finish }
  }
end

Tk.mainloop
