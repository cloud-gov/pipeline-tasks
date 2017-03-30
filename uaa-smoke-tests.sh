#!/bin/sh

set -e

SCRIPTPATH=$(cd $(dirname $0); pwd -P)
pip install bs4 requests
"${SCRIPTPATH}"/uaa-smoke-tests.py
