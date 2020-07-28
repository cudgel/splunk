# frozen_string_literal: true

Facter.add(:splunk_cwd) do
  setcode do
    splunk_cwd = Facter::Util::Resolution.exec('find /opt -maxdepth 1 -type d -name \"*splunk*\"')
    splunk_cwd
  end
end
