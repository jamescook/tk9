# frozen_string_literal: true

require 'open3'

module VisualRegression
  # Ruby wrapper for the perceptualdiff command-line tool.
  # Performs perceptual image comparison that accounts for human vision.
  class Perceptualdiff
    class NotInstalledError < StandardError; end

    Result = Struct.new(:passed, :pixel_diff, :output, :diff_image, keyword_init: true) do
      def passed?
        passed
      end

      def failed?
        !passed
      end
    end

    DEFAULT_THRESHOLD = 100

    attr_reader :threshold

    def initialize(threshold: DEFAULT_THRESHOLD)
      @threshold = threshold
    end

    # Compare two images and return a Result
    #
    # @param expected [String] Path to the expected (blessed) image
    # @param actual [String] Path to the actual (unverified) image
    # @param diff_output [String, nil] Path to write diff image (optional)
    # @return [Result]
    def compare(expected:, actual:, diff_output: nil)
      validate_installation!
      validate_files!(expected, actual)

      args = build_args(expected, actual, diff_output)
      stdout, stderr, status = Open3.capture3(*args)
      output = stdout + stderr

      parse_result(output, status, diff_output)
    end

    # Check if perceptualdiff is installed
    def self.installed?
      _stdout, _stderr, status = Open3.capture3('which', 'perceptualdiff')
      status.success?
    end

    private

    def validate_installation!
      return if self.class.installed?

      raise NotInstalledError, <<~MSG
        perceptualdiff is not installed. Install it with:
          macOS: brew install perceptualdiff
          Linux: apt-get install perceptualdiff
      MSG
    end

    def validate_files!(*files)
      files.each do |file|
        raise ArgumentError, "File not found: #{file}" unless File.exist?(file)
      end
    end

    def build_args(expected, actual, diff_output)
      args = ['perceptualdiff', '--verbose', '--threshold', threshold.to_s]
      args += ['--output', diff_output] if diff_output
      args += [expected, actual]
      args
    end

    def parse_result(output, status, diff_output)
      pixel_diff = extract_pixel_diff(output)
      passed = status.success? || output.include?('PASS')

      Result.new(
        passed: passed,
        pixel_diff: pixel_diff,
        output: output.strip,
        diff_image: diff_output
      )
    end

    def extract_pixel_diff(output)
      if output =~ /(\d+) pixels are different/
        $1.to_i
      elsif output.include?('binary identical')
        0
      else
        nil
      end
    end

    # Check if ImageMagick's composite command is installed
    def self.composite_installed?
      _, _, status = Open3.capture3('which', 'composite')
      status.success?
    end

    # Create an overlay image showing the diff on top of the blessed image
    # Requires ImageMagick's composite command
    #
    # @param blessed [String] Path to the blessed image
    # @param diff [String] Path to the diff image
    # @param output [String] Path for the output overlay image
    # @return [Boolean] true if successful
    def self.create_overlay(blessed:, diff:, output:)
      unless composite_installed?
        warn "    (overlay skipped: install imagemagick for overlay images)"
        return false
      end
      return false unless File.exist?(blessed) && File.exist?(diff)

      # Use ImageMagick composite to blend diff (50% opacity) over blessed
      _, _, status = Open3.capture3(
        'composite', '-dissolve', '50', '-gravity', 'center',
        diff, blessed, output
      )
      status.success?
    end
  end
end
