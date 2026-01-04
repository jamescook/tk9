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

    root = TkRoot.new { withdraw }
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

    # Check errors before tk_end (which may block in visual mode)
    unless errors.empty?
      root.destroy
      raise "Listbox test failures:\n  " + errors.join("\n  ")
    end

    tk_end(root)
  end
end
