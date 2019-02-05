# frozen_string_literal: true

Facter.add(:splunk_symmkey) do
  setcode do
    splunk_symmkey = if File.exist?('/opt/splunk/etc/system/local/symmkey.conf')
                       Facter::Util::Resolution.exec('cat /opt/splunk/etc/system/local/symmkey.conf')
                     else
                       Facter::Util::Resolution.exec("grep -e \"^pass4SymmKey\" /opt/splunk/etc/system/local/server.conf | cut -d'=' -f2 | tr -d '[:space:]'")
                     end
    splunk_symmkey
  end
end
