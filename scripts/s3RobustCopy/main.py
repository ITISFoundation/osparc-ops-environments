# pylint: disable=invalid-name,consider-using-in,consider-using-with,expression-not-assigned
import atexit
import os
import os.path
import sys
import time
import warnings
from pathlib import Path

####
# Copies all files from one S3 bucket to another, or downloads them locally
# Aimed at robustness, should handle network problems and corrupt files
#
#
# Details:
# 1.) List of all files from source and destination bucket is obtained. This takes a while. The files are written to file.
#     Only files not present in both buckets are copied.
# 2.)
# Imports
import boto3
import pandas as pd
import typer
from Crypto.Cipher import AES
from hurry.filesize import size
from retry import retry

# Ignore certificate warnings in output
warnings.filterwarnings(
    "ignore",
    ".*Adding certificate verification is strongly advised.*",
)
#


############
# Common functionality
def is_object_present_on_bucket(botobucket, filepath, all_object_bucket=None):
    if all_object_bucket is None:
        objs = list(botobucket.objects.filter(Prefix=filepath))
    else:
        objs = list(all_object_bucket.filter(Prefix=filepath))
    return bool(len(objs) == 1)


#
# Uses given eTag (=hash) to check if files are identical
# This might only work for files smaller than some Gb due to chunking
def is_object_in_bucket_identical(
    boto_resource_source,
    bucket_name_source,
    boto_resource_target,
    bucketname_target,
    filepath_bucket,
):
    sourceobj = boto_resource_source.Object(bucket_name_source, filepath_bucket)
    sourceobj.load()
    targetobj = boto_resource_target.Object(bucketname_target, filepath_bucket)
    targetobj.load()
    return sourceobj.e_tag != targetobj.e_tag


#
#
def generateCypherKeyFromPassword(password, salt):
    from Crypto.Protocol.KDF import scrypt

    starttime = time.monotonic()
    key = scrypt(password, salt, 32, N=2**16, r=8, p=1)
    stoptime = time.monotonic()
    print("Time for key derivation function:", stoptime - starttime)
    print(
        "-- Warning: Currently no salt is used to generate the key from the password."
    )
    return key


#
#
# Downloads or downloads & uploads (=copy) files
@retry(tries=5, delay=2)
def copyOrDownloadFile(
    downloadfolderlocal,
    key,
    listOfSkipped_,
    listOfSuccess_,
    listOfFailed_,
    listOfFailedWithExceptions_,
    sourcebucketname,
    src_s3,
    destinationbucketname="",
    allObjectsDestinationBucket=None,
    delim="_____",
    dest_s3=None,
    dest_bucket=None,
    no_overwrite=False,
    encrypt=False,
    decrypt=False,
    cypherKey=None,
):  # pylint: disable=too-many-arguments,too-many-branches,too-many-statements
    if dest_s3 is None:
        useDestination_ = False
    else:
        useDestination_ = True
    src_bucket = src_s3.Bucket(sourcebucketname)
    downloadFilename = (
        downloadfolderlocal
        + "/"
        + str(key)
        .replace("/", delim)
        .replace(" ", delim)
        .replace("(", "")
        .replace(")", "")
    )
    my_file = Path(downloadFilename)
    try:
        my_file.is_file()
    except OSError as exc:  # Warning this may break things!
        if exc.errno == 36:  # Filename too long
            downloadFilename = "quickfixFilenameTooLong.file"
            my_file = Path(downloadFilename)
            if not useDestination_:
                print("ERROR. Filename too long. THIS FILE WOULD BE OVERWRITTEN!")
                sys.exit(1)
        else:
            raise
    if not my_file.is_file():  # pylint: disable=too-many-nested-blocks
        try:
            # If we copy to remote bucket
            if downloadfolderlocal == "." and useDestination_:
                if allObjectsDestinationBucket is not None:
                    if is_object_present_on_bucket(
                        dest_bucket, key, allObjectsDestinationBucket
                    ):
                        if no_overwrite:
                            listOfSkipped.add(key)
                            return 0
                        targetObj = src_s3.Object(sourcebucketname, key)
                        targetObj.load()  # Assert object's metadata can be loaded
                        if is_object_in_bucket_identical(
                            dest_s3,
                            destinationbucketname,
                            src_s3,
                            sourcebucketname,
                            key,
                        ):
                            # print("Skipping ",str(key))
                            listOfSkipped.add(key)
                            return 0
            src_bucket.download_file(key, downloadFilename)
            if cypherKey is not None:
                assert not (encrypt and decrypt)
                if encrypt:
                    file_in = open(downloadFilename, "rb").read()
                    cipher = AES.new(cypherKey, AES.MODE_EAX)
                    ciphertext, tag = cipher.encrypt_and_digest(file_in)
                    #
                    file_out = open(downloadFilename, "wb")
                    [
                        file_out.write(x) for x in (cipher.nonce, tag, ciphertext)
                    ]  # pylint: disable=expression-not-assigned
                    file_out.close()
                elif decrypt:
                    file_in = open(downloadFilename, "rb")
                    nonce, tag, ciphertext = (file_in.read(x) for x in (16, 16, -1))
                    cipher = AES.new(cypherKey, AES.MODE_EAX, nonce)
                    binaryDataDecrypted = cipher.decrypt_and_verify(ciphertext, tag)
                    file_out = open(downloadFilename, "wb")
                    file_out.write(binaryDataDecrypted)
                    file_out.close()
            # print("Copying: ", str(key))
            #
            # If we copy to remote bucket
            if downloadfolderlocal == "." and useDestination_:
                # print("Uploading: ", str(key))
                dest_s3.meta.client.upload_file(
                    downloadFilename, destinationbucketname, key
                )
                # Delete local file
                os.system("rm " + downloadFilename)
            listOfSuccess_.add(key)
            return 0
        except Exception as e:  # pylint: disable=broad-exception-caught
            # print(e)
            listOfFailed_.add(key)
            listOfFailedWithExceptions_.append([key, e])
            print("Failed for ", str(key))
            return 1
    else:
        # print("Skipping ",str(key))
        listOfSkipped_.add(key)
        return 0


