#
# Cookbook Name:: jenkins
# Recipe:: jenkins_scripts
#
# Author:: Jason Bain
#
# Copyright 2015.
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

%w(
akamai_api
edgecast_api
).each do |pak|
    gem_package pak do 
       action :install 
    end
end

directory "/etc/tealium/mcdn_purge" do
  owner node[:jenkins][:server][:user]
  group node[:jenkins][:server][:user]
  mode '0755'
  action :create
end

template "/etc/tealium/mcdn_purge/cdn_configs.json" do
  source "cdn_configs.json.erb"
  owner node[:jenkins][:server][:user]
  mode 0700
  variables(
     'purge_dir' => "#{node[:jenkins][:cdn_configs][:purge_dir]}",
     'cdns_akamai' => "#{node[:jenkins][:cdn_configs][:cdns][:akamai]}",
     'cdns_edgecast' => "#{node[:jenkins][:cdn_configs][:cdns][:edgecast]}",
     'cdns_limelight' => "#{node[:jenkins][:cdn_configs][:cdns][:limelight]}",
     'cdns_cdnetworks' => "#{node[:jenkins][:cdn_configs][:cdns][:cdnetworks]}",
     'akamai_user' => "#{node[:jenkins][:akamai][:user]}",
     'akamai_pass' => "#{node[:jenkins][:akamai][:pass]}",
     'akamai_arl' => "#{node[:jenkins][:akamai][:arl]}",
     'akamai_domain' => "#{node[:jenkins][:akamai][:domain]}",
     'edgecast_account_id' => "#{node[:jenkins][:edgecast][:account_id]}",
     'edgecast_api_token' => "#{node[:jenkins][:edgecast][:api_token]}",
     'edgecast_media_base_uri' => "#{node[:jenkins][:edgecast][:media_base_uri]}",
     'limelight_emailTo' => "#{node[:jenkins][:limelight][:emailTo]}",
     'limelight_emailType' => "#{node[:jenkins][:limelight][:emailType]}",
     'limelight_token' => "#{node[:jenkins][:limelight][:token]}",
     'limelight_user' => "#{node[:jenkins][:limelight][:user]}",
     'cdnetworks_user' => "#{node[:jenkins][:cdnetworks][:user]}",
     'cdnetworks_pass' => "#{node[:jenkins][:cdnetworks][:pass]}",
     'cdnetworks_mailTo' => "#{node[:jenkins][:cdnetworks][:mailTo]}"
  )
end


