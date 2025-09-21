# @summary Create a network or file monitor input snippet to be concatenated into inputs.conf
#
# @param disabled Whether the input is disabled
# @param inputtype The type of input (monitor, tcp, udp, etc.)
# @param sourcetype The sourcetype for the input
# @param index The index to send data to
# @param cache Whether to use persistent queue for network inputs
# @param size Size of queue on disk in GB
# @param recurse Whether to recurse for file monitor inputs
# @param target The target file or port for the input
# @param dir The Splunk directory path
# @param user The Splunk user
# @param group The Splunk group
# @param options Additional input options
# @param content Custom input definition content
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
