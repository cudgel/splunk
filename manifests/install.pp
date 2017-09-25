class splunk::install($type=$type)
{
  $sourcepart      = $::splunk::sourcepart
  $current_version = $::splunk::current_version
  $new_version     = $::splunk::new_version
  $splunkos        = $::splunk::splunkos
  $splunkarch      = $::splunk::splunkarch
  $splunkhome      = $::splunk::splunkhome
  $my_perms        = "${::splunk::splunk_user}:${::splunk::splunk_group}"
  $cacert          = $::splunk::params::cacert
  $privkey         = $::splunk::params::privkey
  $servercert      = $::splunk::params::servercert
  $webcert         = $::splunk::params::webcert
  $managesecret    = $::splunk::params::managesecret

  if $type != 'forwarder' {
    file { $splunkhome:
      ensure => directory,
      owner  => $::splunk::splunk_user,
      group  => $::splunk::splunk_group,
      mode   => '0750'
    }
  }

  # begin version change
  if $new_version != $current_version {

    if $current_version != undef {
      $apppart   = "${sourcepart}-${current_version}-${splunkos}-${splunkarch}"
      $oldsource = "${apppart}.${::splunk::splunkext}"

      file { "${::splunk::install_path}/${oldsource}":
        ensure => absent
      }
    }

    if versioncmp($new_version, $current_version) > 0 {

      splunk::fetch{ 'sourcefile':
        splunksource => $::splunk::splunksource,
        type         => $type
      }

      $stopcmd = 'splunk stop'
      $startcmd = 'splunk start --accept-license --answer-yes --no-prompt'

      exec { 'unpackSplunk':
        command   => "${::splunk::params::tarcmd} ${::splunk::splunksource}",
        path      => "${::splunk::splunkhome}/bin:/bin:/usr/bin:",
        cwd       => $::splunk::install_path,
        subscribe => File["${::splunk::install_path}/${::splunk::splunksource}"],
        timeout   => 600,
        unless    => "test -e ${::splunk::splunkhome}/${::splunk::manifest}",
        creates   => "${::splunk::splunkhome}/${::splunk::manifest}",
        user      => $::splunk::splunk_user,
        group     => $::splunk::splunk_group
      }

      exec { 'firstStart':
        command     => "${stopcmd}; ${startcmd}",
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
    }

  } # end new version

  file { "${::splunk::splunkhome}/etc/splunk-launch.conf":
    owner   => $::splunk::splunk_user,
    group   => $::splunk::splunk_group,
    content => template("${module_name}/splunk-launch.conf.erb"),
    notify  => Service[splunk]
  }

  if $cacert != 'cacert.pem' {
    file { "${::splunk::splunkhome}/etc/auth/${cacert}":
      owner  => $::splunk::splunk_user,
      group  => $::splunk::splunk_group,
      mode   => '0640',
      source => "puppet:///splunk_files/auth/${cacert}",
      notify => Service[splunk]
    }
  }

  if $privkey != 'privkey.pem' {
    file { "${::splunk::splunkhome}/etc/auth/splunkweb/${privkey}":
      owner  => $::splunk::splunk_user,
      group  => $::splunk::splunk_group,
      mode   => '0640',
      source => "puppet:///splunk_files/auth/splunkweb/${privkey}",
      notify => Service[splunk]
    }
  }

  if $servercert != 'server.pem' {
    file { "${::splunk::splunkhome}/etc/auth/${servercert}":
      owner  => $::splunk::splunk_user,
      group  => $::splunk::splunk_group,
      mode   => '0640',
      source => "puppet:///splunk_files/auth/${servercert}",
      notify => Service[splunk]
    }
  }

  if $webcert != 'cert.pem' {
    file { "${::splunk::splunkhome}/etc/auth/splunkweb/${webcert}":
      owner  => $::splunk::splunk_user,
      group  => $::splunk::splunk_group,
      mode   => '0640',
      source => "puppet:///splunk_files/auth/splunkweb/${webcert}",
      notify => Service[splunk]
    }
  }

  if $managesecret == true {
    file { "${::splunk::splunkhome}/etc/splunk.secret":
      ensure => absent
    }

    file { "${::splunk::splunkhome}/etc/auth/splunk.secret":
      owner  => $::splunk::splunk_user,
      group  => $::splunk::splunk_group,
      mode   => '0640',
      source => 'puppet:///splunk_files/splunk.secret',
      notify => Service[splunk]
    }
  }

  file { "${::splunk::local_path}/inputs.d":
    ensure => 'directory',
    mode   => '0750',
    owner  => $::splunk::splunk_user,
    group  => $::splunk::splunk_group,
  }

  file { "${::splunk::local_path}/inputs.d/000_default":
    owner   => $::splunk::splunk_user,
    group   => $::splunk::splunk_group,
    require => File["${::splunk::local_path}/inputs.d"],
    content => template("${module_name}/default_inputs.erb")
  }

  if $type != 'forwarder' {

    if $type != 'indexer' {
      file { "${::splunk::local_path}/outputs.d":
        ensure => 'directory',
        mode   => '0750',
        owner  => $::splunk::splunk_user,
        group  => $::splunk::splunk_group,
      }

      file { "${::splunk::local_path}/outputs.d/000_default":
        owner   => $::splunk::splunk_user,
        group   => $::splunk::splunk_group,
        content => template("${module_name}/outputs.erb"),
        require => File["${::splunk::local_path}/outputs.d"],
        notify  => Exec['update-outputs']
      }
    }

    file { "${::splunk::local_path}/server.d":
      ensure => 'directory',
      mode   => '0750',
      owner  => $::splunk::splunk_user,
      group  => $::splunk::splunk_group,
    }

    file { "${::splunk::local_path}/server.d/000_default":
      ensure => absent
    }

    file { "${::splunk::local_path}/server.d/000_header":
      owner   => $::splunk::splunk_user,
      group   => $::splunk::splunk_group,
      require => File["${::splunk::local_path}/server.d"],
      content => '# DO NOT EDIT -- Managed by Puppet',
      notify  => Exec['update-server']
    }

    file { "${::splunk::local_path}/server.d/001_license":
      owner   => $::splunk::splunk_user,
      group   => $::splunk::splunk_group,
      require => File["${::splunk::local_path}/server.d"],
      content => template("${module_name}/license.erb")
    }

    file { "${::splunk::local_path}/server.d/999_ixclustering":
      ensure => absent
    }

    file { "${::splunk::local_path}/server.d/998_ixclustering":
      ensure => absent
    }

    file { "${::splunk::local_path}/server.d/997_ixclustering":
      owner   => $::splunk::splunk_user,
      group   => $::splunk::splunk_group,
      require => File["${::splunk::local_path}/server.d"],
      content => template("${module_name}/ixclustering.erb"),
      notify  => Exec['update-server']
    }

    file { "${::splunk::local_path}/server.d/998_ssl":
      owner   => $::splunk::splunk_user,
      group   => $::splunk::splunk_group,
      require => File["${::splunk::local_path}/server.d"],
      content => template("${module_name}/ssl_server.erb"),
      notify  => Exec['update-server']
    }

    file { "${::splunk::local_path}/server.d/999_default":
      owner   => $::splunk::splunk_user,
      group   => $::splunk::splunk_group,
      require => File["${::splunk::local_path}/server.d"],
      content => template("${module_name}/default_server.erb"),
      notify  => Exec['update-server']
    }

    file { "${::splunk::local_path}/web.conf":
      owner   => $::splunk::splunk_user,
      group   => $::splunk::splunk_user,
      content => template("${module_name}/web.conf.erb"),
      notify  => Service[splunk],
      alias   => 'splunk-web'
    }

    if $type == 'indexer' {

      file { "${::splunk::local_path}/inputs.d/999_splunktcp":
        owner   => $::splunk::splunk_user,
        group   => $::splunk::splunk_group,
        content => template("${module_name}/splunktcp.erb"),
        notify  => Exec['update-inputs']
      }

      file { "${::splunk::local_path}/server.d/995_replication":
        owner   => $::splunk::splunk_user,
        group   => $::splunk::splunk_group,
        require => File["${::splunk::local_path}/server.d"],
        content => template("${module_name}/replication.erb"),
        notify  => Exec['update-server']
      }

    }

    if $type == 'search' {

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

      file { "${::splunk::local_path}/default-mode.conf":
        owner   => $::splunk::splunk_user,
        group   => $::splunk::splunk_user,
        content => template("${module_name}/default-mode.conf.erb"),
        notify  => Service[splunk],
        alias   => 'splunk-mode'
      }

      file { "${::splunk::local_path}/alert_actions.conf":
        owner   => $::splunk::splunk_user,
        group   => $::splunk::splunk_user,
        content => template("${module_name}/alert_actions.conf.erb"),
        notify  => Service[splunk],
        alias   => 'alert-actions'
      }

      file { "${::splunk::local_path}/ui-prefs.conf":
        owner   => $::splunk::splunk_user,
        group   => $::splunk::splunk_user,
        content => template("${module_name}/ui-prefs.conf.erb"),
        notify  => Service['splunk']
      }

      file { "${::splunk::local_path}/limits.conf":
        owner   => $::splunk::splunk_user,
        group   => $::splunk::splunk_user,
        content => template("${module_name}/limits.conf.erb"),
        notify  => Service[splunk]
      }

      file { "${::splunk::local_path}/server.d/998_shclustering":
        ensure => absent
      }

      file { "${::splunk::local_path}/server.d/997_shclustering":
        ensure => absent
      }

      file { "${::splunk::local_path}/server.d/996_shclustering":
        owner   => $::splunk::splunk_user,
        group   => $::splunk::splunk_group,
        require => File["${::splunk::local_path}/server.d"],
        content => template("${module_name}/shclustering.erb"),
        notify  => Exec['update-server']
      }

      file { "${::splunk::local_path}/server.d/995_replication":
        owner   => $::splunk::splunk_user,
        group   => $::splunk::splunk_group,
        require => File["${::splunk::local_path}/server.d"],
        content => template("${module_name}/replication.erb"),
        notify  => Exec['update-server']
      }
    }
  }

}
