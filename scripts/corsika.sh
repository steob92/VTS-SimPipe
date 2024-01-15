#!/bin/bash
# Helper functions for CORSIKA; called from prepare_production.sh

# preparation of CORSIKA containers
prepare_corsika_containers()
{
    DATA_DIR="$1"
    LOG_DIR="$2"
    PULL="$3"
    VTSSIMPIPE_CONTAINER="$4"
    VTSSIMPIPE_CORSIKA_IMAGE="$5"

    CONTAINER_EXTERNAL_DIR="-v \"${DATA_DIR}/CORSIKA:/workdir/external/data\" -v \"$LOG_DIR:/workdir/external/log\""
    CORSIKA_DATA_DIR="/workdir/external/data"
    if [[ $VTSSIMPIPE_CONTAINER == "docker" ]]; then
        COPY_COMMAND="docker run --rm $CONTAINER_EXTERNAL_DIR $VTSSIMPIPE_CORSIKA_IMAGE"
        PULL_COMMAND="docker pull $VTSSIMPIPE_CORSIKA_IMAGE"
    elif [[ $VTSSIMPIPE_CONTAINER == "apptainer" ]]; then
        PULL_COMMAND="apptainer pull --disable-cache --force docker://$VTSSIMPIPE_CORSIKA_IMAGE"
        COPY_COMMAND="apptainer exec --cleanenv ${CONTAINER_EXTERNAL_DIR//-v/--bind} --compat docker://$VTSSIMPIPE_CORSIKA_IMAGE"
    fi
    if [[ $PULL == "TRUE" ]]; then
        eval "$PULL_COMMAND"
    fi
    # copy corsika directory to data dir (as apptainers are readonly)
    echo "Copy CORSIKA files to ${DATA_DIR}/CORSIKA/tmp_corsika_run_files"
    mkdir -p "${DATA_DIR}/CORSIKA/tmp_corsika_run_files"
    COPY_COMMAND="$COPY_COMMAND bash -c \"cp /workdir/corsika-run/* /workdir/external/data/tmp_corsika_run_files\""
    echo "$COPY_COMMAND"
    eval "$COPY_COMMAND"
}

generate_corsika_submission_script()
{
    FSCRIPT="$1"
    INPUT="$2"
    OUTPUT_FILE="$3"
    CONTAINER_EXTERNAL_DIR="$4"
    rm -f "$OUTPUT_FILE.log"
    rm -f "$OUTPUT_FILE.telescope"

    INPUT="/workdir/external/log/$(basename "$INPUT")"

    echo "#!/bin/bash" > "$FSCRIPT.sh"
    mkdir -p $(dirname $OUTPUT_FILE)
    rm -f $OUTPUT_FILE.telescope
    if [[ $VTSSIMPIPE_CONTAINER == "docker" ]]; then
        CORSIKA_EXE="docker run --rm $CONTAINER_EXTERNAL_DIR $VTSSIMPIPE_CORSIKA_IMAGE"
    elif [[ $VTSSIMPIPE_CONTAINER == "apptainer" ]]; then
        CORSIKA_EXE="apptainer exec --cleanenv ${CONTAINER_EXTERNAL_DIR//-v/--bind} --compat docker://$VTSSIMPIPE_CORSIKA_IMAGE"
    fi
    CORSIKA_EXE="${CORSIKA_EXE} bash -c \"cd /workdir/corsika-run && ./corsika77500Linux_QGSII_urqmd < $INPUT\""
    echo "$CORSIKA_EXE > $OUTPUT_FILE.log" >> "$FSCRIPT.sh"
#    echo "bzip2 -f -v $OUTPUT_FILE.telescope" >> "$FSCRIPT.sh"
    chmod u+x "$FSCRIPT.sh"
}


# core scatter area
get_corsika_core_scatter()
{
    ZENITH="$1"
    if [[ $ZENITH -lt 39 ]]; then
        echo "750.E2"
    elif [[ $ZENITH -lt 49 ]]; then
        echo "1000.E2"
    else
        echo "1500.E2"
    fi
}

# minimum energy
get_corsika_energy_min()
{
    ZENITH="$1"
    if [[ $ZENITH -lt 29 ]]; then
        echo "30."
    elif [[ $ZENITH -lt 54 ]]; then
        echo "50."
    else
        echo "100"
    fi
}

# CORSIKA input card
generate_corsika_input_card()
{
    LOG_DIR="$1"
    run_number="$2"
    S1="$3"
    INPUT_TEMPLATE="$4"
    N_SHOWER="$5"
    ZENITH="$6"
    ENERGY_MIN=$(get_corsika_energy_min "$ZENITH")
    CORE_SCATTER=$(get_corsika_core_scatter "$ZENITH")
    ATMOSPHERE="$7"
    CORSIKA_DATA_DIR="$8"
    VTSSIMPIPE_CONTAINER="$9"

    INPUT="$LOG_DIR"/"input_$run_number.dat"
    rm -f "$INPUT"

    S1=$((S1 + 2))
    S2=$((S1 + 2))
    S3=$((S2 + 2))
    S4=$((S3 + 2))

    echo "DATDIR $CORSIKA_DATA_DIR/tmp_corsika_run_files" > "$INPUT"
    sed -e "s|run_number|$run_number|" \
        -e "s|number_of_showers|$N_SHOWER|" \
        -e "s|core_scatter_area|$CORE_SCATTER|" \
        -e "s|energy_min|$ENERGY_MIN|" \
        -e "s|atmosphere_id|$ATMOSPHERE|" \
        -e "s|zenith_angle|$ZENITH|g" \
        -e "s|output_directory|$CORSIKA_DATA_DIR|" \
        -e "s|seed_1|$S1|" \
        -e "s|seed_2|$S2|" \
        -e "s|seed_3|$S3|" \
        -e "s|seed_4|$S4|" \
        "$INPUT_TEMPLATE" >> "$INPUT"

    echo "$S4"
}
