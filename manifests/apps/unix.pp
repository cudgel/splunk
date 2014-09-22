class splunk::apps::unix($tier='forwarder')
{
#
# Do not include this class on a host that does not already have Puppet managing the Splunk install.
#

    case $tier {
        'forwarder': { $splunkhome = '/opt/splunkforwarder' }
        default: { $splunkhome = '/opt/splunk' }
    }

    $myapp = 'Splunk_TA_nix'
    $version = '5.0.2'
    $release = '188215'
    $oldsource = 'Splunk_TA_nix-5.0.0-181970.tgz'
    $mysource = "${myapp}-${version}-${release}.tgz"
    $splunkapps = "${splunkhome}/etc/apps"
    $myappdir = "${splunkapps}/${myapp}"

    file { "${splunkapps}/${oldsource}":
        ensure => absent
    }

    file { "${splunkapps}/${mysource}":
        alias   => 'nix-app',
        source  => "puppet:///modules/splunk/apps/unix/${mysource}",
        owner   => 'splunk',
        group   => 'splunk',
        mode    => '0700',
        replace => false,
        notify  => Exec['unpack-nix'],
        require => File["${splunkhome}"]
    }

    case $osfamily {
        "RedHat": { $tar = "/bin/tar" }
        "Solaris": { $tar = "/usr/sfw/bin/gtar" }
    }

    exec { "${tar} zxf $mysource":
        alias       => "unpack-nix",
        cwd         => "${splunkapps}",
        subscribe   => File['nix-app'],
        unless      => "grep ${version} ${myappdir}/default/app.conf",
        path        => '/bin:/usr/bin'
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

    file { "${myappdir}/local/app.conf":
        source  => "puppet:///modules/splunk/apps/unix/app.conf",
        owner   => 'splunk',
        group   => 'splunk',
        mode    => '0644',
        require => File["${myapp}_local"],
        notify  => Service[splunk]
    }

    file { "${myappdir}/local/indexes.conf":
        content => template('splunk/apps/unix/indexes.erb'),
        owner   => 'splunk',
        group   => 'splunk',
        mode    => '0644',
        require => File["${myapp}_local"],
        notify  => Service[splunk]
    }

    file { "${myappdir}/local/inputs.conf":
        content => template('splunk/apps/unix/inputs.erb'),
        owner   => 'splunk',
        group   => 'splunk',
        mode    => '0644',
        require => File["${myapp}_local"],
        notify  => Service[splunk]
    }

    file { "${myappdir}/bin/common.sh":
        source  => "puppet:///modules/splunk/apps/unix/common.sh",
        owner   => 'splunk',
        group   => 'splunk',
        mode    => '0755',
        require => File["${myappdir}"]
    }

    file { "${myappdir}/bin/netstat.sh":
        source  => "puppet:///modules/splunk/apps/unix/netstat.sh",
        owner   => 'splunk',
        group   => 'splunk',
        mode    => '0755',
        require => File["${myappdir}"]
    }

}

