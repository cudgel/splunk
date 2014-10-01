# splunk::index()
#
define index(
  $sign = 'false',
  $archive = 'false',
  $frozenTime,
  $splunkhome,
  $local_conf
  )
{
  file { "${local_conf}/indexes.d/${title}":
    owner   => ${splunk_user},
    group   => ${splunk_group},
    mode    => '0440',
    content => template('splunk/index.erb'),
    require => File["${local_conf}/indexes.d"],
    notify  => Exec['update-indexes'],
  }
}