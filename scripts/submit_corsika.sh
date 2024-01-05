#!/bin/bash
# Generate CORSIKA input files and submission scripts
#
set -e

echo "Generate CORSIKA input files and submission scripts."
echo

if [ $# -lt 2 ]; then
echo "./submit_corsika.sh <config file> <input file template> <pull and prepare containers (TRUE/FALSE)

For template configuration file, see ./config/CORSIKA/config_template.dat
For a CORSIKA input file template, see ./config/CORSIKA/input_template.dat
"
exit
fi

[[ "$3" ]] && PULL=$3 || PULL=FALSE

# env variables
source $(dirname "$0")/../env_setup.sh
echo "VTSSIMPIPE_CORSIKA_DIR: $VTSSIMPIPE_CORSIKA_DIR"
echo "VTSSIMPIPE_CORSIKA_EXE: $VTSSIMPIPE_CORSIKA_EXE"
echo "VTSSIMPIPE_LOG_DIR: $VTSSIMPIPE_LOG_DIR"

# read configuration parameters
if [[ ! -e $1 ]]; then
    echo "Configuration file $1 does not exist."
    exit
fi
source "$1"

# check that input file template exists
if [[ ! -e $2 ]]; then
    echo "Input file template $2 does not exist."
    exit
fi

# core scatter area
get_core_scatter()
{
    ZENITH=$1
    if [[ $ZENITH -lt 39 ]]; then
        echo "750.E2"
    elif [[ $ZENITH -lt 49 ]]; then
        echo "1000.E2"
    else
        echo "1500.E2"
    fi
}

# minimum energy
get_energy_min()
{
    ZENITH=$1
    if [[ $ZENITH -lt 29 ]]; then
        echo "30."
    elif [[ $ZENITH -lt 54 ]]; then
        echo "50."
    else
        echo "100"
    fi
}

echo "Generating $N_RUNS CORSIKA input files and submission scripts (starting from run number $RUN_START)."
echo "Number of showers per run: $N_SHOWER"
echo "Atmosphere: $ATMOSPHERE"
echo "Zenith angle: $ZENITH deg"
CORE_SCATTER=$(get_core_scatter "$ZENITH")
echo "Core scatter area: $CORE_SCATTER cm"
ENERGY_MIN=$(get_energy_min "$ZENITH")
echo "Minimum energy: $ENERGY_MIN GeV"
S1=65168195
S1=$((RANDOM % 900000000 - 1))
echo "First seed: $S1"

# directories
DIRSUFF="Zd${ZENITH}/CORSIKA"
LOG_DIR="$VTSSIMPIPE_LOG_DIR"/"$DIRSUFF"
DATA_DIR="$VTSSIMPIPE_CORSIKA_DIR"/"$DIRSUFF"
mkdir -p "$LOG_DIR"
mkdir -p "$DATA_DIR"
echo "Log directory: $LOG_DIR"
echo "Data directory: $DATA_DIR"

# generate input files and submission scripts
generate_corsika_submission_script()
{
    FSCRIPT=$1
    INPUT=$2
    LOGFILE=$3
    LOG_DIR=$(dirname "$INPUT")
    CONTAINER_EXTERNAL_DIR=$4
    rm -f "$LOGFILE"

    echo "#!/bin/bash" > "$FSCRIPT.sh"
    # docker: mount external directories
    if [[ $VTSSIMPIPE_CORSIKA_EXE == "docker run"* ]]; then
        INPUT="/workdir/external/$(basename "$INPUT")"
        EXTERNAL_DIR="-v \"$DATA_DIR:$CORSIKA_DATA_DIR\" -v \"$LOG_DIR:/workdir/external\""
        CORSIKA_EXE=${VTSSIMPIPE_CORSIKA_EXE/CORSIKA_DIRECTORIES/$EXTERNAL_DIR}
        CORSIKA_EXE=${CORSIKA_EXE/CORSIKAINPUTFILE/$INPUT}
        echo "$CORSIKA_EXE > $LOGFILE" >> "$FSCRIPT.sh"
    elif [[ $VTSSIMPIPE_CORSIKA_EXE == "apptainer" ]]; then
        INPUT="/workdir/external/$(basename "$INPUT")"
        CORSIKA_EXE="apptainer exec --cleanenv $CONTAINER_EXTERNAL_DIR --compat docker://$VTSSIMPIPE_IMAGE"
        CORSIKA_EXE="${CORSIKA_EXE} bash -c \"cd /workdir/corsika-run && ./corsika77500Linux_QGSII_urqmd < $INPUT\""
        echo "$CORSIKA_EXE > $LOGFILE" >> "$FSCRIPT.sh"
    else
        echo "$VTSSIMPIPE_CORSIKA_EXE < $INPUT > $LOGFILE" >> "$FSCRIPT.sh"
    fi
    chmod u+x "$FSCRIPT.sh"
}

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

# Preparation of containers
CORSIKA_DATA_DIR="$DATA_DIR"
if [[ $VTSSIMPIPE_CORSIKA_EXE == "docker" ]]; then
    CORSIKA_DATA_DIR="/workdir/external/$DIRSUFF"
    CONTAINER_EXTERNAL_DIR="-v \"$DATA_DIR:$CORSIKA_DATA_DIR\" -v \"$LOG_DIR:/workdir/external\""
elif [[ $VTSSIMPIPE_CORSIKA_EXE == "apptainer" ]]; then
    CORSIKA_DATA_DIR="/workdir/external/$DIRSUFF"
    CONTAINER_EXTERNAL_DIR="--bind \"$DATA_DIR:$CORSIKA_DATA_DIR\" --bind \"$LOG_DIR:/workdir/external\""
    INPUT="/workdir/external/$(basename "$INPUT")"
    if [[ $PULL == "TRUE" ]]; then
        apptainer pull --disable-cache --force docker://$VTSSIMPIPE_IMAGE
        # copy corsika directory to data dir (as apptainers are readonly)
        COPY_COMMAND="apptainer exec --cleanenv $CONTAINER_EXTERNAL_DIR --compat docker://$VTSSIMPIPE_IMAGE"
        COPY_COMMAND="$COPY_COMMAND bash -c \"mkdir -p $CORSIKA_DATA_DIR/tmp_corsika_run_files && cp /workdir/corsika-run/* $CORSIKA_DATA_DIR/tmp_corsika_run_files\""
        eval $COPY_COMMAND
        echo "CORSIKA files are copied to $DATA_DIR/tmp_corsika_run_files"
    fi
fi

for ID in $(seq 0 "$N_RUNS");
do
    # input card
    INPUT="$LOG_DIR"/"input_$ID.dat"
    rm -f "$INPUT"

    S1=$((S1 + 2))
    S2=$((S1 + 2))
    S3=$((S2 + 2))
    S4=$((S3 + 2))

    sed -e "s|run_number|$((ID + RUN_START))|" \
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
        "$2" > "$INPUT"

    if [[ $VTSSIMPIPE_CORSIKA_EXE == "apptainer" ]]; then
        dat_dir="DATDIR $CORSIKA_DATA_DIR/tmp_corsika_run_files"
        sed -i "1i$dat_dir" "$INPUT"
    fi

    S1=$((S4 + 2))

    # submission script and HT condor file
    FSCRIPT="$LOG_DIR"/"run_corsika_$ID"
    LOGFILE="$LOG_DIR"/"DAT$ID.log"
    generate_corsika_submission_script "$FSCRIPT" "$INPUT" "$LOGFILE" "$CONTAINER_EXTERNAL_DIR"
    generate_htcondor_file "$FSCRIPT.sh"
done

echo "End of job preparation for CORSIKA ($LOG_DIR)."
