//variables from jenkins
params = [ansible_arguments: env.ansible_arguments,
          stand: env.environment, // type of stand
          security_level: env.security_level, //importance of stored data
          critical_level: env.critical_level,
          
          cluster_name: env.cluster_name,
          
          database_name: env.database_name,
          tablespace_name: env.tablespace_name,
          schema_name: env.schema_name,

          hosts_list: env.hosts_list, //list with hosts for hand run

          kms_mode: env.kms_mode,
          kms_host: env.kms_host, //kms host
          kms_login: env.kms_login, //kms login
          kms_password: env.kms_password, //kms password
          kms_cluster_id: env.kms_cluster_id, //kms cluster_id

          old_versions: env.old_versions.split(',') as List,
          install_types: env.installation_types.split(',') as List,
          target_version: env.target_version,
          recovery_modules: env.recovery_modules.split(',') as List,
          action_type: env.action_type,
          segment: env.segment, //network type

          credentialsId_custom_dev: env.CREDENTIALSID_CUSTOM_DEV,
          git_url_custom_dev: env.GIT_URL_CUSTOM_DEV,
          path_custom_dev: env.PATH_CUSTOM_DEV,

          // database_superuser: 'postgres', //env.database_superuser,
          // database_superuser_password: 'P@sswordFishSword123', //env.database_superuser_password,
          // postgres_ssh_password: 'G!leDSQL_SEl#mJ', //env.postgres_ssh_password,
          // patroni_api_password: 'dev_PGsE_patroni_pass#2021', //env.patroni_api_password,
          ssh_user: env.ssh_user,
          ssh_password: env.ssh_password,
          ssh_port: "22",

          //qaTestVars: env.QATestVars,
          postgresql_ssh_user: 'postgres',
          postgresql_ssh_password: 'G!leDSQL_SEl#mJ',
          postgres_database_user: 'postgres',
          postgres_database_password: 'P@sswordFishSword123',
          path_to_hba_config: '/etc/patroni/postgres.yml',
          main_database: 'postgres',
          patroni_api_password: 'dev_api_pastroni_pass!',
          sec_admin: 'sec_admin',
          sec_pass: 'Supersecadmin$1234',
          db_admin: 'test_db_admin',
          db_pass: 'P@sswordFishSword123',
          backup_admin: 'backup_user',
          backup_pass: 'backupPas$superStronG9@112',
          as_admin: 'test_as_admin',
          as_pass: 'P@sswordFishSword123',
          tuz_devops: 'cdm_devops',
          tuz_devops_pass: 'dev123456789',
          tuz_appl: 'test_as_tuz',
          tuz_appl_pass: 'P@sswordFishSword123',
          list_email: 'AVGalaktionov@omega.sbrf.ru, ASeMilov@omega.sbrf.ru',
          jira_credentialsId: 'SBT-SA-POSTGRESQL_S_passwd',
          jira_server: 'https://jira.sberbank.ru',
          path_cert: '/etc/ssl/certs/ca-bundle.crt',
          logging_level: 'DEBUG',
          full_debug: 'False',
          max_log_symbols: '15000',

          // sec_admin: env.sec_admin,
          // sec_admin_pass: env.sec_admin_pass,
          // db_admin: env.db_admin,
          // db_admin_pass: env.db_admin_pass,
          // backup_admin: env.backup_admin,
          // backup_admin_pass: env.backup_admin_pass,
          // as_admin: env.as_admin,
          // as_admin_pass: env.as_admin_pass,
          // tuz_devops: env.tuz_devops,
          // tuz_devops_pass: env.tuz_devops_pass,
          // tuz_appl: env.tuz_appl,
          // tuz_appl_pass: env.tuz_appl_pass,
          targetAutoTestJobName: env.targetAutoTestJobName,
          full_debug: env.full_debug,
          max_log_symbols: env.max_log_symbols,
          cleanJobName: env.cleanJobName,
          jenkinsAgentLabel: env.jenkinsAgentLabel,
          autotests_branch: env.autotests_branch,
          test_runner_args: env.test_runner_args ]

