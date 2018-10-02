plan pupperbox::deploy(
  TargetSpec $nodes,
  String $username = 'brandon.high',
  String $ssh_domain = 'puppet.com',
  # Override the packages installed
  Array[String] $packages = [],
  Optional[String] $github_user = undef,
  # Will be used to checkout repos over HTTPS, which ends up storing the token in
  # plain text.
  Optional[String] $github_token = undef
) {
  # This should get the agent installed so we can do interesting things.
  $nodes.apply_prep

  $_homedir = "/home/${username}"
  $_srcdir = "${_homedir}/src"
  $_dir_mode = '0750'
  $github_repos = {
    'puppetlabs' => [
      'beaker',
      'beaker-answers',
      'beaker-pe',
      'chloride',
      'enterprise_tasks',
      'frankenbuilder',
      'higgs',
      'pe-installer-shim',
      'pe-installer-vanagon',
      'pe-modules-vanagon',
      'pe-tasks-vanagon',
      'peteam-statusboard',
      'pe_acceptance_tests',
      'puppet',
      'puppet-enterprise-marketplace-image',
      'puppetlabs-pe_accounts',
      'puppetlabs-pe_concat',
      'puppetlabs-pe_hocon',
      'puppetlabs-pe_infrastructure',
      'puppetlabs-pe_inifile',
      'puppetlabs-pe_install',
      'puppetlabs-pe_java_ks',
      'puppetlabs-pe_manager',
      'puppetlabs-pe_nginx',
      'puppetlabs-pe_postgresql',
      'puppetlabs-pe_puppet_authorization',
      'puppetlabs-pe_razor',
      'puppetlabs-pe_repo',
      'puppetlabs-pe_staging',
      'puppetlabs-puppet_enterprise',
    ]
  }

  # Some packages I like to have
  if $packages {
    $_packages = $packages
  } else {
    $_packages = [
      'tmux',
      'vim'
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
      home       => $_homedir,
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

    package { 'zsh':
      ensure => 'latest'
    }

    ohmyzsh::install { $username:
      set_sh  => true,
      require => [User[$username], Package['zsh']],
    }
    -> ohmyzsh::plugins { $username: plugins => ['bundler', 'colorize', 'docker', 'git', 'github', 'ruby', 'rvm', 'vi-mode'] }
    -> ohmyzsh::theme { $username: theme => 'robbyrussell' }

    file { [$_srcdir]:
      ensure => directory,
      owner  => $username,
      group  => $username,
      mode   => $_dir_mode,
    }

    $github_repos.each | $org, $repos | {
      $repos.each |$repo_name| {
        if $github_user and $github_token {
          notice("Checking out ${org}/${repo_name}")
          vcsrepo { "${_srcdir}/${org}/${repo_name}":
            ensure   => present,
            owner    => $username,
            provider => git,
            source   => {
              'origin'   => "https://${github_user}:${github_token}@github.com/${org}/${repo_name}.git",
              'upstream' => "https://${github_user}:${github_token}@github.com/${github_user}/${repo_name}.git"
            },
            require  => File[$_srcdir],
          }
        }
      }
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
