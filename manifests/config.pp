# == Class: splunk::config
#
# This class manages system/local config files, certificates (if defined in hiera and
# served via puppet fileserver), and service installation.
#
# === Examples
#
#  class { splunk::config: type => 'forwarder' }
#
# === Authors
#
# Christopher Caldwell <caldwell@gwu.edu>
#
# === Copyright
#
# Copyright 2017 Christopher Caldwell
#
class splunk::config
{
  $type              = $::splunk::type
  # splunk user home dir from fact
  $splunk_home       = $::splunk::splunk_home
  $install_path      = $::splunk::install_path
  # where splunk is installed
  $splunkdir         = $::splunk::splunkdir
  $splunk_local      = "${splunkdir}/etc/system/local"
  $splunk_user       = $::splunk::splunk_user
  $splunk_group      = $::splunk::splunk_group
  $my_perms          = "${::splunk_user}:${::splunk_group}"
  $cacert            = $::splunk::params::cacert
  $privkey           = $::splunk::params::privkey
  $servercert        = $::splunk::params::servercert
  $webcert           = $::splunk::params::webcert
  $managesecret      = $::splunk::params::managesecret
  $adminpass         = $::splunk::params::adminpass
  $id                = $::splunk::params::shcluster_id
  $confdeploy        = $::splunk::params::search_deploy
  $repl_port         = $::splunk::params::repl_port
  $repl_count        = $::splunk::params::repl_count
  $shcluster_id      = $::splunk::shcluster_id
  $shcluster_mode    = $::splunk::params::shcluster_mode
  $shcluster_label   = $::splunk::params::shcluster_label
  $is_captain        = $::splunk::params::is_captain
  $shcluster_members = $::splunk::params::shcluster_members
  $symmkey           = $::splunk::params::symmkey

  if $type != 'forwarder' {
    file { $splunkdir:
      ensure => directory,
      owner  => $splunk_user,
      group  => $splunk_group,
      mode   => '0750'
    }
  }

  $bashrc = "
SPLUNK_HOME=${splunkdir}
export SPLUNK_HOME
PATH=\$SPLUNK_HOME/bin:\$PATH
export PATH
  "

  file { "${splunk_home}/.bashrc.custom":
    owner   => $splunk_user,
    group   => $splunk_group,
    content => $bashrc
  }

  if ($type == 'forwarder') and ($adminpass != 'changeme')  {
    exec { 'changeAdminPass':
      command => "splunk edit user admin -password ${adminpass} -auth admin:changeme && touch ${splunkdir}/.admin_pass",
      path    => "${splunkdir}/bin:/bin:/usr/bin:",
      unless  => "test -e ${splunkdir}/.admin_pass",
      creates => "${splunkdir}/.admin_pass"
    }
  }

  exec { 'test_for_splunk':
    command => "test -d ${splunkdir}/etc",
    path    => "${splunkdir}/bin:/bin:/usr/bin:",
    cwd     => $install_path,
    user    => $splunk_user,
    group   => $splunk_group,
    unless  => "test -d ${splunkdir}/etc"
  }

  file_line { 'splunk-start':
    path    => '/etc/init.d/splunk',
    line    => "  su - ${splunk_user} -c \'\"${splunkdir}/bin/splunk\" start --no-prompt --answer-yes\'",
    match   => "^\ \ \"${splunkdir}/bin/splunk\" start",
    require => Exec['test_for_splunk']
  }

  file_line { 'splunk-stop':
    path    => '/etc/init.d/splunk',
    line    => "  su - ${splunk_user} -c \'\"${splunkdir}/bin/splunk\" stop\'",
    match   => "^\ \ \"${splunkdir}/bin/splunk\" stop",
    require => Exec['test_for_splunk']
  }

  file_line { 'splunk-restart':
    path    => '/etc/init.d/splunk',
    line    => "  su - ${splunk_user} -c \'\"${splunkdir}/bin/splunk\" restart\'",
    match   => "^\ \ \"${splunkdir}/bin/splunk\" restart",
    require => Exec['test_for_splunk']
  }

  file_line { 'splunk-status':
    path    => '/etc/init.d/splunk',
    line    => "  su - ${splunk_user} -c \'\"${splunkdir}/bin/splunk\" status\'",
    match   => "^\ \ \"${splunkdir}/bin/splunk\" status",
    require => Exec['test_for_splunk']
  }

  file { "${splunkdir}/etc/splunk-launch.conf":
    content => template("${module_name}/splunk-launch.conf.erb"),
    owner   => $splunk_user,
    group   => $splunk_group,
    notify  => Service[splunk],
    require => Exec['test_for_splunk']
  }

  if $cacert != 'cacert.pem' {
    file { "${splunkdir}/etc/auth/${cacert}":
      source  => "puppet:///splunk_files/auth/${cacert}",
      owner   => $splunk_user,
      group   => $splunk_group,
      mode    => '0640',
      notify  => Service[splunk],
      require => Exec['test_for_splunk']
    }
  }