recovery_error_types = ['postgresql_error_um001m',
                        'postgresql_error_um001r',
                        'postgresql_error_um002m',
                        'postgresql_error_um002r',
                        'postgresql_error_um003m',
                        'postgresql_error_um003r',
                        'postgresql_error_um004m',
                        'postgresql_error_um004r',
                        'postgresql_error_um005m',
                        'postgresql_error_um005r',
                        'postgresql_error_um006m',
                        'postgresql_error_um006r',
                        'postgresql_error_um007m',
                        'postgresql_error_um007r',
                        'postgresql_error_um008m',
                        'postgresql_error_um008r',
                        'postgresql_error_um009m',
                        'postgresql_error_um009r',
                        'etcd_error_um001m',
                        'etcd_error_um001r',
                        'etcd_error_um001e',
                        'etcd_error_um002m',
                        'etcd_error_um002r',
                        'etcd_error_um002e',
                        'patroni_error_um001m',
                        'patroni_error_um001r',
                        'patroni_error_um002m',
                        'patroni_error_um002r',
                        'patroni_error_um003m',
                        'patroni_error_um003r',
                        'patroni_error_um004m',
                        'patroni_error_um004r',
                        'patroni_error_um005m',
                        'patroni_error_um005r',
                        'pgbouncer_error_um001m',
                        'pgbouncer_error_um001r',
                        'pgbouncer_error_um002m',
                        'pgbouncer_error_um002r',
                        'pgbouncer_error_um003m',
                        'pgbouncer_error_um003r',
                        'pgbouncer_error_um004m',
                        'pgbouncer_error_um004r',
                        'pgbouncer_error_um005m',
                        'pgbouncer_error_um005r'
                        ]
// println("env.QATestVars: " + env.qaTestVars)
// println("qaTestVars: " + params.qaTestVars)
// println("qaTestVars.as_admin: " + params.qaTestVars.as_admin)
// println("qaTestVars.sec_pass: " + params.qaTestVars.sec_pass)

def setTdeAndAdminProtection(params_list){
  if (params_list.security_level.toLowerCase() == 'k1'){
    params_list += [tde: true]
    params_list += [admin_protection: true]
  }else if (params_list.security_level.toLowerCase() == 'k2'){
    params_list += [tde: true]
    params_list += [admin_protection: false]
  }else{
    params_list += [tde: false]
    params_list += [admin_protection: false]
  }
  return params_list
}

def checkJenkinsVars(params_list, vars_list){
  if (env.JENKINS_URL.contains('sbt-jenkins.sigma.sbrf.ru') || env.JENKINS_URL.contains('sbt-jenkins.ca.sbrf.ru') || env.JENKINS_URL.contains('dzo.sw.sbc.space/jenkins-ci')){
    devops_segment = 'CI'
  }else if (env.JENKINS_URL.contains('sbt-qa-jenkins.sigma.sbrf.ru') || env.JENKINS_URL.contains('sbt-qa-jenkins.ca.sbrf.ru')){
    devops_segment = 'CDL'
  }else if (env.JENKINS_URL.contains('nlb-jenkins-sigma-psi.sigma.sbrf.ru') || env.JENKINS_URL.contains('nlb-jenkins-psi.ca.sbrf.ru') || env.JENKINS_URL.contains('dzo.sw.sbc.space/jenkins-cd')) {
    devops_segment = 'CDP'
  }else if (env.JENKINS_URL.contains('nlb-jenkins-sigma.sigma.sbrf.ru') || env.JENKINS_URL.contains('nlb-jenkins.ca.sbrf.ru')){
    devops_segment = 'PROD'
  }
  wrap([$class: 'MaskPasswordsBuildWrapper', varPasswordPairs: [[password: "${params_list.ssh_password}", var: 'PSWD']]]) {
    vars_list.findAll { key, value ->
      if ((value instanceof java.lang.String) && (value.length() != 0 )) {
        println('Correct. Variable ' + key + ' does not empty and equals: ' + value)
      }else{
        println('Error. Variable ' + key + ' is empty')
        emailext (attachLog: true,
            body: """<p>Job ${env.JOB_NAME} build ${env.BUILD_NUMBER} is FAILURE. <br>More info at ${env.BUILD_URL} or in mail attachment</br></p>""",
            compressLog: true,
            mimeType: 'text/html',
            subject: "FAILURE: Segment: ${vars_list.segment}, Stage: ${devops_segment}",
            to: 'Delivery_team_PostgreSQL_sbt@sberbank.ru'
      )
        autoCancelled = true
        error("Abortion is build, because the variable from input Jenkins variables is empty")
      }
    }
  }
}

