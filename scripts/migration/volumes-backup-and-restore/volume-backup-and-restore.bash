#!/bin/bash
#
# Create and restore docker volumes
#

set -o errexit
set -o nounset
set -o pipefail
IFS=$'\n\t'

# shellcheck disable=1091
source .env

backup()
{
    IFS=', ' read -r -a volumes <<< "${SOURCE_VOLUMES_NAME}"
    IFS=', ' read -r -a folders <<< "${SOURCE_FOLDERS_NAME}"
	count=0
	for element in "${volumes[@]}"
	do
        echo "Making a backup of ${element}:${folders[$count]}"
        if [ -z "$SSH_KEY_FILE" ]
        then
            sshpass -p "$SSH_PWD" ssh "${SSH_USER}"@"${SSH_HOST}" docker run --rm  -v /backup/:/backup -v "${element}":"${folders[$count]}" ubuntu:focal bash -c "cd ${folders[$count]} && tar cvf /backup/${element}.tar *"
        else
            ssh -i "$SSH_KEY_FILE" "${SSH_USER}"@"${SSH_HOST}" "docker run --rm  -v /backup/:/backup -v ${element}:${folders[$count]} ubuntu:focal bash -c \"cd ${folders[$count]} && tar cvf /backup/${element}.tar *\""
        fi
        #docker run --rm  -v /backup/:/backup -v ${element}:${folders[$count]} ubuntu bash -c "cd ${folders[$count]} && tar cvf /backup/${element}.tar *"
        echo "Backup available : /backup/${element}.tar"
	    count=$((count+1))
	done
    exit 0
}

transfer()
{
    sudo apt install sshpass;
    for entry in /backup/*
    do
        echo "Sending $entry to ${SSH_HOST}"
        if [ -z "$SSH_KEY_FILE" ]
        then
            sshpass -p "$SSH_PWD" scp "$entry" "${SSH_USER}"@"${SSH_HOST}":/backup
        else
            scp -i "$SSH_KEY_FILE" "$entry" "${SSH_USER}"@"${SSH_HOST}":/backup
        fi
    done
    exit 0
}

restore()
{
    IFS=', ' read -r -a volumes <<< "${DEST_VOLUMES_NAME}"
    IFS=', ' read -r -a folders <<< "${DEST_FOLDERS_NAME}"
	count=0
	for element in "${volumes[@]}"
    do
        echo "Deleting volume ${element}"
        docker volume rm -f "${element}"
        echo "Creating a new empty volume"
        docker volume create "${element}"
        echo "Restoring the volume..."
        docker run --rm -v /backup/:/backup -v "${element}":"${folders[$count]}" ubuntu bash -c "cd ${folders[$count]} && tar xvf /backup/${element}.tar && cd .. && chmod -R 777 ${folders[$count]}"
        echo "Volume restored."
    done
    exit 0
}

backup_and_restore_ssh()
{
    read -p -r "CAUTION ! This script will remove the existing volume if it exists before restoring it. Are you sure ? (y/n)? " answer
    case ${answer:0:1} in
        y|Y )
            echo "Deleting volume ${DEST_VOLUME_NAME}"
            docker volume rm -f "${DEST_VOLUME_NAME}"
            echo "Creating a new empty volume"
            docker volume create "${DEST_VOLUME_NAME}"
            echo "Macking a backup of ${SOURCE_VOLUME_NAME} in the distant host $SSH_HOST"
            # shellcheck disable=SC2029
            ssh "$SSH_HOST" "docker run --rm -v ${SOURCE_VOLUME_NAME}:${SOURCE_FOLDER_NAME} alpine ash -c 'cd ${SOURCE_FOLDER_NAME} ; tar -cf - . '" \
            | \
            docker run --rm -i -v "${DEST_VOLUME_NAME}":"${DEST_FOLDER_NAME}" alpine ash -c "cd ${DEST_FOLDER_NAME} ; tar -xpvf - ; "
            echo "Volume restored."
        ;;
        * )
            echo "Prudence est mère de sureté "
        ;;
    esac
    exit 0

}

[ "$1" = "backup" ] && backup
[ "$1" = "restore" ] && restore
[ "$1" = "transfer" ] && transfer
[ "$1" = "backup_and_restore_ssh" ] && backup_and_restore_ssh
