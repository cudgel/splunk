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
  Optional[Tuple] $roles           = $splunk::roles,
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

    file { "${local}/auth.d/ldap":
      owner   => $user,
      group   => $group,
      mode    => '0600',
      content => $content,
      require => File["${local}/auth.d"],
      notify  => Exec['update-auth']
    }
  } elsif $authentication == 'SAML' {
    $content = template("${module_name}/auth.d/saml.erb")

    file { "${local}/auth.d/saml":
      owner   => $user,
      group   => $group,
      mode    => '0600',
      content => $content,
      require => File["${local}/auth.d"],
      notify  => Exec['update-auth']
    }

    file { "${local}/auth.d/ldap":
      ensure => absent
    }
  } else {
    file { "${local}/auth.d/ldap":
      ensure => absent
    }
  }

  if $roles.is_a(Tuple) {
    file { "${local}/authorize.conf":
      owner   => $user,
      group   => $group,
      mode    => '0440',
      content => template("${module_name}/authorize.conf.erb"),
      require => File[$local],
      notify  => Service['splunk']
    }
  }
}
