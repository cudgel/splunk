class splunk::service {

  if $facts['os']['family'] == 'RedHat' and Integer($facts['os']['release']['major']) >= 7  {
      file { '/etc/systemd/system/multi-user.target.wants/splunk.service':
        content => template("${module_name}/splunk.service.erb"),
        owner   => 'root',
        group   => 'root'
      }
  }

  service { 'splunk':
    ensure   => 'running',
  }
}
