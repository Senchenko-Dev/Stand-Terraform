@NonCPS
def getNexusLink(version_pgse, params_list, extension_id, remote_username, remote_password) {
    if ( params_list.segment == "sbercloud" || params_list.segment == "sbercloud_archive" ) {
      return "${params_list.rest_api_url}/repository/${params_list.repo_id}/${params_list.group_id}/${params_list.nexus_artifact_id}/${version_pgse.toUpperCase()}/${params_list.nexus_artifact_id}-${version_pgse.toUpperCase()}-${params_list.classifier}.${extension_id}"
    }else{
      println("params_list.qqqqqq")
      println("params_list.rest_api_url" + params_list.rest_api_url)
      println("params_list.repo_id" + params_list.repo_id)
      println("params_list.group_id" + params_list.group_id)
      println("params_list.nexus_artifact_id" + params_list.nexus_artifact_id)
      def api = "${params_list.rest_api_url}/artifact/maven/redirect?r=${params_list.repo_id}&g=${params_list.group_id}&a=${params_list.nexus_artifact_id}&v=${version_pgse.toUpperCase()}&p=${extension_id}&c=${params_list.classifier}"
      def con = new URL(api).openConnection()
      println("params_list.qqqqqq " + api)
      con.requestMethod = 'HEAD'
      if (remote_username != null && remote_password != null) {
          def auth_string = "${remote_username}:${remote_password}".getBytes().encodeBase64().toString()
          con.setRequestProperty("Authorization", "Basic ${auth_string}")
      }
      println("params_list.qqqqqq")
      con.setInstanceFollowRedirects(true)
      con.connect()
      println("params_list.qqqqqq")
      def is = con.getInputStream()
      is.close()
      return con.getURL().toString()
    }
}

def setNetworkParams(params_list, is_old_pgse_version){
  //is_old_pgse_version = true
  if ((params_list.segment == "sigma") || (is_old_pgse_version && params_list.segment.contains('sigma'))){
    params_list += [rest_api_url: 'http://nexus.sigma.sbrf.ru:8099/nexus/service/local']
    params_list += [classifier: "distrib"]
    params_list += [group_id: 'as_postgresql']
    params_list += [repo_id: 'SBT_CI_distr_repo']
    params_list += [nexus_adress: 'mirror.sigma.sbrf.ru']
    params_list += [pip_repo: 'http://mirror.sigma.sbrf.ru/pypi/simple']
    params_list += [nexus_artifact_id: "CI02289206_PostgreSQL_Sber_Edition"]
  }else if(params_list.segment == "sigma_archive"){
    params_list += [rest_api_url: 'http://nexus.sigma.sbrf.ru:8099/nexus/service/local']
    params_list += [classifier: "distrib"]
    params_list += [group_id: 'as_postgresql.archive']
    params_list += [repo_id: 'SBT_CI_distr_repo']
    params_list += [nexus_adress: 'mirror.sigma.sbrf.ru']
    params_list += [pip_repo: 'http://mirror.sigma.sbrf.ru/pypi/simple']
    params_list += [nexus_artifact_id: env.artifactId_for_nexus]
  }else if((params_list.segment == "alpha") || (is_old_pgse_version && params_list.segment.contains('alpha'))){
    params_list += [rest_api_url: 'https://sbrf-nexus.ca.sbrf.ru/nexus/service/local']
    params_list += [classifier: "distrib"]
    params_list += [group_id: 'Nexus_PROD']
    params_list += [nexus_artifact_id: 'CI02289206_PostgreSQL_Sber_Edition']
    params_list += [repo_id: 'Nexus_PROD']
    params_list += [nexus_adress: 'mirror.ca.sbrf.ru']
    params_list += [pip_repo: 'http://mirror.ca.sbrf.ru/pypi/simple']
  }else if(params_list.segment == "alpha_archive"){
    params_list += [rest_api_url: 'http://sbtnexus.ca.sbrf.ru:8081/nexus/service/local']
    params_list += [classifier: "distrib"]
    params_list += [group_id: 'as_postgresql.archive']
    params_list += [nexus_artifact_id: env.artifactId_for_nexus]
    params_list += [repo_id: 'SBT_CI_distr_repo']
    params_list += [nexus_adress: 'mirror.ca.sbrf.ru']
    params_list += [pip_repo: 'http://mirror.ca.sbrf.ru/pypi/simple']
  }else if((params_list.segment == "sbercloud") || (is_old_pgse_version && params_list.segment.contains('sbercloud'))){
    params_list += [rest_api_url: 'https://dzo.sw.sbc.space/nexus-cd']
    params_list += [classifier: "distrib"]
    params_list += [group_id: 'Nexus_PROD']
    params_list += [nexus_artifact_id: env.artifactId_for_nexus]
    params_list += [repo_id: 'sbt_PROD_group']
    params_list += [pip_repo: 'https://pypi.org/simple/']
    params_list += [nexus_adress: 'pypi.org']
  }else if(params_list.segment == "sbercloud_archive"){
    params_list += [rest_api_url: 'https://dzo.sw.sbc.space/nexus-ci']
    params_list += [classifier: "distrib"]
    params_list += [group_id: 'ru/sbt/pangolin/archive']
    params_list += [nexus_artifact_id: env.artifactId_for_nexus]
    params_list += [repo_id: 'sbt_maven']
    params_list += [pip_repo: 'https://pypi.org/simple/']
    params_list += [nexus_adress: 'pypi.org']
  }

  return params_list
}

