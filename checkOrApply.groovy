
node(env.NODE) {
    def gitUrl = scm.userRemoteConfigs[0].url
//    def ocHome = tool(name: 'oc-4.5.0', type: 'oc')

    removeSecrets = false
    hashicorp = true
    HASHICORP_URL = 'http://10.33.8.239:8200'
    HASICORP_PATH = '/v1/DEV/PILP/R4/KV'

    cleanWs()
    ansiColor('xterm') {
//        withEnv(["PATH+OC_HOME=${ocHome}", "OC_HOME=${ocHome}"]) {
//            echo "${ocHome}"
            sh('echo $PATH')
            sh('oc version --client')
            sh('kubectl version --client')
//            sh('./terraform version')



            withCredentials([
                    [$class: 'UsernamePasswordMultiBinding', credentialsId: 'auto_test', usernameVariable: 'GIT_NAME', passwordVariable: 'GIT_PASSWORD'],
                    [$class: 'UsernamePasswordMultiBinding', credentialsId: 'cloudDevOpsEFSPGterraform', usernameVariable: 'PG_NAME', passwordVariable: 'PG_PASSWORD'],
                    [$class: 'StringBinding', credentialsId: ' cloudDevOpsEFSAnsibleVaultPassword', variable: 'ANSIBLE_VAULT_PASSWORD']
            ]) {
                if (env.BITBUCKET_PAYLOAD) {
                    def payload = readJSON text: env.BITBUCKET_PAYLOAD
                    def jobMode = payload.pullRequest.state
                    def branch = env.BITBUCKET_SOURCE_BRANCH
                    def prHref = payload.pullRequest.links.self[0].href
                    def comment = ''
                    
                    if (jobMode == 'MERGED') {
                        withEnv(["TF_VAR_scm_username=${GIT_NAME}",
                              "TF_VAR_scm_password=${GIT_PASSWORD}",
                              "TF_VAR_scm_url=${gitUrl}",
                              "TF_VAR_scm_branch=master",
                              "TF_VAR_vault_password=${ANSIBLE_VAULT_PASSWORD}"]) {
                            //gitClone('auto_test', gitUrl, branch)
                            gitClone('auto_test', gitUrl, 'master')
                            getCred()
                            echo "Запуск по событию. PR - ${jobMode}"

                            comment = ["text": "Применение конфигурации, ссылка на билд: ${env.BUILD_URL}"]
                            writeJSON file: 'comment.json', json: comment
                            sh("set +x; curl --request POST --url ${prHref}/comments --header 'Accept: application/json' --header 'Content-Type: application/json' -u ${GIT_NAME}:${GIT_PASSWORD} -d @comment.json")

                            try {
                                sh("set +x; ./terraform init -no-color -plugin-dir=./plugins -backend-config=\"conn_str=postgres://${PG_NAME}:${PG_PASSWORD}@${env.TERRAFORM_PG_REMOTE_CONN_STR}\"")
                                sh("set +x; ./terraform workspace new ${env.COLLECTIVE_TERRAFORM_WORKSPACE} -no-color || ./terraform workspace select ${env.COLLECTIVE_TERRAFORM_WORKSPACE} -no-color")
                                sh("set +x; ./terraform apply -no-color -var-file=ansible/values.tfvars -var=\"vault_password=${ANSIBLE_VAULT_PASSWORD}\" -auto-approve")
                                sh("set +x; rm -rf .terraform* comment.json ansible/*_kubeconfig")
                                sh("set +x; find . -name '*.pyc' -delete")

                            } catch (e) {
                                sh("set +x; rm -rf .terraform* comment.json ansible/*_kubeconfig")
                                sh("set +x; find . -name '*.pyc' -delete")
                                gitCommit('auto_test', gitUrl, 'master', "Ошибка при применении конфигурации")
                                comment = ["text": "Ошибка при применении конфигурации, после мержа PR, ссылка на билд: ${env.BUILD_URL}"]
                                writeJSON file: 'comment.json', json: comment
                                sh("set +x; curl --request POST --url ${prHref}/comments --header 'Accept: application/json' --header 'Content-Type: application/json' -u ${GIT_NAME}:${GIT_PASSWORD} -d @comment.json")
                                error("Apply error")
                            }
                            gitCommit('auto_test', gitUrl, 'master', "Применение конфигурации прошло успешно")

                            comment = ["text": "Применение конфигурации, после мержа PR прошло успешно, ссылка на билд: ${env.BUILD_URL}"]
                            writeJSON file: 'comment.json', json: comment
                            sh("set +x; curl -X POST --url ${prHref}/comments --header 'Accept: application/json' -H 'Content-Type: application/json' -u ${GIT_NAME}:${GIT_PASSWORD} -d @comment.json")
                        }
                    } else {
                        withEnv(["TF_VAR_scm_username=${GIT_NAME}",
                              "TF_VAR_scm_password=${GIT_PASSWORD}",
                              "TF_VAR_scm_url=${gitUrl}",
                              "TF_VAR_scm_branch=${branch}",
                              "TF_VAR_vault_password=${ANSIBLE_VAULT_PASSWORD}"]) {
                            gitClone('auto_test', gitUrl, branch)
                            getCred()
                            echo "Запуск по событию. PR - ${jobMode}"
                            if (hashicorp) {
                                sh("rm -rf ansible/secrets.yml")
                            }
                            sh("git merge origin/master --no-edit")
                            try {
                                sh("set +x; ./terraform init -no-color -plugin-dir=./plugins -backend-config=\"conn_str=postgres://${PG_NAME}:${PG_PASSWORD}@${env.TERRAFORM_PG_REMOTE_CONN_STR}\"")
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
                } else {
                    withEnv(["TF_VAR_scm_username=${GIT_NAME}",
                                  "TF_VAR_scm_password=${GIT_PASSWORD}",
                                  "TF_VAR_scm_url=${gitUrl}",
                                  "TF_VAR_scm_branch=master",
                                  "TF_VAR_vault_password=${ANSIBLE_VAULT_PASSWORD}"]) {
                        gitClone('auto_test', gitUrl, 'master')
                        getCred()
                        echo "Применение конфигурации без события"
                        try {
                            sh("set +x; ./terraform init -no-color -plugin-dir=./plugins -backend-config=\"conn_str=postgres://${PG_NAME}:${PG_PASSWORD}@${env.TERRAFORM_PG_REMOTE_CONN_STR}\"")
                            sh("set +x; ./terraform workspace new ${env.COLLECTIVE_TERRAFORM_WORKSPACE} -no-color || ./terraform workspace select ${env.COLLECTIVE_TERRAFORM_WORKSPACE} -no-color")
                            //sh("set +x; terraform apply -no-color -var-file=ansible/values.tfvars -var=\"vault_password=${ANSIBLE_VAULT_PASSWORD}\" -var=\"nexususer=${GIT_NAME}\" -var=\"nexuspass=${GIT_PASSWORD}\" -auto-approve" )
                            sh("set +x; ./terraform destroy -no-color -var-file=ansible/values.tfvars -var=\"vault_password=${ANSIBLE_VAULT_PASSWORD}\" -auto-approve")
                            sh("set +x; rm -rf .terraform* ansible/*_kubeconfig")
                            sh("set +x; find . -name '*.pyc' -delete")
                            gitCommit('auto_test', gitUrl, 'master')
                        } catch (e) {
                            sh("set +x; rm -rf .terraform* comment.json ansible/*_kubeconfig")
                            sh("set +x; find . -name '*.pyc' -delete")
                            gitCommit('auto_test', gitUrl, 'master', "Ошибка при применении конфигурации")
                            error("Apply error")
                        }
                    } 
                }
            }
        //}
    }
}


def gitClone(creds, url, branch) {
    checkout([$class    : 'GitSCM', branches: [[name: branch]],
              extensions: [], userRemoteConfigs: [[credentialsId: creds, url: url]]])
}

def gitCommit(creds, url, repoBranch, commitMessage = "Jenkins apply job commit") {
    withCredentials([[$class: 'UsernamePasswordMultiBinding', credentialsId: creds, usernameVariable: 'GIT_NAME', passwordVariable: 'GIT_PASSWORD']]) {
        if (removeSecrets){
            sh('rm -rf ansible/secrets.yml')
        }
        sh('rm -rf ansible/ext-kafka/kafka-ansible-deploy-3.0.3/roles/copy_distro_to_server/files/kafka.zip')
        sh('rm -rf vpass.txt')
        sh('set +x; git config --global user.email "dummy@dummy.com"')
        sh('set +x; git config --global user.name "Jenkins"')
        sh("set +x; git add -A .")
        sh("set +x; git commit -m \"${commitMessage}\" || echo 'Nothing to commit'")
        sh("set +x; git checkout .")
        sh("set +x; git pull --rebase " + url.replaceAll('https://', "https://${GIT_NAME}:${GIT_PASSWORD}@") + " HEAD:$repoBranch")
        sh("set +x; git push " + url.replaceAll('https://', "https://${GIT_NAME}:${GIT_PASSWORD}@") + " HEAD:$repoBranch")
    }
}

def getCred() {
    withCredentials([
            [$class: 'StringBinding', credentialsId: ' cloudDevOpsEFSAnsibleVaultPassword', variable: 'ANSIBLE_VAULT_PASSWORD'],
            [$class: 'StringBinding', credentialsId: 'HashicorpVaultToken', variable: 'HASHICORP_VAULT_TOKEN']
    ]) {
        if (HASHICORP_VAULT_TOKEN.startsWith("s.") && hashicorp == true) {
            HASHICORP_VAULT_TOKEN = HASHICORP_VAULT_TOKEN
            ANSIBLE_VAULT_PASSWORD = ANSIBLE_VAULT_PASSWORD
            sh "python secman_yaml.py --url ${HASHICORP_URL} --path ${HASICORP_PATH} --token ${HASHICORP_VAULT_TOKEN} --output_file ansible/secrets.yml"
            sh "echo ${ANSIBLE_VAULT_PASSWORD} > vpass.txt && ansible-vault encrypt --vault-id @vpass.txt ansible/secrets.yml"
        } else {
            ANSIBLE_VAULT_PASSWORD = ANSIBLE_VAULT_PASSWORD
        }
    }
}