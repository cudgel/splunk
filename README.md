# splunk

#### Table of Contents

1. [Overview](#overview)
2. [Module Description](#module-description)
4. [Usage](#usage)
  a. [Splunk Server Types](#types)
  b. [Inputs](#inputs)
6. [Limitations](#limitations)

<a id="overview"></a>
## Overview

This Splunk module supports deploying complex Splunk environments (forwarder, indexer, and search head roles, clustering, etc). By default, it is does not create the user or group, leaving that up to your implementation. It does require the user and group to exist prior to the application being installed, so chaining your resources is a good idea. It supports running as root or a dedicated account. By default it assumes running as user/group splunk/splunk and will apply ACLs to grant access to log files specified in the hiera hash splunk::inputs. The module does include support for creating the Splunk user/group, but it is intended only for testing the code - not production environments.


If you choose to use a fileserver definition (you should) for your splunk tarballs, e.g.:

```
  [splunk]
    path /etc/puppetlabs/puppet/files/splunk
    allow *
```

the file server should be populated with the tarballs for the splunk components you want to manage and splunk::params::source should be set to 'fileserver'.

<a id="usage"></a>
## Usage


<a id="types"></a>
### Splunk Server Types


<a id="inputs"></a>
### Inputs

Sample hiera for RedHat log files. See the class tests for other examples.

```
  splunk::inputs:
    'messages':
      target: '/var/log/messages'
      index: 'main'
      sourcetype: 'linux_messages_syslog'
    'secure':
      target: '/var/log/secure'
      index: 'main'
      sourcetype: 'linux_secure'
    'maillog':
      target: '/var/log/maillog'
      index: 'main'
      sourcetype: 'syslog'
    'spooler':
      target: '/var/log/spooler'
      index: 'main'
      sourcetype: 'syslog'
    'cron':
      target: '/var/log/cron'
      index: 'main'
      sourcetype: 'syslog'
```

<a id="limitations"></a>
## Limitations

The module has only been tested on RHEL and Debian derivatives. The support for clustering is a work-in-progress - the nodes will be depoyed and Splunk will enforce an existing cluster config, but dynamically creating a new cluster is not yet functional.

License
-------

Apache 2.0

Contact
-------

If you need help implementing, contact me [ caldwell @ gwu dot edu ]

Support
-------

Please log tickets and issues at our [Projects site](https://github.com/cudgel/splunk)
