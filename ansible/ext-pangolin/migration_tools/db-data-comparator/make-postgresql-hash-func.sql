CREATE OR REPLACE FUNCTION gettexthash(
    p_clob text)
    RETURNS text AS
$BODY$
DECLARE
    l_hash text := '';
BEGIN
    if (p_clob is null) then
       return null;
    end if;
    for i in 1..ceil(length(p_clob)::float/2000)::integer loop
       select md5(l_hash || md5(substring(p_clob from (i-1)*2000 + 1 for 2000)))
          into l_hash;
    end loop;
    return l_hash;
END;
$BODY$
    language plpgsql;

CREATE OR REPLACE FUNCTION getbyteahash(
    p_blob bytea)
    RETURNS text AS
$BODY$
DECLARE
    l_hash text := '';
BEGIN
    if (p_blob is null) then
       return null;
    end if;
    for i in 1..ceil(octet_length(p_blob)::float/2000)::integer loop
       select md5(l_hash || md5(encode(substring(p_blob from (i-1)*2000 + 1 for 2000), 'hex')))
          into l_hash;
    end loop;
    return l_hash;
END;
$BODY$
    language plpgsql;

CREATE OR REPLACE FUNCTION gettableparthash(
    req text,
    toDate timestamp with time zone,
    fromDate timestamp with time zone,
    toDateFlag integer,
    fromDateFlag integer,
    batchNum integer)
    RETURNS text AS
$BODY$
DECLARE
    hash text := '';
    rec RECORD;
BEGIN
    FOR rec IN EXECUTE req USING fromDateFlag, toDateFlag, fromDate, toDate, batchNum LOOP
        hash := md5(hash||rec.hash);
    END LOOP;
    return hash;
END;
$BODY$
    language plpgsql;