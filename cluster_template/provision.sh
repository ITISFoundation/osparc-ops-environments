#!/bin/bash

### Global Options
# don't allow use of unset variables
#set -o nounset
# set the exit status $? to the exit code of the last program to exit non-zero (or zero if all exited successfully)
set -o pipefail 

# Variables for this script (vagrant provision)
MY_HOSTNAME="$(hostname)"
readonly MY_HOSTNAME
MY_IP=$(grep "^[[:space:]].*address" /etc/network/interfaces | awk '{print $2}')
readonly MY_IP
export DEBIAN_FRONTEND=noninteractive

### Global Vars
# does this script require sudo/root?
declare -r -i REQ_ROOT=0
# debug mode on(1) or off(0)?
declare -r -i DEBUG=0
# filename of script only, no path, no suffix
declare SCRIPTNAME
SCRIPTNAME="$(basename ${0} .${0##*.})"
readonly SCRIPTNAME
# If BASH_VERSION >= 4.x and DEBUG, then xtrace logs will go here
declare -r DBUG_TRACE="/vagrant/logs/${MY_HOSTNAME}.${SCRIPTNAME}.$$.debug.xtrace"
# standard (non-debug) logging goes here, if uncommented.  Otherwise to stdout
#declare -r STD_LOG="${SCRIPTNAME}.$$.log"
declare -r STD_LOG="/vagrant/logs/${MY_HOSTNAME}.${SCRIPTNAME}.$$.stdout.log"
# non-debug error logs go here, if uncommented.  Otherwise to stderr
declare -r ERR_LOG="/vagrant/logs/${MY_HOSTNAME}.${SCRIPTNAME}.$$.err.log"
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
# global error level variable, start with no errors
declare -i err_level=${OK}

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
#  global vars: OK, FAIL, INFO, WARN, FAIL, FATAL, err_level
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
	declare -i file_wordcount=0

	# if log files exist, but are empty, delete them
	if [[ "${STD_LOG}" != "" ]] && [[ -r "${STD_LOG}" ]]; then
		file_wordcount=$(wc -c < "${STD_LOG}")
		(( file_wordcount == 0 )) && rm "${STD_LOG}"
	fi
	if [[ "${ERR_LOG}" != "" ]] && [[ -r "${ERR_LOG}" ]]; then
		file_wordcount=$(wc -c < "${ERR_LOG}")
		(( file_wordcount == 0 )) && rm "${ERR_LOG}"
	fi
	if [[ "${DBUG_TRACE}" != "" ]] && [[ -r "${DBUG_TRACE}" ]]; then
		file_wordcount=$(wc -c < "${DBUG_TRACE}")
		(( file_wordcount == 0 )) && rm "${DBUG_TRACE}"
	fi

	exit ${err_level}
}

### print_usage
#
# echo script usage
#
print_usage() {

	echo "Usage:"
	echo "  This script does things:"
	echo "    ${SCRIPTNAME} argument1 [argument2 argument3 ...]"
	echo
}

### provision_all
#
#	applied to master and nodes
#
provision_all() {

	#force locale
	echo 'LC_ALL="en_US.UTF-8"' >> /etc/default/locale

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
		apt-get install -y python-minimal
	fi

	# update my hosts file from pre-made config, so i can talk to all the other nodes
	if [[ -r /vagrant/conf/hosts ]]; then
		cat /vagrant/conf/hosts | tee -a /etc/hosts
	fi

	return ${OK}
}

