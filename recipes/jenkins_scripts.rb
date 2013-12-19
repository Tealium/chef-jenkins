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

include_recipe "git"

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

directory "#{node[:jenkins][:server][:home]}/mainfest" do
  action :create
  owner node[:jenkins][:server][:user]
  group node[:jenkins][:server][:user]
end

ruby_block "update_scripts_owner" do
   block do
      FileUtils.chown_R 'jenkins', 'jenkins', '/var/lib/jenkins/server_scripts'
   end
   action :nothing
end

git '/var/lib/jenkins/server_scripts' do
      
      Chef::Log.info("Checking out the Server Scripts Repo")
      repository node[:jenkins][:scripts_repo]["repo"]
      user node[:jenkins][:server][:user]
      group node[:jenkins][:server][:group]
      revision node[:jenkins][:scripts_repo]["revision"]
      ssh_wrapper "/tmp/private_code/wrapssh4git.sh"
      # This flag should be set to true if you want chef to 
      # sync the git repo to the latest version each time that it runs.
      action node[:jenkins][:scripts_repo]["git_sync"] ? :sync : :checkout
      notifies :create, "ruby_block[update_scripts_owner]", :immediately
end


