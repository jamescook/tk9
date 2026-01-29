# frozen_string_literal: true

require 'minitest/autorun'
require 'fileutils'
require 'tmpdir'

# Test trofs extension loading via Tcl
# Requires: rake compile (main tk extension) and rake trofs:compile
class TestTrofs < Minitest::Test
  def setup
    @trofs_dir = File.expand_path('..', __dir__)
    @lib_dir = File.expand_path('../../../lib', __dir__)

    # Add lib to load path for requiring tk
    $LOAD_PATH.unshift(@lib_dir) unless $LOAD_PATH.include?(@lib_dir)

    require 'tk'

    # Add trofs to Tcl's package search path
    Tk.tk_call('lappend', 'auto_path', @trofs_dir)

    # Set TROFS_LIBRARY for finding the Tcl scripts
    ENV['TROFS_LIBRARY'] = File.join(@trofs_dir, 'library')
  end

  def test_package_loads
    version = TkPackage.require('trofs')
    assert_equal '0.4.9', version
  end

  def test_commands_exist
    TkPackage.require('trofs')

    commands = Tk.tk_call('info', 'commands', '::trofs::*').split
    assert_includes commands, '::trofs::archive'
    assert_includes commands, '::trofs::mount'
    assert_includes commands, '::trofs::unmount'
  end

  def test_archive_mount_unmount
    TkPackage.require('trofs')

    Dir.mktmpdir do |tmpdir|
      # Create source directory with test file
      src_dir = File.join(tmpdir, 'source')
      FileUtils.mkdir_p(src_dir)
      File.write(File.join(src_dir, 'hello.txt'), "Hello from trofs!\n")

      # Create archive
      archive = File.join(tmpdir, 'test.trofs')
      Tk.tk_call('::trofs::archive', src_dir, archive)
      assert File.exist?(archive), "Archive should be created"

      # Mount archive
      mount_point = File.join(tmpdir, 'mounted')
      Tk.tk_call('::trofs::mount', archive, mount_point)

      # Read file through mount - need to open then read separately
      chan = Tk.tk_call('open', "#{mount_point}/hello.txt", 'r')
      content = Tk.tk_call('read', chan)
      Tk.tk_call('close', chan)
      assert_equal "Hello from trofs!\n", content

      # Unmount
      Tk.tk_call('::trofs::unmount', mount_point)
    end
  end
end
