# splunk::index()
#
define index(
  $sign = 'false',
  $archive = 'false',
  $frozenTime,
  $splunkhome,
  $splunklocal
  )
{
  file { "${splunklocal}/indexes.d/${title}":
    owner   => ${::splunk::splunk_user},
    group   => ${::splunk::splunk_group},
    mode    => '0440',
    content => template('splunk/index.erb'),
    require => File["${splunklocal}/indexes.d"],
    notify  => Exec['update-indexes'],
  }
}