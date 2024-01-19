#!/bin/bash
# Generate CORSIKA input files and submission scripts
#
set -e

echo "Generate simulation input files and submission scripts."
echo

if [ $# -lt 2 ]; then
echo "./prepare_production.sh <simulation step> <config file> [input file template]

Allowed simulation steps: CORSIKA, GROPTICS, CARE, MERGEVBF, CLEANUP

CORSIKA:
- template configuration file, see ./config/config_ATM61_template.dat
- input file template, see ./config/CORSIKA/input_template.dat
"
exit
fi

SIM_TYPE="$1"
CONFIG="$2"
[[ "$3" ]] && INPUT_TEMPLATE=$3 || INPUT_TEMPLATE=""

if [[ ! -e "$CONFIG" ]]; then
    echo "Configuration file $CONFIG does not exist."
    exit
fi

echo "Simulation type: $SIM_TYPE"

# shellcheck source=/dev/null
. corsika.sh
# shellcheck source=/dev/null
. groptics.sh
# shellcheck source=/dev/null
. care.sh
# shellcheck source=/dev/null
. mergevbf.sh
# shellcheck source=/dev/null
. "$CONFIG"

# env variables
# shellcheck source=/dev/null
. "$(dirname "$0")"/../env_setup.sh
echo "VTSSIMPIPE_DATA_DIR: $VTSSIMPIPE_DATA_DIR"
echo "VTSSIMPIPE_LOG_DIR: $VTSSIMPIPE_LOG_DIR"
echo "VTSSIMPIPE_CONTAINER: $VTSSIMPIPE_CONTAINER"
echo "VTSSIMPIPE_CORSIKA_IMAGE: $VTSSIMPIPE_CORSIKA_IMAGE"
echo "VTSSIMPIPE_GROPTICS_IMAGE: $VTSSIMPIPE_GROPTICS_IMAGE"
echo "VTSSIMPIPE_CARE_IMAGE: $VTSSIMPIPE_CARE_IMAGE"

echo "Generating for $SIM_TYPE $N_RUNS input files and submission scripts (starting from run number $RUN_START)."
echo "Number of showers per run: $N_SHOWER"
echo "Atmosphere: $ATMOSPHERE"
echo "Zenith angle: $ZENITH deg"
echo "Wobble angle: $WOBBLE_LIST deg"
echo "NSB rate: $NSB_LIST MHz"
if [[ $SIM_TYPE == "CORSIKA" ]]; then
    S1=$((RANDOM % 900000000 - 1))
    echo "First CORSIKA seed: $S1"
fi

# directories
DIRSUFF="ATM${ATMOSPHERE}/Zd${ZENITH}"
LOG_DIR="$VTSSIMPIPE_LOG_DIR"/"$DIRSUFF"/"$SIM_TYPE"
DATA_DIR="$VTSSIMPIPE_DATA_DIR"/"$DIRSUFF"
mkdir -p "${LOG_DIR}"
mkdir -p "${DATA_DIR}"
echo "Log directory: $LOG_DIR"
echo "Data directory: $DATA_DIR"

# generate HT condor file
generate_htcondor_file()
{
    SUBSCRIPT=$(readlink -f "${1}")
    SUBFIL=${SUBSCRIPT}.condor
    rm -f "${SUBFIL}"

    cat > "${SUBFIL}" <<EOL
Executable = ${SUBSCRIPT}
Log = ${SUBSCRIPT}.\$(Cluster)_\$(Process).log
Output = ${SUBSCRIPT}.\$(Cluster)_\$(Process).output
Error = ${SUBSCRIPT}.\$(Cluster)_\$(Process).error
Log = ${SUBSCRIPT}.\$(Cluster)_\$(Process).log
request_memory = 2000M
getenv = True
max_materialize = 250
queue 1
EOL
# priority = 15
}

if [[ $SIM_TYPE == "CORSIKA" ]]; then
    prepare_corsika_containers "$DATA_DIR" "$LOG_DIR"
elif [[ $SIM_TYPE == "GROPTICS" ]]; then
    for WOBBLE in ${WOBBLE_LIST}; do
        prepare_groptics_containers "$DATA_DIR" "$ATMOSPHERE" "$WOBBLE"
    done
elif [[ $SIM_TYPE == "CARE" ]]; then
    for WOBBLE in ${WOBBLE_LIST}; do
        for NSB in ${NSB_LIST}; do
            prepare_care_containers "$DATA_DIR" "$WOBBLE" "$NSB"
        done
    done
elif [[ $SIM_TYPE == "MERGEVBF" ]]; then
    echo "(nothing to prepare for mergevbf)"
else
    echo "Unknown simulation type $SIM_TYPE."
    exit
fi

for ID in $(seq 0 "$N_RUNS");
do
    run_number=$((ID + RUN_START))
    FSCRIPT="$LOG_DIR"/"run_${SIM_TYPE}_$run_number"
    INPUT="$LOG_DIR"/"input_$run_number.dat"
    OUTPUT_FILE="${DATA_DIR}/${SIM_TYPE}/DAT${run_number}"

    if [[ $SIM_TYPE == "CORSIKA" ]]; then
        if [[ ! -e "$INPUT_TEMPLATE" ]]; then
            echo "Input file template $INPUT_TEMPLATE does not exist."
            exit
        fi
        S4=$(generate_corsika_input_card \
           "$LOG_DIR" "$run_number" "$S1" \
           "$INPUT_TEMPLATE" "$N_SHOWER" "$ZENITH" "$ATMOSPHERE" \
           "$CORSIKA_DATA_DIR" "$VTSSIMPIPE_CONTAINER")
        S1=$((S4 + 2))

        generate_corsika_submission_script "$FSCRIPT" "$INPUT" "$OUTPUT_FILE" "$CONTAINER_EXTERNAL_DIR"
        generate_htcondor_file "$FSCRIPT.sh"
    elif [[ $SIM_TYPE == "GROPTICS" ]]; then
        for WOBBLE in ${WOBBLE_LIST}; do
            generate_groptics_submission_script "${FSCRIPT}_${WOBBLE}" "$OUTPUT_FILE" \
                "$run_number" "${WOBBLE}"
            generate_htcondor_file "${FSCRIPT}_${WOBBLE}.sh"
        done
    elif [[ $SIM_TYPE == "CARE" ]]; then
        for WOBBLE in ${WOBBLE_LIST}; do
            for NSB in ${NSB_LIST}; do
                generate_care_submission_script "${FSCRIPT}_${WOBBLE}_${NSB}" "$OUTPUT_FILE" \
                    "${WOBBLE}" "${NSB}"
                generate_htcondor_file "${FSCRIPT}_${WOBBLE}_${NSB}.sh"
            done
        done
    elif [[ $SIM_TYPE == "MERGEVBF" ]]; then
        for WOBBLE in ${WOBBLE_LIST}; do
            for NSB in ${NSB_LIST}; do
                generate_mergevbf_submission_script "${FSCRIPT}_${WOBBLE}_${NSB}" "$OUTPUT_FILE" \
                    "${WOBBLE}" "${NSB}"
                generate_htcondor_file "${FSCRIPT}_${WOBBLE}_${NSB}.sh"
            done
        done
    fi
done

done

echo "End of job preparation for $SIM_TYPE ($LOG_DIR)."
