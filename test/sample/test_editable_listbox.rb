# frozen_string_literal: true

require 'minitest/autorun'
require_relative '../tk_test_helper'

class TestEditableListbox < Minitest::Test
  include TkTestHelper

  def test_sample_loads
    sample_path = File.expand_path('../../sample/editable_listbox.rb', __dir__)
    success, stdout, stderr = smoke_test_sample(sample_path)

    assert success, "Sample should load without crashing\nSTDOUT: #{stdout}\nSTDERR: #{stderr}"
    assert_includes stdout, "lbox1 items: 14"
    assert_includes stdout, "lbox2 items: 14"
  end
end
