Facter.add(:splunk_cwd) do
  cwd = nil
  cwd = Facter::Util::Resolution.exec("readlink -e /proc/$(pgrep -o splunk)/exe | grep -oE '/opt/(splunk|splunkforwarder)' | uniq")
  setcode do
    splunk_cwd= cwd
  end
end
