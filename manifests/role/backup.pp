# A set of roles for the backup director, storage and client as they are
# configured in WMF

$director = "FILLMEIN"

class role::backup::director {
    system_role { "role::backup::director": description => "Primary Backup server" }

    class { 'bacula::director':
        sqlvariant          => 'mysql',
        max_dir_concur_jobs => '10',
    }

    # One pool for all
    bacula::director::pool { 'WMF':
        max_vols         => 30,
        storage          => 'WMFFiles',
        volume_retention => '180 days',
    }

    # One schedule per day of the week.
    # Setting execution times so that it is unlikely jobs will run concurrently
    # with cron.{hourly,daily,monthly} or other cronscripts
    $days = ['Sat', 'Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri']

    backup::schedule { $days:
        pool    => 'WMF',
    }

    # This has been taken straight from old files/backup/disklist-*
    bacula::director::fileset { 'a-sqldata':
        includes     => [ '/a/sqldata']
    }
    bacula::director::fileset { 'a-backup':
        includes => [ '/a/backup' ]
    }
    bacula::director::fileset { 'a-eventlogging':
        includes => [ '/a/eventlogging' ]
    }
    bacula::director::fileset { 'a-sqldata':
        includes => [ '/a/sqldata' ]
    }
    bacula::director::fileset { 'home':
        includes => [ '/home' ]
    }
    bacula::director::fileset { 'mnt-a':
        includes => [ '/mnt/a' ]
    }
    bacula::director::fileset { 'root':
        includes => [ '/root' ]
    }
    bacula::director::fileset { 'srv-autoinstall':
        includes => [ '/srv/autoinstall' ]
    }
    bacula::director::fileset { 'srv-tftpboot':
        includes => [ '/srv/tftpboot' ]
    }
    bacula::director::fileset { 'srv-wikimedia':
        includes => [ '/srv/wikimedia' ]
    }
    bacula::director::fileset { 'svnroot':
        includes => [ '/svnroot' ]
    }
    bacula::director::fileset { 'svnroot-bak':
        includes => [ '/svnroot/bak' ]
    }
    bacula::director::fileset { 'var-lib-gerrit2-review_site-git':
        includes => [ '/var/lib/gerrit2/review_site/git' ]
    }
    bacula::director::fileset { 'var-lib-jenkins-backups':
        includes => [ '/var/lib/jenkins/backups' ]
    }
    bacula::director::fileset { 'var-lib-mailman':
        includes => [ '/var/lib/mailman' ]
    }
    bacula::director::fileset { 'var-lib-puppet-ssl':
        includes => [ '/var/lib/puppet/ssl' ]
    }
    bacula::director::fileset { 'var-opendj-backups':
        includes => [ '/var/opendj/backups' ]
    }
    bacula::director::fileset { 'var-vmail':
        includes => [ '/var/vmail' ]
    }

    # The console should be on the director 
    bacula::console { 'bconsole':
        director   => $::fqdn,
    }
}

class role::backup::storage() {
    system_role { "role::backup::storage": description => "Storage backup server" }

    class { 'bacula::storage':
        director            => $director,
        sd_max_concur_jobs  => 5,
        sqlvariant          => 'mysql',
    }
    
    bacula::storage::device { 'FileStorage':
        device_type     => 'File',
        media_type      => 'File',
        archive_device  => '/srv/backups',
        max_concur_jobs => 2,
    }
}
