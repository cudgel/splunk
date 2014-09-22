class splunk::indexer::firewall
{
    firewall::rule { 'splunkweb':
        port => ['8000'],
        from => ['TECH_OPS_SYSADMIN'],
    }

    # search head/peers connections
    firewall::rule { 'splunkd':
        port => ['8089'],
        from => ['161.253.150.191/32', '10.247.98.81/32']
    }
    
    # forwarder connections
    firewall::rule { 'splunk2splunk':
        port => ['9997'],
        from => ['128.164.0.0/16', '161.253.0.0/16', '10.240.0.0/12']
    }    

}