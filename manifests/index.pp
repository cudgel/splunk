# splunk::index(
#
# create a index snippet to be concatenated into
# $SPLUNK_HOME/etc/system/local/indexes.conf
#
define splunk::index(
  Optional[Integer] $frozen_time = 188697600,
  Optional[String] $user         = $splunk::user,
  Optional[String] $group        = $splunk::group,
  Optional[String] $dir          = $splunk::dir,
  Optional[Boolean] $sign        = false,
  Optional[Boolean] $archive     = false,
  Optional[Boolean] $remote      = false,
  Optional[Array] $options       = undef
) {
  $local = "${dir}/etc/system/local"

  file { "${local}/indexes.d/${title}":
    owner   => $user,
    group   => $group,
    mode    => '0440',
    content => template("${module_name}/indexes.d/index.erb"),
    require => File["${local}/indexes.d"],
    notify  => Exec['update-indexes'],
  }
}
