#
# Cookbook Name:: chef-jenkins
# Recipe:: utui_data_cron
#
# Copyright 2015, Tealium Inc.
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
require "json"

log_header = '[chef-jenkins::utui_data_cron] '

directory '/data/accounts' do
  recursive true
  mode '0755'
  owner node[:jenkins][:server][:user]
  group node[:jenkins][:server][:group]
  action :create
end

hour_counter = 1
# pull authoratative data in
cron "update_data_daily" do 
  minute "0"
  hour hour_counter
  user node[:jenkins][:server][:user]
  command "rsync -avz --exclude .git -e 'ssh -i #{node[:jenkins][:production_utui_rsync_user_key]}' #{node[:jenkins][:production_utui_rsync_user]}@#{node[:jenkins][:production_utui_eip]}:/data/utui/data/accounts/ /data/accounts"
  action node['disable_data_update'] ? :delete : :create
end



server_ip_list = []

if node.chef_environment =~ /production/
    envString = '*production*'
else
    envString = node.chef_environment
end

search_string = 'chef_environment:qa* AND role:jenkins_slave AND jenkins_cron_utui_account_rsync:true'
Chef::Log.warn("#{log_header}Search string to find jenkins slave hosts to rsync to is: [#{search_string}]")

if Chef::Config[:solo]
    Chef::Log.warn("#{log_header}This recipe uses search to find the Jenkins slave hosts to rsync account data to.  Chef solo does not support search so you will get the default attributes.  Set them in your node's profile settings if you are Vagranting your way to glory.")
    # jenkins_slaves_manually_specified should be an array of hashes of { 'ec2': { 'public_ipv4': '<IPADDR>' }, 'environment': '<ENV_NAME>' }
    jenkins_slave_hosts = node[:jenkins_slaves_manually_specified]
else
    jenkins_slave_hosts = search(:node, search_string)
    Chef::Log.warn("#{log_header}I got this result set back from search #{jenkins_slave_hosts}")
    if jenkins_slave_hosts.nil? || jenkins_slave_hosts.empty? then
        Chef::Log.error("#{log_header}Didn't find any hosts with search string #{search_string} won't create any rsync cron tasks to sync out data to jenkins slave hosts")
    else
        hour_incrementor = 1
        half_hour_or_nah = 0
        jenkins_slave_hosts.each_with_index do |server, index|

            Chef::Log.warn("#{log_header}Currently processing cron job for server: #{server['fqdn']} with environment: #{server.chef_environment}")
            # rsync out to each Jenkins slave in a VPC
            if ( index % 2 == 0 )
                half_hour_or_nah = 30
            else
                half_hour_or_nah = 0
                hour_counter += 1
            end
            cron "update_data_daily_#{server.chef_environment}" do
            minute half_hour_or_nah
            hour hour_counter
            user node[:jenkins][:server][:user]
            command "rsync -avz --exclude .git --exclude '/lost+found' -x -p -e 'ssh -i #{node[:jenkins][:nonprod_utui_rsync_user_key]}' /data/accounts/ #{node[:jenkins][:nonprod_utui_rysnc_user]}@#{server['ec2']['public_ipv4']}:/data/utui/data/accounts"
            action node['disable_data_update'] ? :delete : :create
            end
        end
    end
end
