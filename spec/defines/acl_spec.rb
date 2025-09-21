# frozen_string_literal: true

require 'spec_helper'

describe 'splunk::acl' do
  let(:title) { '/var/log/authlog' }
  let(:node) { 'splunk.test' }
  let(:facts) do
    {
      'role'         => 'splunk_forwarder',
      'splunk_home'  => '/home/splunk',
      'architecture' => 'x86_64',
      'kernel'       => 'Linux',
      'os'           => {
        'architecture' => 'x86_64',
        'family'       => 'RedHat',
      },
    }
  end
  let(:params) do
    {
      'group' => 'splunk',
    }
  end

  it { is_expected.to compile }
  # it { is_expected.to contain_exec('setfacl_/var/log/authlog') }
end
