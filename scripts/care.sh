#!/bin/bash
# Helper functions for CARE; called from prepare_production.sh

#####################################################################
# generate GrOptics pilot file
#
# The pilot file is used to configure the GrOptics simulation.
#
# WOBBLE:     wobble offset and direction in degrees
# ARRAYCONFIG: telescope model file
# SEED:       seed for the random number generator (0=machine clock)
generate_groptics_pilot_file()
{
    LOG_DIR="$1"
    RUN_NUMBER="$2"

    PILOT="${LOG_DIR}/pilot_${RUN_NUMBER}.dat"
    rm -f "$PILOT"
    touch "$PILOT"

    {
        # (dummy file name; groptics is executed with the "-of" flag)
        echo "* FILEOUT photonLocation.root allT T 0"
        echo "* NSHOWER -1 -1"
        echo "* WOBBLE $(get_wobble "${RUN_NUMBER}" "${WOBBLE}") 0.0 0.0 90."
        echo "* ARRAYCONFIG ./data/${GROPTICS_CONFIG}"
        echo "* SEED 0"
        echo "* DEBUGBRANCHES 1"
    } >> "$PILOT"
    echo "/workdir/external/log/$(basename "$PILOT")"
}

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
    LOG_DIR="$2"
    VTSSIMPIPE_CONTAINER="$3"
    VTSSIMPIPE_CARE_IMAGE="$4"

    TMP_CONFIG_DIR="${DATA_DIR}/CARE/model_files/"
    mkdir -p "$TMP_CONFIG_DIR"

    # copy telescope model files for CARE (copy all files, although not all are needed)
    cp -f "$(dirname "$0")"/../config/TELESCOPE_MODEL/* "${TMP_CONFIG_DIR}/"

    # mount directories
    GROPTICS_DATA_DIR="${DATA_DIR}/GROPTICS"
    CONTAINER_EXTERNAL_DIR="-v \"${GROPTICS_DATA_DIR}:/workdir/external/groptics\""
    CONTAINER_EXTERNAL_DIR="$CONTAINER_EXTERNAL_DIR -v \"${DATA_DIR}/CARE:/workdir/external/care\""
    CONTAINER_EXTERNAL_DIR="$CONTAINER_EXTERNAL_DIR -v \"${TMP_CONFIG_DIR}:/workdir/CARE/data\""
    CONTAINER_EXTERNAL_DIR="$CONTAINER_EXTERNAL_DIR -v \"$LOG_DIR:/workdir/external/log/\""
}

#####################################################################
# generate CARE input files and submission scripts
generate_care_submission_script()
{
    FSCRIPT="$1"
    LOG_DIR=$(dirname "$FSCRIPT")
    OUTPUT_FILE="$2"
    RUN_NUMBER="$3"
    CONTAINER_EXTERNAL_DIR="$4"
    rm -f "$OUTPUT_FILE.care.log"

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

    echo "#!/bin/bash" > "$FSCRIPT.sh"
    if [[ $VTSSIMPIPE_CONTAINER == "docker" ]]; then
        CARE_EXE="docker run --rm $CONTAINER_EXTERNAL_DIR $VTSSIMPIPE_CARE_IMAGE"
    elif [[ $VTSSIMPIPE_CONTAINER == "apptainer" ]]; then
        CARE_EXE="apptainer exec --cleanenv ${CONTAINER_EXTERNAL_DIR//-v/--bind} --compat docker://$VTSSIMPIPE_CARE_IMAGE"
    fi
    CARE_EXE="${CARE_EXE} bash -c \"cd /workdir/CARE && ${CARE}\""
    echo "$CARE_EXE > $OUTPUT_FILE.care.log 2>&1" >> "$FSCRIPT.sh"
    chmod u+x "$FSCRIPT.sh"
}
