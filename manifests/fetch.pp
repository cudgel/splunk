# splunk::fetch()
#
# retrieves the specified splunk or splunkforwarder package directly from
# Splunk instead of from a puppet module if defined
#
# I highly recommend cacheing the images locally and pushing them from a Puppet
# module. The code below expects a configuration similar to this:
#
# [splunk_files]
#   path /etc/puppetlabs/puppet/files/splunk_files
#   allow *
#
define splunk::fetch(
  String $splunk_bundle,
  String $source,
  String $type
) {

  $sourcepart = $splunk::sourcepart
  $version    = $splunk::version
  $release    = $splunk::release

  if $type == 'forwarder' {
    $product = 'universalforwarder'
  } else {
    $product = 'splunk'
  }
  if $source == 'splunk' or source =~ /http.*/  {
    if $source == 'splunk' {
      $wget_url = "https://www.splunk.com/bin/splunk/DownloadActivityServlet?architecture=x86_64&platform=linux&version=${version}&product=${product}&filename=${sourcepart}-${version}-${release}-Linux-x86_64.tgz&wget=true"
    } else {
      $wget_url = "${source}/${splunk_bundle}"
    }

    exec{ "retrieve_${splunk_bundle}":
      command => "wget -O ${splunk_bundle} \'${wget_url}\'",
      path    => "${::splunk::dir}/bin:/bin:/usr/bin:",
      cwd     => $splunk::install_path,
      timeout => 600,
      creates => "${::splunk::install_path}/${splunk_bundle}",
      onlyif  => 'wget --server-response https://www.splunk.com -O /dev/null 2>&1'
    }

    file{ "${::splunk::install_path}/${splunk_bundle}":
      owner   => $splunk::user,
      group   => $splunk::group,
      mode    => '0750',
      require => Exec["retrieve_${splunk_bundle}"],
      notify  => Exec['unpackSplunk']
    }
  } else {
    file{ "${::splunk::install_path}/${splunk_bundle}":
      owner  => $splunk::user,
      group  => $splunk::group,
      mode   => '0750',
      source => "${source}/${splunk_bundle}",
      notify => Exec['unpackSplunk']
    }
  }

}
