# manage Splunk service state
#
class splunk::service inherits ::splunk {
  service { 'splunk':
    ensure  => 'running',
    alias   => 'splunk-service',
    enable  => true,
    require => File['/etc/init.d/splunk']
  }
}
