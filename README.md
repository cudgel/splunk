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

Since the module defaults to user 'splunk', it includes a defined type 'splunk::acl' that will apply read-only POSIX ACLs for group 'splunk' to any inputs defined using this app. There are optional parameters 'recurse' and 'parents' that will try to apply minimial read-only ACLs to parent paths or contents of a directory if set to true.

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
splunk::version: 7.2.3
splunk::release: 06d57c595b80
```

Typically I would define outputs and cluster sites based on a fact like datacenter, but the examples below show it in a node context. 

The app can install certificates from a Puppet file server if any of the default cert names are overridden in hiera. If you supply a new cert you must also supply the cert password.

Use hiera-eyaml to protect secrets in your control repo, like the server cert password. 

```
splunk::servercertpass: >
    ENC[PKCS7,MIIBeQYJKoZIhvcNAQcDoIIBajCCAWYCAQAxggEhMIIBHQIBADAFMAACAQEw
    DQYJKoZIhvcNAQEBBQAEggEAVty92SXg30srYUJaM6YxF9NWPYC3RnkqKWWt
    08xK5822JhbbqeOCFsz+DJ34EGeJY5UJ7VRCnJjFyWANGl79PsFaCQ/36BkG
    LyWx5BSFRbqP75L6SHm4/bETWre3IN4GCj9rEU08ejqFIayhmGbZ+oPZH8RW
    AvtdesxepNvNgRFjI3sQOAwMo8mGTxokLzQ05mmpi+yVBpre4i3t07Wfh2Od
    SobPPDI/lr8izHYXBmqpyQuPUgPgKr9hN3pRR6BzYCpVvEfpR6T1t0dh6WZG
    zR7ATolZqbAU9tduLYiu3nIZ7X+7j9c2ksCXSaqPX4dDLi3nOpD4CS4f2aF/
    b0n6IzA8BgkqhkiG9w0BBwEwHQYJYIZIAWUDBAEqBBAULtw3VN2+8goqyOMa
    Hn0pgBAKWUW3IYF42XuuivjTfZlN]
```

<a id="types"></a>
### Splunk Server Types

####

Below are some examples of various Splunk types. 


#####A Splunk Universal forwarder, Puppet manages the outputs:

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

#####A Splunk Universal forwarder with deployment server:

```
splunk::type: 'forwarder'
splunk::deployment_server: 'https://ds.example.com:8089'
```

#####A Splunk heavy forwarder with deployment server:

```
splunk::type: 'heavyforwarder'
splunk::deployment_server: 'https://ds.example.com:8089'
```

#####Indexer cluster master:

```
splunk::clusters:
  - label: 'IDX-MS'
    access_logging: 1
    build_load: 5
    multisite: true
    sites:
      - site1
      - site2
    repl_factor: 'origin:2,total:3'
    search_factor: 'origin:1,total:2'
    uri: 'ixc.example.com:8089'
splunk::server_site: 'site1'
splunk::privkey: 'ixc_web.key'
splunk::servercert: 'ixc_splunkd.cert'
splunk::webcert: 'ixc_web.cert'
```

#####Indexer cluster member:

```
splunk::type: 'indexer'
splunk::cluster_mode: 'slave'
splunk::repl_port: 8193
splunk::clusters:
  - label: 'IDX-MS'
    access_logging: 1
    build_load: 5
    multisite: true
    sites:
      - site1
      - site2
    repl_factor: 'origin:2,total:3'
    search_factor: 'origin:1,total:2'
    uri: 'ixc.example.com:8089'
splunk::server_site: 'site1'
splunk::privkey: 'ixsite1_web.key'
splunk::servercert: 'ixsite1_splunkd.cert'
splunk::webcert: 'ixsite1_web.cert'
```

#####Search head with indexer-cluster for search peers:

```
splunk::type: 'search'
splunk::repl_port: 8192
splunk::clusters:
  - label: 'IDX-MS'
    multisite: true
    sites:
      - site1
    uri: 'ixc.example.com:8089'
splunk::server_site: 'site1'
splunk::tcpout:
  group: 'site1'
  cname: 'idx-site1.example.com'
  servers:
    - 'idx1.example.com:9998'
    - 'idx2.example.com:9998'
    - 'idx3.example.com:9998'
```

#####Splunk search cluster member, multiple indexer clusters:

```
splunk::type: 'search'
splunk::repl_port: 8192
splunk::shcluster_id: 'dae3f0c5-230a-11e9-9c70-4a0003e77c50'
splunk::shcluster_mode: 'peer'
splunk::shcluster_label: 'SHC'
splunk::clusters:
  - label: 'IDX-MS'
    multisite: true
    sites:
      - site1
    uri: 'ixc.example.com:8089'
  - label: 'IDX-SS'
    multisite: false`
    sites:
      - default
    uri: 'ixc.cloud.example.com:8089'
splunk::privkey: 'srchsite1_web.key'
splunk::servercert: 'srchsite1_splunkd.cert'
splunk::webcert: 'srchsite1_web.cert'

```

<a id="inputs"></a>
### Inputs

```
splunk::input(
user       => <string> (Default splunk::user), # user and group will be used in ACLs
group      => <string> (Default splunk::group),
target     => <string> (Optional), # if not given, the title param will be used
inputtype  => <string> [monitor, udp, tcp, tcp-ssl, splunktcp, etc], # valid server.conf input types
sourcetype => <string> (Default 'auto'),
index      => <string> (Default 'default'),
cache      => <boolean> (Default true), # whether to establish a persistent queue for a network input
size       => <int> (Default 1), # size of queue on disk in GB
options    => <array>, # a list of strings containing any other valid inputs.conf \
                       #  parameters for the input type
recurse    => <boolean>, # should the acls applied to the input recurse
content    => <string>, # any custom input definition you would like to use \
                        # instead of the templated input options
)

```

#####RedHat log files.

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

#####A network input

```
splunk::inputs:
  'syslog-ssl':
    target: '5140'
    inputtype: 'tcp-ssl'
    index: 'secure'
    sourcetype: 'syslog'
    cache: true
    size: 6
    options:
      - 'connection_host = dns'
      - 'no_appending_timestamp = true'
```

More examples can be found in the unit tests.

<a id="limitations"></a>
## Limitations

The module has only been tested on RHEL and Debian derivatives. 

The support for clustering is a work-in-progress - the nodes will be depoyed and Splunk will enforce an existing cluster config, but dynamically creating a new cluster is not fully functional.

The next major release will require you to set the parameter 'splunk::accept_license' to true, since the automated installation accepts the Splunk license when completing the install.

License
-------

Apache 2.0

Contact
-------

If you need help implementing, contact me [ caldwell @ gwu dot edu ]

Support
-------

Please log tickets and issues at the [Projects site](https://github.com/cudgel/splunk)