def downloadDistrib(version_pgse, params_list, is_old_pgse_version) {
  try{
    params_list = setNetworkParams(params_list, is_old_pgse_version)
    sh "rm -f \\*-distrib.tar.gz"
    withCredentials([[$class: 'UsernamePasswordMultiBinding', credentialsId: 'postgresql_nexus_cred', usernameVariable: 'remote_username', passwordVariable: 'remote_password']]){
      println("downloadDistrib " + version_pgse + "++++" + remote_username + "+++++" + remote_password)
      url_to_distr = getNexusLink(version_pgse, params_list, "tar.gz", remote_username, remote_password)
      println("downloadDistrib " + url_to_distr)
      res_wget = sh(returnStdout: true, script: "wget --no-check-certificate --user=${remote_username} --password=${remote_password} ${url_to_distr} 0>/dev/null 1>&0 2>&0").trim() 
      println("res_wget " + res_wget)
    }
    return 0
  }catch(Exception e){
    return 1
  }
}

def unarchive_distrib(distrib_dir, pgse_ver){
  try{
    sh "rm -rf ${distrib_dir}"
    sh "mkdir -p ${distrib_dir}"
    sh "find -iname \\*${pgse_ver}-distrib.tar.gz -exec tar -xvf {} -C ${distrib_dir} \\; 0>/dev/null 1>&0"
    return 0
  }catch(Exception e){
    return 1
  }
}



