#!/bin/bash
set -e

sudo curl https://github.com/pantheon-systems/cli/releases/download/0.6.1/terminus.phar -L -o /usr/local/bin/terminus && sudo chmod +x /usr/local/bin/terminus

terminus auth login $PANTHEON_EMAIL --password=$PANTHEON_PASSWORD

# Clone deployment repository.
expect <<delim
  set timeout 60
  eval spawn git clone $PANTHEON_CODE pantheon
  set prompt ":|#|\\\$"
  interact -o -nobuffer -re $prompt return
  send "$PANTHEON_PASSWORD\r"
expect eof
delim

# Set variables
path=$(dirname "$0")
base=$(cd $path/.. && pwd)
pantheon=$base/pantheon
git="( $base/pantheon && git $git_flags)"

# Build the deployment artifact.
sudo rm $base/cnf/settings.php
sudo rm -Rf $base/www/sites/default
mv $base/cnf/pantheon.settings.php $base/cnf/settings.php
$base/bin/watechci --prod

# Add deployment artifact to the repository.
rm -Rf $pantheon/*
mv $base/www/* $pantheon/

# configure git env
git config --global user.email $PANTHEON_EMAIL
git config --global user.name $CIRCLE_PROJECT_USERNAME

# checkout publish branch
(cd $pantheon ; git checkout -b publish)
(cd $pantheon ; git branch -D master)
(cd $pantheon ; git checkout -b master)

# commit build
(cd $pantheon ; git add -Af)
(cd $pantheon ; git commit -m "Successful verified merge of $CIRCLE_PROJECT_USERNAME $CIRCLE_SHA1.")

# push to Pantheon
(cd $pantheon ; git push -f origin master)