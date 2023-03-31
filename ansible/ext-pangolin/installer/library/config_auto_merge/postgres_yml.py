import ruamel.yaml
from ruamel.yaml.scalarstring import SingleQuotedScalarString as sqss
from ruamel.yaml.comments import CommentedSeq as cmtseq
from ruamel.yaml.comments import CommentedMap as cmtmap
from collections import OrderedDict as orddict
from config_auto_merge import parse_utils as pgutils
import re

def get_force_status(result_added, save_path, attr_name):
    """
    result_removed - список полей, которые необходимо удалить в old_yml_data, перед тем как мержить его с новым yml конфигурационным файлом
    attr_name - название поля в новом конфигурационном файле
    save_path - путь до секции в старом конфигурационном файле, содержащей attr_name
    """
    is_force = False
    for idx, v in enumerate(result_added): # если текущая пара: путь (в конфиге) и значение есть в result_added => новое значение перетрет старое
        if v[0] == pgutils.DiffTypes.dict.value:
            is_force = bool(re.search(save_path, v[1]))
            is_force = is_force and bool(re.search(attr_name, v[2]))

        if is_force:
            break
        
    return is_force
        
def merge_attribute(result_removed, result_added, old_yml_objects, sub_old_yml_objects, sub_new_yml_objects, attr_name, attr_path,
                    only_pgse, support_db_admin_user_list, pghba_mode, diff_bootstrap_file=""):
    """
    мерж либо добавление в случае отсутствия новых значений для пар ключ-значение
    result_removed - список полей, которые необходимо удалить в old_yml_data, перед тем как мержить его с новым yml конфигурационным файлом
    result_added - список полей, значения которых в old_yml_data должны быть обновлены значениями из нового yml конфигурационного файла
    old_yml_objects - загруженная секция с yml данными из старого конфигурационного файла
    sub_old_yml_objects - загруженная подсекция с yml данными из старого конфигурационного файла
    sub_new_yml_objects -  - загруженная подсекция с yml данными из нового конфигурационного файла
    attr_name - название поля в новом конфигурационном файле
    attr_path - путь до секции в старом конфигурационном файле, содержащей attr_name
    diff_bootstrap_file - данные из секции bootstrap
    only_pgse - если False, то в результирующем yml файле будут обработаны вспе корневые разделы, кроме restapi и etcd
    pghba_mode - режим мержа pg_hba части: megre - слияние pg_hba из старого и нового конфига, 
                 new - pg_hba из старого конфига полностью заменятся на pg_hba из нового конфига
    support_db_admin_user_list - список db_admin пользователей из all.yml (sigma или alpha)
    """
    if (sub_old_yml_objects is None) and (sub_new_yml_objects is None):
        return
    save_path = attr_path
    if attr_path == '':
        attr_path = attr_name
    else:
        attr_path = attr_path + '.' + attr_name

    if sub_old_yml_objects is None and old_yml_objects is not None:
        # контроль, чтобы поля из result_removed, в случае наличия их в новом конфиге, не попали в результирующий
        is_remove = False
        for idx, v in enumerate(result_removed):
            if v[0] == pgutils.DiffTypes.dict.value:
                is_remove = bool(re.search(save_path, v[1]))
                is_remove = is_remove and bool(re.search(attr_name, v[2]))
                # фича для etcd.host
                if v[1] == 'etcd' and v[2] == 'host':
                    is_remove = False
            if is_remove:
                return
        if only_pgse == True and ('restapi' in attr_path or 'etcd' in attr_path):
            pass
        else:
            old_yml_objects[attr_name] = sub_new_yml_objects
        return
    
    if isinstance(sub_new_yml_objects, cmtseq): # углубляемся дальше в yml, если имеем список
        merge_list(result_removed, result_added, sub_old_yml_objects, sub_new_yml_objects, attr_path, attr_name, support_db_admin_user_list, pghba_mode)
    elif isinstance(sub_new_yml_objects, cmtmap): # углубляемся дальше в yml, если имеем словарь
        merge_objects(result_removed, result_added, sub_old_yml_objects, sub_new_yml_objects, attr_path, diff_bootstrap_file, only_pgse, support_db_admin_user_list, pghba_mode)
    else: # мерж пары ключ:значение
        if sub_new_yml_objects == sub_old_yml_objects:
            old_yml_objects[attr_name] = sub_old_yml_objects
            return
        # проверить, нужно ли перетирать старое значение для attr_name новым, если True - нужно
        is_force = get_force_status(result_added, save_path, attr_name)
        # получим старое значение комментария (только для тех переменных, для которых старое и новое значения разные)
        prev_comment = get_comment_from_file(old_yml_objects, attr_name) # получить комментарий для заданного поля
        
        # удалить старые коменты, чтобы не было бороды
        prev_comment = re.sub('{}.*.{}\ '.format(pgutils.CommentList.prev_val.value, pgutils.CommentList.old_cmnt.value), '', prev_comment)
        prev_comment = re.sub('{}.*.{}\ '.format(pgutils.CommentList.new_val.value, pgutils.CommentList.old_cmnt.value), '', prev_comment)
        
        if is_force:
            new_comment = "{} {}".format(pgutils.CommentList.prev_val.value, sub_old_yml_objects)
        else:
            new_comment = "{} {}".format(pgutils.CommentList.new_val.value, sub_new_yml_objects)

        if len(prev_comment) > 0 \
            and new_comment != prev_comment \
            and pgutils.CommentList.new_val.value not in prev_comment \
            and pgutils.CommentList.prev_val.value not in prev_comment:
            new_comment = new_comment + ", {} {}".format(pgutils.CommentList.old_cmnt.value, prev_comment)
            
        if 'shared_preload_libraries' in attr_name:
            shared_preload_libraries = pgutils.merge_shared_preload_libraries(sub_old_yml_objects, sub_new_yml_objects)
            sub_old_yml_objects = shared_preload_libraries
            new_comment = ""
        elif is_force:
            sub_old_yml_objects = sub_new_yml_objects
        # для паролей и логинов комменты не пишутся
        if 'password' in attr_name or 'username' in attr_name:
            new_comment = ""

        if type(sub_old_yml_objects) == str and 'username' not in attr_name:
            sub_old_yml_objects = sqss(sub_old_yml_objects)
        # для части bootstrap.dcs необоходимо записать в файл ТОЛЬКО изменененные значения
        if len(diff_bootstrap_file) > 0 \
                and bool(re.search("^bootstrap.dcs", attr_path)) \
                and is_force:
            pgutils.write_etcd_cfg_diff(diff_bootstrap_file, attr_path, sub_old_yml_objects)

        old_yml_objects[attr_name] = sub_old_yml_objects
        if len(new_comment) > 0:
            old_yml_objects.insert(1, attr_name, sub_old_yml_objects, comment=new_comment)

