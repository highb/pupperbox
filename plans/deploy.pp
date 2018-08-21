plan puppetbox::deploy(
  String[1] $host
) {
  $puppet_installed = run_command('which puppet', $host)

  unless $puppet_installed {
    # The puppet-agent is required to do anything more interesting than executing shell scripts.
    run_command('sudo rpm -Uvh https://yum.puppet.com/puppet5/puppet5-release-el-7.noarch.rpm && sudo yum -y install puppet-agent', $host)
  }

  # Facts must be gathered manually
  run_plan(facts, nodes => $host)

  $username = 'brandon.high'

  # Some packages I like to have
  $packages = [
    'tmux',
    'vim',
    'zsh'
  ]

  $packages.each | $package_name | {
    $results = run_task('package', $host, name => $package_name, action => 'install')
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
  apply_prep($host)
  $apply_results = apply($host) {
    class { 'docker':
      version => 'latest',
    }
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
