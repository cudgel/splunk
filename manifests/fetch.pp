define splunk::fetch(
  $sourcefile,
  $sourcepart = $::splunk::sourcepart,
  $version = $::splunk::version,
  $release = $::splunk::release) {


  exec{"retrieve_${sourcefile}":
    command => "/usr/bin/wget -O ${sourcefile} https://www.splunk.com/bin/splunk/DownloadActivityServlet?architecture=x86_64&platform=linux&version=${version}&product=${sourcepart}&filename=${sourcepart}-${version}-${release}-Linux-x86_64.tgz&wget=true",
    cwd     => $::splunk::install_path,
    creates => $sourcefile,
    user    => $::splunk::splunk_user,
    group   => $::splunk::splunk_group
  }

  file{"${::splunk::install_path}/${sourcefile}":
    owner   => $::splunk::splunk_user,
    group   => $::splunk::splunk_group,
    mode    => '0750',
    require => Exec["retrieve_${sourcefile}"],
    notify  => Exec['unpackSplunk']
  }

}
