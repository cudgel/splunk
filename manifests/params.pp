class splunk::params
{
  # general
  $install_path        = hiera('splunk::params::install_path', '/opt')
  $splunk_group        = hiera('splunk::params::splunk_group', 'splunk')
  $splunk_user         = hiera('splunk::params::splunk_user', 'splunk')
  $version             = hiera('splunk::params::version', undef)
  $tcpout              = hiera('splunk::params::tcpout', undef)
  # ssl
  $sslv3               = hiera('splunk::params::sslv3', false)
  $sslversions         = hiera('splunk::params::sslversions', 'tls')
  $symmkey             = hiera('splunk::params::symmkey', undef)
  # splunkd
  $cacertpath          = hiera('splunk::params::cacertpath', 'cacert.pem')
  $servercertpath      = hiera('splunk::params::servercertpath', 'server.pem')
  $servercertpass      = hiera('splunk::params::servercertpass', 'password')
  # splunkweb
  $privkeypath         = hiera('splunk::params::privkeypath', 'privkey.pem')
  $webcertpath         = hiera('splunk::params::webcertpath', 'cert.pem')
  $ciphersuite         = hiera('splunk::params::ciphersuite', undef)
  $webssl              = hiera('splunk::params::webssl', true)
  # clustering
  $repl_port           = hiera('splunk::params::repl_port', 'none')
  $clusters            = hiera('splunk::params::clusters', undef)
  $cluster_mode        = hiera('splunk::params::cluster_mode', 'none')
  $shcluster_id        = hiera('splunk::params::shcluster_id', undef)
  $search_deploy       = hiera('splunk::params::search_deploy', undef)
  $shcluster_mode      = hiera('splunk::params::shcluster_mode', 'none')
  $shcluster_label     = hiera('splunk::params::shcluster_label', undef)
  $server_site         = hiera('splunk::params::server_site', 'default')
  # license
  $license_master      = hiera('splunk::params::license_master', undef)
  $license_master_mode = hiera('splunk::params::license_master_mode', 'slave')
  $licenses            = hiera('splunk::params::licenses', undef)
  # deployment
  $deployment_disable  = hiera('splunk::params::deployment_disable', false)
  $deployment_interval = hiera('splunk::params::deployment_interval', 30)
  $deployment_server   = hiera('splunk::params::deployment_server', undef)
  # search
  $dispatch_earliest   = hiera('splunk::params::dispatch_earliest', undef)
  $dispatch_latest     = hiera('splunk::params::dispatch_latest', undef)
  $dispatch_size       = hiera('splunk::params::dispatch_size', undef)
  $max_searches        = hiera('splunk::params::max_searches', 1)
  $scheduler_disable   = hiera('splunk::params::scheduler_disable', undef)
  $serviceurl          = hiera('splunk::params::serviceurl', undef)
  $subsearch_maxout    = hiera('splunk::params::subsearch_maxout', undef)
  $subsearch_maxtime   = hiera('splunk::params::subsearch_maxtime', undef)
  $subsearch_ttl       = hiera('splunk::params::subsearch_ttl', undef)

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
