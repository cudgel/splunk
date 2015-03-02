class splunk::service inherits ::splunk {

  if $type == 'mserver' {
    service { 'splunkm':
        ensure   => 'running',
        enable   => true,
        provider => 'init'
    }
  }

  service { 'splunk':
        ensure  => 'running',
        enable  => true,
        require => Class['::splunk::install']
  }

}
