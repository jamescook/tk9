# frozen_string_literal: true

require_relative 'test_helper'
require 'tk'

class TestListConversion < Minitest::Test
  # Test that layout specs with :children produce correct Tcl lists
  # Bug: hash options were being wrapped in extra braces, causing
  # "-children {nested}" to become "{-children {nested}}" (single element)
  def test_layout_spec_children_not_wrapped
    spec = ["Scrollbar.trough", {:children=>[
        "Scrollbar.uparrow", {:side=>:top}
      ]}
    ]

    result = TkUtil._ary2list_ruby(spec)

    # The result should be a 3-element Tcl list:
    #   Scrollbar.trough -children {Scrollbar.uparrow -side top}
    # NOT a 2-element list where the second element is:
    #   {-children {Scrollbar.uparrow -side top}}

    # Parse it back as a Tcl list to check element count
    parsed = TkCore::INTERP.tcl_split_list(result)

    assert_equal 3, parsed.length, "Expected 3 elements: element, -children, {nested}, got: #{parsed.inspect}"
    assert_equal "Scrollbar.trough", parsed[0]
    assert_equal "-children", parsed[1]
  end
end
