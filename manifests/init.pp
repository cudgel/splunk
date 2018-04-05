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
class splunk($type='forwarder') {

  include splunk::params

  $splunk_env      = $::splunk::params::splunk_env
  $maj_version     = $::splunk::params::version
  $release         = $::splunk::params::release
  $splunk_user     = $::splunk::params::splunk_user
  $splunk_group    = $::splunk::params::splunk_group
  $install_path    = $::splunk::params::install_path
  # cluster id from initialized cluster
  $shcluster_id    = $::splunk_shcluster_id
  $serviceurl      = $::splunk::params::serviceurl
  $splunkos        = $::splunk::params::splunkos
  $splunkarch      = $::splunk::params::splunkarch
  $splunkext       = $::splunk::params::splunkext
  $tar             = $::splunk::params::tar
  $tarcmd          = $::splunk::params::tarcmd

  # if $splunk_env == 'ci' {
  #   class { 'splunk::user': }
  # }

  $new_version = "${maj_version}-${release}"

  if $type == 'forwarder' {
    $sourcepart = 'splunkforwarder'
  } else {
    $sourcepart = 'splunk'
  }

  $splunkdir     = "${install_path}/${sourcepart}"
  $capath        = "${splunkdir}/etc/auth"
  $local_path    = "${splunkdir}/etc/system/local"
  $splunkdb      = "${splunkdir}/var/lib/splunk"
  $manifest       = "${sourcepart}-${new_version}-${splunkos}-${splunkarch}-manifest"

  # currently installed version from fact
  $current_version = $::splunk_version
  $cut_version = regsubst($current_version, '^(\d+\.\d+\.\d+)-.*$', '\1')
  # because the legacy fact does not represent splunk version as
  # version-release, we cut the version from the string.

  if $maj_version != $cut_version {
    if versioncmp($maj_version, $cut_version) > 0 {
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

  $my_perms   = "${::splunk::splunk_user}:${::splunk::splunk_group}"

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

  # if $type == 'forwarder' and $splunk_env == 'ci' {
  #   class { 'splunk::test': }
  # }
}
