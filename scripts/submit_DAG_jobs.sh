#!/bin/bash
# submit DAG jobs in DESY environment
# use htc-submit.zeuthen.desy.de
# see https://dv-zeuthen.desy.de/services/batch/job_submission/ for details
#
# Submits all *.dag files in the given directory
#
set -e

if [ $# -lt 1 ]
then
    echo "
    ./submit_DAG_jobs.sh <dag directory> <submit/nosubmit>

    "
    exit
fi

export _condor_SEC_TOKEN_DIRECTORY=$(mktemp -d)
condor_token_fetch -lifetime $((7*24*60*60)) -token dag

for dag_file in "${1}"/*.dag; do
    condor_submit_dag "$dag_file"
done

exit $?
