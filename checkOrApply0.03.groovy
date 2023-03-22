node(env.NODE) {
    def gitUrl = scm.userRemoteConfigs[0].url
    def gitBranch = "${env.gitBranch}"
    gitBranch = gitBranch ? gitBranch : 'master'
    gitBranchNew = "${gitBranch}_temp"
//    def ocHome = tool(name: 'oc-4.5.0', type: 'oc')
    // def tfModules = "${env.Modules}"
    def tfModules = env.Modules.split(',') as List
    tfModules = tfModules ? tfModules : ["AWX","ELK_standalone1","KAFKA1","KAFKA_Corex_standalone","Kafka303","NginxG1","Nginx_IAG","Nginx_SGW","Nginx_iag","PGSE_standalone01","PGSE_standalone_test"]
    cleanWs()
    ansiColor('xterm') {
//        withEnv(["PATH+OC_HOME=${ocHome}", "OC_HOME=${ocHome}"]) {
//            echo "${ocHome}"
            sh('echo $PATH')
            sh('oc version --client')
            sh('kubectl version --client')

            withCredentials([
                    [$class: 'UsernamePasswordMultiBinding', credentialsId: 'auto_test', usernameVariable: 'GIT_NAME', passwordVariable: 'GIT_PASSWORD'],
                    [$class: 'UsernamePasswordMultiBinding', credentialsId: 'cloudDevOpsEFSPGterraform', usernameVariable: 'PG_NAME', passwordVariable: 'PG_PASSWORD'],
                    [$class: 'StringBinding', credentialsId: ' cloudDevOpsEFSAnsibleVaultPassword', variable: 'ANSIBLE_VAULT_PASSWORD']
            ]) {
                if (env.APPLY == 'true') {
                    withEnv(["TF_VAR_scm_username=${GIT_NAME}",
                        "TF_VAR_scm_password=${GIT_PASSWORD}",
                        "TF_VAR_scm_url=${gitUrl}",
                        "TF_VAR_scm_branch=${gitBranch}",
                        "TF_VAR_vault_password=${ANSIBLE_VAULT_PASSWORD}"]) {
                        echo "APPLY"
                        gitClone('auto_test', gitUrl, gitBranch)
                        if (env.Delete_after_deploy == 'false') {
                            // gitBranchNew = "${gitBranch}_temp"
                            println("gitBranchNew: $gitBranchNew")
                            // sh("set +x; git checkout -b origin/${gitBranchNew} origin/${gitBranch}")
                            gitCommit2('auto_test', gitUrl, gitBranchNew)
                        }
                        def error = 0
                        createSecretsYaml()
                        println("SIZE MODULES: ${tfModules.size()} - ${tfModules}")
                        if (tfModules.size() != 0) {
                            for (module in tfModules) {
                                println("======== Run module: ${module} ========")
                                if (error == 0) {
                                    sh("sed -i 's/count = 0/count = 1/g' main.tf")
                                    sh("set +x; ./terraform init -no-color -plugin-dir=./plugins")
                                    sh("set +x; ./terraform workspace new ${COLLECTIVE_TERRAFORM_WORKSPACE} -no-color || ./terraform workspace select ${COLLECTIVE_TERRAFORM_WORKSPACE}")
                                    def output = sh(script: "./terraform apply -var-file=ansible/values.tfvars -var=vault_password=${ANSIBLE_VAULT_PASSWORD} -target=module.${module} -auto-approve", returnStatus: true)
                                    if (env.Delete_after_deploy == 'false') {
                                        gitCommit2('auto_test', gitUrl, gitBranchNew, "Commit from module $module")
                                        // gitCommit('auto_test', gitUrl, "autotest_fix_temp","Commit")
                                    }
                                    error = output
                                    if (module != "AWX" && error != 1 && env.Delete_after_deploy.toBoolean()) {
                                        sh("set +x; ./terraform destroy -var-file=ansible/values.tfvars -var=vault_password=${ANSIBLE_VAULT_PASSWORD} -target=module.${module} -auto-approve")
                                    }
                                }
                            }
                        } else {
                              withCredentials([
                                      [$class: 'StringBinding', credentialsId: 'HashicorpVaultToken', variable: 'HASHICORP_VAULT_TOKEN']
                              ]) {
                                sh("set +x; ./terraform init -no-color -plugin-dir=./plugins")
                                sh("set +x; ./terraform workspace new ${COLLECTIVE_TERRAFORM_WORKSPACE} -no-color || ./terraform workspace select ${COLLECTIVE_TERRAFORM_WORKSPACE}")
                                def output = sh(script: "./terraform apply -var-file=ansible/values.tfvars -var=vault_password=${ANSIBLE_VAULT_PASSWORD} -var=hashicorp_vault_url=${env.HASHICORP_URL} -var=hashicorp_vault_token=${env.HASHICORP_VAULT_TOKEN} -auto-approve", returnStatus: true)
                                if (env.Delete_after_deploy == 'false') {
                                    gitCommit2('auto_test', gitUrl, gitBranchNew, "Commit from job running with settings main.tf")
                                }
                            }
                        }
                    }
                } else if (env.ATOMIC_DESTROY == 'true') {
                      echo "ATOMIC_DESTROY"
                      atomicDestroy(gitUrl)
                      // gitClone('auto_test', gitUrl, gitBranch)
                      gitDeleteBranch(gitUrl, gitBranchNew)
                } else if (env.BITBUCKET_PAYLOAD) {
                        echo "PAYLOAD"
                        payload = readJSON text: env.BITBUCKET_PAYLOAD
                        jobMode = payload.pullRequest.state
                        branch = env.BITBUCKET_SOURCE_BRANCH
                        prHref = payload.pullRequest.links.self[0].href
                        comment = ''
                        echo payload
                        echo prHref
                        echo gitUrl
                        if (jobMode == 'MERGED') {
                              apply(gitUrl)
                        } else {
                              plan(gitUrl)
                        }
                    } 
                }

            // }
    }
}



