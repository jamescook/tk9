# frozen_string_literal: true

require 'minitest/autorun'
require_relative '../tk_test_helper'

class TestMenubar1 < Minitest::Test
  include TkTestHelper

  def test_sample_loads_and_menus_work
    sample_path = File.expand_path('../../sample/menubar1.rb', __dir__)
    success, stdout, stderr = smoke_test_sample(sample_path)

    assert success, "Sample should load without crashing\nSTDOUT: #{stdout}\nSTDERR: #{stderr}"
    assert_includes stdout, "UI loaded"
    assert_includes stdout, "Open clicked"
    assert_includes stdout, "Cut clicked"
    assert_includes stdout, "Copy clicked"
  end
end
