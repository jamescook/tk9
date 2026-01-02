# frozen_string_literal: true

require 'minitest/autorun'
require_relative '../tk_test_helper'

class TestBindtagSample < Minitest::Test
  include TkTestHelper

  def test_sample_loads_and_buttons_work
    sample_path = File.expand_path('../../sample/bindtag_sample.rb', __dir__)
    success, stdout, stderr = smoke_test_sample(sample_path)

    assert success, "Sample should load without crashing\nSTDERR: #{stderr}"

    # Each button command should fire
    assert_includes stdout, 'command of button-1'
    assert_includes stdout, 'command of button-2'
    assert_includes stdout, 'command of button-3'
    assert_includes stdout, 'command of button-4'
    assert_includes stdout, 'command of button-5'
    assert_includes stdout, 'call "set_class_bind"'

    # callback_continue should work (button-3 uses tag2)
    assert_includes stdout, 'call Tk.callback_continue'
    refute_includes stdout, 'never see this message'

    # callback_break should work (button-4 uses tag3)
    assert_includes stdout, 'call Tk.callback_break'
  end
end
