Facter.add(:splunk_version) do
  if Dir.exists?('~splunk')
    setcode do
      version = Facter::Util::Resolution.exec('echo `ls -1 ~splunk/*manifest | sort -n | tail -1` | awk -F- \'{print $2 "-" $3}\'')
    end
  end
end