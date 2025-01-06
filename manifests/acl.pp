# splunk::acl()
#
# ensures that the Splunk user can read the file inputs defined
# optionally set acls on parent paths
#
# not optimal, but I could not find another solution on the puppet forge
#
define splunk::acl(
  Optional[String] $target    = undef,
  Optional[String] $group     = $splunk::user,
  Optional[String] $type      = 'file',
  Optional[Boolean] $recurse  = false,
  Optional[Boolean] $parents  = false
) {

  # Validate parameters
  #
  if $target == undef {
    $object = $title
  } else {
    $object = $target
  }
  if $recurse != true and $recurse != false {
    fail('variable "recurse" must be either true or false')
  }

  if $facts['kernel'] == 'Linux' {

    # returns 0 if the object is a file
    $testdir = "test -d ${object}"

    # Calculate the ACE by combining $group, and $readonly.
    # Set the $subject and $db to later verify that the subject exists.
    #
    $subject = $group
    if $type == 'file' {
      $perm = 'r--'
    } else {
      $perm = 'r-x'
    }
    $acl = "group:${group}:${perm}"
    $gacl = "group:${group}:r-x"

    # returns 0 if the mount containing the object supports ACLs
    $testacl = "getfacl -e ${object} > /dev/null 2>&1"

    exec { "set_acl_${object}":
      command => "setfacl -m ${acl} ${object}",
      onlyif  => $testacl,
      path    => '/bin:/usr/bin:/sbin:/usr/sbin',
    }

    if $recurse == true {
      exec { "set_acl_recursive_${object}":
        command => "setfacl -R -m ${acl} ${object}",
        onlyif  => $testacl,
        path    => '/bin:/usr/bin:/sbin:/usr/sbin',
      }
    }
  }
}
