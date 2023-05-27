DROP FUNCTION IF EXISTS pg_catalog.alpha_numeric (policy_value integer, OUT name text, OUT value integer);
CREATE OR REPLACE FUNCTION pg_catalog.alpha_numeric(policy_value integer, OUT name text, OUT value integer)
 RETURNS record
 LANGUAGE internal
 STABLE PARALLEL SAFE
AS $function$create_alpha_numeric_policy$function$
;
DROP FUNCTION IF EXISTS pg_catalog.audit_ddl_command_end ();
CREATE OR REPLACE FUNCTION pg_catalog.audit_ddl_command_end()
 RETURNS event_trigger
 LANGUAGE internal
 STABLE PARALLEL SAFE STRICT
AS $function$audit_ddl_command_end$function$
;
DROP FUNCTION IF EXISTS pg_catalog.audit_sql_drop ();
CREATE OR REPLACE FUNCTION pg_catalog.audit_sql_drop()
 RETURNS event_trigger
 LANGUAGE internal
 STABLE PARALLEL SAFE STRICT
AS $function$audit_sql_drop$function$
;
DROP FUNCTION IF EXISTS pg_catalog.auth_reset_context ();
CREATE OR REPLACE FUNCTION pg_catalog.auth_reset_context()
 RETURNS void
 LANGUAGE internal
 PARALLEL SAFE
AS $function$auth_reset_context$function$
;
DROP FUNCTION IF EXISTS pg_catalog.check_admin_protect_is_on ();
CREATE OR REPLACE FUNCTION pg_catalog.check_admin_protect_is_on()
 RETURNS boolean
 LANGUAGE internal
 STABLE PARALLEL SAFE STRICT
AS $function$check_admin_protect_is_on$function$
;
DROP FUNCTION IF EXISTS pg_catalog.check_auth_servers (auth_type text, servers_re text);
CREATE OR REPLACE FUNCTION pg_catalog.check_auth_servers(auth_type text, servers_re text)
 RETURNS boolean
 LANGUAGE internal
 STABLE PARALLEL SAFE STRICT
AS $function$check_auth_servers$function$
;
DROP FUNCTION IF EXISTS pg_catalog.check_extension_is_on (extension_name name);
CREATE OR REPLACE FUNCTION pg_catalog.check_extension_is_on(extension_name name)
 RETURNS boolean
 LANGUAGE internal
 STABLE PARALLEL SAFE STRICT
AS $function$check_extension_is_on$function$
;
DROP FUNCTION IF EXISTS pg_catalog.check_kms_is_on ();
CREATE OR REPLACE FUNCTION pg_catalog.check_kms_is_on()
 RETURNS boolean
 LANGUAGE internal
 STABLE PARALLEL SAFE STRICT
AS $function$check_kms_is_on$function$
;
DROP FUNCTION IF EXISTS pg_catalog.check_ldap_is_on ();
CREATE OR REPLACE FUNCTION pg_catalog.check_ldap_is_on()
 RETURNS boolean
 LANGUAGE internal
 STABLE PARALLEL SAFE STRICT
AS $function$check_ldap_is_on$function$
;
DROP FUNCTION IF EXISTS pg_catalog.check_password_policy_is_on ();
CREATE OR REPLACE FUNCTION pg_catalog.check_password_policy_is_on()
 RETURNS boolean
 LANGUAGE internal
 STABLE PARALLEL SAFE STRICT
AS $function$check_password_policy_is_on$function$
;
DROP FUNCTION IF EXISTS pg_catalog.check_pg_audit_is_on ();
CREATE OR REPLACE FUNCTION pg_catalog.check_pg_audit_is_on()
 RETURNS boolean
 LANGUAGE internal
 STABLE PARALLEL SAFE STRICT
AS $function$check_pg_audit_is_on$function$
;
DROP FUNCTION IF EXISTS pg_catalog.check_role_params (role text, settings_to_check text);
DROP FUNCTION IF EXISTS pg_catalog.check_roles_is_on ();
DROP FUNCTION IF EXISTS pg_catalog.check_ssl_is_on ();
CREATE OR REPLACE FUNCTION pg_catalog.check_ssl_is_on()
 RETURNS boolean
 LANGUAGE internal
 STABLE PARALLEL SAFE STRICT
AS $function$check_ssl_is_on$function$
;
DROP FUNCTION IF EXISTS pg_catalog.check_syntax (policy_value boolean, OUT name text, OUT value boolean);
CREATE OR REPLACE FUNCTION pg_catalog.check_syntax(policy_value boolean, OUT name text, OUT value boolean)
 RETURNS record
 LANGUAGE internal
 STABLE PARALLEL SAFE
AS $function$create_check_syntax_policy$function$
;
DROP FUNCTION IF EXISTS pg_catalog.check_tde_is_on ();
CREATE OR REPLACE FUNCTION pg_catalog.check_tde_is_on()
 RETURNS boolean
 LANGUAGE internal
 STABLE PARALLEL SAFE STRICT
AS $function$check_tde_is_on$function$
;
DROP FUNCTION IF EXISTS pg_catalog.custom_function (policy_value name, OUT name text, OUT value regproc);
CREATE OR REPLACE FUNCTION pg_catalog.custom_function(policy_value name, OUT name text, OUT value regproc)
 RETURNS record
 LANGUAGE internal
 STABLE PARALLEL SAFE
