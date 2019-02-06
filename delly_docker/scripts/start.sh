#!/usr/bin/env bash

set -o errexit
set -o pipefail
set -x

gosu root chmod a+wrx /tmp
env

# newer version of cwltool no longer mounts hardcoded '/var/spool/cwl'
# as $HOME (used for output in the container). Need to pass current
# user's $HOME as output-dir. The other choice is $PWD, which is set
# using '--workdir' in 'docker run' command by cwltool. Currently version
# of cwltool set $PWD same as $HOME
OUTPUT_DIR=$HOME

cd $OUTPUT_DIR
gosu seqware bash -c "$* --output-dir $OUTPUT_DIR"

# allow cwltool to pick up the results created by seqware
gosu root chmod -R a+wrx $OUTPUT_DIR