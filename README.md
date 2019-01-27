# splunk

#### Table of Contents

1. [Overview](#overview)
  - [History](#history)
2. [Module Description](#module-description)
3. [Usage](#usage)
  - [Splunk Server Types](#types)
  - [Inputs](#inputs)
4. [Limitations](#limitations)

<a id="overview"></a>
## Overview

This Splunk module supports deploying complex Splunk environments (forwarder, indexer, and search head roles, clustering, etc). By default, it is does not create the user or group, leaving that up to your implementation. It does require the user and group to exist prior to the application being installed. The module does include support for creating the Splunk user/group, but it is intended only for testing the code - not production environments.

It supports running as root or a dedicated account. By default it assumes running as user/group splunk/splunk and will apply Posix ACLs to grant access to log files specified in the hiera hash splunk::inputs. 

If you choose to use a fileserver definition (you should - to save everyone's bandwitdh) for your splunk tarballs, e.g.:

```
  [splunk]
    path /etc/puppetlabs/puppet/files/splunk
    allow *
```

The file server should be populated with the tarballs for the splunk components you want to manage and splunk::source should be set to 'fileserver'.

<a id="history"></a>
### History

This module is the descendent of some Puppet code I wrote a long time ago to manage our in-house Splunk intrastructure. I currently use this module to manage a large Splunk infrastructure consising of multiple stand-alone and clustered search heads, multiple single-site and multi-site indexer clusters, management hosts, and hundreds of forwarders (Universal and Heavy). I am not a git expert, so bear with me if I do not follow the best practices in releasing updates to the module.

<a id="usage"></a>
## Usage

Including the Splunk class:

```
classes:
  - splunk
```

Specify a version to install in your hiera. The included defaults are for testing only.

```
splunk::version: 7.2.x
splunk::release: ca04e0f28ae3
```

Typically I would define outputs and cluster sites based on a fact like datacenter, but the examples below show it in a node context.

<a id="types"></a>
### Splunk Server Types

A Splunk Universal forwarder, Puppet manages the outputs:

```
splunk::type: 'forwarder'
splunk::tcpout:
  group: 'site1'
  cname: 'idx-site1.example.com'
  servers:
    - 'idx1.example.com:9998'
    - 'idx2.example.com:9998'
    - 'idx3.example.com:9998'

```

A Splunk Universal forwarder with deployment server:

```
splunk::type: 'forwarder'
splunk::deployment_server: 'https://ds.example.com:8089'
```

A Splunk heavy forwarder with deployment server:

```
splunk::type: 'heavyforwarder'
splunk::deployment_server: 'https://ds.example.com:8089'
```

Indexer cluster master:

```
splunk::type: 'index_master'
splunk::cluster_mode: 'master'
splunk::clusters:
  - label: 'IDX'
    access_logging: 1
    build_load: 5
    multisite: true
    sites:
      - site1
      - site2
    repl_factor: 'origin:2,total:3'
    search_factor: 'origin:1,total:2'
    uri: 'idx-master.example.com:8089'
splunk::server_site: 'site2'
```

Indexer cluster member:

```
splunk::type: 'indexer'
splunk::repl_port: 8192
splunk::cluster_mode: 'slave'
splunk::clusters:
  - label: 'IDX'
    access_logging: 1
    build_load: 5
    multisite: true
    sites:
      - site1
      - site2
    repl_factor: 'origin:2,total:3'
    search_factor: 'origin:1,total:2'
    uri: 'idx-master.example.com:8089'
splunk::server_site: 'site1'
```

Search head with indexer-cluster for search peers:

```
splunk::type: 'search'
splunk::repl_port: 8192
splunk::clusters:
  - label: 'IDX'
    multisite: true
    sites:
      - site1
      - site2
    uri: 'idx-master.example.com:8089'
splunk::server_site: 'site1'
splunk::tcpout:
  group: 'site1'
  cname: 'idx-site1.example.com'
  servers:
    - 'idx1.example.com:9998'
    - 'idx2.example.com:9998'
    - 'idx3.example.com:9998'    
```

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

The module has only been tested on RHEL and Debian derivatives. The support for search-head clustering is a work-in-progress - the nodes will be depoyed and Splunk will enforce an existing cluster config, but dynamically creating a new cluster is not yet functional.

License
-------

Apache 2.0

Contact
-------

If you need help implementing, contact me [ caldwell @ gwu dot edu ]

Support
-------

Please log tickets and issues at the [Projects site](https://github.com/cudgel/splunk)
