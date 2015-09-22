Facter.add(:splunk_version) do
  version = nil
  splunk_home = Facter::Util::Resolution.exec('grep splunk /etc/passwd | awk -F: \'{print $6}\'')
  version = Facter::Util::Resolution.exec("ls -1 /opt/splunk*/*manifest | sort -n | tail -1 | grep -oE '[[:digit:]].[[:digit:]].[[:digit:]]-[[:digit:]]+'")
  setcode do
  # Sanity check to reject anything that is not an iqn
    splunk_version = version
  end
end
