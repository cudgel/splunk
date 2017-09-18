define splunk::fetch(
  $splunksource,
  $sourcepart = $::splunk::sourcepart,
  $version = $::splunk::version,
  $release = $::splunk::release) {


  exec{"retrieve_${splunksource}":
    command => "/usr/bin/wget -O ${splunksource} https://www.splunk.com/bin/splunk/DownloadActivityServlet?architecture=x86_64&platform=linux&version=${version}&product=${sourcepart}&filename=${sourcepart}-${version}-${release}-Linux-x86_64.tgz&wget=true",
    cwd     => $::splunk::install_path,
    creates => "$::splunk::install_path}/$$splunksource",
    user    => $::splunk::splunk_user,
    group   => $::splunk::splunk_group
  }

  file{"${::splunk::install_path}/${splunksource}":
    owner   => $::splunk::splunk_user,
    group   => $::splunk::splunk_group,
    mode    => '0750',
    require => Exec["retrieve_${splunksource}"],
    notify  => Exec['unpackSplunk']
  }

}
