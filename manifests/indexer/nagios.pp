class splunk::indexer::nagios
{
  include nagios

  nagios::service { 'splunkd':
    command => 'check_procs -w 2: -c 2: -C splunkd -u splunk',

  }

  nagios::service { 'splunkd_8089':
    command => 'check_tcp -H 127.0.0.1 -p 8089',

  }

  nagios::service { 'splunkd_9997':
    command => 'check_tcp -H 127.0.0.1 -p 9997',

  }

}
