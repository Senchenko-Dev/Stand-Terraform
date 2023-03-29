import ruamel.yaml
from ruamel.yaml.scalarstring import SingleQuotedScalarString as sqss
from ruamel.yaml.comments import CommentedSeq as cmtseq
from ruamel.yaml.comments import CommentedMap as cmtmap
import re
import json
import os
from enum import Enum as enum

class CommentList(enum):
    new_val="new value:"
    prev_val="prev value:"
    old_cmnt="old comment:"
    cmnt_only="comment_only:"
    
class DiffCommands(enum):
    add="force added"
    rm="removed"
    separator=":::"
    
class DiffTypes(enum):
    list="list"
    dict="dict"
    pghba="pghba"
    
class PghbaConnParams(enum):
    ldap="ldap"
    cert="cert"
    md5="md5"

class PghbaConnTypes(enum):
    local="local"
    hostssl="hostssl"
    hostnossl="hostnossl"
    host="host"
    
class PghbaStrTypes(enum):
    local=4
    with_ip_mask_only=5
    with_ip_adress=6
    

def create_path(path, data, val):
    """
    path - путь (ввиде списка, где последний элемент конечный ключ), по которому необходимо разместить значение val
    data - данные в виде словаря
    val - значение, которое необходимо вставить по указанному пути path
    """
    if len(path) == 0:
        return data
    sub_data = data.get(path[0])
    if sub_data is None:
        data[path[0]] = {}
    new_path = path[1:]
    if len(new_path) == 0:
        data[path[0]] = val
        return data
    return create_path(new_path, data[path[0]], val)

def write_etcd_cfg_diff(diff_bootstrap_file, attr_path, val):
    """
    добавляет в файл diff_bootstrap_file json строки
    строки добавляются только для тех элементов из diff_bootstrap_file, значения которых отличаются в старом и результирующем файлах
    diff_bootstrap_file - путь до файла
    attr_path - путь до ключа
    val - значение ключа, который нужно сохранить в diff_bootstrap_file
    """
    result_json = {}
    attr_path = re.sub(r"^bootstrap.dcs.", "", attr_path)
    paths = attr_path.split('.')
    create_path(paths, result_json, val)

    if os.path.isfile(diff_bootstrap_file) and os.path.getsize(diff_bootstrap_file) > 0:
        with open(diff_bootstrap_file, 'a') as outfile:
            outfile.write("\n")
            json.dump(result_json, outfile)
    else:
        with open(diff_bootstrap_file, 'w') as outfile:
            json.dump(result_json, outfile)

    return 0

def compare_versions(first, second, idx=0):
    """
    сравнение версий PostgreSQL SE only
    если first меньше second, то функция вернет 0
    если first равно second, то функция вернет 2
    если first больше second, то функция вернет 1
    first, second представимы, например, как 4.3.0
    """
    if idx == 0:
        first = first.split('.')
        second = second.split('.')
    if int(first[idx]) < int(second[idx]):
        return 0
    elif int(first[idx]) > int(second[idx]):
        return 1
    else:
        idx += 1
        if idx < len(first):
            return compare_versions(first, second, idx)
        return 2  # is equal

def pg_hba_split(elem):
    """
    input: elem - строка pg_hba
    output: words - массив вида ['host', 'all', 'postgres', '0.0.0.0/0', 'ldap ...']
    """
    word_sum = ''
    words = []
    if CommentList.cmnt_only.value in elem:  #чистые коментарии пропускаем
        return words
    words_splitted = elem.split(' ')
    for idx, word in enumerate(words_splitted): 
        if len(word) == 0:
            continue
        if len(words) > 4:
            words[-1] += ' ' + word
            continue
        elif len(word) > 1 and word[-1] == ',': 
            # запятная как разделитель не должна учитываться в параметрах подключения
            if idx == 2:
                word_sum += word
            else:
                word_sum += ' ' + word
        elif  len(word) > 0 and word != ',' and idx < len(words_splitted)-1 and words_splitted[idx + 1] == ',':
            # запятная как разделитель не должна учитываться в параметрах подключения
            word_sum += ' ' + word + ','
        elif word == ',':
            continue
        else:
            if len(word_sum) > 0:
                words.append(word_sum + ' ' + word)
            else:
                words.append(word)
            word_sum = ''
            
    return words

