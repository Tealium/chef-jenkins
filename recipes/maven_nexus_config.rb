#
# Cookbook Name:: chef-jenkins
# Recipe:: maven_nexus_config
#
# Copyright 2015, Tealium inc
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

mavNexConf = node[:jenkins]

template '/usr/local/maven/conf/settings.xml' do
  source 'local_maven_conf_settings.xml.erb'
  mode '0640'
  owner root
  group root
  variables(
      'serverId' => mavNexConf[:nexus_server_id],
      'userName' => mavNexConf[:nexus_user_id],
      'password' => mavNexConf[:nexus_password],
  )
end