def get_comment_from_file(old_yml_objects, attr_name):
    """
    old_yml_objects - загруженная секция с yml данными из старого конфигурационного файла
    attr_name - название поля в новом конфигурационном файле
    """
    comment = ""
    if old_yml_objects.ca.items is not None:
        for key in old_yml_objects.ca.items:
            lst = old_yml_objects.ca.items[key]
            if attr_name not in key:
                continue
            for cm in lst:
                test_cmn_tkn = ruamel.yaml.tokens.CommentToken('\n\n', ruamel.yaml.error.CommentMark(0), None)
                if type(cm) == type(test_cmn_tkn):
                    comment = re.sub(r"[#\n]", "", cm.value)
                    return comment
    return comment

def merge_objects(result_removed, result_added, old_yml_objects, new_yml_objects, attr_path, diff_bootstrap_file, only_pgse, support_db_admin_user_list, pghba_mode):
    """
    result_removed - список полей, которые необходимо удалить в old_yml_data, перед тем как мержить его с новым yml конфигурационным файлом
    result_added - список полей, значения которых в old_yml_data должны быть обновлены значениями из нового yml конфигурационного файла
    old_yml_objects - yml данные из старого конфигурационного файла
    new_yml_objects - yml данные из нового конфигурационного файла
    attr_path - путь до секции в старом конфигурационном файле
    diff_bootstrap_file - данные из секции bootstrap
    only_pgse - если False, то в результирующем yml файле будут обработаны вспе корневые разделы, кроме restapi и etcd
    support_db_admin_user_list - список db_admin пользователей из all.yml (sigma или alpha)
    pghba_mode - режим мержа pg_hba части: megre - слияние pg_hba из старого и нового конфига, 
                 new - pg_hba из старого конфига полностью заменятся на pg_hba из нового конфига
    """
    for attr_name in new_yml_objects:
        sub_old_yml_objects = None
        if attr_name in old_yml_objects:
            sub_old_yml_objects = old_yml_objects[attr_name]
        sub_new_yml_objects = new_yml_objects[attr_name]
        merge_attribute(result_removed, result_added, old_yml_objects, sub_old_yml_objects, sub_new_yml_objects, attr_name,
                        attr_path, only_pgse, support_db_admin_user_list, pghba_mode, diff_bootstrap_file)

