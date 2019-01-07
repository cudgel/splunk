Facter.add(:splunk_version) do
  splunk_version = Facter::Util::Resolution.exec("ls -1 /opt/splunk* | grep manifest | sort -n | tail -1 | grep -oE '[[:digit:]].[[:digit:]].[[:digit:]]-[a-z0-9]+'")
  splunk_version
end
