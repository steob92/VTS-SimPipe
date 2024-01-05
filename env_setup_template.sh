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

export VTSSIMPIPE_IMAGE="ghcr.io/gernotmaier/vtsimpipe-corsika:latest"
export VTSSIMPIPE_CORSIKA_EXE="apptainer"
# export VTSSIMPIPE_CORSIKA_EXE="docker"
