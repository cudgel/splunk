# splunk::acl()
#
# ensures that the Splunk user can read the file inputs defined
# optionally set acls on parent paths
#
# not optimal, but I could not find another solution on the puppet forge
#
define splunk::acl(
  Optional[String] $target    = undef,
  Optional[String] $group     = $splunk::splunk_user,
  Optional[String] $type      = 'file',
  Optional[Boolean] $recurse  = false,
  Optional[Boolean] $readonly = true,
  Optional[Boolean] $parents  = false
) {

  # Validate parameters
  #
  if $target != undef {
      $object = $title
  } else {
      $object = $target
  }
  if $recurse != true and $recurse != false {
      fail('variable "recurse" must be either true or false')
  }

  if $kernel == 'Linux' {

    # returns 0 if the object is a file
    $testdir = "test -d ${object}"

    # Calculate the ACE by combining $group, and $readonly.
    # Set the $subject and $db to later verify that the subject exists.
    #
    $subject = $group
    if $type == 'file' or $testdir == false {
      if $readonly == false {
        $perm = 'rw-'
      } else {
        $perm = 'r--'
      }
    } else {
      if $readonly == false {
        $perm = 'rwx'
      } else {
        $perm = 'r-x'
      }
    }
    $acl = "group:${group}:${perm}"
    $gacl = "group:${group}:r-x"

    # test if the ACL is to be applied to an nfs mount
    # (extended posix ACLs cannot be set from the nfs client)
    # returns 0 if object is on nfs mount
    $testnfs = "df -P ${object} | tail -1 | awk '{print \$1}' \
| fgrep -f - /proc/mounts | grep -q nfs"

    # returns 0 if the mount containing the object suports ACLs
    $testacl = "df -P ${object} | tail -1 | awk '{print \$1}' \
| fgrep -f - /proc/mounts | grep -q seclabel"

    # Non-recursive ACLs can be applied to anything.
    #
    if $recurse == true {
      $setfacl   = "setfacl -R -m ${acl} ${object} && setfacl -d -R -m ${acl} ${object}"
    } else {
      $setfacl   = "setfacl -m ${acl} ${object}"
    }

    # apply the acl to the object, unless it is an nfs mount
    # throw an error if acl's not supported on filesystem
    #
    exec { "setfacl_${title}":
      path    => '/bin:/usr/bin',
      command => $setfacl,
      onlyif  => $testacl,
      unless  => "getfacl ${object} 2>/dev/null | egrep -q '${acl}'",
      timeout => '0'
    }

    # set a sane default mask to the object so that group acls work in the
    # absence of liberal traditional permissions
    exec { "set_effective_rights_mask_${title}":
      path    => '/bin:/usr/bin',
      command => "setfacl -R -m mask:${perm},default:mask:${perm} ${object}",
      onlyif  => "${testacl} && ${testdir}",
      unless  => "getfacl ${object} 2>/dev/null | egrep -q '^mask::r-x' ",
      timeout => '0'
    }

    if $parents == true {
      $directories = split($object, '/')

      $directories.each |$index, $directory| {
        $calculated_dir = inline_template("<%= @directories[0, @index + 1].join('/') %>")
        $full_path = "/${calculated_dir}"
        if (! defined(File[$full_path]) and $full_path != '/') {
          exec { "setfacl_${directory}":
            path    => '/bin:/usr/bin',
            command => "setfacl -m ${gacl} ${full_path}",
            onlyif  => "${testacl} && ${testdir}",
            unless  => "getfacl ${full_path} 2>/dev/null | egrep -q '${gacl}'",
            timeout => '0'
          }

          exec { "set_effective_rights_mask_${directory}":
            path    => '/bin:/usr/bin',
            command => "setfacl -m mask:r-x,default:mask:r-x ${full_path}",
            onlyif  => "${testacl} && ${testdir}",
            unless  => "getfacl ${full_path} 2>/dev/null | egrep -q '^mask::r-x' ",
            timeout => '0'
          }
        }
      }
    }

  } # end linux

}
