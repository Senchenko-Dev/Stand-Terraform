locals {
  devopsSaName = "devops-pipeline-sa"
  controlPanelName = "control-panel"
  projectPrefix = local.stand_name

  devopsProject = "${local.projectPrefix}-${local.devopsSaName}"
  devopsSaRole = "admin"
  globals = {
    projectPrefix = local.projectPrefix
    devopsSaName = local.devopsSaName
    devopsProject = "${local.projectPrefix}-${local.devopsSaName}"
    devopsSaRole = "admin"
    _delete = true
    dc = "sbmg"
    stand = local.stand_name
    solution = "FRONTEND-STD"
    stashedControlPlaneNamespace = "${local.projectPrefix}-${local.controlPanelName}"
    controlPlaneName = "basic-install"
    values = {
      pullCreds = [
        {
          oseImagePullRegistry = "dzo.sw.sbc.space" #"https://api.stands-vdc03.solution.sbt:6443"
          oseImagePullUser = local.secrets.os.oseImagePullUserFromSecret
          oseImagePullPassword = local.secrets.os.oseImagePullPasswordFromSecret
          oseImagePullName = "dzo.sw.sbc.space"
        }
      ]
      # назначенные роли
      bindings = [
        {
          roleType = "ClusterRole"
          roleName = "admin"
          userKind = "User"
          userName = "aigorebelyaev"
        },
        {
          roleType  = "ClusterRole"
          roleName  = local.devopsSaRole
          userKind  = "ServiceAccount"
          userName  = local.devopsSaName
          saProject = local.devopsProject
        }
      ]
      # ярлыки labels
      labels = {
        id_fp = "globaltag"
      }
    }
  }
}


locals {
  diOpenshiftServiceCore_projects = {
    devops-master-test = {
      oseProjectName = "${local.projectPrefix}-${local.devopsSaName}"
      values = {
        quota = {
          cpu: 4
          mem: 2
        }
        sa = [{ name = local.devopsSaName}]
      }
    },
    control-panel-test = {
      oseProjectName = "${local.projectPrefix}-${local.controlPanelName}"
      values = {
        quota = {
          cpu: 20
          mem: 40
        }
        cp = {
          name: local.globals.controlPlaneName
          template: "cp-basic.yml"
        }
      }
    }
  }
}

module "diOpenshiftServiceCore"  {
  source = "./modules/ansible_project_init"
//  count = 0
  for_each = local.diOpenshiftServiceCore_projects
  managment_system_type = var.managment_system_type
  project_name = each.value.oseProjectName
  kubeconfig = local.oc_kubeconfig
#  awx_props = local.awx_props
  values = merge(
    local.globals.values,
    each.value.values
  )
  vault_password = var.vault_password
}

# Рабочие проекты
locals {
  empty = {}
  group1 = {
    diOpenshiftSessionSector = {
      projects = {
        dyncontent  = {
          fpi_name = "dyncontent"
          values   = {
            quota    = {
              cpu = 2
              mem = 4
            }
            labels     = {
              id_fp = "UFTM",
              fpname = "dyncontent",
              segment = "${local.globals.solution}",
              stand = "${local.globals.stand}"
            }
            bindings = [
              {
                roleType = "ClusterRole"
                roleName = "view"
                userKind = "Group"
                userName = "ose-trb-db"
              }
            ]
          }
        },
      }
      vars = {
        sector = "ses"
        values = {
          sm       = {
            cpNamespace = local.globals.stashedControlPlaneNamespace
            cpName      = local.globals.controlPlaneName
          }
          bindings = [
            {
              roleType = "ClusterRole"
              roleName = "admin"
              userKind = "Group"
              userName = "ose-namespace-admins"
            }
          ]
        }
      }
    }
  }
}

module "diOpenshiftgroup1" {
  source = "./modules/ansible_group_project_init"
  depends_on = [module.diOpenshiftServiceCore]
//  count = 0
  for_each = local.group1
  managment_system_type = var.managment_system_type
#  awx_props = local.awx_props
  kubeconfig = local.oc_kubeconfig
  group = each.key
  specs = each.value
  globals = local.globals
  vault_password = var.vault_password
}

module "config_awx_k8s_templates" {
  depends_on = [module.AWX, module.diOpenshiftgroup1]
//  count = 0
  count = "${length(local.awx_props) != 0 ? 1 : 0}"
  meta = fileset(path.root, "ansible/project_vars/*.yml")
  source = "./modules/awx_config_k8s_templates"
  kubeconfig = local.oc_kubeconfig
  awx_props = local.awx_props
  vault_file = local.vault_file
}

