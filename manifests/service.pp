class splunk::service inherits ::splunk {

  if $::osfamily == 'Debian' {
		file { '/lib/systemd/system/splunk.service':
		  ensure => file,
		  owner  => 'root',
		  group  => 'root',
		  mode   => '0644',
		  source => "puppet:///modules/splunk/splunk.service",
		} 
		service { 'splunk':
		    ensure  => 'running',
		    enable  => true,
		    require => Class['::splunk::install']
		}
	}
    elsif $::osfamily == 'RedHat' {
		service { 'splunk':
		    ensure  => 'running',
		    enable  => true,
		    require => Class['::splunk::install']
		}
    } 
  } 
