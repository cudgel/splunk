Facter.add(:splunk_home) do
  splunk_home = Facter::Util::Resolution.exec('getent passwd splunk | cut -d: -f6')
  splunk_home
end
