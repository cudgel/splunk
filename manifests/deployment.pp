class splunk::deployment
{

  $deployment_server = $::splunk::params::deployment_server
  $splunkapps = "${::splunk::splunkhome}/etc/apps"
  $myapp = 'deployclient'
  $myappdir = "${splunkapps}/${myapp}"

  file { $myappdir:
    ensure  => directory,
    owner   => $::splunk::splunk_user,
    group   => $::splunk::splunk_user,
    recurse => true,
    mode    => '0640',
  }

  file { "${myappdir}/local":
    ensure  => directory,
    owner   => $::splunk::splunk_user,
    group   => $::splunk::splunk_user,
    mode    => '0640',
    require => File[$myappdir]
  }

  if $deployment_server {
    file { "${myappdir}/local/deploymentclient.conf":
      content => template("${module_name}/deploymentclient.conf.erb"),
      owner   => $::splunk::splunk_user,
      group   => $::splunk::splunk_user,
      mode    => '0640',
      require => File["${myappdir}/local"],
      notify  => Service[splunk]
    }
  }
}
