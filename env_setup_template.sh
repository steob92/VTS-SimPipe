#!/bin/bash
# Project wide environment variables

# log files, submission scripts, etc.
export VTSSIMPIPE_LOG_DIR=vtssimpipe_log_dir

################
# CORSIKA

# CORSIKA output
export VTSSIMPIPE_CORSIKA_DIR=vtssimpipe_corsika_dir

# CORSIKA executable
# Provide the CORSIKA command to be called for processing.

# CORSIKA executable (apptainer)
export VTSSIMPIPE_CORSIKA_EXE="apptainer exec --cleanenv --compat docker://ghcr.io/gernotmaier/vtsimpipe-corsika:latest /workdir/corsika-run/corsika77500Linux_QGSII_urqmd"
# CORSIKA executable (docker)
# Important: the string CORSIKA_DIRECTORIES will be replace by the submission scripts
# with the correct directories
# export VTSSIMPIPE_CORSIKA_EXE="docker run --rm CORSIKA_DIRECTORIES vts-simpipe-corsika bash -c \"cd /workdir/corsika-run && ./corsika77500Linux_QGSII_urqmd < CORSIKAINPUTFILE\""
