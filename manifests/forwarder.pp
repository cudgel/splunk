class splunk::forwarder($syslog=false)
{
  class { 'splunk': type => 'forwarder' }
  class { 'splunk::install': }
  class { 'splunk::service': }

  class { 'splunk::deploy': }

  include "splunk::forwarder::${::osfamily}"

  if $syslog == true {
    firewall { '020 syslog':
      chain  => 'INPUT' ,
      proto  => ['tcp','udp'],
      dport  => ['514', '5140', '10514', '10515'],
      action => 'accept'
    }
  }

  file { "${::splunk::splunklocal}/outputs.conf":
    owner   => $::splunk::splunk_user,
    group   => $::splunk::splunk_user,
    content => template("${module_name}/output.erb"),
    mode    => '0644',
    require => File['splunk-home'],
    notify  => Service[splunk],
    alias   => 'splunk-outputs'
  }

}
