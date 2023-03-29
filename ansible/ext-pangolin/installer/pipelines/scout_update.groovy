//variables from jenkins
version = env.version //version of PostgreSQL SE
ansible_arguments = env.ansible_arguments
stand = env.environment // type of stand
hosts_list = env.hosts_list //list with hosts for hand run
segment = env.segment //network type
action_type = env.action_type
action_type_playbook = env.action_type_playbook
update_complexity_level = env.update_complexity_level
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

//nexus variables
switch(segment) {
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
        nexusRestApiUrl = env.NexusRestApiUrl
        nexusClassifier = "distrib"
        groupId = env.GroupId
        artifactId = env.ArtifactId_for_nexus
        repoId = env.RepoId
        pip_repository = env.Pip_repository
        nexusAddress = env.NexusAddress
        break
  case ["sbercloud_installer"]:
        nexusRestApiUrl = env.NexusRestApiUrl
        nexusClassifier = "distrib"
        groupId = env.GroupId
        artifactId = env.ArtifactId_for_nexus
        repoId = env.RepoId
        pip_repository = env.Pip_repository
        nexusAddress = env.NexusAddress
        break
}

@NonCPS
def getNexusLink(nexusRestApiUrl, nexusArtifactId, nexusVersionId, nexusExtensionId, nexusRepositoryId, nexusGroupId, nexusClassifier, remoteUsername, remotePassword) {
    if ( segment == "sbercloud" || segment == "sbercloud_archive" || segment == "sbercloud_installer") {
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

node(env.jenkinsAgentLabel)
{
  timestamps
  {
    ansiColor('xterm')
    {
        deleteDir()
        wrap([$class: 'BuildUser']) {
            try {
                safeBuildUser = BUILD_USER
            } catch (e) {
                echo "User not in scope, probably triggered from another job"
            }
        }
        currentBuild.description = "Запустил: ${safeBuildUser}<br>IP: ${env.hosts_list}<br>${env.BRANCH.split('/').last()}"
        stage('Download distributive')
        {
          withCredentials([[$class: 'UsernamePasswordMultiBinding', credentialsId: 'postgresql_nexus_cred', usernameVariable: 'remoteUsername', passwordVariable: 'remotePassword']])
          {
            url_to_distr = getNexusLink(nexusRestApiUrl, artifactId, version.toUpperCase(), "tar.gz", repoId, groupId, nexusClassifier, remoteUsername, remotePassword)
            sh "wget -nv --no-check-certificate --user=${remoteUsername} --password=${remotePassword} ${url_to_distr}"
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
                error ">>> Scouting failed <<<"
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
                  ansible_exec_string = ' playbook_updates.yaml' +
                                        ' -i inventories/' + installation_type + '/inventory.py' +
                                        ' -t always,' + installation_type +
                                        ' --ssh-extra-args=\'-o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null\'' +
                                        ' -e ansible_ssh_pass=' + encrypt_password +
                                        ' --vault-password-file=' + vault_pswd + ' ' +
                                        ansible_arguments + ' -u ' + ssh_user +
                                        ' --extra-vars \"local_distr_path=' + distributive_path +
                                                      ' segment=' + segment_type.first() +
                                                      ' update_complexity_level=' + update_complexity_level +
                                                      ' custom_config=' + custom_config +
                                                      ' stand=' + stand +'\"'
                  sh """
                      export ANSIBLE_FORCE_COLOR=true
                      source ${env.WORKSPACE}/pg_se_venv/bin/activate
                      chmod +x ${env.WORKSPACE}/pg_se_venv/bin/ansible-playbook
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