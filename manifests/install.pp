class splunk::install inherits splunk {

  file { "${install_path}/${oldsource}":
    ensure => absent
  }

  file { "${install_path}/${splunksource}":
    owner   => ${splunk_user},
    group   => ${splunk_group},
    mode    => '644',
    source  => "puppet:///splunk/${splunksource}",
    notify  => Exec['unpackSplunk']
  }

  exec { 'unpackSplunk':
    command     => "${tarcmd} ${splunksource}; \
chown -RL ${splunk_user}:${splunk_group} ${splunkhome}",
    path        => "${splunkhome}/bin:/bin:/usr/bin:",
    cwd         => "${install_path}",
    subscribe   => File["${install_path}/${splunksource}"],
    timeout     => 600,
    unless      => "test -e ${splunkhome}/splunk-${version}-${release}-${splunkos}-${splunkarch}-manifest",
    creates     => "${splunkhome}/splunk-${version}-${release}-${splunkos}-${splunkarch}-manifest"
  }

  exec { 'firstStart':
    command     => "splunk stop; \
splunk --accept-license --answer-yes --no-prompt start",
    path        => "${splunkhome}/bin:/bin:/usr/bin:",
    subscribe   => Exec['unpackSplunk'],
    refreshonly => true,
    user        => ${splunk_user},
    group       => ${splunk_group}
  }

  exec { 'installSplunkService':
    command   => "splunk enable boot-start -user ${splunk_user}",
    path      => "${splunkhome}/bin:/bin:/usr/bin:",
    subscribe => Exec['unpackSplunk'],
    unless    => 'test -e /etc/init.d/splunk',
    creates   => '/etc/init.d/splunk'
  }

  file { "${splunkhome}/etc/splunk-launch.conf":
    owner   => ${splunk_user},
    group   => ${splunk_group},
    content => template('splunk/launch.erb'),
    mode    => '0644',
    require => Exec['unpackSplunk']
    notify  => Service[splunk],
  }

  file { "${splunklocal}/inputs.d":
    ensure  => 'directory',
    owner   => ${splunk_user},
    group   => ${splunk_group},
    mode    => '0555',
  }

  file { "${splunklocal}/inputs.d/000_default":
    owner   => ${splunk_user},
    group   => ${splunk_group},
    mode    => '0440',
    require => File["${splunklocal}/inputs.d"],
    content => template('splunk/default_inputs.erb')
  }
}
