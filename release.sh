#!/bin/sh

# MIT License
# 
# Copyright (c) 2021 Segment
# 
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
# 
# The above copyright notice and this permission notice shall be included in all
# copies or substantial portions of the Software.
# 
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
# SOFTWARE.

# Original source: https://github.com/segmentio/analytics-swift/blob/main/release.sh

# check if `gh` tool is installed.
if ! command -v gh &> /dev/null
then
	echo "Github CLI tool is required, but could not be found."
	echo "Install it via: $ brew install gh"
	exit 1
fi

# check if `gh` tool has auth access.
# command will return non-zero if not auth'd.
authd=$(gh auth status -t)
if [[ $? != 0 ]]
then
	echo "ex: $ gh auth login"
	exit 1
fi

# check if `cocoapods` is installed.
if ! command pod --version &> /dev/null
then
	echo "Cocoapods is required, but could not be found."
	echo "Install it via: $ gem install cocoapods"
	exit 1
fi

# check if `cocoapods` trunk is authenticated. Expecting output like
#  - Pods:
#    - Appcues
pods=$(pod trunk me | grep -q "    - Appcues")
if [[ $? != 0 ]]
then
	echo "You are not currently allowed to push new versions for the Appcues pod."
	echo "Authenticate with: $ pod trunk register mobile@appcues.com '<YOUR NAME>'"
	exit 1
fi

# check that we're on the `main` branch
branch=$(git rev-parse --abbrev-ref HEAD)
if [ $branch != 'main' ] && [[ $branch != release/* ]]
then
	echo "The 'main' must be the current branch to make a release."
	echo "You are currently on: $branch"
	exit 1
fi

versionFile="./Sources/AppcuesKit/Version.swift"

# get last line in Version.swift
versionLine=$(tail -n 1 $versionFile)
# split at the =
version=$(cut -d "=" -f2- <<< "$versionLine")
# remove quotes and spaces
version=$(sed "s/[' \"]//g" <<< "$version")

echo "AppcuesKit current version: $version"

# no args, so give usage.
if [ $# -eq 0 ]
then
	echo "Release automation script"
	echo ""
	echo "Usage: $ ./release.sh <version>"
	echo "   ex: $ ./release.sh \"1.0.2\""
	exit 0
fi

newVersion="${1}"
echo "Preparing to release $newVersion..."

versionComparison=$(./fastlane/semver.sh $newVersion $version)

if [ $versionComparison != '1' ]
then
	echo "New version must be greater than previous version ($version)."
	exit 1
fi

read -r -p "Are you sure you want to release $newVersion? [y/N] " response
case "$response" in
	[yY][eE][sS]|[yY])
		;;
	*)
		exit 1
		;;
esac

# update sources/AppcuesKit/Version.swift
# - remove last line...
sed -i '' -e '$ d' $versionFile
# - add new line w/ new version
echo "internal let __appcues_version = \"$newVersion\"" >> $versionFile

# update the podspec
sed -i '' -e "s/$version/$newVersion/g" Appcues.podspec

# commit the version change.
git commit -am "🍏 Update version to $newVersion"
git push

# get the commits since the last release, filtering ones that aren't relevant.
changelog=$(git log --pretty=format:"- [%as] %s (%h)" $(git describe --tags --abbrev=0 @^)..@ --abbrev=7 | sed '/[🔧🎬⬆📸✅💡📝]/d')
tempFile=$(mktemp)

# write changelog to temp file.
echo "$changelog" >> $tempFile

# gh release will make both the tag and the release itself.
gh release create $newVersion -F $tempFile -t $newVersion --target $branch

# remove the tempfile.
rm $tempFile

# build up the xcframework and upload to github
./fastlane/build.sh
gh release upload $newVersion AppcuesKit.xcframework.zip

# push the updated podspec
# the version tag need to validate the podspec should have been created above
pod trunk push Appcues.podspec
