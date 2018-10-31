from configuration import *
import extract_validate as ev


messages = []
output_dict = {}


def validate_license(cluster):
    licenses = []
    body = {
        "query": {
            "match": {
                "_id": "license-v2-list-info"
            }
        }
    }
    es = ev.connect_to_elasticsearch()
    res = es.search(index="config-management",
                    doc_type=cluster, body=body)
    for doc in res['hits']['hits']:
        license_v2_info = doc['_source']['results']['licenses']['license-v2-info']
        for license in license_v2_info:
            licenses.append(license['description'].encode('utf8'))
    # print set(licenses)

    # Check if invalid licenses are in the cluster.
    result = all(elem in set(licenses) for elem in set(invalid_license_list))
    if result:
        message = 'License not valid'
        output_dict['License'] = message
        print(message)
    else:
        message = 'License Valid'
        output_dict['License'] = message
        print(message)



def validate_clusterinfo(cluster):
    # print 'Validation check for node-failover:'
    faulty_nodes = []
    body = {
        "query": {
            "match": {
                "_id": "cluster-node-get-iter"
            }
        }
    }
    es = ev.connect_to_elasticsearch()
    res = es.search(index="config-management",
                    doc_type=cluster, body=body)

    for doc in res['hits']['hits']:
        nodes = doc['_source']['results']['attributes-list']['cluster-node-info']

        for i in range(len(nodes)):
            # print nodes[i]
            if nodes[i]['is-node-eligible'] == 'false' or \
                    nodes[i]['is-node-healthy'] == 'false':
                faulty_nodes.append(nodes[i]['node-name'].encode('utf8'))

        if faulty_nodes:
            message = 'Node Failover - NOK'
            messages.append(message)
            print message
            output_dict['is-node-eligible-for-failover'] = 'False'
        else:
            message = 'Node Failover - OK'
            messages.append(message)
            print message
            output_dict['is-node-eligible-for-failover'] = 'True'


def validate_system_image(cluster):
    # print 'Validation for ONTAP version:'
    faulty_nodes = []
    body = {
        "query": {
            "match": {
                "_id": "system-image-get-iter"
            }
        }
    }
    es = ev.connect_to_elasticsearch()
    res = es.search(index="config-management",
                    doc_type=cluster, body=body)

    for doc in res['hits']['hits']:
        nodes = doc['_source']['results']['attributes-list']['system-image-attributes']

        for i in range(len(nodes)):
            if nodes[i]['is-current'] == 'true':
                if nodes[i]['version'] != ontap_version:
                    faulty_nodes.append(nodes[i]['node'].encode('utf8'))

        message = 'ONTAP Version - %s' % nodes[i]['version']
        messages.append(message)
        print message
        output_dict['ontap-version'] = nodes[i]['version']


def validate_autosupport(cluster):
    # print '\nValidation check for auto-support:'
    faulty_nodes = []
    body = {
        "query": {
            "match": {
                "_id": "autosupport-config-get-iter"
            }
        }
    }
    es = ev.connect_to_elasticsearch()
    res = es.search(index="config-management",
                    doc_type=cluster, body=body)

    for doc in res['hits']['hits']:
        nodes = doc['_source']['results']['attributes-list']['autosupport-config-info']

    # if d['results']['@status'] == 'passed':
    #     nodes = d['results']['attributes-list']['autosupport-config-info']

        for i in range(len(nodes)):
            if nodes[i]['is-enabled'] == 'false':
                faulty_nodes.append(nodes[i]['node-name'].encode('utf8'))

        if faulty_nodes:
            message = 'Auto Support - NOK'
            messages.append(message)
            print message
            output_dict['auto-support'] = 'Not enabled'
        else:
            message = 'Auto Support - OK'
            messages.append(message)
            print message
            output_dict['auto-support'] = 'Enabled'


def validate_storage_disk_get_iter(cluster):
    faulty_disks = []
    body = {
        "query": {
            "match": {
                "_id": "storage-disk-get-iter"
            }
        }
    }
    es = ev.connect_to_elasticsearch()
    res = es.search(index="config-management",
                    doc_type=cluster, body=body)

    for doc in res['hits']['hits']:
        nodes = doc['_source']['results']['attributes-list']['storage-disk-info']

        for i in range(len(nodes)):
            if nodes[i]['disk-ownership-info']['is-failed'] == 'true':
                faulty_disks.append(
                    nodes[i]['disk-paths']['disk-path-info']
                    [0]['disk-name'].encode('utf8'))
                print nodes[i]['disk-paths']['disk-path-info'][0]['node']

        if faulty_disks:
            message = 'Failed Disk(s) - YES'
            messages.append(message)
            print message
            print faulty_disks
            output_dict['auto-support'] = 'Not enabled'
        else:
            message = 'Failed Disk(s) - NO'
            messages.append(message)
            print message
            output_dict['auto-support'] = 'Enabled'


def validate_ldap_config_get_iter(cluster):
    faulty_nodes = []
    body = {
        "query": {
            "match": {
                "_id": "ldap-config-get-iter"
            }
        }
    }
    es = ev.connect_to_elasticsearch()
    res = es.search(index="config-management",
                    doc_type=cluster, body=body)

    d = res['hits']['hits'][0]['_source']

    if d['results']['@status'] == 'passed':
        print '*' * 100
        print d['results']['attributes-list']['ldap-config']
        print '*' * 100

        if d['results']['attributes-list']['ldap-config']['client-enabled']:
            message = 'Ldap configured - OK'
            messages.append(message)
            print message
            output_dict['LDAP Configuration'] = 'Enabled'
        else:
            message = 'Ldap configured - NOK'
            messages.append(message)
            print message
            output_dict['LDAP Configuration'] = 'Not enabled'


