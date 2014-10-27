class splunk::install($type=$type)
{
  $sourcepart      = $::splunk::sourcepart
  $current_version = $::splunk::current_version
  $new_version     = $::splunk::version
  $splunkos        = $::splunk::splunkos
  $splunkarch      = $::splunk::splunkarch

  # begin version change
  if $new_version != $current_version {
    $apppart   = "${sourcepart}-${current_version}-${splunkos}-${splunkarch}"
    $oldsource = "${apppart}.${splunkext}"

    file { "${::splunk::install_path}/${::splunk::oldsource}":
      ensure => absent
    }

    file { "${::splunk::install_path}/${::splunk::splunksource}":
      owner  => $::splunk::splunk_user,
      group  => $::splunk::splunk_group,
      mode   => '0640',
      source => "puppet:///modules/${module_name}/${::splunk::splunksource}",
      notify => Exec['unpackSplunk']
    }

    exec { 'unpackSplunk':
      command   => "${::splunk::params::tarcmd} ${::splunk::splunksource}; \
  chown -RL ${::splunk::splunk_user}:${::splunk::splunk_group} \
  ${::splunk::splunkhome}",
      path      => "${::splunk::splunkhome}/bin:/bin:/usr/bin:",
      cwd       => $::splunk::install_path,
      subscribe => File["${::splunk::install_path}/${::splunk::splunksource}"],
      timeout   => 600,
      unless    => "test -e ${::splunk::splunkhome}/${::splunk::manifest}",
      creates   => "${::splunk::splunkhome}/${::splunk::manifest}"
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
      command   => 'splunk enable boot-start',
      path      => "${::splunk::splunkhome}/bin:/bin:/usr/bin:",
      subscribe => Exec['unpackSplunk'],
      unless    => 'test -e /etc/init.d/splunk',
      creates   => '/etc/init.d/splunk'
    }

  } # end new version

  file { "${::splunk::splunkhome}/etc/splunk-launch.conf":
    owner   => $::splunk::splunk_user,
    group   => $::splunk::splunk_group,
    content => template("${module_name}/splunk-launch.conf.erb"),
    mode    => '0640',
    notify  => Service[splunk]
  }

  file { "${::splunk::local_path}/inputs.d":
    ensure => 'directory',
    owner  => $::splunk::splunk_user,
    group  => $::splunk::splunk_group,
    mode   => '0750'
  }

  file { "${::splunk::local_path}/inputs.d/000_default":
    owner   => $::splunk::splunk_user,
    group   => $::splunk::splunk_group,
    mode    => '0440',
    require => File["${::splunk::local_path}/inputs.d"],
    content => template("${module_name}/default_inputs.erb")
  }

  if $type == 'forwarder' {

    file { "${::splunk::local_path}/outputs.conf":
      owner   => $::splunk::splunk_user,
      group   => $::splunk::splunk_user,
      content => template("${module_name}/outputs.conf.erb"),
      mode    => '0640',
      notify  => Service[splunk],
      alias   => 'splunk-outputs'
    }

  } elsif $type == 'indexer' {

    file { "${::splunk::local_path}/outputs.conf":
      ensure => absent,
      notify => Service[splunk]
    }

    file { "${::splunk::local_path}/web.conf":
      owner   => $::splunk::splunk_user,
      group   => $::splunk::splunk_user,
      content => template("${module_name}/web.conf.erb"),
      mode    => '0640',
      notify  => Service[splunk],
      alias   => 'splunk-web',
    }

    file { "${::splunk::local_path}/inputs.d/999_splunktcp":
      owner   => $::splunk::splunk_user,
      group   => $::splunk::splunk_group,
      mode    => '0440',
      content => template("${module_name}/splunktcp.erb"),
      notify  => Exec['update-inputs']
    }

    file { "${::splunk::local_path}/indexes.d":
      ensure => 'directory',
      owner  => $::splunk::splunk_user,
      group  => $::splunk::splunk_group,
      mode   => '0750'
    }

    file { "${::splunk::local_path}/indexes.d/000_default":
      owner   => $::splunk::splunk_user,
      group   => $::splunk::splunk_group,
      mode    => '0440',
      content => template("${module_name}/volumes.erb")
    }

    $my_index_d = "${::splunk::local_path}/indexes.d/"
    $my_index_c = "${::splunk::local_path}/indexes.conf"
    $my_perms   = "${::splunk::splunk_user}:${::splunk::splunk_group}"

    exec { 'update-indexes':
      command     => "/bin/cat ${my_index_d}/* > ${my_index_c}; \
chown ${my_perms} ${my_index_c}",
      refreshonly => true,
      subscribe   => File["${::splunk::local_path}/indexes.d/000_default"],
      notify      => Service[splunk]
    }

  } elsif $type == 'search' {

    if $::osfamily == 'RedHat' {
    # support PDF Report Server
      package { [
        'xorg-x11-server-Xvfb',
        'liberation-mono-fonts',
        'liberation-sans-fonts',
        'liberation-serif-fonts' ]:
        ensure => installed,
      }
    }

    file { "${::splunk::local_path}/outputs.conf":
      owner   => $::splunk::splunk_user,
      group   => $::splunk::splunk_user,
      content => template("${module_name}/outputs.conf.erb"),
      mode    => '0640',
      notify  => Service[splunk],
      alias   => 'splunk-outputs'
    }

    file { "${::splunk::local_path}/alert_actions.conf":
      owner   => $::splunk::splunk_user,
      group   => $::splunk::splunk_user,
      content => template("${module_name}/alert_actions.conf.erb"),
      mode    => '0640',
      notify  => Service[splunk],
      alias   => 'alert-actions'
    }

    file { "${::splunk::local_path}/web.conf":
      owner   => $::splunk::splunk_user,
      group   => $::splunk::splunk_user,
      content => template("${module_name}/web.conf.erb"),
      mode    => '0640',
      notify  => Service[splunk],
      alias   => 'splunk-web'
    }

    file { "${::splunk::local_path}/ui-prefs.conf":
      owner   => $::splunk::splunk_user,
      group   => $::splunk::splunk_user,
      mode    => '0640',
      content => template("${module_name}/ui-prefs.conf.erb"),
      notify  => Service['splunk']
      }


    file { "${::splunk::local_path}/limits.conf":
      owner   => $::splunk::splunk_user,
      group   => $::splunk::splunk_user,
      mode    => '0640',
      content => template("${module_name}/limits.conf.erb"),
      notify  => Service[splunk]
    }

  }

}
