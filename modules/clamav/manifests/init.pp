# == Class: clamav
#
# This class installs & manages ClamAV, http://www.clamav.net/
#
# == Parameters
#

class clamav {
    package { 'clamav-daemon':
        ensure => present,
    }

    exec { 'add clamav to Debian-exim':
        command => 'usermod -a -G Debian-exim clamav',
        unless  => 'id -Gn clamav | grep -q Debian-exim',
        path    => '/bin:/sbin:/usr/bin:/usr/sbin',
        require =>  Package['clamav-daemon'],
    }

    file { '/etc/clamav/clamd.conf':
        owner   => 'root',
        group   => 'root',
        mode    => '0444',
        source  => 'puppet:///modules/clamav/clamd.conf',
        require => Package['clamav-daemon'],
    }

    # Add proxy settings to freshclam
    file_line { 'freshclam_proxyserver':
        line   => "HTTPProxyServer webproxy.${::site}.wmnet",
        path   => '/etc/clamav/freshclam.conf',
        notify => Service['clamav-freshclam'],
    }
    file_line { 'freshclam_proxyport':
        line    => 'HTTPProxyPort 8080',
        path    => '/etc/clamav/freshclam.conf',
        notify => Service['clamav-freshclam'],
    }
    service { 'clamav-freshclam':
        ensure    => running,
    }

    service { 'clamav-daemon':
        ensure    => running,
        require   => File['/etc/clamav/clamd.conf'],
        subscribe => File['/etc/clamav/clamd.conf'],
    }
}
