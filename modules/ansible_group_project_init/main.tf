locals {
  globals = {}
  specsvars = {}
  specsprojects = {}

}
locals {
  group_vars_values = {
    sm = try(var.globals.values.sm, lookup(var.specs.vars.values, "sm", false))
    bindings = concat(lookup(var.globals.values, "bindings", []), lookup(var.specs.vars.values, "bindings", []))
    pullCreds = concat(lookup(var.globals.values, "pullCreds", []), lookup(var.specs.vars.values, "pullCreds", []))
    sa = concat(lookup(var.globals.values, "sa", []), lookup(var.specs.vars.values, "sa", []))
#    tags = concat(lookup(var.globals.values, "tags", []), lookup(var.specs.vars.values, "tags", []))
    labels = merge(lookup(var.globals.values, "labels", {}), lookup(var.specs.vars.values, "labels", {}))
    quota = try(var.specs.vars.values.quota, lookup(var.globals.values, "quota", false))
    cp = try(var.specs.vars.values.cp, lookup(var.globals.values, "cp", false))
  }
}

locals {
  updated_projects = {
    for project, i in var.specs.projects:
      project => {
        fpi_name = i.fpi_name
        oseProjectName = try(i.oseProjectName, null)
        values = {
          sm = try(i.values.sm, lookup(local.group_vars_values, "sm", false))
          bindings = concat(lookup(i.values, "bindings", []), lookup(local.group_vars_values, "bindings", []))
          pullCreds = concat(lookup(i.values, "pullCreds", []), lookup(local.group_vars_values, "pullCreds", []))
          sa = concat(lookup(i.values, "sa", []), lookup(local.group_vars_values, "sa", []))
#          tags = concat(lookup(i.values, "tags", []), lookup(local.group_vars_values, "tags", []))
          labels = merge(lookup(local.group_vars_values, "labels", {}), lookup(i.values, "labels", {}))
          quota = try(i.values.quota, lookup(local.group_vars_values, "quota", false))
          cp = try(i.values.cp, lookup(local.group_vars_values, "cp", false))
        }
      }
  }

}


//output "project" {
  //value = coalesce(each.value.oseProjectName, "${ var.globals.projectPrefix }-${ var.globals.stand }-${ var.specs.vars.sector }-${ var.globals.dc }-${ each.key }")
//  value = [
//    for k, v in local.updated_projects: coalesce(v.value.oseProjectName, "${ var.globals.projectPrefix }-${ var.globals.stand }-${ var.specs.vars.sector }-${var.globals.dc}-${k}")
//  ]
//}


module "project" {
  source = "../ansible_project_init"
  managment_system_type = var.managment_system_type
  for_each = local.updated_projects
  //project_name = try(each.value.oseProjectName, "${ var.globals.projectPrefix }-${ var.globals.stand }-${ var.specs.vars.sector }-${ var.globals.dc }-${ each.key }")
  project_name = coalesce(each.value.oseProjectName, "${ var.globals.projectPrefix }-${ var.globals.stand }-${ var.specs.vars.sector }-${ var.globals.dc }-${ each.value.fpi_name }")
  kubeconfig = var.kubeconfig
  values = each.value.values
  vault_password = var.vault_password
}
