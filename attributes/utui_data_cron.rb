# I anticipate that if this IP changes the cronjob will need to be purged
default[:jenkins][:production_utui_eip] = '127.0.0.1'
default[:jenkins][:production_utui_rsync_user] = 'genericUsername'
default[:jenkins][:production_utui_rsync_user_key] = '/this/path/to/keyfile'

default[:jenkins][:nonprod_utui_rysnc_user] = 'otherGenericUsername'
default[:jenkins][:nonprod_utui_rsync_user_key] = '/this/possibly/different/other/path/to/keyfile'
