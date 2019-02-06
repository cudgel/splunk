# frozen_string_literal: true

require 'spec_helper'

describe 'splunk::input' do
  let(:title) { 'authlog' }
  let(:node) { 'splunk.test' }
  let(:facts) do
    {
      'splunk_home'         => '/home/splunk',
      'environment'         => 'ci',
      'kernel'              => 'Linux',
      'architecture'        => 'x86_64',
      'package_provider'    => 'yum',
      'service_provider'    => 'redhat',
      'os'                  => {
        'architecture' => 'x86_64',
        'distro' => {
          'id'      => 'CentOS',
          'release' => {
            'full'  => '6.10',
            'major' => '6',
            'minor' => '10',
          },
        },
        'family'   => 'RedHat',
        'name'     => 'CentOS',
        'release'  => {
          'full'  => '6.10',
          'major' => '6',
          'minor' => '10',
        },
      },
    }
  end
  let(:params) do
    {
      'target' => '/var/log/authlog',
      'dir'   => '/opt/splunkforwarder',
      'user'  => 'splunk',
      'group' => 'splunk',
    }
  end
  let(:pre_condition) { "class { splunk: type => 'forwarder' }" }

  it { is_expected.to contain_file('/opt/splunkforwarder/etc/system/local/inputs.d/authlog').that_notifies('Exec[update-inputs]') }
  it { is_expected.to contain_exec('set_effective_rights_mask_authlog') }
  it { is_expected.to contain_exec('setfacl_authlog') }
end