def clean_data(result_removed, cleared_list, attr_path, is_pghba):
    """
    удаление заданных в result_removed элементов из списка(!) cleared_list
    """
    idx_removed = set()
    for idx, elem in enumerate(cleared_list):

        if type(elem) == type(cmtmap()): # если пара ключ-значение
            for r in result_removed:
                if r[0] == DiffTypes.dict.value and attr_path == r[1] and list(iter(elem))[0] == r[2]:
                    idx_removed.add(idx)
        elif is_pghba: # если строка из pg_hba
            splt_old = pg_hba_split(elem)
            for r in result_removed:
                if len(splt_old) == 0:
                    break
                if DiffTypes.pghba.value not in r:
                    continue
                splt_removed = pg_hba_split(r.split(DiffCommands.separator.value)[1])
                if len(splt_removed) == 0:
                    continue
                is_equqly, is_pam = check_equal_pghba_string_condition(curr_line = splt_old, 
                                                                    next_line = splt_removed, 
                                                                    work_mode = "clean")
                if not is_equqly:
                    continue
                
                splt_old[2] = re.sub(r"['\ ]", "", splt_old[2])
                old_users = splt_old[2].split(",")
                
                splt_removed[2] = re.sub(r"['\ ]", "", splt_removed[2])
                rm_users = splt_removed[2].split(",")
                
                for rm_user in rm_users:
                    if rm_user in old_users:
                        old_users.remove(rm_user)
                        
                if len(old_users) == 0 or (splt_removed[2] == "all_no_pam" and is_pam == False): # если в diff_cfg был "all_no_pam", либо все пользователи из строки удалены, то и строка не нужна ( для PAM)
                    idx_removed.add(idx)
                elif len(old_users) == 0 or (splt_removed[2] == "all_pam" and is_pam == True): # если в diff_cfg был "all_pam", либо все пользователи из строки удалены, то и строка не нужна ( без PAM)
                    idx_removed.add(idx)
                elif len(old_users) == 0 or (splt_removed[2] == "all_no_pam" and is_pam == None): # если в diff_cfg был "all_no_pam", либо все пользователи из строки удалены, то и строка не нужна ( без PAM)
                    idx_removed.add(idx)
                else:
                    splt_old[2] = ','.join(old_users)
                    
                if len(old_users) > 0 and "all" not in splt_removed[2]:
                    cleared_list[idx] = " ".join(splt_old)
                
        elif type(elem) == str: # если обычная строка
            for r in result_removed:
                if r[0] == DiffTypes.list.value and attr_path == r[1] and elem == r[2]:
                    idx_removed.add(idx)

    idx_removed = sorted(idx_removed, reverse=True)
    for x in idx_removed:
        cleared_list.pop(x)

    return

def check_ldap_equal(old_conn_params, new_conn_params, old_users, new_users):
    """
    input:
    old_users - список старых пользователей
    new_users - список новых пользователей
    old_conn_params - параметры соединения из старого файла
    new_conn_params - параметры соединения из нового файла
    output:
    - первый элемент True => один тип ldap
    - второй элемент True => ldap для учеток с PAM
    """
    if old_conn_params.find(PghbaConnParams.ldap.value) != -1 and new_conn_params.find(PghbaConnParams.ldap.value) != -1:
        if "-pam-" in old_users.lower() and ("-pam-" in new_users.lower() or new_users.lower() == "all_pam"):
            return (True, True)
        if  "-pam-" not in old_users.lower() and ("-pam-" not in new_users.lower() or new_users.lower() == "all_no_pam"):
            return (True, False)
        
        return (False, None)
    else:
        return (None, None)

def check_equal_pghba_string_condition(curr_line, next_line, work_mode, user_list=[]):
    """
    clean - удаление пользователей из заданной строки, либо самой строки, True - удаление будет произведено
    
    curr_line - целевая строка pg_hba
    next_line - строка pg_hba, которая подлежит проверке
    work_mode - clean(удалить заданные строки)
    
    output:
    - первый элемент True - строки равны
    - второй элемент True - PAM ( толкьо для ldap и необходимо только при work_mode == "dublicate" or work_mode == "clean"); в остальных
      случаях None
    """
    if len(next_line) == PghbaStrTypes.with_ip_mask_only.value \
            and len(curr_line) == PghbaStrTypes.with_ip_mask_only.value \
            and curr_line[3] == next_line[3] \
            and curr_line[1] == next_line[1] \
            and curr_line[0] == next_line[0]:
        # 0 - тип подключения, 1 - имя БД, 2 - пользователи, 3 - маска подсети, 4 - параметры подключения
        if (work_mode == "clean"):
            is_same_type_ldap, is_pam = check_ldap_equal(curr_line[4], next_line[4], curr_line[2], next_line[2])
            if (curr_line[4] == next_line[4]) or is_same_type_ldap:
                return (True, is_pam )
    elif len(next_line) == PghbaStrTypes.local.value \
            and len(curr_line) == PghbaStrTypes.local.value \
            and curr_line[3] == next_line[3] \
            and curr_line[1] == next_line[1] \
            and curr_line[0] == next_line[0]:
        # 0 - тип подключения, 1 - имя БД, 2 - пользователи, 3 - параметры подключения
        return (True, None )
    elif len(curr_line) == PghbaStrTypes.with_ip_adress.value \
            and len(next_line) == PghbaStrTypes.with_ip_adress.value:
        pass # добавить при необходимости
    
    return (False, None )

