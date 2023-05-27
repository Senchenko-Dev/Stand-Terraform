#!/usr/bin/python
# -*- coding: utf-8 -*-

DOCUMENTATION = '''
---
module: dos2unix
description: convert CRLF files to LF
options:
	path:
	depth: (OPTIONAL)
'''
EXAMPLES = '''
- name: dos2unix files
    - dos2unix:
        path:   {{ mypath }}
        depth:  10

- name: dos2unix files depth 1
    - dos2unix:
        path:   {{ mypath }}
'''

import os

from ansible.module_utils.basic import AnsibleModule


def get_filenames_with_depth(path, depth):
    if depth > 0:
        for name in os.listdir(path):
            full_path = os.path.join(path, name)

            if os.path.isfile(full_path):
                yield full_path
            else:
                for sub_path in get_filenames_with_depth(full_path, depth - 1):
                    yield sub_path


def crlf_to_lf(filename):
    _crlf = b'\r\n'
    _lf = b'\n'

    with open(filename, 'rb') as open_file:
        content = open_file.read()

    if b'\0' in content:
        # Binary file
        return False

    if content != content.replace(_crlf, _lf):
        content = content.replace(_crlf, _lf)
        with open(filename, 'wb') as open_file:
            open_file.write(content)
        return True
    else:
        return False


def dos2unix(depth, path):
    result = False
    is_exception = False
    message = []
    try:
        message.append('Depth: {}  Path: {}'.format(depth, path))
        path = os.path.normpath(path)
        files_for_work = get_filenames_with_depth(path, depth)
        for file in files_for_work:
            if crlf_to_lf(os.path.normpath(file)):
                result = True
                message.append("File changed: {}".format(file))

    except Exception as ex:
        is_exception = True
        message.append("*** EXCEPTION *** At exception of type {} occurred.".format(type(ex).__name__))
        message.append("*** EXCEPTION *** Args:{}".format(ex.args))
    finally:
        return result, message, is_exception


def main():
    fields = {
        "path": {"required": True, "type": "str"},
        "depth": {"required": False, "type": "int", "default": 1}
    }
    module = AnsibleModule(argument_spec=fields)
    work_path = module.params['path']
    work_depth = module.params['depth']
    result, message, is_exception = dos2unix(work_depth, work_path)
    if is_exception:
        module.fail_json(changed=result, msg='\n'.join(message))
    else:
        module.exit_json(changed=result, msg='\n'.join(message))


if __name__ == '__main__':
    main()
