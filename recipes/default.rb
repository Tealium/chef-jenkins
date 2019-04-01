# frozen_string_literal: true

#
# Cookbook Name:: jenkins
# Based on hudson
# Recipe:: default
#
# Author:: AJ Christensen <aj@junglist.gen.nz>
# Author:: Doug MacEachern <dougm@vmware.com>
# Author:: Fletcher Nichol <fnichol@nichol.ca>
#
# Copyright 2010, VMware, Inc.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

tmp = '/tmp'

group node[:jenkins][:server][:group] do
  not_if 'getent passwd jenkins'
end

user node[:jenkins][:server][:user] do
  home node[:jenkins][:server][:home]
  not_if 'getent passwd jenkins'
end

directory node[:jenkins][:server][:home] do
  recursive true
  owner node[:jenkins][:server][:user]
  group node[:jenkins][:server][:group]
  not_if "test -L #{node[:jenkins][:server][:home]}"
end

# Install plugins
directory "#{node[:jenkins][:server][:home]}/plugins" do
  owner node[:jenkins][:server][:user]
  group node[:jenkins][:server][:group]
  only_if { !node[:jenkins][:server][:plugins].empty? }
end

node[:jenkins][:server][:plugins].each do |name|
  remote_file "#{node[:jenkins][:server][:home]}/plugins/#{name}.hpi" do
    source "#{node[:jenkins][:mirror]}/plugins/#{name}/latest/#{name}.hpi"
    backup false
    owner node[:jenkins][:server][:user]
    group node[:jenkins][:server][:group]
    action :create_if_missing
  end
end

case node.platform
when 'ubuntu', 'debian'
  # See http://jenkins-ci.org/debian/

  case node.platform
  when 'debian'
    remote = "#{node[:jenkins][:mirror]}/latest/debian/jenkins.deb"
    package_provider = Chef::Provider::Package::Dpkg

    package 'daemon'
    # These are both dependencies of the jenkins deb package
    package 'jamvm'
    package 'openjdk-7-jre'

    package 'psmisc'
    key_url = 'http://pkg.jenkins-ci.org/debian/jenkins-ci.org.key'

    remote_file "#{tmp}/jenkins-ci.org.key" do
      source key_url.to_s
    end

    execute 'add-jenkins-key' do
      command "apt-key add #{tmp}/jenkins-ci.org.key"
      action :nothing
    end

  when 'ubuntu'
    key_url = 'http://pkg.jenkins-ci.org/debian/jenkins-ci.org.key'

    include_recipe 'apt'
    include_recipe 'java'

    cookbook_file '/etc/apt/sources.list.d/jenkins.list' do
      owner 'root'
      group 'root'
      mode  '0644'
    end

    execute 'add-jenkins-key' do
      command "wget -q -O - #{key_url} | sudo apt-key add -"
      action :nothing
      notifies :run, 'execute[apt-get update]', :immediately
    end
  end

  pid_file = '/var/run/jenkins/jenkins.pid'
  install_starts_service = true

when 'centos', 'redhat'
  include_recipe 'yum'

  pid_file = '/var/run/jenkins.pid'
  install_starts_service = false

  yum_key 'jenkins' do
    url "#{node.jenkins.package_url}/redhat/jenkins-ci.org.key"
    action :add
  end

  yum_repository 'jenkins' do
    description 'repository for jenkins'
    url "#{node.jenkins.package_url}/redhat/"
    key 'jenkins'
    action :add
  end
end

# "jenkins stop" may (likely) exit before the process is actually dead
# so we sleep until nothing is listening on jenkins.server.port (according to netstat)
ruby_block 'netstat' do
  block do
    10.times do
      if IO.popen('netstat -lnt').entries.select do |entry|
          entry.split[3] =~ /:#{node[:jenkins][:server][:port]}$/
         end.size == 0
        break
      end

      Chef::Log.debug("service[jenkins] still listening (port #{node[:jenkins][:server][:port]})")
      sleep 1
    end
  end
  action :nothing
