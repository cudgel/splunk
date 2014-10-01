# splunk::index()
#
define index(
  $frozenTime,
  $sign = false,
  $archive = false,
  $splunkhome=$::splunk::splunkhome,
  $splunklocal=$::splunk::splunklocal,
  $splunk_user=$::splunk::splunk_user,
  $splunk_group=$::splunk::splunk_group
  )
{
  file { "${splunklocal}/indexes.d/${title}":
    owner   => $splunk_user,
    group   => $splunk_group,
    mode    => '0440',
    content => template('splunk/index.erb'),
    require => File["${splunklocal}/indexes.d"],
    notify  => Exec['update-indexes'],
  }
}