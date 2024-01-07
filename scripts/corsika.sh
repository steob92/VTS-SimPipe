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

    CORSIKA_DATA_DIR="$DATA_DIR"
    if [[ $VTSSIMPIPE_CONTAINER == "docker" ]]; then
        CORSIKA_DATA_DIR="/workdir/external/$DIRSUFF"
        CONTAINER_EXTERNAL_DIR="-v \"$DATA_DIR:$CORSIKA_DATA_DIR\" -v \"$LOG_DIR:/workdir/external\""
        if [[ $PULL == "TRUE" ]]; then
            docker pull "$VTSSIMPIPE_CORSIKA_IMAGE"
        fi
    elif [[ $VTSSIMPIPE_CONTAINER == "apptainer" ]]; then
        CORSIKA_DATA_DIR="/workdir/external/$DIRSUFF"
        CONTAINER_EXTERNAL_DIR="--bind \"$DATA_DIR:$CORSIKA_DATA_DIR\" --bind \"$LOG_DIR:/workdir/external\""
        INPUT="/workdir/external/$(basename "$INPUT")"
        if [[ $PULL == "TRUE" ]]; then
            apptainer pull --disable-cache --force docker://"$VTSSIMPIPE_CORSIKA_IMAGE"
            # copy corsika directory to data dir (as apptainers are readonly)
            COPY_COMMAND="apptainer exec --cleanenv $CONTAINER_EXTERNAL_DIR --compat docker://$VTSSIMPIPE_IMAGE"
            COPY_COMMAND="$COPY_COMMAND bash -c \"mkdir -p $CORSIKA_DATA_DIR/tmp_corsika_run_files && \
                cp /workdir/corsika-run/* $CORSIKA_DATA_DIR/tmp_corsika_run_files\""
            eval "$COPY_COMMAND"
            echo "CORSIKA files are copied to $DATA_DIR/tmp_corsika_run_files"
        fi
    fi
}

# generate CORSIKA input files and submission scripts
generate_corsika_submission_script()
{
    FSCRIPT="$1"
    INPUT="$2"
    OUTPUT_FILE="$3"
    CONTAINER_EXTERNAL_DIR="$4"
    rm -f "$OUTPUT_FILE.log"
    rm -f "$OUTPUT_FILE.telescope"

    echo "#!/bin/bash" > "$FSCRIPT.sh"
    # docker: mount external directories
    if [[ $VTSSIMPIPE_CONTAINER == "docker" ]]; then
        INPUT="/workdir/external/$(basename "$INPUT")"
        CORSIKA_EXE="docker run --rm $CONTAINER_EXTERNAL_DIR $VTSSIMPIPE_CORSIKA_IMAGE"
        CORSIKA_EXE="${CORSIKA_EXE} bash -c \"cd /workdir/corsika-run && ./corsika77500Linux_QGSII_urqmd < $INPUT\""
        echo "$CORSIKA_EXE > $OUTPUT_FILE.log" >> "$FSCRIPT.sh"
    elif [[ $VTSSIMPIPE_CONTAINER == "apptainer" ]]; then
        INPUT="/workdir/external/$(basename "$INPUT")"
        CORSIKA_EXE="apptainer exec --cleanenv $CONTAINER_EXTERNAL_DIR --compat docker://$VTSSIMPIPE_CORSIKA_IMAGE"
        CORSIKA_EXE="${CORSIKA_EXE} bash -c \"cd /workdir/corsika-run && ./corsika77500Linux_QGSII_urqmd < $INPUT\""
        echo "$CORSIKA_EXE > $OUTPUT_FILE.log" >> "$FSCRIPT.sh"
    else
        echo "$VTSSIMPIPE_CONTAINER < $INPUT > $OUTPUT_FILE.log" >> "$FSCRIPT.sh"
    fi
    echo "bzip2 -f -v $OUTPUT_FILE.telescope" >> "$FSCRIPT.sh"
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
        "$INPUT_TEMPLATE" > "$INPUT"

    if [[ $VTSSIMPIPE_CONTAINER == "apptainer" ]]; then
        dat_dir="DATDIR $CORSIKA_DATA_DIR/tmp_corsika_run_files"
        sed -i '' "1s|^|${dat_dir}\\n|" "$INPUT"
    fi

    echo "$S4"
}