def gitClone(creds, url, branch) {
    checkout([$class    : 'GitSCM', branches: [[name: branch]],
              extensions: [], userRemoteConfigs: [[credentialsId: creds, url: url]]])
}

def gitDeleteBranch(url, repoBranch){
    def url_sensitive = url.replaceAll('https://', "https://${GIT_NAME}:${GIT_PASSWORD}@")
    def checkBranchExists = gitCommandHttp('git ls-remote --heads ', url, "", "| grep $repoBranch")
    if (checkBranchExists == 0) {
        sh("git remote add origin_sensitive ${url_sensitive}")
        sh("git push origin_sensitive --delete ${repoBranch}")
        sh("git remote remove origin_sensitive")
        echo "Delete branch: $repoBranch"
    } else {
        echo "Do nothing delete"
    }
}

def gitCommandHttp(cmd, url, repoBranch="", args="") {
    if (repoBranch == "" && args != ""){
        url = url.replaceAll('https://', "https://${GIT_NAME}:${GIT_PASSWORD}@")
    } else {
        url = url.replaceAll('https://', "https://${GIT_NAME}:${GIT_PASSWORD}@") //+ " HEAD:$repoBranch"
        repoBranch = " HEAD:$repoBranch"
    }
    def output = sh(script: "$cmd '$url' $repoBranch $args", returnStatus: true)
    return output
}


def gitCommit2(creds, url, repoBranch,  commitMessage = "Jenkins commit") {
    withCredentials([[$class: 'UsernamePasswordMultiBinding', credentialsId: creds, usernameVariable: 'GIT_NAME', passwordVariable: 'GIT_PASSWORD']]) {
        def checkBranchExists = gitCommandHttp('git ls-remote --heads ', url, "", "| grep $repoBranch")
        def url_sensitive = url.replaceAll('https://', "https://${GIT_NAME}:${GIT_PASSWORD}@")
        echo "checkBranchExists: ${checkBranchExists}"
        sh("git remote add origin_sensitive ${url_sensitive}")
        sh('git fetch origin_sensitive')
        sh('git config --global user.email "dummy@dummy.com"')
        sh('git config --global user.name "Jenkins"')
        sh('git config --global push.default current')
        sh('rm -rf vpass.txt')
        if (checkBranchExists == 0) {
            sh("set +x; git checkout origin_sensitive/${gitBranchNew}")
            sh("ls -la ansible/inventory")
            sh("git status")
            sh("git add -A .")
            sh("git commit -m \"${commitMessage}\" || echo 'Nothing to commit'")
            sh("git checkout .")
            gitCommandHttp('git pull --rebase ', url, repoBranch)
            gitCommandHttp('git push ', url, repoBranch)
        } else {
            sh("set +x; git checkout -b origin_sensitive/${gitBranchNew} origin_sensitive/${gitBranch}")
            gitCommandHttp('git push ', url, repoBranch)
        }
    }
    sh("git remote remove origin_sensitive")
}

