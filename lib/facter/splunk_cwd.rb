# frozen_string_literal: true

Facter.add(:splunk_cwd) do
  setcode do
    splunk_paths = ['/opt/splunk', '/opt/splunkforwarder']

    splunk_cwd = nil

    splunk_paths.each do |path|
      if File.directory?(path) && File.exist?("#{path}/bin/splunk")
        splunk_cwd = path
        break
      end
    end

    splunk_cwd
  end
end
