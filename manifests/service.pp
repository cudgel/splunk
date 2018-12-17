# manage Splunk service state
#
class splunk::service {
  service { 'splunk':
    ensure   => 'running',
    alias    => 'splunk-service',
    enable   => true,
    provider => $::osfamily ? {
      'RedHat' => redhat,
      default  => init
    }
  }
}
