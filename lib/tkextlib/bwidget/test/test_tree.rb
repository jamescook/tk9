# frozen_string_literal: true

# Test for Tk::BWidget::Tree widget options.
#
# See: https://core.tcl-lang.org/bwidget/doc/bwidget/BWman/Tree.html

require_relative '../../../../test/test_helper'
require_relative '../../../../test/tk_test_helper'

class TestBWidgetTree < Minitest::Test
  include TkTestHelper

  def test_tree_comprehensive
    assert_tk_app("BWidget Tree test", method(:tree_app))
  end

  def tree_app
    require 'tk'
    require 'tkextlib/bwidget'

    errors = []

    # --- Basic tree ---
    tree = Tk::BWidget::Tree.new(root)
    tree.pack(fill: 'both', expand: true)

    # --- Insert nodes ---
    tree.insert('end', 'root', 'node1', text: 'Node 1')
    tree.insert('end', 'root', 'node2', text: 'Node 2')
    tree.insert('end', 'node1', 'child1', text: 'Child 1')

    # --- exist? ---
    errors << "exist? failed" unless tree.exist?('node1')
    errors << "exist? false failed" if tree.exist?('nonexistent')

    # --- nodes ---
    children = tree.nodes('node1')
    errors << "nodes failed" unless children.size == 1

    # --- index ---
    idx = tree.index('node2')
    errors << "index failed" unless idx == 1

    # --- itemconfigure/itemcget for node options ---
    tree.itemconfigure('node1', text: 'Modified Node 1')
    text = tree.itemcget('node1', :text)
    errors << "itemcget text failed: got #{text.inspect}" unless text == 'Modified Node 1'

    tree.itemconfigure('node1', open: true)
    open_val = tree.itemcget('node1', :open)
    errors << "itemcget open failed: got #{open_val.inspect}" unless open_val == true

    tree.itemconfigure('node1', open: false)
    open_val = tree.itemcget('node1', :open)
    errors << "itemcget open false failed: got #{open_val.inspect}" unless open_val == false

    # --- open? helper method (uses itemcget internally) ---
    tree.itemconfigure('node1', open: true)
    errors << "open? failed" unless tree.open?('node1')

    # --- selection ---
    tree.selection_set('node1')
    sel = tree.selection_get
    errors << "selection_set failed" if sel.empty?

    tree.selection_clear
    sel = tree.selection_get
    errors << "selection_clear failed" unless sel.empty?

    # --- delete ---
    tree.delete('child1')
    children = tree.nodes('node1')
    errors << "delete failed" unless children.empty?

    raise "BWidget Tree test failures:\n  " + errors.join("\n  ") unless errors.empty?
  end
end
