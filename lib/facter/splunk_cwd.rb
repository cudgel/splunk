Facter.add(:splunk_cwd) do
  splunk_cwd = Facter::Util::Resolution.exec("readlink -e /proc/$(pgrep -o splunk)/exe | grep -oE '/opt/(splunk|splunkforwarder)' | uniq")
  splunk_cwd
end
