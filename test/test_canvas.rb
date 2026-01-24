# frozen_string_literal: true

# Tests for Tk::Canvas - canvas widget methods
#
# See: lib/tk/canvas.rb

require_relative 'test_helper'
require_relative 'tk_test_helper'
require 'tk'

class TestTkCanvas < Minitest::Test
  include TkTestHelper

  # --- create (L118-127) ---

  def test_create_with_class
    assert_tk_app("create with TkcItem subclass", method(:app_create_class))
  end

  def app_create_class
    require 'tk'
    require 'tk/canvas'

    errors = []

    canvas = TkCanvas.new(root)
    # create returns item ID (Integer), not TkcItem object (per comment on L117)
    item_id = canvas.create(TkcRectangle, 10, 10, 50, 50)

    errors << "create should return Integer item ID, got #{item_id.class}" unless item_id.is_a?(Integer)
    errors << "create should return positive ID, got #{item_id}" unless item_id > 0

    raise errors.join("\n") unless errors.empty?
  end

  def test_create_with_string
    assert_tk_app("create with type string", method(:app_create_string))
  end

  def app_create_string
    require 'tk'
    require 'tk/canvas'

    errors = []

    canvas = TkCanvas.new(root)
    # create returns item ID (Integer), not TkcItem object
    item_id = canvas.create('rectangle', 10, 10, 50, 50)

    errors << "create should return Integer item ID, got #{item_id.class}" unless item_id.is_a?(Integer)
    errors << "create should return positive ID, got #{item_id}" unless item_id > 0

    raise errors.join("\n") unless errors.empty?
  end

  # --- dchars (L215-219) ---

  def test_dchars
    assert_tk_app("dchars deletes characters from text item", method(:app_dchars))
  end

  def app_dchars
    require 'tk'
    require 'tk/canvas'

    errors = []

    canvas = TkCanvas.new(root)
    text = TkcText.new(canvas, 50, 50, text: 'Hello World')

    result = canvas.dchars(text, 0, 4)
    errors << "dchars should return canvas" unless result == canvas

    raise errors.join("\n") unless errors.empty?
  end

  # --- icursor (L285-288) ---

  def test_icursor
    assert_tk_app("icursor sets insertion cursor position", method(:app_icursor))
  end

  def app_icursor
    require 'tk'
    require 'tk/canvas'

    errors = []

    canvas = TkCanvas.new(root)
    text = TkcText.new(canvas, 50, 50, text: 'Hello')

    result = canvas.icursor(text, 2)
    errors << "icursor should return canvas" unless result == canvas

    raise errors.join("\n") unless errors.empty?
  end

  # --- imove (L290-294) ---

  def test_imove
    assert_tk_app("imove moves coordinate of item", method(:app_imove))
  end

  def app_imove
    require 'tk'
    require 'tk/canvas'

    errors = []

    canvas = TkCanvas.new(root)
    line = TkcLine.new(canvas, 0, 0, 50, 50, 100, 100)

    # Move the second coordinate (index 1) to new position
    result = canvas.imove(line, 1, 75, 75)
    errors << "imove should return canvas" unless result == canvas

    raise errors.join("\n") unless errors.empty?
  end

  # --- find_above, find_below, find_closest (L247-259) ---

  def test_find_above
    assert_tk_app("find_above finds item above given item", method(:app_find_above))
  end

  def app_find_above
    require 'tk'
    require 'tk/canvas'

    errors = []

    canvas = TkCanvas.new(root)
    rect1 = TkcRectangle.new(canvas, 10, 10, 50, 50)
    rect2 = TkcRectangle.new(canvas, 20, 20, 60, 60)

    # rect2 is above rect1 in stacking order
    found = canvas.find_above(rect1)
    errors << "find_above should return array" unless found.is_a?(Array)
    errors << "find_above should find rect2" if found.empty?

    raise errors.join("\n") unless errors.empty?
  end

  def test_find_below
    assert_tk_app("find_below finds item below given item", method(:app_find_below))
  end

  def app_find_below
    require 'tk'
    require 'tk/canvas'

    errors = []

    canvas = TkCanvas.new(root)
    rect1 = TkcRectangle.new(canvas, 10, 10, 50, 50)
    rect2 = TkcRectangle.new(canvas, 20, 20, 60, 60)

    # rect1 is below rect2
    found = canvas.find_below(rect2)
    errors << "find_below should return array" unless found.is_a?(Array)
    errors << "find_below should find rect1" if found.empty?

    raise errors.join("\n") unless errors.empty?
  end

  def test_find_closest
    assert_tk_app("find_closest finds item nearest to point", method(:app_find_closest))
  end

  def app_find_closest
    require 'tk'
    require 'tk/canvas'

    errors = []

    canvas = TkCanvas.new(root)
    rect = TkcRectangle.new(canvas, 10, 10, 50, 50)

    found = canvas.find_closest(30, 30)
    errors << "find_closest should return array" unless found.is_a?(Array)
    errors << "find_closest should find the rectangle" if found.empty?

    raise errors.join("\n") unless errors.empty?
  end

  # --- find_enclosed, find_overlapping (L253-259) ---

  def test_find_enclosed
    assert_tk_app("find_enclosed finds items fully within region", method(:app_find_enclosed))
  end

  def app_find_enclosed
    require 'tk'
    require 'tk/canvas'

    errors = []

    canvas = TkCanvas.new(root)
    rect = TkcRectangle.new(canvas, 20, 20, 40, 40)

    # Region that fully encloses the rectangle
    found = canvas.find_enclosed(10, 10, 50, 50)
    errors << "find_enclosed should return array" unless found.is_a?(Array)
    errors << "find_enclosed should find the rectangle" if found.empty?

    raise errors.join("\n") unless errors.empty?
  end

  def test_find_overlapping
    assert_tk_app("find_overlapping finds items overlapping region", method(:app_find_overlapping))
  end

  def app_find_overlapping
    require 'tk'
    require 'tk/canvas'

    errors = []

    canvas = TkCanvas.new(root)
    rect = TkcRectangle.new(canvas, 20, 20, 60, 60)

    # Region that overlaps the rectangle
    found = canvas.find_overlapping(10, 10, 30, 30)
    errors << "find_overlapping should return array" unless found.is_a?(Array)
    errors << "find_overlapping should find the rectangle" if found.empty?

    raise errors.join("\n") unless errors.empty?
  end

  # --- select methods (L363-381) ---

  def test_select_from_to
    assert_tk_app("select_from and select_to set selection", method(:app_select_from_to))
  end

  def app_select_from_to
    require 'tk'
    require 'tk/canvas'

    errors = []

    canvas = TkCanvas.new(root)
    text = TkcText.new(canvas, 50, 50, text: 'Hello World')

    result = canvas.select_from(text, 0)
    errors << "select_from should return canvas" unless result == canvas

    result = canvas.select_to(text, 5)
    errors << "select_to should return canvas" unless result == canvas

    raise errors.join("\n") unless errors.empty?
  end

  def test_select_clear
    assert_tk_app("select_clear clears selection", method(:app_select_clear))
  end

  def app_select_clear
    require 'tk'
    require 'tk/canvas'

    errors = []

    canvas = TkCanvas.new(root)
    result = canvas.select_clear
    errors << "select_clear should return canvas" unless result == canvas

    raise errors.join("\n") unless errors.empty?
  end

  def test_select_item
    assert_tk_app("select_item returns selected item", method(:app_select_item))
  end

  def app_select_item
    require 'tk'
    require 'tk/canvas'

    errors = []

    canvas = TkCanvas.new(root)
    text = TkcText.new(canvas, 50, 50, text: 'Hello')

    # Select some text
    canvas.select_from(text, 0)
    canvas.select_to(text, 3)

    item = canvas.select_item
    # May return nil or the text item
    errors << "select_item should not raise" if item == :error

    raise errors.join("\n") unless errors.empty?
  end

  # --- scan_mark, scan_dragto (L354-361) ---

  def test_scan_mark
    assert_tk_app("scan_mark sets scan anchor", method(:app_scan_mark))
  end

  def app_scan_mark
    require 'tk'
    require 'tk/canvas'

    errors = []

    canvas = TkCanvas.new(root, scrollregion: [0, 0, 1000, 1000])
    result = canvas.scan_mark(100, 100)
    errors << "scan_mark should return canvas" unless result == canvas

    raise errors.join("\n") unless errors.empty?
  end

  def test_scan_dragto
    assert_tk_app("scan_dragto scrolls relative to anchor", method(:app_scan_dragto))
  end

  def app_scan_dragto
    require 'tk'
    require 'tk/canvas'

    errors = []

    canvas = TkCanvas.new(root, scrollregion: [0, 0, 1000, 1000])
    canvas.scan_mark(100, 100)

    result = canvas.scan_dragto(150, 150)
    errors << "scan_dragto should return canvas" unless result == canvas

    raise errors.join("\n") unless errors.empty?
  end

  # --- postscript (L327-329) ---

  def test_postscript
    assert_tk_app("postscript generates PostScript output", method(:app_postscript))
  end

  def app_postscript
    require 'tk'
    require 'tk/canvas'

    errors = []

    canvas = TkCanvas.new(root, width: 200, height: 200)
    TkcRectangle.new(canvas, 10, 10, 100, 100, fill: 'red')

    ps = canvas.postscript(colormode: 'gray')
    errors << "postscript should return String, got #{ps.class}" unless ps.is_a?(String)
    errors << "postscript should contain PS header" unless ps.include?('%!')

    raise errors.join("\n") unless errors.empty?
  end

  # --- create_itemobj_from_id (L387-406) ---

  def test_create_itemobj_from_id
    assert_tk_app("create_itemobj_from_id wraps existing item", method(:app_create_itemobj_from_id))
  end

  def app_create_itemobj_from_id
    require 'tk'
    require 'tk/canvas'

    errors = []

    canvas = TkCanvas.new(root)
    rect = TkcRectangle.new(canvas, 10, 10, 50, 50)
    id = rect.id

    # Get object from ID
    obj = canvas.create_itemobj_from_id(id)
    errors << "create_itemobj_from_id should return TkcItem, got #{obj.class}" unless obj.is_a?(TkcItem)

    raise errors.join("\n") unless errors.empty?
  end
end