AS $function$create_custom_function_policy$function$
;
DROP FUNCTION IF EXISTS pg_catalog.disable_policy (role_name name, OUT roleid regrole, OUT reuse_time interval, OUT in_history integer, OUT max_age interval, OUT min_age interval, OUT grace_login_limit integer, OUT grace_login_time_limit interval, OUT expire_warning interval, OUT lockout boolean, OUT lockout_duration interval, OUT max_failure integer, OUT failure_count_interval interval, OUT check_syntax boolean, OUT min_length integer, OUT illegal_values boolean, OUT alpha_numeric integer, OUT min_alpha_chars integer, OUT min_special_chars integer, OUT min_uppercase integer, OUT min_lowercase integer, OUT max_rpt_chars integer, OUT policy_enable boolean, OUT track_login boolean, OUT max_inactivity interval, OUT use_password_strength_estimator boolean, OUT password_strength_estimator_score integer, OUT custom_function regproc);
CREATE OR REPLACE FUNCTION pg_catalog.disable_policy(role_name name, OUT roleid regrole, OUT reuse_time interval, OUT in_history integer, OUT max_age interval, OUT min_age interval, OUT grace_login_limit integer, OUT grace_login_time_limit interval, OUT expire_warning interval, OUT lockout boolean, OUT lockout_duration interval, OUT max_failure integer, OUT failure_count_interval interval, OUT check_syntax boolean, OUT min_length integer, OUT illegal_values boolean, OUT alpha_numeric integer, OUT min_alpha_chars integer, OUT min_special_chars integer, OUT min_uppercase integer, OUT min_lowercase integer, OUT max_rpt_chars integer, OUT policy_enable boolean, OUT track_login boolean, OUT max_inactivity interval, OUT use_password_strength_estimator boolean, OUT password_strength_estimator_score integer, OUT custom_function regproc)
 RETURNS record
 LANGUAGE internal
 STABLE PARALLEL SAFE STRICT
AS $function$disable_policy$function$
;
DROP FUNCTION IF EXISTS pg_catalog.disable_policy_by_id (roleoid oid, OUT roleid regrole, OUT reuse_time interval, OUT in_history integer, OUT max_age interval, OUT min_age interval, OUT grace_login_limit integer, OUT grace_login_time_limit interval, OUT expire_warning interval, OUT lockout boolean, OUT lockout_duration interval, OUT max_failure integer, OUT failure_count_interval interval, OUT check_syntax boolean, OUT min_length integer, OUT illegal_values boolean, OUT alpha_numeric integer, OUT min_alpha_chars integer, OUT min_special_chars integer, OUT min_uppercase integer, OUT min_lowercase integer, OUT max_rpt_chars integer, OUT policy_enable boolean, OUT track_login boolean, OUT max_inactivity interval, OUT use_password_strength_estimator boolean, OUT password_strength_estimator_score integer, OUT custom_function regproc);
CREATE OR REPLACE FUNCTION pg_catalog.disable_policy_by_id(roleoid oid, OUT roleid regrole, OUT reuse_time interval, OUT in_history integer, OUT max_age interval, OUT min_age interval, OUT grace_login_limit integer, OUT grace_login_time_limit interval, OUT expire_warning interval, OUT lockout boolean, OUT lockout_duration interval, OUT max_failure integer, OUT failure_count_interval interval, OUT check_syntax boolean, OUT min_length integer, OUT illegal_values boolean, OUT alpha_numeric integer, OUT min_alpha_chars integer, OUT min_special_chars integer, OUT min_uppercase integer, OUT min_lowercase integer, OUT max_rpt_chars integer, OUT policy_enable boolean, OUT track_login boolean, OUT max_inactivity interval, OUT use_password_strength_estimator boolean, OUT password_strength_estimator_score integer, OUT custom_function regproc)
 RETURNS record
 LANGUAGE internal
 STABLE PARALLEL SAFE STRICT
AS $function$disable_policy_by_id$function$
;
DROP FUNCTION IF EXISTS pg_catalog.edhe_exchange_public_numbers (public_key cstring, OUT rq_id integer, OUT public_key cstring, OUT initialization_vector cstring);
CREATE OR REPLACE FUNCTION pg_catalog.edhe_exchange_public_numbers(public_key cstring, OUT rq_id integer, OUT public_key cstring, OUT initialization_vector cstring)
 RETURNS record
 LANGUAGE internal
 PARALLEL SAFE
AS $function$edhe_exchange_public_numbers$function$
;
DROP FUNCTION IF EXISTS pg_catalog.enable_policy (role_name name, OUT roleid regrole, OUT reuse_time interval, OUT in_history integer, OUT max_age interval, OUT min_age interval, OUT grace_login_limit integer, OUT grace_login_time_limit interval, OUT expire_warning interval, OUT lockout boolean, OUT lockout_duration interval, OUT max_failure integer, OUT failure_count_interval interval, OUT check_syntax boolean, OUT min_length integer, OUT illegal_values boolean, OUT alpha_numeric integer, OUT min_alpha_chars integer, OUT min_special_chars integer, OUT min_uppercase integer, OUT min_lowercase integer, OUT max_rpt_chars integer, OUT policy_enable boolean, OUT track_login boolean, OUT max_inactivity interval, OUT use_password_strength_estimator boolean, OUT password_strength_estimator_score integer, OUT custom_function regproc);
CREATE OR REPLACE FUNCTION pg_catalog.enable_policy(role_name name, OUT roleid regrole, OUT reuse_time interval, OUT in_history integer, OUT max_age interval, OUT min_age interval, OUT grace_login_limit integer, OUT grace_login_time_limit interval, OUT expire_warning interval, OUT lockout boolean, OUT lockout_duration interval, OUT max_failure integer, OUT failure_count_interval interval, OUT check_syntax boolean, OUT min_length integer, OUT illegal_values boolean, OUT alpha_numeric integer, OUT min_alpha_chars integer, OUT min_special_chars integer, OUT min_uppercase integer, OUT min_lowercase integer, OUT max_rpt_chars integer, OUT policy_enable boolean, OUT track_login boolean, OUT max_inactivity interval, OUT use_password_strength_estimator boolean, OUT password_strength_estimator_score integer, OUT custom_function regproc)
 RETURNS record
 LANGUAGE internal
 STABLE PARALLEL SAFE STRICT
