RSpec.configure do |c|
  c.hiera_config = File.expand_path(File.join(__FILE__, '../fixtures/hiera.yaml'))
  c.after(:suite) do
    RSpec::Puppet::Coverage.report!
  end
end
