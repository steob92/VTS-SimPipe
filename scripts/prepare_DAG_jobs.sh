#!/bin/sh
# DAGMan Workflows to prepare all steps simultaneously
#

if [ $# -lt 1 ]; then
    echo "./prepare_DAG_jobs.sh <config file>"
    exit
fi

CONFIG="$1"

# shellcheck source=/dev/null
. "$CONFIG"

# env variables
# shellcheck source=/dev/null
. "$(dirname "$0")"/../env_setup.sh

DIRSUFF="ATM${ATMOSPHERE}/Zd${ZENITH}"

# return string with CARE configs
# in most cases, this is "std", "redHV", or "std redHV"
get_care_configs()
{
    c_config=""
    if [ ! -z "${CARE_CONFIG_std}" ]; then
        c_config="$c_config std "
    fi
    if [ ! -z "${CARE_CONFIG_redHV}" ]; then
        c_config="$c_config redHV "
    fi
    echo "$c_config"
}

# DAG directory
DAG_DIR="$VTSSIMPIPE_LOG_DIR"/"$DIRSUFF"/DAG
mkdir -p "$DAG_DIR"

for ID in $(seq 0 "$N_RUNS"); do
    run_number=$((ID + RUN_START))

    # DAQ file
    DAG_FILE="$DAG_DIR"/run_"$run_number".dag
    rm -f "$DAG_FILE"
    touch "$DAG_FILE"

    # CORSIKA
    job_corsika="$VTSSIMPIPE_LOG_DIR"/"$DIRSUFF"/CORSIKA/run_CORSIKA_${run_number}.sh.condor
    {
        echo "# DAG file for run $run_number"
        echo "JOB CORSIKA_${run_number} $job_corsika"
    } >> "$DAG_FILE"
    PARENT_CORSIKA="PARENT CORSIKA_${run_number} CHILD"

    # GROPTICS and CARE
    for WOBBLE in ${WOBBLE_LIST}; do
        job_groptics="$VTSSIMPIPE_LOG_DIR"/"$DIRSUFF"/GROPTICS/run_GROPTICS_${run_number}_${WOBBLE}.sh.condor
        echo "JOB GROPTICS_${run_number}_${WOBBLE} $job_groptics" >> "$DAG_FILE"
        job_cleanup="$VTSSIMPIPE_LOG_DIR"/"$DIRSUFF"/CLEANUP/run_CLEANUP_${run_number}_${WOBBLE}.sh.condor
        echo "JOB CLEANUP_${run_number}_${WOBBLE} $job_cleanup" >> "$DAG_FILE"
        PARENT_CORSIKA="$PARENT_CORSIKA GROPTICS_${run_number}_${WOBBLE}"
        PARENT_GROPTICS="PARENT GROPTICS_${run_number}_${WOBBLE} CHILD"
        PARENT_CLEANUP="PARENT"
        for config in $(get_care_configs); do
            care_nsb_list="NSB_LIST_$config"
            for NSB in ${!care_nsb_list}; do
                job_care="$VTSSIMPIPE_LOG_DIR"/"$DIRSUFF"/CARE/run_CARE_${run_number}_${config}_${WOBBLE}_${NSB}.sh.condor
                echo "JOB CARE_${run_number}_${config}_${WOBBLE}_${NSB} $job_care" >> "$DAG_FILE"
                PARENT_GROPTICS="$PARENT_GROPTICS CARE_${run_number}_${config}_${WOBBLE}_${NSB}"
                PARENT_CLEANUP="$PARENT_CLEANUP CARE_${run_number}_${config}_${WOBBLE}_${NSB}"
            done
        done
        echo "$PARENT_GROPTICS" >> "$DAG_FILE"
        PARENT_CLEANUP="$PARENT_CLEANUP CHILD CLEANUP_${run_number}_${WOBBLE}"
        echo "$PARENT_CLEANUP" >> "$DAG_FILE"

    done
    echo "$PARENT_CORSIKA" >> "$DAG_FILE"
done

echo "DAG directory: $DAG_DIR"
