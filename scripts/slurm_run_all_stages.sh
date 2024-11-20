#!/bin/bash
# Input various SBATCH commands here


# Source the environment variables
source ../env_setup.sh

# Get the config file
CONFIG=$1
source $CONFIG


# result=$(sbatch submit_corsika.sh | awk '{print $4}')

for ((i=0; i<$N_RUNS; i++));
do
    RUN_NUM=$(($RUN_START + $i))
    echo $RUN_NUM
    # Running CORSIKA Stage
    ${VTSSIMPIPE_LOG_DIR}/ATM${ATMOSPHERE}/Zd${ZENITH}/CORSIKA/run_CORSIKA.sh $RUN_NUM

    # Running the GROptics Stage
    for WOBBLE in ${WOBBLE_LIST}; do
        ${VTSSIMPIPE_LOG_DIR}/ATM${ATMOSPHERE}/Zd${ZENITH}/GROPTICS/run_GROPTICS.sh $RUN_NUM $WOBBLE
    done

    # Running the CARE Stage
    for WOBBLE in ${WOBBLE_LIST}; do
        for NSB in ${NSB_LIST_std}; do
            ${VTSSIMPIPE_LOG_DIR}/ATM${ATMOSPHERE}/Zd${ZENITH}/CARE/run_CARE_std.sh $RUN_NUM $WOBBLE $NSB
        done

        for NSB in ${NSB_LIST_redHV}; do
            ${VTSSIMPIPE_LOG_DIR}/ATM${ATMOSPHERE}/Zd${ZENITH}/CARE/run_CARE_redHV.sh $RUN_NUM $WOBBLE $NSB
        done
    done

    # # Merge the CARE output files
    # for WOBBLE in ${WOBBLE_LIST}; do
    #     for NSB in ${NSB_LIST_std}; do
    #         ${VTSSIMPIPE_LOG_DIR}/ATM${ATMOSPHERE}/Zd${ZENITH}/MERGEVBF/run_MERGEVBF_std_${WOBBLE}_${NSB}_0.sh
    #     done
    #     for NSB in ${NSB_LIST_redHV}; do
    #         ${VTSSIMPIPE_LOG_DIR}/ATM${ATMOSPHERE}/Zd${ZENITH}/MERGEVBF/run_MERGEVBF_redHV_${WOBBLE}_${NSB}_0.sh
    #     done
    # done


done


