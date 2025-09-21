# == Class: splunk::deployment
#
# Installs minimal app containg deployment server configuration
#
# === Variables
#
# Here you should define a list of variables that this module would require.
#
# === Examples
#
#  class { 'splunk::deployment': }
#
class splunk::deployment {
  $deployment_server = $splunk::deployment_server
  $splunkapps = "${splunk::dir}/etc/apps"
  $myapp = 'deployclient'
  $myappdir = "${splunkapps}/${myapp}"

  file { $myappdir:
    ensure  => directory,
    owner   => $splunk::user,
    group   => $splunk::user,
    mode    => '0750',
    recurse => false,
  }

  file { "${myappdir}/local":
    ensure  => directory,
    owner   => $splunk::user,
    group   => $splunk::user,
    require => File[$myappdir],
  }

  if $deployment_server {
    file { "${myappdir}/local/deploymentclient.conf":
      content => template("${module_name}/deploymentclient.conf.erb"),
      owner   => $splunk::user,
      group   => $splunk::user,
      require => File["${myappdir}/local"],
      notify  => Service['splunk'],
    }
  } else {
    file { "${myappdir}/local/deploymentclient.conf":
      ensure => absent,
    }
  }
}
