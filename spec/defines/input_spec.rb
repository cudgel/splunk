require 'spec_helper'

describe 'splunk::input' do
  let(:environment) { 'ci' }

  let(:facts) do
    {
      'os' => {
        'family'  => 'RedHat',
        'release' => {
          'major' => '6',
          'minor' => '10',
          'full'  => '6.10',
        },
      },
    }
  end

  let :default_params do
    {
      type: 'forwarder',
      title: 'authlog',
      target: '/var/log/authlog',
      version: '7.2.1',
      release: 'be11b2c46e23',
    }
  end

  let :pre_condition do
    [
      'include ::splunk',
    ]
  end

  it { is_expected.to contain_class('splunk::config') }
end
