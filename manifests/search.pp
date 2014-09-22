# Class installs/configures Splunk search head.
#
# Requires firewall access:
#    search head -> indexer 8089/TCP 9997/TCP
#    indexer -> search head 8089/TCP
#    end user -> search head 8000/TCP
class splunk::search($allow, $service_url)
{
    $splunkhome = '/opt/splunk'
    $splunklocal = "${splunkhome}/etc/system/local"

    $splunksource = "splunk-${splunkver}-${splunkrel}-${splunkos}-${splunkarch}.${splunkext}"

    class { 'splunk::install': }
    class { 'splunk': splunkhome => "${splunkhome}" }
    class { 'splunk::search::nagios': }

    firewall::rule { 'splunk-web':
        port => '8000',
        from => [ $allow ],
    }

    class { 'firewall::lb':
        port => ['8000', '8089']
    }

    # Allow all search heads to talk to each other for distributed search, license pool
    firewall::rule { 'distSearch':
        port => '8089',
        from => $splunk_searchers
    }

    # Allow indexers to connect for distributed license pool
    firewall::rule { 'splunkd':
        port => '8089',
        from => $splunk_indexers
    }

    if $osfamily == 'RedHat' {
#       support PDF Report Server
        package { [
            'xorg-x11-server-Xvfb',
            'liberation-mono-fonts',
            'liberation-sans-fonts',
            'liberation-serif-fonts' ]:
            ensure => installed,
        }
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

    file { "${splunklocal}/alert_actions.conf":
        owner   => 'splunk',
        group   => 'splunk',
        content => template('splunk/alert_actions.erb'),
        mode    => '0644',
        require => File['splunk-home'],
        notify  => Service[splunk],
        alias   => 'alert-actions'
    }

    file { "${splunklocal}/web.conf":
        owner   => 'splunk',
        group   => 'splunk',
        source  => 'puppet:///modules/splunk/web.conf',
        mode    => '0644',
        require => File['splunk-home'],
        notify  => Service[splunk],
        alias   => 'splunk-web',
    }

  file { "${splunklocal}/ui-prefs.conf":
        owner   => 'splunk',
        group   => 'splunk',
        mode    => '0644',
        content => "# DO NOT EDIT -- managed by Puppet
[default]
dispatch.earliest_time = @d
dispatch.latest_time = now
",
        notify  => Service['splunk']
    }

    file { "${splunklocal}/limits.conf":
        owner   => 'splunk',
        group   => 'splunk',
        mode    => '0644',
        content => "# DO NOT EDIT -- managed by Puppet
[subsearch]
maxout = 15000
maxtime = 600
ttl = 1200

[search]
dispatch_dir_warning_size = 3000
",
        notify => Service[splunk]
    }

}
