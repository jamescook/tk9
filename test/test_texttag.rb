# frozen_string_literal: true

# Tests for TkTextTag, TkTextNamedTag, TkTextTagSel
#
# See: https://www.tcl.tk/man/tcl8.6/TkCmd/text.htm

require_relative 'test_helper'
require_relative 'tk_test_helper'
require 'tk'

class TestTkTextTag < Minitest::Test
  include TkTestHelper

  # --- TkTextTag creation ---

  def test_texttag_creation
    assert_tk_app("TkTextTag creation", method(:app_texttag_creation))
  end

  def app_texttag_creation
    require 'tk'
    require 'tk/text'
    require 'tk/texttag'

    errors = []
    text = TkText.new(root)
    text.pack

    tag = TkTextTag.new(text)
    errors << "tag should be TkTextTag" unless tag.is_a?(TkTextTag)
    errors << "tag should have id" unless tag.id

    raise errors.join("\n") unless errors.empty?
  end

  def test_texttag_with_config
    assert_tk_app("TkTextTag with config", method(:app_texttag_config))
  end

  def app_texttag_config
    require 'tk'
    require 'tk/text'
    require 'tk/texttag'

    errors = []
    text = TkText.new(root)
    text.insert('end', "Hello World")

    # Create tag with range and config
    tag = TkTextTag.new(text, '1.0', '1.5', foreground: 'red')

    ranges = tag.ranges
    errors << "tag should have range" unless ranges.size > 0

    fg = tag.cget(:foreground)
    errors << "foreground should be red" unless fg.to_s.include?('red') || fg == 'red'

    raise errors.join("\n") unless errors.empty?
  end

  # --- TkTextTag exist? ---

  def test_texttag_exist
    assert_tk_app("TkTextTag exist?", method(:app_texttag_exist))
  end

  def app_texttag_exist
    require 'tk'
    require 'tk/text'
    require 'tk/texttag'

    errors = []
    text = TkText.new(root)
    text.insert('end', "Hello World")

    tag = TkTextTag.new(text, '1.0', '1.5')
    errors << "tag should exist" unless tag.exist?

    tag.destroy
    errors << "tag should not exist after destroy" if tag.exist?

    raise errors.join("\n") unless errors.empty?
  end

  # --- first/last indices ---

  def test_texttag_first_last
    assert_tk_app("TkTextTag first/last", method(:app_texttag_first_last))
  end

  def app_texttag_first_last
    require 'tk'
    require 'tk/text'
    require 'tk/texttag'

    errors = []
    text = TkText.new(root)
    text.insert('end', "Hello World Test")

    tag = TkTextTag.new(text, '1.0', '1.5')

    first_idx = tag.first
    errors << "first should return IndexString" unless first_idx.is_a?(Tk::Text::IndexString)
    errors << "first should end with .first" unless first_idx.to_s.end_with?('.first')

    last_idx = tag.last
    errors << "last should return IndexString" unless last_idx.is_a?(Tk::Text::IndexString)
    errors << "last should end with .last" unless last_idx.to_s.end_with?('.last')

    raise errors.join("\n") unless errors.empty?
  end

  # --- add/remove ---

  def test_texttag_add_remove
    assert_tk_app("TkTextTag add/remove", method(:app_texttag_add_remove))
  end

  def app_texttag_add_remove
    require 'tk'
    require 'tk/text'
    require 'tk/texttag'

    errors = []
    text = TkText.new(root)
    text.insert('end', "Hello World Test String")

    tag = TkTextTag.new(text)

    # Add to a range
    result = tag.add('1.0', '1.5')
    errors << "add should return self" unless result == tag

    ranges = tag.ranges
    errors << "should have 1 range after add" unless ranges.size == 1

    # Add another range
    tag.add('1.6', '1.11')
    ranges = tag.ranges
    errors << "should have 2 ranges after second add" unless ranges.size == 2

    # Remove one range
    result = tag.remove('1.0', '1.5')
    errors << "remove should return self" unless result == tag

    ranges = tag.ranges
    errors << "should have 1 range after remove" unless ranges.size == 1

    raise errors.join("\n") unless errors.empty?
  end

  # --- ranges ---

  def test_texttag_ranges
    assert_tk_app("TkTextTag ranges", method(:app_texttag_ranges))
  end

  def app_texttag_ranges
    require 'tk'
    require 'tk/text'
    require 'tk/texttag'

    errors = []
    text = TkText.new(root)
    text.insert('end', "Hello World")

    tag = TkTextTag.new(text, '1.0', '1.5')

    ranges = tag.ranges
    errors << "ranges should be array" unless ranges.is_a?(Array)
    errors << "ranges should have 1 pair" unless ranges.size == 1
    errors << "range should be [start, end] pair" unless ranges[0].is_a?(Array) && ranges[0].size == 2
    errors << "range start should be IndexString" unless ranges[0][0].is_a?(Tk::Text::IndexString)

    raise errors.join("\n") unless errors.empty?
  end

  # --- nextrange/prevrange ---

  def test_texttag_nextrange_prevrange
    assert_tk_app("TkTextTag nextrange/prevrange", method(:app_texttag_nextprev))
  end

  def app_texttag_nextprev
    require 'tk'
    require 'tk/text'
    require 'tk/texttag'

    errors = []
    text = TkText.new(root)
    text.insert('end', "Hello World Test String")

    tag = TkTextTag.new(text)
    tag.add('1.6', '1.11')   # "World"
    tag.add('1.12', '1.16')  # "Test"

    # nextrange from beginning
    next_r = tag.nextrange('1.0')
    errors << "nextrange should return array" unless next_r.is_a?(Array)
    errors << "nextrange should find World at 1.6" unless next_r[0].to_s == '1.6'

    # prevrange from end
    prev_r = tag.prevrange('end')
    errors << "prevrange should return array" unless prev_r.is_a?(Array)
    errors << "prevrange should find Test at 1.12" unless prev_r[0].to_s == '1.12'

    raise errors.join("\n") unless errors.empty?
  end

  # --- cget/configure ---

  def test_texttag_cget_configure
    assert_tk_app("TkTextTag cget/configure", method(:app_texttag_cget))
  end

  def app_texttag_cget
    require 'tk'
    require 'tk/text'
    require 'tk/texttag'

    errors = []
    text = TkText.new(root)
    text.insert('end', "Hello World")

    tag = TkTextTag.new(text, '1.0', '1.5')

    # Configure
    result = tag.configure(foreground: 'blue')
    errors << "configure should return something" if result.nil?

    # cget
    fg = tag.cget(:foreground)
    errors << "cget foreground should be blue" unless fg.to_s.include?('blue') || fg == 'blue'

    # Hash-style access
    tag[:background] = 'yellow'
    bg = tag[:background]
    errors << "hash access should work" unless bg.to_s.include?('yellow') || bg == 'yellow'

    raise errors.join("\n") unless errors.empty?
  end

  # --- raise/lower ---

  def test_texttag_raise_lower
    assert_tk_app("TkTextTag raise/lower", method(:app_texttag_raise_lower))
  end

  def app_texttag_raise_lower
    require 'tk'
    require 'tk/text'
    require 'tk/texttag'

    errors = []
    text = TkText.new(root)
    text.insert('end', "Hello World")

    tag1 = TkTextTag.new(text, '1.0', '1.5', foreground: 'red')
    tag2 = TkTextTag.new(text, '1.0', '1.5', foreground: 'blue')

    result = tag1.raise(tag2)
    errors << "raise should return self" unless result == tag1

    result = tag1.lower(tag2)
    errors << "lower should return self" unless result == tag1

    raise errors.join("\n") unless errors.empty?
  end

  # --- TkTextNamedTag ---

  def test_textnamedtag_new
    assert_tk_app("TkTextNamedTag.new", method(:app_textnamedtag_new))
  end

  def app_textnamedtag_new
    require 'tk'
    require 'tk/text'
    require 'tk/texttag'

    errors = []
    text = TkText.new(root)
    text.insert('end', "Hello World Test")

    # new with name only
    tag = TkTextNamedTag.new(text, 'myname')
    errors << "id should be 'myname'" unless tag.id.to_s == 'myname'

    # new with name and range
    tag2 = TkTextNamedTag.new(text, 'mytag2', '1.0', '1.5')
    errors << "tag2 should have range" unless tag2.ranges.size > 0

    # new with name, range, and config hash
    tag3 = TkTextNamedTag.new(text, 'mytag3', '1.6', '1.11', foreground: 'red')
    errors << "tag3 should have range" unless tag3.ranges.size > 0
    fg = tag3.cget(:foreground)
    errors << "tag3 should be red" unless fg.to_s.include?('red') || fg == 'red'

    # new with name and config hash only (no range)
    tag4 = TkTextNamedTag.new(text, 'mytag4', background: 'yellow')
    bg = tag4.cget(:background)
    errors << "tag4 should have yellow bg" unless bg.to_s.include?('yellow') || bg == 'yellow'

    raise errors.join("\n") unless errors.empty?
  end

  def test_textnamedtag_reuse
    assert_tk_app("TkTextNamedTag reuse existing", method(:app_textnamedtag_reuse))
  end

  def app_textnamedtag_reuse
    require 'tk'
    require 'tk/text'
    require 'tk/texttag'

    errors = []
    text = TkText.new(root)
    text.insert('end', "Hello World")

    tag1 = TkTextNamedTag.new(text, 'samename', '1.0', '1.5')

    # Creating with same name returns same object
    tag2 = TkTextNamedTag.new(text, 'samename')
    errors << "same name should return same object" unless tag1.equal?(tag2)

    # But can still add ranges via the returned object
    tag2.add('1.6', '1.11')
    ranges = tag1.ranges
    errors << "should have 2 ranges now" unless ranges.size == 2

    raise errors.join("\n") unless errors.empty?
  end

  def test_textnamedtag_initialize_direct
    assert_tk_app("TkTextNamedTag initialize", method(:app_textnamedtag_init))
  end

  def app_textnamedtag_init
    require 'tk'
    require 'tk/text'
    require 'tk/texttag'

    errors = []
    text = TkText.new(root)
    text.insert('end', "Hello World Test")

    # Directly call initialize via allocate to test that path
    # (normally new() bypasses initialize for existing tags)
    tag = TkTextNamedTag.allocate
    tag.send(:initialize, text, 'direct_init', '1.0', '1.5', foreground: 'green')

    errors << "id should be 'direct_init'" unless tag.id.to_s == 'direct_init'
    errors << "should have range" unless tag.ranges.size > 0
    fg = tag.cget(:foreground)
    errors << "should be green" unless fg.to_s.include?('green') || fg == 'green'

    raise errors.join("\n") unless errors.empty?
  end

  # --- TkTextTagSel ---

  def test_texttagsel
    assert_tk_app("TkTextTagSel", method(:app_texttagsel))
  end

  def app_texttagsel
    require 'tk'
    require 'tk/text'
    require 'tk/texttag'

    errors = []
    text = TkText.new(root)
    text.insert('end', "Hello World")

    sel = TkTextTagSel.new(text)
    errors << "id should be 'sel'" unless sel.id.to_s == 'sel'

    # Configure the selection tag
    sel.configure(background: 'lightblue')
    bg = sel.cget(:background)
    errors << "sel tag should be configurable" unless bg

    raise errors.join("\n") unless errors.empty?
  end

  # --- TkTextTag.id2obj ---

  def test_texttag_id2obj
    assert_tk_app("TkTextTag.id2obj", method(:app_texttag_id2obj))
  end

  def app_texttag_id2obj
    require 'tk'
    require 'tk/text'
    require 'tk/texttag'

    errors = []
    text = TkText.new(root)

    tag = TkTextTag.new(text)
    tag_id = tag.id.to_s

    found = TkTextTag.id2obj(text, tag_id)
    errors << "id2obj should return TkTextTag" unless found.is_a?(TkTextTag)
    errors << "id2obj should return same object" unless found == tag

    raise errors.join("\n") unless errors.empty?
  end

  # --- bind methods ---

  def test_texttag_bind
    assert_tk_app("TkTextTag bind", method(:app_texttag_bind))
  end

  def app_texttag_bind
    require 'tk'
    require 'tk/text'
    require 'tk/texttag'

    errors = []
    text = TkText.new(root)
    text.insert('end', "Hello World")

    tag = TkTextTag.new(text, '1.0', '1.5')

    # bind
    result = tag.bind('Enter') { }
    errors << "bind should return self" unless result == tag

    # bindinfo
    info = tag.bindinfo
    errors << "bindinfo should return array" unless info.is_a?(Array)

    # bind_append
    result = tag.bind_append('Enter') { }
    errors << "bind_append should return self" unless result == tag

    # bind_remove
    result = tag.bind_remove('Enter')
    errors << "bind_remove should return self" unless result == tag

    raise errors.join("\n") unless errors.empty?
  end

  # --- destroy ---

  def test_texttag_destroy
    assert_tk_app("TkTextTag destroy", method(:app_texttag_destroy))
  end

  def app_texttag_destroy
    require 'tk'
    require 'tk/text'
    require 'tk/texttag'

    errors = []
    text = TkText.new(root)
    text.insert('end', "Hello World")

    tag = TkTextTag.new(text, '1.0', '1.5')
    errors << "tag should exist before destroy" unless tag.exist?

    result = tag.destroy
    errors << "destroy should return self" unless result == tag
    errors << "tag should not exist after destroy" if tag.exist?

    raise errors.join("\n") unless errors.empty?
  end
end
