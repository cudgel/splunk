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

  $dir  = $splunk::dir
  $user = $splunk::user

  if $facts['os']['family'] == 'RedHat' and Integer($facts['os']['release']['major']) >= 7  {
    file { '/etc/systemd/system/multi-user.target.wants/splunk.service':
      content => template("${module_name}/splunk.service.erb"),
      owner   => 'root',
      group   => 'root'
    }
  } else {
    exec { 'test_for_init':
      command => 'test -f /etc/init.d/splunk',
      path    => '/bin:/bin:/usr/bin',
      unless  => 'test -f /etc/init.d/splunk'
    }

    file_line { 'splunk-start':
      path    => '/etc/init.d/splunk',
      line    => "  su - ${user} -c \'\"${dir}/bin/splunk\" start --no-prompt --answer-yes\'",
      match   => "^\s\s\"${dir}/bin/splunk\" start",
      require => Exec['test_for_init']
    }

    file_line { 'splunk-stop':
      path    => '/etc/init.d/splunk',
      line    => "  su - ${user} -c \'\"${dir}/bin/splunk\" stop\'",
      match   => "^\s\s\"${dir}/bin/splunk\" stop",
      require => Exec['test_for_init']
    }

    file_line { 'splunk-restart':
      path    => '/etc/init.d/splunk',
      line    => "  su - ${user} -c \'\"${dir}/bin/splunk\" restart\'",
      match   => "^\s\s\"${dir}/bin/splunk\" restart",
      require => Exec['test_for_init']
    }

    file_line { 'splunk-status':
      path    => '/etc/init.d/splunk',
      line    => "  su - ${user} -c \'\"${dir}/bin/splunk\" status\'",
      match   => "^\s\s\"${dir}/bin/splunk\" status",
      require => Exec['test_for_init']
    }
  }

  service { 'splunk':
    ensure  => 'running',
    restart => "/usr/bin/sudo -u ${user} ${dir}/bin/splunk restart",
    start   => "/usr/bin/sudo -u ${user} ${dir}/bin/splunk start",
    stop    => "/usr/bin/sudo -u ${user} ${dir}/bin/splunk stop",
    status  => "/usr/bin/sudo -u ${user} ${dir}/bin/splunk status",
  }
}
