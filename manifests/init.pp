# == Class: splunk
#
# Full description of class splunk here.
#
# === Parameters
#
# Document parameters here.
#
# [*sample_parameter*]
#   Explanation of what this parameter affects and what it defaults to.
#   e.g. "Specify one or more upstream ntp servers as an array."
#
# === Variables
#
# Here you should define a list of variables that this module would require.
#
# [*sample_variable*]
#   Explanation of how this variable affects the funtion of this class and if
#   it has a default. e.g. "The parameter enc_ntp_servers must be set by the
#   External Node Classifier as a comma separated list of hostnames." (Note,
#   global variables should be avoided in favor of class parameters as
#   of Puppet 2.6.)
#
# === Examples
#
#  class { splunk: }
#
# === Authors
#
# Christopher Caldwell <caldwell@gwu.edu>
#
# === Copyright
#
# Copyright 2017 Christopher Caldwell
#
class splunk(
String $version,
String $release,
String $type,
Boolean $adhoc_searchhead,
Boolean $autolb,
Integer $autolbfrequency,
String $cacert,
Boolean $captain_is_adhoc,
String $ciphersuite,
String $cluster_mode,
String $confdir,
Boolean $create_user,
Boolean $deployment_disable,
Integer $deployment_interval,
String $dispatch_earliest,
String $dispatch_latest,
Integer $dispatch_size,
String $ecdhcurves,
String $email,
String $ext,
Boolean $forcetimebasedautolb,
String $install_path,
Boolean $is_captain,
String $license_master_mode,
Boolean $managesecret,
Integer $max_rawsize_perchunk,
Integer $max_searches,
String $os,
Boolean $preferred_captain,
String $privkey,
Boolean $scheduler_disable,
Integer $search_maxinfocsv,
Integer $search_maxqueue,
String $server_site,
String $servercert,
String $servercertpass,
String $source,
String $group,
String $user,
Boolean $splunknotcp_ssl,
Boolean $splunknotcp,
Boolean $sslclientcert,
Boolean $sslclientcompression,
Boolean $sslcompression,
Boolean $sslnegotiation,
Boolean $sslstsheader,
Boolean $sslv3,
Boolean $sslverify,
String $sslversions,
Integer $subsearch_maxout,
Integer $subsearch_maxtime,
Integer $subsearch_ttl,
String $tarcmd,
Boolean $use_mounts,
String $webcert,
Boolean $webssl,
Enum['v1,v2', 'v2'] $signatureversion,
Enum['decryptOnly', 'disabled'] $legacyciphers,
Enum['sse-s3', 'sse-kms', 'sse-c', 'none'] $s3_encryption,
Optional[String] $license_master,
Optional[String] $cold_path,
Optional[String] $warm_path,
Optional[String] $datamodel_path,
Optional[Integer] $maxwarm          = 0,
Optional[Integer] $maxcold          = 0,
Optional[Integer] $s3_keyrefresh    = 86400,
Optional[Hash] $acls                = undef,
Optional[String] $admin_pass        = undef,
Optional[String] $authentication    = undef,
Optional[Hash] $authconfig          = undef,
Optional[String] $cert_source       = undef,
Optional[Hash] $indexes             = undef,
Optional[Hash] $inputs              = undef,
Optional[Tuple] $clusters           = undef,
Optional[String] $deployment_server = undef,
Optional[Tuple] $licenses           = undef,
Optional[Array] $packages           = undef,
Optional[Integer] $repl_count       = undef,
Optional[Integer] $repl_port        = undef,
Optional[Tuple] $roles              = undef,
Optional[String] $search_deploy     = undef,
Optional[String] $serviceurl        = undef,
Optional[String] $shcluster_label   = undef,
Optional[String] $shcluster_mode    = undef,
Optional[Array] $shcluster_members  = undef,
Optional[String] $symmkey           = undef,
Optional[Hash] $tcpout              = undef,
Optional[String] $remote_path       = undef,
Optional[String] $s3_access_key     = undef,
Optional[String] $s3_secret_key     = undef,
Optional[String] $s3_endpoint       = undef,
Optional[string] $s3_sslverify      = undef,
Optional[string] $s3_sslversions    = undef,
Optional[string] $s3_ssl_altname    = undef,
Optional[string] $s3_ssl_capath     = undef,
Optional[string] $s3_ciphersuite    = undef,
Optional[string] $s3_ecdhcurves     = undef,
Optional[string] $s3_region         = undef,
Optional[string] $s3_kms_key        = undef
) {

  if $type != 'none' {

    if $environment == 'ci' or $create_user == true {
      class { 'splunk::user': }
    }

    $new_version = "${version}-${release}"

    $arch = $facts['architecture'] ? {
      x86_64  => 'x86_64',
      amd64   => 'x86_64',
      default => 'i686'
    }
    if $type == 'forwarder' {
      $sourcepart = 'splunkforwarder'
    } else {
      $sourcepart = 'splunk'
    }

    $dir      = "${install_path}/${sourcepart}"
    $capath   = "${dir}/etc/auth"
    $confpath = $confdir ? {
      'system' => 'etc/system',
      'app'    => 'etc/apps/__puppet_conf',
      default  => 'etc/system'
    }
    $local    = "${dir}/${confpath}/local"
    $splunkdb = "${dir}/var/lib/splunk"
    $manifest = "${sourcepart}-${new_version}-${os}-${arch}-manifest"

    # fact containing splunk search head cluster id (if a cluster member)
    # once defined, we add it to our generated files so it is not  lost
    if defined('$splunk_shcluster_id') and is_string('$splunk_shcluster_id') {
      $shcluster_id = $::splunk_shcluster_id
    } else {
      $shcluster_id = undef
    }

    if defined('$splunk_symmkey') and $::splunk_symmkey =~ /\$\d\$\S+/ {
      $pass4symmkey = $::splunk_symmkey
    } else {
      $pass4symmkey = undef
    }

    if defined('$splunk_certpass') and $::splunk_certpass =~ /\$\d\$\S+/ {
      $certpass = $::splunk_certpass
    } else {
      $certpass = undef
    }

    # splunk user home dir from fact
    if defined('$splunk_home') and is_string('$splunk_home') {
      $home = $::splunk_home
    } else {
      $home = undef
    }

    # fact showing directory of any running splunk process
    # should match $dir for the type
    if defined('$splunk_cwd') and is_string('$splunk_cwd') {
      $cwd = $::splunk_cwd
    } else {
      $cwd = undef
    }

    # fact is true if splunk/etc and splunk/var are on
    # separate mount points
    if defined('$splunk_mounts') and $::splunk_mounts == true {
      $has_mounts = true
    } else {
      $has_mounts = false
    }

    # splunk is currently installed - get version from fact
    if defined('$splunk_version') and $::splunk_version =~ /^(\d\.)+\d-\w+/ {
      $cur_version = $::splunk_version
      # because the legacy fact does not represent splunk version as
      # version-release, we cut the version from the string.
      $vtemp = regsubst($cur_version, '^((?:\d\.)+\d)-\w+$', '\1')
      $vdiff = versioncmp($version, $vtemp)
      if $cwd =~ /\/\w+\/.*/ {
        # splunk is running from the directory expected for the type
        if $cwd == $dir {
          if $vdiff == 1 {
            info('Upgrading Splunk version.')
            $action = 'upgrade'
          } elsif $vdiff == -1 {
            # current version is higher than the one puppet wants to install
            info('Not downgrading or configuring. Splunk is already at a higher version.')
            $action = 'service'
          } else {
            # version matches - just do config tasks
            $action = 'config'
          }
        } elsif $cwd != $dir and $cwd != $home {
          notice('Changing Splunk install directory.')
          # splunk type changed
          # do not change if no previous splunk install
          # do not change if splunk is running out of the splunk users home
          $action = 'change'
        } else {
          notice('Unhandled splunk_cwd')
        }
      }
    } else {
      # no installed version of splunk from fact
      info('Unhandled splunk_version')
      if ($use_mounts == true and $has_mounts == true) or $use_mounts == false {
        $action = 'install'
      } else {
        info('Wait for mounts')
        $action = 'wait'
      }
      $cur_version = undef
    }

    if $action == 'install' or $action == 'upgrade' or $action == 'change' {
      class { 'splunk::install': }
      -> class { 'splunk::config': }
      -> class { 'splunk::service': }
    } elsif $action == 'config' {
      class { 'splunk::config': }
      -> class { 'splunk::service': }
    } elsif $action == 'service' {
      class { 'splunk::service': }
    } elsif $action == 'wait' {
      notice('Waiting for pre-requisites.')
    } else {
      notice('Unhandled action.')
      $action = 'none'
    }

    if $action != 'none' and $action != 'wait' {
      # configure deployment server for indexers and forwarders
      if $type =~ /^(heavy)?forwarder/ and $deployment_server != undef {
        class { 'splunk::deployment': }
      }

      $perms = "${user}:${group}"

      # have Puppet configure Splunk authentication
      if $authentication != undef {
        if defined('$splunk_authpass') and $::splunk_authpass =~ /\$\d\$\S+/ {
          $authpass = $::splunk_authpass
        } else {
          $authpass = undef
        }

        class { 'splunk::auth': }
        $auth_dir  = "${local}/auth.d/"
        $auth_conf  = "${local}/authentication.conf"
        $auth_cmd = "/bin/cat ${auth_dir}/* > ${auth_conf}; \
            chown ${perms} ${auth_conf}"

        exec { 'update-auth':
          command     => $auth_cmd,
          refreshonly => true,
          user        => $user,
          group       => $group,
          umask       => '027',
          creates     => $auth_conf,
          notify      => Service['splunk']
        }
      }

      $inputs_dir  = "${local}/inputs.d/"
      $inputs_conf  = "${local}/inputs.conf"
      $inputs_cmd = "/bin/cat ${inputs_dir}/* > ${inputs_conf}; \
          chown ${perms} ${inputs_conf}"

      exec { 'update-inputs':
        command     => $inputs_cmd,
        refreshonly => true,
        user        => $user,
        group       => $group,
        umask       => '027',
        creates     => $inputs_conf,
        notify      => Service['splunk']
      }

      if $type != 'forwarder' or $deployment_server == undef {
        if $type != 'indexer' and is_hash($tcpout) {
          $outputs_dir = "${local}/outputs.d/"
          $outputs_conf = "${local}/outputs.conf"
          $outputs_cmd = "/bin/cat ${outputs_dir}/* > ${outputs_conf}; \
              chown ${perms} ${outputs_conf}"

          exec { 'update-outputs':
            command     => $outputs_cmd,
            refreshonly => true,
            user        => $user,
            group       => $group,
            umask       => '027',
            creates     => $outputs_conf,
            notify      => Service['splunk']
          }
        }

        if ($type == 'indexer' or $type == 'standalone') and is_hash($indexes) {
          $indexes_dir = "${local}/indexes.d/"
          $indexes_conf = "${local}/indexes.conf"
          $indexes_cmd = "/bin/cat ${indexes_dir}/* > ${indexes_conf}; \
              chown ${perms} ${indexes_conf}"

          exec { 'update-indexes':
            command     => $indexes_cmd,
            refreshonly => true,
            user        => $user,
            group       => $group,
            umask       => '027',
            creates     => $indexes_conf,
            notify      => Service['splunk']
          }
        }

        $server_dir = "${local}/server.d/"
        $server_conf = "${local}/server.conf"
        $server_cmd = "/bin/cat ${server_dir}/* > ${server_conf}; \
            chown ${perms} ${server_conf}"

        exec { 'update-server':
          command     => $server_cmd,
          refreshonly => true,
          user        => $user,
          group       => $group,
          umask       => '027',
          creates     => $server_conf,
          notify      => Service['splunk']
        }
      }
    }
  }
}
