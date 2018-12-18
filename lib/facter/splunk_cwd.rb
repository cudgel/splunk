Facter.add(:splunk_cwd) do
  cwd = nil
  cwd = Facter::Util::Resolution.exec("ps -f -u splunk | grep bin | grep -oE '/opt/(splunk|splunkforwarder)' | uniq")
  setcode do
    splunk_cwd= cwd
  end
end
