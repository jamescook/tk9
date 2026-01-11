# frozen_string_literal: false
#
#  tkextlib/bwidget/passwddlg.rb
#                               by Hidetoshi NAGAI (nagai@ai.kyutech.ac.jp)
#

require 'tk' unless defined?(Tk)
require 'tkextlib/bwidget.rb'
require 'tkextlib/bwidget/messagedlg'

module Tk
  module BWidget
    class PasswdDlg < Tk::BWidget::MessageDlg
    end
  end
end

class Tk::BWidget::PasswdDlg
  extend Tk::OptionDSL

  TkCommandNames = ['PasswdDlg'.freeze].freeze
  WidgetClassName = 'PasswdDlg'.freeze
  WidgetClassNames[WidgetClassName] ||= self

  # BWidget PasswdDlg options
  option :loginhelpvar, type: :tkvariable
  option :logintextvariable, type: :tkvariable
  option :passwdhelpvar, type: :tkvariable
  option :passwdtextvariable, type: :tkvariable

  def create
    login, passwd = simplelist(tk_call(self.class::TkCommandNames[0],
                                       @path, *hash_kv(@keys)))
    [login, passwd]
  end
end
