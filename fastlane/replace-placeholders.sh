# replace placeholders
sed -i '' -e "s/<#APPCUES_ACCOUNT_ID#>/\"$1\"/g" ../Examples/DeveloperCocoapodsExample/CocoapodsExample/AppDelegate.swift
