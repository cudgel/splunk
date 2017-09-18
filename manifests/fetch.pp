# splunk::fetch()
#
# retrieves the specified splunk or splunkforwarder package directly from
# Splunk instead of from a local file source
#
define splunk::fetch(
  $splunksource,
  $sourcepart = $::splunk::sourcepart,
  $version = $::splunk::version,
  $release = $::splunk::release) {

  $wget_url = "https://www.splunk.com/bin/splunk/DownloadActivityServlet?architecture=x86_64&platform=linux&version=${version}&product=${sourcepart}&filename=${sourcepart}-${version}-${release}-Linux-x86_64.tgz&wget=true"

  exec{"retrieve_${splunksource}":
    command => "wget -O ${splunksource} \'${wget_url}\'",
    path    => "${::splunk::splunkhome}/bin:/bin:/usr/bin:",
    cwd     => $::splunk::install_path,
    creates => "${::splunk::install_path}/${splunksource}"
  }

  file{"${::splunk::install_path}/${splunksource}":
    owner   => $::splunk::splunk_user,
    group   => $::splunk::splunk_group,
    mode    => '0750',
    require => Exec["retrieve_${splunksource}"],
    notify  => Exec['unpackSplunk']
  }

}