def setCurruntInstaller(params_list, dirPath, branchName=''){
    sh "rm -rf ${dirPath}"
    sh "mkdir -p ${dirPath}"
    dir("${dirPath}")
    {
      checkout scm
      if(branchName != ''){
        sh """
        git checkout ${branchName}
        git status
        """
        sh(
          script: "ls -la ${params_list.installer_dir}/scripts/",
          returnStatus: true
        )
        println("branchName = "+branchName)
      }
    }
}

def convertInputDataToYaml(params_list, install_type){
  try{
    install_type_splited = install_type.split('-')
    dir ("${params_list.installer_dir}/files/")
    {
      writeFile file: 'hosts', text: params_list.hosts_list
      sh """
          source ${env.WORKSPACE}/pg_se_venv/bin/activate
          python json_to_yml.py ${install_type_splited.first()}
        """
    }
    return 0
  }catch(Exception e){
    return 1
  }
}

list_of_variables = params
params = setTdeAndAdminProtection(params)
//
//params += [install_type_splited: params.installation_types.split('-')]
//params += [segment_type_splited: params.segment.split('_')]

//ddd = Date.parse( "yyyy-MM-dd'T'HH:mm:ss", text ).with { new Date( time + 1000) }
//println("date: " + ddd)

//++++++++++++++++++++++++++++++++++++++++++++
//++++++++++++++++++PIPELINE++++++++++++++++++
//++++++++++++++++++++++++++++++++++++++++++++

result_job = []

def prepareAnsibleSlaveVM(params_list){
  try{
    deleteDir()
    println("prepareAnsibleSlaveVM 0")
    setCurruntInstaller(params_list, "${params_list.groovy_dir}", env.installer_branch)
    println("prepareAnsibleSlaveVM 1:" + "${params_list.groovy_dir}/pipelines/common.groovy")
    sh """
    ls -la ${params_list.groovy_dir}/pipelines/
    sleep 4s
    """
    common = load("${params_list.groovy_dir}/pipelines/common.groovy")
    println("prepareAnsibleSlaveVM 2:" + "${params_list.groovy_dir}/pipelines/common.groovy")
    echo "\033[37;1;45m>>> Check jenkins input variables <<<\033[0m"
    //checkJenkinsVars(params_list,list_of_variables)
    echo "\033[37;1;45m>>> Install python libraries <<<\033[0m"
    common.createPythonVenv(params_list)

    return 0
  }catch(Exception e){
    return 1
  }
}

def installPangolin(params_list, ver, cfg){
  try{
    if(ver == params_list.target_version)
      is_old_pgse_version = false
    else
      is_old_pgse_version = true
    println("start params_list.target_version " + params_list.target_version)

    short_ver = (ver.split('-'))[1]
    echo "\033[37;1;45m>>> Download Pangolin ver. ${ver} of type ${cfg} distributive <<<\033[0m"
    result = common.downloadDistrib(ver, params_list,is_old_pgse_version)
    println("result:" + result)
    if(result == 0){
      echo "\033[37;1;45m>>> Unarchive Pangolin ver. ${ver} of type ${cfg} distributive <<<\033[0m"
      result |= common.unarchive_distrib(params_list.distrib_dir, ver)
      println("result:" + result)
    }
    if(result == 0){
      echo "\033[37;1;45m>>> Prepare installation Pangolin ver. ${ver} of type ${cfg} <<<\033[0m"
    //result |= 
      common.prepareInstallationOldPgseVersions(params_list.installer_dir)
      println("result:" + result)
    }
    if(result == 0 && ver == params_list.target_version){
      echo "\033[37;1;45m>>> Set current version for installer <<<\033[0m"
      setCurruntInstaller(params_list, "${params_list.distrib_dir}/installer")
    }
    if(result == 0){
      echo "\033[37;1;45m>>> Download custom_dev.yml <<<\033[0m"
      result |= common.downoladCustomCfg(params_list, short_ver)
      println("result:" + result)
    }
    if(result == 0){
      result = sh(
          script: "grep ${cfg} ${params_list.installer_dir}/playbook.yaml",
          returnStatus: true
      )
    }
    if(result == 0){
      echo "\033[37;1;45m>>> Clean hosts <<<\033[0m"
      result |= common.cleanVMs(params_list)
      println("result:" + result)
    }
    if(result == 0){
      echo "\033[37;1;45m>>> Convert input data to yaml for created inventories file <<<\033[0m"
      result |= convertInputDataToYaml(params_list, cfg)
      println("result:" + result)
      println("version___ " + ver + "  "+(ver.split('-'))[1])
    }
    params_list += common.defineParamsByPGSEVersion(params_list, short_ver)
    if(result == 0){
      echo "\033[37;1;45m>>> Start installation old PG SE <<<\033[0m"
      result |= common.runAnsiblePlaybook("install", cfg, params_list, ver)
      println("result:" + result)
    }
  //checkLogs(logfile)
    if(result != 0){
      result_job += ">>> Installation Pangolin ver. ${ver} of type ${cfg} was inner error, see logs <<<"
      echo "\033[37;1;45m>>> Installation Pangolin ver. ${ver} of type ${cfg} was inner error, see logs <<<\033[0m"
      return [1, params_list]
    }
    result_job += ">>> Installation Pangolin ver. ${ver} of type ${cfg} was successful <<<"
    echo "\033[37;1;45m>>> Installation Pangolin ver. ${ver} of type ${cfg} was successful <<<\033[0m"
    return [0, params_list]
  }catch(Exception e){
    result_job += ">>> Installation Pangolin ver. ${ver} of type ${cfg} was error, see logs <<<"
    echo "\033[37;1;45m>>> Installation Pangolin ver. ${ver} of type ${cfg} was error, see logs <<<\033[0m"
    return [1, params_list]
  }
}

