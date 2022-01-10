#!/bin/bash

#
# ZEUTS
#

## Need To Fill
#Sync - Requierd
ROM_NAME="PixelExtended"
ANDROID_VERSION="12"
REPO_URL="https://github.com/PixelExtended/manifest"
REPO_BRANCH="snow"
MANIFEST_URL=""
MANIFEST_BRANCH=""

#Build - Requierd 
DEVICE_CODENAME="mojito"
AUTO_BRINGUP=""
LUNCH_NAME="aosp_mojito-userdebug"
BACON_NAME="mka bacon -j16"

#Upload stuff - Optional
UPLOAD_TYPE="OFF"
UPLOAD_RECOVERY=""
BUILD_TYPE="OFFICIAL"

#Google Drive - Optional
GD_PATH=""

#Github Releases - Optional
GH_USERNAME=""
GH_REPO=""

#SourceForge - Optional
SF_USER="zaxismxt"
SF_PASS=""
SF_PROJECT=""
SF_PATH=""

#Telegram - Optional
TG_USERNAME="@ZEUTS"
TG_TOKEN="5098685564:AAF-OWxf1gjAoLUejp99AWNsdxl7DuCCAkk"
TG_CHAT="-1001586406120"

source build.sh
