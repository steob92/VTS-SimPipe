#!/bin/bash
# Pull all required container images
#
set -e

echo "./pull.sh

Pull all required container images.
Image URLs are read from env_setup.sh.
"

# env variables
# shellcheck source=/dev/null
. "$(dirname "$0")"/../env_setup.sh
echo "VTSSIMPIPE_CONTAINER: $VTSSIMPIPE_CONTAINER"
echo "VTSSIMPIPE_CORSIKA_IMAGE: $VTSSIMPIPE_CORSIKA_IMAGE"
echo "VTSSIMPIPE_GROPTICS_IMAGE: $VTSSIMPIPE_GROPTICS_IMAGE"
echo "VTSSIMPIPE_CARE_IMAGE: $VTSSIMPIPE_CARE_IMAGE"
echo "VTSSIMPIPE_MERGEVBF_IMAGE: $VTSSIMPIPE_MERGEVBF_IMAGE"

if [[ "$VTSSIMPIPE_CONTAINER" == "apptainer" ]]; then
    echo "Pulling apptainer images to $VTSSIMPIPE_CONTAINER_DIR"
    mkdir -p "${VTSSIMPIPE_CONTAINER_DIR}"
    apptainer pull --force --dir "${VTSSIMPIPE_CONTAINER_DIR}/" docker://"${VTSSIMPIPE_CONTAINER_URL}${VTSSIMPIPE_CORSIKA_IMAGE}"
    apptainer pull --force --dir "${VTSSIMPIPE_CONTAINER_DIR}/" docker://"${VTSSIMPIPE_CONTAINER_URL}${VTSSIMPIPE_GROPTICS_IMAGE}"
    apptainer pull --force --dir "${VTSSIMPIPE_CONTAINER_DIR}/" docker://"${VTSSIMPIPE_CONTAINER_URL}${VTSSIMPIPE_CARE_IMAGE}"
    apptainer pull --force --dir "${VTSSIMPIPE_CONTAINER_DIR}/" docker://"${VTSSIMPIPE_CONTAINER_URL}${VTSSIMPIPE_MERGEVBF_IMAGE}"
elif [[ "$VTSSIMPIPE_CONTAINER" == "docker" ]]; then
    echo "Pulling docker images."
    docker pull "${VTSSIMPIPE_CONTAINER_URL}${VTSSIMPIPE_CORSIKA_IMAGE}"
    docker pull "${VTSSIMPIPE_CONTAINER_URL}${VTSSIMPIPE_GROPTICS_IMAGE}"
    docker pull "${VTSSIMPIPE_CONTAINER_URL}${VTSSIMPIPE_CARE_IMAGE}"
    docker pull "${VTSSIMPIPE_CONTAINER_URL}${VTSSIMPIPE_MERGEVBF_IMAGE}"
else
    echo "Unknown container type $VTSSIMPIPE_CONTAINER."
    exit
fi
