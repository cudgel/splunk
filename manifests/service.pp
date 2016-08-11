class splunk::service inherits ::splunk {

  service { 'splunk':
        ensure   => 'running',
        enable   => true,
        provider => init,
        require  => Class['::splunk::install']
  }

}