AS $function$enable_policy$function$
;
DROP FUNCTION IF EXISTS pg_catalog.enable_policy_by_id (roleoid oid, OUT roleid regrole, OUT reuse_time interval, OUT in_history integer, OUT max_age interval, OUT min_age interval, OUT grace_login_limit integer, OUT grace_login_time_limit interval, OUT expire_warning interval, OUT lockout boolean, OUT lockout_duration interval, OUT max_failure integer, OUT failure_count_interval interval, OUT check_syntax boolean, OUT min_length integer, OUT illegal_values boolean, OUT alpha_numeric integer, OUT min_alpha_chars integer, OUT min_special_chars integer, OUT min_uppercase integer, OUT min_lowercase integer, OUT max_rpt_chars integer, OUT policy_enable boolean, OUT track_login boolean, OUT max_inactivity interval, OUT use_password_strength_estimator boolean, OUT password_strength_estimator_score integer, OUT custom_function regproc);
CREATE OR REPLACE FUNCTION pg_catalog.enable_policy_by_id(roleoid oid, OUT roleid regrole, OUT reuse_time interval, OUT in_history integer, OUT max_age interval, OUT min_age interval, OUT grace_login_limit integer, OUT grace_login_time_limit interval, OUT expire_warning interval, OUT lockout boolean, OUT lockout_duration interval, OUT max_failure integer, OUT failure_count_interval interval, OUT check_syntax boolean, OUT min_length integer, OUT illegal_values boolean, OUT alpha_numeric integer, OUT min_alpha_chars integer, OUT min_special_chars integer, OUT min_uppercase integer, OUT min_lowercase integer, OUT max_rpt_chars integer, OUT policy_enable boolean, OUT track_login boolean, OUT max_inactivity interval, OUT use_password_strength_estimator boolean, OUT password_strength_estimator_score integer, OUT custom_function regproc)
 RETURNS record
 LANGUAGE internal
 STABLE PARALLEL SAFE STRICT
AS $function$enable_policy_by_id$function$
;
DROP FUNCTION IF EXISTS pg_catalog.expire_warning (policy_value interval, OUT name text, OUT value interval);
CREATE OR REPLACE FUNCTION pg_catalog.expire_warning(policy_value interval, OUT name text, OUT value interval)
 RETURNS record
 LANGUAGE internal
 STABLE PARALLEL SAFE
AS $function$create_expire_warning_policy$function$
;
DROP FUNCTION IF EXISTS pg_catalog.failure_count_interval (policy_value interval, OUT name text, OUT value interval);
CREATE OR REPLACE FUNCTION pg_catalog.failure_count_interval(policy_value interval, OUT name text, OUT value interval)
 RETURNS record
 LANGUAGE internal
 STABLE PARALLEL SAFE
AS $function$create_failure_count_interval_policy$function$
;
DROP FUNCTION IF EXISTS pg_catalog.fc_interval (policy_value interval, OUT name text, OUT value interval);
CREATE OR REPLACE FUNCTION pg_catalog.fc_interval(policy_value interval, OUT name text, OUT value interval)
 RETURNS record
 LANGUAGE internal
 STABLE PARALLEL SAFE
AS $function$create_failure_count_interval_policy$function$
;
DROP FUNCTION IF EXISTS pg_catalog.get_encryption_keys_count ();
CREATE OR REPLACE FUNCTION pg_catalog.get_encryption_keys_count()
 RETURNS integer
 LANGUAGE internal
 STABLE PARALLEL SAFE STRICT
AS $function$get_encryption_keys_count$function$
;
DROP FUNCTION IF EXISTS pg_catalog.get_password_policy_profile (OUT roleid regrole, OUT fail_counter integer, OUT last_fail_time timestamp with time zone, OUT grace_success_counter integer, OUT last_success_time timestamp with time zone, OUT create_time timestamp with time zone, OUT unblock_expiry_time timestamp with time zone);
CREATE OR REPLACE FUNCTION pg_catalog.get_password_policy_profile(OUT roleid regrole, OUT fail_counter integer, OUT last_fail_time timestamp with time zone, OUT grace_success_counter integer, OUT last_success_time timestamp with time zone, OUT create_time timestamp with time zone, OUT unblock_expiry_time timestamp with time zone)
 RETURNS SETOF record
 LANGUAGE internal
 STABLE PARALLEL SAFE STRICT
AS $function$get_password_policy_profile$function$
;
DROP FUNCTION IF EXISTS pg_catalog.grace_li (policy_value integer, OUT name text, OUT value integer);
CREATE OR REPLACE FUNCTION pg_catalog.grace_li(policy_value integer, OUT name text, OUT value integer)
 RETURNS record
 LANGUAGE internal
 STABLE PARALLEL SAFE
AS $function$create_grace_login_limit_policy$function$
;
DROP FUNCTION IF EXISTS pg_catalog.grace_login_limit (policy_value integer, OUT name text, OUT value integer);
CREATE OR REPLACE FUNCTION pg_catalog.grace_login_limit(policy_value integer, OUT name text, OUT value integer)
 RETURNS record
 LANGUAGE internal
 STABLE PARALLEL SAFE
