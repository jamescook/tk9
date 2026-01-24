# frozen_string_literal: true

# Test for small shim/stub files that either:
# 1. Raise LoadError for removed features
# 2. Forward requires to the canonical location
#
# Uses subprocess to test require behavior cleanly.

require_relative 'test_helper'
require_relative 'tk_test_helper'

class TestRequireShims < Minitest::Test
  include TkTestHelper

  def test_removed_stubs_raise_load_error
    assert_tk_subprocess("removed stubs raise LoadError") do
      <<~'RUBY'
        errors = []

        # These files were removed and should raise LoadError
        removed_files = %w[
          multi-tk
          remote-tk
          thread_tk
          tk/macpkg
        ]

        removed_files.each do |file|
          begin
            require file
            errors << "#{file} should raise LoadError but didn't"
          rescue LoadError => e
            errors << "#{file} wrong message" unless e.message.include?("removed")
          end
        end

        raise errors.join("\n") unless errors.empty?
      RUBY
    end
  end

  def test_forwarding_shims_load_correctly
    assert_tk_subprocess("forwarding shims load correctly") do
      <<~'RUBY'
        require 'tk'

        errors = []

        # These files forward to their canonical location
        # Each should load without error
        # Note: tkwinpkg excluded (Windows-only, needs dde package)
        forwarding_shims = %w[
          tkutil
          tkafter
          tkbgerror
          tkcanvas
          tkconsole
          tkdialog
          tkentry
          tkmenubar
          tkmngfocus
          tkpalette
          tkscrollbox
          tktext
          tkvirtevent
          tk/after
        ]

        forwarding_shims.each do |file|
          begin
            require file
          rescue => e
            errors << "#{file} failed to load: #{e.class} - #{e.message}"
          end
        end

        raise errors.join("\n") unless errors.empty?
      RUBY
    end
  end

  def test_tkmacpkg_chains_to_removed
    assert_tk_subprocess("tkmacpkg chains to removed tk/macpkg") do
      <<~'RUBY'
        # tkmacpkg requires tk/macpkg which raises LoadError
        begin
          require 'tkmacpkg'
          raise "tkmacpkg should raise LoadError"
        rescue LoadError => e
          raise "wrong message" unless e.message.include?("removed")
        end
      RUBY
    end
  end

  def test_deprecated_shims_warn_but_load
    assert_tk_subprocess("deprecated shims warn but load") do
      <<~'RUBY'
        require 'tk'
        require 'stringio'

        errors = []

        # These files are deprecated - they warn but still load
        deprecated_shims = %w[
          tk/itemconfig
          tk/kinput
          tkextlib/tcllib
        ]

        deprecated_shims.each do |file|
          warnings = []
          old_stderr = $stderr
          $stderr = StringIO.new

          begin
            require file
            warnings = $stderr.string
          ensure
            $stderr = old_stderr
          end

          # Should have loaded without error
          # and should have issued a warning
          if warnings.empty?
            errors << "#{file} should emit deprecation warning"
          end
        end

        # Verify tkextlib/tcllib provides empty module
        unless defined?(Tk::Tcllib)
          errors << "tkextlib/tcllib should define Tk::Tcllib module"
        end

        raise errors.join("\n") unless errors.empty?
      RUBY
    end
  end
end
