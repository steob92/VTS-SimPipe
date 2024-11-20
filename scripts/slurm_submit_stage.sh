#!/bin/bash

# Source the environment variables
source ../env_setup.sh

# Get the config file
CONFIG=$1
source $CONFIG

# Define the account to run under
ACCOUNTNAME=rrg-ragan

# Define the SBATCH header template
SBATCH_HEADER="#!/bin/bash
#SBATCH --job-name=JOBNAME
#SBATCH --account=ACCOUNTNAME
#SBATCH --output=${VTSSIMPIPE_LOG_DIR}/logs/JOBNAME-%j.out
#SBATCH --error=${VTSSIMPIPE_LOG_DIR}/logs/JOBNAME-%j.err
#SBATCH --time=24:00:00
#SBATCH --nodes=1
#SBATCH --ntasks=1
#SBATCH --mem=3G
"

CARE_DEP_CHAIN_STD="#SBATCH --dependency=afterok"
CARE_DEP_CHAIN_RED="#SBATCH --dependency=afterok"

# result=$(sbatch submit_corsika.sh | awk '{print $4}')
PWD=$(pwd)

for ((i=0; i<$N_RUNS; i++));
do


    RUN_NUM=$(($RUN_START + $i))

    echo "Staging CORSIKA for RUN_NUM: $RUN_NUM"
    # Create a new SBATCH script for the CORSIKA stage
    SBATCH_SCRIPT="${PWD}/${VTSSIMPIPE_LOG_DIR}/ATM${ATMOSPHERE}/Zd${ZENITH}/CORSIKA/sbatch_CORSIKA_${RUN_NUM}.sh"
    echo "$SBATCH_HEADER" > $SBATCH_SCRIPT
    echo "module load apptainer" >> $SBATCH_SCRIPT
    # Replace JOBNAME and ACCOUNTNAME with the appropriate values
    sed -i "s/JOBNAME/CORSIKA_${RUN_NUM}/g" $SBATCH_SCRIPT
    sed -i "s/ACCOUNTNAME/${ACCOUNTNAME}/g" $SBATCH_SCRIPT

    echo "${VTSSIMPIPE_LOG_DIR}/ATM${ATMOSPHERE}/Zd${ZENITH}/CORSIKA/run_CORSIKA.sh $RUN_NUM" >> $SBATCH_SCRIPT

    # Submit the SBATCH script and get the dependency for the next stage
    CORSIKA_DEP=$(sbatch ${SBATCH_SCRIPT} | awk '{print $4}')

    # Staging the GROptics Stage
    for WOBBLE in ${WOBBLE_LIST}; do
        echo "Staging GROptics for RUN_NUM: $RUN_NUM, WOBBLE: $WOBBLE"

        SBATCH_SCRIPT="${PWD}/${VTSSIMPIPE_LOG_DIR}/ATM${ATMOSPHERE}/Zd${ZENITH}/GROPTICS/sbatch_GROPTICS_${RUN_NUM}_${WOBBLE}.sh"
        echo "$SBATCH_HEADER" > $SBATCH_SCRIPT
        # Adding the dependency on the CORSIKA stage
        echo "#SBATCH --dependency=afterok:${CORSIKA_DEP}" >> $SBATCH_SCRIPT
        echo "module load apptainer" >> $SBATCH_SCRIPT
        echo "${VTSSIMPIPE_LOG_DIR}/ATM${ATMOSPHERE}/Zd${ZENITH}/GROPTICS/run_GROPTICS.sh $RUN_NUM $WOBBLE" >> $SBATCH_SCRIPT
        # Replace JOBNAME and ACCOUNTNAME with the appropriate values
        sed -i "s/JOBNAME/GROPTICS_${RUN_NUM}_${WOBBLE}/g" $SBATCH_SCRIPT
        sed -i "s/ACCOUNTNAME/${ACCOUNTNAME}/g" $SBATCH_SCRIPT
        
        
        GROPTICS_DEP=$(sbatch ${SBATCH_SCRIPT} | awk '{print $4}')
        
        for NSB in ${NSB_LIST_std}; do
            echo "Staging CARE (STD) for RUN_NUM: $RUN_NUM, WOBBLE: $WOBBLE, NSB: $NSB"
        
            SBATCH_SCRIPT="${VTSSIMPIPE_LOG_DIR}/ATM${ATMOSPHERE}/Zd${ZENITH}/CARE/sbatch_CARE_std_${RUN_NUM}_${WOBBLE}_${NSB}.sh"
            echo "$SBATCH_HEADER" > $SBATCH_SCRIPT
            # Adding the dependency on the GROptics stage
            echo "#SBATCH --dependency=afterok:${GROPTICS_DEP}" >> $SBATCH_SCRIPT
            echo "module load apptainer" >> $SBATCH_SCRIPT
            echo "${PWD}/${VTSSIMPIPE_LOG_DIR}/ATM${ATMOSPHERE}/Zd${ZENITH}/CARE/run_CARE_std.sh $RUN_NUM $WOBBLE $NSB" >> $SBATCH_SCRIPT
            # Replace JOBNAME and ACCOUNTNAME with the appropriate values
            sed -i "s/JOBNAME/CARE_std_${RUN_NUM}_${WOBBLE}_${NSB}/g" $SBATCH_SCRIPT
            sed -i "s/ACCOUNTNAME/${ACCOUNTNAME}/g" $SBATCH_SCRIPT
            
            CARE_DEP_SHV=$(sbatch ${SBATCH_SCRIPT} | awk '{print $4}')
            CARE_DEP_CHAIN_STD="${CARE_DEP_CHAIN_STD}:${CARE_DEP_SHV}"
            
        done

        for NSB in ${NSB_LIST_redHV}; do
            echo "Staging CARE (RHV) for RUN_NUM: $RUN_NUM, WOBBLE: $WOBBLE, NSB: $NSB"


            SBATCH_SCRIPT="${VTSSIMPIPE_LOG_DIR}/ATM${ATMOSPHERE}/Zd${ZENITH}/CARE/sbatch_CARE_redHV_${RUN_NUM}_${WOBBLE}_${NSB}.sh"
            echo "$SBATCH_HEADER" > $SBATCH_SCRIPT
            # Adding the dependency on the GROptics stage
            echo "#SBATCH --dependency=afterok:${GROPTICS_DEP}" >> $SBATCH_SCRIPT
            echo "module load apptainer" >> $SBATCH_SCRIPT
            echo "${PWD}/${VTSSIMPIPE_LOG_DIR}/ATM${ATMOSPHERE}/Zd${ZENITH}/CARE/run_CARE_redHV.sh $RUN_NUM $WOBBLE $NSB" >> $SBATCH_SCRIPT
            # Replace JOBNAME and ACCOUNTNAME with the appropriate values
            sed -i "s/JOBNAME/CARE_rhv_${RUN_NUM}_${WOBBLE}_${NSB}/g" $SBATCH_SCRIPT
            sed -i "s/ACCOUNTNAME/${ACCOUNTNAME}/g" $SBATCH_SCRIPT
            
            CARE_DEP_RHV=$(sbatch ${SBATCH_SCRIPT} | awk '{print $4}')
            CARE_DEP_CHAIN_RED="${CARE_DEP_CHAIN_RED}:${CARE_DEP_RHV}"
        done
    done

