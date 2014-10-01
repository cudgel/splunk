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
  $splunklocal,
  $options = '',
  $recurse = 'false'
  )
{

  file { "${splunklocal}/inputs.d/${title}":
    owner   => ${::splunk::splunk_user},
    group   => ${::splunk::splunk_group},
    mode    => '0440',
    content => template('splunk/input.erb'),
    require => File["${splunklocal}/inputs.d"],
    notify  => Exec['update-inputs'],
  }

  if $inputtype == 'monitor' {
    fooacl::conf { "${target}":
      permissions     => "group:${splunk::splunk_group}:r-X"
    }
  }
}