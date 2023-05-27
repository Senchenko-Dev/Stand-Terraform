#!/usr/bin/python
import subprocess
from ansible import errors

class FilterModule(object):
    def filters(self):
        return {'encrypt': self.encrypt}

    def encrypt(self, pwd, key):
        cmd_prefix = "java -Djava.security.egd=file:/dev/./urandom -jar /tmp/password-encrypt-cli-1.3.jar"
        try:
            encoded = subprocess.check_output("{} --key='{}' --password='{}'".format(cmd_prefix, key, pwd), shell=True).split()[-1]
            return encoded.decode("utf-8")
        except Exception as e:
            exc = str(e).replace("'{}'".format(key), "***").replace("'{}'".format(pwd), "***")
            raise errors.AnsibleFilterError('Filter encrypt error: {0}'.format(exc))