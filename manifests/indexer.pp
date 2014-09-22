class splunk::indexer (
    $warmpath,
    $coldpath,
    $maxwarm,
    $maxcold
) inherits splunk
{

    class { 'splunk::install': }
    class { 'splunk': splunkhome => "${splunkhome}" }
    class { 'splunk::apps::deploy': }
    class { 'splunk::apps::unix': tier => 'indexer' }
    class { 'splunk::apps::sos': tier => 'indexer' }
    class { 'splunk::indexer::nagios': }

    firewall::rule { 'distSearch':
        port => '8089',
        from => $splunk_searchers
    }

    firewall::rule { 'forwarders':
        port => '9997'
    }

    file { "${splunklocal}/outputs.conf":
        ensure  => absent,
        notify  => Service[splunk]
    }

    file { "${splunklocal}/web.conf":
        owner   => 'splunk',
        group   => 'splunk',
        source  => 'puppet:///modules/splunk/web.conf',
        mode    => '0644',
        require => File['splunk-home'],
        notify  => Service[splunk],
        alias   => 'splunk-web'
    }

    file { "${splunklocal}/inputs.d/999_splunktcp":
        owner   => 'splunk',
        group   => 'splunk',
        mode    => '0440',
        content => template('splunk/splunktcp.erb'),
        notify  => Exec['update-inputs']
    }

    file { "${splunklocal}/indexes.d":
        ensure  => 'directory',
        owner   => 'splunk',
        group   => 'splunk',
        mode    => '0555',
        require => File['splunk-home']
    }

    file { "${splunklocal}/indexes.d/000_default":
        owner   => 'splunk',
        group   => 'splunk',
        mode    => '0440',
        content => template('splunk/volumes.erb')
    }

    exec { 'update-indexes':
        command     => "/bin/cat ${splunklocal}/indexes.d/* > ${splunklocal}/indexes.conf; \
chown splunk:splunk ${splunklocal}/indexes.conf",
        refreshonly => true,
        subscribe   => File["${splunklocal}/indexes.d/000_default"],
        notify      => Service[splunk],
    }

    file { "${splunklocal}/props.conf":
        owner   => 'splunk',
        group   => 'splunk',
        mode    => '644',
        source  => "puppet:///modules/splunk/indexer/props.conf"
    }
}
