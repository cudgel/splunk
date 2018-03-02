# == Class: splunk::deployment
#
# Installs minimal app containg deployment server configuration
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
#  class { 'splunk::deployment': }
#
class splunk::deployment
{

  $deployment_server = $::splunk::params::deployment_server
  $splunkapps = "${::splunk::splunkdir}/etc/apps"
  $myapp = 'deployclient'
  $myappdir = "${splunkapps}/${myapp}"

  file { $myappdir:
    ensure  => directory,
    owner   => $::splunk::splunk_user,
    group   => $::splunk::splunk_user,
    mode    => '0750',
    recurse => true
  }

  file { "${myappdir}/local":
    ensure  => directory,
    owner   => $::splunk::splunk_user,
    group   => $::splunk::splunk_user,
    require => File[$myappdir]
  }

  if $deployment_server {
    file { "${myappdir}/local/deploymentclient.conf":
      content => template("${module_name}/deploymentclient.conf.erb"),
      owner   => $::splunk::splunk_user,
      group   => $::splunk::splunk_user,
      require => File["${myappdir}/local"],
      notify  => Service[splunk]
    }
  }
}
