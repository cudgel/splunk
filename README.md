# splunk

#### Table of Contents

1. [Overview](#overview)
    - [FS Mounts](#splunk_mounts)
    - [File Source](#splunk_files)
1. [Module Description](#module-description)
1. [Security](#security)
1. [Usage](#usage)
    - [Authentication](#auth)
    - [Roles](#roles)
    - [Splunk Server Types](#types)
    - [Inputs](#inputs)
    - [Indexes](#indexes)
1. [Limitations](#limitations)

<a id="overview"></a>
## Overview

This Splunk module supports deploying complex Splunk environments (forwarder, indexer, and search head roles, clustering, etc). By default, it is does not create the user or group, leaving that up to your implementation. It does require the user and group to exist prior to the application being installed. The module does include support for creating the Splunk user/group, but it is intended only for testing the code - not production environments.

It supports running as root or a dedicated account. By default it assumes running as user/group splunk/splunk and will apply Posix ACLs to grant access to log files specified in the hiera hash splunk::inputs.

This module is the descendent of some Puppet code I wrote a long time ago to manage our in-house Splunk intrastructure. I have been using this module to manage a large Splunk infrastructure consising of multiple stand-alone and clustered search heads, multiple single-site and multi-site indexer clusters, management hosts, and hundreds of forwarders (Universal and Heavy). I am not a git expert, so bear with me if I do not follow the best practices in releasing updates to the module.

<a id="splunk_mounts"></a>
### FS Mounts

The module assumes installation on a single partition. If you set the parameter splunk::use_mounts to true, the module will not install Splunk until "splunk/etc" and "splunk/var" are mounted on the server.

<a id="splunk_files"></a>
### File Source

To save everyone's bandwitdh, you should find another way to serve the Splunk installers and any certificates you want to distribute. The parameter splunk::source can be set to any valid Puppet file resource that contains the expected structure.

For example, given this export in fileserver.conf:

```
[splunk_files]
  path /etc/puppetlabs/puppet/files/splunk
```

And this file structure on disk:

```
splunk
├── auth
│   ├── ixc_splunkd.cert
│   ├── ixsite1_splunkd.cert
│   ├── ixsite2_splunkd.cert
│   ├── srchsite1_splunkd.cert
│   └── web
│       ├── ixc_web.cert
│       ├── ixc_web.key
│       ├── ixsite1_web.cert
│       ├── ixsite1_web.key
│       ├── ixsite2_web.cert
│       ├── ixsite2_web.key
│       ├── srchsite1_web.cert
│       ├── srchsite1_web.key
├── splunk-6.6.1-aeae3fe0c5af-Linux-x86_64.tgz
├── splunk-6.6.3-e21ee54bc796-Linux-x86_64.tgz
├── splunk-6.6.4-00895e76d346-Linux-x86_64.tgz
├── splunk-6.6.5-b119a2a8b0ad-Linux-x86_64.tgz
├── splunk-7.0.1-2b5b15c4ee89-Linux-x86_64.tgz
├── splunk-7.0.3-fa31da744b51-Linux-x86_64.tgz
├── splunk-7.1.1-8f0ead9ec3db-Linux-x86_64.tgz
├── splunkforwarder-7.1.3-51d9cac7b837-Linux-x86_64.tgz
└── splunk-7.1.3-51d9cac7b837-Linux-x86_64.tgz
```

The source would have the setting `splunk::source: 'puppet:///splunk_files'` which will compile as using the fileserver for the splunk installer source. A similar setting splunk::cert_source controls where the certs are served from (should they differ). This setting is required if using non-default certs.

---

<a id="security"></a>
## Security

The app can install certificates from a Puppet file server if any of the default cert names are overridden in hiera. If you supply a new cert you must also supply the cert password.

Use hiera-eyaml to protect secrets in your control repo, like the server cert password, e.g. 'password':

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

Starting with v1.5.0, the app will store only hashed passwords on-disk once it knows them.

#### ACLs

Since the module defaults to user 'splunk', it includes a defined type 'splunk::acl' that will apply read-only POSIX ACLs for group 'splunk' to any inputs defined using this app. There are optional parameters 'recurse' and 'parents' that will try to apply minimial read-only ACLs to parent paths or contents of a directory if set to true.

---

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

<a id="auth"></a>
### Authentication

Starting with v1.5.0 the app has tested support for deploying a working LDAP authentication configuration. If you supply the setting `splunk::auth_pass` in EYAML, the module will hash and use this password instead of the cleartext password in the authconfig setting.

```
splunk::authentication: 'LDAP'
splunk::authconfig:
  sslenabled: 1
  anonymous_referrals: 1
  charset: 'utf8'
  groupbasedn: 'ou=Groups,dc=example,dc=com;'
  groupmappingattribute: 'dn'
  groupmemberattribute: 'member'
  groupNameAttribute: 'cn'
  label: 'AD'
  type: 'Active Directory'
  host: 'ad.example.com'
  binddn: 'cn=Directory Manager'
  binddnpassword: 'password'
  nestedgroups: 1
  network_timeout: 20
  port: 636
  realnameattribute: 'displayname'
  sizelimit: 1000
  timelimit: 15
  userbasedn: 'ou=People,dc=example,dc=com;'
  userbasefilter: '(|(memberOf=CN=SplunkAdmins,OU=Groups,DC=example,DC=com)(memberOf=CN=SplunkPowerUsers,OU=Groups,DC=example,DC=com)(memberOf=CN=SplunkUsers,OU=Groups,DC=example,DC=com))'
  usernameattribute: 'samaccountname'
  emailattribute: 'userprincipalname'
  role_maps:
    - role: 'admin'
      groups:
        - 'SplunkAdmins'
    - role: 'power'
      groups:
        - 'SplunkPowerUsers'
    - role: 'users'
      groups:
        - 'SplunkUsers'
        - 'Contractors'
```

<a id="roles"></a>
### Roles

Beginning with v1.5.4, the module will populate authorize.conf with roles defined in hiera.

```
splunk::roles:
  - name: 'admin'
    disabled: false
    options:
      - 'rtsearch = enabled'
      - 'srchIndexesDefault = *'
      - 'srchMaxTime = 0'
  - name: 'power'
    disabled: false
    options:
      - 'rtsearch = disabled'
      - 'schedule_rtsearch = disabled'
      - 'schedule_search = enabled'
      - 'srchDiskQuota = 5000'
```

---

<a id="types"></a>
### Splunk Server Types

Below are some examples of various Splunk types.

##### A Splunk Universal forwarder, Puppet manages the outputs:

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

##### A Splunk Universal forwarder with deployment server:

```
splunk::type: 'forwarder'
splunk::deployment_server: 'https://ds.example.com:8089'
```

##### A Splunk heavy forwarder with deployment server:

```
splunk::type: 'heavyforwarder'
splunk::deployment_server: 'https://ds.example.com:8089'
```

##### Indexer cluster master:

```
splunk::type: 'indexer'
splunk::cluster_mode: 'master'
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

##### Indexer cluster member:

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

##### Search head with indexer-cluster for search peers:

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

##### Splunk search cluster member, multiple indexer clusters:

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
---

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

##### RedHat log files.

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

##### A network input

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

---

<a id="indexes"></a>
### Indexes

Starting with version 1.6.0, you can define indexes in Puppet if you are configuring a stand-alone indexer or an S1 architecture. Indexes are defined as a hash in hiera, any valid index settings can be added as an array of strings under options. The settings splunk::cold_path and splunk::warm_path can be used to relocate indexes outside of the Splunk var/lib/splunk directory.

```
splunk::indexes:
  'main':
    frozen_time: 604800
    options:
      - 'maxDataSize = auto'
      - 'maxWarmDBCount = 10'

```

---

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
