# splunk::input()
#
# create a network or file monitor input snippet to be concatenated into
# $SPLUNK_HOME/etc/system/local/inputs.conf
# if creating a file monitor, apply acl to the object as well
#
define splunk::input(
  String $target,
  Optional[String] $dir        = $splunk::dir,
  Optional[String] $user       = $splunk::splunk_user,
  Optional[String] $group      = $splunk::splunk_group,
  Optional[Boolean] $disabled  = false,
  Optional[String] $inputtype  = 'monitor',
  Optional[String] $sourcetype = 'auto',
  Optional[String] $index      = 'default',
  Optional[Boolean] $cache     = true,
  Optional[Integer] $size      = 1,
  Optional[Hash] $options      = undef,
  Optional[Boolean] $recurse   = false,
  Optional[String] $content    = undef
  )
{

  $local    = "${dir}/etc/system/local"

  if $content != undef {
    $mycontent = $content
  } else {
    $mycontent = template("${module_name}/inputs.d/input.erb")
    if $inputtype == 'monitor' {
      splunk::acl { $title:
        target   => $target,
        group    => $group,
        recurse  => $recurse,
        readonly => true
      }
    }
  }

  file { "${local}/inputs.d/${title}":
    owner   => $user,
    group   => $group,
    mode    => '0440',
    content => $mycontent,
    require => File["${local}/inputs.d"],
    notify  => Exec['update-inputs']
  }


}
