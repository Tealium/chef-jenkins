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
  libxml2
  libxml2-dev
  libxml2-utils
  libxslt1-dev
  libxslt1.1
  zlib1g-dev
).each do |pak|
    package pak do 
       action :install 
    end
  end


# Add ppa to make version 1.7+ of Subversion available
execute "add-apt-repository" do
  command "add-apt-repository ppa:brightbox/ruby-ng-experimental"
end

# apt-get update to bring in the ppa contents
execute "apt-get update" do
  command "sudo apt-get update"
end

package "ruby2.2" 

package "ruby2.2-dev"

gem_package "nokogiri" do 
  options ("-- --use-system-libraries --with-xml2-include=/usr/include/libxml2/")
  action :install 
end

%w(
akamai_api
edgecast_api
ruby-hmac
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

#Need to set if it's not found or vagrant set to DONOTUSE

node[:jenkins][:mcdn_purge].each do |environment|
  template "/etc/tealium/mcdn_purge/#{environment.first}_cdn_configs.json"  do
  source "cdn_configs.json.erb"
  owner node[:jenkins][:server][:user]
  mode 0700
  variables(
     'purge_dir' => node[:jenkins][:mcdn_purge]["#{environment.first}"][:purge_dir],
     'enable_cdns_akamai' => node[:jenkins][:mcdn_purge]["#{environment.first}"][:cdns][:akamai],
     'enable_cdns_edgecast' => node[:jenkins][:mcdn_purge]["#{environment.first}"][:cdns][:edgecast],
     'enable_cdns_limelight' => node[:jenkins][:mcdn_purge]["#{environment.first}"][:cdns][:limelight],
     'akamai_user' => node[:jenkins][:akamai][:user],
     'akamai_pass' => node[:jenkins][:akamai][:pass],
     'akamai_arl' => node[:jenkins][:akamai][:arl],
     'akamai_domain' => node[:jenkins][:akamai][:domain],
     'edgecast_account_id' => node[:jenkins][:edgecast][:account_id],
     'edgecast_api_token' => node[:jenkins][:edgecast][:api_token],
     'edgecast_media_base_uri' => node[:jenkins][:edgecast][:media_base_uri],
     'limelight_emailTo' => node[:jenkins][:limelight][:emailTo],
     'limelight_emailType' => node[:jenkins][:limelight][:emailType],
     'limelight_token' => node[:jenkins][:limelight][:token],
     'limelight_user' => node[:jenkins][:limelight][:user]
  )
  end
end

