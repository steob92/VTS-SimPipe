#!/bin/bash
# Prepare all simulation production steps

if [ $# -lt 2 ]; then
    echo "./prepare_all_production_steps.sh <config file> <corsika input file> [remove previous file (Dangerous!)"
    exit
fi

CONFIG="$1"
INPUT="$2"
CLEAN_ALL_FILES="$3"

# shellcheck source=/dev/null
. "$(dirname "$0")"/../env_setup.sh
# shellcheck source=/dev/null
. "$CONFIG"
DIRSUFF="ATM${ATMOSPHERE}/Zd${ZENITH}"

for step in CORSIKA GROPTICS CARE CLEANUP; do
    if [ -n "$CLEAN_ALL_FILES" ] && [ "$CLEAN_ALL_FILES" == "clean_all_files" ]; then
        echo "cleaning $step"
        rm -rf "${VTSSIMPIPE_LOG_DIR:?}"/"$DIRSUFF"/"$step"
        rm -rf "${VTSSIMPIPE_DATA_DIR:?}"/"$DIRSUFF"/"$step"
        rm -rf "${VTSSIMPIPE_DATA_DIR:?}"/"$DIRSUFF"/"${step}_std"
        rm -rf "${VTSSIMPIPE_DATA_DIR:?}"/"$DIRSUFF"/"${step}_redHV"
    fi
    echo "prepare $step"
    ./prepare_production.sh $step "${CONFIG}" "${INPUT}"
done
