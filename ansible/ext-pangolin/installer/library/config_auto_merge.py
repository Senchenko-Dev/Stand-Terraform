#!/usr/bin/python

# Copyright: (c) 2021, Roman Aminov <RMuAminov@sberbank.ru>
# GNU General Public License v3.0+ (see COPYING or https://www.gnu.org/licenses/gpl-3.0.txt)
from __future__ import (absolute_import, division, print_function)

__metaclass__ = type

DOCUMENTATION = r'''
---
module: config_auto_merge

short_description: Module for auto merge configs: postgres.yml, postgresql.conf or pg_hba.conf

version_added: "1.0.2"

description: Thise module for auto merge configs: postgres.yml, postgresql.conf or pg_hba.conf.

options:
    old_cfg_file:
        description: old config path
        required: True
        type: str
    new_cfg_file: 
        description: new config path
        required: True
        type: str
    result_cfg_file:
        description: result config path
        required: True
        type: str
    old_ver:
        description: old version of PostgreSQL SE (by default 00.00.00)
        required: False
        type: int 
    new_ver:
        description: new version of PostgreSQL SE (by default 00.00.00)
        required: False
        type: str
    root_path:
        description: path to the directory with diff files
        required: True
        type: str
    yml_cfg_section_merge_mode:
        description: merge part of pg se only, without patroni part (by default False)
        required: False
        type: bool
    log_file:
        description: log file (by default "./")
        required: False
        type: str
    pghba_mode:
        description: merge pg_hba part of config files (command "merge") or use pg_phba part of new config file (command "new") \
                     or get pg_hba string by pghba_users params (command "get") or replace pghba string with pghba_users params (command "replace") (by default "merge")
        required: False
        type: str
    pghba_users:
        description: get_pg_hba/replace_pg_hba pghba string with these users only (by default "")
        required: False
        type: str
    custom_cfg_name:
        description: yaml file with db_admin users (by default "custom_dev.yml")
        required: False
        type: str

author:
    - Roman Aminov
'''

EXAMPLES = r'''

'''

RETURN = r'''
'''

import sys

sys.path.append("/home/postgres/installer_cache_dir")

from ansible.module_utils.basic import AnsibleModule
from config_auto_merge import postgres_yml as pgyml
from config_auto_merge import postgres_conf as pgconf
from config_auto_merge import pg_hba_conf as pghbaconf
import argparse
from ruamel.yaml.comments import CommentedSeq as cmtseq
from ruamel.yaml import YAML
import re

result = dict(
    changed = False,
    original_message = '',
    message = ''
)

def run_module():
    module_args = dict(
        old_cfg_file = dict(type = 'str', required = True),
        new_cfg_file = dict(type = 'str', required = True),
        result_cfg_file = dict(type = 'str', required = True),
        root_path = dict(type = 'str', required = False, default = ""),
        yml_cfg_section_merge_mode = dict(type = 'str', required = False, default = "all"),
        log_file = dict(type = 'str', required = False, default = "./"),
        pghba_mode = dict(type = 'str', required = False, default = "merge"),
        pghba_users = dict(type = 'str', required = False, default = ""),
        custom_cfg_name = dict(type = 'str', required = True)
    )

    module = AnsibleModule(argument_spec = module_args,
                           supports_check_mode = True)

    old_cfg_file = module.params['old_cfg_file']
    new_cfg_file = module.params['new_cfg_file']
    result_cfg_file = module.params['result_cfg_file']
    root_path = module.params['root_path']
    yml_cfg_section_merge_mode = module.params['yml_cfg_section_merge_mode']
    log_file = module.params['log_file']
    pghba_mode = module.params['pghba_mode']
    pghba_users = module.params['pghba_users']
    custom_cfg_name = module.params['custom_cfg_name']

    run_status, msg = run_automerge(old_cfg_file, new_cfg_file, result_cfg_file, root_path,
                                    yml_cfg_section_merge_mode, log_file, pghba_mode, pghba_users, custom_cfg_name)

    result['message'] = run_status
    result['original_message'] = msg

    module.exit_json(**result)

