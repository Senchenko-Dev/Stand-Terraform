//variables from jenkins
version = env.version //version of PostgreSQL SE
tag = env.installation_type // type of installation(cluster,standalone)
ansible_arguments = env.ansible_arguments
stand = env.environment // type of stand
security_level = env.security_level //importance of stored data
critical_level = env.critical_level
clustername = env.clustername
port = env.port //PosgreSQL port
tablespace_name = env.tablespace_name
tablespace_location = env.tablespace_location
database_name = env.database_name
as_tuz = env.as_tuz //technical users
as_admins = env.as_admins //users which have administrative permission in system
hosts_list = env.hosts_list //list with hosts for hand run
segment = env.segment //network type
kms_host= env.kms_host //kms host
kms_login= env.kms_login //kms login
kms_password= env.kms_password //kms password
kms_cluster_id= env.kms_cluster_id //kms cluster_id
artifactId_for_nexus=env.artifactId_for_nexus
schema_name = env.schema_name
//for custom_dev
credentialsId_custom_dev=env.CREDENTIALSID_CUSTOM_DEV
branch_custom_dev=env.BRANCH_CUSTOM_DEV
git_url_custom_dev=env.GIT_URL_CUSTOM_DEV
path_custom_dev=env.PATH_CUSTOM_DEV

if (security_level.toLowerCase() == 'k1'){
  tde = true
  admin_protection = true
}else if (security_level.toLowerCase() == 'k2'){
  tde = true
  admin_protection = false
}else{
  tde = false
  admin_protection = false
}

//for ssh
ssh_user = env.ssh_user
ssh_password = env.ssh_password

//custome variables
install_type = tag.split('-')
splitted_version = version.split('-')
segment_type = segment.split('_')
list_of_variables = [version : version,
                     tag: tag,
                     port: port,
                     //tablespace_name: tablespace_name,
                     tablespace_location: tablespace_location,
                     //database_name: database_name,
                     as_admins: as_admins,
                     as_tuz: as_tuz,
                     stand: stand,
                     security_level: security_level,
                     critical_level: critical_level,
                     clustername: clustername,
                     ssh_user: ssh_user,
                     ssh_password: ssh_password,
                     kms_host: kms_host,
                     kms_login: kms_login,
                     kms_password: kms_password,
                     kms_cluster_id: kms_cluster_id,
                     segment: segment,
                     artifactId_for_nexus: artifactId_for_nexus,
                     schema_name: schema_name]

//nexus variables
switch(segment) {
  case ["sigma"]:
        nexusRestApiUrl = 'http://nexus.sigma.sbrf.ru:8099/nexus/service/local'
        nexusClassifier = "distrib"
        groupId = 'as_postgresql'
        artifactId = artifactId_for_nexus
        repoId = 'SBT_CI_distr_repo'
        nexusAddress = 'mirror.sigma.sbrf.ru'
        pip_repository = 'http://mirror.sigma.sbrf.ru/pypi/simple'
        break
  case ["sigma_archive"]:
        nexusRestApiUrl = 'http://nexus.sigma.sbrf.ru:8099/nexus/service/local'
        nexusClassifier = "distrib"
        groupId = 'as_postgresql.archive'
        artifactId = artifactId_for_nexus
        repoId = 'SBT_CI_distr_repo'
        nexusAddress = 'mirror.sigma.sbrf.ru'
        pip_repository = 'http://mirror.sigma.sbrf.ru/pypi/simple'
        break
  case ["alpha"]:
        nexusRestApiUrl = 'https://sbrf-nexus.ca.sbrf.ru/nexus/service/local'
        nexusClassifier = "distrib"
        groupId = 'Nexus_PROD'
        artifactId = 'CI02289206_PostgreSQL_Sber_Edition'
        repoId = 'Nexus_PROD'
        nexusAddress = 'mirror.ca.sbrf.ru'
        pip_repository = 'http://mirror.ca.sbrf.ru/pypi/simple'
        break
  case ["alpha_archive"]:
        nexusRestApiUrl = 'http://sbtnexus.ca.sbrf.ru:8081/nexus/service/local'
        nexusClassifier = "distrib"
        groupId = 'as_postgresql.archive'
        artifactId = artifactId_for_nexus
        repoId = 'SBT_CI_distr_repo'
        nexusAddress = 'mirror.ca.sbrf.ru'
        pip_repository = 'http://mirror.ca.sbrf.ru/pypi/simple'
        break
  case ["sbercloud"]:
        nexusRestApiUrl = 'https://dzo.sw.sbc.space/nexus-cd'
        nexusClassifier = "distrib"
        groupId = 'Nexus_PROD'
        artifactId = artifactId_for_nexus
        repoId = 'sbt_PROD_group'
        pip_repository = 'https://spo.solution.sbt/python/simple'
        nexusAddress = 'spo.solution.sbt'
        break
    case ["sbercloud_archive"]:
        nexusRestApiUrl = 'https://dzo.sw.sbc.space/nexus-ci'
        nexusClassifier = "distrib"
        groupId = 'ru/sbt/pangolin/archive'
        artifactId = artifactId_for_nexus
        repoId = 'sbt_maven'
        pip_repository = 'https://spo.solution.sbt/python/simple'
        nexusAddress = 'spo.solution.sbt'
        break
}

