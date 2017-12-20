Facter.add(:splunk_shcluster_id) do
  id = nil
  id = Facter::Util::Resolution.exec("grep id /opt/splunk/etc/system/local/server.conf | cut -d'=' -f2 | tr -d '[:space:]'")
  setcode do
    splunk_shcluster_id = id
  end
end
