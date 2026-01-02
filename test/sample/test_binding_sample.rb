# frozen_string_literal: true

require 'minitest/autorun'
require_relative '../tk_test_helper'

class TestBindingSample < Minitest::Test
  include TkTestHelper

  def test_sample_loads_and_buttons_work
    sample_path = File.expand_path('../../sample/binding_sample.rb', __dir__)
    success, stdout, stderr = smoke_test_sample(sample_path)

    assert success, "Sample should load without crashing\nSTDERR: #{stderr}"
    assert_includes stdout, 'button is clicked!!', "TkButton should have been clicked"
    assert_includes stdout, 'label is clicked!!', "Button_clone should have been clicked"
  end
end
