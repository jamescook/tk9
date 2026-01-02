# frozen_string_literal: true

require 'minitest/autorun'
require_relative '../tk_test_helper'

class TestCdTimer < Minitest::Test
  include TkTestHelper

  def test_sample_loads
    sample_path = File.expand_path('../../sample/cd_timer.rb', __dir__)
    success, stdout, stderr = smoke_test_sample(sample_path, args: ["0.1"])

    assert success, "Sample should load without crashing\nSTDERR: #{stderr}"
    assert_includes stdout, 'start clicked'
  end
end