def merge_list(result_removed, result_added, old_list, new_list, attr_path, attr_name, support_db_admin_user_list, pghba_mode):
    """
    result_removed - список полей, которые необходимо удалить в old_yml_data, перед тем как мержить его с новым yml конфигурационным файлом
    result_added - список полей, значения которых в old_yml_data должны быть обновлены значениями из нового yml конфигурационного файла
    old_list - исследуемый список из старого конфигурационного файла
    new_list - исследуемый список из нового конфигурационного файла
    attr_path - путь до секции в старом конфигурационном файле
    attr_name - название поля в новом конфигурационном файле
    support_db_admin_user_list - список db_admin пользователей из all.yml (sigma или alpha)
    pghba_mode - режим мержа pg_hba части: megre - слияние pg_hba из старого и нового конфига, 
                 new - pg_hba из старого конфига полностью заменятся на pg_hba из нового конфига
    """
    lists_with_id = create_merge_directives()
    is_pghba = 'pg_hba' in attr_path
    if is_pghba:
       pgutils.remove_duplicate_pghba(old_list)

    # в этом режиме pghba_mode часть с pghba полностью заменяется на новую
    if is_pghba and pghba_mode == "new":
        old_list.clear()

    for idx, new_elem in enumerate(new_list):
        item_in_previous = find_item_in_list(lists_with_id, old_list, new_elem, attr_path)
        if item_in_previous is None:
            old_list.append(new_elem)
            continue
        if lists_with_id[attr_path] is None:
            if is_pghba and pghba_mode == "new":
                old_list.append(new_elem)
            else:
                pgutils.merge_list_elements(old_list, new_elem, is_pghba, support_db_admin_user_list)
            continue
        
        merge_objects(result_removed, result_added, item_in_previous, new_elem, attr_path, pghba_mode)
    
    pgutils.clean_data(result_removed, old_list, attr_path, is_pghba)
    
    if is_pghba:
        pgutils.sort_pghba(old_list)

def find_item_in_list(lists_with_id, old_list, item_new, attr_path):
    """
    lists_with_id - словарь, ключи в котором путь до ВСЕХ подструктур со списком в yml файле 
    old_list - список
    item_new - элемент, который необходимо найти
    attr_path - путь до секции в старом конфигурационном файле
    """
    if attr_path not in lists_with_id:
        return None

    id_attr_name = lists_with_id[attr_path]
    id_new = None
    if id_attr_name is not None:
        id_new = item_new[id_attr_name]

    for item_previous in old_list:
        id_previous = None
        if id_attr_name is not None:
            id_previous = item_previous[id_attr_name]
        if id_previous == id_new:
            return item_previous
    return None

def remove_dict_elem(keys, elem, only_pgse):
    """
    удаление элементов из словаря по ключам
    keys - список ключей для удаления
    elem - структура словаря, в котором находится с элемент с данным значением ключей
    only_pgse - если False, то в результирующем yml файле будут обработаны вспе корневые разделы, кроме restapi и etcd
    """
    if len(keys) > 0:
        if only_pgse and ('etcd' in keys or 'restapi' in keys): # для версий ниже 421
            return False
        key = keys.pop(0)
    else:
        return False
    res = False
    if keys and elem.get(key) != None and type(elem.get(key)) != type(cmtseq()) and len(keys) != 0 and elem[key] != "{}" and len(elem[key]):
        res = remove_dict_elem(keys, elem.get(key), only_pgse)

    if type(elem) == type(cmtseq()):
        return False
    elif len(keys) == 0 or elem.get(key) == "{}":  # or not len(elem[key])):
        if elem.get(key) == None:
            return False
        if type(elem[key]) == type(cmtmap()) and len(elem[key]):
            return False
        del elem[key]
        return True
    elif elem.get(key) is None:
        return False

    return False

def clear_dict(result_removed, old_data, only_pgse):
    """
    удалить в старом конфиге поля прописанные в result_removed (для словаря только)
    result_removed - список полей, которые необходимо удалить в old_yml_data, перед тем как мержить его с новым yml конфигурационным файлом
    old_data - структура из которой необоходимо удалить необходимые поля, прописанные в result_removed
    only_pgse - если False, то в результирующем yml файле будут обработаны вспе корневые разделы, кроме restapi и etcd
    """
    for i, x in enumerate(result_removed):
        # 0 - тип структуры, 1 - значение
        if x[0] == pgutils.DiffTypes.dict.value:
            path = x[1].split('.')
            if len(x) == 3:
                path.append(x[2])
            remove_dict_elem(path, old_data, only_pgse)

    return

def create_merge_directives():
    """
    определить пути к спискам в файле
    т.е. если в yml файле существует подструктура списка, то здесь нужно явно прописать путь до него
    """
    lists_with_id = orddict()
    lists_with_id['bootstrap.initdb'] = None
    lists_with_id['postgresql.create_replica_methods'] = None
    lists_with_id['postgresql.pg_hba'] = None

    return lists_with_id