done




# Merge the CARE output files
for WOBBLE in ${WOBBLE_LIST}; do
    for NSB in ${NSB_LIST_std}; do

        echo "Staging MERGEVBF (STD) for RUN_NUM: $RUN_NUM, WOBBLE: $WOBBLE, NSB: $NSB"
        SBATCH_SCRIPT="${VTSSIMPIPE_LOG_DIR}/ATM${ATMOSPHERE}/Zd${ZENITH}/MERGEVBF/sbatch_MERGEVBF_std_${WOBBLE}_${NSB}_0.sh"
        echo "$SBATCH_HEADER" > $SBATCH_SCRIPT
        # Adding the dependency on the CARE stage
        echo "${CARE_DEP_CHAIN_STD}" >> $SBATCH_SCRIPT
        echo "module load apptainer" >> $SBATCH_SCRIPT
        echo "${PWD}/${VTSSIMPIPE_LOG_DIR}/ATM${ATMOSPHERE}/Zd${ZENITH}/MERGEVBF/run_MERGEVBF_std_${WOBBLE}_${NSB}_0.sh" >> $SBATCH_SCRIPT
        # Replace JOBNAME and ACCOUNTNAME with the appropriate values
        sed -i "s/JOBNAME/MERGE_CARE_std_${WOBBLE}_${NSB}/g" $SBATCH_SCRIPT
        sed -i "s/ACCOUNTNAME/${ACCOUNTNAME}/g" $SBATCH_SCRIPT
        
        MERGEVBF_DEP=$(sbatch ${SBATCH_SCRIPT} | awk '{print $4}')
    done
    for NSB in ${NSB_LIST_redHV}; do
        echo "Staging MERGEVBF (RHV) for RUN_NUM: $RUN_NUM, WOBBLE: $WOBBLE, NSB: $NSB"
        SBATCH_SCRIPT="${VTSSIMPIPE_LOG_DIR}/ATM${ATMOSPHERE}/Zd${ZENITH}/MERGEVBF/sbatch_MERGEVBF_redHV_${WOBBLE}_${NSB}_0.sh"
        echo "$SBATCH_HEADER" > $SBATCH_SCRIPT
        # Adding the dependency on the CARE stage
        echo "${CARE_DEP_CHAIN_RED}" >> $SBATCH_SCRIPT
        echo "module load apptainer" >> $SBATCH_SCRIPT
        echo "${PWD}/${VTSSIMPIPE_LOG_DIR}/ATM${ATMOSPHERE}/Zd${ZENITH}/MERGEVBF/run_MERGEVBF_redHV_${WOBBLE}_${NSB}_0.sh" >> $SBATCH_SCRIPT
        # Replace JOBNAME and ACCOUNTNAME with the ahvppropriate values
        sed -i "s/JOBNAME/MERGE_CARE_r_${WOBBLE}_${NSB}/g" $SBATCH_SCRIPT
        sed -i "s/ACCOUNTNAME/${ACCOUNTNAME}/g" $SBATCH_SCRIPT

        MERGEVBF_DEP=$(sbatch ${SBATCH_SCRIPT} | awk '{print $4}')

    done
done