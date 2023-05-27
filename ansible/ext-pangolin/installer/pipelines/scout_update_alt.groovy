//variables from jenkins
version = env.version //version of PostgreSQL SE
ansible_arguments = env.ansible_arguments
stand = env.environment // type of stand
hosts_list = env.hosts_list //list with hosts for hand run
segment = env.segment //network type
action_type = env.action_type
custom_config = env.custom_config // path to custom config

//for ssh
ssh_user = env.ssh_user
ssh_password = env.ssh_password

//custome variables
splitted_version = version.split('-')
segment_type = segment.split('_')
switch(hosts_list.split(" ").length)
{
  case [1]:
        installation_type = "standalone"
        break
  case [3]:
        installation_type = "cluster"
        break
}

//recipient string
delivery_team = env.list_emails

//nexus variables
switch(segment)
{
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
}

if (segment == 'sigma_installer' || segment == 'sigma_archive')
{
  if (env.JENKINS_URL.contains('sbt-jenkins.sigma.sbrf.ru'))
  {
    devops_segment = 'CI'
  }
  else if (env.JENKINS_URL.contains('sbt-qa-jenkins.sigma.sbrf.ru'))
  {
    devops_segment = 'CDL'
  }
  else if (env.JENKINS_URL.contains('nlb-jenkins-sigma-psi.sigma.sbrf.ru'))
  {
    devops_segment = 'CDP'
  }
  else if (env.JENKINS_URL.contains('nlb-jenkins-sigma.sigma.sbrf.ru'))
  {
    devops_segment = 'PROD'
  }
}
else
{
  if (env.JENKINS_URL.contains('sbt-jenkins.ca.sbrf.ru'))
  {
    devops_segment='CI'
  }
  else if (env.JENKINS_URL.contains('sbt-qa-jenkins.ca.sbrf.ru'))
  {
    devops_segment = 'CDL'
  }
  else if (env.JENKINS_URL.contains('nlb-jenkins-psi.ca.sbrf.ru'))
  {
    devops_segment = 'CDP'
  }
  else if (env.JENKINS_URL.contains('nlb-jenkins.ca.sbrf.ru'))
  {
    devops_segment = 'PROD'
  }
}

@NonCPS
def getNexusLink(nexusRestApiUrl, nexusArtifactId, nexusVersionId, nexusExtensionId, nexusRepositoryId, nexusGroupId, nexusClassifier, remoteUsername, remotePassword) {
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
    con.getURL().toString()
}

node('masterLin')
{
  timestamps
  {
    ansiColor('xterm')
    {
        deleteDir()
        stage('Download distributive')
        {
          withCredentials([[$class: 'UsernamePasswordMultiBinding', credentialsId: 'postgresql_nexus_cred', usernameVariable: 'remoteUsername', passwordVariable: 'remotePassword']])
          {
            url_to_distr = getNexusLink(nexusRestApiUrl, artifactId, version.toUpperCase(), "tar.gz", repoId, groupId, nexusClassifier, remoteUsername, remotePassword)
            sh "wget --user=${remoteUsername} --password=${remotePassword} ${url_to_distr}"
          }
        }
        stage('Unarchive distributive')
        {
          sh "mkdir distributive"
          sh "find -iname \\*${version}-distrib.tar.gz -exec tar -xvf {} -C distributive \\;"
        }
        stage ('Change installer') {
            sh "rm -rf ${env.WORKSPACE}/distributive/installer"
            sh "mkdir ${env.WORKSPACE}/distributive/installer"
            dir("${env.WORKSPACE}/distributive/installer")
            {
              def scmVars = checkout scm
              def branchName = env.BRANCH
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
                python json_to_yml.py ${installation_type}
               """
          }
        }
        stage('Run Ansible playbook for scout')
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
                  ansible_exec_string = ' playbook_scouting.yaml' +
                                        ' -i inventories/' + installation_type + '/inventory.py' +
                                        ' -t always,' + installation_type +
                                        ' --ssh-extra-args=\'-o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null\'' +
                                        ' -e ansible_ssh_pass=' + encrypt_password +
                                        ' --vault-password-file=' + vault_pswd + ' ' +
                                        ansible_arguments + ' -u ' + ssh_user +
                                        ' --extra-vars \"local_distr_path=' + distributive_path +
                                                      ' segment=' + segment_type.first() +
                                                      ' action_type=' + action_type +
                                                      ' custom_config=' + custom_config +
                                                      ' stand=' + stand +'\"'
                  sh """
                      export ANSIBLE_FORCE_COLOR=true
                      source ${env.WORKSPACE}/pg_se_venv/bin/activate
                      chmod +x ${env.WORKSPACE}/pg_se_venv/bin/ansible-playbook
                      ansible-playbook ${ansible_exec_string}
                     """
                }
                println('Scouting completed')
              }
              catch(r)
              {
                println('Scouting failed')
                println(r)
                currentBuild.result = 'FAILURE'
              }
            }
          }
        }
        stage('Run Ansible playbook for update')
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
                  ansible_exec_string = ' playbook_minor_update.yaml' +
                                        ' -i inventories/' + installation_type + '/inventory.py' +
                                        ' -t always,' + installation_type +
                                        ' --ssh-extra-args=\'-o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null\'' +
                                        ' -e ansible_ssh_pass=' + encrypt_password +
                                        ' --vault-password-file=' + vault_pswd + ' ' +
                                        ansible_arguments + ' -u ' + ssh_user +
                                        ' --extra-vars \"local_distr_path=' + distributive_path +
                                                      ' segment=' + segment_type.first() +
                                                      ' manual_run=yes' +
                                                      ' action_type=' + action_type +
                                                      ' custom_config=' + custom_config +
                                                      ' stand=' + stand +'\"'
                  sh """
                      export ANSIBLE_FORCE_COLOR=true
                      source ${env.WORKSPACE}/pg_se_venv/bin/activate
                      ansible-playbook ${ansible_exec_string}
                     """
                }
                println('Update completed')
              }
              catch(r)
              {
                println('Update failed')
                println(r)
                currentBuild.result = 'FAILURE'
              }
            }
          }
        }
      }
  }
}