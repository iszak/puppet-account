define account (
    $email = undef,
    $name  = undef,
    $user  = undef,

    $dotfiles = true,

    $ssh_key      = undef,
    $ssh_key_type = undef,

    $postgresql          = true,
    $postgresql_password = true,

    $packages            = []
) {
    include ::git

    user { $user:
      ensure     => present,
      managehome => true
    }

    git::config { 'user.name':
      require => User[$user],
      value   => $name,
      user    => $user,
    }

    git::config { 'user.email':
      require => User[$user],
      value   => $email,
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

    if ($ssh_key != undef and $ssh_key_type != undef) {
        ssh_authorized_key { $user:
            ensure => present,
            name   => $user,
            user   => $user,
            type   => $ssh_key_type,
            key    => $ssh_key
        }
    }


    if ($postgresql == true) {
        include ::postgresql::server

        postgresql::server::role { $user:
            require       => Class['postgresql::server'],
            password_hash => postgresql_password($user, $postgresql_password),
            superuser     => true,
            createdb      => true,
            createrole    => true,
            replication   => true,
        }
    }

    if ($packages != []) {
        package { $packages:
            ensure => latest
        }
    }
}