def PrepareScoutUpdatePangolin(params_list, ver, cfg, is_old_pgse_version){
  try{
    echo "\033[37;1;45m>>> Download distributive with new PG SE version <<<\033[0m"
    result = common.downloadDistrib(params_list.target_version, params, is_old_pgse_version)
    if(result == 0){
      echo "\033[37;1;45m>>> Unarchive distributive with new PG SE version <<<\033[0m"
      result |= common.unarchive_distrib(params_list.distrib_dir, params.target_version)
    }
    if(result == 0){
      echo "\033[37;1;45m>>> Set current version for installer <<<\033[0m"
      setCurruntInstaller(params_list, "${params_list.installer_dir}", env.installer_branch)
    }
    if(result == 0){
      echo "\033[37;1;45m>>> Download custom_dev.yml <<<\033[0m"
      short_ver = (params_list.target_version.split('-'))[1]
      result |= common.downoladCustomCfg(params_list, short_ver)
    }
    if(result == 0){
      echo "\033[37;1;45m>>> Convert input data to yaml for created inventories file <<<\033[0m"
      result |= convertInputDataToYaml(params_list, cfg)
      println("result:" + result)
    }
    if(result != 0){
      result_job += ">>> Prepare Scout -> Update Pangolin ver. ${ver} of type ${cfg} was inner error, see logs <<<"
      echo "\033[37;1;45m>>> Prepare Scout -> Update Pangolin ver. ${ver} of type ${cfg} was inner error, see logs <<<\033[0m"
      return 1
    }
    result_job += ">>> Prepare Scout -> Update Pangolin ver. ${ver} of type ${cfg} was successful <<<"
    echo "\033[37;1;45m>>> Prepare Scout -> Update Pangolin ver. ${ver} of type ${cfg} was successful <<<\033[0m"
    return 0
  }catch(Exception e){
    result_job += ">>> Prepare Scout -> Update Pangolin ver. ${ver} of type ${cfg} was error, see logs <<<"
    echo "\033[37;1;45m>>> Prepare Scout -> Update Pangolin ver. ${ver} of type ${cfg} was error, see logs <<<\033[0m"
    return 1
  }
}

def ScoutUpdatePangolin(params_list, ver, cfg, recovery_error_elem = ''){
  try{
    if(recovery_error_elem == '')
      start_name = "Scout -> Update"
    else
      start_name = "Scout -> Recovery"
    echo "\033[37;1;45m>>> Start scout before update version PG SE <<<\033[0m"
    result = common.runAnsiblePlaybook("update_minor_scout", cfg, params_list, ver)
    if(result == 0){
      echo "\033[37;1;45m>>> Start end-to-end update version PG SE <<<\033[0m"
      result |= common.runAnsiblePlaybook("update_minor", cfg, params_list, ver, recovery_error_elem)
    }
    if(result != 0){
      result_job += ">>> ${start_name} Pangolin ver. ${ver} of type ${cfg} was inner error, see logs <<<"
      echo "\033[37;1;45m>>> ${start_name} Pangolin ver. ${ver} of type ${cfg} was inner error, see logs <<<\033[0m"
      return 1
    }
    result_job += ">>> ${start_name} Pangolin ver. ${ver} of type ${cfg} was successful <<<"
    echo "\033[37;1;45m>>> ${start_name} Pangolin ver. ${ver} of type ${cfg} was successful <<<\033[0m"
    return 0
  }catch(Exception e){
    result_job += ">>> ${start_name} Pangolin ver. ${ver} of type ${cfg} was error, see logs <<<"
    echo "\033[37;1;45m>>> ${start_name} Pangolin ver. ${ver} of type ${cfg} was error, see logs <<<\033[0m"
    return 1
  }
}

