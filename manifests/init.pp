# == Class: splunk
#
# Full description of class splunk here.
#
# === Parameters
#
# Document parameters here.
#
# [*sample_parameter*]
#   Explanation of what this parameter affects and what it defaults to.
#   e.g. "Specify one or more upstream ntp servers as an array."
#
# === Variables
#
# Here you should define a list of variables that this module would require.
#
# [*sample_variable*]
#   Explanation of how this variable affects the funtion of this class and if
#   it has a default. e.g. "The parameter enc_ntp_servers must be set by the
#   External Node Classifier as a comma separated list of hostnames." (Note,
#   global variables should be avoided in favor of class parameters as
#   of Puppet 2.6.)
#
# === Examples
#
#  class { splunk: type => 'forwarder' }
#
# === Authors
#
# Christopher Caldwell <author@domain.com>
#
# === Copyright
#
# Copyright 2017 Christopher Caldwell
#
class splunk(
  String $version,
String $release,
String $type,
Boolean $adhoc_searchhead,
Boolean $autolb,
Integer $autolbfrequency,
String $cacert,
Boolean $captain_is_adhoc,
String $ciphersuite,
String $cluster_mode,
Boolean $create_user,
Boolean $deployment_disable,
Integer $deployment_interval,
Optional[String] $deployment_server,
String $dispatch_earliest,
String $dispatch_latest,
Integer $dispatch_size,
String $ecdhcurves,
String $email,
Boolean $forcetimebasedautolb,
String $install_path,
Boolean $is_captain,
String $license_master_mode,
Optional[String] $license_master,
Boolean $managesecret,
Integer $max_rawsize_perchunk,
Integer $max_searches,
Boolean $preferred_captain,
String $privkey,
Integer $repl_count,
Integer $repl_port,
Boolean $scheduler_disable,
Optional[String] $search_deploy,
Integer $search_maxinfocsv,
Integer $search_maxqueue,
String $server_site,
String $servercert,
String $servercertpass,
Optional[String] $serviceurl,
String $shcluster_mode,
String $source,
String $splunk_group,
String $splunk_user,
Boolean $splunknotcp_ssl,
Boolean $splunknotcp,
Boolean $sslclientcert,
Boolean $sslclientcompression,
Boolean $sslcompression,
Boolean $sslnegotiation,
Boolean $sslstsheader,
Boolean $sslv3,
Boolean $sslverify,
String $sslversions,
Integer $subsearch_maxout,
Integer $subsearch_maxtime,
Integer $subsearch_ttl,
Optional[String] $symmkey,
Optional[Hash] $tcpout,
String $webcert,
Boolean $webssl,
Optional[Hash] $acls,
Optional[Hash] $inputs,
Optional[String] $splunk_env = undef,
Optional[Tuple] $clusters = undef,
Optional[Tuple] $licenses = undef,
Optional[String] $shcluster_label = undef,
Optional[Array] $shcluster_members = undef,

) {

  if $type != 'none' {

    if $splunk_env == 'ci' or $create_user == true {
      class { 'splunk::user': }
    }

  $new_version = "${splunk::version}-${splunk::release}"

  if $type == 'forwarder' {
    $sourcepart = 'splunkforwarder'
  } else {
    $sourcepart = 'splunk'
  }

  $splunkdir     = "${splunk::install_path}/${sourcepart}"
  $capath        = "${splunkdir}/etc/auth"
  $local_path    = "${splunkdir}/etc/system/local"
  $splunkdb      = "${splunkdir}/var/lib/splunk"
  $manifest       = "${sourcepart}-${new_version}-${splunkos}-${splunkarch}-manifest"

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

    # splunk search head cluster id (if a cluster member)
  $shcluster_id = $::splunk_shcluster_id

    # directory of any running splunk process
  $cwd = $::splunk_cwd

  # currently installed version from fact
  $current_version = $::splunk_version
  $cut_version = regsubst($current_version, '^(\d+\.\d+\.\d+)-.*$', '\1')
  # because the legacy fact does not represent splunk version as
  # version-release, we cut the version from the string.

  if $version != $cut_version or $cwd != $splunkdir {
    if versioncmp($version, $cut_version) > 0 or $cut_version == '' or $cwd != $splunkdir {
      class { 'splunk::install': } -> class { 'splunk::config': } -> class { 'splunk::service': }
    }
  } else {
    class { 'splunk::config': } -> class { 'splunk::service': }
  }

  # configure deployment server for indexers and forwarders
  if $type == 'forwarder' or $type == 'heavyforwarder' {
    class { 'splunk::deployment': }
  }

  $my_input_d  = "${local_path}/inputs.d/"
  $my_input_c  = "${local_path}/inputs.conf"
  $my_output_d = "${local_path}/outputs.d/"
  $my_output_c = "${local_path}/outputs.conf"
  $my_server_d = "${local_path}/server.d/"
  $my_server_c = "${local_path}/server.conf"
    $my_perms    = "${splunk::splunk_user}:${splunk::splunk_group}"

  exec { 'update-inputs':
    command     => "/bin/cat ${my_input_d}/* > ${my_input_c}; \
chown ${my_perms} ${my_input_c}",
    refreshonly => true,
    subscribe   => File["${local_path}/inputs.d/000_default"],
    notify      => Service['splunk']
  }

  if $type != 'forwarder' {

    exec { 'update-outputs':
      command     => "/bin/cat ${my_output_d}/* > ${my_output_c}; \
  chown ${my_perms} ${my_output_c}",
      refreshonly => true,
      notify      => Service['splunk']
    }

    exec { 'update-server':
      command     => "/bin/cat ${my_server_d}/* > ${my_server_c}; \
chown ${my_perms} ${my_server_c}",
      refreshonly => true,
      subscribe   => [File["${local_path}/server.d/000_header"],
File["${local_path}/server.d/998_ssl"], File["${local_path}/server.d/999_default"]],
      notify      => Service['splunk']
    }

  }

  }

}
