# splunk::auth()
#
# create authentication.conf and authorize.conf files to configure
# user authentication and roles
#
class splunk::auth(
  Optional[String] $dir            = $splunk::dir,
  Optional[String] $user           = $splunk::user,
  Optional[String] $group          = $splunk::group,
  Optional[String] $authentication = $splunk::authentication,
  Optional[Hash] $authconfig       = $splunk::authconfig,
  Optional[String] $body           = undef
) {

  $local    = "${dir}/etc/system/local"


  file { "${local}/auth.d":
    ensure  => 'directory',
    mode    => '0750',
    owner   => $user,
    group   => $group,
    require => Exec['test_for_splunk']
  }

  if $authentication == 'LDAP' {
    $content = template("${module_name}/auth.d/ldap.erb")
  } else {
    $content = $body
  }

  file { "${local}/auth.d/ldap":
    owner   => $user,
    group   => $group,
    mode    => '0440',
    content => $content,
    require => File["${local}/auth.d"],
    notify  => Exec['update-server']
  }

}