  if $privkey != 'privkey.pem' {
    file { "${splunkdir}/etc/auth/splunkweb/${privkey}":
      source  => "puppet:///splunk_files/auth/splunkweb/${privkey}",
      owner   => $splunk_user,
      group   => $splunk_group,
      mode    => '0640',
      notify  => Service[splunk],
      require => Exec['test_for_splunk']
    }
  }

  if $servercert != 'server.pem' {
    file { "${splunkdir}/etc/auth/${servercert}":
      source  => "puppet:///splunk_files/auth/${servercert}",
      owner   => $splunk_user,
      group   => $splunk_group,
      mode    => '0640',
      notify  => Service[splunk],
      require => Exec['test_for_splunk']
    }
  }

  if $webcert != 'cert.pem' {
    file { "${splunkdir}/etc/auth/splunkweb/${webcert}":
      source  => "puppet:///splunk_files/auth/splunkweb/${webcert}",
      owner   => $splunk_user,
      group   => $splunk_group,
      mode    => '0640',
      notify  => Service[splunk],
      require => Exec['test_for_splunk']
    }
  }

  if $managesecret == true {
    file { "${splunkdir}/etc/splunk.secret":
      ensure => absent
    }

    file { "${splunkdir}/etc/auth/splunk.secret":
      source  => 'puppet:///splunk_files/splunk.secret',
      owner   => $splunk_user,
      group   => $splunk_group,
      mode    => '0640',
      notify  => Service[splunk],
      require => Exec['test_for_splunk']
    }
  }

  file { "${splunkdir}/etc/apps":
    ensure  => 'directory',
    mode    => '0750',
    owner   => $splunk_user,
    group   => $splunk_group,
    require => Exec['test_for_splunk']
  }

  file { $splunkdir:
    ensure  => 'directory',
    mode    => '0755',
    owner   => $splunk_user,
    group   => $splunk_group,
    require => Exec['test_for_splunk']
  }

  file { "${splunk_local}/inputs.d":
    ensure  => 'directory',
    mode    => '0750',
    owner   => $splunk_user,
    group   => $splunk_group,
    require => Exec['test_for_splunk']
  }

  file { "${splunk_local}/inputs.d/000_default":
    content => template("${module_name}/inputs.d/default_inputs.erb"),
    owner   => $splunk_user,
    group   => $splunk_group,
    require => File["${splunk_local}/inputs.d"]
  }

  file { "${splunk_local}/inputs.d/000_splunkssl":
    content => template("${module_name}/inputs.d/ssl.erb"),
    owner   => $splunk_user,
    group   => $splunk_group,
    require => File["${splunk_local}/inputs.d"],
    notify  => Exec['update-inputs']
  }

