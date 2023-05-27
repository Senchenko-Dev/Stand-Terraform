from config_auto_merge import parse_utils as pgutils
import re

def read_pghba_conf(conf_path):
    """
    conf_path - путь до pg_hba.conf
    """
    conf_file = open(conf_path, 'r')
    res_data = []
    for line in conf_file:
        line = re.sub("^\s+|\n|\r|\s+$", '', line)
        if len(line) > 0 and line[0] == '#':
            line = re.sub(r"[#]", "", line)
            res_data.append(pgutils.CommentList.cmnt_only.value + line)
        else:
            res_data.append(line)
    return res_data

def get_or_replace_pghba(old_conf_file, new_yml_data, result_file, pghba_mode, pghba_users):
    """
    получить список pg_hba строк, в которых есть кто-либо из pghba_users (pghba_mode==get_pg_hba)
    заменить строки pg_hba, в которых есть кто-либо из pghba_users в файле old_conf_file, на строки из  new_yml_data (pghba_mode==replace_pg_hba)
    """
    pghba_old_list = read_pghba_conf(old_conf_file)

    res_list = []
    try:
        res_list = pgutils.pop_pg_hba(pghba_old_list, pghba_users)
    except:
        return (1, [])
        
    if pghba_mode == "get_pg_hba":
        return (0, res_list)
    elif pghba_mode == "replace_pg_hba":
        res_list = pghba_old_list + new_yml_data
        pgutils.sort_pghba(res_list)
        old_yml_data = res_list

        f = open(result_file, 'w')
        for old_line in old_yml_data:
            if pgutils.CommentList.cmnt_only.value not in old_line:
                res_str = str(old_line)
            else:
                old_line = re.sub("^({})".format(pgutils.CommentList.cmnt_only.value), '', old_line)
                res_str = '#' + str(old_line)
            f.write(res_str + '\n')
        return (0, [])                 
    else:
        return (1, [])

def merge_pghba_conf(old_conf_file, new_conf_file, result_file, old_ver, new_ver, root_path, custom_cfg_name, pghba_mode):
    """
    old_conf_file - пусть до postgres.yml файла для old_ver
    new_conf_file - пусть до postgres.yml файла для new_ver
    result_file - пусть до pg_hba.conf файла, полученного в ходе мержа
    old_ver - версия старой версии PG SE postgres.yml файла, например, 4.2.5
    new_ver - версия новой версии PG SE postgres.yml файла, например, 4.3.0
    root_path - путь до папки с diff_cfg.txt, с копией all.yml, где также будет создан diff_bootstrap_dcs.txt
    pghba_mode - режим мержа pg_hba части: megre - слияние pg_hba из старого и нового конфига, 
                 new - pg_hba из старого конфига полностью заменятся на pg_hba из нового конфига
    custom_cfg_name - yml файл с db_admin пользователями
    """
    file_diff_name = root_path + "/diff_cfg.txt"
    
    support_db_admin_user_list = pgutils.load_support_dm_admins_list(root_path, custom_cfg_name, False)

    old_list = read_pghba_conf(old_conf_file)
    new_list = read_pghba_conf(new_conf_file)

    pgutils.remove_duplicate_pghba(old_list)

    result_removed, result_added = pgutils.read_diff_file(old_ver, new_ver, file_diff_name)

    if pghba_mode == "new":
        old_list.clear()

    for new_line in new_list:
        if pghba_mode == "new":
            old_list.append(new_line)
        else:
            pgutils.merge_list_elements(old_list, new_line, True, support_db_admin_user_list)
    
    pgutils.sort_pghba(old_list)
    
    pgutils.clean_data(result_removed, old_list, "", True)

    f = open(result_file, 'w')
    for old_line in old_list:
        if pgutils.CommentList.cmnt_only.value not in old_line:
            res_str = str(old_line)
        else:
            old_line = re.sub("^({})".format(pgutils.CommentList.cmnt_only.value), '', old_line)
            res_str = '#' + str(old_line)
        f.write(res_str + '\n')