# frozen_string_literal: true

Facter.add(:splunk_symmkey) do
  setcode do
    splunk_symmkey = Facter::Util::Resolution.exec("grep -e ^pass4SymmKey /opt/splunk/etc/system/local/server.conf | head -1 | cut -d'=' -f2 | tr -d '[:space:]'")
    splunk_symmkey
  end
end
