#!/bin/bash
# Helper functions for CARE; called from prepare_production.sh

#####################################################################
# preparation of CARE containers
prepare_care_containers()
{
    DATA_DIR="$1"
    OBS_MODE="$2"

    CARE_DATA_DIR="${DATA_DIR}/CARE_${OBS_MODE}"
    TMP_CONFIG_DIR="${CARE_DATA_DIR}/model_files/"
    mkdir -p "$TMP_CONFIG_DIR"

    # copy telescope model files for CARE (copy all files, although not all are needed)
    cp -f "$(dirname "$0")"/../config/CARE/* "${TMP_CONFIG_DIR}/"
}

#####################################################################
# generate CARE input files and submission scripts
#
# Unfortunately quite fine tuned due to directory requirements of
# corsikaIOreader and grOptics:
#
# /workdir/external/log:     directory for run scripts and pilot files
# /workdir/external/groptics:directory with GrOptics (input) files
# /workdir/CARE/Config:      directory into which model files
#                            (configuration, pulse shapes) are copied.
#
generate_care_submission_script()
{
    CAREFSCRIPT="$1"
    LOG_DIR=$(dirname "$CAREFSCRIPT")
    OUTPUT_FILE="$2"
    rm -f "$OUTPUT_FILE.care.log"
    CARE_CONFIG="$3"
    OBS_MODE="$4"

    CARE="./CameraAndReadout \
     NSBRATEPERPIXEL \\\"0 0 \${NSB_LEVEL}\\\" \
     HIGHGAINPULSESHAPE \\\"0 /workdir/CARE/data/${CARE_HIGH_GAIN}\\\" \
     LOWGAINPULSESHAPE \\\"0 /workdir/CARE/data/${CARE_LOW_GAIN}\\\" \
     SIMULATORNAME \\\"$(echo $LOGNAME)\\\" \
     ATMOSPHERICMODEL \\\"$ATMOSPHERE\\\" \
     DAYOFSIMULATEDEVENTS \\\"$(date +'%Y-%m-%d')\\\" \
     --notraces \
     --seed $((RANDOM % 900000000 - 1)) \
     --vbfrunnumber 10000 \
     --writepedestals 1 \
     --configfile /workdir/CARE/data/${CARE_CONFIG} \
     --outputfile /workdir/external/care/DAT\${RUN_NUMBER} \
     --inputfile /workdir/external/groptics/DAT\${RUN_NUMBER}.groptics.root"

    echo "#!/bin/bash" > "$CAREFSCRIPT.sh"
    echo "RUN_NUMBER=\$1" >> "$CAREFSCRIPT.sh"
    echo "WOBBLE_OFFSET=\$2" >> "$CAREFSCRIPT.sh"
    echo "NSB_LEVEL=\$3" >> "$CAREFSCRIPT.sh"
    echo "" >> "$CAREFSCRIPT.sh"
    echo "mkdir -p ${DATA_DIR}/CARE_${OBS_MODE}/W\${WOBBLE_OFFSET}/NSB\${NSB_LEVEL}" >> "$CAREFSCRIPT.sh"
    
    # mount directories
{
cat << EOF
GROPTICS_DATA_DIR="${DATA_DIR}/GROPTICS/W\${WOBBLE_OFFSET}"
CARE_DATA_DIR="${DATA_DIR}/CARE_${OBS_MODE}/W\${WOBBLE_OFFSET}/NSB\${NSB_LEVEL}"
TMP_CONFIG_DIR="\${CARE_DATA_DIR}/model_files/"
CONTAINER_EXTERNAL_DIR="-v \${GROPTICS_DATA_DIR}:/workdir/external/groptics"
CONTAINER_EXTERNAL_DIR="\$CONTAINER_EXTERNAL_DIR -v \${CARE_DATA_DIR}:/workdir/external/care"
CONTAINER_EXTERNAL_DIR="\$CONTAINER_EXTERNAL_DIR -v ${TMP_CONFIG_DIR}:/workdir/CARE/data"
CONTAINER_EXTERNAL_DIR="\$CONTAINER_EXTERNAL_DIR -v $LOG_DIR:/workdir/external/log/"
EOF
} >> "$CAREFSCRIPT.sh"

    if [[ $VTSSIMPIPE_CONTAINER == "docker" ]]; then
        CARE_EXE="docker run --rm $CONTAINER_EXTERNAL_DIR ${VTSSIMPIPE_CONTAINER_URL}${VTSSIMPIPE_CARE_IMAGE}"
    elif [[ $VTSSIMPIPE_CONTAINER == "apptainer" ]]; then
        CARE_EXE="apptainer exec --cleanenv --no-mount bind-paths \${CONTAINER_EXTERNAL_DIR//-v/--bind} ${VTSSIMPIPE_CONTAINER_DIR}/${VTSSIMPIPE_CARE_IMAGE/:/_}.sif"
    fi
    CARE_EXE="${CARE_EXE} bash -c \"cd /workdir/CARE && ${CARE}\""
    echo "$CARE_EXE > \${CARE_DATA_DIR}/DAT\${RUN_NUMBER}.care.log 2>&1" >> "$CAREFSCRIPT.sh"
    chmod u+x "$CAREFSCRIPT.sh"
}
