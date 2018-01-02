Facter.add(:splunk_guid) do
  guid = nil
  guid = Facter::Util::Resolution.exec("grep guid /opt/splunk*/etc/instance.cfg | awk '{print $3}'")
  setcode do
    splunk_guid = guid
  end
end
