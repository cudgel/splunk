# create inputs and apply acls on forwarders
# for ci testing only
class splunk::test {

    # create OS, role, and host specific inputs
    $my_inputs = hiera_hash('splunk::inputs')
    create_resources('splunk::input', $my_inputs)

    # set up any ACLs definied  at the OS, role or host for splunk group
    # log access
    $my_acls = hiera_hash('splunk::acls')
    create_resources('splunk::acl', $my_acls)
}
