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
  $splunk_home       = $::splunk::splunk_home
  # where splunk is installed
  $splunkdir         = $::splunk::splunkdir
  $splunk_local      = "${splunkdir}/etc/system/local"
  # splunk or splunkforwarder
  $sourcepart        = $::splunk::sourcepart
  # currently installed version from fact
  $current_version   = $::splunk::current_version
  # new verion from hiera
  $new_version       = $::splunk::new_version
  # x.x.x (minus release)
  $maj_version       = $::splunk::version
  $splunkos          = $::splunk::splunkos
  $splunkarch        = $::splunk::splunkarch
  $splunkext         = $::splunk::splunkext
  $tarcmd            = $::splunk::params::tarcmd
  $manifest          = $::splunk::manifest
  # splunk (web) or fileserver or a custom url
  $source            = $::splunk::params::source
  $splunk_user       = $::splunk::user
  $splunk_group      = $::splunk::group
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
    require => User[$splunk_user],
    content => $bashrc
  }


  # begin version change
  # because the legacy fact does not represent splunk version as
  # version-release, we cut the version from the string.
  $cut_version = regsubst($current_version, '^(\d+\.\d+\.\d+)-.*$', '\1')

  if $maj_version != $cut_version {

    if versioncmp($maj_version, $cut_version) > 0 {

      if $current_version != undef {
        $oldsource = "${sourcepart}-${current_version}-${splunkos}-${splunkarch}.${splunkext}"

        file { "${::splunk::install_path}/${oldsource}":
          ensure => absent
        }
      } else {
        $new_install = true
      }

      $newsource   = "${sourcepart}-${new_version}-${splunkos}-${splunkarch}.${splunkext}"

      splunk::fetch{ 'sourcefile':
        splunk_bundle => $newsource,
        type          => $type,
        source        => $source
      }

      $stopcmd  = 'splunk stop'
      $startcmd = 'splunk start --accept-license --answer-yes --no-prompt'

      exec { 'unpackSplunk':

        command   => "${tarcmd} ${newsource}",
        path      => "${splunkdir}/bin:/bin:/usr/bin:",
        cwd       => $splunkdir,
        timeout   => 600,
        user      => $splunk_user,
        group     => $splunk_group,
        subscribe => File["${splunkdir}/${newsource}"],
        before    => Exec['test_for_splunk'],
        unless    => "test -e ${splunkdir}/${manifest}",
        onlyif    => "test -s ${newsource} \
        && test -d ${splunkdir}",
        creates   => "${splunkdir}/${manifest}"
      }

      exec { 'serviceStart':
        command     => "${stopcmd}; ${startcmd}",
        path        => "${splunkdir}/bin:/bin:/usr/bin:",
        user        => $splunk_user,
        group       => $splunk_group,
        subscribe   => Exec['unpackSplunk'],
        refreshonly => true
      }

      exec { 'installSplunkService':
        command   => 'splunk enable boot-start',
        path      => "${splunkdir}/bin:/bin:/usr/bin:",
        subscribe => Exec['unpackSplunk'],
        unless    => 'test -e /etc/init.d/splunk',
        creates   => '/etc/init.d/splunk'
      }

    }

  # end version change
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
    cwd     => $splunkdir,
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
      owner   => $splunk_user,
      group   => $splunk_group,
      mode    => '0640',
      source  => "puppet:///splunk_files/auth/splunkweb/${privkey}",
      notify  => Service[splunk],
      require => Exec['test_for_splunk']
    }
  }

  if $servercert != 'server.pem' {
    file { "${splunkdir}/etc/auth/${servercert}":
      owner   => $splunk_user,
      group   => $splunk_group,
      mode    => '0640',
      source  => "puppet:///splunk_files/auth/${servercert}",
      notify  => Service[splunk],
      require => Exec['test_for_splunk']
    }
  }

  if $webcert != 'cert.pem' {
    file { "${splunkdir}/etc/auth/splunkweb/${webcert}":
      owner   => $splunk_user,
      group   => $splunk_group,
      mode    => '0640',
      source  => "puppet:///splunk_files/auth/splunkweb/${webcert}",
      notify  => Service[splunk],
      require => Exec['test_for_splunk']
    }
  }

  if $managesecret == true {
    file { "${splunkdir}/etc/splunk.secret":
      ensure => absent
    }

    file { "${splunkdir}/etc/auth/splunk.secret":
      owner   => $splunk_user,
      group   => $splunk_group,
      mode    => '0640',
      source  => 'puppet:///splunk_files/splunk.secret',
      notify  => Service[splunk],
      require => Exec['test_for_splunk']
    }
  }

  file { "${splunk_local}/inputs.d":
    ensure  => 'directory',
    mode    => '0750',
    owner   => $splunk_user,
    group   => $splunk_group,
    require => Exec['test_for_splunk']
  }

  file { "${splunk_local}/inputs.d/000_default":
    owner   => $splunk_user,
    group   => $splunk_group,
    require => File["${splunk_local}/inputs.d"],
    content => template("${module_name}/inputs.d/default_inputs.erb")
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
        owner   => $splunk_user,
        group   => $splunk_group,
        content => template("${module_name}/outputs.d/outputs.erb"),
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
      owner   => $splunk_user,
      group   => $splunk_group,
      content => '# DO NOT EDIT -- Managed by Puppet',
      require => File["${splunk_local}/server.d"],
      notify  => Exec['update-server']
    }

    file { "${splunk_local}/server.d/001_license":
      owner   => $splunk_user,
      group   => $splunk_group,
      content => template("${module_name}/server.d/license.erb"),
      require => File["${splunk_local}/server.d"]
    }

    file { "${splunk_local}/server.d/999_ixclustering":
      ensure => absent
    }

    file { "${splunk_local}/server.d/998_ixclustering":
      ensure => absent
    }

    file { "${splunk_local}/server.d/997_ixclustering":
      owner   => $splunk_user,
      group   => $splunk_group,
      content => template("${module_name}/server.d/ixclustering.erb"),
      require => File["${splunk_local}/server.d"],
      notify  => Exec['update-server']
    }

    file { "${splunk_local}/server.d/998_ssl":
      owner   => $splunk_user,
      group   => $splunk_group,
      content => template("${module_name}/server.d/ssl_server.erb"),
      require => File["${splunk_local}/server.d"],
      notify  => Exec['update-server']
    }

    file { "${splunk_local}/server.d/999_default":
      owner   => $splunk_user,
      group   => $splunk_group,
      content => template("${module_name}/server.d/default_server.erb"),
      require => File["${splunk_local}/server.d"],
      notify  => Exec['update-server']
    }

    file { "${splunk_local}/web.conf":
      owner   => $splunk_user,
      group   => $splunk_user,
      content => template("${module_name}/web.conf.erb"),
      notify  => Service[splunk],
      alias   => 'splunk-web',
      require => Exec['test_for_splunk']
    }

    if $type == 'indexer' {

      file { "${splunk_local}/inputs.d/999_splunktcp":
        owner   => $splunk_user,
        group   => $splunk_group,
        content => template("${module_name}/inputs.d/splunktcp.erb"),
        require => File["${splunk_local}/inputs.d"],
        notify  => Exec['update-inputs']
      }

      file { "${splunk_local}/server.d/995_replication":
        owner   => $splunk_user,
        group   => $splunk_group,
        content => template("${module_name}/server.d/replication.erb"),
        require => File["${splunk_local}/server.d"],
        notify  => Exec['update-server']
      }

    }

    if ($type == 'search') or ($type == 'standalone') {

      if $shcluster_mode == 'peer' {
        unless $shcluster_id =~ /\w{8}-(?:\w{4}-){3}\w{12}/ {
          exec { 'changedAdminPass_do':
            command => 'splunk edit user admin -password changed -auth admin:changeme',
            user    => $splunk_user,
            group   => $splunk_group,
            cwd     => $splunkdir,
            path    => "${splunkdir}/bin:/bin:/usr/bin:",
            require => [ File["${splunk_local}/server.d"], File["${splunk_home}/.bashrc.custom"] ]
          }

          exec { 'join_cluster':
            command     => "splunk init shcluster-config -auth admin:changed -mgmt_uri https://${::fqdn}:8089 -replication_port ${repl_port} -replication_factor ${repl_count} -conf_deploy_fetch_url https://${confdeploy} -secret ${symmkey} -shcluster_label ${shcluster_label} && splunk restart",
            path        => "${splunkdir}/bin:/bin:/usr/bin:",
            cwd         => $splunkdir,
            environment => "SPLUNK_HOME=${splunkdir}",
            timeout     => 600,
            user        => $splunk_user,
            group       => $splunk_group,
            require     => [ Exec['test_for_splunk'], Exec['changedAdminPass_do'] ],
            notify      => Exec['changedAdminPass_undo']
          }

          if $is_captain == true {
            $shcluster_members.each |String $member| {
              $servers_list = "${servers_list}.${member}:8089"
            }

            exec { 'bootstrap_cluster':
              command => "splunk bootstrap shcluster-captain -servers_list \"${servers_list}\" -auth admin:changed",
              path    => "${splunkdir}/bin:/bin:/usr/bin:",
              cwd     => $splunkdir,
              user    => $splunk_user,
              group   => $splunk_group,
              require => [ Exec['test_for_splunk'], Exec['changedAdminPass_do'] ],
              notify  => Exec['changedAdminPass_undo']
            }
          }

          exec { 'changedAdminPass_undo':
            command     => 'splunk edit user admin -password changme -auth admin:changed',
            path        => "${splunkdir}/bin:/bin:/usr/bin:",
            cwd         => $splunkdir,
            environment => "SPLUNK_HOME=${splunkdir}",
            user        => $splunk_user,
            group       => $splunk_group,
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

      file { "${splunk_local}/default-mode.conf":
        owner   => $splunk_user,
        group   => $splunk_user,
        content => template("${module_name}/default-mode.conf.erb"),
        notify  => Service[splunk],
        alias   => 'splunk-mode',
        require => Exec['test_for_splunk']
      }

      file { "${splunk_local}/alert_actions.conf":
        owner   => $splunk_user,
        group   => $splunk_user,
        content => template("${module_name}/alert_actions.conf.erb"),
        notify  => Service[splunk],
        alias   => 'alert-actions',
        require => Exec['test_for_splunk']
      }

      file { "${splunk_local}/ui-prefs.conf":
        owner   => $splunk_user,
        group   => $splunk_user,
        content => template("${module_name}/ui-prefs.conf.erb"),
        notify  => Service['splunk'],
        require => Exec['test_for_splunk']
      }

      file { "${splunk_local}/limits.conf":
        owner   => $splunk_user,
        group   => $splunk_user,
        content => template("${module_name}/limits.conf.erb"),
        notify  => Service[splunk],
        require => Exec['test_for_splunk']
      }

      if ($shcluster_id =~ /\w{8}-(?:\w{4}-){3}\w{12}/) or ($shcluster_mode == 'deployer') {
        # if clustering has already been set up, manage configs
        file { "${splunk_local}/server.d/996_shclustering":
          owner   => $splunk_user,
          group   => $splunk_group,
          require => File["${splunk_local}/server.d"],
          content => template("${module_name}/server.d/shclustering.erb"),
          notify  => Exec['update-server']
        }

        file { "${splunk_local}/server.d/995_replication":
          owner   => $splunk_user,
          group   => $splunk_group,
          require => File["${splunk_local}/server.d"],
          content => template("${module_name}/server.d/replication.erb"),
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
