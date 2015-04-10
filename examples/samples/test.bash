#!/bin/bash -x

set -e
set -o pipefail


ls asdf | cat | sed -e 's/f/g/g' > xxx || echo "$0 failed"

