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
  $action            = $splunk::action
  $type              = $splunk::type
  $install_path      = $splunk::install_path
  $dir               = $splunk::dir
  $cert_source       = $splunk::cert_source
  $confdir           = $splunk::confdir
  $confpath          = $splunk::confpath
  $local             = $splunk::local
  $manifest          = $splunk::manifest
  $geo_source        = $splunk::geo_source
  $geo_hash          = $splunk::geo_hash
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
  $remote_path       = $splunk::remote_path
  $admin_pass        = $splunk::admin_pass

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

  if $cert_source != undef {

    if $cacert != 'cacert.pem' {
      file { "${dir}/etc/auth/${cacert}":
        source  => "${cert_source}/auth/${cacert}",
        owner   => $user,
        group   => $group,
        mode    => '0640',
        notify  => Service['splunk'],
        require => Exec['test_for_splunk']
      }
    }

    if $privkey != 'privkey.pem' {
      file { "${dir}/etc/auth/splunkweb/${privkey}":
        source  => "${cert_source}/auth/splunkweb/${privkey}",
        owner   => $user,
        group   => $group,
        mode    => '0640',
        notify  => Service['splunk'],
        require => Exec['test_for_splunk']
      }
    }

    if $servercert != 'server.pem' {
      file { "${dir}/etc/auth/${servercert}":
        source  => "${cert_source}/auth/${servercert}",
        owner   => $user,
        group   => $group,
        mode    => '0640',
        notify  => Service['splunk'],
        require => Exec['test_for_splunk']
      }
    }

    if $webcert != 'cert.pem' {
      file { "${dir}/etc/auth/splunkweb/${webcert}":
        source  => "${cert_source}/auth/splunkweb/${webcert}",
        owner   => $user,
        group   => $group,
        mode    => '0640',
        notify  => Service['splunk'],
        require => Exec['test_for_splunk']
      }
    }

    if $managesecret == true {
      file { "${dir}/etc/auth/splunk.secret":
        source  => "${cert_source}/splunk.secret",
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
    file { "${dir}/etc/apps/__puppet_conf":
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

  if $action == 'install' {
    if $admin_pass != undef {
      file { "${local}/user-seed.conf":
        content => template("${module_name}/user-seed.conf.erb"),
        owner   => $user,
        group   => $group,
        notify  => Service['splunk']
      }
    }
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

  file { "${local}/inputs.d/001_splunkssl":
    content => template("${module_name}/inputs.d/ssl.erb"),
    owner   => $user,
    group   => $group,
    require => File["${local}/inputs.d"],
    notify  => Exec['update-inputs']
  }

  if ($type == 'indexer' or $type == 'index_master' or $type == 'standalone') and $indexes =~ Hash {
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

    if $remote_path != undef {
      file { "${local}/indexes.d/001_s3":
        content => template("${module_name}/indexes.d/s3.erb"),
        owner   => $user,
        group   => $group,
        require => File["${local}/indexes.d"],
        notify  => Exec['update-indexes']
      }
    }

    create_resources('splunk::index', $indexes)
  }

  if (($type != 'forwarder' and $type != 'indexer' and $type != 'standalone') or
    ($type == 'forwarder' and $deployment_server == undef)) and $tcpout =~ Hash {
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
            command     => "splunk init shcluster-config \
-auth admin:${admin_pass} -mgmt_uri https://${::fqdn}:8089 -replication_port ${repl_port} \
-replication_factor ${repl_count} -conf_deploy_fetch_url https://${confdeploy} \
-secret ${symmkey} -shcluster_label ${shcluster_label} && splunk restart",
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

            $servers_list = join($shcluster_members, ',')

            $bootstrap_cmd = "splunk bootstrap shcluster-captain \
-servers_list \"${servers_list}\" -auth admin:${admin_pass}"

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

      if $geo_source != undef {
        file { "${dir}/share/GeoLite2-City.mmdb":
          source  => "${geo_source}/GeoLite2-City.mmdb",
          owner   => $user,
          group   => $user,
          require => Exec['test_for_splunk']
        }

        file_line { 'geolite2_hash':
          path    => "${dir}/${manifest}",
          line    => "f 444 ${user} ${group} splunk/share/GeoLite2-City.mmdb ${geo_hash}",
          match   => "^f 444 ${user} ${group} splunk/share/GeoLite2-City.mmdb",
          require => Exec['test_for_splunk'],
          notify  => Service['splunk']
        }
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
      }
    }
  }

  if $splunk_inputs =~ Hash and $splunk_inputs != undef {
    create_resources('splunk::input', $splunk_inputs)
  }
  if $splunk_acls =~ Hash and $splunk_acls != undef {
    create_resources('splunk::acl', $splunk_acls)
  }
}
