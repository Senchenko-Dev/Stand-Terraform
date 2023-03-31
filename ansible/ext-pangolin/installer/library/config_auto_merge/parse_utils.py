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

def clean_old_commits(commits):
    return
    res = commits.split(CommentList.new_val.value)
    if len(res):
        res = res.pop(0)
        res = " ".join(res)
        res = res.split(CommentList.prev_val.value)
    else:
        res = commits.split(CommentList.prev_val.value)

    if len(res):
        res = res.pop(0)
        res = " ".join(res)
        res_2 = res[-1].split(CommentList.old_cmnt.value)
    
    if not len(res) and not len(res_2):
        return
    if len(res_2):
        res[-1] = res_2[-1]
    num_ch_1 = 0
    num_ch_2 = 0
    idx = -1
    res = res[-1] 
    for i, ch in enumerate(res):
        if (num_ch_1 + num_ch_2) % 2 == 0 and (num_ch_1 != 0 or num_ch_2 != 0):
            idx = i
            break
        if ch == '\'':
            num_ch_1 += 1
        if ch == '\"':
            num_ch_2 += 1

def pg_hba_split(elem):
    """
    input: elem - строка pg_hba
    output: words - массив вида ['host', 'all', 'postgres', '0.0.0.0/0', 'ldap ...']
    """
    word_sum = ''
    words = []
    if CommentList.cmnt_only.value in elem:  #чистые коментарии пропускаем
        return words
    for word in elem.split(' '): 
        if len(word) == 0:
            continue
        if len(words) > 4:
            words[-1] += ' ' + word
        elif word[-1] == ',': # запятная как разделитель не должна учитываться в параметрах подключения
            word_sum += ' ' + word
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
        if "-pam-" in old_users and ("-pam-" in new_users or new_users == "all_pam"):
            return (True, True)
        if  "-pam-" not in old_users and ("-pam-" not in new_users or new_users == "all_no_pam"):
            return (True, False)
        
        return (False, None)
    else:
        return (None, None)

