class splunk::deploy($deploymentserver='$::splunk::deploymentserver')
{

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

  if $deploymentserver {
    file { "${myappdir}/local/deploymentclient.conf":
      content => template("${module_name}/deployclient.erb"),
      owner   => $::splunk::splunk_user,
      group   => $::splunk::splunk_user,
      mode    => '0640',
      require => File["${myappdir}/local"],
      notify  => Service[splunk]
    }
  }
}
