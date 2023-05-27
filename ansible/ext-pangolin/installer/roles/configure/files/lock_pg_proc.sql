set role db_admin;
INSERT INTO pg_catalog.pg_depend (classid,objid,objsubid,refclassid,refobjid,refobjsubid,deptype)
select 0,0,0,c.oid,p.oid,0,'p'
FROM pg_catalog.pg_class c
join pg_catalog.pg_proc p on c.relname = 'pg_proc'
join pg_catalog.pg_namespace ns on p.pronamespace =ns.oid
and ns.nspname = 'pg_catalog'
and p.proname in
(select unnest(string_to_array('alpha_numeric,audit_ddl_command_end,audit_sql_drop,auth_reset_context,check_admin_protect_is_on,check_auth_servers,check_extension_is_on,check_kms_is_on,check_ldap_is_on,check_password_policy_is_on,check_pg_audit_is_on,check_ssl_is_on,check_syntax,check_tde_is_on,custom_function,disable_policy,disable_policy_by_id,edhe_exchange_public_numbers,enable_policy,enable_policy_by_id,expire_warning,failure_count_interval,fc_interval,get_encryption_keys_count,get_password_policy_profile,grace_li,grace_login_limit,grace_login_time_limit,grace_lti,illegal_values,in_history,lduration,lockout,lockout_duration,max_age,max_failure,max_inactivity,max_rpt_chars,min_age,min_alpha_chars,min_length,min_lowercase,min_special_chars,min_uppercase,password_strength_estimator_score,pg_hostname,policy_enable,pp_check_role,pp_check_role_all,pp_check_role_by_id,recognize_password_policy,recognize_password_policy_by_id,recognize_password_policy_detailed,recognize_password_policy_detailed_by_id,reuse_time,sber_version,select_all_password_policies,set_role_policies,set_role_policies_by_id,track_login,unblock_role,unblock_role_by_id,use_password_strength_estimator,use_zxcvbn,zxcvbn_score',',')))
;
update pg_catalog.pg_database set datallowconn =false where datname ='template0';