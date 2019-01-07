Facter.add(:splunk_guid) do
  splunk_guid = Facter::Util::Resolution.exec("grep guid /opt/splunk*/etc/instance.cfg | awk '{print $3}'")
  splunk_guid
end