def getAnsibleExecString(playbook_type, install_type, version_pgse, params_list, encrypt_password, vault_pswd, recovery_error_elem = ''){
  if (playbook_type == "install"){
    playbook_name = "playbook.yaml"
    action_type = "install"
  }else if (playbook_type == "update_minor_scout"){
    playbook_name = "playbook_scouting.yaml"
    action_type = "update_minor_scout"
  }else if (playbook_type == "update_minor"){
    playbook_name = "playbook_minor_update.yaml"
    action_type = "update_minor"
  }
  println("getAnsibleExecString " + playbook_type + install_type + version_pgse + encrypt_password + vault_pswd)
  distributive_path = "${params_list.distrib_dir}"
  curr_version_pgse = version_pgse.split('-')
  println("getAnsibleExecString 1")
  install_type_splited = install_type.split('-')
  segment_type_splited = params_list.segment.split('_')

  ansible_tags = install_type
  if(!playbook_type.contains('install')) 
    ansible_tags = install_type_splited.first()
  ansible_exec_string = ' ' + playbook_name +
                        ' -i inventories/' + install_type_splited.first() + '/inventory.py' +
                        ' -t always,' + ansible_tags +
                        ' --ssh-extra-args=\'-o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null\'' +
                        ' -e ansible_ssh_pass=' + encrypt_password +
                        ' --vault-password-file=' + vault_pswd + ' ' +
                        ' --flush-cache ' +
                        params_list.ansible_arguments + ' -u ' + params_list.ssh_user +
                        //' -e \'{"as_admins":[' + params_list.as_admin + ']}\'' +
                        //' -e \'{"as_TUZ":[' + params_list.tuz_devops + ',' + params_list.tuz_appl + ']}\'' +
                        ' -e \'{"tde": ' + params_list.tde + '}\'' +
                        ' -e \'{"admin_protection": ' + params_list.admin_protection + '}\'' +
                        ' -e \'{"nolog": false }\' ' +
                        ' --extra-vars \"local_distr_path=' + distributive_path +
                                      ' installation_type=' + install_type_splited.first() +
                                      //' version=' + curr_version_pgse.last() +
                                      //' PGPORT=' + params_list.port_pgse +
                                      //' KMS_HOST=' + params_list.kms_host +
                                      //' KMS_LOGIN=' + params_list.kms_login +
                                      //' KMS_PASSWORD=' + params_list.kms_password +
                                      //' KMS_CLUSTER_ID=' + params_list.kms_cluster_id +
                                      ' schema_name=' + params_list.schema_name +
                                      ' tag=' + install_type +
                                      ' db_name=' + params_list.database_name +
                                      ' security_level=' + params_list.security_level +
                                      ' critical_level=' + params_list.critical_level +
                                      ' segment=' + segment_type_splited.first() +
                                      ' inner_install=yes' +
                                      ' action_type=' + action_type +
                                      ' custom_config=group_vars/custom_dev.yml' +
                                      ' stand=' + params_list.stand  +'\"'

  if( recovery_error_elem != '')
    ansible_exec_string += ' -e \'{"' + recovery_error_elem +'": true }\''
  is_recovery_test_mode = false
  if(!playbook_type.contains('install'))
    is_recovery_test_mode = true
  ansible_exec_string += ' -e \'{"is_recovery_test_mode": ' + is_recovery_test_mode + '}\''
  //ansible_exec_string += '\"'
  //ansible_exec_string += ' -e \'{"' + pg_major_version +'": "04" }\''
  println("getAnsibleExecString 2 " + ansible_exec_string)
  println("getAnsibleExecString 3 " + recovery_error_elem)
  return ansible_exec_string
}

def runAnsiblePlaybook(playbook_type, install_type, params_list, ver, recovery_error_elem = ''){
  try{
    wrap([$class: 'MaskPasswordsBuildWrapper', varPasswordPairs: [[password: "${params_list.ssh_password}", var: 'PSWD']]])
    {
      encrypt_password = "${params_list.ssh_password}"
      def distributive_path = "${params_list.distrib_dir}"
      dir("${params_list.installer_dir}/")
      {
        withCredentials([file(credentialsId: 'ansible_vault_file', variable: 'vault_pswd')])
        {
          logPath = "${params_list.logs_dir}/${ver}-${install_type}/${playbook_type}/"
          if(recovery_error_elem != '')
            logName = "${playbook_type}-with-${recovery_error_elem}.txt"
          else
            logName = "${playbook_type}.txt"
          println("logPath/logName = " + logPath  + logName)
          ansible_exec_string = getAnsibleExecString(playbook_type, install_type, ver, params_list, encrypt_password, vault_pswd, recovery_error_elem)
          sh """
              mkdir -p ${logPath}
              export ANSIBLE_FORCE_COLOR=true
              export ANSIBLE_PIPELINING=1
              source ${env.WORKSPACE}/pg_se_venv/bin/activate
              chmod +x ${env.WORKSPACE}/pg_se_venv/bin/ansible-playbook
              ansible-playbook ${ansible_exec_string} 0>${logPath}${logName} 1>&0 2>&0
            """
          println("step 1 ")
          log_file = "${logPath}${logName}"
          res_check_logs = checkAnsibleResult(params_list, playbook_type, log_file, ver, install_type, recovery_error_elem)
          
          println("step 11 ")
          println("step 2  + ${res_check_logs}")
        }
        
      }
    }
    
    return res_check_logs
  }catch(Exception e){
    return 1
  }
}

