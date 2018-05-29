#!/bin/bash

### Global Options
# don't allow use of unset variables
#set -o nounset
# set the exit status $? to the exit code of the last program to exit non-zero (or zero if all exited successfully)
set -o pipefail 

### GLOBAL VARIABLES
# Variables for this script (vagrant provision)
MY_HOSTNAME="$(hostname)"
readonly MY_HOSTNAME
MY_IP_BLOCK=$(grep "ip_block:" /vagrant/cluster_settings.yml | awk '{print $2}')
readonly MY_IP_BLOCK
MY_IP=$(ip route | grep "${MY_IP_BLOCK}" | awk '{print $NF}')
readonly MY_IP
ANS_USER=$(grep "ip_block:" /vagrant/cluster_settings.yml | awk '{print $2}')
export DEBIAN_FRONTEND=noninteractive

# filename of script only, no path, no suffix
declare SCRIPT_NAME
SCRIPT_NAME="$(basename ${0} .${0##*.})"
readonly SCRIPT_NAME
declare DIR_NAME
DIR_NAME=$(dirname "${0}")
readonly DIR_NAME

# STATUS AND ERROR CONFIGURATION
# yep or nope
declare -r -i YES=0
declare -r -i NO=1
# command status results
declare -r -i OK=0
declare -r -i FAIL=1
declare -r -a STATUS_STR=( " OK " "FAIL" )
# error severity
declare -r -i INFO=0
declare -r -i WARN=1
declare -r -i ABORT=2
declare -r -i FATAL=3
declare -r -a SEVERITY_STR=( "INFO" "WARN" "ABRT" "FTAL" )

### GLOBAL DEPENDENT VARS (declared after variables they depend on)
# debug mode yes=0, no=1?
declare -i DEBUG=${YES}
# global error level variable, start with no errors
declare -i err_level=${OK}
# does this script require sudo/root?
declare -r -i REQ_ROOT=${YES}
# LOGGING CONFIGURATION
#declare -r LOG_DIR="/var/log/${SCRIPT_NAME}"
declare -r LOG_DIR="/vagrant/log/${MY_HOSTNAME}/${SCRIPT_NAME}-$(date '+%Y-%m-%d-%H%M%S')"
# If BASH_VERSION >= 4.x and DEBUG, then xtrace logs will go here
declare -r DBUG_TRACE="${LOG_DIR}/${SCRIPT_NAME}.$$.debug.xtrace"
# standard (non-debug) output goes here if uncommented.  Otherwise to stdout
#declare -r STD_LOG="${LOG_DIR}/${SCRIPT_NAME}.$$.log"
declare -r STD_LOG=""
# non-debug error logs go here, if uncommented.  Otherwise to stderr
#declare -r ERR_LOG="${LOG_DIR}/${SCRIPT_NAME}.$$.err.log"
declare -r ERR_LOG=""

### GLOBAL CONFIGURABLE VARS (set via command line)
declare NODE_TYPE=""

