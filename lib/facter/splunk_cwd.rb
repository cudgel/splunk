# frozen_string_literal: true

Facter.add(:splunk_cwd) do
  setcode do
    if File.exist? '/opt/splunk' or File.exist? '/opt/splunkforwarder'
      splunk_cwd = Facter::Util::Resolution.exec("readlink -e /proc/$(pgrep -o splunk)/exe | grep -oE '/opt/(splunk|splunkforwarder)' | uniq")
      splunk_cwd
    end
  end
end
