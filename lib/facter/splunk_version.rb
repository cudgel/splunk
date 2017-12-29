Facter.add(:splunk_version) do
  version = nil
  version = Facter::Util::Resolution.exec("ls -1 /opt/splunk* | grep manifest | sort -n | tail -1 | grep -oE '[[:digit:]].[[:digit:]].[[:digit:]]-[a-z0-9]+'")
  setcode do
    splunk_version = version
  end
end
