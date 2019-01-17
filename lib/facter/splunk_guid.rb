# frozen_string_literal: true

Facter.add(:splunk_guid) do
  setcode do
    if File.exist?('/opt/splunk') || File.exist?('/opt/splunkforwarder')
      splunk_guid = Facter::Util::Resolution.exec("grep guid /opt/splunk*/etc/instance.cfg | awk '{print $3}'")
      splunk_guid
    end
  end
end
