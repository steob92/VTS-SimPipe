#!/bin/bash
# Generate CORSIKA input files and submission scripts
#

echo "Generate CORSIKA input files and submission scripts."
echo

if [ $# -lt 2 ]; then
echo "./submit_corsika.sh <config file> <input file template>

For template configuration file, see ./config/CORSIKA/config_template.dat
For a CORSIKA input file template, see ./config/CORSIKA/input_template.dat
"
exit
fi

# env variables
source ../env_setup.sh
echo "VTSSIMPIPE_CORSIKA_DIR: $VTSSIMPIPE_CORSIKA_DIR"
echo "VTSSIMPIPE_CORSIKA_EXE: $VTSSIMPIPE_CORSIKA_EXE"
echo "VTSSIMPIPE_LOG_DIR: $VTSSIMPIPE_LOG_DIR"

# read configuration parameters
if [[ ! -e $1 ]]; then
    echo "Configuration file $1 does not exist."
    exit
fi
source $1

# check that input file template exists
if [[ ! -e $2 ]]; then
    echo "Input file template $2 does not exist."
    exit
fi

###################
# configuration parameters (some of them zenith angle dependent)

# core scatter area
get_core_scatter()
{
    ZENITH=$1
    # TODO
    if [[ $ZENITH -lt 40 ]]; then
        echo "1500.E2"
    else
        echo "1500.E2"
    fi
}

# minimum energy
get_energy_min()
{
    ZENITH=$1
    # TODO
    if [[ $ZENITH -lt 40 ]]; then
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
echo "First seed: $S1"

# directories
DIRSUFF="Zd${ZENITH}/CORSIKA/"
LOGDIR="$VTSSIMPIPE_LOG_DIR"/"$DIRSUFF"
DATADIR="$VTSSIMPIPE_CORSIKA_DIR"/"$DIRSUFF"
mkdir -p "$LOGDIR"
mkdir -p "$DATADIR"
echo "Log directory: $LOGDIR"
echo "Data directory: $DATADIR"

# generate input files and submission scripts
generate_corsika_submission_script()
{
    FSCRIPT=$1
    INPUT=$2
    LOGFILE=$3
    LOGDIR=$(dirname "$INPUT")
    rm -f "$LOGFILE"

    # submission script
    echo "#!/bin/bash" > "$FSCRIPT"
    if [[ $VTSSIMPIPE_CORSIKA_EXE == *"docker"* ]]; then
        INPUT="/workdir/external/$(basename "$INPUT")"
        CORSIKA_EXE=${VTSSIMPIPE_CORSIKA_EXE/CORSIKALOGDIR/$LOGDIR}
        CORSIKA_EXE=${CORSIKA_EXE/CORSIKAINPUTFILE/$INPUT}
    else
        CORSIKA_EXE="$VTSSIMPIPE_CORSIKA_EXE < $INPUT"
    fi
    echo "$CORSIKA_EXE > $LOGFILE" >> "$FSCRIPT"
    chmod u+x "$FSCRIPT"
}

# require to set docker paths correctly

for ID in $(seq 0 "$N_RUNS");
do
    # input card
    INPUT="$LOGDIR"/"input_$ID.dat"
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
        -e "s|output_directory|$DATADIR|" \
        -e "s|seed_1|$S1|" \
        -e "s|seed_2|$S2|" \
        -e "s|seed_3|$S3|" \
        -e "s|seed_4|$S4|" \
        "$2" > "$INPUT"

    S1=$((S4 + 2))

    # submission script and HT condor file
    FSCRIPT="$LOGDIR"/"run_corsika_$ID"
    LOGFILE="$LOGDIR"/"DAT$ID.log"
    generate_corsika_submission_script "$FSCRIPT" "$INPUT" "$LOGFILE"
done
