# frozen_string_literal: true

# Common test helper - loads SimpleCov for coverage, then minitest.
# All test files should require this FIRST.
#
# Set COVERAGE=1 to enable coverage collection.
#
# COVERAGE_NAME is critical for multi-container coverage collection:
# - Each Docker container (main, bwidget, tkdnd) sets a unique COVERAGE_NAME
# - TkWorker uses COVERAGE_NAME to create unique coverage directories per container
# - Without unique names, PID collision across containers causes coverage overwrites
#   (e.g., both main and bwidget containers might spawn TkWorker with PID 37)

if ENV['COVERAGE']
  require 'simplecov'
  require 'simplecov_json_formatter'
  require_relative 'simplecov_config'

  coverage_name = ENV['COVERAGE_NAME'] || 'default'
  SimpleCov.coverage_dir "#{SimpleCovConfig::PROJECT_ROOT}/coverage/results/#{coverage_name}"
  SimpleCov.command_name "#{coverage_name}:#{Process.pid}"
  SimpleCov.formatter = SimpleCov::Formatter::MultiFormatter.new([
    SimpleCov::Formatter::SimpleFormatter,
    SimpleCov::Formatter::HTMLFormatter,
    SimpleCov::Formatter::JSONFormatter
  ])

  SimpleCov.start do
    SimpleCovConfig.apply_filters(self)
    SimpleCovConfig.apply_groups(self)
    track_files "#{SimpleCovConfig::PROJECT_ROOT}/lib/**/*.rb"
  end
end

$LOAD_PATH.unshift(File.expand_path('../lib', __dir__))

# Absolute path to test fixtures directory - works from any test file location
FIXTURES_PATH = File.expand_path('fixtures', __dir__)

require 'minitest/autorun'

# Stop TkWorker cleanly after all tests (allows coverage to be written)
Minitest.after_run do
  if defined?(TkWorker) && TkWorker.running?
    TkWorker.stop
  end
end

# Note: Coverage collation across multiple test suites (main, bwidget, tkdnd)
# is done by `rake coverage:collate` after all test runs complete.
# Each test run saves to coverage/results/<COVERAGE_NAME>/.resultset.json
