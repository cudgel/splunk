class splunk::params
{
    $install_path   = '/opt'
    $splunkhome     = "${install_path}/splunk"
    $splunklocal    = "${splunkhome}/etc/system/local"
    $splunk_user    = 'splunk',
    $splunk_group   = 'splunk',
    $old_version    = '6.0.1'
    $old_release    = '189883'
    $version        = '6.0.3'
    $release        = '204106'
    $splunkdb       = "${splunkhome}/var/lib/splunk"

    if $osfamily    == "Solaris" {
        $splunkos   = 'SunOS'
        $splunkarch = $architecture ? {
            i86pc   => 'x86_64',
            default => 'sparc'
        }
        $splunkext  = 'tar.Z'
        $tar        = '/usr/sfw/bin/gtar'
        $tarcmd     = "${tar} xZf"
    } elsif $kernel == "Linux" {
        $splunkos   = 'Linux'
        $splunkarch = $architecture ? {
            x86_64  => 'x86_64',
            default => 'i686'
        }
        $splunkext  = 'tgz'
        $tar        = '/bin/tar'
        $tarcmd     = "${tar} xzf"
    } else {
        fail("Unsupported OS")
    }

    $oldsource      = "splunk-${old_version}-${old_release}-${splunkos}-${splunkarch}.${splunkext}"
    $splunksource   = "splunk-${version}-${release}-${splunkos}-${splunkarch}.${splunkext}"

}
