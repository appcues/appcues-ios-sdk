#!/bin/sh

PROJECT_NAME="Appcues"
FRAMEWORK_NAME="AppcuesKit"

XCFRAMEWORK_NAME="${FRAMEWORK_NAME}.xcframework"
BUILD_FOLDER_NAME=$(mktemp -d -t "${FRAMEWORK_NAME}")
FRAMEWORK_PATH="${BUILD_FOLDER_NAME}/${XCFRAMEWORK_NAME}"
SIMULATOR_ARCHIVE_PATH="${BUILD_FOLDER_NAME}/simulator.xcarchive"
IOS_DEVICE_ARCHIVE_PATH="${BUILD_FOLDER_NAME}/iOS.xcarchive"
ZIP_NAME="${XCFRAMEWORK_NAME}.zip"

# Ensure the project file is up to date before trying to archive
mint run xcodegen

xcodebuild archive -quiet -scheme ${PROJECT_NAME} -destination="iOS Simulator" -archivePath "${SIMULATOR_ARCHIVE_PATH}" -sdk iphonesimulator SKIP_INSTALL=NO BUILD_LIBRARIES_FOR_DISTRIBUTION=YES || exit 1
xcodebuild archive -quiet -scheme ${PROJECT_NAME} -destination="iOS" -archivePath "${IOS_DEVICE_ARCHIVE_PATH}" -sdk iphoneos SKIP_INSTALL=NO BUILD_LIBRARIES_FOR_DISTRIBUTION=YES || exit 1

# Ceating XCFramework
xcodebuild -create-xcframework -framework ${SIMULATOR_ARCHIVE_PATH}/Products/Library/Frameworks/${FRAMEWORK_NAME}.framework -framework ${IOS_DEVICE_ARCHIVE_PATH}/Products/Library/Frameworks/${FRAMEWORK_NAME}.framework -output "${FRAMEWORK_PATH}" || exit 1

# Remove old zip before creating new
rm "${ZIP_NAME}"

DESTINATION=$(pwd)
pushd "${BUILD_FOLDER_NAME}"
zip -r "${DESTINATION}/${ZIP_NAME}" "${XCFRAMEWORK_NAME}"
popd

# Clean up temp directory
rm -rf "${BUILD_FOLDER_NAME}"