def checkAnsibleResult(params_list, playbook_type, log_file, ver, cfg,recovery_error_elem){
  try{
    println("qwerty 0")
    if (playbook_type == "install"){
      println("qwerty 1")
      res_grep_str = sh (returnStdout: true, script: """grep \"master.*unreachable\" ${log_file} | cut -d'=' -f4,5 | cut -d'=' -f2 | cut -d' ' -f1 """).trim()
      println("qwerty 2")
      res_grep = res_grep_str.toInteger()
      println("qwerty 3")
      hosts_list=params_list.hosts_list.split(' ')
      if (hosts_list.size() == 3){
        println("qwerty 4")
        res_grep_replica = sh (returnStdout: true, script: """grep \"replica.*unreachable\" ${log_file} | cut -d'=' -f4,5 | cut -d'=' -f2 | cut -d' ' -f1 """).trim()
        println("qwerty 5")
        res_grep_etcd = sh (returnStdout: true, script: """grep \"etcd.*unreachable\" ${log_file} | cut -d'=' -f4,5 | cut -d'=' -f2 | cut -d' ' -f1 """).trim()
        res_grep += res_grep_replica.toInteger() + res_grep_etcd.toInteger()
      }
    }else if (playbook_type == "update_minor_scout"){
      res_grep = sh (returnStdout: true, script: """grep \"Разведка перед обновлением СУБД Pangolin завершена\" ${log_file} """).trim()
    }else if (playbook_type == "update_minor"){
      if(recovery_error_elem == '')
        res_grep = sh (returnStdout: true, script: """grep \"Обновление СУБД Pangolin успешно завершено\" ${log_file} """).trim()
      else
        res_grep = sh (returnStdout: true, script: """grep \"Восстановление СУБД Pangolin успешно завершено\" ${log_file} """).trim()
    }
    echo "\033[37;1;45m>>> Check ansible log for ${playbook_type} Pangolin ver. ${ver} of type ${cfg} was successful <<<\033[0m"
    return 0
  }catch(Exception e){
    echo "\033[37;1;45m>>> Check ansible log for ${playbook_type} Pangolin ver. ${ver} of type ${cfg} was error, see logs <<<\033[0m"
    return 1
  }
}

def createPythonVenv(params_list){
  params_list = setNetworkParams(params_list, false)
  sh """
      virtualenv pg_se_venv --python=python2
      source pg_se_venv/bin/activate
      pip install --index-url='${params_list.pip_repo}' --trusted-host='${params_list.nexus_adress}' ansible==2.9.25
      pip install --index-url='${params_list.pip_repo}' --trusted-host='${params_list.nexus_adress}' rpm==0.0.2
      pip install --index-url='${params_list.pip_repo}' --trusted-host='${params_list.nexus_adress}' jmespath==0.9.4
      pip install --index-url='${params_list.pip_repo}' --trusted-host='${params_list.nexus_adress}' netaddr==0.7.19
      pip install --index-url='${params_list.pip_repo}' --trusted-host='${params_list.nexus_adress}' PyYAML==5.3
      pip install --index-url='${params_list.pip_repo}' --trusted-host='${params_list.nexus_adress}' jinja2==2.11.2
      """
}

def compare_versions(operator_name,ver_1, ver_2, idx=0){
    first = ver_1
    second = ver_2
    if(idx == 0){
      first = first.split('\\.')
      second = second.split('\\.')
    }
    if((first[idx]).toInteger() < (second[idx]).toInteger()){
      if(operator_name == 'l_less_r')
        return true // left less right
      else
        return false
    }else if((first[idx]).toInteger() > (second[idx]).toInteger()){
      if(operator_name == 'l_more_r')
        return true // left more right
      else
        return false
    }else{
      idx += 1
      if(idx < first.size())
        return compare_versions(operator_name, first, second, idx)
      if(operator_name == 'l_equal_r')
        return true // left equal right
      else
        return false
    }
}

