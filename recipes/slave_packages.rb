#
# Cookbook Name:: chef-jenkins
# Recipe:: slave_packages
#
# Copyright (c) 2016 Tealium, All Rights Reserved.

include_recipe "apt"

%w(
  xvfb
  mongodb-clients
  libxml2-utils
  libasound2
  libgtk-3-0
  libxrender1
  libxtst6
  libxp6
  libxi6
).each do |pak|
  package pak do 
   action :install
  end
end

package 'firefox-mozilla-build' do
  version '46.0.1-0ubuntu1'
end
package 'jq' do
  version '1.5+dfsg-1'
end
package 'libonig2' do
  version '5.9.6-1'
end
