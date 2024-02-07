#!/bin/bash
# submit DAG jobs in DESY environment from a list of files
# use htc-submit.zeuthen.desy.de
# see https://dv-zeuthen.desy.de/services/batch/job_submission/ for details
#
# Submits all *.dag files in the given directory
#
set -e

if [ $# -lt 1 ]
then
    echo "
    ./submit_DAG_jobs_from_file_list.sh <file list>

    "
    exit
fi

FILELIST="$1"

export _condor_SEC_TOKEN_DIRECTORY=$(mktemp -d)
condor_token_fetch -lifetime $((30*24*60*60)) -token dag

FLIST=$(cat $FILELIST)
for F in ${FLIST}; do
    echo $F
    condor_submit_dag ${F}
done

exit $?
