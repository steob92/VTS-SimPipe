#!/bin/bash
# Helper functions for CARE; called from prepare_production.sh

#####################################################################
# preparation of CARE containers
#
# Unfortunately quite fine tuned due to directory requirements of
# corsikaIOreader and grOptics:
#
# /workdir/external/log:     directory for run scripts and pilot files
# /workdir/external/groptics:directory with GrOptics (input) files
# /workdir/CARE/Config:      directory into which model files
#                            (configuration, pulse shapes) are copied.
#
prepare_care_containers()
{
    DATA_DIR="$1"
    WOBBLE="$2"
    NSB="$3"

    CARE_DATA_DIR="${DATA_DIR}/W${WOBBLE}/NSB${NSB}/CARE"
    TMP_CONFIG_DIR="${CARE_DATA_DIR}/model_files/"
    mkdir -p "$TMP_CONFIG_DIR"

    # copy telescope model files for CARE (copy all files, although not all are needed)
    cp -f "$(dirname "$0")"/../config/TELESCOPE_MODEL/* "${TMP_CONFIG_DIR}/"
}

#####################################################################
# generate CARE input files and submission scripts
generate_care_submission_script()
{
    CAREFSCRIPT="$1"
    LOG_DIR=$(dirname "$CAREFSCRIPT")
    OUTPUT_FILE="$2"
    rm -f "$OUTPUT_FILE.care.log"
    WOBBLE="$3"
    NSB="$4"

    # mount directories
    GROPTICS_DATA_DIR="${DATA_DIR}/W${WOBBLE}/GROPTICS"
    CARE_DATA_DIR="${DATA_DIR}/W${WOBBLE}/NSB${NSB}/CARE"
    TMP_CONFIG_DIR="${CARE_DATA_DIR}/model_files/"
    CONTAINER_EXTERNAL_DIR="-v \"${GROPTICS_DATA_DIR}:/workdir/external/groptics\""
    CONTAINER_EXTERNAL_DIR="$CONTAINER_EXTERNAL_DIR -v \"${CARE_DATA_DIR}/CARE:/workdir/external/care\""
    CONTAINER_EXTERNAL_DIR="$CONTAINER_EXTERNAL_DIR -v \"${TMP_CONFIG_DIR}:/workdir/CARE/data\""
    CONTAINER_EXTERNAL_DIR="$CONTAINER_EXTERNAL_DIR -v \"$LOG_DIR:/workdir/external/log/\""

    CARE="./CameraAndReadout \
     NSBRATEPERPIXEL \\\"0 0 ${NSB}\\\" \
     HIGHGAINPULSESHAPE \\\"0 /workdir/CARE/data/${CARE_HIGH_GAIN}\\\" \
     LOWGAINPULSESHAPE \\\"0 /workdir/CARE/data/${CARE_LOW_GAIN}\\\" \
     --notraces \
     --seed $((RANDOM % 900000000 - 1)) \
     --vbfrunnumber 10000 \
     --writepedestals 1 \
     --configfile /workdir/CARE/data/${CARE_CONFIG} \
     --outputfile /workdir/external/care/$(basename "$OUTPUT_FILE") \
     --inputfile /workdir/external/groptics/$(basename "$OUTPUT_FILE").groptics.root"

    echo "#!/bin/bash" > "$CAREFSCRIPT.sh"
    if [[ $VTSSIMPIPE_CONTAINER == "docker" ]]; then
        CARE_EXE="docker run --rm $CONTAINER_EXTERNAL_DIR $VTSSIMPIPE_CARE_IMAGE"
    elif [[ $VTSSIMPIPE_CONTAINER == "apptainer" ]]; then
        CARE_EXE="apptainer exec --cleanenv ${CONTAINER_EXTERNAL_DIR//-v/--bind} --compat docker://$VTSSIMPIPE_CARE_IMAGE"
    fi
    CARE_EXE="${CARE_EXE} bash -c \"cd /workdir/CARE && ${CARE}\""
    echo "$CARE_EXE > $OUTPUT_FILE.care.log 2>&1" >> "$CAREFSCRIPT.sh"
    chmod u+x "$CAREFSCRIPT.sh"
}
