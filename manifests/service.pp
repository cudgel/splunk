class splunk::service {

  service { 'splunk':
    ensure   => 'running',
  }
}
