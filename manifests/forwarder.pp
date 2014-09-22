class splunk::forwarder($type='colocated')
{
    $splunkhome = '/opt/splunkforwarder'
    $splunklocal = "${splunkhome}/etc/system/local"
    $prevver = '5.0.5'
    $prevrel = '179365'
    $splunkver = '6.0.3'
    $splunkrel = '204106'

    if $osfamily == "Solaris" {
        $splunkos = 'SunOS'
        $splunkarch = $architecture ? {
            i86pc  => 'x86_64',
            default => 'sparc'
        }
        $splunkext = 'tar.Z'
        $tar = '/usr/sfw/bin/gtar'
        $tarcmd = "${tar} xZf"
    } elsif $kernel == "Linux" {
        $splunkos = 'Linux'
        $splunkarch = $architecture ? {
            x86_64  => 'x86_64',
            default => 'i686'
        }
        $splunkext = 'tgz'
        $tar = '/bin/tar'
        $tarcmd = "${tar} xzf"
    } else {
        fail("Unsupported OS")
    }

    $oldsource = "splunkforwarder-${prevver}-${prevrel}-${splunkos}-${splunkarch}.${splunkext}"
    $splunksource = "splunkforwarder-${splunkver}-${splunkrel}-${splunkos}-${splunkarch}.${splunkext}"

    class { 'splunk': splunkhome => "${splunkhome}" }
    class { 'splunk::forwarder::nagios': }
    class { 'splunk::apps::deploy': }
    class { 'splunk::apps::unix': }
    class { 'splunk::apps::sos': }

    file { "/opt/${oldsource}":
        ensure => absent
    }

    file { "/opt/${splunksource}":
        owner   => 'splunk',
        group   => 'splunk',
        mode    => '644',
        source  => "puppet:///splunk/${splunksource}",
        notify  => Exec['unpacksplunk']
    }

    exec { 'unpacksplunk':
        command     => "splunk stop; ${tarcmd} ${splunksource}; chown -RL splunk:splunk ${splunkhome}",
        path        => '${splunkhome}/bin:/bin:/usr/bin:',
        cwd         => '/opt',
        subscribe   => File["/opt/${splunksource}"],
        refreshonly => true,
        unless      => "test -e ${splunkhome}/splunk-${splunkver}-${splunkrel}-${splunkos}-${splunkarch}-manifest",
        creates     => "${splunkhome}/splunk-${splunkver}-${splunkrel}-${splunkos}-${splunkarch}-manifest"
    }

    exec { 'installSplunk':
        command   => "splunk --answer-yes --no-prompt --accept-license start && \
splunk enable boot-start -user splunk && \
splunk stop && \
chown -RL splunk:splunk ${splunkhome}",
        path      => "${splunkhome}/bin:/bin:/usr/bin:",
        subscribe => Exec['unpacksplunk'],
        unless    => 'test -e /etc/init.d.splunk',
        creates   => '/etc/init.d/splunk'
    }

    exec { 'upgradeSplunk':
        command   => "splunk --answer-yes --no-prompt --accept-license start",
        path      => "${splunkhome}/bin:/bin:/usr/bin:",
        subscribe => Exec['unpacksplunk'],
        refreshonly => true,
        user      => 'splunk',
        group     => 'splunk'
    }

    file { '/etc/init.d/splunk':
        owner   => 'root',
        group   => 'root',
        mode    => '755'
    }

    service { 'splunk':
        ensure     => 'running',
        provider => 'init',
        hasrestart => true,
        hasstatus  => true,
        require    => File['/etc/init.d/splunk']
    }

    include "splunk::forwarder::${TARGET}"

    if $type == 'dedicated' {
        # open standard and alternate ports for syslog inputs
        firewall::rule { 'syslog':
            port     => ['514', '5140', '10514', '10515'],
            protocol => ['udp', 'tcp']
        }
    }

    firewall::rule { 'splunkDeploy':
        port => '8089',
        from => $splunk_searchers
    }

    file { "${splunkhome}":
        owner   => 'splunk',
        group   => 'splunk',
        mode    => '0755',
        alias   => 'splunk-home'
    }

    file { "${splunklocal}/outputs.conf":
        owner   => 'splunk',
        group   => 'splunk',
        content => template('splunk/outputs.erb'),
        mode    => '0644',
        require => File['splunk-home'],
        notify  => Service[splunk],
        alias   => 'splunk-outputs'
    }

    file { "${splunklocal}/props.conf":
        owner   => 'splunk',
        group   => 'splunk',
        source  => 'puppet:///modules/splunk/forwarder/props.conf',
        mode    => '0644',
        require => File['splunk-home'],
        notify  => Service[splunk],
        alias   => 'splunk-props'
    }

    file { "${splunklocal}/inputs.d":
        ensure  => 'directory',
        owner   => 'splunk',
        group   => 'splunk',
        mode    => '0555',
        require => File['splunk-home']
    }

    file { "${splunklocal}/inputs.d/000_default":
        owner   => 'splunk',
        group   => 'splunk',
        mode    => '0440',
        require => File["${splunklocal}/inputs.d"],
        content => template('splunk/default_inputs.erb')
    }
}
