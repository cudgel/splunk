class splunk::service inherits ::splunk {

  case $::osfamily {
      'RedHat': {
          $init = 'redhat'
        }
      'Debian': {
          $init = 'debian'
      }
      default: {
          $init = 'init'
      }
  }

  service { 'splunk':
        ensure   => 'running',
        enable   => true,
        provider => $init,
        require  => Class['::splunk::install']
  }

}
