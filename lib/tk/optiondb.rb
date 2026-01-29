# frozen_string_literal: false
#
# tk/optiondb.rb : treat option database
#

module TkOptionDB
  include Tk
  extend Tk

  TkCommandNames = ['option'.freeze].freeze

  module Priority
    WidgetDefault = 20
    StartupFile   = 40
    UserDefault   = 60
    Interactive   = 80
  end

  def add(pat, value, pri=None)
    tk_call('option', 'add', pat, value, pri)
  end
  def clear
    tk_call_without_enc('option', 'clear')
  end
  def get(win, name, klass)
    tk_call('option', 'get', win ,name, klass)
  end
  def readfile(file, pri=None)
    tk_call('option', 'readfile', file, pri)
  end
  alias read_file readfile
  module_function :add, :clear, :get, :readfile, :read_file

  def read_entries(file, _f_enc=nil)
    if TkCore::INTERP.safe?
      fail SecurityError,
        "can't call 'TkOptionDB.read_entries' on a safe interpreter"
    end

    # Note: f_enc parameter kept for API compatibility but unused
    # Modern Ruby/Tcl use UTF-8 natively

    ent = []
    cline = ''
    open(file, 'r') {|f|
      while line = f.gets
        #cline += line.chomp!
        cline.concat(line.chomp!)
        case cline
        when /\\$/    # continue
          cline.chop!
          next
        when /^\s*(!|#)/     # comment
          cline = ''
          next
        when /^([^:]+):(.*)$/
          pat = $1.strip
          val = $2.lstrip
          p "ResourceDB: #{[pat, val].inspect}" if $DEBUG
          ent << [pat, val]
          cline = ''
        else          # unknown --> ignore
          cline = ''
          next
        end
      end
    }
    ent
  end
  module_function :read_entries

  def read_with_encoding(file, f_enc=nil, pri=None)
    # try to read the file as an OptionDB file
    read_entries(file, f_enc).each{|pat, val|
      add(pat, val, pri)
    }

=begin
    i_enc = Tk.encoding()

    unless f_enc
      f_enc = i_enc
    end

    cline = ''
    open(file, 'r') {|f|
      while line = f.gets
        cline += line.chomp!
        case cline
        when /\\$/    # continue
          cline.chop!
          next
        when /^\s*!/     # comment
          cline = ''
          next
        when /^([^:]+):\s(.*)$/
          pat = $1
          val = $2
          p "ResourceDB: #{[pat, val].inspect}" if $DEBUG
          pat = TkCore::INTERP._toUTF8(pat, f_enc)
          pat = TkCore::INTERP._fromUTF8(pat, i_enc)
          val = TkCore::INTERP._toUTF8(val, f_enc)
          val = TkCore::INTERP._fromUTF8(val, i_enc)
          add(pat, val, pri)
          cline = ''
        else          # unknown --> ignore
          cline = ''
          next
        end
      end
    }
=end
  end
  module_function :read_with_encoding

  # Extend with compat stubs for removed proc class methods
  # (new_proc_class, new_proc_class_random, eval_under_random_base)
  extend TkOptionDBCompat
end
TkOption = TkOptionDB
TkResourceDB = TkOptionDB
