name        "chef-jenkins"
 maintainer       "AJ Christensen"
maintainer_email "aj@junglist.gen.nz"
license          "Apache 2.0"
description      "Installs and configures Jenkins CI server & slaves"
long_description IO.read(File.join(File.dirname(__FILE__), 'README.md'))
version          "0.8.24"

%w(runit java).each { |cb| depends cb }
%w(iptables yum apt).each { |cb| recommends cb }
