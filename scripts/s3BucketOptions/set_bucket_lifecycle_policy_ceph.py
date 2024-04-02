import warnings

import boto3
import botocore
import typer

warnings.filterwarnings(
    "ignore",
    ".*Adding certificate verification is strongly advised.*",
)


#
def main(
    destinationbucketname: str,
    destinationbucketaccess: str,
    destinationbucketsecret: str,
    destinationendpointurl: str,
    noncurrentversionexpirationdays: int,
    noncurrentversiontransitiondays: int,
):
    #
    bucket_lifecycle_config = [
        {
            "ID": "DeleteOldVersionsAfter"
            + str(noncurrentversionexpirationdays)
            + "Days",
            "Status": "Enabled",
            "Prefix": "",
            "NoncurrentVersionExpiration": {
                "NoncurrentDays": noncurrentversionexpirationdays,
            },
        },
        {
            "ID": "TransitionOldVersionsAfter"
            + str(noncurrentversiontransitiondays)
            + "Days",
            "Status": "Enabled",
            "Prefix": "",
            "NoncurrentVersionTransition": {
                "NoncurrentDays": noncurrentversiontransitiondays,
                "StorageClass": "HDD_REPLICATED",
            },
        },
    ]

    s3 = boto3.client(
        "s3",
        region_name="us-east-1",
        endpoint_url=destinationendpointurl,
        aws_access_key_id=destinationbucketaccess,
        aws_secret_access_key=destinationbucketsecret,
        verify=False,
    )
    try:
        response = s3.get_bucket_lifecycle(Bucket=destinationbucketname)
        print("Lifecycle Settings before the change:")
        print(response["Rules"])
        print("########")
    except botocore.exceptions.ClientError as e:
        if e.response["Error"]["Code"] == "NoSuchLifecycleConfiguration":
            print("Lifecycle Settings before the change:")
            print("NoSuchLifecycleConfiguration")
        else:
            # AllAccessDisabled error == bucket not found
            print(e)
            return None
    s3.put_bucket_lifecycle(
        Bucket=destinationbucketname,
        LifecycleConfiguration={"Rules": bucket_lifecycle_config},
    )
    try:
        response = response = s3.get_bucket_lifecycle(Bucket=destinationbucketname)
        print("Lifecycle Settings after the change:")
        print(response["Rules"])
        #
        print("#####")
        return None
    except botocore.exceptions.ClientError as e:
        if e.response["Error"]["Code"] == "NoSuchLifecycleConfiguration":
            return []

        print(e)
        return None


if __name__ == "__main__":
    typer.run(main)
