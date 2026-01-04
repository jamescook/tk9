require "bundler/gem_tasks"
require 'rake/extensiontask'
require 'rake/testtask'
require 'rake/clean'

# Compiling on macOS with Homebrew:
#
# Tcl/Tk 9.0:
#   rake clean && rake compile -- --with-tcltkversion=9.0 \
#     --with-tcl-lib=$(brew --prefix tcl-tk)/lib \
#     --with-tcl-include=$(brew --prefix tcl-tk)/include/tcl-tk \
#     --with-tk-lib=$(brew --prefix tcl-tk)/lib \
#     --with-tk-include=$(brew --prefix tcl-tk)/include/tcl-tk \
#     --without-X11
#
# Tcl/Tk 8.6:
#   rake clean && rake compile -- --with-tcltkversion=8.6 \
#     --with-tcl-lib=$(brew --prefix tcl-tk@8)/lib \
#     --with-tcl-include=$(brew --prefix tcl-tk@8)/include \
#     --with-tk-lib=$(brew --prefix tcl-tk@8)/lib \
#     --with-tk-include=$(brew --prefix tcl-tk@8)/include \
#     --without-X11

# Clean up extconf cached config files
CLEAN.include('ext/tk/config_list')
CLOBBER.include('tmp', 'lib/*.bundle', 'lib/*.so', 'ext/**/*.o', 'ext/**/*.bundle', 'ext/**/*.bundle.dSYM')

# Clean coverage artifacts before test runs to prevent accumulation
CLEAN.include('coverage/.resultset.json', 'coverage/results')

Rake::ExtensionTask.new do |ext|
  ext.name = 'tcltklib'
  ext.ext_dir = 'ext/tk'
  ext.lib_dir = 'lib'
end

# NOTE: tkutil C extension eliminated - now pure Ruby in lib/tk/util.rb

desc "Clear stale coverage artifacts"
task :clean_coverage do
  require 'fileutils'
  FileUtils.rm_f('coverage/.resultset.json')
  FileUtils.rm_rf('coverage/results')
  FileUtils.mkdir_p('coverage/results')
end

Rake::TestTask.new(:test) do |t|
  t.libs << 'test'
  t.test_files = FileList['test/**/test_*.rb']
  t.verbose = true
end

task test: [:compile, :clean_coverage]

namespace :test do
  Rake::TestTask.new(:widget) do |t|
    t.libs << 'test'
    t.test_files = FileList['test/widget/test_*.rb']
    t.verbose = true
  end

  task widget: [:compile, :clean_coverage]
end

def detect_platform
  case RUBY_PLATFORM
  when /darwin/ then 'darwin'
  when /linux/ then 'linux'
  when /mingw|mswin/ then 'windows'
  else 'unknown'
  end
end

namespace :screenshots do
  desc "Generate screenshots (without comparison)"
  task generate: :compile do
    $LOAD_PATH.unshift(File.expand_path('lib', __dir__))
    require 'tk'
    platform = detect_platform
    tcl_version = "tcl#{Tk::TCL_VERSION}"
    output_dir = "screenshots/unverified/#{platform}/#{tcl_version}"
    ruby "-I", "lib", "test/visual_regression/widget_showcase.rb", output_dir
  end

  # Bless all tcl versions for a given platform
  def bless_platform(platform)
    require 'fileutils'
    unverified_base = "screenshots/unverified/#{platform}"
    unless Dir.exist?(unverified_base)
      puts "No unverified screenshots for #{platform}"
      return
    end

    total = 0
    Dir.glob("#{unverified_base}/tcl*").each do |tcl_dir|
      tcl_version = File.basename(tcl_dir)
      src = tcl_dir
      dst = "screenshots/blessed/#{platform}/#{tcl_version}"
      FileUtils.mkdir_p(dst)
      Dir.glob("#{src}/*.png").each do |f|
        FileUtils.cp(f, dst)
        puts "Blessed: #{platform}/#{tcl_version}/#{File.basename(f)}"
        total += 1
      end
    end
    puts "\nBlessed #{total} screenshots for #{platform}"
  end

  desc "Bless all unverified screenshots (all platforms)"
  task :bless do
    %w[darwin linux windows].each do |platform|
      bless_platform(platform)
    end
  end

  namespace :bless do
    desc "Bless Linux screenshots (from Docker)"
    task :linux do
      bless_platform('linux')
    end

    desc "Bless Darwin screenshots"
    task :darwin do
      bless_platform('darwin')
    end

    desc "Bless Windows screenshots"
    task :windows do
      bless_platform('windows')
    end
  end
end

task :default => :compile
