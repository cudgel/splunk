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
class splunk::fetch
{
  $source       = $splunk::source
  $sourcepart   = $splunk::sourcepart
  $type         = $splunk::type
  $version      = $splunk::version
  $release      = $splunk::release
  $newsource    = $splunk::newsource
  $install_path = $splunk::install_path

  if $type == 'forwarder' {
    $product = 'universalforwarder'
  } else {
    $product = 'splunk'
  }
  if $source == 'splunk' or source =~ /http.*/  {
    if $source == 'splunk' {
      $curl_url = "https://www.splunk.com/bin/splunk/DownloadActivityServlet?architecture=x86_64&platform=linux&version=${version}&product=${product}&filename=${sourcepart}-${version}-${release}-Linux-x86_64.tgz&wget=true"
    } else {
      $curl_url = "${source}/${newsource}"
    }

    exec{ "retrieve_${newsource}":
      command => "curl -Lo ${newsource} \'${curl_url}\'",
      path    => '/bin:/usr/bin:',
      cwd     => $install_path,
      timeout => 600,
      creates => "${install_path}/${newsource}",
      onlyif  => 'curl -I https://www.splunk.com -o /dev/null 2>&1'
    }

    file{ "${install_path}/${newsource}":
      owner   => $splunk::user,
      group   => $splunk::group,
      mode    => '0750',
      require => Exec["retrieve_${newsource}"]
    }
  } else {
    file{ "${install_path}/${newsource}":
      owner  => $splunk::user,
      group  => $splunk::group,
      mode   => '0750',
      source => "${source}/${newsource}"
    }
  }

}
