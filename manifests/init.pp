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
#  class { splunk:
#    servers => [ 'pool.ntp.org', 'ntp.local.company.com' ],
#  }
#
# === Authors
#
# Author Name <author@domain.com>
#
# === Copyright
#
# Copyright 2014 Your name here, unless otherwise noted.
#
class splunk(
  $type              = 'forwarder',
  $version           = hiera('splunk::version', undef),
  $release           = hiera('splunk::release', undef),
  $splunk_user       = hiera('splunk::splunk_user', 'splunk'),
  $splunk_group      = hiera('splunk::splunk_group', 'splunk'),
  $install_path      = '/opt',
  $old_version       = hiera('splunk::old_version', undef),
  $old_release       = hiera('splunk::old_release', undef),
  $deployment_server = hiera('splunk::deployment_server', undef),
  $service_url       = $::fqdn,
) inherits ::splunk::params {

  if $type == 'forwarder' {
    $sourcepart = 'splunkforwarder'
  } else {
    $sourcepart = 'splunk'
  }
  $splunkhome        = "${install_path}/${sourcepart}"
  $splunklocal       = "${splunkhome}/etc/system/local"
  $splunkdb          = "${splunkhome}/var/lib/splunk"

  $apppart        = "${sourcepart}-${version}-${release}-${splunkos}-${splunkarch}"
  $oldsource      = "${sourcepart}-${old_version}-${old_release}-${splunkos}-${splunkarch}.${splunkext}"
  $splunksource   = "${apppart}.${splunkext}"
  $manifest       = "${apppart}-manifest"


  user { $splunk_user:
    ensure     => present,
    gid        => $splunk_group,
    home       => $splunkhome,
    managehome => false,
    shell      => '/bin/bash',
    password   => '!!'
  }

  class { 'splunk::install': type => $type }->
  class { 'splunk::service': }->
  if $type != 'search' {
      class { 'splunk::deploy': }
  }

}
