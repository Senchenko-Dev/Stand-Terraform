import re
import string

def get_cert_path(str, cert_name):
    if not len(str) or not len(cert_name):
        return ""
    cert = cert_name.split('|')
    if len(cert) == 2:
        if cert[0] in str:
            cert_name = cert[0]
        elif cert[1] in str:
            cert_name = cert[1]
        else:
            return ""
    elif len(cert) == 1:
        if cert[0] in str:
            cert_name = cert[0]
        else:
            return ""

    list_of_strs = str.split(cert_name)
    if len(list_of_strs) < 2:
        return ""
    list_of_strs = list_of_strs[-1].split('=')
    if len(list_of_strs) < 2:
        return ""
    list_of_strs = list_of_strs[1].split(' ')
    if not len(list_of_strs):
        return ""
    res_str = ""
    for idx, x in enumerate(list_of_strs):
        if len(x):
            res_str = re.sub(r"[\"\'=\ ]", "", list_of_strs[idx])
            break

    return res_str

def strip(string, position):
	if position == 'beginning':
		changed_string = string.lstrip()
	elif position == 'end':
		changed_string = string.rstrip()
	elif position == 'both':
		changed_string = string.lstrip().rstrip()
	else:
		raise ValueError('Incorrect name of position. Position can be one value from list: beginning, end, both')
	return changed_string

def check_backup_user_in_file(text):
    entries = re.findall(r'-U backup_user', text)
    if len(entries) == 2:
        return True
    else:
        return False

def add_quotes_to_values(list_schemas):
    schema_string = []
    for el in list_schemas:
        new_elem = ''
        new_elem += '"' + el + '"'
        schema_string.append(new_elem)
    return schema_string

def compare_pgbouncer_configs(scenario_error_differ, list1, list2):
    dict1 = {}
    dict2 = {}
    if len(list1) != len(list2):
        scenario_error_differ = True
        return scenario_error_differ
    for el1, el2 in zip(list1, list2):
        dict1[el1['item']] = el1['message']
        dict2[el2['item']] = el2['message']
    if dict1 == dict2:
        scenario_error_differ = False
        return scenario_error_differ
    else:
        scenario_error_differ = True
        return scenario_error_differ

def bcompare(list, comp_type):
    for x in list:
        if not x and comp_type == "AND": return False
        if x and comp_type == "OR": return True
    else:
        if comp_type == "AND": return True
        if comp_type == "OR": return False

def compare_pangolin_versions( operator_name,versions, idx=0):
    """
    example:
    versions = ['4.3.1', '4.2.1']
    compare_versions('l_less_r', versions)
    """
    first = versions[0]
    second = versions[1]
    if idx == 0:
        first = first.split('.')
        second = second.split('.')

    if int(first[idx]) < int(second[idx]):
        if operator_name == 'l_less_r':
            return True # left less right
        else:
            return False
    elif int(first[idx]) > int(second[idx]):
        if operator_name == 'l_more_r':
            return True # left more right
        else:
            return False
    else:
        idx += 1
        if idx < len(first):
            vrs = [first, second]
            print(first)
            return compare_versions(operator_name, vrs, idx)
        if operator_name == 'l_equal_r':
            return True # left equal right
        else:
            return False

def escape_string(instr):
    outres = list(instr)
    insert_count = 0
    for idx, x in enumerate(instr):
        if x in string.punctuation:
            outres.insert(idx + insert_count, '\\')
            ii = idx + insert_count
            insert_count += 1
    outres = "".join(outres)
    return outres

def get_password_from_pg_auth_path(list_res):
    for el in list_res:
        if '$enc' in el:
            return el
    else:
        raise ValueError('There is no encrypted password in the received list')

def check_configs_on_unsupported_symbols(filename):
    with open(filename, 'rb') as config_file:
        read_conf = config_file.readlines()
    check_result = True
    for line in read_conf:
        if not re.search(r"^[#;]",str(line)):
            try:
                line.decode('ascii')
            except UnicodeDecodeError:
                check_result = False
                break
    return check_result


def filter_all(comparison):
    return all(comparison)


def filter_any(comparison):
    return any(comparison)

class FilterModule(object):
    def filters(self):
        return {
            'strip': strip,
            'check_backup_user_in_file': check_backup_user_in_file,
            'add_quotes_to_values': add_quotes_to_values,
            'compare_pgbouncer_configs': compare_pgbouncer_configs,
            'bcompare': bcompare,
            'escape_string': escape_string,
            'get_cert_path': get_cert_path,
            'get_password_from_pg_auth_path': get_password_from_pg_auth_path,
            'check_configs_on_unsupported_symbols': check_configs_on_unsupported_symbols,
            'filter_any': filter_any,
            'filer_all': filter_all,
        }

# if __name__ == "__main__":
#     print(check_configs_on_unsupported_symbols("pg_hba.conf"))