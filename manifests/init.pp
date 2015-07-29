define account (
    $user,
    $groups = ['sudo'],
    $shell = '/bin/bash',

    $git_email,
    $git_name,

    $dotfiles            = true,

    $ssh_key,
    $ssh_key_type,

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

    validate_string($ssh_key)
    validate_string($ssh_key_type)

    validate_bool($postgresql)
    validate_string($postgresql_user)
    validate_string($postgresql_password)

    validate_array($packages)

    user { $user:
      ensure     => present,
      name       => $name,
      groups     => $groups,
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
            source   => "https://github.com/${user}/dotfiles.git",
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

    ssh_authorized_key { $user:
        ensure => present,
        name   => $user,
        user   => $user,
        type   => $ssh_key_type,
        key    => $ssh_key
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
