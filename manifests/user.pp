# create a splunk user - for ci/testing only
# manage your real accounts properly
class splunk::user {
  $user  = $splunk::user
  $group = $splunk::group

  group { $group:
    ensure => present,
    name   => $group,
  }

  user { $user:
    ensure     => present,
    name       => $user,
    comment    => 'Splunk service account',
    managehome => true,
    provider   => useradd,
    gid        => $group,
  }
}
