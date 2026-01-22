# frozen_string_literal: false
#
# tk/tk_mac.rb : Access Mac-Specific functionality on macOS from Tk
#
# See: https://www.tcl-lang.org/man/tcl/TkCmd/tk_mac.html
#
require 'tk' unless defined?(Tk)

module Tk
  module Mac
  end
end

module Tk::Mac
  extend TkCore

  # event handler callbacks
  def self.def_ShowPreferences(cmd=nil, &block)
    ip_eval("proc ::tk::mac::ShowPreferences {} { #{install_cmd(cmd || block)} }")
    nil
  end

  def self.def_OpenApplication(cmd=nil, &block)
    ip_eval("proc ::tk::mac::OpenApplication {} { #{install_cmd(cmd || block)} }")
    nil
  end

  def self.def_ReopenApplication(cmd=nil, &block)
    ip_eval("proc ::tk::mac::ReopenApplication {} { #{install_cmd(cmd || block)} }")
    nil
  end

  def self.def_OpenDocument(cmd=nil, &block)
    ip_eval("proc ::tk::mac::OpenDocument {args} { eval #{install_cmd(cmd || block)} $args }")
    nil
  end

  def self.def_PrintDocument(cmd=nil, &block)
    ip_eval("proc ::tk::mac::PrintDocument {args} { eval #{install_cmd(cmd || block)} $args }")
    nil
  end

  def self.def_Quit(cmd=nil, &block)
    ip_eval("proc ::tk::mac::Quit {} { #{install_cmd(cmd || block)} }")
    nil
  end

  def self.def_OnHide(cmd=nil, &block)
    ip_eval("proc ::tk::mac::OnHide {} { #{install_cmd(cmd || block)} }")
    nil
  end

  def self.def_OnShow(cmd=nil, &block)
    ip_eval("proc ::tk::mac::OnShow {} { #{install_cmd(cmd || block)} }")
    nil
  end

  def self.def_ShowHelp(cmd=nil, &block)
    ip_eval("proc ::tk::mac::ShowHelp {} { #{install_cmd(cmd || block)} }")
    nil
  end


  # additional dialogs
  def self.standardAboutPanel
    tk_call('::tk::mac::standardAboutPanel')
    nil
  end


  # Deprecated methods - removed in modern Tcl/Tk
  def self.useCompatibilityMetrics(*)
    warn "Tk::Mac.useCompatibilityMetrics has been removed from Tcl/Tk", uplevel: 1
    raise NotImplementedError, "useCompatibilityMetrics no longer exists in Tcl/Tk"
  end

  def self.CGAntialiasLimit(*)
    warn "Tk::Mac.CGAntialiasLimit has been removed from Tcl/Tk", uplevel: 1
    raise NotImplementedError, "CGAntialiasLimit no longer exists in Tcl/Tk"
  end

  def self.antialiasedtext(*)
    warn "Tk::Mac.antialiasedtext has been removed from Tcl/Tk", uplevel: 1
    raise NotImplementedError, "antialiasedtext no longer exists in Tcl/Tk"
  end

  def self.useThemedToplevel(*)
    warn "Tk::Mac.useThemedToplevel has been removed from Tcl/Tk", uplevel: 1
    raise NotImplementedError, "useThemedToplevel no longer exists in Tcl/Tk"
  end

end

class Tk::Mac::IconBitmap < TkImage
  TkCommandNames = ['::tk::mac::iconBitmap'].freeze

  def self.new(width, height, keys)
    if keys.kind_of?(Hash)
      name = nil
      if keys.key?(:imagename)
        name = keys[:imagename]
      elsif keys.key?('imagename')
        name = keys['imagename']
      end
      if name
        if name.kind_of?(TkImage)
          obj = name
        else
          name = _get_eval_string(name)
          obj = nil
          Tk_IMGTBL.mutex.synchronize{
            obj = Tk_IMGTBL[name]
          }
        end
        if obj
          if !(keys[:without_creating] || keys['without_creating'])
            keys = _symbolkey2str(keys)
            keys.delete('imagename')
            keys.delete('without_creating')
            obj.instance_eval{
              tk_call_without_enc('::tk::mac::iconBitmap',
                                  @path, width, height, *hash_kv(keys, true))
            }
          end
          return obj
        end
      end
    end
    (obj = self.allocate).instance_eval{
      Tk_IMGTBL.mutex.synchronize{
        initialize(width, height, keys)
        Tk_IMGTBL[@path] = self
      }
    }
    obj
  end

  def initialize(width, height, keys)
    @path = nil
    without_creating = false
    if keys.kind_of?(Hash)
      keys = _symbolkey2str(keys)
      @path = keys.delete('imagename')
      without_creating = keys.delete('without_creating')
    end
    unless @path
      Tk_Image_ID.mutex.synchronize{
        @path = Tk_Image_ID.join(TkCore::INTERP._ip_id_)
        Tk_Image_ID[1].succ!
      }
    end
    unless without_creating
      tk_call_without_enc('::tk::mac::iconBitmap',
                          @path, width, height, *hash_kv(keys, true))
    end
  end
end
