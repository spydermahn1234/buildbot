#!/bin/bash

#
# Orel6505
#

## Sync
sync() {
    if ! [ -d "${MY_DIR}"/rom/"${ROM_NAME}"-"${ANDROID_VERSION}" ]; then
        mkdir "${MY_DIR}"/rom/"${ROM_NAME}"-"${ANDROID_VERSION}"
    fi
    cd "${MY_DIR}"/rom/"${ROM_NAME}"-"${ANDROID_VERSION}"
    START_REPO=$(date +"%s")
    repo init -u "${REPO_URL}" -b "${REPO_BRANCH}" --depth=1
    if [ -d ".repo/local_manifests" ]; then
        rm -fr ".repo/local_manifests"
    fi
    git clone "${MANIFEST_URL}" -b "${MANIFEST_BRANCH}" .repo/local_manifests --depth=1
    if [ "${TG_CHAT}" != "" ]; then
        curl -s --data parse_mode=HTML --data text="Startd to sync ${ROM_NAME}-${ANDROID_VERSION}!" --data chat_id="${TG_CHAT}" --request POST https://api.telegram.org/bot"${TG_TOKEN}"/sendMessage 
    else 
        echo "Startd to sync ${ROM_NAME}-${ANDROID_VERSION}!"
    fi
    repo sync --force-sync --no-tags --no-clone-bundle
    if ! [ -d "${MY_DIR}"/rom/"${ROM_NAME}"-"${ANDROID_VERSION}/bootable" ]; then 
        END_REPO=$(date +"%s")
        DIFF_REPO=$((END_REPO-START_REPO))
        if [ "${TG_CHAT}" != "" ]; then
            curl -s --data parse_mode=HTML --data text="${ROM_NAME}-${ANDROID_VERSION} Sync failed in $((DIFF_REPO / 3600)) hours, $((DIFF_REPO % 3600 / 60)) minutes and $((DIFF_REPO % 60)) seconds!
"${TG_USERNAME}" don't be lazy and open build machine for errors" --data chat_id="${TG_CHAT}" --request POST https://api.telegram.org/bot"${TG_TOKEN}"/sendMessage 
        else
            echo "Sync failed in $((DIFF_REPO / 3600)) hours, $((DIFF_REPO % 3600 / 60)) minutes and $((DIFF_REPO % 60)) seconds!"
        fi
        curl -s --data parse_mode=HTML --data sticker=CAADBQADGgEAAixuhBPbSa3YLUZ8DBYE --data chat_id="${TG_CHAT}" --request POST https://api.telegram.org/bot"${TG_TOKEN}"/sendSticker
        return 1
    else
        END_REPO=$(date +"%s")
        DIFF_REPO=$((END_REPO-START_REPO))
        if [ "${TG_CHAT}" != "" ]; then
            curl -s --data parse_mode=HTML --data text="${ROM_NAME}-${ANDROID_VERSION} source synced successfully! It's took $((DIFF_REPO / 3600)) hours, $((DIFF_REPO % 3600 / 60)) minutes and $((DIFF_REPO % 60)) seconds!" --data chat_id="${TG_CHAT}" --request POST https://api.telegram.org/bot$TG_TOKEN/sendMessage 
            curl -s --data parse_mode=HTML --data text="The sync succedded, Starting to build..." --data chat_id=$TG_CHAT --data chat_id="${TG_CHAT}" --request POST https://api.telegram.org/bot"${TG_TOKEN}"/sendMessage 
        else
            echo "The sync succedded, Starting to build..." 
        fi
    fi
}

