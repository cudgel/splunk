require 'spec_helper'

describe 'splunk::acl' do
  let(:environment) { 'ci' }

 let(:facts) do
    {
      'os' => {
        'family'  => 'RedHat',
        'release' => {
          'major' => '6',
          'minor' => '10',
          'full'  => '6.10',
        }
      }
    }
  end

  let :default_params do
    {
      type: 'forwarder'
    }
  end

  it { is_expected.to contain_class('splunk::config') }
end
