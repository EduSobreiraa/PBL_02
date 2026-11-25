#!/bin/sh

if [ -n "${ALTERA_MF_V:-}" ]; then
    altera_mf_v=$ALTERA_MF_V
elif [ -n "${QUARTUS_ROOTDIR:-}" ]; then
    altera_mf_v=$QUARTUS_ROOTDIR/eda/sim_lib/altera_mf.v
else
    echo "ERROR: set ALTERA_MF_V or QUARTUS_ROOTDIR to the Quartus installation for official altsyncram simulation" >&2
    exit 2
fi

if [ ! -r "$altera_mf_v" ]; then
    echo "ERROR: official Quartus simulation library is not readable: $altera_mf_v" >&2
    echo "Set ALTERA_MF_V to altera_mf.v or QUARTUS_ROOTDIR to the Quartus root directory." >&2
    exit 2
fi
