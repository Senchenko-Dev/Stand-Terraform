import re
import os

def version(version):
    """Filter for cast string variable with version to float"""
    string_with_version = str(version)
    if len(string_with_version) in (5,6,7):
        _version = string_with_version.split('.')
        version = _version[0] + '.' + _version[1]
    else:
        raise ValueError('Input variable have incorrect len')
    return float(version)


def compare_versions(versions):
    """Filter for compare version of installed service with version of 
    service from distributive. When distrib version newer than installed,
    function is returning True, else False"""
    current_version = versions[0].split('.')
    version_from_distrib = versions[1].split('.')
    if int(current_version[0]) == int(version_from_distrib[0]):
        if int(current_version[1]) == int(version_from_distrib[1]):
            if int(current_version[2]) >= int(version_from_distrib[2]):
                return 'False'
            elif int(current_version[2]) < int(version_from_distrib[2]):
                return 'True'
        elif int(current_version[1]) < int(version_from_distrib[1]):
            return 'True'
        elif int(current_version[1]) > int(version_from_distrib[1]):
            return 'False'
    elif int(current_version[0]) < int(version_from_distrib[0]):
        return 'True'
    elif int(current_version[0]) > int(version_from_distrib[0]):
        return 'False'


def compare_pg_se_versions(versions, idx=0):
    """compare version for PostgreSQL SE only. When left version less than rigth version,
    function is returning 0 and etc."""
    first = versions[0]
    second = versions[1]
    if idx == 0:
        first = first.split('.')
        second = second.split('.')

    if int(first[idx]) < int(second[idx]):
        return 0 # left less right
    elif int(first[idx]) > int(second[idx]):
        return 2 # left more right
    else:
        idx += 1
        if idx < len(first):
            vrs = [first, second]
            return compare_pg_se_versions( vrs, idx)
        return 1  # left equal right


def get_version_from_filename(path):
    """Filter for get version from file name or directory name"""
    version = re.findall(r'\d*\.\d*\.\d*', os.path.split(path)[-1])
    return str.join('',version)


def define_lag(hosname_of_replica, json):
    """Filter get dict and return value of lag key"""
    for item in json:
        if hosname_of_replica in item.values():
            return (item.get('lag'))


class FilterModule(object):
    def filters(self):
        return {
            'version': version,
            'compare_versions': compare_versions,
            'get_version_from_filename': get_version_from_filename,
            'compare_pg_se_versions': compare_pg_se_versions,
            'define_lag': define_lag,
        }
