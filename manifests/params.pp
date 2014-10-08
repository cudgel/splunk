class splunk::params
{
  $version           = hiera('splunk::params::version', undef)
  $release           = hiera('splunk::params::release', undef)
  $splunk_user       = hiera('splunk::params::splunk_user', 'splunk')
  $splunk_group      = hiera('splunk::params::splunk_group', 'splunk')
  $old_version       = hiera('splunk::params::old_version', undef)
  $old_release       = hiera('splunk::params::old_release', undef)
  $deployment_server = hiera('splunk::params::deployment_server', undef)
  $install_path      = hiera('splunk::params::install_path', '/opt')
  $warmpath          = hiera('splunk::params::warmpath', undef)
  $coldpath          = hiera('splunk::params::coldpath', undef)
  $maxwarm           = hiera('splunk::params::maxwarm', undef)
  $maxcold           = hiera('splunk::params::maxcold', undef)

  if $::osfamily    == 'Solaris' {
    $splunkos   = 'SunOS'
    $splunkarch = $::architecture ? {
      i86pc   => 'x86_64',
      default => 'sparc'
    }
    $splunkext  = 'tar.Z'
    $tar        = '/usr/sfw/bin/gtar'
    $tarcmd     = "${tar} xZf"
  } elsif $::kernel == 'Linux' {
    $splunkos   = 'Linux'
    $splunkarch = $::architecture ? {
      x86_64  => 'x86_64',
      default => 'i686'
    }
    $splunkext  = 'tgz'
    $tar        = '/bin/tar'
    $tarcmd     = "${tar} xzf"
  } else {
    fail('Unsupported OS')
  }
}
