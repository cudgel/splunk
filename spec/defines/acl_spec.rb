# frozen_string_literal: true

require 'spec_helper'

describe 'splunk::acl' do
  let(:title) { '/var/log/authlog' }
  let(:node) { 'splunk.test' }
  let(:facts) do
    {
      'role'                => 'splunk_forwarder',
      'splunk_cwd'          => '',
      'splunk_guid'         => '',
      'splunk_home'         => '/home/splunk',
      'splunk_shcluster_id' => '',
      'splunk_version'      => '',
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
end
