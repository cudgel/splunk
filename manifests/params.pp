class splunk::params
{
  $type              = 'forwarder'
  $install_path      = '/opt'
  if $type == 'forwarder' {
    $sourcepart = 'splunkforwarder'
  } else {
    $sourcepart = 'splunk'
  }
  $splunkhome        = "${install_path}/${sourcepart}"
  $splunklocal       = "${splunkhome}/etc/system/local"
  $splunk_user       = 'splunk'
  $splunk_group      = 'splunk'
  $old_version       = '6.0.1'
  $old_release       = '189883'
  $version           = '6.0.3'
  $release           = '204106'
  $splunkdb          = "${splunkhome}/var/lib/splunk"
  $serviceurl        = "http://${::fqdn}"
  $deployment_server = undef
  $maxwarm           = '360000'
  $maxcold           = '720000'

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
    $splunkarch = $architecture ? {
      x86_64  => 'x86_64',
      default => 'i686'
    }
    $splunkext  = 'tgz'
    $tar        = '/bin/tar'
    $tarcmd     = "${tar} xzf"
  } else {
    fail('Unsupported OS')
  }

  $oldsource      = "${sourcepart}-${old_version}-${old_release}-${splunkos}-${splunkarch}.${splunkext}"
  $splunksource   = "${sourcepart}-${version}-${release}-${splunkos}-${splunkarch}.${splunkext}"


}
