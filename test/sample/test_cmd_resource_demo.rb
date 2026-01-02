# frozen_string_literal: true

require 'minitest/autorun'
require 'open3'
require_relative '../tk_test_helper'

class TestCmdResourceDemo < Minitest::Test
  include TkTestHelper

  def test_option_db_proc_classes
    sample_path = File.expand_path('../../sample/cmd_resource_demo.rb', __dir__)
    project_root = File.expand_path('../..', __dir__)
    load_paths = $LOAD_PATH.select { |p| p.include?(project_root) }
    load_path_args = load_paths.flat_map { |p| ["-I", p] }

    stdout, stderr, status = Open3.capture3(
      RbConfig.ruby, *load_path_args, sample_path
    )

    assert status.success?, "Sample should run without errors\nSTDERR: #{stderr}"

    # cmd1 uses *hello.show_msg pattern
    assert_includes stdout, "Hello, Hello, cmd1!!"

    # cmd2 uses *hello.ZZZ.show_msg pattern
    assert_includes stdout, "Hello, Hello, ZZZ:cmd2!!"

    # cmd3 uses *hello.ZZZ.show_msg pattern
    assert_includes stdout, "Hello, Hello, ZZZ:cmd3!!"

    # cmd4 uses *BTN_CMD.show_msg with custom __check_proc_string__
    assert_includes stdout, "Hello, cmd4!!"
  end
end
