# frozen_string_literal: true

module Tk
  # Human-friendly comments for generated option declarations.
  # These get injected into generated code to help developers.
  OPTION_COMMENTS = {
    # Relief styles
    relief: "flat, raised, sunken, groove, ridge, solid",
    overrelief: "relief when mouse hovers",

    # Anchor/justify
    anchor: "n, ne, e, se, s, sw, w, nw, center",
    justify: "left, center, right",
    compound: "none, bottom, top, left, right, center",

    # State
    state: "normal, active, disabled",
    default: "normal, active, disabled",

    # Cursor blink timing
    insertofftime: "cursor blink off time (ms)",
    insertontime: "cursor blink on time (ms)",

    # Entry/text
    show: "character mask for passwords (e.g., '*')",
    validate: "none, focus, focusin, focusout, key, all",
    wrap: "none, char, word",

    # Scrolling
    scrollregion: "bounding box for scrolling",
    xscrollincrement: "horizontal scroll unit",
    yscrollincrement: "vertical scroll unit",

    # Canvas
    closeenough: "mouse proximity threshold (float)",
    confine: "restrict view to scroll region",

    # Selection
    selectmode: "single, browse, multiple, extended",
    exportselection: "export selection to X clipboard",

    # Fonts/text
    underline: "index of character to underline for keyboard shortcut (-1 for none)",
    wraplength: "max line length before wrapping",

    # Misc
    takefocus: "include in keyboard traversal",
    container: "embed other windows",
    cursor: "mouse cursor name",
  }.freeze
end
