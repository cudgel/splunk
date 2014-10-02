# Class installs/configures Splunk search head.
#
# Requires firewall access:
#    search head -> indexer 8089/TCP 9997/TCP
#    indexer -> search head 8089/TCP
#    end user -> search head 8000/TCP
class splunk::search {

    class { 'splunk': type => 'search' }
    class { 'splunk::install': }
    class { 'splunk::service': }

    firewall { '020 splunk-web':
      chain  => 'INPUT' ,
      proto  => 'tcp',
      dport  => '8000',
      action => 'accept'
    }

    firewall { '030 splunkd':
      chain  => 'INPUT' ,
      proto  => 'tcp',
      dport  => '8089',
      action => 'accept'
    }

    if $::osfamily == 'RedHat' {
#       support PDF Report Server
        package { [
            'xorg-x11-server-Xvfb',
            'liberation-mono-fonts',
            'liberation-sans-fonts',
            'liberation-serif-fonts' ]:
            ensure => installed,
        }
    }

    file { "${::splunk::splunklocal}/outputs.conf":
        owner   => $::splunk::splunk_user,
        group   => $::splunk::splunk_user,
        content => template("${module_name}/outputs.erb"),
        mode    => '0644',
        require => File['splunk-home'],
        notify  => Service[splunk],
        alias   => 'splunk-outputs'
    }

    file { "${::splunk::splunklocal}/alert_actions.conf":
        owner   => $::splunk::splunk_user,
        group   => $::splunk::splunk_user,
        content => template("${module_name}/alert_actions.erb"),
        mode    => '0644',
        require => File['splunk-home'],
        notify  => Service[splunk],
        alias   => 'alert-actions'
    }

    file { "${::splunk::splunklocal}/web.conf":
        owner   => $::splunk::splunk_user,
        group   => $::splunk::splunk_user,
        source  => 'puppet:///modules/splunk/web.conf',
        mode    => '0644',
        require => File['splunk-home'],
        notify  => Service[splunk],
        alias   => 'splunk-web',
    }

  file { "${::splunk::splunklocal}/ui-prefs.conf":
        owner   => $::splunk::splunk_user,
        group   => $::splunk::splunk_user,
        mode    => '0644',
        content => "# DO NOT EDIT -- managed by Puppet
[default]
dispatch.earliest_time = @d
dispatch.latest_time = now
",
        notify  => Service['splunk']
    }

    file { "${::splunk::splunklocal}/limits.conf":
        owner   => $::splunk::splunk_user,
        group   => $::splunk::splunk_user,
        mode    => '0644',
        content => "# DO NOT EDIT -- managed by Puppet
[subsearch]
maxout = 15000
maxtime = 600
ttl = 1200

[search]
dispatch_dir_warning_size = 3000
",
        notify  => Service[splunk]
    }

}
