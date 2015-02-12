class splunk::params
{
  $version             = hiera('splunk::params::version', undef)
  $splunk_user         = hiera('splunk::params::splunk_user', 'splunk')
  $splunk_group        = hiera('splunk::params::splunk_group', 'splunk')
  $deployment_disable  = hiera('splunk::params::deployment_disable', false)
  $deployment_interval = hiera('splunk::params::deployment_interval', 30)
  $deployment_server   = hiera('splunk::params::deployment_server', undef)
  $indexers            = hiera('splunk::params::indexers', undef)
  $install_path        = hiera('splunk::params::install_path', '/opt')
  $frozenTime          = hiera('splunk::params::frozenTime', undef)
  $warmpath            = hiera('splunk::params::warmpath', undef)
  $coldpath            = hiera('splunk::params::coldpath', undef)
  $maxwarmlargeMB      = hiera('splunk::params::maxwarmlargeMB', undef)
  $maxwarmsmallMB      = hiera('splunk::params::maxwarmsmallMB', undef)
  $maxcoldlargeMB      = hiera('splunk::params::maxcoldlargeMB', undef)
  $maxcoldsmallMB      = hiera('splunk::params::maxcoldsmallMB', undef)
  $cipherSuite         = hiera('splunk::params::cipherSuite', undef)
  $ssl_versions         = hiera('splunk::params::ssl_versions', undef)
  $TCPSSL              = hiera('splunk::params::TCPSSL', true)
  $webSSL              = hiera('splunk::params::webSSL', true)
  $SSLV3               = hiera('splunk::params::SSLV3', false)
  $dispatch_earliest   = hiera('splunk::params::dispatch_earliest', undef)
  $dispatch_latest     = hiera('splunk::params::dispatch_latest', undef)
  $dispatch_size       = hiera('splunk::params::dispatch_size', undef)
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
