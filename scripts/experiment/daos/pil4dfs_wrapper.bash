#!/bin/bash

DAOS_INSTALL=${AOS_DAOS_INSTALL:-/usr}

LIBPIL4DFS_SO="libpil4dfs.so"

if [ -f $DAOS_INSTALL/lib/$LIBPIL4DFS_SO ]; then
    DAOS_LIBPIL4DFS=$DAOS_INSTALL/lib/$LIBPIL4DFS_SO
elif [ -f $DAOS_INSTALL/lib64/$LIBPIL4DFS_SO ]; then
    DAOS_LIBPIL4DFS=$DAOS_INSTALL/lib64/$LIBPIL4DFS_SO
else
    echo >&2 "ERROR: Could not locate $LIBPIL4DFS_SO in DAOS installation ($DAOS_INSTALL)"
    exit 1
fi

# Report ALL intercept calls
#export D_IL_REPORT=-1

# Report first ten intercept calls of each operation type (e.g. read/write/stat)
#export D_IL_REPORT=10

# Report summary of intercept calls
#export D_IL_REPORT=0

# Execute program+args given as script args with DAOS I/O interception 
LD_PRELOAD=$DAOS_LIBPIL4DFS $*
