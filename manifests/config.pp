# == Class: splunk::config
#
# This class manages system/local config files, certificates (if defined in hiera and
# served via puppet module), and service installation.
#
# === Examples
#
#  class { 'splunk::config': }
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
  $type              = $splunk::type
  $install_path      = $splunk::install_path
  $dir               = $splunk::dir
  $confdir           = $splunk::confdir
  $confpath          = $splunk::confpath
  $local             = $splunk::local
  $source            = $splunk::source
  $user              = $splunk::user
  $group             = $splunk::group
  $cacert            = $splunk::cacert
  $privkey           = $splunk::privkey
  $servercert        = $splunk::servercert
  $webcert           = $splunk::webcert
  $managesecret      = $splunk::managesecret
  $id                = $splunk::shcluster_id
  $confdeploy        = $splunk::search_deploy
  $repl_port         = $splunk::repl_port
  $repl_count        = $splunk::repl_count
  $shcluster_id      = $splunk::shcluster_id
  $shcluster_mode    = $splunk::shcluster_mode
  $shcluster_label   = $splunk::shcluster_label
  $is_captain        = $splunk::is_captain
  $shcluster_members = $splunk::shcluster_members
  $symmkey           = $splunk::symmkey
  $pass4symmkey      = $splunk::pass4symmkey
  $splunk_acls       = $splunk::acls
  $splunk_inputs     = $splunk::inputs
  $cluster_mode      = $splunk::cluster_mode
  $tcpout            = $splunk::tcpout
  $deployment_server = $splunk::deployment_server
  $indexes           = $splunk::indexes
  $packages          = $splunk::packages

  $splunk_home = $splunk_home
  $perms = "${user}:${group}"

  $bashrc = "
