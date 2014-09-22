class splunk::apps::weblogic(
    $tier='forwarder',
    $type='node',
    $node_root='',
    $wl_root='',
    $wl_app,
    $app_on_nas='false',
    $javahome='',
    $domain_count='1')
{
#
# Do not include this class on a host that does not already have Puppet managing the Splunk install.
#
    case $tier {
        'forwarder': { $splunkhome = '/opt/splunkforwarder' }
        default: { $splunkhome = '/opt/splunk' }
    }

    $myapp = 'function1_weblogicserver_ta_nix'
    $oldversion = '0.1'
    $version = '0.3'
    $splunkapps = "${splunkhome}/etc/apps"
    $oldsource = "${myapp}-${oldversion}.tar.gz"
    $mysource = "${myapp}-${version}.tar.gz"
    $myappdir = "${splunkapps}/${myapp}"

    file { "${splunkapps}/${oldsource}":
        ensure => absent
    }

    file { "${splunkapps}/${mysource}":
        alias   => 'weblogic-app',
        source  => "puppet:///modules/splunk/apps/weblogic/${mysource}",
        owner   => 'splunk',
        group   => 'splunk',
        mode    => '0700',
        replace => false,
        notify  => Exec['unpack-weblogic']
    }

    case $osfamily {
        "RedHat": { $tar = "/bin/tar" }
        "Solaris": { $tar = "/usr/sfw/bin/gtar" }
    }

    exec { "${tar} zxf $mysource":
        alias       => "unpack-weblogic",
        cwd         => "${splunkapps}",
        subscribe   => File['weblogic-app'],
        unless      => "grep ${version} ${myappdir}/local/app.conf",
        path        => '/bin:/usr/bin',
        notify      => Service[splunk]
    }

    file { "${myappdir}":
        owner   => 'splunk',
        group   => 'splunk',
        recurse => true
    }

    file { "${myappdir}/local":
        ensure  => 'directory',
        owner   => 'splunk',
        group   => 'splunk',
        mode    => '0644',
        require => File["${myappdir}"],
        alias   => "${myapp}_local"
    }

    file { "${myappdir}/local/app.conf":
        source  => "puppet:///modules/splunk/apps/weblogic/app.conf",
        owner   => 'splunk',
        group   => 'splunk',
        mode    => '0644',
        require => File["${myapp}_local"],
        notify  => Service[splunk]
    }

    file { "${myappdir}/local/env.d":
        ensure  => 'directory',
        owner   => 'splunk',
        group   => 'splunk',
        mode    => '0750',
        require => File["${myapp}_local"]
    }

    case $type {
        'nodemgr': {
            acl::entry { "wls_nodemanager_log_path":
                path     => "${node_root}/common/nodemanager",
                group    => 'splunk',
                readonly => 'true',
                recurse  => 'true'
            }

            file { "${myappdir}/local/inputs.conf":
                owner   => 'splunk',
                group   => 'splunk',
                mode    => '0440',
                content => template('splunk/apps/weblogic/nodemgr.erb')
            }
        }
        default: {
            acl::entry { "wl_root":
                path     => "${wl_root}",
                group    => 'splunk',
                readonly => 'true',
                recurse  => 'false'
            }

            if $app_on_nas == 'false' {
                acl::entry { "wl_app":
                    path     => "${wl_app}",
                    group    => 'splunk',
                    readonly => 'true',
                    recurse  => 'true'
                }

                acl::entry { "wl_app_logs":
                    path     => "${wl_app}/../logs",
                    group    => 'splunk',
                    readonly => 'false',
                    recurse  => 'true'
                }
            }

            acl::entry { "wl_domains":
                path     => "${wl_root}/domains",
                group    => 'splunk',
                readonly => 'true',
                recurse  => 'false'
            }

            file { "${myappdir}/local/inputs.conf":
                owner   => 'splunk',
                group   => 'splunk',
                mode    => '0440',
                content => template('splunk/apps/weblogic/node.erb')
            }
        }
    }

    file { "${myappdir}/local/env.d/000_default":
        content => template('splunk/apps/weblogic/default_env.erb'),
        owner   => 'splunk',
        group   => 'splunk',
        mode    => '0755',
        notify  => Service[splunk]
    }

    exec { 'update-wl-paths':
        command     => "/bin/cat ${myappdir}/local/env.d/* > ${myappdir}/bin/setWlstEnv.sh; /bin/chmod 755 ${myappdir}/bin/setWlstEnv.sh",
        refreshonly => true,
        subscribe   => File["${myappdir}/local/env.d/000_default"],
        notify      => Service[splunk]
    }

    # splunk::input()
    #
    define domain(
        $domain_id,
        $admin_server,
        $wl_root,
        $domain_port,
        $splunkhome="/opt/splunkforwarder"
        )
    {
        $splunkapps = "${splunkhome}/etc/apps"
        $myappdir = "${splunkapps}/function1_weblogicserver_ta_nix"

        file { "${myappdir}/local/env.d/${title}":
            ensure  => $ensure,
            owner   => 'splunk',
            group   => 'splunk',
            mode    => '0440',
            content => template('splunk/apps/weblogic/domain.erb'),
            require => File["${myappdir}/local/env.d"],
            notify  => Exec['update-wl-paths']
        }

        acl::entry { "wl_domains_${title}":
            path     => "${wl_root}/domains/${title}",
            group    => 'splunk',
            readonly => 'true',
            recurse  => 'false'
        }

        acl::entry { "wls_${title}_servers":
            path     => "${wl_root}/domains/${title}/servers",
            group    => 'splunk',
            readonly => 'true',
            recurse  => 'true'
        }
    }

}
