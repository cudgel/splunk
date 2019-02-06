# frozen_string_literal: true

require 'spec_helper'

describe 'splunk::acl' do
  let(:title) { '/var/log/authlog' }
  let(:node) { 'splunk.test' }
  let(:facts) do
    {
      'role'                => 'splunk_forwarder',
      'splunk_home'         => '/home/splunk',
      'environment'         => 'ci',
      'architecture'        => 'x86_64',
      'kernel'              => 'Linux',
      'os'                  => {
        'family'  => 'RedHat',
        'release' => {
          'major' => '6',
        },
      },
    }
  end
  let(:params) do
    {
      'group' => 'splunk',
    }
  end

  it { is_expected.to compile }
  it { is_expected.to contain_exec('set_effective_rights_mask_/var/log/authlog') }
  it { is_expected.to contain_exec('setfacl_/var/log/authlog') }
end
