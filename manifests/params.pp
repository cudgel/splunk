  # initialize module parameters from hiera data
#
class splunk::params
{
  # general
  $splunk_env           = $splunk::splunk_env
  $type                 = $splunk::type
  $install_path         = $splunk::install_path
  $splunk_group         = $splunk::splunk_group
  $splunk_user          = $splunk::splunk_user
  $source               = $splunk::source
  $version              = $splunk::version
  $release              = $splunk::release
  $tcpout               = $splunk::tcpout
  $email                = $splunk::email
  # outputs
  $autolb               = $splunk::autolb
  $autolbfrequency      = $splunk::autolbfrequency
  $forcetimebasedautolb = $splunk::forcetimebasedautolb
  # ssl
  $sslv3                = $splunk::sslv3
  $sslversions          = $splunk::sslversions
  $sslverify            = $splunk::sslverify
  $sslclientcert        = $splunk::sslclientcert
  $sslclientcompression = $splunk::sslclientcompression
  $sslcompression       = $splunk::sslcompression
  $sslnegotiation       = $splunk::sslnegotiation
  $sslstsheader         = $splunk::sslstsheader
  $symmkey              = $splunk::symmkey
  $ciphersuite          = $splunk::ciphersuite
  $ecdhcurves           = $splunk::ecdhcurves
  # splunkd
  $cacert               = $splunk::cacert
  $servercert           = $splunk::servercert
  $servercertpass       = $splunk::servercertpass
  $managesecret         = $splunk::managesecret
  # splunkweb
  $privkey              = $splunk::privkey
  $webcert              = $splunk::webcert
  $webssl               = $splunk::webssl
  # clustering
  $repl_port            = $splunk::repl_port
  $repl_count           = $splunk::repl_count
  $clusters             = $splunk::clusters
  $cluster_mode         = $splunk::cluster_mode
  $shcluster_id         = $splunk::shcluster_id
  $search_deploy        = $splunk::search_deploy
  $shcluster_mode       = $splunk::shcluster_mode
  $shcluster_label      = $splunk::shcluster_label
  $server_site          = $splunk::server_site
  $is_captain           = $splunk::is_captain
  $preferred_captain    = $splunk::preferred_captain
  $adhoc_searchhead     = $splunk::adhoc_searchhead
  $captain_is_adhoc     = $splunk::captain_is_adhoc
  $shcluster_members    = $splunk::shcluster_members
  # license
  $license_master       = $splunk::license_master
  $license_master_mode  = $splunk::license_master_mode
  $licenses             = $splunk::licenses
  # deployment
  $deployment_disable   = $splunk::deployment_disable
  $deployment_interval  = $splunk::deployment_interval
  $deployment_server    = $splunk::deployment_server
  # search
  $dispatch_earliest    = $splunk::dispatch_earliest
  $dispatch_latest      = $splunk::dispatch_latest
  $dispatch_size        = $splunk::dispatch_size
  $max_searches         = $splunk::max_searches
  $scheduler_disable    = $splunk::scheduler_disable
  $serviceurl           = $splunk::serviceurl
  $search_maxinfocsv    = $splunk::search_maxinfocsv
  $search_maxqueue      = $splunk::search_maxqueue
  $subsearch_maxout     = $splunk::subsearch_maxout
  $subsearch_maxtime    = $splunk::subsearch_maxtime
  $subsearch_ttl        = $splunk::subsearch_ttl
  $max_rawsize_perchunk = $splunk::max_rawsize_perchunk
  # inputs - true disables, false enables
  $splunknotcp          = $splunk::splunknotcp
  $splunknotcp_ssl      = $splunk::splunknotcp_ssl

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
      amd64   => 'x86_64',
      default => 'i686'
    }
    $splunkext  = 'tgz'
    $tar        = '/bin/tar'
    $tarcmd     = "${tar} xzf"
  } else {
    fail('Unsupported OS')
  }
}
