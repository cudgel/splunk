# splunk::input()
#
# create a network or file monitor input snippet to be concatenated into
# $SPLUNK_HOME/etc/system/local/inputs.conf
# if creating a file monitor, apply acl to the object as well
#
define splunk::input(
  $splunkdir    = $::splunk::splunkdir,
  $local_path   = $::splunk::local_path,
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
    $mycontent = template("${module_name}/inputs.d/input.erb")
    if $inputtype == 'monitor' {
      splunk::acl { $title:
        target   => $target,
        group    => $splunk_group,
        recurse  => $recurse,
        readonly => true
      }
    }
  }

  file { "${local_path}/inputs.d/${title}":
    owner   => $splunk_user,
    group   => $splunk_group,
    mode    => '0440',
    content => $mycontent,
    require => File["${local_path}/inputs.d"],
    notify  => Exec['update-inputs'],
  }


}
