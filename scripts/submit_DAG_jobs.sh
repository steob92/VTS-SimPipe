#!/bin/bash
# submit DAG jobs in DESY environment
# use htc-submit.zeuthen.desy.de
# e.g., ssh htc-submit.zeuthen.desy.de 'cd "$(pwd)" && ./submit_DAG_jobs.sh <config file> <dag directory>'
# see https://dv-zeuthen.desy.de/services/batch/job_submission/ for details
#
# Submits all *.dag files in the given directory
#
set -e

if [ $# -lt 2 ]
then
    echo "
    ./submit_DAG_jobs.sh <config file> <dag directory>

    "
    exit
fi

CONFIG="$1"

export _condor_SEC_TOKEN_DIRECTORY=$(mktemp -d)
condor_token_fetch -lifetime $((30*24*60*60)) -token dag

# shellcheck source=/dev/null
. "$CONFIG"

for ID in $(seq 0 "$N_RUNS"); do
    run_number=$((ID + RUN_START))
    condor_submit_dag "${2}/run_${run_number}.dag"
done

exit $?
