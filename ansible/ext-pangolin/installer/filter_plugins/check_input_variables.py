import ansible

def find_text_in_variable(variable, text):
    "If text find in variable return True, otherwise will returned False"
    if isinstance(variable, list) or isinstance(variable, ansible.utils.unsafe_proxy.AnsibleUnsafeText):
        if isinstance(text, list):
            for string in text:
                for value in variable:
                    if str(value) == str(string):
                        return True
        elif isinstance(text, str) or isinstance(text, int):
            for value in variable:
                if str(value) == str(text):
                    return True
    elif isinstance(variable, str):
        if isinstance(text, str):
            if str(variable) == str(text):
                return True
    else:
        raise TypeError('Input variables can be list or string')

def find_element_in_variable(variable, text):
    "If element in variable return True, otherwise will returned False"
    if isinstance(variable, list) or isinstance(variable, ansible.utils.unsafe_proxy.AnsibleUnsafeText):
        if isinstance(text, list):
            for string in text:
                for value in variable:
                    if (str(value)).find(str(string)) != -1:
                        return True
        elif isinstance(text, str):
            for value in variable:
                if (str(value)).find(str(text)) != -1:
                    return True
    else:
        raise TypeError('Input variables can be list or string')

def check_letters_in_variable(variable):
    "If variable contains upper letter function return True, otherwise will returned False"
    try:
        if isinstance(variable, list):
            result = []
            for value in variable:
                for letter in str(value):
                    if letter.isupper():
                        result.append(True)
                    else:
                        result.append(False)
        elif isinstance(variable, str) or isinstance(variable, ansible.utils.unsafe_proxy.AnsibleUnsafeText):
            result = []
            for letter in str(variable):
                if letter.isupper():
                    result.append(True)
                else:
                    result.append(False)
        if any(result):
            return True
        else:
            return False
    except ValueError:
        return True
        

class FilterModule(object):
    def filters(self):
        return {
            'find_text_in_variable': find_text_in_variable,
            'find_element_in_variable': find_element_in_variable,
            'check_letters_in_variable': check_letters_in_variable,
        }