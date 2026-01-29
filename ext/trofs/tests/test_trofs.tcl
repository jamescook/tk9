#!/usr/bin/env tclsh
#
# Basic tests for trofs extension
#
# Run with: TCLLIBPATH=/path/to/tmp/trofs tclsh test_trofs.tcl
#

# Add build directory to auto_path if TCLLIBPATH isn't set
if {![info exists env(TCLLIBPATH)] || $env(TCLLIBPATH) eq ""} {
    # Try to find the library relative to this script
    set script_dir [file dirname [file normalize [info script]]]
    set build_dir [file normalize [file join $script_dir ../../../tmp/trofs]]
    if {[file exists $build_dir]} {
        lappend auto_path $build_dir
    }
}

# Test counter
set tests_run 0
set tests_passed 0

proc test {name body} {
    global tests_run tests_passed
    incr tests_run
    puts -nonewline "  $name ... "
    if {[catch {uplevel 1 $body} result]} {
        puts "FAILED: $result"
    } else {
        puts "ok"
        incr tests_passed
    }
}

proc assert {condition {msg "assertion failed"}} {
    if {![uplevel 1 [list expr $condition]]} {
        error $msg
    }
}

proc assert_equal {expected actual} {
    if {$expected ne $actual} {
        error "expected '$expected', got '$actual'"
    }
}

puts "=== trofs Test Suite ==="
puts ""

# Test: Load package
puts "Loading trofs package..."
test "package require trofs" {
    package require trofs 0.4.9
}

# Verify commands exist
puts ""
puts "Checking trofs commands..."
test "trofs::archive command exists" {
    assert {[info commands ::trofs::archive] ne ""}
}

test "trofs::mount command exists" {
    assert {[info commands ::trofs::mount] ne ""}
}

test "trofs::unmount command exists" {
    assert {[info commands ::trofs::unmount] ne ""}
}

# Create temp directory for testing
set tmpdir [file join [file dirname [info script]] tmp_test_[pid]]
file mkdir $tmpdir
set srcdir [file join $tmpdir source]
set archive [file join $tmpdir test.trofs]
set mountpoint [file join $tmpdir mounted]

# Cleanup proc
proc cleanup {} {
    global tmpdir mountpoint
    catch {::trofs::unmount $mountpoint}
    catch {file delete -force $tmpdir}
}

# Setup test files
puts ""
puts "Setting up test data..."
test "create test directory structure" {
    file mkdir $srcdir
    file mkdir [file join $srcdir subdir]

    # Create test files
    set f [open [file join $srcdir hello.txt] w]
    puts $f "Hello, trofs!"
    close $f

    set f [open [file join $srcdir subdir/nested.txt] w]
    puts $f "Nested file content"
    close $f

    assert {[file exists [file join $srcdir hello.txt]]}
    assert {[file exists [file join $srcdir subdir/nested.txt]]}
}

# Test archive creation
puts ""
puts "Testing archive creation..."
test "create trofs archive" {
    # archive takes: source_directory archive_file
    ::trofs::archive $srcdir $archive
    assert {[file exists $archive]}
}

# Test mounting
puts ""
puts "Testing mount/unmount..."
test "mount archive" {
    ::trofs::mount $archive $mountpoint
    assert {[file exists $mountpoint]}
    assert {[file isdirectory $mountpoint]}
}

test "read file from mounted archive" {
    set f [open [file join $mountpoint hello.txt] r]
    set content [read $f]
    close $f
    assert_equal "Hello, trofs!\n" $content
}

test "read nested file from mounted archive" {
    set f [open [file join $mountpoint subdir/nested.txt] r]
    set content [read $f]
    close $f
    assert_equal "Nested file content\n" $content
}

test "list directory contents" {
    set files [lsort [glob -directory $mountpoint *]]
    # Should contain hello.txt and subdir
    assert {[llength $files] == 2}
}

test "glob pattern matching" {
    set txtfiles [glob -directory $mountpoint *.txt]
    assert {[llength $txtfiles] == 1}
    assert {[file tail [lindex $txtfiles 0]] eq "hello.txt"}
}

test "unmount archive" {
    ::trofs::unmount $mountpoint
    # After unmount, the directory should not exist or be empty
    assert {![file exists [file join $mountpoint hello.txt]]}
}

# Cleanup
cleanup

# Summary
puts ""
puts "=== Results ==="
puts "Tests run: $tests_run"
puts "Tests passed: $tests_passed"
puts "Tests failed: [expr {$tests_run - $tests_passed}]"
puts ""

if {$tests_passed == $tests_run} {
    puts "All tests passed!"
    exit 0
} else {
    puts "Some tests failed."
    exit 1
}