def validate_net_dns_get_iter(cluster):
    faulty_nodes = []
    body = {
        "query": {
            "match": {
                "_id": "net-dns-get-iter"
            }
        }
    }
    es = ev.connect_to_elasticsearch()
    res = es.search(index="config-management",
                    doc_type=cluster, body=body)

    d = res['hits']['hits'][0]['_source']

    if d['results']['@status'] == 'passed':
        nodes = d['results']['attributes-list']['net-dns-info']

        for i in range(len(nodes)):
            if nodes[i]['dns-state'] != 'enabled':
                faulty_nodes.append(nodes[i]['vserver-name'].encode('utf8'))
                # print nodes[i]['vserver-name'].encode('utf8')

        if faulty_nodes:
            message = 'DNS Configured - NOK'
            messages.append(message)
            print message
            output_dict['DNS Configured'] = 'Not enabled'
        else:
            message = 'DNS Configuration - OK'
            messages.append(message)
            print message
            output_dict['DNS Configuration'] = 'Enabled'


def validate_aggr_get_iter(cluster):
    '''Check for all aggregates that are over a certain percent in usage'''
    faulty_aggrs = []
    body = {
        "query": {
            "match": {
                "_id": "aggr-get-iter"
            }
        }
    }
    es = ev.connect_to_elasticsearch()
    res = es.search(index="config-management",
                    doc_type=cluster, body=body)

    # with open(json_cluster_dir + '/' + 'aggr-get-iter.json') as json_data:
    #     d = json.load(json_data)

    d = res['hits']['hits'][0]['_source']

    if d['results']['@status'] == 'passed':
        nodes = d['results']['attributes-list']['aggr-attributes']

        for i in range(len(nodes)):
            size_used = float(nodes[i]['aggr-space-attributes']['size-used'])
            size_total = float(nodes[i]['aggr-space-attributes']['size-total'])
            percent_used = round(float(size_used/size_total) * 100, 0)

            if percent_used > 95:
                faulty_aggrs.append(nodes[i]['aggregate-name'])
                # print nodes[i]['aggregate-name']

        if faulty_aggrs:
            message = 'Aggregates - NOK'
            messages.append(message)
            print message
            output_dict['aggregate'] = 'Some/All aggregates over 90 used'
        else:
            message = 'Aggregates - OK'
            messages.append(message)
            print message
            output_dict['aggregate'] = 'All aggregates are within limit'


def validate_snapmirror_get_iter(cluster):
    '''Validate snamirror relationship'''
    faulty_aggrs = []
    body = {
        "query": {
            "match": {
                "_id": "snapmirror-get-iter"
            }
        }
    }
    es = ev.connect_to_elasticsearch()
    res = es.search(index="config-management",
                    doc_type=cluster, body=body)

    d = res['hits']['hits'][0]['_source']

    if d['results']['@status'] == 'passed':
        nodes = d['results']['attributes-list']['snapmirror-info']

        for i in range(len(nodes)):
            if nodes[i]['relationship-type'] == 'extended_data_protection':
                print 'James Bond!'
            else:
                print 'Not a James Bond'


def validate_volume_get_iter(cluster):
    '''Check for all volumes that are over a certain percent in usage'''
    faulty_vols = []
    body = {
        "query": {
            "match": {
                "_id": "volume-get-iter"
            }
        }
    }
    es = ev.connect_to_elasticsearch()
    res = es.search(index="config-management",
                    doc_type=cluster, body=body)

    # with open(json_cluster_dir + '/' + 'aggr-get-iter.json') as json_data:
    #     d = json.load(json_data)

    d = res['hits']['hits'][0]['_source']

    if d['results']['@status'] == 'passed':
        nodes = d['results']['attributes-list']['volume-attributes']

        for i in range(len(nodes)):
            size_used = float(nodes[i]['volume-space-attributes']['size-used'])
            size_total = float(
                nodes[i]['volume-space-attributes']['size-total'])
            percent_used = round(float(size_used/size_total) * 100, 0)
            print size_used, size_total, percent_used

            if percent_used > 50:
                faulty_vols.append(nodes[i]['volume-id-attributes']['name'])
                # print nodes[i]['aggregate-name']

        if faulty_vols:
            message = 'Volumes - NOK'
            messages.append(message)
            print message
            output_dict['volume'] = 'Some/All volumes over 90 used'
        else:
            message = 'Volumes - OK'
            messages.append(message)
            print message
            output_dict['volume'] = 'All volumes are within limit'

    print faulty_vols


def data_validation(cluster):
    validate_license(cluster)
    validate_clusterinfo(cluster)
    validate_system_image(cluster)
    validate_autosupport(cluster)
    # validate_storage_disk_get_iter(cluster)
    validate_ldap_config_get_iter(cluster)
    validate_net_dns_get_iter(cluster)
    # validate_net_routes_get_iter(cluster)
    # validate_service_processor_get_iter(cluster)
    # validate_volume_get_iter(cluster)
    # validate_aggr_get_iter(cluster)
    # validate_snapmirror_get_iter(cluster)