  if $type != 'forwarder' {

    if ($type != 'indexer') and ($type != 'standalone') {
      file { "${splunk_local}/outputs.d":
        ensure  => 'directory',
        mode    => '0750',
        owner   => $splunk_user,
        group   => $splunk_group,
        require => Exec['test_for_splunk']
      }

      file { "${splunk_local}/outputs.d/000_default":
        content => template("${module_name}/outputs.d/outputs.erb"),
        owner   => $splunk_user,
        group   => $splunk_group,
        require => File["${splunk_local}/outputs.d"],
        notify  => Exec['update-outputs']
      }
    }

    file { "${splunk_local}/server.d":
      ensure  => 'directory',
      mode    => '0750',
      owner   => $splunk_user,
      group   => $splunk_group,
      require => Exec['test_for_splunk']
    }

    file { "${splunk_local}/server.d/000_default":
      ensure => absent
    }

    file { "${splunk_local}/server.d/000_header":
      content => '# DO NOT EDIT -- Managed by Puppet',
      owner   => $splunk_user,
      group   => $splunk_group,
      require => File["${splunk_local}/server.d"],
      notify  => Exec['update-server']
    }

    file { "${splunk_local}/server.d/001_license":
      content => template("${module_name}/server.d/license.erb"),
      owner   => $splunk_user,
      group   => $splunk_group,
      require => File["${splunk_local}/server.d"]
    }

    file { "${splunk_local}/server.d/997_ixclustering":
      content => template("${module_name}/server.d/ixclustering.erb"),
      owner   => $splunk_user,
      group   => $splunk_group,
      require => File["${splunk_local}/server.d"],
      notify  => Exec['update-server']
    }

    file { "${splunk_local}/server.d/998_ssl":
      content => template("${module_name}/server.d/ssl_server.erb"),
      owner   => $splunk_user,
      group   => $splunk_group,
      require => File["${splunk_local}/server.d"],
      notify  => Exec['update-server']
    }

    file { "${splunk_local}/server.d/999_default":
      content => template("${module_name}/server.d/default_server.erb"),
      owner   => $splunk_user,
      group   => $splunk_group,
      require => File["${splunk_local}/server.d"],
      notify  => Exec['update-server']
    }

    file { "${splunk_local}/web.conf":
      content => template("${module_name}/web.conf.erb"),
      alias   => 'splunk-web',
      owner   => $splunk_user,
      group   => $splunk_user,
      require => Exec['test_for_splunk'],
      notify  => Service[splunk]
    }

    if $type == 'indexer' {

      file { "${splunk_local}/inputs.d/999_splunktcp":
        content => template("${module_name}/inputs.d/splunktcp.erb"),
        owner   => $splunk_user,
        group   => $splunk_group,
        require => File["${splunk_local}/inputs.d"],
        notify  => Exec['update-inputs']
      }

      file { "${splunk_local}/server.d/995_replication":
        content => template("${module_name}/server.d/replication.erb"),
        owner   => $splunk_user,
        group   => $splunk_group,
        require => File["${splunk_local}/server.d"],
        notify  => Exec['update-server']
      }

    }

    if ($type == 'search') or ($type == 'standalone') {

      if $shcluster_mode == 'peer' {

        unless $shcluster_id =~ /\w{8}-(?:\w{4}-){3}\w{12}/ {

          exec { 'join_cluster':
            command     => "splunk init shcluster-config -auth admin:changme -mgmt_uri https://${::fqdn}:8089 -replication_port ${repl_port} -replication_factor ${repl_count} -conf_deploy_fetch_url https://${confdeploy} -secret ${symmkey} -shcluster_label ${shcluster_label} && splunk restart",
            environment => "SPLUNK_HOME=${splunkdir}",
            path        => "${splunkdir}/bin:/bin:/usr/bin:",
            cwd         => $splunkdir,
            timeout     => 600,
            user        => $splunk_user,
            group       => $splunk_group,
            onlyif      => 'splunk status',
            require     => Exec['test_for_splunk']
          }

          if $is_captain == true {
            $shcluster_members.each |String $member| {
              $servers_list = "${servers_list}.${member}:8089"
            }

            exec { 'bootstrap_cluster':
              command     => "splunk bootstrap shcluster-captain -servers_list \"${servers_list}\" -auth admin:changme",
              environment => "SPLUNK_HOME=${splunkdir}",
              path        => "${splunkdir}/bin:/bin:/usr/bin:",
              cwd         => $splunkdir,
              user        => $splunk_user,
              group       => $splunk_group,
              onlyif      => 'splunk status',
              require     => Exec['test_for_splunk']
            }
          }

        }
      }

      if $::osfamily == 'RedHat' {
        # support PDF Report Server
        package { [
          'xorg-x11-server-Xvfb',
          'liberation-mono-fonts',
          'liberation-sans-fonts',
          'liberation-serif-fonts' ]:
          ensure => installed
        }
      } elsif $::osfamily == 'Debian' {
        package { [
          'xvfb',
          'fonts-liberation' ]:
          ensure => installed
        }
      }

      file { "${splunk_local}/default-mode.conf":
        alias   => 'splunk-mode',
        content => template("${module_name}/default-mode.conf.erb"),
        owner   => $splunk_user,
        group   => $splunk_user,
        notify  => Service[splunk],
        require => Exec['test_for_splunk']
      }

      file { "${splunk_local}/alert_actions.conf":
        alias   => 'alert-actions',
        content => template("${module_name}/alert_actions.conf.erb"),
        owner   => $splunk_user,
        group   => $splunk_user,
        notify  => Service[splunk],
        require => Exec['test_for_splunk']
      }

      file { "${splunk_local}/ui-prefs.conf":
        content => template("${module_name}/ui-prefs.conf.erb"),
        owner   => $splunk_user,
        group   => $splunk_user,
        notify  => Service['splunk'],
        require => Exec['test_for_splunk']
      }

      file { "${splunk_local}/limits.conf":
        content => template("${module_name}/limits.conf.erb"),
        owner   => $splunk_user,
        group   => $splunk_user,
        notify  => Service[splunk],
        require => Exec['test_for_splunk']
      }

      if ($shcluster_id =~ /\w{8}-(?:\w{4}-){3}\w{12}/) or ($shcluster_mode == 'deployer') {
        # if clustering has already been set up, manage configs
        file { "${splunk_local}/server.d/996_shclustering":
          content => template("${module_name}/server.d/shclustering.erb"),
          owner   => $splunk_user,
          group   => $splunk_group,
          require => File["${splunk_local}/server.d"],
          notify  => Exec['update-server']
        }

        file { "${splunk_local}/server.d/995_replication":
          content => template("${module_name}/server.d/replication.erb"),
          owner   => $splunk_user,
          group   => $splunk_group,
          require => File["${splunk_local}/server.d"],
          notify  => Exec['update-server']
        }
      } else {
        # remove any fragments from unconfigure shc member or standalone
        file { "${splunk_local}/server.d/996_shclustering":
          ensure => absent,
          notify => Exec['update-server']
        }

        file { "${splunk_local}/server.d/995_replication":
          ensure => absent,
          notify => Exec['update-server']
        }
      }
    }
  }

}