def merge_shared_preload_libraries(old_str, new_str):
    """
    старые записи, за исключением 'pgaudit'
    не удаляются; из двух строк old_str и new_str формируется одна
    """
    old_str = re.sub(r"['\ ]", "", old_str)
    new_str = re.sub(r"['\ ]", "", new_str)
    if len(old_str) == 0:
        return new_str
    old_elems = old_str.split(',')
    new_elems = new_str.split(',')

    if 'pgaudit' in old_elems:
        old_elems.remove('pgaudit')

    res = list(set(old_elems + new_elems))

    if 'pg_stat_kcache' in res:
        res.remove('pg_stat_kcache')
    res.remove('pg_hint_plan')
    res.remove('pg_outline')
    res.remove('pg_pathman')

    if 'pg_stat_kcache' in new_elems:
        res.append('pg_stat_kcache')
    res.append('pg_hint_plan')
    res.append('pg_outline')
    res.append('pg_pathman')

    res = ','.join(res)
    return res

def load_control_info_from_custom_dev(root_path, custom_cfg_name):
    """
    карту замен для методов аутентификации в pghba
    root_path - путь до корневой папки, в которой находится копия all.yml

    auth_methods_control_map - карта замены одного параметра (ключ) аутентификации другим (значение)
    is_update_ldap_auth_methods - заменять или нет настройки ldap в старом конфиге
    """
    auth_methods_control_map = {}

    all_yml_file = root_path + '/' + custom_cfg_name
    with open(all_yml_file, 'r') as fp:
        for all_yml_file in ruamel.yaml.round_trip_load_all(stream=fp):
            pass

    is_update_ldap_auth_methods = all_yml_file.get('is_update_ldap_auth_methods')
    if is_update_ldap_auth_methods == None \
       or not bool(is_update_ldap_auth_methods) \
       or str(is_update_ldap_auth_methods) in ['off', 'false', 'False', 'no']:
       is_update_ldap_auth_methods = False
    else:
       is_update_ldap_auth_methods = True

    if all_yml_file.get('auth_methods_control_map') != None:
        auth_methods_control_map = all_yml_file.get('auth_methods_control_map')
        if ruamel.yaml.comments.CommentedMap != type(auth_methods_control_map) \
            or len(auth_methods_control_map) <= 0:
            auth_methods_control_map = {}

    return (auth_methods_control_map, is_update_ldap_auth_methods)

def pop_pg_hba(old_list, pghba_users):
    """
    получение из pghba строк с указанными пользователями
    old_list - pghba список
    pghba_users - список пользователей, строки с которыми нужно получить
    """
    result_pghba_str = ""
    pghba_users = re.sub(r"['\ ]", "", pghba_users)
    pghba_users = pghba_users.split(',')
    pghba_users_len = len(pghba_users)

    remove_elems = []

    for idx, old_elem in enumerate(old_list):
        old_list[idx] = old_elem.expandtabs()
        old_elem = old_list[idx]
        old_elem_split = pg_hba_split(old_elem) #парсинг строки pghba
        if len(old_elem_split) == 0:
            continue

        # 2 - пользователи  
        old_elem_split[2] = re.sub(r"['\ ]", "", old_elem_split[2])
        old_elem_len = len(old_elem_split[2].split(','))
        big_len = len(set(pghba_users + old_elem_split[2].split(',')))
        if (big_len < (pghba_users_len + old_elem_len)) or pghba_users_len == 0:
            tmp = ""
            for i, x in enumerate(old_elem_split):
                if len(old_elem_split) > 4 and (i == 3): # для ip/mask
                    x = x.replace('/','|')
                tmp += x
                tmp += "|"
            result_pghba_str += tmp
            remove_elems.insert(0,idx)

    for rmelem in remove_elems:
        del old_list[rmelem]
        
    if len(result_pghba_str) > 0 and result_pghba_str[-1] == '|':
        result_pghba_str = result_pghba_str[0:-1]

    return result_pghba_str
    
