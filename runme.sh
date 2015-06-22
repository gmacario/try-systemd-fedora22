#!/bin/bash

mkdir -p shared
if [ ! -e shared/runme2.sh ]; then cp runme2.sh shared/; fi
docker run --volume=${PWD}/shared:/shared -ti library/fedora /bin/bash

# EOF
