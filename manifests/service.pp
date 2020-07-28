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

  $dir         = $splunk::dir
  $user        = $splunk::user
  $use_systemd = $splunk::use_systemd

  if $user == 'splunk' {
    unless $use_systemd == true {
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

      $restart = "/usr/bin/sudo -u ${user} ${dir}/bin/splunk restart"
      $start   = "/usr/bin/sudo -u ${user} ${dir}/bin/splunk start"
      $stop    = "/usr/bin/sudo -u ${user} ${dir}/bin/splunk stop"
      $status  = "/usr/bin/sudo -u ${user} ${dir}/bin/splunk status"

      if $facts['osfamily'] == 'RedHat' {
        $provider = redhat
      } elsif $facts['osfamily'] == 'Debian' {
        $provder == debian
      } else {
        $provider = init
      }
    } else {
      $restart = '/usr/bin/sudo /usr/bin/systemctl restart splunk'
      $start   = '/usr/bin/sudo /usr/bin/systemctl start splunk'
      $stop    = '/usr/bin/sudo /usr/bin/systemctl stop splunk'
      $status  = '/usr/bin/sudo /usr/bin/systemctl status splunk'

      $provder = systemd
    }
  }

  service { 'splunk':
    ensure   => 'running',
    restart  => $restart,
    start    => $start,
    stop     => $stop,
    status   => $status,
    provider => $provider
  }
}