def defineParamsByPGSEVersion(params_list, current_ver){
  if(compare_versions('l_less_r', current_ver, '4.2.1')){
    params_list += [port_pgse: "5432"]
    params_list += [port_pgbouncer: "6543"]
  }else{
    params_list += [port_pgse: "5433"]
    params_list += [port_pgbouncer: "6544"]
  }
  if(compare_versions('l_less_r', current_ver, '4.3.0')){
    params_list += [pghome: "/usr/local/pgsql/"]
    params_list += [pgdata: "/pgdata/11/data/"]
    params_list += [pglogs: "/pgerrorlogs/04"]
  }else{
    major_ver = (current_ver.split('\\.')[0]).toInteger()
    params_list += [pghome: "/usr/pgsql-se-0${major_ver}"]
    params_list += [pgdata: "/pgdata/0${major_ver}/data/"]
    params_list += [pglogs: "/pgerrorlogs/0${major_ver}"]
  }

  return params_list
}

def cleanVMs(params_list){
  try{
    hosts_list=params_list.hosts_list.split(' ')
    if (hosts_list.size() == 1){
        host_active = hosts_list[0]
        host_standby = hosts_list[0]
        host_etcd = hosts_list[0]
    }else{
        host_active = hosts_list[0]
        host_standby = hosts_list[1]
        host_etcd = hosts_list[2]
    }
    build job: params_list.cleanJobName, 
            parameters: [ string(name: 'host_active', value: host_active),
                        string(name: 'host_standby', value: host_standby),
                        string(name: 'host_etcd', value: host_etcd),
                        string(name: 'ssh_login', value: params_list.ssh_user),
                        string(name: 'ssh_password', value: params_list.ssh_password) ]
    return 0
  }catch(Exception e){
    return 1
  }
}

def downoladCustomCfg(params_list, ver){
  try{
    println("downoladCustomCfg+++++ " + ver)
    if(params_list.target_version == ""){
      println("downoladCustomCfg+++++000 " + ver)
      return 0
    }
    dir ("${params_list.installer_dir}/group_vars/")
    {
      println("params_list.target_version " + params_list.target_version)
      target_ver = (params_list.target_version.split('-'))[1]
      if(ver == target_ver)
        sh "cp ../scripts/custom_dev.yml ./"
      else if(!compare_versions('l_less_r', ver, '4.5.0')){
        println("ver.split+++++ " + ver.split('\\.'))
        copy_ver = ver.split('\\.')
        copy_ver[0] = copy_ver[0].toInteger().toString()
        copy_ver[1] = copy_ver[1].toInteger().toString()
        copy_ver[2] = copy_ver[2].toInteger().toString()
        branch_custom_dev = copy_ver.join('.') + "/develop"
        withCredentials([[$class: 'UsernamePasswordMultiBinding', credentialsId: credentialsId_custom_dev, usernameVariable: 'username_custom_dev', passwordVariable: 'password_custom_dev']]){
          url_to_custom_dev="${git_url_custom_dev}/raw/${path_custom_dev}?at=refs/heads/${branch_custom_dev}"
          sh "curl -s -S -L --insecure --user ${username_custom_dev}:${password_custom_dev} ${url_to_custom_dev} -o custom_dev.yml"
        }
      }
    }
    return 0
  }catch(Exception e){
    return 1
  }
}

