#!/bin/bash

lines=$(grep -iEA 1 '^#+ *security considerations *#* *$' pull-request/.git/body | grep -ev '^ *\[Note' | wc -l)

ls -al pull-request


if [ ${lines} -ge 2 ]; then
    exit 0
else
    echo "didn't find Security Considerations section in PR"
    exit 1
fi
