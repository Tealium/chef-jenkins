#
# Cookbook Name:: chef-jenkins
# Recipe:: utui_rsync_list
#
# Copyright 2017, Tealium Inc.
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

return if node["app_environment"]  =~ /^(production|pc\d+|production_jenkins_slave)$/

app_environment = node["app_environment"] || "development"
rsync_accounts = data_bag_item('rsync_utui_data', app_environment)

rsync_accounts_include = rsync_accounts['include'].join("\n")
rsync_accounts_exclude = rsync_accounts['exclude'].join("\n")

template '/etc/tealium/rsync_include_exclude_list.txt' do
  source 'rsync_include_exclude_list.txt.erb'
  mode '0775'
  owner node[:jenkins][:server][:user]
  group node[:jenkins][:server][:group]
  variables(
    :include_list => rsync_accounts_include,
    :exclude_list => rsync_accounts_exclude
  )
end