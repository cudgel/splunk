# @summary Ensures that the Splunk user can read the file inputs defined
#
# @param target The target file or directory path
# @param group The group to apply ACLs for
# @param type The type of object (file or directory)
# @param recurse Whether to apply ACLs recursively
# @param parents Whether to apply ACLs to parent paths
#
define splunk::acl (
  Optional[String] $target   = undef,
  Optional[String] $group    = undef,
  Optional[String] $type     = undef,
  Optional[Boolean] $recurse = undef,
  Optional[Boolean] $parents = undef,
) {
  if $group {
    $_group = $group
  } elsif defined('::splunk') {
    $_group = $::splunk::user
  } else {
    $_group = 'splunk'
  }
  $_type = pick($type, 'file')
  $_recurse = pick($recurse, false)
  $_parents = pick($parents, false)

  # Validate parameters
  #
  if $target == undef {
    $object = $title
  } else {
    $object = $target
  }
  if $_recurse != true and $_recurse != false {
    fail('variable "recurse" must be either true or false')
  }

  if $facts['kernel'] == 'Linux' {
    # returns 0 if the object is a file
    $testdir = "test -d ${object}"

    # Calculate the ACE by combining $_group, and $readonly.
    # Set the $subject and $db to later verify that the subject exists.
    #
    $subject = $_group
    if $_type == 'file' {
      $perm = 'r--'
    } else {
      $perm = 'r-x'
    }
    $acl = "group:${_group}:${perm}"
    $gacl = "group:${_group}:r-x"

    # returns 0 if the mount containing the object supports ACLs
    $testacl = "getfacl -e ${object} > /dev/null 2>&1"

    exec { "set_acl_${object}":
      command => "setfacl -m ${acl} ${object}",
      onlyif  => $testacl,
      path    => '/bin:/usr/bin:/sbin:/usr/sbin',
    }

    if $_recurse == true {
      exec { "set_acl_recursive_${object}":
        command => "setfacl -R -m ${acl} ${object}",
        onlyif  => $testacl,
        path    => '/bin:/usr/bin:/sbin:/usr/sbin',
      }
    }
  }
}
