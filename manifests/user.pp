# create a splunk user - for ci/testing only
# manage your real accounts properly
class splunk::user {

  $splunk_user       = $::splunk::splunk_user
  $splunk_group      = $::splunk::splunk_group

  user { $splunk_user:
    name           => $splunk_user,
    ensure         => present,
    comment        => 'Splunk service account',
    gid            => $splunk_group
  }
}