def merge_list_elements(old_list, new_elem, is_pghba):
    """
    слияние списков
    old_list - список, целевой
    new_elem - новый элемент, который необходимо вставить в список (если до этого его не было)
    """
    if new_elem in old_list:  #если строки одинаковы, то пропускаем
        return False
    elif type(new_elem) == str and is_pghba:  #pg_hba слияние
        return False
    elif type(new_elem) == str and not is_pghba:  #слияние строк в списке (кроме pg_hba)
        old_list.append(new_elem)
        return True
    elif isinstance(new_elem, cmtmap):  #слияние пар ключ-значение
        for old_elem in old_list:
            if isinstance(old_elem, cmtmap):
                a = [key for key in old_elem][0]
                b = [key for key in new_elem][0]
                if a == b and old_elem[a] != new_elem[b]:
                    val = old_elem[a]
                    if type(val) == str:
                        val = sqss(val)
                    new_comment = "{}{}".format(CommentList.new_val.value, new_elem[b])
                    old_elem.insert(1, a, val, comment=new_comment)
                    return True
        else:
            old_list.append(new_elem)
            return True
    return False

def read_diff_file(diff_file_name):
    """
    diff_file_name - путь (включая имя) до diff_cfg.txt
    """
    f = open(diff_file_name, 'r')
    removed = []
    added = []
    is_removed = False
    idx_removed = -1
    idx_added = -1
    # считываем файл
    for line in f:
        line = re.sub(r"[\n]", "", line)
        if re.search(r'\b{}\b'.format(DiffCommands.rm.value), line):
            is_removed = True
        elif re.search(r'\b{}\b'.format(DiffCommands.add.value), line):
            is_removed = False
        elif re.search(r'\b{}|{}|{}\b'.format(DiffTypes.list.value, DiffTypes.dict.value, DiffTypes.pghba.value), line):
            if is_removed:
                removed.append(line)
            else:
                added.append(line)
        else:
            continue

    result_removed = list(set(removed))
    for i, x in enumerate(result_removed):
        tpv = x.split(DiffCommands.separator.value)
        if tpv[0] != DiffTypes.pghba.value:
            if len(tpv) == 2:
                result_removed[i] = [tpv[0], tpv[1]]
            elif len(tpv) == 3:
                result_removed[i] = [tpv[0], tpv[1], tpv[2]]

    result_added = list(set(added))
    for i, x in enumerate(result_added):
        tpv = x.split(DiffCommands.separator.value)
        if tpv[0] != DiffTypes.pghba.value:
            if len(tpv) == 2:
                result_added[i] = [tpv[0], tpv[1]]
            elif len(tpv) == 3:
                result_added[i] = [tpv[0], tpv[1], tpv[2]]
   
    return result_removed, result_added

def merge_pghba(old_list, new_list, auth_methods_control_map, is_update_ldap_auth_methods):
    """
    old_list - исследуемый список из старого конфигурационного файла
    new_list - исследуемый список из нового конфигурационного файла
    auth_methods_control_map - карта замен настроек авторизации в pghba
    """
    for idx, old_elem in enumerate(old_list):
        old_elem = old_elem.replace('\t',' ')
        old_elem_split = pg_hba_split(old_elem) #парсинг строки pghba из old файла
        if len(old_elem_split) == 0:
            continue

        # update ldap
        if is_update_ldap_auth_methods:
            for new_elem in new_list:
                new_elem = new_elem.replace('\t',' ')
                new_elem_split = pg_hba_split(new_elem) #парсинг строки pghba из new файла
                if len(new_elem_split) == 0:
                    continue
                is_same_type_ldap, is_pam = check_ldap_equal(old_elem_split[-1], new_elem_split[-1], old_elem_split[2], new_elem_split[2])
                if is_same_type_ldap == True:
                    old_elem_split[-1] = new_elem_split[-1]
                    old_elem = ' '.join(old_elem_split)
                    old_list[idx] = old_elem
                    break

        # auth-methods
        auth_methods = old_elem_split[-1]
        for key in auth_methods_control_map:
            if key in auth_methods:
                old_elem_split[-1] = auth_methods.replace(key, auth_methods_control_map[key])
                old_elem = ' '.join(old_elem_split)
                old_list[idx] = old_elem

    new_list = remove_duplicate_lines(old_list, new_list)
    old_list.extend(new_list)

    return old_list

