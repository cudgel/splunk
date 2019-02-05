# frozen_string_literal: true

Facter.add(:splunk_certpass) do
  setcode do
    splunk_certpass = Facter::Util::Resolution.exec("grep -e \"^sslPassword\" /opt/splunk/etc/system/local/server.conf | cut -d'=' -f2 | tr -d '[:space:]'")
    splunk_certpass
  end
end
