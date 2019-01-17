# frozen_string_literal: true

Facter.add(:splunk_home) do
  setcode do
    if File.exist?('/opt/splunk') || File.exist?('/opt/splunkforwarder')
      splunk_home = Facter::Util::Resolution.exec('getent passwd splunk | cut -d: -f6')
      splunk_home
    end
  end
end