## Build 
build() {
    cd "${MY_DIR}"/rom/"${ROM_NAME}"-"${ANDROID_VERSION}"
    repo sync --force-sync --no-tags --no-clone-bundle
    source build/envsetup.sh
    for CODENAME in ${DEVICE_CODENAME}
    do
        if [ "${AUTO_BRINGUP}" == "Y" ] || [ "${AUTO_BRINGUP}" == "yes" ] || [ "${AUTO_BRINGUP}" == "Yes" ]; then
            VENDOR_NAME="$(find . ~ -type d -name "${CODENAME}" | sort -nr | awk 'NR==1,NR==1')"
            VENDOR_NAME="$(dirname $VENDOR_NAME)"
            VENDOR_NAME="$(basename $VENDOR_NAME)"
            cd "${MY_DIR}"/rom/"${ROM_NAME}"-"${ANDROID_VERSION}"/device/"${VENDOR_NAME}"/"${CODENAME}"
            PREBUILT_LUNCH=$(ls *${CODENAME}*|cut -f1 -d _)
            sed -i "s/${PREBUILT_LUNCH}/${LUNCH_NAME}/g" ${PREBUILT_LUNCH}_${CODENAME}.mk
            if [ -e "${MY_DIR}"/rom/"${ROM_NAME}"-"${ANDROID_VERSION}"/vendor/"${LUNCH_NAME}"/config/common_full_phone.mk ]; then
                sed -i "/call inherit-product, vendor/c\$(call inherit-product, vendor/${LUNCH_NAME}/config/common_full_phone.mk)" ${PREBUILT_LUNCH}_${CODENAME}.mk
            else
                sed -i "/call inherit-product, vendor/c\$(call inherit-product, vendor/${LUNCH_NAME}/config/common.mk)" ${PREBUILT_LUNCH}_${CODENAME}.mk
            fi
            sed -i "s/${PREBUILT_LUNCH}/${LUNCH_NAME}/g" AndroidProducts.mk
            mv ${PREBUILT_LUNCH}_${CODENAME}.mk ${LUNCH_NAME}_${CODENAME}.mk
            cd "${MY_DIR}"/rom/"${ROM_NAME}"-"${ANDROID_VERSION}"
        fi
        lunch "${LUNCH_NAME}"_"${CODENAME}"-userdebug
        START_BUILD=$(date +"%s")
        if [ -e "{${OUT_DIR}"/out/target/product/"${CODENAME}"/build_fingerprint.txt ]; then
	        END_BUILD=$(date +"%s")
	        DIFF_BUILD=$((END_BUILD-START_BUILD))
            if [ "${TG_CHAT}" != "" ]; then
	            curl -s --data parse_mode=HTML --data text="dumpvars for ${CODENAME} failed.
"${TG_USERNAME}" don't be lazy and open build machine for errors" --request POST https://api.telegram.org/bot"${TG_TOKEN}"/sendMessage
                curl -s --data parse_mode=HTML --data sticker=CAADBQADGgEAAixuhBPbSa3YLUZ8DBYE --data chat_id="${TG_CHAT}" --request POST https://api.telegram.org/bot"${TG_TOKEN}"/sendSticker
            else
                echo "dumpvars for ${CODENAME} failed."
            fi
            return 1
        fi
        if [ "${TG_CHAT}" != "" ]; then
            curl -s --data parse_mode=HTML --data text="${ROM_NAME}-${ANDROID_VERSION} Build for ${CODENAME} started!" --data chat_id="${TG_CHAT}" --request POST https://api.telegram.org/bot"${TG_TOKEN}"/sendMessage 
        else
            echo "Build for ${CODENAME} started!"
        fi
        make ${BACON_NAME}
        BUILD_STATUS=${?}
        if [ "${BUILD_STATUS}" != 0 ]; then
	        END_BUILD=$(date +"%s")
	        DIFF_BUILD=$((END_BUILD-START_BUILD))
            if [ "${TG_CHAT}" != "" ]; then
	            curl -s --data parse_mode=HTML --data text="The ${ROM_NAME}-${ANDROID_VERSION} build for ${CODENAME} failed in $((DIFF_BUILD / 3600)) hours, $((DIFF_BUILD % 3600 / 60)) minutes and $((DIFF_BUILD % 60)) seconds!
"${TG_USERNAME}" don't be lazy and open build machine for errors" --data chat_id="${TG_CHAT}" --request POST https://api.telegram.org/bot"${TG_TOKEN}"/sendMessage 
                curl -F document=@out/error.log --request POST https://api.telegram.org/bot"${TG_TOKEN}"/sendDocument?chat_id="${TG_CHAT}"
                curl -s --data parse_mode=HTML --data sticker=CAADBQADGgEAAixuhBPbSa3YLUZ8DBYE --data chat_id="${TG_CHAT}" --request POST https://api.telegram.org/bot"${TG_TOKEN}"/sendSticker
            else
                echo "Build for ${CODENAME} failed."
            fi
            return 1
        else
            END_BUILD=$(date +"%s")
	        DIFF_BUILD=$((END_BUILD-START_BUILD))
            if [ "${TG_CHAT}" != "" ]; then
                curl -s --data parse_mode=HTML --data text="The ${ROM_NAME}-${ANDROID_VERSION} build for ${CODENAME} succeed!
The build took $((DIFF_BUILD / 3600)) hours, $((DIFF_BUILD % 3600 / 60)) minutes and $((DIFF_BUILD % 60)) seconds!" --data chat_id="${TG_CHAT}" --request POST https://api.telegram.org/bot"${TG_TOKEN}"/sendMessage 
            else
                echo "${ROM_NAME} for ${CODENAME} succeed!"
            fi
            cd "${MY_DIR}"/rom/"${ROM_NAME}"-"${ANDROID_VERSION}"/out/target/product/"${CODENAME}"
            ROM_ZIP=$(find -type f -name "*.zip" -exec stat -c '%Y %n' {} \; | sort -nr | awk 'NR==1,NR==1 {print $2 }' | head -n 20) 
            ROM_ZIP=$(basename $ROM_ZIP)
            RECOVERY_IMG=$(ls recovery.img)
            if [ -e *.sha256 ]; then
                ROM_HASH256=$(find -type f -name "*.sha256sum" -exec stat -c '%Y %n' {} \; | sort -nr | awk 'NR==1,NR==1 {print $2 }')
                ROM_HASH=$(basename $ROM_HASH256)
            else
                ROM_HASH5=$(find -type f -name "*.md5sum" -exec stat -c '%Y %n' {} \; | sort -nr | awk 'NR==1,NR==1 {print $2 }')
                ROM_HASH=$(basename $ROM_HASH5)
            fi

            #if github release
            if [ "${UPLOAD_TYPE}" == "GH" ]; then
                GH_RELEASE="${BUILD_TYPE}"-"${ROM_ZIP}"
                if ! [ -d "${MY_DIR}"/"${GH_REPO}" ]; then
                    git clone https://github.com/"${GH_USERNAME}"/"${GH_REPO}" "${MY_DIR}"
                fi
                cp "${ROM_ZIP}" "${MY_DIR}"/"${GH_REPO}"
                cp "${ROM_HASH}" "${MY_DIR}"/"${GH_REPO}"
                if [ "${UPLOAD_RECOVERY}" = "true" ]; then
                    cp "${RECOVERY_IMG}" "${MY_DIR}"/"${GH_REPO}"
                fi
                cd "${MY_DIR}"/"${GH_REPO}"
                if ! [ "${UPLOAD_RECOVERY}" = "true" ]; then
                    gh release create "${GH_RELEASE}" -t "${GH_RELEASE}" "${ROM_ZIP}" "${ROM_HASH}" "${RECOVERY_IMG}"
                    rm "${RECOVERY_IMG}"
                else 
                    gh release create "${GH_RELEASE}" -t "${GH_RELEASE}" "${ROM_ZIP}" "${ROM_HASH}"
                fi
                if [ "${TG_CHAT}" != "" ]; then
                    curl -s --data parse_mode=HTML --data text="Upload ${ROM_ZIP} for ${CODENAME} succeed!" --data reply_markup="{\"inline_keyboard\": [[{\"text\":\"Download!\", \"url\": \"https://github.com/${GH_USERNAME}/${GH_REPO}/${GH_RELEASE}\"}]]}" --data chat_id="${TG_CHAT}" --request POST https://api.telegram.org/bot"${TG_TOKEN}"/sendMessage
                    curl -s --data parse_mode=HTML --data sticker=CAADBQADGgEAAixuhBPbSa3YLUZ8DBYE --data chat_id="${TG_CHAT}" --request POST https://api.telegram.org/bot"${TG_TOKEN}"/sendSticker
                else
                    echo "Upload ${ROM_ZIP} for ${CODENAME} succeed! https://github.com/${GH_USERNAME}/${GH_REPO}/${GH_RELEASE}"
                fi
            fi

            #if sourceforge release
            if [ "${UPLOAD_TYPE}" == "SF" ]; then
                if [ "${SF_PATH}" == "" ]; then
			        sshpass -p "${SF_PASS}" scp ${ROM_ZIP} ${SF_USER}@frs.sourceforge.net:/home/frs/project/${SF_PROJECT}/${CODENAME}
                    if [ "${UPLOAD_RECOVERY}" = "true" ]; then
                        sshpass -p "${SF_PASS}" scp ${RECOVERY_IMG} ${SF_USER}@frs.sourceforge.net:/home/frs/project/${SF_PROJECT}/${CODENAME}
                    fi
                    if [ "${TG_CHAT}" != "" ]; then
			            curl -s --data parse_mode=HTML --data text="Upload ${ROM_ZIP} for ${CODENAME} succeed!" --data reply_markup="{\"inline_keyboard\": [[{\"text\":\"Download!\", \"url\": \"https://sourceforge.net/p/${SF_PROJECT}/files/${CODENAME}/\"}]]}" --data chat_id="${TG_CHAT}" --request POST https://api.telegram.org/bot"${TG_TOKEN}"/sendMessage
                        curl -s --data parse_mode=HTML --data sticker=CAADBQADGgEAAixuhBPbSa3YLUZ8DBYE --data chat_id="${TG_CHAT}" --request POST https://api.telegram.org/bot"${TG_TOKEN}"/sendSticker
                    else
                        echo "Upload ${ROM_ZIP} for ${CODENAME} succeed! https://sourceforge.net/projects/${SF_PROJECT}/files/${SF_PATH}/"
                    fi
                else 
                    sshpass -p "${SF_PASS}" scp ${ROM_ZIP} ${SF_USER}@frs.sourceforge.net:/home/frs/project/${SF_PROJECT}/${SF_PATH}
                    if [ "${UPLOAD_RECOVERY}" = "true" ]; then
                        sshpass -p "${SF_PASS}" scp ${RECOVERY_IMG} ${SF_USER}@frs.sourceforge.net:/home/frs/project/${SF_PROJECT}/${SF_PATH}
                    fi
                    if [ "${TG_CHAT}" != "" ]; then
			            curl -s --data parse_mode=HTML --data text="Upload ${ROM_ZIP} for ${CODENAME} succeed!" --data reply_markup="{\"inline_keyboard\": [[{\"text\":\"Download!\", \"url\": \"https://sourceforge.net/p/${SF_PROJECT}/files/${SF_PATH}/\"}]]}" --data chat_id="${TG_CHAT}" --request POST https://api.telegram.org/bot"${TG_TOKEN}"/sendMessage
                        curl -s --data parse_mode=HTML --data sticker=CAADBQADGgEAAixuhBPbSa3YLUZ8DBYE --data chat_id="${TG_CHAT}" --request POST https://api.telegram.org/bot"${TG_TOKEN}"/sendSticker
                    else
                        echo "Upload ${ROM_ZIP} for ${CODENAME} succeed! https://sourceforge.net/projects/${SF_PROJECT}/files/${SF_PATH}/"
                    fi
                fi
            fi

            #if google drive
            if [ "${UPLOAD_TYPE}" == "GD" ]; then
                GD_FOLDER="${MY_DIR}"/gd
                if ! [ -e "${GD_FOLDER}"/gdrive ]; then
                    echo "you didn't lisen to me, Please read README.md and run first_time.sh to set Gdrive"
                fi
                cp "${ROM_ZIP}" "${GD_FOLDER}"
                cp "${ROM_HASH}" "${GD_FOLDER}"
                if [ "${UPLOAD_RECOVERY}" = "true" ]; then
                    cp "${RECOVERY_IMG}" "${GDRIVE_FOLDER}"
                fi
                cd "${GD_FOLDER}"
                ./gdrive upload "${ROM_ZIP}" --parent ${GD_PATH} --share --delete
                ./gdrive upload "${ROM_HASH}" --parent ${GD_PATH} --share --delete
                if [ "${UPLOAD_RECOVERY}" = "true" ]; then
                    ./gdrive upload "${RECOVERY_IMG}" --parent ${GD_PATH} --share --delete
                fi
                if [ "${TG_CHAT}" != "" ]; then
                    curl -s --data parse_mode=HTML --data text="Upload ${ROM_ZIP} for ${CODENAME} succeed!" --data reply_markup="{\"inline_keyboard\": [[{\"text\":\"Download!\", \"url\": \"https://drive.google.com/drive/folders/${GD_PATH}\"}]]}" --data chat_id="${TG_CHAT}" --request POST https://api.telegram.org/bot"${TG_TOKEN}"/sendMessage
                    curl -s --data parse_mode=HTML --data sticker=CAADBQADGgEAAixuhBPbSa3YLUZ8DBYE --data chat_id="${TG_CHAT}" --request POST https://api.telegram.org/bot"${TG_TOKEN}"/sendSticker
                else
                    echo "Upload ${ROM_ZIP} for ${CODENAME} succeed! https://drive.google.com/drive/folders/${GD_PATH}"
                fi
            fi
            cd "${MY_DIR}"/rom/"${ROM_NAME}"-"${ANDROID_VERSION}"
        fi
    done
}

## Start
if ! [ -d "${MY_DIR}"/rom/"${ROM_NAME}"-"${ANDROID_VERSION}/bootable" ]; then
    sync
fi
if [ -d "${MY_DIR}"/rom/"${ROM_NAME}"-"${ANDROID_VERSION}/bootable" ]; then
    build
fi
cd "${MY_DIR}"
