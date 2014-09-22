class splunk::search::nagios
{
  include nagios

  nagios::service { 'splunkd':
    command => 'check_procs -w 2: -c 2: -C "splunkd" -a "-p 8089" -u splunk',

  }

  nagios::service { 'splunkd_8089':
    command => 'check_tcp -H 127.0.0.1 -p 8089',

  }

  nagios::service { 'splunkd_8000':
    command => 'check_http -S -H 127.0.0.1 -p 8000',
  }

}
