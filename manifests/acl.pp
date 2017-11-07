define splunk::acl(
  $target   = '',
  $group    = $::splunk::splunk_group,
  $recurse  = false,
  $readonly = true,
  $parents  = false
) {

  # Validate parameters
  #
  if $target == '' {
      $object = $title
  } else {
      $object = $target
  }
  if $readonly != true and $readonly != false {
      fail('variable "readonly" must be either true or false')
  }
  if $recurse != true and $recurse != false {
      fail('variable "recurse" must be either true or false')
  }

  if $::kernel == 'Linux' {

    # Calculate the ACE by combining $group, and $readonly.
    # Set the $subject and $db to later verify that the subject exists.
    #
    $subject = $group
    if $readonly == true {
      $perm = 'r-x'
    } else {
      $perm = 'rwx'
    }
    $acl = "group:${group}:${perm}"
    $gacl = "group:${group}:r-x"

    # test if the ACL is to be applied to an nfs mount
    # (extended posix ACLs cannot be set from the nfs client)
    # returns 0 if object is on nfs mount
    $testnfs = "df -P ${object} | tail -1 | awk '{print \$1}' |
fgrep -f - /proc/mounts | grep -q nfs"

    # Recursive ACLs can only be applied to a directory.
    # Non-recursive ACLs can be applied to anything.
    #
    if $recurse == true {
      $setfacl   = "setfacl -R -m ${acl} ${object} &&
setfacl -d -R -m ${acl} ${object}"
    } else {
      $setfacl   = "setfacl -m ${acl} ${object}"
    }

    # apply the acl to the object, unless it is an nfs mount
    # throw an error if acl's not supported on filesystem
    #
    exec { "setfacl_${title}":
      path    => '/bin:/usr/bin',
      command => $setfacl,
      unless  => "${testnfs} || getfacl ${object} 2>/dev/null |
egrep -q '${acl}'",
      timeout => '0'
    }

    # set a sane default mask to the object so that group acls work in the
    # absence of liberal traditional permissions
    exec { "set_effective_rights_mask_${title}":
      path    => '/bin:/usr/bin',
      command => "setfacl -R -m mask:${perm},default:mask:${perm} ${object}",
      unless  => "${testnfs} || test -f ${object} || getfacl ${object} 2>/dev/null |
egrep -q '^mask::r-x' ",
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
            unless  => "${testnfs} || getfacl ${full_path} 2>/dev/null |
      egrep -q '${gacl}'",
            timeout => '0'
          }

          exec { "set_effective_rights_mask_${directory}":
            path    => '/bin:/usr/bin',
            command => "setfacl -m mask:r-x,default:mask:r-x ${full_path}",
            unless  => "${testnfs} || getfacl ${full_path} 2>/dev/null |
      egrep -q '^mask::r-x' ",
            timeout => '0'
          }
        }
      }
    }

  } # end linux

}
