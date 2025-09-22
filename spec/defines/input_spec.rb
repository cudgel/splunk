# frozen_string_literal: true

require 'spec_helper'

describe 'splunk::input' do
  let(:title) { 'authlog' }
  let(:node) { 'splunk.test' }
  let(:facts) do
    {
      'splunk_home'      => '/home/splunk',
      'kernel'           => 'Linux',
      'operatingsystem'  => 'CentOS',
      'osfamily'         => 'RedHat',
      'os'               => {
        'architecture' => 'x86_64',
        'family'       => 'RedHat',
        'selinux' => {
          'enabled' => 'false',
        }
      },
    }
  end
  let(:params) do
    {
      'target' => '/var/log/authlog',
      'dir' => '/opt/splunkforwarder',
      'user' => 'splunk',
      'group' => 'splunk',
    }
  end
  let(:pre_condition) do
    "class { splunk: type => 'forwarder', version => '9.4.4', release => 'f627d88b766b' }"
  end

  it { is_expected.to contain_file('/opt/splunkforwarder/etc/system/local/inputs.d/authlog').that_notifies('Exec[update-inputs]') }
  it { is_expected.to contain_splunk__acl('authlog') }
  it { is_expected.to contain_exec('set_acl_/var/log/authlog') }
end