def remove_duplicate_lines(old_list, new_list):
    """
    Удаление дубликатов строк из списка нового конф файла pg_hba или в части hba файла postgres.yml, на сонове старого.
    old_list - список строк hba из старого конфига
    new_list - список строк hba из нового конфига
    В результате вернет new_list без дубликатов для нового конфига.
    """

    list_old, list_new, key_old, key_new = [], [], [], []
    dict_old, dict_new, dict_for_update, res_del = {}, {}, {}, {}

    short_line, result = [], []

    # Лист со строками хба из старого конфига без пустых элементов и комментариев
    for main_idx, main_line in enumerate(old_list):
        curr_line = pg_hba_split(main_line)
        if curr_line and len(curr_line) == 5:
            list_old.append(curr_line)

    # 'dict_old' - словарь старых строк хба, где 'key' - "'тип подключения' 'имя БД' 'string' 'маска подсети' 'параметры подключения'", 'value' - список пользователей с параметрами подключения 'key'
    for num, elem in enumerate(list_old):
        key_old.append(f"{elem[0]} {elem[1]} string {elem[3]} {elem[4]}")
        if key_old[num] not in dict_old:
            dict_old.update({key_old[num]: f"{elem[2]}, "})
        else:
            dict_old[key_old[num]] = (dict_old[key_old[num]] + elem[2] + ', ')

    # Лист со строками хба из нового конфига без пустых элементов и комментариев
    for main_idx, main_line in enumerate(new_list):
        curr_line = pg_hba_split(main_line)
        if curr_line and len(curr_line) == 5:
            list_new.append(curr_line)
        elif len(curr_line) == 4:
            short_line.append(curr_line)

    # 'short_line' - лист со строками хба размером '4' (например: 'local all all md5'). Сразу записываются в 'result'
    result = [' '.join(x) for x in short_line]

    # 'dict_new' - словарь новых строк хба, где 'key' - "'тип подключения' 'имя БД' 'string' 'маска подсети' 'параметры подключения'", 'value' - список пользователей с параметрами подключения 'key'
    for num, elem in enumerate(list_new):
        key_new.append(f"{elem[0]} {elem[1]} string {elem[3]} {elem[4]}")
        if key_new[num] not in dict_new:
            dict_new.update({key_new[num]: f"{elem[2]}, "})
        else:
            dict_new[key_new[num]] = (dict_new[key_new[num]] + elem[2] + ', ')

    # Цикл для сравнения пользователей старого и нового спика, если параметры подключения одинаковые. 'res_del' - словарь совпадений пользователей нового конфига с пользователями старого конфига
    # 'new_users_list' - приведение списка пользователей к одному виду, типа ['user1', 'user2', 'user3'], 'old_users_list' - приведение списка пользователей к одному виду, типа ['user1', 'user2', 'user3']
    for key_new, val_new in dict_new.items():
        new = val_new.split(', ')
        new_users_list = [x.strip(', ') for x in new]
        new_users_list = list(filter(None, new_users_list))
        dict_new.update({key_new: new_users_list})
        for key_old, val_old in dict_old.items():
            old = val_old.split(', ')
            old_users_list = [x.strip(', ') for x in old]
            old_users_list = list(filter(None, old_users_list))
            if key_new == key_old:
                for user in new_users_list:
                    if user in old_users_list:
                        if key_new not in res_del:
                            res_del.update({key_new: f"{user}, "})
                        else:
                            res_del[key_new] = (res_del[key_new] + user + ', ')

    dict_for_update = dict_new.copy()
    # Цикл для сравнения получившегося списка 'res_del' и первоночального списка 'dict_new' строк из нового конфига
    # 'dict_for_update' - словарь с 'key' -параметры подключения, 'value' - список пользователей. ['user1', 'user2'] - если совпадений не нашлось. '' - если совпали все пользователи
    for key, val in dict_for_update.items():
        for key_del, val_del in res_del.items():
            delete = val_del.split(', ')
            del_users_list = [x.strip(', ') for x in delete]
            del_users_list = list(filter(None, del_users_list))
            if key in key_del and set(val) == set(del_users_list):
                dict_for_update.update({key: ''})
            elif key in key_del and set(val) != set(del_users_list):
                update_list = list(set(val) - set(del_users_list))
                dict_for_update.update({key: update_list})

    # 'result' - результирующий список с подстановкой пользователей по ключу вместо слова 'string'.
    for key, val in dict_for_update.items():
        if val:
            line = key.replace('string', ', '.join(val))
            result.append(line)

    return result