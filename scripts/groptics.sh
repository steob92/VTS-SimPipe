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

# generate GrOptics input files and submission scripts

# preparation of GrOptics containers
prepare_groptics_containers()
{
    DATA_DIR="$1"
    LOG_DIR="$2"
    ATMOSPHERE="$3"

    TMP_CONFIG_DIR="${DATA_DIR}/tmp_groptics_files"
    mkdir -p "$TMP_CONFIG_DIR"

    EXTINCTION_FILE=$(get_extinction_file "$3")
    cp "$(dirname "$0")"/../config/ATMOSPHERE/"$EXTINCTION_FILE" "${TMP_CONFIG_DIR}/"

    CORSIKA_DATA_DIR="${DATA_DIR}/CORSIKA"
    CONTAINER_DATA_DIR="/workdir/external/"
    if [[ $VTSSIMPIPE_CONTAINER == "docker" ]]; then
        CONTAINER_EXTERNAL_DIR="-v \"${DATA_DIR}/CORSIKA:$CONTAINER_DATA_DIR\" -v \"$LOG_DIR:/workdir/external\""
        if [[ $PULL == "TRUE" ]]; then
            docker pull "$VTSSIMPIPE_CORSIKA_IMAGE"
        fi
        CONTAINER_DATA_DIR="/workdir/external/data/"
    elif [[ $VTSSIMPIPE_CONTAINER == "apptainer" ]]; then
        CONTAINER_EXTERNAL_DIR="--bind \"$DATA_DIR:$CORSIKA_DATA_DIR\" --bind \"$LOG_DIR:/workdir/external\""
        INPUT="/workdir/external/$(basename "$INPUT")"
        if [[ $PULL == "TRUE" ]]; then
            apptainer pull --disable-cache --force docker://"$VTSSIMPIPE_CORSIKA_IMAGE"
        fi
    fi
}

generate_groptics_submission_script()
{
    FSCRIPT="$1"
    LOG_DIR=$(dirname "$FSCRIPT")
    OUTPUT_FILE="$2"
    RUN_NUMBER="$3"
    ATMOSPHERE="$4"
    EXTINTINCTION_FILE=$(get_extinction_file "$4")
    CONTAINER_EXTERNAL_DIR="$5"
    rm -f "$OUTPUT_FILE.groptics.log"

    CORSIKA_FILE="${CORSIKA_DATA_DIR}/$(basename "$OUTPUT_FILE").telescope"

    echo "CONTAINER_DIR: $CONTAINER_EXTERNAL_DIR"
    echo "CORSIKA_FILE: $CORSIKA_FILE"

    CORSIKA_IO_READER="../corsikaIOreader/corsikaIOreader \
        -queff 0.50\
        -cors ${CORSIKA_FILE} \
        -seed ${RUN_NUMBER} -grisu stdout \
        -abs ${EXTINTINCTION_FILE} \
        -cfg ${cfg_ioreader}"
    GROPTICS="grOptics -of ${gro_file_loc} -p ${gro_pilot}"


    echo "#!/bin/bash" > "$FSCRIPT.sh"
    # docker: mount external directories
    if [[ $VTSSIMPIPE_CONTAINER == "docker" ]]; then
        INPUT="/workdir/external/$(basename "$INPUT")"
        GROPTICS_EXE="docker run --rm $CONTAINER_EXTERNAL_DIR $VTSSIMPIPE_GROPTICS_IMAGE"
        GROPTICS_EXE="${GROPTICS_EXE} bash -c \"cd /workdir/GrOptics && ${CORSIKA_IO_READER} | ${GROPTICS}\""
        echo "$GROPTICS_EXE > $OUTPUT_FILE.log" >> "$FSCRIPT.sh"
    elif [[ $VTSSIMPIPE_CONTAINER == "apptainer" ]]; then
        INPUT="/workdir/external/$(basename "$INPUT")"
        GROPTICS_EXE="apptainer exec --cleanenv $CONTAINER_EXTERNAL_DIR --compat docker://$VTSSIMPIPE_GROPTICS_IMAGE"
        GROPTICS_EXE="${GROPTICS_EXE} bash -c \"cd /workdir/GrOptics && ${CORSIKA_IO_READER} | ${GROPTICS}\""
        echo "$GROPTICS_EXE > $OUTPUT_FILE.log" >> "$FSCRIPT.sh"
    else
        echo "$VTSSIMPIPE_CONTAINER < $INPUT > $OUTPUT_FILE.log" >> "$FSCRIPT.sh"
    fi
    echo "bzip2 -f -v $OUTPUT_FILE.telescope" >> "$FSCRIPT.sh"
    chmod u+x "$FSCRIPT.sh"
}
