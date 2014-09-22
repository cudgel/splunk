class splunk::apps::varnish($tier='forwarder')
{
#
# Do not include this class on a host that does not already have Puppet managing the Splunk install.
#

    case $tier {
        'forwarder': { $splunkhome = '/opt/splunkforwarder' }
        default: { $splunkhome = '/opt/splunk' }
    }

    $myapp = varnishmonitor
    $version = '0.1'
    $mysource = 'varnishmonitor.tar.gz'
    $splunkapps = "${splunkhome}/etc/apps"
    $myappdir = "${splunkapps}/${myapp}"

    file { "${splunkapps}/${mysource}":
        alias   => 'varnish-app',
        source  => "puppet:///modules/splunk/apps/varnish/${mysource}",
        owner   => 'splunk',
        group   => 'splunk',
        mode    => '0700',
        replace => false,
        notify  => Exec['unpack-varnish']
    }

    case $osfamily {
        "RedHat": { $tar = "/bin/tar" }
        "Solaris": { $tar = "/usr/sfw/bin/gtar" }
    }

    exec { "${tar} zxf $mysource":
        alias       => "unpack-varnish",
        cwd         => "${splunkapps}",
        subscribe   => File['varnish-app'],
        unless      => "grep ${version} ${myappdir}/local/app.conf",
        path        => '/bin:/usr/bin',
        notify      => Service[splunk]
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
        source  => "puppet:///modules/splunk/apps/varnish/app.conf",
        owner   => 'splunk',
        group   => 'splunk',
        mode    => '0644',
        require => File["${myapp}_local"],
        notify  => Service[splunk]
    }

    file { "${myappdir}/local/indexes.conf":
        content => template('splunk/apps/varnish/indexes.erb'),
        owner   => 'splunk',
        group   => 'splunk',
        mode    => '0644',
        require => File["${myapp}_local"],
        notify  => Service[splunk]
    }

    file { "${myappdir}/local/inputs.conf":
        source  => "puppet:///modules/splunk/apps/varnish/inputs.conf",
        owner   => 'splunk',
        group   => 'splunk',
        mode    => '0644',
        require => File["${myapp}_local"],
        notify  => Service[splunk]
    }

    acl::entry { "varnishdir":
        path     => "/var/lib/varnish",
        group    => 'splunk',
        readonly => 'true',
        recurse  => 'true',
    }

    acl::entry { "varnishlogdir":
        path     => "/var/log/varnish",
        group    => 'splunk',
        readonly => 'true',
        recurse  => 'true',
    }

}
