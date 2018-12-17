class splunk::service {

if $::osfamily == 'Redhat' {
  $my_provider = 'redhat'
} else {
  $my_provider = 'init'
}

  service { 'splunk':
    ensure   => 'running',
    alias    => 'splunk-service',
    enable   => true,
    provider => $my_provider
  }
}
