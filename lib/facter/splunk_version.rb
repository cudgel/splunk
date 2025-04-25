# frozen_string_literal: true

Facter.add(:splunk_version) do
  setcode do
    splunk_version = Facter::Util::Resolution.exec("ls -1 /opt/splunk* | grep manifest | sort -n | tail -1 | grep -oE '([0-9.])+-([a-f0-9])+'")
    splunk_version
  end
end
