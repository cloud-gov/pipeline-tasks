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
UPSTREAM_DIR=$SCRIPTPATH/cf-release
mkdir -p $UPSTREAM_DIR
git -C $UPSTREAM_DIR init --quiet
git -C $UPSTREAM_DIR remote add origin https://github.com/cloudfoundry/cf-release.git
git -C $UPSTREAM_DIR config core.sparsecheckout true
echo templates/ > $UPSTREAM_DIR/.git/info/sparse-checkout
git -C $UPSTREAM_DIR pull origin master --quiet

# Install required gem if not installed
if [ -z $(gem list -i yaml) ]; then
  gem install yaml --no-ri --no-rdoc 2>&1 > /dev/null
fi

# Compare the templates with a ruby script
nomatch () { case "$2" in $1) return 1 ;; *) return 0 ;; esac ; }
for ours in `ls $TEMPLATES_DIR/*.yml`
do
  # ignore any "secret" files
  if nomatch '*secret*' "$ours"; then
    # Get just the filename
    FILE=${ours##*/}
    if [ -f "$SCRIPTPATH/cf-release/templates/$FILE" ]; then
        ruby $SCRIPTPATH/diff-templates.rb $UPSTREAM_DIR/templates/$FILE $TEMPLATES_DIR/$FILE
        echo
    else
        echo "Not found in cf-release/templates: $FILE"
        echo
    fi
  fi
done
