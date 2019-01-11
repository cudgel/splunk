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
# Christopher Caldwell <author@domain.com>
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
String $splunk_group,
String $splunk_user,
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
String $webcert,
Boolean $webssl,
Optional[String] $license_master,
Optional[Hash] $acls = undef,
Optional[Hash] $inputs = undef,
Optional[Tuple] $clusters = undef,
Optional[String] $deployment_server = undef,
Optional[Tuple] $licenses = undef,
Optional[Integer] $repl_count = undef,
Optional[Integer] $repl_port = undef,
Optional[String] $search_deploy = undef,
Optional[String] $serviceurl = undef,
Optional[String] $shcluster_label = undef,
Optional[String] $shcluster_mode = undef,
Optional[Array] $shcluster_members = undef,
Optional[String] $symmkey = undef,
Optional[Hash] $tcpout = undef
) {

  if $type != 'none' {

    if $environment == 'ci' or $create_user == true {
      class { 'splunk::user': }
    }

    $new_version = "${version}-${release}"

    $arch = $architecture ? {
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
    $local    = "${dir}/etc/system/local"
    $splunkdb = "${dir}/var/lib/splunk"
    $manifest = "${sourcepart}-${new_version}-${os}-${arch}-manifest"

    # splunk search head cluster id (if a cluster member)
    $shcluster_id = $splunk_shcluster_id

    # splunk user home dir from fact
    $home = $splunk_home

    # directory of any running splunk process
    $cwd = $splunk_cwd

    # currently installed version from fact
    $current_version = $splunk_version
    $cut_version = regsubst($current_version, '^(\d+\.\d+\.\d+)-.*$', '\1')
    # because the legacy fact does not represent splunk version as
    # version-release, we cut the version from the string.

    if versioncmp($version, $cut_version) == 1 or $cut_version == '' or $cwd != $dir {
      class { 'splunk::install': } -> class { 'splunk::config': } -> class { 'splunk::service': }
    } else {
      if versioncmp($version, $cut_version) == -1 {
        info('Splunk is already at a higher version.')
      }
      class { 'splunk::config': } -> class { 'splunk::service': }
    }

  # configure deployment server for indexers and forwarders
    if $type == 'forwarder' or $type == 'heavyforwarder' and $deployment_server != undef {
      class { 'splunk::deployment': }
    }

    $perms = "${splunk_user}:${splunk_group}"

    $my_input_d  = "${local}/inputs.d/"
    $my_input_c  = "${local}/inputs.conf"

    exec { 'update-inputs':
      command     => "/bin/cat ${my_input_d}/* > ${my_input_c}; \
          chown ${perms} ${my_input_c}",
      refreshonly => true,
      subscribe   => File["${local}/inputs.d/000_default"],
      notify      => Service['splunk']
    }

    if $type != 'forwarder' {

      if $type != 'indexer' and is_hash($tcpout) {

        $my_output_d = "${local}/outputs.d/"
        $my_output_c = "${local}/outputs.conf"

        exec { 'update-outputs':
          command     => "/bin/cat ${my_output_d}/* > ${my_output_c}; \
                chown ${perms} ${my_output_c}",
          refreshonly => true,
          creates     => "${local}/outputs.conf",
          notify      => Service['splunk']
        }
      }

      $my_server_d = "${local}/server.d/"
      $my_server_c = "${local}/server.conf"

      exec { 'update-server':
        command     => "/bin/cat ${my_server_d}/* > ${my_server_c}; \
            chown ${perms} ${my_server_c}",
        refreshonly => true,
        subscribe   => [
            File["${local}/server.d/000_header"],
            File["${local}/server.d/998_ssl"],
            File["${local}/server.d/999_default"]
          ],
        notify      => Service['splunk']
      }

    }

  }

}
