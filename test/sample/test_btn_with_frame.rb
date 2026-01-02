# frozen_string_literal: true

require 'minitest/autorun'
require_relative '../tk_test_helper'

class TestBtnWithFrame < Minitest::Test
  include TkTestHelper

  def test_sample_loads
    sample_path = File.expand_path('../../sample/btn_with_frame.rb', __dir__)
    success, stdout, stderr = smoke_test_sample(sample_path)

    assert success, "Sample should load without crashing\nSTDERR: #{stderr}"
    assert_includes stdout, 'UI loaded'
  end
end
