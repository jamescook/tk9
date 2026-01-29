# frozen_string_literal: true

# Tests for base class option defaults defined in TkConfigMethod.
# These options are hardcoded in __boolval_optkeys and __strval_optkeys.
# This test ensures they work correctly before/after migrating to OptionDSL.

require_relative 'test_helper'
require_relative 'tk_test_helper'

class TestBaseOptions < Minitest::Test
  include TkTestHelper

  def test_base_boolean_options
    assert_tk_app("Base boolean options test", method(:base_bool_app))
  end

  def test_base_string_options
    assert_tk_app("Base string options test", method(:base_string_app))
  end

  def test_color_relief_pixels_types
    assert_tk_app("Color/relief/pixels types test", method(:types_app))
  end

  def base_bool_app
    require 'tk'
    require 'tk/entry'
    require 'tk/listbox'
    require 'tk/scrollbar'

    errors = []

    # --- exportselection (Entry, Listbox, Text, Spinbox) ---
    entry = TkEntry.new(root, exportselection: true)
    errors << "exportselection true failed" unless entry.cget(:exportselection)
    errors << "exportselection true not boolean" unless entry.cget(:exportselection).is_a?(TrueClass)

    entry.configure(exportselection: false)
    errors << "exportselection false failed" if entry.cget(:exportselection)
    errors << "exportselection false not boolean" unless entry.cget(:exportselection).is_a?(FalseClass)

    # --- jump (Scrollbar) ---
    scrollbar = TkScrollbar.new(root, jump: true)
    errors << "jump true failed" unless scrollbar.cget(:jump)
    errors << "jump true not boolean" unless scrollbar.cget(:jump).is_a?(TrueClass)

    scrollbar.configure(jump: false)
    errors << "jump false failed" if scrollbar.cget(:jump)
    errors << "jump false not boolean" unless scrollbar.cget(:jump).is_a?(FalseClass)

    # --- setgrid (Listbox, Text) ---
    listbox = TkListbox.new(root, setgrid: true)
    errors << "setgrid true failed" unless listbox.cget(:setgrid)
    errors << "setgrid true not boolean" unless listbox.cget(:setgrid).is_a?(TrueClass)

    listbox.configure(setgrid: false)
    errors << "setgrid false failed" if listbox.cget(:setgrid)
    errors << "setgrid false not boolean" unless listbox.cget(:setgrid).is_a?(FalseClass)

    # --- takefocus (most widgets) ---
    # Note: takefocus is special - can be "", "0", "1", or a script
    # When set to false, Tk returns "" which needs special handling
    entry2 = TkEntry.new(root, takefocus: true)
    tf_true = entry2.cget(:takefocus)
    errors << "takefocus true failed: got #{tf_true.inspect}" unless tf_true == true || tf_true == "1" || tf_true == 1

    entry2.configure(takefocus: false)
    tf_false = entry2.cget(:takefocus)
    errors << "takefocus false failed: got #{tf_false.inspect}" unless tf_false == false || tf_false == "" || tf_false == "0" || tf_false == 0

    raise "Base boolean options failures:\n  " + errors.join("\n  ") unless errors.empty?
  end

  def base_string_app
    require 'tk'
    require 'tk/entry'
    require 'tk/button'
    require 'tk/scrollbar'
    require 'tk/scale'

    errors = []

    # --- text ---
    button = TkButton.new(root, text: "Hello")
    errors << "text failed" unless button.cget(:text) == "Hello"

    # --- background/foreground ---
    entry = TkEntry.new(root, background: "white", foreground: "black")
    errors << "background failed" unless entry.cget(:background).to_s == "white"
    errors << "foreground failed" unless entry.cget(:foreground).to_s == "black"

    # --- activebackground/activeforeground ---
    button.configure(activebackground: "red", activeforeground: "white")
    errors << "activebackground failed" unless button.cget(:activebackground).to_s == "red"
    errors << "activeforeground failed" unless button.cget(:activeforeground).to_s == "white"

    # --- disabledbackground/disabledforeground ---
    entry.configure(disabledbackground: "gray", disabledforeground: "darkgray")
    errors << "disabledbackground failed" unless entry.cget(:disabledbackground).to_s == "gray"
    errors << "disabledforeground failed" unless entry.cget(:disabledforeground).to_s == "darkgray"

    # --- highlightbackground/highlightcolor ---
    entry.configure(highlightbackground: "blue", highlightcolor: "navy")
    errors << "highlightbackground failed" unless entry.cget(:highlightbackground).to_s == "blue"
    errors << "highlightcolor failed" unless entry.cget(:highlightcolor).to_s == "navy"

    # --- insertbackground ---
    entry.configure(insertbackground: "red")
    errors << "insertbackground failed" unless entry.cget(:insertbackground).to_s == "red"

    # --- selectbackground/selectforeground ---
    entry.configure(selectbackground: "navy", selectforeground: "white")
    errors << "selectbackground failed" unless entry.cget(:selectbackground).to_s == "navy"
    errors << "selectforeground failed" unless entry.cget(:selectforeground).to_s == "white"

    # --- troughcolor (Scrollbar, Scale) ---
    scrollbar = TkScrollbar.new(root, troughcolor: "lightgray")
    errors << "troughcolor failed" unless scrollbar.cget(:troughcolor).to_s == "lightgray"

    raise "Base string options failures:\n  " + errors.join("\n  ") unless errors.empty?
  end

  def types_app
    require 'tk'
    require 'tk/button'
    require 'tk/entry'
    require 'tk/frame'

    errors = []

    # --- color type (returns string) ---
    button = TkButton.new(root, background: "red", foreground: "white")
    errors << "color background failed" unless button.cget(:background).to_s == "red"
    errors << "color foreground failed" unless button.cget(:foreground).to_s == "white"

    # --- relief type (returns string) ---
    frame = TkFrame.new(root, relief: "raised")
    errors << "relief raised failed" unless frame.cget(:relief) == "raised"

    frame.configure(relief: "sunken")
    errors << "relief sunken failed" unless frame.cget(:relief) == "sunken"

    frame.configure(relief: "groove")
    errors << "relief groove failed" unless frame.cget(:relief) == "groove"

    # --- pixels type (returns string or integer) ---
    entry = TkEntry.new(root, borderwidth: 2, highlightthickness: 1)
    bw = entry.cget(:borderwidth)
    errors << "pixels borderwidth failed" unless bw.to_i == 2

    ht = entry.cget(:highlightthickness)
    errors << "pixels highlightthickness failed" unless ht.to_i == 1

    raise "Color/relief/pixels type failures:\n  " + errors.join("\n  ") unless errors.empty?
  end
end
