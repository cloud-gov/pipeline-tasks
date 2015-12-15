#!/bin/sh

set -e

#
# A little environment validation
#
if [ -z "$TEMPLATES_DIR" ]; then
  echo "must specify \$TEMPLATES_DIR" >&2
  exit 1
fi

SCRIPTPATH=$( cd $(dirname $0) ; pwd -P )

# Get the cf upstream templates
if [ -d "cf-release" ]; then
  rm -rf cf-release
fi
mkdir -p cf-release
cd cf-release
git init &> /dev/null
git remote add -f origin https://github.com/cloudfoundry/cf-release.git &> /dev/null
git config core.sparsecheckout true &> /dev/null
echo templates/ > .git/info/sparse-checkout
git pull origin master &> /dev/null
cd - &> /dev/null

# Install required gem if it isn't instaled
if [ -z $(gem list -i yaml) ]; then
  gem install yaml --no-ri --no-rdoc 2>&1 > /dev/null
fi

# Compare the templates with a ruby script
for ours in `ls $TEMPLATES_DIR/*.yml`
do
  if [[ $ours != *"secret"* ]]; then
    FILE=${ours##*/}
    if [[ -f "cf-release/templates/$FILE" ]]; then
        ruby $SCRIPTPATH/diff-templates.rb cf-release/templates/$FILE $TEMPLATES_DIR/$FILE
        echo
    else
        echo "Not found in cf-release/templates: $FILE"
        echo
    fi
  fi
done
