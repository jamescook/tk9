# frozen_string_literal: true

# Tests for TkcTag, TkcTagString, TkcTagAll, TkcTagCurrent, TkcGroup
# and the TkcTagAccess module
#
# See: https://www.tcl.tk/man/tcl8.6/TkCmd/canvas.htm

require_relative 'test_helper'
require_relative 'tk_test_helper'
require 'tk'

class TestTkcTag < Minitest::Test
  include TkTestHelper

  # --- TkcTag basic operations ---

  def test_tkctag_creation
    assert_tk_app("TkcTag creation", method(:app_tag_creation))
  end

  def app_tag_creation
    require 'tk'
    require 'tk/canvas'

    errors = []
    canvas = TkCanvas.new(root)

    tag = TkcTag.new(canvas)
    errors << "tag should be TkcTag, got #{tag.class}" unless tag.is_a?(TkcTag)
    errors << "tag should have id" if tag.id.nil? || tag.id.empty?

    raise errors.join("\n") unless errors.empty?
  end

  def test_tkctag_with_mode
    assert_tk_app("TkcTag creation with mode", method(:app_tag_with_mode))
  end

  def app_tag_with_mode
    require 'tk'
    require 'tk/canvas'

    errors = []
    canvas = TkCanvas.new(root)

    # Create an item first
    rect = TkcRectangle.new(canvas, 10, 10, 50, 50)

    # Create tag with 'withtag' mode
    tag = TkcTag.new(canvas, 'withtag', rect)
    found = tag.find
    errors << "tag should find rect, got #{found.inspect}" unless found.any? { |item| item == rect }

    raise errors.join("\n") unless errors.empty?
  end

  def test_tkctag_exist
    assert_tk_app("TkcTag exist?", method(:app_tag_exist))
  end

  def app_tag_exist
    require 'tk'
    require 'tk/canvas'

    errors = []
    canvas = TkCanvas.new(root)

    rect = TkcRectangle.new(canvas, 10, 10, 50, 50)
    tag = TkcTag.new(canvas, 'withtag', rect)

    errors << "tag should exist" unless tag.exist?

    # Delete the item
    rect.delete
    errors << "tag should not exist after item deleted" if tag.exist?

    raise errors.join("\n") unless errors.empty?
  end

  def test_tkctag_delete
    assert_tk_app("TkcTag delete", method(:app_tag_delete))
  end

  def app_tag_delete
    require 'tk'
    require 'tk/canvas'

    errors = []
    canvas = TkCanvas.new(root)

    rect = TkcRectangle.new(canvas, 10, 10, 50, 50)
    tag = TkcTag.new(canvas, 'withtag', rect)

    # Delete via tag
    result = tag.delete
    errors << "delete should return self" unless result == tag

    # Item should be gone
    all_items = canvas.find_all
    errors << "rect should be deleted" if all_items.include?(rect)

    raise errors.join("\n") unless errors.empty?
  end

  # --- TkcTag set_to_* methods ---

  def test_tkctag_set_to_all
    assert_tk_app("TkcTag set_to_all", method(:app_tag_set_to_all))
  end

  def app_tag_set_to_all
    require 'tk'
    require 'tk/canvas'

    errors = []
    canvas = TkCanvas.new(root)

    TkcRectangle.new(canvas, 10, 10, 50, 50)
    TkcOval.new(canvas, 60, 10, 100, 50)

    tag = TkcTag.new(canvas)
    result = tag.set_to_all

    errors << "set_to_all should return self" unless result == tag

    found = tag.find
    errors << "should find 2 items, got #{found.size}" unless found.size == 2

    raise errors.join("\n") unless errors.empty?
  end

  def test_tkctag_set_to_enclosed
    assert_tk_app("TkcTag set_to_enclosed", method(:app_tag_set_to_enclosed))
  end

  def app_tag_set_to_enclosed
    require 'tk'
    require 'tk/canvas'

    errors = []
    canvas = TkCanvas.new(root)

    # Create rect fully inside 0,0,100,100
    rect = TkcRectangle.new(canvas, 10, 10, 50, 50)
    # Create oval partially outside
    TkcOval.new(canvas, 80, 80, 150, 150)

    tag = TkcTag.new(canvas)
    tag.set_to_enclosed(0, 0, 100, 100)

    found = tag.find
    errors << "should find only rect (enclosed), got #{found.size} items" unless found.size == 1
    errors << "should find rect" unless found.include?(rect)

    raise errors.join("\n") unless errors.empty?
  end

  def test_tkctag_set_to_overlapping
    assert_tk_app("TkcTag set_to_overlapping", method(:app_tag_set_to_overlapping))
  end

  def app_tag_set_to_overlapping
    require 'tk'
    require 'tk/canvas'

    errors = []
    canvas = TkCanvas.new(root)

    rect = TkcRectangle.new(canvas, 10, 10, 50, 50)
    oval = TkcOval.new(canvas, 80, 80, 150, 150)
    # Line completely outside
    TkcLine.new(canvas, 200, 200, 300, 300)

    tag = TkcTag.new(canvas)
    tag.set_to_overlapping(0, 0, 100, 100)

    found = tag.find
    errors << "should find 2 overlapping items, got #{found.size}" unless found.size == 2
    errors << "should include rect" unless found.include?(rect)
    errors << "should include oval" unless found.include?(oval)

    raise errors.join("\n") unless errors.empty?
  end

  def test_tkctag_set_to_closest
    assert_tk_app("TkcTag set_to_closest", method(:app_tag_set_to_closest))
  end

  def app_tag_set_to_closest
    require 'tk'
    require 'tk/canvas'

    errors = []
    canvas = TkCanvas.new(root)

    rect = TkcRectangle.new(canvas, 10, 10, 20, 20)
    TkcOval.new(canvas, 100, 100, 120, 120)

    tag = TkcTag.new(canvas)
    tag.set_to_closest(15, 15)

    found = tag.find
    errors << "should find closest item (rect)" unless found.include?(rect)

    raise errors.join("\n") unless errors.empty?
  end

  def test_tkctag_set_to_above_below
    assert_tk_app("TkcTag set_to_above/below", method(:app_tag_above_below))
  end

  def app_tag_above_below
    require 'tk'
    require 'tk/canvas'

    errors = []
    canvas = TkCanvas.new(root)

    rect1 = TkcRectangle.new(canvas, 10, 10, 50, 50)
    rect2 = TkcRectangle.new(canvas, 20, 20, 60, 60)
    rect3 = TkcRectangle.new(canvas, 30, 30, 70, 70)

    # Tag items above rect1 (should get rect2)
    tag_above = TkcTag.new(canvas)
    tag_above.set_to_above(rect1)
    found_above = tag_above.find
    errors << "above rect1 should be rect2" unless found_above.include?(rect2)

    # Tag items below rect3 (should get rect2)
    tag_below = TkcTag.new(canvas)
    tag_below.set_to_below(rect3)
    found_below = tag_below.find
    errors << "below rect3 should be rect2" unless found_below.include?(rect2)

    raise errors.join("\n") unless errors.empty?
  end

  # --- TkcTagAccess methods on canvas items ---

  def test_item_addtag
    assert_tk_app("canvas item addtag", method(:app_item_addtag))
  end

  def app_item_addtag
    require 'tk'
    require 'tk/canvas'

    errors = []
    canvas = TkCanvas.new(root)

    rect = TkcRectangle.new(canvas, 10, 10, 50, 50)
    tag = TkcTag.new(canvas)

    result = rect.addtag(tag.id)
    errors << "addtag should return self" unless result == rect

    tags = rect.gettags
    errors << "item should have tag #{tag.id}" unless tags.any? { |t| t.id == tag.id || t.to_s == tag.id }

    raise errors.join("\n") unless errors.empty?
  end

  def test_item_bbox
    assert_tk_app("canvas item bbox", method(:app_item_bbox))
  end

  def app_item_bbox
    require 'tk'
    require 'tk/canvas'

    errors = []
    canvas = TkCanvas.new(root)

    rect = TkcRectangle.new(canvas, 10, 20, 50, 60)
    bbox = rect.bbox

    errors << "bbox should return array" unless bbox.is_a?(Array)
    errors << "bbox should have 4 elements, got #{bbox.size}" unless bbox.size == 4
    # Bbox values should be close to item coords
    errors << "bbox x1 should be ~10, got #{bbox[0]}" unless (bbox[0] - 10).abs <= 2
    errors << "bbox y1 should be ~20, got #{bbox[1]}" unless (bbox[1] - 20).abs <= 2

    raise errors.join("\n") unless errors.empty?
  end

  def test_item_coords
    assert_tk_app("canvas item coords", method(:app_item_coords))
  end

  def app_item_coords
    require 'tk'
    require 'tk/canvas'

    errors = []
    canvas = TkCanvas.new(root)

    rect = TkcRectangle.new(canvas, 10, 20, 50, 60)

    # Get coords
    coords = rect.coords
    errors << "coords should return [10, 20, 50, 60], got #{coords}" unless coords == [10.0, 20.0, 50.0, 60.0]

    # Set coords
    rect.coords(100, 100, 200, 200)
    new_coords = rect.coords
    errors << "new coords should be [100, 100, 200, 200], got #{new_coords}" unless new_coords == [100.0, 100.0, 200.0, 200.0]

    # Set via coords=
    rect.coords = [5, 5, 15, 15]
    final_coords = rect.coords
    errors << "final coords should be [5, 5, 15, 15], got #{final_coords}" unless final_coords == [5.0, 5.0, 15.0, 15.0]

    raise errors.join("\n") unless errors.empty?
  end

  def test_item_dtag
    assert_tk_app("canvas item dtag", method(:app_item_dtag))
  end

  def app_item_dtag
    require 'tk'
    require 'tk/canvas'

    errors = []
    canvas = TkCanvas.new(root)

    rect = TkcRectangle.new(canvas, 10, 10, 50, 50, tags: 'mytag')

    # Check tag exists
    tags_before = rect.gettags
    has_mytag = tags_before.any? { |t| t.to_s == 'mytag' || (t.respond_to?(:id) && t.id == 'mytag') }
    errors << "should have mytag before dtag" unless has_mytag

    # Remove tag
    result = rect.dtag('mytag')
    errors << "dtag should return self" unless result == rect

    tags_after = rect.gettags
    still_has = tags_after.any? { |t| t.to_s == 'mytag' || (t.respond_to?(:id) && t.id == 'mytag') }
    errors << "should not have mytag after dtag" if still_has

    raise errors.join("\n") unless errors.empty?
  end

  def test_item_find
    assert_tk_app("canvas item find", method(:app_item_find))
  end

  def app_item_find
    require 'tk'
    require 'tk/canvas'

    errors = []
    canvas = TkCanvas.new(root)

    rect = TkcRectangle.new(canvas, 10, 10, 50, 50)
    tag = TkcTag.new(canvas, 'withtag', rect)

    found = tag.find
    errors << "find should return array with rect" unless found.include?(rect)

    # list is alias
    listed = tag.list
    errors << "list should equal find" unless listed == found

    raise errors.join("\n") unless errors.empty?
  end

  def test_item_move
    assert_tk_app("canvas item move", method(:app_item_move))
  end

  def app_item_move
    require 'tk'
    require 'tk/canvas'

    errors = []
    canvas = TkCanvas.new(root)

    rect = TkcRectangle.new(canvas, 10, 10, 50, 50)

    result = rect.move(100, 50)
    errors << "move should return self" unless result == rect

    coords = rect.coords
    errors << "x1 should be 110, got #{coords[0]}" unless coords[0] == 110.0
    errors << "y1 should be 60, got #{coords[1]}" unless coords[1] == 60.0

    raise errors.join("\n") unless errors.empty?
  end

  def test_item_moveto
    assert_tk_app("canvas item moveto", method(:app_item_moveto))
  end

  def app_item_moveto
    require 'tk'
    require 'tk/canvas'

    errors = []
    canvas = TkCanvas.new(root)

    # Use outline width 0 to avoid bbox offset from default 1px outline
    rect = TkcRectangle.new(canvas, 10, 10, 50, 50, outline: '', width: 0)

    result = rect.moveto(200, 200)
    errors << "moveto should return self" unless result == rect

    coords = rect.coords
    # moveto positions bbox corner at specified location
    errors << "x1 should be 200, got #{coords[0]}" unless coords[0] == 200.0
    errors << "y1 should be 200, got #{coords[1]}" unless coords[1] == 200.0

    raise errors.join("\n") unless errors.empty?
  end

  def test_item_scale
    assert_tk_app("canvas item scale", method(:app_item_scale))
  end

  def app_item_scale
    require 'tk'
    require 'tk/canvas'

    errors = []
    canvas = TkCanvas.new(root)

    rect = TkcRectangle.new(canvas, 0, 0, 10, 10)

    result = rect.scale(0, 0, 2, 2)
    errors << "scale should return self" unless result == rect

    coords = rect.coords
    errors << "scaled x2 should be 20, got #{coords[2]}" unless coords[2] == 20.0
    errors << "scaled y2 should be 20, got #{coords[3]}" unless coords[3] == 20.0

    raise errors.join("\n") unless errors.empty?
  end

  def test_item_lower_raise
    assert_tk_app("canvas item lower/raise", method(:app_item_lower_raise))
  end

  def app_item_lower_raise
    require 'tk'
    require 'tk/canvas'

    errors = []
    canvas = TkCanvas.new(root)

    rect1 = TkcRectangle.new(canvas, 10, 10, 50, 50)
    rect2 = TkcRectangle.new(canvas, 20, 20, 60, 60)
    rect3 = TkcRectangle.new(canvas, 30, 30, 70, 70)

    # Lower rect3 below rect2
    result = rect3.lower(rect2)
    errors << "lower should return self" unless result == rect3

    # Raise rect1 above rect2
    result = rect1.raise(rect2)
    errors << "raise should return self" unless result == rect1

    raise errors.join("\n") unless errors.empty?
  end

  def test_item_itemtype
    assert_tk_app("canvas item itemtype", method(:app_item_itemtype))
  end

  def app_item_itemtype
    require 'tk'
    require 'tk/canvas'

    errors = []
    canvas = TkCanvas.new(root)

    rect = TkcRectangle.new(canvas, 10, 10, 50, 50)
    oval = TkcOval.new(canvas, 60, 60, 100, 100)
    line = TkcLine.new(canvas, 0, 0, 50, 50)

    # itemtype returns the Ruby class, not the Tcl type string
    errors << "rect type should be TkcRectangle, got #{rect.itemtype}" unless rect.itemtype == TkcRectangle
    errors << "oval type should be TkcOval, got #{oval.itemtype}" unless oval.itemtype == TkcOval
    errors << "line type should be TkcLine, got #{line.itemtype}" unless line.itemtype == TkcLine

    raise errors.join("\n") unless errors.empty?
  end

  # --- Logical operators ---

  def test_tag_logical_and
    assert_tk_app("TkcTag logical AND", method(:app_tag_logical_and))
  end

  def app_tag_logical_and
    require 'tk'
    require 'tk/canvas'

    errors = []
    canvas = TkCanvas.new(root)

    tag1 = TkcTagString.new(canvas, 'tag1')
    tag2 = TkcTagString.new(canvas, 'tag2')

    combined = tag1 & tag2
    errors << "& should return TkcTagString" unless combined.is_a?(TkcTagString)
    errors << "& path should be '(tag1)&&(tag2)', got #{combined.path}" unless combined.path == '(tag1)&&(tag2)'

    raise errors.join("\n") unless errors.empty?
  end

  def test_tag_logical_or
    assert_tk_app("TkcTag logical OR", method(:app_tag_logical_or))
  end

  def app_tag_logical_or
    require 'tk'
    require 'tk/canvas'

    errors = []
    canvas = TkCanvas.new(root)

    tag1 = TkcTagString.new(canvas, 'tag1')
    tag2 = TkcTagString.new(canvas, 'tag2')

    combined = tag1 | tag2
    errors << "| should return TkcTagString" unless combined.is_a?(TkcTagString)
    errors << "| path should be '(tag1)||(tag2)', got #{combined.path}" unless combined.path == '(tag1)||(tag2)'

    raise errors.join("\n") unless errors.empty?
  end

  def test_tag_logical_xor
    assert_tk_app("TkcTag logical XOR", method(:app_tag_logical_xor))
  end

  def app_tag_logical_xor
    require 'tk'
    require 'tk/canvas'

    errors = []
    canvas = TkCanvas.new(root)

    tag1 = TkcTagString.new(canvas, 'tag1')
    tag2 = TkcTagString.new(canvas, 'tag2')

    combined = tag1 ^ tag2
    errors << "^ should return TkcTagString" unless combined.is_a?(TkcTagString)
    errors << "^ path should be '(tag1)^(tag2)', got #{combined.path}" unless combined.path == '(tag1)^(tag2)'

    raise errors.join("\n") unless errors.empty?
  end

  def test_tag_logical_not
    assert_tk_app("TkcTag logical NOT", method(:app_tag_logical_not))
  end

  def app_tag_logical_not
    require 'tk'
    require 'tk/canvas'

    errors = []
    canvas = TkCanvas.new(root)

    tag = TkcTagString.new(canvas, 'mytag')

    negated = -tag
    errors << "-@ should return TkcTagString" unless negated.is_a?(TkcTagString)
    errors << "-@ path should be '!(mytag)', got #{negated.path}" unless negated.path == '!(mytag)'

    raise errors.join("\n") unless errors.empty?
  end

  # --- TkcTagString ---

  def test_tkctagstring_new
    assert_tk_app("TkcTagString.new", method(:app_tagstring_new))
  end

  def app_tagstring_new
    require 'tk'
    require 'tk/canvas'

    errors = []
    canvas = TkCanvas.new(root)

    tag = TkcTagString.new(canvas, 'myname')
    errors << "tag id should be 'myname', got #{tag.id}" unless tag.id == 'myname'
    errors << "tag path should be 'myname', got #{tag.path}" unless tag.path == 'myname'

    raise errors.join("\n") unless errors.empty?
  end

  def test_tkctagstring_reuse_existing
    assert_tk_app("TkcTagString reuses existing", method(:app_tagstring_reuse))
  end

  def app_tagstring_reuse
    require 'tk'
    require 'tk/canvas'

    errors = []
    canvas = TkCanvas.new(root)

    tag1 = TkcTagString.new(canvas, 'samename')
    tag2 = TkcTagString.new(canvas, 'samename')

    errors << "same name should return same object" unless tag1.equal?(tag2)

    raise errors.join("\n") unless errors.empty?
  end

  # --- TkcTagAll and TkcTagCurrent ---

  def test_tkctagall
    assert_tk_app("TkcTagAll", method(:app_tagall))
  end

  def app_tagall
    require 'tk'
    require 'tk/canvas'

    errors = []
    canvas = TkCanvas.new(root)

    TkcRectangle.new(canvas, 10, 10, 50, 50)
    TkcOval.new(canvas, 60, 60, 100, 100)

    all_tag = TkcTagAll.new(canvas)
    errors << "TkcTagAll id should be 'all', got #{all_tag.id}" unless all_tag.id == 'all'

    found = all_tag.find
    errors << "all tag should find 2 items, got #{found.size}" unless found.size == 2

    raise errors.join("\n") unless errors.empty?
  end

  def test_tkctagcurrent
    assert_tk_app("TkcTagCurrent", method(:app_tagcurrent))
  end

  def app_tagcurrent
    require 'tk'
    require 'tk/canvas'

    errors = []
    canvas = TkCanvas.new(root)

    current_tag = TkcTagCurrent.new(canvas)
    errors << "TkcTagCurrent id should be 'current', got #{current_tag.id}" unless current_tag.id == 'current'

    raise errors.join("\n") unless errors.empty?
  end

  # --- TkcGroup ---

  def test_tkcgroup_creation
    assert_tk_app("TkcGroup creation", method(:app_group_creation))
  end

  def app_group_creation
    require 'tk'
    require 'tk/canvas'

    errors = []
    canvas = TkCanvas.new(root)

    group = TkcGroup.new(canvas)
    errors << "group should be TkcGroup" unless group.is_a?(TkcGroup)
    errors << "group should have id" if group.id.nil? || group.id.empty?

    raise errors.join("\n") unless errors.empty?
  end

  def test_tkcgroup_with_items
    assert_tk_app("TkcGroup with items", method(:app_group_with_items))
  end

  def app_group_with_items
    require 'tk'
    require 'tk/canvas'

    errors = []
    canvas = TkCanvas.new(root)

    rect = TkcRectangle.new(canvas, 10, 10, 50, 50)
    oval = TkcOval.new(canvas, 60, 60, 100, 100)

    group = TkcGroup.new(canvas, rect, oval)
    found = group.find

    errors << "group should contain 2 items, got #{found.size}" unless found.size == 2
    errors << "group should contain rect" unless found.include?(rect)
    errors << "group should contain oval" unless found.include?(oval)

    raise errors.join("\n") unless errors.empty?
  end

  def test_tkcgroup_include_exclude
    assert_tk_app("TkcGroup include/exclude", method(:app_group_include_exclude))
  end

  def app_group_include_exclude
    require 'tk'
    require 'tk/canvas'

    errors = []
    canvas = TkCanvas.new(root)

    rect = TkcRectangle.new(canvas, 10, 10, 50, 50)
    oval = TkcOval.new(canvas, 60, 60, 100, 100)
    _line = TkcLine.new(canvas, 0, 0, 100, 100)  # Not included in group

    group = TkcGroup.new(canvas)

    # Include items (not line)
    result = group.include(rect, oval)
    errors << "include should return self" unless result == group

    found = group.find
    errors << "should have 2 items after include" unless found.size == 2

    # Exclude one
    result = group.exclude(oval)
    errors << "exclude should return self" unless result == group

    found = group.find
    errors << "should have 1 item after exclude, got #{found.size}" unless found.size == 1
    errors << "should still have rect" unless found.include?(rect)

    raise errors.join("\n") unless errors.empty?
  end

  # --- TkcTag.id2obj ---

  def test_tkctag_id2obj
    assert_tk_app("TkcTag.id2obj", method(:app_tag_id2obj))
  end

  def app_tag_id2obj
    require 'tk'
    require 'tk/canvas'

    errors = []
    canvas = TkCanvas.new(root)

    tag = TkcTag.new(canvas)
    tag_id = tag.id

    found = TkcTag.id2obj(canvas, tag_id)
    errors << "id2obj should return TkcTag" unless found.is_a?(TkcTag)
    errors << "id2obj should return same object" unless found == tag

    raise errors.join("\n") unless errors.empty?
  end

  # --- Binding methods ---

  def test_item_bind
    assert_tk_app("canvas item bind", method(:app_item_bind))
  end

  def app_item_bind
    require 'tk'
    require 'tk/canvas'

    errors = []
    canvas = TkCanvas.new(root)

    rect = TkcRectangle.new(canvas, 10, 10, 50, 50)

    # Binding callback - not invoked in this test, just checking binding creation
    result = rect.bind('ButtonPress-1') { }
    errors << "bind should return self" unless result == rect

    # Check binding exists
    info = rect.bindinfo('ButtonPress-1')
    errors << "bindinfo should return binding info" if info.nil? || info.empty?

    raise errors.join("\n") unless errors.empty?
  end

  def test_item_bind_append
    assert_tk_app("canvas item bind_append", method(:app_item_bind_append))
  end

  def app_item_bind_append
    require 'tk'
    require 'tk/canvas'

    errors = []
    canvas = TkCanvas.new(root)

    rect = TkcRectangle.new(canvas, 10, 10, 50, 50)

    rect.bind('ButtonPress-1') { }
    result = rect.bind_append('ButtonPress-1') { }
    errors << "bind_append should return self" unless result == rect

    raise errors.join("\n") unless errors.empty?
  end

  def test_item_bind_remove
    assert_tk_app("canvas item bind_remove", method(:app_item_bind_remove))
  end

  def app_item_bind_remove
    require 'tk'
    require 'tk/canvas'

    errors = []
    canvas = TkCanvas.new(root)

    rect = TkcRectangle.new(canvas, 10, 10, 50, 50)

    rect.bind('ButtonPress-1') { }
    result = rect.bind_remove('ButtonPress-1')
    errors << "bind_remove should return self" unless result == rect

    raise errors.join("\n") unless errors.empty?
  end

  # --- Configure methods ---

  def test_item_configure
    assert_tk_app("canvas item configure", method(:app_item_configure))
  end

  def app_item_configure
    require 'tk'
    require 'tk/canvas'

    errors = []
    canvas = TkCanvas.new(root)

    rect = TkcRectangle.new(canvas, 10, 10, 50, 50)

    result = rect.configure(:fill, 'red')
    errors << "configure should return self" unless result == rect

    fill = rect.cget_tkstring(:fill)
    errors << "fill should be 'red', got #{fill}" unless fill == 'red'

    raise errors.join("\n") unless errors.empty?
  end

  def test_item_configinfo
    assert_tk_app("canvas item configinfo", method(:app_item_configinfo))
  end

  def app_item_configinfo
    require 'tk'
    require 'tk/canvas'

    errors = []
    canvas = TkCanvas.new(root)

    rect = TkcRectangle.new(canvas, 10, 10, 50, 50, fill: 'blue')

    info = rect.configinfo(:fill)
    errors << "configinfo should return array" unless info.is_a?(Array)

    all_info = rect.configinfo
    errors << "configinfo() should return all options" unless all_info.is_a?(Array) && all_info.size > 1

    raise errors.join("\n") unless errors.empty?
  end
end
