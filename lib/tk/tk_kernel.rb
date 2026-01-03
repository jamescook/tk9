# frozen_string_literal: true
#
# TkKernel - base class for Tk objects
# Provides block form for new: TkKernel.new { configure(...) }

class TkKernel
  def self.new(*args, &block)
    obj = super(*args)
    obj.instance_exec(&block) if block
    obj
  end
end
