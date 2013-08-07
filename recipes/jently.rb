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

%w(
jently
daemons
systemu
faraday
faraday_middleware
octokit
json
pry
multi_json
).each do |pak|
    gem_package pak do 
       action :install 
    end
end

package "rubygems1.8" do
	action :install
end

#No longer need this shell file.
#template "tmp/gemShell.sh" do#
#	source "gemShell.sh.erb"
#  	owner node[:jenkins][:server][:user]
#  	group node[:jenkins][:server][:group]
#    mode 0555
#end

directory "/tmp/private_code" do
  action :create
  owner node[:jenkins][:server][:user]
  group node[:jenkins][:server][:user]
end

# Now let's setup things so that we can pull down the repo.
directory "/tmp/private_code/.ssh" do
  owner node[:jenkins][:server][:user]
  recursive true
end

file "/tmp/private_code/.ssh/id_deploy" do
   Chef::Log.info("The private_key is: #{node[:jenkins][:server][:private_key]}")
   content node[:jenkins][:server][:private_key]
   owner node[:jenkins][:server][:user]
   mode 0600
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
      :jenkins_job_timeout_seconds => jently_config["jenkins_job_timeout_seconds"], 
      :jenkins_polling_interval_seconds => jently_config["jenkins_polling_interval_seconds"], 
      :testers => jently_config["testers"]
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