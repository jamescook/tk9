# frozen_string_literal: false
#
#   tk/console.rb : control the console on system without a real console
#

module TkConsole
  include Tk
  extend Tk

  TkCommandNames = ['console'.freeze, 'consoleinterp'.freeze].freeze

  def self.create
    TkCore::INTERP.create_console
  end

  def self.title(str=None)
    tk_call 'console', 'title', str
  end
  def self.hide
    tk_call_without_enc('console', 'hide')
  end
  def self.show
    tk_call_without_enc('console', 'show')
  end
  def self.eval(tcl_script)
    #
    # supports a Tcl script only
    # I have no idea to support a Ruby script seamlessly.
    #
    tk_call_without_enc('console', 'eval', _get_eval_enc_str(tcl_script))
  end
  def self.maininterp_eval(tcl_script)
    #
    # supports a Tcl script only
    # I have no idea to support a Ruby script seamlessly.
    #
    tk_call_without_enc('consoleinterp', 'eval', _get_eval_enc_str(tcl_script))

  end
  def self.maininterp_record(tcl_script)
    #
    # supports a Tcl script only
    # I have no idea to support a Ruby script seamlessly.
    #
    tk_call_without_enc('consoleinterp', 'record', _get_eval_enc_str(tcl_script))

  end
end
