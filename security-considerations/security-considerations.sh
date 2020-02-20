#!/bin/bash

set -x

# look for a security considerations header and the two lines after it.    drop the heading                           drop the instructions  drop any empty lines
lines=$(grep -iEA 2 '^#+ *security considerations' pull-request/.git/body | grep -Ev '^#+ *security considerations' | grep -Ev '^ *\[Note' | grep -Ev '^ *$')

if [[ -z ${lines} ]]; then
    echo "Didn't find Security Considerations section in PR"
    exit 1
fi

