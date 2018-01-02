Facter.add(:splunk_home) do
  home = nil
  home = Facter::Util::Resolution.exec("getent passwd splunk | cut -d: -f6")
  setcode do
    splunk_home = home
  end
end

