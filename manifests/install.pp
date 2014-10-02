class splunk::install inherits ::splunk {

  file { "${::splunk::install_path}/${::splunk::params::oldsource}":
    ensure => absent
  }

  file { "${::splunk::install_path}/${::splunk::params::splunksource}":
    owner   => $::splunk::splunk_user,
    group   => $::splunk::splunk_group,
    mode    => '0644',
    source  => "puppet:///modules/${module_name}/${::splunk::splunksource}",
    notify  => Exec['unpackSplunk']
  }

  exec { 'unpackSplunk':
    command     => "${::splunk::params::tarcmd} ${::splunk::splunksource}; \
chown -RL ${::splunk::splunk_user}:${::splunk::splunk_group} \
${::splunk::splunkhome}",
    path        => "${::splunk::splunkhome}/bin:/bin:/usr/bin:",
    cwd         => $::splunk::install_path,
    subscribe   => File["${::splunk::install_path}/${::splunk::splunksource}"],
    timeout     => 600,
    unless      => "test -e ${::splunk::splunkhome}/splunk-${::splunk::version}-${::splunk::release}-${::splunk::splunkos}-${::splunk::splunkarch}-manifest",
    creates     => "${::splunk::splunkhome}/splunk-${::splunk::version}-${::splunk::release}-${::splunk::splunkos}-${::splunk::splunkarch}-manifest"
  }

  exec { 'firstStart':
    command     => "splunk stop; \
splunk --accept-license --answer-yes --no-prompt start",
    path        => "${::splunk::splunkhome}/bin:/bin:/usr/bin:",
    subscribe   => Exec['unpackSplunk'],
    refreshonly => true,
    user        => $::splunk::splunk_user,
    group       => $::splunk::splunk_group
  }

  exec { 'installSplunkService':
    command   => "splunk enable boot-start -user ${::splunk::splunk_user}",
    path      => "${::splunk::splunkhome}/bin:/bin:/usr/bin:",
    subscribe => Exec['unpackSplunk'],
    unless    => 'test -e /etc/init.d/splunk',
    creates   => '/etc/init.d/splunk'
  }

  file { "${::splunk::splunkhome}/etc/splunk-launch.conf":
    owner   => $::splunk::splunk_user,
    group   => $::splunk::splunk_group,
    content => template("${module_name}/launch.erb"),
    mode    => '0644',
    require => Exec['unpackSplunk'],
    notify  => Service[splunk]
  }

  file { "${::splunk::splunklocal}/inputs.d":
    ensure  => 'directory',
    owner   => $::splunk::splunk_user,
    group   => $::splunk::splunk_group,
    mode    => '0555'
  }

  file { "${::splunk::splunklocal}/inputs.d/000_default":
    owner   => $::splunk::splunk_user,
    group   => $::splunk::splunk_group,
    mode    => '0440',
    require => File["${::splunk::splunklocal}/inputs.d"],
    content => template("${module_name}/default_inputs.erb")
  }
}
