import os
import boto3
import gitlab
import git
import shutil
import sys
from dotenv import load_dotenv
import subprocess
import yaml
import paramiko


# Load environment variables from the .env file
load_dotenv()
arg = sys.argv[1]

test_result = 0


stacks = {"master": {"key": "osparc-infra/docs/deployments-hardware-and-credentials/osparc.speag.com/osparc-speag.pem", "e2e-name": "Master", "sparc-external-name": "master", "registry": "registry.osparc-master.speag.com", "ops-deployment-configuration-git-branch": "osparc-master.speag.com"},
          "aws-staging": {"key": "osparc-infra/docs/deployments-hardware-and-credentials/staging.osparc.io/osparc-staging.pem", "e2e-name": "AWS-Staging", "sparc-external-name": "aws-staging", "registry": "registry.staging.osparc.io", "ops-deployment-configuration-git-branch": "staging.osparc.io"},
          "aws-production": {"key": "osparc-infra/docs/deployments-hardware-and-credentials/osparc.io/osparc-production.pem", "e2e-name": "AWS-Production", "sparc-external-name": "aws-production", "registry": "registry.osparc.io", "ops-deployment-configuration-git-branch": "osparc.io"},
          "tip": {"key": "osparc-infra/docs/deployments-hardware-and-credentials/tip.itis.swiss/osparc-public.pem", "e2e-name": "tip.itis.swiss", "sparc-external-name": "tip-public", "registry": "registry.tip.itis.swiss", "ops-deployment-configuration-git-branch": "tip.itis.swiss"},
          "dalco-staging": {"key": "osparc-infra/docs/deployments-hardware-and-credentials/osparc.speag.com/osparc-speag.pem", "e2e-name": "Dalco", "sparc-external-name": "dalco-staging-production", "registry": "registry.osparc-staging.speag.com", "ops-deployment-configuration-git-branch": "osparc-staging.speag.com"},
          "dalco-production": {"key": "osparc-infra/docs/deployments-hardware-and-credentials/osparc.speag.com/osparc-speag.pem", "e2e-name": "Dalco", "sparc-external-name": "dalco-staging-production", "registry": "registry.osparc.speag.com", "ops-deployment-configuration-git-branch": "osparc.speag.com"}, }

args = ["master", "aws-production", "aws-staging",
        "dalco-staging", "dalco-production", "tip"]


# This function parse yaml data from e2e-ops and return a list of hosts to ssh
# Expect e2e-ops repo to be pulled into .
def yaml_data_to_hosts(stack_arg):
    global stacks
    stack = stacks[stack_arg]
    with open("e2e-ops/data/machineCredentials.yml", 'r') as file:
        yaml_data = yaml.load(file, Loader=yaml.FullLoader)
        clusters = yaml_data["Clusters"]
        test_occurrence = next(
            (item for item in clusters if stack["e2e-name"] in item), None)
        hosts_yaml = test_occurrence[stack["e2e-name"]]
        hosts = []
        for host in hosts_yaml:
            for ho in host.values():
                hosts.append(ho)
    global test_result
    if len(hosts) == 0:
        print("Error : 0 host to ssh")
        test_result = -1
    return hosts


# This function parse yaml data from sparc-external file and return images that will need to be pulled, and their deployment
# Expect sparc-external repo to be pulled into .
def yaml_data_to_pulling_info(stack_arg):
    global stacks
    stack = stacks[stack_arg]
    pull_images = []
    with open("sparc-external/sync-workflow.yml", 'r') as file:
        yaml_data = yaml.load(file, Loader=yaml.FullLoader)
        images = yaml_data["stages"]
        for image in images:
            for to in image["to"]:
                if "pull_last_version" in to and to["pull_last_version"] and to["destination"] == stack["sparc-external-name"]:
                    tags = len(to["tags"])
                    tag = to["tags"][tags - 1]
                    pull_images.append(to["repository"] + ":" + tag)
    return pull_images


# Return stack docker registry credentials
def stack_docker_registry_credentials(stack_arg):
    global stack
    branch_name = stacks[stack_arg]["ops-deployment-configuration-git-branch"]
    subprocess.run(
        ['git', '-C', "osparc-ops-deployment-configuration", 'checkout', branch_name])
    load_dotenv('osparc-ops-deployment-configuration/repo.config')
    credentials = {"login" : os.environ.get('SERVICES_USER'), "pwd" : os.environ.get('SERVICES_PASSWORD'), "address" : os.environ.get('REGISTRY_DOMAIN')}
    return credentials


# Execute SSH command
# Error fatal means that any error will result in the script sending exit(-1)
# error message checks if the outputerr countains something in particular, and if yes exit(-1)
# If Error fatal is true and error_message are filled, the script exit with -1 if the error output does NOT countain what is in the variable error_message
def execute_ssh_command(client, command, error_fatal, error_message):
    stdin, stdout, stderr = client.exec_command(command)
    outputerr = stderr.read().decode()
    outputout = stdout.read().decode() # = "" when nothing is written
    print("Error output\n" + outputerr)
    print("Output\n" + outputout)
    # Error output means that something goes wrong with the command. The script will exist with -1
    global test_result
    if outputerr is not "":
        if error_fatal and error_message is not None and error_message not in outputerr:
            test_result = -1
        if not error_fatal and error_message is not None and error_message in outputerr:
            test_result = -1
        if error_fatal and error_message is None and outputerr is not None:
            test_result = -1



