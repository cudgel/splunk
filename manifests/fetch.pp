# splunk::fetch()
#
# retrieves the specified splunk or splunkforwarder package directly from
# Splunk instead of from puppet fileserver if no
#
define splunk::fetch(
  $splunk_bundle,
  $source,
  $type,
  $sourcepart = $splunk::sourcepart,
  $version    = $splunk::version,
  $release    = $splunk::release) {

  if $type == 'forwarder' {
    $product = 'universalforwarder'
  } else {
    $product = 'splunk'
  }

  if $source == 'fileserver' {

    file{ "${::splunk::install_path}/${splunk_bundle}":
      owner  => $splunk::splunk_user,
      group  => $splunk::splunk_group,
      mode   => '0750',
      source => "puppet:///splunk_files/${splunk_bundle}",
      notify => Exec['unpackSplunk']
    }

  } else {

    if $source == 'splunk' {
      $wget_url = "https://www.splunk.com/bin/splunk/DownloadActivityServlet?architecture=x86_64&platform=linux&version=${version}&product=${product}&filename=${sourcepart}-${version}-${release}-Linux-x86_64.tgz&wget=true"
    } else {
      $wget_url = "${source}/${splunk_bundle}"
    }

    exec{ "retrieve_${splunk_bundle}":
      command => "wget -O ${splunk_bundle} \'${wget_url}\'",
      path    => "${::splunk::splunkdir}/bin:/bin:/usr/bin:",
      cwd     => $splunk::install_path,
      timeout => 600,
      creates => "${::splunk::install_path}/${splunk_bundle}",
      onlyif  => 'wget --server-response https://www.splunk.com -O /dev/null 2>&1'
    }

    file{ "${::splunk::install_path}/${splunk_bundle}":
      owner   => $splunk::splunk_user,
      group   => $splunk::splunk_group,
      mode    => '0750',
      require => Exec["retrieve_${splunk_bundle}"],
      notify  => Exec['unpackSplunk']
    }
  }

}
