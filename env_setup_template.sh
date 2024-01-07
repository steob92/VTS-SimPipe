#!/bin/bash
# Project wide environment variables

# log files, submission scripts, etc.
export VTSSIMPIPE_LOG_DIR=vtssimpipe_log_dir
# output directory
export VTSSIMPIPE_DATA_DIR=vtssimpipe_corsika_dir
# container type
export VTSSIMPIPE_CONTAINER="apptainer"
# export VTSSIMPIPE_CONTAINER="docker"

################
# CORSIKA

# CORSIKA executable
# Provide the CORSIKA command to be called for processing.
export VTSSIMPIPE_CORSIKA_IMAGE="ghcr.io/gernotmaier/vtsimpipe-corsika:latest"
