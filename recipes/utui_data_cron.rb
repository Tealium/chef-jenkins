#
# Cookbook Name:: utui
# Recipe:: utui_data_craon
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
require "json"

cron "update_data_daily" do 
	minute "0"
	hour "1"
	user "jenkins"
  command "rsync -avz --exclude .git -e 'ssh -i /var/run/tealium/chef/chef-deployment' ubuntu@184.169.215.36:/data/utui/data/ /data"
  action node['disable_data_update'] ? :delete : :create
end

#Not going to use this for now
#template "/data/exclude.txt" do
#	source "exclude.txt.erb"
#	mode 755
#	jenkins_data = search(:jenkins_data, "id:utui_data").first
#  variables(
#    :exclude => jenkins_data["exclude"].nil? ? "{}" : jenkins_data["exclude"]
#	)
#end
