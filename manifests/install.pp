# == Class: splunk::install
#
# This class maintains the installation of Splunk, installing a new Splunk
# instance or upgrading an existing one. Currently it tries to fetch the
# specified version of either splunk or splunkforwarder (depending on the
# type of install) from splunk.com or a hiera-defined server.
# Manages system/local config files, certificates (if defined in hiera and
# served via puppet fileserver), and service installation.
#
# === Examples
#
#  class { splunk::install: type => 'forwarder' }
#
# === Authors
#
# Christopher Caldwell <author@domain.com>
#
# === Copyright
#
# Copyright 2017 Christopher Caldwell
#
class splunk::install($type=$type)
{
  # splunk user home dir from fact
  $splunk_home       = $::splunk_home
  $sourcepart        = $::splunk::sourcepart
  # currently installed version from fact
  $current_version   = $::splunk::current_version
  # version to be installed
  $new_version       = $::splunk::new_version
  $maj_version       = $::splunk::version
  $splunkos          = $::splunk::splunkos
  $splunkarch        = $::splunk::splunkarch
  $source            = $::splunk::params::source
  $splunkdir         = $::splunk::splunkdir
  $my_perms          = "${::splunk::splunk_user}:${::splunk::splunk_group}"
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
      owner  => $::splunk::splunk_user,
      group  => $::splunk::splunk_group,
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
    owner   => $::splunk::splunk_user,
    group   => $::splunk::splunk_group,
    require => User[$::splunk::splunk_user],
    content => $bashrc
  }


  # begin version change
  # because the legacy fact does not represent splunk version as
  # version-release, we cut the version from the string.
  $cut_version = regsubst($current_version, '^(\d+\.\d+\.\d+)-.*$', '\1')

  if $maj_version != $cut_version {

    if versioncmp($maj_version, $cut_version) > 0 {

      if $current_version != undef {
        $apppart   = "${sourcepart}-${current_version}-${splunkos}-${splunkarch}"
        $oldsource = "${apppart}.${::splunk::splunkext}"

        file { "${::splunk::install_path}/${oldsource}":
          ensure => absent
        }
      } else {
        $new_install = true
      }

      splunk::fetch{ 'sourcefile':
        splunk_bundle => $::splunk::splunk_bundle,
        type          => $type,
        source        => $source
      }

      $stopcmd  = 'splunk stop'
      $startcmd = 'splunk start --accept-license --answer-yes --no-prompt'

      exec { 'unpackSplunk':
        before    => Exec['test_for_splunk'],
        command   => "${::splunk::params::tarcmd} ${::splunk::splunk_bundle}",
        path      => "${::splunk::splunkdir}/bin:/bin:/usr/bin:",
        cwd       => $::splunk::install_path,
        subscribe => File["${::splunk::install_path}/${::splunk::splunk_bundle}"],
        timeout   => 600,
        unless    => "test -e ${::splunk::splunkdir}/${::splunk::manifest}",
        onlyif    => "test -s ${::splunk::splunk_bundle} \
        && test -d ${::splunk::splunkdir}",
        creates   => "${::splunk::splunkdir}/${::splunk::manifest}",
        user      => $::splunk::splunk_user,
        group     => $::splunk::splunk_group
      }

      exec { 'serviceStart':
        command     => "${stopcmd}; ${startcmd}",
        path        => "${::splunk::splunkdir}/bin:/bin:/usr/bin:",
        subscribe   => Exec['unpackSplunk'],
        refreshonly => true,
        user        => $::splunk::splunk_user,
        group       => $::splunk::splunk_group
      }

      exec { 'installSplunkService':
        command   => 'splunk enable boot-start',
        path      => "${::splunk::splunkdir}/bin:/bin:/usr/bin:",
        subscribe => Exec['unpackSplunk'],
        unless    => 'test -e /etc/init.d/splunk',
        creates   => '/etc/init.d/splunk'
      }

    }

  # end version change
  }

  if ($type == 'forwarder') and ($adminpass != 'changeme')  {
    exec { 'changeAdminPass':
      command => "splunk edit user admin -password ${adminpass} -auth admin:changeme && touch ${::splunk::splunkdir}/.admin_pass",
      path    => "${::splunk::splunkdir}/bin:/bin:/usr/bin:",
      unless  => "test -e ${::splunk::splunkdir}/.admin_pass",
      creates => "${::splunk::splunkdir}/.admin_pass"
    }
  }

  exec { 'test_for_splunk':
    command => "test -d ${::splunk::splunkdir}/etc",
    path    => "${::splunk::splunkdir}/bin:/bin:/usr/bin:",
    cwd     => $::splunk::install_path,
    user    => $::splunk::splunk_user,
    unless  => "test -d ${::splunk::splunkdir}/etc",
    group   => $::splunk::splunk_group
  }


