#!/bin/bash
#
# Extract the database from the current host and copy it in a new host
#
#
# http://redsymbol.net/articles/unofficial-bash-strict-mode/
set -o errexit
set -o nounset
set -o pipefail
IFS=$'\n\t'
# shellcheck disable=1091
source .env


usage()
{
    echo "usage: s3-data-migration.bash [--rm ] [--create] [--copy]"
    echo "--rm : Delete the destination bucket"
    echo "--create : Create the destination bucket"
    echo "--cp : Copy data from the old bucket to the destination one"
}

rm=false
create=false
cp=false

for var in "$@"
do
    if [ "$var" = "--rm" ]; then
        rm=true
    elif [ "$var" = "--create" ]; then
        create=true
    elif [ "$var" = "--cp" ]; then
        cp=true
    else
        usage
        exit
    fi
done

if [ "$rm" = true ]; then
    IFS=', ' read -r -a dest_buckets <<< "${S3_DEST_BUCKETS}"
	for element in "${dest_buckets[@]}"
	do
        read -p -r "Are you sure ? You are going to delete ${S3_DEST_ENDPOINT} / ${element} (y/n)? " yn
        if [ "$yn" = "y" ]; then
            echo "Deleting bucket  ${S3_DEST_ENDPOINT} / ${element}"
            docker run \
            -v /etc/ssl/certs:/etc/ssl/certs:ro \
            --network host \
            --env MC_HOST_old="https://${S3_ORIGIN_ACCESS_KEY}:${S3_ORIGIN_SECRET_KEY}@${S3_ORIGIN_ENDPOINT}" \
            --env MC_HOST_new="https://${S3_DEST_ACCESS_KEY}:${S3_DEST_SECRET_KEY}@${S3_DEST_ENDPOINT}" \
            minio/mc rb --force new/"${element}"
        fi
	done
fi

if [ "$create" = true ]; then
    IFS=', ' read -r -a dest_buckets <<< "${S3_DEST_BUCKETS}"
	for element in "${dest_buckets[@]}"
	do
        echo "Creating  ${S3_DEST_ENDPOINT} / ${element} bucket"
        docker run \
            -v /etc/ssl/certs:/etc/ssl/certs:ro \
            --network host \
            --env MC_HOST_old="https://${S3_ORIGIN_ACCESS_KEY}:${S3_ORIGIN_SECRET_KEY}@${S3_ORIGIN_ENDPOINT}" \
            --env MC_HOST_new="https://${S3_DEST_ACCESS_KEY}:${S3_DEST_SECRET_KEY}@${S3_DEST_ENDPOINT}" \
            minio/mc mb new/"${element}"
    done
fi


if [ "$cp" = true ]; then
    IFS=', ' read -r -a old_buckets <<< "${S3_ORIGIN_BUCKETS}"
    IFS=', ' read -r -a new_buckets <<< "${S3_DEST_BUCKETS}"
    count=0
	for element in "${old_buckets[@]}"
	do
        echo "migrating data from ${S3_ORIGIN_ENDPOINT} / ${element} to ${S3_DEST_ENDPOINT} / ${new_buckets[$count]}"
        docker run \
            -v /etc/ssl/certs:/etc/ssl/certs:ro \
            --network host \
            --env MC_HOST_old="https://${S3_ORIGIN_ACCESS_KEY}:${S3_ORIGIN_SECRET_KEY}@${S3_ORIGIN_ENDPOINT}" \
            --env MC_HOST_new="https://${S3_DEST_ACCESS_KEY}:${S3_DEST_SECRET_KEY}@${S3_DEST_ENDPOINT}" \
            minio/mc cp --recursive  old/"${element}"/ new/"${new_buckets[$count]}" || true
        count=$((count+1))
    done
fi
