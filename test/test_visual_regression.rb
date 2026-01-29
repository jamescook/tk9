# frozen_string_literal: true

require_relative 'test_helper'
require_relative 'visual_regression/runner'

class TestVisualRegression < Minitest::Test
  def test_widget_screenshots_match_blessed_baselines
    runner = VisualRegression::Runner.new(threshold: 100)

    runner.setup_directories
    runner.generate_screenshots
    runner.compare_screenshots
    runner.report_results

    failures = runner.results.select { |r| r[:status] == :fail }
    missing = runner.results.select { |r| r[:status] == :missing }

    assert_empty missing, "Missing blessed baselines:\n" +
      missing.map { |r| "  #{r[:name]}" }.join("\n") +
      "\n\nTo create baselines: rake screenshots:bless (or: cp #{runner.unverified_dir}/*.png #{runner.blessed_dir}/)"

    assert_empty failures, "Visual regression failures:\n" +
      failures.map { |r| "  #{r[:name]}: #{r[:pixel_diff]} pixels differ" }.join("\n")
  end
end
