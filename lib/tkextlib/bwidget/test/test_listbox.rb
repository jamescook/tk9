# frozen_string_literal: true

# Test for Tk::BWidget::ListBox widget options.
#
# See: https://core.tcl-lang.org/bwidget/doc/bwidget/BWman/ListBox.html

require_relative '../../../../test/test_helper'
require_relative '../../../../test/tk_test_helper'

class TestBWidgetListBox < Minitest::Test
  include TkTestHelper

  def test_listbox_comprehensive
    assert_tk_app("BWidget ListBox test", method(:listbox_app))
  end

  def listbox_app
    require 'tk'
    require 'tkextlib/bwidget'

    errors = []

    # --- Basic listbox ---
    lb = Tk::BWidget::ListBox.new(root)
    lb.pack(fill: "both", expand: true, padx: 10, pady: 10)

    # --- Insert items ---
    lb.insert("end", "item1", text: "Item 1")
    lb.insert("end", "item2", text: "Item 2")
    lb.insert("end", "item3", text: "Item 3")

    # --- exist? ---
    errors << "exist? should be true for item1" unless lb.exist?("item1")
    errors << "exist? should be false for nonexistent" if lb.exist?("nonexistent")

    # --- index ---
    idx = lb.index("item2")
    errors << "index failed, expected 1, got #{idx}" unless idx == 1

    # --- items ---
    all_items = lb.items
    errors << "items should return 3, got #{all_items.size}" unless all_items.size == 3

    # --- get_item ---
    item_at_0 = lb.get_item(0)
    errors << "get_item(0) failed" unless item_at_0 == "item1"

    # --- move ---
    lb.move("item3", 0)
    errors << "move failed" unless lb.index("item3") == 0

    # --- reorder ---
    lb.reorder(["item1", "item2", "item3"])
    errors << "reorder failed" unless lb.index("item1") == 0

    # --- selection methods ---
    lb.configure(selectmode: "multiple")

    lb.selection_set("item1")
    sel = lb.selection_get
    errors << "selection_set failed" if sel.empty?

    lb.selection_add("item2")
    sel = lb.selection_get
    errors << "selection_add failed, expected 2, got #{sel.size}" unless sel.size == 2

    lb.selection_remove("item1")
    sel = lb.selection_get
    errors << "selection_remove failed, expected 1, got #{sel.size}" unless sel.size == 1

    lb.selection_clear
    sel = lb.selection_get
    errors << "selection_clear failed" unless sel.empty?

    # --- see (scroll to item) ---
    lb.see("item3")

    # --- selectmode ---
    lb.configure(selectmode: "single")
    errors << "selectmode single failed" unless lb.cget(:selectmode) == "single"

    # --- background ---
    lb.configure(background: "white")
    errors << "background failed" if lb.cget(:background).to_s.empty?

    # --- height ---
    lb.configure(height: 10)
    errors << "height failed" unless lb.cget(:height).to_i == 10

    # --- Delete items ---
    lb.delete("item2")
    errors << "delete failed" if lb.exist?("item2")

    # --- ListBox::Item class ---
    item_obj = Tk::BWidget::ListBox::Item.new(lb, text: "Object Item")
    errors << "Item not created" unless item_obj.exist?
    errors << "Item listbox mismatch" unless item_obj.listbox == lb

    item_obj.configure(text: "Modified Item")
    text = item_obj.cget(:text)
    errors << "Item cget failed: #{text}" unless text == "Modified Item"

    item_idx = item_obj.index
    errors << "Item index failed" if item_idx.nil?

    item_obj.selection_set
    item_obj.selection_remove

    item_obj.delete
    errors << "Item delete failed" if item_obj.exist?

    raise "BWidget ListBox test failures:\n  " + errors.join("\n  ") unless errors.empty?
  end
end
