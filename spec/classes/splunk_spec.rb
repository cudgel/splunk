# frozen_string_literal: true

require 'spec_helper'

describe 'splunk' do
  let(:title) { 'splunk' }
  let(:node) { 'test.ci' }
  let(:facts) do
    {
      'splunk_cwd'          => '',
      'splunk_guid'         => '',
      'splunk_home'         => '/home/splunk',
      'splunk_shcluster_id' => '',
      'splunk_version'      => '',
      'environment'         => 'ci',
      'kernel'              => 'Linux',
      'architecture'        => 'x86_64',
      'package_provider'    => 'yum',
      'service_provider'    => 'redhat',
      'osfamily'            => 'RedHat',
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
      'type' => 'none',
    }
  end

  context 'with type=> forwarder' do
    let(:params) do
      {
        'type' => 'forwarder',
      }
    end

    it { is_expected.to compile.with_all_deps }
    it { is_expected.to contain_class('splunk') }
    it { is_expected.to contain_class('splunk::install') }
    it { is_expected.to contain_file('/opt/splunkforwarder-7.2.1-be11b2c46e23-Linux-x86_64.tgz').that_notifies('Exec[unpackSplunk]') }
    it { is_expected.to contain_class('splunk::config') }
    it { is_expected.to contain_class('splunk::service') }
    it { is_expected.to contain_service('splunk') }
  end

  context 'with type=> heavyforwarder' do
    let(:params) do
      {
        'type' => 'heavyforwarder',
      }
    end

    it { is_expected.to compile }
  end

  context 'with type=> indexer' do
    let(:params) do
      {
        'type' => 'indexer',
      }
    end

    it { is_expected.to compile }
  end

  context 'with type=> search' do
    let(:params) do
      {
        'type' => 'search',
      }
    end

    it { is_expected.to compile }
  end

  context 'with type=> standalone' do
    let(:params) do
      {
        'type' => 'standalone',
      }
    end

    it { is_expected.to compile }
  end
end
