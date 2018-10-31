#!/remote/us01it1/galaxy/python/bin/python2.7
# -*- coding: utf-8 -*-
import os
import sys
import time
import json
import errno
import xmltodict
import argparse
from elasticsearch import Elasticsearch, helpers
from configuration import *
import configuration as config

# Import netapp module
current_dir = os.path.dirname(os.path.realpath(__file__))
netapp_module = current_dir + '/netapp-manageability-sdk-9.3/lib/python/NetApp'
sys.path.append(netapp_module)
from NaServer import *

# Global variables
json_dir = current_dir + '/JSONs/'
messages = []

output_dict = {}


def login_naserver(cluster):
    '''Global variables'''
    hostname = cluster
    username = config.username
    password = config.password
    port = 80
    serverType = 'FILER'
    transportType = 'HTTP'

    # Connect to NaServer
    server = NaServer(hostname, 1, 101)
    server.set_server_type(serverType)
    server.set_transport_type(transportType)
    server.set_port(port)
    server.set_style('LOGIN')
    server.set_admin_user(username, password)

    return server


def check_naserver_status(server, api):
    '''Check the status of Netapp server'''
    output = server.invoke_elem(api)
    if (output.results_status() == 'failed'):
        print('Error:\n')
        print(output.sprintf())
        sys.exit(1)
    else:
        return output


def write_json_file(file_name, json_string):
    '''Write JSON output to a file'''

    if not os.path.exists(json_cluster_dir):
        os.makedirs(json_cluster_dir)

    json_file = json_cluster_dir + '/' + file_name
    with open(json_file, 'w') as f:
        f.write(json_string)


def write_messages_to_file(cluster, messages):
    '''Write output to a file'''

    # Make an output directory, if it does not exist
    output_dir = json_dir + 'output'
    if not os.path.exists(output_dir):
        os.makedirs(output_dir)

    # Create an output file with timestamp
    output_file = output_dir + '/' + cluster + '_' + 'output'

    print 'Validation Output:'
    with open(output_file, 'w') as f:
        for message in messages:
            print message
            f.write(message + '\n')
        # f.write('This file was generated at', str(time.time()))


def connect_to_elasticsearch():
    try:
        es = Elasticsearch(
            hosts=[config.eshostname],
            http_auth=(config.eshostname, config.espassword),
            port=9200,
        )
        return es

    except Exception as ex:
        print "Error:", ex
        sys.exit()


def write_to_elasticsearch(cluster, json_string, api_name):
    '''Write JSON files to elasticsearch DB'''
    es = connect_to_elasticsearch()
    try:
        es.index(index='config-management', doc_type=cluster,
                 id=api_name, body=json.loads(json_string))
    except Exception as e:
        raise e


def data_extraction_steps(api_name, cluster, server):
    api = NaElement(api_name)

    # Check NAserver status
    output = check_naserver_status(server, api)

    # Convert XML to JSON
    xml_string = output.sprintf().encode('utf8')
    # print xml_string
    json_string = json.dumps(xmltodict.parse(xml_string), indent=4)
    # time.sleep(30)

    # Write JSON output to a file
    # write_json_file(api_name + '.json', json_string)

    # Write JSON to elastic search database
    write_to_elasticsearch(cluster, json_string, api_name)

    return json_string

##################### Data Extraction #####################


def license_v2_list_info(cluster, server):
    '''Get license information of a cluster'''
    api_name = 'license-v2-list-info'
    data_extraction_steps(api_name, cluster, server)


def cluster_node_get_iter(cluster, server):
    '''Returns information about nodes in a cluster'''
    api_name = 'cluster-node-get-iter'
    data_extraction_steps(api_name, cluster, server)


def system_image_get_iter(cluster, server):
    '''Display sofware image information'''
    api_name = 'system-image-get-iter'
    data_extraction_steps(api_name, cluster, server)


def net_port_get_iter(cluster, server):
    '''Iterate over a list of network port objects'''
    api_name = 'net-port-get-iter'
    data_extraction_steps(api_name, cluster, server)


def autosupport_config_get_iter(cluster, server):
    '''Get current status of AutoSupport'''
    api_name = 'autosupport-config-get-iter'
    data_extraction_steps(api_name, cluster, server)


def storage_disk_get_iter(cluster, server):
    '''Get status of failed disks'''
    api_name = 'storage-disk-get-iter'
    data_extraction_steps(api_name, cluster, server)


def ldap_config_get_iter(cluster, server):
    '''Check if ldap is configured'''
    api_name = 'ldap-config-get-iter'
    data_extraction_steps(api_name, cluster, server)


def net_dns_get_iter(cluster, server):
    '''Check if DNS is enabled'''
    api_name = 'net-dns-get-iter'
    data_extraction_steps(api_name, cluster, server)


def net_routes_get_iter(cluster, server):
    '''Make sure the metrics are different for gateways.'''
    api_name = 'net-routes-get-iter'
    data_extraction_steps(api_name, cluster, server)


def service_processor_get_iter(cluster, server):
    '''Check if each node has an IP'''
    api_name = 'service-processor-get-iter'
    data_extraction_steps(api_name, cluster, server)


def volume_get_iter(cluster, server):
    '''Check for offline volumes'''
    api_name = 'volume-get-iter'
    data_extraction_steps(api_name, cluster, server)


def aggr_get_iter(cluster, server):
    '''Check the aggregate'''
    api_name = 'aggr-get-iter'
    data_extraction_steps(api_name, cluster, server)


def snapmirror_get_iter(cluster, server):
    '''Get snapmirror relationships of a cluster'''
    api_name = 'snapmirror-get-iter'
    data_extraction_steps(api_name, cluster, server)


def data_extraction(cluster, server):
    license_v2_list_info(cluster, server)
    cluster_node_get_iter(cluster, server)
    system_image_get_iter(cluster, server)
    net_port_get_iter(cluster, server)
    autosupport_config_get_iter(cluster, server)
    storage_disk_get_iter(cluster, server)
    ldap_config_get_iter(cluster, server)
    net_dns_get_iter(cluster, server)
    # net_routes_get_iter(cluster, server)
    # service_processor_get_iter(cluster, server)
    # volume_get_iter(cluster, server)
    # aggr_get_iter(cluster, server)
    snapmirror_get_iter(cluster, server)
