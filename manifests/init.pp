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

  $version         = $::splunk::params::version
  $splunk_user     = $::splunk::params::splunk_user
  $splunk_group    = $::splunk::params::splunk_group
  $install_path    = $::splunk::params::install_path
  $current_version = $::splunk_version
  $service_url     = $::fqdn
  $splunkos        = $::splunk::params::splunkos
  $splunkarch      = $::splunk::params::splunkarch
  $splunkext       = $::splunk::params::splunkext
  $tar             = $::splunk::params::tar
  $tarcmd          = $::splunk::params::tarcmd
  $mserver         = $::splunk::params::mserver

  if $type == 'forwarder' {
    $sourcepart = 'splunkforwarder'
  } else {
    $sourcepart = 'splunk'
  }

  $splunkhome    = "${install_path}/${sourcepart}"
  $local_path    = "${splunkhome}/etc/system/local"
  $splunkdb      = "${splunkhome}/var/lib/splunk"
  $apppart       = "${sourcepart}-${version}-${splunkos}-${splunkarch}"
  $splunksource  = "${apppart}.${splunkext}"
  $manifest      = "${apppart}-manifest"
  $mserversource = "mserver-linux-realease-${mserver}.tgz"

  class { 'splunk::install': type => $type }->
  class { 'splunk::service': }
  if $type != 'mserver' {
    # configure deployment server for indexers and forwarders
    if $type != 'search' {
      class { 'splunk::deploy': }
    }

    $my_input_d = "${::splunk::local_path}/inputs.d/"
    $my_input_c = "${::splunk::local_path}/inputs.conf"
    $my_perms   = "${::splunk::splunk_user}:${::splunk::splunk_group}"

    exec { 'update-inputs':
      command     => "/bin/cat ${my_input_d}/* > ${my_input_c}; \
  chown ${my_perms} ${my_input_c}",
      refreshonly => true,
      subscribe   => File["${local_path}/inputs.d/000_default"],
      notify      => Service[splunk],
    }
  }
}
