# frozen_string_literal: true

Facter.add(:splunk_home) do
  setcode do
    splunk_home = Facter::Util::Resolution.exec('getent passwd splunk | cut -d: -f6')
    splunk_home
  end
end
