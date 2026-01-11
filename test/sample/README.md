# Sample Test Guidelines

Notes for writing tests that exercise the samples in `sample/`.

## The Problem

Samples run as subprocesses. The test harness sends SIGTERM after receiving a "ready" signal. If your sample relies on async timers (`after`), they won't fire before SIGTERM kills the process.

## What Works

### 1. Wait for UI visibility before interacting

Don't interact with widgets until they're actually visible:

```ruby
# In Tcl
bridge.eval('bind . <Visibility> { set ::visible 1 }')

# Check in event loop
if bridge.eval('info exists ::visible') == '1'
  # Now safe to interact
end
```

Or with the legacy Tk API:
```ruby
Tk.root.bind('Visibility') { ... }
```

### 2. Simulate clicks with invoke, not after timers

**Bad** - SIGTERM arrives before timer fires:
```ruby
bridge.eval("after 100 {.btn invoke}")
```

**Good** - Immediate, synchronous:
```ruby
bridge.invoke(".btn", "invoke")
bridge.dispatch_pending_callbacks  # Run any queued Ruby callbacks
```

### 3. For Tk::Bridge, dispatch callbacks after invoke

Tk::Bridge queues callbacks in a Tcl variable. They only execute when you call `dispatch_pending_callbacks`:

```ruby
bridge.invoke(".close", "invoke")      # Queues the callback
bridge.dispatch_pending_callbacks      # Actually runs the Ruby proc
```

### 4. Let the sample exit naturally when possible

If your sample exits when all windows close, just click the close buttons and let it exit. The test can check stdout after the process completes.

## Example Pattern

```ruby
# In the sample
if ENV['TK_READY_FD']
  # Set up visibility detection
  bridge.eval('set ::visible 0')
  bridge.eval('bind . <Visibility> { set ::visible 1 }')
end

# In event loop
if smoke_test_mode && !done
  if bridge.eval('set ::visible') == '1'
    bridge.invoke(".close", "invoke")
    bridge.dispatch_pending_callbacks
    done = true
  end
end
```

## Common Gotchas

- **Buffered stdout**: Use `$stdout.sync = true` at the top of the sample
- **Multiple interpreters**: Each needs its own visibility check and button invoke
- **Signal handlers**: `tcltk_compat.rb`'s SIGTERM handler doesn't work well with multiple interpreters or Tk::Bridge - let samples exit naturally instead
