#
# Cookbook Name:: utui
# Recipe:: urest_config
#
# Copyright 2012, Tealium Inc.
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

directory "etc/tealium/urest" do
  action :create
  owner node[:jenkins][:server][:user]
  group node[:jenkins][:server][:user]
end

node["urest_config"].each do |config|
  template "/etc/tealium/urest/#{config.first}.json"  do
     source "config.json.erb"
     mode 0444
     Chef::Log.info("This is what the config is #{config.first}")

     variables(
      :urest_host      		    => node["urest_config"]["#{config.first}"]["urest_host"],
      :urest_port     		    => node["urest_config"]["#{config.first}"]["urest_port"],
      :urest_users_path       => node["urest_config"]["#{config.first}"]["urest_users_path"],
      :urest_legacy_path      => node["urest_config"]["#{config.first}"]["urest_legacy_path"],
      :utag_host              => node["urest_config"]["#{config.first}"]["utag_host"],
      :utag_path              => node["urest_config"]["#{config.first}"]["utag_path"],
      :cdn_host               => node["urest_config"]["#{config.first}"]["cdn_host"],
      :cdn_path               => node["urest_config"]["#{config.first}"]["cdn_path"],
      :recurly_subdomain      => node["urest_config"]["#{config.first}"]["recurly_subdomain"],
      :tealium_tools_package  => node["urest_config"]["#{config.first}"]["tealium_tools_package"],
      :community_host         => node["urest_config"]["#{config.first}"]['community_host']
     )
  end
end