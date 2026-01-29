#!/usr/bin/env ruby
# frozen_string_literal: true

# Generate a minimal DTED Level 0 file for testing
# Based on MIL-PRF-89020B specification

# DTED Level 0 for Zone I (0-50° lat):
# - 30 arc second spacing
# - 121 x 121 elevation posts per 1° cell

class DTEDGenerator
  def initialize(sw_lat: 0, sw_lon: 0)
    @sw_lat = sw_lat
    @sw_lon = sw_lon
    @num_lon_lines = 121  # Level 0 Zone I
    @num_lat_points = 121
    @lat_interval = 300   # 30 seconds in tenths
    @lon_interval = 300
  end

  def generate
    uhl = generate_uhl
    dsi = generate_dsi
    acc = generate_acc
    data = generate_data_records

    uhl + dsi + acc + data
  end

  private

  def generate_uhl
    record = "UHL1"
    # Longitude of origin (8 chars): DDDMMSSH
    record += format("%03d0000%s", @sw_lon.abs, @sw_lon >= 0 ? "E" : "W")
    # Latitude of origin (8 chars): DDMMSSH + padding space
    record += format("%02d0000%s ", @sw_lat.abs, @sw_lat >= 0 ? "N" : "S")
    # Longitude interval in tenths of seconds (4 chars)
    record += format("%04d", @lon_interval)
    # Latitude interval in tenths of seconds (4 chars)
    record += format("%04d", @lat_interval)
    # Absolute vertical accuracy (4 chars) - NA
    record += "NA  "
    # Security code (3 chars)
    record += "U  "
    # Unique reference (12 chars)
    record += " " * 12
    # Number of longitude lines (4 chars)
    record += format("%04d", @num_lon_lines)
    # Number of latitude points (4 chars)
    record += format("%04d", @num_lat_points)
    # Multiple accuracy (1 char)
    record += "0"
    # Reserved (24 chars)
    record += " " * 24

    raise "UHL wrong size: #{record.bytesize}" unless record.bytesize == 80
    record
  end

  def generate_dsi
    record = "DSI"
    # Security classification (1 char)
    record += "U"
    # Security control and release markings (2 chars)
    record += "  "
    # Security handling description (27 chars)
    record += " " * 27
    # Reserved (26 chars)
    record += " " * 26
    # NIMA series designator (5 chars)
    record += "DTED0"
    # Unique reference number (15 chars)
    record += "0" * 15
    # Reserved (8 chars)
    record += " " * 8
    # Data edition number (2 chars)
    record += "01"
    # Match/merge version (1 char)
    record += "A"
    # Maintenance date YYMM (4 chars)
    record += "0000"
    # Match/merge date YYMM (4 chars)
    record += "0000"
    # Maintenance description code (4 chars)
    record += "0000"
    # Producer code (8 chars)
    record += "US      "
    # Reserved (16 chars)
    record += " " * 16
    # Product specification (9 chars)
    record += "PRF89020B"
    # Amendment/change number (2 chars)
    record += "00"
    # Date of product spec YYMM (4 chars)
    record += "0005"
    # Vertical datum (3 chars)
    record += "MSL"
    # Horizontal datum (5 chars)
    record += "WGS84"
    # Digitizing collection system (10 chars)
    record += "TEST      "
    # Compilation date YYMM (4 chars)
    record += "2601"
    # Reserved (22 chars)
    record += " " * 22

    # Lat/lon of origin with tenths
    lat_h = @sw_lat >= 0 ? "N" : "S"
    lon_h = @sw_lon >= 0 ? "E" : "W"

    # Latitude of origin DDMMSS.SH (9 chars)
    record += format("%02d0000.0%s", @sw_lat.abs, lat_h)
    # Longitude of origin DDDMMSS.SH (10 chars)
    record += format("%03d0000.0%s", @sw_lon.abs, lon_h)

    # Bounding rectangle corners (SW, NW, NE, SE)
    # SW corner
    record += format("%02d0000%s", @sw_lat.abs, lat_h)      # 7 chars
    record += format("%03d0000%s", @sw_lon.abs, lon_h)     # 8 chars
    # NW corner
    record += format("%02d0000%s", (@sw_lat + 1).abs, lat_h)  # 7 chars
    record += format("%03d0000%s", @sw_lon.abs, lon_h)        # 8 chars
    # NE corner
    record += format("%02d0000%s", (@sw_lat + 1).abs, lat_h)  # 7 chars
    record += format("%03d0000%s", (@sw_lon + 1).abs, lon_h)  # 8 chars
    # SE corner
    record += format("%02d0000%s", @sw_lat.abs, lat_h)        # 7 chars
    record += format("%03d0000%s", (@sw_lon + 1).abs, lon_h)  # 8 chars

    # Orientation angle (9 chars)
    record += "000000.00"
    # Latitude interval (4 chars)
    record += format("%04d", @lat_interval)
    # Longitude interval (4 chars)
    record += format("%04d", @lon_interval)
    # Number of latitude lines (4 chars)
    record += format("%04d", @num_lat_points)
    # Number of longitude lines (4 chars)
    record += format("%04d", @num_lon_lines)
    # Partial cell indicator (2 chars)
    record += "00"
    # Reserved for NIMA (101 chars)
    record += " " * 101
    # Reserved for producer (100 chars)
    record += " " * 100
    # Reserved for comments (156 chars)
    record += " " * 156

    raise "DSI wrong size: #{record.bytesize}, expected 648" unless record.bytesize == 648
    record
  end

  def generate_acc
    record = "ACC"
    # Absolute horizontal accuracy (4 chars)
    record += "NA  "
    # Absolute vertical accuracy (4 chars)
    record += "NA  "
    # Relative horizontal accuracy (4 chars)
    record += "NA  "
    # Relative vertical accuracy (4 chars)
    record += "NA  "
    # Reserved (4 chars)
    record += "    "
    # Reserved for NIMA (1 char)
    record += " "
    # Reserved (31 chars)
    record += " " * 31
    # Multiple accuracy outline flag (2 chars)
    record += "00"

    # Accuracy subregion descriptions (9 x 284 = 2556 chars)
    record += " " * 2556

    # Reserved for NIMA (18 chars)
    record += " " * 18
    # Reserved (69 chars)
    record += " " * 69

    raise "ACC wrong size: #{record.bytesize}, expected 2700" unless record.bytesize == 2700
    record
  end

  def generate_data_records
    data = ""

    @num_lon_lines.times do |lon_idx|
      data += generate_data_record(lon_idx)
    end

    data
  end

  def generate_data_record(lon_idx)
    # Recognition sentinel: 252 octal = 0xAA
    record = [0xAA].pack("C")

    # Data block count (3 bytes, big-endian)
    record += [lon_idx].pack("N")[1, 3]

    # Longitude count (2 bytes, big-endian)
    record += [lon_idx].pack("n")

    # Latitude count - starting latitude (2 bytes, big-endian)
    record += [0].pack("n")

    # Elevation values (each 2 bytes, signed magnitude, big-endian)
    @num_lat_points.times do |lat_idx|
      # Generate simple test elevations (0-100m range)
      elev = ((lon_idx + lat_idx) % 100)
      record += [elev].pack("n")
    end

    # Checksum: sum of all bytes as 8-bit unsigned values
    checksum = record.bytes.sum
    record += [checksum].pack("N")

    record
  end
end

# Generate the file
output_path = File.join(__dir__, "sample.dt0")
generator = DTEDGenerator.new(sw_lat: 0, sw_lon: 0)
File.binwrite(output_path, generator.generate)

size = File.size(output_path)
puts "Generated #{output_path}: #{size} bytes"