def gitCommit(creds, url, repoBranch, commitMessage = "Jenkins apply job commit") {
    withCredentials([[$class: 'UsernamePasswordMultiBinding', credentialsId: creds, usernameVariable: 'GIT_NAME', passwordVariable: 'GIT_PASSWORD']]) {
        // if (env.BITBUCKET_PAYLOAD) {
            sh('rm -rf vpass.txt')
            sh('set +x; git config --global user.email "dummy@dummy.com"')
            sh('set +x; git config --global user.name "Jenkins"')
            sh("set +x; git add -A .")
            if (env.HASHICORP.toBoolean()){
                sh("set +x; git rm -f --ignore-unmatch ansible/secrets.yml")
            }
            sh("set +x; git reset HEAD ansible/ext-kafka")
            sh("set +x; git reset HEAD ansible/ext-pangolin")
            sh("set +x; git reset HEAD ansible/roles/nginx_iag/files")
            sh("set +x; git commit -m \"${commitMessage}\" || echo 'Nothing to commit'")
            sh("set +x; git checkout .")
            sh("set +x; git pull --rebase " + url.replaceAll('https://', "https://${GIT_NAME}:${GIT_PASSWORD}@") + " HEAD:$repoBranch")
            sh("set +x; git push " + url.replaceAll('https://', "https://${GIT_NAME}:${GIT_PASSWORD}@") + " HEAD:$repoBranch")
        // }
    }
}

def createSecretsYaml() {
  try {
      withCredentials([
              [$class: 'StringBinding', credentialsId: 'HashicorpVaultToken', variable: 'HASHICORP_VAULT_TOKEN']
      ]) {
          def secrets = new File("ansible/secrets.yml")
          if (env.HASHICORP.toBoolean() == true || !secrets.exists()) {
              if (env.HASHICORP_URL && env.HASHICORP_PATH && HASHICORP_VAULT_TOKEN) {
                  sh "echo Run with Hashicorp Vault"
                  sh "python secman_yaml.py --url ${env.HASHICORP_URL} --path ${env.HASHICORP_PATH} --token ${HASHICORP_VAULT_TOKEN} --output_file ansible/secrets.yml"
                  sh "echo ${ANSIBLE_VAULT_PASSWORD} > vpass.txt && ansible-vault encrypt --vault-id @vpass.txt ansible/secrets.yml"
              } else {
                  sh("echo Hashicorp not available")
              }
          }
      }
    } catch (e) {
      error("Hashicorp error")  
    }
}

