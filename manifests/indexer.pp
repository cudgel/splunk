class splunk::indexer (
  $warmpath=$::splunk::params::splunkdb,
  $coldpath=$::splunk::params::splunkdb,
  $maxwarm=$::splunk::params::maxwarm,
  $maxcold=$::splunk::params::maxcold
)
{

  class { 'splunk': type => 'indexer' }
  class { 'splunk::install': }
  class { 'splunk::service': }
  class { 'splunk::deploy': }


  firewall { '020 splunkd':
    chain  => 'INPUT' ,
    proto  => 'tcp',
    dport  => '8089',
    action => 'accept'
  }

  firewall { '025 Splunk forwarders':
    chain  => 'INPUT' ,
    proto  => 'tcp',
    dport  => '9997',
    action => 'accept'
  }

  file { "${::splunk::splunklocal}/outputs.conf":
    ensure  => absent,
    notify  => Service[splunk]
  }

  file { "${::splunk::splunklocal}/web.conf":
    owner   => 'splunk',
    group   => 'splunk',
    source  => 'puppet:///modules/splunk/web.conf',
    mode    => '0644',
    require => File['splunk-home'],
    notify  => Service[splunk],
    alias   => 'splunk-web'
  }

  file { "${::splunk::splunklocal}/inputs.d/999_splunktcp":
    owner   => 'splunk',
    group   => 'splunk',
    mode    => '0440',
    content => template("${module_name}/splunktcp.erb"),
    notify  => Exec['update-inputs']
  }

  file { "${::splunk::splunklocal}/indexes.d":
    ensure  => 'directory',
    owner   => 'splunk',
    group   => 'splunk',
    mode    => '0555',
    require => File['splunk-home']
  }

  file { "${::splunk::splunklocal}/indexes.d/000_default":
    owner   => 'splunk',
    group   => 'splunk',
    mode    => '0440',
    content => template("${module_name}/volumes.erb")
  }

  exec { 'update-indexes':
    command     => "/bin/cat ${::splunk::splunklocal}/indexes.d/* > ${::splunk::splunklocal}/indexes.conf; \
chown splunk:splunk ${::splunk::splunklocal}/indexes.conf",
    refreshonly => true,
    subscribe   => File["${::splunk::splunklocal}/indexes.d/000_default"],
    notify      => Service[splunk],
  }
}
