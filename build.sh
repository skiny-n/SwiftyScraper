#!/bin/bash

# This script builds and moves the commandline app to the Products directory. 
# Usage: $ sh build.sh


# Build 
xcodebuild \
-workspace WeatherFetcher/WeatherFetcher/WeatherFetcher.xcworkspace \
-scheme WeatherFetcher \
-configuration Debug \
-destination platform=macos \
-derivedDataPath './Build/' \
CODE_SIGN_IDENTITY="" \
CODE_SIGNING_REQUIRED="NO" \
CODE_SIGNING_ALLOWED="NO" \
clean build 

# Move to Products folder
cp -f ./Build/Build/Products/Debug/WeatherFetcher ./Products/WeatherFetcher
cp -R -f ./Build/Build/Products/Debug/Resources/ ./Products/Resources/

# Remove the artifacts

rm -r ./Build/