pipeline{
  agent{
    label env.jenkinsAgentLabel
  }
  options{
	  ansiColor('xterm')
  }
  stages{
    stage("InstallUpdateRecovery"){
      steps{
        script{
          stage("PrepareAnsibleSlaveVM"){
            version_list = params.old_versions
            version_list.add(params.target_version)
            configuration_list = params.install_types
            recovery_modules = params.recovery_modules

            params += [distrib_dir: "${env.WORKSPACE}/distributive"]
            params += [installer_dir: "${params.distrib_dir}/installer"]
            params += [groovy_dir: "${env.WORKSPACE}/src"]
            params += [logs_dir: "${env.WORKSPACE}/logs"]
            
            prefixActionType = 'Major'
            if(params.action_type.contains('minor'))
              prefixActionType = 'Minor'

            if(prepareAnsibleSlaveVM(params) != 0){
              currentBuild.result = 'FAILURE'
              error ">>> Pipeline has been error, see logs <<<"
            }
          }

          for(ver in version_list){
            if((!params.action_type.contains('install') && ver == params.target_version) || ver.length() == 0)
              continue
            for(cfg in configuration_list){
              if(cfg.length() == 0)
                continue
              stage("InstallPangolin-${ver}-${cfg}"){
                (res_install, params) = installPangolin(params, ver, cfg)
                println("res installPangolin " + res_install)
              }
              if( res_install != 0)
                continue
              if(!params.action_type.contains('install')){
                stage("Prepare${prefixActionType}UpdatePangolin"){
                  is_old_pgse_version = false
                  res_action = PrepareScoutUpdatePangolin(params, ver, cfg, is_old_pgse_version)
                }
                if( res_action != 0)
                  continue
              }
              if(params.action_type.contains('recovery')){
                if(ver == params.target_version)
                  continue
                stage("${prefixActionType}RecoveryPangolin"){
                  for(recovery_error_elem in recovery_error_types){
                    is_error_exists = (recovery_error_elem.split('_')[0] in recovery_modules) || 'all' in recovery_modules
                    if(!is_error_exists)
                      continue
                    res_action = ScoutUpdatePangolin(params, ver, cfg, recovery_error_elem)
                    if( res_action == 0)
                      continue
                    stage("ReInstallPangolin-${ver}-${cfg}"){
                      (res_install, params) = installPangolin(params, ver, cfg)
                      if( res_install != 0)
                        break
                      is_old_pgse_version = false
                      res_action = PrepareScoutUpdatePangolin(params, ver, cfg, is_old_pgse_version)
                      if( res_action != 0)
                        break
                    }
                  }
                }
              }
              if(!params.action_type.contains('install') && res_action == 0){
                stage("${prefixActionType}UpdatePangolinTo-${params.target_version}"){
                  res_action = ScoutUpdatePangolin(params, ver, cfg)
                }
                if( res_action != 0)
                  continue
              }
              if( !params.action_type.contains('install') || (ver == params.target_version) ){
                stage("RunQATests-${ver}"){
                  common.runAutotests(params, (cfg.split('-'))[0], ver, cfg)
                }
              }
            }
          }
          stage("CreateResultLogArchive"){
            try{
              echo "\033[37;1;45m>>> Result log archive will be created <<<\033[0m"
              sh """
                cd ${params.logs_dir}
                env GZIP=-9 tar --totals -czf ${env.WORKSPACE}/total_archive.tar.gz *
              """
              archiveArtifacts artifacts: """total_archive.tar.gz"""
            }catch(Exception e){
              echo "\033[37;1;45m>>> Result log archive didn't created, see logs <<<\033[0m"
            }
            echo "\033[37;1;45m>>> Results of job work <<<\033[0m"
            for(res in result_job){
              echo "\033[37;1;45m${res}\033[0m"
            }
          }
        }
      }
    }
  }
}