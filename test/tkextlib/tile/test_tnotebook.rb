# frozen_string_literal: true

# Comprehensive test for Tk::Tile::TNotebook widget options.
# Runs in a single subprocess to minimize overhead.
#
# See: https://www.tcl-lang.org/man/tcl/TkCmd/ttk_notebook.html

require_relative '../../test_helper'
require_relative '../../tk_test_helper'

class TestTNotebookWidget < Minitest::Test
  include TkTestHelper

  def test_tnotebook_comprehensive
    assert_tk_app("TNotebook widget comprehensive test", method(:tnotebook_app))
  end

  def tnotebook_app
    require 'tk'
    require 'tkextlib/tile'

    errors = []

    frame = Tk::Tile::TFrame.new(root, padding: 20)
    frame.pack(fill: "both", expand: true)

    # --- Basic notebook ---
    notebook = Tk::Tile::TNotebook.new(frame)
    notebook.pack(fill: "both", expand: true)

    # --- Add tabs ---
    tab1 = Tk::Tile::TFrame.new(notebook, padding: 10)
    Tk::Tile::TLabel.new(tab1, text: "Content of Tab 1").pack

    tab2 = Tk::Tile::TFrame.new(notebook, padding: 10)
    Tk::Tile::TLabel.new(tab2, text: "Content of Tab 2").pack

    tab3 = Tk::Tile::TFrame.new(notebook, padding: 10)
    Tk::Tile::TLabel.new(tab3, text: "Content of Tab 3").pack

    notebook.add(tab1, text: "Tab 1")
    notebook.add(tab2, text: "Tab 2")
    notebook.add(tab3, text: "Tab 3")

    # --- Verify tabs ---
    tabs = notebook.tabs
    errors << "tabs count failed" unless tabs.size == 3

    # --- Select tab ---
    notebook.select(1)
    errors << "select failed" unless notebook.index("current") == 1

    # --- Width and height ---
    notebook.configure(width: 400)
    errors << "width failed" unless notebook.cget(:width).to_i == 400

    notebook.configure(height: 300)
    errors << "height failed" unless notebook.cget(:height).to_i == 300

    # --- Padding ---
    notebook.configure(padding: "5 10")
    padding = notebook.cget(:padding)
    errors << "padding cget failed" if padding.nil?

    # --- Tab configuration ---
    notebook.tabconfigure(tab1, text: "Settings")
    tab_text = notebook.tabcget(tab1, :text)
    errors << "tabcget text failed" unless tab_text == "Settings"

    # --- Hide/forget tabs ---
    notebook.hide(tab3)
    # Tab is hidden but still exists
    errors << "hide failed - tabs count changed" unless notebook.tabs.size == 3

    # --- Insert tab at position ---
    tab4 = Tk::Tile::TFrame.new(notebook, padding: 10)
    Tk::Tile::TLabel.new(tab4, text: "Content of Tab 4").pack
    notebook.insert(1, tab4, text: "Inserted Tab")

    errors << "insert failed" unless notebook.tabs.size == 4

    # --- Index ---
    idx = notebook.index(tab2)
    errors << "index failed" unless idx.is_a?(Integer)

    # --- Style (ttk-specific) ---
    original_style = notebook.cget(:style)
    errors << "style cget failed" if original_style.nil?

    # ========================================
    # Tab Configuration Tests (tabconfigure/tabcget)
    # ========================================

    # --- tabcget text ---
    text = notebook.tabcget(tab1, :text)
    errors << "tabcget text failed: got #{text.inspect}" unless text == "Settings"

    # --- tabconfigure/tabcget sticky ---
    notebook.tabconfigure(tab1, sticky: "nsew")
    sticky = notebook.tabcget(tab1, :sticky)
    errors << "tabcget sticky failed: got #{sticky.inspect}" unless sticky == "nesw" || sticky == "nsew"

    # --- tabconfigure/tabcget padding ---
    notebook.tabconfigure(tab2, padding: "5 10")
    padding = notebook.tabcget(tab2, :padding)
    errors << "tabcget padding failed" if padding.to_s.empty?

    # --- tabconfigure/tabcget state ---
    notebook.tabconfigure(tab2, state: "disabled")
    state = notebook.tabcget(tab2, :state)
    errors << "tabcget state disabled failed: got #{state.inspect}" unless state == "disabled"

    notebook.tabconfigure(tab2, state: "normal")
    state = notebook.tabcget(tab2, :state)
    errors << "tabcget state normal failed: got #{state.inspect}" unless state == "normal"

    # --- tabconfigure/tabcget underline ---
    notebook.tabconfigure(tab1, underline: 0)
    underline = notebook.tabcget(tab1, :underline)
    errors << "tabcget underline failed: got #{underline.inspect}" unless underline.to_i == 0

    # --- tabconfigure/tabcget compound ---
    notebook.tabconfigure(tab1, compound: "left")
    compound = notebook.tabcget(tab1, :compound)
    errors << "tabcget compound failed: got #{compound.inspect}" unless compound == "left"

    # --- tabconfiginfo returns array with option details ---
    info = notebook.tabconfiginfo(tab1, :text)
    errors << "tabconfiginfo failed: got #{info.inspect}" unless info.is_a?(Array) && info[0] == "text"

    # --- current_tabconfiginfo returns hash ---
    current = notebook.current_tabconfiginfo(tab1, :text)
    errors << "current_tabconfiginfo failed: got #{current.inspect}" unless current.is_a?(Hash) && current["text"] == "Settings"

    # --- Test hidden tab state ---
    notebook.tabconfigure(tab3, state: "hidden")
    state = notebook.tabcget(tab3, :state)
    errors << "tabcget state hidden failed: got #{state.inspect}" unless state == "hidden"

    notebook.tabconfigure(tab3, state: "normal")

    # ========================================
    # Additional coverage
    # ========================================

    # --- Class method style ---
    style_str = Tk::Tile::TNotebook.style
    errors << "class style() failed" unless style_str == 'TNotebook'

    style_custom = Tk::Tile::TNotebook.style('Custom')
    errors << "class style('Custom') failed" unless style_custom == 'TNotebook.Custom'

    # --- Notebook alias ---
    errors << "Notebook alias missing" unless Tk::Tile::Notebook == Tk::Tile::TNotebook

    # --- selected (returns currently selected tab widget) ---
    notebook.select(tab1)
    sel = notebook.selected
    errors << "selected failed" if sel.nil?

    # --- tabcget_tkstring ---
    text_str = notebook.tabcget_tkstring(tab1, :text)
    errors << "tabcget_tkstring failed" if text_str.nil?

    # --- forget (removes tab completely) ---
    notebook.forget(tab4)
    errors << "forget failed" unless notebook.tabs.size == 3

    # --- enable_traversal (keyboard navigation) ---
    begin
      notebook.enable_traversal
    rescue => e
      errors << "enable_traversal failed: #{e.message}"
    end

    # --- tabconfiginfo all options ---
    all_info = notebook.tabconfiginfo(tab1)
    errors << "tabconfiginfo all failed" unless all_info.is_a?(Array) && all_info.size > 0

    # --- current_tabconfiginfo all options ---
    all_current = notebook.current_tabconfiginfo(tab1)
    errors << "current_tabconfiginfo all failed" unless all_current.is_a?(Hash) && all_current.size > 0

    raise "TNotebook test failures:\n  " + errors.join("\n  ") unless errors.empty?
  end
end
