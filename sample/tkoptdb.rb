#!/usr/bin/env ruby
# frozen_string_literal: false
#
#  sample script of TkOptionDB
#
#  Demonstrates loading widget options (colors, borders, text) from
#  resource files. If 'LANG' starts with 'ja', uses Japanese labels.
#
require "tk"

if __FILE__ == $0 || !TkCore::INTERP.safe?
  if ENV['LANG'] =~ /^ja/
    # read Japanese resource
    TkOptionDB.read_with_encoding(File.expand_path('resource.en',
                                                   File.dirname(__FILE__)),
                                  'utf-8')
  else
    # read English resource
    TkOptionDB.readfile(File.expand_path('resource.en',
                                         File.dirname(__FILE__)))
  end
end

# Define procs in Ruby code (not from resource file - that was removed for security)
show_msg = proc { |arg| puts "Hello! This is a sample of #{arg}." }
bye_msg = proc { puts "Good-bye!"; exit }

# First frame - uses BtnFrame class which has styling in resource file
TkFrame.new(:class=>'BtnFrame'){|f|
  pack(:padx=>5, :pady=>5)
  TkButton.new(:parent=>f, :widgetname=>'hello'){
    command proc{ show_msg.call(TkOptionDB.inspect) }
    pack(:fill=>:x, :padx=>10, :pady=>10)
  }
  TkButton.new(:parent=>f, :widgetname=>'quit'){
    command bye_msg
    pack(:fill=>:x, :padx=>10, :pady=>10)
  }
}

# Second frame - same class, same styling
class BtnFrame < TkFrame; end
BtnFrame.new{|f|
  pack(:padx=>5, :pady=>5)
  TkButton.new(:parent=>f, :widgetname=>'hello'){
    command proc{ show_msg.call(TkOptionDB.inspect) }
    pack(:fill=>:x, :padx=>10, :pady=>10)
  }
  TkButton.new(:parent=>f, :widgetname=>'quit'){
    command bye_msg
    pack(:fill=>:x, :padx=>10, :pady=>10)
  }
}

# Third frame - unknown class, uses default options
TkFrame.new(:class=>'BtnFrame2'){|f|
  pack(:padx=>5, :pady=>5)
  TkButton.new(:parent=>f, :widgetname=>'hello'){
    command proc{ show_msg.call(TkOptionDB.inspect) }
    pack(:fill=>:x, :padx=>10, :pady=>10)
  }
  TkButton.new(:parent=>f, :widgetname=>'quit'){
    command bye_msg
    pack(:fill=>:x, :padx=>10, :pady=>10)
  }
}

# Automated demo support (testing only, no recording)
require 'tk/demo_support'

if TkDemo.active?
  TkDemo.on_visible {
    puts "UI loaded"
    puts "TkOptionDB demo - button styling from resource file"
    Tk.after(TkDemo.delay) { TkDemo.finish }
  }
end

Tk.mainloop
