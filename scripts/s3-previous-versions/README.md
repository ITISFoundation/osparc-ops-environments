# Goal

This script use [the s3-pit-restore script](https://github.com/angeloc/s3-pit-restore) with a little wrapper to ensure that it can be used with minio.

# Usage
* Create an .env file from the template.env file and fill it
* Launch the script with
```console
./launch.bash command
```
where command is the command you would use with s3-pit-restore.

E.g : if you want to restore the bucket simcore-origin to his  06-17-2021 23:59:50 +2 version in the bucket simcore-new-bucket :
```console
./launch.bash --bucket simcore-origin --dest-bucket simcore-new-bucket 06-17-2021 23:59:50 +2 "06-17-2021 23:59:50 +2"
