UPDATE pg_class SET relnamespace=(select oid from pg_namespace where nspname='public') where relname='pp_password';
DROP VIEW IF EXISTS pp_password;

CREATE VIEW public.pp_password AS
    SELECT
        pp.roleid AS roloid,
        pp.fail_counter AS failcounter,
        pp.last_fail_time AS lastfailtime,
        pp.grace_success_counter AS gracesuccesscounter,
        pp.last_success_time AS lastsuccesstime,
        pp.create_time AS createtime,
        pp.unblock_expiry_time AS unblockexpirytime
    FROM get_password_policy_profile() AS pp;

UPDATE pg_class SET relnamespace=11 where relname='pp_password';
UPDATE pg_type SET typnamespace=11 where typname='pp_password';
REVOKE ALL on pg_catalog.pp_password FROM public;

UPDATE pg_class SET relnamespace=(select oid from pg_namespace where nspname='public') where relname='pp_password_detailed';
DROP VIEW IF EXISTS pp_password_detailed;

CREATE VIEW public.pp_password_detailed AS
    SELECT
        pp.roleid AS roloid,
        pp.fail_counter AS failcounter,
        pp.last_fail_time AS lastfailtime,
        pp.grace_success_counter AS gracesuccesscounter,
        pp.last_success_time AS lastsuccesstime,
        pp.create_time AS createtime,
        pp.unblock_expiry_time AS unblockexpirytime,
        pp.is_auth_available AS is_auth_available,
        pp.is_blocked AS is_blocked,
        pp.check_policy_for_max_age AS check_policy_for_max_age,
        pp.check_policy_for_max_age_text AS check_policy_for_max_age_text,
        pp.check_policy_for_lockout AS check_policy_for_lockout,
        pp.check_policy_for_lockout_text AS check_policy_for_lockout_text,
        pp.check_policy_for_inactivity_check AS check_policy_for_inactivity_check,
        pp.check_policy_for_inactivity_check_text AS check_policy_for_inactivity_check_text,
        pp.check_policy_for_password_check AS check_policy_for_password_check,
        pp.check_policy_for_password_check_text AS check_policy_for_password_check_text,
        pp.check_lockout AS check_lockout,
        pp.check_lockout_text AS check_lockout_text,
        pp.check_inactivity AS check_inactivity,
        pp.check_inactivity_text AS check_inactivity_text,
        pp.check_password_age AS check_password_age,
        pp.check_password_age_text AS check_password_age_text
    FROM pp_check_role_all() AS pp;

UPDATE pg_class SET relnamespace=11 where relname='pp_password_detailed';
UPDATE pg_type SET typnamespace=11 where typname='pp_password_detailed';
REVOKE ALL on pg_catalog.pp_password_detailed FROM public;

reindex index pg_class_oid_index;
reindex index pg_class_relname_nsp_index;
reindex index pg_class_tblspc_relfilenode_index;
reindex index pg_type_oid_index;
reindex index pg_type_typname_nsp_index;