class splunk::install($type,$syslog=false)
{

  $manifest  = "${::splunk::apppart}-manifest"

  file { "${::splunk::install_path}/${::splunk::oldsource}":
    ensure => absent
  }

  file { "${::splunk::install_path}/${::splunk::splunksource}":
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
    cwd         => $install_path,
    subscribe   => File["${::splunk::install_path}/${::splunk::splunksource}"],
    timeout     => 600,
    unless      => "test -e ${manifest}",
    creates     => $manifest
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

  if $type == 'forwarder' {
    if $syslog == true {
      firewall { '020 syslog':
        chain  => 'INPUT' ,
        proto  => ['tcp','udp'],
        dport  => ['514', '5140', '10514', '10515'],
        action => 'accept'
      }
    }

    file { "${::splunk::splunklocal}/outputs.conf":
      owner   => $::splunk::splunk_user,
      group   => $::splunk::splunk_user,
      content => template("${module_name}/output.erb"),
      mode    => '0644',
      notify  => Service[splunk],
      alias   => 'splunk-outputs'
    }

  } elsif $type == 'indexer' {

    firewall { '020 splunkd':
      chain  => 'INPUT' ,
      proto  => 'tcp',
      dport  => '8089',
      action => 'accept'
    }

    firewall { '025 Splunk forwarders':
      chain  => 'INPUT' ,
      proto  => 'tcp',
      dport  => '9997',
      action => 'accept'
    }

    file { "${::splunk::splunklocal}/outputs.conf":
      ensure  => absent,
      notify  => Service[splunk]
    }

    file { "${::splunk::splunklocal}/web.conf":
      owner   => $::splunk::splunk_user,
      group   => $::splunk::splunk_group,
      source  => 'puppet:///modules/splunk/web.conf',
      mode    => '0644',
      require => File['splunk-home'],
      notify  => Service[splunk],
      alias   => 'splunk-web'
    }

    file { "${::splunk::splunklocal}/inputs.d/999_splunktcp":
      owner   => $::splunk::splunk_user,
      group   => $::splunk::splunk_group,
      mode    => '0440',
      content => template("${module_name}/splunktcp.erb"),
      notify  => Exec['update-inputs']
    }

    file { "${::splunk::splunklocal}/indexes.d":
      ensure  => 'directory',
      owner   => $::splunk::splunk_user,
      group   => $::splunk::splunk_group,
      mode    => '0555',
      require => File['splunk-home']
    }

    file { "${::splunk::splunklocal}/indexes.d/000_default":
      owner   => $::splunk::splunk_user,
      group   => $::splunk::splunk_group,
      mode    => '0440',
      content => template("${module_name}/volumes.erb")
    }

    exec { 'update-indexes':
      command     => "/bin/cat ${::splunk::splunklocal}/indexes.d/* > ${::splunk::splunklocal}/indexes.conf; \
  chown ${::splunk::splunk_user}:${::splunk::splunk_group} ${::splunk::splunklocal}/indexes.conf",
      refreshonly => true,
      subscribe   => File["${::splunk::splunklocal}/indexes.d/000_default"],
      notify      => Service[splunk],
    }

  } elsif $type == 'search' {

      firewall { '020 splunk-web':
        chain  => 'INPUT' ,
        proto  => 'tcp',
        dport  => '8000',
        action => 'accept'
      }

      firewall { '030 splunkd':
        chain  => 'INPUT' ,
        proto  => 'tcp',
        dport  => '8089',
        action => 'accept'
      }

      if $::osfamily == 'RedHat' {
  #       support PDF Report Server
          package { [
              'xorg-x11-server-Xvfb',
              'liberation-mono-fonts',
              'liberation-sans-fonts',
              'liberation-serif-fonts' ]:
              ensure => installed,
          }
      }

      file { "${::splunk::splunklocal}/outputs.conf":
          owner   => $::splunk::splunk_user,
          group   => $::splunk::splunk_user,
          content => template("${module_name}/outputs.erb"),
          mode    => '0644',
          require => File['splunk-home'],
          notify  => Service[splunk],
          alias   => 'splunk-outputs'
      }

      file { "${::splunk::splunklocal}/alert_actions.conf":
          owner   => $::splunk::splunk_user,
          group   => $::splunk::splunk_user,
          content => template("${module_name}/alert_actions.erb"),
          mode    => '0644',
          require => File['splunk-home'],
          notify  => Service[splunk],
          alias   => 'alert-actions'
      }

      file { "${::splunk::splunklocal}/web.conf":
          owner   => $::splunk::splunk_user,
          group   => $::splunk::splunk_user,
          source  => 'puppet:///modules/splunk/web.conf',
          mode    => '0644',
          require => File['splunk-home'],
          notify  => Service[splunk],
          alias   => 'splunk-web',
      }

    file { "${::splunk::splunklocal}/ui-prefs.conf":
          owner   => $::splunk::splunk_user,
          group   => $::splunk::splunk_user,
          mode    => '0644',
          content => "# DO NOT EDIT -- managed by Puppet
  [default]
  dispatch.earliest_time = @d
  dispatch.latest_time = now
  ",
          notify  => Service['splunk']
      }

      file { "${::splunk::splunklocal}/limits.conf":
          owner   => $::splunk::splunk_user,
          group   => $::splunk::splunk_user,
          mode    => '0644',
          content => "# DO NOT EDIT -- managed by Puppet
  [subsearch]
  maxout = 15000
  maxtime = 600
  ttl = 1200

  [search]
  dispatch_dir_warning_size = 3000
  ",
          notify  => Service[splunk]
      }
  } else {

  }

}
