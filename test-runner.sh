#!/bin/bash
set -o pipefail


get_changes ()
{
	git remote add current https://github.com/todoflux/todoflux.git && \
	git fetch --quiet current && \
	git diff HEAD origin/master --name-only |  awk 'BEGIN {FS = "/"}; {print $1 "/" $2 "/" $3}' | grep -v \/\/ | grep examples | awk -F '[/]' '{print "--framework=" $2}'|uniq
}

if [ "$TRAVIS_BRANCH" = "master" ] && [ "$TRAVIS_PULL_REQUEST" = "false" ]
then
	git submodule add -b gh-pages https://${GH_OAUTH_TOKEN}@github.com/${GH_OWNER}/${GH_PROJECT_NAME} site > /dev/null 2>&1
	cd site
	if git checkout gh-pages; then git checkout -b gh-pages; fi
	git rm -r .
	cp -R ../dist/* .
	cp ../dist/.* .
	git add -f .
	git config user.email 'ilya@pukhalski.com'
	git config user.name 'pukhalski'
	git commit -am 'update the build files for gh-pages [ci skip]'
	printenv
	# Any command that using GH_OAUTH_TOKEN must pipe the output to /dev/null to not expose your oauth token
	git push https://${GH_OAUTH_TOKEN}@github.com/${GH_OWNER}/${GH_PROJECT_NAME} HEAD:gh-pages > /dev/null 2>&1
else
	changes=$(get_changes)

	if [ "${#changes}" = 0 ]
	then
		exit 0
	else
		cd tooling && \
		echo $changes | xargs ./run.sh && \
		cd ../tests && \
		echo $changes | xargs ./run.sh
	fi

	exit $?
fi
