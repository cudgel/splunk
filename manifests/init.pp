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
# Copyright 2014 Your name here, unless otherwise noted.
#
class splunk($type='forwarder') {

  include splunk::params

  $version           = $::splunk::params::version
  $release           = $::splunk::params::release
  $splunk_user       = $::splunk::params::splunk_user
  $splunk_group      = $::splunk::params::splunk_group
  $install_path      = $::splunk::params::install_path
  $old_version       = $::splunk::params::old_version
  $old_release       = $::splunk::params::old_release
  $deployment_server = $::splunk::params::deployment_server
  $indexers          = $::splunk::params::indexers
  $service_url       = $::fqdn
  $splunkos          = $::splunk::params::splunkos
  $splunkarch        = $::splunk::params::splunkarch
  $splunkext         = $::splunk::params::splunkext
  $tar               = $::splunk::params::tar
  $tarcmd            = $::splunk::params::tarcmd
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
  class { 'splunk::service': }
  if $type != 'search' {
      class { 'splunk::deploy': }
  }

  exec { 'update-inputs':
    command     => "/bin/cat ${splunklocal}/inputs.d/* > ${splunklocal}/inputs.conf; \
chown ${splunk_user}:${splunk_group} ${splunklocal}/inputs.conf",
    refreshonly => true,
    subscribe   => File["${splunklocal}/inputs.d/000_default"],
    notify      => Service[splunk],
  }

}
