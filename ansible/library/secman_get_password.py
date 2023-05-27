from ansible.module_utils.basic import *
import pycurl
import json
import os
try:
	from StringIO import StringIO # Python 2
except ImportError:
    from io import StringIO # Python 3

DOCUMENTATION = r'''
    module: secman_get_password

    description: get password /group passwords in SecMan 

    options:
        token: 
            description: vault token, default env.VAULT_TOKEN
            required: false
            type: str        
        url: 
            description: vault url https://ift.secrets.ca.sbrf.ru, default env.VAULT_ADDR
            required: false
            type: str     
        path_to_group: 
            description: path to secrets CI00058876_CI00356039/A/58876/jen/DevB/kv/ansible/APP_SERVERS/
            required: true
            type: str     
        secret_key: 
            description: if add secret_key, module response only password
            required: false
            type: str     
        ssl_verefy:
            description: disable / enable ssl verefy
            required: false
            type: bool 
        author:
            - Surkov A.V.
'''

EXAMPLES = r'''

  - name: Sent request to SecMan
    secman_get_password:
      token: "{{ VAULT_TOKEN }}" #env variable  default = env.VAULT_TOKEN
      url: "{{ VAULT_ADDR }}" #env variable  default=env.VAULT_ADDR
      path_to_group: {{ path_to_group }} 
      secret_key: {{ ansible_user }}
      ssl_verefy: false
    register: sec_man_response
    delegate_to: localhost 

    "module_args": {
              token: "s.00000000000000000.CI00058876_CI00356039" 
              url: "https://ift.secrets.ca.sbrf.ru"
              path_to_group: "CI00058876_CI00356039/A/58876/jen/DevB/kv/ansible/APP_SERVERS/"
              secret_key:"wfadmin"
            }
    '''

RETURN = r'''
        changed:
            description: true = success, false = failure
            type: boolean
        password:
            description: return password for the secret_key (UserName=OWS Address=10.222.10.1) or if not set secret_key return dict with passwords
            type: str / dict             
        response_code:
            description: http response code, successful RC = 200 otherwise failure
            type: int
        response:
            description: additional information for analysis
            type: str
'''


def get_password():
    module_args = dict(
        token=dict(type='str', required=False, default=None),
        url=dict(type='str', required=False, default=None),
        secret_key=dict(type='str', required=False, default=None),
        path_to_group=dict(type='str', required=True),
        ssl_verefy=dict(type='bool', required=False, default=False)
    )

    module = AnsibleModule(
        argument_spec=module_args,
        supports_check_mode=True
    )

    result = dict(
        changed=False,
        password='',
        response_code='',
        response='',
    )

    if module.check_mode:
        module.exit_json(**result)

    try:
        token = ""
        url = ""

        if module.params['token'] != None:
            token = module.params['token'].strip()
        elif os.environ.has_key('VAULT_TOKEN'):
            token = os.environ.get('VAULT_TOKEN').strip()
        else:
            result['response'] = "Set env.VAULT_TOKEN or token"
            module.fail_json(msg='You requested fail, see response', **result)

        if module.params['url'] != None:
            url = module.params['url'].strip()
        elif os.environ.has_key('VAULT_ADDR'):
            url = os.environ.get('VAULT_ADDR').strip()
        else:
            result['response'] = "Set env.VAULT_ADDR or url"
            module.fail_json(msg='You requested fail, see response', **result)

        url = url.strip() + module.params['path_to_group'].strip()
        curl = pycurl.Curl()
        buffer = StringIO()
        headers = ["x-vault-token: %s" % str(token), "accept: */*"]

        curl.setopt(pycurl.URL, url.encode('ascii'))

        curl.setopt(pycurl.SSL_VERIFYPEER, module.params['ssl_verefy'])

        # curl.setopt(pycurl.SSL_VERIFYHOST, False)
        curl.setopt(pycurl.WRITEFUNCTION, buffer.write)
        curl.setopt(pycurl.HTTPHEADER, headers)
        curl.setopt(pycurl.TIMEOUT, 300)

        curl.perform()
        http_response_code = curl.getinfo(pycurl.HTTP_CODE)
        curl.close()
        result['response_code'] = http_response_code
        if http_response_code == 200:
            request_data = json.loads(buffer.getvalue())
            result['changed'] = True
            # try get one password for secret_key
            if module.params['secret_key'] != None:

                if request_data['data'].has_key(module.params['secret_key']):
                    result['password'] = request_data['data'][str(module.params['secret_key'])]
                else:
                    result['response'] = "Cant get password for secret_key: {} url: {}".format(
                        module.params['secret_key'], url)
                    module.fail_json(msg='You requested fail, see response', **result)
            # else get dict with passwords
            else:
                result['password'] = request_data['data']
        else:
            result[
                'response'] = "secman: Get request: storage is empty or another problem. Check secman_url {} ; May be url in the end  symbol '/' , response code: {} , response: {}" \
                .format(url, http_response_code, buffer.getvalue())
            module.fail_json(msg='You requested fail, see response', **result)
        buffer.close()


    except Exception as ex:
        result['response'] = "Can't get password from SecMan ", "Exception:", ex
        module.fail_json(msg='You requested fail, see response', **result)
    module.exit_json(**result)


if __name__ == '__main__':
    get_password()