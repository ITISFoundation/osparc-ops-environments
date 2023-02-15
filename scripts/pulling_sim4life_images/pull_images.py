import os
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


stacks = {"master" : {"key": "osparc-infra/docs/deployments-hardware-and-credentials/osparc.speag.com/osparc-speag.pem", "e2e-name" : "Master" }}

args = ["master", "aws-production", "aws-staging", "dalco-staging", "dalco-production", "tip"]


# This function parse yaml data from e2e-ops and return and list of hosts to ssh
def yaml_data_to_hosts(stack_arg):
    global stacks
    stack = stacks[stack_arg]
    with open("e2e-ops/data/machineCredentials.yml", 'r') as file:
        yaml_data = yaml.load(file, Loader=yaml.FullLoader)
        clusters = yaml_data["Clusters"]
        test_occurrence = next((item for item in clusters if stack["e2e-name"] in item), None)
        hosts_yaml = test_occurrence[stack["e2e-name"]]
        hosts = []
        for host in hosts_yaml:
            for ho in host.values():
                hosts.append(ho)

    return hosts


def ssh(hosts, arg):
    for host in hosts:
        host_ip = host["IP"]
        port = 22
        if "SSHPort" in host :
            port = host["SSHPort"]
        
        username = host["Username"]
        global stacks
        stack = stacks[arg]
        subprocess.run("chmod 600 " + stack["key"], shell=True)
        key_filename = stack["key"]
        command = 'nvidia-smi'
        not_found_str = 'not found'

        # Create an SSH client and load the private key
        ssh = paramiko.SSHClient()
        ssh.set_missing_host_key_policy(paramiko.AutoAddPolicy())
        private_key = paramiko.RSAKey.from_private_key_file(key_filename)
        print(host_ip)
        print(port)
        print(username)
        print(private_key)

        try:
            # Connect to the remote host using SSH
            ssh.connect(hostname=host_ip, port=port, username=username, pkey=private_key)

            # Execute the 'nvidia-smi' command on the remote host
            stdin, stdout, stderr = ssh.exec_command(command)

            # Read the output of the command
            output = stderr.read().decode()
            print(output)

            # Check if the string is not found in the output
            if not_found_str not in output:
                print(f"The string '{not_found_str}' was not found in the output of the command.")
            else:
                print(f"The string '{not_found_str}' was found in the output of the command.")

        except paramiko.AuthenticationException:
            print("Authentication failed. Please verify your credentials and private key file path.")
        except paramiko.SSHException as ssh_exception:
            print(f"Unable to establish SSH connection. Error: {ssh_exception}")
        finally:
            # Close the SSH connection
            ssh.close()



def clone_repos():
    # Set up the GitLab API client
    gl = gitlab.Gitlab(os.getenv('GITLAB_URL'), private_token=os.getenv('GITLAB_ACCESS_TOKEN'))

    # Authenticate to the GitLab API
    gl.auth()

    # Clone osparc-infra (413) and e2e-ops (525)
    for id in [413, 525]:
        project_id = id
        project = gl.projects.get(project_id)
        repo_url = project.ssh_url_to_repo
        repo_path = os.path.join(os.path.dirname(__file__), project.path)
        git.Repo.clone_from(repo_url, repo_path)

def clean_repos():
    for repos in ["osparc-infra", "e2e-ops"]:
        shutil.rmtree(os.path.join(os.path.dirname(__file__), repos), ignore_errors=True)

clean_repos()
clone_repos()

if arg not in args :
    print("Invalid argument. Please specify " + args)
else:
    hosts = yaml_data_to_hosts(arg)
    ssh(hosts, arg)