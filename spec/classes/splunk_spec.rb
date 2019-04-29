# frozen_string_literal: true

require 'spec_helper'

describe 'splunk' do
  let(:title) { 'splunk' }
  let(:node) { 'splunk.example.com' }
  let(:facts) do
    {
      'splunk_home'         => '/home/splunk',
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

  context 'universal forwarder with puppet managed outputs' do
    let(:params) do
      {
        'type'        => 'forwarder',
        'create_user' => true,
        'tcpout'      => {
          'group'   => 'splunkidx',
          'cname'   => 'splunkidx.example.com',
          'servers' => [
            'splunkidx1:9998',
          ],
        },
      }
    end

    it { is_expected.to compile.with_all_deps }
    it { is_expected.to contain_class('splunk') }
    it { is_expected.to contain_class('splunk::user') }
    it { is_expected.to contain_user('splunk').with('ensure' => 'present', 'gid' => 'splunk') }
    it { is_expected.to contain_file('/home/splunk/.bashrc.custom') }
    it { is_expected.to contain_class('splunk::install') }
    it { is_expected.to contain_file('/opt/splunkforwarder-7.2.1-be11b2c46e23-Linux-x86_64.tgz').that_notifies('Exec[unpackSplunk]') }
    it { is_expected.to contain_class('splunk::config') }
    it { is_expected.to contain_file('/opt/splunkforwarder/etc/splunk-launch.conf').that_notifies('Service[splunk]').that_requires('Exec[test_for_splunk]') }
    it { is_expected.to contain_file('/opt/splunkforwarder/etc/apps').with_ensure('directory').that_requires('Exec[test_for_splunk]') }
    it { is_expected.to contain_file('/opt/splunkforwarder/etc/system/local').with_ensure('directory').that_requires('Exec[test_for_splunk]') }
    it { is_expected.to contain_file('/opt/splunkforwarder/etc/system/local/inputs.d').with_ensure('directory').that_requires('Exec[test_for_splunk]') }
    it { is_expected.to contain_file('/opt/splunkforwarder/etc/system/local/inputs.d/000_default').that_requires('File[/opt/splunkforwarder/etc/system/local/inputs.d]') }
    it { is_expected.to contain_file('/opt/splunkforwarder/etc/system/local/inputs.d/000_splunkssl').that_requires('File[/opt/splunkforwarder/etc/system/local/inputs.d]').that_notifies('Exec[update-inputs]') }
    it { is_expected.to contain_exec('update-inputs').that_notifies('Service[splunk]') }
    it { is_expected.to contain_file('/opt/splunkforwarder/etc/system/local/outputs.d').with_ensure('directory').that_requires('Exec[test_for_splunk]') }
    it { is_expected.to contain_file('/opt/splunkforwarder/etc/system/local/outputs.d/000_default').that_requires('File[/opt/splunkforwarder/etc/system/local/outputs.d]').that_notifies('Exec[update-outputs]') }
    it { is_expected.to contain_exec('update-outputs').that_notifies('Service[splunk]') }
    it { is_expected.to contain_class('splunk::service') }
    it { is_expected.to contain_file_line('splunk-restart') }
    it { is_expected.to contain_file_line('splunk-start') }
    it { is_expected.to contain_file_line('splunk-status') }
    it { is_expected.to contain_file_line('splunk-stop') }
    it { is_expected.to contain_service('splunk').with('ensure' => 'running') }
  end

  context 'universal forwarder with deployment server' do
    let(:params) do
      {
        'type'              => 'forwarder',
        'deployment_server' => 'https://splunkds.example.com:8089',
        'create_user'       => true,
      }
    end

    it { is_expected.to compile.with_all_deps }
    it { is_expected.to contain_class('splunk') }
    it { is_expected.to contain_class('splunk::user') }
    it { is_expected.to contain_user('splunk').with('ensure' => 'present', 'gid' => 'splunk') }
    it { is_expected.to contain_file('/home/splunk/.bashrc.custom') }
    it { is_expected.to contain_class('splunk::install') }
    it { is_expected.to contain_exec('retrieve_splunkforwarder-7.2.1-be11b2c46e23-Linux-x86_64.tgz') }
    it { is_expected.to contain_file('/opt/splunkforwarder-7.2.1-be11b2c46e23-Linux-x86_64.tgz').that_notifies('Exec[unpackSplunk]') }
    it { is_expected.to contain_class('splunk::config') }
    it { is_expected.to contain_file('/opt/splunkforwarder/etc/apps').with_ensure('directory').that_requires('Exec[test_for_splunk]') }
    it { is_expected.to contain_file('/opt/splunkforwarder/etc/system/local').with_ensure('directory').that_requires('Exec[test_for_splunk]') }
    it { is_expected.to contain_file('/opt/splunkforwarder/etc/system/local/inputs.d').with_ensure('directory').that_requires('Exec[test_for_splunk]') }
    it { is_expected.to contain_file('/opt/splunkforwarder/etc/system/local/inputs.d/000_default').that_requires('File[/opt/splunkforwarder/etc/system/local/inputs.d]') }
    it { is_expected.to contain_file('/opt/splunkforwarder/etc/system/local/inputs.d/000_splunkssl').that_requires('File[/opt/splunkforwarder/etc/system/local/inputs.d]').that_notifies('Exec[update-inputs]') }
    it { is_expected.to contain_class('splunk::deployment') }
    it { is_expected.to contain_file('/opt/splunkforwarder/etc/apps/deployclient') }
    it { is_expected.to contain_file('/opt/splunkforwarder/etc/apps/deployclient/local').with_ensure('directory').that_requires('File[/opt/splunkforwarder/etc/apps/deployclient]') }
    it { is_expected.to contain_file('/opt/splunkforwarder/etc/apps/deployclient/local/deploymentclient.conf').that_requires('File[/opt/splunkforwarder/etc/apps/deployclient/local]').that_notifies('Service[splunk]') }
    it { is_expected.to contain_class('splunk::service') }
    it { is_expected.to contain_service('splunk').with('ensure' => 'running') }
  end

  context 'universal forwarder upgrade' do
    let(:facts) do
      super().merge(
        'splunk_version' => '7.2.1-be11b2c46e23',
        'splunk_cwd'     => '/opt/splunkforwarder',
      )
    end
    let(:params) do
      {
        'type'    => 'forwarder',
        'version' => '7.2.3',
        'release' => '06d57c595b80',
      }
    end

    it { is_expected.to compile.with_all_deps }
    it { is_expected.to contain_class('splunk') }
    it { is_expected.to contain_class('splunk::install') }
    it { is_expected.to contain_file('/opt/splunkforwarder-7.2.1-be11b2c46e23-Linux-x86_64.tgz').with('ensure' => 'absent') }
    it { is_expected.to contain_exec('retrieve_splunkforwarder-7.2.3-06d57c595b80-Linux-x86_64.tgz') }
    it { is_expected.to contain_file('/opt/splunkforwarder-7.2.3-06d57c595b80-Linux-x86_64.tgz').that_notifies('Exec[unpackSplunk]') }
    it { is_expected.to contain_class('splunk::config') }
    it { is_expected.to contain_class('splunk::service') }
    it { is_expected.to contain_service('splunk').with('ensure' => 'running') }
  end

  context 'universal forwarder attempted downgrade' do
    let(:facts) do
      super().merge(
        'splunk_version' => '7.2.3-06d57c595b80',
        'splunk_cwd'     => '/opt/splunkforwarder',
      )
    end
    let(:params) do
      {
        'type'    => 'forwarder',
        'version' => '7.2.1',
        'release' => 'be11b2c46e23',
      }
    end

    it { is_expected.to compile.with_all_deps }
    it { is_expected.to contain_class('splunk') }
    it { is_expected.to contain_class('splunk::config') }
    it { is_expected.to contain_class('splunk::service') }
    it { is_expected.to contain_service('splunk').with('ensure' => 'running') }
  end

  context 'universal forwarder already installed' do
    let(:facts) do
      super().merge(
        'splunk_version' => '7.2.1-be11b2c46e23',
        'splunk_cwd'     => '/opt/splunkforwarder',
      )
    end
    let(:params) do
      {
        'type'    => 'forwarder',
        'version' => '7.2.1',
        'release' => 'be11b2c46e23',
      }
    end

    it { is_expected.to compile.with_all_deps }
    it { is_expected.to contain_class('splunk') }
    it { is_expected.to contain_class('splunk::config') }
    it { is_expected.to contain_class('splunk::service') }
    it { is_expected.to contain_service('splunk').with('ensure' => 'running') }
  end

  context 'universal forwarder converted to heavy forwarder' do
    let(:facts) do
      super().merge(
        'splunk_version' => '7.2.1-be11b2c46e23',
        'splunk_cwd'     => '/opt/splunkforwarder',
      )
    end
    let(:params) do
      {
        'type'    => 'heavyforwarder',
        'version' => '7.2.1',
        'release' => 'be11b2c46e23',
      }
    end

    it { is_expected.to compile.with_all_deps }
    it { is_expected.to contain_class('splunk') }
    it { is_expected.to contain_class('splunk::install') }
    it { is_expected.to contain_file('/opt/splunkforwarder-7.2.1-be11b2c46e23-Linux-x86_64.tgz').with('ensure' => 'absent') }
    it { is_expected.to contain_exec('uninstallSplunkService') }
    it { is_expected.to contain_exec('serviceStop') }
    it { is_expected.to contain_file('/opt/splunkforwarder').with('ensure' => 'absent') }
    it { is_expected.to contain_file('/opt/splunk-7.2.1-be11b2c46e23-Linux-x86_64.tgz').that_notifies('Exec[unpackSplunk]') }
    it { is_expected.to contain_class('splunk::config') }
    it { is_expected.to contain_class('splunk::service') }
    it { is_expected.to contain_service('splunk').with('ensure' => 'running') }
  end

  context 'heavy forwarder with deployment server' do
    let(:params) do
      {
        'type'              => 'heavyforwarder',
        'deployment_server' => 'https://splunkds.example.com:8089',
        'create_user'       => true,
      }
    end

    it { is_expected.to compile.with_all_deps }
    it { is_expected.to contain_class('splunk') }
    it { is_expected.to contain_class('splunk::user') }
    it { is_expected.to contain_user('splunk').with('ensure' => 'present', 'gid' => 'splunk') }
    it { is_expected.to contain_file('/home/splunk/.bashrc.custom') }
    it { is_expected.to contain_class('splunk::install') }
    it { is_expected.to contain_file('/opt/splunk-7.2.1-be11b2c46e23-Linux-x86_64.tgz').that_notifies('Exec[unpackSplunk]') }
    it { is_expected.to contain_class('splunk::config') }
    it { is_expected.to contain_class('splunk::deployment') }
    it { is_expected.to contain_file('/opt/splunk/etc/apps').with_ensure('directory').that_requires('Exec[test_for_splunk]') }
    it { is_expected.to contain_file('/opt/splunk/etc/system/local').with_ensure('directory').that_requires('Exec[test_for_splunk]') }
    it { is_expected.to contain_file('/opt/splunk/etc/system/local/inputs.d').with_ensure('directory').that_requires('Exec[test_for_splunk]') }
    it { is_expected.to contain_file('/opt/splunk/etc/system/local/inputs.d/000_default').that_requires('File[/opt/splunk/etc/system/local/inputs.d]') }
    it { is_expected.to contain_file('/opt/splunk/etc/system/local/inputs.d/000_splunkssl').that_requires('File[/opt/splunk/etc/system/local/inputs.d]').that_notifies('Exec[update-inputs]') }
    it { is_expected.to contain_file('/opt/splunk/etc/apps/deployclient') }
    it { is_expected.to contain_file('/opt/splunk/etc/apps/deployclient/local').with_ensure('directory').that_requires('File[/opt/splunk/etc/apps/deployclient]') }
    it { is_expected.to contain_file('/opt/splunk/etc/apps/deployclient/local/deploymentclient.conf').that_requires('File[/opt/splunk/etc/apps/deployclient/local]').that_notifies('Service[splunk]') }
    it { is_expected.to contain_class('splunk::service') }
    it { is_expected.to contain_service('splunk').with('ensure' => 'running') }
  end

  context 'indexer' do
    let(:params) do
      {
        'type'           => 'indexer',
        'create_user'    => true,
        'license_master' => 'splunklm.example.com:8089',
        'server_site'    => 'site1',
        'repl_port'      => 8193,
        'cluster_mode'   => 'none',
        'indexes'        => {
          'main' => {
            'frozen_time' => 86_400,
          },
        },
      }
    end

    it { is_expected.to compile.with_all_deps }
    it { is_expected.to contain_class('splunk') }
    it { is_expected.to contain_class('splunk::user') }
    it { is_expected.to contain_user('splunk').with('ensure' => 'present', 'gid' => 'splunk') }
    it { is_expected.to contain_file('/home/splunk/.bashrc.custom') }
    it { is_expected.to contain_class('splunk::install') }
    it { is_expected.to contain_splunk__fetch('sourcefile') }
    it { is_expected.to contain_file('/opt/splunk-7.2.1-be11b2c46e23-Linux-x86_64.tgz').that_notifies('Exec[unpackSplunk]') }
    it { is_expected.to contain_exec('splunkDir') }
    it { is_expected.to contain_class('splunk::config') }
    it { is_expected.to contain_file('/opt/splunk/etc/splunk-launch.conf').that_notifies('Service[splunk]').that_requires('Exec[test_for_splunk]') }
    it { is_expected.to contain_file('/opt/splunk/etc/system/local/inputs.d').with_ensure('directory').that_requires('Exec[test_for_splunk]') }
    it { is_expected.to contain_file('/opt/splunk/etc/system/local/inputs.d/000_default').that_requires('File[/opt/splunk/etc/system/local/inputs.d]') }
    it { is_expected.to contain_file('/opt/splunk/etc/system/local/inputs.d/000_splunkssl').that_requires('File[/opt/splunk/etc/system/local/inputs.d]').that_notifies('Exec[update-inputs]') }
    it { is_expected.to contain_file('/opt/splunk/etc/system/local/inputs.d/999_splunktcp') }
    it { is_expected.to contain_file('/opt/splunk/etc/system/local/indexes.d').with_ensure('directory').that_requires('Exec[test_for_splunk]') }
    it { is_expected.to contain_file('/opt/splunk/etc/system/local/indexes.d/000_default').that_requires('File[/opt/splunk/etc/system/local/indexes.d]') }
    it { is_expected.to contain_splunk__index('main') }
    it { is_expected.to contain_file('/opt/splunk/etc/system/local/indexes.d/main').that_requires('File[/opt/splunk/etc/system/local/indexes.d]').that_notifies('Exec[update-indexes]') }
    it { is_expected.to contain_exec('update-indexes').that_notifies('Service[splunk]') }
    it { is_expected.to contain_file('/opt/splunk/etc/system/local/server.d').with_ensure('directory').that_requires('Exec[test_for_splunk]') }
    it { is_expected.to contain_file('/opt/splunk/etc/system/local/server.d/001_license') }
    it { is_expected.to contain_file('/opt/splunk/etc/system/local/server.d/998_ssl').that_requires('File[/opt/splunk/etc/system/local/server.d]').that_notifies('Exec[update-server]') }
    it { is_expected.to contain_file('/opt/splunk/etc/system/local/server.d/999_default').that_requires('File[/opt/splunk/etc/system/local/server.d]').that_notifies('Exec[update-server]') }
    it { is_expected.to contain_class('splunk::service') }
    it { is_expected.to contain_service('splunk').with('ensure' => 'running') }
  end

  context 'indexer with smartstore' do
    let(:params) do
      {
        'type'           => 'indexer',
        'create_user'    => true,
        'license_master' => 'splunklm.example.com:8089',
        'server_site'    => 'site1',
        'repl_port'      => 8193,
        'cluster_mode'   => 'none',
        'remote_path'    => 's3://splunk-remote/indexes',
        's3_endpoint'    => 's3.amazonaws.com',
        's3_encryption'     => 'sse-s3',
        'indexes'        => {
          'main' => {
            'frozen_time' => 86_400,
            'remote'      => true,
          },
        },
      }
    end

    it { is_expected.to contain_file('/opt/splunk/etc/system/local/indexes.d').with_ensure('directory').that_requires('Exec[test_for_splunk]') }
    it { is_expected.to contain_file('/opt/splunk/etc/system/local/indexes.d/001_s3').that_requires('File[/opt/splunk/etc/system/local/indexes.d]') }
    it { is_expected.to contain_splunk__index('main') }
  end

  context 'index cluster member' do
    let(:params) do
      {
        'type'              => 'indexer',
        'create_user'       => true,
        'license_master'    => 'splunklm.example.com:8089',
        'server_site'       => 'site1',
        'repl_port'         => 8193,
        'cluster_mode'      => 'slave',
        'clusters'          => [
          {
            'label'          => 'SPL-IDX',
            'access_logging' => 1,
            'build_load'     => 5,
            'multisite'      => true,
            'sites'          => [
              'site1',
              'site2',
            ],
            'repl_factor'   => 'origin:2,total:3',
            'search_factor' => 'origin:1,total:2',
            'uri'           => 'splunk-cm.example.com:8089',
          },
        ],
      }
    end

    it { is_expected.to compile.with_all_deps }
    it { is_expected.to contain_class('splunk') }
    it { is_expected.to contain_class('splunk::user') }
    it { is_expected.to contain_user('splunk').with('ensure' => 'present', 'gid' => 'splunk') }
    it { is_expected.to contain_file('/home/splunk/.bashrc.custom') }
    it { is_expected.to contain_class('splunk::install') }
    it { is_expected.to contain_file('/opt/splunk-7.2.1-be11b2c46e23-Linux-x86_64.tgz').that_notifies('Exec[unpackSplunk]') }
    it { is_expected.to contain_class('splunk::config') }
    it { is_expected.to contain_file('/opt/splunk/etc/splunk-launch.conf').that_notifies('Service[splunk]').that_requires('Exec[test_for_splunk]') }
    it { is_expected.to contain_file('/opt/splunk/etc/system/local/inputs.d').with_ensure('directory').that_requires('Exec[test_for_splunk]') }
    it { is_expected.to contain_file('/opt/splunk/etc/system/local/inputs.d/000_default').that_requires('File[/opt/splunk/etc/system/local/inputs.d]') }
    it { is_expected.to contain_file('/opt/splunk/etc/system/local/inputs.d/000_splunkssl').that_requires('File[/opt/splunk/etc/system/local/inputs.d]').that_notifies('Exec[update-inputs]') }
    it { is_expected.to contain_file('/opt/splunk/etc/system/local/inputs.d/999_splunktcp') }
    it { is_expected.to contain_file('/opt/splunk/etc/system/local/server.d').with_ensure('directory').that_requires('Exec[test_for_splunk]') }
    it { is_expected.to contain_file('/opt/splunk/etc/system/local/server.d/001_license') }
    it { is_expected.to contain_file('/opt/splunk/etc/system/local/server.d/995_replication') }
    it { is_expected.to contain_file('/opt/splunk/etc/system/local/server.d/997_ixclustering') }
    it { is_expected.to contain_file('/opt/splunk/etc/system/local/server.d/998_ssl').that_requires('File[/opt/splunk/etc/system/local/server.d]').that_notifies('Exec[update-server]') }
    it { is_expected.to contain_file('/opt/splunk/etc/system/local/server.d/999_default').that_requires('File[/opt/splunk/etc/system/local/server.d]').that_notifies('Exec[update-server]') }
    it { is_expected.to contain_class('splunk::service') }
    it { is_expected.to contain_service('splunk').with('ensure' => 'running') }
  end

  context 'search head with index cluster' do
    let(:params) do
      {
        'type'              => 'search',
        'create_user'       => true,
        'cluster_mode'      => 'searchhead',
        'clusters'          => [
          {
            'label'     => 'SPL-IDX',
            'multisite' => true,
            'sites'     => [
              'site1',
            ],
            'uri' => 'splunk-cm.example.com:8089',
          },
        ],
        'tcpout' => {
          'group'   => 'splunkidx',
          'cname'   => 'splunkidx.example.com',
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
    it { is_expected.to contain_class('splunk::user') }
    it { is_expected.to contain_user('splunk').with('ensure' => 'present', 'gid' => 'splunk') }
    it { is_expected.to contain_file('/home/splunk/.bashrc.custom') }
    it { is_expected.to contain_class('splunk::install') }
    it { is_expected.to contain_file('/opt/splunk-7.2.1-be11b2c46e23-Linux-x86_64.tgz').that_notifies('Exec[unpackSplunk]') }
    it { is_expected.to contain_class('splunk::config') }
    it { is_expected.to contain_file('/opt/splunk/etc/splunk-launch.conf').that_notifies('Service[splunk]').that_requires('Exec[test_for_splunk]') }
    it { is_expected.to contain_file('/opt/splunk/etc/system/local/inputs.d').with_ensure('directory').that_requires('Exec[test_for_splunk]') }
    it { is_expected.to contain_file('/opt/splunk/etc/system/local/inputs.d/000_default').that_requires('File[/opt/splunk/etc/system/local/inputs.d]') }
    it { is_expected.to contain_file('/opt/splunk/etc/system/local/ui-prefs.conf').that_requires('Exec[test_for_splunk]').that_notifies('Service[splunk]') }
    it { is_expected.to contain_file('/opt/splunk/etc/system/local/server.d').with_ensure('directory').that_requires('Exec[test_for_splunk]') }
    it { is_expected.to contain_file('/opt/splunk/etc/system/local/server.d/001_license') }
    it { is_expected.to contain_file('/opt/splunk/etc/system/local/server.d/995_replication') }
    it { is_expected.to contain_file('/opt/splunk/etc/system/local/server.d/996_shclustering').with_ensure('absent').that_notifies('Exec[update-server]') }
    it { is_expected.to contain_file('/opt/splunk/etc/system/local/server.d/997_ixclustering') }
    it { is_expected.to contain_file('/opt/splunk/etc/system/local/server.d/998_ssl').that_requires('File[/opt/splunk/etc/system/local/server.d]').that_notifies('Exec[update-server]') }
    it { is_expected.to contain_file('/opt/splunk/etc/system/local/server.d/999_default').that_requires('File[/opt/splunk/etc/system/local/server.d]').that_notifies('Exec[update-server]') }
    it { is_expected.to contain_class('splunk::service') }
    it { is_expected.to contain_service('splunk').with('ensure' => 'running') }
  end

  context 'search cluster peer (configured) with index cluster' do
    let(:facts) do
      super().merge(
        'splunk_shcluster_id' => '5054d4a8-19a5-11e9-8800-acbc32b372d1',
      )
    end
    let(:params) do
      {
        'type'              => 'search',
        'create_user'       => true,
        'repl_port'         => 8192,
        'cluster_mode'      => 'searchhead',
        'preferred_captain' => false,
        'captain_is_adhoc'  => false,
        'shcluster_mode'    => 'peer',
        'shcluster_label'   => 'SPL-SRCH',
        'clusters'          => [
          {
            'label'     => 'SPL-IDX',
            'multisite' => true,
            'sites'     => [
              'site1',
            ],
            'uri' => 'splunk-cm.example.com:8089',
          },
        ],
        'tcpout' => {
          'group'   => 'splunkidx',
          'cname'   => 'splunkidx.example.com',
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
    it { is_expected.to contain_class('splunk::user') }
    it { is_expected.to contain_user('splunk').with('ensure' => 'present', 'gid' => 'splunk') }
    it { is_expected.to contain_file('/home/splunk/.bashrc.custom') }
    it { is_expected.to contain_class('splunk::install') }
    it { is_expected.to contain_file('/opt/splunk-7.2.1-be11b2c46e23-Linux-x86_64.tgz').that_notifies('Exec[unpackSplunk]') }
    it { is_expected.to contain_class('splunk::config') }
    it { is_expected.to contain_file('/opt/splunk/etc/splunk-launch.conf').that_notifies('Service[splunk]').that_requires('Exec[test_for_splunk]') }
    it { is_expected.to contain_file('/opt/splunk/etc/system/local/inputs.d').with_ensure('directory').that_requires('Exec[test_for_splunk]') }
    it { is_expected.to contain_file('/opt/splunk/etc/system/local/inputs.d/000_default').that_requires('File[/opt/splunk/etc/system/local/inputs.d]') }
    it { is_expected.to contain_file('/opt/splunk/etc/system/local/outputs.d').with_ensure('directory').that_requires('Exec[test_for_splunk]') }
    it { is_expected.to contain_file('/opt/splunk/etc/system/local/outputs.d/000_default').that_requires('File[/opt/splunk/etc/system/local/outputs.d]').that_notifies('Exec[update-outputs]') }
    it { is_expected.to contain_file('/opt/splunk/etc/system/local/server.d').with_ensure('directory').that_requires('Exec[test_for_splunk]') }
    it { is_expected.to contain_file('/opt/splunk/etc/system/local/server.d/001_license') }
    it { is_expected.to contain_file('/opt/splunk/etc/system/local/server.d/995_replication') }
    it { is_expected.to contain_file('/opt/splunk/etc/system/local/server.d/996_shclustering').that_notifies('Exec[update-server]') }
    it { is_expected.to contain_file('/opt/splunk/etc/system/local/server.d/997_ixclustering') }
    it { is_expected.to contain_file('/opt/splunk/etc/system/local/server.d/998_ssl').that_requires('File[/opt/splunk/etc/system/local/server.d]').that_notifies('Exec[update-server]') }
    it { is_expected.to contain_file('/opt/splunk/etc/system/local/server.d/999_default').that_requires('File[/opt/splunk/etc/system/local/server.d]').that_notifies('Exec[update-server]') }
    it { is_expected.to contain_class('splunk::service') }
    it { is_expected.to contain_service('splunk').with('ensure' => 'running') }
  end

  context 'search deployer' do
    let(:params) do
      {
        'type'              => 'search',
        'create_user'       => true,
        'repl_port'         => 8192,
        'shcluster_mode'    => 'deployer',
        'shcluster_label'   => 'SPL-SRCH',
      }
    end

    it { is_expected.to compile.with_all_deps }
    it { is_expected.to contain_class('splunk') }
    it { is_expected.to contain_class('splunk::user') }
    it { is_expected.to contain_user('splunk').with('ensure' => 'present', 'gid' => 'splunk') }
    it { is_expected.to contain_file('/home/splunk/.bashrc.custom') }
    it { is_expected.to contain_class('splunk::install') }
    it { is_expected.to contain_file('/opt/splunk-7.2.1-be11b2c46e23-Linux-x86_64.tgz').that_notifies('Exec[unpackSplunk]') }
    it { is_expected.to contain_class('splunk::config') }
    it { is_expected.to contain_file('/opt/splunk/etc/system/local/inputs.d').with_ensure('directory').that_requires('Exec[test_for_splunk]') }
    it { is_expected.to contain_file('/opt/splunk/etc/system/local/inputs.d/000_default').that_requires('File[/opt/splunk/etc/system/local/inputs.d]') }
    it { is_expected.to contain_file('/opt/splunk/etc/system/local/server.d').with_ensure('directory').that_requires('Exec[test_for_splunk]') }
    it { is_expected.to contain_file('/opt/splunk/etc/system/local/server.d/001_license') }
    it { is_expected.to contain_file('/opt/splunk/etc/system/local/server.d/995_replication') }
    it { is_expected.to contain_file('/opt/splunk/etc/system/local/server.d/996_shclustering').that_notifies('Exec[update-server]') }
    it { is_expected.to contain_class('splunk::service') }
    it { is_expected.to contain_service('splunk').with('ensure' => 'running') }
  end

  context 'standalone splunk server' do
    let(:params) do
      {
        'type'        => 'standalone',
        'create_user' => true,
      }
    end

    it { is_expected.to compile.with_all_deps }
    it { is_expected.to contain_class('splunk') }
    it { is_expected.to contain_class('splunk::user') }
    it { is_expected.to contain_group('splunk') }
    it { is_expected.to contain_user('splunk').with('ensure' => 'present', 'gid' => 'splunk') }
    it { is_expected.to contain_file('/home/splunk/.bashrc.custom') }
    it { is_expected.to contain_class('splunk::install') }
    it { is_expected.to contain_exec('retrieve_splunk-7.2.1-be11b2c46e23-Linux-x86_64.tgz') }
    it { is_expected.to contain_file('/opt/splunk-7.2.1-be11b2c46e23-Linux-x86_64.tgz').that_notifies('Exec[unpackSplunk]') }
    it { is_expected.to contain_exec('unpackSplunk').that_subscribes_to('File[/opt/splunk-7.2.1-be11b2c46e23-Linux-x86_64.tgz]') }
    it { is_expected.to contain_exec('serviceStart') }
    it { is_expected.to contain_exec('installSplunkService').that_subscribes_to('Exec[unpackSplunk]').that_requires('Exec[unpackSplunk]') }
    it { is_expected.to contain_class('splunk::config') }
    it { is_expected.to contain_exec('test_for_splunk') }
    it { is_expected.to contain_file('/opt/splunk/etc/splunk-launch.conf').that_notifies('Service[splunk]').that_requires('Exec[test_for_splunk]') }
    it { is_expected.to contain_file('/opt/splunk/etc/system/local/limits.conf').that_notifies('Service[splunk]').that_requires('Exec[test_for_splunk]') }
    it { is_expected.to contain_file('/opt/splunk/etc/system/local/web.conf').that_notifies('Service[splunk]').that_requires('Exec[test_for_splunk]') }
    it { is_expected.to contain_file('/opt/splunk/etc/system/local/default-mode.conf').that_notifies('Service[splunk]').that_requires('Exec[test_for_splunk]') }
    it { is_expected.to contain_file('/opt/splunk/etc/system/local/alert_actions.conf') }
    it { is_expected.to contain_file('/opt/splunk/etc/system/local/server.d').with_ensure('directory').that_requires('Exec[test_for_splunk]') }
    it { is_expected.to contain_file('/opt/splunk/etc/system/local/server.d/000_header') }
    it { is_expected.to contain_exec('update-server').that_notifies('Service[splunk]') }
    it { is_expected.to contain_package('xorg-x11-server-Xvfb').with_ensure('installed') }
    it { is_expected.to contain_package('liberation-mono-fonts').with_ensure('installed') }
    it { is_expected.to contain_package('liberation-sans-fonts').with_ensure('installed') }
    it { is_expected.to contain_package('liberation-serif-fonts').with_ensure('installed') }
    it { is_expected.to contain_class('splunk::service') }
    it { is_expected.to contain_service('splunk').with('ensure' => 'running') }
  end

  context 'standalone splunk server with LDAP' do
    let(:params) do
      {
        'type'           => 'standalone',
        'create_user'    => true,
        'authentication' => 'LDAP',
        'authconfig'     => {
          'label'          => 'AD',
          'type'           => 'Active Directory',
          'host'           => 'ad.example.com',
          'binddn'         => 'cn=Directory Manager',
          'binddnpassword' => 'password',
          'groupbasedn'    => 'ou=Groups,dc=example,dc=com;',
          'userbasedn'     => 'ou=People,dc=example,dc=com;',
          'userbasefilter' => '(|(memberOf=CN=SplunkAdmins,OU=Groups,DC=example,DC=com)(memberOf=CN=SplunkPowerUsers,OU=Groups,DC=example,DC=com)(memberOf=CN=SplunkUsers,OU=Groups,DC=example,DC=com))',
          'role_maps'      => [
            {
              'role'   => 'admin',
              'groups' => [
                'SplunkAdmins',
              ],
            },
            {
              'role'   => 'power',
              'groups' => [
                'SplunkPowerUsers',
              ],
            },
            {
              'role'   => 'users',
              'groups' => [
                'SplunkUsers',
                'Contractors',
              ],
            },
          ],
        },
        'roles' => [
          {
            'name'     => 'admin',
            'disabled' => false,
            'options'  => [
              'rtsearch = enabled',
              'srchIndexesDefault = *',
              'srchMaxTime = 0',
            ],
          },
        ],
      }
    end

    it { is_expected.to compile.with_all_deps }
    it { is_expected.to contain_class('splunk') }
    it { is_expected.to contain_class('splunk::user') }
    it { is_expected.to contain_user('splunk').with('ensure' => 'present', 'gid' => 'splunk') }
    it { is_expected.to contain_file('/home/splunk/.bashrc.custom') }
    it { is_expected.to contain_class('splunk::install') }
    it { is_expected.to contain_file('/opt/splunk-7.2.1-be11b2c46e23-Linux-x86_64.tgz').that_notifies('Exec[unpackSplunk]') }
    it { is_expected.to contain_class('splunk::config') }
    it { is_expected.to contain_file('/opt/splunk/etc/system/local/alert_actions.conf') }
    it { is_expected.to contain_class('splunk::auth') }
    it { is_expected.to contain_file('/opt/splunk/etc/system/local/auth.d').with_ensure('directory').that_requires('Exec[test_for_splunk]') }
    it { is_expected.to contain_file('/opt/splunk/etc/system/local/auth.d/ldap') }
    it { is_expected.to contain_exec('update-auth').that_notifies('Service[splunk]') }
    it { is_expected.to contain_file('/opt/splunk/etc/system/local/authorize.conf').that_notifies('Service[splunk]') }
    it { is_expected.to contain_class('splunk::service') }
    it { is_expected.to contain_service('splunk').with('ensure' => 'running') }
  end

  context 'standalone splunk server with fileserver' do
    let(:params) do
      {
        'type'        => 'standalone',
        'create_user' => true,
        'source'      => 'puppet:///splunk_files',
      }
    end

    it { is_expected.to compile.with_all_deps }
    it { is_expected.to contain_class('splunk') }
    it { is_expected.to contain_class('splunk::user') }
    it { is_expected.to contain_user('splunk').with('ensure' => 'present', 'gid' => 'splunk') }
    it { is_expected.to contain_file('/home/splunk/.bashrc.custom') }
    it { is_expected.to contain_class('splunk::install') }
    it { is_expected.to contain_file('/opt/splunk-7.2.1-be11b2c46e23-Linux-x86_64.tgz').that_notifies('Exec[unpackSplunk]') }
    it { is_expected.to contain_exec('serviceStart') }
    it { is_expected.to contain_class('splunk::config') }
    it { is_expected.to contain_file('/opt/splunk/etc/splunk-launch.conf').that_notifies('Service[splunk]').that_requires('Exec[test_for_splunk]') }
    it { is_expected.to contain_file('/opt/splunk/etc/system/local/limits.conf').that_notifies('Service[splunk]').that_requires('Exec[test_for_splunk]') }
    it { is_expected.to contain_file('/opt/splunk/etc/system/local/web.conf').that_notifies('Service[splunk]').that_requires('Exec[test_for_splunk]') }
    it { is_expected.to contain_file('/opt/splunk/etc/system/local/default-mode.conf').that_notifies('Service[splunk]').that_requires('Exec[test_for_splunk]') }
    it { is_expected.to contain_file('/opt/splunk/etc/system/local/alert_actions.conf') }
    it { is_expected.to contain_file('/opt/splunk/etc/system/local/server.d').with_ensure('directory').that_requires('Exec[test_for_splunk]') }
    it { is_expected.to contain_file('/opt/splunk/etc/system/local/server.d/000_header') }
    it { is_expected.to contain_package('xorg-x11-server-Xvfb').with_ensure('installed') }
    it { is_expected.to contain_package('liberation-mono-fonts').with_ensure('installed') }
    it { is_expected.to contain_package('liberation-sans-fonts').with_ensure('installed') }
    it { is_expected.to contain_package('liberation-serif-fonts').with_ensure('installed') }
    it { is_expected.to contain_class('splunk::service') }
    it { is_expected.to contain_service('splunk').with('ensure' => 'running') }
  end
end
