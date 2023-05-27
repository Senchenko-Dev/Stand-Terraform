import re
import string


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

class FilterModule(object):
    def filters(self):
        return {
            'strip': strip,
            'check_backup_user_in_file': check_backup_user_in_file,
            'add_quotes_to_values': add_quotes_to_values,
            'compare_pgbouncer_configs': compare_pgbouncer_configs,
            'bcompare': bcompare,
            'escape_string': escape_string,
        }