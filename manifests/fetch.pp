# == Class: splunk::fetch
#
# This class tries to fetch the specified version of either splunk
# or splunkforwarder (depending on the type of install) from splunk.com
# or a hiera-defined server.
#
# === Examples
#
#  This class is not called directly
#
# === Authors
#
# Christopher Caldwell <caldwell@gwu.edu>
#
# === Copyright
#
# Copyright 2017 Christopher Caldwell
#
class splunk::fetch {
  $source       = $splunk::source
  $sourcepart   = $splunk::sourcepart
  $type         = $splunk::type
  $version      = $splunk::version
  $release      = $splunk::release
  $newsource    = $splunk::newsource
  $install_path = $splunk::install_path

  # Compute platform token the same way as in init.pp to match package naming
  $version_parts = split($version, '\.')
  $major = $version_parts[0]
  $minor = pick($version_parts, 1, '0')
  $is_new_naming = versioncmp("${major}.${minor}.0", '9.4.0') >= 0

  if $is_new_naming {
    $pkg_kernel = 'linux'
    $pkg_arch = $facts['os']['architecture'] ? {
      'x86_64' => 'amd64',
      'amd64'  => 'amd64',
      default  => 'amd64'
    }
    $pkg_platform = "${pkg_kernel}-${pkg_arch}"
  } else {
    $pkg_kernel = $facts['kernel']
    $pkg_arch = $facts['os']['architecture'] ? {
      'x86_64'  => 'x86_64',
      'amd64'   => 'x86_64',
      default => 'i686'
    }
    $pkg_platform = "${pkg_kernel}-${pkg_arch}"
  }

  if $type == 'forwarder' {
    $product = 'universalforwarder'
  } else {
    $product = 'splunk'
  }
  if $source == 'splunk' or $source =~ /http.*/ {
    if $source == 'splunk' {
      $wget_url = "https://download.splunk.com/products/${product}/releases/${version}/linux/${sourcepart}-${version}-${release}-${pkg_platform}.tgz"
    } else {
      $wget_url = "${source}/${newsource}"
    }

    $wget_command = "wget --no-check-certificate -O ${newsource} \'${wget_url}\'"

    notify { 'wget_command':
      message => $wget_command,
    }

    exec { "retrieve_${newsource}":
      command => $wget_command,
      path    => '/bin:/usr/bin:',
      cwd     => $install_path,
      timeout => 600,
      creates => "${install_path}/${newsource}",
      onlyif  => 'curl -I https://www.splunk.com -o /dev/null 2>&1',
    }

    file { "${install_path}/${newsource}":
      owner   => $splunk::user,
      group   => $splunk::group,
      mode    => '0750',
      require => Exec["retrieve_${newsource}"],
    }
  } else {
    file { "${install_path}/${newsource}":
      owner  => $splunk::user,
      group  => $splunk::group,
      mode   => '0750',
      source => "${source}/${newsource}",
    }
  }
}