AS $function$create_grace_login_limit_policy$function$
;
DROP FUNCTION IF EXISTS pg_catalog.grace_login_time_limit (policy_value interval, OUT name text, OUT value interval);
CREATE OR REPLACE FUNCTION pg_catalog.grace_login_time_limit(policy_value interval, OUT name text, OUT value interval)
 RETURNS record
 LANGUAGE internal
 STABLE PARALLEL SAFE
AS $function$create_grace_login_time_limit_policy$function$
;
DROP FUNCTION IF EXISTS pg_catalog.grace_lti (policy_value interval, OUT name text, OUT value interval);
CREATE OR REPLACE FUNCTION pg_catalog.grace_lti(policy_value interval, OUT name text, OUT value interval)
 RETURNS record
 LANGUAGE internal
 STABLE PARALLEL SAFE
AS $function$create_grace_login_time_limit_policy$function$
;
DROP FUNCTION IF EXISTS pg_catalog.illegal_values (policy_value boolean, OUT name text, OUT value boolean);
CREATE OR REPLACE FUNCTION pg_catalog.illegal_values(policy_value boolean, OUT name text, OUT value boolean)
 RETURNS record
 LANGUAGE internal
 STABLE PARALLEL SAFE
AS $function$create_illegal_values_policy$function$
;
DROP FUNCTION IF EXISTS pg_catalog.in_history (policy_value integer, OUT name text, OUT value integer);
CREATE OR REPLACE FUNCTION pg_catalog.in_history(policy_value integer, OUT name text, OUT value integer)
 RETURNS record
 LANGUAGE internal
 STABLE PARALLEL SAFE
AS $function$create_in_history_policy$function$
;
DROP FUNCTION IF EXISTS pg_catalog.lduration (policy_value interval, OUT name text, OUT value interval);
CREATE OR REPLACE FUNCTION pg_catalog.lduration(policy_value interval, OUT name text, OUT value interval)
 RETURNS record
 LANGUAGE internal
 STABLE PARALLEL SAFE
AS $function$create_lockout_duration_policy$function$
;
DROP FUNCTION IF EXISTS pg_catalog.lockout (policy_value boolean, OUT name text, OUT value boolean);
CREATE OR REPLACE FUNCTION pg_catalog.lockout(policy_value boolean, OUT name text, OUT value boolean)
 RETURNS record
 LANGUAGE internal
 STABLE PARALLEL SAFE
AS $function$create_lockout_policy$function$
;
DROP FUNCTION IF EXISTS pg_catalog.lockout_duration (policy_value interval, OUT name text, OUT value interval);
CREATE OR REPLACE FUNCTION pg_catalog.lockout_duration(policy_value interval, OUT name text, OUT value interval)
 RETURNS record
 LANGUAGE internal
 STABLE PARALLEL SAFE
AS $function$create_lockout_duration_policy$function$
;
DROP FUNCTION IF EXISTS pg_catalog.max_age (policy_value interval, OUT name text, OUT value interval);
CREATE OR REPLACE FUNCTION pg_catalog.max_age(policy_value interval, OUT name text, OUT value interval)
 RETURNS record
 LANGUAGE internal
 STABLE PARALLEL SAFE
AS $function$create_max_age_policy$function$
;
DROP FUNCTION IF EXISTS pg_catalog.max_failure (policy_value integer, OUT name text, OUT value integer);
CREATE OR REPLACE FUNCTION pg_catalog.max_failure(policy_value integer, OUT name text, OUT value integer)
 RETURNS record
 LANGUAGE internal
 STABLE PARALLEL SAFE
AS $function$create_max_failure_policy$function$
;
DROP FUNCTION IF EXISTS pg_catalog.max_inactivity (policy_value interval, OUT name text, OUT value interval);
CREATE OR REPLACE FUNCTION pg_catalog.max_inactivity(policy_value interval, OUT name text, OUT value interval)
 RETURNS record
 LANGUAGE internal
 STABLE PARALLEL SAFE
AS $function$create_max_inactivity_policy$function$
;
DROP FUNCTION IF EXISTS pg_catalog.max_rpt_chars (policy_value integer, OUT name text, OUT value integer);
CREATE OR REPLACE FUNCTION pg_catalog.max_rpt_chars(policy_value integer, OUT name text, OUT value integer)
 RETURNS record
 LANGUAGE internal
 STABLE PARALLEL SAFE
AS $function$create_max_rpt_chars_policy$function$
;
DROP FUNCTION IF EXISTS pg_catalog.min_age (policy_value interval, OUT name text, OUT value interval);
CREATE OR REPLACE FUNCTION pg_catalog.min_age(policy_value interval, OUT name text, OUT value interval)
 RETURNS record
 LANGUAGE internal
 STABLE PARALLEL SAFE
AS $function$create_min_age_policy$function$
;
DROP FUNCTION IF EXISTS pg_catalog.min_alpha_chars (policy_value integer, OUT name text, OUT value integer);
CREATE OR REPLACE FUNCTION pg_catalog.min_alpha_chars(policy_value integer, OUT name text, OUT value integer)
 RETURNS record
 LANGUAGE internal
 STABLE PARALLEL SAFE
AS $function$create_min_alpha_chars_policy$function$
;
DROP FUNCTION IF EXISTS pg_catalog.min_length (policy_value integer, OUT name text, OUT value integer);
CREATE OR REPLACE FUNCTION pg_catalog.min_length(policy_value integer, OUT name text, OUT value integer)
 RETURNS record
 LANGUAGE internal
 STABLE PARALLEL SAFE
AS $function$create_min_length_policy$function$
;
DROP FUNCTION IF EXISTS pg_catalog.min_lowercase (policy_value integer, OUT name text, OUT value integer);
CREATE OR REPLACE FUNCTION pg_catalog.min_lowercase(policy_value integer, OUT name text, OUT value integer)
 RETURNS record
 LANGUAGE internal
 STABLE PARALLEL SAFE
