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

    root = TkRoot.new { withdraw }
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
    errors << "selectbackground failed" if text.cget(:selectbackground).to_s.empty?

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

    # Check errors before tk_end (which may block in visual mode)
    unless errors.empty?
      root.destroy
      raise "Text test failures:\n  " + errors.join("\n  ")
    end

    tk_end(root)
  end
end