file_line { 'splunk-start':
  path    => '/etc/init.d/splunk',
  line    => "  su - ${::splunk::splunk_user} -c \'\"${::splunk::splunkdir}/bin/splunk\" start --no-prompt --answer-yes\'",
  match   => "^\ \ \"${::splunk::splunkdir}/bin/splunk\" start",
  require => Exec['test_for_splunk']
}

file_line { 'splunk-stop':
  path    => '/etc/init.d/splunk',
  line    => "  su - ${::splunk::splunk_user} -c \'\"${::splunk::splunkdir}/bin/splunk\" stop\'",
  match   => "^\ \ \"${::splunk::splunkdir}/bin/splunk\" stop",
  require => Exec['test_for_splunk']
}

file_line { 'splunk-restart':
  path    => '/etc/init.d/splunk',
  line    => "  su - ${::splunk::splunk_user} -c \'\"${::splunk::splunkdir}/bin/splunk\" restart\'",
  match   => "^\ \ \"${::splunk::splunkdir}/bin/splunk\" restart",
  require => Exec['test_for_splunk']
}

file_line { 'splunk-status':
  path    => '/etc/init.d/splunk',
  line    => "  su - ${::splunk::splunk_user} -c \'\"${::splunk::splunkdir}/bin/splunk\" status\'",
  match   => "^\ \ \"${::splunk::splunkdir}/bin/splunk\" status",
  require => Exec['test_for_splunk']
}

  file { "${::splunk::splunkdir}/etc/splunk-launch.conf":
    owner   => $::splunk::splunk_user,
    group   => $::splunk::splunk_group,
    content => template("${module_name}/splunk-launch.conf.erb"),
    notify  => Service[splunk],
    require => Exec['test_for_splunk']
  }

  if $cacert != 'cacert.pem' {
    file { "${::splunk::splunkdir}/etc/auth/${cacert}":
      owner   => $::splunk::splunk_user,
      group   => $::splunk::splunk_group,
      mode    => '0640',
      source  => "puppet:///splunk_files/auth/${cacert}",
      notify  => Service[splunk],
      require => Exec['test_for_splunk']
    }
  }

  if $privkey != 'privkey.pem' {
    file { "${::splunk::splunkdir}/etc/auth/splunkweb/${privkey}":
      owner   => $::splunk::splunk_user,
      group   => $::splunk::splunk_group,
      mode    => '0640',
      source  => "puppet:///splunk_files/auth/splunkweb/${privkey}",
      notify  => Service[splunk],
      require => Exec['test_for_splunk']
    }
  }

  if $servercert != 'server.pem' {
    file { "${::splunk::splunkdir}/etc/auth/${servercert}":
      owner   => $::splunk::splunk_user,
      group   => $::splunk::splunk_group,
      mode    => '0640',
      source  => "puppet:///splunk_files/auth/${servercert}",
      notify  => Service[splunk],
      require => Exec['test_for_splunk']
    }
  }

  if $webcert != 'cert.pem' {
    file { "${::splunk::splunkdir}/etc/auth/splunkweb/${webcert}":
      owner   => $::splunk::splunk_user,
      group   => $::splunk::splunk_group,
      mode    => '0640',
      source  => "puppet:///splunk_files/auth/splunkweb/${webcert}",
      notify  => Service[splunk],
      require => Exec['test_for_splunk']
    }
  }

  if $managesecret == true {
    file { "${::splunk::splunkdir}/etc/splunk.secret":
      ensure => absent
    }

    file { "${::splunk::splunkdir}/etc/auth/splunk.secret":
      owner   => $::splunk::splunk_user,
      group   => $::splunk::splunk_group,
      mode    => '0640',
      source  => 'puppet:///splunk_files/splunk.secret',
      notify  => Service[splunk],
      require => Exec['test_for_splunk']
    }
  }

  file { "${::splunk::local_path}/inputs.d":
    ensure  => 'directory',
    mode    => '0750',
    owner   => $::splunk::splunk_user,
    group   => $::splunk::splunk_group,
    require => Exec['test_for_splunk']
  }

  file { "${::splunk::local_path}/inputs.d/000_default":
    owner   => $::splunk::splunk_user,
    group   => $::splunk::splunk_group,
    require => File["${::splunk::local_path}/inputs.d"],
    content => template("${module_name}/inputs.d/default_inputs.erb")
  }

  if $type != 'forwarder' {

    if ($type != 'indexer') and ($type != 'standalone') {
      file { "${::splunk::local_path}/outputs.d":
        ensure  => 'directory',
        mode    => '0750',
        owner   => $::splunk::splunk_user,
        group   => $::splunk::splunk_group,
        require => Exec['test_for_splunk']
      }

      file { "${::splunk::local_path}/outputs.d/000_default":
        owner   => $::splunk::splunk_user,
        group   => $::splunk::splunk_group,
        content => template("${module_name}/outputs.d/outputs.erb"),
        require => File["${::splunk::local_path}/outputs.d"],
        notify  => Exec['update-outputs']
      }
    }

    file { "${::splunk::local_path}/server.d":
      ensure  => 'directory',
      mode    => '0750',
      owner   => $::splunk::splunk_user,
      group   => $::splunk::splunk_group,
      require => Exec['test_for_splunk']
    }

    file { "${::splunk::local_path}/server.d/000_default":
      ensure => absent
    }

    file { "${::splunk::local_path}/server.d/000_header":
      owner   => $::splunk::splunk_user,
      group   => $::splunk::splunk_group,
      content => '# DO NOT EDIT -- Managed by Puppet',
      require => File["${::splunk::local_path}/server.d"],
      notify  => Exec['update-server']
    }

    file { "${::splunk::local_path}/server.d/001_license":
      owner   => $::splunk::splunk_user,
      group   => $::splunk::splunk_group,
      content => template("${module_name}/server.d/license.erb"),
      require => File["${::splunk::local_path}/server.d"]
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
      content => template("${module_name}/server.d/ixclustering.erb"),
      require => File["${::splunk::local_path}/server.d"],
      notify  => Exec['update-server']
    }

    file { "${::splunk::local_path}/server.d/998_ssl":
      owner   => $::splunk::splunk_user,
      group   => $::splunk::splunk_group,
      content => template("${module_name}/server.d/ssl_server.erb"),
      require => File["${::splunk::local_path}/server.d"],
      notify  => Exec['update-server']
    }

    file { "${::splunk::local_path}/server.d/999_default":
      owner   => $::splunk::splunk_user,
      group   => $::splunk::splunk_group,
      content => template("${module_name}/server.d/default_server.erb"),
      require => File["${::splunk::local_path}/server.d"],
      notify  => Exec['update-server']
    }

    file { "${::splunk::local_path}/web.conf":
      owner   => $::splunk::splunk_user,
      group   => $::splunk::splunk_user,
      content => template("${module_name}/web.conf.erb"),
      notify  => Service[splunk],
      alias   => 'splunk-web',
      require => Exec['test_for_splunk']
    }

    if $type == 'indexer' {

      file { "${::splunk::local_path}/inputs.d/999_splunktcp":
        owner   => $::splunk::splunk_user,
        group   => $::splunk::splunk_group,
        content => template("${module_name}/inputs.d/splunktcp.erb"),
        require => File["${::splunk::local_path}/inputs.d"],
        notify  => Exec['update-inputs']
      }

      file { "${::splunk::local_path}/server.d/995_replication":
        owner   => $::splunk::splunk_user,
        group   => $::splunk::splunk_group,
        content => template("${module_name}/server.d/replication.erb"),
        require => File["${::splunk::local_path}/server.d"],
        notify  => Exec['update-server']
      }

    }

    if ($type == 'search') or ($type == 'standalone') {

      if $shcluster_mode == 'peer' {
        unless $shcluster_id =~ /\w{8}-(?:\w{4}-){3}\w{12}/ {
          exec { 'changedAdminPass_do':
            command => 'splunk edit user admin -password changed -auth admin:changeme',
            user    => $::splunk::splunk_user,
            group   => $::splunk::splunk_group,
            cwd     => $::splunk::install_path,
            path    => "${::splunk::splunkdir}/bin:/bin:/usr/bin:",
            require => [ File["${::splunk::local_path}/server.d"], File["${splunk_home}/.bashrc.custom"] ]
          }

          exec { 'join_cluster':
            command     => "splunk init shcluster-config -auth admin:changed -mgmt_uri https://${::fqdn}:8089 -replication_port ${repl_port} -replication_factor ${repl_count} -conf_deploy_fetch_url https://${confdeploy} -secret ${symmkey} -shcluster_label ${shcluster_label} && splunk restart",
            path        => "${::splunk::splunkdir}/bin:/bin:/usr/bin:",
            cwd         => $::splunk::install_path,
            environment => "SPLUNK_HOME=${::splunk::splunkdir}",
            timeout     => 600,
            user        => $::splunk::splunk_user,
            group       => $::splunk::splunk_group,
            require     => [ Exec['test_for_splunk'], Exec['changedAdminPass_do'] ],
            notify      => Exec['changedAdminPass_undo']
          }

          if $is_captain == true {
            $shcluster_members.each |String $member| {
              $servers_list = "${servers_list}.${member}:8089"
            }

            exec { 'bootstrap_cluster':
              command => "splunk bootstrap shcluster-captain -servers_list \"${servers_list}\" -auth admin:changed",
              path    => "${::splunk::splunkdir}/bin:/bin:/usr/bin:",
              cwd     => $::splunk::install_path,
              user    => $::splunk::splunk_user,
              group   => $::splunk::splunk_group,
              require => [ Exec['test_for_splunk'], Exec['changedAdminPass_do'] ],
              notify  => Exec['changedAdminPass_undo']
            }
          }

          exec { 'changedAdminPass_undo':
            command     => 'splunk edit user admin -password changme -auth admin:changed',
            path        => "${::splunk::splunkdir}/bin:/bin:/usr/bin:",
            cwd         => $::splunk::install_path,
            environment => "SPLUNK_HOME=${::splunk::splunkdir}",
            user        => $::splunk::splunk_user,
            group       => $::splunk::splunk_group,
            require     => [ Exec['test_for_splunk'], Exec['changedAdminPass_do'] ],
            refreshonly => true
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

      file { "${::splunk::local_path}/default-mode.conf":
        owner   => $::splunk::splunk_user,
        group   => $::splunk::splunk_user,
        content => template("${module_name}/default-mode.conf.erb"),
        notify  => Service[splunk],
        alias   => 'splunk-mode',
        require => Exec['test_for_splunk']
      }

      file { "${::splunk::local_path}/alert_actions.conf":
        owner   => $::splunk::splunk_user,
        group   => $::splunk::splunk_user,
        content => template("${module_name}/alert_actions.conf.erb"),
        notify  => Service[splunk],
        alias   => 'alert-actions',
        require => Exec['test_for_splunk']
      }

      file { "${::splunk::local_path}/ui-prefs.conf":
        owner   => $::splunk::splunk_user,
        group   => $::splunk::splunk_user,
        content => template("${module_name}/ui-prefs.conf.erb"),
        notify  => Service['splunk'],
        require => Exec['test_for_splunk']
      }

      file { "${::splunk::local_path}/limits.conf":
        owner   => $::splunk::splunk_user,
        group   => $::splunk::splunk_user,
        content => template("${module_name}/limits.conf.erb"),
        notify  => Service[splunk],
        require => Exec['test_for_splunk']
      }

      if ($shcluster_id =~ /\w{8}-(?:\w{4}-){3}\w{12}/) or ($shcluster_mode == 'deployer') {
        # if clustering has already been set up, manage configs
        file { "${::splunk::local_path}/server.d/996_shclustering":
          owner   => $::splunk::splunk_user,
          group   => $::splunk::splunk_group,
          require => File["${::splunk::local_path}/server.d"],
          content => template("${module_name}/server.d/shclustering.erb"),
          notify  => Exec['update-server']
        }

        file { "${::splunk::local_path}/server.d/995_replication":
          owner   => $::splunk::splunk_user,
          group   => $::splunk::splunk_group,
          require => File["${::splunk::local_path}/server.d"],
          content => template("${module_name}/server.d/replication.erb"),
          notify  => Exec['update-server']
        }
      } else {
        # remove any fragments from unconfigure shc member or standalone
        file { "${::splunk::local_path}/server.d/996_shclustering":
          ensure => absent,
          notify => Exec['update-server']
        }

        file { "${::splunk::local_path}/server.d/995_replication":
          ensure => absent,
          notify => Exec['update-server']
        }
      }
    }
  }

}
