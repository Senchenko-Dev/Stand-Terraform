switch(segment) {
  case ["sigma"]:
        stash = 'ssh://git@10.21.25.60:8878/pgsql/installer.git'
        sbrf = 'ssh://git@sbrf-bitbucket.sigma.sbrf.ru:7999/ci02474762/ci02289206_pgsql.git'
        break
  case ["alpha"]:
        stash = 'ssh://git@stash.delta.sbrf.ru:7999/pgsql/installer.git'
        sbrf = 'ssh://git@sbrf-bitbucket.ca.sbrf.ru:7999/ci02474762/ci02289206_pgsql.git'
        break
}

node('masterLin'){ 
  timestamps {
                deleteDir()
                stage('Get sources from stash repository') {
                    deleteDir()
                    checkout([$class                           : 'GitSCM', branches: [[name: 'develop']],
                              doGenerateSubmoduleConfigurations: false,
                              extensions                       : [],
                              submoduleCfg                     : [],
                              userRemoteConfigs                : [[credentialsId: 'postgresql_git', url: stash]]])
                }
                stage ('Added new remote repository and push'){
                      dir ("${env.WORKSPACE}/installer"){
                        sshagent (credentials: ['postgresql_git']) {
                            def strings_with_brances = sh (
                              script: "git branch -r | grep 'develop' | cut -d '/' -f 2,3",
                              returnStdout: true).trim()
                            def develop_branches =  strings_with_brances.readLines()
                            sh "git remote add sbrf_installer ${sbrf}"
                            for (item in develop_branches){
                                sh "git checkout ${item}"
                                sh "git push -f sbrf_installer ${item}"
                            }
                        }
                      }
                    }
                  }
                }