AS $function$create_min_lowercase_policy$function$
;
DROP FUNCTION IF EXISTS pg_catalog.min_special_chars (policy_value integer, OUT name text, OUT value integer);
CREATE OR REPLACE FUNCTION pg_catalog.min_special_chars(policy_value integer, OUT name text, OUT value integer)
 RETURNS record
 LANGUAGE internal
 STABLE PARALLEL SAFE
AS $function$create_min_special_chars_policy$function$
;
DROP FUNCTION IF EXISTS pg_catalog.min_uppercase (policy_value integer, OUT name text, OUT value integer);
CREATE OR REPLACE FUNCTION pg_catalog.min_uppercase(policy_value integer, OUT name text, OUT value integer)
 RETURNS record
 LANGUAGE internal
 STABLE PARALLEL SAFE
AS $function$create_min_uppercase_policy$function$
;
DROP FUNCTION IF EXISTS pg_catalog.password_strength_estimator_score (policy_value integer, OUT name text, OUT value integer);
CREATE OR REPLACE FUNCTION pg_catalog.password_strength_estimator_score(policy_value integer, OUT name text, OUT value integer)
 RETURNS record
 LANGUAGE internal
 STABLE PARALLEL SAFE
AS $function$create_password_strength_estimator_score_policy$function$
;
DROP FUNCTION IF EXISTS pg_catalog.pg_hostname ();
CREATE OR REPLACE FUNCTION pg_catalog.pg_hostname()
 RETURNS text
 LANGUAGE internal
 STABLE PARALLEL SAFE STRICT
AS $function$pg_hostname$function$
;
DROP FUNCTION IF EXISTS pg_catalog.policy_enable (policy_value boolean, OUT name text, OUT value boolean);
CREATE OR REPLACE FUNCTION pg_catalog.policy_enable(policy_value boolean, OUT name text, OUT value boolean)
 RETURNS record
 LANGUAGE internal
 STABLE PARALLEL SAFE
AS $function$create_policy_enable_policy$function$
;
DROP FUNCTION IF EXISTS pg_catalog.pp_check_role (rolename name, OUT roleid regrole, OUT fail_counter integer, OUT last_fail_time timestamp with time zone, OUT grace_success_counter integer, OUT last_success_time timestamp with time zone, OUT create_time timestamp with time zone, OUT unblock_expiry_time timestamp with time zone, OUT is_auth_available boolean, OUT is_blocked boolean, OUT check_policy_for_max_age boolean, OUT check_policy_for_max_age_text text, OUT check_policy_for_lockout boolean, OUT check_policy_for_lockout_text text, OUT check_policy_for_inactivity_check boolean, OUT check_policy_for_inactivity_check_text text, OUT check_policy_for_password_check boolean, OUT check_policy_for_password_check_text text, OUT check_lockout boolean, OUT check_lockout_text text, OUT check_inactivity boolean, OUT check_inactivity_text text, OUT check_password_age boolean, OUT check_password_age_text text);
CREATE OR REPLACE FUNCTION pg_catalog.pp_check_role(rolename name, OUT roleid regrole, OUT fail_counter integer, OUT last_fail_time timestamp with time zone, OUT grace_success_counter integer, OUT last_success_time timestamp with time zone, OUT create_time timestamp with time zone, OUT unblock_expiry_time timestamp with time zone, OUT is_auth_available boolean, OUT is_blocked boolean, OUT check_policy_for_max_age boolean, OUT check_policy_for_max_age_text text, OUT check_policy_for_lockout boolean, OUT check_policy_for_lockout_text text, OUT check_policy_for_inactivity_check boolean, OUT check_policy_for_inactivity_check_text text, OUT check_policy_for_password_check boolean, OUT check_policy_for_password_check_text text, OUT check_lockout boolean, OUT check_lockout_text text, OUT check_inactivity boolean, OUT check_inactivity_text text, OUT check_password_age boolean, OUT check_password_age_text text)
 RETURNS record
 LANGUAGE internal
 STABLE PARALLEL SAFE STRICT
AS $function$pp_check_role$function$
;
DROP FUNCTION IF EXISTS pg_catalog.pp_check_role_all (OUT roleid regrole, OUT fail_counter integer, OUT last_fail_time timestamp with time zone, OUT grace_success_counter integer, OUT last_success_time timestamp with time zone, OUT create_time timestamp with time zone, OUT unblock_expiry_time timestamp with time zone, OUT is_auth_available boolean, OUT is_blocked boolean, OUT check_policy_for_max_age boolean, OUT check_policy_for_max_age_text text, OUT check_policy_for_lockout boolean, OUT check_policy_for_lockout_text text, OUT check_policy_for_inactivity_check boolean, OUT check_policy_for_inactivity_check_text text, OUT check_policy_for_password_check boolean, OUT check_policy_for_password_check_text text, OUT check_lockout boolean, OUT check_lockout_text text, OUT check_inactivity boolean, OUT check_inactivity_text text, OUT check_password_age boolean, OUT check_password_age_text text);
CREATE OR REPLACE FUNCTION pg_catalog.pp_check_role_all(OUT roleid regrole, OUT fail_counter integer, OUT last_fail_time timestamp with time zone, OUT grace_success_counter integer, OUT last_success_time timestamp with time zone, OUT create_time timestamp with time zone, OUT unblock_expiry_time timestamp with time zone, OUT is_auth_available boolean, OUT is_blocked boolean, OUT check_policy_for_max_age boolean, OUT check_policy_for_max_age_text text, OUT check_policy_for_lockout boolean, OUT check_policy_for_lockout_text text, OUT check_policy_for_inactivity_check boolean, OUT check_policy_for_inactivity_check_text text, OUT check_policy_for_password_check boolean, OUT check_policy_for_password_check_text text, OUT check_lockout boolean, OUT check_lockout_text text, OUT check_inactivity boolean, OUT check_inactivity_text text, OUT check_password_age boolean, OUT check_password_age_text text)
 RETURNS SETOF record
 LANGUAGE internal
 STABLE PARALLEL SAFE STRICT
