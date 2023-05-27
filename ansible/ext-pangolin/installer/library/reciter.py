#!/usr/bin/python

# Copyright: (c) 2020, Pavel Kraskin <PMKraskin@sberbank.ru>
# GNU General Public License v3.0+ (see COPYING or https://www.gnu.org/licenses/gpl-3.0.txt)
from __future__ import (absolute_import, division, print_function)

__metaclass__ = type

DOCUMENTATION = r'''
---
module: reciter

short_description: Module for read configurations file

version_added: "1.0.2"

description: This is module for read and seacrh some parameters in 
configurations file. This version can read patroni(yml), pgbouncer(ini), postgresql(conf) and
systemd(unit service) configuration files.

options:
    src:
        description: Path to configuration file
        required: true
        type: str
    action:
        description: Type of action. Action will be get or check.
        required: true
        type: str
    parameter:
        description: Name of general parameter, which will find in configuration file
        required: true
        type: str
    inner_parameter:
        description: Name of nasted parameter, which will find in general parameter
        required: true
        type: str

author:
    - Pavel Kraskin (@Emojomaker)
'''

EXAMPLES = r'''

'''

RETURN = r'''
'''

from ansible.module_utils.basic import AnsibleModule
import os.path
import yaml
import re

try:
    import configparser
except ImportError:
    import ConfigParser as configparser

result = dict(
    changed=False,
    original_message='',
    message=''
)


def run_module():
    module_args = dict(
        src=dict(type='str', required=True),
        action=dict(choises=['check', 'get'], type='str', required=True),
        parameter=dict(type='str', required=True),
        inner_parameter=dict(type='str', required=False)
    )

    module = AnsibleModule(
        argument_spec=module_args,
        supports_check_mode=True
    )

    action = module.params['action']
    if action == 'check':
        search_patroni_parameter(module.params['src'], module.params['parameter'], module.params['inner_parameter'])
    elif action == 'get':
        get_value_of_parameter(module.params['src'], module.params['parameter'], module.params['inner_parameter'])
    module.exit_json(**result)


def check_configuration_file(path_to_file):
    if os.path.exists(path_to_file):
        return True
    else:
        result['message'] = False
        result['original_message'] = 'File {0} doesn`t exists or user doesn`t have permissions'.format(path_to_file)
        return False


def search_patroni_parameter(path_to_config, parameter, inner_parameter=None):
    if check_configuration_file(path_to_config):
        with open(path_to_config) as file:
            dict_with_parameters = yaml.safe_load(file)
            value_for_message = parameter if inner_parameter is None else inner_parameter
            if parameter in dict_with_parameters.keys():
                inner_values = dict_with_parameters.get(parameter)
                if isinstance(inner_values, dict):
                    item = loop_in_dict_values(inner_values, inner_parameter)
                    if item is None:
                        result['message'] = False
                        result['original_message'] = 'Parameter {0} didn`t find in patroni ' \
                                                     'configuration file'.format(inner_parameter)
                    else:
                        result['message'] = item['exists']
                        result['original_message'] = 'Parameter {0} found in patroni ' \
                                                     'configuration file'.format(inner_parameter)


def parse_unit_service_file(path_to_config):
    param_template = r'\w*\='
    list_of_parameters = {}
    with open(path_to_config) as file:
        for string in file.readlines():
            if re.match(param_template, string):
                params_with_value = string.replace('\n', '').replace('"', '').split('=')
                if len(params_with_value) >= 3:
                    key, value = params_with_value[0], params_with_value[1] + '=' + params_with_value[2]
                else:
                    key, value = params_with_value
                list_of_parameters.update({key: value})
    return list_of_parameters


def loop_in_dict_values(item_for_loop, inner_parameter=None):
    for key, value in item_for_loop.items():
        if isinstance(value, (str, int, bool)):
            if key == inner_parameter:
                return {'exists': True, 'value': value}
        elif isinstance(value, list):
            if key == inner_parameter:
                if len(value) == 1:
                    return {'exists': True, 'value': value[-1]}
                else:
                    return {'exists': True, 'value': value}
        elif isinstance(value, dict):
            item = loop_in_dict_values(value, inner_parameter)
            if item is not None:
                return item


def get_value_from_postgresql_conf(path_to_config, parameter):
    conf_file = open(path_to_config, 'r')
    res_data = {}
    for line in conf_file:
        if re.search(r'archive_command', line):
            line = re.sub(r"[\n\"\']", "", line)
            line = re.sub(r"[\ ]", "", line, 2)
        else:
            line = re.sub(r"[\n\"\'\ ]", "", line)
        elems = line.split("#")
        if len(elems[0]) == 0 or "=" not in elems[0]:
            continue
        elems = elems[0].split("=")
        if parameter == elems[0]:
            res_data[parameter] = elems[1]

    if len(res_data) > 0 and res_data.get(parameter) != None:
        return (res_data.get(parameter), True)

    return (None, False)


def get_value_of_parameter(path_to_config, parameter, inner_parameter=None):
    if check_configuration_file(path_to_config):
        if path_to_config.endswith('.yml'):
            with open(path_to_config) as file:
                data = yaml.safe_load(file)
                if parameter in data.keys():
                    inner_value = data.get(parameter)
                    value_for_message = parameter if inner_parameter is None else inner_parameter
                    result['original_message'] = 'Parameter {0} found in patroni' \
                                                 ' configuration file'.format(value_for_message)
                    if isinstance(inner_value, dict):
                        item = loop_in_dict_values(inner_value, inner_parameter)
                        try:
                            result['message'] = item['value']
                        except TypeError:
                            result['message'] = False
                            result['original_message'] = 'Parameter {0} didn`t find in patroni ' \
                                                         'configuration file'.format(inner_parameter)
                    elif isinstance(inner_value, (str, int, bool)):
                        result['message'] = inner_value
        elif path_to_config.endswith('.ini') or path_to_config.endswith('.tmpl'):
            config_reader = configparser.ConfigParser(allow_no_value=True)
            with open(path_to_config, 'r', encoding='utf-8') as file:
                read_file = re.sub(' {1,}', '', file.read())
            config_reader.read_string(read_file)
            try:
                content = config_reader.get('pgbouncer', parameter)
                result['message'] = content
                result['original_message'] = 'Parameter {0} found in pgbouncer' \
                                             ' configuration file'.format(parameter)
            except configparser.NoOptionError:
                result['original_message'] = 'Parameter {0} didn`t find in pgbouncer ' \
                                             'configuration file'.format(parameter)
        elif path_to_config.endswith('.conf'):
            if "postgresql.conf" in path_to_config:
                item = get_value_from_postgresql_conf(path_to_config, parameter)
                if item[1]:
                    result['message'] = item[0]
                    result['original_message'] = 'Parameter {0} found in postgresql.conf ' \
                                                 'configuration file'.format(parameter)
                else:
                    result['message'] = False
                    result['original_message'] = 'Parameter {0} didn`t find in postgresql.conf ' \
                                                 'configuration file'.format(parameter)
        elif path_to_config.endswith('.service'):
            parameters = parse_unit_service_file(path_to_config)
            if parameter in parameters.keys():
                result['message'] = parameters.get(parameter)
                result['original_message'] = 'Parameter {0} found in service unit file '.format(parameter)
            else:
                result['message'] = False
                result['original_message'] = 'Parameter {0} didn`t find service unit file'.format(parameter)

        else:
            result['original_message'] = 'File {0} with this extension does not supported'.format(
                path_to_config)


def main():
    run_module()


if __name__ == '__main__':
    main()
