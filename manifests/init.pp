# @summary Manages Splunk installation and configuration
#
# @param version Splunk version to install
# @param release Splunk release build number
# @param type Type of Splunk installation (forwarder, indexer, search, etc.)
# @param kernel_version Kernel version for package naming
# @param adhoc_searchhead Whether this is an adhoc search head
# @param autolb Enable automatic load balancing
# @param autolbfrequency Frequency for automatic load balancing
# @param cacert CA certificate filename
# @param captain_is_adhoc Whether the captain is adhoc
# @param ciphersuite SSL cipher suite
# @param cluster_mode Cluster mode (master, slave, searchhead, none)
# @param confdir Configuration directory type
# @param create_user Whether to create the Splunk user
# @param deployment_disable Disable deployment client
# @param deployment_interval Deployment client check interval
# @param dispatch_earliest Default earliest time for searches
# @param dispatch_latest Default latest time for searches
# @param dispatch_size Default dispatch size
# @param ecdhcurves ECDH curves for SSL
# @param email Email address for alerts
# @param ext File extension for packages
# @param forcetimebasedautolb Force time-based auto load balancing
# @param install_path Installation path for Splunk
# @param is_captain Whether this node is a search head cluster captain
# @param license_master_mode License master mode
# @param mailserver Mail server for alerts
# @param managesecret Whether to manage splunk.secret file
# @param max_rawsize_perchunk Maximum raw size per chunk
# @param max_searches Maximum concurrent searches
# @param preferred_captain Whether this is the preferred captain
# @param privkey Private key filename
# @param scheduler_disable Disable scheduler
# @param search_maxinfocsv Maximum info CSV size
# @param search_maxqueue Maximum search queue size
# @param server_site Server site for multisite clustering
# @param servercert Server certificate filename
# @param servercertpass Server certificate password
# @param source Source for Splunk packages
# @param group Splunk group name
# @param user Splunk user name
# @param replace_hash Whether to replace existing password hashes
# @param splunknotcp_ssl Disable SSL for Splunk TCP
# @param splunknotcp Disable Splunk TCP
# @param sslclientcert SSL client certificate
# @param sslclientcompression SSL client compression
# @param sslcompression SSL compression
# @param sslnegotiation SSL negotiation
# @param sslstsheader SSL STS header
# @param sslv3 Enable SSLv3
# @param sslverify SSL verification
# @param sslversions SSL versions
# @param subsearch_maxout Maximum subsearch output
# @param subsearch_maxtime Maximum subsearch time
# @param subsearch_ttl Subsearch TTL
# @param symmkey Symmetric key
# @param tarcmd Tar command for extraction
# @param use_mounts Whether to use separate mounts
# @param use_systemd Whether to use systemd
# @param webcert Web certificate filename
# @param webssl Enable web SSL
# @param signatureversion S3 signature version
# @param legacyciphers Legacy cipher support
# @param s3_encryption S3 encryption type
# @param license_master License master URI
# @param cold_path Cold storage path
# @param warm_path Warm storage path
# @param datamodel_path Data model path
# @param maxwarm Maximum warm buckets
# @param maxcold Maximum cold buckets
# @param s3_keyrefresh S3 key refresh interval
# @param acls ACL configurations
# @param admin_pass Admin password
# @param auth_pass Authentication password
# @param authentication Authentication method
# @param authconfig Authentication configuration
# @param cert_source Certificate source
# @param indexes Index configurations
# @param inputs Input configurations
# @param apps App configurations
# @param geo_source GeoIP database source
# @param geo_hash GeoIP database hash
# @param clusters Cluster configurations
# @param deployment_server Deployment server URI
# @param licenses License configurations
# @param repl_count Replication count
# @param repl_port Replication port
# @param roles Role configurations
# @param search_deploy Search deployer URI
# @param mailfrom Mail from address
# @param serviceurl Service URL
# @param shcluster_label Search head cluster label
# @param shcluster_mode Search head cluster mode
# @param shcluster_members Search head cluster members
# @param tcpout TCP output configuration
# @param remote_path Remote storage path
# @param s3_access_key S3 access key
# @param s3_secret_key S3 secret key
# @param s3_endpoint S3 endpoint
# @param s3_sslverify S3 SSL verification
# @param s3_sslversions S3 SSL versions
# @param s3_ssl_altname S3 SSL alternative name
# @param s3_ssl_capath S3 SSL CA path
# @param s3_ciphersuite S3 cipher suite
# @param s3_ecdhcurves S3 ECDH curves
# @param s3_region S3 region
# @param s3_kms_key S3 KMS key
#
class splunk (
  String $version,
  String $release,
  String $type,
  String $kernel_version,
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
  String $mailserver,
  Boolean $managesecret,
  Integer $max_rawsize_perchunk,
  Integer $max_searches,
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
  Boolean $replace_hash,
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
  String $symmkey,
  String $tarcmd,
  Boolean $use_mounts,
  Boolean $use_systemd,
  String $webcert,
  Boolean $webssl,
  Enum['v1,v2', 'v2'] $signatureversion,
  Enum['decryptOnly', 'disabled'] $legacyciphers,
  Enum['sse-s3', 'sse-kms', 'sse-c', 'none'] $s3_encryption,
  Optional[String] $license_master,
  Optional[String] $cold_path,
  Optional[String] $warm_path,
  Optional[String] $datamodel_path,
  Integer $maxwarm          = 0,
  Integer $maxcold          = 0,
  Integer $s3_keyrefresh    = 86400,
  Optional[Hash] $acls                = undef,
  Optional[String] $admin_pass        = undef,
  Optional[String] $auth_pass         = undef,
  Optional[String] $authentication    = undef,
  Optional[Hash] $authconfig          = undef,
  Optional[String] $cert_source       = undef,
  Optional[Hash] $indexes             = undef,
  Optional[Hash] $inputs              = undef,
  Optional[Hash] $apps                = undef,
  Optional[String] $geo_source        = undef,
  Optional[String] $geo_hash          = undef,
  Optional[Tuple] $clusters           = undef,
  Optional[String] $deployment_server = undef,
  Optional[Tuple] $licenses           = undef,
  Optional[Integer] $repl_count       = undef,
  Optional[Integer] $repl_port        = undef,
  Optional[Tuple] $roles              = undef,
  Optional[String] $search_deploy     = undef,
  Optional[String] $mailfrom          = undef,
  Optional[String] $serviceurl        = undef,
  Optional[String] $shcluster_label   = undef,
  Optional[String] $shcluster_mode    = undef,
  Optional[Array] $shcluster_members  = undef,
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
  if $type == 'none' and $facts['splunk_cwd'] != undef {
    exec { 'stop_splunk_service':
      command => "${facts['splunk_cwd']}/bin/splunk stop",
      onlyif  => "${facts['splunk_cwd']}/bin/splunk status",
      path    => '/bin:/usr/bin:/sbin:/usr/sbin',
      before  => File['splunk_installation'],
    }

    file { 'splunk_installation':
      ensure  => absent,
      path    => $facts['splunk_cwd'],
      recurse => true,
      force   => true,
    }
  }

  if $type != 'none' {
    if $environment == 'ci' or $create_user == true {
      class { 'splunk::user': }
    }

    $new_version = "${version}-${release}"
    # Determine package name components. Splunk changed naming in 9.4.0
    # Prior to 9.4.0 the package used 'Linux-x86_64'; from 9.4.0+ it uses 'linux-amd64'
    $kernel = $facts['kernel']
    $arch = $facts['os']['architecture'] ? {
      'x86_64'  => 'x86_64',
      'amd64'   => 'x86_64',
      default => 'i686'
    }

    # Create a package platform suffix that matches Splunk download naming.
    # For versions >= 9.4.0 use 'linux-amd64' (lowercase linux and amd64),
    # otherwise use the legacy 'Linux-x86_64' behavior.
    # Decide on naming based on full version using versioncmp
    $is_new_naming = versioncmp($version, '9.4.0') >= 0

    if $is_new_naming {
      # New naming: kernel 'linux' and arch 'amd64' in lowercase and joined with '-'
      $pkg_kernel = 'linux'
      # map common fact archs to 'amd64'
      $pkg_arch = $facts['os']['architecture'] ? {
        'x86_64' => 'amd64',
        'amd64'  => 'amd64',
        default  => 'amd64'
      }
      $pkg_platform = "${pkg_kernel}-${pkg_arch}"
    } else {
      # Legacy naming: 'Linux-x86_64'
      $pkg_kernel = $kernel
      $pkg_arch = $arch
      $pkg_platform = "${pkg_kernel}-${pkg_arch}"
    }

    if $type == 'forwarder' {
      $sourcepart = 'splunkforwarder'
      $product = 'universalforwarder'
    } else {
      $sourcepart = 'splunk'
      $product = 'splunk'
    }

    # Use computed platform token when building package filename
    $newsource   = "${sourcepart}-${version}-${release}-${pkg_platform}.${ext}"
    $dir      = "${install_path}/${sourcepart}"
    $capath   = "${dir}/etc/auth"
    $confpath = $confdir ? {
      'system' => 'etc/system',
      'app'    => 'etc/apps/__puppet_conf',
      default  => 'etc/system'
    }
    $local    = "${dir}/${confpath}/local"
    $splunkdb = "${dir}/var/lib/splunk"
    $manifest = downcase("${sourcepart}-${new_version}-${pkg_kernel}-${kernel_version}-${pkg_arch}-manifest")

    # fact containing splunk search head cluster id (if a cluster member)
    # once defined, we add it to our generated files so it is not  lost
    if defined('$splunk_shcluster_id') and $facts['splunk_shcluster_id'] =~ String {
      $shcluster_id = $facts['splunk_shcluster_id']
    } else {
      $shcluster_id = undef
    }

    if defined('$splunk_symmkey') and $facts['splunk_symmkey'] =~ /^\$\d\$\S+/ and $replace_hash == false {
      $pass4symmkey = $facts['splunk_symmkey']
    } else {
      $pass4symmkey = undef
    }

    if defined('$splunk_certpass') and $facts['splunk_certpass'] =~ /^\$\d\$\S+/ and $replace_hash == false {
      $certpass = $facts['splunk_certpass']
    } else {
      $certpass = undef
    }

    # splunk user home dir from fact
    if defined('$splunk_home') and $facts['splunk_home'] =~ String {
      $home = $facts['splunk_home']
    } else {
      $home = undef
    }

    # fact showing directory of any running splunk process
    # should match $dir for the type
    if defined('$splunk_cwd') and $facts['splunk_cwd'] =~ String {
      $cwd = $facts['splunk_cwd']
    } else {
      $cwd = undef
    }

    # fact is true if splunk/etc and splunk/var are on
    # separate mount points
    if defined('$splunk_mounts') and $facts['splunk_mounts'] == true {
      $has_mounts = true
    } else {
      $has_mounts = false
    }

    # splunk is currently installed - get version from fact
    if defined('$splunk_version') and $facts['splunk_version'] =~ /^(\d\.)+\d-\w+/ {
      $cur_version = $facts['splunk_version']
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
      class { 'splunk::fetch': }
      -> class { 'splunk::install': }
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
      if $authentication != undef and $type != 'forwarder' {
        if defined('$splunk_authpass') and $facts['splunk_authpass'] =~ /\$\d\$\S+/ {
          $authpass = $facts['splunk_authpass']
        } elsif $auth_pass =~ String {
          $authpass = $auth_pass
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
          notify      => Service['splunk'],
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
        notify      => Service['splunk'],
      }

      if $type != 'forwarder' or $deployment_server == undef {
        if $type != 'indexer' and $tcpout =~ Hash {
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
            notify      => Service['splunk'],
          }
        }

        if ($type == 'indexer' or $type == 'index_master' or $type == 'standalone') and $indexes =~ Hash {
          $indexes_dir = "${local}/indexes.d/"
          if $splunk::cluster_mode == 'master' {
            $indexes_conf_dir = "${dir}/etc/master-apps/_cluster/local"
          } else {
            $indexes_conf_dir = $local
          }
          $indexes_conf = "${indexes_conf_dir}/indexes.conf"
          $indexes_cmd = "/bin/cat ${indexes_dir}/* > ${indexes_conf}; \
              chown ${perms} ${indexes_conf}"

          exec { 'update-indexes':
            command     => $indexes_cmd,
            refreshonly => true,
            user        => $user,
            group       => $group,
            umask       => '027',
            notify      => Service['splunk'],
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
          notify      => Service['splunk'],
        }
      }
    }
  }
}
