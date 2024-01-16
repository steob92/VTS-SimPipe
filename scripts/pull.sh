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

if [[ "$VTSSIMPIPE_CONTAINER" == "apptainer" ]]; then
    echo "Pulling apptainer images."
    apptainer pull --disable-cache --force docker://"$VTSSIMPIPE_CORSIKA_IMAGE"
    apptainer pull --disable-cache --force docker://"$VTSSIMPIPE_GROPTICS_IMAGE"
    apptainer pull --disable-cache --force docker://"$VTSSIMPIPE_CARE_IMAGE"
elif [[ "$VTSSIMPIPE_CONTAINER" == "docker" ]]; then
    echo "Pulling docker images."
    docker pull "$VTSSIMPIPE_CORSIKA_IMAGE"
    docker pull "$VTSSIMPIPE_GROPTICS_IMAGE"
    docker pull "$VTSSIMPIPE_CARE_IMAGE"
else
    echo "Unknown container type $VTSSIMPIPE_CONTAINER."
    exit
fi
