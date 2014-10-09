# splunk::input()
#
define splunk::input(
  $splunkhome   = $::splunk::splunkhome,
  $splunklocal  = $::splunk::splunklocal,
  $splunk_user  = $::splunk::splunk_user,
  $splunk_group = $::splunk::splunk_group,
  $disabled     = false,
  $target       = '',
  $inputtype    = 'monitor',
  $sourcetype   = 'auto',
  $index        = '',
  $cache        = true,
  $size         = '1',
  $options      = [],
  $recurse      = false,
  $content      = undef
  )
{

  if $content != undef {
    $mycontent = $content
  } else {
    $mycontent = template("${module_name}/input.erb")
    if $inputtype == 'monitor' {
      fooacl::conf { $target:
        permissions     => ["group:${splunk_group}:r-X"]
      }
    }
  }

  file { "${splunklocal}/inputs.d/${title}":
    owner   => $splunk_user,
    group   => $splunk_group,
    mode    => '0440',
    content => $mycontent,
    require => File["${splunklocal}/inputs.d"],
    notify  => Exec['update-inputs'],
  }


}