AS $function$pp_check_role_all$function$
;
DROP FUNCTION IF EXISTS pg_catalog.pp_check_role_by_id (roleid oid, OUT roleid regrole, OUT fail_counter integer, OUT last_fail_time timestamp with time zone, OUT grace_success_counter integer, OUT last_success_time timestamp with time zone, OUT create_time timestamp with time zone, OUT unblock_expiry_time timestamp with time zone, OUT is_auth_available boolean, OUT is_blocked boolean, OUT check_policy_for_max_age boolean, OUT check_policy_for_max_age_text text, OUT check_policy_for_lockout boolean, OUT check_policy_for_lockout_text text, OUT check_policy_for_inactivity_check boolean, OUT check_policy_for_inactivity_check_text text, OUT check_policy_for_password_check boolean, OUT check_policy_for_password_check_text text, OUT check_lockout boolean, OUT check_lockout_text text, OUT check_inactivity boolean, OUT check_inactivity_text text, OUT check_password_age boolean, OUT check_password_age_text text);
CREATE OR REPLACE FUNCTION pg_catalog.pp_check_role_by_id(roleid oid, OUT roleid regrole, OUT fail_counter integer, OUT last_fail_time timestamp with time zone, OUT grace_success_counter integer, OUT last_success_time timestamp with time zone, OUT create_time timestamp with time zone, OUT unblock_expiry_time timestamp with time zone, OUT is_auth_available boolean, OUT is_blocked boolean, OUT check_policy_for_max_age boolean, OUT check_policy_for_max_age_text text, OUT check_policy_for_lockout boolean, OUT check_policy_for_lockout_text text, OUT check_policy_for_inactivity_check boolean, OUT check_policy_for_inactivity_check_text text, OUT check_policy_for_password_check boolean, OUT check_policy_for_password_check_text text, OUT check_lockout boolean, OUT check_lockout_text text, OUT check_inactivity boolean, OUT check_inactivity_text text, OUT check_password_age boolean, OUT check_password_age_text text)
 RETURNS record
 LANGUAGE internal
 STABLE PARALLEL SAFE STRICT
AS $function$pp_check_role_by_id$function$
;
DROP FUNCTION IF EXISTS pg_catalog.recognize_password_policy (rolename name, OUT roleid regrole, OUT reuse_time interval, OUT in_history integer, OUT max_age interval, OUT min_age interval, OUT grace_login_limit integer, OUT grace_login_time_limit interval, OUT expire_warning interval, OUT lockout boolean, OUT lockout_duration interval, OUT max_failure integer, OUT failure_count_interval interval, OUT check_syntax boolean, OUT min_length integer, OUT illegal_values boolean, OUT alpha_numeric integer, OUT min_alpha_chars integer, OUT min_special_chars integer, OUT min_uppercase integer, OUT min_lowercase integer, OUT max_rpt_chars integer, OUT policy_enable boolean, OUT track_login boolean, OUT max_inactivity interval, OUT use_password_strength_estimator boolean, OUT password_strength_estimator_score integer, OUT custom_function regproc);
CREATE OR REPLACE FUNCTION pg_catalog.recognize_password_policy(rolename name, OUT roleid regrole, OUT reuse_time interval, OUT in_history integer, OUT max_age interval, OUT min_age interval, OUT grace_login_limit integer, OUT grace_login_time_limit interval, OUT expire_warning interval, OUT lockout boolean, OUT lockout_duration interval, OUT max_failure integer, OUT failure_count_interval interval, OUT check_syntax boolean, OUT min_length integer, OUT illegal_values boolean, OUT alpha_numeric integer, OUT min_alpha_chars integer, OUT min_special_chars integer, OUT min_uppercase integer, OUT min_lowercase integer, OUT max_rpt_chars integer, OUT policy_enable boolean, OUT track_login boolean, OUT max_inactivity interval, OUT use_password_strength_estimator boolean, OUT password_strength_estimator_score integer, OUT custom_function regproc)
 RETURNS record
 LANGUAGE internal
 STABLE PARALLEL SAFE STRICT
AS $function$recognize_password_policy$function$
;
DROP FUNCTION IF EXISTS pg_catalog.recognize_password_policy_by_id (roleoid oid, OUT roleid regrole, OUT reuse_time interval, OUT in_history integer, OUT max_age interval, OUT min_age interval, OUT grace_login_limit integer, OUT grace_login_time_limit interval, OUT expire_warning interval, OUT lockout boolean, OUT lockout_duration interval, OUT max_failure integer, OUT failure_count_interval interval, OUT check_syntax boolean, OUT min_length integer, OUT illegal_values boolean, OUT alpha_numeric integer, OUT min_alpha_chars integer, OUT min_special_chars integer, OUT min_uppercase integer, OUT min_lowercase integer, OUT max_rpt_chars integer, OUT policy_enable boolean, OUT track_login boolean, OUT max_inactivity interval, OUT use_password_strength_estimator boolean, OUT password_strength_estimator_score integer, OUT custom_function regproc);
CREATE OR REPLACE FUNCTION pg_catalog.recognize_password_policy_by_id(roleoid oid, OUT roleid regrole, OUT reuse_time interval, OUT in_history integer, OUT max_age interval, OUT min_age interval, OUT grace_login_limit integer, OUT grace_login_time_limit interval, OUT expire_warning interval, OUT lockout boolean, OUT lockout_duration interval, OUT max_failure integer, OUT failure_count_interval interval, OUT check_syntax boolean, OUT min_length integer, OUT illegal_values boolean, OUT alpha_numeric integer, OUT min_alpha_chars integer, OUT min_special_chars integer, OUT min_uppercase integer, OUT min_lowercase integer, OUT max_rpt_chars integer, OUT policy_enable boolean, OUT track_login boolean, OUT max_inactivity interval, OUT use_password_strength_estimator boolean, OUT password_strength_estimator_score integer, OUT custom_function regproc)
 RETURNS record
 LANGUAGE internal
 STABLE PARALLEL SAFE STRICT
