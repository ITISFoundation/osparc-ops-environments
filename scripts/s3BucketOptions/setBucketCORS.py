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
):
    #
    corsConfigPermissive = [
        {
            "AllowedHeaders": ["*"],
            "AllowedMethods": ["GET", "PUT", "HEAD", "DELETE"],
            "AllowedOrigins": ["*"],
            "ExposeHeaders": ["GET", "PUT", "HEAD", "DELETE", "ETag"],
        }
    ]
    # Define the configuration rules
    cors_configuration = {"CORSRules": corsConfigPermissive}
    # GET the CORS configuration
    s3 = boto3.client(
        "s3",
        endpoint_url=destinationendpointurl,
        aws_access_key_id=destinationbucketaccess,
        aws_secret_access_key=destinationbucketsecret,
    )
    try:
        response = s3.get_bucket_cors(Bucket=destinationbucketname)
        print("CORS Settings before the change:")
        print(response["CORSRules"])
        print("########")
    except botocore.exceptions.ClientError as e:
        if e.response["Error"]["Code"] == "NoSuchCORSConfiguration":
            print("NoSuchCORSConfiguration")
        else:
            # AllAccessDisabled error == bucket not found
            print(e)
            return None
    s3.put_bucket_cors(
        Bucket=destinationbucketname, CORSConfiguration=cors_configuration
    )
    try:
        response = s3.get_bucket_cors(Bucket=destinationbucketname)
        print("CORS Settings after the change:")
        print(response["CORSRules"])
        #
        print("#####")
    except botocore.exceptions.ClientError as e:
        if e.response["Error"]["Code"] == "NoSuchCORSConfiguration":
            return []
        else:
            # AllAccessDisabled error == bucket not found
            print(e)
            return None


if __name__ == "__main__":
    typer.run(main)
