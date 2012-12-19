#
# Cookbook Name:: jenkins
# Recipe:: jently
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
#

package "rubygems1.8" do
	action :install
end

template "tmp/gemShell.sh" do
	source "gemShell.sh.erb"
  	owner node[:jenkins][:server][:user]
  	group node[:jenkins][:server][:group]
    mode 0555
end

execute "tmp/gemShell.sh" do
	action :run
end

directory "/tmp/private_code" do
  action :create
  owner node[:jenkins][:server][:user]
  group node[:jenkins][:server][:user]
end

template "/tmp/private_code/wrapssh4git_data.sh" do
  source "wrapssh4git.sh.erb"
  owner node[:jenkins][:server][:user]
  mode 0700
  variables(
    'home_dir' => '/tmp/private_code',
    'ssh_key'  => "#{node[:jenkins][:server][:home]}/.ssh/id_rsa"
  )
end

#we want to be able to have multiple versions of this gem for the different environments.
node["jently_config"].each do |jently|

  template "/tmp/private_code/clone_update_#{jently}.sh"  do
    source "clone_update.sh.erb" 
    owner node[:jenkins][:server][:user]
    group node[:jenkins][:server][:group]
    mode 0555
    variables(
      :sshwrapper => '/tmp/private_code/wrapssh4git_data.sh',
      :directory => "#{node[:jenkins][:jently]}/#{jently}"
    )
  end

  execute "/tmp/private_code/clone_update_#{jently}.sh" do
    action :run
  end

  template "#{node[:jenkins][:jently]}/#{jently}/config/config.yaml" do
    source "jently_config.yaml.erb"
    owner node[:jenkins][:server][:user]
    group node[:jenkins][:server][:group]
    mode 0700
    Chef::Log.info("This is what the data_bag is #{jently}")
    jently_config = search(:jently, "id:#{jently}").first

    variables(
      :github_login => jently_config["github_login"],
      :github_password => jently_config["github_password"],
      :github_ssh_repository => jently_config["github_ssh_repository"],   
      :github_polling_interval_seconds => jently_config["github_polling_interval_seconds"],
      :jenkins_login => jently_config["jenkins_login"],
      :jenkins_password => jently_config["jenkins_password"],
      :jenkins_url => jently_config["jenkins_url"], 
      :jenkins_job_name => jently_config["jenkins_job_name"], 
      :jenkins_job_timeout_seconds => jently_config["jenkins_job_timeout_seconds"], 
      :jenkins_polling_interval_seconds => jently_config["jenkins_polling_interval_seconds"], 
      :testing_branch_name => jently_config["testing_branch_name"], 
      :tester_username => jently_config["tester_username"], 
      :tester_comment => jently_config["tester_comment"],
      :remote_name => jently_config["remote_name"]
    )
  end
    
  template "#{node[:jenkins][:jently]}/#{jently}/run_ruby_script.sh" do
    source "run_ruby_script.sh.erb"
    owner node[:jenkins][:server][:user]
    group node[:jenkins][:server][:group]
    mode 0555
    variables(
      :directory => "#{node[:jenkins][:jently]}/#{jently}"
    )
  end

  execute "#{node[:jenkins][:jently]}/#{jently}/run_ruby_script.sh" do
    action :run
  end
end