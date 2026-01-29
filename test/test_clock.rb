# frozen_string_literal: true

# Tests for Tk::Clock - Tcl clock command wrapper
#
# NOTE: The utility of this module is unclear given Ruby's native equivalents:
#   - Tk::Clock.seconds      -> Time.now.to_i
#   - Tk::Clock.milliseconds -> Process.clock_gettime(Process::CLOCK_MONOTONIC, :millisecond)
#   - Tk::Clock.format       -> Time.strftime
#   - Tk::Clock.scan         -> Time.parse
#
# We keep this module for backwards compatibility with existing Tk apps.
#
# See: https://www.tcl-lang.org/man/tcl/TclCmd/clock.html

require_relative 'test_helper'
require_relative 'tk_test_helper'

class TestClock < Minitest::Test
  include TkTestHelper

  # ===========================================
  # seconds/milliseconds/microseconds
  # ===========================================

  def test_seconds
    assert_tk_app("Clock seconds", method(:seconds_app))
  end

  def seconds_app
    require 'tk'
    require 'tk/clock'

    errors = []

    tcl_time = Tk::Clock.seconds
    ruby_time = Time.now.to_i

    # Should be within 1 second of each other
    diff = (tcl_time - ruby_time).abs
    errors << "seconds diff too large: #{diff}" if diff > 1

    # Should be a reasonable Unix timestamp
    year_2020 = Time.new(2020, 1, 1).to_i
    year_2100 = Time.new(2100, 1, 1).to_i
    errors << "seconds out of range: #{tcl_time}" unless tcl_time.between?(year_2020, year_2100)

    raise errors.join("\n") unless errors.empty?
  end

  def test_milliseconds
    assert_tk_app("Clock milliseconds", method(:milliseconds_app))
  end

  def milliseconds_app
    require 'tk'
    require 'tk/clock'

    errors = []

    ms = Tk::Clock.milliseconds
    errors << "milliseconds should be positive, got #{ms}" unless ms > 0

    # Should be roughly 1000x seconds
    secs = Tk::Clock.seconds
    ratio = ms.to_f / secs
    errors << "ms/s ratio should be ~1000, got #{ratio.round}" unless ratio.between?(999, 1001)

    raise errors.join("\n") unless errors.empty?
  end

  def test_microseconds
    assert_tk_app("Clock microseconds", method(:microseconds_app))
  end

  def microseconds_app
    require 'tk'
    require 'tk/clock'

    errors = []

    us = Tk::Clock.microseconds
    errors << "microseconds should be positive, got #{us}" unless us > 0

    # Should be roughly 1000x milliseconds
    ms = Tk::Clock.milliseconds
    ratio = us.to_f / ms
    errors << "us/ms ratio should be ~1000, got #{ratio.round}" unless ratio.between?(990, 1010)

    raise errors.join("\n") unless errors.empty?
  end

  # ===========================================
  # clicks - high resolution timer
  # ===========================================

  def test_clicks
    assert_tk_app("Clock clicks", method(:clicks_app))
  end

  def clicks_app
    require 'tk'
    require 'tk/clock'

    errors = []

    # Default clicks - should be positive
    c1 = Tk::Clock.clicks
    errors << "clicks should be positive, got #{c1}" unless c1 > 0

    # Milliseconds variant
    c2 = Tk::Clock.clicks(:milliseconds)
    errors << "clicks(:milliseconds) should be positive, got #{c2}" unless c2 > 0

    # Microseconds variant
    c3 = Tk::Clock.clicks(:microseconds)
    errors << "clicks(:microseconds) should be positive, got #{c3}" unless c3 > 0

    # String variants
    c4 = Tk::Clock.clicks('mil')
    errors << "clicks('mil') should be positive, got #{c4}" unless c4 > 0

    c5 = Tk::Clock.clicks('mic')
    errors << "clicks('mic') should be positive, got #{c5}" unless c5 > 0

    raise errors.join("\n") unless errors.empty?
  end

  # ===========================================
  # format - timestamp to string
  # ===========================================

  def test_format
    assert_tk_app("Clock format", method(:format_app))
  end

  def format_app
    require 'tk'
    require 'tk/clock'

    errors = []

    # Format current time with default format
    now = Tk::Clock.seconds
    formatted = Tk::Clock.format(now)
    errors << "format should not be empty, got #{formatted.inspect}" if formatted.nil? || formatted.empty?

    # Format with custom format string (Tcl format codes)
    year = Tk::Clock.format(now, '%Y')
    errors << "year format failed" unless year =~ /^\d{4}$/

    # Known timestamp: 0 = 1970-01-01 00:00:00 UTC
    epoch = Tk::Clock.formatGMT(0, '%Y-%m-%d')
    errors << "epoch should be 1970-01-01, got #{epoch}" unless epoch == '1970-01-01'

    raise errors.join("\n") unless errors.empty?
  end

  def test_format_gmt
    assert_tk_app("Clock formatGMT", method(:format_gmt_app))
  end

  def format_gmt_app
    require 'tk'
    require 'tk/clock'

    errors = []

    now = Tk::Clock.seconds

    # formatGMT should give UTC time in HH:MM format
    gmt = Tk::Clock.formatGMT(now, '%H:%M')
    errors << "formatGMT should match HH:MM pattern, got #{gmt.inspect}" unless gmt =~ /^\d{2}:\d{2}$/

    raise errors.join("\n") unless errors.empty?
  end

  # ===========================================
  # scan - string to timestamp
  # ===========================================

  def test_scan
    assert_tk_app("Clock scan", method(:scan_app))
  end

  def scan_app
    require 'tk'
    require 'tk/clock'

    errors = []

    # Scan a date string - 1970-01-01 should be near epoch (within a day for timezone)
    ts = Tk::Clock.scan('1970-01-01')
    errors << "scan('1970-01-01') should be near 0, got #{ts}" unless ts.abs < 86400

    # Round-trip: format then scan
    now = Tk::Clock.seconds
    formatted = Tk::Clock.format(now, '%Y-%m-%d %H:%M:%S')
    scanned = Tk::Clock.scan(formatted)

    # Should be close (within a day due to timezone issues)
    diff = (now - scanned).abs
    errors << "round-trip diff too large: #{diff}" if diff > 86400

    raise errors.join("\n") unless errors.empty?
  end

  def test_scan_gmt
    assert_tk_app("Clock scanGMT", method(:scan_gmt_app))
  end

  def scan_gmt_app
    require 'tk'
    require 'tk/clock'

    errors = []

    # Scan as GMT - epoch should be exactly 0
    ts = Tk::Clock.scanGMT('1970-01-01 00:00:00')
    errors << "scanGMT('1970-01-01 00:00:00') should be 0, got #{ts}" unless ts == 0

    raise errors.join("\n") unless errors.empty?
  end

  # ===========================================
  # add - add time intervals
  # ===========================================

  def test_add
    assert_tk_app("Clock add", method(:add_app))
  end

  def add_app
    require 'tk'
    require 'tk/clock'

    errors = []

    now = Tk::Clock.seconds

    # Add 1 day
    tomorrow = Tk::Clock.add(now, 1, 'day')
    diff = tomorrow - now
    errors << "add 1 day should add 86400 seconds, got #{diff}" unless diff == 86400

    # Add 1 hour
    later = Tk::Clock.add(now, 1, 'hour')
    diff = later - now
    errors << "add 1 hour should add 3600 seconds, got #{diff}" unless diff == 3600

    raise errors.join("\n") unless errors.empty?
  end
end
