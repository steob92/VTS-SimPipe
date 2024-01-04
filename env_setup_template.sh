#!/bin/bash
# Project wide environment variables

# log files, submission scripts, etc.
export VTSIMPIPE_LOG_DIR=vtssimpipe_log_dir

################
# CORSIKA

# CORSIKA output
export VTSSIMPIPE_CORSIKA_DIR=vtssimpipe_corsika_dir
# CORSIKA executable (docker)
export VTSSIMPIPE_CORSIKA_EXE="docker run --rm -it -v "$(pwd):/workdir/external" vts-simpipe-corsika /workdir/corsika-run/corsika77500Linux_QGSII_urqmd"
