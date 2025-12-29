# frozen_string_literal: true

require 'fileutils'
require_relative 'perceptualdiff'
require_relative 'widget_showcase'

module VisualRegression
  # Orchestrates visual regression testing:
  # 1. Generates screenshots of the widget showcase
  # 2. Compares against blessed baseline images
  # 3. Reports differences and exits with appropriate status
  class Runner
    SCREENSHOTS_DIR = File.expand_path('../../../screenshots', __FILE__)
    BLESSED_DIR = File.join(SCREENSHOTS_DIR, 'blessed')
    UNVERIFIED_DIR = File.join(SCREENSHOTS_DIR, 'unverified')
    DIFFS_DIR = File.join(SCREENSHOTS_DIR, 'diffs')

    attr_reader :threshold, :results

    def initialize(threshold: Perceptualdiff::DEFAULT_THRESHOLD)
      @threshold = threshold
      @results = []
    end

    def self.call(threshold: Perceptualdiff::DEFAULT_THRESHOLD)
      runner = new(threshold: threshold)
      runner.setup_directories
      runner.generate_screenshots
      runner.compare_screenshots
      runner.report_results
      runner.exit_with_status
    end

    def setup_directories
      FileUtils.mkdir_p(BLESSED_DIR)
      FileUtils.mkdir_p(UNVERIFIED_DIR)
      FileUtils.mkdir_p(DIFFS_DIR)
      FileUtils.rm_f(Dir.glob(File.join(DIFFS_DIR, '*.png')))
    end

    def generate_screenshots
      puts "Generating screenshots..."
      $stdout.flush
      WidgetShowcase.new(output_dir: UNVERIFIED_DIR).run
      puts "Screenshot generation complete!"
      $stdout.flush
    end

    def compare_screenshots
      puts "\nComparing screenshots against blessed baselines..."
      puts "-" * 60
      $stdout.flush

      puts "Initializing perceptualdiff..."
      $stdout.flush
      diff_tool = Perceptualdiff.new(threshold: threshold)
      puts "Perceptualdiff initialized with threshold: #{threshold}"
      $stdout.flush
      unverified_files = Dir.glob(File.join(UNVERIFIED_DIR, '*.png')).sort

      if unverified_files.empty?
        puts "ERROR: No screenshots generated!"
        return
      end

      unverified_files.each do |unverified|
        name = File.basename(unverified)
        blessed = File.join(BLESSED_DIR, name)
        diff = File.join(DIFFS_DIR, "diff_#{name}")

        result = compare_single(diff_tool, name, blessed, unverified, diff)
        @results << result
      end
    end

    def compare_single(diff_tool, name, blessed, unverified, diff)
      unless File.exist?(blessed)
        puts "  #{name}: MISSING BASELINE"
        return { name: name, status: :missing, message: 'No blessed baseline exists' }
      end

      result = diff_tool.compare(expected: blessed, actual: unverified, diff_output: diff)

      if result.passed?
        puts "  #{name}: PASS"
        FileUtils.rm_f(diff) # Remove diff file for passing tests
        { name: name, status: :pass, pixel_diff: result.pixel_diff }
      else
        puts "  #{name}: FAIL (#{result.pixel_diff} pixels differ)"
        { name: name, status: :fail, pixel_diff: result.pixel_diff, diff_image: diff }
      end
    end

    def report_results
      puts "-" * 60
      puts "\nSummary:"

      passed = @results.count { |r| r[:status] == :pass }
      failed = @results.count { |r| r[:status] == :fail }
      missing = @results.count { |r| r[:status] == :missing }

      puts "  Passed:  #{passed}"
      puts "  Failed:  #{failed}"
      puts "  Missing: #{missing}"

      if failed > 0
        puts "\nFailed comparisons:"
        @results.select { |r| r[:status] == :fail }.each do |r|
          puts "  - #{r[:name]} (#{r[:pixel_diff]} pixels differ)"
          puts "    Diff image: #{r[:diff_image]}"
        end
      end

      if missing > 0
        puts "\nMissing baselines (copy from unverified/ to blessed/ to create):"
        @results.select { |r| r[:status] == :missing }.each do |r|
          puts "  - #{r[:name]}"
        end
        puts "\nTo bless current screenshots:"
        puts "  cp #{UNVERIFIED_DIR}/*.png #{BLESSED_DIR}/"
      end
    end

    def exit_with_status
      failed = @results.count { |r| r[:status] == :fail }
      exit(failed > 0 ? 1 : 0)
    end
  end
end

# Allow running standalone
if __FILE__ == $0
  threshold = (ARGV[0] || 100).to_i
  VisualRegression::Runner.call(threshold: threshold)
end
