#!/usr/bin/env bash

set -o errexit
set -o pipefail
set -x

gosu root chmod a+wrx /tmp
gosu root chmod a+wrx /var/spool/cwl
#export TMPDIR=/tmp
#export HOME=/var/spool/cwl
env
whoami
gosu seqware bash -c "$*"
#allow cwltool to pick up the results created by seqware
gosu root chmod -R a+wrx /var/spool/cwl
