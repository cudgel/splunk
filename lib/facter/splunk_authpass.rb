# frozen_string_literal: true

Facter.add(:splunk_authpass) do
  setcode do
    splunk_authpass = Facter::Util::Resolution.exec("grep -i password /opt/splunk/etc/system/local/authentication.conf | cut -d'=' -f2 | tr -d '[:space:]'")
    splunk_authpass
  end
end
