CREATE OR REPLACE FUNCTION ext.get_role_passwd()
RETURNS TABLE (username TEXT, password TEXT) AS
$$
BEGIN
RETURN QUERY
SELECT usename::TEXT, passwd::TEXT FROM pg_shadow;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER
;