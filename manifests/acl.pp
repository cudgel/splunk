define splunk::acl(
  $target,
  $user=$::splunk::splunk_user,
  $group=$::splunk::splunk_group,
  $recurse=false,
  $readonly=true
) {

  # Validate parameters
  #
  if $user and $group {
      fail('Setting both a user and group ACL is not supported')
  }
  if ! $user and ! $group {
      fail('Must specify either a user or a group')
  }
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


  if $::osfamily == 'RedHat' {

    # Calculate the ACE by combining $user, $group, and $readonly.
    # Set the $subject and $db to later verify that the subject exists.
    #
    if $user {
      $subject = $user
      if $readonly == true {
        $acl = "user:${user}:r-x"
      } else {
        $acl = "user:${user}:rwx"
      }
      $db = 'passwd'
      $entity = "user:${user}"

    } else {
      $subject = $group
      if $readonly == true {
        $acl = "group:${group}:r-x"
      } else {
        $acl = "group:${group}:rwx"
      }
      $db = 'group'
      $entity = "group:${group}"
    }

    # test if the ACL is to be applied to an nfs mount
    # (extended posix ACLs cannot be set from the nfs client)
    $testnfs = "df -P ${object} | tail -1 | awk '{print \$NF}' |
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
      target    => '/bin:/usr/bin',
      command => $setfacl,
      unless  => "${testnfs} || getfacl ${object} 2>/dev/null |
egrep -q '${acl}'",
      timeout => '0'
    }

    # set a sane default mask to the object so that group acls work in the
    # absence of liberal traditional permissions
    exec { "set_effective_rights_mask_${title}":
      target    => '/bin:/usr/bin',
      command => "setfacl -R -m 'mask:rwx,default:mask:rwx' ${object}",
      unless  => "${testnfs} || getfacl ${object} 2>/dev/null |
egrep -q '^mask::rwx' ",
      timeout => '0'
    }

  } # end redhat

  if $::osfamily == 'Solaris' {

    # Calculate the ACE by combining $user, $group, and $readonly.
    # Set the $subject and $db to later verify that the subject exists.
    #
    if $user {
      $subject = $user
      if $readonly == true {
        $acl = "user:${user}:rxaRcs"
      } else {
        $acl = "user:${user}:rwxpcCosRrWaAdD"
      }
      $acl_subject = "user:${user}"
      $db = 'passwd'
    } else {
      $subject = $group
      if $readonly == true {
        $acl = "group:${group}:rxaRcs"
      } else {
        $acl = "group:${group}:rwxpcCosRrWaAdD"
      }
      $acl_subject = "group:${group}"
      $db = 'group'
    }

    # Recursive ACLs can only be applied to a directory.
    # Non-recursive ACLs can be applied to anything.
    #
    if $recurse == true {
      $predicate = "test -d ${object}"
      $setfacl   = "find ${object} -type d
-exec chmod A+${acl}:fd:allow '{}' \\; &&
find ${object} -type f -exec chmod A+${acl}:allow '{}' \\; "
    } else {
        $predicate = '/bin/true'
        $setfacl   = "chmod A+${acl}:allow ${object}"
    }

    exec { "chmod_${title}":
        command => "${predicate} &&
getent ${db} ${subject} &&
${setfacl}",
        target    => '/bin:/sbin:/usr/bin:/usr/sbin',
        unless  => "ls -dv ${object} |
egrep '[0-9]:${acl_subject}' >/dev/null",
        timeout => '0',
    }

  } # end solaris

}