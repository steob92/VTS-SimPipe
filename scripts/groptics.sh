#!/bin/bash
# Helper functions for GrOptics; called from prepare_production.sh

#####################################################################
# corsikaIOreader command
#
# queff = 0.5: 50% of all photons are (randomly) discared.
#              This is taken into account in the queff, and
#              reflectivity part of the simulations.
# abs:         extinction file for Cherenkov photon scattering
#              and absorption (note that requirement of "M5" in the
#              file name of the extinction file)
# cfg:         telescope model file. Used only to map the telescopes
#              from CORSIKA to GrOptics (more telescopes might have
#              been simulated in CORSIKA than are used in GrOptics).
#
# Note: corsikaIOreader requires also the atmprof file as
# ./data/atmprof${ATMOSPHERE}.dat from the path the executable is
# called.
prepare_corsikaIOreader()
{
    CORSIKA_IO_READER="../corsikaIOreader/corsikaIOreader \
        -queff 0.50\
        -cors ${CORSIKA_FILE} \
        -seed $((RANDOM % 900000000 - 1)) -grisu stdout \
        -abs /workdir/GrOptics/data/${EXTINCTION} \
        -cfg /workdir/GrOptics/data/${TELESCOPE_MODEL}"
    echo "$CORSIKA_IO_READER"
}


#####################################################################
# get wobble direction (use run number)
get_wobble()
{
    RUN_NUMBER="$1"
    WOBBLE="$2"
    if [[ $((RUN_NUMBER % 4)) == 0 ]]; then
        # North
        echo "0.0 ${WOBBLE}"
    elif [[ $((RUN_NUMBER % 4)) == 1 ]]; then
        # East
        echo "${WOBBLE} 0.0"
    elif [[ $((RUN_NUMBER % 4)) == 2 ]]; then
        # South
        echo "0.0 -${WOBBLE}"
    else
        # West
        echo "-${WOBBLE} 0.0"
    fi
}


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
    WOBBLE="$3"

    PILOT="${LOG_DIR}/pilot_${RUN_NUMBER}_W${WOBBLE}.dat"
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
# preparation of GrOptics containers
#
# Unfortunately quite fine tuned due to directory requirements of
# corsikaIOreader and grOptics:
#
# /workdir/external/corsika: directory with CORSIKA (input) files
# /workdir/external/log:     directory for run scripts and pilot files
# /workdir/external/groptics:directory with GrOptics (output) files
# /workdir/GrOptics/Config:  directory into which model files
#                            (atmosphere, telescope model) are copied.
#
prepare_groptics_containers()
{
    DATA_DIR="$1"
    ATMOSPHERE="$2"
    WOBBLE="$3"

    mkdir -p "$DATA_DIR"
    GROPTICS_DATA_DIR="${DATA_DIR}/GROPTICS/W${WOBBLE}"
    TMP_CONFIG_DIR="${GROPTICS_DATA_DIR}/model_files/"
    mkdir -p "$TMP_CONFIG_DIR"

    # copy file for atmospheric extinction (corsikaIOreader required "M5" in file name)
    cp -f "$(dirname "$0")"/../config/ATMOSPHERE/"$EXTINCTION" "${TMP_CONFIG_DIR}/"
    # copy file for atmospheric profile (corsikaIOreader expect it in the /workdir/external/groptics/data directory)
    cp -f "$(dirname "$0")"/../config/ATMOSPHERE/atmprof"$ATMOSPHERE".dat "${TMP_CONFIG_DIR}/"
    # copy file for telescope model
    cp -f "$(dirname "$0")"/../config/GROPTICS/"$TELESCOPE_MODEL" "${TMP_CONFIG_DIR}/"
    # copy file for GrOptics configuration
    cp -f "$(dirname "$0")"/../config/GROPTICS/"$GROPTICS_CONFIG" "${TMP_CONFIG_DIR}/"
}

#####################################################################
# generate GrOptics input files and submission scripts
generate_groptics_submission_script()
{
    GROPTICSFSCRIPT="$1"
    LOG_DIR=$(dirname "$GROPTICSFSCRIPT")
    OUTPUT_FILE="$2"
    RUN_NUMBER="$3"
    WOBBLE="$4"
    rm -f "$OUTPUT_FILE.groptics.log"

    GROPTICS_DATA_DIR="${DATA_DIR}/GROPTICS/W${WOBBLE}"
    TMP_CONFIG_DIR="${GROPTICS_DATA_DIR}/model_files/"
    # mount directories
    CORSIKA_DATA_DIR="${DATA_DIR}/CORSIKA"
    CONTAINER_EXTERNAL_DIR="-v \"${CORSIKA_DATA_DIR}:/workdir/external/corsika\""
    CONTAINER_EXTERNAL_DIR="$CONTAINER_EXTERNAL_DIR -v \"$GROPTICS_DATA_DIR:/workdir/external/groptics\""
    CORSIKA_FILE="${CORSIKA_DATA_DIR}/$(basename "$OUTPUT_FILE").telescope"
    CORSIKA_FILE="/workdir/external/corsika/$(basename "$CORSIKA_FILE")"
    # corsikaIOreader expects the atmprof file in the /workdir/external/groptics/data directory
    # groptics expect cfg files in the /workdir/external/groptics/data directory
    CONTAINER_EXTERNAL_DIR="$CONTAINER_EXTERNAL_DIR -v \"${TMP_CONFIG_DIR}:/workdir/GrOptics/data\""
    CONTAINER_EXTERNAL_DIR="$CONTAINER_EXTERNAL_DIR -v \"$LOG_DIR:/workdir/external/log/\""

    CORSIKA_IO_READER=$(prepare_corsikaIOreader)
    GROPTICS="./grOptics -of /workdir/external/groptics/$(basename "$OUTPUT_FILE").groptics.root \
     -p $(generate_groptics_pilot_file "$LOG_DIR" "$RUN_NUMBER" "$WOBBLE")"

    echo "#!/bin/bash" > "$GROPTICSFSCRIPT.sh"
    if [[ $VTSSIMPIPE_CONTAINER == "docker" ]]; then
        GROPTICS_EXE="docker run --rm $CONTAINER_EXTERNAL_DIR ${VTSSIMPIPE_CONTAINER_URL}${VTSSIMPIPE_GROPTICS_IMAGE}"
    elif [[ $VTSSIMPIPE_CONTAINER == "apptainer" ]]; then
        GROPTICS_EXE="apptainer exec --cleanenv ${CONTAINER_EXTERNAL_DIR//-v/--bind} ${VTSSIMPIPE_CONTAINER_URL}${VTSSIMPIPE_GROPTICS_IMAGE/:/_}.sif"
    fi
    GROPTICS_EXE="${GROPTICS_EXE} bash -c \"cd /workdir/GrOptics && ${CORSIKA_IO_READER} | ${GROPTICS}\""
    echo "$GROPTICS_EXE > $GROPTICS_DATA_DIR/$(basename "$OUTPUT_FILE").groptics.log 2>&1" >> "$GROPTICSFSCRIPT.sh"
    chmod u+x "$GROPTICSFSCRIPT.sh"
}
