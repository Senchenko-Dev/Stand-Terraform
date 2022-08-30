"""Module for convert json input file to yaml"""
from json import load, dumps
from yaml import dump as create_yaml
from os import chdir
import sys


def read_data(filename):
    """Read json data from file"""
    with open(filename) as file:
        for string in file.readlines():
            data = string.split(' ')
    return data


def get_count_of_nodes(filename):
    """Count nodes in json data"""
    count_postgres = 0
    count_etcd = 0
    data = read_data(filename)
    if len(data) == 1:
        count_postgres += 1
    elif len(data) == 3:
        count_postgres += 2
        count_etcd += 1
    else:
        raise ValueError('Hosts list may be contain one or three elements')
    return {'postgres': count_postgres, 'etcd': count_etcd}


def write_customized_json(filename):
    """Write customize json file
       Replace postgres tag to first, second tag
    """
    position_of_node = ['first', 'second']
    type_of_node = ['master', 'replica']
    data_for_write = {}
    data = read_data('hosts')
    check_counts = get_count_of_nodes('hosts')
    with open(filename, 'a') as file:
        if check_counts['postgres'] == 2:
            for number, line in enumerate(data):
                if number == 0 or number == 1:
                    data_for_write[position_of_node[number] + '_postgres_node'] = {"hostvars": {type_of_node[number]:
                                                                                   {"ansible_host": data[number], }}}
                elif number == 2:
                    data_for_write['etcd_node'] = {"hostvars": {"etcd": {'ansible_host': data[number], }}}
                    data_for_write['cluster'] = {"hostvars": {'ansible_connection': 'ssh', }}
        elif check_counts['postgres'] == 1:
            data_for_write['postgres_node'] = {"hostvars": {"master": {'ansible_host': data[-1],}}}
            data_for_write['standalone'] = {"hostvars": {'ansible_connection': 'ssh', }}
        file.write(dumps(data_for_write, indent=2))


if __name__ == '__main__':
    inventory = sys.argv[1]
    write_customized_json('output.json')
    with open('output.json', 'r') as file:
        chdir('../inventories/' + inventory)
        with open('hosts.yml', 'w') as host_file:
            host_file.write(create_yaml(load(file)))

