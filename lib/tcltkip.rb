# frozen_string_literal: true
#
# TclTkIp Ruby extensions
#
# TclTkIp is defined in C (tcltklib.c). This file adds Ruby convenience
# methods. Modern Tcl (8.1+) uses UTF-8 internally, so encoding conversion
# methods are no-ops that always return UTF-8.

class TclTkIp
  # Aliases for encoding-aware vs raw C methods (now identical - all UTF-8)
  alias _eval_without_enc _eval
  alias __eval__ _eval
  alias _eval_with_enc _eval
  alias _invoke_without_enc _invoke
  alias __invoke__ _invoke
  alias _invoke_with_enc _invoke

  # For RemoteTkIp compatibility
  def _ip_id_
    ''
  end

  # Encoding methods - always UTF-8 in modern Tcl/Ruby
  def force_default_encoding=(mode); end
  def force_default_encoding? = true
  def default_encoding=(name); end
  def encoding=(name); end
  def encoding_name = 'utf-8'
  def encoding_obj = ::Encoding::UTF_8
  alias encoding encoding_name
  alias default_encoding encoding_name
end
