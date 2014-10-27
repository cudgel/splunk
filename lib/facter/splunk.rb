Facter.add(:splunk_version) do
  if Dir.exists?('~splunk')
    setcode do
      version = nil
      version = Facter::Util::Resolution.exec('echo `ls -1 ~splunk/*manifest | sort -n | tail -1` | awk -F- \'{print $2 "-" $3}\'')
      version = nil unless version =~ /^\d.\d.\d-\d*$/
      version
    end
  end
end