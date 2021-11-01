# replace placeholders
sed -i '' -e "s/<#APPCUES_ACCOUNT_ID#>/\"$2\"/g" ../Examples/${1}/AppDelegate.swift
sed -i '' -e "s/APPCUES_ACCOUNT_ID/$2/g" ../Examples/${1}/Info.plist
