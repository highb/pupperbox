plan pupperbox::deploy(
  TargetSpec $nodes,
  String $username = 'brandon.high',
  String $ssh_domain = 'puppet.com',
  # Override the packages installed
  Array[String] $packages = []
) {
  # This should get the agent installed so we can do interesting things.
  $nodes.apply_prep


  # Some packages I like to have
  if $packages {
    $_packages = $packages
  } else {
    $_packages = [
      'tmux',
      'vim',
      'zsh'
    ]
  }

  $_packages.each | $package_name | {
    $results = run_task('package', $nodes, name => $package_name, action => 'install')
    $results.each | $result | {
      $node = $result.target.name
      if $result.ok {
        notice("${node} managed ${package_name}: ${result.value}")
      } else {
        error("${node} was unable to manage ${package_name}: ${result.error.message}")
      }
    }
  }

  # Apply some Puppet module code
  $apply_results = apply($nodes) {
    class { 'docker':
      version => 'latest',
    }

    user { $username:
      ensure     => present,
      groups     => ['wheel', 'docker'],
      managehome => true,
      home       => "/home/${username}",
      shell      => '/usr/bin/zsh',
      require    => Class['docker'],
    }

    $_id_rsa_pub = file('pupperbox/id_rsa.pub', '/dev/null')

    if $_id_rsa_pub =~ /ssh-rsa (.*) / {
      ssh_authorized_key { "${username}@${ssh_domain}":
        ensure  => present,
        user    => $username,
        type    => 'ssh-rsa',
        key     => $1,
        require => User[$username],
      }
    }

    ohmyzsh::install { $username:
      set_sh  => true,
      require => User[$username],
    }
    -> ohmyzsh::plugins { $username: plugins => ['bundler', 'colorize', 'docker', 'git', 'github', 'ruby', 'rvm', 'vi-mode'] }
    -> ohmyzsh::theme { $username: theme => 'robbyrussell' }
  }

  $apply_results.each | $result | {
    $node = $result.target.name
    if $result.ok {
      notice("${node} attempted to apply.")
      if $result.value['status'] == 'failed' {
        notice("it failed, yo: ${result.value['logs']}")
      }
    } else {
      notice("${node} was not ok: ${result.error.message}")
    }
  }

  return 'Success!'
}