### provision_ansible
#
#	applied to master node, must be done before provisioning subsequent nodes
#
provision_ansible() {

	sudo -u vagrant ssh-keygen -b 2048 -t rsa -q -N "" -f /home/vagrant/.ssh/id_rsa
	catch $? ${WARN} "ansible master ssh-keygen" || return ${WARN}

	cp -f /home/vagrant/.ssh/id_rsa.pub /vagrant/conf/generated/ansible_authkey
	catch $? ${WARN} "copy id_rsa.pub to /vagrant/conf/generated/ansible_authkey" || return ${WARN}

	if [[ -e /vagrant/conf/generated/known_hosts ]]; then
		rm -f /vagrant/conf/generated/known_hosts
		sudo -u vagrant touch /vagrant/conf/generated/known_hosts
	fi
	ln -s /vagrant/conf/generated/known_hosts /home/vagrant/.ssh/known_hosts

	#set minimum working ansible, do the rest with ansible itself
	#pwgen used to generate access and secret keys for minio server...
	apt-add-repository -y ppa:ansible/ansible
	apt-get update
	apt-get install -y ansible pwgen

	#install generated ansible hosts file
	mv /etc/ansible/hosts /etc/ansible/hosts.original
	catch $? "${WARN}" "move default ansible hosts file out of the way"
	ln -s /vagrant/conf/generated/ansible_hosts /etc/ansible/hosts
	catch $? "${WARN}" "symlink /etc/ansible/hosts to /vagrant/conf/ansible_hosts"

	#install any roles we've put into -requirements.yaml files in this directory
	for f in $(find /vagrant/ansible/roles/ -type f -name '*requirements.yaml'); do
		ansible-galaxy install -r "${f}"
		catch $? "${WARN}" "ansible-galaxy install required roles in ${f}*"
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
	catch $? ${WARN} "Adding ansible master's public ssh key to this node's authorized_keys file" || return ${WARN}

	#add this node's ssh public host key to our ansible master's known_hosts file
	ssh-keyscan -H ${MY_IP} | sudo -u vagrant tee -a /vagrant/conf/generated/known_hosts
	catch $? ${WARN} "Adding this node's public ssh key to ansible master's known_hosts file" || return ${WARN}

	return ${OK}
}

main() {

	#root execution check
	if (( REQ_ROOT && ! EUID )); then
		echo "This script requires sudo or root to run."
		echo
		err_level=${FATAL} && exit 1
	fi

	if [[ ! -d /vagrant/logs ]]; then mkdir -p /vagrant/logs; fi

	# setup debug logging
	if (( DEBUG )); then
		echo "${SCRIPTNAME}: DEBUG MODE ACTIVE"

		#setup xtrace
		if [[ $(echo "${BASH_VERSION}" | cut -d '.' -f 1) -gt 3 ]]; then
			echo "  bash xtrace output to:   ${DBUG_TRACE}"
			export PS4='XTRACE: $(basename ${BASH_SOURCE[0]}):${BASH_LINENO[0]}: ${FUNCNAME[0]}() - [${SHLVL},${BASH_SUBSHELL},$?]'
			exec 5> "${DBUG_TRACE}"
			export BASH_XTRACEFD="5"
		else
			echo "  bash xtrace output to:   STDERR"
		fi
		set -o xtrace
	fi

	# setup normal logging
	[[ "${STD_LOG}" != "" ]] && exec 1> "${STD_LOG}"
	[[ "${ERR_LOG}" != "" ]] && exec 2> "${ERR_LOG}"

  #argument count check, require 1
	if (( $# != 1 )); then
		print_usage
		err_level=${FATAL} && cleanup_exit
	fi

	declare -r NODETYPE="${1}"; shift	

	### MAIN FUNCTION OF SCRIPT

	provision_all
	catch $? ${FATAL} "provision_all on ${MY_HOSTNAME}"

	case ${NODETYPE} in
		"ansible")
			provision_ansible
			catch $? ${FATAL} "provision_ansible on ${MY_HOSTNAME}"
			;;
		"docker-swarm-manager")
			provision_worker
			catch $? ${FATAL} "provision_worker on ${MY_HOSTNAME}"
			provision_manager
			catch $? ${FATAL} "provision_manager on ${MY_HOSTNAME}"
			;;
		"docker-swarm-worker")
			provision_worker
			catch $? ${FATAL} "provision_worker on ${MY_HOSTNAME}"
			;;
		*)
			catch ${FAIL} ${FATAL} "undefined node type for provisioning: ${NODETYPE}"
	esac

	cleanup_exit
}

main "${@}"


