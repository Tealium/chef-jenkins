# for rsync enabled boxes, create the destination dir for the rsync jobs defined in utui_data_cron.rb
if node[:jenkins]['cron_utui_account_rsync']
    directory "/data/utui/data/accounts" do
        action :create
        mode 0777
        owner node[:jenkins][:server][:user]
        group node[:jenkins][:server][:user]
        recursive true
    end
end
