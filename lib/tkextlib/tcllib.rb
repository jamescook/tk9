# frozen_string_literal: true
#
# tcllib/tklib extension - REMOVED
#

warn "tkextlib/tcllib has been removed (January 2026). " \
     "See lib/tkextlib/tcllib/DEPRECATED.md for details."

# Provide empty module so existing code doesn't crash on Tk::Tcllib references
module Tk
  module Tcllib
  end
end
