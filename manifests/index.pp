# splunk::index()
#
define splunk::index(
  $size         = undef,
  $sign         = false,
  $archive      = false,
  $frozenTime   = $::splunk::params::frozenTime,
  $splunkhome   = $::splunk::splunkhome,
  $local_path   = $::splunk::local_path,
  $splunk_user  = $::splunk::splunk_user,
  $splunk_group = $::splunk::splunk_group,
  $warmpath     = $::splunk::params::warmpath,
  $coldpath     = $::splunk::params::coldpath
  )
{
  file { "${local_path}/indexes.d/${title}":
    owner   => $splunk_user,
    group   => $splunk_group,
    mode    => '0440',
    content => template("${module_name}/index.erb"),
    require => File["${local_path}/indexes.d"],
    notify  => Exec['update-indexes']
  }
}