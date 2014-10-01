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
class splunk (
  $type              = $::splunk::params::type,
  $splunkhome        = $::splunk::params::splunkhome,
  $splunklocal       = $::splunk::params::splunklocal,
  $version           = $::splunk::params::version,
  $release           = $::splunk::params::release,
  $splunk_user       = $::splunk::params::splunk_user,
  $splunk_group      = $::splunk::params::splunk_group,
  $install_path      = $::splunk::params::install_path,
  $old_version       = $::splunk::params::old_version,
  $old_release       = $::splunk::params::old_release,
  $service_url       = $::splunk::params::service_url,
  $deployment_server = $::splunk::params::deployment_server
) inherits ::splunk::params {


}