AS $function$recognize_password_policy_by_id$function$
;
DROP FUNCTION IF EXISTS pg_catalog.recognize_password_policy_detailed (name name, OUT policy_name text, OUT value text, OUT source_type text, OUT source text);
CREATE OR REPLACE FUNCTION pg_catalog.recognize_password_policy_detailed(name name, OUT policy_name text, OUT value text, OUT source_type text, OUT source text)
 RETURNS record
 LANGUAGE internal
 STABLE PARALLEL SAFE STRICT
AS $function$recognize_password_policy_detailed$function$
;
DROP FUNCTION IF EXISTS pg_catalog.recognize_password_policy_detailed_by_id (roleoid oid, OUT policy_name text, OUT value text, OUT source_type text, OUT source text);
CREATE OR REPLACE FUNCTION pg_catalog.recognize_password_policy_detailed_by_id(roleoid oid, OUT policy_name text, OUT value text, OUT source_type text, OUT source text)
 RETURNS record
 LANGUAGE internal
 STABLE PARALLEL SAFE STRICT
AS $function$recognize_password_policy_detailed_by_id$function$
;
DROP FUNCTION IF EXISTS pg_catalog.reuse_time (policy_value interval, OUT name text, OUT value interval);
CREATE OR REPLACE FUNCTION pg_catalog.reuse_time(policy_value interval, OUT name text, OUT value interval)
 RETURNS record
 LANGUAGE internal
 STABLE PARALLEL SAFE
AS $function$create_reuse_time_policy$function$
;
DROP FUNCTION IF EXISTS pg_catalog.sber_version ();
CREATE OR REPLACE FUNCTION pg_catalog.sber_version()
 RETURNS text
 LANGUAGE internal
 STABLE PARALLEL SAFE STRICT
AS $function$sber_version$function$
;
DROP FUNCTION IF EXISTS pg_catalog.select_all_password_policies (OUT roleid regrole, OUT reuse_time interval, OUT in_history integer, OUT max_age interval, OUT min_age interval, OUT grace_login_limit integer, OUT grace_login_time_limit interval, OUT expire_warning interval, OUT lockout boolean, OUT lockout_duration interval, OUT max_failure integer, OUT failure_count_interval interval, OUT check_syntax boolean, OUT min_length integer, OUT illegal_values boolean, OUT alpha_numeric integer, OUT min_alpha_chars integer, OUT min_special_chars integer, OUT min_uppercase integer, OUT min_lowercase integer, OUT max_rpt_chars integer, OUT policy_enable boolean, OUT track_login boolean, OUT max_inactivity interval, OUT use_password_strength_estimator boolean, OUT password_strength_estimator_score integer, OUT custom_function regproc);
CREATE OR REPLACE FUNCTION pg_catalog.select_all_password_policies(OUT roleid regrole, OUT reuse_time interval, OUT in_history integer, OUT max_age interval, OUT min_age interval, OUT grace_login_limit integer, OUT grace_login_time_limit interval, OUT expire_warning interval, OUT lockout boolean, OUT lockout_duration interval, OUT max_failure integer, OUT failure_count_interval interval, OUT check_syntax boolean, OUT min_length integer, OUT illegal_values boolean, OUT alpha_numeric integer, OUT min_alpha_chars integer, OUT min_special_chars integer, OUT min_uppercase integer, OUT min_lowercase integer, OUT max_rpt_chars integer, OUT policy_enable boolean, OUT track_login boolean, OUT max_inactivity interval, OUT use_password_strength_estimator boolean, OUT password_strength_estimator_score integer, OUT custom_function regproc)
 RETURNS SETOF record
 LANGUAGE internal
 STABLE PARALLEL SAFE STRICT
AS $function$select_all_password_policies$function$
;
DROP FUNCTION IF EXISTS pg_catalog.set_role_policies (rolname name, VARIADIC policies record[], OUT roleid regrole, OUT reuse_time interval, OUT in_history integer, OUT max_age interval, OUT min_age interval, OUT grace_login_limit integer, OUT grace_login_time_limit interval, OUT expire_warning interval, OUT lockout boolean, OUT lockout_duration interval, OUT max_failure integer, OUT failure_count_interval interval, OUT check_syntax boolean, OUT min_length integer, OUT illegal_values boolean, OUT alpha_numeric integer, OUT min_alpha_chars integer, OUT min_special_chars integer, OUT min_uppercase integer, OUT min_lowercase integer, OUT max_rpt_chars integer, OUT policy_enable boolean, OUT track_login boolean, OUT max_inactivity interval, OUT use_password_strength_estimator boolean, OUT password_strength_estimator_score integer, OUT custom_function regproc);
CREATE OR REPLACE FUNCTION pg_catalog.set_role_policies(rolname name, VARIADIC policies record[], OUT roleid regrole, OUT reuse_time interval, OUT in_history integer, OUT max_age interval, OUT min_age interval, OUT grace_login_limit integer, OUT grace_login_time_limit interval, OUT expire_warning interval, OUT lockout boolean, OUT lockout_duration interval, OUT max_failure integer, OUT failure_count_interval interval, OUT check_syntax boolean, OUT min_length integer, OUT illegal_values boolean, OUT alpha_numeric integer, OUT min_alpha_chars integer, OUT min_special_chars integer, OUT min_uppercase integer, OUT min_lowercase integer, OUT max_rpt_chars integer, OUT policy_enable boolean, OUT track_login boolean, OUT max_inactivity interval, OUT use_password_strength_estimator boolean, OUT password_strength_estimator_score integer, OUT custom_function regproc)
 RETURNS record
 LANGUAGE internal
 STABLE PARALLEL SAFE STRICT
