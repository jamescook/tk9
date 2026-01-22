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

  # ---------------------------------------------------------
  # value/value=/clear - Simple content access
  # ---------------------------------------------------------

  def test_text_value_accessors
    assert_tk_app("Text value accessors", method(:value_accessors_app))
  end

  def value_accessors_app
    require 'tk'
    require 'tk/text'

    errors = []

    text = TkText.new(root, width: 40, height: 10)
    text.pack

    # value= sets content, replacing everything
    text.value = "Hello World"
    errors << "value= failed" unless text.value == "Hello World"

    # value returns content without trailing newline
    text.value = "Line 1\nLine 2\nLine 3"
    errors << "multiline value failed" unless text.value == "Line 1\nLine 2\nLine 3"

    # clear removes all content
    text.clear
    errors << "clear failed" unless text.value == ""

    # erase is alias for clear
    text.value = "Some text"
    text.erase
    errors << "erase alias failed" unless text.value == ""

    raise errors.join("\n") unless errors.empty?
  end

  # ---------------------------------------------------------
  # Marks - Named positions in text
  # ---------------------------------------------------------

  def test_text_marks
    assert_tk_app("Text marks", method(:marks_app))
  end

  def marks_app
    require 'tk'
    require 'tk/text'

    errors = []

    text = TkText.new(root, width: 40, height: 10)
    text.pack

    text.value = "Line 1\nLine 2\nLine 3"

    # mark_set creates a named position
    text.mark_set("mymark", "2.0")

    # mark_names lists all marks
    names = text.mark_names
    errors << "mark_names should include 'mymark'" unless names.map(&:to_s).include?("mymark")
    errors << "mark_names should include 'insert'" unless names.map(&:to_s).include?("insert")

    # mark_gravity controls which side mark sticks to
    text.mark_gravity("mymark", "left")
    gravity = text.mark_gravity("mymark")
    errors << "mark_gravity get failed, got '#{gravity}'" unless gravity == "left"

    text.mark_gravity("mymark", "right")
    gravity = text.mark_gravity("mymark")
    errors << "mark_gravity set right failed" unless gravity == "right"

    # mark_next/mark_previous navigate between marks
    text.mark_set("mark_a", "1.0")
    text.mark_set("mark_b", "2.0")
    text.mark_set("mark_c", "3.0")

    next_mark = text.mark_next("1.0")
    errors << "mark_next failed" if next_mark.nil?

    prev_mark = text.mark_previous("end")
    errors << "mark_previous failed" if prev_mark.nil?

    # set_insert moves the insert cursor
    text.set_insert("2.3")
    # Verify by checking index of insert mark
    insert_idx = text.index("insert")
    errors << "set_insert failed, got '#{insert_idx}'" unless insert_idx.to_s == "2.3"

    # mark_unset removes a mark
    text.mark_unset("mymark")
    names_after = text.mark_names.map(&:to_s)
    errors << "mark_unset failed" if names_after.include?("mymark")

    raise errors.join("\n") unless errors.empty?
  end

  # ---------------------------------------------------------
  # Undo/Redo operations
  # ---------------------------------------------------------

  def test_text_undo_redo
    assert_tk_app("Text undo/redo", method(:undo_redo_app))
  end

  def undo_redo_app
    require 'tk'
    require 'tk/text'

    errors = []

    text = TkText.new(root, width: 40, height: 10, undo: true)
    text.pack

    # Start fresh
    text.edit_reset

    # Make some edits
    text.insert("end", "First")
    text.edit_separator  # Force undo boundary
    text.insert("end", " Second")
    text.edit_separator
    text.insert("end", " Third")

    errors << "initial content wrong" unless text.value == "First Second Third"

    # modified? should be true after edits
    errors << "modified? should be true" unless text.modified?

    # Undo last edit
    text.edit_undo
    errors << "undo failed, got '#{text.value}'" unless text.value == "First Second"

    # Undo again
    text.edit_undo
    errors << "second undo failed" unless text.value == "First"

    # Redo
    text.edit_redo
    errors << "redo failed" unless text.value == "First Second"

    # Reset clears undo stack
    text.edit_reset
    # After reset, undo should raise or do nothing
    begin
      text.edit_undo
      # If we get here without error, the text should be unchanged
      # (undo stack was cleared)
    rescue TclTkLib::TclError
      # Expected - nothing to undo
    end

    # Can set modified flag explicitly
    text.modified = false
    errors << "modified= false failed" if text.modified?

    raise errors.join("\n") unless errors.empty?
  end

  # ---------------------------------------------------------
  # Compare - Compare two indices
  # ---------------------------------------------------------

  def test_text_compare
    assert_tk_app("Text compare", method(:compare_app))
  end

  def compare_app
    require 'tk'
    require 'tk/text'

    errors = []

    text = TkText.new(root, width: 40, height: 10)
    text.pack

    text.value = "Line 1\nLine 2\nLine 3"

    # compare returns boolean for index comparisons
    errors << "1.0 < 2.0 should be true" unless text.compare("1.0", "<", "2.0")
    errors << "2.0 > 1.0 should be true" unless text.compare("2.0", ">", "1.0")
    errors << "1.0 == 1.0 should be true" unless text.compare("1.0", "==", "1.0")
    errors << "1.0 != 2.0 should be true" unless text.compare("1.0", "!=", "2.0")
    errors << "1.0 <= 1.0 should be true" unless text.compare("1.0", "<=", "1.0")
    errors << "2.0 >= 1.0 should be true" unless text.compare("2.0", ">=", "1.0")

    # Negative cases
    errors << "2.0 < 1.0 should be false" if text.compare("2.0", "<", "1.0")
    errors << "1.0 > 2.0 should be false" if text.compare("1.0", ">", "2.0")
    errors << "1.0 == 2.0 should be false" if text.compare("1.0", "==", "2.0")

    raise errors.join("\n") unless errors.empty?
  end

  # ---------------------------------------------------------
  # Index arithmetic with IndexString
  # ---------------------------------------------------------

  def test_text_index_arithmetic
    assert_tk_app("Text index arithmetic", method(:index_arithmetic_app))
  end

  def index_arithmetic_app
    require 'tk'
    require 'tk/text'

    errors = []

    text = TkText.new(root, width: 40, height: 10)
    text.pack

    text.value = "Hello World\nSecond Line\nThird Line"

    # Get an index
    idx = text.index("1.0")
    errors << "index should return IndexString" unless idx.is_a?(Tk::Text::IndexString)

    # + with chars (digit prefix - uses ' + ' separator)
    idx_plus = idx + "5 chars"
    resolved = text.index(idx_plus)
    errors << "+ chars failed, got '#{resolved}'" unless resolved.to_s == "1.5"

    # + with non-digit modifier (uses ' ' separator, else branch)
    idx_plus_mod = idx + "lineend"
    resolved = text.index(idx_plus_mod)
    errors << "+ lineend failed, got '#{resolved}'" unless resolved.to_s == "1.11"

    # - with chars (digit prefix - uses ' - ' separator)
    idx2 = text.index("1.5")
    idx_minus = idx2 - "3 chars"
    resolved = text.index(idx_minus)
    errors << "- chars failed, got '#{resolved}'" unless resolved.to_s == "1.2"

    # - with "- N" pattern (elsif branch: "- 5 chars" -> double negative, goes forward)
    idx3 = text.index("1.0")
    idx_double_neg = idx3 - "- 5 chars"
    resolved = text.index(idx_double_neg)
    errors << "- double negative failed, got '#{resolved}'" unless resolved.to_s == "1.5"

    # - with non-digit modifier (else branch)
    idx4 = text.index("1.5")
    idx_minus_mod = idx4 - "linestart"
    # "1.5 linestart" should resolve to beginning of line
    resolved = text.index(idx_minus_mod)
    errors << "- linestart failed, got '#{resolved}'" unless resolved.to_s == "1.0"

    # + with numeric (shorthand for chars, positive - else branch)
    idx_num = idx + 3
    resolved = text.index(idx_num)
    errors << "+ numeric failed" unless resolved.to_s == "1.3"

    # + with negative numeric (if branch in chars method)
    idx5 = text.index("1.5")
    idx_neg = idx5 + (-3)
    resolved = text.index(idx_neg)
    errors << "+ negative numeric failed, got '#{resolved}'" unless resolved.to_s == "1.2"

    # display_chars - positive (else branch)
    idx_dc = idx.display_chars(5)
    resolved = text.index(idx_dc)
    errors << "display_chars positive failed, got '#{resolved}'" unless resolved.to_s == "1.5"

    # display_chars - negative (if branch)
    idx_dc_neg = text.index("1.5").display_chars(-3)
    resolved = text.index(idx_dc_neg)
    errors << "display_chars negative failed, got '#{resolved}'" unless resolved.to_s == "1.2"

    # display_char alias
    idx_dc_alias = idx.display_char(2)
    errors << "display_char alias failed" unless idx_dc_alias.to_s.include?("display chars")

    # any_chars - positive (else branch)
    idx_ac = idx.any_chars(5)
    resolved = text.index(idx_ac)
    errors << "any_chars positive failed, got '#{resolved}'" unless resolved.to_s == "1.5"

    # any_chars - negative (if branch)
    idx_ac_neg = text.index("1.5").any_chars(-3)
    resolved = text.index(idx_ac_neg)
    errors << "any_chars negative failed, got '#{resolved}'" unless resolved.to_s == "1.2"

    # indices - positive (else branch)
    idx_ind = idx.indices(5)
    resolved = text.index(idx_ind)
    errors << "indices positive failed, got '#{resolved}'" unless resolved.to_s == "1.5"

    # indices - negative (if branch)
    idx_ind_neg = text.index("1.5").indices(-3)
    resolved = text.index(idx_ind_neg)
    errors << "indices negative failed, got '#{resolved}'" unless resolved.to_s == "1.2"

    # display_indices - positive (else branch)
    idx_di = idx.display_indices(5)
    resolved = text.index(idx_di)
    errors << "display_indices positive failed, got '#{resolved}'" unless resolved.to_s == "1.5"

    # display_indices - negative (if branch)
    idx_di_neg = text.index("1.5").display_indices(-3)
    resolved = text.index(idx_di_neg)
    errors << "display_indices negative failed, got '#{resolved}'" unless resolved.to_s == "1.2"

    # any_indices - positive (else branch)
    idx_ai = idx.any_indices(5)
    resolved = text.index(idx_ai)
    errors << "any_indices positive failed, got '#{resolved}'" unless resolved.to_s == "1.5"

    # any_indices - negative (if branch)
    idx_ai_neg = text.index("1.5").any_indices(-3)
    resolved = text.index(idx_ai_neg)
    errors << "any_indices negative failed, got '#{resolved}'" unless resolved.to_s == "1.2"

    # lines - positive (else branch, already covered but explicit)
    idx_lines = idx.lines(1)
    resolved = text.index(idx_lines)
    errors << "lines(1) failed, got '#{resolved}'" unless resolved.to_s == "2.0"

    # lines - negative (if branch)
    idx_lines_neg = text.index("2.0").lines(-1)
    resolved = text.index(idx_lines_neg)
    errors << "lines negative failed, got '#{resolved}'" unless resolved.to_s == "1.0"

    # display_lines requires widget to be rendered (Tk.update)
    Tk.update

    # display_lines - positive (else branch)
    idx_dl = idx.display_lines(1)
    resolved = text.index(idx_dl)
    errors << "display_lines positive failed, got '#{resolved}'" unless resolved.to_s == "2.0"

    # display_lines - negative (if branch)
    idx_dl_neg = text.index("2.0").display_lines(-1)
    resolved = text.index(idx_dl_neg)
    errors << "display_lines negative failed, got '#{resolved}'" unless resolved.to_s == "1.0"

    # display_linestart - beginning of display line
    idx_dls = text.index("1.5").display_linestart
    resolved = text.index(idx_dls)
    errors << "display_linestart failed, got '#{resolved}'" unless resolved.to_s == "1.0"

    # display_lineend - end of display line
    idx_dle = text.index("1.0").display_lineend
    resolved = text.index(idx_dle)
    errors << "display_lineend failed, got '#{resolved}'" unless resolved.to_s == "1.11"

    # display_wordstart - beginning of display word
    idx_dws = text.index("1.3").display_wordstart
    resolved = text.index(idx_dws)
    errors << "display_wordstart failed, got '#{resolved}'" unless resolved.to_s == "1.0"

    # display_wordend - end of display word
    idx_dwe = text.index("1.0").display_wordend
    resolved = text.index(idx_dwe)
    errors << "display_wordend failed, got '#{resolved}'" unless resolved.to_s == "1.5"

    # lineend modifier
    idx_end = idx.lineend
    resolved = text.index(idx_end)
    errors << "lineend failed, got '#{resolved}'" unless resolved.to_s == "1.11"

    # linestart modifier
    idx_mid = text.index("1.5")
    idx_start = idx_mid.linestart
    resolved = text.index(idx_start)
    errors << "linestart failed" unless resolved.to_s == "1.0"

    # wordend modifier
    idx_word = text.index("1.0")
    idx_wend = idx_word.wordend
    resolved = text.index(idx_wend)
    errors << "wordend failed, got '#{resolved}'" unless resolved.to_s == "1.5"  # "Hello" ends at 1.5

    # wordstart modifier
    idx_mid = text.index("1.3")
    idx_wstart = idx_mid.wordstart
    resolved = text.index(idx_wstart)
    errors << "wordstart failed" unless resolved.to_s == "1.0"

    # IndexString.at for mouse coordinates
    idx_at = Tk::Text::IndexString.at(10, 10)
    errors << "IndexString.at failed" unless idx_at.to_s == "@10,10"

    raise errors.join("\n") unless errors.empty?
  end

  # ---------------------------------------------------------
  # Tag operations - add/delete/raise/lower
  # ---------------------------------------------------------

  def test_text_tag_operations
    assert_tk_app("Text tag operations", method(:tag_operations_app))
  end

  def tag_operations_app
    require 'tk'
    require 'tk/text'

    errors = []

    text = TkText.new(root, width: 40, height: 10)
    text.pack

    text.value = "Hello World Test String"

    # tag_add applies a tag to a range
    text.tag_add("mytag", "1.0", "1.5")
    ranges = text.tag_ranges("mytag")
    errors << "tag_add failed" if ranges.empty?

    # tag_remove removes tag from a range (but doesn't delete the tag)
    text.tag_remove("mytag", "1.0", "1.5")
    ranges = text.tag_ranges("mytag")
    errors << "tag_remove failed" unless ranges.empty?

    # Tag still exists even with no ranges
    text.tag_configure("mytag", foreground: "red")
    names = text.tag_names
    errors << "tag should still exist after remove" unless names.map(&:to_s).include?("mytag")

    # tag_delete completely removes the tag
    text.tag_delete("mytag")
    names = text.tag_names
    errors << "tag_delete failed" if names.map(&:to_s).include?("mytag")

    # tag_raise/tag_lower change tag priority
    text.tag_add("tag1", "1.0", "1.10")
    text.tag_add("tag2", "1.0", "1.10")
    text.tag_configure("tag1", foreground: "red")
    text.tag_configure("tag2", foreground: "blue")

    # Raise tag1 above tag2
    text.tag_raise("tag1", "tag2")
    # Lower tag1 below tag2
    text.tag_lower("tag1", "tag2")
    # No easy way to verify priority, just ensure no errors

    # tag_nextrange finds next occurrence of tag
    text.tag_add("findme", "1.6", "1.11")  # "World"
    next_range = text.tag_nextrange("findme", "1.0")
    errors << "tag_nextrange failed" if next_range.empty?
    errors << "tag_nextrange start wrong" unless next_range[0].to_s == "1.6"

    # tag_prevrange finds previous occurrence
    prev_range = text.tag_prevrange("findme", "end")
    errors << "tag_prevrange failed" if prev_range.empty?

    raise errors.join("\n") unless errors.empty?
  end

  # ---------------------------------------------------------
  # Search operations
  # ---------------------------------------------------------

  def test_text_search_operations
    assert_tk_app("Text search operations", method(:search_operations_app))
  end

  def search_operations_app
    require 'tk'
    require 'tk/text'

    errors = []

    text = TkText.new(root, width: 40, height: 10)
    text.pack

    text.value = "Hello World\nHello Again\nGoodbye World"

    # search finds first occurrence
    pos = text.search("Hello", "1.0")
    errors << "search failed" unless pos.to_s == "1.0"

    # search with stop index
    pos = text.search("Hello", "1.1", "2.0")
    errors << "search with stop should find nothing" unless pos.to_s.empty?

    # search_with_length returns [index, length, match]
    result = text.search_with_length("World", "1.0")
    errors << "search_with_length index wrong" unless result[0].to_s == "1.6"
    errors << "search_with_length length wrong" unless result[1] == 5

    # rsearch searches backwards
    pos = text.rsearch("Hello", "end")
    errors << "rsearch failed, got '#{pos}'" unless pos.to_s == "2.0"

    # search with regexp
    pos = text.search(/W.*d/, "1.0")
    errors << "regexp search failed" unless pos.to_s == "1.6"

    # tksearch uses Tcl's search (supports more options)
    pos = text.tksearch(["nocase"], "HELLO", "1.0")
    errors << "tksearch nocase failed" unless pos.to_s == "1.0"

    # tksearch with regexp option
    pos = text.tksearch(["regexp"], "^Hello", "1.0")
    errors << "tksearch regexp failed, got '#{pos}'" unless pos.to_s == "1.0"

    raise errors.join("\n") unless errors.empty?
  end

  # ---------------------------------------------------------
  # Count and bbox
  # ---------------------------------------------------------

  def test_text_count_bbox
    assert_tk_app("Text count and bbox", method(:count_bbox_app))
  end

  def count_bbox_app
    require 'tk'
    require 'tk/text'

    errors = []

    text = TkText.new(root, width: 40, height: 10)
    text.pack

    text.value = "Line 1\nLine 2\nLine 3"

    # count returns number of units between indices
    char_count = text.count("1.0", "1.6", :chars)
    errors << "count chars failed, got #{char_count}" unless char_count == 6

    line_count = text.count("1.0", "3.0", :lines)
    errors << "count lines failed, got #{line_count}" unless line_count == 2

    # count_info returns hash with multiple counts
    info = text.count_info("1.0", "end")
    errors << "count_info should have :chars" unless info.key?(:chars)
    errors << "count_info should have :lines" unless info.key?(:lines)

    # bbox returns bounding box [x, y, width, height] for a character
    # Need to update display first
    Tk.update
    bbox = text.bbox("1.0")
    if bbox  # May be nil if not visible
      errors << "bbox should return 4 elements" unless bbox.length == 4
    end

    # dlineinfo returns display line info [x, y, width, height, baseline]
    dinfo = text.dlineinfo("1.0")
    if dinfo  # May be nil if not visible
      errors << "dlineinfo should return 5 elements" unless dinfo.length == 5
    end

    raise errors.join("\n") unless errors.empty?
  end

  # ---------------------------------------------------------
  # Tag config methods (tag_cget variants, tag_configinfo)
  # ---------------------------------------------------------

  def test_text_tag_config_methods
    assert_tk_app("Text tag config methods", method(:tag_config_methods_app))
  end

  def tag_config_methods_app
    require 'tk'
    require 'tk/text'

    errors = []

    text = TkText.new(root, width: 40, height: 10)
    text.pack

    text.value = "Hello World"
    text.tag_add("testtag", "1.0", "1.5")
    text.tag_configure("testtag", foreground: "red", background: "yellow", underline: true)

    # tag_cget - returns typed value
    fg = text.tag_cget("testtag", :foreground)
    errors << "tag_cget foreground failed, got '#{fg}'" unless fg == "red"

    # tag_cget_tkstring - returns raw Tcl string
    fg_str = text.tag_cget_tkstring("testtag", :foreground)
    errors << "tag_cget_tkstring failed" unless fg_str.is_a?(String)
    errors << "tag_cget_tkstring value wrong" unless fg_str == "red"

    # tag_cget_strict - strict typed value
    ul = text.tag_cget_strict("testtag", :underline)
    errors << "tag_cget_strict failed" unless ul == true

    # tag_configinfo - returns config list for one option
    info = text.tag_configinfo("testtag", :foreground)
    errors << "tag_configinfo should return array" unless info.is_a?(Array)
    errors << "tag_configinfo option name wrong" unless info[0] == "foreground"

    # tag_configinfo - returns all options when no slot given
    all_info = text.tag_configinfo("testtag")
    errors << "tag_configinfo all should return array" unless all_info.is_a?(Array)
    errors << "tag_configinfo all should have multiple items" unless all_info.length > 1

    # current_tag_configinfo - returns hash of current values
    current = text.current_tag_configinfo("testtag", :foreground)
    errors << "current_tag_configinfo should return hash" unless current.is_a?(Hash)
    errors << "current_tag_configinfo should have foreground" unless current.key?("foreground")

    # current_tag_configinfo - all options
    current_all = text.current_tag_configinfo("testtag")
    errors << "current_tag_configinfo all should return hash" unless current_all.is_a?(Hash)
    errors << "current_tag_configinfo all should have foreground" unless current_all.key?("foreground")
    errors << "current_tag_configinfo all should have background" unless current_all.key?("background")

    raise errors.join("\n") unless errors.empty?
  end

  # ---------------------------------------------------------
  # Embedded window config methods
  # ---------------------------------------------------------

  def test_text_window_config_methods
    assert_tk_app("Text window config methods", method(:window_config_methods_app))
  end

  def window_config_methods_app
    require 'tk'
    require 'tk/text'
    require 'tk/textwindow'

    errors = []

    text = TkText.new(root, width: 40, height: 10)
    text.pack

    text.value = "Before  After"

    # Create a button to embed
    btn = TkButton.new(text, text: "Click Me")

    # Embed the window using TkTextWindow
    TkTextWindow.new(text, "1.7", window: btn, padx: 5, pady: 3)

    # window_cget - get option value
    win = text.window_cget("1.7", :window)
    errors << "window_cget window failed" if win.nil?

    padx = text.window_cget("1.7", :padx)
    errors << "window_cget padx failed, got '#{padx}'" unless padx.to_i == 5

    # window_cget_tkstring - raw Tcl string
    padx_str = text.window_cget_tkstring("1.7", :padx)
    errors << "window_cget_tkstring failed" unless padx_str.to_s == "5"

    # window_cget_strict - strict typed value
    pady = text.window_cget_strict("1.7", :pady)
    errors << "window_cget_strict failed" unless pady.to_i == 3

    # window_configure - set options
    text.window_configure("1.7", padx: 10)
    new_padx = text.window_cget("1.7", :padx)
    errors << "window_configure failed" unless new_padx.to_i == 10

    # window_configure with hash
    text.window_configure("1.7", { padx: 8, pady: 4 })
    errors << "window_configure hash padx failed" unless text.window_cget("1.7", :padx).to_i == 8
    errors << "window_configure hash pady failed" unless text.window_cget("1.7", :pady).to_i == 4

    # window_configinfo - returns config list for one option
    info = text.window_configinfo("1.7", :padx)
    errors << "window_configinfo should return array" unless info.is_a?(Array)
    errors << "window_configinfo option name wrong" unless info[0] == "padx"

    # window_configinfo - all options
    all_info = text.window_configinfo("1.7")
    errors << "window_configinfo all should return array" unless all_info.is_a?(Array)
    errors << "window_configinfo all should have multiple items" unless all_info.length > 1

    # current_window_configinfo - returns hash of current values
    current = text.current_window_configinfo("1.7", :padx)
    errors << "current_window_configinfo should return hash" unless current.is_a?(Hash)
    errors << "current_window_configinfo should have padx" unless current.key?("padx")

    # current_window_configinfo - all options
    current_all = text.current_window_configinfo("1.7")
    errors << "current_window_configinfo all should return hash" unless current_all.is_a?(Hash)

    # window_names - list embedded windows
    names = text.window_names
    errors << "window_names should not be empty" if names.empty?

    raise errors.join("\n") unless errors.empty?
  end

  # ---------------------------------------------------------
  # Tag/mark lookup via @tags instance variable
  # ---------------------------------------------------------

  def test_text_tagid2obj_lookup
    assert_tk_app("Text tagid2obj lookup", method(:tagid2obj_lookup_app))
  end

  def tagid2obj_lookup_app
    require 'tk'
    require 'tk/text'
    require 'tk/texttag'
    require 'tk/textmark'

    errors = []

    text = TkText.new(root, width: 40, height: 10)
    text.pack
    text.value = "Hello World"

    # Create a tag
    tag = TkTextTag.new(text, "1.0", "1.5")
    tag_id = tag.id.to_s

    # Create a mark
    mark = TkTextMark.new(text, "1.5")
    mark_id = mark.id.to_s

    # Verify tagid2obj returns the Ruby object
    found_tag = text.tagid2obj(tag_id)
    errors << "tagid2obj should return TkTextTag, got #{found_tag.class}" unless found_tag.kind_of?(TkTextTag)

    found_mark = text.tagid2obj(mark_id)
    errors << "tagid2obj should return TkTextMark, got #{found_mark.class}" unless found_mark.kind_of?(TkTextMark)

    # Verify class-level id2obj delegates correctly
    found_tag2 = TkTextTag.id2obj(text, tag_id)
    errors << "TkTextTag.id2obj should return same object" unless found_tag2 == found_tag

    found_mark2 = TkTextMark.id2obj(text, mark_id)
    errors << "TkTextMark.id2obj should return same object" unless found_mark2 == found_mark

    # Unknown ID should return the string
    unknown = text.tagid2obj("nonexistent")
    errors << "tagid2obj should return string for unknown ID" unless unknown == "nonexistent"

    raise errors.join("\n") unless errors.empty?
  end
end
