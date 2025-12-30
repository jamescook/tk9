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

    attr_reader :threshold, :results, :tcl_version, :platform

    def initialize(threshold: Perceptualdiff::DEFAULT_THRESHOLD)
      @threshold = threshold
      @results = []
      @tcl_version = "tcl#{Tk::TCL_VERSION}"
      @platform = detect_platform
    end

    def detect_platform
      case RUBY_PLATFORM
      when /darwin/
        'darwin'
      when /linux/
        'linux'
      when /mingw|mswin/
        'windows'
      else
        'unknown'
      end
    end

    def blessed_dir
      File.join(SCREENSHOTS_DIR, 'blessed', platform, tcl_version)
    end

    def unverified_dir
      File.join(SCREENSHOTS_DIR, 'unverified', platform, tcl_version)
    end

    def diffs_dir
      File.join(SCREENSHOTS_DIR, 'diffs', platform, tcl_version)
    end

    def logs_dir
      File.join(SCREENSHOTS_DIR, 'logs', platform, tcl_version)
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
      FileUtils.mkdir_p(blessed_dir)
      FileUtils.mkdir_p(unverified_dir)
      FileUtils.mkdir_p(diffs_dir)
      FileUtils.mkdir_p(logs_dir)
      FileUtils.rm_f(Dir.glob(File.join(diffs_dir, '*.png')))
      FileUtils.rm_f(Dir.glob(File.join(logs_dir, '*.log')))
    end

    def generate_screenshots
      puts "Generating screenshots for #{tcl_version}..."
      WidgetShowcase.new(output_dir: unverified_dir).run
    end

    def compare_screenshots
      puts "\nComparing against blessed baselines (#{tcl_version})..."
      puts "-" * 60

      diff_tool = Perceptualdiff.new(threshold: threshold)
      unverified_files = Dir.glob(File.join(unverified_dir, '*.png')).sort

      if unverified_files.empty?
        puts "ERROR: No screenshots generated!"
        return
      end

      unverified_files.each do |unverified|
        name = File.basename(unverified)
        blessed = File.join(blessed_dir, name)
        diff = File.join(diffs_dir, "diff_#{name}")

        result = compare_single(diff_tool, name, blessed, unverified, diff)
        @results << result
      end
    end

    def compare_single(diff_tool, name, blessed, unverified, diff)
      unless File.exist?(blessed)
        puts "  #{name.ljust(28)} MISSING BASELINE"
        return { name: name, status: :missing, message: 'No blessed baseline exists' }
      end

      result = diff_tool.compare(expected: blessed, actual: unverified, diff_output: diff)

      # Write perceptualdiff output to log file
      log_file = File.join(logs_dir, "#{File.basename(name, '.png')}.log")
      File.write(log_file, "Comparing: #{blessed} vs #{unverified}\n\n#{result.output}\n")

      if result.passed?
        puts "  #{name.ljust(28)} PASS"
        FileUtils.rm_f(diff) # Remove diff file for passing tests
        { name: name, status: :pass, pixel_diff: result.pixel_diff }
      else
        puts "  #{name.ljust(28)} FAIL (#{result.pixel_diff} pixels differ)"
        puts "    Log: #{log_file}"
        # Create overlay showing diff on top of blessed image
        overlay = File.join(diffs_dir, "overlay_#{name}")
        if Perceptualdiff.create_overlay(blessed: blessed, diff: diff, output: overlay)
          puts "    Overlay: #{overlay}"
        end
        { name: name, status: :fail, pixel_diff: result.pixel_diff, diff_image: diff, overlay_image: overlay }
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
        puts "  cp #{unverified_dir}/*.png #{blessed_dir}/"
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
