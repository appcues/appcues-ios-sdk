#!/bin/sh

repoName="appcues-ios-sdk"
initialBranch=$(git rev-parse --abbrev-ref HEAD)
versionFile="./Sources/AppcuesKit/Version.swift"

# get last line in Version.swift
versionLine=$(tail -n 1 $versionFile)
# split at the =
version=$(cut -d "=" -f2- <<< "$versionLine")
# remove quotes and spaces
version=$(sed "s/[' \"]//g" <<< "$version")

# check that we're on the `main` branch
if [ $initialBranch != 'main' ]
then
    read -r -p "Current branch: $initialBranch. Documentation should usually be updated from the main branch. Are you sure you want to continue? [y/N] " response
    case "$response" in
        [yY][eE][sS]|[yY])
            ;;
        *)
            exit 1
            ;;
    esac
fi

xcodebuild docbuild \
    -quiet \
    -scheme Appcues \
    -destination generic/platform=iOS \
    OTHER_DOCC_FLAGS="--transform-for-static-hosting --hosting-base-path $repoName --output-path docs"

zip -r docs.zip docs
git checkout gh-pages
# removing existing docs to ensure no old files linger
rm -rf ./docs
unzip -o docs.zip
rm docs.zip

git add .
git commit -m "📝 Update compiled docs for $version"
git push

git checkout $initialBranch
