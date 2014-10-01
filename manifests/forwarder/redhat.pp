class splunk::forwarder::redhat
inherits splunk::forwarder
{

    if $syslog == true {
        # redirect 514UDP/TCP to Splunk listening on a non-privileged port
        class { 'firewall::nat':
            content => "-A PREROUTING -p udp --dport 514 -j REDIRECT --to-port 10514
-A PREROUTING -p tcp --dport 514 -j REDIRECT --to-port 10514"
        }
    }
}