# Expect sparc-external repo to be pulled into .

def ssh(hosts, images_to_pull, stack_arg):
    registry_credentials = stack_docker_registry_credentials(stack_arg)
    for host in hosts:
        host_ip = host["IP"]
        port = 22
        if "SSHPort" in host:
            port = host["SSHPort"]

        username = host["Username"]
        global stacks
        stack = stacks[stack_arg]
        subprocess.run("chmod 600 " + stack["key"], shell=True)
        key_filename = stack["key"]
        command = 'nvidia-smi'
        not_found_str = 'not found'

        # Create an SSH client and load the private key
        ssh = paramiko.SSHClient()
        ssh.set_missing_host_key_policy(paramiko.AutoAddPolicy())
        private_key = paramiko.RSAKey.from_private_key_file(key_filename)
        global test_result
        
        try:
            # Connect to the remote host using SSH
            print("SSH to " + host_ip)
            ssh.connect(hostname=host_ip, port=port,
                        username=username, pkey=private_key)

            # Execute the 'nvidia-smi' command on the remote host
            stdin, stdout, stderr = ssh.exec_command(command, 0, None)

            # Read the output of the command
            output = stderr.read().decode()

            # Check if the string is not found in the output
            if not_found_str not in output:
                print("Nvidia-smi is present on this hosts. We pull the images")
                print("First, we login to the registry")
                command =  "docker login --username " + registry_credentials.get('login') + " --password " + registry_credentials.get('pwd') + " " + registry_credentials.get('address')
                execute_ssh_command(ssh, command, False, "failed with status: 401 Unauthorized")

                print("Next, we pull the images ")
                for image in images_to_pull:
                    print("docker pull " + stack["registry"] + "/" + image)
                    command = "docker pull " + stack["registry"] + "/" + image
                    execute_ssh_command(ssh, command, True, None)

                print("Last, we logout from the registry")
                command = "docker logout"
                execute_ssh_command(ssh, command, True, None)

            else:
                print("No GPU on the host.")
        

        except paramiko.AuthenticationException:
            test_result = -1
            print(
                "Authentication failed. Please verify your credentials and private key file path.")
            
        except paramiko.SSHException as ssh_exception:
            test_result = -1
            print(
                f"Unable to establish SSH connection. Error: {ssh_exception}")
        finally:
            # Close the SSH connection
            ssh.close()


# This function list aws autoscaled instance that needs to pull the image, either for aws-staging or aws-production, based on their label.
# It returns a list of the publics ips of theses instances
def list_aws_instances(stack_arg):
    if stack_arg == "aws-production":
        message = "autoscaling-osparc-production"
    if stack_arg == "aws-staging":
        message = "autoscaling-osparc-staging"

    ec2 = boto3.client('ec2', aws_access_key_id=os.getenv('AWS_ACCESS_KEY'),
                       aws_secret_access_key=os.getenv('AWS_SECRET_KEY'), region_name="us-east-1")
    response = ec2.describe_instances(
        Filters=[{'Name': 'tag:Name', 'Values': [message]}])
    # Extract the public IP addresses of each instance
    public_ips = []
    for reservation in response['Reservations']:
        for instance in reservation['Instances']:
            if "PublicIpAddress" in instance:
                public_ips.append(instance['PublicIpAddress'])

    return public_ips


def clone_repos():
    # Set up the GitLab API client
    gl = gitlab.Gitlab(os.getenv('GITLAB_URL'),
                       private_token=os.getenv('GITLAB_ACCESS_TOKEN'))

    # Authenticate to the GitLab API
    gl.auth()

    # Clone osparc-infra (413), e2e-ops (525), osparc-ops-deployment-configuration (764), and sparc-external (258)
    for id in [413, 525, 764, 258]:
        project_id = id
        project = gl.projects.get(project_id)
        repo_url = project.ssh_url_to_repo
        repo_path = os.path.join(os.path.dirname(__file__), project.path)
        git.Repo.clone_from(repo_url, repo_path)


def clean_repos():
    for repos in ["osparc-infra", "e2e-ops", "sparc-external", "osparc-ops-deployment-configuration"]:
        shutil.rmtree(os.path.join(os.path.dirname(
            __file__), repos), ignore_errors=True)


# Return a list of the hosts to ssh for this stack
def hosts_list(stack_arg):
    hosts = yaml_data_to_hosts(arg)
    if stack_arg == "aws-production" or stack_arg == "aws-staging":
        aws_hosts = list_aws_instances(stack_arg)
        for host in aws_hosts:
            hosts.append({'IP': host, 'Username': hosts[0]["Username"], 'IdentityFile': hosts[0]
                         ["IdentityFile"], 'SudoPassword': hosts[0]["SudoPassword"]})
    return hosts


# clone_repos()

if arg not in args:
    print("Invalid argument. Please specify " + args)
else:
    hosts = hosts_list(arg)
    images_to_pull = yaml_data_to_pulling_info(arg)
    if len(images_to_pull) > 0:
        ssh(hosts, images_to_pull, arg)
    else:
        print("No images to pull on stack " + arg)
    # clean_repos()
print(test_result)
exit(test_result)