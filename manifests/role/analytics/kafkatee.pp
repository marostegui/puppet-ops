# == Class role::analytics::kafkatee
# Base role class for installing kafkatee.
# Your kafkatee outputs should store output
# $log_directory (/srv/log).
#
class role::analytics::kafkatee {
    require role::analytics::kafka::config

    # Install kafkatee configured to consume from
    # the Kafka cluster.  The default
    # $output_format for this class will work for us,
    # so we do not set it manually here.
    class { '::kafkatee':
        kafka_brokers           => $role::analytics::kafka::config::brokers_array,
        log_statistics_interval => 15,
    }

    $log_directory            = '/srv/log'
    file { $log_directory:
        ensure      => 'directory',
        owner       => 'kafkatee',
        group       => 'kafkatee',
        require     => Class['kafaktee'],
    }
}


# == Class role::analytics::kafkatee::webrequest
# Base role class for webrequest data logging via
# kafkatee.  This class installs kafkatee and
# sets up webrequest log and archive directories
# and logrotate rules.
#
class role::analytics::kafkatee::webrequest inherits role::analytics::kafkatee {
    $webrequest_log_directory     = "${log_directory}/webrequest"
    $webrequest_archive_directory = "${$webrequest_log_directory}/archive"
    file { [$webrequest_log_directory, $webrequest_archive_directory]:
        ensure      => 'directory',
        owner       => 'kafkatee',
        group       => 'kafkatee',
        require     => Class['kafaktee'],
    }

    # if the logs in $log_directory should be rotated
    # then configure a logrotate.d script to do so.
    file { '/etc/logrotate.d/kafaktee-webrequest':
        mode    => '0444',
        owner   => 'root',
        group   => 'root',
        content => "# Note:  This file is managed by Puppet.

# Rotate anything in ${webrequest_log_directory}/*.log daily
${webrequest_log_directory}/*.log {
	daily
	olddir $webrequest_archive_directory
	notifempty
	nocreate
	maxage 180
	rotate 1000
	dateext
	compress
	postrotate
		service kafkatee reload
	endscript
}
"
    }
}


# == Class role::analytics::kafkatee::input::webrequest::mobile
# Sets up kafkatee to consume from webrequest_mobile topic and
# output desired files sampling and filtering this topic.
#
class role::analytics::kafkatee::webrequest::mobile inherits role::analytics::kafkatee::webrequest {
    include role::analytics::kafkatee::input::webrequest::mobile

    ::kafkatee::output { 'mobile-sampled-100':
        destination => "${webrequest_log_directory}/mobile-sampled-100.tsv.log",
        sample      => 100,
    }

    # TODO: wikipedia-zero log output
}


# == Class role::analytics::kafkatee::input::webrequest::mobile
# Sets up a kafkatee input to consume from the webrequest_mobile topic
# This is its own class so that if a kafkatee instance wants
# to consume from multiple topics, it may include each
# topic as a class.
#
class role::analytics::kafkatee::input::webrequest::mobile {
    ::kafkatee::input { 'kafka-webrequest_mobile':
        topic       => 'webrequest_mobile',
        partitions  => '0-9',
        options     => { 'encoding' => 'json' },
    }
}

