#!/bin/sh
set -e

echo "Starting the Jekyll Action"

echo "::debug ::Starting bundle install"
bundle config path vendor/bundle
bundle install
echo "::debug ::Completed bundle install"

if [ -n "${INPUT_JEKYLL_SRC}" ]; then
  JEKYLL_SRC=${INPUT_JEKYLL_SRC}
  echo "::debug ::Using parameter value ${JEKYLL_SRC} as a source directory"
elif [ -n "${SRC}" ]; then
  JEKYLL_SRC=${SRC}
  echo "::debug ::Using SRC environment var value ${JEKYLL_SRC} as a source directory"
else
  JEKYLL_SRC=$(find . -path ./vendor/bundle -prune -o -name '_config.yml' -exec dirname {} \;)
  echo "::debug ::Resolved ${JEKYLL_SRC} as a source directory"
fi

JEKYLL_ENV=production bundle exec jekyll build -s ${JEKYLL_SRC} -d build
echo "Jekyll build done II"

cd build

# No need to have GitHub Pages to run Jekyll
touch .nojekyll

# Is this a regular repo or an org.github.io type of repo
case "${GITHUB_REPOSITORY}" in
  *.github.io) remote_branch="master" ;;
  *)           remote_branch="gh-pages" ;;
esac

if [ "${GITHUB_REF}" = "refs/heads/${remote_branch}" ]; then
  echo "Cannot publish on branch ${remote_branch}"
  exit 1
fi

echo "Publishing to ${GITHUB_REPOSITORY} on branch ${remote_branch}"

remote_repo="https://${JEKYLL_PAT}@github.com/${GITHUB_REPOSITORY}.git" && \
git init && \
git config user.name "${GITHUB_ACTOR}" && \
git config user.email "${GITHUB_ACTOR}@users.noreply.github.com" && \
git add . && \
git commit -m "jekyll build from Action ${GITHUB_SHA}"

echo "Committed changes"
git log
git branch
git remote add origin $remote_repo
echo "Test"
echo git push --force origin master:$remote_branch
echo "Test 2"
git push --force origin master:$remote_branch
rm -fr .git && \
cd .. 

exit $?