### catch
#
# decides how to react to possible error casts.  raises global err_level if necessary
#
# arg1 = status, (integer): 0 (OK), 1 (FAIL): did the operation pass or fail
# arg2 = severity, (integer): 0 (INFO), 1 (WARN), 2 (ABORT), 3 (FATAL): so we can choose how to respond
# arg3 = operation, string, what were we trying to do?
#
# returns: (integer): 0 (OK), 1 (FAIL): forwarded straight through from arg1
#
# depends on:
#  global vars: OK, FAIL, INFO, WARN, ABORT, FATAL, err_level
#  functions: cleanup_exit
#
# Credit to [https://gist.github.com/akostadinov/] for the stack trace implementation
#
catch() {

	declare -r -i STATUS="${1}"; shift
	declare -r -i SEVERITY="${1}"; shift
	declare -r OPER="${1:-''}"; shift

	declare message="${OPER}"
	declare stack_trace=""

	message="[${STATUS_STR[${STATUS}]}] [${SEVERITY_STR[${SEVERITY}]}]: ${message}"

	if (( STATUS != OK )); then
		err_level=$(( err_level>SEVERITY?err_level:SEVERITY ))
		echo "${message}"
		case ${SEVERITY} in
			${INFO})
				# add any error handling as appropriate here...
				;;
			${WARN})
				# add any error handling as appropriate here...
				;;
			${ABORT})
				# add any error handling as appropriate here...
				;;
			${FATAL})
				stack_depth=${#FUNCNAME[@]}
				# don't include this function (catch)
				for (( i=1; i<stack_depth; i++ )); do
					declare this_func="${FUNCNAME[$i]}"
					[[ -z "${this_func}" ]] && this_func="MAIN"
					declare this_lineno="${BASH_LINENO[$(( i - 1 ))]}"
					declare this_source="${BASH_SOURCE[$i]}"
					[[ -z "${this_source}" ]] && this_source="NOT_A_FILE"
					stack_trace="${stack_trace}"$'\n'"   at: ${this_func}:${this_lineno} from ${this_source}"
				done
				echo "${stack_trace}"
				cleanup_exit
				;;
			*)
				catch ${FAIL} ${FATAL} "undefined severity level: ${SEVERITY}"
		esac

	fi

	return "${STATUS}"

}

cleanup_exit() {

	#remove temp files here
	#consider trapping error or interrupt events to do this also

	# if script ran without problems, we don't need to keep any log files
	if (( DEBUG == YES )) && (( err_level > INFO )); then
		rm -f "${STD_LOG}" "${ERR_LOG}" "${DBUG_TRACE}"
	fi

	exit ${err_level}

}

main() {

	setup || catch ${FAIL} ${FATAL} "Failed during setup"
	parse_opts "${@}" || catch ${FAIL} ${FATAL} "Failed to parse command line options"

	### MAIN FUNCTION OF SCRIPT

	provision_all
	catch ${?} ${FATAL} "provision_all on ${MY_HOSTNAME}"

	case ${NODE_TYPE} in
		"ansible")
			provision_ansible
			catch ${?} ${FATAL} "provision_ansible on ${MY_HOSTNAME}"
			;;
		"managers")
			provision_worker
			catch ${?} ${FATAL} "provision_worker on ${MY_HOSTNAME}"
			provision_manager
			catch $? ${FATAL} "provision_manager on ${MY_HOSTNAME}"
			;;
		"workers")
			provision_worker
			catch ${?} ${FATAL} "provision_worker on ${MY_HOSTNAME}"
			;;
		*)
			catch ${FAIL} ${FATAL} "undefined NODE_TYPE for provisioning: ${NODE_TYPE}"
	esac

	cleanup_exit

}

### parse command line options ###
parse_opts() {

  #argument count check
  local -i REQ_ARGS=1
  readonly REQ_ARGS
  if (( $# != REQ_ARGS )); then
		catch ${FAIL} ${WARN} "Script requires at least ${REQ_ARGS} arguments; $# given}" && return ${FAIL}
	fi

  NODE_TYPE="${1}"; shift
  readonly NODE_TYPE

	#validate opts, if necessary
  case $NODE_TYPE in
    ansible)
      # do stuff here
      ;;
    managers)
      # do stuff here
      ;;
    workers)
      # do stuff here
      ;;
    *)
      # default
      catch ${FAIL} ${WARN} "Invalid NODE_TYPE: ${NODE_TYPE}" && return ${FAIL}
      ;;
    esac

    return ${OK}
}

### print_usage
#
# echo script usage
#
print_usage() {

	echo ""
	echo "Provision a Vagrant VM for a cluster"
	echo ""
	echo "./${SCRIPT_NAME} <node-group>"
	echo ""
	
  return ${OK}

}

