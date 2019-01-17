# frozen_string_literal: true

Facter.add(:splunk_shcluster_id) do
  setcode do
    if File.exist?('/opt/splunk') || File.exist?('/opt/splunkforwarder')
      splunk_shcluster_id = Facter::Util::Resolution.exec("grep -e \"^id\" /opt/splunk/etc/system/local/server.conf | cut -d'=' -f2 | tr -d '[:space:]'")
      splunk_shcluster_id
    end
  end
end