def run_automerge(old_conf_file, new_conf_file, result_file, root_path,
                  yml_cfg_section_merge_mode, log_file, pghba_mode, pghba_users, custom_cfg_name):
    """
    Ф-я выполняет 3 основных действия:
    1. мерж двух конфигурационных файлов pg_hba.conf/postgresql.conf/postgres.yml (pghba_mode==merge or new)
    2. получение списка pg_hba строк, в которых есть кто-либо из pghba_users (pghba_mode==get_pg_hba)
    3. замена строк pg_hba, в которых есть кто-либо из pghba_users в файле old_conf_file, на строки из  new_conf_file (pghba_mode==replace_pg_hba)

    old_conf_file - пусть до postgres.yml/postgresql.conf/pg_hba.conf файла для old_ver
    new_conf_file - пусть до postgres.yml/postgresql.conf/pg_hba.conf файла для new_ver
    result_file - пусть до postgres.yml файла, полученного в ходе мержа
    root_path - путь до корневой папки с diff_cfg.txt, с копией all.yml, где также будет создан diff_bootstrap_dcs.txt
    yml_cfg_section_merge_mode - перечисление корневых разделов yml, которые будут мержится
    log_file - путь до amerge.log файла, лог файла работы скрипта авто мержа
    pghba_mode - режим мержа pg_hba части: megre - слияние pg_hba из старого и нового конфига, 
                 new - pg_hba из старого конфига полностью заменятся на pg_hba из нового конфига,
                 get_pg_hba - получение списка pg_hba строк, в которых есть кто-либо из pghba_users,
                 replace_pg_hba - замена строк pg_hba, в которых есть кто-либо из pghba_users в файле old_conf_file, на строки из  new_conf_file
    custom_cfg_name - yml файл с db_admin пользователями
    """
    if pghba_mode == "get_pg_hba" or pghba_mode == "replace_pg_hba":
        if 'pg_hba.conf' not in old_conf_file and 'postgres.yml' not in old_conf_file:
            return(1, "ERROR: incorrect input files")
        if 'postgres.yml' in old_conf_file:
            new_yml = """
                postgresql:
                    pg_hba:
                            []
            """
            new_yml = YAML().load(new_yml)        
            new_yml['postgresql']['pg_hba'] = cmtseq(new_conf_file.split(":::"))
            return pgyml.get_or_replace_pghba(old_conf_file, new_yml, result_file, pghba_mode, pghba_users)
        elif 'pg_hba.conf' in old_conf_file:
            new_yml = cmtseq(new_conf_file.split(":::"))
            return pghbaconf.get_or_replace_pghba(old_conf_file, new_yml, result_file, pghba_mode, pghba_users)
    elif 'postgres.yml' in old_conf_file and 'postgres.yml' in new_conf_file:
        pgyml.merge(old_conf_file, new_conf_file, result_file, root_path, pghba_mode, custom_cfg_name, yml_cfg_section_merge_mode)
    elif 'postgresql.conf' in old_conf_file and 'postgresql.conf' in new_conf_file:
        pgconf.merge_postgres_conf(old_conf_file, new_conf_file, result_file, root_path)
    elif 'pg_hba.conf' in old_conf_file and 'pg_hba.conf' in new_conf_file:
        pghbaconf.merge_pghba_conf(old_conf_file, new_conf_file, result_file, root_path, custom_cfg_name, pghba_mode)
    else:
        return(1, "ERROR: incorrect input files")

    return(0, "SUCCESS")

def main():
    run_module() 

if __name__ == "__main__":
    parser = argparse.ArgumentParser(description='auto merge configs: postgres.yml, postgresql.conf or pg_hba.conf')
    parser.add_argument('--old_cfg_file',    dest="old_cfg_file",
                        action="store", type=str, required=True, help='old config path')
    parser.add_argument('--new_cfg_file',    dest="new_cfg_file",
                        action="store", type=str, required=True, help='new config path')
    parser.add_argument('--result_cfg_file', dest="result_cfg_file",
                        action="store", type=str, required=True, help='result config path')
    parser.add_argument('--root_path',   dest="root_path",
                        action="store", type=str, required=True, help='path to the directory with diff files')
    parser.add_argument('--yml_cfg_section_merge_mode',       dest="yml_cfg_section_merge_mode",
                        action="store", default="all", type=str, required=False, help='merge part of pg se only, without patroni part')
    parser.add_argument('--log_file', dest="log_file",
                        action="store", default="./", type=str, required=False,
                        help='log file')
    parser.add_argument('--pghba_mode', dest="pghba_mode",
                        action="store", default="merge", type=str, required=False,
                        help='merge pg_hba part of config files (command "merge") or use pg_phba part of new config file (command "new") \
                            or get pg_hba string by pghba_users params (command "get") or replace pghba string with pghba_users params (command "replace")')
    parser.add_argument('--pghba_users', dest="pghba_users",
                        action="store", default="", type=str, required=False,
                        help='get_pg_hba/replace_pg_hba pghba string with these users only')
    parser.add_argument('--custom_cfg_name', dest="custom_cfg_name",
                        action="store", default="custom_dev.yml", type=str, required=False,
                        help='yaml file with db_admin users')
    main()
    args = parser.parse_args()
    yml_cfg_section_merge_mode = re.sub(r"[\ ]", "", args.yml_cfg_section_merge_mode)
    yml_cfg_section_merge_mode = yml_cfg_section_merge_mode.split(',')

    run_automerge(args.old_cfg_file, args.new_cfg_file, args.result_cfg_file, args.root_path,
                  yml_cfg_section_merge_mode, args.log_file, args.pghba_mode, args.pghba_users,args.custom_cfg_name)
    
