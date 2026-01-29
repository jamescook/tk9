# frozen_string_literal: true

# Comprehensive test for Tk::Listbox widget options.
# Runs in a single subprocess to minimize overhead.
#
# See: https://www.tcl-lang.org/man/tcl/TkCmd/listbox.html

require_relative '../test_helper'
require_relative '../tk_test_helper'

class TestListboxWidget < Minitest::Test
  include TkTestHelper

  def test_listbox_comprehensive
    assert_tk_app("Listbox widget comprehensive test", method(:listbox_app))
  end

  def listbox_app
    require 'tk'
    require 'tk/listbox'
    require 'tk/frame'
    require 'tk/label'

    errors = []

    # --- Basic creation with size ---
    frame = TkFrame.new(root, padx: 10, pady: 10)
    frame.pack(fill: "both", expand: true)

    TkLabel.new(frame, text: "Select an item:").pack(anchor: "w")

    listbox = TkListbox.new(frame, width: 30, height: 10)
    listbox.pack(fill: "both", expand: true)
    errors << "width mismatch" unless listbox.cget(:width) == 30
    errors << "height mismatch" unless listbox.cget(:height) == 10

    # --- Insert items ---
    items = ["Apple", "Banana", "Cherry", "Date", "Elderberry", "Fig", "Grape"]
    listbox.value = items
    errors << "value= failed" unless listbox.size == items.size

    # --- Get items ---
    retrieved = listbox.value
    errors << "value failed" unless retrieved.size == items.size

    # --- Relief and border ---
    listbox.configure(relief: "sunken", borderwidth: 2)
    errors << "relief failed" unless listbox.cget(:relief) == "sunken"
    errors << "borderwidth failed" unless listbox.cget(:borderwidth).to_i == 2

    # --- Select modes ---
    %w[single browse multiple extended].each do |mode|
      listbox.configure(selectmode: mode)
      errors << "selectmode #{mode} failed" unless listbox.cget(:selectmode) == mode
    end

    # --- Active style ---
    %w[dotbox none underline].each do |style|
      listbox.configure(activestyle: style)
      errors << "activestyle #{style} failed" unless listbox.cget(:activestyle) == style
    end

    # --- State ---
    listbox.configure(state: "disabled")
    errors << "disabled state failed" unless listbox.cget(:state) == "disabled"
    listbox.configure(state: "normal")
    errors << "normal state failed" unless listbox.cget(:state) == "normal"

    # --- Selection colors ---
    listbox.configure(selectbackground: "navy", selectforeground: "white")
    errors << "selectbackground failed" if listbox.cget(:selectbackground).to_s.empty?
    errors << "selectforeground failed" if listbox.cget(:selectforeground).to_s.empty?

    # --- Selection operations ---
    listbox.selection_set(0)
    errors << "selection_set failed" unless listbox.selection_includes(0)

    listbox.selection_set(2, 4)
    errors << "range selection failed" unless listbox.curselection.size >= 3

    listbox.selection_clear(0, "end")
    errors << "selection_clear failed" unless listbox.curselection.empty?

    # --- Activate item ---
    listbox.activate(3)

    # --- Get single item ---
    item = listbox.get(0)
    errors << "get single failed" unless item == "Apple"

    # --- Get range ---
    range = listbox.get(0, 2)
    errors << "get range failed" unless range.size == 3

    # --- Nearest and index ---
    idx = listbox.index(0)
    errors << "index failed" unless idx == 0

    # --- Export selection ---
    listbox.configure(exportselection: false)
    errors << "exportselection failed" if listbox.cget(:exportselection)

    # --- Justify ---
    %w[left center right].each do |justify|
      listbox.configure(justify: justify)
      errors << "justify #{justify} failed" unless listbox.cget(:justify) == justify
    end

    # --- Clear/erase (test then repopulate for visual mode) ---
    listbox.clear
    errors << "clear failed" unless listbox.size == 0

    # Repopulate for visual display
    listbox.value = items
    listbox.selection_set(2)

    # ========================================
    # Listbox Item Configuration Tests (itemconfigure/itemcget)
    # ========================================

    # --- itemconfigure background ---
    listbox.itemconfigure(0, background: "lightyellow")
    errors << "itemconfigure background failed" if listbox.itemcget(0, :background).to_s.empty?

    # --- itemconfigure foreground ---
    listbox.itemconfigure(0, foreground: "darkblue")
    errors << "itemconfigure foreground failed" if listbox.itemcget(0, :foreground).to_s.empty?

    # --- itemconfigure selectbackground ---
    listbox.itemconfigure(1, selectbackground: "darkgreen")
    errors << "itemconfigure selectbackground failed" if listbox.itemcget(1, :selectbackground).to_s.empty?

    # --- itemconfigure selectforeground ---
    listbox.itemconfigure(1, selectforeground: "white")
    errors << "itemconfigure selectforeground failed" if listbox.itemcget(1, :selectforeground).to_s.empty?

    # --- Multiple items with different colors ---
    listbox.itemconfigure(2, background: "lightpink", foreground: "darkred")
    errors << "item 2 background failed" if listbox.itemcget(2, :background).to_s.empty?
    errors << "item 2 foreground failed" if listbox.itemcget(2, :foreground).to_s.empty?

    listbox.itemconfigure(3, background: "lightgreen", foreground: "darkgreen")
    errors << "item 3 background failed" if listbox.itemcget(3, :background).to_s.empty?

    # --- Verify individual items have different colors ---
    bg0 = listbox.itemcget(0, :background).to_s
    bg2 = listbox.itemcget(2, :background).to_s
    errors << "different item backgrounds failed" if bg0 == bg2 && !bg0.empty?

    # --- Verify ItemOptionDSL integration (listbox items have string options only, no list options) ---
    # This tests that the DSL bridge works correctly when no list options are declared
    listbox.itemconfigure(4, background: "white", foreground: "black",
                          selectbackground: "navy", selectforeground: "yellow")
    errors << "DSL item background failed" if listbox.itemcget(4, :background).to_s.empty?
    errors << "DSL item foreground failed" if listbox.itemcget(4, :foreground).to_s.empty?
    errors << "DSL item selectbackground failed" if listbox.itemcget(4, :selectbackground).to_s.empty?
    errors << "DSL item selectforeground failed" if listbox.itemcget(4, :selectforeground).to_s.empty?

    # Check errors before tk_end (which may block in visual mode)
    unless errors.empty?
      raise "Listbox test failures:\n  " + errors.join("\n  ")
    end

  end
end
