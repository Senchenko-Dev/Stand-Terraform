set role db_admin;
delete from pg_depend using
(select c.oid as c_id,
p.oid as p_id,
p.proname
from pg_catalog.pg_class c
join pg_catalog.pg_proc p on c.relname = 'pg_proc'
join pg_catalog.pg_namespace ns on p.pronamespace=ns.oid and ns.nspname='pg_catalog'
) flt
where pg_depend.refclassid=flt.c_id
and pg_depend.refobjid = flt.p_id
and pg_depend.deptype ='p'
and pg_depend.classid=0
and pg_depend.objid=0
and pg_depend.objsubid=0
and flt.proname in
(select unnest(string_to_array('add_auth_record_to_storage,alpha_numeric,audit_ddl_command_end,audit_sql_drop,auth_reset_context,check_admin_protect_is_on,check_auth_servers,check_extension_is_on,check_kms_is_on,check_ldap_is_on,check_password_policy_is_on,check_pg_audit_is_on,check_role_params,check_roles_is_on,check_ssl_is_on,check_syntax,check_tde_is_on,custom_function,disable_policy,disable_policy_by_id,edhe_exchange_public_numbers,enable_policy,enable_policy_by_id,expire_warning,failure_count_interval,fc_interval,get_encryption_keys_count,get_password_policy_profile,grace_li,grace_login_limit,grace_login_time_limit,grace_lti,illegal_values,in_history,lduration,lockout,lockout_duration,max_age,max_failure,max_inactivity,max_rpt_chars,min_age,min_alpha_chars,min_length,min_lowercase,min_special_chars,min_uppercase,password_strength_estimator_score,pg_hostname,policy_enable,pp_check_role,pp_check_role_all,pp_check_role_by_id,recognize_password_policy,recognize_password_policy_by_id,recognize_password_policy_detailed,recognize_password_policy_detailed_by_id,reuse_time,sber_version,select_all_password_policies,set_role_policies,set_role_policies_by_id,track_login,unblock_role,unblock_role_by_id,use_password_strength_estimator,use_zxcvbn,zxcvbn_score',',')))
;
update pg_catalog.pg_database set datallowconn =true where datname ='template0';