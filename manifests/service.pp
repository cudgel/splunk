class splunk::service inherits ::splunk {

    service { 'splunk':
        enable  => true,
        ensure  => 'running',
        require => Class['::splunk::install']
    }

}