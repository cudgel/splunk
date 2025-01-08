# splunk::input()
#
# create a network or file monitor input snippet to be concatenated into
# $SPLUNK_HOME/etc/system/local/inputs.conf
# if creating a file monitor, apply acl to the object as well
#
define splunk::input (
  Boolean $disabled  = false,
  String $inputtype  = 'monitor',
  String $sourcetype = 'auto',
  String $index      = 'default',
  Boolean $cache     = true,
  Integer $size      = 1,
  Boolean $recurse   = false,
  Optional[String] $target     = undef,
  Optional[String] $dir        = $splunk::dir,
  Optional[String] $user       = $splunk::user,
  Optional[String] $group      = $splunk::group,
  Optional[Array] $options     = undef,
  Optional[String] $content    = undef
) {
  $local    = "${dir}/etc/system/local"

  # Validate parameters
  #
  if $target == undef {
    $target = $title
  }

  if $content == undef {
    $body = template("${module_name}/inputs.d/input.erb")
    if $inputtype == 'monitor' {
      splunk::acl { $title:
        target  => $target,
        group   => $group,
        recurse => $recurse,
      }
    }
  } else {
    $body = $content
  }

  file { "${local}/inputs.d/${title}":
    owner   => $user,
    group   => $group,
    mode    => '0440',
    content => $body,
    require => File["${local}/inputs.d"],
    notify  => Exec['update-inputs'],
  }
}
