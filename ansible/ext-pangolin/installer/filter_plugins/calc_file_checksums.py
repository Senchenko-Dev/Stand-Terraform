import zlib
import os

def calc_checksum_of_file(the_file):
    with open(the_file, 'rb') as fp:
        data = fp.read()
        return zlib.crc32(data)

def get_sorted_list_of_files(current_dir):
    lst_of_files = []
    print("dsgsdgsdg", current_dir,"+++++++",os.walk(current_dir))
    for dirpath, dirnames, filenames in os.walk(current_dir):
        print("dsgsdgsdg", current_dir,"+++++++", filenames)
        for filename in filenames:
            lst_of_files.append(os.path.join(dirpath, filename))
    return sorted(lst_of_files)

def calc_checksums(current_dir):
    lst_of_checksums = []

    lst_of_files = get_sorted_list_of_files(current_dir)
    for f in lst_of_files:
        lst_of_checksums.append(calc_checksum_of_file(f))
    print("dsgsdgsdg", lst_of_files)
    return ','.join(str(x) for x in lst_of_checksums)

class FilterModule(object):
    def filters(self):
        return {
            'calc_checksums': calc_checksums,
        }