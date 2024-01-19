#!/bin/bash
# Helper functions for mergevbf; called from prepare_production.sh

get_merge_file_name()
{
    WOBBLE="$3"
    NSB="$4"
    RUNNUMBER="$5"

    # gamma_V6_CARE_std_Atmosphere61_zen20deg_1.0wob_160MHz_1.vbf.zst
    FNAME="gamma_V6_CARE_"
    if [[ $CARE_CONFIG == *"RHV"* ]]; then
        FNAME="${FNAME}_redHV"
    else
        FNAME="${FNAME}_std"
    fi
    FNAME="${FNAME}"
    echo "$FNAME"
}


#####################################################################
# generate mergevbf input files and submission scripts
#
# /workdir/external/log:     directory for run scripts and pilot files
# /workdir/external/care     :directory with CARE (input) files
#
generate_mergevbf_submission_script()
{
    MERGEVBFFSCRIPT="$1"
    LOG_DIR=$(dirname "$MERGEVBFFSCRIPT")
    OUTPUT_FILE="$2"
    rm -f "$OUTPUT_FILE.mergevbf.log"
    WOBBLE="$3"
    NSB="$4"
    RUNNUMBER="$5"

    # mount directories
    CARE_DATA_DIR="${DATA_DIR}/CARE/W${WOBBLE}/NSB${NSB}"
    MERGEVBF_DATA_DIR="${DATA_DIR}/MERGEVBF/"
    mkdir -p "$MERGEVBF_DATA_DIR"
    CONTAINER_EXTERNAL_DIR="-v \"${MERGEVBF_DATA_DIR}:/workdir/external/mergevbf\""
    CONTAINER_EXTERNAL_DIR="$CONTAINER_EXTERNAL_DIR -v \"${CARE_DATA_DIR}:/workdir/external/care\""
    CONTAINER_EXTERNAL_DIR="$CONTAINER_EXTERNAL_DIR -v \"$LOG_DIR:/workdir/external/log/\""

    # gamma_V6_CARE_std_Atmosphere61_zen20deg_1.0wob_160MHz_1.vbf.zst
    MERGEDFILE=get_merge_file_name "$WOBBLE" "$NSB" "$RUNNUMBER"

    MERGEVBF="./bin/mergeVBF \
     /workdir/external/mergevbf/vbf_files.list \
     /workdir/external/mergevbf/$(basename "$OUTPUT_FILE").vbf ${RUNNUMBER}"

    echo "#!/bin/bash" > "$MERGEVBFFSCRIPT.sh"
    if [[ $VTSSIMPIPE_CONTAINER == "docker" ]]; then
        CARE_EXE="docker run --rm $CONTAINER_EXTERNAL_DIR $VTSSIMPIPE_MERGEVBF_IMAGE"
    elif [[ $VTSSIMPIPE_CONTAINER == "apptainer" ]]; then
        CARE_EXE="apptainer exec --cleanenv ${CONTAINER_EXTERNAL_DIR//-v/--bind} --compat docker://$VTSSIMPIPE_MERGEVBF_IMAGE"
    fi
    COLLECT_VBF="ls /workdir/external/care/*.vbf > /workdir/external/mergevbf/vbf_files.list"
    ZSTD_VBF="zstd $MERGEDFILE"
    MERGEVBF_EXE="${CARE_EXE} bash -c \"cd /workdir/EventDisplay_v4 && ${COLLECT_VBF} && ${MERGEVBF} && ${ZSTD_VBF}\""
    echo "$MERGEVBF_EXE > $MERGEVBF_DATA_DIR/$(basename "$OUTPUT_FILE").mergevbf.log 2>&1" >> "$MERGEVBFFSCRIPT.sh"
    chmod u+x "$MERGEVBFFSCRIPT.sh"
}
