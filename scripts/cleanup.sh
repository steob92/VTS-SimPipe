#!/bin/bash
# Helper functions for clean of files

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

#####################################################################
# generate cleanup submission scripts
generate_cleanup_submission_script()
{
    CLEANUPSCRIPT="$1"
    LOG_DIR=$(dirname "$CLEANUPSCRIPT")
    OUTPUT_FILE="$2"
    RUN_NUMBER="$3"
    WOFF_LIST="$4"
    CLEANUP_DATA_DIR="${DATA_DIR}/CLEANUP/"
    mkdir -p "${CLEANUP_DATA_DIR}"
    rm -f "$CLEANUP_DATA_DIR/$(basename "$OUTPUT_FILE").cleanup.log"

    # CORSIKA - files are bzipped2
    CORSIKA_DATA_DIR="${DATA_DIR}/CORSIKA"

    echo "#!/bin/bash" > "$CLEANUPSCRIPT.sh"
    for WOBBLE in ${WOFF_LIST}; do
        # GROPTICS - files are removed
        GROPTICS_DATA_DIR="${DATA_DIR}/GROPTICS/W${WOBBLE}"
        CLEANUP_GROPTICS="rm -f -v ${GROPTICS_DATA_DIR}/$(basename "$OUTPUT_FILE").groptics.root"
        echo "$CLEANUP_GROPTICS > $CLEANUP_DATA_DIR/$(basename "$OUTPUT_FILE").cleanup.log 2>&1" >> "$CLEANUPSCRIPT.sh"
    done
    echo "bzip2 -f -v ${CORSIKA_DATA_DIR}/$(basename "$OUTPUT_FILE").telescope >> $CLEANUP_DATA_DIR/$(basename "$OUTPUT_FILE").cleanup.log 2>&1" >> "$CLEANUPSCRIPT.sh"
    echo "bzip2 -f -v ${CORSIKA_DATA_DIR}/$(basename "$OUTPUT_FILE").log >> $CLEANUP_DATA_DIR/$(basename "$OUTPUT_FILE").cleanup.log 2>&1" >> "$CLEANUPSCRIPT.sh"
    chmod u+x "$CLEANUPSCRIPT.sh"
}
