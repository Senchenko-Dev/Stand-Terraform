#!/usr/bin/python
#
# Requirements packages
# yum install python2-ruamel-yaml python2-pycurl
#
# Upload secrets.yml to hasicorp vault
# ./secman_yaml.py --url http://10.33.8.239:8200 --path /v1/DEV/PILP/R4/KV --token s.cAdFmzZzPh65jrvr19kCguVE --yaml secrets.yml
#
import pycurl
import json
import argparse
from StringIO import StringIO
from ruamel import yaml

parser = argparse.ArgumentParser(description="Export secman secrets to yaml file")
parser.add_argument('--url', help='http://10.33.8.239:8200')
parser.add_argument('--path', help='Path hashicorp like as /v1/DEV/PILP/R4/KV')
parser.add_argument('--token', help='Token hashicorp like as s.cAdFmzZzPh65jrvr19kCguVE')
parser.add_argument('--yaml', help='Set file yaml')
parser.add_argument('--ssl', default=False, help='SSL')
parser.add_argument('--output_file', default='secrets.yml', help='File variables')
parser.add_argument('--verbose', default='0', help='Enable verbose 1')

args = parser.parse_args()

url = args.url 
path_to_group = args.path
token = args.token
yaml_file = args.yaml
ssl_verefy = args.ssl
output_file = args.output_file
verbose = int(args.verbose)

def should_use_block(value):
    for c in u"\u000a\u000d\u001c\u001d\u001e\u0085\u2028\u2029":
        if c in value:
            return True
    return False

def my_represent_scalar(self, tag, value, style=None):
    if style is None:
        if should_use_block(value):
            style='|'
        else:
            style = self.default_style

    node = yaml.representer.ScalarNode(tag, value, style=style)
    if self.alias_key is not None:
        self.represented_objects[self.alias_key] = node
    return node

class Secrets:
    def __init__(self, yaml_file=None, path_to_group=path_to_group, my_represent_scalar=my_represent_scalar):
        self.yaml_file = yaml_file
        self.my_represent_scalar = my_represent_scalar
        self.headers = ["x-vault-token: %s" % str(token), "accept: */*"]
        self.secret_dirs = {'secret_dirs': {}}
        self.result = {'secrets': {}}
        self.secrets = {'secrets': {}}
        self.path_to_group = path_to_group

    def __curl(self):
        curl = pycurl.Curl()        
        curl.setopt(pycurl.SSL_VERIFYPEER, ssl_verefy)
        curl.setopt(pycurl.HTTPHEADER, self.headers)
        curl.setopt(pycurl.TIMEOUT, 300)
        curl.setopt(pycurl.VERBOSE, verbose)
        return curl


    def __get_dirs(self):
        secret_dirs = self.secret_dirs
        curl = self.__curl()
        path_to_group = self.path_to_group + '?list=true'
        furl = url.strip() + path_to_group.strip()
        buffer = StringIO()

        curl.setopt(pycurl.URL, furl.encode('ascii'))
        curl.setopt(pycurl.WRITEFUNCTION, buffer.write)
        curl.perform()
        http_response_code = curl.getinfo(pycurl.HTTP_CODE)
        curl.close()

        if http_response_code == 200:
            request_data = json.loads(buffer.getvalue())
            for key in request_data['data']:
                secret_dirs['secret_dirs'] = request_data['data'][key]
        else:
           print http_response_code
        return secret_dirs['secret_dirs']

    def __get_passwords(self, secret_dir):
        secrets = self.secrets

        curl = self.__curl()
        secrets['secrets'][secret_dir] = {}
        path_to_group = self.path_to_group + '/' + secret_dir
        furl = url.strip() + path_to_group.strip()
        buffer = StringIO()
  
        curl.setopt(pycurl.URL, furl.encode('ascii'))
        curl.setopt(pycurl.WRITEFUNCTION, buffer.write)
        curl.perform()
        http_response_code = curl.getinfo(pycurl.HTTP_CODE)
        curl.close()
        if http_response_code == 200:
            request_data = json.loads(buffer.getvalue())
            for key in request_data['data']:
                secrets['secrets'][secret_dir][key] = request_data['data'][key]
        else:
           print http_response_code
        self.result['secrets'][secret_dir] = secrets['secrets'][secret_dir]

    def write_yaml(self):
        secret_dirs = self.__get_dirs()
        for secret_dir in secret_dirs:
            self.__get_passwords(secret_dir)
  
        yaml.representer.BaseRepresenter.represent_scalar = self.my_represent_scalar
        yaml.safe_dump(self.result, file(output_file,'w'), encoding='utf-8', allow_unicode=True, default_flow_style=False)
        
    def __push_secret(self, secret_dir, json_secret):
        curl = self.__curl()
        path_to_group = self.path_to_group + '/' + secret_dir
        furl = url.strip() + path_to_group.strip()
        body = json.dumps(json_secret)
        buffer = StringIO()
        
        curl.setopt(pycurl.POST, 1)
        curl.setopt(pycurl.POSTFIELDS, body)
        curl.setopt(pycurl.URL, furl.encode('ascii'))      
        curl.setopt(pycurl.WRITEFUNCTION, buffer.write)
        curl.perform()

        http_response_code = curl.getinfo(pycurl.HTTP_CODE)
        if http_response_code == 204:
            print "{} uploaded {} secrets \n---".format(secret_dir, len(json_secret.keys()))
        else:
            print http_response_code
        curl.close()

    def upload(self):
        with open(self.yaml_file, 'r') as yfile:
            d = yaml.safe_load(yfile)
        for k, v in d["secrets"].items():
            self.__push_secret(k, v)

if __name__ == "__main__":
    s = Secrets(yaml_file)
    if yaml_file == None:
        s.write_yaml()
    else:
        s.upload()
