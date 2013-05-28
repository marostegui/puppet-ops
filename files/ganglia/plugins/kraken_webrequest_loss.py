#!/usr/bin/env python
# -*- coding: utf-8 -*-
"""
    Python Gmond Module for Kraken Webrequest Loss Percentage.
    Loss percentage per source host data is generated by the packetloss
    Oozie job in Kraken.

    :copyright: (c) 2012 Wikimedia Foundation
    :author: Andrew Otto <otto@wikimedia.org>
    :license: GPL

"""
from __future__ import print_function

import logging
import commands

UPDATE_INTERVAL = 3600 # seconds

# Config for multiple metrics.
# Currently we only compute a single webrequest loss
# percentage, but this allows us to add more later.
metrics = {
    'webrequest_loss_average': {
        'description': 'Average Webrequest Loss Percentage',
        'path':        '/wmf/data/webrequest/loss',
    }
}

def latest_loss_path(metric_name):
    """Returns HDFS path to the most recently generated webrequest loss data."""
    logging.debug("latest_loss_path(%s)" % metrics[metric_name]['path'])
    return commands.getoutput("/usr/bin/hadoop fs -ls %s | /usr/bin/tail -n 1 | /usr/bin/awk '{print $NF}'" % (metrics[metric_name]['path']))

def loss_data(loss_path):
    """Returns the output data inside the HDFS loss_path."""
    logging.debug("loss_data(%s)" % loss_path)
    return commands.getoutput("/usr/bin/hadoop fs -cat %s/part*" % (loss_path))

def loss_average(loss_data):
    """Parses loss_data for loss percentages and averages them all."""
    logging.debug("loss_average(%s)" % loss_data)
    percent_sum = 0.0
    loss_lines = loss_data.split("\n")
    for line in loss_lines:
        fields = line.split("\t")
        percent = fields[-1]
        percent_sum += float(percent)

    average_percent = (percent_sum / float(len(loss_lines)))
    return average_percent

def metric_handler(name):
    """Get value of particular metric; part of Gmond interface"""
    logging.debug('metric_handler(): %s', name)
    return loss_average(loss_data(latest_loss_path(name)))

def metric_init(params):
    global descriptors

    descriptors = []
    for metric_name, metric_config in metrics.items():
        descriptors.append({
            'name': metric_name,
            'call_back': metric_handler,
            'time_max': 3660,
            'value_type': 'float',
            'units': '%',
            'slope': 'both',
            'format': '%f',
            'description': metric_config['description'],
            'groups': 'analytics'
        })

    return descriptors


def metric_cleanup():
    """Teardown; part of Gmond interface"""
    pass


if __name__ == '__main__':
    # When invoked as standalone script, run a self-test by querying each
    # metric descriptor and printing it out.
    logging.basicConfig(level=logging.DEBUG)
    for metric in metric_init({}):
        value = metric['call_back'](metric['name'])
        print(( "%s => " + metric['format'] ) % ( metric['name'], value ))