def prepareInstallationOldPgseVersions(installer_dir){
  try{
    // фиксы, чтобы установка старой версии прошла успешно
    sh """
        cat ${installer_dir}/roles/postgresql/tasks/update_bootstrap.yml
        sed -i "s|.*body_json:.*{{ item.replace.*|        body_json: '{{ item.replace(\"\\\\\\\\\",\"\") }}'|" ${installer_dir}/roles/postgresql/tasks/update_bootstrap.yml
        cat ${installer_dir}/roles/postgresql/tasks/update_bootstrap.yml 
       """
  }catch(r){
    println("warning: prepareInstallationOldPgseVersions 1")
  }

  try{
    sh """
        dir_name=${installer_dir}/
        sed -i 's/    that: ansible_version.full|version >= 2.9/    that: ansible_version/' \${dir_name}/roles/checkup/tasks/ansible_env.yml 
        #sed -i "/^as_admins:.*\$/d" \${dir_name}/group_vars/all.yml 0>/dev/null 1>&0 2>&0
        #echo "" >> \${dir_name}/group_vars/all.yml 0>/dev/null 1>&0 2>&0
        #echo "as_admins: ['SBT-SA-PGPS0004',]" >> \${dir_name}/group_vars/all.yml 0>/dev/null 1>&0 2>&0
        years=\$(date +%Y-2020|bc)      
        for file_yml in \$(find \${installer_dir} -maxdepth 7 -name *.yml ); do  
          sed -i 's/Dec 31 2020/Dec 31 2030/' \${file_yml} 0>/dev/null 1>&0 2>&0
          sed -i 's/Dec 31 2021/Dec 31 2030/' \${file_yml} 0>/dev/null 1>&0 2>&0
          echo "\${file_yml}"
          sed -i 's/seconds: 10/seconds: 20/' \${file_yml} 0>/dev/null 1>&0 2>&0
          sed -i 's/seconds: 11/seconds: 20/' \${file_yml} 0>/dev/null 1>&0 2>&0
          sed -i 's/seconds: 15/seconds: 20/' \${file_yml} 0>/dev/null 1>&0 2>&0
          sed -i 's/no_log: [T|t]rue/no_log: false/' \${file_yml} 0>/dev/null 1>&0 2>&0
        done 0>/dev/null 1>&0 2>&0
      """
  }catch(r){
    println("warning: prepareInstallationOldPgseVersions 2")
  }
}


def runAutotests(params_list, install_type, ver, cfg){
  try{
    echo "\033[37;1;45m>>> QA test for Pangolin ver. ${ver} of type ${cfg} was started <<<\033[0m"
    hosts_list=params_list.hosts_list.split(' ')
    if (hosts_list.size() == 1){
        host_active = hosts_list[0]
        host_standby = hosts_list[0]
        host_etcd = hosts_list[0]
    }else{
        host_active = hosts_list[0]
        host_standby = hosts_list[1]
        host_etcd = hosts_list[2]
    }

    changePostgresLinuxPass(params_list)

    def build_result = build job: params_list.targetAutoTestJobName, propagate: true,
                      parameters: [
                          string(name: 'BRANCH', value: params_list.autotests_branch),
                          string(name: 'host_active', value: host_active),
                          string(name: 'host_standby', value: host_standby),
                          string(name: 'host_etcd', value: host_etcd),
                          string(name: 'database', value: params_list.main_database),
                          string(name: 'db_port', value: params_list.port_pgse),
                          string(name: 'bouncer_port', value: params_list.port_pgbouncer),
                          string(name: 'ssh_port', value: params_list.ssh_port),
                          string(name: 'su_user', value: params_list.postgres_database_user),
                          password(name: 'su_password', value: params_list.postgres_database_password),
                          password(name: 'ssh_password', value: params_list.postgresql_ssh_password),
                          password(name: 'patroni_password', value: params_list.patroni_api_password),
                          string(name: 'dev_user', value: params_list.ssh_user),
                          password(name: 'dev_password', value: params_list.ssh_password),
                          string(name: 'cluster_name', value: params_list.cluster_name),
                          //string(name: 'default_leader', value: default_leader),
                          //string(name: 'node_name1', value: node_name1),
                          //string(name: 'node_name2', value: node_name2),
                          string(name: 'PGHOME', value: params_list.pghome),
                          string(name: 'PGDATA', value: params_list.pgdata),
                          string(name: 'PGLOGS', value: params_list.pglogs),
                          string(name: 'patroni_conf', value: params_list.path_to_hba_config),
                          string(name: 'sec_admin', value: params_list.sec_admin),
                          password(name: 'sec_pass', value: params_list.sec_pass),
                          string(name: 'db_admin', value: params_list.db_admin),
                          password(name: 'db_pass', value: params_list.db_pass),
                          string(name: 'backup_admin', value: params_list.backup_admin),
                          password(name: 'backup_pass', value: params_list.backup_pass),
                          string(name: 'as_admin', value: params_list.as_admin),
                          password(name: 'as_pass', value: params_list.as_pass),
                          string(name: 'tuz_devops', value: params_list.tuz_devops),
                          password(name: 'tuz_devops_pass', value: params_list.tuz_devops_pass),
                          string(name: 'tuz_appl', value: params_list.tuz_appl),
                          password(name: 'tuz_appl_pass', value: params_list.tuz_appl_pass),
                          string(name: 'check_db', value: params_list.database_name),
                          string(name: 'check_schema', value: params_list.schema_name),
                          string(name: 'check_ts', value: params_list.tablespace_name),
                          string(name: 'KMS_MODE', value: params_list.kms_mode),
                          string(name: 'KMS_HOST', value: params_list.kms_host),
                          string(name: 'KMS_LOGIN', value: params_list.kms_login),
                          password(name: 'KMS_PASSWORD', value: params_list.kms_password),
                          string(name: 'KMS_ROOT_TOKEN', value: params_list.kms_root_token),
                          string(name: 'KMS_CONFIG', value: params_list.kms_config),
                          string(name: 'KMS_CLUSTER_ID', value: params_list.kms_cluster_id),
                          //string(name: 'open_source_version', value: params_list.open_source_version),
                          //string(name: 'open_source_version_num', value: open_source_version_num),
                          //string(name: 'sber_version', value: sber_version),
                          string(name: 'security_level', value: params_list.security_level),
                          string(name: 'install_type', value: install_type),
                          string(name: 'test_runner_args', value: params_list.test_runner_args),
                          //string(name: 'src_host', value: data_protector_host),
                          //string(name: 'src_login', value: data_protector_login),
                          //password(name: 'src_password', value: data_protector_password),
                          //string(name: 'secure_config', value: secure_config),
                          string(name: 'list_email', value: params_list.list_email),
                          string(name: 'jira_credentialsId', value: params_list.jira_credentialsId),
                          string(name: 'jira_server', value: params_list.jira_server),
                          string(name: 'path_cert', value: params_list.path_cert),
                          string(name: 'logging_level', value: params_list.logging_level),
                          string(name: 'full_debug', value: params_list.full_debug),
                          string(name: 'max_log_symbols', value: params_list.max_log_symbols),
                          string(name: 'jenkinsAgentLabel', value: params_list.jenkinsAgentLabel)
                      ]

    echo "\033[37;1;45m>>> QA test for Pangolin ver. ${ver} of type ${cfg} was successful <<<\033[0m"
    return 0
  }catch(Exception e){
    echo "\033[37;1;45m>>> QA test for Pangolin ver. ${ver} of type ${cfg} was error, see logs <<<\033[0m"
    return 1
  }
}


