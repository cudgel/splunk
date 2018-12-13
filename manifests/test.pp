# create inputs and apply acls on forwarders
# for ci testing only
class splunk::test {

    # create OS, role, and host specific inputs
    $my_inputs = lookup('splunk::inputs')
    if is_hash($my_inputs) and $my_inputs != undef {
      create_resources('splunk::input', $my_inputs)
    }

    # set up any ACLs definied  at the OS, role or host for splunk group
    # log access
    $my_acls = lookup('splunk::acls')
    if is_hash($my_acls) and $my_acls != undef {
      create_resources('splunk::acl', $my_acls)
    }
}
