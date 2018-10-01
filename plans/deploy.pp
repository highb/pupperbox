plan pupperbox::deploy(
  TargetSpec $nodes
) {
  # This should get the agent installed so we can do interesting things.
  $nodes.apply_prep

  $username = 'brandon.high'

  # Some packages I like to have
  $packages = [
    'tmux',
    'vim',
    'zsh'
  ]

  $packages.each | $package_name | {
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
