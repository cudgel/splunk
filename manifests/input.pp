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
    owner   => ${splunk_user},
    group   => ${splunk_group},
    mode    => '0440',
    content => template('splunk/input.erb'),
    require => File["${splunklocal}/inputs.d"],
    notify  => Exec['update-inputs'],
  }

  if $inputtype == 'monitor' {
    fooacl::conf { "${target}":
      permissions     => "group:${splunk_group}:r-X"
    }
  }

  exec { 'update-inputs':
    command     => "/bin/cat ${splunklocal}/inputs.d/* > ${splunklocal}/inputs.conf; \
chown ${splunk_user}:${splunk_group} ${splunklocal}/inputs.conf",
    refreshonly => true,
    subscribe   => File["${splunklocal}/inputs.d/000_default"],
    notify      => Service[splunk],
  }
}