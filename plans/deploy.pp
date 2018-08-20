plan pupperbox::deploy(
  String[1] $host
) {
  $username = 'brandon.high'
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

  # Tried using puppet module for managing oh-my-zsh here, but its all kinds of broken.
  $apply_results = apply($host) {
    include 'docker'
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