def remove_patroni_keys(result_added):
    """
    result_added- список полей, значения которых в old_yml_data должны быть обновлены значениями из нового yml конфигурационного файла
    """
    only_pg_keys = ["bootstrap", "postgresql"]
    remove_idxs = []
    for idx, line in enumerate(result_added):
        tmp = line[0] + ":::" + line[1]
        is_exist = bool(re.search("^dict:::{}".format(only_pg_keys[0]), tmp))
        is_exist = is_exist or bool(re.search("^dict:::{}".format(only_pg_keys[1]), tmp))
        if not is_exist:
            remove_idxs.insert(0, idx)

    for idx in remove_idxs:
        result_added.pop(idx)

    return result_added

def save_diff_cfg_for_bootstrap(result_added):
    """
    result_added- список полей, значения которых в old_yml_data должны быть обновлены значениями из нового yml конфигурационного файла
    """
    bootstrap_dcs_section = "bootstrap.dcs"
    res_f = []
    for idx, line in enumerate(result_added):
        tmp = line[0] + ":::" + line[1]
        is_exist = bool(re.search("^dict:::{}".format(bootstrap_dcs_section), tmp))
        if is_exist:
            res_f.append(line[1] + "." + line[2])
    return

def get_or_replace_pghba(old_conf_file, new_yml_data, result_file, pghba_mode, pghba_users):
    """
    получить список pg_hba строк, в которых есть кто-либо из pghba_users (pghba_mode==get_pg_hba)
    заменить строки pg_hba, в которых есть кто-либо из pghba_users в файле old_conf_file, на строки из  new_yml_data (pghba_mode==replace_pg_hba)
    """
    with open(old_conf_file, 'r') as fp:
        for old_yml_data in ruamel.yaml.round_trip_load_all(stream=fp):
            pass
    
    res_list = []
    try:
        pghba_old_list = old_yml_data['postgresql']['pg_hba']
        pghba_new_list = new_yml_data['postgresql']['pg_hba']
        res_list = pgutils.pop_pg_hba(pghba_old_list, pghba_users)
    except:
        return (1, [])

    if len(pghba_users) != 0 and pghba_users[-1] == ',':
        pghba_users = pghba_users[0:-1]
        
    if pghba_mode == "get_pg_hba":
        if len(res_list) != 0 and res_list[-1] == '|':
            res_list = res_list[0:-1]
        return (0, res_list)
    elif pghba_mode == "replace_pg_hba":
        res_list = pghba_old_list + pghba_new_list
        pgutils.sort_pghba(res_list)
        old_yml_data['postgresql']['pg_hba'] = res_list
        ruamel.yaml.round_trip_dump(old_yml_data, open(result_file, 'w'), width=100000, indent=4, block_seq_indent=4,
                                explicit_start=False)
        return (0, [])                 
    else:
        return (1, [])

def merge(old_conf_file, new_conf_file, result_file, old_ver, new_ver, root_path, pghba_mode, custom_cfg_name, only_pgse=False):
    """
    old_conf_file - пусть до postgres.yml файла для old_ver
    new_conf_file - пусть до postgres.yml файла для new_ver
    result_file - пусть до postgres.yml файла, полученного в ходе мержа
    old_ver - версия старой версии PG SE postgres.yml файла, например, 4.2.5
    new_ver - версия новой версии PG SE postgres.yml файла, например, 4.3.0
    root_path - путь до папки с diff_cfg.txt, с копией all.yml, где также будет создан diff_bootstrap_dcs.txt
    only_pgse - если False, то в результирующем yml файле будут обработаны вспе корневые разделы, кроме restapi и etcd
    pghba_mode - режим мержа pghba части: merge - слияние, new - полная замена на новые значения
    custom_cfg_name - yml файл с db_admin пользователями
    """
    diff_bootstrap_file = root_path + "/diff_bootstrap_dcs.txt"
    diff_cfg_file = root_path + "/diff_cfg.txt"

    open(diff_bootstrap_file, 'w').close()
    
    support_db_admin_user_list = pgutils.load_support_dm_admins_list(root_path, custom_cfg_name, False)

    with open(old_conf_file, 'r') as fp:
        for old_yml_data in ruamel.yaml.round_trip_load_all(stream=fp):
            pass
    with open(new_conf_file, 'r') as fp:
        for new_yml_data in ruamel.yaml.round_trip_load_all(stream=fp):
            pass
    # загрузить из diff_cfg.txt данные 
    result_removed, result_added = pgutils.read_diff_file(old_ver, new_ver, diff_cfg_file)
    
    # удалить из old_yml_data данные, которые исходя из diff_cfg.txt должны удалиться
    clear_dict(result_removed, old_yml_data, only_pgse)
    
    if only_pgse:
        result_added = remove_patroni_keys(result_added)

    merge_objects(result_removed, result_added, old_yml_data, new_yml_data, '', diff_bootstrap_file, only_pgse, support_db_admin_user_list, pghba_mode)

    ruamel.yaml.round_trip_dump(old_yml_data, open(result_file, 'w'), width=100000, indent=4, block_seq_indent=4,
                                explicit_start=False)
