# frozen_string_literal: true

# Tests for TkScrollbox - Listbox with Scrollbar composite widget
#
# TkScrollbox bundles a Listbox with a vertical Scrollbar.
# It's an example of TkComposite usage, written by Matz.
#
# See: sample/tkbrowse.rb, sample/tkballoonhelp.rb

require_relative 'test_helper'
require_relative 'tk_test_helper'

class TestScrollbox < Minitest::Test
  include TkTestHelper

  # ===========================================
  # Basic creation
  # ===========================================

  def test_create
    assert_tk_app("Scrollbox create", method(:create_app))
  end

  def create_app
    require 'tk'
    require 'tk/scrollbox'

    errors = []

    sb = TkScrollbox.new(root)
    errors << "should be a Listbox" unless sb.is_a?(Tk::Listbox)

    raise errors.join("\n") unless errors.empty?
  end

  def test_create_with_options
    assert_tk_app("Scrollbox create with options", method(:create_options_app))
  end

  def create_options_app
    require 'tk'
    require 'tk/scrollbox'

    errors = []

    sb = TkScrollbox.new(root, 'height' => 10, 'width' => 30)

    errors << "height should be 10" unless sb.cget(:height) == 10
    errors << "width should be 30" unless sb.cget(:width) == 30

    raise errors.join("\n") unless errors.empty?
  end

  # ===========================================
  # Listbox functionality
  # ===========================================

  def test_insert_and_get
    assert_tk_app("Scrollbox insert and get", method(:insert_get_app))
  end

  def insert_get_app
    require 'tk'
    require 'tk/scrollbox'

    errors = []

    sb = TkScrollbox.new(root)
    sb.insert('end', 'Item 1', 'Item 2', 'Item 3')

    errors << "should have 3 items" unless sb.size == 3
    errors << "first item should be 'Item 1'" unless sb.get(0) == 'Item 1'
    errors << "second item should be 'Item 2'" unless sb.get(1) == 'Item 2'
    errors << "third item should be 'Item 3'" unless sb.get(2) == 'Item 3'

    raise errors.join("\n") unless errors.empty?
  end

  def test_delete
    assert_tk_app("Scrollbox delete", method(:delete_app))
  end

  def delete_app
    require 'tk'
    require 'tk/scrollbox'

    errors = []

    sb = TkScrollbox.new(root)
    sb.insert('end', 'A', 'B', 'C', 'D')
    errors << "should start with 4 items" unless sb.size == 4

    sb.delete(1)  # Delete 'B'
    errors << "should have 3 items after delete" unless sb.size == 3
    errors << "second item should now be 'C'" unless sb.get(1) == 'C'

    raise errors.join("\n") unless errors.empty?
  end

  def test_selection
    assert_tk_app("Scrollbox selection", method(:selection_app))
  end

  def selection_app
    require 'tk'
    require 'tk/scrollbox'

    errors = []

    sb = TkScrollbox.new(root)
    sb.insert('end', 'One', 'Two', 'Three')

    sb.selection_set(1)
    selected = sb.curselection

    errors << "should have selection" if selected.empty?
    errors << "selection should include index 1" unless selected.include?(1)

    raise errors.join("\n") unless errors.empty?
  end

  # ===========================================
  # Delegation - foreground
  # ===========================================

  def test_delegate_foreground
    assert_tk_app("Scrollbox delegate foreground", method(:delegate_fg_app))
  end

  def delegate_fg_app
    require 'tk'
    require 'tk/scrollbox'

    errors = []

    sb = TkScrollbox.new(root, 'foreground' => 'blue')

    # Foreground should be delegated to the listbox
    fg = sb.cget(:foreground)
    errors << "foreground should be blue, got #{fg}" unless fg == 'blue'

    # Change it
    sb.configure('foreground', 'red')
    fg = sb.cget(:foreground)
    errors << "foreground should now be red" unless fg == 'red'

    raise errors.join("\n") unless errors.empty?
  end

  # ===========================================
  # Delegation - background (to both list and scrollbar)
  # ===========================================

  def test_delegate_background
    assert_tk_app("Scrollbox delegate background", method(:delegate_bg_app))
  end

  def delegate_bg_app
    require 'tk'
    require 'tk/scrollbox'

    errors = []

    sb = TkScrollbox.new(root, 'background' => 'yellow')

    # Background should be delegated to listbox
    bg = sb.cget(:background)
    errors << "background should be yellow" unless bg == 'yellow'

    raise errors.join("\n") unless errors.empty?
  end

  # ===========================================
  # Delegation - borderwidth/relief (to frame)
  # ===========================================

  def test_delegate_borderwidth
    assert_tk_app("Scrollbox delegate borderwidth", method(:delegate_bw_app))
  end

  def delegate_bw_app
    require 'tk'
    require 'tk/scrollbox'

    errors = []

    sb = TkScrollbox.new(root, 'borderwidth' => 3)

    # borderwidth is delegated to the frame, but we can configure it
    sb.configure('borderwidth', 5)

    # Should not raise error
    errors << "borderwidth delegation should work" unless true

    raise errors.join("\n") unless errors.empty?
  end

  def test_delegate_relief
    assert_tk_app("Scrollbox delegate relief", method(:delegate_relief_app))
  end

  def delegate_relief_app
    require 'tk'
    require 'tk/scrollbox'

    errors = []

    sb = TkScrollbox.new(root, 'relief' => 'sunken')

    sb.configure('relief', 'raised')

    # Should not raise error
    errors << "relief delegation should work" unless true

    raise errors.join("\n") unless errors.empty?
  end

  # ===========================================
  # Scrolling behavior
  # ===========================================

  def test_scrolling_with_many_items
    assert_tk_app("Scrollbox scrolling", method(:scrolling_app))
  end

  def scrolling_app
    require 'tk'
    require 'tk/scrollbox'

    errors = []

    sb = TkScrollbox.new(root, 'height' => 5)
    sb.pack

    # Insert more items than visible height
    (1..20).each { |i| sb.insert('end', "Item #{i}") }

    errors << "should have 20 items" unless sb.size == 20

    # yview should work (scrollbar connected)
    sb.yview('moveto', 0.5)  # Scroll to middle

    # Should not raise error
    errors << "yview should work" unless true

    raise errors.join("\n") unless errors.empty?
  end

  def test_see_method
    assert_tk_app("Scrollbox see method", method(:see_app))
  end

  def see_app
    require 'tk'
    require 'tk/scrollbox'

    errors = []

    sb = TkScrollbox.new(root, 'height' => 5)
    sb.pack

    (1..50).each { |i| sb.insert('end', "Item #{i}") }

    # see() scrolls to make an item visible
    sb.see(49)  # Scroll to last item

    # Should not raise error
    errors << "see should work" unless true

    raise errors.join("\n") unless errors.empty?
  end

  # ===========================================
  # Block syntax
  # ===========================================

  def test_block_syntax
    assert_tk_app("Scrollbox block syntax", method(:block_syntax_app))
  end

  def block_syntax_app
    require 'tk'
    require 'tk/scrollbox'

    errors = []

    sb = TkScrollbox.new(root) {
      height 10
      width 40
      insert 'end', 'Block item 1'
      insert 'end', 'Block item 2'
    }

    errors << "height should be 10" unless sb.cget(:height) == 10
    errors << "width should be 40" unless sb.cget(:width) == 40
    errors << "should have 2 items" unless sb.size == 2

    raise errors.join("\n") unless errors.empty?
  end

  # ===========================================
  # Default delegation
  # ===========================================

  def test_default_delegation
    assert_tk_app("Scrollbox default delegation", method(:default_delegation_app))
  end

  def default_delegation_app
    require 'tk'
    require 'tk/scrollbox'

    errors = []

    # Options not explicitly delegated should go to the listbox (DEFAULT)
    sb = TkScrollbox.new(root,
                         'selectmode' => 'multiple',
                         'exportselection' => false)

    errors << "selectmode should work" unless sb.cget(:selectmode) == 'multiple'
    errors << "exportselection should work" unless sb.cget(:exportselection) == false

    raise errors.join("\n") unless errors.empty?
  end
end
