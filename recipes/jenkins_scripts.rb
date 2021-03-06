#
# Cookbook Name:: jenkins
# Recipe:: jenkins_scripts
#
# Author:: Tealium Devops
#
# Copyright 2016.
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

# for parsing out the versions from the pom files
package 'libxml-xpath-perl'
package 'debhelper'

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
    'ssh_key'  => "#{node[:jenkins][:server][:home]}/.ssh/new_id_rsa"
  )
end

directory "/var/lib/jenkins/manifest" do
  action :create
  mode 0777
  owner node[:jenkins][:server][:user]
  group node[:jenkins][:server][:user]
end

ruby_block "update_scripts_owner" do
   block do
      FileUtils.chown_R 'jenkins', 'jenkins', '/var/lib/jenkins/server_scripts'
   end
   action :nothing
end

if !File.symlink?("/var/lib/jenkins/server_scripts")
  git '/var/lib/jenkins/server_scripts' do

        Chef::Log.info("Checking out the Server Scripts Repo")
        repository node[:scripts_repo]["repo"]
        user node[:jenkins][:server][:user]
        group node[:jenkins][:server][:group]
        revision node[:scripts_repo]["revision"]
        ssh_wrapper "/tmp/private_code/wrapssh4git.sh"
        # This flag should be set to true if you want chef to
        # sync the git repo to the latest version each time that it runs.
        action node[:scripts_repo]["git_sync"] ? :sync : :checkout
        notifies :create, "ruby_block[update_scripts_owner]", :immediately
  end
end


