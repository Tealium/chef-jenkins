#
# Cookbook Name:: jenkins
# Based on hudson
# Recipe:: deploy_ssh
#
# Author:: AJ Christensen <aj@junglist.gen.nz>
# Author:: Doug MacEachern <dougm@vmware.com>
# Author:: Fletcher Nichol <fnichol@nichol.ca>
#
# Copyright 2010, VMware, Inc.
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

  pkey = "#{node[:jenkins][:server][:home]}/.ssh/id_rsa"

   Chef::Log.info("Using repo #{node[:jenkins][:profile_name]} ")
   jenkins_keys = search(:jenkins_keys, "id:#{node[:jenkins][:profile_name]}").first
    
    Chef::Log.info("#{jenkins_keys}")
   
   node.default[:jenkins][:server][:public_key] = jenkins_keys["public_key"] 
   node.default[:jenkins][:server][:private_key] = jenkins_keys["private_key"]

  directory "#{node[:jenkins][:server][:home]}/.ssh" do
    mode 0700
    owner node[:jenkins][:server][:user]
    group node[:jenkins][:server][:group]
  end

   file "#{node[:jenkins][:server][:home]}/.ssh/id_rsa" do
      Chef::Log.info("The pem_key is: #{node[:jenkins][:server][:private_key]}")
      content node[:jenkins][:server][:private_key]
      owner node[:jenkins][:server][:user]
      mode 0600
   end

   file "#{node[:jenkins][:server][:home]}/.ssh/id_rsa.pub" do
      Chef::Log.info("The public_key is: #{node[:jenkins][:server][:public_key]}")
      content node[:jenkins][:server][:public_key]
      owner node[:jenkins][:server][:user]
      mode 0644
   end

   ruby_block "store jenkins ssh pubkey" do
     block do
       node.set[:jenkins][:server][:pubkey] = File.open("#{pkey}.pub") { |f| f.gets }
     end
   end

   file "#{node[:jenkins][:server][:home]}/.ssh/authorized_keys" do
     action :create
     mode 0600
     owner node[:jenkins][:server][:user]
     group node[:jenkins][:server][:user]
     content node[:jenkins][:server][:pubkey]
   end

   file "/etc/sudoers.d/#{node[:jenkins][:server][:user]}" do
    action :create
    mode 0440
    owner "root"
    group "root"
    content "#{node[:jenkins][:server][:user]} ALL=(ALL) NOPASSWD:ALL\n"
  end



  