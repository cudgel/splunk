# @summary Create an index snippet to be concatenated into indexes.conf
#
# @param frozen_time Time in seconds after which data is frozen
# @param user The Splunk user
# @param group The Splunk group
# @param dir The Splunk directory path
# @param sign Whether to sign the index
# @param archive Whether to archive the index
# @param remote Whether this is a remote index
# @param options Additional index options
#
define splunk::index (
  Optional[Integer] $frozen_time = undef,
  Optional[String] $user         = $splunk::user,
  Optional[String] $group        = $splunk::group,
  Optional[String] $dir          = $splunk::dir,
  Optional[Boolean] $sign        = undef,
  Optional[Boolean] $archive     = undef,
  Optional[Boolean] $remote      = undef,
  Optional[Array] $options       = undef,
) {
  $_frozen_time = pick($frozen_time, 188697600)
  $_sign = pick($sign, false)
  $_archive = pick($archive, false)
  $_remote = pick($remote, false)
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
