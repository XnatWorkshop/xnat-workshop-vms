#!/bin/bash

# wipe out .vagrant folder - it will be recreated
[[ -d .vagrant ]] && rm -R .vagrant

#echo
#echo Downloading XNAT and Pipeline war files...

getConfigValueFromFile() {
    echo $(grep ^$2 $1 | cut -f 2- -d : | sed -e 's/#.*$//' | sed -e 's/^[[:space:]]*//')
}

getConfigValue() {
    local VALUE=$(getConfigValueFromFile local.yaml $1)
    [[ -z $VALUE ]] && { VALUE=$(getConfigValueFromFile config.yaml $1); }
    echo $VALUE
}

XNAT_URL=$(getConfigValue xnat_url)
PIPELINE_URL=$(getConfigValue pipeline_url)

mkdir -p ../../local/downloads
DL_DIR=../../local/downloads

GET_FRESH=Y
doDownload() {
    echo Downloading: $1
    cd ${DL_DIR}
    curl -L --retry 5 --retry-delay 5 -O $1 || echo "Error downloading $1"
    cd -
}

XNAT_WAR=${DL_DIR}/${XNAT_URL##*/}
if [[ -e ${XNAT_WAR} ]]; then
    read -p "${XNAT_URL##*/} has already been downloaded. Would you like to download a new copy? [Y/n] " GET_FRESH_XNAT_WAR
else
    GET_FRESH_XNAT_WAR=Y
fi

PIPELINE_ZIP=${DL_DIR}/${PIPELINE_URL##*/}
if [[ -e ${PIPELINE_ZIP} ]]; then
    read -p "${PIPELINE_URL##*/} has already been downloaded. Would you like to download a new copy? [Y/n] " GET_FRESH_PIPELINE_ZIP
else
    GET_FRESH_PIPELINE_ZIP=Y
fi

if [[ ! ${GET_FRESH_XNAT_WAR} =~ [Nn] ]]; then
    [[ -e ${XNAT_WAR} ]] && { rm ${XNAT_WAR}; }
    echo
    echo Downloading from configured URL: ${XNAT_URL}
    doDownload ${XNAT_URL}
fi

if [[ ! ${GET_FRESH_PIPELINE_ZIP} =~ [Nn] ]]; then
    [[ -e ${PIPELINE_ZIP} ]] && { rm ${PIPELINE_ZIP}; }
    echo
    echo Downloading from configured URL: ${PIPELINE_URL}
    doDownload ${PIPELINE_URL}
fi



echo
echo Starting XNAT build...

echo
echo Provisioning VM with specified user...

echo
vagrant up

echo
echo Reloading VM to configure folder sharing...

echo
vagrant reload

echo
echo Running build provision to build and deploy XNAT on the VM...

echo
vagrant provision --provision-with build

echo
echo Provisioning completed.
