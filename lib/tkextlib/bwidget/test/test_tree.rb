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

    # --- close_tree / open_tree ---
    tree.open_tree('node1')
    errors << "open_tree failed" unless tree.open?('node1')

    tree.close_tree('node1')
    errors << "close_tree failed" if tree.open?('node1')

    # --- toggle ---
    tree.toggle('node1')
    errors << "toggle failed" unless tree.open?('node1')

    # --- parent ---
    parent_node = tree.parent('child1')
    errors << "parent failed, got #{parent_node}" unless parent_node == 'node1'

    # --- move ---
    tree.insert('end', 'root', 'node3', text: 'Node 3')
    tree.move('node3', 'child1', 0)
    errors << "move failed" unless tree.parent('child1') == 'node3'
    # Move back
    tree.move('node1', 'child1', 0)

    # --- see (scroll to node) ---
    tree.see('node2')

    # --- visible ---
    vis = tree.visible('node1')
    # visible returns boolean

    # --- line ---
    line_num = tree.line('node1')
    errors << "line failed" if line_num.nil?

    # --- selection_add / selection_remove / selection_toggle ---
    tree.selection_clear
    tree.selection_add('node1')
    tree.selection_add('node2')
    sel = tree.selection_get
    errors << "selection_add failed, expected 2, got #{sel.size}" unless sel.size == 2

    tree.selection_remove('node1')
    sel = tree.selection_get
    errors << "selection_remove failed" unless sel.size == 1

    tree.selection_toggle('node1')
    sel = tree.selection_get
    errors << "selection_toggle failed" unless sel.size == 2

    # --- reorder ---
    tree.insert('end', 'node1', 'child2', text: 'Child 2')
    tree.reorder('node1', ['child2', 'child1'])
    first_child = tree.get_node('node1', 0)
    errors << "reorder failed, got #{first_child}" unless first_child == 'child2'

    # --- delete ---
    tree.delete('child1', 'child2')
    children = tree.nodes('node1')
    errors << "delete failed" unless children.empty?

    # --- Tree::Node class ---
    node_obj = Tk::BWidget::Tree::Node.new(tree, 'root', text: 'Object Node')
    errors << "Node not created" unless node_obj.exist?
    errors << "Node tree mismatch" unless node_obj.tree == tree

    node_obj.configure(text: 'Modified Node')
    text = node_obj.cget(:text)
    errors << "Node cget failed: #{text}" unless text == 'Modified Node'

    node_idx = node_obj.index
    errors << "Node index failed" if node_idx.nil?

    node_obj.selection_set
    node_obj.selection_toggle
    node_obj.selection_remove

    node_obj.open_tree
    errors << "Node open_tree failed" unless node_obj.open?
    node_obj.close_tree
    errors << "Node close_tree failed" if node_obj.open?

    node_obj.delete
    errors << "Node delete failed" if node_obj.exist?

    raise "BWidget Tree test failures:\n  " + errors.join("\n  ") unless errors.empty?
  end
end