#######################################################


# Variable init
listOfSuccess = set()
listOfFailed = set()
listOfFailedWithExceptions = []
listOfSkipped = set()
listTotalInSourceBucket = set()
#######################################################


# Main
def main(
    sourcebucketname: str,
    sourcebucketaccess: str,
    sourcebucketsecret: str,
    sourceendpointurl: str,
    downloadfolderlocal: str = "",
    destinationbucketregion: str = "us-east-1",
    sourcebucketregion: str = "us-east-1",
    destinationbucketname: str = "",
    destinationbucketaccess: str = "",
    destinationbucketsecret: str = "",
    destinationendpointurl: str = "",
    files: str = "",
    filemetadatacsv: str = "",
    projectscsv: str = "",
    userscsv: str = "",
    nooverwrites: bool = typer.Option(False, "--nooverwrites"),
    encryption: bool = typer.Option(False, "--encryption"),
    decryption: bool = typer.Option(False, "--decryption"),
    password: str = "",
):  # pylint: disable=too-many-arguments,too-many-branches,too-many-statements
    if nooverwrites:
        print("CONFIG: WILL NOT OVERWRITE ANY FILES.")
    if (encryption or decryption) and password != "":
        cypherKey = generateCypherKeyFromPassword(password, "")
        if encryption:
            print("ENCRYPTING FILES DURING COPY")
        elif decryption:
            print("DECRYPTING FILES DURING COPY")
    else:
        cypherKey = None

    #
    #
    # Check if we download or copy.
    # If useDestination is True, we copy, else we download
    useDestination = True
    if (
        destinationbucketaccess == ""
        or destinationbucketsecret == ""
        or destinationendpointurl == ""
    ):
        useDestination = False
        print("The program will copy the source bucket to the LOCAL MACHINE.")
    else:
        print("The program will copy the source bucket to the DESTINATION BUCKET.")
        if destinationbucketname == "":
            print(
                "Assuming DESTINATION BUCKET NAME to be identical to SOURCE BUCKET NAME:",
                sourcebucketname,
            )
            destinationbucketname = sourcebucketname

    # Prepare file logging
    if files == "":

        def saveFiles():
            print("Program done. Writing results to file...")
            with open("filesCopied.txt", "w") as f:
                for item in list(listOfSuccess):
                    f.write("%s\n" % item)
            with open("filesFailed.txt", "w") as f:
                for item in list(listOfFailed):
                    f.write("%s\n" % item)
            with open("filesFailedWithException.txt", "w") as f:
                for item in list(listOfFailedWithExceptions):
                    f.write(str(item[0]) + ": " + str(item[1]) + "\n")
            with open("filesSkipped.txt", "w") as f:
                for item in list(listOfSkipped):
                    f.write("%s\n" % item)
            with open("filesOriginal.txt", "w") as f:
                for item in (
                    list(listOfFailed) + list(listOfSkipped) + list(listOfSuccess)
                ):
                    f.write("%s\n" % item)

        atexit.register(saveFiles)

    # Configure source bucket
    # via
    # https://docs.min.io/docs/how-to-use-aws-sdk-for-python-with-minio-server.html
    from botocore.client import Config

    src_s3 = boto3.resource(
        "s3",
        endpoint_url=sourceendpointurl,
        aws_access_key_id=sourcebucketaccess,
        aws_secret_access_key=sourcebucketsecret,
        config=Config(signature_version="s3v4"),
        region_name=sourcebucketregion,
        verify=False,
    )
    src_bucket = src_s3.Bucket(sourcebucketname)
    # Configure destination bucket
    if useDestination:
        dest_s3 = boto3.resource(
            "s3",
            endpoint_url=destinationendpointurl,
            aws_access_key_id=destinationbucketaccess,
            aws_secret_access_key=destinationbucketsecret,
            # config=Config(signature_version='s3v4'),
            region_name=destinationbucketregion,
            verify=False,
        )
        try:
            dest_s3.create_bucket(Bucket=destinationbucketname)
        except boto3.client("s3").exceptions.BucketAlreadyOwnedByYou:
            pass
        time.sleep(0.25)
        dest_bucket = dest_s3.Bucket(destinationbucketname)

    #

    print("Source Bucket: ", sourceendpointurl, "/", sourcebucketname)
    if downloadfolderlocal != "":  # Then we download without copying
        print("Destination Local: ", downloadfolderlocal)
        if os.path.isdir(downloadfolderlocal):
            if os.listdir(downloadfolderlocal):
                print("Target Backup Directory is not empty!")
                answer = input("Do you want to overwrite? [y/N]")
                if answer != "y" and answer != "Y":
                    sys.exit(0)
        else:
            print("ERROR: Given backup directory doesn't exist")
            sys.exit(1)
    #
    elif destinationendpointurl != "":
        print(
            "Destination Bucket: ", destinationendpointurl, "/", destinationbucketname
        )
    else:
        print("No local download folder or destination bucket specified. Aborting.")
        sys.exit(1)

    print("Starting...")
    startTime = time.time()
    if files == "":  # Consider all files in source bucket
        allObjectsSourceBucket = src_bucket.objects.all()
        if (
            downloadfolderlocal == "" or downloadfolderlocal == "."
        ) and useDestination:  # We copy to another bucket
            print("Comparing files in source and destination...")
            allObjectsDestinationBucket = dest_bucket.objects.all()
            print("Processing source bucket keys...")
            print("This might take a while...")
            sourceKeys = set({i.key for i in allObjectsSourceBucket})
            for i in sourceKeys:
                listTotalInSourceBucket.add(i)
            filenameFilesInSourceBucket = "filesInSourceBucket.txt"
            with open(filenameFilesInSourceBucket, "w") as f:
                for item in list(sourceKeys):
                    f.write("%s\n" % item)
            print("Processing destination bucket keys...")
            destinationKeys = set({i.key for i in allObjectsDestinationBucket})
            filenameFilesInDestinationBucket = "filesInDestinationBucket.txt"
            with open(filenameFilesInDestinationBucket, "w") as f:
                for item in list(destinationKeys):
                    f.write("%s\n" % item)
            filesOnlyInOneBucket = list(sourceKeys - destinationKeys)
            filenameFilesToBeCopied = "filesToBeCopied.txt"
            print("Writing files to be copied to file: ", filenameFilesToBeCopied)
            with open(filenameFilesToBeCopied, "w") as f:
                for item in filesOnlyInOneBucket:
                    f.write("%s\n" % item)
            print("Beginning S3 copy now.")
            #
            # Begin copy or DL
            #
            with typer.progressbar(filesOnlyInOneBucket) as progress:
                for key in progress:
                    copyOrDownloadFile(
                        ".",
                        key,
                        listOfSkipped,
                        listOfSuccess,
                        listOfFailed,
                        listOfFailedWithExceptions,
                        sourcebucketname,
                        src_s3,
                        destinationbucketname,
                        allObjectsDestinationBucket,
                        dest_s3=dest_s3,
                        dest_bucket=dest_bucket,
                        no_overwrite=nooverwrites,
                        cypherKey=cypherKey,
                        encrypt=encryption,
                        decrypt=decryption,
                    )
        else:  # We download to local folder
            print("Processing filenames...")
            sourceKeys = set({i.key for i in allObjectsSourceBucket})
            for i in sourceKeys:
                listTotalInSourceBucket.add(i)
            filenameFilesInSourceBucket = "filesInSourceBucket.txt"
            with open(filenameFilesInSourceBucket, "w") as f:
                for item in list(sourceKeys):
                    f.write("%s\n" % item)
            print("Beginning S3 download now.")
            with typer.progressbar(sourceKeys) as progress:
                for key in progress:
                    copyOrDownloadFile(
                        downloadfolderlocal,
                        key,
                        listOfSkipped,
                        listOfSuccess,
                        listOfFailed,
                        listOfFailedWithExceptions,
                        sourcebucketname,
                        src_s3,
                        destinationbucketname,
                        no_overwrite=nooverwrites,
                        cypherKey=cypherKey,
                        encrypt=encryption,
                        decrypt=decryption,
                    )
    else:  # We only consider certain files as specified in an inputfile, given by cmd option --files. Files already present in the destination are skipped without checks.
        with open(files, "r+") as inFiles:
            linesAreRead = inFiles.readlines()
            with typer.progressbar(linesAreRead) as progress:
                for oneFile in progress:
                    oneFile = oneFile.strip("\n")
                    if downloadfolderlocal == "":
                        downloadfolderlocal = "."
                    # Skip commented lines
                    if oneFile[0] == "#":
                        continue
                    if useDestination:
                        copyOrDownloadFile(
                            downloadfolderlocal,
                            oneFile,
                            listOfSkipped,
                            listOfSuccess,
                            listOfFailed,
                            listOfFailedWithExceptions,
                            sourcebucketname,
                            src_s3,
                            destinationbucketname,
                            dest_s3=dest_s3,
                            dest_bucket=dest_bucket,
                            no_overwrite=nooverwrites,
                            cypherKey=cypherKey,
                            encrypt=encryption,
                            decrypt=decryption,
                        )
                    else:
                        copyOrDownloadFile(
                            downloadfolderlocal,
                            oneFile,
                            listOfSkipped,
                            listOfSuccess,
                            listOfFailed,
                            listOfFailedWithExceptions,
                            sourcebucketname,
                            src_s3,
                            no_overwrite=nooverwrites,
                            cypherKey=cypherKey,
                            encrypt=encryption,
                            decrypt=decryption,
                        )
    #
    # If provided, read oSparc postgrs export csv files to resolve
    # user%project associated with a corrupt file
    if filemetadatacsv != "" and projectscsv != "":
        print("Trying to match corrupted files with their DB owner and projects.")
        filemetadata = pd.read_csv(filemetadatacsv)
        projectsTable = pd.read_csv(projectscsv)
        if userscsv != "":
            userstable = pd.read_csv(userscsv)
    elif filemetadatacsv != "" or projectscsv != "":
        print(
            "Missing one argument for matching corrupted files with their DB owner, either filemetadatacsv or projectscsv."
        )
    # After copy/DL: Print some info about the failed files
    print("####################")
    print("Failed files with exception:")
    for item in listOfFailedWithExceptions:
        print(str(item[0]) + ": " + str(item[1]))
        targetObj = src_s3.Object(sourcebucketname, str(item[0]))
        targetObj.load()
        print("Filesize: ", str(size(targetObj.content_length)))
        print("Last modified: ", str(targetObj.last_modified))
        # If we have the oSparc Postgres files, we can provide more details
        # about the files which we couldnt download
        if filemetadatacsv != "" and projectscsv != "":
            selection = filemetadata.loc[filemetadata["file_uuid"].isin([str(item[0])])]
            currentItem = selection.iloc[0]
            userID = currentItem.user_id
            userName = currentItem.user_name
            if str(userName) == "nan" and userscsv != "":
                selectionUser = userstable.loc[userstable["id"].isin([userID])]
                if len(selectionUser) == 1:
                    userName = str(selectionUser.iloc[0].email)
            print("User ID: ", str(userID), " User: ", str(userName))
            projectID = currentItem.project_id  # 1af7c5cc-d827-11eb-9a92-02420a004c15
            project_name = currentItem.project_name
            print("Project ID: ", str(projectID), " ProjectName: ", str(project_name))
            selectionProj = projectsTable.loc[projectsTable["uuid"].isin([projectID])]
            if str(project_name) == "nan" and len(selectionProj) == 0:
                print("PROJECT NOT FOUND in projects PG table.")
            elif str(project_name) == "nan":
                project_name = (
                    str(selectionProj["name"]).split("\n")[0].split("    ")[1]
                )

        print("--------")
    print("####################")
    print("Failed files")
    for i in listOfFailed:
        print(i)
    if files == "":
        print(
            "Failed ",
            str(len(listOfFailed)),
            "/",
            str(len(list(listTotalInSourceBucket))),
        )
    else:
        print("Failed ", str(len(listOfFailed)), "/", str(len(linesAreRead)))
    endTime = time.time()
    #
    print("#####")
    print("Execution time in seconds:")
    print(endTime - startTime)


if __name__ == "__main__":
    typer.run(main)
