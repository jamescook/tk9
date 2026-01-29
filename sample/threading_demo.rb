#!/usr/bin/env ruby
# frozen_string_literal: true
# tk-record: screen_size=975x405
#
# Concurrency Demo - File Hasher
#
# Compares three concurrency modes:
# - None: Direct execution, UI updates via Tk.update. Fast but blocks controls.
# - Thread: Background thread with on_main_thread. Enables Pause but has GVL overhead.
# - Ractor: True parallelism (separate GVL). Best throughput, enables Stop.
#
require 'tk'
require 'digest'
require 'tmpdir'
require_relative 'tkballoonhelp'

class ThreadingDemo
  ALGORITHMS = %w[SHA256 SHA512 SHA384 SHA1 MD5].freeze
  MODES = %w[None Thread Ractor].freeze

  def initialize
    @root = Tk.root
    @root.title('Concurrency Demo - File Hasher')
    @root.minsize(600, 400)
    @chunk_size = TkVariable.new(3)
    @algorithm = TkVariable.new('SHA256')
    @mode = TkVariable.new('Thread')
    @allow_pause = TkVariable.new(0)  # Checkbox: 0=off, 1=on
    @running = false
    @paused = false
    @stop_requested = false
    @background_task = nil  # TkCore.background_work task

    build_ui
    collect_files

    Tk.update
    # Position at 0,0 for recording, preserve calculated size
    @root.geometry("#{@root.winfo_width}x#{@root.winfo_height}+0+0")
    @root.resizable(true, true)

    # Report calculated size for recording setup
    puts "Window size: #{@root.winfo_width}x#{@root.winfo_height}"
  end

  def build_ui
    TkLabel.new(@root,
      text: "File hasher demo - compares None/Thread/Ractor modes.\n" \
            "None: fast but controls blocked. Thread: Pause works, GVL overhead. " \
            "Ractor: true parallel, best throughput (Ruby 4 optimal).",
      justify: :left
    ).pack(fill: :x, padx: 10, pady: 10)

    ctrl_frame = TkFrame.new(@root).pack(fill: :x, padx: 10, pady: 5)

    @start_btn = TkButton.new(ctrl_frame, text: 'Start', command: proc { start_hashing })
    @start_btn.pack(side: :left)

    @pause_btn = TkButton.new(ctrl_frame, text: 'Pause', state: :disabled, command: proc { toggle_pause })
    @pause_btn.pack(side: :left, padx: 5)

    @reset_btn = TkButton.new(ctrl_frame, text: 'Reset', command: proc { reset })
    @reset_btn.pack(side: :left)

    TkLabel.new(ctrl_frame, text: 'Algorithm:').pack(side: :left, padx: 10)
    @algo_combo = Tk::Tile::Combobox.new(ctrl_frame,
      textvariable: @algorithm,
      values: ALGORITHMS,
      width: 8,
      state: :readonly
    )
    @algo_combo.pack(side: :left)

    TkLabel.new(ctrl_frame, text: 'Batch:').pack(side: :left, padx: 10)
    @batch_label = TkLabel.new(ctrl_frame, text: '3', width: 3)
    @batch_label.pack(side: :left)

    Tk::Tile::Scale.new(ctrl_frame,
      orient: :horizontal,
      from: 1,
      to: 100,
      length: 100,
      variable: @chunk_size,
      command: proc { |v| @batch_label.text = v.to_f.round.to_s }
    ).pack(side: :left, padx: 5)

    TkLabel.new(ctrl_frame, text: 'Mode:').pack(side: :left, padx: 10)
    @mode_combo = Tk::Tile::Combobox.new(ctrl_frame,
      textvariable: @mode,
      values: MODES,
      width: 7,
      state: :readonly
    )
    @mode_combo.pack(side: :left)

    @pause_check = Tk::Tile::Checkbutton.new(ctrl_frame,
      text: 'Allow Pause',
      variable: @allow_pause
    )
    @pause_check.pack(side: :left, padx: 10)
    # Tooltip for pause checkbox (skip in recording mode - Ttk incompatible)
    unless ENV['TK_RECORD']
      Tk::RbWidget::BalloonHelp.new(@pause_check,
        text: "Enables pause for Ractor mode.\nAdds overhead on Ruby 3.x (~16ms/batch).\nRuby 4.0+ has no overhead.",
        interval: 500)
    end

    # Statusbar
    statusbar = TkFrame.new(@root)
    statusbar.pack(side: :bottom, fill: :x, padx: 5, pady: 5)

    # Progress section (left)
    progress_frame = TkFrame.new(statusbar, relief: :sunken, borderwidth: 2)
    progress_frame.pack(side: :left, fill: :x, expand: true, padx: 2)

    @progress_var = TkVariable.new(0)
    Tk::Tile::Progressbar.new(progress_frame,
      orient: :horizontal,
      length: 200,
      mode: :determinate,
      variable: @progress_var,
      maximum: 100
    ).pack(side: :left, padx: 5, pady: 4)

    @status_label = TkLabel.new(progress_frame, text: 'Ready', width: 20, anchor: :w)
    @status_label.pack(side: :left, padx: 10)

    @current_file_label = TkLabel.new(progress_frame, text: '', width: 28, anchor: :w)
    @current_file_label.pack(side: :left, padx: 5)

    # Info section (right)
    info_frame = TkFrame.new(statusbar, relief: :sunken, borderwidth: 2)
    info_frame.pack(side: :right, padx: 2)

    @file_count_label = TkLabel.new(info_frame, text: '', width: 12, anchor: :e)
    @file_count_label.pack(side: :left, padx: 8, pady: 4)

    Tk::Tile::Separator.new(info_frame, orient: :vertical).pack(side: :left, fill: :y, pady: 4)

    TkLabel.new(info_frame, text: "Ruby #{RUBY_VERSION}", anchor: :e).pack(side: :left, padx: 8, pady: 4)

    # Log
    log_outer = TkLabelFrame.new(@root, text: 'Output', relief: :groove)
    log_outer.pack(fill: :both, expand: true, padx: 10, pady: 5)

    log_frame = TkFrame.new(log_outer)
    log_frame.pack(fill: :both, expand: true, padx: 5, pady: 5)
    log_frame.pack_propagate(false)

    @log = TkText.new(log_frame, width: 80, height: 15, wrap: :none)
    @log.pack(side: :left, fill: :both, expand: true)

    scrollbar = TkScrollbar.new(log_frame)
    scrollbar.pack(side: :right, fill: :y)
    @log.yscrollbar(scrollbar)
  end

  def collect_files
    base = File.exist?('/app') ? '/app' : Dir.pwd
    @files = Dir.glob("#{base}/**/*", File::FNM_DOTMATCH).select { |f| File.file?(f) }
    @files.reject! { |f| f.include?('/.git/') }
    @files.sort!
    @file_count_label.text = "#{@files.size} files"
  end

  def current_mode
    @mode.to_s
  end

  def start_hashing
    @running = true
    @paused = false
    @stop_requested = false
    @start_btn.state = :disabled
    @algo_combo.state = :disabled
    @mode_combo.state = :disabled
    @log.delete('1.0', :end)
    @progress_var.value = 0
    @status_label.text = "Hashing..."

    # Pause available in Thread mode always, Ractor mode only if Allow Pause checked
    @pause_btn.state = case current_mode
      when 'None' then :disabled
      when 'Thread' then :normal
      when 'Ractor' then @allow_pause.to_i == 1 ? :normal : :disabled
    end

    # Disable resize during hashing (resize events block main thread)
    @root.resizable(false, false) unless current_mode == 'Ractor'

    @metrics = {
      start_time: Process.clock_gettime(Process::CLOCK_MONOTONIC),
      ui_update_count: 0,
      ui_update_total_ms: 0.0,
      total: @files.size,
      files_done: 0,
      mode: current_mode
    }

    case current_mode
    when 'None'
      hash_files_direct
    when 'Thread'
      start_background_work(:thread)
    when 'Ractor'
      start_background_work(:ractor)
    end
  end

  def toggle_pause
    @paused = !@paused
    @pause_btn.text = @paused ? 'Resume' : 'Pause'
    @status_label.text = @paused ? 'Paused' : 'Hashing...'
    @root.resizable(@paused, @paused)
    @mode_combo.state = @paused ? :readonly : :disabled

    # Send pause/resume message to background task
    if @background_task
      @paused ? @background_task.pause : @background_task.resume
    end

    write_metrics("PAUSED") if @paused && @metrics
  end

  def reset
    @stop_requested = true
    @paused = false
    @running = false

    # Stop background task if running
    @background_task&.stop
    @background_task = nil

    @start_btn.state = :normal
    @pause_btn.state = :disabled
    @pause_btn.text = 'Pause'
    @algo_combo.state = :readonly
    @mode_combo.state = :readonly
    @root.resizable(true, true)
    @log.delete('1.0', :end)
    @progress_var.value = 0
    @status_label.text = 'Ready'
    @current_file_label.text = ''

    # Reset all inputs to initial values
    @mode.value = 'Thread'
    @algorithm.value = 'SHA256'
    @chunk_size.value = 3
    @batch_label.text = '3'
    @allow_pause.value = 0
  end

  def write_metrics(status = "DONE")
    return unless @metrics
    m = @metrics
    elapsed = Process.clock_gettime(Process::CLOCK_MONOTONIC) - m[:start_time]
    # Use tmpdir if sample dir isn't writable (e.g., Docker read-only mount)
    dir = File.writable?(__dir__) ? __dir__ : Dir.tmpdir
    File.open(File.join(dir, 'threading_demo_metrics.log'), 'a') do |f|
      f.puts "=" * 60
      f.puts "Status: #{status} at #{Time.now}"
      f.puts "Mode: #{m[:mode]}"
      f.puts "Algorithm: #{@algorithm}"
      f.puts "Files processed: #{m[:files_done]}/#{m[:total]}"
      f.puts "Batch size: #{[@chunk_size.to_f.round, 1].max}"
      f.puts "-" * 40
      f.puts "Elapsed: #{elapsed.round(3)}s"
      f.puts "UI updates: #{m[:ui_update_count]}"
      f.puts "UI update total: #{m[:ui_update_total_ms].round(1)}ms" if m[:ui_update_total_ms]
      f.puts "UI update avg: #{(m[:ui_update_total_ms] / m[:ui_update_count]).round(2)}ms" if m[:ui_update_count] > 0 && m[:ui_update_total_ms]
      f.puts "Files/sec: #{(m[:files_done] / elapsed).round(1)}" if elapsed > 0
      f.puts
    end
  end

  def truncate_filename(name, max = 25)
    name.length > max ? "#{name[0, max]}..." : name
  end

  def finish_hashing
    write_metrics("DONE") unless @stop_requested
    return if @stop_requested

    elapsed = Process.clock_gettime(Process::CLOCK_MONOTONIC) - @metrics[:start_time]
    files_per_sec = (@metrics[:files_done] / elapsed).round(1)
    @status_label.text = "Done #{elapsed.round(2)}s (#{files_per_sec}/s)"
    @current_file_label.text = ''
    @start_btn.state = :normal
    @pause_btn.state = :disabled
    @algo_combo.state = :readonly
    @mode_combo.state = :readonly
    @root.resizable(true, true)
    @running = false
  end

  UI_THROTTLE_MS = 10

  # ─────────────────────────────────────────────────────────────
  # Mode: None (direct execution)
  # ─────────────────────────────────────────────────────────────

  def hash_files_direct
    total = @files.size
    pending_updates = []
    algo = Digest.const_get(@algorithm.to_s)
    last_ui_update = 0.0

    @files.each_with_index do |path, index|
      break if @stop_requested

      begin
        hash = algo.file(path).hexdigest
        short_path = path.sub(%r{^/app/}, '').sub(Dir.pwd + '/', '')
        pending_updates << "#{short_path}: #{hash}\n"
      rescue StandardError => e
        short_path = path.sub(%r{^/app/}, '').sub(Dir.pwd + '/', '')
        pending_updates << "#{short_path}: ERROR - #{e.message}\n"
      end

      chunk_size = [@chunk_size.to_f.round, 1].max
      is_last = index == total - 1
      now = Process.clock_gettime(Process::CLOCK_MONOTONIC, :millisecond)
      time_ok = (now - last_ui_update) >= UI_THROTTLE_MS

      if (pending_updates.size >= chunk_size && time_ok) || is_last
        ui_start = Process.clock_gettime(Process::CLOCK_MONOTONIC)

        @log.insert(:end, pending_updates.join)
        @log.see(:end)
        @progress_var.value = ((index + 1).to_f / total * 100).round
        @status_label.text = "Hashing... #{index + 1}/#{total}"
        @current_file_label.text = truncate_filename(File.basename(path))
        Tk.update

        pending_updates.clear
        last_ui_update = now
        @metrics[:ui_update_count] += 1
        @metrics[:ui_update_total_ms] += (Process.clock_gettime(Process::CLOCK_MONOTONIC) - ui_start) * 1000
        @metrics[:files_done] = index + 1
      end
    end

    finish_hashing
  end

  # ─────────────────────────────────────────────────────────────
  # Mode: Thread or Ractor (unified via TkCore.background_work)
  # ─────────────────────────────────────────────────────────────

  def start_background_work(mode)
    # Prepare shareable data for the worker
    files = @files.dup
    algo_name = @algorithm.to_s
    chunk_size = [@chunk_size.to_f.round, 1].max
    base_dir = Dir.pwd
    allow_pause = @allow_pause.to_i == 1

    work_data = {
      files: files,
      algo_name: algo_name,
      chunk_size: chunk_size,
      base_dir: base_dir,
      allow_pause: allow_pause
    }

    # For Ractor mode, data must be shareable
    if mode == :ractor
      work_data = Ractor.make_shareable({
        files: Ractor.make_shareable(files.freeze),
        algo_name: algo_name.freeze,
        chunk_size: chunk_size,
        base_dir: base_dir.freeze,
        allow_pause: allow_pause
      })
    end

    @background_task = TkCore.background_work(work_data, mode: mode) do |task, data|
      algo_class = Digest.const_get(data[:algo_name])
      total = data[:files].size
      pending = []

      data[:files].each_with_index do |path, index|
        # Check for pause message at batch boundaries
        if data[:allow_pause] && pending.empty?
          task.check_pause
        end

        begin
          hash = algo_class.file(path).hexdigest
          short_path = path.sub(%r{^/app/}, '').sub(data[:base_dir] + '/', '')
          pending << "#{short_path}: #{hash}\n"
        rescue StandardError => e
          short_path = path.sub(%r{^/app/}, '').sub(data[:base_dir] + '/', '')
          pending << "#{short_path}: ERROR - #{e.message}\n"
        end

        is_last = index == total - 1
        if pending.size >= data[:chunk_size] || is_last
          task.yield({
            index: index,
            total: total,
            updates: pending.join
          })
          pending = []
        end
      end
    end.on_progress do |msg|
      ui_start = Process.clock_gettime(Process::CLOCK_MONOTONIC)

      @log.insert(:end, msg[:updates])
      @log.see(:end)
      @progress_var.value = ((msg[:index] + 1).to_f / msg[:total] * 100).round
      @status_label.text = "Hashing... #{msg[:index] + 1}/#{msg[:total]}"

      @metrics[:ui_update_count] += 1
      @metrics[:ui_update_total_ms] ||= 0.0
      @metrics[:ui_update_total_ms] += (Process.clock_gettime(Process::CLOCK_MONOTONIC) - ui_start) * 1000
      @metrics[:files_done] = msg[:index] + 1
    end.on_done do
      @background_task = nil
      finish_hashing
    end
  end

  def run
    Tk.mainloop
  end