if (segment == 'sigma' || segment == 'sigma_archive'){
  if (env.JENKINS_URL.contains('sbt-jenkins.sigma.sbrf.ru')){
    devops_segment = 'CI'
  }else if (env.JENKINS_URL.contains('sbt-qa-jenkins.sigma.sbrf.ru')){
    devops_segment = 'CDL'
  }else if (env.JENKINS_URL.contains('nlb-jenkins-sigma-psi.sigma.sbrf.ru')) {
    devops_segment = 'CDP'
  }else if (env.JENKINS_URL.contains('nlb-jenkins-sigma.sigma.sbrf.ru')){
    devops_segment = 'PROD'
  }
} else if (segment == 'alpha' || segment == 'alpha_archive') {
    if (env.JENKINS_URL.contains('sbt-jenkins.ca.sbrf.ru')){
      devops_segment='CI'
    }else if (env.JENKINS_URL.contains('sbt-qa-jenkins.ca.sbrf.ru')){
    devops_segment = 'CDL'
  }else if (env.JENKINS_URL.contains('nlb-jenkins-psi.ca.sbrf.ru')) {
    devops_segment = 'CDP'
  }else if (env.JENKINS_URL.contains('nlb-jenkins.ca.sbrf.ru')){
    devops_segment = 'PROD'
  }
} else {
    if (env.JENKINS_URL.contains('dzo.sw.sbc.space/jenkins-ci')) {
        devops_segment = 'CI'
    } else if (env.JENKINS_URL.contains('dzo.sw.sbc.space/jenkins-cd')) {
        devops_segment = 'CDP'
    }
}

@NonCPS
def getNexusLink(nexusRestApiUrl, nexusArtifactId, nexusVersionId, nexusExtensionId, nexusRepositoryId, nexusGroupId, nexusClassifier, remoteUsername, remotePassword) {
    if ( segment == "sbercloud" || segment == "sbercloud_archive" ) {
      return "${nexusRestApiUrl}/repository/${nexusRepositoryId}/${nexusGroupId}/${nexusArtifactId}/${nexusVersionId}/${nexusArtifactId}-${nexusVersionId}-${nexusClassifier}.tar.gz"
    } else {
      def api = "${nexusRestApiUrl}/artifact/maven/redirect?r=${nexusRepositoryId}&g=${nexusGroupId}&a=${nexusArtifactId}&v=${nexusVersionId}&p=${nexusExtensionId}&c=${nexusClassifier}"
      def con = new URL(api).openConnection()
      println(con)
      con.requestMethod = 'HEAD'
      if (remoteUsername != null && remotePassword != null) {
          def authString = "${remoteUsername}:${remotePassword}".getBytes().encodeBase64().toString()
          con.setRequestProperty("Authorization", "Basic ${authString}")
      }
      con.setInstanceFollowRedirects(true)
      con.connect()
      def is = con.getInputStream()
      is.close()
      return con.getURL().toString()
    }
}

