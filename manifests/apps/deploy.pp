class splunk::apps::deploy($deploymentserver='161.253.150.191')
{
#
# Do not include this class on a host that does not already have Puppet managing the Splunk install. 
#

	$splunkapps = "${splunkhome}/etc/apps"
	$myapp = 'deployclient'
	$myappdir = "${splunkapps}/${myapp}"
	
    file { "${myappdir}":
        owner   => 'splunk',
        group   => 'splunk',
        recurse    => true,
        mode    => '0640',
        ensure => "directory",
    }

    file { "${myappdir}/local":
        owner   => 'splunk',
        group   => 'splunk',
    	ensure  => 'directory',
        mode    => '0640',
        require => File["${myappdir}"]
    }	

    file { "${myappdir}/local/deploymentclient.conf":
        content => template('splunk/apps/deploy/deployclient.erb'),
        owner   => 'splunk',
        group   => 'splunk',
        mode    => '0640',
        require => File["${myappdir}/local"],
        notify  => Service[splunk]
    }

}
