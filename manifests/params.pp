class splunk::params
{
  # splunkd
  $caCertPath          = hiera('splunk::params::caCertPath', 'cacert.pem')
  $serverCertPath      = hiera('splunk::params::serverCertPath', 'server.pem')
  $serverCertPass      = hiera('splunk::params::serverCertPass', 'password')
  # splunkweb
  $privKeyPath         = hiera('splunk::params::privKeyPath', 'privkey.pem')
  $webCertPath         = hiera('splunk::params::webCertPath', 'cert.pem')
  $cipherSuite         = hiera('splunk::params::cipherSuite', undef)
  $repl_port           = hiera('splunk::params::repl_port', undef)
  $clusters            = hiera('splunk::params::clusters', undef)
  $cluster_mode        = hiera('splunk::params::cluster_mode', 'none')
  $shcluster_id        = hiera('splunk::params::shcluster_id', undef)
  $search_deploy       = hiera('splunk::params::search_deploy', undef)
  $shcluster_mode      = hiera('splunk::params::shcluster_mode', 'none')
  $shcluster_label     = hiera('splunk::params::shcluster_label', undef)
  $symmKey             = hiera('splunk::params::symmKey', undef)
  $license_master      = hiera('splunk::params::license_master', undef)
  $license_master_mode = hiera('splunk::params::license_master_mode', 'slave')
  $licenses            = hiera('splunk::params::licenses', undef)
  $server_site         = hiera('splunk::params::server_site', 'default')
  $deployment_disable  = hiera('splunk::params::deployment_disable', false)
  $deployment_interval = hiera('splunk::params::deployment_interval', 30)
  $deployment_server   = hiera('splunk::params::deployment_server', undef)
  $dispatch_earliest   = hiera('splunk::params::dispatch_earliest', undef)
  $dispatch_latest     = hiera('splunk::params::dispatch_latest', undef)
  $dispatch_size       = hiera('splunk::params::dispatch_size', undef)
  $frozenTime          = hiera('splunk::params::frozenTime', undef)
  $tcpout              = hiera('splunk::params::tcpout', undef)
  $install_path        = hiera('splunk::params::install_path', '/opt')

  $scheduler_disable = hiera('splunk::params::scheduler_disable', undef)
  $serviceurl        = hiera('splunk::params::serviceurl', undef)
  $splunk_group      = hiera('splunk::params::splunk_group', 'splunk')
  $splunk_user       = hiera('splunk::params::splunk_user', 'splunk')
  $sslv3             = hiera('splunk::params::SSLV3', false)
  $sslVersions       = hiera('splunk::params::sslVersions', 'tls')
  $max_searches      = hiera('splunk::params::max_searches', 2)
  $subsearch_maxout  = hiera('splunk::params::subsearch_maxout', undef)
  $subsearch_maxtime = hiera('splunk::params::subsearch_maxtime', undef)
  $subsearch_ttl     = hiera('splunk::params::subsearch_ttl', undef)
  $tcpssl            = hiera('splunk::params::TCPSSL', true)
  $version           = hiera('splunk::params::version', undef)
  $webSSL            = hiera('splunk::params::webSSL', true)

  if $::osfamily    == 'Solaris' {
    $splunkos   = 'SunOS'
    $splunkarch = $::architecture ? {
      i86pc   => 'x86_64',
      default => 'sparc'
    }
    $splunkext  = 'tar.Z'
    $tar        = '/usr/sfw/bin/gtar'
    $tarcmd     = "${tar} xZf"
  } elsif $::kernel == 'Linux' {
    $splunkos   = 'Linux'
    $splunkarch = $::architecture ? {
      x86_64  => 'x86_64',
      default => 'i686'
    }
    $splunkext  = 'tgz'
    $tar        = '/bin/tar'
    $tarcmd     = "${tar} xzf"
  } else {
    fail('Unsupported OS')
  }
}
