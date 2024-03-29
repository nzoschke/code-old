#!/bin/bash
# Reference implementation of a simple "slug compiler"

# set up logging; stdout is tee'd to compile log, stderr appends to debug log
TMP_DIR=$(dirname $PWD)/.tmp
exec 1> >(tee -a $TMP_DIR/compile.log)
exec 2> >(cat >> $TMP_DIR/debug.log)

# main script
set -xo pipefail
source $TMP_DIR/build_env

GIT_DIR=$(pwd)
WORK_DIR=$(dirname $GIT_DIR)
BP_DIR=$WORK_DIR/.bp

touch $TMP_DIR/start
echo "-----> Heroku receiving push"

read oldrev newrev ref
git --work-tree=$WORK_DIR checkout -f $newrev

echo "-----> Updating buildpack..."
git clone $BUILDPACK_URL $BP_DIR 1>&2

# run detect / compile / release in a clean environment
_env() { env -i PATH=$PATH "$@"; }
DETECT=$(_env $BP_DIR/bin/detect $WORK_DIR | tee $TMP_DIR/detect.log)
echo "-----> $DETECT app detected"
_env $BP_DIR/bin/compile $WORK_DIR $GIT_DIR/.cache ; STATUS=$?
_env $BP_DIR/bin/release $WORK_DIR > $TMP_DIR/release.log

if [ $STATUS != 0 ]; then
  echo "!     Heroku push rejected"
else
  (
    cd $TMP_DIR
    echo -e ".git/\n.tmp/" > exclude
    mksquashfs $WORK_DIR slug.img -all-root -ef exclude -noappend -no-progress 1>&2
    echo "-----> Compiled slug size is $(du -h slug.img | cut -f1)"

    # prepare release json
    ruby <<'EOF'
    require "json"
    require "yaml"
    m = YAML.load_file "metadata.yml"
    r = YAML.load_file "release.log"
    File.open("release.json", "w") do |f|
      f.write({
        "head"          => `git rev-parse head`.strip,
        "release_descr" => "Deploy slug from code.heroku.com",
        "slug_put_key"  => m["slug_put_key"],
        "slug_version"  => 2,
        "stack"         => "cedar",
      }.merge(r).to_json)
    end
EOF

    cat release.json 1>&2

    # PUT slug and POST release
    _ex() { grep "^$1:" metadata.yml | cut -d" " -f2; }
    echo -n "-----> Launching..."
    curl -v -T slug.img "$(grep slug_put_url metadata.yml | cut -d' ' -f2)" >> debug.log
    VERSION=$(curl -v -H "Content-Type:application/json" -H "Accept:application/json" -X POST -d @release.json "$(_ex release_url)")
    echo " done, $VERSION"
    echo "       http://$(_ex url) deployed to Heroku"
    
  )
fi

echo $STATUS > $TMP_DIR/exit
exit $STATUS
