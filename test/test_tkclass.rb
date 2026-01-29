# frozen_string_literal: true

# Test for lib/tkclass.rb - top-level constant aliases for Tk classes
# Uses subprocess to avoid polluting test namespace with top-level constants

require_relative 'test_helper'
require_relative 'tk_test_helper'

class TestTkClass < Minitest::Test
  include TkTestHelper

  def test_tkclass_aliases
    assert_tk_subprocess("tkclass.rb aliases") do
      <<~'RUBY'
        require 'tkclass'

        errors = []

        # Widget aliases
        errors << "TopLevel != TkToplevel" unless TopLevel == TkToplevel
        errors << "Frame != TkFrame" unless Frame == TkFrame
        errors << "Label != TkLabel" unless Label == TkLabel
        errors << "Button != TkButton" unless Button == TkButton
        errors << "Radiobutton != TkRadioButton" unless Radiobutton == TkRadioButton
        errors << "Checkbutton != TkCheckButton" unless Checkbutton == TkCheckButton
        errors << "Message != TkMessage" unless Message == TkMessage
        errors << "Entry != TkEntry" unless Entry == TkEntry
        errors << "Spinbox != TkSpinbox" unless Spinbox == TkSpinbox
        errors << "Text != TkText" unless Text == TkText
        errors << "Scale != TkScale" unless Scale == TkScale
        errors << "Scrollbar != TkScrollbar" unless Scrollbar == TkScrollbar
        errors << "Listbox != TkListbox" unless Listbox == TkListbox
        errors << "Menu != TkMenu" unless Menu == TkMenu
        errors << "Menubutton != TkMenubutton" unless Menubutton == TkMenubutton
        errors << "Canvas != TkCanvas" unless Canvas == TkCanvas

        # Canvas item aliases
        errors << "Arc != TkcArc" unless Arc == TkcArc
        errors << "Bitmap != TkcBitmap" unless Bitmap == TkcBitmap
        errors << "Line != TkcLine" unless Line == TkcLine
        errors << "Oval != TkcOval" unless Oval == TkcOval
        errors << "Polygon != TkcPolygon" unless Polygon == TkcPolygon
        errors << "Rectangle != TkcRectangle" unless Rectangle == TkcRectangle
        errors << "TextItem != TkcText" unless TextItem == TkcText
        errors << "WindowItem != TkcWindow" unless WindowItem == TkcWindow

        # Image aliases
        errors << "BitmapImage != TkBitmapImage" unless BitmapImage == TkBitmapImage
        errors << "PhotoImage != TkPhotoImage" unless PhotoImage == TkPhotoImage

        # Utility aliases
        errors << "Selection != TkSelection" unless Selection == TkSelection
        errors << "Winfo != TkWinfo" unless Winfo == TkWinfo
        errors << "Pack != TkPack" unless Pack == TkPack
        errors << "Grid != TkGrid" unless Grid == TkGrid
        errors << "Place != TkPlace" unless Place == TkPlace
        errors << "Variable != TkVariable" unless Variable == TkVariable
        errors << "VirtualEvent != TkVirtualEvent" unless VirtualEvent == TkVirtualEvent

        # Mainloop function (defined as private method on Object)
        errors << "Mainloop not defined" unless respond_to?(:Mainloop, true)

        raise errors.join("\n") unless errors.empty?
      RUBY
    end
  end
end
