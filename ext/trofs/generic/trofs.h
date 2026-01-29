/*
 * trofs.h --
 */

#ifndef _TROFS
#define _TROFS

#include <tcl.h>

#ifndef CONST86
#define CONST86
#endif

/*
 * Only the _Init function is exported.
 */

extern DLLEXPORT int	Trofs_Init(Tcl_Interp * interp);

#endif /* _TROFS */
