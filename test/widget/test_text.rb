# frozen_string_literal: true

# Comprehensive test for Tk::Text widget options.
# Runs in a single subprocess to minimize overhead.
#
# See: https://www.tcl-lang.org/man/tcl/TkCmd/text.html

require_relative '../test_helper'
require_relative '../tk_test_helper'

class TestTextWidget < Minitest::Test
  include TkTestHelper

  def test_text_comprehensive
    assert_tk_app("Text widget comprehensive test", method(:text_app))
  end

  def text_app
    require 'tk'
    require 'tk/text'

    errors = []

    # --- Basic creation with size ---
    text = TkText.new(root, width: 60, height: 20)
    text.pack(fill: "both", expand: true)
    errors << "width mismatch" unless text.cget(:width) == 60
    errors << "height mismatch" unless text.cget(:height) == 20

    # --- Insert text content ---
    text.insert("end", "Hello, World!\n")
    text.insert("end", "This is a multi-line\ntext widget test.\n")
    content = text.get("1.0", "end-1c")
    errors << "insert/get failed" unless content.include?("Hello")

    # --- Relief and border ---
    text.configure(relief: "sunken", borderwidth: 2)
    errors << "relief failed" unless text.cget(:relief) == "sunken"
    errors << "borderwidth failed" unless text.cget(:borderwidth).to_i == 2

    # --- Padding ---
    text.configure(padx: 10, pady: 5)
    errors << "padx failed" unless text.cget(:padx).to_i == 10
    errors << "pady failed" unless text.cget(:pady).to_i == 5

    # --- Wrap modes ---
    %w[none char word].each do |wrap|
      text.configure(wrap: wrap)
      errors << "wrap #{wrap} failed" unless text.cget(:wrap) == wrap
    end

    # --- State ---
    text.configure(state: "disabled")
    errors << "disabled state failed" unless text.cget(:state) == "disabled"
    text.configure(state: "normal")
    errors << "normal state failed" unless text.cget(:state) == "normal"

    # --- Undo/Redo options ---
    text.configure(undo: true, autoseparators: true, maxundo: 100)
    errors << "undo failed" unless text.cget(:undo)
    errors << "autoseparators failed" unless text.cget(:autoseparators)
    errors << "maxundo failed" unless text.cget(:maxundo) == 100

    # --- Spacing options ---
    text.configure(spacing1: 2, spacing2: 1, spacing3: 2)
    errors << "spacing1 failed" unless text.cget(:spacing1).to_i == 2
    errors << "spacing2 failed" unless text.cget(:spacing2).to_i == 1
    errors << "spacing3 failed" unless text.cget(:spacing3).to_i == 2

    # --- Insert cursor options ---
    text.configure(insertwidth: 3, insertofftime: 300, insertontime: 600)
    errors << "insertwidth failed" unless text.cget(:insertwidth).to_i == 3
    errors << "insertofftime failed" unless text.cget(:insertofftime) == 300
    errors << "insertontime failed" unless text.cget(:insertontime) == 600

    # --- Selection colors ---
    text.configure(selectbackground: "blue", selectforeground: "white")
    errors << "selectbackground failed" unless text.cget(:selectbackground).to_s == "blue"
    text.configure(inactiveselectbackground: "gray")
    errors << "inactiveselectbackground failed" unless text.cget(:inactiveselectbackground).to_s == "gray"

    # --- Tab style ---
    text.configure(tabstyle: "wordprocessor")
    errors << "tabstyle failed" unless text.cget(:tabstyle) == "wordprocessor"

    # --- Block cursor ---
    text.configure(blockcursor: true)
    errors << "blockcursor failed" unless text.cget(:blockcursor)

    # --- Export selection ---
    text.configure(exportselection: false)
    errors << "exportselection failed" if text.cget(:exportselection)

    # --- Text operations: delete, search ---
    text.delete("1.0", "end")
    text.insert("end", "Find me here\nAnd here too")

    # Search for text
    pos = text.search("here", "1.0")
    errors << "search failed" if pos.to_s.empty?

    # ========================================
    # Text Tag Configuration Tests (tag_configure/tag_cget)
    # ========================================

    # Create a tag and apply it
    text.delete("1.0", "end")
    text.insert("end", "Normal text. ")
    text.insert("end", "Tagged text here. ", "highlight")
    text.insert("end", "More normal text.")

    # --- Configure tag foreground/background ---
    text.tag_configure("highlight", foreground: "white", background: "blue")
    errors << "tag foreground failed" unless text.tag_cget("highlight", :foreground) == "white"
    errors << "tag background failed" unless text.tag_cget("highlight", :background) == "blue"

    # --- Configure tag font styling ---
    text.tag_configure("highlight", underline: true)
    errors << "tag underline failed" unless text.tag_cget("highlight", :underline)

    text.tag_configure("highlight", overstrike: true)
    errors << "tag overstrike failed" unless text.tag_cget("highlight", :overstrike)

    # --- Configure tag relief ---
    text.tag_configure("highlight", relief: "raised", borderwidth: 1)
    errors << "tag relief failed" unless text.tag_cget("highlight", :relief) == "raised"

    # --- Configure tag spacing ---
    text.tag_configure("highlight", spacing1: 5)
    errors << "tag spacing1 failed" unless text.tag_cget("highlight", :spacing1).to_i == 5

    # --- Configure tag justify ---
    text.tag_configure("highlight", justify: "center")
    errors << "tag justify failed" unless text.tag_cget("highlight", :justify) == "center"

    # --- Create second tag with different options ---
    text.insert("end", "\nError message", "error")
    text.tag_configure("error", foreground: "red", background: "yellow")
    errors << "error tag foreground failed" unless text.tag_cget("error", :foreground) == "red"
    errors << "error tag background failed" unless text.tag_cget("error", :background) == "yellow"

    # --- Tag ranges ---
    ranges = text.tag_ranges("highlight")
    errors << "tag_ranges failed" if ranges.nil?

    # --- Tag names ---
    names = text.tag_names
    errors << "tag_names failed" unless names.include?("highlight")

    # Check errors before tk_end (which may block in visual mode)
    unless errors.empty?
      raise "Text test failures:\n  " + errors.join("\n  ")
    end

  end
end
