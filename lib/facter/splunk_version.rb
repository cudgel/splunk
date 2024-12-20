Facter.add(:splunk_version) do
  confine :kernel => 'Linux'
  setcode do
    # Define possible Splunk installation paths
    splunk_paths = {
      enterprise: '/opt/splunk/bin/splunk',
      forwarder: '/opt/splunkforwarder/bin/splunk'
    }

    # Find which Splunk binary exists
    binary_path = splunk_paths.values.find { |path| File.executable?(path) }

    if binary_path
      begin
        version = Facter::Core::Execution.execute("#{binary_path} version --accept-license")
        if version =~ /Version\s+([\d.]+)/
          $1
        else
          Facter.debug("Could not parse Splunk version output")
          nil
        end
      rescue Facter::Core::Execution::ExecutionFailure => e
        Facter.debug("Failed to get Splunk version: #{e.message}")
        nil
      end
    else
      Facter.debug("No Splunk binary found in expected locations")
      nil
    end
  end
end
