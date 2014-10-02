class splunk::params
{
  $splunkdb          = "${splunkhome}/var/lib/splunk"
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

  $apppart        = "${::splunk::sourcepart}-${::splunk::version}-${::splunk::release}-${splunkos}-${splunkarch}"
  $oldsource      = "${::splunk::sourcepart}-${::splunk::old_version}-${::splunk::old_release}-${splunkos}-${splunkarch}.${splunkext}"
  $splunksource   = "${apppart}.${splunkext}"
}