### provision_all
#
#	applied to master and nodes
#
provision_all() {

	#force locale
	echo 'LC_ALL="en_US.UTF-8"' >> /etc/default/locale

  #create ansible user (not necessary if we use standard 'vagrant')
  #sudo adduser myuser --gecos "First Last,RoomNumber,WorkPhone,HomePhone" --disabled-password
  #echo "myuser:password" | sudo chpasswd

	if [[ ! -d /home/vagrant/.ssh ]]; then
		echo "/home/vagrant/.ssh not found, creating."
		sudo -u vagrant mkdir -p /home/vagrant/.ssh
		chmod 700 /home/vagrant/.ssh
		sudo -u vagrant touch /home/vagrant/.ssh/authorized_keys
		chmod 600 /home/vagrant/.ssh/authorized_keys
	fi

	if [[ ! -x /usr/bin/python ]]; then
		echo "Python not found on this node, installing package python-minimal"
		apt-get update
    catch ${?} ${ABORT} "apt-get update on ${MY_HOSTNAME}" || return ${FAIL}
		apt-get install -y python-minimal
    catch ${?} ${ABORT} "apt-get install python-minimal on ${MY_HOSTNAME}" || return ${FAIL}
	fi

	# update my hosts file from pre-made config, so i can talk to all the other nodes
	if [[ -r /vagrant/conf/etc-hosts ]]; then
		cat /vagrant/conf/etc-hosts | tee -a /etc/hosts
    catch ${?} ${ABORT} "setup local hosts file on ${MY_HOSTNAME}" || return ${FAIL}
	fi

	return ${OK}
}

### provision_ansible
#
#	applied to master node, must be done before provisioning subsequent nodes
#
provision_ansible() {

  # create ssh key pair for ourself
	sudo -u vagrant ssh-keygen -b 2048 -t rsa -q -N "" -f /home/vagrant/.ssh/id_rsa
	catch ${?} ${WARN} "ansible master ssh-keygen" || return ${FAIL}

  # put public key where other nodes can copy it from
	cp -f /home/vagrant/.ssh/id_rsa.pub /vagrant/conf/generated/ansible_authkey
	catch ${?} ${WARN} "copy id_rsa.pub to /vagrant/conf/generated/ansible_authkey" || return ${FAIL}

  # create a clean known_hosts file, where all of our nodes will put their own public ssh key
	if [[ -e /vagrant/conf/generated/known_hosts ]]; then
		rm -f /vagrant/conf/generated/known_hosts
		sudo -u vagrant touch /vagrant/conf/generated/known_hosts
	fi
	ln -s /vagrant/conf/generated/known_hosts /home/vagrant/.ssh/known_hosts

	#set minimum working ansible, do the rest with ansible itself
	#pwgen used to generate random passwords as needed...
	apt-add-repository -y ppa:ansible/ansible
  catch ${?} ${WARN} "add ansible repository on ${MY_HOSTNAME}" || return ${FAIL}
	apt-get update
  catch ${?} ${WARN} "ap-get update ${MY_HOSTNAME}" || return ${FAIL}
	apt-get install -y ansible pwgen
  catch ${?} ${WARN} "apt-get install ansible pwgen on ${MY_HOSTNAME}" || return ${FAIL}

	#install ansible hosts file that was generated in Vagrantfile
	mv /etc/ansible/hosts /etc/ansible/hosts.original
	catch ${?} "${WARN}" "move default ansible hosts file out of the way" || return ${FAIL}
	ln -s /vagrant/conf/generated/ansible-hosts /etc/ansible/hosts
	catch ${?} "${WARN}" "symlink /etc/ansible/hosts to /vagrant/conf/ansible-hosts" || return ${FAIL}

	#install any 3rd party roles we've put into *-requirements.yml files in this directory
	for f in $(find /vagrant/ansible/roles/ -type f -name '*requirements.yml'); do
		ansible-galaxy install -r "${f}"
		catch ${?} "${WARN}" "ansible-galaxy install required roles in ${f}*"  || return ${FAIL}
	done

	return ${OK}
}

### provision_manager
#
#	setup node as a docker swarm manager
#
provision_manager() {

	echo "Perform tasks to setup docker swarm manager here"

	return ${OK}
}

