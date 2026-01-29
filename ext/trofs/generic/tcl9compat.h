/*
 * tcl9compat.h --
 *
 *     Compatibility macros for building trofs with Tcl 8.6+ and Tcl 9.x
 *
 * This header provides compatibility shims so that trofs can be built
 * against both Tcl 8.6 and Tcl 9.0+. The main changes in Tcl 9 are:
 *
 *   - TCL_CHANNEL_VERSION_3 removed, minimum is TCL_CHANNEL_VERSION_5
 *   - closeProc and seekProc fields in Tcl_ChannelType are now void*
 *   - Tcl_ChannelSeekProc() removed, use Tcl_ChannelWideSeekProc()
 *   - Tcl_DriverCloseProc and Tcl_DriverSeekProc are now void types
 *   - int size parameters changed to Tcl_Size (long on 64-bit)
 */

#ifndef TCL9COMPAT_H
#define TCL9COMPAT_H

#include <tcl.h>

/*
 * Tcl_Size was added in Tcl 8.7/9.0. For older versions, use int.
 */
#ifndef TCL_SIZE_MAX
typedef int Tcl_Size;
#define TCL_SIZE_MAX INT_MAX
#endif

/*
 * Channel version compatibility.
 * Tcl 9 requires at least VERSION_5. Tcl 8.6 supports VERSION_3.
 */
#if TCL_MAJOR_VERSION >= 9
#  define TROFS_CHANNEL_VERSION TCL_CHANNEL_VERSION_5
#else
#  define TROFS_CHANNEL_VERSION TCL_CHANNEL_VERSION_3
#endif

/*
 * In Tcl 9, the closeProc field is void* and close2Proc is used.
 * In Tcl 8, closeProc is still valid.
 * We use close2Proc for both since it's available in Tcl 8.4+.
 */
#if TCL_MAJOR_VERSION >= 9
#  define TROFS_CLOSE_PROC NULL
#  define TROFS_CLOSE2_PROC DriverClose2
#else
#  define TROFS_CLOSE_PROC DriverClose
#  define TROFS_CLOSE2_PROC NULL
#endif

/*
 * In Tcl 9, the seekProc field is void* and only wideSeekProc is used.
 * In Tcl 8, both are supported but we prefer wideSeekProc.
 */
#if TCL_MAJOR_VERSION >= 9
#  define TROFS_SEEK_PROC NULL
#else
#  define TROFS_SEEK_PROC DriverSeek
#endif

/*
 * Tcl_ChannelSeekProc() was removed in Tcl 9.
 * The code now only uses Tcl_ChannelWideSeekProc() which exists in both.
 */
#if TCL_MAJOR_VERSION >= 9
#  define TROFS_HAS_CHANNEL_SEEK_PROC 0
#else
#  define TROFS_HAS_CHANNEL_SEEK_PROC 1
#endif

#endif /* TCL9COMPAT_H */
