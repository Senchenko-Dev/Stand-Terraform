//output "project1" {
//  //value = coalesce(each.value.oseProjectName, "${ var.globals.projectPrefix }-${ var.globals.stand }-${ var.specs.vars.sector }-${ var.globals.dc }-${ each.key }")
//  value = [
//    for k, v in local.updated_projects: coalesce(v.oseProjectName, "${ var.globals.projectPrefix }-${ var.globals.stand }-${ var.specs.vars.sector }-${var.globals.dc}-${k}")
//  ]
//}