# Sample Test Guidelines

Notes for writing tests that exercise the samples in `sample/`.

## The Problem

Samples run as subprocesses. The test harness sends SIGTERM after receiving a "ready" signal. If your sample relies on async timers (`after`), they won't fire before SIGTERM kills the process.

## What Works

### 1. Wait for UI visibility before interacting

Don't interact with widgets until they're actually visible:

```ruby
Tk.root.bind('Visibility') { @visible = true }
```

### 2. Simulate clicks with invoke, not after timers

**Bad** - SIGTERM arrives before timer fires:
```ruby
Tk.after(100) { btn.invoke }
```

**Good** - Immediate:
```ruby
btn.invoke
```

### 3. Let the sample exit naturally when possible

If your sample exits when all windows close, just click the close buttons and let it exit. The test can check stdout after the process completes.

## Example Pattern

See `lib/tk/demo_support.rb` for the standard TkDemo pattern:

```ruby
require 'tk/demo_support'

if TkDemo.active?
  TkDemo.on_visible {
    btn.invoke
    TkDemo.finish
  }
end
```

## Common Gotchas

- **Buffered stdout**: Use `$stdout.sync = true` at the top of the sample
- **Multiple interpreters**: Each needs its own visibility check and button invoke
