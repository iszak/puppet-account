define account (
    $user,
    $groups = ['sudo'],
    $shell = '/bin/bash',

    $git_email,
    $git_name,
    $git_user,

    $dotfiles            = true,

    $ssh_authorized_keys = {},

    $password            = undef,

    $postgresql          = false,
    $postgresql_user     = undef,
    $postgresql_password = undef,

    $packages            = []
) {
    include ::git

    validate_string($user)
    validate_string($git_email)
    validate_string($git_name)

    validate_bool($dotfiles)

    validate_hash($ssh_authorized_keys)

    validate_bool($postgresql)
    validate_string($postgresql_user)
    validate_string($postgresql_password)

    validate_array($packages)

    if ($ssh_authorized_keys == {} and $password == undef) {
      fail('Either a SSH key or password must be set')
    }

    user { $user:
      ensure     => present,
      name       => $name,
      groups     => $groups,
      password   => $password,
      shell      => $shell,
      managehome => true,
    }

    git::config { 'user.name':
      require => User[$user],
      value   => $git_name,
      user    => $user,
    }

    git::config { 'user.email':
      require => User[$user],
      value   => $git_email,
      user    => $user,
    }

    if ($dotfiles == true) {
        vcsrepo { "/home/${user}/.dotfiles":
            ensure   => present,
            require  => User[$user],
            provider => git,
            source   => "https://github.com/${git_user}/dotfiles.git",
            user     => $user,
            owner    => $user,
            group    => $user,
        }

        #exec { "/bin/ln --symbolic /home/${user}/.dotfiles":
        #    command => "/bin/ln --symbolic /home/${user}/.dotfiles/.* /home/${user}/",
        #    user    => $user,
        #    group   => $user,
        #    require => Vcsrepo["/home/${user}/.dotfiles"]
        #}
    }

    if ($ssh_authorized_keys != {}) {
      create_resources(
        ssh_authorized_key,
        $ssh_authorized_keys,
        {
          ensure => present,
          name   => $user,
          user   => $user,
        }
      )
    }


    if ($postgresql == true) {
        include ::postgresql::server

        if ($postgresql_user == undef or $postgresql_password == undef) {
            fail('PostgreSQL username and password is unset')
        }

        postgresql::server::role { $postgresql_user:
            require       => Class['postgresql::server'],
            password_hash => postgresql_password($postgresql_user, $postgresql_password),
            superuser     => true,
            createdb      => true,
            createrole    => true,
            replication   => true,
        }
    }

    if ($packages != []) {
        ensure_packages($packages, {ensure => latest})
    }
}
