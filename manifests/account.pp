define account (
    $email = undef,
    $name  = undef,
    $user  = undef,
) {
    include git

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
}
