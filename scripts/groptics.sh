#!/bin/bash
# Helper functions for GrOptics; called from prepare_production.sh

# get extinction file generated with MODTRAN
get_extinction_file()
{
    ATMOSPHERE="$1"
    if [[ $ATMOSPHERE == "61" ]]; then
        echo "Ext_results_VWinter_3_2_6.M5.txt"
    elif [[ $ATMOSPHERE == "62" ]]; then
        echo "Ext_results_VSummer_6_1_6.M5.txt"
    else
        echo "INVALID_EXTINCTION_FILE_FOR_$ATMOSPHERE"
    fi
}

# preparation of GrOptics containers
#
# Unfortunately quite fine tuned due to directory requirements of
# corsikaIOreader and grOptics.
prepare_groptics_containers()
{
    DATA_DIR="$1"
    LOG_DIR="$2"
    ATMOSPHERE="$3"
    PULL="$4"
    VTSSIMPIPE_CONTAINER="$5"
    VTSSIMPIPE_GROPTICS_IMAGE="$6"

    TMP_CONFIG_DIR="${DATA_DIR}/GROPTICS/model_files/"
    mkdir -p "$TMP_CONFIG_DIR"

    # copy file for atmospheric extinction (corsikaIOreader required "M5" in file name)
    EXTINCTION_FILE=$(get_extinction_file "$3")
    cp -f "$(dirname "$0")"/../config/ATMOSPHERE/"$EXTINCTION_FILE" "${TMP_CONFIG_DIR}/extinction_model.M5.dat"
    # copy file for atmospheric profile (corsikaIOreader expect it in the /workdir/external/groptics/data directory)
    cp -f "$(dirname "$0")"/../config/ATMOSPHERE/atmprof"$ATMOSPHERE".dat "${TMP_CONFIG_DIR}/atmprof${ATMOSPHERE}.dat"
    # copy file for telescope model
    cp -f "$(dirname "$0")"/../config/TELESCOPE_MODEL/"$TELESCOPE_MODEL" "${TMP_CONFIG_DIR}/telescope_model.dat"

    # mount directories
    CORSIKA_DATA_DIR="${DATA_DIR}/CORSIKA"
    CONTAINER_EXTERNAL_DIR="-v \"${CORSIKA_DATA_DIR}:/workdir/external/corsika\""
    CONTAINER_EXTERNAL_DIR="$CONTAINER_EXTERNAL_DIR -v \"${DATA_DIR}/GROPTICS:/workdir/external/groptics\""
    # corsikaIOreader expects the atmprof file in the /workdir/external/groptics/data directory
    CONTAINER_EXTERNAL_DIR="$CONTAINER_EXTERNAL_DIR -v \"${TMP_CONFIG_DIR}:/workdir/GrOptics/data\""
    CONTAINER_EXTERNAL_DIR="$CONTAINER_EXTERNAL_DIR -v \"$LOG_DIR:/workdir/external/log/\""

    if [[ $PULL == "TRUE" ]]; then
        if [[ $VTSSIMPIPE_CONTAINER == "docker" ]]; then
            docker pull "$VTSSIMPIPE_GROPTICS_IMAGE"
        elif [[ $VTSSIMPIPE_CONTAINER == "apptainer" ]]; then
            apptainer pull --disable-cache --force docker://"$VTSSIMPIPE_GROPTICS_IMAGE"
        fi
    fi
}

# generate GrOptics input files and submission scripts
generate_groptics_submission_script()
{
    FSCRIPT="$1"
    LOG_DIR=$(dirname "$FSCRIPT")
    OUTPUT_FILE="$2"
    RUN_NUMBER="$3"
    CONTAINER_EXTERNAL_DIR="$4"
    rm -f "$OUTPUT_FILE.groptics.log"

    CORSIKA_FILE="${CORSIKA_DATA_DIR}/$(basename "$OUTPUT_FILE").telescope"
    if [[ $VTSSIMPIPE_CONTAINER == "docker" ]] || [[ $VTSSIMPIPE_CONTAINER == "apptainer" ]]; then
        CORSIKA_FILE="/workdir/external/corsika/$(basename "$CORSIKA_FILE")"
    fi

    CORSIKA_IO_READER="../corsikaIOreader/corsikaIOreader \
        -queff 0.50\
        -cors ${CORSIKA_FILE} \
        -seed ${RUN_NUMBER} -grisu stdout \
        -abs /workdir/external/groptics/model_files/extinction_model.M5.dat \
        -cfg /workdir/external/groptics/model_files/telescope_model.dat"
    GROPTICS="grOptics -of ${OUTPUT_FILE}.groptics -p ${gro_pilot}"

    echo "#!/bin/bash" > "$FSCRIPT.sh"
    if [[ $VTSSIMPIPE_CONTAINER == "docker" ]]; then
        GROPTICS_EXE="docker run --rm $CONTAINER_EXTERNAL_DIR $VTSSIMPIPE_GROPTICS_IMAGE"
    elif [[ $VTSSIMPIPE_CONTAINER == "apptainer" ]]; then
        GROPTICS_EXE="apptainer exec --cleanenv $CONTAINER_EXTERNAL_DIR --compat docker://$VTSSIMPIPE_GROPTICS_IMAGE"
    fi
    GROPTICS_EXE="${GROPTICS_EXE} bash -c \"cd /workdir/GrOptics && ${CORSIKA_IO_READER} | ${GROPTICS}\""
    echo "$GROPTICS_EXE > $OUTPUT_FILE.log" >> "$FSCRIPT.sh"
#    echo "bzip2 -f -v $OUTPUT_FILE.telescope" >> "$FSCRIPT.sh"
    chmod u+x "$FSCRIPT.sh"
}