def plan(gitUrl) {
    withEnv(["TF_VAR_scm_username=${GIT_NAME}",
          "TF_VAR_scm_password=${GIT_PASSWORD}",
          "TF_VAR_scm_url=${gitUrl}",
          "TF_VAR_scm_branch=${branch}",
          "TF_VAR_vault_password=${ANSIBLE_VAULT_PASSWORD}"]) {
        gitClone('auto_test', gitUrl, branch)
        createSecretsYaml()
        echo "Запуск по событию. PR - ${jobMode}"
        sh("git merge -s ours origin/${gitBranch} --no-edit")
        try {
            sh("set +x; ./terraform init -no-color -plugin-dir=./plugins")
            sh("set +x; ./terraform workspace new ${env.COLLECTIVE_TERRAFORM_WORKSPACE} -no-color || ./terraform workspace select ${env.COLLECTIVE_TERRAFORM_WORKSPACE} -no-color")
            sh("set +x; ./terraform plan -no-color -var-file=ansible/values.tfvars -var=\"vault_password=${ANSIBLE_VAULT_PASSWORD}\" > plan")
            sh("set +x; cat plan | sed 's/\"//g' | sed 's/#//g' | sed 's/  //g' > form_plan; rm -f plan")
        } catch (e) {
            comment = ["text": "Ошибка при проверке PR, ссылка на билд: ${env.BUILD_URL}"]
            writeJSON file: 'comment.json', json: comment
            sh("set +x; curl --request POST --url ${prHref}/comments --header 'Accept: application/json' --header 'Content-Type: application/json' -u ${GIT_NAME}:${GIT_PASSWORD} -d @comment.json")
            sh("set +x; curl -X PUT --url ${prHref}/participants/${GIT_NAME} -H 'Content-Type: application/json' -H 'Accept:application/json' -u ${GIT_NAME}:${GIT_PASSWORD} -d '{\"user\":{\"name\":\"${GIT_NAME}\"},\"approved\":false,\"status\":\"NEEDS_WORK\"}'")
            error("Plan error")
        }


        //def rawComment = "### Текущие учитываемые объекты\n\n" + currentObjects + "### Объекты будут заменены\n\n" + replacedObjects + "### Создаваемые объекты\n\n" + createdObjects + "### Удаляемые объекты\n\n" + destroyedObjects
        //echo "${replacedObjects}"
        //echo "${currentObjects}"
        //echo "${createdObjects}"
        //echo "${rawComment}"
        def currentObjects = sh(script: "set +x; cat form_plan | grep 'Refreshing state' || true", returnStdout: true)
        currentObjects = currentObjects ? "### Текущие учитываемые объекты\n\n${currentObjects}" : ''
        def replacedObjects = sh(script: "set +x; cat form_plan | grep 'be replaced' | grep -v 'null_resource.vault_file' | grep -v 'local_file.*-inventory' || true", returnStdout: true)
        replacedObjects = replacedObjects ? "### Объекты будут заменены\n\n${replacedObjects}" : ''
        def ansibleProjectApplyObjects = sh(script: "set +x; cat form_plan | grep 'null_resource.vault_file.*be replaced\\|null_resource.vault_file.*be created' || true", returnStdout: true)
        ansibleProjectApplyObjects = ansibleProjectApplyObjects ? "### Применение параметров к проекту\n\n${ansibleProjectApplyObjects}" : ''
        def ansibleSPOApplyObjects = sh(script: "set +x; cat form_plan | grep 'local_file.*-inventory.*be replaced\\|local_file.*-inventory.*be created' || true", returnStdout: true)
        ansibleSPOApplyObjects = ansibleSPOApplyObjects ? "### Конфигурация/Применение параметров к серверам\n\n${ansibleSPOApplyObjects}" : ''
        def createdObjects = sh(script: "set +x; cat form_plan | grep 'be created' | grep -v 'null_resource.vault_file' | grep -v 'local_file.*-inventory' || true", returnStdout: true)
        createdObjects = createdObjects ? "### Создаваемые объекты\n\n${createdObjects}" : ''
        def destroyedObjects = sh(script: "set +x; cat form_plan | grep 'be destroyed' || true ", returnStdout: true)
        destroyedObjects = destroyedObjects ? "### Удаляемые объекты\n\n${destroyedObjects}" : ''
        def rawComment = createdObjects + ansibleProjectApplyObjects + ansibleSPOApplyObjects + replacedObjects + destroyedObjects + currentObjects
        comment = ["text": rawComment]
        writeJSON file: 'comment.json', json: comment
        sh("set +x; curl -X POST --url ${prHref}/comments --header 'Accept: application/json' --header 'Content-Type: application/json' -u ${GIT_NAME}:${GIT_PASSWORD} -d @comment.json")
        sh("set +x; curl -X PUT --url ${prHref}/participants/${GIT_NAME} -H 'Content-Type: application/json' -H 'Accept:application/json' -u ${GIT_NAME}:${GIT_PASSWORD} -d '{\"user\":{\"name\":\"${GIT_NAME}\"},\"approved\":true,\"status\":\"APPROVED\"}'")
    }

}