end

# Automated demo support (testing and recording)
require 'tk/demo_support'

if TkDemo.active?
  # Set up visibility binding BEFORE creating demo (which makes window visible)
  demo = nil
  TkDemo.on_visible {
    # Small delay to let demo assignment complete (Tk.update in constructor triggers this early)
    Tk.after(100) {
      # Quick mode: just run Thread mode once for smoke test
      quick_mode = ARGV.include?('--quick')

      if quick_mode
        puts "[DEMO] Quick smoke test (Thread mode only)"
      else
        puts "[DEMO] Testing all modes with batch=100"
      end

      # Get UI widgets
      chunk_var = demo.instance_variable_get(:@chunk_size)
      mode_combo = demo.instance_variable_get(:@mode_combo)
      start_btn = demo.instance_variable_get(:@start_btn)
      reset_btn = demo.instance_variable_get(:@reset_btn)
      allow_pause_var = demo.instance_variable_get(:@allow_pause)

      # Set batch size to 100
      chunk_var.value = 100

      # Test matrix: [mode, pause_enabled]
      tests = if quick_mode
        [['Thread', false]]  # Just one quick test
      else
        [
          ['None', false],
          ['Thread', false],
          ['Thread', true],
          ['Ractor', false],
          ['Ractor', true]
        ]
      end
      test_index = 0

      run_next_test = proc do
        if test_index < tests.size
          mode, pause = tests[test_index]
          puts "[DEMO] #{mode}#{pause ? ' +pause' : ''}"

          # Configure mode and pause
          mode_combo.set(mode)
          allow_pause_var.value = pause ? 1 : 0

          # Start hashing
          Tk.after(100) { start_btn.invoke }

          # Wait for completion
          check_done = proc do
            if demo.instance_variable_get(:@running)
              Tk.after(200, &check_done)
            else
              test_index += 1
              if test_index < tests.size
                Tk.after(200) {
                  reset_btn.invoke
                  Tk.after(200, &run_next_test)
                }
              else
                puts "[DEMO] All tests completed"
                Tk.after(200) { TkDemo.finish }
              end
            end
          end
          Tk.after(500, &check_done)
        end
      end

      run_next_test.call
    }
  }

  # Create demo AFTER binding is set up
  demo = ThreadingDemo.new
  Tk.mainloop
else
  ThreadingDemo.new.run
end
