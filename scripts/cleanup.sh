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
    OUTPUT_DIR="$2"
    CLEANUP_DATA_DIR="${DATA_DIR}/CLEANUP/"
    mkdir -p "${CLEANUP_DATA_DIR}"
    # CORSIKA - files are bzipped2
    CORSIKA_DATA_DIR="${DATA_DIR}/CORSIKA"

    echo "#!/bin/bash" > "$CLEANUPSCRIPT.sh"
    echo "RUN_NUMBER=\$1" >> "$CLEANUPSCRIPT.sh"
    echo "rm -f \"$CLEANUP_DATA_DIR/DAT\${RUN_NUMBER}.cleanup.log\"" >> "$$CLEANUPSCRIPT.sh"
    # GROPTICS - files are removed
    # TODO - not removed yet
    CLEANUP_GROPTICS="find ${DATA_DIR}/GROPTICS/ -name \"DAT\${RUN_NUMBER}*.groptics.root\" -print" >> "$CLEANUPSCRIPT.sh"
    echo "$CLEANUP_GROPTICS > $CLEANUP_DATA_DIR/DAT\${RUN_NUMBER}.cleanup.log 2>&1" >> "$CLEANUPSCRIPT.sh"
    echo "bzip2 -f -v ${CORSIKA_DATA_DIR}/DAT\${RUN_NUMBER}.telescope >> $CLEANUP_DATA_DIR/DAT\${RUN_NUMBER}.cleanup.log 2>&1" >> "$CLEANUPSCRIPT.sh"
    echo "bzip2 -f -v ${CORSIKA_DATA_DIR}/DAT\${RUN_NUMBER}.log >> $CLEANUP_DATA_DIR/DAT\${RUN_NUMBER}.cleanup.log 2>&1" >> "$CLEANUPSCRIPT.sh"
    chmod u+x "$CLEANUPSCRIPT.sh"
}
