#
# Cookbook Name:: utui
# Recipe:: llwn_packages
#
# Author:: Gautam Dey <gautam@tealium.com>
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

include_recipe "apt"
include_recipe "perl"

# Install packages that are needed.

%w(
  libmoose-perl
  libyaml-perl
  libjson-perl
  libcgi-session-perl
  libmime-lite-perl
  libnet-amazon-s3-perl
  libarchive-zip-perl
  libdatetime-perl
  libdatetime-format-iso8601-perl
  libsoap-lite-perl
  liblog-log4perl-perl
  libjavascript-minifier-perl
  libjavascript-minifier-xs-perl
  libmoosex-attributehelpers-perl
  libmoosex-log-log4perl-perl
  libmongodb-perl
  libtemplate-perl
  iamcli
  libipc-run3-perl
  make
  libconfig-json-perl
  libdigest-perl
  libright-aws-ruby 
  libfile-slurp-perl
  build-essential
).each do |pak|
    package pak do 
       action :install 
    end
end

%w(
   Net::LimeLight::Purge
).each do |package| 
   cpan_module package
end

directory "/etc/tealium" do 
   recursive true
end

directory "/usr/sbin/tealium" do 
   recursive true
end

directory "/var/run/tealium" do 
   recursive true
   mode 0777
end

#do not need this right now.  We are using hte one that is in the GitHub repo.
#cookbook_file "/usr/sbin/tealium/update-llnw.pl" do
#    source "update-llnw.pl"
#    mode 0555
#end

node["update_llnw"].each do |environment|
  template "/etc/tealium/#{environment.first}.json"  do
     source "update-llnw.json.erb"
     mode 0444
     Chef::Log.info("This is what the environment is #{environment.first}")

     variables(
      :source_dir              => node["update_llnw"]["#{environment.first}"]["source_dirs"],
      :llnw_ftp_username       => node["update_llnw"]["#{environment.first}"]["llnw"]["ftp"]["username"],
      :llnw_ftp_password       => node["update_llnw"]["#{environment.first}"]["llnw"]["ftp"]["password"],
      :llnw_ftp_url            => node["update_llnw"]["#{environment.first}"]["llnw"]["ftp"]["url"],
      :llnw_shortname          => node["update_llnw"]["#{environment.first}"]["llnw"]["shortname"],
      :llnw_username           => node["update_llnw"]["#{environment.first}"]["llnw"]["username"],
      :llnw_password           => node["update_llnw"]["#{environment.first}"]["llnw"]["password"],
      :llnw_url                => node["update_llnw"]["#{environment.first}"]["llnw"]["url"],
      :llnw_prepend_dir        => node["update_llnw"]["#{environment.first}"]["llnw"]["prepend_dir"],
      :akamai_ftp_username     => node["update_llnw"]["#{environment.first}"]["akamai"]["ftp"]["username"],
      :akamai_ftp_password     => node["update_llnw"]["#{environment.first}"]["akamai"]["ftp"]["password"],
      :akamai_ftp_url          => node["update_llnw"]["#{environment.first}"]["akamai"]["ftp"]["url"],
      :akamai_shortname        => node["update_llnw"]["#{environment.first}"]["akamai"]["shortname"],
      :akamai_username         => node["update_llnw"]["#{environment.first}"]["akamai"]["username"],
      :akamai_password         => node["update_llnw"]["#{environment.first}"]["akamai"]["password"],
      :akamai_url              => node["update_llnw"]["#{environment.first}"]["akamai"]["url"],
      :akamai_prepend_dir      => node["update_llnw"]["#{environment.first}"]["akamai"]["prepend_dir"],
      :edgecast_ftp_username   => node["update_llnw"]["#{environment.first}"]["edgecast"]["ftp"]["username"],
      :edgecast_ftp_password   => node["update_llnw"]["#{environment.first}"]["edgecast"]["ftp"]["password"],
      :edgecast_ftp_url        => node["update_llnw"]["#{environment.first}"]["edgecast"]["ftp"]["url"],
      :edgecast_shortname      => node["update_llnw"]["#{environment.first}"]["edgecast"]["shortname"],
      :edgecast_username       => node["update_llnw"]["#{environment.first}"]["edgecast"]["username"],
      :edgecast_password       => node["update_llnw"]["#{environment.first}"]["edgecast"]["password"],
      :edgecast_url            => node["update_llnw"]["#{environment.first}"]["edgecast"]["url"],
      :edgecast_prepend_dir    => node["update_llnw"]["#{environment.first}"]["edgecast"]["prepend_dir"]
     )
  end
end

