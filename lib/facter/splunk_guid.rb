Facter.add(:splunk_guid) do
  guid = nil
  guid = Facter::Util::Resolution.exec("grep guid /opt/splunk*/etc/instance.cfg | awk '{print $3}'")
  setcode do
  # Sanity check to reject anything that is not an iqn
    splunk_guid = guid
  end
end
