# frozen_string_literal: true

# Common test helper - loads SimpleCov for coverage, then minitest.
# All test files should require this FIRST.

require 'simplecov'

# Unique command name for each process (enables subprocess merging)
SimpleCov.command_name "test:#{Process.pid}"

SimpleCov.start do
  add_filter '/test/'
  add_filter '/ext/'
  add_filter '/benchmark/'

  add_group 'Core', 'lib/tk.rb'
  add_group 'Widgets', 'lib/tk'
  add_group 'Extensions', 'lib/tkextlib'
  add_group 'Utilities', ['lib/tkutil.rb', 'lib/tk/util.rb']

  # Track all lib files
  track_files 'lib/**/*.rb'
end

$LOAD_PATH.unshift(File.expand_path('../lib', __dir__))

require 'minitest/autorun'
