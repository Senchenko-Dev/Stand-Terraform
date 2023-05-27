[openshift_clusters]
%{ for ansible_host in ans_hosts ~}
${ansible_host.name} openshiftAppsDomain="${ansible_host.openshiftAppsDomain}" openshiftCluster="${ansible_host.openshiftCluster}" openshiftCorePlatformProjectName="${ansible_host.openshiftCorePlatformProjectName}"

;main_cluster openshiftAppsDomain="apps.stands-vdc03.solution.sbt" openshiftCluster="https://api.stands-vdc03.solution.sbt:6443" openshiftCorePlatformProjectName="inner-bf1-inner-bf1-ses-sbmg-sentsov"
%{ endfor ~}
