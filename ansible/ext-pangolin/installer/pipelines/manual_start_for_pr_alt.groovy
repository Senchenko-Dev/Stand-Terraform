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
artifactId_for_nexus=env.artifactId_for_nexus
schema_name = env.schema_name
custom_config = env.custom_config // path to custom config

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
                     segment: segment,
                     artifactId_for_nexus: artifactId_for_nexus]

//nexus variables
switch(segment) {
  case ["sigma"]:
        nexusRestApiUrl = 'https://sbrf-nexus.sigma.sbrf.ru/nexus/service/local'
        nexusClassifier = "distrib"
        groupId = 'Nexus_PROD'
        artifactId = 'CI02289206_PostgreSQL_Sber_Edition'
        repoId = 'Nexus_PROD'
        nexusAddress = 'mirror.sigma.sbrf.ru'
        pip_repository = 'http://mirror.sigma.sbrf.ru/pypi/simple'
        break
  case ["sigma_installer"]:
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
}

if (segment == 'sigma' || segment == 'sigma_archive'){
  if (env.JENKINS_URL.contains('sbt-jenkins.sigma.sbrf.ru')){
    devops_segment = 'CI'
  }else if (env.JENKINS_URL.contains('sbt-qa-jenkins.sigma.sbrf.ru')){
    devops_segment = 'CDL'
  }else if (env.JENKINS_URL.contains('nlb-jenkins-sigma-psi.sigma.sbrf.ru')){
    devops_segment = 'CDP'
  }else if (env.JENKINS_URL.contains('nlb-jenkins-sigma.sigma.sbrf.ru')){
    devops_segment = 'PROD'
  }
}else if (segment == 'sigma_installer'){
  if (env.JENKINS_URL.contains('sbt-jenkins.sigma.sbrf.ru')){
    devops_segment = 'PR_CI'
  }else if (env.JENKINS_URL.contains('sbt-qa-jenkins.sigma.sbrf.ru')){
    devops_segment = 'PR_CDL'
  }else if (env.JENKINS_URL.contains('nlb-jenkins-sigma-psi.sigma.sbrf.ru')){
    devops_segment = 'PR_CDP'
  }else if (env.JENKINS_URL.contains('nlb-jenkins-sigma.sigma.sbrf.ru')){
    devops_segment = 'PR_PROD'
  }
}else{
    if (env.JENKINS_URL.contains('sbt-jenkins.ca.sbrf.ru')){
      devops_segment='CI'
    }else if (env.JENKINS_URL.contains('sbt-qa-jenkins.ca.sbrf.ru')){
    devops_segment = 'CDL'
  }else if (env.JENKINS_URL.contains('nlb-jenkins-psi.ca.sbrf.ru')){
    devops_segment = 'CDP'
  }else if (env.JENKINS_URL.contains('nlb-jenkins.ca.sbrf.ru')){
    devops_segment = 'PROD'
  }
}

@NonCPS
def getNexusLink(nexusRestApiUrl, nexusArtifactId, nexusVersionId, nexusExtensionId, nexusRepositoryId, nexusGroupId, nexusClassifier, remoteUsername, remotePassword)
{
  def api = "${nexusRestApiUrl}/artifact/maven/redirect?r=${nexusRepositoryId}&g=${nexusGroupId}&a=${nexusArtifactId}&v=${nexusVersionId}&p=${nexusExtensionId}&c=${nexusClassifier}"
  def con = new URL(api).openConnection()
  println(con)
  con.requestMethod = 'HEAD'
  if (remoteUsername != null && remotePassword != null)
  {
    def authString = "${remoteUsername}:${remotePassword}".getBytes().encodeBase64().toString()
    con.setRequestProperty("Authorization", "Basic ${authString}")
  }
  con.setInstanceFollowRedirects(true)
  con.connect()
  def is = con.getInputStream()
  is.close()
  con.getURL().toString()
}

node('masterLin'){
  timestamps {
    ansiColor('xterm') {
                  deleteDir()
                  stage('Check jenkins variables'){
                    wrap([$class: 'MaskPasswordsBuildWrapper', varPasswordPairs: [[password: "${ssh_password}", var: 'PSWD']]]) {
                      list_of_variables.findAll { key, value ->
                        if ((value instanceof java.lang.String) && (value.length() != 0 ))
                        {
                            println('Correct. Variable ' + key + ' does not empty and equals: ' + value)
                        }
                        else
                        {
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
                      sh "wget --user=${remoteUsername} --password=${remotePassword} ${url_to_distr}"
                    }
                  }
                  stage('Unarchive distributive'){
                    sh "mkdir distributive"
                    sh "find -iname \\*${version}-distrib.tar.gz -exec tar -xvf {} -C distributive \\;"
                  }
                  stage ('Change installer') {
                    sh "rm -rf ${env.WORKSPACE}/distributive/installer"
                    sh "mkdir ${env.WORKSPACE}/distributive/installer"
                    dir("${env.WORKSPACE}/distributive/installer")
                    {
                      def scmVars = checkout scm
                      def branchName = scmVars.GIT_BRANCH
                      def commitName = scmVars.GIT_COMMIT
                      println "branchName: ${branchName}"
                      println "git commit: ${commitName}"
                    }
                  }
                  stage('Install python libraries')
                {
                  sh """
                      virtualenv pg_se_venv --python=python3
                      source pg_se_venv/bin/activate
                      pip install --index-url='${pip_repository}' --trusted-host='${nexusAddress}' ansible==2.9.25
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
                stage ('Start job Clearing_servers') {
                  build job: 'Clearing_servers'
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
                                                              ' manual_run=yes' +
                                                              ' inner_install=yes' +
                                                              ' custom_config=' + custom_config +
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