def apply(gitUrl) {
    withEnv(["TF_VAR_scm_username=${GIT_NAME}",
          "TF_VAR_scm_password=${GIT_PASSWORD}",
          "TF_VAR_scm_url=${gitUrl}",
          "TF_VAR_scm_branch=${gitBranch}",
          "TF_VAR_vault_password=${ANSIBLE_VAULT_PASSWORD}"]) {
        gitClone('auto_test', gitUrl, "${gitBranch}")
        createSecretsYaml()
        echo "Запуск по событию. PR - ${jobMode}"

        comment = ["text": "Применение конфигурации, ссылка на билд: ${env.BUILD_URL}"]
        writeJSON file: 'comment.json', json: comment
        sh("set +x; curl --request POST --url ${prHref}/comments --header 'Accept: application/json' --header 'Content-Type: application/json' -u ${GIT_NAME}:${GIT_PASSWORD} -d @comment.json")

        try {
            sh("set +x; ./terraform init -no-color -plugin-dir=./plugins")
            sh("set +x; ./terraform workspace new ${env.COLLECTIVE_TERRAFORM_WORKSPACE} -no-color || ./terraform workspace select ${env.COLLECTIVE_TERRAFORM_WORKSPACE} -no-color")
            sh("set +x; ./terraform apply -no-color -var-file=ansible/values.tfvars -var=\"vault_password=${ANSIBLE_VAULT_PASSWORD}\" -auto-approve")
            sh("set +x; rm -rf .terraform* comment.json ansible/*_kubeconfig")
            sh("set +x; find . -name '*.pyc' -delete")

        } catch (e) {
            sh("set +x; rm -rf .terraform* comment.json ansible/*_kubeconfig")
            sh("set +x; find . -name '*.pyc' -delete")
            gitCommit('auto_test', gitUrl, "${gitBranch}", "Ошибка при применении конфигурации")
            comment = ["text": "Ошибка при применении конфигурации, после мержа PR, ссылка на билд: ${env.BUILD_URL}"]
            writeJSON file: 'comment.json', json: comment
            sh("set +x; curl --request POST --url ${prHref}/comments --header 'Accept: application/json' --header 'Content-Type: application/json' -u ${GIT_NAME}:${GIT_PASSWORD} -d @comment.json")
            error("Apply error")
        }
        gitCommit('auto_test', gitUrl, "${gitBranch}", "Применение конфигурации прошло успешно")

        comment = ["text": "Применение конфигурации, после мержа PR прошло успешно, ссылка на билд: ${env.BUILD_URL}"]
        writeJSON file: 'comment.json', json: comment
        sh("set +x; curl -X POST --url ${prHref}/comments --header 'Accept: application/json' -H 'Content-Type: application/json' -u ${GIT_NAME}:${GIT_PASSWORD} -d @comment.json")
    }

}

def atomicDestroy(gitUrl) {
    withEnv(["TF_VAR_scm_username=${GIT_NAME}",
                  "TF_VAR_scm_password=${GIT_PASSWORD}",
                  "TF_VAR_scm_url=${gitUrl}",
                  "TF_VAR_scm_branch=${gitBranch}",
                  "TF_VAR_vault_password=${ANSIBLE_VAULT_PASSWORD}"]) {
        gitClone('auto_test', gitUrl, "${gitBranch}")
        createSecretsYaml()
        echo "Применение конфигурации без события"
        try {
            sh("set +x; ./terraform init -no-color -plugin-dir=./plugins")
            sh("set +x; ./terraform workspace new ${env.COLLECTIVE_TERRAFORM_WORKSPACE} -no-color || ./terraform workspace select ${env.COLLECTIVE_TERRAFORM_WORKSPACE} -no-color")
            sh("set +x; ./terraform destroy -no-color -var-file=ansible/values.tfvars -var=\"vault_password=${ANSIBLE_VAULT_PASSWORD}\" -auto-approve")
            sh("set +x; rm -rf .terraform* ansible/*_kubeconfig")
            sh("set +x; find . -name '*.pyc' -delete")
            gitCommit('auto_test', gitUrl, "${gitBranch}","Удаление всех ресурсов прошло успешно")
        } catch (e) {
            sh("set +x; rm -rf .terraform* comment.json ansible/*_kubeconfig")
            sh("set +x; find . -name '*.pyc' -delete")
            gitCommit('auto_test', gitUrl, "${gitBranch}", "Ошибка при применении конфигурации")
            error("Destroy error")
        }
    } 
}