AS $function$set_role_policies$function$
;
DROP FUNCTION IF EXISTS pg_catalog.set_role_policies_by_id (roleid oid, VARIADIC policies record[], OUT roleid regrole, OUT reuse_time interval, OUT in_history integer, OUT max_age interval, OUT min_age interval, OUT grace_login_limit integer, OUT grace_login_time_limit interval, OUT expire_warning interval, OUT lockout boolean, OUT lockout_duration interval, OUT max_failure integer, OUT failure_count_interval interval, OUT check_syntax boolean, OUT min_length integer, OUT illegal_values boolean, OUT alpha_numeric integer, OUT min_alpha_chars integer, OUT min_special_chars integer, OUT min_uppercase integer, OUT min_lowercase integer, OUT max_rpt_chars integer, OUT policy_enable boolean, OUT track_login boolean, OUT max_inactivity interval, OUT use_password_strength_estimator boolean, OUT password_strength_estimator_score integer, OUT custom_function regproc);
CREATE OR REPLACE FUNCTION pg_catalog.set_role_policies_by_id(roleid oid, VARIADIC policies record[], OUT roleid regrole, OUT reuse_time interval, OUT in_history integer, OUT max_age interval, OUT min_age interval, OUT grace_login_limit integer, OUT grace_login_time_limit interval, OUT expire_warning interval, OUT lockout boolean, OUT lockout_duration interval, OUT max_failure integer, OUT failure_count_interval interval, OUT check_syntax boolean, OUT min_length integer, OUT illegal_values boolean, OUT alpha_numeric integer, OUT min_alpha_chars integer, OUT min_special_chars integer, OUT min_uppercase integer, OUT min_lowercase integer, OUT max_rpt_chars integer, OUT policy_enable boolean, OUT track_login boolean, OUT max_inactivity interval, OUT use_password_strength_estimator boolean, OUT password_strength_estimator_score integer, OUT custom_function regproc)
 RETURNS record
 LANGUAGE internal
 STABLE PARALLEL SAFE STRICT
AS $function$set_role_policies_by_id$function$
;
DROP FUNCTION IF EXISTS pg_catalog.track_login (policy_value boolean, OUT name text, OUT value boolean);
CREATE OR REPLACE FUNCTION pg_catalog.track_login(policy_value boolean, OUT name text, OUT value boolean)
 RETURNS record
 LANGUAGE internal
 STABLE PARALLEL SAFE
AS $function$create_track_login_policy$function$
;
DROP FUNCTION IF EXISTS pg_catalog.unblock_role (role_name name);
CREATE OR REPLACE FUNCTION pg_catalog.unblock_role(role_name name)
 RETURNS boolean
 LANGUAGE internal
 STABLE PARALLEL SAFE STRICT
AS $function$unblock_role$function$
;
DROP FUNCTION IF EXISTS pg_catalog.unblock_role_by_id (role_name oid);
CREATE OR REPLACE FUNCTION pg_catalog.unblock_role_by_id(role_name oid)
 RETURNS boolean
 LANGUAGE internal
 STABLE PARALLEL SAFE STRICT
AS $function$unblock_role_by_id$function$
;
DROP FUNCTION IF EXISTS pg_catalog.use_password_strength_estimator (policy_value boolean, OUT name text, OUT value boolean);
CREATE OR REPLACE FUNCTION pg_catalog.use_password_strength_estimator(policy_value boolean, OUT name text, OUT value boolean)
 RETURNS record
 LANGUAGE internal
 STABLE PARALLEL SAFE
AS $function$create_use_password_strength_estimator_policy$function$
;
DROP FUNCTION IF EXISTS pg_catalog.use_zxcvbn (policy_value boolean, OUT name text, OUT value boolean);
CREATE OR REPLACE FUNCTION pg_catalog.use_zxcvbn(policy_value boolean, OUT name text, OUT value boolean)
 RETURNS record
 LANGUAGE internal
 STABLE PARALLEL SAFE
AS $function$create_use_password_strength_estimator_policy$function$
;
DROP FUNCTION IF EXISTS pg_catalog.zxcvbn_score (policy_value integer, OUT name text, OUT value integer);
CREATE OR REPLACE FUNCTION pg_catalog.zxcvbn_score(policy_value integer, OUT name text, OUT value integer)
 RETURNS record
 LANGUAGE internal
 STABLE PARALLEL SAFE
AS $function$create_password_strength_estimator_score_policy$function$
;
DROP FUNCTION IF EXISTS pg_catalog.add_auth_record_to_storage(host text, port integer, database name, username name, password text);
CREATE OR REPLACE FUNCTION pg_catalog.add_auth_record_to_storage(host text, port integer, database name, username name, password text)
  RETURNS void
  LANGUAGE internal
  STABLE PARALLEL SAFE
 AS $function$add_auth_record_to_storage$function$
;
reindex index pg_proc_oid_index;
reindex index pg_proc_proname_args_nsp_index;