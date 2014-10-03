# splunk::index()
#
define index(
  $frozenTime,
  $sign         = false,
  $archive      = false,
  $splunkhome   = $::splunk::splunkhome,
  $splunklocal  = $::splunk::splunklocal,
  $splunk_user  = $::splunk::splunk_user,
  $splunk_group = $::splunk::splunk_group,
  $warmpath     = $::splunk::params::warmpath,
  $coldpath     = $::splunk::params::coldpath
  )
{
  file { "${splunklocal}/indexes.d/${title}":
    owner   => $splunk_user,
    group   => $splunk_group,
    mode    => '0440',
    content => template("${module_name}/index.erb"),
    require => File["${splunklocal}/indexes.d"],
    notify  => Exec['update-indexes'],
  }
}