define sudo::group( $privileges=[], $ensure='present', $group = $title ) {
    require sudo

    file { "/etc/sudoers.d/${title}":
        ensure  => $ensure,
        owner   => root,
        group   => root,
        mode    => '0440',
        content => template('sudo/sudoers.erb'),
    }

}
