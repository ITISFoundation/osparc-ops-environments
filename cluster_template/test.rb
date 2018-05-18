#!/usr/bin/ruby

require 'yaml'

CLUSTER_SETTINGS_FILE = "./cluster_settings.yml"
ANSIBLE_INV_FILE = "./conf/generated/ansible-hosts"
ETC_HOSTS_FILE = "./conf/generated/etc-hosts"

def generate_ansible_inventory(settings, ansible_inv_file)
  File.delete(ansible_inv_file) if File.exist?(ansible_inv_file)
  File.open(ansible_inv_file, 'w') do |f|
    ip = settings['cluster']['ip_start']

    f.write "[ansible]\n"
    f.write "#{settings['ansible']['hostname']} "
    f.write "ansible_host=127.0.0.1 "
    f.write "ansible_connection=local\n\n"

    settings['cluster']['groups'].each do |key, value|
      f.write "[#{key}]\n"
      (1..value['qty']).each do |i|
        ip += 1
        suffix = sprintf "#{value['hostname_suffix']}", i
        f.write "#{value['hostname_prefix']}#{suffix} "
        f.write "ansible_host=#{settings['cluster']['ip_block']}.#{ip} "
        f.write "ansible_port=#{settings['ansible']['port']} "
        f.write "ansible_user=#{settings['ansible']['port']}\n"
      end
      f.write "\n"
    end
  end
end

def generate_etc_hosts(settings, etc_hosts_file)
  File.delete(etc_hosts_file) if File.exist?(etc_hosts_file)
  File.open(etc_hosts_file, 'w') do |f|
    ip = settings['cluster']['ip_start']
    f.write "ansible #{settings['cluster']['ip_block']}.#{ip}\n"
    settings['cluster']['groups'].each do |key, value|
      (1..value['qty']).each do |i|
        ip += 1
        suffix = sprintf "#{value['hostname_suffix']}", i
        f.write "#{value['hostname_prefix']}#{suffix} "
        f.write "#{settings['cluster']['ip_block']}.#{ip}\n"
      end
    end
  end
end

settings = YAML.load_file(CLUSTER_SETTINGS_FILE)
generate_ansible_inventory(settings, ANSIBLE_INV_FILE)
generate_etc_hosts(settings, ETC_HOSTS_FILE)

host_ips = Hash[*File.read(ETC_HOSTS_FILE).split(/[ \n]+/)]

print "#{host_ips[settings['ansible']['hostname']]}\n\n"
