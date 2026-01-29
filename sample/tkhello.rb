# frozen_string_literal: false
# tk-record: screen_size=320x240
require "tk"

Tk.root.geometry('320x240')

hello_btn = TkButton.new(nil,
                         :text => 'hello',
                         :command => proc { puts "hello" }).pack(:fill => 'x')
TkButton.new(nil,
             :text => 'quit',
             :command => proc { exit }).pack(:fill => 'x')

# Automated demo support (testing and recording)
require 'tk/demo_support'

if TkDemo.active?
  TkDemo.on_visible {
    hello_btn.invoke
    Tk.after(TkDemo.delay(test: 200, record: 500)) {
      hello_btn.invoke
      TkDemo.finish
    }
  }
end

Tk.mainloop
