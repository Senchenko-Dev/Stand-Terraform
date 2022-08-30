#!/usr/bin/env python

import argparse
import json
import yaml
import re
import os


class Inventory(object):
    def __init__(self, **kwargs):
        self.entries = kwargs['entries']
        self.processed_entries = kwargs['empty_inventory']
        self.postgres_nodes_list = []
        self.etcd_nodes_list = []

    def generate_hosts(self):
        """Parse yaml data and get hosts names"""
        for host, attributes in self.entries.items():
            if re.search(r'postgres_node\b', host):
                self.processed_entries['postgres_nodes'] = {}
                self.postgres_nodes_list.append((list(attributes['hostvars'])[0]))
                self.processed_entries['postgres_nodes'].update({'hosts': self.postgres_nodes_list})
            elif re.search(r'etcd_node\b', host):
                self.processed_entries['etcd_nodes'] = {}
                self.etcd_nodes_list.append((list(attributes['hostvars'])[0]))
                self.processed_entries['etcd_nodes'].update({'hosts': self.etcd_nodes_list})

    def generate_groups(self):
        """Parse yaml data and get tags"""
        for host, attributes in self.entries.items():
            if 'postgres_node' in host:
                self.processed_entries['postgres_group'] = {}
                self.processed_entries['postgres_group'].update({'children': ['postgres_nodes']})
            elif 'etcd_node' in host:
                self.processed_entries['etcd_group'] = {}
                self.processed_entries['etcd_group'].update({'children': ['etcd_nodes']})
            else:
                self.processed_entries[host] = {}
                if self.processed_entries.get('etcd_nodes'):
                    self.processed_entries[host].update({'children': ['postgres_group', 'etcd_group']})
                else:
                    self.processed_entries[host].update({'children': ['postgres_group']})

    def generate_hostvars(self):
        """Parse yaml data and get host name, ansible and other variables"""
        self.processed_entries['_meta'] = {"hostvars": {}}
        _temp_meta = {}
        for host, attributes in self.entries.items():
            if 'node' in host:
                for key, value in attributes['hostvars'].items():
                    _temp_meta.update({key: value})
        self.processed_entries['_meta']['hostvars'].update(_temp_meta)


def load_inventory_file():
    """Load data from yaml file"""
    hosts_file = os.path.dirname(os.path.realpath(__file__)) + '/' + 'hosts.yml'
    with open(hosts_file, "r") as file:
        try:
            return yaml.load(file, Loader=yaml.FullLoader)
        except yaml.YAMLError as exception:
            print(exception)


if __name__ == '__main__':
    parser = argparse.ArgumentParser()
    parser.add_argument('--list', action='store_true')
    parser.add_argument('--host', action='store')
    args = parser.parse_args()
    if args.host:
        inventory_data = load_inventory_file()
        inventory_args = {'entries': inventory_data, 'empty_inventory': {}}
        inventory = Inventory(**inventory_args)
        inventory.generate_hosts()
        inventory.generate_groups()
        inventory.generate_hostvars()
        print(json.dumps(inventory.processed_entries['_meta']['hostvars'][args.host], indent=2))
    else:
        inventory_data = load_inventory_file()
        inventory_args = {'entries': inventory_data, 'empty_inventory': {}}
        inventory = Inventory(**inventory_args)
        inventory.generate_hosts()
        inventory.generate_groups()
        inventory.generate_hostvars()
        print(json.dumps(inventory.processed_entries, indent=2))