### provision_worker
#
#	setup node as a docker swarm worker
#
provision_worker() {

	#partition and format our additional disk (assuming /dev/sdc for now)
	#note: this guid comes from: https://en.wikipedia.org/wiki/GUID_Partition_Table
	#echo -e "label: gpt\n\ntype=0FC63DAF-8483-4772-8E79-3D69D8477DE4" > /tmp/${MY_HOSTNAME}.sfdisk
	#sfdisk --quiet --force /dev/sdc < /tmp/${MY_HOSTNAME}.sfdisk
	#partprobe
	#mke2fs -q -F -j -t xfs /dev/sdc1
	#mkfs.xfs /dev/sdc1
	#diskuuid=$(blkid | grep "/dev/sdc1" | cut -d '"' -f 2)
	#mkdir -p /gluster/data
	#echo "UUID=${diskuuid} /gluster/data xfs defaults 0 2" >> /etc/fstab
	#mount -a

	cat /vagrant/conf/generated/ansible_authkey | sudo -u vagrant tee -a /home/vagrant/.ssh/authorized_keys
	catch ${?} ${WARN} "Add ansible master's public ssh key to this node's authorized_keys file" || return ${FAIL}

	#add this node's ssh public host key to our ansible master's known_hosts file
	ssh-keyscan -H -t rsa ${MY_IP} | sudo -u vagrant tee -a /vagrant/conf/generated/known_hosts
	catch ${?} ${WARN} "Add this node's public ssh key to ansible master's known_hosts file" || return ${FAIL}

	return ${OK}
}

setup() {

	#root execution check
	if (( REQ_ROOT == YES )) && (( EUID != 0 )); then
		catch ${FAIL} ${WARN} "This script requires sudo or root to run." && return ${FAIL}
	fi

	mkdir -p "${LOG_DIR}"
  catch ${?} ${ABORT} "Create logs dir ${LOG_DIR}" || return ${FAIL}

	# setup debug logging
	if (( DEBUG == YES )); then
		echo "${SCRIPT_NAME}: DEBUG MODE ACTIVE"

		#setup xtrace
		if [[ $(echo "${BASH_VERSION}" | cut -d '.' -f 1) -gt 3 ]]; then
			echo "  bash xtrace output to:   ${DBUG_TRACE}"
			touch ${DBUG_TRACE}
      catch ${?} ${WARN} "Open log file ${DBUG_TRACE} for writing" || return ${FAIL}
			export PS4='XTRACE: $(basename ${BASH_SOURCE[0]}):${BASH_LINENO[0]}: ${FUNCNAME[0]}() - [${SHLVL},${BASH_SUBSHELL},$?]'
			exec 5> "${DBUG_TRACE}"
			export BASH_XTRACEFD="5"
		else
			echo "  bash xtrace output to:   STDERR"
		fi
		set -o xtrace
	fi

	# setup normal logging
	if [[ "${STD_LOG}" != "" ]]; then
		touch ${STD_LOG}
    catch ${?} ${WARN} "Open log file ${STD_LOG} for writing" || return ${FAIL}
		exec 1> "${STD_LOG}"
	fi
	if [[ "${ERR_LOG}" != "" ]]; then
		touch ${ERR_LOG}
    catch ${?} ${WARN} "Open log file ${ERR_LOG} for writing" || return ${FAIL}
		exec 2> "${ERR_LOG}"
	fi

  valid_ip "${MY_IP}"
  catch ${?} ${WARN} "Validate IP address (${MY_IP})" || return ${FAIL}

}

# Test an IP address for validity:
# Usage:
#      valid_ip IP_ADDRESS
#      if [[ $? -eq 0 ]]; then echo good; else echo bad; fi
#   OR
#      if valid_ip IP_ADDRESS; then echo good; else echo bad; fi
#
# https://www.linuxjournal.com/content/validating-ip-address-bash-script
#
function valid_ip()
{
    local  ip=$1
    local  stat=1

    if [[ $ip =~ ^[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}$ ]]; then
        OIFS=$IFS
        IFS='.'
        ip=($ip)
        IFS=$OIFS
        [[ ${ip[0]} -le 255 && ${ip[1]} -le 255 \
            && ${ip[2]} -le 255 && ${ip[3]} -le 255 ]]
        stat=$?
    fi
    return $stat
}

main "${@}"
