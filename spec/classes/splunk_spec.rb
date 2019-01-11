# frozen_string_literal: true

require 'spec_helper'

describe 'splunk' do
  let(:title) { 'splunk' }
  let(:node) { 'splunk.test' }
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

  context 'universal forwarder with deployment server' do
    let(:params) do
      {
        'type'              => 'forwarder',
        'deployment_server' => 'https://splunkds.test:8089',
      }
    end

    it { is_expected.to compile.with_all_deps }
    it { is_expected.to contain_class('splunk') }
    it { is_expected.to contain_class('splunk::install') }
    it { is_expected.to contain_file('/opt/splunkforwarder-7.2.1-be11b2c46e23-Linux-x86_64.tgz').that_notifies('Exec[unpackSplunk]') }
    it { is_expected.to contain_class('splunk::config') }
    it { is_expected.to contain_class('splunk::service') }
    it { is_expected.to contain_service('splunk') }
    it { is_expected.to contain_class('splunk::deployment') }
  end

  context 'heavy forwarder with deployment server' do
    let(:params) do
      {
        'type'              => 'heavyforwarder',
        'deployment_server' => 'https://splunkds.test:8089',
        'tcpout' => {
          'group'   => 'splunkidx',
          'cname'   => 'splunkidx.test',
          'servers' => [
            'splunkidx1:9998',
            'splunkidx2:9998',
            'splunkidx3:9998',
          ],
        },
      }
    end

    it { is_expected.to compile.with_all_deps }
    it { is_expected.to contain_class('splunk') }
    it { is_expected.to contain_class('splunk::install') }
    it { is_expected.to contain_file('/opt/splunk-7.2.1-be11b2c46e23-Linux-x86_64.tgz').that_notifies('Exec[unpackSplunk]') }
    it { is_expected.to contain_class('splunk::config') }
    it { is_expected.to contain_file('/opt/splunk/etc/system/local/outputs.d/000_default') }
    it { is_expected.to contain_class('splunk::service') }
    it { is_expected.to contain_service('splunk') }
    it { is_expected.to contain_class('splunk::deployment') }
  end

  context 'index cluster member' do
    let(:params) do
      {
        'type'              => 'indexer',
        'license_master'    => 'splunklm.test:8089',
        'server_site'       => 'site1',
        'symmkey'           => 'bei6cah0yees0UW3ce3thoht1kaex2az',
        'repl_port'         => 8193,
        'cluster_mode'      => 'slave',
        'clusters'          => [
          {
            'label'          => 'splunkidx',
            'access_logging' => 1,
            'build_load'     => 5,
            'multisite'      => true,
            'sites'          => [
              'site1',
              'site2',
            ],
            'repl_factor'   => 'origin:2,total:3',
            'search_factor' => 'origin:1,total:2',
            'uri'           => 'splunkidx-cm.test:8089',
          },
        ],
      }
    end

    it { is_expected.to compile.with_all_deps }
    it { is_expected.to contain_class('splunk') }
    it { is_expected.to contain_class('splunk::install') }
    it { is_expected.to contain_file('/opt/splunk-7.2.1-be11b2c46e23-Linux-x86_64.tgz').that_notifies('Exec[unpackSplunk]') }
    it { is_expected.to contain_class('splunk::config') }
    it { is_expected.to contain_file('/opt/splunk/etc/system/local/server.d/001_license') }
    it { is_expected.to contain_file('/opt/splunk/etc/system/local/server.d/997_ixclustering') }
    it { is_expected.to contain_file('/opt/splunk/etc/system/local/inputs.d/999_splunktcp') }
    it { is_expected.to contain_file('/opt/splunk/etc/system/local/server.d/995_replication') }
    it { is_expected.to contain_class('splunk::service') }
    it { is_expected.to contain_service('splunk') }
  end

  context 'search head' do
    let(:params) do
      {
        'type' => 'search',
      }
    end

    it { is_expected.to compile.with_all_deps }
    it { is_expected.to contain_class('splunk') }
    it { is_expected.to contain_class('splunk::install') }
    it { is_expected.to contain_file('/opt/splunk-7.2.1-be11b2c46e23-Linux-x86_64.tgz').that_notifies('Exec[unpackSplunk]') }
    it { is_expected.to contain_class('splunk::config') }
    it { is_expected.to contain_class('splunk::service') }
    it { is_expected.to contain_service('splunk') }
  end

  context 'standalone splunk server' do
    let(:params) do
      {
        'type' => 'standalone',
      }
    end

    it { is_expected.to compile.with_all_deps }
    it { is_expected.to contain_class('splunk') }
    it { is_expected.to contain_class('splunk::install') }
    it { is_expected.to contain_file('/opt/splunk-7.2.1-be11b2c46e23-Linux-x86_64.tgz').that_notifies('Exec[unpackSplunk]') }
    it { is_expected.to contain_class('splunk::config') }
    it { is_expected.to contain_class('splunk::service') }
    it { is_expected.to contain_service('splunk') }
  end
end
