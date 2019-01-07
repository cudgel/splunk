# == Class: splunk::service
#
# This class manages service state.
#
# === Examples
#
#  class { 'splunk::service': }
#
# === Authors
#
# Christopher Caldwell <caldwell@gwu.edu>
#
# === Copyright
#
# Copyright 2017 Christopher Caldwell
#
class splunk::service {

  $dir             = $splunk::dir
  $splunk_user     = $splunk::splunk_user

  if $facts['os']['family'] == 'RedHat' and Integer($facts['os']['release']['major']) >= 7  {
      file { '/etc/systemd/system/multi-user.target.wants/splunk.service':
        content => template("${module_name}/splunk.service.erb"),
        owner   => 'root',
        group   => 'root'
      }
  }

  service { 'splunk':
    ensure  => 'running',
    restart => "/usr/bin/sudo -u ${splunk_user} ${dir}/bin/splunk restart",
    start   => "/usr/bin/sudo -u ${splunk_user} ${dir}/bin/splunk start",
    stop    => "/usr/bin/sudo -u ${splunk_user} ${dir}/bin/splunk stop",
    status  => "/usr/bin/sudo -u ${splunk_user} ${dir}/bin/splunk status",
  }
}
