# frozen_string_literal: true

# Comprehensive test for Tk::Tile::Treeview widget options.
# Runs in a single subprocess to minimize overhead.
#
# See: https://www.tcl-lang.org/man/tcl/TkCmd/ttk_treeview.html

require_relative '../../test_helper'
require_relative '../../tk_test_helper'

class TestTreeviewWidget < Minitest::Test
  include TkTestHelper

  def test_treeview_comprehensive
    assert_tk_app("Treeview widget comprehensive test", method(:treeview_app))
  end

  def treeview_app
    require 'tk'
    require 'tkextlib/tile'

    errors = []

    frame = Tk::Tile::TFrame.new(root, padding: 20)
    frame.pack(fill: "both", expand: true)

    # --- Basic treeview with columns ---
    tree = Tk::Tile::Treeview.new(frame,
      columns: ["name", "size", "modified"],
      height: 10
    )
    tree.pack(fill: "both", expand: true)

    # Verify columns
    cols = tree.cget(:columns)
    errors << "columns failed - expected array" unless cols.is_a?(Array)
    errors << "columns count failed" unless cols.size == 3
    errors << "columns content failed" unless cols.include?("name")

    # Verify height
    errors << "height failed" unless tree.cget(:height) == 10

    # --- Configure headings ---
    tree.heading_configure("#0", text: "Item")
    tree.heading_configure("name", text: "Name")
    tree.heading_configure("size", text: "Size")
    tree.heading_configure("modified", text: "Modified")

    # Verify heading text
    heading_text = tree.headingcget('name', :text)
    errors << "headingcget text failed" unless heading_text == "Name"

    # --- Configure column widths ---
    tree.column_configure("#0", width: 150)
    tree.column_configure("name", width: 200)
    tree.column_configure("size", width: 80)
    tree.column_configure("modified", width: 150)

    # --- Insert items ---
    folder1 = tree.insert("", "end", text: "Documents", values: ["Documents", "4 KB", "2024-01-01"])
    folder2 = tree.insert("", "end", text: "Pictures", values: ["Pictures", "2 KB", "2024-01-02"])

    errors << "insert returned nil" if folder1.nil?

    # Insert children
    file1 = tree.insert(folder1, "end", text: "report.txt", values: ["report.txt", "1 KB", "2024-01-01"])
    file2 = tree.insert(folder1, "end", text: "notes.txt", values: ["notes.txt", "500 B", "2024-01-01"])

    # --- Verify item exists ---
    errors << "item exist failed" unless tree.exist?(folder1)

    # --- Children ---
    children = tree.children(folder1)
    errors << "children count failed" unless children.size == 2

    # --- Selection mode ---
    tree.configure(selectmode: "browse")
    errors << "selectmode browse failed" unless tree.cget(:selectmode) == "browse"

    tree.configure(selectmode: "extended")
    errors << "selectmode extended failed" unless tree.cget(:selectmode) == "extended"

    tree.configure(selectmode: "none")
    errors << "selectmode none failed" unless tree.cget(:selectmode) == "none"

    tree.configure(selectmode: "extended")

    # --- Show option ---
    tree.configure(show: ["tree", "headings"])
    show_val = tree.cget(:show)
    errors << "show failed - expected array" unless show_val.is_a?(Array)
    errors << "show tree failed" unless show_val.include?("tree")
    errors << "show headings failed" unless show_val.include?("headings")

    # --- displaycolumns ---
    tree.configure(displaycolumns: ["name", "size"])
    display = tree.cget(:displaycolumns)
    errors << "displaycolumns count failed" unless display.size == 2

    tree.configure(displaycolumns: "#all")

    # --- Selection operations ---
    tree.selection_set(folder1)
    sel = tree.selection
    errors << "selection_set failed" unless sel.size == 1

    tree.selection_add(folder2)
    sel = tree.selection
    errors << "selection_add failed" unless sel.size == 2

    tree.selection_remove(folder1)
    sel = tree.selection
    errors << "selection_remove failed" unless sel.size == 1

    tree.selection_toggle(folder1)
    sel = tree.selection
    errors << "selection_toggle failed" unless sel.size == 2

    # --- Item configuration ---
    tree.itemconfigure(folder1, open: true)
    errors << "item open failed" unless tree.itemcget(folder1, :open) == true

    tree.itemconfigure(folder1, open: false)
    errors << "item close failed" unless tree.itemcget(folder1, :open) == false

    # --- get/set values ---
    tree.set(file1, "size", "2 KB")
    val = tree.get(file1, "size")
    errors << "get/set value failed" unless val == "2 KB"

    # --- Index ---
    idx = tree.index(folder2)
    errors << "index failed" unless idx == 1

    # --- Move item ---
    tree.move(folder2, "", 0)
    idx = tree.index(folder2)
    errors << "move failed" unless idx == 0

    # --- Delete ---
    tree.delete(file2)
    children = tree.children(folder1)
    errors << "delete failed" unless children.size == 1

    # --- Style ---
    style = tree.cget(:style)
    errors << "style cget failed" if style.nil?

    # --- Height change ---
    tree.configure(height: 5)
    errors << "height change failed" unless tree.cget(:height) == 5

    # --- Tk 9.0+ options (test with min_version check) ---
    if defined?(Tk::TK_MAJOR_VERSION) && Tk::TK_MAJOR_VERSION >= 9
      tree.configure(striped: true)
      errors << "striped failed" unless tree.cget(:striped) == true

      tree.configure(selecttype: "cell")
      errors << "selecttype failed" unless tree.cget(:selecttype) == "cell"

      tree.configure(titlecolumns: 1)
      errors << "titlecolumns failed" unless tree.cget(:titlecolumns) == 1
    end

    # ========================================
    # Item Configuration Tests (itemconfigure/itemcget)
    # ========================================

    # Recreate a simple tree for cleaner item config tests
    tree2 = Tk::Tile::Treeview.new(frame,
      columns: ["col1", "col2"],
      height: 5
    )
    tree2.pack(fill: "both", expand: true, pady: 10)

    tree2.heading_configure("#0", text: "Name")
    tree2.heading_configure("col1", text: "Value 1")
    tree2.heading_configure("col2", text: "Value 2")

    item1 = tree2.insert("", "end", text: "Item 1", values: ["A", "B"])
    item2 = tree2.insert("", "end", text: "Item 2", values: ["C", "D"])

    # --- Item open option ---
    tree2.itemconfigure(item1, open: true)
    errors << "itemconfigure open failed" unless tree2.itemcget(item1, :open) == true

    tree2.itemconfigure(item1, open: false)
    errors << "itemconfigure open false failed" unless tree2.itemcget(item1, :open) == false

    # --- Item text option ---
    tree2.itemconfigure(item1, text: "Modified Item 1")
    errors << "itemconfigure text failed" unless tree2.itemcget(item1, :text) == "Modified Item 1"

    # --- Item values option ---
    tree2.itemconfigure(item1, values: ["X", "Y"])
    vals = tree2.itemcget(item1, :values)
    errors << "itemconfigure values failed" unless vals.include?("X")

    # ========================================
    # Column Configuration Tests (columnconfigure/columncget)
    # ========================================

    # --- Column width ---
    tree2.column_configure("col1", width: 100)
    width = tree2.columncget("col1", :width)
    errors << "columnconfigure width failed" unless width.to_i == 100

    # --- Column minwidth ---
    tree2.column_configure("col1", minwidth: 50)
    minwidth = tree2.columncget("col1", :minwidth)
    errors << "columnconfigure minwidth failed" unless minwidth.to_i == 50

    # --- Column stretch ---
    tree2.column_configure("col1", stretch: false)
    stretch = tree2.columncget("col1", :stretch)
    errors << "columnconfigure stretch failed" unless stretch == false

    tree2.column_configure("col1", stretch: true)

    # --- Column anchor ---
    tree2.column_configure("col1", anchor: "center")
    anchor = tree2.columncget("col1", :anchor)
    errors << "columnconfigure anchor failed" unless anchor == "center"

    # ========================================
    # Heading Configuration Tests (headingconfigure/headingcget)
    # ========================================

    # --- Heading text ---
    tree2.heading_configure("col1", text: "Column One")
    text = tree2.headingcget("col1", :text)
    errors << "headingconfigure text failed" unless text == "Column One"

    # --- Heading anchor ---
    tree2.heading_configure("col1", anchor: "w")
    anchor = tree2.headingcget("col1", :anchor)
    errors << "headingconfigure anchor failed" unless anchor == "w"

    # ========================================
    # Tag Configuration Tests (tagconfigure/tagcget)
    # ========================================

    # Create and configure a tag
    tree2.tag_configure("highlight", background: "yellow")
    bg = tree2.tagcget("highlight", :background)
    errors << "tagconfigure background failed" if bg.to_s.empty?

    tree2.tag_configure("highlight", foreground: "red")
    fg = tree2.tagcget("highlight", :foreground)
    errors << "tagconfigure foreground failed" if fg.to_s.empty?

    # Apply tag to item
    tree2.itemconfigure(item1, tags: ["highlight"])
    tags = tree2.itemcget(item1, :tags)
    errors << "item tags failed" if tags.nil? || tags.empty?

    # Create another tag
    tree2.tag_configure("important", background: "lightblue")
    tree2.itemconfigure(item2, tags: ["important"])

    raise "Treeview test failures:\n  " + errors.join("\n  ") unless errors.empty?
  end
end
