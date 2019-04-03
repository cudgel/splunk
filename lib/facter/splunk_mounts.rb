# frozen_string_literal: true

Facter.add(:splunk_mounts) do
  setcode do
    splunk_etc = Facter::Util::Resolution.exec("mount | grep splunk/etc | awk '{print $3}'")
    splunk_var = Facter::Util::Resolution.exec("mount | grep splunk/var | awk '{print $3}'")

    if splunk_etc =~ %r{^.*etc.*$} && splunk_var =~ %r{^.*var.*$}
      splunk_mounts = true
      splunk_mounts
    end
  end
end
