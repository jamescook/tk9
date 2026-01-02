# frozen_string_literal: true

require 'minitest/autorun'
require_relative '../tk_test_helper'

class TestFigmemoSample < Minitest::Test
  include TkTestHelper

  def test_sample_loads
    sample_path = File.expand_path('../../sample/figmemo_sample.rb', __dir__)
    success, stdout, stderr = smoke_test_sample(sample_path)

    assert success, "Sample should load without crashing\nSTDOUT: #{stdout}\nSTDERR: #{stderr}"
    assert_includes stdout, "UI loaded"
    assert_includes stdout, "canvas class: PhotoCanvas"
  end
end