def check_equal_pghba_string_condition(curr_line, next_line, work_mode, user_list=[], support_db_admin_user_list=""):
    """
    dublicate - удалить дубликаты, True - если дубликаты были найдены
    merge - слияние двух строк, True - если строки удовлетворяют условиям слияние
    clean - удаление пользователей из заданной строки, либо самой строки, True - удаление будет произведено
    
    curr_line - целевая строка pg_hba
    next_line - строка pg_hba, которая подлежит проверке
    work_mode - dublicate(убрать дубилкаты)/merge(слияние двух строк)/clean(удалить заданные строки)
    user_list - список пользователей из curr_line и next_line
    support_db_admin_user_list - список db_admin пользователей из all.yml (sigma или alpha)
    
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
        if (work_mode == "dublicate" or work_mode == "clean"):
            is_same_type_ldap, is_pam = check_ldap_equal(curr_line[4], next_line[4], curr_line[2], next_line[2])
            if (curr_line[4] == next_line[4]) or is_same_type_ldap:
                return (True, is_pam )
        elif work_mode == "merge":
            is_ldap, actual_conn_params = merge_pghba_ldap_string(user_list, curr_line, next_line, support_db_admin_user_list)
            if is_ldap or curr_line[4] == next_line[4]:
                curr_line[4] = actual_conn_params
                return (True, None )
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
    
def remove_duplicate_pghba(pghba_list):
    """
    удаление дубликатов строк
    также в случае если тип подключения, имя БД, параметры подключения и ip совпадают,но разные пользователи, то строки объединянются в одну
    pghba_list - pg_hba список
    return True, если дубликаты были
    """
    remove_idx = []
    for main_idx, main_line in enumerate(pghba_list):
        curr_line = pg_hba_split(main_line)
        for idx in range(main_idx + 1, len(pghba_list)):
            next_line = pg_hba_split(pghba_list[idx])
            if len(next_line) == 0 or len(curr_line) == 0:
                continue
            
            is_merge, is_pam = check_equal_pghba_string_condition(curr_line = curr_line, 
                                                                 next_line = next_line,
                                                                 work_mode = "dublicate")
                
            if not is_merge:
                continue
            
            curr_line[2] = re.sub(r"[\ ]", "", curr_line[2])
            next_line[2] = re.sub(r"[\ ]", "", next_line[2])

            main_subsplit = curr_line[2].split(',')
            next_subsplit = next_line[2].split(',')
            main_subsplit = list(set(next_subsplit + main_subsplit))
            
            curr_line[2] = ', '.join(main_subsplit)
            pghba_list[main_idx] = ' '.join(curr_line)

            remove_idx.insert(0, idx)

    remove_idx = list(set(remove_idx))
    remove_idx = sorted(remove_idx, reverse=True)
    for idx in remove_idx:
        del pghba_list[idx]

    if len(remove_idx) == 0:
        return False
    
    return True

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
    #если в результирующей строке pg_pathman не последний, то перезаписываем его
    if res[-1] != 'pg_pathman':
        res.remove('pg_pathman')
        res.append('pg_pathman')
    res = ','.join(res)
    return res

def sort_pghba(pghba_list):
    """
    сортировка pghba списка в такой последовательности:
    local->hostssl->host
    """
    if len(pghba_list) == 0:
        return

    pghba_parts = [[], [], [],[],[],[]] #local->hostssl->host_pam_ldap->host_md5(только ТУЗы)->host_no_pam_ldap
    for i, x in enumerate(pghba_list):
        tmp_name = x.split(' ')
        if len(tmp_name) == 0:
            continue
        if tmp_name[0] == PghbaConnTypes.local.value:
            pghba_parts[0].append(x)
        elif tmp_name[0] == PghbaConnTypes.hostssl.value:
            pghba_parts[1].append(x)
        elif tmp_name[0] == PghbaConnTypes.host.value:
            if "-pam-" in x: # учетки с PAM должны быть в приоритете
                pghba_parts[2].append(x)
            elif "md5" in x and "0.0.0.0/0" in x: # только TUZы 
                pghba_parts[3].append(x)
            else:
                pghba_parts[4].append(x)
    pghba_list.clear()
    for x in pghba_parts:
        pghba_list.extend(x)

    return

def load_support_dm_admins_list(root_path, custom_cfg_name, is_alpha):
    """
    загрузить support_sigma/support_alpha список зарегистрированных db_admins пользователей
    root_path - путь до корневой папки, в которой находится копия all.yml
    is_alpha = true => support_alpha, и наоборот.
    """
    all_yml_file = root_path + '/' + custom_cfg_name
    with open(all_yml_file, 'r') as fp:
        for all_yml_file in ruamel.yaml.round_trip_load_all(stream=fp):
            pass
    if is_alpha and all_yml_file.get('support_alpha') != None:
        return all_yml_file.get('support_alpha')
    elif not is_alpha and all_yml_file.get('support_sigma') != None:
        return all_yml_file.get('support_sigma')
    else:
        return ""
    
def merge_pghba_ldap_string(user_list, curr_pghba, new_pghba, support_db_admin_user_list):
    """
    если тип подключения, БД для подключения и ip в строке из старого и из нового файлов совпадают, а также в обоих случаях подключение происходит
    с помощью ldap, то перед тем как мержить строки необходимо произвести проверку, на предмет входят ли пользователи в этих строках в групповую 
    роль db_admin. Т.е. если в списке support_sigma/support_alpha есть указанный пользователь (из строки pg_hba), то в результирующую строку мержа, 
    его не нужно добавлять (в том случае если в строке уже есть групповая роль db_admin, если нет, то ее нужно ввести). В противном случае его 
    необходимо добавить;
    настройки ldap всегда обновляются (берутся новые значения); причем учитывается, что существует разделение на ldap настройки для PAM 
    (в имени всегда присутствует "pam") и для обычной доменной авторизации;
    user_list - смерженный список пользователей (старых с новыми)
    old_users - список старых пользователей
    new_users - список новых пользователей
    old_conn_params - параметры соединения из старого файла
    new_conn_params - параметры соединения из нового файла
    support_db_admin_user_list - список db_admin пользователей из all.yml (sigma или alpha)
    """
    
    old_users = curr_pghba[2]
    new_users = new_pghba[2]
    old_conn_params = curr_pghba[4]
    new_conn_params = new_pghba[4]
    
    if old_conn_params.find(PghbaConnParams.ldap.value) != -1 and new_conn_params.find(PghbaConnParams.ldap.value) != -1:                            
        if "-pam-" in old_users and "-pam-" in new_users:
            old_conn_params = new_conn_params
        elif "-pam-" not in old_users and "-pam-" not in new_users:
            old_conn_params = new_conn_params
        else:
            return (False, old_conn_params)

        removed_users = []
        for user in user_list:
            if support_db_admin_user_list.find(user) != -1:
                removed_users.append(user)
                
        for ruser in removed_users:
            user_list.remove(ruser)
            
        if len(removed_users) > 0 and "+db_admin" not in user_list:
            user_list.insert(0, "+db_admin")
            
        return (True, old_conn_params)
    else:    
        return (False, old_conn_params)

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
    
def merge_list_elements(old_list, new_elem, is_pghba, support_db_admin_user_list):
    """
    слияние списков
    old_list - список, целевой
    new_elem - новый элемент, который необходимо вставить в список (если до этого его не было)
    is_pghba - ключ, True - список представляет собой pg_hba структуру, False - не pg_hba
    support_db_admin_user_list - список db_admin пользователей из all.yml (sigma или alpha)
    """
    if new_elem in old_list:  #если строки одинаковы, то пропускаем
        return False
    elif type(new_elem) == str and is_pghba:  #pg_hba слияние
        new_elem_split = pg_hba_split(new_elem) #парсинг строки pghba из нового файла
        if len(new_elem_split) == 0:
            return False
                
        for idx, old_elem in enumerate(old_list):
            old_elem_split = pg_hba_split(old_elem) #парсинг строки pghba из старого файла
            if len(old_elem_split) == 0:
                continue

            # 2 - пользователи  
            new_elem_split[2] = re.sub(r"['\ ]", "", new_elem_split[2])
            old_elem_split[2] = re.sub(r"['\ ]", "", old_elem_split[2])
            user_list = list(set(new_elem_split[2].split(',') + old_elem_split[2].split(',')))
            
            is_merge, is_pam = check_equal_pghba_string_condition(curr_line = old_elem_split, 
                                                                next_line = new_elem_split, 
                                                                work_mode = "merge",
                                                                user_list = user_list, 
                                                                support_db_admin_user_list = support_db_admin_user_list)
            if not is_merge: 
                continue
            
            if is_merge:
                user_list = sorted(user_list, reverse=True) # групповые роли должны быть в конце списка пользователей
                old_elem_split[2] = ', '.join(user_list)
                old_elem = ' '.join(old_elem_split)
                old_list[idx] = old_elem
                return True
        else:
            old_list.append(' '.join(new_elem_split))
            return True
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

def read_diff_file(old_ver, new_ver, diff_file_name):
    """
    old_ver - версия, с которой происходит обновление
    new_ver - версия на которую будем обновляться
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
            res_line = line.split(DiffCommands.separator.value)[0]
            if not len(removed) or removed[idx_removed][0] != res_line:
                idx_removed += 1
                removed.append([0, []])
            removed[idx_removed][0] = res_line
        elif re.search(r'\b{}\b'.format(DiffCommands.add.value), line):
            is_removed = False
            res_line = line.split(DiffCommands.separator.value)[0]
            if not len(added) or added[idx_added][0] != res_line:
                idx_added += 1
                added.append([0, []])
            added[idx_added][0] = res_line
        elif re.search(r'\b{}|{}|{}\b'.format(DiffTypes.list.value, DiffTypes.dict.value, DiffTypes.pghba.value), line):
            if is_removed:
                removed[idx_removed][1].append(line)
            else:
                added[idx_added][1].append(line)
        else:
            continue

    # необходимо получить общий, не зависящий от версий, контейнер с данными
    # то есть, как пример, если параметр должен быть удален в новой версии, но 
    # был добавлен в промежуточной, его не следует добавлять в результирующий файл
    merge_diff_file(old_ver, new_ver, added, removed)
    merge_diff_file(old_ver, new_ver, removed, added)


    result_removed = set()
    for x in removed:
        result_removed |= set(x[1])
    result_added = set()
    for x in added:
        result_added |= set(x[1])

    removed.clear()
    added.clear()

    result_removed = list(result_removed)
    for i, x in enumerate(result_removed):
        tpv = x.split(DiffCommands.separator.value)
        if tpv[0] != DiffTypes.pghba.value:
            if len(tpv) == 2:
                result_removed[i] = [tpv[0], tpv[1]]
            elif len(tpv) == 3:
                result_removed[i] = [tpv[0], tpv[1], tpv[2]]

    result_added = list(result_added)
    for i, x in enumerate(result_added):
        tpv = x.split(DiffCommands.separator.value)
        if tpv[0] != DiffTypes.pghba.value:
            if len(tpv) == 2:
                result_added[i] = [tpv[0], tpv[1]]
            elif len(tpv) == 3:
                result_added[i] = [tpv[0], tpv[1], tpv[2]]
   
    return result_removed, result_added

def merge_diff_file(old_ver, new_ver, cleared, priority):
    """
    old_ver - версия старой версии PG SE postgres.yml файла, например, 4.2.5
    new_ver - версия новой версии PG SE postgres.yml файла, например, 4.3.0
    """
    for r_ver in cleared:
        is_less_old = compare_versions(r_ver[0], old_ver)  # is less
        is_more_new = compare_versions(r_ver[0], new_ver)  # is more
        if is_less_old == 0 or is_more_new == 1:
            continue
        for a_ver in priority:
            is_less_old = compare_versions(a_ver[0], old_ver)  # is less
            is_more_new = compare_versions(a_ver[0], new_ver)  # is more
            if is_less_old == 0 or is_more_new == 1:
                continue
            idxs = []
            is_less = compare_versions(r_ver[0], a_ver[0])
            if is_less != 0:
                continue
            for i, r in enumerate(r_ver[1]):
                if r in a_ver[1]:
                    if i not in idxs:
                        idxs.insert(0, i)
            for i in idxs:
                r_ver[1].pop(i)
    return