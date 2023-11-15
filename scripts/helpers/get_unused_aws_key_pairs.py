import sys
from pprint import pprint

import boto3

# Create a session with the specified profile or use the default profile
profile_name = sys.argv[1] if len(sys.argv) > 1 else None
session = boto3.Session(profile_name=profile_name)

# Use the session to create an EC2 client to get the default region
ec2_client = session.client("ec2")
default_region = ec2_client.meta.region_name

# Use the session to create an EC2 resource with the default region
ec2 = session.resource("ec2", region_name=default_region)

unused_keys = {}

# Iterate over all regions
for region in ec2.meta.client.describe_regions()["Regions"]:
    region_name = region["RegionName"]
    try:
        # Use the session to create an EC2 resource for the specific region
        ec2conn = session.resource("ec2", region_name=region_name)

        # Get all key pairs in the region
        key_pairs = ec2conn.key_pairs.all()

        # Get the names of key pairs used by instances in the region
        used_keys = {instance.key_name for instance in ec2conn.instances.all()}

        # Iterate over key pairs and delete unused ones
        for key_pair in key_pairs:
            if key_pair.name not in used_keys:
                unused_keys[key_pair.name] = region_name
    except Exception as e:
        print(f"No access to region {region_name}: {e}")

# Print the results
print(f"Found {len(unused_keys)} unused key pairs across all regions:")
pprint(unused_keys)
