#!/bin/bash
# Project wide environment variables

# log files, submission scripts, etc.
export VTSSIMPIPE_LOG_DIR=vtssimpipe_log_dir
# output directory
export VTSSIMPIPE_DATA_DIR=vtssimpipe_corsika_dir
# container type
# export VTSSIMPIPE_CONTAINER="apptainer"
export VTSSIMPIPE_CONTAINER="docker"
# CORSIKA
export VTSSIMPIPE_CORSIKA_IMAGE="ghcr.io/gernotmaier/vtsimpipe-corsika:latest"
# GROPTICS
export VTSSIMPIPE_GROPTICS_IMAGE="ghcr.io/gernotmaier/vtsimpipe-groptics"
# CARE
export VTSSIMPIPE_CARE_IMAGE="ghcr.io/gernotmaier/vtsimpipe-care"
# MERGEVBF (Eventdisplay)
export VTSSIMPIPE_MERGEVBF_IMAGE="ghcr.io/veritas-observatory/eventdisplay_v4:latest"
