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
    WOBBLE="$4"
    rm -f "$OUTPUT_FILE.cleanup.log"

    # CORSIKA - no cleanup (yet)
    CORSIKA_DATA_DIR="${DATA_DIR}/CORSIKA"
    # GROPTICS - files are removed
    GROPTICS_DATA_DIR="${DATA_DIR}/GROPTICS/W${WOBBLE}"

    echo "#!/bin/bash" > "$CLEANUPSCRIPT.sh"
    CLEANUP_GROPTICS="ls -l ${GROPTICS_DATA_DIR}"
    echo "$CLEANUP_GROPTICS > "$OUTPUT_FILE".cleanup.log 2>&1" >> "$CLEANUPSCRIPT.sh"
    chmod u+x "$CLEANUPSCRIPT.sh"
}
