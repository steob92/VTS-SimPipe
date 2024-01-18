#!/bin/bash
# submit DAG jobs in DESY environment
# see https://dv-zeuthen.desy.de/services/batch/job_submission/ for details

export _condor_SEC_TOKEN_DIRECTORY=$(mktemp -d)
condor_token_fetch -lifetime $((7*24*60*60)) -token dag

condor_submit_dag "$@"
exit $?
