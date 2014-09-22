class splunk::apps::sos($tier='forwarder')
{
#
# Do not include this class on a host that does not already have Puppet managing the Splunk install.
#

    case $tier {
        'forwarder': { $splunkhome = '/opt/splunkforwarder' }
        default: { $splunkhome = '/opt/splunk' }
    }

    $myapp = 'sos'
    $oldsource = 'TA-SoS_2.0.2-135609.tar.gz'
    $version = '2.0.4'
    $build = '160984'
    $mysource = "TA-SoS_${version}-${build}.tar.gz"
    $splunkapps = "${splunkhome}/etc/apps"
    $myappdir = "${splunkapps}/TA-sos"

    file { "${splunkapps}/${oldsource}":
        ensure => absent
    }

    file { "${splunkapps}/${mysource}":
        alias   => 'sos-app',
        source  => "puppet:///modules/splunk/apps/sos/${mysource}",
        owner   => 'splunk',
        group   => 'splunk',
        mode    => '0700',
        replace => false,
        notify  => Exec['unpack-sos'],
        require => File["${splunkhome}"]
    }

    case $osfamily {
        "RedHat": { $tar = "/bin/tar" }
        "Solaris": { $tar = "/usr/sfw/bin/gtar" }
    }

    exec { "${tar} zxf $mysource":
        alias       => 'unpack-sos',
        cwd         => "${splunkapps}",
        subscribe   => File['sos-app'],
        unless      => "grep ${version} ${myappdir}/default/app.conf",
        path        => '/bin:/usr/bin',
        refreshonly => true,
        creates     => "${myappdir}"
    }

    file { "${myappdir}":
        owner   => 'splunk',
        group   => 'splunk',
        recurse => true
    }

    file { "${myappdir}/local":
        ensure  => 'directory',
        owner   => 'splunk',
        group   => 'splunk',
        mode    => '0644',
        require => File["${myappdir}"],
        alias   => "${myapp}_local"
    }

    file { "${myappdir}/local/inputs.conf":
        content => template('splunk/apps/sos/inputs.erb'),
        owner   => 'splunk',
        group   => 'splunk',
        mode    => '0644',
        require => File["${myapp}_local"],
        notify  => Service[splunk]
    }

}
