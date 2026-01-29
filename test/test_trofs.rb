# frozen_string_literal: true

# Tests for Tk::Trofs - Tcl Read-Only Filesystem extension
#
# trofs allows creating and mounting read-only archive files,
# useful for single-file distribution of Tcl packages.

require_relative 'test_helper'
require_relative 'tk_test_helper'

class TestTrofs < Minitest::Test
  include TkTestHelper

  def test_trofs_package_loads
    assert_tk_app("Tk::Trofs package loads", method(:app_trofs_loads))
  end

  def app_trofs_loads
    require 'tk'

    # Add trofs build directory to Tcl's package path
    # Note: __dir__ doesn't work in eval'd subprocess code, so use $LOAD_PATH to find project root
    lib_dir = $LOAD_PATH.find { |p| p.end_with?('/lib') && File.exist?(File.join(p, 'tk.rb')) }
    project_root = lib_dir ? File.dirname(lib_dir) : '/app'
    trofs_dir = File.join(project_root, 'ext/trofs')
    if File.exist?(trofs_dir)
      Tk.tk_call('lappend', 'auto_path', trofs_dir)
      ENV['TROFS_LIBRARY'] = File.join(trofs_dir, 'library')
    end

    require 'tkextlib/trofs'

    # Check package info
    raise "package_name wrong" unless Tk::Trofs.package_name == 'trofs'

    version = Tk::Trofs.package_version
    raise "package_version should return string" unless version.is_a?(String)
  end

  def test_trofs_archive_mount_unmount
    assert_tk_app("Tk::Trofs archive/mount/unmount", method(:app_trofs_operations))
  end

  def app_trofs_operations
    require 'tk'
    require 'fileutils'
    require 'tmpdir'

    # Add trofs build directory to Tcl's package path
    # Note: __dir__ doesn't work in eval'd subprocess code, so use $LOAD_PATH to find project root
    lib_dir = $LOAD_PATH.find { |p| p.end_with?('/lib') && File.exist?(File.join(p, 'tk.rb')) }
    project_root = lib_dir ? File.dirname(lib_dir) : '/app'
    trofs_dir = File.join(project_root, 'ext/trofs')
    if File.exist?(trofs_dir)
      Tk.tk_call('lappend', 'auto_path', trofs_dir)
      ENV['TROFS_LIBRARY'] = File.join(trofs_dir, 'library')
    end

    require 'tkextlib/trofs'

    Dir.mktmpdir do |tmpdir|
      # Create source directory with test file
      src_dir = File.join(tmpdir, 'source')
      FileUtils.mkdir_p(src_dir)
      File.write(File.join(src_dir, 'test.txt'), "Hello from trofs!")

      # Create archive using Tk::Trofs
      archive = File.join(tmpdir, 'test.trofs')
      Tk::Trofs.create_archive(src_dir, archive)
      raise "archive not created" unless File.exist?(archive)

      # Mount archive
      mount_point = File.join(tmpdir, 'mounted')
      result = Tk::Trofs.mount(archive, mount_point)
      raise "mount should return path" if result.nil? || result.empty?

      # Verify we can see the mounted content via Tcl
      exists = Tk.tk_call('file', 'exists', "#{mount_point}/test.txt")
      raise "file should exist in mount" unless exists == '1'

      # Unmount
      Tk::Trofs.umount(mount_point)
    end
  end
end
