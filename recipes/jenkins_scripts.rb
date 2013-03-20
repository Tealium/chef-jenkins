#
# Cookbook Name:: jenkins
# Recipe:: jenkins_scripts
#
# Author:: Jennifer Frisk
#
# Copyright 2012.
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

directory "/tmp/private_code" do
 action :create
 owner node[:jenkins][:server][:user]
 group node[:jenkins][:server][:user]
end

template "/tmp/private_code/wrapssh4git.sh" do
  source "wrapssh4git.sh.erb"
  owner node[:jenkins][:server][:user]
  mode 0700
  variables(
    'home_dir' => '/tmp/private_code',
    'ssh_key'  => "#{node[:jenkins][:server][:home]}/.ssh/id_rsa"
  )
end

 template "/tmp/private_code/clone_update_scripts.sh"  do
    source "clone_update_scripts.sh.erb" 
    owner node[:jenkins][:server][:user]
    group node[:jenkins][:server][:group]
    mode 0555
    variables(
    :sshwrapper => '/tmp/private_code/wrapssh4git.sh',
    :directory => "/var/lib/server_scripts"
   )
  end

 execute "/tmp/private_code/clone_update_scripts.sh" do
    action :run
  end

git "/var/lib/server_scripts" do
      Chef::Log.info("Checking out repository: #{node["scripts_repo"]["repo"]}")
     repository node["scripts_repo"]["repo"]
  		user node[:jenkins][:server][:user]
  		group node[:jenkins][:server][:user]
      revision node["scripts_repo"]["revision"]
      ssh_wrapper "/tmp/private_code/wrapssh4git.sh"
      # This flag should be set to true if you want chef to 
      # sync the git repo to the latest version each time that it runs.
      action node["scripts_repo"]["git_sync"] ? :sync : :checkout
end