node(env.jenkinsAgentLabel){
  timestamps {
    ansiColor('xterm') {
                deleteDir()
                stage('Check jenkins variables'){
                      wrap([$class: 'MaskPasswordsBuildWrapper', varPasswordPairs: [[password: "${ssh_password}", var: 'PSWD']]]) {
                      list_of_variables.findAll { key, value ->
                        if ((value instanceof java.lang.String) && (value.length() != 0 ))  {
                            println('Correct. Variable ' + key + ' does not empty and equals: ' + value)
                        }else{
                          println('Error. Variable ' + key + ' is empty')
                          emailext (attachLog: true,
                              body: """<p>Job ${env.JOB_NAME} build ${env.BUILD_NUMBER} is FAILURE. <br>More info at ${env.BUILD_URL} or in mail attachment</br></p>""",
                              compressLog: true,
                              mimeType: 'text/html',
                              subject: "FAILURE: Segment: ${segment}, Stage: ${devops_segment}",
                              to: 'PMKraskin@sberbank.ru, Karpenko.An.Ser@sberbank.ru, Pekler.P.V@sberbank.ru, MAlBibik@sberbank.ru, RMuAminov@sberbank.ru, AAleverov@sberbank.ru'
                        )
                          autoCancelled = true
                          error("Abortion is build, because the variable from input Jenkins variables is empty")
                        }
                      }
                    }
                  }
                stage('Download distributive') {
                 withCredentials([[$class: 'UsernamePasswordMultiBinding', credentialsId: 'postgresql_nexus_cred', usernameVariable: 'remoteUsername', passwordVariable: 'remotePassword']])
                  {
                    url_to_distr = getNexusLink(nexusRestApiUrl, artifactId, version.toUpperCase(), "tar.gz", repoId, groupId, nexusClassifier, remoteUsername, remotePassword)
                    sh "wget -nv --no-check-certificate --user=${remoteUsername} --password=${remotePassword} ${url_to_distr}"
                    }
                }
                stage('Unarchive distributive'){
                  sh "mkdir distributive"
                  sh "find -iname \\*${version}-distrib.tar.gz -exec tar -xvf {} -C distributive \\;"
                }
                stage('Download custom_dev.yml')
                {
                  dir ("${env.WORKSPACE}/distributive/installer/group_vars/")
                  {
                    withCredentials([[$class: 'UsernamePasswordMultiBinding', credentialsId: credentialsId_custom_dev, usernameVariable: 'username_custom_dev', passwordVariable: 'password_custom_dev']])
                    {
                      url_to_custom_dev="${git_url_custom_dev}/raw/${path_custom_dev}?at=refs/heads/${branch_custom_dev}"
                      sh "curl -s -S -L --insecure --user ${username_custom_dev}:${password_custom_dev} ${url_to_custom_dev} -o custom_dev.yml"
                    }
                  }
                }
                stage('Install python libraries')
                {
                  sh """
                      virtualenv pg_se_venv --python=python2
                      source pg_se_venv/bin/activate
                      pip install --index-url='${pip_repository}' --trusted-host='${nexusAddress}' ansible==2.9.18
                      pip install --index-url='${pip_repository}' --trusted-host='${nexusAddress}' rpm==0.0.2
                      pip install --index-url='${pip_repository}' --trusted-host='${nexusAddress}' -r distributive/installer/files/slave.txt
                     """
                }
                stage ('Convert input data to yaml')
                {
                  dir ("${env.WORKSPACE}/distributive/installer/files/")
                  {
                    writeFile file: 'hosts', text: hosts_list
                    sh """
                        source ${env.WORKSPACE}/pg_se_venv/bin/activate
                        python json_to_yml.py ${install_type.first()}
                       """
                  }
                }
                stage ('Start job Generate_certs') {
                  build job: "${gen_certs_job}", parameters: [ string(name: 'hosts_list', value: hosts_list),
                  string(name: 'ssh_user', value: ssh_user), password(name: 'ssh_password', value: ssh_password) ]
                }
                stage('Run Ansible playbook for hand case')
                {
                  wrap([$class: 'MaskPasswordsBuildWrapper', varPasswordPairs: [[password: "${ssh_password}", var: 'PSWD']]])
                  {
                    encrypt_password = "${ssh_password}"
                    def distributive_path = "${env.WORKSPACE}" + '/distributive'
                    dir("${env.WORKSPACE}/distributive/installer/")
                    {
                      try
                      {
                        withCredentials([file(credentialsId: 'ansible_vault_file', variable: 'vault_pswd')])
                        {
                          ansible_exec_string = ' playbook.yaml' +
                                                ' -i inventories/' + install_type.first() + '/inventory.py' +
                                                ' -t always,' + tag +
                                                ' --ssh-extra-args=\'-o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null\'' +
                                                ' -e ansible_ssh_pass=' + encrypt_password +
                                                ' --vault-password-file=' + vault_pswd + ' ' +
                                                ansible_arguments + ' -u ' + ssh_user +
                                                ' -e \'{"as_admins":[' + as_admins + ']}\'' +
                                                ' -e \'{"as_TUZ":[' + as_tuz + ']}\'' +
                                                ' -e \'{"tde": ' + tde + '}\'' +
                                                ' -e \'{"admin_protection": ' + admin_protection + '}\'' +
                                                ' --extra-vars \"local_distr_path=' + distributive_path +
                                                              ' installation_type=' + install_type.first() +
                                                              ' version=' + splitted_version.last() +
                                                              ' PGPORT=' + port +
                                                              ' PGDATA=' + pgdata +
                                                              ' PGLOGS=' + pglogs +
                                                              ' KMS_HOST=' + kms_host +
                                                              ' KMS_LOGIN=' + kms_login +
                                                              ' KMS_PASSWORD=' + kms_password +
                                                              ' KMS_CLUSTER_ID=' + kms_cluster_id +
                                                              ' tablespace_name=' + tablespace_name +
                                                              ' tablespace_location=' + tablespace_location +
                                                              ' schema_name=' + schema_name +
                                                              ' tag=' + tag +
                                                              ' db_name=' + database_name +
                                                              ' clustername=' + clustername +
                                                              ' security_level=' + security_level +
                                                              ' critical_level=' + critical_level +
                                                              ' segment=' + segment_type.first() +
                                                              ' inner_install=yes' +
                                                              ' custom_config=group_vars/custom_dev.yml' +
                                                              ' stand=' + stand +'\"'
                          sh """
                              export ANSIBLE_FORCE_COLOR=true
                              source ${env.WORKSPACE}/pg_se_venv/bin/activate
                              chmod +x ${env.WORKSPACE}/pg_se_venv/bin/ansible-playbook
                              ansible-playbook ${ansible_exec_string}
                             """
                        }
                      }
                      catch(r)
                      {
                        println(r)
                        currentBuild.result = 'FAILURE'
                      }
                    }
                  }
                }
                }
            }
          }