// def deleteDpSpecs(String dp_host, String dp_ssh_user, String dp_ssh_password){
//     sh "sshpass -p ${dp_ssh_password} ssh -o StrictHostKeyChecking=no -p 22 ${dp_ssh_user}@${dp_host} 'cd /etc/opt/omni/server/datalists/ && rm -f tvlds-pprb00016Xtvlds-pprb00017_RUN_PG_FULL tvlds-pprb00016Xtvlds-pprb00017_tvlds-pprb00016_PG_FULL tvlds-pprb00016Xtvlds-pprb00017_tvlds-pprb00016_PG_LOG tvlds-pprb00016Xtvlds-pprb00017_tvlds-pprb00017_PG_FULL tvlds-pprb00016Xtvlds-pprb00017_tvlds-pprb00017_PG_LOG'"
// }

def changePostgresLinuxPass(params_list){
    println("jsdhfkjsdhkfgj+++++++")
    hosts_list=params_list.hosts_list.split(' ')
    hosts_list.each {
        res_sh = sh(
          script: "sshpass -p \'${params_list.ssh_password}\' ssh -o StrictHostKeyChecking=no -p 22 ${params_list.ssh_user}@${it} \'echo \'${params_list.postgresql_ssh_password}\' | sudo passwd \'postgres\' --stdin\'",
          returnStatus: true
        )
        println("res_sh= " + res_sh)
    }
}

// def deleteTestStringsFromHba(list_of_hosts){
//         list_of_hosts.each{
//         sh "sshpass -p ${postgresql_ssh_password} ssh -o StrictHostKeyChecking=no -p 22 postgres@${it} 'sed -i \"/host all all 0.0.0.0/d\" ${path_to_hba_config}'"
//     }
// }

return this;