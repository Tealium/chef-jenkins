#
# Cookbook Name:: utui
# Recipe:: tag_companion
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
include_recipe "perl"

directory "/etc/tealium/tagcompanion" do
   recursive true
end

node["tc.server"].each do |tags|
  template "/etc/tealium/tagcompanion/#{tags.first}.json"  do
     source "tag_companion_config.json.erb"
     mode 0444
     variables(
   	   :companion => node["tc.server"]["#{tags.first}"].nil? ? "{}" : node["tc.server"]["#{tags.first}"].to_hash.to_json
   )
  end
end



