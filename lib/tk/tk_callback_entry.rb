# frozen_string_literal: true
#
# TkCallbackEntry - marker class for Tk callback entries
# Used for type checking in callback handling

require_relative 'tk_kernel'

class TkCallbackEntry < TkKernel
  def self.inspect
    "TkCallbackEntry"
  end
end
