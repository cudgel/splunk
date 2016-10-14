class splunk::service inherits ::splunk {

  service { 'splunk':
        ensure  => 'running',
        enable  => true,
        require => Class['::splunk::install']
  }

}
