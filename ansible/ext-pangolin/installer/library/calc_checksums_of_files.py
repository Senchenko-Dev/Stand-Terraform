#!/usr/bin/python

# Copyright: (c) 2021, Roman Aminov <RMuAminov@sberbank.ru>
# GNU General Public License v3.0+ (see COPYING or https://www.gnu.org/licenses/gpl-3.0.txt)
from __future__ import (absolute_import, division, print_function)

__metaclass__ = type

DOCUMENTATION = r'''
---
module: calc_checksums_of_files

short_description: Module for calculate checksum for data from directory

version_added: "1.0.0"

description: Module for calculate checksum for data from directory

author:
    - Roman Aminov
'''

EXAMPLES = r'''

'''

RETURN = r'''
'''

import sys
from ansible.module_utils.basic import AnsibleModule
import zlib
import os

result = dict(
    changed = False,
    original_message = '',
    message = ''
)

def run_module():
    module_args = dict(
        dir_path = dict(type = 'str', required = True)
    )

    module = AnsibleModule(argument_spec = module_args,
                           supports_check_mode = True)

    dir_path = module.params['dir_path']

    res_str = calc_checksums(dir_path)

    result['message'] = res_str
    if len(res_str) > 0:
        result['original_message'] = "OK"
    else:
        result['original_message'] = "ERROR"

    module.exit_json(**result)

def calc_checksum_of_file(the_file):
    with open(the_file, 'rb') as fp:
        data = fp.read()
        res_chcks = zlib.crc32(data)
        return [res_chcks, the_file]

def get_sorted_list_of_files(current_dir):
    lst_of_files = []
    for dirpath, dirnames, filenames in os.walk(current_dir):
        for filename in filenames:
            lst_of_files.append(os.path.join(dirpath, filename))
    return sorted(lst_of_files)

def calc_checksums(current_dir):
    lst_of_checksums = []

    lst_of_files = get_sorted_list_of_files(current_dir)
    for f in lst_of_files:
        lst_of_checksums.append(calc_checksum_of_file(f))
    return ','.join(str(x) for x in lst_of_checksums)

def main():
    run_module() 

if __name__ == "__main__":
    main()