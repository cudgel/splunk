class splunk::service inherits splunk {

    service { 'splunk':
        ensure     => 'running',
        provider   => 'init',
        hasrestart => true,
        hasstatus  => true,
        require    => Class['splunk::install']
    }

}