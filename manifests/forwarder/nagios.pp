class splunk::forwarder::nagios
{
    include nagios

    nagios::service { 'splunkd':
        command => 'check_procs -w 2 -c 2 -C "splunkd" -a "-p 8089" -u splunk',
    }

}
