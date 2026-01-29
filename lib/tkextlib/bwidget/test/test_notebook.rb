# frozen_string_literal: true

# Test for Tk::BWidget::NoteBook widget options.
#
# See: https://core.tcl-lang.org/bwidget/doc/bwidget/BWman/NoteBook.html

require_relative '../../../../test/test_helper'
require_relative '../../../../test/tk_test_helper'

class TestBWidgetNoteBook < Minitest::Test
  include TkTestHelper

  def test_notebook_comprehensive
    assert_tk_app("BWidget NoteBook test", method(:notebook_app))
  end

  def notebook_app
    require 'tk'
    require 'tkextlib/bwidget'

    errors = []

    # --- Basic notebook ---
    notebook = Tk::BWidget::NoteBook.new(root)
    notebook.pack(fill: 'both', expand: true)

    # --- Add pages ---
    page1 = notebook.insert('end', 'page1', text: 'Page 1')
    page2 = notebook.insert('end', 'page2', text: 'Page 2')
    page3 = notebook.insert('end', 'page3', text: 'Page 3')

    errors << "insert page1 failed" if page1.nil?
    errors << "insert page2 failed" if page2.nil?

    # --- pages method ---
    pages = notebook.pages
    errors << "pages count failed" unless pages.size == 3

    # --- index method ---
    idx = notebook.index('page2')
    errors << "index failed" unless idx == 1

    # --- raise (select) page ---
    notebook.raise('page2')
    current = notebook.raise
    errors << "raise/get current failed" unless current == 'page2'

    # --- homogeneous (BWidget-specific boolean option) ---
    notebook.configure(homogeneous: true)
    errors << "homogeneous true failed" unless notebook.cget(:homogeneous) == true

    notebook.configure(homogeneous: false)
    errors << "homogeneous false failed" unless notebook.cget(:homogeneous) == false

    # --- get_frame ---
    frame = notebook.get_frame('page1')
    errors << "get_frame failed" if frame.nil?

    # --- move page ---
    notebook.move('page3', 0)
    idx = notebook.index('page3')
    errors << "move failed" unless idx == 0

    # --- delete page ---
    notebook.delete('page3')
    pages = notebook.pages
    errors << "delete failed" unless pages.size == 2

    # --- itemconfigure/itemcget for page options ---
    notebook.itemconfigure('page1', text: 'First Page')
    text = notebook.itemcget('page1', :text)
    errors << "itemcget text failed: got #{text.inspect}" unless text == 'First Page'

    notebook.itemconfigure('page1', state: 'disabled')
    state = notebook.itemcget('page1', :state)
    errors << "itemcget state failed: got #{state.inspect}" unless state == 'disabled'

    notebook.itemconfigure('page1', state: 'normal')

    raise "BWidget NoteBook test failures:\n  " + errors.join("\n  ") unless errors.empty?
  end
end