SPLUNK_HOME=${dir}
export SPLUNK_HOME
PATH=\$SPLUNK_HOME/bin:\$PATH
export PATH
  "

  if $splunk_home != undef {
    file { "${splunk_home}/.bashrc.custom":
      owner   => $user,
      group   => $group,
      content => $bashrc
    }
  }

  exec { 'test_for_splunk':
    command => "test -d ${dir}/etc",
    path    => "${dir}/bin:/bin:/usr/bin:",
    cwd     => $install_path,
    user    => $user,
    group   => $group,
    unless  => "test -d ${dir}/etc"
  }

  file { "${dir}/etc/splunk-launch.conf":
    content => template("${module_name}/splunk-launch.conf.erb"),
    owner   => $user,
    group   => $group,
    notify  => Service['splunk'],
    require => Exec['test_for_splunk']
  }

  if $pass4symmkey != undef and $pass4symmkey =~ /\$\d\$\S+/ {
    $symmcmd = "echo '${pass4symmkey}' > ${local}/symmkey.conf"

    exec { 'storeKey':
      command => $symmcmd,
      path    => "${dir}/bin:/bin:/usr/bin:",
      cwd     => $install_path,
      user    => $user,
      group   => $group,
      require => Exec['test_for_splunk'],
      unless  => "test -f ${local}/symmkey.conf"
    }
  }

  if $source != 'splunk' and $source !~ /http.*/ {

    if $cacert != 'cacert.pem' {
      file { "${dir}/etc/auth/${cacert}":
        source  => "${source}/auth/${cacert}",
        owner   => $user,
        group   => $group,
        mode    => '0640',
        notify  => Service['splunk'],
        require => Exec['test_for_splunk']
      }
    }

    if $privkey != 'privkey.pem' {
      file { "${dir}/etc/auth/splunkweb/${privkey}":
        source  => "${source}/auth/splunkweb/${privkey}",
        owner   => $user,
        group   => $group,
        mode    => '0640',
        notify  => Service['splunk'],
        require => Exec['test_for_splunk']
      }
    }

    if $servercert != 'server.pem' {
      file { "${dir}/etc/auth/${servercert}":
        source  => "${source}/auth/${servercert}",
        owner   => $user,
        group   => $group,
        mode    => '0640',
        notify  => Service['splunk'],
        require => Exec['test_for_splunk']
      }
    }

    if $webcert != 'cert.pem' {
      file { "${dir}/etc/auth/splunkweb/${webcert}":
        source  => "${source}/auth/splunkweb/${webcert}",
        owner   => $user,
        group   => $group,
        mode    => '0640',
        notify  => Service['splunk'],
        require => Exec['test_for_splunk']
      }
    }

    if $managesecret == true {
      file { "${dir}/etc/auth/splunk.secret":
        source  => "${source}/splunk.secret",
        owner   => $user,
        group   => $group,
        mode    => '0640',
        notify  => Service['splunk'],
        require => Exec['test_for_splunk']
      }
    }
  }

  file { "${dir}/etc/apps":
    ensure  => 'directory',
    owner   => $user,
    group   => $group,
    require => Exec['test_for_splunk']
  }

  if $confpath == 'app' {
    file { "$(dir}/etc/apps/__puppet_conf":
      ensure  => 'directory',
      owner   => $user,
      group   => $group,
      require => Exec['test_for_splunk']
    }
  }

  file { $local:
    ensure  => 'directory',
    owner   => $user,
    group   => $group,
    require => Exec['test_for_splunk']
  }

  file { "${local}/inputs.d":
    ensure  => 'directory',
    mode    => '0750',
    owner   => $user,
    group   => $group,
    require => Exec['test_for_splunk']
  }

  file { "${local}/inputs.d/000_default":
    content => template("${module_name}/inputs.d/default_inputs.erb"),
    owner   => $user,
    group   => $group,
    require => File["${local}/inputs.d"],
    notify  => Exec['update-inputs']
  }

  file { "${local}/inputs.d/000_splunkssl":
    content => template("${module_name}/inputs.d/ssl.erb"),
    owner   => $user,
    group   => $group,
    require => File["${local}/inputs.d"],
    notify  => Exec['update-inputs']
  }

  if ($type == 'indexer'or $type == 'standalone') and is_hash($indexes) {
    file { "${local}/indexes.d":
      ensure  => 'directory',
      mode    => '0750',
      owner   => $user,
      group   => $group,
      require => Exec['test_for_splunk']
    }

    file { "${local}/indexes.d/000_default":
      mode    => '0750',
      owner   => $user,
      group   => $group,
      require => Exec['test_for_splunk'],
      content => template('splunk/indexes.d/default_indexes.erb')
    }

    create_resources('splunk::input', $splunk_inputs)
  }

  if (($type != 'forwarder' and $type != 'indexer' and $type != 'standalone') or
    ($type == 'forwarder' and $deployment_server == undef)) and is_hash($tcpout) {
    file { "${local}/outputs.d":
      ensure  => 'directory',
      mode    => '0750',
      owner   => $user,
      group   => $group,
      require => Exec['test_for_splunk']
    }

    file { "${local}/outputs.d/000_default":
      content => template("${module_name}/outputs.d/outputs.erb"),
      owner   => $user,
      group   => $group,
      require => File["${local}/outputs.d"],
      notify  => Exec['update-outputs']
    }
  }

  if $type != forwarder {

    file { "${local}/server.d":
      ensure  => 'directory',
      mode    => '0750',
      owner   => $user,
      group   => $group,
      require => Exec['test_for_splunk']
    }

    file { "${local}/server.d/000_header":
      content => '# DO NOT EDIT -- Managed by Puppet',
      owner   => $user,
      group   => $group,
      require => File["${local}/server.d"],
      notify  => Exec['update-server']
    }

    file { "${local}/server.d/001_license":
      content => template("${module_name}/server.d/license.erb"),
      owner   => $user,
      group   => $group,
      require => File["${local}/server.d"]
    }

    if $cluster_mode != 'none' {
      file { "${local}/server.d/997_ixclustering":
        content => template("${module_name}/server.d/ixclustering.erb"),
        owner   => $user,
        group   => $group,
        require => File["${local}/server.d"],
        notify  => Exec['update-server']
      }
    }

    file { "${local}/server.d/998_ssl":
      content => template("${module_name}/server.d/ssl_server.erb"),
      owner   => $user,
      group   => $group,
      require => File["${local}/server.d"],
      notify  => Exec['update-server']
    }

    file { "${local}/server.d/999_default":
      content => template("${module_name}/server.d/default_server.erb"),
      owner   => $user,
      group   => $group,
      require => File["${local}/server.d"],
      notify  => Exec['update-server']
    }

    file { "${local}/web.conf":
      content => template("${module_name}/web.conf.erb"),
      owner   => $user,
      group   => $user,
      require => Exec['test_for_splunk'],
      notify  => Service['splunk']
    }

    if $type == 'indexer' {
      file { "${local}/inputs.d/999_splunktcp":
        content => template("${module_name}/inputs.d/splunktcp.erb"),
        owner   => $user,
        group   => $group,
        require => File["${local}/inputs.d"],
        notify  => Exec['update-inputs']
      }

      if $cluster_mode != 'none' {
        file { "${local}/server.d/995_replication":
          content => template("${module_name}/server.d/replication.erb"),
          owner   => $user,
          group   => $group,
          require => File["${local}/server.d"],
          notify  => Exec['update-server']
        }
      }
    }

    if ($type == 'search') or ($type == 'standalone') {

      if $shcluster_mode == 'peer' {

        unless $shcluster_id =~ /\w{8}-(?:\w{4}-){3}\w{12}/ {

          exec { 'join_cluster':
            command     => "splunk init shcluster-config -auth admin:changme -mgmt_uri https://${::fqdn}:8089 -replication_port ${repl_port} -replication_factor ${repl_count} -conf_deploy_fetch_url https://${confdeploy} -secret ${symmkey} -shcluster_label ${shcluster_label} && splunk restart",
            environment => "SPLUNK_HOME=${dir}",
            path        => "${dir}/bin:/bin:/usr/bin:",
            cwd         => $dir,
            timeout     => 600,
            user        => $user,
            group       => $group,
            onlyif      => 'splunk status',
            require     => Exec['test_for_splunk']
          }

          if $is_captain == true and $shcluster_members != undef {
            $shcluster_members.each |String $member| {
              $servers_list = "${servers_list}.${member}:8089"
            }

            $bootstrap_cmd = "splunk bootstrap shcluster-captain \
                -servers_list \"${servers_list}\" -auth admin:changme"

            exec { 'bootstrap_cluster':
              command     => $bootstrap_cmd,
              environment => "SPLUNK_HOME=${dir}",
              path        => "${dir}/bin:/bin:/usr/bin:",
              cwd         => $dir,
              user        => $user,
              group       => $group,
              onlyif      => 'splunk status',
              require     => Exec['test_for_splunk']
            }
          }

        }
      }

      package { $packages:
        ensure => installed
      }

      file { "${local}/default-mode.conf":
        content => template("${module_name}/default-mode.conf.erb"),
        owner   => $user,
        group   => $user,
        notify  => Service['splunk'],
        require => Exec['test_for_splunk']
      }

      file { "${local}/alert_actions.conf":
        alias   => 'alert-actions',
        content => template("${module_name}/alert_actions.conf.erb"),
        owner   => $user,
        group   => $user,
        notify  => Service['splunk'],
        require => Exec['test_for_splunk']
      }

      file { "${local}/ui-prefs.conf":
        content => template("${module_name}/ui-prefs.conf.erb"),
        owner   => $user,
        group   => $user,
        notify  => Service['splunk'],
        require => Exec['test_for_splunk']
      }

      file { "${local}/limits.conf":
        content => template("${module_name}/limits.conf.erb"),
        owner   => $user,
        group   => $user,
        notify  => Service['splunk'],
        require => Exec['test_for_splunk']
      }

      if $shcluster_id != undef or $shcluster_mode == 'deployer' {
        # if clustering has already been set up, manage configs
        file { "${local}/server.d/996_shclustering":
          content => template("${module_name}/server.d/shclustering.erb"),
          owner   => $user,
          group   => $group,
          require => File["${local}/server.d"],
          notify  => Exec['update-server']
        }

        file { "${local}/server.d/995_replication":
          content => template("${module_name}/server.d/replication.erb"),
          owner   => $user,
          group   => $group,
          require => File["${local}/server.d"],
          notify  => Exec['update-server']
        }
      } else {
        # remove any fragments from unconfigured shc member or standalone
        file { "${local}/server.d/996_shclustering":
          ensure => absent,
          notify => Exec['update-server']
        }

        file { "${local}/server.d/995_replication":
          ensure => absent,
          notify => Exec['update-server']
        }
      }
    }
  }

  if is_hash($splunk_inputs) and $splunk_inputs != undef {
    create_resources('splunk::input', $splunk_inputs)
  }
  if is_hash($splunk_acls) and $splunk_acls != undef {
    create_resources('splunk::acl', $splunk_acls)
  }
}