end

service 'jenkins' do
  supports %i[stop start restart status]
  status_command "test -f #{pid_file} && kill -0 `cat #{pid_file}`"
  action :nothing
end

ruby_block 'block_until_operational' do
  block do
    until IO.popen('netstat -lnt').entries.select do |entry|
        entry.split[3] =~ /:#{node[:jenkins][:server][:port]}$/
          end.size == 1
      Chef::Log.debug "service[jenkins] not listening on port #{node.jenkins.server.port}"
      sleep 1
    end

    loop do
      url = URI.parse("#{node.jenkins.server.url}/job/test/config.xml")
      res = Chef::REST::RESTRequest.new(:GET, url, nil).call
      break if res.is_a?(Net::HTTPSuccess) || res.is_a?(Net::HTTPNotFound)

      Chef::Log.debug "service[jenkins] not responding OK to GET / #{res.inspect}"
      sleep 1
    end
  end
  action :nothing
end

if node.platform == 'ubuntu'
  execute 'setup-jenkins' do
    command 'echo w00t'
    notifies :stop, 'service[jenkins]', :immediately
    notifies :create, 'ruby_block[netstat]', :immediately # wait a moment for the port to be released
    notifies :run, 'execute[add-jenkins-key]', :immediately
    notifies :install, 'package[jenkins]', :immediately
    notifies :start, "service[jenkins]", :immediately unless install_starts_service
    notifies :create, 'ruby_block[block_until_operational]', :immediately
    creates '/usr/share/jenkins/jenkins.war'
  end
else
  local = File.join(tmp, File.basename(remote))

  remote_file local do
    source remote
    backup false
    notifies :stop, 'service[jenkins]', :immediately
    notifies :create, 'ruby_block[netstat]', :immediately # wait a moment for the port to be released
    notifies :run, 'execute[add-jenkins-key]', :immediately
    notifies :install, 'package[jenkins]', :immediately
    notifies :start, "service[jenkins]", :immediately unless install_starts_service
    if node[:jenkins][:server][:use_head] # XXX remove when CHEF-1848 is merged
      action :nothing
    end
  end

  http_request "HEAD #{remote}" do
    only_if { node[:jenkins][:server][:use_head] } # XXX remove when CHEF-1848 is merged
    message ''
    url remote
    action :head
    if File.exist?(local)
      headers 'If-Modified-Since' => File.mtime(local).httpdate
    end
    notifies :create, "remote_file[#{local}]", :immediately
  end
end

# this is defined after http_request/remote_file because the package
# providers will throw an exception if `source' doesn't exist
package 'jenkins' do
  provider package_provider
  source local if node.platform != 'ubuntu'
  action :nothing
end

# restart if this run only added new plugins
log 'plugins updated, restarting jenkins' do
  # ugh :restart does not work, need to sleep after stop.
  notifies :stop, 'service[jenkins]', :immediately
  notifies :create, 'ruby_block[netstat]', :immediately
  notifies :start, 'service[jenkins]', :immediately
  notifies :create, 'ruby_block[block_until_operational]', :immediately
  only_if do
    if File.exist?(pid_file)
      htime = File.mtime(pid_file)
      Dir["#{node[:jenkins][:server][:home]}/plugins/*.hpi"].select do |file|
        File.mtime(file) > htime
      end.size > 0
    end
  end

  action :nothing
end

# Front Jenkins with an HTTP server
case node[:jenkins][:http_proxy][:variant]
when 'nginx'
  include_recipe 'jenkins::proxy_nginx'
when 'apache2'
  include_recipe 'jenkins::proxy_apache2'
end

if node.jenkins.iptables_allow == 'enable'
  include_recipe 'iptables'
  iptables_rule 'port_jenkins' do
    if node[:jenkins][:iptables_allow] == 'enable'
      enable true
    else
      enable false
    end
  end
end
