from collections import OrderedDict as ordict
from config_auto_merge import parse_utils as pgutils
import re

def read_postgres_conf(conf_path):
    conf_file = open(conf_path, 'r')
    res_data = ordict()
    for line in conf_file:
        vals = ['', '', '']
        idx = 0
        is_new_words = False
        is_first_eq = True
        line = re.sub(r"[\n]", "", line)
        for symbl in line:
            if symbl == ' ' and len(vals[idx]) == 0:
                continue
            elif symbl == '#' and len(vals[0]) == 0:
                line = re.sub(r"[#]", "", line)
                res_data[pgutils.CommentList.cmnt_only.value+line] = ['', line]
                break
            elif symbl != ' ' and symbl != '#' and symbl != '\t':
                if symbl == '=' and is_first_eq:
                    is_first_eq = False
                    vals[idx] += ' ='
                    continue
                if is_new_words and idx == 1:
                    is_new_words = False
                    idx = 2
                elif is_new_words:
                    is_new_words = False
                    idx = 1
                vals[idx] += symbl
            elif symbl == ' ' or symbl == '#' or symbl == '\t':
                if idx == 0:
                    is_new_words = True
                elif idx == 1 and symbl == '#':
                    is_new_words = True
                elif symbl != '#' and symbl != '\n':
                    vals[idx] += symbl
        if vals[0] != '':
            vals[1] = re.sub("^\s+|\n|\r|\s+$", '', vals[1])
            vals[2] = re.sub("^\s+|\n|\r|\s+$", '', vals[2])
            res_data[vals[0]] = [vals[1], vals[2]]

    return res_data

def remove_unactual_fields(result_removed, old_data):
    for i, x in enumerate(result_removed):
        if x[0] == pgutils.DiffTypes.dict.value:
           for key in old_data:
               tmp = key
               tmp = re.sub(r"[=\ ]", "", tmp)
               if x[2] == tmp:
                    old_data.pop(key)
                    break
    return

def merge_postgres_conf(old_conf_file, new_conf_file, result_file, old_ver, new_ver, root_path):
    """
    old_conf_file - пусть до postgres.yml файла для old_ver
    new_conf_file - пусть до postgres.yml файла для new_ver
    result_file - пусть до postgrsql.conf файла, полученного в ходе мержа
    old_ver - версия старой версии PG SE postgres.yml файла, например, 4.2.5
    new_ver - версия новой версии PG SE postgres.yml файла, например, 4.3.0
    root_path - путь до папки с diff_cfg.txt, с копией all.yml, где также будет создан diff_bootstrap_dcs.txt
    """
    file_diff_name = root_path + "/diff_cfg.txt"

    old_config_dict = read_postgres_conf(old_conf_file)
    new_config_dict = read_postgres_conf(new_conf_file)

    result_removed, result_added = pgutils.read_diff_file(old_ver, new_ver, file_diff_name)
    remove_unactual_fields(result_removed, old_config_dict)

    remove_keys = []  #список пересекающихся в обоих конфигах строк
    for new_key, new_item in new_config_dict.items():
        for old_key, old_item in old_config_dict.items():
            old_key_tmp = old_key
            new_key_tmp = new_key
            old_key_tmp = re.sub(r"[=\ ]", "", old_key_tmp)
            new_key_tmp = re.sub(r"[=\ ]", "", new_key_tmp)
            if old_key_tmp == new_key_tmp and pgutils.CommentList.cmnt_only.value not in new_key_tmp:
                a = b = ''
                is_force = False
                for idx, v in enumerate(result_added):
                    if v[0] == pgutils.DiffTypes.dict.value:
                        is_force = bool(re.search(new_key_tmp, v[2]))
                    if is_force:
                        break
                if is_force and old_item[0] != new_item[0]:
                    a = "{}{}".format(pgutils.CommentList.prev_val.value, old_item[0])
                    old_item[0] = new_item[0]
                elif old_item[0] != new_item[0]:
                    a = "{}{}".format(pgutils.CommentList.new_val.value, new_item[0])
                
                if len(a) > 0 and len(old_item[1]) > 0:
                    b = ", "
                if len(old_item[1]) > 0:
                    b += pgutils.CommentList.old_cmnt.value + str(old_item[1])
                old_item[1] = a + b
                if 'shared_preload_libraries' in new_key:
                    shared_preload_libraries = pgutils.merge_shared_preload_libraries(old_item[0], new_item[0])
                    old_item[0] = '\'' + shared_preload_libraries + '\''
                remove_keys.append(new_key)
            elif old_key_tmp == new_key_tmp and pgutils.CommentList.cmnt_only.value in new_key_tmp:
                remove_keys.append(new_key)

    for k in remove_keys:
        new_config_dict.pop(k)

    #добавить новые строки из нового конфига
    for new_key, new_item in new_config_dict.items():
        old_config_dict[new_key] = new_item
        
    f = open(result_file, 'w')
    for key, item in old_config_dict.items():
        res_str = ''
        if pgutils.CommentList.cmnt_only.value not in key:
            res_str = str(key) + ' ' + str(item[0])
            if len(item[1]) > 0:
                res_str += '    #' + str(item[1])
        else:
            res_str = '#' + str(item[1])
        f.write(res_str + '\n')
