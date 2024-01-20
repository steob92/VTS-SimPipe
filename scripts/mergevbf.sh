#!/bin/bash
# Helper functions for mergevbf; called from prepare_production.sh

get_merge_file_name()
{
    WOBBLE="$1"
    NSB="$2"
    VBF_ID="$3"

    # gamma_V6_CARE_std_Atmosphere61_zen20deg_1.0wob_160MHz_1.vbf.zst
    FNAME="gamma_V6_CARE"
    if [[ $CARE_CONFIG == *"RHV"* ]]; then
        FNAME="${FNAME}_redHV"
    else
        FNAME="${FNAME}_std"
    fi
    FNAME="${FNAME}_Atmosphere${ATMOSPHERE}"
    FNAME="${FNAME}_zen${ZENITH}deg"
    FNAME="${FNAME}_${WOBBLE}wob"
    FNAME="${FNAME}_${NSB}MHz_${VBF_ID}.vbf"
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
    OBS_MODE="$5"

    # mount directories
    CARE_DATA_DIR="${DATA_DIR}/CARE_${OBS_MODE}/W${WOBBLE}/NSB${NSB}"
    MERGEVBF_DATA_DIR="${DATA_DIR}/MERGEVBF_${OBS_MODE}"
    mkdir -p "$MERGEVBF_DATA_DIR"
    CONTAINER_EXTERNAL_DIR="-v \"${MERGEVBF_DATA_DIR}:/workdir/external/mergevbf\""
    CONTAINER_EXTERNAL_DIR="$CONTAINER_EXTERNAL_DIR -v \"${CARE_DATA_DIR}:/workdir/external/care\""
    CONTAINER_EXTERNAL_DIR="$CONTAINER_EXTERNAL_DIR -v \"$LOG_DIR:/workdir/external/log/\""

    batch_size=3
    rm -f "$MERGEVBF_DATA_DIR"/file_list.dat
    rm -f "${MERGEVBF_DATA_DIR}/split_file_list_*"
    find "$CARE_DATA_DIR" -type f -name "*.vbf" -exec basename {} \; | sed 's|^|/workdir/external/care/|' | sort -n > "$MERGEVBF_DATA_DIR"/file_list.dat
    split -d -l $batch_size "$MERGEVBF_DATA_DIR"/file_list.dat "$MERGEVBF_DATA_DIR"/split_file_list_

    if [ -s"${MERGEVBF_DATA_DIR}/file_list.dat" ]; then
        return
    fi

    for flist in "$MERGEVBF_DATA_DIR"/split_file_list_*; do
        vbf_id="${flist##*_}"

        MERGEDFILE=$(get_merge_file_name "$WOBBLE" "$NSB" "$vbf_id")
        RUNNUMBER=$(head -n 1 "$flist" | awk -F '[^0-9]+' '{print $2}')

        MERGEVBF="./bin/mergeVBF \
            /workdir/external/mergevbf/$(basename "$flist") \
            /workdir/external/mergevbf/$MERGEDFILE ${RUNNUMBER}"

        rm -f "${MERGEVBFFSCRIPT}_${vbf_id}.sh"
        echo "#!/bin/bash" > "${MERGEVBFFSCRIPT}_${vbf_id}.sh"
        echo "set -e" >> "${MERGEVBFFSCRIPT}_${vbf_id}.sh"
        if [[ $VTSSIMPIPE_CONTAINER == "docker" ]]; then
            CARE_EXE="docker run --rm $CONTAINER_EXTERNAL_DIR $VTSSIMPIPE_MERGEVBF_IMAGE"
        elif [[ $VTSSIMPIPE_CONTAINER == "apptainer" ]]; then
            CARE_EXE="apptainer exec --cleanenv ${CONTAINER_EXTERNAL_DIR//-v/--bind} --compat docker://$VTSSIMPIPE_MERGEVBF_IMAGE"
        fi
        ZSTD_VBF="zstd /workdir/external/mergevbf/$MERGEDFILE"
        MERGEVBF_EXE="${CARE_EXE} bash -c \"cd /workdir/EventDisplay_v4 && ${MERGEVBF} && ${ZSTD_VBF}\""
        echo "$MERGEVBF_EXE > ${MERGEVBF_DATA_DIR}/${MERGEDFILE}.log 2>&1" >> "${MERGEVBFFSCRIPT}_${vbf_id}.sh"
        (
            echo "if [[ -e \"${MERGEVBF_DATA_DIR}/${MERGEDFILE}.zst\" ]]; then"
            echo "    rm -f \"${MERGEVBF_DATA_DIR}/${MERGEDFILE}\""
            echo "fi"
        ) >> "${MERGEVBFFSCRIPT}_${vbf_id}.sh"
        chmod u+x "${MERGEVBFFSCRIPT}_${vbf_id}.sh"
    done
}
