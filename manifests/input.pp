# splunk::input()
#
define input(
  $disabled = 'false',
  $target = '',
  $inputtype = 'monitor',
  $sourcetype = 'auto',
  $index = '',
  $cache = 'true',
  $size = '1',
  $splunkhome,
  $local_conf,
  $options = '',
  $recurse = 'false'
  )
{

  file { "${local_conf}/inputs.d/${title}":
    owner   => ${splunk::params::user},
    group   => ${splunk::params::group},
    mode    => '0440',
    content => template('splunk/input.erb'),
    require => File["${local_conf}/inputs.d"],
    notify  => Exec['update-inputs'],
  }

  if $inputtype == 'monitor' {
    fooacl::conf { "${target}":
      permissions     => "group:${splunk::params::group}:r-X"
    }
  }
}