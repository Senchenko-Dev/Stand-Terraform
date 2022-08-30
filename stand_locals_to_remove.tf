locals {
# TODO раскидать по груп варз
//  wildfly_19_url = "https://download.jboss.org/wildfly/19.0.0.Final/wildfly-19.0.0.Final.zip" // заблокировано
  wildfly_21_url = "https://dzo.sw.sbc.space/nexus-cd/repository/sbt_PROD/sbt_PROD/CI90000011_cloudspo/WildFly-21.0.2/CI90000011_cloudspo-WildFly-21.0.2-distrib.zip"
  wildfly_22_url = "https://dzo.sw.sbc.space/nexus-cd/repository/sbt_PROD/sbt_PROD/CI90000011_cloudspo/WildFly-22.0.1/CI90000011_cloudspo-WildFly-22.0.1-distrib.zip"

  wf_props = {
    wf_os_user = "wildfly"
    wf_os_user_pwd = "wildfly"
    wf_os_group = "wfgroup"
    wf_install_dir = "/usr/WF/"
  }

### POSTGRE SBER EDITION ###
  pangolin461-164_url = "https://dzo.sw.sbc.space/nexus-cd/repository/sbt_PROD_group/Nexus_PROD/CI02289206_PostgreSQL_Sber_Edition/D-04.006.01-164/CI02289206_PostgreSQL_Sber_Edition-D-04.006.01-164-distrib.tar.gz"
  pangolin460-064_url = "https://dzo.sw.sbc.space/nexus-cd/repository/sbt_PROD/sbt_PROD/CI90000013_pangolin/D-04.006.00-064/CI90000013_pangolin-D-04.006.00-064-distrib.tar.gz"
  pangolin460-010_url = "https://dzo.sw.sbc.space/nexus-cd/repository/sbt_PROD/sbt_PROD/CI90000013_pangolin/D-04.006.00-010/CI90000013_pangolin-D-04.006.00-010-distrib.tar.gz"
  pangolin_installation_type = {
    standalone: "standalone"
    cluster: "cluster"
  }
  pangolin_installation_subtype = {
    standalone-postgresql-only: "standalone-postgresql-only"
    standalone-postgresql-pgbouncer: "standalone-postgresql-pgbouncer"
    standalone-patroni-etcd-pgbouncer: "standalone-patroni-etcd-pgbouncer"
    cluster-patroni-etcd-pgbouncer: "cluster-patroni-etcd-pgbouncer"
    cluster-patroni-etcd-pgbouncer-haproxy: "cluster-patroni-etcd-pgbouncer-haproxy"
  }
  pgdata_dir = "/pgdata"
  nexus_variables = {
    nexusRestApiUrl: "https://dzo.sw.sbc.space/nexus-cd"
    nexusClassifier: "distrib"
    groupId: "Nexus_PROD"
//    artifactId = "CI90000013_pangolin" # artifactId_for_nexus
    repoId: "sbt_PROD_group"
    pip_repository: "https://pypi.org/simple/"
    nexusAddress: "pypi.org"
  }

}
