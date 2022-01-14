PGDMP  	        1                 z            taiga #   12.9 (Ubuntu 12.9-0ubuntu0.20.04.1) #   12.9 (Ubuntu 12.9-0ubuntu0.20.04.1) �              0    0    ENCODING    ENCODING        SET client_encoding = 'UTF8';
                      false            �           0    0 
   STDSTRINGS 
   STDSTRINGS     (   SET standard_conforming_strings = 'on';
                      false            �           0    0 
   SEARCHPATH 
   SEARCHPATH     8   SELECT pg_catalog.set_config('search_path', '', false);
                      false            �           1262    9776739    taiga    DATABASE     w   CREATE DATABASE taiga WITH TEMPLATE = template0 ENCODING = 'UTF8' LC_COLLATE = 'en_US.UTF-8' LC_CTYPE = 'en_US.UTF-8';
    DROP DATABASE taiga;
                taiga    false            n           1255    9777888    array_distinct(anyarray)    FUNCTION     �   CREATE FUNCTION public.array_distinct(anyarray) RETURNS anyarray
    LANGUAGE sql
    AS $_$
              SELECT ARRAY(SELECT DISTINCT unnest($1))
            $_$;
 /   DROP FUNCTION public.array_distinct(anyarray);
       public          taiga    false            }           1255    9778299 '   clean_key_in_custom_attributes_values()    FUNCTION     �  CREATE FUNCTION public.clean_key_in_custom_attributes_values() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
                       DECLARE
                               key text;
                               project_id int;
                               object_id int;
                               attribute text;
                               tablename text;
                               custom_attributes_tablename text;
                         BEGIN
                               key := OLD.id::text;
                               project_id := OLD.project_id;
                               attribute := TG_ARGV[0]::text;
                               tablename := TG_ARGV[1]::text;
                               custom_attributes_tablename := TG_ARGV[2]::text;

                               EXECUTE 'UPDATE ' || quote_ident(custom_attributes_tablename) || '
                                           SET attributes_values = json_object_delete_keys(attributes_values, ' || quote_literal(key) || ')
                                          FROM ' || quote_ident(tablename) || '
                                         WHERE ' || quote_ident(tablename) || '.project_id = ' || project_id || '
                                           AND ' || quote_ident(custom_attributes_tablename) || '.' || quote_ident(attribute) || ' = ' || quote_ident(tablename) || '.id';
                               RETURN NULL;
                           END; $$;
 >   DROP FUNCTION public.clean_key_in_custom_attributes_values();
       public          taiga    false            l           1255    9777858 !   inmutable_array_to_string(text[])    FUNCTION     �   CREATE FUNCTION public.inmutable_array_to_string(text[]) RETURNS text
    LANGUAGE sql IMMUTABLE
    AS $_$SELECT array_to_string($1, ' ', '')$_$;
 8   DROP FUNCTION public.inmutable_array_to_string(text[]);
       public          taiga    false            p           1255    9778298 %   json_object_delete_keys(json, text[])    FUNCTION     �  CREATE FUNCTION public.json_object_delete_keys(json json, VARIADIC keys_to_delete text[]) RETURNS json
    LANGUAGE sql IMMUTABLE STRICT
    AS $$
                   SELECT COALESCE ((SELECT ('{' || string_agg(to_json("key") || ':' || "value", ',') || '}')
                                       FROM json_each("json")
                                      WHERE "key" <> ALL ("keys_to_delete")),
                                    '{}')::json $$;
 Y   DROP FUNCTION public.json_object_delete_keys(json json, VARIADIC keys_to_delete text[]);
       public          taiga    false            ~           1255    9778423 &   json_object_delete_keys(jsonb, text[])    FUNCTION     �  CREATE FUNCTION public.json_object_delete_keys(json jsonb, VARIADIC keys_to_delete text[]) RETURNS jsonb
    LANGUAGE sql IMMUTABLE STRICT
    AS $$
                   SELECT COALESCE ((SELECT ('{' || string_agg(to_json("key") || ':' || "value", ',') || '}')
                                       FROM jsonb_each("json")
                                      WHERE "key" <> ALL ("keys_to_delete")),
                                    '{}')::text::jsonb $$;
 Z   DROP FUNCTION public.json_object_delete_keys(json jsonb, VARIADIC keys_to_delete text[]);
       public          taiga    false            m           1255    9777886    reduce_dim(anyarray)    FUNCTION     �  CREATE FUNCTION public.reduce_dim(anyarray) RETURNS SETOF anyarray
    LANGUAGE plpgsql IMMUTABLE
    AS $_$
            DECLARE
                s $1%TYPE;
            BEGIN
                IF $1 = '{}' THEN
                	RETURN;
                END IF;
                FOREACH s SLICE 1 IN ARRAY $1 LOOP
                    RETURN NEXT s;
                END LOOP;
                RETURN;
            END;
            $_$;
 +   DROP FUNCTION public.reduce_dim(anyarray);
       public          taiga    false            o           1255    9777889    update_project_tags_colors()    FUNCTION     �  CREATE FUNCTION public.update_project_tags_colors() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
            DECLARE
            	tags text[];
            	project_tags_colors text[];
            	tag_color text[];
            	project_tags text[];
            	tag text;
            	project_id integer;
            BEGIN
            	tags := NEW.tags::text[];
            	project_id := NEW.project_id::integer;
            	project_tags := '{}';

            	-- Read project tags_colors into project_tags_colors
            	SELECT projects_project.tags_colors INTO project_tags_colors
                FROM projects_project
                WHERE id = project_id;

            	-- Extract just the project tags to project_tags_colors
                IF project_tags_colors != ARRAY[]::text[] THEN
                    FOREACH tag_color SLICE 1 in ARRAY project_tags_colors
                    LOOP
                        project_tags := array_append(project_tags, tag_color[1]);
                    END LOOP;
                END IF;

            	-- Add to project_tags_colors the new tags
                IF tags IS NOT NULL THEN
                    FOREACH tag in ARRAY tags
                    LOOP
                        IF tag != ALL(project_tags) THEN
                            project_tags_colors := array_cat(project_tags_colors,
                                                             ARRAY[ARRAY[tag, NULL]]);
                        END IF;
                    END LOOP;
                END IF;

            	-- Save the result in the tags_colors column
                UPDATE projects_project
                SET tags_colors = project_tags_colors
                WHERE id = project_id;

            	RETURN NULL;
            END; $$;
 3   DROP FUNCTION public.update_project_tags_colors();
       public          taiga    false            |           1255    9777887    array_agg_mult(anyarray) 	   AGGREGATE     w   CREATE AGGREGATE public.array_agg_mult(anyarray) (
    SFUNC = array_cat,
    STYPE = anyarray,
    INITCOND = '{}'
);
 0   DROP AGGREGATE public.array_agg_mult(anyarray);
       public          taiga    false            �           3600    9777786    english_stem_nostop    TEXT SEARCH DICTIONARY     {   CREATE TEXT SEARCH DICTIONARY public.english_stem_nostop (
    TEMPLATE = pg_catalog.snowball,
    language = 'english' );
 8   DROP TEXT SEARCH DICTIONARY public.english_stem_nostop;
       public          taiga    false            �           3602    9777787    english_nostop    TEXT SEARCH CONFIGURATION     �  CREATE TEXT SEARCH CONFIGURATION public.english_nostop (
    PARSER = pg_catalog."default" );

ALTER TEXT SEARCH CONFIGURATION public.english_nostop
    ADD MAPPING FOR asciiword WITH public.english_stem_nostop;

ALTER TEXT SEARCH CONFIGURATION public.english_nostop
    ADD MAPPING FOR word WITH public.english_stem_nostop;

ALTER TEXT SEARCH CONFIGURATION public.english_nostop
    ADD MAPPING FOR numword WITH simple;

ALTER TEXT SEARCH CONFIGURATION public.english_nostop
    ADD MAPPING FOR email WITH simple;

ALTER TEXT SEARCH CONFIGURATION public.english_nostop
    ADD MAPPING FOR url WITH simple;

ALTER TEXT SEARCH CONFIGURATION public.english_nostop
    ADD MAPPING FOR host WITH simple;

ALTER TEXT SEARCH CONFIGURATION public.english_nostop
    ADD MAPPING FOR sfloat WITH simple;

ALTER TEXT SEARCH CONFIGURATION public.english_nostop
    ADD MAPPING FOR version WITH simple;

ALTER TEXT SEARCH CONFIGURATION public.english_nostop
    ADD MAPPING FOR hword_numpart WITH simple;

ALTER TEXT SEARCH CONFIGURATION public.english_nostop
    ADD MAPPING FOR hword_part WITH public.english_stem_nostop;

ALTER TEXT SEARCH CONFIGURATION public.english_nostop
    ADD MAPPING FOR hword_asciipart WITH public.english_stem_nostop;

ALTER TEXT SEARCH CONFIGURATION public.english_nostop
    ADD MAPPING FOR numhword WITH simple;

ALTER TEXT SEARCH CONFIGURATION public.english_nostop
    ADD MAPPING FOR asciihword WITH public.english_stem_nostop;

ALTER TEXT SEARCH CONFIGURATION public.english_nostop
    ADD MAPPING FOR hword WITH public.english_stem_nostop;

ALTER TEXT SEARCH CONFIGURATION public.english_nostop
    ADD MAPPING FOR url_path WITH simple;

ALTER TEXT SEARCH CONFIGURATION public.english_nostop
    ADD MAPPING FOR file WITH simple;

ALTER TEXT SEARCH CONFIGURATION public.english_nostop
    ADD MAPPING FOR "float" WITH simple;

ALTER TEXT SEARCH CONFIGURATION public.english_nostop
    ADD MAPPING FOR "int" WITH simple;

ALTER TEXT SEARCH CONFIGURATION public.english_nostop
    ADD MAPPING FOR uint WITH simple;
 6   DROP TEXT SEARCH CONFIGURATION public.english_nostop;
       public          taiga    false    2189            �            1259    9777048    attachments_attachment    TABLE     �  CREATE TABLE public.attachments_attachment (
    id integer NOT NULL,
    object_id integer NOT NULL,
    created_date timestamp with time zone NOT NULL,
    modified_date timestamp with time zone NOT NULL,
    attached_file character varying(500),
    is_deprecated boolean NOT NULL,
    description text NOT NULL,
    "order" integer NOT NULL,
    content_type_id integer NOT NULL,
    owner_id integer,
    project_id integer NOT NULL,
    name character varying(500) NOT NULL,
    size integer,
    sha1 character varying(40) NOT NULL,
    from_comment boolean NOT NULL,
    CONSTRAINT attachments_attachment_object_id_check CHECK ((object_id >= 0))
);
 *   DROP TABLE public.attachments_attachment;
       public         heap    taiga    false            �            1259    9777046    attachments_attachment_id_seq    SEQUENCE     �   CREATE SEQUENCE public.attachments_attachment_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
 4   DROP SEQUENCE public.attachments_attachment_id_seq;
       public          taiga    false    233            �           0    0    attachments_attachment_id_seq    SEQUENCE OWNED BY     _   ALTER SEQUENCE public.attachments_attachment_id_seq OWNED BY public.attachments_attachment.id;
          public          taiga    false    232            �            1259    9777095 
   auth_group    TABLE     f   CREATE TABLE public.auth_group (
    id integer NOT NULL,
    name character varying(150) NOT NULL
);
    DROP TABLE public.auth_group;
       public         heap    taiga    false            �            1259    9777093    auth_group_id_seq    SEQUENCE     �   CREATE SEQUENCE public.auth_group_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
 (   DROP SEQUENCE public.auth_group_id_seq;
       public          taiga    false    237            �           0    0    auth_group_id_seq    SEQUENCE OWNED BY     G   ALTER SEQUENCE public.auth_group_id_seq OWNED BY public.auth_group.id;
          public          taiga    false    236            �            1259    9777105    auth_group_permissions    TABLE     �   CREATE TABLE public.auth_group_permissions (
    id integer NOT NULL,
    group_id integer NOT NULL,
    permission_id integer NOT NULL
);
 *   DROP TABLE public.auth_group_permissions;
       public         heap    taiga    false            �            1259    9777103    auth_group_permissions_id_seq    SEQUENCE     �   CREATE SEQUENCE public.auth_group_permissions_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
 4   DROP SEQUENCE public.auth_group_permissions_id_seq;
       public          taiga    false    239            �           0    0    auth_group_permissions_id_seq    SEQUENCE OWNED BY     _   ALTER SEQUENCE public.auth_group_permissions_id_seq OWNED BY public.auth_group_permissions.id;
          public          taiga    false    238            �            1259    9777087    auth_permission    TABLE     �   CREATE TABLE public.auth_permission (
    id integer NOT NULL,
    name character varying(255) NOT NULL,
    content_type_id integer NOT NULL,
    codename character varying(100) NOT NULL
);
 #   DROP TABLE public.auth_permission;
       public         heap    taiga    false            �            1259    9777085    auth_permission_id_seq    SEQUENCE     �   CREATE SEQUENCE public.auth_permission_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
 -   DROP SEQUENCE public.auth_permission_id_seq;
       public          taiga    false    235            �           0    0    auth_permission_id_seq    SEQUENCE OWNED BY     Q   ALTER SEQUENCE public.auth_permission_id_seq OWNED BY public.auth_permission.id;
          public          taiga    false    234                       1259    9777978    contact_contactentry    TABLE     �   CREATE TABLE public.contact_contactentry (
    id integer NOT NULL,
    comment text NOT NULL,
    created_date timestamp with time zone NOT NULL,
    project_id integer NOT NULL,
    user_id integer NOT NULL
);
 (   DROP TABLE public.contact_contactentry;
       public         heap    taiga    false                       1259    9777976    contact_contactentry_id_seq    SEQUENCE     �   CREATE SEQUENCE public.contact_contactentry_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
 2   DROP SEQUENCE public.contact_contactentry_id_seq;
       public          taiga    false    271            �           0    0    contact_contactentry_id_seq    SEQUENCE OWNED BY     [   ALTER SEQUENCE public.contact_contactentry_id_seq OWNED BY public.contact_contactentry.id;
          public          taiga    false    270            &           1259    9778314 %   custom_attributes_epiccustomattribute    TABLE     �  CREATE TABLE public.custom_attributes_epiccustomattribute (
    id integer NOT NULL,
    name character varying(64) NOT NULL,
    description text NOT NULL,
    type character varying(16) NOT NULL,
    "order" bigint NOT NULL,
    created_date timestamp with time zone NOT NULL,
    modified_date timestamp with time zone NOT NULL,
    project_id integer NOT NULL,
    extra jsonb
);
 9   DROP TABLE public.custom_attributes_epiccustomattribute;
       public         heap    taiga    false            %           1259    9778312 ,   custom_attributes_epiccustomattribute_id_seq    SEQUENCE     �   CREATE SEQUENCE public.custom_attributes_epiccustomattribute_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
 C   DROP SEQUENCE public.custom_attributes_epiccustomattribute_id_seq;
       public          taiga    false    294            �           0    0 ,   custom_attributes_epiccustomattribute_id_seq    SEQUENCE OWNED BY     }   ALTER SEQUENCE public.custom_attributes_epiccustomattribute_id_seq OWNED BY public.custom_attributes_epiccustomattribute.id;
          public          taiga    false    293            (           1259    9778325 ,   custom_attributes_epiccustomattributesvalues    TABLE     �   CREATE TABLE public.custom_attributes_epiccustomattributesvalues (
    id integer NOT NULL,
    version integer NOT NULL,
    attributes_values jsonb NOT NULL,
    epic_id integer NOT NULL
);
 @   DROP TABLE public.custom_attributes_epiccustomattributesvalues;
       public         heap    taiga    false            '           1259    9778323 3   custom_attributes_epiccustomattributesvalues_id_seq    SEQUENCE     �   CREATE SEQUENCE public.custom_attributes_epiccustomattributesvalues_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
 J   DROP SEQUENCE public.custom_attributes_epiccustomattributesvalues_id_seq;
       public          taiga    false    296            �           0    0 3   custom_attributes_epiccustomattributesvalues_id_seq    SEQUENCE OWNED BY     �   ALTER SEQUENCE public.custom_attributes_epiccustomattributesvalues_id_seq OWNED BY public.custom_attributes_epiccustomattributesvalues.id;
          public          taiga    false    295                       1259    9778189 &   custom_attributes_issuecustomattribute    TABLE     �  CREATE TABLE public.custom_attributes_issuecustomattribute (
    id integer NOT NULL,
    name character varying(64) NOT NULL,
    description text NOT NULL,
    "order" bigint NOT NULL,
    created_date timestamp with time zone NOT NULL,
    modified_date timestamp with time zone NOT NULL,
    project_id integer NOT NULL,
    type character varying(16) NOT NULL,
    extra jsonb
);
 :   DROP TABLE public.custom_attributes_issuecustomattribute;
       public         heap    taiga    false                       1259    9778187 -   custom_attributes_issuecustomattribute_id_seq    SEQUENCE     �   CREATE SEQUENCE public.custom_attributes_issuecustomattribute_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
 D   DROP SEQUENCE public.custom_attributes_issuecustomattribute_id_seq;
       public          taiga    false    282            �           0    0 -   custom_attributes_issuecustomattribute_id_seq    SEQUENCE OWNED BY        ALTER SEQUENCE public.custom_attributes_issuecustomattribute_id_seq OWNED BY public.custom_attributes_issuecustomattribute.id;
          public          taiga    false    281                        1259    9778246 -   custom_attributes_issuecustomattributesvalues    TABLE     �   CREATE TABLE public.custom_attributes_issuecustomattributesvalues (
    id integer NOT NULL,
    version integer NOT NULL,
    attributes_values jsonb NOT NULL,
    issue_id integer NOT NULL
);
 A   DROP TABLE public.custom_attributes_issuecustomattributesvalues;
       public         heap    taiga    false                       1259    9778244 4   custom_attributes_issuecustomattributesvalues_id_seq    SEQUENCE     �   CREATE SEQUENCE public.custom_attributes_issuecustomattributesvalues_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
 K   DROP SEQUENCE public.custom_attributes_issuecustomattributesvalues_id_seq;
       public          taiga    false    288            �           0    0 4   custom_attributes_issuecustomattributesvalues_id_seq    SEQUENCE OWNED BY     �   ALTER SEQUENCE public.custom_attributes_issuecustomattributesvalues_id_seq OWNED BY public.custom_attributes_issuecustomattributesvalues.id;
          public          taiga    false    287                       1259    9778200 %   custom_attributes_taskcustomattribute    TABLE     �  CREATE TABLE public.custom_attributes_taskcustomattribute (
    id integer NOT NULL,
    name character varying(64) NOT NULL,
    description text NOT NULL,
    "order" bigint NOT NULL,
    created_date timestamp with time zone NOT NULL,
    modified_date timestamp with time zone NOT NULL,
    project_id integer NOT NULL,
    type character varying(16) NOT NULL,
    extra jsonb
);
 9   DROP TABLE public.custom_attributes_taskcustomattribute;
       public         heap    taiga    false                       1259    9778198 ,   custom_attributes_taskcustomattribute_id_seq    SEQUENCE     �   CREATE SEQUENCE public.custom_attributes_taskcustomattribute_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
 C   DROP SEQUENCE public.custom_attributes_taskcustomattribute_id_seq;
       public          taiga    false    284            �           0    0 ,   custom_attributes_taskcustomattribute_id_seq    SEQUENCE OWNED BY     }   ALTER SEQUENCE public.custom_attributes_taskcustomattribute_id_seq OWNED BY public.custom_attributes_taskcustomattribute.id;
          public          taiga    false    283            "           1259    9778259 ,   custom_attributes_taskcustomattributesvalues    TABLE     �   CREATE TABLE public.custom_attributes_taskcustomattributesvalues (
    id integer NOT NULL,
    version integer NOT NULL,
    attributes_values jsonb NOT NULL,
    task_id integer NOT NULL
);
 @   DROP TABLE public.custom_attributes_taskcustomattributesvalues;
       public         heap    taiga    false            !           1259    9778257 3   custom_attributes_taskcustomattributesvalues_id_seq    SEQUENCE     �   CREATE SEQUENCE public.custom_attributes_taskcustomattributesvalues_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
 J   DROP SEQUENCE public.custom_attributes_taskcustomattributesvalues_id_seq;
       public          taiga    false    290            �           0    0 3   custom_attributes_taskcustomattributesvalues_id_seq    SEQUENCE OWNED BY     �   ALTER SEQUENCE public.custom_attributes_taskcustomattributesvalues_id_seq OWNED BY public.custom_attributes_taskcustomattributesvalues.id;
          public          taiga    false    289                       1259    9778211 *   custom_attributes_userstorycustomattribute    TABLE     �  CREATE TABLE public.custom_attributes_userstorycustomattribute (
    id integer NOT NULL,
    name character varying(64) NOT NULL,
    description text NOT NULL,
    "order" bigint NOT NULL,
    created_date timestamp with time zone NOT NULL,
    modified_date timestamp with time zone NOT NULL,
    project_id integer NOT NULL,
    type character varying(16) NOT NULL,
    extra jsonb
);
 >   DROP TABLE public.custom_attributes_userstorycustomattribute;
       public         heap    taiga    false                       1259    9778209 1   custom_attributes_userstorycustomattribute_id_seq    SEQUENCE     �   CREATE SEQUENCE public.custom_attributes_userstorycustomattribute_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
 H   DROP SEQUENCE public.custom_attributes_userstorycustomattribute_id_seq;
       public          taiga    false    286            �           0    0 1   custom_attributes_userstorycustomattribute_id_seq    SEQUENCE OWNED BY     �   ALTER SEQUENCE public.custom_attributes_userstorycustomattribute_id_seq OWNED BY public.custom_attributes_userstorycustomattribute.id;
          public          taiga    false    285            $           1259    9778272 1   custom_attributes_userstorycustomattributesvalues    TABLE     �   CREATE TABLE public.custom_attributes_userstorycustomattributesvalues (
    id integer NOT NULL,
    version integer NOT NULL,
    attributes_values jsonb NOT NULL,
    user_story_id integer NOT NULL
);
 E   DROP TABLE public.custom_attributes_userstorycustomattributesvalues;
       public         heap    taiga    false            #           1259    9778270 8   custom_attributes_userstorycustomattributesvalues_id_seq    SEQUENCE     �   CREATE SEQUENCE public.custom_attributes_userstorycustomattributesvalues_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
 O   DROP SEQUENCE public.custom_attributes_userstorycustomattributesvalues_id_seq;
       public          taiga    false    292            �           0    0 8   custom_attributes_userstorycustomattributesvalues_id_seq    SEQUENCE OWNED BY     �   ALTER SEQUENCE public.custom_attributes_userstorycustomattributesvalues_id_seq OWNED BY public.custom_attributes_userstorycustomattributesvalues.id;
          public          taiga    false    291            �            1259    9776777    django_admin_log    TABLE     �  CREATE TABLE public.django_admin_log (
    id integer NOT NULL,
    action_time timestamp with time zone NOT NULL,
    object_id text,
    object_repr character varying(200) NOT NULL,
    action_flag smallint NOT NULL,
    change_message text NOT NULL,
    content_type_id integer,
    user_id integer NOT NULL,
    CONSTRAINT django_admin_log_action_flag_check CHECK ((action_flag >= 0))
);
 $   DROP TABLE public.django_admin_log;
       public         heap    taiga    false            �            1259    9776775    django_admin_log_id_seq    SEQUENCE     �   CREATE SEQUENCE public.django_admin_log_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
 .   DROP SEQUENCE public.django_admin_log_id_seq;
       public          taiga    false    209            �           0    0    django_admin_log_id_seq    SEQUENCE OWNED BY     S   ALTER SEQUENCE public.django_admin_log_id_seq OWNED BY public.django_admin_log.id;
          public          taiga    false    208            �            1259    9776753    django_content_type    TABLE     �   CREATE TABLE public.django_content_type (
    id integer NOT NULL,
    app_label character varying(100) NOT NULL,
    model character varying(100) NOT NULL
);
 '   DROP TABLE public.django_content_type;
       public         heap    taiga    false            �            1259    9776751    django_content_type_id_seq    SEQUENCE     �   CREATE SEQUENCE public.django_content_type_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
 1   DROP SEQUENCE public.django_content_type_id_seq;
       public          taiga    false    205            �           0    0    django_content_type_id_seq    SEQUENCE OWNED BY     Y   ALTER SEQUENCE public.django_content_type_id_seq OWNED BY public.django_content_type.id;
          public          taiga    false    204            �            1259    9776742    django_migrations    TABLE     �   CREATE TABLE public.django_migrations (
    id integer NOT NULL,
    app character varying(255) NOT NULL,
    name character varying(255) NOT NULL,
    applied timestamp with time zone NOT NULL
);
 %   DROP TABLE public.django_migrations;
       public         heap    taiga    false            �            1259    9776740    django_migrations_id_seq    SEQUENCE     �   CREATE SEQUENCE public.django_migrations_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
 /   DROP SEQUENCE public.django_migrations_id_seq;
       public          taiga    false    203            �           0    0    django_migrations_id_seq    SEQUENCE OWNED BY     U   ALTER SEQUENCE public.django_migrations_id_seq OWNED BY public.django_migrations.id;
          public          taiga    false    202            E           1259    9778780    django_session    TABLE     �   CREATE TABLE public.django_session (
    session_key character varying(40) NOT NULL,
    session_data text NOT NULL,
    expire_date timestamp with time zone NOT NULL
);
 "   DROP TABLE public.django_session;
       public         heap    taiga    false            )           1259    9778424    djmail_message    TABLE     �  CREATE TABLE public.djmail_message (
    uuid character varying(40) NOT NULL,
    from_email character varying(1024) NOT NULL,
    to_email text NOT NULL,
    body_text text NOT NULL,
    body_html text NOT NULL,
    subject character varying(1024) NOT NULL,
    data text NOT NULL,
    retry_count smallint NOT NULL,
    status smallint NOT NULL,
    priority smallint NOT NULL,
    created_at timestamp with time zone NOT NULL,
    sent_at timestamp with time zone,
    exception text NOT NULL
);
 "   DROP TABLE public.djmail_message;
       public         heap    taiga    false            +           1259    9778435    easy_thumbnails_source    TABLE     �   CREATE TABLE public.easy_thumbnails_source (
    id integer NOT NULL,
    storage_hash character varying(40) NOT NULL,
    name character varying(255) NOT NULL,
    modified timestamp with time zone NOT NULL
);
 *   DROP TABLE public.easy_thumbnails_source;
       public         heap    taiga    false            *           1259    9778433    easy_thumbnails_source_id_seq    SEQUENCE     �   CREATE SEQUENCE public.easy_thumbnails_source_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
 4   DROP SEQUENCE public.easy_thumbnails_source_id_seq;
       public          taiga    false    299            �           0    0    easy_thumbnails_source_id_seq    SEQUENCE OWNED BY     _   ALTER SEQUENCE public.easy_thumbnails_source_id_seq OWNED BY public.easy_thumbnails_source.id;
          public          taiga    false    298            -           1259    9778443    easy_thumbnails_thumbnail    TABLE     �   CREATE TABLE public.easy_thumbnails_thumbnail (
    id integer NOT NULL,
    storage_hash character varying(40) NOT NULL,
    name character varying(255) NOT NULL,
    modified timestamp with time zone NOT NULL,
    source_id integer NOT NULL
);
 -   DROP TABLE public.easy_thumbnails_thumbnail;
       public         heap    taiga    false            ,           1259    9778441     easy_thumbnails_thumbnail_id_seq    SEQUENCE     �   CREATE SEQUENCE public.easy_thumbnails_thumbnail_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
 7   DROP SEQUENCE public.easy_thumbnails_thumbnail_id_seq;
       public          taiga    false    301            �           0    0     easy_thumbnails_thumbnail_id_seq    SEQUENCE OWNED BY     e   ALTER SEQUENCE public.easy_thumbnails_thumbnail_id_seq OWNED BY public.easy_thumbnails_thumbnail.id;
          public          taiga    false    300            /           1259    9778469 #   easy_thumbnails_thumbnaildimensions    TABLE     K  CREATE TABLE public.easy_thumbnails_thumbnaildimensions (
    id integer NOT NULL,
    thumbnail_id integer NOT NULL,
    width integer,
    height integer,
    CONSTRAINT easy_thumbnails_thumbnaildimensions_height_check CHECK ((height >= 0)),
    CONSTRAINT easy_thumbnails_thumbnaildimensions_width_check CHECK ((width >= 0))
);
 7   DROP TABLE public.easy_thumbnails_thumbnaildimensions;
       public         heap    taiga    false            .           1259    9778467 *   easy_thumbnails_thumbnaildimensions_id_seq    SEQUENCE     �   CREATE SEQUENCE public.easy_thumbnails_thumbnaildimensions_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
 A   DROP SEQUENCE public.easy_thumbnails_thumbnaildimensions_id_seq;
       public          taiga    false    303            �           0    0 *   easy_thumbnails_thumbnaildimensions_id_seq    SEQUENCE OWNED BY     y   ALTER SEQUENCE public.easy_thumbnails_thumbnaildimensions_id_seq OWNED BY public.easy_thumbnails_thumbnaildimensions.id;
          public          taiga    false    302                       1259    9778130 
   epics_epic    TABLE     �  CREATE TABLE public.epics_epic (
    id integer NOT NULL,
    tags text[],
    version integer NOT NULL,
    is_blocked boolean NOT NULL,
    blocked_note text NOT NULL,
    ref bigint,
    epics_order bigint NOT NULL,
    created_date timestamp with time zone NOT NULL,
    modified_date timestamp with time zone NOT NULL,
    subject text NOT NULL,
    description text NOT NULL,
    client_requirement boolean NOT NULL,
    team_requirement boolean NOT NULL,
    assigned_to_id integer,
    owner_id integer,
    project_id integer NOT NULL,
    status_id integer,
    color character varying(32) NOT NULL,
    external_reference text[]
);
    DROP TABLE public.epics_epic;
       public         heap    taiga    false                       1259    9778128    epics_epic_id_seq    SEQUENCE     �   CREATE SEQUENCE public.epics_epic_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
 (   DROP SEQUENCE public.epics_epic_id_seq;
       public          taiga    false    278            �           0    0    epics_epic_id_seq    SEQUENCE OWNED BY     G   ALTER SEQUENCE public.epics_epic_id_seq OWNED BY public.epics_epic.id;
          public          taiga    false    277                       1259    9778141    epics_relateduserstory    TABLE     �   CREATE TABLE public.epics_relateduserstory (
    id integer NOT NULL,
    "order" bigint NOT NULL,
    epic_id integer NOT NULL,
    user_story_id integer NOT NULL
);
 *   DROP TABLE public.epics_relateduserstory;
       public         heap    taiga    false                       1259    9778139    epics_relateduserstory_id_seq    SEQUENCE     �   CREATE SEQUENCE public.epics_relateduserstory_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
 4   DROP SEQUENCE public.epics_relateduserstory_id_seq;
       public          taiga    false    280            �           0    0    epics_relateduserstory_id_seq    SEQUENCE OWNED BY     _   ALTER SEQUENCE public.epics_relateduserstory_id_seq OWNED BY public.epics_relateduserstory.id;
          public          taiga    false    279            0           1259    9778510    external_apps_application    TABLE     �   CREATE TABLE public.external_apps_application (
    id character varying(255) NOT NULL,
    name character varying(255) NOT NULL,
    icon_url text,
    web character varying(255),
    description text,
    next_url text NOT NULL
);
 -   DROP TABLE public.external_apps_application;
       public         heap    taiga    false            2           1259    9778520    external_apps_applicationtoken    TABLE       CREATE TABLE public.external_apps_applicationtoken (
    id integer NOT NULL,
    auth_code character varying(255),
    token character varying(255),
    state character varying(255),
    application_id character varying(255) NOT NULL,
    user_id integer NOT NULL
);
 2   DROP TABLE public.external_apps_applicationtoken;
       public         heap    taiga    false            1           1259    9778518 %   external_apps_applicationtoken_id_seq    SEQUENCE     �   CREATE SEQUENCE public.external_apps_applicationtoken_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
 <   DROP SEQUENCE public.external_apps_applicationtoken_id_seq;
       public          taiga    false    306            �           0    0 %   external_apps_applicationtoken_id_seq    SEQUENCE OWNED BY     o   ALTER SEQUENCE public.external_apps_applicationtoken_id_seq OWNED BY public.external_apps_applicationtoken.id;
          public          taiga    false    305            4           1259    9778547    feedback_feedbackentry    TABLE     �   CREATE TABLE public.feedback_feedbackentry (
    id integer NOT NULL,
    full_name character varying(256) NOT NULL,
    email character varying(255) NOT NULL,
    comment text NOT NULL,
    created_date timestamp with time zone NOT NULL
);
 *   DROP TABLE public.feedback_feedbackentry;
       public         heap    taiga    false            3           1259    9778545    feedback_feedbackentry_id_seq    SEQUENCE     �   CREATE SEQUENCE public.feedback_feedbackentry_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
 4   DROP SEQUENCE public.feedback_feedbackentry_id_seq;
       public          taiga    false    308            �           0    0    feedback_feedbackentry_id_seq    SEQUENCE OWNED BY     _   ALTER SEQUENCE public.feedback_feedbackentry_id_seq OWNED BY public.feedback_feedbackentry.id;
          public          taiga    false    307                       1259    9778092    history_historyentry    TABLE     /  CREATE TABLE public.history_historyentry (
    id character varying(255) NOT NULL,
    "user" jsonb,
    created_at timestamp with time zone,
    type smallint,
    is_snapshot boolean,
    key character varying(255),
    diff jsonb,
    snapshot jsonb,
    "values" jsonb,
    comment text,
    comment_html text,
    delete_comment_date timestamp with time zone,
    delete_comment_user jsonb,
    is_hidden boolean,
    comment_versions jsonb,
    edit_comment_date timestamp with time zone,
    project_id integer NOT NULL,
    values_diff_cache jsonb
);
 (   DROP TABLE public.history_historyentry;
       public         heap    taiga    false            �            1259    9777206    issues_issue    TABLE     �  CREATE TABLE public.issues_issue (
    id integer NOT NULL,
    tags text[],
    version integer NOT NULL,
    is_blocked boolean NOT NULL,
    blocked_note text NOT NULL,
    ref bigint,
    created_date timestamp with time zone NOT NULL,
    modified_date timestamp with time zone NOT NULL,
    finished_date timestamp with time zone,
    subject text NOT NULL,
    description text NOT NULL,
    assigned_to_id integer,
    milestone_id integer,
    owner_id integer,
    priority_id integer,
    project_id integer NOT NULL,
    severity_id integer,
    status_id integer,
    type_id integer,
    external_reference text[],
    due_date date,
    due_date_reason text NOT NULL
);
     DROP TABLE public.issues_issue;
       public         heap    taiga    false            �            1259    9777204    issues_issue_id_seq    SEQUENCE     �   CREATE SEQUENCE public.issues_issue_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
 *   DROP SEQUENCE public.issues_issue_id_seq;
       public          taiga    false    243            �           0    0    issues_issue_id_seq    SEQUENCE OWNED BY     K   ALTER SEQUENCE public.issues_issue_id_seq OWNED BY public.issues_issue.id;
          public          taiga    false    242                       1259    9777792 
   likes_like    TABLE       CREATE TABLE public.likes_like (
    id integer NOT NULL,
    object_id integer NOT NULL,
    created_date timestamp with time zone NOT NULL,
    content_type_id integer NOT NULL,
    user_id integer NOT NULL,
    CONSTRAINT likes_like_object_id_check CHECK ((object_id >= 0))
);
    DROP TABLE public.likes_like;
       public         heap    taiga    false            
           1259    9777790    likes_like_id_seq    SEQUENCE     �   CREATE SEQUENCE public.likes_like_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
 (   DROP SEQUENCE public.likes_like_id_seq;
       public          taiga    false    267            �           0    0    likes_like_id_seq    SEQUENCE OWNED BY     G   ALTER SEQUENCE public.likes_like_id_seq OWNED BY public.likes_like.id;
          public          taiga    false    266            �            1259    9777155    milestones_milestone    TABLE     )  CREATE TABLE public.milestones_milestone (
    id integer NOT NULL,
    name character varying(200) NOT NULL,
    slug character varying(250) NOT NULL,
    estimated_start date NOT NULL,
    estimated_finish date NOT NULL,
    created_date timestamp with time zone NOT NULL,
    modified_date timestamp with time zone NOT NULL,
    closed boolean NOT NULL,
    disponibility double precision,
    "order" smallint NOT NULL,
    owner_id integer,
    project_id integer NOT NULL,
    CONSTRAINT milestones_milestone_order_check CHECK (("order" >= 0))
);
 (   DROP TABLE public.milestones_milestone;
       public         heap    taiga    false            �            1259    9777153    milestones_milestone_id_seq    SEQUENCE     �   CREATE SEQUENCE public.milestones_milestone_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
 2   DROP SEQUENCE public.milestones_milestone_id_seq;
       public          taiga    false    241            �           0    0    milestones_milestone_id_seq    SEQUENCE OWNED BY     [   ALTER SEQUENCE public.milestones_milestone_id_seq OWNED BY public.milestones_milestone.id;
          public          taiga    false    240            �            1259    9777466 '   notifications_historychangenotification    TABLE     V  CREATE TABLE public.notifications_historychangenotification (
    id integer NOT NULL,
    key character varying(255) NOT NULL,
    created_datetime timestamp with time zone NOT NULL,
    updated_datetime timestamp with time zone NOT NULL,
    history_type smallint NOT NULL,
    owner_id integer NOT NULL,
    project_id integer NOT NULL
);
 ;   DROP TABLE public.notifications_historychangenotification;
       public         heap    taiga    false            �            1259    9777474 7   notifications_historychangenotification_history_entries    TABLE     �   CREATE TABLE public.notifications_historychangenotification_history_entries (
    id integer NOT NULL,
    historychangenotification_id integer NOT NULL,
    historyentry_id character varying(255) NOT NULL
);
 K   DROP TABLE public.notifications_historychangenotification_history_entries;
       public         heap    taiga    false            �            1259    9777472 >   notifications_historychangenotification_history_entries_id_seq    SEQUENCE     �   CREATE SEQUENCE public.notifications_historychangenotification_history_entries_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
 U   DROP SEQUENCE public.notifications_historychangenotification_history_entries_id_seq;
       public          taiga    false    253            �           0    0 >   notifications_historychangenotification_history_entries_id_seq    SEQUENCE OWNED BY     �   ALTER SEQUENCE public.notifications_historychangenotification_history_entries_id_seq OWNED BY public.notifications_historychangenotification_history_entries.id;
          public          taiga    false    252            �            1259    9777464 .   notifications_historychangenotification_id_seq    SEQUENCE     �   CREATE SEQUENCE public.notifications_historychangenotification_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
 E   DROP SEQUENCE public.notifications_historychangenotification_id_seq;
       public          taiga    false    251            �           0    0 .   notifications_historychangenotification_id_seq    SEQUENCE OWNED BY     �   ALTER SEQUENCE public.notifications_historychangenotification_id_seq OWNED BY public.notifications_historychangenotification.id;
          public          taiga    false    250            �            1259    9777482 4   notifications_historychangenotification_notify_users    TABLE     �   CREATE TABLE public.notifications_historychangenotification_notify_users (
    id integer NOT NULL,
    historychangenotification_id integer NOT NULL,
    user_id integer NOT NULL
);
 H   DROP TABLE public.notifications_historychangenotification_notify_users;
       public         heap    taiga    false            �            1259    9777480 ;   notifications_historychangenotification_notify_users_id_seq    SEQUENCE     �   CREATE SEQUENCE public.notifications_historychangenotification_notify_users_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
 R   DROP SEQUENCE public.notifications_historychangenotification_notify_users_id_seq;
       public          taiga    false    255            �           0    0 ;   notifications_historychangenotification_notify_users_id_seq    SEQUENCE OWNED BY     �   ALTER SEQUENCE public.notifications_historychangenotification_notify_users_id_seq OWNED BY public.notifications_historychangenotification_notify_users.id;
          public          taiga    false    254            �            1259    9777423    notifications_notifypolicy    TABLE     d  CREATE TABLE public.notifications_notifypolicy (
    id integer NOT NULL,
    notify_level smallint NOT NULL,
    created_at timestamp with time zone NOT NULL,
    modified_at timestamp with time zone NOT NULL,
    project_id integer NOT NULL,
    user_id integer NOT NULL,
    live_notify_level smallint NOT NULL,
    web_notify_level boolean NOT NULL
);
 .   DROP TABLE public.notifications_notifypolicy;
       public         heap    taiga    false            �            1259    9777421 !   notifications_notifypolicy_id_seq    SEQUENCE     �   CREATE SEQUENCE public.notifications_notifypolicy_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
 8   DROP SEQUENCE public.notifications_notifypolicy_id_seq;
       public          taiga    false    249            �           0    0 !   notifications_notifypolicy_id_seq    SEQUENCE OWNED BY     g   ALTER SEQUENCE public.notifications_notifypolicy_id_seq OWNED BY public.notifications_notifypolicy.id;
          public          taiga    false    248                       1259    9777533    notifications_watched    TABLE     O  CREATE TABLE public.notifications_watched (
    id integer NOT NULL,
    object_id integer NOT NULL,
    created_date timestamp with time zone NOT NULL,
    content_type_id integer NOT NULL,
    user_id integer NOT NULL,
    project_id integer NOT NULL,
    CONSTRAINT notifications_watched_object_id_check CHECK ((object_id >= 0))
);
 )   DROP TABLE public.notifications_watched;
       public         heap    taiga    false                        1259    9777531    notifications_watched_id_seq    SEQUENCE     �   CREATE SEQUENCE public.notifications_watched_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
 3   DROP SEQUENCE public.notifications_watched_id_seq;
       public          taiga    false    257            �           0    0    notifications_watched_id_seq    SEQUENCE OWNED BY     ]   ALTER SEQUENCE public.notifications_watched_id_seq OWNED BY public.notifications_watched.id;
          public          taiga    false    256            6           1259    9778606    notifications_webnotification    TABLE     R  CREATE TABLE public.notifications_webnotification (
    id integer NOT NULL,
    created timestamp with time zone NOT NULL,
    read timestamp with time zone,
    event_type integer NOT NULL,
    data jsonb NOT NULL,
    user_id integer NOT NULL,
    CONSTRAINT notifications_webnotification_event_type_check CHECK ((event_type >= 0))
);
 1   DROP TABLE public.notifications_webnotification;
       public         heap    taiga    false            5           1259    9778604 $   notifications_webnotification_id_seq    SEQUENCE     �   CREATE SEQUENCE public.notifications_webnotification_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
 ;   DROP SEQUENCE public.notifications_webnotification_id_seq;
       public          taiga    false    310            �           0    0 $   notifications_webnotification_id_seq    SEQUENCE OWNED BY     m   ALTER SEQUENCE public.notifications_webnotification_id_seq OWNED BY public.notifications_webnotification.id;
          public          taiga    false    309                       1259    9777899    projects_epicstatus    TABLE     "  CREATE TABLE public.projects_epicstatus (
    id integer NOT NULL,
    name character varying(255) NOT NULL,
    slug character varying(255) NOT NULL,
    "order" integer NOT NULL,
    is_closed boolean NOT NULL,
    color character varying(20) NOT NULL,
    project_id integer NOT NULL
);
 '   DROP TABLE public.projects_epicstatus;
       public         heap    taiga    false                       1259    9777897    projects_epicstatus_id_seq    SEQUENCE     �   CREATE SEQUENCE public.projects_epicstatus_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
 1   DROP SEQUENCE public.projects_epicstatus_id_seq;
       public          taiga    false    269            �           0    0    projects_epicstatus_id_seq    SEQUENCE OWNED BY     Y   ALTER SEQUENCE public.projects_epicstatus_id_seq OWNED BY public.projects_epicstatus.id;
          public          taiga    false    268            :           1259    9778649    projects_issueduedate    TABLE       CREATE TABLE public.projects_issueduedate (
    id integer NOT NULL,
    name character varying(255) NOT NULL,
    "order" integer NOT NULL,
    by_default boolean NOT NULL,
    color character varying(20) NOT NULL,
    days_to_due integer,
    project_id integer NOT NULL
);
 )   DROP TABLE public.projects_issueduedate;
       public         heap    taiga    false            9           1259    9778647    projects_issueduedate_id_seq    SEQUENCE     �   CREATE SEQUENCE public.projects_issueduedate_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
 3   DROP SEQUENCE public.projects_issueduedate_id_seq;
       public          taiga    false    314            �           0    0    projects_issueduedate_id_seq    SEQUENCE OWNED BY     ]   ALTER SEQUENCE public.projects_issueduedate_id_seq OWNED BY public.projects_issueduedate.id;
          public          taiga    false    313            �            1259    9776867    projects_issuestatus    TABLE     #  CREATE TABLE public.projects_issuestatus (
    id integer NOT NULL,
    name character varying(255) NOT NULL,
    "order" integer NOT NULL,
    is_closed boolean NOT NULL,
    color character varying(20) NOT NULL,
    project_id integer NOT NULL,
    slug character varying(255) NOT NULL
);
 (   DROP TABLE public.projects_issuestatus;
       public         heap    taiga    false            �            1259    9776865    projects_issuestatus_id_seq    SEQUENCE     �   CREATE SEQUENCE public.projects_issuestatus_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
 2   DROP SEQUENCE public.projects_issuestatus_id_seq;
       public          taiga    false    217            �           0    0    projects_issuestatus_id_seq    SEQUENCE OWNED BY     [   ALTER SEQUENCE public.projects_issuestatus_id_seq OWNED BY public.projects_issuestatus.id;
          public          taiga    false    216            �            1259    9776875    projects_issuetype    TABLE     �   CREATE TABLE public.projects_issuetype (
    id integer NOT NULL,
    name character varying(255) NOT NULL,
    "order" integer NOT NULL,
    color character varying(20) NOT NULL,
    project_id integer NOT NULL
);
 &   DROP TABLE public.projects_issuetype;
       public         heap    taiga    false            �            1259    9776873    projects_issuetype_id_seq    SEQUENCE     �   CREATE SEQUENCE public.projects_issuetype_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
 0   DROP SEQUENCE public.projects_issuetype_id_seq;
       public          taiga    false    219            �           0    0    projects_issuetype_id_seq    SEQUENCE OWNED BY     W   ALTER SEQUENCE public.projects_issuetype_id_seq OWNED BY public.projects_issuetype.id;
          public          taiga    false    218            �            1259    9776814    projects_membership    TABLE     �  CREATE TABLE public.projects_membership (
    id integer NOT NULL,
    is_admin boolean NOT NULL,
    email character varying(255),
    created_at timestamp with time zone NOT NULL,
    token character varying(60),
    user_id integer,
    project_id integer NOT NULL,
    role_id integer NOT NULL,
    invited_by_id integer,
    invitation_extra_text text,
    user_order bigint NOT NULL
);
 '   DROP TABLE public.projects_membership;
       public         heap    taiga    false            �            1259    9776812    projects_membership_id_seq    SEQUENCE     �   CREATE SEQUENCE public.projects_membership_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
 1   DROP SEQUENCE public.projects_membership_id_seq;
       public          taiga    false    213            �           0    0    projects_membership_id_seq    SEQUENCE OWNED BY     Y   ALTER SEQUENCE public.projects_membership_id_seq OWNED BY public.projects_membership.id;
          public          taiga    false    212            �            1259    9776883    projects_points    TABLE     �   CREATE TABLE public.projects_points (
    id integer NOT NULL,
    name character varying(255) NOT NULL,
    "order" integer NOT NULL,
    value double precision,
    project_id integer NOT NULL
);
 #   DROP TABLE public.projects_points;
       public         heap    taiga    false            �            1259    9776881    projects_points_id_seq    SEQUENCE     �   CREATE SEQUENCE public.projects_points_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
 -   DROP SEQUENCE public.projects_points_id_seq;
       public          taiga    false    221            �           0    0    projects_points_id_seq    SEQUENCE OWNED BY     Q   ALTER SEQUENCE public.projects_points_id_seq OWNED BY public.projects_points.id;
          public          taiga    false    220            �            1259    9776891    projects_priority    TABLE     �   CREATE TABLE public.projects_priority (
    id integer NOT NULL,
    name character varying(255) NOT NULL,
    "order" integer NOT NULL,
    color character varying(20) NOT NULL,
    project_id integer NOT NULL
);
 %   DROP TABLE public.projects_priority;
       public         heap    taiga    false            �            1259    9776889    projects_priority_id_seq    SEQUENCE     �   CREATE SEQUENCE public.projects_priority_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
 /   DROP SEQUENCE public.projects_priority_id_seq;
       public          taiga    false    223            �           0    0    projects_priority_id_seq    SEQUENCE OWNED BY     U   ALTER SEQUENCE public.projects_priority_id_seq OWNED BY public.projects_priority.id;
          public          taiga    false    222            �            1259    9776822    projects_project    TABLE       CREATE TABLE public.projects_project (
    id integer NOT NULL,
    tags text[],
    name character varying(250) NOT NULL,
    slug character varying(250) NOT NULL,
    description text,
    created_date timestamp with time zone NOT NULL,
    modified_date timestamp with time zone NOT NULL,
    total_milestones integer,
    total_story_points double precision,
    is_backlog_activated boolean NOT NULL,
    is_kanban_activated boolean NOT NULL,
    is_wiki_activated boolean NOT NULL,
    is_issues_activated boolean NOT NULL,
    videoconferences character varying(250),
    videoconferences_extra_data character varying(250),
    anon_permissions text[],
    public_permissions text[],
    is_private boolean NOT NULL,
    tags_colors text[],
    owner_id integer,
    creation_template_id integer,
    default_issue_status_id integer,
    default_issue_type_id integer,
    default_points_id integer,
    default_priority_id integer,
    default_severity_id integer,
    default_task_status_id integer,
    default_us_status_id integer,
    issues_csv_uuid character varying(32),
    tasks_csv_uuid character varying(32),
    userstories_csv_uuid character varying(32),
    is_featured boolean NOT NULL,
    is_looking_for_people boolean NOT NULL,
    total_activity integer NOT NULL,
    total_activity_last_month integer NOT NULL,
    total_activity_last_week integer NOT NULL,
    total_activity_last_year integer NOT NULL,
    total_fans integer NOT NULL,
    total_fans_last_month integer NOT NULL,
    total_fans_last_week integer NOT NULL,
    total_fans_last_year integer NOT NULL,
    totals_updated_datetime timestamp with time zone NOT NULL,
    logo character varying(500),
    looking_for_people_note text NOT NULL,
    blocked_code character varying(255),
    transfer_token character varying(255),
    is_epics_activated boolean NOT NULL,
    default_epic_status_id integer,
    epics_csv_uuid character varying(32),
    is_contact_activated boolean NOT NULL,
    default_swimlane_id integer,
    workspace_id integer,
    color integer NOT NULL,
    CONSTRAINT projects_project_total_activity_check CHECK ((total_activity >= 0)),
    CONSTRAINT projects_project_total_activity_last_month_check CHECK ((total_activity_last_month >= 0)),
    CONSTRAINT projects_project_total_activity_last_week_check CHECK ((total_activity_last_week >= 0)),
    CONSTRAINT projects_project_total_activity_last_year_check CHECK ((total_activity_last_year >= 0)),
    CONSTRAINT projects_project_total_fans_check CHECK ((total_fans >= 0)),
    CONSTRAINT projects_project_total_fans_last_month_check CHECK ((total_fans_last_month >= 0)),
    CONSTRAINT projects_project_total_fans_last_week_check CHECK ((total_fans_last_week >= 0)),
    CONSTRAINT projects_project_total_fans_last_year_check CHECK ((total_fans_last_year >= 0))
);
 $   DROP TABLE public.projects_project;
       public         heap    taiga    false            �            1259    9776820    projects_project_id_seq    SEQUENCE     �   CREATE SEQUENCE public.projects_project_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
 .   DROP SEQUENCE public.projects_project_id_seq;
       public          taiga    false    215            �           0    0    projects_project_id_seq    SEQUENCE OWNED BY     S   ALTER SEQUENCE public.projects_project_id_seq OWNED BY public.projects_project.id;
          public          taiga    false    214                       1259    9777717    projects_projectmodulesconfig    TABLE     �   CREATE TABLE public.projects_projectmodulesconfig (
    id integer NOT NULL,
    config jsonb,
    project_id integer NOT NULL
);
 1   DROP TABLE public.projects_projectmodulesconfig;
       public         heap    taiga    false                       1259    9777715 $   projects_projectmodulesconfig_id_seq    SEQUENCE     �   CREATE SEQUENCE public.projects_projectmodulesconfig_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
 ;   DROP SEQUENCE public.projects_projectmodulesconfig_id_seq;
       public          taiga    false    263            �           0    0 $   projects_projectmodulesconfig_id_seq    SEQUENCE OWNED BY     m   ALTER SEQUENCE public.projects_projectmodulesconfig_id_seq OWNED BY public.projects_projectmodulesconfig.id;
          public          taiga    false    262            �            1259    9776899    projects_projecttemplate    TABLE       CREATE TABLE public.projects_projecttemplate (
    id integer NOT NULL,
    name character varying(250) NOT NULL,
    slug character varying(250) NOT NULL,
    description text NOT NULL,
    created_date timestamp with time zone NOT NULL,
    modified_date timestamp with time zone NOT NULL,
    default_owner_role character varying(50) NOT NULL,
    is_backlog_activated boolean NOT NULL,
    is_kanban_activated boolean NOT NULL,
    is_wiki_activated boolean NOT NULL,
    is_issues_activated boolean NOT NULL,
    videoconferences character varying(250),
    videoconferences_extra_data character varying(250),
    default_options jsonb,
    us_statuses jsonb,
    points jsonb,
    task_statuses jsonb,
    issue_statuses jsonb,
    issue_types jsonb,
    priorities jsonb,
    severities jsonb,
    roles jsonb,
    "order" bigint NOT NULL,
    epic_statuses jsonb,
    is_epics_activated boolean NOT NULL,
    is_contact_activated boolean NOT NULL,
    epic_custom_attributes jsonb,
    is_looking_for_people boolean NOT NULL,
    issue_custom_attributes jsonb,
    looking_for_people_note text NOT NULL,
    tags text[],
    tags_colors text[],
    task_custom_attributes jsonb,
    us_custom_attributes jsonb,
    issue_duedates jsonb,
    task_duedates jsonb,
    us_duedates jsonb
);
 ,   DROP TABLE public.projects_projecttemplate;
       public         heap    taiga    false            �            1259    9776897    projects_projecttemplate_id_seq    SEQUENCE     �   CREATE SEQUENCE public.projects_projecttemplate_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
 6   DROP SEQUENCE public.projects_projecttemplate_id_seq;
       public          taiga    false    225            �           0    0    projects_projecttemplate_id_seq    SEQUENCE OWNED BY     c   ALTER SEQUENCE public.projects_projecttemplate_id_seq OWNED BY public.projects_projecttemplate.id;
          public          taiga    false    224            �            1259    9776912    projects_severity    TABLE     �   CREATE TABLE public.projects_severity (
    id integer NOT NULL,
    name character varying(255) NOT NULL,
    "order" integer NOT NULL,
    color character varying(20) NOT NULL,
    project_id integer NOT NULL
);
 %   DROP TABLE public.projects_severity;
       public         heap    taiga    false            �            1259    9776910    projects_severity_id_seq    SEQUENCE     �   CREATE SEQUENCE public.projects_severity_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
 /   DROP SEQUENCE public.projects_severity_id_seq;
       public          taiga    false    227            �           0    0    projects_severity_id_seq    SEQUENCE OWNED BY     U   ALTER SEQUENCE public.projects_severity_id_seq OWNED BY public.projects_severity.id;
          public          taiga    false    226            @           1259    9778704    projects_swimlane    TABLE     �   CREATE TABLE public.projects_swimlane (
    id integer NOT NULL,
    name text NOT NULL,
    "order" bigint NOT NULL,
    project_id integer NOT NULL
);
 %   DROP TABLE public.projects_swimlane;
       public         heap    taiga    false            ?           1259    9778702    projects_swimlane_id_seq    SEQUENCE     �   CREATE SEQUENCE public.projects_swimlane_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
 /   DROP SEQUENCE public.projects_swimlane_id_seq;
       public          taiga    false    320            �           0    0    projects_swimlane_id_seq    SEQUENCE OWNED BY     U   ALTER SEQUENCE public.projects_swimlane_id_seq OWNED BY public.projects_swimlane.id;
          public          taiga    false    319            B           1259    9778721     projects_swimlaneuserstorystatus    TABLE     �   CREATE TABLE public.projects_swimlaneuserstorystatus (
    id integer NOT NULL,
    wip_limit integer,
    status_id integer NOT NULL,
    swimlane_id integer NOT NULL
);
 4   DROP TABLE public.projects_swimlaneuserstorystatus;
       public         heap    taiga    false            A           1259    9778719 '   projects_swimlaneuserstorystatus_id_seq    SEQUENCE     �   CREATE SEQUENCE public.projects_swimlaneuserstorystatus_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
 >   DROP SEQUENCE public.projects_swimlaneuserstorystatus_id_seq;
       public          taiga    false    322            �           0    0 '   projects_swimlaneuserstorystatus_id_seq    SEQUENCE OWNED BY     s   ALTER SEQUENCE public.projects_swimlaneuserstorystatus_id_seq OWNED BY public.projects_swimlaneuserstorystatus.id;
          public          taiga    false    321            <           1259    9778657    projects_taskduedate    TABLE       CREATE TABLE public.projects_taskduedate (
    id integer NOT NULL,
    name character varying(255) NOT NULL,
    "order" integer NOT NULL,
    by_default boolean NOT NULL,
    color character varying(20) NOT NULL,
    days_to_due integer,
    project_id integer NOT NULL
);
 (   DROP TABLE public.projects_taskduedate;
       public         heap    taiga    false            ;           1259    9778655    projects_taskduedate_id_seq    SEQUENCE     �   CREATE SEQUENCE public.projects_taskduedate_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
 2   DROP SEQUENCE public.projects_taskduedate_id_seq;
       public          taiga    false    316            �           0    0    projects_taskduedate_id_seq    SEQUENCE OWNED BY     [   ALTER SEQUENCE public.projects_taskduedate_id_seq OWNED BY public.projects_taskduedate.id;
          public          taiga    false    315            �            1259    9776920    projects_taskstatus    TABLE     "  CREATE TABLE public.projects_taskstatus (
    id integer NOT NULL,
    name character varying(255) NOT NULL,
    "order" integer NOT NULL,
    is_closed boolean NOT NULL,
    color character varying(20) NOT NULL,
    project_id integer NOT NULL,
    slug character varying(255) NOT NULL
);
 '   DROP TABLE public.projects_taskstatus;
       public         heap    taiga    false            �            1259    9776918    projects_taskstatus_id_seq    SEQUENCE     �   CREATE SEQUENCE public.projects_taskstatus_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
 1   DROP SEQUENCE public.projects_taskstatus_id_seq;
       public          taiga    false    229            �           0    0    projects_taskstatus_id_seq    SEQUENCE OWNED BY     Y   ALTER SEQUENCE public.projects_taskstatus_id_seq OWNED BY public.projects_taskstatus.id;
          public          taiga    false    228            >           1259    9778665    projects_userstoryduedate    TABLE       CREATE TABLE public.projects_userstoryduedate (
    id integer NOT NULL,
    name character varying(255) NOT NULL,
    "order" integer NOT NULL,
    by_default boolean NOT NULL,
    color character varying(20) NOT NULL,
    days_to_due integer,
    project_id integer NOT NULL
);
 -   DROP TABLE public.projects_userstoryduedate;
       public         heap    taiga    false            =           1259    9778663     projects_userstoryduedate_id_seq    SEQUENCE     �   CREATE SEQUENCE public.projects_userstoryduedate_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
 7   DROP SEQUENCE public.projects_userstoryduedate_id_seq;
       public          taiga    false    318            �           0    0     projects_userstoryduedate_id_seq    SEQUENCE OWNED BY     e   ALTER SEQUENCE public.projects_userstoryduedate_id_seq OWNED BY public.projects_userstoryduedate.id;
          public          taiga    false    317            �            1259    9776928    projects_userstorystatus    TABLE     `  CREATE TABLE public.projects_userstorystatus (
    id integer NOT NULL,
    name character varying(255) NOT NULL,
    "order" integer NOT NULL,
    is_closed boolean NOT NULL,
    color character varying(20) NOT NULL,
    wip_limit integer,
    project_id integer NOT NULL,
    slug character varying(255) NOT NULL,
    is_archived boolean NOT NULL
);
 ,   DROP TABLE public.projects_userstorystatus;
       public         heap    taiga    false            �            1259    9776926    projects_userstorystatus_id_seq    SEQUENCE     �   CREATE SEQUENCE public.projects_userstorystatus_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
 6   DROP SEQUENCE public.projects_userstorystatus_id_seq;
       public          taiga    false    231            �           0    0    projects_userstorystatus_id_seq    SEQUENCE OWNED BY     c   ALTER SEQUENCE public.projects_userstorystatus_id_seq OWNED BY public.projects_userstorystatus.id;
          public          taiga    false    230            ^           1259    9779210    references_project1    SEQUENCE     |   CREATE SEQUENCE public.references_project1
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
 *   DROP SEQUENCE public.references_project1;
       public          taiga    false            g           1259    9779228    references_project10    SEQUENCE     }   CREATE SEQUENCE public.references_project10
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
 +   DROP SEQUENCE public.references_project10;
       public          taiga    false            h           1259    9779230    references_project11    SEQUENCE     }   CREATE SEQUENCE public.references_project11
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
 +   DROP SEQUENCE public.references_project11;
       public          taiga    false            i           1259    9779232    references_project12    SEQUENCE     }   CREATE SEQUENCE public.references_project12
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
 +   DROP SEQUENCE public.references_project12;
       public          taiga    false            j           1259    9779234    references_project13    SEQUENCE     }   CREATE SEQUENCE public.references_project13
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
 +   DROP SEQUENCE public.references_project13;
       public          taiga    false            k           1259    9779236    references_project14    SEQUENCE     }   CREATE SEQUENCE public.references_project14
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
 +   DROP SEQUENCE public.references_project14;
       public          taiga    false            _           1259    9779212    references_project2    SEQUENCE     |   CREATE SEQUENCE public.references_project2
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
 *   DROP SEQUENCE public.references_project2;
       public          taiga    false            `           1259    9779214    references_project3    SEQUENCE     |   CREATE SEQUENCE public.references_project3
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
 *   DROP SEQUENCE public.references_project3;
       public          taiga    false            a           1259    9779216    references_project4    SEQUENCE     |   CREATE SEQUENCE public.references_project4
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
 *   DROP SEQUENCE public.references_project4;
       public          taiga    false            b           1259    9779218    references_project5    SEQUENCE     |   CREATE SEQUENCE public.references_project5
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
 *   DROP SEQUENCE public.references_project5;
       public          taiga    false            c           1259    9779220    references_project6    SEQUENCE     |   CREATE SEQUENCE public.references_project6
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
 *   DROP SEQUENCE public.references_project6;
       public          taiga    false            d           1259    9779222    references_project7    SEQUENCE     |   CREATE SEQUENCE public.references_project7
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
 *   DROP SEQUENCE public.references_project7;
       public          taiga    false            e           1259    9779224    references_project8    SEQUENCE     |   CREATE SEQUENCE public.references_project8
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
 *   DROP SEQUENCE public.references_project8;
       public          taiga    false            f           1259    9779226    references_project9    SEQUENCE     |   CREATE SEQUENCE public.references_project9
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
 *   DROP SEQUENCE public.references_project9;
       public          taiga    false            D           1259    9778759    references_reference    TABLE     F  CREATE TABLE public.references_reference (
    id integer NOT NULL,
    object_id integer NOT NULL,
    ref bigint NOT NULL,
    created_at timestamp with time zone NOT NULL,
    content_type_id integer NOT NULL,
    project_id integer NOT NULL,
    CONSTRAINT references_reference_object_id_check CHECK ((object_id >= 0))
);
 (   DROP TABLE public.references_reference;
       public         heap    taiga    false            C           1259    9778757    references_reference_id_seq    SEQUENCE     �   CREATE SEQUENCE public.references_reference_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
 2   DROP SEQUENCE public.references_reference_id_seq;
       public          taiga    false    324            �           0    0    references_reference_id_seq    SEQUENCE OWNED BY     [   ALTER SEQUENCE public.references_reference_id_seq OWNED BY public.references_reference.id;
          public          taiga    false    323            G           1259    9778792    settings_userprojectsettings    TABLE       CREATE TABLE public.settings_userprojectsettings (
    id integer NOT NULL,
    homepage smallint NOT NULL,
    created_at timestamp with time zone NOT NULL,
    modified_at timestamp with time zone NOT NULL,
    project_id integer NOT NULL,
    user_id integer NOT NULL
);
 0   DROP TABLE public.settings_userprojectsettings;
       public         heap    taiga    false            F           1259    9778790 #   settings_userprojectsettings_id_seq    SEQUENCE     �   CREATE SEQUENCE public.settings_userprojectsettings_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
 :   DROP SEQUENCE public.settings_userprojectsettings_id_seq;
       public          taiga    false    327            �           0    0 #   settings_userprojectsettings_id_seq    SEQUENCE OWNED BY     k   ALTER SEQUENCE public.settings_userprojectsettings_id_seq OWNED BY public.settings_userprojectsettings.id;
          public          taiga    false    326                       1259    9777562 
   tasks_task    TABLE     �  CREATE TABLE public.tasks_task (
    id integer NOT NULL,
    tags text[],
    version integer NOT NULL,
    is_blocked boolean NOT NULL,
    blocked_note text NOT NULL,
    ref bigint,
    created_date timestamp with time zone NOT NULL,
    modified_date timestamp with time zone NOT NULL,
    finished_date timestamp with time zone,
    subject text NOT NULL,
    description text NOT NULL,
    is_iocaine boolean NOT NULL,
    assigned_to_id integer,
    milestone_id integer,
    owner_id integer,
    project_id integer NOT NULL,
    status_id integer,
    user_story_id integer,
    taskboard_order bigint NOT NULL,
    us_order bigint NOT NULL,
    external_reference text[],
    due_date date,
    due_date_reason text NOT NULL
);
    DROP TABLE public.tasks_task;
       public         heap    taiga    false                       1259    9777560    tasks_task_id_seq    SEQUENCE     �   CREATE SEQUENCE public.tasks_task_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
 (   DROP SEQUENCE public.tasks_task_id_seq;
       public          taiga    false    259            �           0    0    tasks_task_id_seq    SEQUENCE OWNED BY     G   ALTER SEQUENCE public.tasks_task_id_seq OWNED BY public.tasks_task.id;
          public          taiga    false    258            I           1259    9778848    telemetry_instancetelemetry    TABLE     �   CREATE TABLE public.telemetry_instancetelemetry (
    id integer NOT NULL,
    instance_id character varying(100) NOT NULL,
    created_at timestamp with time zone NOT NULL
);
 /   DROP TABLE public.telemetry_instancetelemetry;
       public         heap    taiga    false            H           1259    9778846 "   telemetry_instancetelemetry_id_seq    SEQUENCE     �   CREATE SEQUENCE public.telemetry_instancetelemetry_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
 9   DROP SEQUENCE public.telemetry_instancetelemetry_id_seq;
       public          taiga    false    329            �           0    0 "   telemetry_instancetelemetry_id_seq    SEQUENCE OWNED BY     i   ALTER SEQUENCE public.telemetry_instancetelemetry_id_seq OWNED BY public.telemetry_instancetelemetry.id;
          public          taiga    false    328            	           1259    9777742    timeline_timeline    TABLE     �  CREATE TABLE public.timeline_timeline (
    id integer NOT NULL,
    object_id integer NOT NULL,
    namespace character varying(250) NOT NULL,
    event_type character varying(250) NOT NULL,
    project_id integer,
    data jsonb NOT NULL,
    data_content_type_id integer NOT NULL,
    created timestamp with time zone NOT NULL,
    content_type_id integer NOT NULL,
    CONSTRAINT timeline_timeline_object_id_check CHECK ((object_id >= 0))
);
 %   DROP TABLE public.timeline_timeline;
       public         heap    taiga    false                       1259    9777740    timeline_timeline_id_seq    SEQUENCE     �   CREATE SEQUENCE public.timeline_timeline_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
 /   DROP SEQUENCE public.timeline_timeline_id_seq;
       public          taiga    false    265            �           0    0    timeline_timeline_id_seq    SEQUENCE OWNED BY     U   ALTER SEQUENCE public.timeline_timeline_id_seq OWNED BY public.timeline_timeline.id;
          public          taiga    false    264            M           1259    9778889    token_denylist_denylistedtoken    TABLE     �   CREATE TABLE public.token_denylist_denylistedtoken (
    id bigint NOT NULL,
    denylisted_at timestamp with time zone NOT NULL,
    token_id bigint NOT NULL
);
 2   DROP TABLE public.token_denylist_denylistedtoken;
       public         heap    taiga    false            L           1259    9778887 %   token_denylist_denylistedtoken_id_seq    SEQUENCE     �   CREATE SEQUENCE public.token_denylist_denylistedtoken_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
 <   DROP SEQUENCE public.token_denylist_denylistedtoken_id_seq;
       public          taiga    false    333            �           0    0 %   token_denylist_denylistedtoken_id_seq    SEQUENCE OWNED BY     o   ALTER SEQUENCE public.token_denylist_denylistedtoken_id_seq OWNED BY public.token_denylist_denylistedtoken.id;
          public          taiga    false    332            K           1259    9778876    token_denylist_outstandingtoken    TABLE       CREATE TABLE public.token_denylist_outstandingtoken (
    id bigint NOT NULL,
    jti character varying(255) NOT NULL,
    token text NOT NULL,
    created_at timestamp with time zone,
    expires_at timestamp with time zone NOT NULL,
    user_id integer
);
 3   DROP TABLE public.token_denylist_outstandingtoken;
       public         heap    taiga    false            J           1259    9778874 &   token_denylist_outstandingtoken_id_seq    SEQUENCE     �   CREATE SEQUENCE public.token_denylist_outstandingtoken_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
 =   DROP SEQUENCE public.token_denylist_outstandingtoken_id_seq;
       public          taiga    false    331            �           0    0 &   token_denylist_outstandingtoken_id_seq    SEQUENCE OWNED BY     q   ALTER SEQUENCE public.token_denylist_outstandingtoken_id_seq OWNED BY public.token_denylist_outstandingtoken.id;
          public          taiga    false    330                       1259    9777644    users_authdata    TABLE     �   CREATE TABLE public.users_authdata (
    id integer NOT NULL,
    key character varying(50) NOT NULL,
    value character varying(300) NOT NULL,
    extra jsonb NOT NULL,
    user_id integer NOT NULL
);
 "   DROP TABLE public.users_authdata;
       public         heap    taiga    false                       1259    9777642    users_authdata_id_seq    SEQUENCE     �   CREATE SEQUENCE public.users_authdata_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
 ,   DROP SEQUENCE public.users_authdata_id_seq;
       public          taiga    false    261            �           0    0    users_authdata_id_seq    SEQUENCE OWNED BY     O   ALTER SEQUENCE public.users_authdata_id_seq OWNED BY public.users_authdata.id;
          public          taiga    false    260            �            1259    9776801 
   users_role    TABLE       CREATE TABLE public.users_role (
    id integer NOT NULL,
    name character varying(200) NOT NULL,
    slug character varying(250) NOT NULL,
    permissions text[],
    "order" integer NOT NULL,
    computable boolean NOT NULL,
    project_id integer,
    is_admin boolean NOT NULL
);
    DROP TABLE public.users_role;
       public         heap    taiga    false            �            1259    9776799    users_role_id_seq    SEQUENCE     �   CREATE SEQUENCE public.users_role_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
 (   DROP SEQUENCE public.users_role_id_seq;
       public          taiga    false    211            �           0    0    users_role_id_seq    SEQUENCE OWNED BY     G   ALTER SEQUENCE public.users_role_id_seq OWNED BY public.users_role.id;
          public          taiga    false    210            �            1259    9776763 
   users_user    TABLE     �  CREATE TABLE public.users_user (
    id integer NOT NULL,
    password character varying(128) NOT NULL,
    last_login timestamp with time zone,
    is_superuser boolean NOT NULL,
    username character varying(255) NOT NULL,
    email character varying(255) NOT NULL,
    is_active boolean NOT NULL,
    full_name character varying(256) NOT NULL,
    color character varying(9) NOT NULL,
    bio text NOT NULL,
    photo character varying(500),
    date_joined timestamp with time zone NOT NULL,
    lang character varying(20),
    timezone character varying(20),
    colorize_tags boolean NOT NULL,
    token character varying(200),
    email_token character varying(200),
    new_email character varying(254),
    is_system boolean NOT NULL,
    theme character varying(100),
    max_private_projects integer,
    max_public_projects integer,
    max_memberships_private_projects integer,
    max_memberships_public_projects integer,
    uuid character varying(32) NOT NULL,
    accepted_terms boolean NOT NULL,
    read_new_terms boolean NOT NULL,
    verified_email boolean NOT NULL,
    is_staff boolean NOT NULL,
    date_cancelled timestamp with time zone
);
    DROP TABLE public.users_user;
       public         heap    taiga    false            �            1259    9776761    users_user_id_seq    SEQUENCE     �   CREATE SEQUENCE public.users_user_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
 (   DROP SEQUENCE public.users_user_id_seq;
       public          taiga    false    207            �           0    0    users_user_id_seq    SEQUENCE OWNED BY     G   ALTER SEQUENCE public.users_user_id_seq OWNED BY public.users_user.id;
          public          taiga    false    206            O           1259    9778933    users_workspacerole    TABLE       CREATE TABLE public.users_workspacerole (
    id integer NOT NULL,
    name character varying(200) NOT NULL,
    slug character varying(250) NOT NULL,
    permissions text[],
    "order" integer NOT NULL,
    is_admin boolean NOT NULL,
    workspace_id integer NOT NULL
);
 '   DROP TABLE public.users_workspacerole;
       public         heap    taiga    false            N           1259    9778931    users_workspacerole_id_seq    SEQUENCE     �   CREATE SEQUENCE public.users_workspacerole_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
 1   DROP SEQUENCE public.users_workspacerole_id_seq;
       public          taiga    false    335            �           0    0    users_workspacerole_id_seq    SEQUENCE OWNED BY     Y   ALTER SEQUENCE public.users_workspacerole_id_seq OWNED BY public.users_workspacerole.id;
          public          taiga    false    334            Q           1259    9778954    userstorage_storageentry    TABLE       CREATE TABLE public.userstorage_storageentry (
    id integer NOT NULL,
    created_date timestamp with time zone NOT NULL,
    modified_date timestamp with time zone NOT NULL,
    key character varying(255) NOT NULL,
    value jsonb,
    owner_id integer NOT NULL
);
 ,   DROP TABLE public.userstorage_storageentry;
       public         heap    taiga    false            P           1259    9778952    userstorage_storageentry_id_seq    SEQUENCE     �   CREATE SEQUENCE public.userstorage_storageentry_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
 6   DROP SEQUENCE public.userstorage_storageentry_id_seq;
       public          taiga    false    337            �           0    0    userstorage_storageentry_id_seq    SEQUENCE OWNED BY     c   ALTER SEQUENCE public.userstorage_storageentry_id_seq OWNED BY public.userstorage_storageentry.id;
          public          taiga    false    336            �            1259    9777288    userstories_rolepoints    TABLE     �   CREATE TABLE public.userstories_rolepoints (
    id integer NOT NULL,
    points_id integer,
    role_id integer NOT NULL,
    user_story_id integer NOT NULL
);
 *   DROP TABLE public.userstories_rolepoints;
       public         heap    taiga    false            �            1259    9777286    userstories_rolepoints_id_seq    SEQUENCE     �   CREATE SEQUENCE public.userstories_rolepoints_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
 4   DROP SEQUENCE public.userstories_rolepoints_id_seq;
       public          taiga    false    245            �           0    0    userstories_rolepoints_id_seq    SEQUENCE OWNED BY     _   ALTER SEQUENCE public.userstories_rolepoints_id_seq OWNED BY public.userstories_rolepoints.id;
          public          taiga    false    244            �            1259    9777296    userstories_userstory    TABLE     �  CREATE TABLE public.userstories_userstory (
    id integer NOT NULL,
    tags text[],
    version integer NOT NULL,
    is_blocked boolean NOT NULL,
    blocked_note text NOT NULL,
    ref bigint,
    is_closed boolean NOT NULL,
    backlog_order bigint NOT NULL,
    created_date timestamp with time zone NOT NULL,
    modified_date timestamp with time zone NOT NULL,
    finish_date timestamp with time zone,
    subject text NOT NULL,
    description text NOT NULL,
    client_requirement boolean NOT NULL,
    team_requirement boolean NOT NULL,
    assigned_to_id integer,
    generated_from_issue_id integer,
    milestone_id integer,
    owner_id integer,
    project_id integer NOT NULL,
    status_id integer,
    sprint_order bigint NOT NULL,
    kanban_order bigint NOT NULL,
    external_reference text[],
    tribe_gig text,
    due_date date,
    due_date_reason text NOT NULL,
    generated_from_task_id integer,
    from_task_ref text,
    swimlane_id integer
);
 )   DROP TABLE public.userstories_userstory;
       public         heap    taiga    false            S           1259    9779025 $   userstories_userstory_assigned_users    TABLE     �   CREATE TABLE public.userstories_userstory_assigned_users (
    id integer NOT NULL,
    userstory_id integer NOT NULL,
    user_id integer NOT NULL
);
 8   DROP TABLE public.userstories_userstory_assigned_users;
       public         heap    taiga    false            R           1259    9779023 +   userstories_userstory_assigned_users_id_seq    SEQUENCE     �   CREATE SEQUENCE public.userstories_userstory_assigned_users_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
 B   DROP SEQUENCE public.userstories_userstory_assigned_users_id_seq;
       public          taiga    false    339            �           0    0 +   userstories_userstory_assigned_users_id_seq    SEQUENCE OWNED BY     {   ALTER SEQUENCE public.userstories_userstory_assigned_users_id_seq OWNED BY public.userstories_userstory_assigned_users.id;
          public          taiga    false    338            �            1259    9777294    userstories_userstory_id_seq    SEQUENCE     �   CREATE SEQUENCE public.userstories_userstory_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
 3   DROP SEQUENCE public.userstories_userstory_id_seq;
       public          taiga    false    247            �           0    0    userstories_userstory_id_seq    SEQUENCE OWNED BY     ]   ALTER SEQUENCE public.userstories_userstory_id_seq OWNED BY public.userstories_userstory.id;
          public          taiga    false    246            U           1259    9779064 
   votes_vote    TABLE       CREATE TABLE public.votes_vote (
    id integer NOT NULL,
    object_id integer NOT NULL,
    content_type_id integer NOT NULL,
    user_id integer NOT NULL,
    created_date timestamp with time zone NOT NULL,
    CONSTRAINT votes_vote_object_id_check CHECK ((object_id >= 0))
);
    DROP TABLE public.votes_vote;
       public         heap    taiga    false            T           1259    9779062    votes_vote_id_seq    SEQUENCE     �   CREATE SEQUENCE public.votes_vote_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
 (   DROP SEQUENCE public.votes_vote_id_seq;
       public          taiga    false    341            �           0    0    votes_vote_id_seq    SEQUENCE OWNED BY     G   ALTER SEQUENCE public.votes_vote_id_seq OWNED BY public.votes_vote.id;
          public          taiga    false    340            W           1259    9779073    votes_votes    TABLE     !  CREATE TABLE public.votes_votes (
    id integer NOT NULL,
    object_id integer NOT NULL,
    count integer NOT NULL,
    content_type_id integer NOT NULL,
    CONSTRAINT votes_votes_count_check CHECK ((count >= 0)),
    CONSTRAINT votes_votes_object_id_check CHECK ((object_id >= 0))
);
    DROP TABLE public.votes_votes;
       public         heap    taiga    false            V           1259    9779071    votes_votes_id_seq    SEQUENCE     �   CREATE SEQUENCE public.votes_votes_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
 )   DROP SEQUENCE public.votes_votes_id_seq;
       public          taiga    false    343            �           0    0    votes_votes_id_seq    SEQUENCE OWNED BY     I   ALTER SEQUENCE public.votes_votes_id_seq OWNED BY public.votes_votes.id;
          public          taiga    false    342            Y           1259    9779111    webhooks_webhook    TABLE     �   CREATE TABLE public.webhooks_webhook (
    id integer NOT NULL,
    url character varying(200) NOT NULL,
    key text NOT NULL,
    project_id integer NOT NULL,
    name character varying(250) NOT NULL
);
 $   DROP TABLE public.webhooks_webhook;
       public         heap    taiga    false            X           1259    9779109    webhooks_webhook_id_seq    SEQUENCE     �   CREATE SEQUENCE public.webhooks_webhook_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
 .   DROP SEQUENCE public.webhooks_webhook_id_seq;
       public          taiga    false    345            �           0    0    webhooks_webhook_id_seq    SEQUENCE OWNED BY     S   ALTER SEQUENCE public.webhooks_webhook_id_seq OWNED BY public.webhooks_webhook.id;
          public          taiga    false    344            [           1259    9779122    webhooks_webhooklog    TABLE     �  CREATE TABLE public.webhooks_webhooklog (
    id integer NOT NULL,
    url character varying(200) NOT NULL,
    status integer NOT NULL,
    request_data jsonb NOT NULL,
    response_data text NOT NULL,
    webhook_id integer NOT NULL,
    created timestamp with time zone NOT NULL,
    duration double precision NOT NULL,
    request_headers jsonb NOT NULL,
    response_headers jsonb NOT NULL
);
 '   DROP TABLE public.webhooks_webhooklog;
       public         heap    taiga    false            Z           1259    9779120    webhooks_webhooklog_id_seq    SEQUENCE     �   CREATE SEQUENCE public.webhooks_webhooklog_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
 1   DROP SEQUENCE public.webhooks_webhooklog_id_seq;
       public          taiga    false    347            �           0    0    webhooks_webhooklog_id_seq    SEQUENCE OWNED BY     Y   ALTER SEQUENCE public.webhooks_webhooklog_id_seq OWNED BY public.webhooks_webhooklog.id;
          public          taiga    false    346                       1259    9778001    wiki_wikilink    TABLE     �   CREATE TABLE public.wiki_wikilink (
    id integer NOT NULL,
    title character varying(500) NOT NULL,
    href character varying(500) NOT NULL,
    "order" bigint NOT NULL,
    project_id integer NOT NULL
);
 !   DROP TABLE public.wiki_wikilink;
       public         heap    taiga    false                       1259    9777999    wiki_wikilink_id_seq    SEQUENCE     �   CREATE SEQUENCE public.wiki_wikilink_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
 +   DROP SEQUENCE public.wiki_wikilink_id_seq;
       public          taiga    false    273            �           0    0    wiki_wikilink_id_seq    SEQUENCE OWNED BY     M   ALTER SEQUENCE public.wiki_wikilink_id_seq OWNED BY public.wiki_wikilink.id;
          public          taiga    false    272                       1259    9778013    wiki_wikipage    TABLE     `  CREATE TABLE public.wiki_wikipage (
    id integer NOT NULL,
    version integer NOT NULL,
    slug character varying(500) NOT NULL,
    content text NOT NULL,
    created_date timestamp with time zone NOT NULL,
    modified_date timestamp with time zone NOT NULL,
    last_modifier_id integer,
    owner_id integer,
    project_id integer NOT NULL
);
 !   DROP TABLE public.wiki_wikipage;
       public         heap    taiga    false                       1259    9778011    wiki_wikipage_id_seq    SEQUENCE     �   CREATE SEQUENCE public.wiki_wikipage_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
 +   DROP SEQUENCE public.wiki_wikipage_id_seq;
       public          taiga    false    275            �           0    0    wiki_wikipage_id_seq    SEQUENCE OWNED BY     M   ALTER SEQUENCE public.wiki_wikipage_id_seq OWNED BY public.wiki_wikipage.id;
          public          taiga    false    274            8           1259    9778626    workspaces_workspace    TABLE     p  CREATE TABLE public.workspaces_workspace (
    id integer NOT NULL,
    name character varying(40) NOT NULL,
    slug character varying(250),
    color integer NOT NULL,
    created_date timestamp with time zone NOT NULL,
    modified_date timestamp with time zone NOT NULL,
    owner_id integer NOT NULL,
    anon_permissions text[],
    public_permissions text[]
);
 (   DROP TABLE public.workspaces_workspace;
       public         heap    taiga    false            7           1259    9778624    workspaces_workspace_id_seq    SEQUENCE     �   CREATE SEQUENCE public.workspaces_workspace_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
 2   DROP SEQUENCE public.workspaces_workspace_id_seq;
       public          taiga    false    312            �           0    0    workspaces_workspace_id_seq    SEQUENCE OWNED BY     [   ALTER SEQUENCE public.workspaces_workspace_id_seq OWNED BY public.workspaces_workspace.id;
          public          taiga    false    311            ]           1259    9779174    workspaces_workspacemembership    TABLE     �   CREATE TABLE public.workspaces_workspacemembership (
    id integer NOT NULL,
    user_id integer,
    workspace_id integer NOT NULL,
    workspace_role_id integer NOT NULL
);
 2   DROP TABLE public.workspaces_workspacemembership;
       public         heap    taiga    false            \           1259    9779172 %   workspaces_workspacemembership_id_seq    SEQUENCE     �   CREATE SEQUENCE public.workspaces_workspacemembership_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
 <   DROP SEQUENCE public.workspaces_workspacemembership_id_seq;
       public          taiga    false    349            �           0    0 %   workspaces_workspacemembership_id_seq    SEQUENCE OWNED BY     o   ALTER SEQUENCE public.workspaces_workspacemembership_id_seq OWNED BY public.workspaces_workspacemembership.id;
          public          taiga    false    348            �           2604    9777051    attachments_attachment id    DEFAULT     �   ALTER TABLE ONLY public.attachments_attachment ALTER COLUMN id SET DEFAULT nextval('public.attachments_attachment_id_seq'::regclass);
 H   ALTER TABLE public.attachments_attachment ALTER COLUMN id DROP DEFAULT;
       public          taiga    false    232    233    233            �           2604    9777098    auth_group id    DEFAULT     n   ALTER TABLE ONLY public.auth_group ALTER COLUMN id SET DEFAULT nextval('public.auth_group_id_seq'::regclass);
 <   ALTER TABLE public.auth_group ALTER COLUMN id DROP DEFAULT;
       public          taiga    false    237    236    237            �           2604    9777108    auth_group_permissions id    DEFAULT     �   ALTER TABLE ONLY public.auth_group_permissions ALTER COLUMN id SET DEFAULT nextval('public.auth_group_permissions_id_seq'::regclass);
 H   ALTER TABLE public.auth_group_permissions ALTER COLUMN id DROP DEFAULT;
       public          taiga    false    239    238    239            �           2604    9777090    auth_permission id    DEFAULT     x   ALTER TABLE ONLY public.auth_permission ALTER COLUMN id SET DEFAULT nextval('public.auth_permission_id_seq'::regclass);
 A   ALTER TABLE public.auth_permission ALTER COLUMN id DROP DEFAULT;
       public          taiga    false    234    235    235            �           2604    9777981    contact_contactentry id    DEFAULT     �   ALTER TABLE ONLY public.contact_contactentry ALTER COLUMN id SET DEFAULT nextval('public.contact_contactentry_id_seq'::regclass);
 F   ALTER TABLE public.contact_contactentry ALTER COLUMN id DROP DEFAULT;
       public          taiga    false    271    270    271            �           2604    9778317 (   custom_attributes_epiccustomattribute id    DEFAULT     �   ALTER TABLE ONLY public.custom_attributes_epiccustomattribute ALTER COLUMN id SET DEFAULT nextval('public.custom_attributes_epiccustomattribute_id_seq'::regclass);
 W   ALTER TABLE public.custom_attributes_epiccustomattribute ALTER COLUMN id DROP DEFAULT;
       public          taiga    false    294    293    294            �           2604    9778328 /   custom_attributes_epiccustomattributesvalues id    DEFAULT     �   ALTER TABLE ONLY public.custom_attributes_epiccustomattributesvalues ALTER COLUMN id SET DEFAULT nextval('public.custom_attributes_epiccustomattributesvalues_id_seq'::regclass);
 ^   ALTER TABLE public.custom_attributes_epiccustomattributesvalues ALTER COLUMN id DROP DEFAULT;
       public          taiga    false    296    295    296            �           2604    9778192 )   custom_attributes_issuecustomattribute id    DEFAULT     �   ALTER TABLE ONLY public.custom_attributes_issuecustomattribute ALTER COLUMN id SET DEFAULT nextval('public.custom_attributes_issuecustomattribute_id_seq'::regclass);
 X   ALTER TABLE public.custom_attributes_issuecustomattribute ALTER COLUMN id DROP DEFAULT;
       public          taiga    false    282    281    282            �           2604    9778249 0   custom_attributes_issuecustomattributesvalues id    DEFAULT     �   ALTER TABLE ONLY public.custom_attributes_issuecustomattributesvalues ALTER COLUMN id SET DEFAULT nextval('public.custom_attributes_issuecustomattributesvalues_id_seq'::regclass);
 _   ALTER TABLE public.custom_attributes_issuecustomattributesvalues ALTER COLUMN id DROP DEFAULT;
       public          taiga    false    288    287    288            �           2604    9778203 (   custom_attributes_taskcustomattribute id    DEFAULT     �   ALTER TABLE ONLY public.custom_attributes_taskcustomattribute ALTER COLUMN id SET DEFAULT nextval('public.custom_attributes_taskcustomattribute_id_seq'::regclass);
 W   ALTER TABLE public.custom_attributes_taskcustomattribute ALTER COLUMN id DROP DEFAULT;
       public          taiga    false    284    283    284            �           2604    9778262 /   custom_attributes_taskcustomattributesvalues id    DEFAULT     �   ALTER TABLE ONLY public.custom_attributes_taskcustomattributesvalues ALTER COLUMN id SET DEFAULT nextval('public.custom_attributes_taskcustomattributesvalues_id_seq'::regclass);
 ^   ALTER TABLE public.custom_attributes_taskcustomattributesvalues ALTER COLUMN id DROP DEFAULT;
       public          taiga    false    290    289    290            �           2604    9778214 -   custom_attributes_userstorycustomattribute id    DEFAULT     �   ALTER TABLE ONLY public.custom_attributes_userstorycustomattribute ALTER COLUMN id SET DEFAULT nextval('public.custom_attributes_userstorycustomattribute_id_seq'::regclass);
 \   ALTER TABLE public.custom_attributes_userstorycustomattribute ALTER COLUMN id DROP DEFAULT;
       public          taiga    false    286    285    286            �           2604    9778275 4   custom_attributes_userstorycustomattributesvalues id    DEFAULT     �   ALTER TABLE ONLY public.custom_attributes_userstorycustomattributesvalues ALTER COLUMN id SET DEFAULT nextval('public.custom_attributes_userstorycustomattributesvalues_id_seq'::regclass);
 c   ALTER TABLE public.custom_attributes_userstorycustomattributesvalues ALTER COLUMN id DROP DEFAULT;
       public          taiga    false    292    291    292            �           2604    9776780    django_admin_log id    DEFAULT     z   ALTER TABLE ONLY public.django_admin_log ALTER COLUMN id SET DEFAULT nextval('public.django_admin_log_id_seq'::regclass);
 B   ALTER TABLE public.django_admin_log ALTER COLUMN id DROP DEFAULT;
       public          taiga    false    208    209    209            �           2604    9776756    django_content_type id    DEFAULT     �   ALTER TABLE ONLY public.django_content_type ALTER COLUMN id SET DEFAULT nextval('public.django_content_type_id_seq'::regclass);
 E   ALTER TABLE public.django_content_type ALTER COLUMN id DROP DEFAULT;
       public          taiga    false    204    205    205            �           2604    9776745    django_migrations id    DEFAULT     |   ALTER TABLE ONLY public.django_migrations ALTER COLUMN id SET DEFAULT nextval('public.django_migrations_id_seq'::regclass);
 C   ALTER TABLE public.django_migrations ALTER COLUMN id DROP DEFAULT;
       public          taiga    false    203    202    203            �           2604    9778438    easy_thumbnails_source id    DEFAULT     �   ALTER TABLE ONLY public.easy_thumbnails_source ALTER COLUMN id SET DEFAULT nextval('public.easy_thumbnails_source_id_seq'::regclass);
 H   ALTER TABLE public.easy_thumbnails_source ALTER COLUMN id DROP DEFAULT;
       public          taiga    false    299    298    299            �           2604    9778446    easy_thumbnails_thumbnail id    DEFAULT     �   ALTER TABLE ONLY public.easy_thumbnails_thumbnail ALTER COLUMN id SET DEFAULT nextval('public.easy_thumbnails_thumbnail_id_seq'::regclass);
 K   ALTER TABLE public.easy_thumbnails_thumbnail ALTER COLUMN id DROP DEFAULT;
       public          taiga    false    301    300    301            �           2604    9778472 &   easy_thumbnails_thumbnaildimensions id    DEFAULT     �   ALTER TABLE ONLY public.easy_thumbnails_thumbnaildimensions ALTER COLUMN id SET DEFAULT nextval('public.easy_thumbnails_thumbnaildimensions_id_seq'::regclass);
 U   ALTER TABLE public.easy_thumbnails_thumbnaildimensions ALTER COLUMN id DROP DEFAULT;
       public          taiga    false    303    302    303            �           2604    9778133    epics_epic id    DEFAULT     n   ALTER TABLE ONLY public.epics_epic ALTER COLUMN id SET DEFAULT nextval('public.epics_epic_id_seq'::regclass);
 <   ALTER TABLE public.epics_epic ALTER COLUMN id DROP DEFAULT;
       public          taiga    false    278    277    278            �           2604    9778144    epics_relateduserstory id    DEFAULT     �   ALTER TABLE ONLY public.epics_relateduserstory ALTER COLUMN id SET DEFAULT nextval('public.epics_relateduserstory_id_seq'::regclass);
 H   ALTER TABLE public.epics_relateduserstory ALTER COLUMN id DROP DEFAULT;
       public          taiga    false    279    280    280            �           2604    9778523 !   external_apps_applicationtoken id    DEFAULT     �   ALTER TABLE ONLY public.external_apps_applicationtoken ALTER COLUMN id SET DEFAULT nextval('public.external_apps_applicationtoken_id_seq'::regclass);
 P   ALTER TABLE public.external_apps_applicationtoken ALTER COLUMN id DROP DEFAULT;
       public          taiga    false    305    306    306            �           2604    9778550    feedback_feedbackentry id    DEFAULT     �   ALTER TABLE ONLY public.feedback_feedbackentry ALTER COLUMN id SET DEFAULT nextval('public.feedback_feedbackentry_id_seq'::regclass);
 H   ALTER TABLE public.feedback_feedbackentry ALTER COLUMN id DROP DEFAULT;
       public          taiga    false    308    307    308            �           2604    9777209    issues_issue id    DEFAULT     r   ALTER TABLE ONLY public.issues_issue ALTER COLUMN id SET DEFAULT nextval('public.issues_issue_id_seq'::regclass);
 >   ALTER TABLE public.issues_issue ALTER COLUMN id DROP DEFAULT;
       public          taiga    false    243    242    243            �           2604    9777795    likes_like id    DEFAULT     n   ALTER TABLE ONLY public.likes_like ALTER COLUMN id SET DEFAULT nextval('public.likes_like_id_seq'::regclass);
 <   ALTER TABLE public.likes_like ALTER COLUMN id DROP DEFAULT;
       public          taiga    false    267    266    267            �           2604    9777158    milestones_milestone id    DEFAULT     �   ALTER TABLE ONLY public.milestones_milestone ALTER COLUMN id SET DEFAULT nextval('public.milestones_milestone_id_seq'::regclass);
 F   ALTER TABLE public.milestones_milestone ALTER COLUMN id DROP DEFAULT;
       public          taiga    false    240    241    241            �           2604    9777469 *   notifications_historychangenotification id    DEFAULT     �   ALTER TABLE ONLY public.notifications_historychangenotification ALTER COLUMN id SET DEFAULT nextval('public.notifications_historychangenotification_id_seq'::regclass);
 Y   ALTER TABLE public.notifications_historychangenotification ALTER COLUMN id DROP DEFAULT;
       public          taiga    false    251    250    251            �           2604    9777477 :   notifications_historychangenotification_history_entries id    DEFAULT     �   ALTER TABLE ONLY public.notifications_historychangenotification_history_entries ALTER COLUMN id SET DEFAULT nextval('public.notifications_historychangenotification_history_entries_id_seq'::regclass);
 i   ALTER TABLE public.notifications_historychangenotification_history_entries ALTER COLUMN id DROP DEFAULT;
       public          taiga    false    253    252    253            �           2604    9777485 7   notifications_historychangenotification_notify_users id    DEFAULT     �   ALTER TABLE ONLY public.notifications_historychangenotification_notify_users ALTER COLUMN id SET DEFAULT nextval('public.notifications_historychangenotification_notify_users_id_seq'::regclass);
 f   ALTER TABLE public.notifications_historychangenotification_notify_users ALTER COLUMN id DROP DEFAULT;
       public          taiga    false    255    254    255            �           2604    9777426    notifications_notifypolicy id    DEFAULT     �   ALTER TABLE ONLY public.notifications_notifypolicy ALTER COLUMN id SET DEFAULT nextval('public.notifications_notifypolicy_id_seq'::regclass);
 L   ALTER TABLE public.notifications_notifypolicy ALTER COLUMN id DROP DEFAULT;
       public          taiga    false    249    248    249            �           2604    9777536    notifications_watched id    DEFAULT     �   ALTER TABLE ONLY public.notifications_watched ALTER COLUMN id SET DEFAULT nextval('public.notifications_watched_id_seq'::regclass);
 G   ALTER TABLE public.notifications_watched ALTER COLUMN id DROP DEFAULT;
       public          taiga    false    257    256    257            �           2604    9778609     notifications_webnotification id    DEFAULT     �   ALTER TABLE ONLY public.notifications_webnotification ALTER COLUMN id SET DEFAULT nextval('public.notifications_webnotification_id_seq'::regclass);
 O   ALTER TABLE public.notifications_webnotification ALTER COLUMN id DROP DEFAULT;
       public          taiga    false    310    309    310            �           2604    9777902    projects_epicstatus id    DEFAULT     �   ALTER TABLE ONLY public.projects_epicstatus ALTER COLUMN id SET DEFAULT nextval('public.projects_epicstatus_id_seq'::regclass);
 E   ALTER TABLE public.projects_epicstatus ALTER COLUMN id DROP DEFAULT;
       public          taiga    false    269    268    269            �           2604    9778652    projects_issueduedate id    DEFAULT     �   ALTER TABLE ONLY public.projects_issueduedate ALTER COLUMN id SET DEFAULT nextval('public.projects_issueduedate_id_seq'::regclass);
 G   ALTER TABLE public.projects_issueduedate ALTER COLUMN id DROP DEFAULT;
       public          taiga    false    313    314    314            �           2604    9776870    projects_issuestatus id    DEFAULT     �   ALTER TABLE ONLY public.projects_issuestatus ALTER COLUMN id SET DEFAULT nextval('public.projects_issuestatus_id_seq'::regclass);
 F   ALTER TABLE public.projects_issuestatus ALTER COLUMN id DROP DEFAULT;
       public          taiga    false    217    216    217            �           2604    9776878    projects_issuetype id    DEFAULT     ~   ALTER TABLE ONLY public.projects_issuetype ALTER COLUMN id SET DEFAULT nextval('public.projects_issuetype_id_seq'::regclass);
 D   ALTER TABLE public.projects_issuetype ALTER COLUMN id DROP DEFAULT;
       public          taiga    false    218    219    219            �           2604    9776817    projects_membership id    DEFAULT     �   ALTER TABLE ONLY public.projects_membership ALTER COLUMN id SET DEFAULT nextval('public.projects_membership_id_seq'::regclass);
 E   ALTER TABLE public.projects_membership ALTER COLUMN id DROP DEFAULT;
       public          taiga    false    213    212    213            �           2604    9776886    projects_points id    DEFAULT     x   ALTER TABLE ONLY public.projects_points ALTER COLUMN id SET DEFAULT nextval('public.projects_points_id_seq'::regclass);
 A   ALTER TABLE public.projects_points ALTER COLUMN id DROP DEFAULT;
       public          taiga    false    220    221    221            �           2604    9776894    projects_priority id    DEFAULT     |   ALTER TABLE ONLY public.projects_priority ALTER COLUMN id SET DEFAULT nextval('public.projects_priority_id_seq'::regclass);
 C   ALTER TABLE public.projects_priority ALTER COLUMN id DROP DEFAULT;
       public          taiga    false    223    222    223            �           2604    9776825    projects_project id    DEFAULT     z   ALTER TABLE ONLY public.projects_project ALTER COLUMN id SET DEFAULT nextval('public.projects_project_id_seq'::regclass);
 B   ALTER TABLE public.projects_project ALTER COLUMN id DROP DEFAULT;
       public          taiga    false    214    215    215            �           2604    9777720     projects_projectmodulesconfig id    DEFAULT     �   ALTER TABLE ONLY public.projects_projectmodulesconfig ALTER COLUMN id SET DEFAULT nextval('public.projects_projectmodulesconfig_id_seq'::regclass);
 O   ALTER TABLE public.projects_projectmodulesconfig ALTER COLUMN id DROP DEFAULT;
       public          taiga    false    263    262    263            �           2604    9776902    projects_projecttemplate id    DEFAULT     �   ALTER TABLE ONLY public.projects_projecttemplate ALTER COLUMN id SET DEFAULT nextval('public.projects_projecttemplate_id_seq'::regclass);
 J   ALTER TABLE public.projects_projecttemplate ALTER COLUMN id DROP DEFAULT;
       public          taiga    false    225    224    225            �           2604    9776915    projects_severity id    DEFAULT     |   ALTER TABLE ONLY public.projects_severity ALTER COLUMN id SET DEFAULT nextval('public.projects_severity_id_seq'::regclass);
 C   ALTER TABLE public.projects_severity ALTER COLUMN id DROP DEFAULT;
       public          taiga    false    226    227    227            �           2604    9778707    projects_swimlane id    DEFAULT     |   ALTER TABLE ONLY public.projects_swimlane ALTER COLUMN id SET DEFAULT nextval('public.projects_swimlane_id_seq'::regclass);
 C   ALTER TABLE public.projects_swimlane ALTER COLUMN id DROP DEFAULT;
       public          taiga    false    319    320    320            �           2604    9778724 #   projects_swimlaneuserstorystatus id    DEFAULT     �   ALTER TABLE ONLY public.projects_swimlaneuserstorystatus ALTER COLUMN id SET DEFAULT nextval('public.projects_swimlaneuserstorystatus_id_seq'::regclass);
 R   ALTER TABLE public.projects_swimlaneuserstorystatus ALTER COLUMN id DROP DEFAULT;
       public          taiga    false    321    322    322            �           2604    9778660    projects_taskduedate id    DEFAULT     �   ALTER TABLE ONLY public.projects_taskduedate ALTER COLUMN id SET DEFAULT nextval('public.projects_taskduedate_id_seq'::regclass);
 F   ALTER TABLE public.projects_taskduedate ALTER COLUMN id DROP DEFAULT;
       public          taiga    false    316    315    316            �           2604    9776923    projects_taskstatus id    DEFAULT     �   ALTER TABLE ONLY public.projects_taskstatus ALTER COLUMN id SET DEFAULT nextval('public.projects_taskstatus_id_seq'::regclass);
 E   ALTER TABLE public.projects_taskstatus ALTER COLUMN id DROP DEFAULT;
       public          taiga    false    228    229    229            �           2604    9778668    projects_userstoryduedate id    DEFAULT     �   ALTER TABLE ONLY public.projects_userstoryduedate ALTER COLUMN id SET DEFAULT nextval('public.projects_userstoryduedate_id_seq'::regclass);
 K   ALTER TABLE public.projects_userstoryduedate ALTER COLUMN id DROP DEFAULT;
       public          taiga    false    317    318    318            �           2604    9776931    projects_userstorystatus id    DEFAULT     �   ALTER TABLE ONLY public.projects_userstorystatus ALTER COLUMN id SET DEFAULT nextval('public.projects_userstorystatus_id_seq'::regclass);
 J   ALTER TABLE public.projects_userstorystatus ALTER COLUMN id DROP DEFAULT;
       public          taiga    false    230    231    231            �           2604    9778762    references_reference id    DEFAULT     �   ALTER TABLE ONLY public.references_reference ALTER COLUMN id SET DEFAULT nextval('public.references_reference_id_seq'::regclass);
 F   ALTER TABLE public.references_reference ALTER COLUMN id DROP DEFAULT;
       public          taiga    false    324    323    324            �           2604    9778795    settings_userprojectsettings id    DEFAULT     �   ALTER TABLE ONLY public.settings_userprojectsettings ALTER COLUMN id SET DEFAULT nextval('public.settings_userprojectsettings_id_seq'::regclass);
 N   ALTER TABLE public.settings_userprojectsettings ALTER COLUMN id DROP DEFAULT;
       public          taiga    false    326    327    327            �           2604    9777565    tasks_task id    DEFAULT     n   ALTER TABLE ONLY public.tasks_task ALTER COLUMN id SET DEFAULT nextval('public.tasks_task_id_seq'::regclass);
 <   ALTER TABLE public.tasks_task ALTER COLUMN id DROP DEFAULT;
       public          taiga    false    259    258    259            �           2604    9778851    telemetry_instancetelemetry id    DEFAULT     �   ALTER TABLE ONLY public.telemetry_instancetelemetry ALTER COLUMN id SET DEFAULT nextval('public.telemetry_instancetelemetry_id_seq'::regclass);
 M   ALTER TABLE public.telemetry_instancetelemetry ALTER COLUMN id DROP DEFAULT;
       public          taiga    false    329    328    329            �           2604    9777745    timeline_timeline id    DEFAULT     |   ALTER TABLE ONLY public.timeline_timeline ALTER COLUMN id SET DEFAULT nextval('public.timeline_timeline_id_seq'::regclass);
 C   ALTER TABLE public.timeline_timeline ALTER COLUMN id DROP DEFAULT;
       public          taiga    false    265    264    265            �           2604    9778892 !   token_denylist_denylistedtoken id    DEFAULT     �   ALTER TABLE ONLY public.token_denylist_denylistedtoken ALTER COLUMN id SET DEFAULT nextval('public.token_denylist_denylistedtoken_id_seq'::regclass);
 P   ALTER TABLE public.token_denylist_denylistedtoken ALTER COLUMN id DROP DEFAULT;
       public          taiga    false    332    333    333            �           2604    9778879 "   token_denylist_outstandingtoken id    DEFAULT     �   ALTER TABLE ONLY public.token_denylist_outstandingtoken ALTER COLUMN id SET DEFAULT nextval('public.token_denylist_outstandingtoken_id_seq'::regclass);
 Q   ALTER TABLE public.token_denylist_outstandingtoken ALTER COLUMN id DROP DEFAULT;
       public          taiga    false    330    331    331            �           2604    9777647    users_authdata id    DEFAULT     v   ALTER TABLE ONLY public.users_authdata ALTER COLUMN id SET DEFAULT nextval('public.users_authdata_id_seq'::regclass);
 @   ALTER TABLE public.users_authdata ALTER COLUMN id DROP DEFAULT;
       public          taiga    false    261    260    261            �           2604    9776804    users_role id    DEFAULT     n   ALTER TABLE ONLY public.users_role ALTER COLUMN id SET DEFAULT nextval('public.users_role_id_seq'::regclass);
 <   ALTER TABLE public.users_role ALTER COLUMN id DROP DEFAULT;
       public          taiga    false    210    211    211            �           2604    9776766    users_user id    DEFAULT     n   ALTER TABLE ONLY public.users_user ALTER COLUMN id SET DEFAULT nextval('public.users_user_id_seq'::regclass);
 <   ALTER TABLE public.users_user ALTER COLUMN id DROP DEFAULT;
       public          taiga    false    206    207    207            �           2604    9778936    users_workspacerole id    DEFAULT     �   ALTER TABLE ONLY public.users_workspacerole ALTER COLUMN id SET DEFAULT nextval('public.users_workspacerole_id_seq'::regclass);
 E   ALTER TABLE public.users_workspacerole ALTER COLUMN id DROP DEFAULT;
       public          taiga    false    335    334    335            �           2604    9778957    userstorage_storageentry id    DEFAULT     �   ALTER TABLE ONLY public.userstorage_storageentry ALTER COLUMN id SET DEFAULT nextval('public.userstorage_storageentry_id_seq'::regclass);
 J   ALTER TABLE public.userstorage_storageentry ALTER COLUMN id DROP DEFAULT;
       public          taiga    false    336    337    337            �           2604    9777291    userstories_rolepoints id    DEFAULT     �   ALTER TABLE ONLY public.userstories_rolepoints ALTER COLUMN id SET DEFAULT nextval('public.userstories_rolepoints_id_seq'::regclass);
 H   ALTER TABLE public.userstories_rolepoints ALTER COLUMN id DROP DEFAULT;
       public          taiga    false    245    244    245            �           2604    9777299    userstories_userstory id    DEFAULT     �   ALTER TABLE ONLY public.userstories_userstory ALTER COLUMN id SET DEFAULT nextval('public.userstories_userstory_id_seq'::regclass);
 G   ALTER TABLE public.userstories_userstory ALTER COLUMN id DROP DEFAULT;
       public          taiga    false    246    247    247            �           2604    9779028 '   userstories_userstory_assigned_users id    DEFAULT     �   ALTER TABLE ONLY public.userstories_userstory_assigned_users ALTER COLUMN id SET DEFAULT nextval('public.userstories_userstory_assigned_users_id_seq'::regclass);
 V   ALTER TABLE public.userstories_userstory_assigned_users ALTER COLUMN id DROP DEFAULT;
       public          taiga    false    338    339    339            �           2604    9779067    votes_vote id    DEFAULT     n   ALTER TABLE ONLY public.votes_vote ALTER COLUMN id SET DEFAULT nextval('public.votes_vote_id_seq'::regclass);
 <   ALTER TABLE public.votes_vote ALTER COLUMN id DROP DEFAULT;
       public          taiga    false    340    341    341            �           2604    9779076    votes_votes id    DEFAULT     p   ALTER TABLE ONLY public.votes_votes ALTER COLUMN id SET DEFAULT nextval('public.votes_votes_id_seq'::regclass);
 =   ALTER TABLE public.votes_votes ALTER COLUMN id DROP DEFAULT;
       public          taiga    false    343    342    343            �           2604    9779114    webhooks_webhook id    DEFAULT     z   ALTER TABLE ONLY public.webhooks_webhook ALTER COLUMN id SET DEFAULT nextval('public.webhooks_webhook_id_seq'::regclass);
 B   ALTER TABLE public.webhooks_webhook ALTER COLUMN id DROP DEFAULT;
       public          taiga    false    345    344    345            �           2604    9779125    webhooks_webhooklog id    DEFAULT     �   ALTER TABLE ONLY public.webhooks_webhooklog ALTER COLUMN id SET DEFAULT nextval('public.webhooks_webhooklog_id_seq'::regclass);
 E   ALTER TABLE public.webhooks_webhooklog ALTER COLUMN id DROP DEFAULT;
       public          taiga    false    346    347    347            �           2604    9778004    wiki_wikilink id    DEFAULT     t   ALTER TABLE ONLY public.wiki_wikilink ALTER COLUMN id SET DEFAULT nextval('public.wiki_wikilink_id_seq'::regclass);
 ?   ALTER TABLE public.wiki_wikilink ALTER COLUMN id DROP DEFAULT;
       public          taiga    false    273    272    273            �           2604    9778016    wiki_wikipage id    DEFAULT     t   ALTER TABLE ONLY public.wiki_wikipage ALTER COLUMN id SET DEFAULT nextval('public.wiki_wikipage_id_seq'::regclass);
 ?   ALTER TABLE public.wiki_wikipage ALTER COLUMN id DROP DEFAULT;
       public          taiga    false    275    274    275            �           2604    9778629    workspaces_workspace id    DEFAULT     �   ALTER TABLE ONLY public.workspaces_workspace ALTER COLUMN id SET DEFAULT nextval('public.workspaces_workspace_id_seq'::regclass);
 F   ALTER TABLE public.workspaces_workspace ALTER COLUMN id DROP DEFAULT;
       public          taiga    false    311    312    312            �           2604    9779177 !   workspaces_workspacemembership id    DEFAULT     �   ALTER TABLE ONLY public.workspaces_workspacemembership ALTER COLUMN id SET DEFAULT nextval('public.workspaces_workspacemembership_id_seq'::regclass);
 P   ALTER TABLE public.workspaces_workspacemembership ALTER COLUMN id DROP DEFAULT;
       public          taiga    false    348    349    349            �          0    9777048    attachments_attachment 
   TABLE DATA           �   COPY public.attachments_attachment (id, object_id, created_date, modified_date, attached_file, is_deprecated, description, "order", content_type_id, owner_id, project_id, name, size, sha1, from_comment) FROM stdin;
    public          taiga    false    233   9�      �          0    9777095 
   auth_group 
   TABLE DATA           .   COPY public.auth_group (id, name) FROM stdin;
    public          taiga    false    237   V�                 0    9777105    auth_group_permissions 
   TABLE DATA           M   COPY public.auth_group_permissions (id, group_id, permission_id) FROM stdin;
    public          taiga    false    239   s�      �          0    9777087    auth_permission 
   TABLE DATA           N   COPY public.auth_permission (id, name, content_type_id, codename) FROM stdin;
    public          taiga    false    235   ��                 0    9777978    contact_contactentry 
   TABLE DATA           ^   COPY public.contact_contactentry (id, comment, created_date, project_id, user_id) FROM stdin;
    public          taiga    false    271   ��      7          0    9778314 %   custom_attributes_epiccustomattribute 
   TABLE DATA           �   COPY public.custom_attributes_epiccustomattribute (id, name, description, type, "order", created_date, modified_date, project_id, extra) FROM stdin;
    public          taiga    false    294   ��      9          0    9778325 ,   custom_attributes_epiccustomattributesvalues 
   TABLE DATA           o   COPY public.custom_attributes_epiccustomattributesvalues (id, version, attributes_values, epic_id) FROM stdin;
    public          taiga    false    296   ��      +          0    9778189 &   custom_attributes_issuecustomattribute 
   TABLE DATA           �   COPY public.custom_attributes_issuecustomattribute (id, name, description, "order", created_date, modified_date, project_id, type, extra) FROM stdin;
    public          taiga    false    282   ��      1          0    9778246 -   custom_attributes_issuecustomattributesvalues 
   TABLE DATA           q   COPY public.custom_attributes_issuecustomattributesvalues (id, version, attributes_values, issue_id) FROM stdin;
    public          taiga    false    288   �      -          0    9778200 %   custom_attributes_taskcustomattribute 
   TABLE DATA           �   COPY public.custom_attributes_taskcustomattribute (id, name, description, "order", created_date, modified_date, project_id, type, extra) FROM stdin;
    public          taiga    false    284   .�      3          0    9778259 ,   custom_attributes_taskcustomattributesvalues 
   TABLE DATA           o   COPY public.custom_attributes_taskcustomattributesvalues (id, version, attributes_values, task_id) FROM stdin;
    public          taiga    false    290   K�      /          0    9778211 *   custom_attributes_userstorycustomattribute 
   TABLE DATA           �   COPY public.custom_attributes_userstorycustomattribute (id, name, description, "order", created_date, modified_date, project_id, type, extra) FROM stdin;
    public          taiga    false    286   h�      5          0    9778272 1   custom_attributes_userstorycustomattributesvalues 
   TABLE DATA           z   COPY public.custom_attributes_userstorycustomattributesvalues (id, version, attributes_values, user_story_id) FROM stdin;
    public          taiga    false    292   ��      �          0    9776777    django_admin_log 
   TABLE DATA           �   COPY public.django_admin_log (id, action_time, object_id, object_repr, action_flag, change_message, content_type_id, user_id) FROM stdin;
    public          taiga    false    209   ��      �          0    9776753    django_content_type 
   TABLE DATA           C   COPY public.django_content_type (id, app_label, model) FROM stdin;
    public          taiga    false    205   ��      �          0    9776742    django_migrations 
   TABLE DATA           C   COPY public.django_migrations (id, app, name, applied) FROM stdin;
    public          taiga    false    203   o�      V          0    9778780    django_session 
   TABLE DATA           P   COPY public.django_session (session_key, session_data, expire_date) FROM stdin;
    public          taiga    false    325   1      :          0    9778424    djmail_message 
   TABLE DATA           �   COPY public.djmail_message (uuid, from_email, to_email, body_text, body_html, subject, data, retry_count, status, priority, created_at, sent_at, exception) FROM stdin;
    public          taiga    false    297   N      <          0    9778435    easy_thumbnails_source 
   TABLE DATA           R   COPY public.easy_thumbnails_source (id, storage_hash, name, modified) FROM stdin;
    public          taiga    false    299   k      >          0    9778443    easy_thumbnails_thumbnail 
   TABLE DATA           `   COPY public.easy_thumbnails_thumbnail (id, storage_hash, name, modified, source_id) FROM stdin;
    public          taiga    false    301   �      @          0    9778469 #   easy_thumbnails_thumbnaildimensions 
   TABLE DATA           ^   COPY public.easy_thumbnails_thumbnaildimensions (id, thumbnail_id, width, height) FROM stdin;
    public          taiga    false    303   �      '          0    9778130 
   epics_epic 
   TABLE DATA             COPY public.epics_epic (id, tags, version, is_blocked, blocked_note, ref, epics_order, created_date, modified_date, subject, description, client_requirement, team_requirement, assigned_to_id, owner_id, project_id, status_id, color, external_reference) FROM stdin;
    public          taiga    false    278   �      )          0    9778141    epics_relateduserstory 
   TABLE DATA           U   COPY public.epics_relateduserstory (id, "order", epic_id, user_story_id) FROM stdin;
    public          taiga    false    280   �      A          0    9778510    external_apps_application 
   TABLE DATA           c   COPY public.external_apps_application (id, name, icon_url, web, description, next_url) FROM stdin;
    public          taiga    false    304   �      C          0    9778520    external_apps_applicationtoken 
   TABLE DATA           n   COPY public.external_apps_applicationtoken (id, auth_code, token, state, application_id, user_id) FROM stdin;
    public          taiga    false    306         E          0    9778547    feedback_feedbackentry 
   TABLE DATA           ]   COPY public.feedback_feedbackentry (id, full_name, email, comment, created_date) FROM stdin;
    public          taiga    false    308   6      %          0    9778092    history_historyentry 
   TABLE DATA             COPY public.history_historyentry (id, "user", created_at, type, is_snapshot, key, diff, snapshot, "values", comment, comment_html, delete_comment_date, delete_comment_user, is_hidden, comment_versions, edit_comment_date, project_id, values_diff_cache) FROM stdin;
    public          taiga    false    276   S                0    9777206    issues_issue 
   TABLE DATA           +  COPY public.issues_issue (id, tags, version, is_blocked, blocked_note, ref, created_date, modified_date, finished_date, subject, description, assigned_to_id, milestone_id, owner_id, priority_id, project_id, severity_id, status_id, type_id, external_reference, due_date, due_date_reason) FROM stdin;
    public          taiga    false    243   p                0    9777792 
   likes_like 
   TABLE DATA           [   COPY public.likes_like (id, object_id, created_date, content_type_id, user_id) FROM stdin;
    public          taiga    false    267   �                0    9777155    milestones_milestone 
   TABLE DATA           �   COPY public.milestones_milestone (id, name, slug, estimated_start, estimated_finish, created_date, modified_date, closed, disponibility, "order", owner_id, project_id) FROM stdin;
    public          taiga    false    241   �                0    9777466 '   notifications_historychangenotification 
   TABLE DATA           �   COPY public.notifications_historychangenotification (id, key, created_datetime, updated_datetime, history_type, owner_id, project_id) FROM stdin;
    public          taiga    false    251   �                0    9777474 7   notifications_historychangenotification_history_entries 
   TABLE DATA           �   COPY public.notifications_historychangenotification_history_entries (id, historychangenotification_id, historyentry_id) FROM stdin;
    public          taiga    false    253   �                0    9777482 4   notifications_historychangenotification_notify_users 
   TABLE DATA           y   COPY public.notifications_historychangenotification_notify_users (id, historychangenotification_id, user_id) FROM stdin;
    public          taiga    false    255         
          0    9777423    notifications_notifypolicy 
   TABLE DATA           �   COPY public.notifications_notifypolicy (id, notify_level, created_at, modified_at, project_id, user_id, live_notify_level, web_notify_level) FROM stdin;
    public          taiga    false    249                   0    9777533    notifications_watched 
   TABLE DATA           r   COPY public.notifications_watched (id, object_id, created_date, content_type_id, user_id, project_id) FROM stdin;
    public          taiga    false    257   h      G          0    9778606    notifications_webnotification 
   TABLE DATA           e   COPY public.notifications_webnotification (id, created, read, event_type, data, user_id) FROM stdin;
    public          taiga    false    310   �                0    9777899    projects_epicstatus 
   TABLE DATA           d   COPY public.projects_epicstatus (id, name, slug, "order", is_closed, color, project_id) FROM stdin;
    public          taiga    false    269   �      K          0    9778649    projects_issueduedate 
   TABLE DATA           n   COPY public.projects_issueduedate (id, name, "order", by_default, color, days_to_due, project_id) FROM stdin;
    public          taiga    false    314   $      �          0    9776867    projects_issuestatus 
   TABLE DATA           e   COPY public.projects_issuestatus (id, name, "order", is_closed, color, project_id, slug) FROM stdin;
    public          taiga    false    217         �          0    9776875    projects_issuetype 
   TABLE DATA           R   COPY public.projects_issuetype (id, name, "order", color, project_id) FROM stdin;
    public          taiga    false    219   �      �          0    9776814    projects_membership 
   TABLE DATA           �   COPY public.projects_membership (id, is_admin, email, created_at, token, user_id, project_id, role_id, invited_by_id, invitation_extra_text, user_order) FROM stdin;
    public          taiga    false    213   �      �          0    9776883    projects_points 
   TABLE DATA           O   COPY public.projects_points (id, name, "order", value, project_id) FROM stdin;
    public          taiga    false    221         �          0    9776891    projects_priority 
   TABLE DATA           Q   COPY public.projects_priority (id, name, "order", color, project_id) FROM stdin;
    public          taiga    false    223   �      �          0    9776822    projects_project 
   TABLE DATA           �  COPY public.projects_project (id, tags, name, slug, description, created_date, modified_date, total_milestones, total_story_points, is_backlog_activated, is_kanban_activated, is_wiki_activated, is_issues_activated, videoconferences, videoconferences_extra_data, anon_permissions, public_permissions, is_private, tags_colors, owner_id, creation_template_id, default_issue_status_id, default_issue_type_id, default_points_id, default_priority_id, default_severity_id, default_task_status_id, default_us_status_id, issues_csv_uuid, tasks_csv_uuid, userstories_csv_uuid, is_featured, is_looking_for_people, total_activity, total_activity_last_month, total_activity_last_week, total_activity_last_year, total_fans, total_fans_last_month, total_fans_last_week, total_fans_last_year, totals_updated_datetime, logo, looking_for_people_note, blocked_code, transfer_token, is_epics_activated, default_epic_status_id, epics_csv_uuid, is_contact_activated, default_swimlane_id, workspace_id, color) FROM stdin;
    public          taiga    false    215   h                0    9777717    projects_projectmodulesconfig 
   TABLE DATA           O   COPY public.projects_projectmodulesconfig (id, config, project_id) FROM stdin;
    public          taiga    false    263   �!      �          0    9776899    projects_projecttemplate 
   TABLE DATA           �  COPY public.projects_projecttemplate (id, name, slug, description, created_date, modified_date, default_owner_role, is_backlog_activated, is_kanban_activated, is_wiki_activated, is_issues_activated, videoconferences, videoconferences_extra_data, default_options, us_statuses, points, task_statuses, issue_statuses, issue_types, priorities, severities, roles, "order", epic_statuses, is_epics_activated, is_contact_activated, epic_custom_attributes, is_looking_for_people, issue_custom_attributes, looking_for_people_note, tags, tags_colors, task_custom_attributes, us_custom_attributes, issue_duedates, task_duedates, us_duedates) FROM stdin;
    public          taiga    false    225   �!      �          0    9776912    projects_severity 
   TABLE DATA           Q   COPY public.projects_severity (id, name, "order", color, project_id) FROM stdin;
    public          taiga    false    227   S'      Q          0    9778704    projects_swimlane 
   TABLE DATA           J   COPY public.projects_swimlane (id, name, "order", project_id) FROM stdin;
    public          taiga    false    320   �(      S          0    9778721     projects_swimlaneuserstorystatus 
   TABLE DATA           a   COPY public.projects_swimlaneuserstorystatus (id, wip_limit, status_id, swimlane_id) FROM stdin;
    public          taiga    false    322   �(      M          0    9778657    projects_taskduedate 
   TABLE DATA           m   COPY public.projects_taskduedate (id, name, "order", by_default, color, days_to_due, project_id) FROM stdin;
    public          taiga    false    316   �(      �          0    9776920    projects_taskstatus 
   TABLE DATA           d   COPY public.projects_taskstatus (id, name, "order", is_closed, color, project_id, slug) FROM stdin;
    public          taiga    false    229   �)      O          0    9778665    projects_userstoryduedate 
   TABLE DATA           r   COPY public.projects_userstoryduedate (id, name, "order", by_default, color, days_to_due, project_id) FROM stdin;
    public          taiga    false    318   �+      �          0    9776928    projects_userstorystatus 
   TABLE DATA           �   COPY public.projects_userstorystatus (id, name, "order", is_closed, color, wip_limit, project_id, slug, is_archived) FROM stdin;
    public          taiga    false    231   �,      U          0    9778759    references_reference 
   TABLE DATA           k   COPY public.references_reference (id, object_id, ref, created_at, content_type_id, project_id) FROM stdin;
    public          taiga    false    324   /      X          0    9778792    settings_userprojectsettings 
   TABLE DATA           r   COPY public.settings_userprojectsettings (id, homepage, created_at, modified_at, project_id, user_id) FROM stdin;
    public          taiga    false    327   7/                0    9777562 
   tasks_task 
   TABLE DATA           <  COPY public.tasks_task (id, tags, version, is_blocked, blocked_note, ref, created_date, modified_date, finished_date, subject, description, is_iocaine, assigned_to_id, milestone_id, owner_id, project_id, status_id, user_story_id, taskboard_order, us_order, external_reference, due_date, due_date_reason) FROM stdin;
    public          taiga    false    259   T/      Z          0    9778848    telemetry_instancetelemetry 
   TABLE DATA           R   COPY public.telemetry_instancetelemetry (id, instance_id, created_at) FROM stdin;
    public          taiga    false    329   q/                0    9777742    timeline_timeline 
   TABLE DATA           �   COPY public.timeline_timeline (id, object_id, namespace, event_type, project_id, data, data_content_type_id, created, content_type_id) FROM stdin;
    public          taiga    false    265   �/      ^          0    9778889    token_denylist_denylistedtoken 
   TABLE DATA           U   COPY public.token_denylist_denylistedtoken (id, denylisted_at, token_id) FROM stdin;
    public          taiga    false    333   �8      \          0    9778876    token_denylist_outstandingtoken 
   TABLE DATA           j   COPY public.token_denylist_outstandingtoken (id, jti, token, created_at, expires_at, user_id) FROM stdin;
    public          taiga    false    331   �8                0    9777644    users_authdata 
   TABLE DATA           H   COPY public.users_authdata (id, key, value, extra, user_id) FROM stdin;
    public          taiga    false    261   �8      �          0    9776801 
   users_role 
   TABLE DATA           l   COPY public.users_role (id, name, slug, permissions, "order", computable, project_id, is_admin) FROM stdin;
    public          taiga    false    211   �8      �          0    9776763 
   users_user 
   TABLE DATA           �  COPY public.users_user (id, password, last_login, is_superuser, username, email, is_active, full_name, color, bio, photo, date_joined, lang, timezone, colorize_tags, token, email_token, new_email, is_system, theme, max_private_projects, max_public_projects, max_memberships_private_projects, max_memberships_public_projects, uuid, accepted_terms, read_new_terms, verified_email, is_staff, date_cancelled) FROM stdin;
    public          taiga    false    207   g:      `          0    9778933    users_workspacerole 
   TABLE DATA           k   COPY public.users_workspacerole (id, name, slug, permissions, "order", is_admin, workspace_id) FROM stdin;
    public          taiga    false    335   zA      b          0    9778954    userstorage_storageentry 
   TABLE DATA           i   COPY public.userstorage_storageentry (id, created_date, modified_date, key, value, owner_id) FROM stdin;
    public          taiga    false    337   B                0    9777288    userstories_rolepoints 
   TABLE DATA           W   COPY public.userstories_rolepoints (id, points_id, role_id, user_story_id) FROM stdin;
    public          taiga    false    245   B                0    9777296    userstories_userstory 
   TABLE DATA           �  COPY public.userstories_userstory (id, tags, version, is_blocked, blocked_note, ref, is_closed, backlog_order, created_date, modified_date, finish_date, subject, description, client_requirement, team_requirement, assigned_to_id, generated_from_issue_id, milestone_id, owner_id, project_id, status_id, sprint_order, kanban_order, external_reference, tribe_gig, due_date, due_date_reason, generated_from_task_id, from_task_ref, swimlane_id) FROM stdin;
    public          taiga    false    247   ;B      d          0    9779025 $   userstories_userstory_assigned_users 
   TABLE DATA           Y   COPY public.userstories_userstory_assigned_users (id, userstory_id, user_id) FROM stdin;
    public          taiga    false    339   XB      f          0    9779064 
   votes_vote 
   TABLE DATA           [   COPY public.votes_vote (id, object_id, content_type_id, user_id, created_date) FROM stdin;
    public          taiga    false    341   uB      h          0    9779073    votes_votes 
   TABLE DATA           L   COPY public.votes_votes (id, object_id, count, content_type_id) FROM stdin;
    public          taiga    false    343   �B      j          0    9779111    webhooks_webhook 
   TABLE DATA           J   COPY public.webhooks_webhook (id, url, key, project_id, name) FROM stdin;
    public          taiga    false    345   �B      l          0    9779122    webhooks_webhooklog 
   TABLE DATA           �   COPY public.webhooks_webhooklog (id, url, status, request_data, response_data, webhook_id, created, duration, request_headers, response_headers) FROM stdin;
    public          taiga    false    347   �B      "          0    9778001    wiki_wikilink 
   TABLE DATA           M   COPY public.wiki_wikilink (id, title, href, "order", project_id) FROM stdin;
    public          taiga    false    273   �B      $          0    9778013    wiki_wikipage 
   TABLE DATA           �   COPY public.wiki_wikipage (id, version, slug, content, created_date, modified_date, last_modifier_id, owner_id, project_id) FROM stdin;
    public          taiga    false    275   C      I          0    9778626    workspaces_workspace 
   TABLE DATA           �   COPY public.workspaces_workspace (id, name, slug, color, created_date, modified_date, owner_id, anon_permissions, public_permissions) FROM stdin;
    public          taiga    false    312   #C      n          0    9779174    workspaces_workspacemembership 
   TABLE DATA           f   COPY public.workspaces_workspacemembership (id, user_id, workspace_id, workspace_role_id) FROM stdin;
    public          taiga    false    349   qE      �           0    0    attachments_attachment_id_seq    SEQUENCE SET     L   SELECT pg_catalog.setval('public.attachments_attachment_id_seq', 1, false);
          public          taiga    false    232            �           0    0    auth_group_id_seq    SEQUENCE SET     @   SELECT pg_catalog.setval('public.auth_group_id_seq', 1, false);
          public          taiga    false    236            �           0    0    auth_group_permissions_id_seq    SEQUENCE SET     L   SELECT pg_catalog.setval('public.auth_group_permissions_id_seq', 1, false);
          public          taiga    false    238            �           0    0    auth_permission_id_seq    SEQUENCE SET     F   SELECT pg_catalog.setval('public.auth_permission_id_seq', 284, true);
          public          taiga    false    234            �           0    0    contact_contactentry_id_seq    SEQUENCE SET     J   SELECT pg_catalog.setval('public.contact_contactentry_id_seq', 1, false);
          public          taiga    false    270            �           0    0 ,   custom_attributes_epiccustomattribute_id_seq    SEQUENCE SET     [   SELECT pg_catalog.setval('public.custom_attributes_epiccustomattribute_id_seq', 1, false);
          public          taiga    false    293            �           0    0 3   custom_attributes_epiccustomattributesvalues_id_seq    SEQUENCE SET     b   SELECT pg_catalog.setval('public.custom_attributes_epiccustomattributesvalues_id_seq', 1, false);
          public          taiga    false    295            �           0    0 -   custom_attributes_issuecustomattribute_id_seq    SEQUENCE SET     \   SELECT pg_catalog.setval('public.custom_attributes_issuecustomattribute_id_seq', 1, false);
          public          taiga    false    281            �           0    0 4   custom_attributes_issuecustomattributesvalues_id_seq    SEQUENCE SET     c   SELECT pg_catalog.setval('public.custom_attributes_issuecustomattributesvalues_id_seq', 1, false);
          public          taiga    false    287            �           0    0 ,   custom_attributes_taskcustomattribute_id_seq    SEQUENCE SET     [   SELECT pg_catalog.setval('public.custom_attributes_taskcustomattribute_id_seq', 1, false);
          public          taiga    false    283            �           0    0 3   custom_attributes_taskcustomattributesvalues_id_seq    SEQUENCE SET     b   SELECT pg_catalog.setval('public.custom_attributes_taskcustomattributesvalues_id_seq', 1, false);
          public          taiga    false    289            �           0    0 1   custom_attributes_userstorycustomattribute_id_seq    SEQUENCE SET     `   SELECT pg_catalog.setval('public.custom_attributes_userstorycustomattribute_id_seq', 1, false);
          public          taiga    false    285            �           0    0 8   custom_attributes_userstorycustomattributesvalues_id_seq    SEQUENCE SET     g   SELECT pg_catalog.setval('public.custom_attributes_userstorycustomattributesvalues_id_seq', 1, false);
          public          taiga    false    291            �           0    0    django_admin_log_id_seq    SEQUENCE SET     F   SELECT pg_catalog.setval('public.django_admin_log_id_seq', 1, false);
          public          taiga    false    208            �           0    0    django_content_type_id_seq    SEQUENCE SET     I   SELECT pg_catalog.setval('public.django_content_type_id_seq', 71, true);
          public          taiga    false    204            �           0    0    django_migrations_id_seq    SEQUENCE SET     H   SELECT pg_catalog.setval('public.django_migrations_id_seq', 277, true);
          public          taiga    false    202            �           0    0    easy_thumbnails_source_id_seq    SEQUENCE SET     L   SELECT pg_catalog.setval('public.easy_thumbnails_source_id_seq', 1, false);
          public          taiga    false    298            �           0    0     easy_thumbnails_thumbnail_id_seq    SEQUENCE SET     O   SELECT pg_catalog.setval('public.easy_thumbnails_thumbnail_id_seq', 1, false);
          public          taiga    false    300            �           0    0 *   easy_thumbnails_thumbnaildimensions_id_seq    SEQUENCE SET     Y   SELECT pg_catalog.setval('public.easy_thumbnails_thumbnaildimensions_id_seq', 1, false);
          public          taiga    false    302            �           0    0    epics_epic_id_seq    SEQUENCE SET     @   SELECT pg_catalog.setval('public.epics_epic_id_seq', 1, false);
          public          taiga    false    277            �           0    0    epics_relateduserstory_id_seq    SEQUENCE SET     L   SELECT pg_catalog.setval('public.epics_relateduserstory_id_seq', 1, false);
          public          taiga    false    279            �           0    0 %   external_apps_applicationtoken_id_seq    SEQUENCE SET     T   SELECT pg_catalog.setval('public.external_apps_applicationtoken_id_seq', 1, false);
          public          taiga    false    305            �           0    0    feedback_feedbackentry_id_seq    SEQUENCE SET     L   SELECT pg_catalog.setval('public.feedback_feedbackentry_id_seq', 1, false);
          public          taiga    false    307            �           0    0    issues_issue_id_seq    SEQUENCE SET     B   SELECT pg_catalog.setval('public.issues_issue_id_seq', 1, false);
          public          taiga    false    242            �           0    0    likes_like_id_seq    SEQUENCE SET     @   SELECT pg_catalog.setval('public.likes_like_id_seq', 1, false);
          public          taiga    false    266            �           0    0    milestones_milestone_id_seq    SEQUENCE SET     J   SELECT pg_catalog.setval('public.milestones_milestone_id_seq', 1, false);
          public          taiga    false    240            �           0    0 >   notifications_historychangenotification_history_entries_id_seq    SEQUENCE SET     m   SELECT pg_catalog.setval('public.notifications_historychangenotification_history_entries_id_seq', 1, false);
          public          taiga    false    252            �           0    0 .   notifications_historychangenotification_id_seq    SEQUENCE SET     ]   SELECT pg_catalog.setval('public.notifications_historychangenotification_id_seq', 1, false);
          public          taiga    false    250            �           0    0 ;   notifications_historychangenotification_notify_users_id_seq    SEQUENCE SET     j   SELECT pg_catalog.setval('public.notifications_historychangenotification_notify_users_id_seq', 1, false);
          public          taiga    false    254            �           0    0 !   notifications_notifypolicy_id_seq    SEQUENCE SET     P   SELECT pg_catalog.setval('public.notifications_notifypolicy_id_seq', 60, true);
          public          taiga    false    248            �           0    0    notifications_watched_id_seq    SEQUENCE SET     K   SELECT pg_catalog.setval('public.notifications_watched_id_seq', 1, false);
          public          taiga    false    256            �           0    0 $   notifications_webnotification_id_seq    SEQUENCE SET     S   SELECT pg_catalog.setval('public.notifications_webnotification_id_seq', 1, false);
          public          taiga    false    309            �           0    0    projects_epicstatus_id_seq    SEQUENCE SET     I   SELECT pg_catalog.setval('public.projects_epicstatus_id_seq', 70, true);
          public          taiga    false    268            �           0    0    projects_issueduedate_id_seq    SEQUENCE SET     K   SELECT pg_catalog.setval('public.projects_issueduedate_id_seq', 42, true);
          public          taiga    false    313            �           0    0    projects_issuestatus_id_seq    SEQUENCE SET     J   SELECT pg_catalog.setval('public.projects_issuestatus_id_seq', 98, true);
          public          taiga    false    216            �           0    0    projects_issuetype_id_seq    SEQUENCE SET     H   SELECT pg_catalog.setval('public.projects_issuetype_id_seq', 42, true);
          public          taiga    false    218            �           0    0    projects_membership_id_seq    SEQUENCE SET     I   SELECT pg_catalog.setval('public.projects_membership_id_seq', 60, true);
          public          taiga    false    212            �           0    0    projects_points_id_seq    SEQUENCE SET     F   SELECT pg_catalog.setval('public.projects_points_id_seq', 168, true);
          public          taiga    false    220            �           0    0    projects_priority_id_seq    SEQUENCE SET     G   SELECT pg_catalog.setval('public.projects_priority_id_seq', 42, true);
          public          taiga    false    222            �           0    0    projects_project_id_seq    SEQUENCE SET     F   SELECT pg_catalog.setval('public.projects_project_id_seq', 14, true);
          public          taiga    false    214            �           0    0 $   projects_projectmodulesconfig_id_seq    SEQUENCE SET     S   SELECT pg_catalog.setval('public.projects_projectmodulesconfig_id_seq', 1, false);
          public          taiga    false    262            �           0    0    projects_projecttemplate_id_seq    SEQUENCE SET     M   SELECT pg_catalog.setval('public.projects_projecttemplate_id_seq', 2, true);
          public          taiga    false    224            �           0    0    projects_severity_id_seq    SEQUENCE SET     G   SELECT pg_catalog.setval('public.projects_severity_id_seq', 70, true);
          public          taiga    false    226            �           0    0    projects_swimlane_id_seq    SEQUENCE SET     G   SELECT pg_catalog.setval('public.projects_swimlane_id_seq', 1, false);
          public          taiga    false    319            �           0    0 '   projects_swimlaneuserstorystatus_id_seq    SEQUENCE SET     V   SELECT pg_catalog.setval('public.projects_swimlaneuserstorystatus_id_seq', 1, false);
          public          taiga    false    321            �           0    0    projects_taskduedate_id_seq    SEQUENCE SET     J   SELECT pg_catalog.setval('public.projects_taskduedate_id_seq', 42, true);
          public          taiga    false    315            �           0    0    projects_taskstatus_id_seq    SEQUENCE SET     I   SELECT pg_catalog.setval('public.projects_taskstatus_id_seq', 70, true);
          public          taiga    false    228            �           0    0     projects_userstoryduedate_id_seq    SEQUENCE SET     O   SELECT pg_catalog.setval('public.projects_userstoryduedate_id_seq', 42, true);
          public          taiga    false    317            �           0    0    projects_userstorystatus_id_seq    SEQUENCE SET     N   SELECT pg_catalog.setval('public.projects_userstorystatus_id_seq', 84, true);
          public          taiga    false    230            �           0    0    references_project1    SEQUENCE SET     B   SELECT pg_catalog.setval('public.references_project1', 1, false);
          public          taiga    false    350            �           0    0    references_project10    SEQUENCE SET     C   SELECT pg_catalog.setval('public.references_project10', 1, false);
          public          taiga    false    359            �           0    0    references_project11    SEQUENCE SET     C   SELECT pg_catalog.setval('public.references_project11', 1, false);
          public          taiga    false    360            �           0    0    references_project12    SEQUENCE SET     C   SELECT pg_catalog.setval('public.references_project12', 1, false);
          public          taiga    false    361                        0    0    references_project13    SEQUENCE SET     C   SELECT pg_catalog.setval('public.references_project13', 1, false);
          public          taiga    false    362                       0    0    references_project14    SEQUENCE SET     C   SELECT pg_catalog.setval('public.references_project14', 1, false);
          public          taiga    false    363                       0    0    references_project2    SEQUENCE SET     B   SELECT pg_catalog.setval('public.references_project2', 1, false);
          public          taiga    false    351                       0    0    references_project3    SEQUENCE SET     B   SELECT pg_catalog.setval('public.references_project3', 1, false);
          public          taiga    false    352                       0    0    references_project4    SEQUENCE SET     B   SELECT pg_catalog.setval('public.references_project4', 1, false);
          public          taiga    false    353                       0    0    references_project5    SEQUENCE SET     B   SELECT pg_catalog.setval('public.references_project5', 1, false);
          public          taiga    false    354                       0    0    references_project6    SEQUENCE SET     B   SELECT pg_catalog.setval('public.references_project6', 1, false);
          public          taiga    false    355                       0    0    references_project7    SEQUENCE SET     B   SELECT pg_catalog.setval('public.references_project7', 1, false);
          public          taiga    false    356                       0    0    references_project8    SEQUENCE SET     B   SELECT pg_catalog.setval('public.references_project8', 1, false);
          public          taiga    false    357            	           0    0    references_project9    SEQUENCE SET     B   SELECT pg_catalog.setval('public.references_project9', 1, false);
          public          taiga    false    358            
           0    0    references_reference_id_seq    SEQUENCE SET     J   SELECT pg_catalog.setval('public.references_reference_id_seq', 1, false);
          public          taiga    false    323                       0    0 #   settings_userprojectsettings_id_seq    SEQUENCE SET     R   SELECT pg_catalog.setval('public.settings_userprojectsettings_id_seq', 1, false);
          public          taiga    false    326                       0    0    tasks_task_id_seq    SEQUENCE SET     @   SELECT pg_catalog.setval('public.tasks_task_id_seq', 1, false);
          public          taiga    false    258                       0    0 "   telemetry_instancetelemetry_id_seq    SEQUENCE SET     Q   SELECT pg_catalog.setval('public.telemetry_instancetelemetry_id_seq', 1, false);
          public          taiga    false    328                       0    0    timeline_timeline_id_seq    SEQUENCE SET     H   SELECT pg_catalog.setval('public.timeline_timeline_id_seq', 103, true);
          public          taiga    false    264                       0    0 %   token_denylist_denylistedtoken_id_seq    SEQUENCE SET     T   SELECT pg_catalog.setval('public.token_denylist_denylistedtoken_id_seq', 1, false);
          public          taiga    false    332                       0    0 &   token_denylist_outstandingtoken_id_seq    SEQUENCE SET     U   SELECT pg_catalog.setval('public.token_denylist_outstandingtoken_id_seq', 1, false);
          public          taiga    false    330                       0    0    users_authdata_id_seq    SEQUENCE SET     D   SELECT pg_catalog.setval('public.users_authdata_id_seq', 1, false);
          public          taiga    false    260                       0    0    users_role_id_seq    SEQUENCE SET     @   SELECT pg_catalog.setval('public.users_role_id_seq', 31, true);
          public          taiga    false    210                       0    0    users_user_id_seq    SEQUENCE SET     @   SELECT pg_catalog.setval('public.users_user_id_seq', 15, true);
          public          taiga    false    206                       0    0    users_workspacerole_id_seq    SEQUENCE SET     I   SELECT pg_catalog.setval('public.users_workspacerole_id_seq', 11, true);
          public          taiga    false    334                       0    0    userstorage_storageentry_id_seq    SEQUENCE SET     N   SELECT pg_catalog.setval('public.userstorage_storageentry_id_seq', 1, false);
          public          taiga    false    336                       0    0    userstories_rolepoints_id_seq    SEQUENCE SET     L   SELECT pg_catalog.setval('public.userstories_rolepoints_id_seq', 1, false);
          public          taiga    false    244                       0    0 +   userstories_userstory_assigned_users_id_seq    SEQUENCE SET     Z   SELECT pg_catalog.setval('public.userstories_userstory_assigned_users_id_seq', 1, false);
          public          taiga    false    338                       0    0    userstories_userstory_id_seq    SEQUENCE SET     K   SELECT pg_catalog.setval('public.userstories_userstory_id_seq', 1, false);
          public          taiga    false    246                       0    0    votes_vote_id_seq    SEQUENCE SET     @   SELECT pg_catalog.setval('public.votes_vote_id_seq', 1, false);
          public          taiga    false    340                       0    0    votes_votes_id_seq    SEQUENCE SET     A   SELECT pg_catalog.setval('public.votes_votes_id_seq', 1, false);
          public          taiga    false    342                       0    0    webhooks_webhook_id_seq    SEQUENCE SET     F   SELECT pg_catalog.setval('public.webhooks_webhook_id_seq', 1, false);
          public          taiga    false    344                       0    0    webhooks_webhooklog_id_seq    SEQUENCE SET     I   SELECT pg_catalog.setval('public.webhooks_webhooklog_id_seq', 1, false);
          public          taiga    false    346                       0    0    wiki_wikilink_id_seq    SEQUENCE SET     C   SELECT pg_catalog.setval('public.wiki_wikilink_id_seq', 1, false);
          public          taiga    false    272                       0    0    wiki_wikipage_id_seq    SEQUENCE SET     C   SELECT pg_catalog.setval('public.wiki_wikipage_id_seq', 1, false);
          public          taiga    false    274                       0    0    workspaces_workspace_id_seq    SEQUENCE SET     J   SELECT pg_catalog.setval('public.workspaces_workspace_id_seq', 11, true);
          public          taiga    false    311                        0    0 %   workspaces_workspacemembership_id_seq    SEQUENCE SET     T   SELECT pg_catalog.setval('public.workspaces_workspacemembership_id_seq', 11, true);
          public          taiga    false    348            h           2606    9777057 2   attachments_attachment attachments_attachment_pkey 
   CONSTRAINT     p   ALTER TABLE ONLY public.attachments_attachment
    ADD CONSTRAINT attachments_attachment_pkey PRIMARY KEY (id);
 \   ALTER TABLE ONLY public.attachments_attachment DROP CONSTRAINT attachments_attachment_pkey;
       public            taiga    false    233            q           2606    9777135    auth_group auth_group_name_key 
   CONSTRAINT     Y   ALTER TABLE ONLY public.auth_group
    ADD CONSTRAINT auth_group_name_key UNIQUE (name);
 H   ALTER TABLE ONLY public.auth_group DROP CONSTRAINT auth_group_name_key;
       public            taiga    false    237            v           2606    9777131 R   auth_group_permissions auth_group_permissions_group_id_permission_id_0cd325b0_uniq 
   CONSTRAINT     �   ALTER TABLE ONLY public.auth_group_permissions
    ADD CONSTRAINT auth_group_permissions_group_id_permission_id_0cd325b0_uniq UNIQUE (group_id, permission_id);
 |   ALTER TABLE ONLY public.auth_group_permissions DROP CONSTRAINT auth_group_permissions_group_id_permission_id_0cd325b0_uniq;
       public            taiga    false    239    239            y           2606    9777110 2   auth_group_permissions auth_group_permissions_pkey 
   CONSTRAINT     p   ALTER TABLE ONLY public.auth_group_permissions
    ADD CONSTRAINT auth_group_permissions_pkey PRIMARY KEY (id);
 \   ALTER TABLE ONLY public.auth_group_permissions DROP CONSTRAINT auth_group_permissions_pkey;
       public            taiga    false    239            s           2606    9777100    auth_group auth_group_pkey 
   CONSTRAINT     X   ALTER TABLE ONLY public.auth_group
    ADD CONSTRAINT auth_group_pkey PRIMARY KEY (id);
 D   ALTER TABLE ONLY public.auth_group DROP CONSTRAINT auth_group_pkey;
       public            taiga    false    237            l           2606    9777117 F   auth_permission auth_permission_content_type_id_codename_01ab375a_uniq 
   CONSTRAINT     �   ALTER TABLE ONLY public.auth_permission
    ADD CONSTRAINT auth_permission_content_type_id_codename_01ab375a_uniq UNIQUE (content_type_id, codename);
 p   ALTER TABLE ONLY public.auth_permission DROP CONSTRAINT auth_permission_content_type_id_codename_01ab375a_uniq;
       public            taiga    false    235    235            n           2606    9777092 $   auth_permission auth_permission_pkey 
   CONSTRAINT     b   ALTER TABLE ONLY public.auth_permission
    ADD CONSTRAINT auth_permission_pkey PRIMARY KEY (id);
 N   ALTER TABLE ONLY public.auth_permission DROP CONSTRAINT auth_permission_pkey;
       public            taiga    false    235            �           2606    9777986 .   contact_contactentry contact_contactentry_pkey 
   CONSTRAINT     l   ALTER TABLE ONLY public.contact_contactentry
    ADD CONSTRAINT contact_contactentry_pkey PRIMARY KEY (id);
 X   ALTER TABLE ONLY public.contact_contactentry DROP CONSTRAINT contact_contactentry_pkey;
       public            taiga    false    271            8           2606    9778338 \   custom_attributes_epiccustomattribute custom_attributes_epiccu_project_id_name_3850c31d_uniq 
   CONSTRAINT     �   ALTER TABLE ONLY public.custom_attributes_epiccustomattribute
    ADD CONSTRAINT custom_attributes_epiccu_project_id_name_3850c31d_uniq UNIQUE (project_id, name);
 �   ALTER TABLE ONLY public.custom_attributes_epiccustomattribute DROP CONSTRAINT custom_attributes_epiccu_project_id_name_3850c31d_uniq;
       public            taiga    false    294    294            :           2606    9778322 P   custom_attributes_epiccustomattribute custom_attributes_epiccustomattribute_pkey 
   CONSTRAINT     �   ALTER TABLE ONLY public.custom_attributes_epiccustomattribute
    ADD CONSTRAINT custom_attributes_epiccustomattribute_pkey PRIMARY KEY (id);
 z   ALTER TABLE ONLY public.custom_attributes_epiccustomattribute DROP CONSTRAINT custom_attributes_epiccustomattribute_pkey;
       public            taiga    false    294            >           2606    9778335 e   custom_attributes_epiccustomattributesvalues custom_attributes_epiccustomattributesvalues_epic_id_key 
   CONSTRAINT     �   ALTER TABLE ONLY public.custom_attributes_epiccustomattributesvalues
    ADD CONSTRAINT custom_attributes_epiccustomattributesvalues_epic_id_key UNIQUE (epic_id);
 �   ALTER TABLE ONLY public.custom_attributes_epiccustomattributesvalues DROP CONSTRAINT custom_attributes_epiccustomattributesvalues_epic_id_key;
       public            taiga    false    296            @           2606    9778333 ^   custom_attributes_epiccustomattributesvalues custom_attributes_epiccustomattributesvalues_pkey 
   CONSTRAINT     �   ALTER TABLE ONLY public.custom_attributes_epiccustomattributesvalues
    ADD CONSTRAINT custom_attributes_epiccustomattributesvalues_pkey PRIMARY KEY (id);
 �   ALTER TABLE ONLY public.custom_attributes_epiccustomattributesvalues DROP CONSTRAINT custom_attributes_epiccustomattributesvalues_pkey;
       public            taiga    false    296                       2606    9778225 ]   custom_attributes_issuecustomattribute custom_attributes_issuec_project_id_name_6f71f010_uniq 
   CONSTRAINT     �   ALTER TABLE ONLY public.custom_attributes_issuecustomattribute
    ADD CONSTRAINT custom_attributes_issuec_project_id_name_6f71f010_uniq UNIQUE (project_id, name);
 �   ALTER TABLE ONLY public.custom_attributes_issuecustomattribute DROP CONSTRAINT custom_attributes_issuec_project_id_name_6f71f010_uniq;
       public            taiga    false    282    282                       2606    9778197 R   custom_attributes_issuecustomattribute custom_attributes_issuecustomattribute_pkey 
   CONSTRAINT     �   ALTER TABLE ONLY public.custom_attributes_issuecustomattribute
    ADD CONSTRAINT custom_attributes_issuecustomattribute_pkey PRIMARY KEY (id);
 |   ALTER TABLE ONLY public.custom_attributes_issuecustomattribute DROP CONSTRAINT custom_attributes_issuecustomattribute_pkey;
       public            taiga    false    282            *           2606    9778256 h   custom_attributes_issuecustomattributesvalues custom_attributes_issuecustomattributesvalues_issue_id_key 
   CONSTRAINT     �   ALTER TABLE ONLY public.custom_attributes_issuecustomattributesvalues
    ADD CONSTRAINT custom_attributes_issuecustomattributesvalues_issue_id_key UNIQUE (issue_id);
 �   ALTER TABLE ONLY public.custom_attributes_issuecustomattributesvalues DROP CONSTRAINT custom_attributes_issuecustomattributesvalues_issue_id_key;
       public            taiga    false    288            ,           2606    9778254 `   custom_attributes_issuecustomattributesvalues custom_attributes_issuecustomattributesvalues_pkey 
   CONSTRAINT     �   ALTER TABLE ONLY public.custom_attributes_issuecustomattributesvalues
    ADD CONSTRAINT custom_attributes_issuecustomattributesvalues_pkey PRIMARY KEY (id);
 �   ALTER TABLE ONLY public.custom_attributes_issuecustomattributesvalues DROP CONSTRAINT custom_attributes_issuecustomattributesvalues_pkey;
       public            taiga    false    288                       2606    9778223 \   custom_attributes_taskcustomattribute custom_attributes_taskcu_project_id_name_c1c55ac2_uniq 
   CONSTRAINT     �   ALTER TABLE ONLY public.custom_attributes_taskcustomattribute
    ADD CONSTRAINT custom_attributes_taskcu_project_id_name_c1c55ac2_uniq UNIQUE (project_id, name);
 �   ALTER TABLE ONLY public.custom_attributes_taskcustomattribute DROP CONSTRAINT custom_attributes_taskcu_project_id_name_c1c55ac2_uniq;
       public            taiga    false    284    284            !           2606    9778208 P   custom_attributes_taskcustomattribute custom_attributes_taskcustomattribute_pkey 
   CONSTRAINT     �   ALTER TABLE ONLY public.custom_attributes_taskcustomattribute
    ADD CONSTRAINT custom_attributes_taskcustomattribute_pkey PRIMARY KEY (id);
 z   ALTER TABLE ONLY public.custom_attributes_taskcustomattribute DROP CONSTRAINT custom_attributes_taskcustomattribute_pkey;
       public            taiga    false    284            /           2606    9778267 ^   custom_attributes_taskcustomattributesvalues custom_attributes_taskcustomattributesvalues_pkey 
   CONSTRAINT     �   ALTER TABLE ONLY public.custom_attributes_taskcustomattributesvalues
    ADD CONSTRAINT custom_attributes_taskcustomattributesvalues_pkey PRIMARY KEY (id);
 �   ALTER TABLE ONLY public.custom_attributes_taskcustomattributesvalues DROP CONSTRAINT custom_attributes_taskcustomattributesvalues_pkey;
       public            taiga    false    290            1           2606    9778269 e   custom_attributes_taskcustomattributesvalues custom_attributes_taskcustomattributesvalues_task_id_key 
   CONSTRAINT     �   ALTER TABLE ONLY public.custom_attributes_taskcustomattributesvalues
    ADD CONSTRAINT custom_attributes_taskcustomattributesvalues_task_id_key UNIQUE (task_id);
 �   ALTER TABLE ONLY public.custom_attributes_taskcustomattributesvalues DROP CONSTRAINT custom_attributes_taskcustomattributesvalues_task_id_key;
       public            taiga    false    290            $           2606    9778221 a   custom_attributes_userstorycustomattribute custom_attributes_userst_project_id_name_86c6b502_uniq 
   CONSTRAINT     �   ALTER TABLE ONLY public.custom_attributes_userstorycustomattribute
    ADD CONSTRAINT custom_attributes_userst_project_id_name_86c6b502_uniq UNIQUE (project_id, name);
 �   ALTER TABLE ONLY public.custom_attributes_userstorycustomattribute DROP CONSTRAINT custom_attributes_userst_project_id_name_86c6b502_uniq;
       public            taiga    false    286    286            &           2606    9778219 Z   custom_attributes_userstorycustomattribute custom_attributes_userstorycustomattribute_pkey 
   CONSTRAINT     �   ALTER TABLE ONLY public.custom_attributes_userstorycustomattribute
    ADD CONSTRAINT custom_attributes_userstorycustomattribute_pkey PRIMARY KEY (id);
 �   ALTER TABLE ONLY public.custom_attributes_userstorycustomattribute DROP CONSTRAINT custom_attributes_userstorycustomattribute_pkey;
       public            taiga    false    286            4           2606    9778282 q   custom_attributes_userstorycustomattributesvalues custom_attributes_userstorycustomattributesva_user_story_id_key 
   CONSTRAINT     �   ALTER TABLE ONLY public.custom_attributes_userstorycustomattributesvalues
    ADD CONSTRAINT custom_attributes_userstorycustomattributesva_user_story_id_key UNIQUE (user_story_id);
 �   ALTER TABLE ONLY public.custom_attributes_userstorycustomattributesvalues DROP CONSTRAINT custom_attributes_userstorycustomattributesva_user_story_id_key;
       public            taiga    false    292            6           2606    9778280 h   custom_attributes_userstorycustomattributesvalues custom_attributes_userstorycustomattributesvalues_pkey 
   CONSTRAINT     �   ALTER TABLE ONLY public.custom_attributes_userstorycustomattributesvalues
    ADD CONSTRAINT custom_attributes_userstorycustomattributesvalues_pkey PRIMARY KEY (id);
 �   ALTER TABLE ONLY public.custom_attributes_userstorycustomattributesvalues DROP CONSTRAINT custom_attributes_userstorycustomattributesvalues_pkey;
       public            taiga    false    292            �           2606    9776786 &   django_admin_log django_admin_log_pkey 
   CONSTRAINT     d   ALTER TABLE ONLY public.django_admin_log
    ADD CONSTRAINT django_admin_log_pkey PRIMARY KEY (id);
 P   ALTER TABLE ONLY public.django_admin_log DROP CONSTRAINT django_admin_log_pkey;
       public            taiga    false    209            �           2606    9776760 E   django_content_type django_content_type_app_label_model_76bd3d3b_uniq 
   CONSTRAINT     �   ALTER TABLE ONLY public.django_content_type
    ADD CONSTRAINT django_content_type_app_label_model_76bd3d3b_uniq UNIQUE (app_label, model);
 o   ALTER TABLE ONLY public.django_content_type DROP CONSTRAINT django_content_type_app_label_model_76bd3d3b_uniq;
       public            taiga    false    205    205            �           2606    9776758 ,   django_content_type django_content_type_pkey 
   CONSTRAINT     j   ALTER TABLE ONLY public.django_content_type
    ADD CONSTRAINT django_content_type_pkey PRIMARY KEY (id);
 V   ALTER TABLE ONLY public.django_content_type DROP CONSTRAINT django_content_type_pkey;
       public            taiga    false    205            �           2606    9776750 (   django_migrations django_migrations_pkey 
   CONSTRAINT     f   ALTER TABLE ONLY public.django_migrations
    ADD CONSTRAINT django_migrations_pkey PRIMARY KEY (id);
 R   ALTER TABLE ONLY public.django_migrations DROP CONSTRAINT django_migrations_pkey;
       public            taiga    false    203            �           2606    9778787 "   django_session django_session_pkey 
   CONSTRAINT     i   ALTER TABLE ONLY public.django_session
    ADD CONSTRAINT django_session_pkey PRIMARY KEY (session_key);
 L   ALTER TABLE ONLY public.django_session DROP CONSTRAINT django_session_pkey;
       public            taiga    false    325            B           2606    9778431 "   djmail_message djmail_message_pkey 
   CONSTRAINT     b   ALTER TABLE ONLY public.djmail_message
    ADD CONSTRAINT djmail_message_pkey PRIMARY KEY (uuid);
 L   ALTER TABLE ONLY public.djmail_message DROP CONSTRAINT djmail_message_pkey;
       public            taiga    false    297            G           2606    9778440 2   easy_thumbnails_source easy_thumbnails_source_pkey 
   CONSTRAINT     p   ALTER TABLE ONLY public.easy_thumbnails_source
    ADD CONSTRAINT easy_thumbnails_source_pkey PRIMARY KEY (id);
 \   ALTER TABLE ONLY public.easy_thumbnails_source DROP CONSTRAINT easy_thumbnails_source_pkey;
       public            taiga    false    299            K           2606    9778452 M   easy_thumbnails_source easy_thumbnails_source_storage_hash_name_481ce32d_uniq 
   CONSTRAINT     �   ALTER TABLE ONLY public.easy_thumbnails_source
    ADD CONSTRAINT easy_thumbnails_source_storage_hash_name_481ce32d_uniq UNIQUE (storage_hash, name);
 w   ALTER TABLE ONLY public.easy_thumbnails_source DROP CONSTRAINT easy_thumbnails_source_storage_hash_name_481ce32d_uniq;
       public            taiga    false    299    299            M           2606    9778450 Y   easy_thumbnails_thumbnail easy_thumbnails_thumbnai_storage_hash_name_source_fb375270_uniq 
   CONSTRAINT     �   ALTER TABLE ONLY public.easy_thumbnails_thumbnail
    ADD CONSTRAINT easy_thumbnails_thumbnai_storage_hash_name_source_fb375270_uniq UNIQUE (storage_hash, name, source_id);
 �   ALTER TABLE ONLY public.easy_thumbnails_thumbnail DROP CONSTRAINT easy_thumbnails_thumbnai_storage_hash_name_source_fb375270_uniq;
       public            taiga    false    301    301    301            Q           2606    9778448 8   easy_thumbnails_thumbnail easy_thumbnails_thumbnail_pkey 
   CONSTRAINT     v   ALTER TABLE ONLY public.easy_thumbnails_thumbnail
    ADD CONSTRAINT easy_thumbnails_thumbnail_pkey PRIMARY KEY (id);
 b   ALTER TABLE ONLY public.easy_thumbnails_thumbnail DROP CONSTRAINT easy_thumbnails_thumbnail_pkey;
       public            taiga    false    301            V           2606    9778476 L   easy_thumbnails_thumbnaildimensions easy_thumbnails_thumbnaildimensions_pkey 
   CONSTRAINT     �   ALTER TABLE ONLY public.easy_thumbnails_thumbnaildimensions
    ADD CONSTRAINT easy_thumbnails_thumbnaildimensions_pkey PRIMARY KEY (id);
 v   ALTER TABLE ONLY public.easy_thumbnails_thumbnaildimensions DROP CONSTRAINT easy_thumbnails_thumbnaildimensions_pkey;
       public            taiga    false    303            X           2606    9778478 X   easy_thumbnails_thumbnaildimensions easy_thumbnails_thumbnaildimensions_thumbnail_id_key 
   CONSTRAINT     �   ALTER TABLE ONLY public.easy_thumbnails_thumbnaildimensions
    ADD CONSTRAINT easy_thumbnails_thumbnaildimensions_thumbnail_id_key UNIQUE (thumbnail_id);
 �   ALTER TABLE ONLY public.easy_thumbnails_thumbnaildimensions DROP CONSTRAINT easy_thumbnails_thumbnaildimensions_thumbnail_id_key;
       public            taiga    false    303                       2606    9778138    epics_epic epics_epic_pkey 
   CONSTRAINT     X   ALTER TABLE ONLY public.epics_epic
    ADD CONSTRAINT epics_epic_pkey PRIMARY KEY (id);
 D   ALTER TABLE ONLY public.epics_epic DROP CONSTRAINT epics_epic_pkey;
       public            taiga    false    278                       2606    9778146 2   epics_relateduserstory epics_relateduserstory_pkey 
   CONSTRAINT     p   ALTER TABLE ONLY public.epics_relateduserstory
    ADD CONSTRAINT epics_relateduserstory_pkey PRIMARY KEY (id);
 \   ALTER TABLE ONLY public.epics_relateduserstory DROP CONSTRAINT epics_relateduserstory_pkey;
       public            taiga    false    280                       2606    9778485 Q   epics_relateduserstory epics_relateduserstory_user_story_id_epic_id_ad704d40_uniq 
   CONSTRAINT     �   ALTER TABLE ONLY public.epics_relateduserstory
    ADD CONSTRAINT epics_relateduserstory_user_story_id_epic_id_ad704d40_uniq UNIQUE (user_story_id, epic_id);
 {   ALTER TABLE ONLY public.epics_relateduserstory DROP CONSTRAINT epics_relateduserstory_user_story_id_epic_id_ad704d40_uniq;
       public            taiga    false    280    280            ]           2606    9778530 \   external_apps_applicationtoken external_apps_applicatio_application_id_user_id_b6a9e9a8_uniq 
   CONSTRAINT     �   ALTER TABLE ONLY public.external_apps_applicationtoken
    ADD CONSTRAINT external_apps_applicatio_application_id_user_id_b6a9e9a8_uniq UNIQUE (application_id, user_id);
 �   ALTER TABLE ONLY public.external_apps_applicationtoken DROP CONSTRAINT external_apps_applicatio_application_id_user_id_b6a9e9a8_uniq;
       public            taiga    false    306    306            [           2606    9778517 8   external_apps_application external_apps_application_pkey 
   CONSTRAINT     v   ALTER TABLE ONLY public.external_apps_application
    ADD CONSTRAINT external_apps_application_pkey PRIMARY KEY (id);
 b   ALTER TABLE ONLY public.external_apps_application DROP CONSTRAINT external_apps_application_pkey;
       public            taiga    false    304            a           2606    9778528 B   external_apps_applicationtoken external_apps_applicationtoken_pkey 
   CONSTRAINT     �   ALTER TABLE ONLY public.external_apps_applicationtoken
    ADD CONSTRAINT external_apps_applicationtoken_pkey PRIMARY KEY (id);
 l   ALTER TABLE ONLY public.external_apps_applicationtoken DROP CONSTRAINT external_apps_applicationtoken_pkey;
       public            taiga    false    306            d           2606    9778555 2   feedback_feedbackentry feedback_feedbackentry_pkey 
   CONSTRAINT     p   ALTER TABLE ONLY public.feedback_feedbackentry
    ADD CONSTRAINT feedback_feedbackentry_pkey PRIMARY KEY (id);
 \   ALTER TABLE ONLY public.feedback_feedbackentry DROP CONSTRAINT feedback_feedbackentry_pkey;
       public            taiga    false    308            
           2606    9778099 .   history_historyentry history_historyentry_pkey 
   CONSTRAINT     l   ALTER TABLE ONLY public.history_historyentry
    ADD CONSTRAINT history_historyentry_pkey PRIMARY KEY (id);
 X   ALTER TABLE ONLY public.history_historyentry DROP CONSTRAINT history_historyentry_pkey;
       public            taiga    false    276            �           2606    9777214    issues_issue issues_issue_pkey 
   CONSTRAINT     \   ALTER TABLE ONLY public.issues_issue
    ADD CONSTRAINT issues_issue_pkey PRIMARY KEY (id);
 H   ALTER TABLE ONLY public.issues_issue DROP CONSTRAINT issues_issue_pkey;
       public            taiga    false    243            �           2606    9777812 E   likes_like likes_like_content_type_id_object_id_user_id_e20903f0_uniq 
   CONSTRAINT     �   ALTER TABLE ONLY public.likes_like
    ADD CONSTRAINT likes_like_content_type_id_object_id_user_id_e20903f0_uniq UNIQUE (content_type_id, object_id, user_id);
 o   ALTER TABLE ONLY public.likes_like DROP CONSTRAINT likes_like_content_type_id_object_id_user_id_e20903f0_uniq;
       public            taiga    false    267    267    267            �           2606    9777798    likes_like likes_like_pkey 
   CONSTRAINT     X   ALTER TABLE ONLY public.likes_like
    ADD CONSTRAINT likes_like_pkey PRIMARY KEY (id);
 D   ALTER TABLE ONLY public.likes_like DROP CONSTRAINT likes_like_pkey;
       public            taiga    false    267            }           2606    9777173 G   milestones_milestone milestones_milestone_name_project_id_fe19fd36_uniq 
   CONSTRAINT     �   ALTER TABLE ONLY public.milestones_milestone
    ADD CONSTRAINT milestones_milestone_name_project_id_fe19fd36_uniq UNIQUE (name, project_id);
 q   ALTER TABLE ONLY public.milestones_milestone DROP CONSTRAINT milestones_milestone_name_project_id_fe19fd36_uniq;
       public            taiga    false    241    241            �           2606    9777161 .   milestones_milestone milestones_milestone_pkey 
   CONSTRAINT     l   ALTER TABLE ONLY public.milestones_milestone
    ADD CONSTRAINT milestones_milestone_pkey PRIMARY KEY (id);
 X   ALTER TABLE ONLY public.milestones_milestone DROP CONSTRAINT milestones_milestone_pkey;
       public            taiga    false    241            �           2606    9777171 G   milestones_milestone milestones_milestone_slug_project_id_e59bac6a_uniq 
   CONSTRAINT     �   ALTER TABLE ONLY public.milestones_milestone
    ADD CONSTRAINT milestones_milestone_slug_project_id_e59bac6a_uniq UNIQUE (slug, project_id);
 q   ALTER TABLE ONLY public.milestones_milestone DROP CONSTRAINT milestones_milestone_slug_project_id_e59bac6a_uniq;
       public            taiga    false    241    241            �           2606    9777526 t   notifications_historychangenotification_notify_users notifications_historycha_historychangenotificatio_3b0f323b_uniq 
   CONSTRAINT     �   ALTER TABLE ONLY public.notifications_historychangenotification_notify_users
    ADD CONSTRAINT notifications_historycha_historychangenotificatio_3b0f323b_uniq UNIQUE (historychangenotification_id, user_id);
 �   ALTER TABLE ONLY public.notifications_historychangenotification_notify_users DROP CONSTRAINT notifications_historycha_historychangenotificatio_3b0f323b_uniq;
       public            taiga    false    255    255            �           2606    9778110 w   notifications_historychangenotification_history_entries notifications_historycha_historychangenotificatio_8fb55cdd_uniq 
   CONSTRAINT     �   ALTER TABLE ONLY public.notifications_historychangenotification_history_entries
    ADD CONSTRAINT notifications_historycha_historychangenotificatio_8fb55cdd_uniq UNIQUE (historychangenotification_id, historyentry_id);
 �   ALTER TABLE ONLY public.notifications_historychangenotification_history_entries DROP CONSTRAINT notifications_historycha_historychangenotificatio_8fb55cdd_uniq;
       public            taiga    false    253    253            �           2606    9777530 g   notifications_historychangenotification notifications_historycha_key_owner_id_project_id__869f948f_uniq 
   CONSTRAINT     �   ALTER TABLE ONLY public.notifications_historychangenotification
    ADD CONSTRAINT notifications_historycha_key_owner_id_project_id__869f948f_uniq UNIQUE (key, owner_id, project_id, history_type);
 �   ALTER TABLE ONLY public.notifications_historychangenotification DROP CONSTRAINT notifications_historycha_key_owner_id_project_id__869f948f_uniq;
       public            taiga    false    251    251    251    251            �           2606    9778112 t   notifications_historychangenotification_history_entries notifications_historychangenotification_history_entries_pkey 
   CONSTRAINT     �   ALTER TABLE ONLY public.notifications_historychangenotification_history_entries
    ADD CONSTRAINT notifications_historychangenotification_history_entries_pkey PRIMARY KEY (id);
 �   ALTER TABLE ONLY public.notifications_historychangenotification_history_entries DROP CONSTRAINT notifications_historychangenotification_history_entries_pkey;
       public            taiga    false    253            �           2606    9777487 n   notifications_historychangenotification_notify_users notifications_historychangenotification_notify_users_pkey 
   CONSTRAINT     �   ALTER TABLE ONLY public.notifications_historychangenotification_notify_users
    ADD CONSTRAINT notifications_historychangenotification_notify_users_pkey PRIMARY KEY (id);
 �   ALTER TABLE ONLY public.notifications_historychangenotification_notify_users DROP CONSTRAINT notifications_historychangenotification_notify_users_pkey;
       public            taiga    false    255            �           2606    9777471 T   notifications_historychangenotification notifications_historychangenotification_pkey 
   CONSTRAINT     �   ALTER TABLE ONLY public.notifications_historychangenotification
    ADD CONSTRAINT notifications_historychangenotification_pkey PRIMARY KEY (id);
 ~   ALTER TABLE ONLY public.notifications_historychangenotification DROP CONSTRAINT notifications_historychangenotification_pkey;
       public            taiga    false    251            �           2606    9777428 :   notifications_notifypolicy notifications_notifypolicy_pkey 
   CONSTRAINT     x   ALTER TABLE ONLY public.notifications_notifypolicy
    ADD CONSTRAINT notifications_notifypolicy_pkey PRIMARY KEY (id);
 d   ALTER TABLE ONLY public.notifications_notifypolicy DROP CONSTRAINT notifications_notifypolicy_pkey;
       public            taiga    false    249            �           2606    9777430 V   notifications_notifypolicy notifications_notifypolicy_project_id_user_id_e7aa5cf2_uniq 
   CONSTRAINT     �   ALTER TABLE ONLY public.notifications_notifypolicy
    ADD CONSTRAINT notifications_notifypolicy_project_id_user_id_e7aa5cf2_uniq UNIQUE (project_id, user_id);
 �   ALTER TABLE ONLY public.notifications_notifypolicy DROP CONSTRAINT notifications_notifypolicy_project_id_user_id_e7aa5cf2_uniq;
       public            taiga    false    249    249            �           2606    9777541 R   notifications_watched notifications_watched_content_type_id_object_i_e7c27769_uniq 
   CONSTRAINT     �   ALTER TABLE ONLY public.notifications_watched
    ADD CONSTRAINT notifications_watched_content_type_id_object_i_e7c27769_uniq UNIQUE (content_type_id, object_id, user_id, project_id);
 |   ALTER TABLE ONLY public.notifications_watched DROP CONSTRAINT notifications_watched_content_type_id_object_i_e7c27769_uniq;
       public            taiga    false    257    257    257    257            �           2606    9777539 0   notifications_watched notifications_watched_pkey 
   CONSTRAINT     n   ALTER TABLE ONLY public.notifications_watched
    ADD CONSTRAINT notifications_watched_pkey PRIMARY KEY (id);
 Z   ALTER TABLE ONLY public.notifications_watched DROP CONSTRAINT notifications_watched_pkey;
       public            taiga    false    257            g           2606    9778615 @   notifications_webnotification notifications_webnotification_pkey 
   CONSTRAINT     ~   ALTER TABLE ONLY public.notifications_webnotification
    ADD CONSTRAINT notifications_webnotification_pkey PRIMARY KEY (id);
 j   ALTER TABLE ONLY public.notifications_webnotification DROP CONSTRAINT notifications_webnotification_pkey;
       public            taiga    false    310            �           2606    9777907 ,   projects_epicstatus projects_epicstatus_pkey 
   CONSTRAINT     j   ALTER TABLE ONLY public.projects_epicstatus
    ADD CONSTRAINT projects_epicstatus_pkey PRIMARY KEY (id);
 V   ALTER TABLE ONLY public.projects_epicstatus DROP CONSTRAINT projects_epicstatus_pkey;
       public            taiga    false    269            �           2606    9777913 E   projects_epicstatus projects_epicstatus_project_id_name_b71c417e_uniq 
   CONSTRAINT     �   ALTER TABLE ONLY public.projects_epicstatus
    ADD CONSTRAINT projects_epicstatus_project_id_name_b71c417e_uniq UNIQUE (project_id, name);
 o   ALTER TABLE ONLY public.projects_epicstatus DROP CONSTRAINT projects_epicstatus_project_id_name_b71c417e_uniq;
       public            taiga    false    269    269            �           2606    9777915 E   projects_epicstatus projects_epicstatus_project_id_slug_f67857e5_uniq 
   CONSTRAINT     �   ALTER TABLE ONLY public.projects_epicstatus
    ADD CONSTRAINT projects_epicstatus_project_id_slug_f67857e5_uniq UNIQUE (project_id, slug);
 o   ALTER TABLE ONLY public.projects_epicstatus DROP CONSTRAINT projects_epicstatus_project_id_slug_f67857e5_uniq;
       public            taiga    false    269    269            q           2606    9778654 0   projects_issueduedate projects_issueduedate_pkey 
   CONSTRAINT     n   ALTER TABLE ONLY public.projects_issueduedate
    ADD CONSTRAINT projects_issueduedate_pkey PRIMARY KEY (id);
 Z   ALTER TABLE ONLY public.projects_issueduedate DROP CONSTRAINT projects_issueduedate_pkey;
       public            taiga    false    314            t           2606    9778676 I   projects_issueduedate projects_issueduedate_project_id_name_cba303bc_uniq 
   CONSTRAINT     �   ALTER TABLE ONLY public.projects_issueduedate
    ADD CONSTRAINT projects_issueduedate_project_id_name_cba303bc_uniq UNIQUE (project_id, name);
 s   ALTER TABLE ONLY public.projects_issueduedate DROP CONSTRAINT projects_issueduedate_project_id_name_cba303bc_uniq;
       public            taiga    false    314    314            1           2606    9776872 .   projects_issuestatus projects_issuestatus_pkey 
   CONSTRAINT     l   ALTER TABLE ONLY public.projects_issuestatus
    ADD CONSTRAINT projects_issuestatus_pkey PRIMARY KEY (id);
 X   ALTER TABLE ONLY public.projects_issuestatus DROP CONSTRAINT projects_issuestatus_pkey;
       public            taiga    false    217            4           2606    9776947 G   projects_issuestatus projects_issuestatus_project_id_name_a88dd6c0_uniq 
   CONSTRAINT     �   ALTER TABLE ONLY public.projects_issuestatus
    ADD CONSTRAINT projects_issuestatus_project_id_name_a88dd6c0_uniq UNIQUE (project_id, name);
 q   ALTER TABLE ONLY public.projects_issuestatus DROP CONSTRAINT projects_issuestatus_project_id_name_a88dd6c0_uniq;
       public            taiga    false    217    217            6           2606    9778696 G   projects_issuestatus projects_issuestatus_project_id_slug_ca3e758d_uniq 
   CONSTRAINT     �   ALTER TABLE ONLY public.projects_issuestatus
    ADD CONSTRAINT projects_issuestatus_project_id_slug_ca3e758d_uniq UNIQUE (project_id, slug);
 q   ALTER TABLE ONLY public.projects_issuestatus DROP CONSTRAINT projects_issuestatus_project_id_slug_ca3e758d_uniq;
       public            taiga    false    217    217            :           2606    9776880 *   projects_issuetype projects_issuetype_pkey 
   CONSTRAINT     h   ALTER TABLE ONLY public.projects_issuetype
    ADD CONSTRAINT projects_issuetype_pkey PRIMARY KEY (id);
 T   ALTER TABLE ONLY public.projects_issuetype DROP CONSTRAINT projects_issuetype_pkey;
       public            taiga    false    219            =           2606    9776945 C   projects_issuetype projects_issuetype_project_id_name_41b47d87_uniq 
   CONSTRAINT     �   ALTER TABLE ONLY public.projects_issuetype
    ADD CONSTRAINT projects_issuetype_project_id_name_41b47d87_uniq UNIQUE (project_id, name);
 m   ALTER TABLE ONLY public.projects_issuetype DROP CONSTRAINT projects_issuetype_project_id_name_41b47d87_uniq;
       public            taiga    false    219    219            �           2606    9776819 ,   projects_membership projects_membership_pkey 
   CONSTRAINT     j   ALTER TABLE ONLY public.projects_membership
    ADD CONSTRAINT projects_membership_pkey PRIMARY KEY (id);
 V   ALTER TABLE ONLY public.projects_membership DROP CONSTRAINT projects_membership_pkey;
       public            taiga    false    213                       2606    9776837 H   projects_membership projects_membership_user_id_project_id_a2829f61_uniq 
   CONSTRAINT     �   ALTER TABLE ONLY public.projects_membership
    ADD CONSTRAINT projects_membership_user_id_project_id_a2829f61_uniq UNIQUE (user_id, project_id);
 r   ALTER TABLE ONLY public.projects_membership DROP CONSTRAINT projects_membership_user_id_project_id_a2829f61_uniq;
       public            taiga    false    213    213            ?           2606    9776888 $   projects_points projects_points_pkey 
   CONSTRAINT     b   ALTER TABLE ONLY public.projects_points
    ADD CONSTRAINT projects_points_pkey PRIMARY KEY (id);
 N   ALTER TABLE ONLY public.projects_points DROP CONSTRAINT projects_points_pkey;
       public            taiga    false    221            B           2606    9776943 =   projects_points projects_points_project_id_name_900c69f4_uniq 
   CONSTRAINT     �   ALTER TABLE ONLY public.projects_points
    ADD CONSTRAINT projects_points_project_id_name_900c69f4_uniq UNIQUE (project_id, name);
 g   ALTER TABLE ONLY public.projects_points DROP CONSTRAINT projects_points_project_id_name_900c69f4_uniq;
       public            taiga    false    221    221            D           2606    9776896 (   projects_priority projects_priority_pkey 
   CONSTRAINT     f   ALTER TABLE ONLY public.projects_priority
    ADD CONSTRAINT projects_priority_pkey PRIMARY KEY (id);
 R   ALTER TABLE ONLY public.projects_priority DROP CONSTRAINT projects_priority_pkey;
       public            taiga    false    223            G           2606    9776941 A   projects_priority projects_priority_project_id_name_ca316bb1_uniq 
   CONSTRAINT     �   ALTER TABLE ONLY public.projects_priority
    ADD CONSTRAINT projects_priority_project_id_name_ca316bb1_uniq UNIQUE (project_id, name);
 k   ALTER TABLE ONLY public.projects_priority DROP CONSTRAINT projects_priority_project_id_name_ca316bb1_uniq;
       public            taiga    false    223    223                       2606    9777911 <   projects_project projects_project_default_epic_status_id_key 
   CONSTRAINT     �   ALTER TABLE ONLY public.projects_project
    ADD CONSTRAINT projects_project_default_epic_status_id_key UNIQUE (default_epic_status_id);
 f   ALTER TABLE ONLY public.projects_project DROP CONSTRAINT projects_project_default_epic_status_id_key;
       public            taiga    false    215                       2606    9776949 =   projects_project projects_project_default_issue_status_id_key 
   CONSTRAINT     �   ALTER TABLE ONLY public.projects_project
    ADD CONSTRAINT projects_project_default_issue_status_id_key UNIQUE (default_issue_status_id);
 g   ALTER TABLE ONLY public.projects_project DROP CONSTRAINT projects_project_default_issue_status_id_key;
       public            taiga    false    215            	           2606    9776951 ;   projects_project projects_project_default_issue_type_id_key 
   CONSTRAINT     �   ALTER TABLE ONLY public.projects_project
    ADD CONSTRAINT projects_project_default_issue_type_id_key UNIQUE (default_issue_type_id);
 e   ALTER TABLE ONLY public.projects_project DROP CONSTRAINT projects_project_default_issue_type_id_key;
       public            taiga    false    215                       2606    9776953 7   projects_project projects_project_default_points_id_key 
   CONSTRAINT        ALTER TABLE ONLY public.projects_project
    ADD CONSTRAINT projects_project_default_points_id_key UNIQUE (default_points_id);
 a   ALTER TABLE ONLY public.projects_project DROP CONSTRAINT projects_project_default_points_id_key;
       public            taiga    false    215                       2606    9776955 9   projects_project projects_project_default_priority_id_key 
   CONSTRAINT     �   ALTER TABLE ONLY public.projects_project
    ADD CONSTRAINT projects_project_default_priority_id_key UNIQUE (default_priority_id);
 c   ALTER TABLE ONLY public.projects_project DROP CONSTRAINT projects_project_default_priority_id_key;
       public            taiga    false    215                       2606    9776957 9   projects_project projects_project_default_severity_id_key 
   CONSTRAINT     �   ALTER TABLE ONLY public.projects_project
    ADD CONSTRAINT projects_project_default_severity_id_key UNIQUE (default_severity_id);
 c   ALTER TABLE ONLY public.projects_project DROP CONSTRAINT projects_project_default_severity_id_key;
       public            taiga    false    215                       2606    9778742 9   projects_project projects_project_default_swimlane_id_key 
   CONSTRAINT     �   ALTER TABLE ONLY public.projects_project
    ADD CONSTRAINT projects_project_default_swimlane_id_key UNIQUE (default_swimlane_id);
 c   ALTER TABLE ONLY public.projects_project DROP CONSTRAINT projects_project_default_swimlane_id_key;
       public            taiga    false    215                       2606    9776959 <   projects_project projects_project_default_task_status_id_key 
   CONSTRAINT     �   ALTER TABLE ONLY public.projects_project
    ADD CONSTRAINT projects_project_default_task_status_id_key UNIQUE (default_task_status_id);
 f   ALTER TABLE ONLY public.projects_project DROP CONSTRAINT projects_project_default_task_status_id_key;
       public            taiga    false    215                       2606    9776961 :   projects_project projects_project_default_us_status_id_key 
   CONSTRAINT     �   ALTER TABLE ONLY public.projects_project
    ADD CONSTRAINT projects_project_default_us_status_id_key UNIQUE (default_us_status_id);
 d   ALTER TABLE ONLY public.projects_project DROP CONSTRAINT projects_project_default_us_status_id_key;
       public            taiga    false    215                       2606    9776830 &   projects_project projects_project_pkey 
   CONSTRAINT     d   ALTER TABLE ONLY public.projects_project
    ADD CONSTRAINT projects_project_pkey PRIMARY KEY (id);
 P   ALTER TABLE ONLY public.projects_project DROP CONSTRAINT projects_project_pkey;
       public            taiga    false    215                        2606    9776834 *   projects_project projects_project_slug_key 
   CONSTRAINT     e   ALTER TABLE ONLY public.projects_project
    ADD CONSTRAINT projects_project_slug_key UNIQUE (slug);
 T   ALTER TABLE ONLY public.projects_project DROP CONSTRAINT projects_project_slug_key;
       public            taiga    false    215            �           2606    9777725 @   projects_projectmodulesconfig projects_projectmodulesconfig_pkey 
   CONSTRAINT     ~   ALTER TABLE ONLY public.projects_projectmodulesconfig
    ADD CONSTRAINT projects_projectmodulesconfig_pkey PRIMARY KEY (id);
 j   ALTER TABLE ONLY public.projects_projectmodulesconfig DROP CONSTRAINT projects_projectmodulesconfig_pkey;
       public            taiga    false    263            �           2606    9777727 J   projects_projectmodulesconfig projects_projectmodulesconfig_project_id_key 
   CONSTRAINT     �   ALTER TABLE ONLY public.projects_projectmodulesconfig
    ADD CONSTRAINT projects_projectmodulesconfig_project_id_key UNIQUE (project_id);
 t   ALTER TABLE ONLY public.projects_projectmodulesconfig DROP CONSTRAINT projects_projectmodulesconfig_project_id_key;
       public            taiga    false    263            I           2606    9776907 6   projects_projecttemplate projects_projecttemplate_pkey 
   CONSTRAINT     t   ALTER TABLE ONLY public.projects_projecttemplate
    ADD CONSTRAINT projects_projecttemplate_pkey PRIMARY KEY (id);
 `   ALTER TABLE ONLY public.projects_projecttemplate DROP CONSTRAINT projects_projecttemplate_pkey;
       public            taiga    false    225            L           2606    9776909 :   projects_projecttemplate projects_projecttemplate_slug_key 
   CONSTRAINT     u   ALTER TABLE ONLY public.projects_projecttemplate
    ADD CONSTRAINT projects_projecttemplate_slug_key UNIQUE (slug);
 d   ALTER TABLE ONLY public.projects_projecttemplate DROP CONSTRAINT projects_projecttemplate_slug_key;
       public            taiga    false    225            N           2606    9776917 (   projects_severity projects_severity_pkey 
   CONSTRAINT     f   ALTER TABLE ONLY public.projects_severity
    ADD CONSTRAINT projects_severity_pkey PRIMARY KEY (id);
 R   ALTER TABLE ONLY public.projects_severity DROP CONSTRAINT projects_severity_pkey;
       public            taiga    false    227            Q           2606    9776939 A   projects_severity projects_severity_project_id_name_6187c456_uniq 
   CONSTRAINT     �   ALTER TABLE ONLY public.projects_severity
    ADD CONSTRAINT projects_severity_project_id_name_6187c456_uniq UNIQUE (project_id, name);
 k   ALTER TABLE ONLY public.projects_severity DROP CONSTRAINT projects_severity_project_id_name_6187c456_uniq;
       public            taiga    false    227    227            �           2606    9778712 (   projects_swimlane projects_swimlane_pkey 
   CONSTRAINT     f   ALTER TABLE ONLY public.projects_swimlane
    ADD CONSTRAINT projects_swimlane_pkey PRIMARY KEY (id);
 R   ALTER TABLE ONLY public.projects_swimlane DROP CONSTRAINT projects_swimlane_pkey;
       public            taiga    false    320            �           2606    9778749 A   projects_swimlane projects_swimlane_project_id_name_a949892d_uniq 
   CONSTRAINT     �   ALTER TABLE ONLY public.projects_swimlane
    ADD CONSTRAINT projects_swimlane_project_id_name_a949892d_uniq UNIQUE (project_id, name);
 k   ALTER TABLE ONLY public.projects_swimlane DROP CONSTRAINT projects_swimlane_project_id_name_a949892d_uniq;
       public            taiga    false    320    320            �           2606    9778738 ]   projects_swimlaneuserstorystatus projects_swimlaneusersto_swimlane_id_status_id_d6ff394d_uniq 
   CONSTRAINT     �   ALTER TABLE ONLY public.projects_swimlaneuserstorystatus
    ADD CONSTRAINT projects_swimlaneusersto_swimlane_id_status_id_d6ff394d_uniq UNIQUE (swimlane_id, status_id);
 �   ALTER TABLE ONLY public.projects_swimlaneuserstorystatus DROP CONSTRAINT projects_swimlaneusersto_swimlane_id_status_id_d6ff394d_uniq;
       public            taiga    false    322    322            �           2606    9778726 F   projects_swimlaneuserstorystatus projects_swimlaneuserstorystatus_pkey 
   CONSTRAINT     �   ALTER TABLE ONLY public.projects_swimlaneuserstorystatus
    ADD CONSTRAINT projects_swimlaneuserstorystatus_pkey PRIMARY KEY (id);
 p   ALTER TABLE ONLY public.projects_swimlaneuserstorystatus DROP CONSTRAINT projects_swimlaneuserstorystatus_pkey;
       public            taiga    false    322            v           2606    9778662 .   projects_taskduedate projects_taskduedate_pkey 
   CONSTRAINT     l   ALTER TABLE ONLY public.projects_taskduedate
    ADD CONSTRAINT projects_taskduedate_pkey PRIMARY KEY (id);
 X   ALTER TABLE ONLY public.projects_taskduedate DROP CONSTRAINT projects_taskduedate_pkey;
       public            taiga    false    316            y           2606    9778674 G   projects_taskduedate projects_taskduedate_project_id_name_6270950e_uniq 
   CONSTRAINT     �   ALTER TABLE ONLY public.projects_taskduedate
    ADD CONSTRAINT projects_taskduedate_project_id_name_6270950e_uniq UNIQUE (project_id, name);
 q   ALTER TABLE ONLY public.projects_taskduedate DROP CONSTRAINT projects_taskduedate_project_id_name_6270950e_uniq;
       public            taiga    false    316    316            S           2606    9776925 ,   projects_taskstatus projects_taskstatus_pkey 
   CONSTRAINT     j   ALTER TABLE ONLY public.projects_taskstatus
    ADD CONSTRAINT projects_taskstatus_pkey PRIMARY KEY (id);
 V   ALTER TABLE ONLY public.projects_taskstatus DROP CONSTRAINT projects_taskstatus_pkey;
       public            taiga    false    229            V           2606    9776937 E   projects_taskstatus projects_taskstatus_project_id_name_4b65b78f_uniq 
   CONSTRAINT     �   ALTER TABLE ONLY public.projects_taskstatus
    ADD CONSTRAINT projects_taskstatus_project_id_name_4b65b78f_uniq UNIQUE (project_id, name);
 o   ALTER TABLE ONLY public.projects_taskstatus DROP CONSTRAINT projects_taskstatus_project_id_name_4b65b78f_uniq;
       public            taiga    false    229    229            X           2606    9777712 E   projects_taskstatus projects_taskstatus_project_id_slug_30401ba3_uniq 
   CONSTRAINT     �   ALTER TABLE ONLY public.projects_taskstatus
    ADD CONSTRAINT projects_taskstatus_project_id_slug_30401ba3_uniq UNIQUE (project_id, slug);
 o   ALTER TABLE ONLY public.projects_taskstatus DROP CONSTRAINT projects_taskstatus_project_id_slug_30401ba3_uniq;
       public            taiga    false    229    229            {           2606    9778670 8   projects_userstoryduedate projects_userstoryduedate_pkey 
   CONSTRAINT     v   ALTER TABLE ONLY public.projects_userstoryduedate
    ADD CONSTRAINT projects_userstoryduedate_pkey PRIMARY KEY (id);
 b   ALTER TABLE ONLY public.projects_userstoryduedate DROP CONSTRAINT projects_userstoryduedate_pkey;
       public            taiga    false    318            ~           2606    9778672 Q   projects_userstoryduedate projects_userstoryduedate_project_id_name_177c510a_uniq 
   CONSTRAINT     �   ALTER TABLE ONLY public.projects_userstoryduedate
    ADD CONSTRAINT projects_userstoryduedate_project_id_name_177c510a_uniq UNIQUE (project_id, name);
 {   ALTER TABLE ONLY public.projects_userstoryduedate DROP CONSTRAINT projects_userstoryduedate_project_id_name_177c510a_uniq;
       public            taiga    false    318    318            \           2606    9776933 6   projects_userstorystatus projects_userstorystatus_pkey 
   CONSTRAINT     t   ALTER TABLE ONLY public.projects_userstorystatus
    ADD CONSTRAINT projects_userstorystatus_pkey PRIMARY KEY (id);
 `   ALTER TABLE ONLY public.projects_userstorystatus DROP CONSTRAINT projects_userstorystatus_pkey;
       public            taiga    false    231            _           2606    9776935 O   projects_userstorystatus projects_userstorystatus_project_id_name_7c0a1351_uniq 
   CONSTRAINT     �   ALTER TABLE ONLY public.projects_userstorystatus
    ADD CONSTRAINT projects_userstorystatus_project_id_name_7c0a1351_uniq UNIQUE (project_id, name);
 y   ALTER TABLE ONLY public.projects_userstorystatus DROP CONSTRAINT projects_userstorystatus_project_id_name_7c0a1351_uniq;
       public            taiga    false    231    231            a           2606    9777714 O   projects_userstorystatus projects_userstorystatus_project_id_slug_97a888b5_uniq 
   CONSTRAINT     �   ALTER TABLE ONLY public.projects_userstorystatus
    ADD CONSTRAINT projects_userstorystatus_project_id_slug_97a888b5_uniq UNIQUE (project_id, slug);
 y   ALTER TABLE ONLY public.projects_userstorystatus DROP CONSTRAINT projects_userstorystatus_project_id_slug_97a888b5_uniq;
       public            taiga    false    231    231            �           2606    9778765 .   references_reference references_reference_pkey 
   CONSTRAINT     l   ALTER TABLE ONLY public.references_reference
    ADD CONSTRAINT references_reference_pkey PRIMARY KEY (id);
 X   ALTER TABLE ONLY public.references_reference DROP CONSTRAINT references_reference_pkey;
       public            taiga    false    324            �           2606    9778767 F   references_reference references_reference_project_id_ref_82d64d63_uniq 
   CONSTRAINT     �   ALTER TABLE ONLY public.references_reference
    ADD CONSTRAINT references_reference_project_id_ref_82d64d63_uniq UNIQUE (project_id, ref);
 p   ALTER TABLE ONLY public.references_reference DROP CONSTRAINT references_reference_project_id_ref_82d64d63_uniq;
       public            taiga    false    324    324            �           2606    9778797 >   settings_userprojectsettings settings_userprojectsettings_pkey 
   CONSTRAINT     |   ALTER TABLE ONLY public.settings_userprojectsettings
    ADD CONSTRAINT settings_userprojectsettings_pkey PRIMARY KEY (id);
 h   ALTER TABLE ONLY public.settings_userprojectsettings DROP CONSTRAINT settings_userprojectsettings_pkey;
       public            taiga    false    327            �           2606    9778799 Z   settings_userprojectsettings settings_userprojectsettings_project_id_user_id_330ddee9_uniq 
   CONSTRAINT     �   ALTER TABLE ONLY public.settings_userprojectsettings
    ADD CONSTRAINT settings_userprojectsettings_project_id_user_id_330ddee9_uniq UNIQUE (project_id, user_id);
 �   ALTER TABLE ONLY public.settings_userprojectsettings DROP CONSTRAINT settings_userprojectsettings_project_id_user_id_330ddee9_uniq;
       public            taiga    false    327    327            �           2606    9777570    tasks_task tasks_task_pkey 
   CONSTRAINT     X   ALTER TABLE ONLY public.tasks_task
    ADD CONSTRAINT tasks_task_pkey PRIMARY KEY (id);
 D   ALTER TABLE ONLY public.tasks_task DROP CONSTRAINT tasks_task_pkey;
       public            taiga    false    259            �           2606    9778853 <   telemetry_instancetelemetry telemetry_instancetelemetry_pkey 
   CONSTRAINT     z   ALTER TABLE ONLY public.telemetry_instancetelemetry
    ADD CONSTRAINT telemetry_instancetelemetry_pkey PRIMARY KEY (id);
 f   ALTER TABLE ONLY public.telemetry_instancetelemetry DROP CONSTRAINT telemetry_instancetelemetry_pkey;
       public            taiga    false    329            �           2606    9777751 (   timeline_timeline timeline_timeline_pkey 
   CONSTRAINT     f   ALTER TABLE ONLY public.timeline_timeline
    ADD CONSTRAINT timeline_timeline_pkey PRIMARY KEY (id);
 R   ALTER TABLE ONLY public.timeline_timeline DROP CONSTRAINT timeline_timeline_pkey;
       public            taiga    false    265            �           2606    9778894 B   token_denylist_denylistedtoken token_denylist_denylistedtoken_pkey 
   CONSTRAINT     �   ALTER TABLE ONLY public.token_denylist_denylistedtoken
    ADD CONSTRAINT token_denylist_denylistedtoken_pkey PRIMARY KEY (id);
 l   ALTER TABLE ONLY public.token_denylist_denylistedtoken DROP CONSTRAINT token_denylist_denylistedtoken_pkey;
       public            taiga    false    333            �           2606    9778896 J   token_denylist_denylistedtoken token_denylist_denylistedtoken_token_id_key 
   CONSTRAINT     �   ALTER TABLE ONLY public.token_denylist_denylistedtoken
    ADD CONSTRAINT token_denylist_denylistedtoken_token_id_key UNIQUE (token_id);
 t   ALTER TABLE ONLY public.token_denylist_denylistedtoken DROP CONSTRAINT token_denylist_denylistedtoken_token_id_key;
       public            taiga    false    333            �           2606    9778886 G   token_denylist_outstandingtoken token_denylist_outstandingtoken_jti_key 
   CONSTRAINT     �   ALTER TABLE ONLY public.token_denylist_outstandingtoken
    ADD CONSTRAINT token_denylist_outstandingtoken_jti_key UNIQUE (jti);
 q   ALTER TABLE ONLY public.token_denylist_outstandingtoken DROP CONSTRAINT token_denylist_outstandingtoken_jti_key;
       public            taiga    false    331            �           2606    9778884 D   token_denylist_outstandingtoken token_denylist_outstandingtoken_pkey 
   CONSTRAINT     �   ALTER TABLE ONLY public.token_denylist_outstandingtoken
    ADD CONSTRAINT token_denylist_outstandingtoken_pkey PRIMARY KEY (id);
 n   ALTER TABLE ONLY public.token_denylist_outstandingtoken DROP CONSTRAINT token_denylist_outstandingtoken_pkey;
       public            taiga    false    331            �           2606    9777654 5   users_authdata users_authdata_key_value_7ee3acc9_uniq 
   CONSTRAINT     v   ALTER TABLE ONLY public.users_authdata
    ADD CONSTRAINT users_authdata_key_value_7ee3acc9_uniq UNIQUE (key, value);
 _   ALTER TABLE ONLY public.users_authdata DROP CONSTRAINT users_authdata_key_value_7ee3acc9_uniq;
       public            taiga    false    261    261            �           2606    9777652 "   users_authdata users_authdata_pkey 
   CONSTRAINT     `   ALTER TABLE ONLY public.users_authdata
    ADD CONSTRAINT users_authdata_pkey PRIMARY KEY (id);
 L   ALTER TABLE ONLY public.users_authdata DROP CONSTRAINT users_authdata_pkey;
       public            taiga    false    261            �           2606    9776809    users_role users_role_pkey 
   CONSTRAINT     X   ALTER TABLE ONLY public.users_role
    ADD CONSTRAINT users_role_pkey PRIMARY KEY (id);
 D   ALTER TABLE ONLY public.users_role DROP CONSTRAINT users_role_pkey;
       public            taiga    false    211            �           2606    9777138 3   users_role users_role_slug_project_id_db8c270c_uniq 
   CONSTRAINT     z   ALTER TABLE ONLY public.users_role
    ADD CONSTRAINT users_role_slug_project_id_db8c270c_uniq UNIQUE (slug, project_id);
 ]   ALTER TABLE ONLY public.users_role DROP CONSTRAINT users_role_slug_project_id_db8c270c_uniq;
       public            taiga    false    211    211            �           2606    9777146 )   users_user users_user_email_243f6e77_uniq 
   CONSTRAINT     e   ALTER TABLE ONLY public.users_user
    ADD CONSTRAINT users_user_email_243f6e77_uniq UNIQUE (email);
 S   ALTER TABLE ONLY public.users_user DROP CONSTRAINT users_user_email_243f6e77_uniq;
       public            taiga    false    207            �           2606    9776771    users_user users_user_pkey 
   CONSTRAINT     X   ALTER TABLE ONLY public.users_user
    ADD CONSTRAINT users_user_pkey PRIMARY KEY (id);
 D   ALTER TABLE ONLY public.users_user DROP CONSTRAINT users_user_pkey;
       public            taiga    false    207            �           2606    9777149 "   users_user users_user_username_key 
   CONSTRAINT     a   ALTER TABLE ONLY public.users_user
    ADD CONSTRAINT users_user_username_key UNIQUE (username);
 L   ALTER TABLE ONLY public.users_user DROP CONSTRAINT users_user_username_key;
       public            taiga    false    207            �           2606    9778924 (   users_user users_user_uuid_6fe513d7_uniq 
   CONSTRAINT     c   ALTER TABLE ONLY public.users_user
    ADD CONSTRAINT users_user_uuid_6fe513d7_uniq UNIQUE (uuid);
 R   ALTER TABLE ONLY public.users_user DROP CONSTRAINT users_user_uuid_6fe513d7_uniq;
       public            taiga    false    207            �           2606    9778941 ,   users_workspacerole users_workspacerole_pkey 
   CONSTRAINT     j   ALTER TABLE ONLY public.users_workspacerole
    ADD CONSTRAINT users_workspacerole_pkey PRIMARY KEY (id);
 V   ALTER TABLE ONLY public.users_workspacerole DROP CONSTRAINT users_workspacerole_pkey;
       public            taiga    false    335            �           2606    9778948 G   users_workspacerole users_workspacerole_slug_workspace_id_1c9aef12_uniq 
   CONSTRAINT     �   ALTER TABLE ONLY public.users_workspacerole
    ADD CONSTRAINT users_workspacerole_slug_workspace_id_1c9aef12_uniq UNIQUE (slug, workspace_id);
 q   ALTER TABLE ONLY public.users_workspacerole DROP CONSTRAINT users_workspacerole_slug_workspace_id_1c9aef12_uniq;
       public            taiga    false    335    335            �           2606    9778964 L   userstorage_storageentry userstorage_storageentry_owner_id_key_746399cb_uniq 
   CONSTRAINT     �   ALTER TABLE ONLY public.userstorage_storageentry
    ADD CONSTRAINT userstorage_storageentry_owner_id_key_746399cb_uniq UNIQUE (owner_id, key);
 v   ALTER TABLE ONLY public.userstorage_storageentry DROP CONSTRAINT userstorage_storageentry_owner_id_key_746399cb_uniq;
       public            taiga    false    337    337            �           2606    9778962 6   userstorage_storageentry userstorage_storageentry_pkey 
   CONSTRAINT     t   ALTER TABLE ONLY public.userstorage_storageentry
    ADD CONSTRAINT userstorage_storageentry_pkey PRIMARY KEY (id);
 `   ALTER TABLE ONLY public.userstorage_storageentry DROP CONSTRAINT userstorage_storageentry_pkey;
       public            taiga    false    337            �           2606    9777293 2   userstories_rolepoints userstories_rolepoints_pkey 
   CONSTRAINT     p   ALTER TABLE ONLY public.userstories_rolepoints
    ADD CONSTRAINT userstories_rolepoints_pkey PRIMARY KEY (id);
 \   ALTER TABLE ONLY public.userstories_rolepoints DROP CONSTRAINT userstories_rolepoints_pkey;
       public            taiga    false    245            �           2606    9777315 Q   userstories_rolepoints userstories_rolepoints_user_story_id_role_id_dc0ba15e_uniq 
   CONSTRAINT     �   ALTER TABLE ONLY public.userstories_rolepoints
    ADD CONSTRAINT userstories_rolepoints_user_story_id_role_id_dc0ba15e_uniq UNIQUE (user_story_id, role_id);
 {   ALTER TABLE ONLY public.userstories_rolepoints DROP CONSTRAINT userstories_rolepoints_user_story_id_role_id_dc0ba15e_uniq;
       public            taiga    false    245    245            �           2606    9779042 `   userstories_userstory_assigned_users userstories_userstory_as_userstory_id_user_id_beae1231_uniq 
   CONSTRAINT     �   ALTER TABLE ONLY public.userstories_userstory_assigned_users
    ADD CONSTRAINT userstories_userstory_as_userstory_id_user_id_beae1231_uniq UNIQUE (userstory_id, user_id);
 �   ALTER TABLE ONLY public.userstories_userstory_assigned_users DROP CONSTRAINT userstories_userstory_as_userstory_id_user_id_beae1231_uniq;
       public            taiga    false    339    339            �           2606    9779030 N   userstories_userstory_assigned_users userstories_userstory_assigned_users_pkey 
   CONSTRAINT     �   ALTER TABLE ONLY public.userstories_userstory_assigned_users
    ADD CONSTRAINT userstories_userstory_assigned_users_pkey PRIMARY KEY (id);
 x   ALTER TABLE ONLY public.userstories_userstory_assigned_users DROP CONSTRAINT userstories_userstory_assigned_users_pkey;
       public            taiga    false    339            �           2606    9777305 0   userstories_userstory userstories_userstory_pkey 
   CONSTRAINT     n   ALTER TABLE ONLY public.userstories_userstory
    ADD CONSTRAINT userstories_userstory_pkey PRIMARY KEY (id);
 Z   ALTER TABLE ONLY public.userstories_userstory DROP CONSTRAINT userstories_userstory_pkey;
       public            taiga    false    247            �           2606    9779084 E   votes_vote votes_vote_content_type_id_object_id_user_id_97d16fa0_uniq 
   CONSTRAINT     �   ALTER TABLE ONLY public.votes_vote
    ADD CONSTRAINT votes_vote_content_type_id_object_id_user_id_97d16fa0_uniq UNIQUE (content_type_id, object_id, user_id);
 o   ALTER TABLE ONLY public.votes_vote DROP CONSTRAINT votes_vote_content_type_id_object_id_user_id_97d16fa0_uniq;
       public            taiga    false    341    341    341            �           2606    9779070    votes_vote votes_vote_pkey 
   CONSTRAINT     X   ALTER TABLE ONLY public.votes_vote
    ADD CONSTRAINT votes_vote_pkey PRIMARY KEY (id);
 D   ALTER TABLE ONLY public.votes_vote DROP CONSTRAINT votes_vote_pkey;
       public            taiga    false    341            �           2606    9779082 ?   votes_votes votes_votes_content_type_id_object_id_5abfc91b_uniq 
   CONSTRAINT     �   ALTER TABLE ONLY public.votes_votes
    ADD CONSTRAINT votes_votes_content_type_id_object_id_5abfc91b_uniq UNIQUE (content_type_id, object_id);
 i   ALTER TABLE ONLY public.votes_votes DROP CONSTRAINT votes_votes_content_type_id_object_id_5abfc91b_uniq;
       public            taiga    false    343    343            �           2606    9779080    votes_votes votes_votes_pkey 
   CONSTRAINT     Z   ALTER TABLE ONLY public.votes_votes
    ADD CONSTRAINT votes_votes_pkey PRIMARY KEY (id);
 F   ALTER TABLE ONLY public.votes_votes DROP CONSTRAINT votes_votes_pkey;
       public            taiga    false    343            �           2606    9779119 &   webhooks_webhook webhooks_webhook_pkey 
   CONSTRAINT     d   ALTER TABLE ONLY public.webhooks_webhook
    ADD CONSTRAINT webhooks_webhook_pkey PRIMARY KEY (id);
 P   ALTER TABLE ONLY public.webhooks_webhook DROP CONSTRAINT webhooks_webhook_pkey;
       public            taiga    false    345            �           2606    9779130 ,   webhooks_webhooklog webhooks_webhooklog_pkey 
   CONSTRAINT     j   ALTER TABLE ONLY public.webhooks_webhooklog
    ADD CONSTRAINT webhooks_webhooklog_pkey PRIMARY KEY (id);
 V   ALTER TABLE ONLY public.webhooks_webhooklog DROP CONSTRAINT webhooks_webhooklog_pkey;
       public            taiga    false    347            �           2606    9778010     wiki_wikilink wiki_wikilink_pkey 
   CONSTRAINT     ^   ALTER TABLE ONLY public.wiki_wikilink
    ADD CONSTRAINT wiki_wikilink_pkey PRIMARY KEY (id);
 J   ALTER TABLE ONLY public.wiki_wikilink DROP CONSTRAINT wiki_wikilink_pkey;
       public            taiga    false    273            �           2606    9778033 9   wiki_wikilink wiki_wikilink_project_id_href_a39ae7e7_uniq 
   CONSTRAINT     �   ALTER TABLE ONLY public.wiki_wikilink
    ADD CONSTRAINT wiki_wikilink_project_id_href_a39ae7e7_uniq UNIQUE (project_id, href);
 c   ALTER TABLE ONLY public.wiki_wikilink DROP CONSTRAINT wiki_wikilink_project_id_href_a39ae7e7_uniq;
       public            taiga    false    273    273                        2606    9778021     wiki_wikipage wiki_wikipage_pkey 
   CONSTRAINT     ^   ALTER TABLE ONLY public.wiki_wikipage
    ADD CONSTRAINT wiki_wikipage_pkey PRIMARY KEY (id);
 J   ALTER TABLE ONLY public.wiki_wikipage DROP CONSTRAINT wiki_wikipage_pkey;
       public            taiga    false    275                       2606    9778031 9   wiki_wikipage wiki_wikipage_project_id_slug_cb5b63e2_uniq 
   CONSTRAINT     �   ALTER TABLE ONLY public.wiki_wikipage
    ADD CONSTRAINT wiki_wikipage_project_id_slug_cb5b63e2_uniq UNIQUE (project_id, slug);
 c   ALTER TABLE ONLY public.wiki_wikipage DROP CONSTRAINT wiki_wikipage_project_id_slug_cb5b63e2_uniq;
       public            taiga    false    275    275            l           2606    9778631 .   workspaces_workspace workspaces_workspace_pkey 
   CONSTRAINT     l   ALTER TABLE ONLY public.workspaces_workspace
    ADD CONSTRAINT workspaces_workspace_pkey PRIMARY KEY (id);
 X   ALTER TABLE ONLY public.workspaces_workspace DROP CONSTRAINT workspaces_workspace_pkey;
       public            taiga    false    312            o           2606    9778633 2   workspaces_workspace workspaces_workspace_slug_key 
   CONSTRAINT     m   ALTER TABLE ONLY public.workspaces_workspace
    ADD CONSTRAINT workspaces_workspace_slug_key UNIQUE (slug);
 \   ALTER TABLE ONLY public.workspaces_workspace DROP CONSTRAINT workspaces_workspace_slug_key;
       public            taiga    false    312            �           2606    9779196 Z   workspaces_workspacemembership workspaces_workspacememb_user_id_workspace_id_92c1b27f_uniq 
   CONSTRAINT     �   ALTER TABLE ONLY public.workspaces_workspacemembership
    ADD CONSTRAINT workspaces_workspacememb_user_id_workspace_id_92c1b27f_uniq UNIQUE (user_id, workspace_id);
 �   ALTER TABLE ONLY public.workspaces_workspacemembership DROP CONSTRAINT workspaces_workspacememb_user_id_workspace_id_92c1b27f_uniq;
       public            taiga    false    349    349            �           2606    9779179 B   workspaces_workspacemembership workspaces_workspacemembership_pkey 
   CONSTRAINT     �   ALTER TABLE ONLY public.workspaces_workspacemembership
    ADD CONSTRAINT workspaces_workspacemembership_pkey PRIMARY KEY (id);
 l   ALTER TABLE ONLY public.workspaces_workspacemembership DROP CONSTRAINT workspaces_workspacemembership_pkey;
       public            taiga    false    349            d           1259    9777073 /   attachments_attachment_content_type_id_35dd9d5d    INDEX     }   CREATE INDEX attachments_attachment_content_type_id_35dd9d5d ON public.attachments_attachment USING btree (content_type_id);
 C   DROP INDEX public.attachments_attachment_content_type_id_35dd9d5d;
       public            taiga    false    233            e           1259    9777083 =   attachments_attachment_content_type_id_object_id_3f2e447c_idx    INDEX     �   CREATE INDEX attachments_attachment_content_type_id_object_id_3f2e447c_idx ON public.attachments_attachment USING btree (content_type_id, object_id);
 Q   DROP INDEX public.attachments_attachment_content_type_id_object_id_3f2e447c_idx;
       public            taiga    false    233    233            f           1259    9777074 (   attachments_attachment_owner_id_720defb8    INDEX     o   CREATE INDEX attachments_attachment_owner_id_720defb8 ON public.attachments_attachment USING btree (owner_id);
 <   DROP INDEX public.attachments_attachment_owner_id_720defb8;
       public            taiga    false    233            i           1259    9777075 *   attachments_attachment_project_id_50714f52    INDEX     s   CREATE INDEX attachments_attachment_project_id_50714f52 ON public.attachments_attachment USING btree (project_id);
 >   DROP INDEX public.attachments_attachment_project_id_50714f52;
       public            taiga    false    233            o           1259    9777136    auth_group_name_a6ea08ec_like    INDEX     h   CREATE INDEX auth_group_name_a6ea08ec_like ON public.auth_group USING btree (name varchar_pattern_ops);
 1   DROP INDEX public.auth_group_name_a6ea08ec_like;
       public            taiga    false    237            t           1259    9777132 (   auth_group_permissions_group_id_b120cbf9    INDEX     o   CREATE INDEX auth_group_permissions_group_id_b120cbf9 ON public.auth_group_permissions USING btree (group_id);
 <   DROP INDEX public.auth_group_permissions_group_id_b120cbf9;
       public            taiga    false    239            w           1259    9777133 -   auth_group_permissions_permission_id_84c5c92e    INDEX     y   CREATE INDEX auth_group_permissions_permission_id_84c5c92e ON public.auth_group_permissions USING btree (permission_id);
 A   DROP INDEX public.auth_group_permissions_permission_id_84c5c92e;
       public            taiga    false    239            j           1259    9777118 (   auth_permission_content_type_id_2f476e4b    INDEX     o   CREATE INDEX auth_permission_content_type_id_2f476e4b ON public.auth_permission USING btree (content_type_id);
 <   DROP INDEX public.auth_permission_content_type_id_2f476e4b;
       public            taiga    false    235            �           1259    9777997 (   contact_contactentry_project_id_27bfec4e    INDEX     o   CREATE INDEX contact_contactentry_project_id_27bfec4e ON public.contact_contactentry USING btree (project_id);
 <   DROP INDEX public.contact_contactentry_project_id_27bfec4e;
       public            taiga    false    271            �           1259    9777998 %   contact_contactentry_user_id_f1f19c5f    INDEX     i   CREATE INDEX contact_contactentry_user_id_f1f19c5f ON public.contact_contactentry USING btree (user_id);
 9   DROP INDEX public.contact_contactentry_user_id_f1f19c5f;
       public            taiga    false    271            <           1259    9778336 -   custom_attributes_epiccu_epic_id_d413e57a_idx    INDEX     �   CREATE INDEX custom_attributes_epiccu_epic_id_d413e57a_idx ON public.custom_attributes_epiccustomattributesvalues USING btree (epic_id);
 A   DROP INDEX public.custom_attributes_epiccu_epic_id_d413e57a_idx;
       public            taiga    false    296            ;           1259    9778345 9   custom_attributes_epiccustomattribute_project_id_ad2cfaa8    INDEX     �   CREATE INDEX custom_attributes_epiccustomattribute_project_id_ad2cfaa8 ON public.custom_attributes_epiccustomattribute USING btree (project_id);
 M   DROP INDEX public.custom_attributes_epiccustomattribute_project_id_ad2cfaa8;
       public            taiga    false    294            (           1259    9778309 .   custom_attributes_issuec_issue_id_868161f8_idx    INDEX     �   CREATE INDEX custom_attributes_issuec_issue_id_868161f8_idx ON public.custom_attributes_issuecustomattributesvalues USING btree (issue_id);
 B   DROP INDEX public.custom_attributes_issuec_issue_id_868161f8_idx;
       public            taiga    false    288                       1259    9778231 :   custom_attributes_issuecustomattribute_project_id_3b4acff5    INDEX     �   CREATE INDEX custom_attributes_issuecustomattribute_project_id_3b4acff5 ON public.custom_attributes_issuecustomattribute USING btree (project_id);
 N   DROP INDEX public.custom_attributes_issuecustomattribute_project_id_3b4acff5;
       public            taiga    false    282            -           1259    9778310 -   custom_attributes_taskcu_task_id_3d1ccf5e_idx    INDEX     �   CREATE INDEX custom_attributes_taskcu_task_id_3d1ccf5e_idx ON public.custom_attributes_taskcustomattributesvalues USING btree (task_id);
 A   DROP INDEX public.custom_attributes_taskcu_task_id_3d1ccf5e_idx;
       public            taiga    false    290            "           1259    9778237 9   custom_attributes_taskcustomattribute_project_id_f0f622a8    INDEX     �   CREATE INDEX custom_attributes_taskcustomattribute_project_id_f0f622a8 ON public.custom_attributes_taskcustomattribute USING btree (project_id);
 M   DROP INDEX public.custom_attributes_taskcustomattribute_project_id_f0f622a8;
       public            taiga    false    284            2           1259    9778311 3   custom_attributes_userst_user_story_id_99b10c43_idx    INDEX     �   CREATE INDEX custom_attributes_userst_user_story_id_99b10c43_idx ON public.custom_attributes_userstorycustomattributesvalues USING btree (user_story_id);
 G   DROP INDEX public.custom_attributes_userst_user_story_id_99b10c43_idx;
       public            taiga    false    292            '           1259    9778243 >   custom_attributes_userstorycustomattribute_project_id_2619cf6c    INDEX     �   CREATE INDEX custom_attributes_userstorycustomattribute_project_id_2619cf6c ON public.custom_attributes_userstorycustomattribute USING btree (project_id);
 R   DROP INDEX public.custom_attributes_userstorycustomattribute_project_id_2619cf6c;
       public            taiga    false    286            �           1259    9776797 )   django_admin_log_content_type_id_c4bce8eb    INDEX     q   CREATE INDEX django_admin_log_content_type_id_c4bce8eb ON public.django_admin_log USING btree (content_type_id);
 =   DROP INDEX public.django_admin_log_content_type_id_c4bce8eb;
       public            taiga    false    209            �           1259    9776798 !   django_admin_log_user_id_c564eba6    INDEX     a   CREATE INDEX django_admin_log_user_id_c564eba6 ON public.django_admin_log USING btree (user_id);
 5   DROP INDEX public.django_admin_log_user_id_c564eba6;
       public            taiga    false    209            �           1259    9778789 #   django_session_expire_date_a5c62663    INDEX     e   CREATE INDEX django_session_expire_date_a5c62663 ON public.django_session USING btree (expire_date);
 7   DROP INDEX public.django_session_expire_date_a5c62663;
       public            taiga    false    325            �           1259    9778788 (   django_session_session_key_c0390e0f_like    INDEX     ~   CREATE INDEX django_session_session_key_c0390e0f_like ON public.django_session USING btree (session_key varchar_pattern_ops);
 <   DROP INDEX public.django_session_session_key_c0390e0f_like;
       public            taiga    false    325            C           1259    9778432 !   djmail_message_uuid_8dad4f24_like    INDEX     p   CREATE INDEX djmail_message_uuid_8dad4f24_like ON public.djmail_message USING btree (uuid varchar_pattern_ops);
 5   DROP INDEX public.djmail_message_uuid_8dad4f24_like;
       public            taiga    false    297            D           1259    9778455 $   easy_thumbnails_source_name_5fe0edc6    INDEX     g   CREATE INDEX easy_thumbnails_source_name_5fe0edc6 ON public.easy_thumbnails_source USING btree (name);
 8   DROP INDEX public.easy_thumbnails_source_name_5fe0edc6;
       public            taiga    false    299            E           1259    9778456 )   easy_thumbnails_source_name_5fe0edc6_like    INDEX     �   CREATE INDEX easy_thumbnails_source_name_5fe0edc6_like ON public.easy_thumbnails_source USING btree (name varchar_pattern_ops);
 =   DROP INDEX public.easy_thumbnails_source_name_5fe0edc6_like;
       public            taiga    false    299            H           1259    9778453 ,   easy_thumbnails_source_storage_hash_946cbcc9    INDEX     w   CREATE INDEX easy_thumbnails_source_storage_hash_946cbcc9 ON public.easy_thumbnails_source USING btree (storage_hash);
 @   DROP INDEX public.easy_thumbnails_source_storage_hash_946cbcc9;
       public            taiga    false    299            I           1259    9778454 1   easy_thumbnails_source_storage_hash_946cbcc9_like    INDEX     �   CREATE INDEX easy_thumbnails_source_storage_hash_946cbcc9_like ON public.easy_thumbnails_source USING btree (storage_hash varchar_pattern_ops);
 E   DROP INDEX public.easy_thumbnails_source_storage_hash_946cbcc9_like;
       public            taiga    false    299            N           1259    9778464 '   easy_thumbnails_thumbnail_name_b5882c31    INDEX     m   CREATE INDEX easy_thumbnails_thumbnail_name_b5882c31 ON public.easy_thumbnails_thumbnail USING btree (name);
 ;   DROP INDEX public.easy_thumbnails_thumbnail_name_b5882c31;
       public            taiga    false    301            O           1259    9778465 ,   easy_thumbnails_thumbnail_name_b5882c31_like    INDEX     �   CREATE INDEX easy_thumbnails_thumbnail_name_b5882c31_like ON public.easy_thumbnails_thumbnail USING btree (name varchar_pattern_ops);
 @   DROP INDEX public.easy_thumbnails_thumbnail_name_b5882c31_like;
       public            taiga    false    301            R           1259    9778466 ,   easy_thumbnails_thumbnail_source_id_5b57bc77    INDEX     w   CREATE INDEX easy_thumbnails_thumbnail_source_id_5b57bc77 ON public.easy_thumbnails_thumbnail USING btree (source_id);
 @   DROP INDEX public.easy_thumbnails_thumbnail_source_id_5b57bc77;
       public            taiga    false    301            S           1259    9778462 /   easy_thumbnails_thumbnail_storage_hash_f1435f49    INDEX     }   CREATE INDEX easy_thumbnails_thumbnail_storage_hash_f1435f49 ON public.easy_thumbnails_thumbnail USING btree (storage_hash);
 C   DROP INDEX public.easy_thumbnails_thumbnail_storage_hash_f1435f49;
       public            taiga    false    301            T           1259    9778463 4   easy_thumbnails_thumbnail_storage_hash_f1435f49_like    INDEX     �   CREATE INDEX easy_thumbnails_thumbnail_storage_hash_f1435f49_like ON public.easy_thumbnails_thumbnail USING btree (storage_hash varchar_pattern_ops);
 H   DROP INDEX public.easy_thumbnails_thumbnail_storage_hash_f1435f49_like;
       public            taiga    false    301                       1259    9778170 "   epics_epic_assigned_to_id_13e08004    INDEX     c   CREATE INDEX epics_epic_assigned_to_id_13e08004 ON public.epics_epic USING btree (assigned_to_id);
 6   DROP INDEX public.epics_epic_assigned_to_id_13e08004;
       public            taiga    false    278                       1259    9778171    epics_epic_owner_id_b09888c4    INDEX     W   CREATE INDEX epics_epic_owner_id_b09888c4 ON public.epics_epic USING btree (owner_id);
 0   DROP INDEX public.epics_epic_owner_id_b09888c4;
       public            taiga    false    278                       1259    9778172    epics_epic_project_id_d98aaef7    INDEX     [   CREATE INDEX epics_epic_project_id_d98aaef7 ON public.epics_epic USING btree (project_id);
 2   DROP INDEX public.epics_epic_project_id_d98aaef7;
       public            taiga    false    278                       1259    9778169    epics_epic_ref_aa52eb4a    INDEX     M   CREATE INDEX epics_epic_ref_aa52eb4a ON public.epics_epic USING btree (ref);
 +   DROP INDEX public.epics_epic_ref_aa52eb4a;
       public            taiga    false    278                       1259    9778173    epics_epic_status_id_4cf3af1a    INDEX     Y   CREATE INDEX epics_epic_status_id_4cf3af1a ON public.epics_epic USING btree (status_id);
 1   DROP INDEX public.epics_epic_status_id_4cf3af1a;
       public            taiga    false    278                       1259    9778184 '   epics_relateduserstory_epic_id_57605230    INDEX     m   CREATE INDEX epics_relateduserstory_epic_id_57605230 ON public.epics_relateduserstory USING btree (epic_id);
 ;   DROP INDEX public.epics_relateduserstory_epic_id_57605230;
       public            taiga    false    280                       1259    9778185 -   epics_relateduserstory_user_story_id_329a951c    INDEX     y   CREATE INDEX epics_relateduserstory_user_story_id_329a951c ON public.epics_relateduserstory USING btree (user_story_id);
 A   DROP INDEX public.epics_relateduserstory_user_story_id_329a951c;
       public            taiga    false    280            Y           1259    9778531 *   external_apps_application_id_e9988cf8_like    INDEX     �   CREATE INDEX external_apps_application_id_e9988cf8_like ON public.external_apps_application USING btree (id varchar_pattern_ops);
 >   DROP INDEX public.external_apps_application_id_e9988cf8_like;
       public            taiga    false    304            ^           1259    9778542 6   external_apps_applicationtoken_application_id_0e934655    INDEX     �   CREATE INDEX external_apps_applicationtoken_application_id_0e934655 ON public.external_apps_applicationtoken USING btree (application_id);
 J   DROP INDEX public.external_apps_applicationtoken_application_id_0e934655;
       public            taiga    false    306            _           1259    9778543 ;   external_apps_applicationtoken_application_id_0e934655_like    INDEX     �   CREATE INDEX external_apps_applicationtoken_application_id_0e934655_like ON public.external_apps_applicationtoken USING btree (application_id varchar_pattern_ops);
 O   DROP INDEX public.external_apps_applicationtoken_application_id_0e934655_like;
       public            taiga    false    306            b           1259    9778544 /   external_apps_applicationtoken_user_id_6e2f1e8a    INDEX     }   CREATE INDEX external_apps_applicationtoken_user_id_6e2f1e8a ON public.external_apps_applicationtoken USING btree (user_id);
 C   DROP INDEX public.external_apps_applicationtoken_user_id_6e2f1e8a;
       public            taiga    false    306                       1259    9778105 %   history_historyentry_id_ff18cc9f_like    INDEX     x   CREATE INDEX history_historyentry_id_ff18cc9f_like ON public.history_historyentry USING btree (id varchar_pattern_ops);
 9   DROP INDEX public.history_historyentry_id_ff18cc9f_like;
       public            taiga    false    276                       1259    9778106 !   history_historyentry_key_c088c4ae    INDEX     a   CREATE INDEX history_historyentry_key_c088c4ae ON public.history_historyentry USING btree (key);
 5   DROP INDEX public.history_historyentry_key_c088c4ae;
       public            taiga    false    276                       1259    9778107 &   history_historyentry_key_c088c4ae_like    INDEX     z   CREATE INDEX history_historyentry_key_c088c4ae_like ON public.history_historyentry USING btree (key varchar_pattern_ops);
 :   DROP INDEX public.history_historyentry_key_c088c4ae_like;
       public            taiga    false    276                       1259    9778108 (   history_historyentry_project_id_9b008f70    INDEX     o   CREATE INDEX history_historyentry_project_id_9b008f70 ON public.history_historyentry USING btree (project_id);
 <   DROP INDEX public.history_historyentry_project_id_9b008f70;
       public            taiga    false    276            �           1259    9777264 $   issues_issue_assigned_to_id_c6054289    INDEX     g   CREATE INDEX issues_issue_assigned_to_id_c6054289 ON public.issues_issue USING btree (assigned_to_id);
 8   DROP INDEX public.issues_issue_assigned_to_id_c6054289;
       public            taiga    false    243            �           1259    9777265 "   issues_issue_milestone_id_3c2695ee    INDEX     c   CREATE INDEX issues_issue_milestone_id_3c2695ee ON public.issues_issue USING btree (milestone_id);
 6   DROP INDEX public.issues_issue_milestone_id_3c2695ee;
       public            taiga    false    243            �           1259    9777266    issues_issue_owner_id_5c361b47    INDEX     [   CREATE INDEX issues_issue_owner_id_5c361b47 ON public.issues_issue USING btree (owner_id);
 2   DROP INDEX public.issues_issue_owner_id_5c361b47;
       public            taiga    false    243            �           1259    9777267 !   issues_issue_priority_id_93842a93    INDEX     a   CREATE INDEX issues_issue_priority_id_93842a93 ON public.issues_issue USING btree (priority_id);
 5   DROP INDEX public.issues_issue_priority_id_93842a93;
       public            taiga    false    243            �           1259    9777268     issues_issue_project_id_4b0f3e2f    INDEX     _   CREATE INDEX issues_issue_project_id_4b0f3e2f ON public.issues_issue USING btree (project_id);
 4   DROP INDEX public.issues_issue_project_id_4b0f3e2f;
       public            taiga    false    243            �           1259    9777263    issues_issue_ref_4c1e7f8f    INDEX     Q   CREATE INDEX issues_issue_ref_4c1e7f8f ON public.issues_issue USING btree (ref);
 -   DROP INDEX public.issues_issue_ref_4c1e7f8f;
       public            taiga    false    243            �           1259    9777269 !   issues_issue_severity_id_695dade0    INDEX     a   CREATE INDEX issues_issue_severity_id_695dade0 ON public.issues_issue USING btree (severity_id);
 5   DROP INDEX public.issues_issue_severity_id_695dade0;
       public            taiga    false    243            �           1259    9777270    issues_issue_status_id_64473cf1    INDEX     ]   CREATE INDEX issues_issue_status_id_64473cf1 ON public.issues_issue USING btree (status_id);
 3   DROP INDEX public.issues_issue_status_id_64473cf1;
       public            taiga    false    243            �           1259    9777271    issues_issue_type_id_c1063362    INDEX     Y   CREATE INDEX issues_issue_type_id_c1063362 ON public.issues_issue USING btree (type_id);
 1   DROP INDEX public.issues_issue_type_id_c1063362;
       public            taiga    false    243            �           1259    9777823 #   likes_like_content_type_id_8ffc2116    INDEX     e   CREATE INDEX likes_like_content_type_id_8ffc2116 ON public.likes_like USING btree (content_type_id);
 7   DROP INDEX public.likes_like_content_type_id_8ffc2116;
       public            taiga    false    267            �           1259    9777824    likes_like_user_id_aae4c421    INDEX     U   CREATE INDEX likes_like_user_id_aae4c421 ON public.likes_like USING btree (user_id);
 /   DROP INDEX public.likes_like_user_id_aae4c421;
       public            taiga    false    267            z           1259    9777184 "   milestones_milestone_name_23fb0698    INDEX     c   CREATE INDEX milestones_milestone_name_23fb0698 ON public.milestones_milestone USING btree (name);
 6   DROP INDEX public.milestones_milestone_name_23fb0698;
       public            taiga    false    241            {           1259    9777185 '   milestones_milestone_name_23fb0698_like    INDEX     |   CREATE INDEX milestones_milestone_name_23fb0698_like ON public.milestones_milestone USING btree (name varchar_pattern_ops);
 ;   DROP INDEX public.milestones_milestone_name_23fb0698_like;
       public            taiga    false    241            ~           1259    9777188 &   milestones_milestone_owner_id_216ba23b    INDEX     k   CREATE INDEX milestones_milestone_owner_id_216ba23b ON public.milestones_milestone USING btree (owner_id);
 :   DROP INDEX public.milestones_milestone_owner_id_216ba23b;
       public            taiga    false    241            �           1259    9777189 (   milestones_milestone_project_id_6151cb75    INDEX     o   CREATE INDEX milestones_milestone_project_id_6151cb75 ON public.milestones_milestone USING btree (project_id);
 <   DROP INDEX public.milestones_milestone_project_id_6151cb75;
       public            taiga    false    241            �           1259    9777186 "   milestones_milestone_slug_08e5995e    INDEX     c   CREATE INDEX milestones_milestone_slug_08e5995e ON public.milestones_milestone USING btree (slug);
 6   DROP INDEX public.milestones_milestone_slug_08e5995e;
       public            taiga    false    241            �           1259    9777187 '   milestones_milestone_slug_08e5995e_like    INDEX     |   CREATE INDEX milestones_milestone_slug_08e5995e_like ON public.milestones_milestone USING btree (slug varchar_pattern_ops);
 ;   DROP INDEX public.milestones_milestone_slug_08e5995e_like;
       public            taiga    false    241            �           1259    9777514 6   notifications_historycha_historyentry_id_ad550852_like    INDEX     �   CREATE INDEX notifications_historycha_historyentry_id_ad550852_like ON public.notifications_historychangenotification_history_entries USING btree (historyentry_id varchar_pattern_ops);
 J   DROP INDEX public.notifications_historycha_historyentry_id_ad550852_like;
       public            taiga    false    253            �           1259    9777512 >   notifications_historychang_historychangenotification__65e52ffd    INDEX     �   CREATE INDEX notifications_historychang_historychangenotification__65e52ffd ON public.notifications_historychangenotification_history_entries USING btree (historychangenotification_id);
 R   DROP INDEX public.notifications_historychang_historychangenotification__65e52ffd;
       public            taiga    false    253            �           1259    9777527 >   notifications_historychang_historychangenotification__d8e98e97    INDEX     �   CREATE INDEX notifications_historychang_historychangenotification__d8e98e97 ON public.notifications_historychangenotification_notify_users USING btree (historychangenotification_id);
 R   DROP INDEX public.notifications_historychang_historychangenotification__d8e98e97;
       public            taiga    false    255            �           1259    9777513 3   notifications_historychang_historyentry_id_ad550852    INDEX     �   CREATE INDEX notifications_historychang_historyentry_id_ad550852 ON public.notifications_historychangenotification_history_entries USING btree (historyentry_id);
 G   DROP INDEX public.notifications_historychang_historyentry_id_ad550852;
       public            taiga    false    253            �           1259    9777528 +   notifications_historychang_user_id_f7bd2448    INDEX     �   CREATE INDEX notifications_historychang_user_id_f7bd2448 ON public.notifications_historychangenotification_notify_users USING btree (user_id);
 ?   DROP INDEX public.notifications_historychang_user_id_f7bd2448;
       public            taiga    false    255            �           1259    9777498 9   notifications_historychangenotification_owner_id_6f63be8a    INDEX     �   CREATE INDEX notifications_historychangenotification_owner_id_6f63be8a ON public.notifications_historychangenotification USING btree (owner_id);
 M   DROP INDEX public.notifications_historychangenotification_owner_id_6f63be8a;
       public            taiga    false    251            �           1259    9777499 ;   notifications_historychangenotification_project_id_52cf5e2b    INDEX     �   CREATE INDEX notifications_historychangenotification_project_id_52cf5e2b ON public.notifications_historychangenotification USING btree (project_id);
 O   DROP INDEX public.notifications_historychangenotification_project_id_52cf5e2b;
       public            taiga    false    251            �           1259    9777441 .   notifications_notifypolicy_project_id_aa5da43f    INDEX     {   CREATE INDEX notifications_notifypolicy_project_id_aa5da43f ON public.notifications_notifypolicy USING btree (project_id);
 B   DROP INDEX public.notifications_notifypolicy_project_id_aa5da43f;
       public            taiga    false    249            �           1259    9777442 +   notifications_notifypolicy_user_id_2902cbeb    INDEX     u   CREATE INDEX notifications_notifypolicy_user_id_2902cbeb ON public.notifications_notifypolicy USING btree (user_id);
 ?   DROP INDEX public.notifications_notifypolicy_user_id_2902cbeb;
       public            taiga    false    249            �           1259    9777557 .   notifications_watched_content_type_id_7b3ab729    INDEX     {   CREATE INDEX notifications_watched_content_type_id_7b3ab729 ON public.notifications_watched USING btree (content_type_id);
 B   DROP INDEX public.notifications_watched_content_type_id_7b3ab729;
       public            taiga    false    257            �           1259    9777559 )   notifications_watched_project_id_c88baa46    INDEX     q   CREATE INDEX notifications_watched_project_id_c88baa46 ON public.notifications_watched USING btree (project_id);
 =   DROP INDEX public.notifications_watched_project_id_c88baa46;
       public            taiga    false    257            �           1259    9777558 &   notifications_watched_user_id_1bce1955    INDEX     k   CREATE INDEX notifications_watched_user_id_1bce1955 ON public.notifications_watched USING btree (user_id);
 :   DROP INDEX public.notifications_watched_user_id_1bce1955;
       public            taiga    false    257            e           1259    9778622 .   notifications_webnotification_created_b17f50f8    INDEX     {   CREATE INDEX notifications_webnotification_created_b17f50f8 ON public.notifications_webnotification USING btree (created);
 B   DROP INDEX public.notifications_webnotification_created_b17f50f8;
       public            taiga    false    310            h           1259    9778623 .   notifications_webnotification_user_id_f32287d5    INDEX     {   CREATE INDEX notifications_webnotification_user_id_f32287d5 ON public.notifications_webnotification USING btree (user_id);
 B   DROP INDEX public.notifications_webnotification_user_id_f32287d5;
       public            taiga    false    310            �           1259    9777918 '   projects_epicstatus_project_id_d2c43c29    INDEX     m   CREATE INDEX projects_epicstatus_project_id_d2c43c29 ON public.projects_epicstatus USING btree (project_id);
 ;   DROP INDEX public.projects_epicstatus_project_id_d2c43c29;
       public            taiga    false    269            �           1259    9777916 !   projects_epicstatus_slug_63c476c8    INDEX     a   CREATE INDEX projects_epicstatus_slug_63c476c8 ON public.projects_epicstatus USING btree (slug);
 5   DROP INDEX public.projects_epicstatus_slug_63c476c8;
       public            taiga    false    269            �           1259    9777917 &   projects_epicstatus_slug_63c476c8_like    INDEX     z   CREATE INDEX projects_epicstatus_slug_63c476c8_like ON public.projects_epicstatus USING btree (slug varchar_pattern_ops);
 :   DROP INDEX public.projects_epicstatus_slug_63c476c8_like;
       public            taiga    false    269            r           1259    9778682 )   projects_issueduedate_project_id_ec077eb7    INDEX     q   CREATE INDEX projects_issueduedate_project_id_ec077eb7 ON public.projects_issueduedate USING btree (project_id);
 =   DROP INDEX public.projects_issueduedate_project_id_ec077eb7;
       public            taiga    false    314            2           1259    9776967 (   projects_issuestatus_project_id_1988ebf4    INDEX     o   CREATE INDEX projects_issuestatus_project_id_1988ebf4 ON public.projects_issuestatus USING btree (project_id);
 <   DROP INDEX public.projects_issuestatus_project_id_1988ebf4;
       public            taiga    false    217            7           1259    9777700 "   projects_issuestatus_slug_2c528947    INDEX     c   CREATE INDEX projects_issuestatus_slug_2c528947 ON public.projects_issuestatus USING btree (slug);
 6   DROP INDEX public.projects_issuestatus_slug_2c528947;
       public            taiga    false    217            8           1259    9777701 '   projects_issuestatus_slug_2c528947_like    INDEX     |   CREATE INDEX projects_issuestatus_slug_2c528947_like ON public.projects_issuestatus USING btree (slug varchar_pattern_ops);
 ;   DROP INDEX public.projects_issuestatus_slug_2c528947_like;
       public            taiga    false    217            ;           1259    9776973 &   projects_issuetype_project_id_e831e4ae    INDEX     k   CREATE INDEX projects_issuetype_project_id_e831e4ae ON public.projects_issuetype USING btree (project_id);
 :   DROP INDEX public.projects_issuetype_project_id_e831e4ae;
       public            taiga    false    219            �           1259    9777412 *   projects_membership_invited_by_id_a2c6c913    INDEX     s   CREATE INDEX projects_membership_invited_by_id_a2c6c913 ON public.projects_membership USING btree (invited_by_id);
 >   DROP INDEX public.projects_membership_invited_by_id_a2c6c913;
       public            taiga    false    213            �           1259    9776853 '   projects_membership_project_id_5f65bf3f    INDEX     m   CREATE INDEX projects_membership_project_id_5f65bf3f ON public.projects_membership USING btree (project_id);
 ;   DROP INDEX public.projects_membership_project_id_5f65bf3f;
       public            taiga    false    213            �           1259    9776859 $   projects_membership_role_id_c4bd36ef    INDEX     g   CREATE INDEX projects_membership_role_id_c4bd36ef ON public.projects_membership USING btree (role_id);
 8   DROP INDEX public.projects_membership_role_id_c4bd36ef;
       public            taiga    false    213                        1259    9776847 $   projects_membership_user_id_13374535    INDEX     g   CREATE INDEX projects_membership_user_id_13374535 ON public.projects_membership USING btree (user_id);
 8   DROP INDEX public.projects_membership_user_id_13374535;
       public            taiga    false    213            @           1259    9776979 #   projects_points_project_id_3b8f7b42    INDEX     e   CREATE INDEX projects_points_project_id_3b8f7b42 ON public.projects_points USING btree (project_id);
 7   DROP INDEX public.projects_points_project_id_3b8f7b42;
       public            taiga    false    221            E           1259    9776985 %   projects_priority_project_id_936c75b2    INDEX     i   CREATE INDEX projects_priority_project_id_936c75b2 ON public.projects_priority USING btree (project_id);
 9   DROP INDEX public.projects_priority_project_id_936c75b2;
       public            taiga    false    223                       1259    9777005 .   projects_project_creation_template_id_b5a97819    INDEX     {   CREATE INDEX projects_project_creation_template_id_b5a97819 ON public.projects_project USING btree (creation_template_id);
 B   DROP INDEX public.projects_project_creation_template_id_b5a97819;
       public            taiga    false    215                       1259    9777929 (   projects_project_epics_csv_uuid_cb50f2ee    INDEX     o   CREATE INDEX projects_project_epics_csv_uuid_cb50f2ee ON public.projects_project USING btree (epics_csv_uuid);
 <   DROP INDEX public.projects_project_epics_csv_uuid_cb50f2ee;
       public            taiga    false    215                       1259    9777930 -   projects_project_epics_csv_uuid_cb50f2ee_like    INDEX     �   CREATE INDEX projects_project_epics_csv_uuid_cb50f2ee_like ON public.projects_project USING btree (epics_csv_uuid varchar_pattern_ops);
 A   DROP INDEX public.projects_project_epics_csv_uuid_cb50f2ee_like;
       public            taiga    false    215                       1259    9777734 )   projects_project_issues_csv_uuid_e6a84723    INDEX     q   CREATE INDEX projects_project_issues_csv_uuid_e6a84723 ON public.projects_project USING btree (issues_csv_uuid);
 =   DROP INDEX public.projects_project_issues_csv_uuid_e6a84723;
       public            taiga    false    215                       1259    9777735 .   projects_project_issues_csv_uuid_e6a84723_like    INDEX     �   CREATE INDEX projects_project_issues_csv_uuid_e6a84723_like ON public.projects_project USING btree (issues_csv_uuid varchar_pattern_ops);
 B   DROP INDEX public.projects_project_issues_csv_uuid_e6a84723_like;
       public            taiga    false    215                       1259    9777857 %   projects_project_name_id_44f44a5f_idx    INDEX     f   CREATE INDEX projects_project_name_id_44f44a5f_idx ON public.projects_project USING btree (name, id);
 9   DROP INDEX public.projects_project_name_id_44f44a5f_idx;
       public            taiga    false    215    215                       1259    9776841 "   projects_project_owner_id_b940de39    INDEX     c   CREATE INDEX projects_project_owner_id_b940de39 ON public.projects_project USING btree (owner_id);
 6   DROP INDEX public.projects_project_owner_id_b940de39;
       public            taiga    false    215                       1259    9776840 #   projects_project_slug_2d50067a_like    INDEX     t   CREATE INDEX projects_project_slug_2d50067a_like ON public.projects_project USING btree (slug varchar_pattern_ops);
 7   DROP INDEX public.projects_project_slug_2d50067a_like;
       public            taiga    false    215            !           1259    9777736 (   projects_project_tasks_csv_uuid_ecd0b1b5    INDEX     o   CREATE INDEX projects_project_tasks_csv_uuid_ecd0b1b5 ON public.projects_project USING btree (tasks_csv_uuid);
 <   DROP INDEX public.projects_project_tasks_csv_uuid_ecd0b1b5;
       public            taiga    false    215            "           1259    9777737 -   projects_project_tasks_csv_uuid_ecd0b1b5_like    INDEX     �   CREATE INDEX projects_project_tasks_csv_uuid_ecd0b1b5_like ON public.projects_project USING btree (tasks_csv_uuid varchar_pattern_ops);
 A   DROP INDEX public.projects_project_tasks_csv_uuid_ecd0b1b5_like;
       public            taiga    false    215            #           1259    9778642    projects_project_textquery_idx    INDEX     �  CREATE INDEX projects_project_textquery_idx ON public.projects_project USING gin ((((setweight(to_tsvector('simple'::regconfig, (COALESCE(name, ''::character varying))::text), 'A'::"char") || setweight(to_tsvector('simple'::regconfig, COALESCE(public.inmutable_array_to_string(tags), ''::text)), 'B'::"char")) || setweight(to_tsvector('simple'::regconfig, COALESCE(description, ''::text)), 'C'::"char"))));
 2   DROP INDEX public.projects_project_textquery_idx;
       public            taiga    false    215    215    364    215    215            $           1259    9777848 (   projects_project_total_activity_edf1a486    INDEX     o   CREATE INDEX projects_project_total_activity_edf1a486 ON public.projects_project USING btree (total_activity);
 <   DROP INDEX public.projects_project_total_activity_edf1a486;
       public            taiga    false    215            %           1259    9777849 3   projects_project_total_activity_last_month_669bff3e    INDEX     �   CREATE INDEX projects_project_total_activity_last_month_669bff3e ON public.projects_project USING btree (total_activity_last_month);
 G   DROP INDEX public.projects_project_total_activity_last_month_669bff3e;
       public            taiga    false    215            &           1259    9777850 2   projects_project_total_activity_last_week_961ca1b0    INDEX     �   CREATE INDEX projects_project_total_activity_last_week_961ca1b0 ON public.projects_project USING btree (total_activity_last_week);
 F   DROP INDEX public.projects_project_total_activity_last_week_961ca1b0;
       public            taiga    false    215            '           1259    9777851 2   projects_project_total_activity_last_year_12ea6dbe    INDEX     �   CREATE INDEX projects_project_total_activity_last_year_12ea6dbe ON public.projects_project USING btree (total_activity_last_year);
 F   DROP INDEX public.projects_project_total_activity_last_year_12ea6dbe;
       public            taiga    false    215            (           1259    9777852 $   projects_project_total_fans_436fe323    INDEX     g   CREATE INDEX projects_project_total_fans_436fe323 ON public.projects_project USING btree (total_fans);
 8   DROP INDEX public.projects_project_total_fans_436fe323;
       public            taiga    false    215            )           1259    9777853 /   projects_project_total_fans_last_month_455afdbb    INDEX     }   CREATE INDEX projects_project_total_fans_last_month_455afdbb ON public.projects_project USING btree (total_fans_last_month);
 C   DROP INDEX public.projects_project_total_fans_last_month_455afdbb;
       public            taiga    false    215            *           1259    9777854 .   projects_project_total_fans_last_week_c65146b1    INDEX     {   CREATE INDEX projects_project_total_fans_last_week_c65146b1 ON public.projects_project USING btree (total_fans_last_week);
 B   DROP INDEX public.projects_project_total_fans_last_week_c65146b1;
       public            taiga    false    215            +           1259    9777855 .   projects_project_total_fans_last_year_167b29c2    INDEX     {   CREATE INDEX projects_project_total_fans_last_year_167b29c2 ON public.projects_project USING btree (total_fans_last_year);
 B   DROP INDEX public.projects_project_total_fans_last_year_167b29c2;
       public            taiga    false    215            ,           1259    9777856 1   projects_project_totals_updated_datetime_1bcc5bfa    INDEX     �   CREATE INDEX projects_project_totals_updated_datetime_1bcc5bfa ON public.projects_project USING btree (totals_updated_datetime);
 E   DROP INDEX public.projects_project_totals_updated_datetime_1bcc5bfa;
       public            taiga    false    215            -           1259    9777738 .   projects_project_userstories_csv_uuid_6e83c6c1    INDEX     {   CREATE INDEX projects_project_userstories_csv_uuid_6e83c6c1 ON public.projects_project USING btree (userstories_csv_uuid);
 B   DROP INDEX public.projects_project_userstories_csv_uuid_6e83c6c1;
       public            taiga    false    215            .           1259    9777739 3   projects_project_userstories_csv_uuid_6e83c6c1_like    INDEX     �   CREATE INDEX projects_project_userstories_csv_uuid_6e83c6c1_like ON public.projects_project USING btree (userstories_csv_uuid varchar_pattern_ops);
 G   DROP INDEX public.projects_project_userstories_csv_uuid_6e83c6c1_like;
       public            taiga    false    215            /           1259    9778750 &   projects_project_workspace_id_7ea54f67    INDEX     k   CREATE INDEX projects_project_workspace_id_7ea54f67 ON public.projects_project USING btree (workspace_id);
 :   DROP INDEX public.projects_project_workspace_id_7ea54f67;
       public            taiga    false    215            J           1259    9776986 +   projects_projecttemplate_slug_2731738e_like    INDEX     �   CREATE INDEX projects_projecttemplate_slug_2731738e_like ON public.projects_projecttemplate USING btree (slug varchar_pattern_ops);
 ?   DROP INDEX public.projects_projecttemplate_slug_2731738e_like;
       public            taiga    false    225            O           1259    9776992 %   projects_severity_project_id_9ab920cd    INDEX     i   CREATE INDEX projects_severity_project_id_9ab920cd ON public.projects_severity USING btree (project_id);
 9   DROP INDEX public.projects_severity_project_id_9ab920cd;
       public            taiga    false    227            �           1259    9778718 %   projects_swimlane_project_id_06871cf8    INDEX     i   CREATE INDEX projects_swimlane_project_id_06871cf8 ON public.projects_swimlane USING btree (project_id);
 9   DROP INDEX public.projects_swimlane_project_id_06871cf8;
       public            taiga    false    320            �           1259    9778739 3   projects_swimlaneuserstorystatus_status_id_2f3fda91    INDEX     �   CREATE INDEX projects_swimlaneuserstorystatus_status_id_2f3fda91 ON public.projects_swimlaneuserstorystatus USING btree (status_id);
 G   DROP INDEX public.projects_swimlaneuserstorystatus_status_id_2f3fda91;
       public            taiga    false    322            �           1259    9778740 5   projects_swimlaneuserstorystatus_swimlane_id_1d3f2b21    INDEX     �   CREATE INDEX projects_swimlaneuserstorystatus_swimlane_id_1d3f2b21 ON public.projects_swimlaneuserstorystatus USING btree (swimlane_id);
 I   DROP INDEX public.projects_swimlaneuserstorystatus_swimlane_id_1d3f2b21;
       public            taiga    false    322            w           1259    9778688 (   projects_taskduedate_project_id_775d850d    INDEX     o   CREATE INDEX projects_taskduedate_project_id_775d850d ON public.projects_taskduedate USING btree (project_id);
 <   DROP INDEX public.projects_taskduedate_project_id_775d850d;
       public            taiga    false    316            T           1259    9776998 '   projects_taskstatus_project_id_8b32b2bb    INDEX     m   CREATE INDEX projects_taskstatus_project_id_8b32b2bb ON public.projects_taskstatus USING btree (project_id);
 ;   DROP INDEX public.projects_taskstatus_project_id_8b32b2bb;
       public            taiga    false    229            Y           1259    9777702 !   projects_taskstatus_slug_cf358ffa    INDEX     a   CREATE INDEX projects_taskstatus_slug_cf358ffa ON public.projects_taskstatus USING btree (slug);
 5   DROP INDEX public.projects_taskstatus_slug_cf358ffa;
       public            taiga    false    229            Z           1259    9777703 &   projects_taskstatus_slug_cf358ffa_like    INDEX     z   CREATE INDEX projects_taskstatus_slug_cf358ffa_like ON public.projects_taskstatus USING btree (slug varchar_pattern_ops);
 :   DROP INDEX public.projects_taskstatus_slug_cf358ffa_like;
       public            taiga    false    229            |           1259    9778694 -   projects_userstoryduedate_project_id_ab7b1680    INDEX     y   CREATE INDEX projects_userstoryduedate_project_id_ab7b1680 ON public.projects_userstoryduedate USING btree (project_id);
 A   DROP INDEX public.projects_userstoryduedate_project_id_ab7b1680;
       public            taiga    false    318            ]           1259    9777004 ,   projects_userstorystatus_project_id_cdf95c9c    INDEX     w   CREATE INDEX projects_userstorystatus_project_id_cdf95c9c ON public.projects_userstorystatus USING btree (project_id);
 @   DROP INDEX public.projects_userstorystatus_project_id_cdf95c9c;
       public            taiga    false    231            b           1259    9777704 &   projects_userstorystatus_slug_d574ed51    INDEX     k   CREATE INDEX projects_userstorystatus_slug_d574ed51 ON public.projects_userstorystatus USING btree (slug);
 :   DROP INDEX public.projects_userstorystatus_slug_d574ed51;
       public            taiga    false    231            c           1259    9777705 +   projects_userstorystatus_slug_d574ed51_like    INDEX     �   CREATE INDEX projects_userstorystatus_slug_d574ed51_like ON public.projects_userstorystatus USING btree (slug varchar_pattern_ops);
 ?   DROP INDEX public.projects_userstorystatus_slug_d574ed51_like;
       public            taiga    false    231            �           1259    9778778 -   references_reference_content_type_id_c134e05e    INDEX     y   CREATE INDEX references_reference_content_type_id_c134e05e ON public.references_reference USING btree (content_type_id);
 A   DROP INDEX public.references_reference_content_type_id_c134e05e;
       public            taiga    false    324            �           1259    9778779 (   references_reference_project_id_00275368    INDEX     o   CREATE INDEX references_reference_project_id_00275368 ON public.references_reference USING btree (project_id);
 <   DROP INDEX public.references_reference_project_id_00275368;
       public            taiga    false    324            �           1259    9778810 0   settings_userprojectsettings_project_id_0bc686ce    INDEX        CREATE INDEX settings_userprojectsettings_project_id_0bc686ce ON public.settings_userprojectsettings USING btree (project_id);
 D   DROP INDEX public.settings_userprojectsettings_project_id_0bc686ce;
       public            taiga    false    327            �           1259    9778811 -   settings_userprojectsettings_user_id_0e7fdc25    INDEX     y   CREATE INDEX settings_userprojectsettings_user_id_0e7fdc25 ON public.settings_userprojectsettings USING btree (user_id);
 A   DROP INDEX public.settings_userprojectsettings_user_id_0e7fdc25;
       public            taiga    false    327            �           1259    9777610 "   tasks_task_assigned_to_id_e8821f61    INDEX     c   CREATE INDEX tasks_task_assigned_to_id_e8821f61 ON public.tasks_task USING btree (assigned_to_id);
 6   DROP INDEX public.tasks_task_assigned_to_id_e8821f61;
       public            taiga    false    259            �           1259    9777611     tasks_task_milestone_id_64cc568f    INDEX     _   CREATE INDEX tasks_task_milestone_id_64cc568f ON public.tasks_task USING btree (milestone_id);
 4   DROP INDEX public.tasks_task_milestone_id_64cc568f;
       public            taiga    false    259            �           1259    9777612    tasks_task_owner_id_db3dcc3e    INDEX     W   CREATE INDEX tasks_task_owner_id_db3dcc3e ON public.tasks_task USING btree (owner_id);
 0   DROP INDEX public.tasks_task_owner_id_db3dcc3e;
       public            taiga    false    259            �           1259    9777613    tasks_task_project_id_a2815f0c    INDEX     [   CREATE INDEX tasks_task_project_id_a2815f0c ON public.tasks_task USING btree (project_id);
 2   DROP INDEX public.tasks_task_project_id_a2815f0c;
       public            taiga    false    259            �           1259    9777609    tasks_task_ref_9f55bd37    INDEX     M   CREATE INDEX tasks_task_ref_9f55bd37 ON public.tasks_task USING btree (ref);
 +   DROP INDEX public.tasks_task_ref_9f55bd37;
       public            taiga    false    259            �           1259    9777614    tasks_task_status_id_899d2b90    INDEX     Y   CREATE INDEX tasks_task_status_id_899d2b90 ON public.tasks_task USING btree (status_id);
 1   DROP INDEX public.tasks_task_status_id_899d2b90;
       public            taiga    false    259            �           1259    9777615 !   tasks_task_user_story_id_47ceaf1d    INDEX     a   CREATE INDEX tasks_task_user_story_id_47ceaf1d ON public.tasks_task USING btree (user_story_id);
 5   DROP INDEX public.tasks_task_user_story_id_47ceaf1d;
       public            taiga    false    259            �           1259    9778873    timeline_ti_content_1af26f_idx    INDEX     �   CREATE INDEX timeline_ti_content_1af26f_idx ON public.timeline_timeline USING btree (content_type_id, object_id, created DESC);
 2   DROP INDEX public.timeline_ti_content_1af26f_idx;
       public            taiga    false    265    265    265            �           1259    9778872    timeline_ti_namespa_89bca1_idx    INDEX     o   CREATE INDEX timeline_ti_namespa_89bca1_idx ON public.timeline_timeline USING btree (namespace, created DESC);
 2   DROP INDEX public.timeline_ti_namespa_89bca1_idx;
       public            taiga    false    265    265            �           1259    9777774 *   timeline_timeline_content_type_id_5731a0c6    INDEX     s   CREATE INDEX timeline_timeline_content_type_id_5731a0c6 ON public.timeline_timeline USING btree (content_type_id);
 >   DROP INDEX public.timeline_timeline_content_type_id_5731a0c6;
       public            taiga    false    265            �           1259    9778854 "   timeline_timeline_created_4e9e3a68    INDEX     c   CREATE INDEX timeline_timeline_created_4e9e3a68 ON public.timeline_timeline USING btree (created);
 6   DROP INDEX public.timeline_timeline_created_4e9e3a68;
       public            taiga    false    265            �           1259    9777773 /   timeline_timeline_data_content_type_id_0689742e    INDEX     }   CREATE INDEX timeline_timeline_data_content_type_id_0689742e ON public.timeline_timeline USING btree (data_content_type_id);
 C   DROP INDEX public.timeline_timeline_data_content_type_id_0689742e;
       public            taiga    false    265            �           1259    9777775 %   timeline_timeline_event_type_cb2fcdb2    INDEX     i   CREATE INDEX timeline_timeline_event_type_cb2fcdb2 ON public.timeline_timeline USING btree (event_type);
 9   DROP INDEX public.timeline_timeline_event_type_cb2fcdb2;
       public            taiga    false    265            �           1259    9777776 *   timeline_timeline_event_type_cb2fcdb2_like    INDEX     �   CREATE INDEX timeline_timeline_event_type_cb2fcdb2_like ON public.timeline_timeline USING btree (event_type varchar_pattern_ops);
 >   DROP INDEX public.timeline_timeline_event_type_cb2fcdb2_like;
       public            taiga    false    265            �           1259    9777778 $   timeline_timeline_namespace_26f217ed    INDEX     g   CREATE INDEX timeline_timeline_namespace_26f217ed ON public.timeline_timeline USING btree (namespace);
 8   DROP INDEX public.timeline_timeline_namespace_26f217ed;
       public            taiga    false    265            �           1259    9777779 )   timeline_timeline_namespace_26f217ed_like    INDEX     �   CREATE INDEX timeline_timeline_namespace_26f217ed_like ON public.timeline_timeline USING btree (namespace varchar_pattern_ops);
 =   DROP INDEX public.timeline_timeline_namespace_26f217ed_like;
       public            taiga    false    265            �           1259    9777772 %   timeline_timeline_project_id_58d5eadd    INDEX     i   CREATE INDEX timeline_timeline_project_id_58d5eadd ON public.timeline_timeline USING btree (project_id);
 9   DROP INDEX public.timeline_timeline_project_id_58d5eadd;
       public            taiga    false    265            �           1259    9778902 1   token_denylist_outstandingtoken_jti_70fa66b5_like    INDEX     �   CREATE INDEX token_denylist_outstandingtoken_jti_70fa66b5_like ON public.token_denylist_outstandingtoken USING btree (jti varchar_pattern_ops);
 E   DROP INDEX public.token_denylist_outstandingtoken_jti_70fa66b5_like;
       public            taiga    false    331            �           1259    9778903 0   token_denylist_outstandingtoken_user_id_c6f48986    INDEX        CREATE INDEX token_denylist_outstandingtoken_user_id_c6f48986 ON public.token_denylist_outstandingtoken USING btree (user_id);
 D   DROP INDEX public.token_denylist_outstandingtoken_user_id_c6f48986;
       public            taiga    false    331            �           1259    9777660    users_authdata_key_c3b89eef    INDEX     U   CREATE INDEX users_authdata_key_c3b89eef ON public.users_authdata USING btree (key);
 /   DROP INDEX public.users_authdata_key_c3b89eef;
       public            taiga    false    261            �           1259    9777661     users_authdata_key_c3b89eef_like    INDEX     n   CREATE INDEX users_authdata_key_c3b89eef_like ON public.users_authdata USING btree (key varchar_pattern_ops);
 4   DROP INDEX public.users_authdata_key_c3b89eef_like;
       public            taiga    false    261            �           1259    9777662    users_authdata_user_id_9625853a    INDEX     ]   CREATE INDEX users_authdata_user_id_9625853a ON public.users_authdata USING btree (user_id);
 3   DROP INDEX public.users_authdata_user_id_9625853a;
       public            taiga    false    261            �           1259    9777139    users_role_project_id_2837f877    INDEX     [   CREATE INDEX users_role_project_id_2837f877 ON public.users_role USING btree (project_id);
 2   DROP INDEX public.users_role_project_id_2837f877;
       public            taiga    false    211            �           1259    9776810    users_role_slug_ce33b471    INDEX     O   CREATE INDEX users_role_slug_ce33b471 ON public.users_role USING btree (slug);
 ,   DROP INDEX public.users_role_slug_ce33b471;
       public            taiga    false    211            �           1259    9776811    users_role_slug_ce33b471_like    INDEX     h   CREATE INDEX users_role_slug_ce33b471_like ON public.users_role USING btree (slug varchar_pattern_ops);
 1   DROP INDEX public.users_role_slug_ce33b471_like;
       public            taiga    false    211            �           1259    9777147    users_user_email_243f6e77_like    INDEX     j   CREATE INDEX users_user_email_243f6e77_like ON public.users_user USING btree (email varchar_pattern_ops);
 2   DROP INDEX public.users_user_email_243f6e77_like;
       public            taiga    false    207            �           1259    9778920    users_user_upper_idx    INDEX     ^   CREATE INDEX users_user_upper_idx ON public.users_user USING btree (upper('username'::text));
 (   DROP INDEX public.users_user_upper_idx;
       public            taiga    false    207            �           1259    9778921    users_user_upper_idx1    INDEX     \   CREATE INDEX users_user_upper_idx1 ON public.users_user USING btree (upper('email'::text));
 )   DROP INDEX public.users_user_upper_idx1;
       public            taiga    false    207            �           1259    9777150 !   users_user_username_06e46fe6_like    INDEX     p   CREATE INDEX users_user_username_06e46fe6_like ON public.users_user USING btree (username varchar_pattern_ops);
 5   DROP INDEX public.users_user_username_06e46fe6_like;
       public            taiga    false    207            �           1259    9778925    users_user_uuid_6fe513d7_like    INDEX     h   CREATE INDEX users_user_uuid_6fe513d7_like ON public.users_user USING btree (uuid varchar_pattern_ops);
 1   DROP INDEX public.users_user_uuid_6fe513d7_like;
       public            taiga    false    207            �           1259    9778949 !   users_workspacerole_slug_2db99758    INDEX     a   CREATE INDEX users_workspacerole_slug_2db99758 ON public.users_workspacerole USING btree (slug);
 5   DROP INDEX public.users_workspacerole_slug_2db99758;
       public            taiga    false    335            �           1259    9778950 &   users_workspacerole_slug_2db99758_like    INDEX     z   CREATE INDEX users_workspacerole_slug_2db99758_like ON public.users_workspacerole USING btree (slug varchar_pattern_ops);
 :   DROP INDEX public.users_workspacerole_slug_2db99758_like;
       public            taiga    false    335            �           1259    9778951 )   users_workspacerole_workspace_id_30155f00    INDEX     q   CREATE INDEX users_workspacerole_workspace_id_30155f00 ON public.users_workspacerole USING btree (workspace_id);
 =   DROP INDEX public.users_workspacerole_workspace_id_30155f00;
       public            taiga    false    335            �           1259    9778970 *   userstorage_storageentry_owner_id_c4c1ffc0    INDEX     s   CREATE INDEX userstorage_storageentry_owner_id_c4c1ffc0 ON public.userstorage_storageentry USING btree (owner_id);
 >   DROP INDEX public.userstorage_storageentry_owner_id_c4c1ffc0;
       public            taiga    false    337            �           1259    9777326 )   userstories_rolepoints_points_id_cfcc5a79    INDEX     q   CREATE INDEX userstories_rolepoints_points_id_cfcc5a79 ON public.userstories_rolepoints USING btree (points_id);
 =   DROP INDEX public.userstories_rolepoints_points_id_cfcc5a79;
       public            taiga    false    245            �           1259    9777327 '   userstories_rolepoints_role_id_94ac7663    INDEX     m   CREATE INDEX userstories_rolepoints_role_id_94ac7663 ON public.userstories_rolepoints USING btree (role_id);
 ;   DROP INDEX public.userstories_rolepoints_role_id_94ac7663;
       public            taiga    false    245            �           1259    9777379 -   userstories_rolepoints_user_story_id_ddb4c558    INDEX     y   CREATE INDEX userstories_rolepoints_user_story_id_ddb4c558 ON public.userstories_rolepoints USING btree (user_story_id);
 A   DROP INDEX public.userstories_rolepoints_user_story_id_ddb4c558;
       public            taiga    false    245            �           1259    9777359 -   userstories_userstory_assigned_to_id_5ba80653    INDEX     y   CREATE INDEX userstories_userstory_assigned_to_id_5ba80653 ON public.userstories_userstory USING btree (assigned_to_id);
 A   DROP INDEX public.userstories_userstory_assigned_to_id_5ba80653;
       public            taiga    false    247            �           1259    9779044 5   userstories_userstory_assigned_users_user_id_6de6e8a7    INDEX     �   CREATE INDEX userstories_userstory_assigned_users_user_id_6de6e8a7 ON public.userstories_userstory_assigned_users USING btree (user_id);
 I   DROP INDEX public.userstories_userstory_assigned_users_user_id_6de6e8a7;
       public            taiga    false    339            �           1259    9779043 :   userstories_userstory_assigned_users_userstory_id_fcb98e26    INDEX     �   CREATE INDEX userstories_userstory_assigned_users_userstory_id_fcb98e26 ON public.userstories_userstory_assigned_users USING btree (userstory_id);
 N   DROP INDEX public.userstories_userstory_assigned_users_userstory_id_fcb98e26;
       public            taiga    false    339            �           1259    9777360 6   userstories_userstory_generated_from_issue_id_afe43198    INDEX     �   CREATE INDEX userstories_userstory_generated_from_issue_id_afe43198 ON public.userstories_userstory USING btree (generated_from_issue_id);
 J   DROP INDEX public.userstories_userstory_generated_from_issue_id_afe43198;
       public            taiga    false    247            �           1259    9779045 5   userstories_userstory_generated_from_task_id_8e958d43    INDEX     �   CREATE INDEX userstories_userstory_generated_from_task_id_8e958d43 ON public.userstories_userstory USING btree (generated_from_task_id);
 I   DROP INDEX public.userstories_userstory_generated_from_task_id_8e958d43;
       public            taiga    false    247            �           1259    9777361 +   userstories_userstory_milestone_id_37f31d22    INDEX     u   CREATE INDEX userstories_userstory_milestone_id_37f31d22 ON public.userstories_userstory USING btree (milestone_id);
 ?   DROP INDEX public.userstories_userstory_milestone_id_37f31d22;
       public            taiga    false    247            �           1259    9777362 '   userstories_userstory_owner_id_df53c64e    INDEX     m   CREATE INDEX userstories_userstory_owner_id_df53c64e ON public.userstories_userstory USING btree (owner_id);
 ;   DROP INDEX public.userstories_userstory_owner_id_df53c64e;
       public            taiga    false    247            �           1259    9777363 )   userstories_userstory_project_id_03e85e9c    INDEX     q   CREATE INDEX userstories_userstory_project_id_03e85e9c ON public.userstories_userstory USING btree (project_id);
 =   DROP INDEX public.userstories_userstory_project_id_03e85e9c;
       public            taiga    false    247            �           1259    9777358 "   userstories_userstory_ref_824701c0    INDEX     c   CREATE INDEX userstories_userstory_ref_824701c0 ON public.userstories_userstory USING btree (ref);
 6   DROP INDEX public.userstories_userstory_ref_824701c0;
       public            taiga    false    247            �           1259    9777364 (   userstories_userstory_status_id_858671dd    INDEX     o   CREATE INDEX userstories_userstory_status_id_858671dd ON public.userstories_userstory USING btree (status_id);
 <   DROP INDEX public.userstories_userstory_status_id_858671dd;
       public            taiga    false    247            �           1259    9779056 *   userstories_userstory_swimlane_id_8ecab79d    INDEX     s   CREATE INDEX userstories_userstory_swimlane_id_8ecab79d ON public.userstories_userstory USING btree (swimlane_id);
 >   DROP INDEX public.userstories_userstory_swimlane_id_8ecab79d;
       public            taiga    false    247            �           1259    9779095 #   votes_vote_content_type_id_c8375fe1    INDEX     e   CREATE INDEX votes_vote_content_type_id_c8375fe1 ON public.votes_vote USING btree (content_type_id);
 7   DROP INDEX public.votes_vote_content_type_id_c8375fe1;
       public            taiga    false    341            �           1259    9779096    votes_vote_user_id_24a74629    INDEX     U   CREATE INDEX votes_vote_user_id_24a74629 ON public.votes_vote USING btree (user_id);
 /   DROP INDEX public.votes_vote_user_id_24a74629;
       public            taiga    false    341            �           1259    9779102 $   votes_votes_content_type_id_29583576    INDEX     g   CREATE INDEX votes_votes_content_type_id_29583576 ON public.votes_votes USING btree (content_type_id);
 8   DROP INDEX public.votes_votes_content_type_id_29583576;
       public            taiga    false    343            �           1259    9779136 $   webhooks_webhook_project_id_76846b5e    INDEX     g   CREATE INDEX webhooks_webhook_project_id_76846b5e ON public.webhooks_webhook USING btree (project_id);
 8   DROP INDEX public.webhooks_webhook_project_id_76846b5e;
       public            taiga    false    345            �           1259    9779142 '   webhooks_webhooklog_webhook_id_646c2008    INDEX     m   CREATE INDEX webhooks_webhooklog_webhook_id_646c2008 ON public.webhooks_webhooklog USING btree (webhook_id);
 ;   DROP INDEX public.webhooks_webhooklog_webhook_id_646c2008;
       public            taiga    false    347            �           1259    9778039    wiki_wikilink_href_46ee8855    INDEX     U   CREATE INDEX wiki_wikilink_href_46ee8855 ON public.wiki_wikilink USING btree (href);
 /   DROP INDEX public.wiki_wikilink_href_46ee8855;
       public            taiga    false    273            �           1259    9778040     wiki_wikilink_href_46ee8855_like    INDEX     n   CREATE INDEX wiki_wikilink_href_46ee8855_like ON public.wiki_wikilink USING btree (href varchar_pattern_ops);
 4   DROP INDEX public.wiki_wikilink_href_46ee8855_like;
       public            taiga    false    273            �           1259    9778041 !   wiki_wikilink_project_id_7dc700d7    INDEX     a   CREATE INDEX wiki_wikilink_project_id_7dc700d7 ON public.wiki_wikilink USING btree (project_id);
 5   DROP INDEX public.wiki_wikilink_project_id_7dc700d7;
       public            taiga    false    273            �           1259    9778059 '   wiki_wikipage_last_modifier_id_38be071c    INDEX     m   CREATE INDEX wiki_wikipage_last_modifier_id_38be071c ON public.wiki_wikipage USING btree (last_modifier_id);
 ;   DROP INDEX public.wiki_wikipage_last_modifier_id_38be071c;
       public            taiga    false    275            �           1259    9778060    wiki_wikipage_owner_id_f1f6c5fd    INDEX     ]   CREATE INDEX wiki_wikipage_owner_id_f1f6c5fd ON public.wiki_wikipage USING btree (owner_id);
 3   DROP INDEX public.wiki_wikipage_owner_id_f1f6c5fd;
       public            taiga    false    275                       1259    9778061 !   wiki_wikipage_project_id_03a1e2ca    INDEX     a   CREATE INDEX wiki_wikipage_project_id_03a1e2ca ON public.wiki_wikipage USING btree (project_id);
 5   DROP INDEX public.wiki_wikipage_project_id_03a1e2ca;
       public            taiga    false    275                       1259    9778057    wiki_wikipage_slug_10d80dc1    INDEX     U   CREATE INDEX wiki_wikipage_slug_10d80dc1 ON public.wiki_wikipage USING btree (slug);
 /   DROP INDEX public.wiki_wikipage_slug_10d80dc1;
       public            taiga    false    275                       1259    9778058     wiki_wikipage_slug_10d80dc1_like    INDEX     n   CREATE INDEX wiki_wikipage_slug_10d80dc1_like ON public.wiki_wikipage USING btree (slug varchar_pattern_ops);
 4   DROP INDEX public.wiki_wikipage_slug_10d80dc1_like;
       public            taiga    false    275            i           1259    9778641 )   workspaces_workspace_name_id_69b27cd8_idx    INDEX     n   CREATE INDEX workspaces_workspace_name_id_69b27cd8_idx ON public.workspaces_workspace USING btree (name, id);
 =   DROP INDEX public.workspaces_workspace_name_id_69b27cd8_idx;
       public            taiga    false    312    312            j           1259    9778640 &   workspaces_workspace_owner_id_d8b120c0    INDEX     k   CREATE INDEX workspaces_workspace_owner_id_d8b120c0 ON public.workspaces_workspace USING btree (owner_id);
 :   DROP INDEX public.workspaces_workspace_owner_id_d8b120c0;
       public            taiga    false    312            m           1259    9778639 '   workspaces_workspace_slug_c37054a2_like    INDEX     |   CREATE INDEX workspaces_workspace_slug_c37054a2_like ON public.workspaces_workspace USING btree (slug varchar_pattern_ops);
 ;   DROP INDEX public.workspaces_workspace_slug_c37054a2_like;
       public            taiga    false    312            �           1259    9779197 /   workspaces_workspacemembership_user_id_091e94f3    INDEX     }   CREATE INDEX workspaces_workspacemembership_user_id_091e94f3 ON public.workspaces_workspacemembership USING btree (user_id);
 C   DROP INDEX public.workspaces_workspacemembership_user_id_091e94f3;
       public            taiga    false    349            �           1259    9779198 4   workspaces_workspacemembership_workspace_id_d634b215    INDEX     �   CREATE INDEX workspaces_workspacemembership_workspace_id_d634b215 ON public.workspaces_workspacemembership USING btree (workspace_id);
 H   DROP INDEX public.workspaces_workspacemembership_workspace_id_d634b215;
       public            taiga    false    349            �           1259    9779199 9   workspaces_workspacemembership_workspace_role_id_39c459bf    INDEX     �   CREATE INDEX workspaces_workspacemembership_workspace_role_id_39c459bf ON public.workspaces_workspacemembership USING btree (workspace_role_id);
 M   DROP INDEX public.workspaces_workspacemembership_workspace_role_id_39c459bf;
       public            taiga    false    349            \           2620    9778339 ^   custom_attributes_epiccustomattribute update_epiccustomvalues_after_remove_epiccustomattribute    TRIGGER       CREATE TRIGGER update_epiccustomvalues_after_remove_epiccustomattribute AFTER DELETE ON public.custom_attributes_epiccustomattribute FOR EACH ROW EXECUTE FUNCTION public.clean_key_in_custom_attributes_values('epic_id', 'epics_epic', 'custom_attributes_epiccustomattributesvalues');
 w   DROP TRIGGER update_epiccustomvalues_after_remove_epiccustomattribute ON public.custom_attributes_epiccustomattribute;
       public          taiga    false    381    294            Y           2620    9778308 a   custom_attributes_issuecustomattribute update_issuecustomvalues_after_remove_issuecustomattribute    TRIGGER     !  CREATE TRIGGER update_issuecustomvalues_after_remove_issuecustomattribute AFTER DELETE ON public.custom_attributes_issuecustomattribute FOR EACH ROW EXECUTE FUNCTION public.clean_key_in_custom_attributes_values('issue_id', 'issues_issue', 'custom_attributes_issuecustomattributesvalues');
 z   DROP TRIGGER update_issuecustomvalues_after_remove_issuecustomattribute ON public.custom_attributes_issuecustomattribute;
       public          taiga    false    381    282            X           2620    9778148 4   epics_epic update_project_tags_colors_on_epic_insert    TRIGGER     �   CREATE TRIGGER update_project_tags_colors_on_epic_insert AFTER INSERT ON public.epics_epic FOR EACH ROW EXECUTE FUNCTION public.update_project_tags_colors();
 M   DROP TRIGGER update_project_tags_colors_on_epic_insert ON public.epics_epic;
       public          taiga    false    278    367            W           2620    9778147 4   epics_epic update_project_tags_colors_on_epic_update    TRIGGER     �   CREATE TRIGGER update_project_tags_colors_on_epic_update AFTER UPDATE ON public.epics_epic FOR EACH ROW EXECUTE FUNCTION public.update_project_tags_colors();
 M   DROP TRIGGER update_project_tags_colors_on_epic_update ON public.epics_epic;
       public          taiga    false    367    278            R           2620    9777895 7   issues_issue update_project_tags_colors_on_issue_insert    TRIGGER     �   CREATE TRIGGER update_project_tags_colors_on_issue_insert AFTER INSERT ON public.issues_issue FOR EACH ROW EXECUTE FUNCTION public.update_project_tags_colors();
 P   DROP TRIGGER update_project_tags_colors_on_issue_insert ON public.issues_issue;
       public          taiga    false    367    243            Q           2620    9777894 7   issues_issue update_project_tags_colors_on_issue_update    TRIGGER     �   CREATE TRIGGER update_project_tags_colors_on_issue_update AFTER UPDATE ON public.issues_issue FOR EACH ROW EXECUTE FUNCTION public.update_project_tags_colors();
 P   DROP TRIGGER update_project_tags_colors_on_issue_update ON public.issues_issue;
       public          taiga    false    243    367            V           2620    9777893 4   tasks_task update_project_tags_colors_on_task_insert    TRIGGER     �   CREATE TRIGGER update_project_tags_colors_on_task_insert AFTER INSERT ON public.tasks_task FOR EACH ROW EXECUTE FUNCTION public.update_project_tags_colors();
 M   DROP TRIGGER update_project_tags_colors_on_task_insert ON public.tasks_task;
       public          taiga    false    367    259            U           2620    9777892 4   tasks_task update_project_tags_colors_on_task_update    TRIGGER     �   CREATE TRIGGER update_project_tags_colors_on_task_update AFTER UPDATE ON public.tasks_task FOR EACH ROW EXECUTE FUNCTION public.update_project_tags_colors();
 M   DROP TRIGGER update_project_tags_colors_on_task_update ON public.tasks_task;
       public          taiga    false    367    259            T           2620    9777891 D   userstories_userstory update_project_tags_colors_on_userstory_insert    TRIGGER     �   CREATE TRIGGER update_project_tags_colors_on_userstory_insert AFTER INSERT ON public.userstories_userstory FOR EACH ROW EXECUTE FUNCTION public.update_project_tags_colors();
 ]   DROP TRIGGER update_project_tags_colors_on_userstory_insert ON public.userstories_userstory;
       public          taiga    false    367    247            S           2620    9777890 D   userstories_userstory update_project_tags_colors_on_userstory_update    TRIGGER     �   CREATE TRIGGER update_project_tags_colors_on_userstory_update AFTER UPDATE ON public.userstories_userstory FOR EACH ROW EXECUTE FUNCTION public.update_project_tags_colors();
 ]   DROP TRIGGER update_project_tags_colors_on_userstory_update ON public.userstories_userstory;
       public          taiga    false    247    367            Z           2620    9778307 ^   custom_attributes_taskcustomattribute update_taskcustomvalues_after_remove_taskcustomattribute    TRIGGER       CREATE TRIGGER update_taskcustomvalues_after_remove_taskcustomattribute AFTER DELETE ON public.custom_attributes_taskcustomattribute FOR EACH ROW EXECUTE FUNCTION public.clean_key_in_custom_attributes_values('task_id', 'tasks_task', 'custom_attributes_taskcustomattributesvalues');
 w   DROP TRIGGER update_taskcustomvalues_after_remove_taskcustomattribute ON public.custom_attributes_taskcustomattribute;
       public          taiga    false    381    284            [           2620    9778306 j   custom_attributes_userstorycustomattribute update_userstorycustomvalues_after_remove_userstorycustomattrib    TRIGGER     <  CREATE TRIGGER update_userstorycustomvalues_after_remove_userstorycustomattrib AFTER DELETE ON public.custom_attributes_userstorycustomattribute FOR EACH ROW EXECUTE FUNCTION public.clean_key_in_custom_attributes_values('user_story_id', 'userstories_userstory', 'custom_attributes_userstorycustomattributesvalues');
 �   DROP TRIGGER update_userstorycustomvalues_after_remove_userstorycustomattrib ON public.custom_attributes_userstorycustomattribute;
       public          taiga    false    286    381            �           2606    9777058 Q   attachments_attachment attachments_attachme_content_type_id_35dd9d5d_fk_django_co    FK CONSTRAINT     �   ALTER TABLE ONLY public.attachments_attachment
    ADD CONSTRAINT attachments_attachme_content_type_id_35dd9d5d_fk_django_co FOREIGN KEY (content_type_id) REFERENCES public.django_content_type(id) DEFERRABLE INITIALLY DEFERRED;
 {   ALTER TABLE ONLY public.attachments_attachment DROP CONSTRAINT attachments_attachme_content_type_id_35dd9d5d_fk_django_co;
       public          taiga    false    4066    233    205            �           2606    9777068 L   attachments_attachment attachments_attachme_project_id_50714f52_fk_projects_    FK CONSTRAINT     �   ALTER TABLE ONLY public.attachments_attachment
    ADD CONSTRAINT attachments_attachme_project_id_50714f52_fk_projects_ FOREIGN KEY (project_id) REFERENCES public.projects_project(id) DEFERRABLE INITIALLY DEFERRED;
 v   ALTER TABLE ONLY public.attachments_attachment DROP CONSTRAINT attachments_attachme_project_id_50714f52_fk_projects_;
       public          taiga    false    233    4125    215            �           2606    9777077 P   attachments_attachment attachments_attachment_owner_id_720defb8_fk_users_user_id    FK CONSTRAINT     �   ALTER TABLE ONLY public.attachments_attachment
    ADD CONSTRAINT attachments_attachment_owner_id_720defb8_fk_users_user_id FOREIGN KEY (owner_id) REFERENCES public.users_user(id) DEFERRABLE INITIALLY DEFERRED;
 z   ALTER TABLE ONLY public.attachments_attachment DROP CONSTRAINT attachments_attachment_owner_id_720defb8_fk_users_user_id;
       public          taiga    false    207    233    4071            �           2606    9777125 O   auth_group_permissions auth_group_permissio_permission_id_84c5c92e_fk_auth_perm    FK CONSTRAINT     �   ALTER TABLE ONLY public.auth_group_permissions
    ADD CONSTRAINT auth_group_permissio_permission_id_84c5c92e_fk_auth_perm FOREIGN KEY (permission_id) REFERENCES public.auth_permission(id) DEFERRABLE INITIALLY DEFERRED;
 y   ALTER TABLE ONLY public.auth_group_permissions DROP CONSTRAINT auth_group_permissio_permission_id_84c5c92e_fk_auth_perm;
       public          taiga    false    235    4206    239            �           2606    9777120 P   auth_group_permissions auth_group_permissions_group_id_b120cbf9_fk_auth_group_id    FK CONSTRAINT     �   ALTER TABLE ONLY public.auth_group_permissions
    ADD CONSTRAINT auth_group_permissions_group_id_b120cbf9_fk_auth_group_id FOREIGN KEY (group_id) REFERENCES public.auth_group(id) DEFERRABLE INITIALLY DEFERRED;
 z   ALTER TABLE ONLY public.auth_group_permissions DROP CONSTRAINT auth_group_permissions_group_id_b120cbf9_fk_auth_group_id;
       public          taiga    false    237    239    4211            �           2606    9777111 E   auth_permission auth_permission_content_type_id_2f476e4b_fk_django_co    FK CONSTRAINT     �   ALTER TABLE ONLY public.auth_permission
    ADD CONSTRAINT auth_permission_content_type_id_2f476e4b_fk_django_co FOREIGN KEY (content_type_id) REFERENCES public.django_content_type(id) DEFERRABLE INITIALLY DEFERRED;
 o   ALTER TABLE ONLY public.auth_permission DROP CONSTRAINT auth_permission_content_type_id_2f476e4b_fk_django_co;
       public          taiga    false    4066    205    235                       2606    9777987 T   contact_contactentry contact_contactentry_project_id_27bfec4e_fk_projects_project_id    FK CONSTRAINT     �   ALTER TABLE ONLY public.contact_contactentry
    ADD CONSTRAINT contact_contactentry_project_id_27bfec4e_fk_projects_project_id FOREIGN KEY (project_id) REFERENCES public.projects_project(id) DEFERRABLE INITIALLY DEFERRED;
 ~   ALTER TABLE ONLY public.contact_contactentry DROP CONSTRAINT contact_contactentry_project_id_27bfec4e_fk_projects_project_id;
       public          taiga    false    215    271    4125                       2606    9777992 K   contact_contactentry contact_contactentry_user_id_f1f19c5f_fk_users_user_id    FK CONSTRAINT     �   ALTER TABLE ONLY public.contact_contactentry
    ADD CONSTRAINT contact_contactentry_user_id_f1f19c5f_fk_users_user_id FOREIGN KEY (user_id) REFERENCES public.users_user(id) DEFERRABLE INITIALLY DEFERRED;
 u   ALTER TABLE ONLY public.contact_contactentry DROP CONSTRAINT contact_contactentry_user_id_f1f19c5f_fk_users_user_id;
       public          taiga    false    207    271    4071            2           2606    9778346 _   custom_attributes_epiccustomattributesvalues custom_attributes_ep_epic_id_d413e57a_fk_epics_epi    FK CONSTRAINT     �   ALTER TABLE ONLY public.custom_attributes_epiccustomattributesvalues
    ADD CONSTRAINT custom_attributes_ep_epic_id_d413e57a_fk_epics_epi FOREIGN KEY (epic_id) REFERENCES public.epics_epic(id) DEFERRABLE INITIALLY DEFERRED;
 �   ALTER TABLE ONLY public.custom_attributes_epiccustomattributesvalues DROP CONSTRAINT custom_attributes_ep_epic_id_d413e57a_fk_epics_epi;
       public          taiga    false    4367    278    296            1           2606    9778340 [   custom_attributes_epiccustomattribute custom_attributes_ep_project_id_ad2cfaa8_fk_projects_    FK CONSTRAINT     �   ALTER TABLE ONLY public.custom_attributes_epiccustomattribute
    ADD CONSTRAINT custom_attributes_ep_project_id_ad2cfaa8_fk_projects_ FOREIGN KEY (project_id) REFERENCES public.projects_project(id) DEFERRABLE INITIALLY DEFERRED;
 �   ALTER TABLE ONLY public.custom_attributes_epiccustomattribute DROP CONSTRAINT custom_attributes_ep_project_id_ad2cfaa8_fk_projects_;
       public          taiga    false    215    294    4125            .           2606    9778283 a   custom_attributes_issuecustomattributesvalues custom_attributes_is_issue_id_868161f8_fk_issues_is    FK CONSTRAINT     �   ALTER TABLE ONLY public.custom_attributes_issuecustomattributesvalues
    ADD CONSTRAINT custom_attributes_is_issue_id_868161f8_fk_issues_is FOREIGN KEY (issue_id) REFERENCES public.issues_issue(id) DEFERRABLE INITIALLY DEFERRED;
 �   ALTER TABLE ONLY public.custom_attributes_issuecustomattributesvalues DROP CONSTRAINT custom_attributes_is_issue_id_868161f8_fk_issues_is;
       public          taiga    false    4234    288    243            +           2606    9778226 \   custom_attributes_issuecustomattribute custom_attributes_is_project_id_3b4acff5_fk_projects_    FK CONSTRAINT     �   ALTER TABLE ONLY public.custom_attributes_issuecustomattribute
    ADD CONSTRAINT custom_attributes_is_project_id_3b4acff5_fk_projects_ FOREIGN KEY (project_id) REFERENCES public.projects_project(id) DEFERRABLE INITIALLY DEFERRED;
 �   ALTER TABLE ONLY public.custom_attributes_issuecustomattribute DROP CONSTRAINT custom_attributes_is_project_id_3b4acff5_fk_projects_;
       public          taiga    false    4125    215    282            ,           2606    9778232 [   custom_attributes_taskcustomattribute custom_attributes_ta_project_id_f0f622a8_fk_projects_    FK CONSTRAINT     �   ALTER TABLE ONLY public.custom_attributes_taskcustomattribute
    ADD CONSTRAINT custom_attributes_ta_project_id_f0f622a8_fk_projects_ FOREIGN KEY (project_id) REFERENCES public.projects_project(id) DEFERRABLE INITIALLY DEFERRED;
 �   ALTER TABLE ONLY public.custom_attributes_taskcustomattribute DROP CONSTRAINT custom_attributes_ta_project_id_f0f622a8_fk_projects_;
       public          taiga    false    284    215    4125            /           2606    9778288 _   custom_attributes_taskcustomattributesvalues custom_attributes_ta_task_id_3d1ccf5e_fk_tasks_tas    FK CONSTRAINT     �   ALTER TABLE ONLY public.custom_attributes_taskcustomattributesvalues
    ADD CONSTRAINT custom_attributes_ta_task_id_3d1ccf5e_fk_tasks_tas FOREIGN KEY (task_id) REFERENCES public.tasks_task(id) DEFERRABLE INITIALLY DEFERRED;
 �   ALTER TABLE ONLY public.custom_attributes_taskcustomattributesvalues DROP CONSTRAINT custom_attributes_ta_task_id_3d1ccf5e_fk_tasks_tas;
       public          taiga    false    4295    290    259            -           2606    9778238 `   custom_attributes_userstorycustomattribute custom_attributes_us_project_id_2619cf6c_fk_projects_    FK CONSTRAINT     �   ALTER TABLE ONLY public.custom_attributes_userstorycustomattribute
    ADD CONSTRAINT custom_attributes_us_project_id_2619cf6c_fk_projects_ FOREIGN KEY (project_id) REFERENCES public.projects_project(id) DEFERRABLE INITIALLY DEFERRED;
 �   ALTER TABLE ONLY public.custom_attributes_userstorycustomattribute DROP CONSTRAINT custom_attributes_us_project_id_2619cf6c_fk_projects_;
       public          taiga    false    4125    215    286            0           2606    9778293 j   custom_attributes_userstorycustomattributesvalues custom_attributes_us_user_story_id_99b10c43_fk_userstori    FK CONSTRAINT     �   ALTER TABLE ONLY public.custom_attributes_userstorycustomattributesvalues
    ADD CONSTRAINT custom_attributes_us_user_story_id_99b10c43_fk_userstori FOREIGN KEY (user_story_id) REFERENCES public.userstories_userstory(id) DEFERRABLE INITIALLY DEFERRED;
 �   ALTER TABLE ONLY public.custom_attributes_userstorycustomattributesvalues DROP CONSTRAINT custom_attributes_us_user_story_id_99b10c43_fk_userstori;
       public          taiga    false    247    4254    292            �           2606    9776787 G   django_admin_log django_admin_log_content_type_id_c4bce8eb_fk_django_co    FK CONSTRAINT     �   ALTER TABLE ONLY public.django_admin_log
    ADD CONSTRAINT django_admin_log_content_type_id_c4bce8eb_fk_django_co FOREIGN KEY (content_type_id) REFERENCES public.django_content_type(id) DEFERRABLE INITIALLY DEFERRED;
 q   ALTER TABLE ONLY public.django_admin_log DROP CONSTRAINT django_admin_log_content_type_id_c4bce8eb_fk_django_co;
       public          taiga    false    4066    209    205            �           2606    9776792 C   django_admin_log django_admin_log_user_id_c564eba6_fk_users_user_id    FK CONSTRAINT     �   ALTER TABLE ONLY public.django_admin_log
    ADD CONSTRAINT django_admin_log_user_id_c564eba6_fk_users_user_id FOREIGN KEY (user_id) REFERENCES public.users_user(id) DEFERRABLE INITIALLY DEFERRED;
 m   ALTER TABLE ONLY public.django_admin_log DROP CONSTRAINT django_admin_log_user_id_c564eba6_fk_users_user_id;
       public          taiga    false    4071    207    209            3           2606    9778457 N   easy_thumbnails_thumbnail easy_thumbnails_thum_source_id_5b57bc77_fk_easy_thum    FK CONSTRAINT     �   ALTER TABLE ONLY public.easy_thumbnails_thumbnail
    ADD CONSTRAINT easy_thumbnails_thum_source_id_5b57bc77_fk_easy_thum FOREIGN KEY (source_id) REFERENCES public.easy_thumbnails_source(id) DEFERRABLE INITIALLY DEFERRED;
 x   ALTER TABLE ONLY public.easy_thumbnails_thumbnail DROP CONSTRAINT easy_thumbnails_thum_source_id_5b57bc77_fk_easy_thum;
       public          taiga    false    301    299    4423            4           2606    9778479 [   easy_thumbnails_thumbnaildimensions easy_thumbnails_thum_thumbnail_id_c3a0c549_fk_easy_thum    FK CONSTRAINT     �   ALTER TABLE ONLY public.easy_thumbnails_thumbnaildimensions
    ADD CONSTRAINT easy_thumbnails_thum_thumbnail_id_c3a0c549_fk_easy_thum FOREIGN KEY (thumbnail_id) REFERENCES public.easy_thumbnails_thumbnail(id) DEFERRABLE INITIALLY DEFERRED;
 �   ALTER TABLE ONLY public.easy_thumbnails_thumbnaildimensions DROP CONSTRAINT easy_thumbnails_thum_thumbnail_id_c3a0c549_fk_easy_thum;
       public          taiga    false    303    4433    301            %           2606    9778505 >   epics_epic epics_epic_assigned_to_id_13e08004_fk_users_user_id    FK CONSTRAINT     �   ALTER TABLE ONLY public.epics_epic
    ADD CONSTRAINT epics_epic_assigned_to_id_13e08004_fk_users_user_id FOREIGN KEY (assigned_to_id) REFERENCES public.users_user(id) DEFERRABLE INITIALLY DEFERRED;
 h   ALTER TABLE ONLY public.epics_epic DROP CONSTRAINT epics_epic_assigned_to_id_13e08004_fk_users_user_id;
       public          taiga    false    207    4071    278            &           2606    9778154 8   epics_epic epics_epic_owner_id_b09888c4_fk_users_user_id    FK CONSTRAINT     �   ALTER TABLE ONLY public.epics_epic
    ADD CONSTRAINT epics_epic_owner_id_b09888c4_fk_users_user_id FOREIGN KEY (owner_id) REFERENCES public.users_user(id) DEFERRABLE INITIALLY DEFERRED;
 b   ALTER TABLE ONLY public.epics_epic DROP CONSTRAINT epics_epic_owner_id_b09888c4_fk_users_user_id;
       public          taiga    false    278    4071    207            '           2606    9778159 @   epics_epic epics_epic_project_id_d98aaef7_fk_projects_project_id    FK CONSTRAINT     �   ALTER TABLE ONLY public.epics_epic
    ADD CONSTRAINT epics_epic_project_id_d98aaef7_fk_projects_project_id FOREIGN KEY (project_id) REFERENCES public.projects_project(id) DEFERRABLE INITIALLY DEFERRED;
 j   ALTER TABLE ONLY public.epics_epic DROP CONSTRAINT epics_epic_project_id_d98aaef7_fk_projects_project_id;
       public          taiga    false    4125    215    278            (           2606    9778164 B   epics_epic epics_epic_status_id_4cf3af1a_fk_projects_epicstatus_id    FK CONSTRAINT     �   ALTER TABLE ONLY public.epics_epic
    ADD CONSTRAINT epics_epic_status_id_4cf3af1a_fk_projects_epicstatus_id FOREIGN KEY (status_id) REFERENCES public.projects_epicstatus(id) DEFERRABLE INITIALLY DEFERRED;
 l   ALTER TABLE ONLY public.epics_epic DROP CONSTRAINT epics_epic_status_id_4cf3af1a_fk_projects_epicstatus_id;
       public          taiga    false    4330    269    278            )           2606    9778179 O   epics_relateduserstory epics_relatedusersto_user_story_id_329a951c_fk_userstori    FK CONSTRAINT     �   ALTER TABLE ONLY public.epics_relateduserstory
    ADD CONSTRAINT epics_relatedusersto_user_story_id_329a951c_fk_userstori FOREIGN KEY (user_story_id) REFERENCES public.userstories_userstory(id) DEFERRABLE INITIALLY DEFERRED;
 y   ALTER TABLE ONLY public.epics_relateduserstory DROP CONSTRAINT epics_relatedusersto_user_story_id_329a951c_fk_userstori;
       public          taiga    false    280    4254    247            *           2606    9778174 O   epics_relateduserstory epics_relateduserstory_epic_id_57605230_fk_epics_epic_id    FK CONSTRAINT     �   ALTER TABLE ONLY public.epics_relateduserstory
    ADD CONSTRAINT epics_relateduserstory_epic_id_57605230_fk_epics_epic_id FOREIGN KEY (epic_id) REFERENCES public.epics_epic(id) DEFERRABLE INITIALLY DEFERRED;
 y   ALTER TABLE ONLY public.epics_relateduserstory DROP CONSTRAINT epics_relateduserstory_epic_id_57605230_fk_epics_epic_id;
       public          taiga    false    4367    278    280            5           2606    9778532 X   external_apps_applicationtoken external_apps_applic_application_id_0e934655_fk_external_    FK CONSTRAINT     �   ALTER TABLE ONLY public.external_apps_applicationtoken
    ADD CONSTRAINT external_apps_applic_application_id_0e934655_fk_external_ FOREIGN KEY (application_id) REFERENCES public.external_apps_application(id) DEFERRABLE INITIALLY DEFERRED;
 �   ALTER TABLE ONLY public.external_apps_applicationtoken DROP CONSTRAINT external_apps_applic_application_id_0e934655_fk_external_;
       public          taiga    false    306    304    4443            6           2606    9778537 Q   external_apps_applicationtoken external_apps_applic_user_id_6e2f1e8a_fk_users_use    FK CONSTRAINT     �   ALTER TABLE ONLY public.external_apps_applicationtoken
    ADD CONSTRAINT external_apps_applic_user_id_6e2f1e8a_fk_users_use FOREIGN KEY (user_id) REFERENCES public.users_user(id) DEFERRABLE INITIALLY DEFERRED;
 {   ALTER TABLE ONLY public.external_apps_applicationtoken DROP CONSTRAINT external_apps_applic_user_id_6e2f1e8a_fk_users_use;
       public          taiga    false    306    207    4071            $           2606    9778123 T   history_historyentry history_historyentry_project_id_9b008f70_fk_projects_project_id    FK CONSTRAINT     �   ALTER TABLE ONLY public.history_historyentry
    ADD CONSTRAINT history_historyentry_project_id_9b008f70_fk_projects_project_id FOREIGN KEY (project_id) REFERENCES public.projects_project(id) DEFERRABLE INITIALLY DEFERRED;
 ~   ALTER TABLE ONLY public.history_historyentry DROP CONSTRAINT history_historyentry_project_id_9b008f70_fk_projects_project_id;
       public          taiga    false    276    4125    215            �           2606    9777223 B   issues_issue issues_issue_assigned_to_id_c6054289_fk_users_user_id    FK CONSTRAINT     �   ALTER TABLE ONLY public.issues_issue
    ADD CONSTRAINT issues_issue_assigned_to_id_c6054289_fk_users_user_id FOREIGN KEY (assigned_to_id) REFERENCES public.users_user(id) DEFERRABLE INITIALLY DEFERRED;
 l   ALTER TABLE ONLY public.issues_issue DROP CONSTRAINT issues_issue_assigned_to_id_c6054289_fk_users_user_id;
       public          taiga    false    4071    243    207            �           2606    9777228 J   issues_issue issues_issue_milestone_id_3c2695ee_fk_milestones_milestone_id    FK CONSTRAINT     �   ALTER TABLE ONLY public.issues_issue
    ADD CONSTRAINT issues_issue_milestone_id_3c2695ee_fk_milestones_milestone_id FOREIGN KEY (milestone_id) REFERENCES public.milestones_milestone(id) DEFERRABLE INITIALLY DEFERRED;
 t   ALTER TABLE ONLY public.issues_issue DROP CONSTRAINT issues_issue_milestone_id_3c2695ee_fk_milestones_milestone_id;
       public          taiga    false    4224    241    243            �           2606    9777233 <   issues_issue issues_issue_owner_id_5c361b47_fk_users_user_id    FK CONSTRAINT     �   ALTER TABLE ONLY public.issues_issue
    ADD CONSTRAINT issues_issue_owner_id_5c361b47_fk_users_user_id FOREIGN KEY (owner_id) REFERENCES public.users_user(id) DEFERRABLE INITIALLY DEFERRED;
 f   ALTER TABLE ONLY public.issues_issue DROP CONSTRAINT issues_issue_owner_id_5c361b47_fk_users_user_id;
       public          taiga    false    4071    207    243            �           2606    9777866 F   issues_issue issues_issue_priority_id_93842a93_fk_projects_priority_id    FK CONSTRAINT     �   ALTER TABLE ONLY public.issues_issue
    ADD CONSTRAINT issues_issue_priority_id_93842a93_fk_projects_priority_id FOREIGN KEY (priority_id) REFERENCES public.projects_priority(id) DEFERRABLE INITIALLY DEFERRED;
 p   ALTER TABLE ONLY public.issues_issue DROP CONSTRAINT issues_issue_priority_id_93842a93_fk_projects_priority_id;
       public          taiga    false    223    4164    243            �           2606    9777243 D   issues_issue issues_issue_project_id_4b0f3e2f_fk_projects_project_id    FK CONSTRAINT     �   ALTER TABLE ONLY public.issues_issue
    ADD CONSTRAINT issues_issue_project_id_4b0f3e2f_fk_projects_project_id FOREIGN KEY (project_id) REFERENCES public.projects_project(id) DEFERRABLE INITIALLY DEFERRED;
 n   ALTER TABLE ONLY public.issues_issue DROP CONSTRAINT issues_issue_project_id_4b0f3e2f_fk_projects_project_id;
       public          taiga    false    243    215    4125            �           2606    9778568 F   issues_issue issues_issue_severity_id_695dade0_fk_projects_severity_id    FK CONSTRAINT     �   ALTER TABLE ONLY public.issues_issue
    ADD CONSTRAINT issues_issue_severity_id_695dade0_fk_projects_severity_id FOREIGN KEY (severity_id) REFERENCES public.projects_severity(id) DEFERRABLE INITIALLY DEFERRED;
 p   ALTER TABLE ONLY public.issues_issue DROP CONSTRAINT issues_issue_severity_id_695dade0_fk_projects_severity_id;
       public          taiga    false    243    227    4174            �           2606    9778573 G   issues_issue issues_issue_status_id_64473cf1_fk_projects_issuestatus_id    FK CONSTRAINT     �   ALTER TABLE ONLY public.issues_issue
    ADD CONSTRAINT issues_issue_status_id_64473cf1_fk_projects_issuestatus_id FOREIGN KEY (status_id) REFERENCES public.projects_issuestatus(id) DEFERRABLE INITIALLY DEFERRED;
 q   ALTER TABLE ONLY public.issues_issue DROP CONSTRAINT issues_issue_status_id_64473cf1_fk_projects_issuestatus_id;
       public          taiga    false    243    217    4145            �           2606    9778578 C   issues_issue issues_issue_type_id_c1063362_fk_projects_issuetype_id    FK CONSTRAINT     �   ALTER TABLE ONLY public.issues_issue
    ADD CONSTRAINT issues_issue_type_id_c1063362_fk_projects_issuetype_id FOREIGN KEY (type_id) REFERENCES public.projects_issuetype(id) DEFERRABLE INITIALLY DEFERRED;
 m   ALTER TABLE ONLY public.issues_issue DROP CONSTRAINT issues_issue_type_id_c1063362_fk_projects_issuetype_id;
       public          taiga    false    243    219    4154                       2606    9777813 H   likes_like likes_like_content_type_id_8ffc2116_fk_django_content_type_id    FK CONSTRAINT     �   ALTER TABLE ONLY public.likes_like
    ADD CONSTRAINT likes_like_content_type_id_8ffc2116_fk_django_content_type_id FOREIGN KEY (content_type_id) REFERENCES public.django_content_type(id) DEFERRABLE INITIALLY DEFERRED;
 r   ALTER TABLE ONLY public.likes_like DROP CONSTRAINT likes_like_content_type_id_8ffc2116_fk_django_content_type_id;
       public          taiga    false    267    4066    205                       2606    9777818 7   likes_like likes_like_user_id_aae4c421_fk_users_user_id    FK CONSTRAINT     �   ALTER TABLE ONLY public.likes_like
    ADD CONSTRAINT likes_like_user_id_aae4c421_fk_users_user_id FOREIGN KEY (user_id) REFERENCES public.users_user(id) DEFERRABLE INITIALLY DEFERRED;
 a   ALTER TABLE ONLY public.likes_like DROP CONSTRAINT likes_like_user_id_aae4c421_fk_users_user_id;
       public          taiga    false    267    4071    207            �           2606    9777174 L   milestones_milestone milestones_milestone_owner_id_216ba23b_fk_users_user_id    FK CONSTRAINT     �   ALTER TABLE ONLY public.milestones_milestone
    ADD CONSTRAINT milestones_milestone_owner_id_216ba23b_fk_users_user_id FOREIGN KEY (owner_id) REFERENCES public.users_user(id) DEFERRABLE INITIALLY DEFERRED;
 v   ALTER TABLE ONLY public.milestones_milestone DROP CONSTRAINT milestones_milestone_owner_id_216ba23b_fk_users_user_id;
       public          taiga    false    241    207    4071            �           2606    9777179 T   milestones_milestone milestones_milestone_project_id_6151cb75_fk_projects_project_id    FK CONSTRAINT     �   ALTER TABLE ONLY public.milestones_milestone
    ADD CONSTRAINT milestones_milestone_project_id_6151cb75_fk_projects_project_id FOREIGN KEY (project_id) REFERENCES public.projects_project(id) DEFERRABLE INITIALLY DEFERRED;
 ~   ALTER TABLE ONLY public.milestones_milestone DROP CONSTRAINT milestones_milestone_project_id_6151cb75_fk_projects_project_id;
       public          taiga    false    215    4125    241            	           2606    9778588 w   notifications_historychangenotification_history_entries notifications_histor_historychangenotific_65e52ffd_fk_notificat    FK CONSTRAINT     +  ALTER TABLE ONLY public.notifications_historychangenotification_history_entries
    ADD CONSTRAINT notifications_histor_historychangenotific_65e52ffd_fk_notificat FOREIGN KEY (historychangenotification_id) REFERENCES public.notifications_historychangenotification(id) DEFERRABLE INITIALLY DEFERRED;
 �   ALTER TABLE ONLY public.notifications_historychangenotification_history_entries DROP CONSTRAINT notifications_histor_historychangenotific_65e52ffd_fk_notificat;
       public          taiga    false    253    251    4269                       2606    9778598 t   notifications_historychangenotification_notify_users notifications_histor_historychangenotific_d8e98e97_fk_notificat    FK CONSTRAINT     (  ALTER TABLE ONLY public.notifications_historychangenotification_notify_users
    ADD CONSTRAINT notifications_histor_historychangenotific_d8e98e97_fk_notificat FOREIGN KEY (historychangenotification_id) REFERENCES public.notifications_historychangenotification(id) DEFERRABLE INITIALLY DEFERRED;
 �   ALTER TABLE ONLY public.notifications_historychangenotification_notify_users DROP CONSTRAINT notifications_histor_historychangenotific_d8e98e97_fk_notificat;
       public          taiga    false    255    4269    251            
           2606    9778583 r   notifications_historychangenotification_history_entries notifications_histor_historyentry_id_ad550852_fk_history_h    FK CONSTRAINT       ALTER TABLE ONLY public.notifications_historychangenotification_history_entries
    ADD CONSTRAINT notifications_histor_historyentry_id_ad550852_fk_history_h FOREIGN KEY (historyentry_id) REFERENCES public.history_historyentry(id) DEFERRABLE INITIALLY DEFERRED;
 �   ALTER TABLE ONLY public.notifications_historychangenotification_history_entries DROP CONSTRAINT notifications_histor_historyentry_id_ad550852_fk_history_h;
       public          taiga    false    253    276    4362                       2606    9777488 [   notifications_historychangenotification notifications_histor_owner_id_6f63be8a_fk_users_use    FK CONSTRAINT     �   ALTER TABLE ONLY public.notifications_historychangenotification
    ADD CONSTRAINT notifications_histor_owner_id_6f63be8a_fk_users_use FOREIGN KEY (owner_id) REFERENCES public.users_user(id) DEFERRABLE INITIALLY DEFERRED;
 �   ALTER TABLE ONLY public.notifications_historychangenotification DROP CONSTRAINT notifications_histor_owner_id_6f63be8a_fk_users_use;
       public          taiga    false    4071    207    251                       2606    9777493 ]   notifications_historychangenotification notifications_histor_project_id_52cf5e2b_fk_projects_    FK CONSTRAINT     �   ALTER TABLE ONLY public.notifications_historychangenotification
    ADD CONSTRAINT notifications_histor_project_id_52cf5e2b_fk_projects_ FOREIGN KEY (project_id) REFERENCES public.projects_project(id) DEFERRABLE INITIALLY DEFERRED;
 �   ALTER TABLE ONLY public.notifications_historychangenotification DROP CONSTRAINT notifications_histor_project_id_52cf5e2b_fk_projects_;
       public          taiga    false    251    4125    215                       2606    9778593 g   notifications_historychangenotification_notify_users notifications_histor_user_id_f7bd2448_fk_users_use    FK CONSTRAINT     �   ALTER TABLE ONLY public.notifications_historychangenotification_notify_users
    ADD CONSTRAINT notifications_histor_user_id_f7bd2448_fk_users_use FOREIGN KEY (user_id) REFERENCES public.users_user(id) DEFERRABLE INITIALLY DEFERRED;
 �   ALTER TABLE ONLY public.notifications_historychangenotification_notify_users DROP CONSTRAINT notifications_histor_user_id_f7bd2448_fk_users_use;
       public          taiga    false    255    207    4071                       2606    9777431 P   notifications_notifypolicy notifications_notify_project_id_aa5da43f_fk_projects_    FK CONSTRAINT     �   ALTER TABLE ONLY public.notifications_notifypolicy
    ADD CONSTRAINT notifications_notify_project_id_aa5da43f_fk_projects_ FOREIGN KEY (project_id) REFERENCES public.projects_project(id) DEFERRABLE INITIALLY DEFERRED;
 z   ALTER TABLE ONLY public.notifications_notifypolicy DROP CONSTRAINT notifications_notify_project_id_aa5da43f_fk_projects_;
       public          taiga    false    215    4125    249                       2606    9777436 W   notifications_notifypolicy notifications_notifypolicy_user_id_2902cbeb_fk_users_user_id    FK CONSTRAINT     �   ALTER TABLE ONLY public.notifications_notifypolicy
    ADD CONSTRAINT notifications_notifypolicy_user_id_2902cbeb_fk_users_user_id FOREIGN KEY (user_id) REFERENCES public.users_user(id) DEFERRABLE INITIALLY DEFERRED;
 �   ALTER TABLE ONLY public.notifications_notifypolicy DROP CONSTRAINT notifications_notifypolicy_user_id_2902cbeb_fk_users_user_id;
       public          taiga    false    207    249    4071                       2606    9777542 P   notifications_watched notifications_watche_content_type_id_7b3ab729_fk_django_co    FK CONSTRAINT     �   ALTER TABLE ONLY public.notifications_watched
    ADD CONSTRAINT notifications_watche_content_type_id_7b3ab729_fk_django_co FOREIGN KEY (content_type_id) REFERENCES public.django_content_type(id) DEFERRABLE INITIALLY DEFERRED;
 z   ALTER TABLE ONLY public.notifications_watched DROP CONSTRAINT notifications_watche_content_type_id_7b3ab729_fk_django_co;
       public          taiga    false    4066    205    257                       2606    9777552 K   notifications_watched notifications_watche_project_id_c88baa46_fk_projects_    FK CONSTRAINT     �   ALTER TABLE ONLY public.notifications_watched
    ADD CONSTRAINT notifications_watche_project_id_c88baa46_fk_projects_ FOREIGN KEY (project_id) REFERENCES public.projects_project(id) DEFERRABLE INITIALLY DEFERRED;
 u   ALTER TABLE ONLY public.notifications_watched DROP CONSTRAINT notifications_watche_project_id_c88baa46_fk_projects_;
       public          taiga    false    215    4125    257                       2606    9777547 M   notifications_watched notifications_watched_user_id_1bce1955_fk_users_user_id    FK CONSTRAINT     �   ALTER TABLE ONLY public.notifications_watched
    ADD CONSTRAINT notifications_watched_user_id_1bce1955_fk_users_user_id FOREIGN KEY (user_id) REFERENCES public.users_user(id) DEFERRABLE INITIALLY DEFERRED;
 w   ALTER TABLE ONLY public.notifications_watched DROP CONSTRAINT notifications_watched_user_id_1bce1955_fk_users_user_id;
       public          taiga    false    207    257    4071            7           2606    9778617 ]   notifications_webnotification notifications_webnotification_user_id_f32287d5_fk_users_user_id    FK CONSTRAINT     �   ALTER TABLE ONLY public.notifications_webnotification
    ADD CONSTRAINT notifications_webnotification_user_id_f32287d5_fk_users_user_id FOREIGN KEY (user_id) REFERENCES public.users_user(id) DEFERRABLE INITIALLY DEFERRED;
 �   ALTER TABLE ONLY public.notifications_webnotification DROP CONSTRAINT notifications_webnotification_user_id_f32287d5_fk_users_user_id;
       public          taiga    false    207    4071    310                       2606    9777919 R   projects_epicstatus projects_epicstatus_project_id_d2c43c29_fk_projects_project_id    FK CONSTRAINT     �   ALTER TABLE ONLY public.projects_epicstatus
    ADD CONSTRAINT projects_epicstatus_project_id_d2c43c29_fk_projects_project_id FOREIGN KEY (project_id) REFERENCES public.projects_project(id) DEFERRABLE INITIALLY DEFERRED;
 |   ALTER TABLE ONLY public.projects_epicstatus DROP CONSTRAINT projects_epicstatus_project_id_d2c43c29_fk_projects_project_id;
       public          taiga    false    4125    269    215            9           2606    9778677 K   projects_issueduedate projects_issueduedat_project_id_ec077eb7_fk_projects_    FK CONSTRAINT     �   ALTER TABLE ONLY public.projects_issueduedate
    ADD CONSTRAINT projects_issueduedat_project_id_ec077eb7_fk_projects_ FOREIGN KEY (project_id) REFERENCES public.projects_project(id) DEFERRABLE INITIALLY DEFERRED;
 u   ALTER TABLE ONLY public.projects_issueduedate DROP CONSTRAINT projects_issueduedat_project_id_ec077eb7_fk_projects_;
       public          taiga    false    215    314    4125            �           2606    9776962 T   projects_issuestatus projects_issuestatus_project_id_1988ebf4_fk_projects_project_id    FK CONSTRAINT     �   ALTER TABLE ONLY public.projects_issuestatus
    ADD CONSTRAINT projects_issuestatus_project_id_1988ebf4_fk_projects_project_id FOREIGN KEY (project_id) REFERENCES public.projects_project(id) DEFERRABLE INITIALLY DEFERRED;
 ~   ALTER TABLE ONLY public.projects_issuestatus DROP CONSTRAINT projects_issuestatus_project_id_1988ebf4_fk_projects_project_id;
       public          taiga    false    215    217    4125            �           2606    9776968 P   projects_issuetype projects_issuetype_project_id_e831e4ae_fk_projects_project_id    FK CONSTRAINT     �   ALTER TABLE ONLY public.projects_issuetype
    ADD CONSTRAINT projects_issuetype_project_id_e831e4ae_fk_projects_project_id FOREIGN KEY (project_id) REFERENCES public.projects_project(id) DEFERRABLE INITIALLY DEFERRED;
 z   ALTER TABLE ONLY public.projects_issuetype DROP CONSTRAINT projects_issuetype_project_id_e831e4ae_fk_projects_project_id;
       public          taiga    false    4125    215    219            �           2606    9777413 O   projects_membership projects_membership_invited_by_id_a2c6c913_fk_users_user_id    FK CONSTRAINT     �   ALTER TABLE ONLY public.projects_membership
    ADD CONSTRAINT projects_membership_invited_by_id_a2c6c913_fk_users_user_id FOREIGN KEY (invited_by_id) REFERENCES public.users_user(id) DEFERRABLE INITIALLY DEFERRED;
 y   ALTER TABLE ONLY public.projects_membership DROP CONSTRAINT projects_membership_invited_by_id_a2c6c913_fk_users_user_id;
       public          taiga    false    213    4071    207            �           2606    9776854 R   projects_membership projects_membership_project_id_5f65bf3f_fk_projects_project_id    FK CONSTRAINT     �   ALTER TABLE ONLY public.projects_membership
    ADD CONSTRAINT projects_membership_project_id_5f65bf3f_fk_projects_project_id FOREIGN KEY (project_id) REFERENCES public.projects_project(id) DEFERRABLE INITIALLY DEFERRED;
 |   ALTER TABLE ONLY public.projects_membership DROP CONSTRAINT projects_membership_project_id_5f65bf3f_fk_projects_project_id;
       public          taiga    false    4125    213    215            �           2606    9776860 I   projects_membership projects_membership_role_id_c4bd36ef_fk_users_role_id    FK CONSTRAINT     �   ALTER TABLE ONLY public.projects_membership
    ADD CONSTRAINT projects_membership_role_id_c4bd36ef_fk_users_role_id FOREIGN KEY (role_id) REFERENCES public.users_role(id) DEFERRABLE INITIALLY DEFERRED;
 s   ALTER TABLE ONLY public.projects_membership DROP CONSTRAINT projects_membership_role_id_c4bd36ef_fk_users_role_id;
       public          taiga    false    4085    211    213            �           2606    9776848 I   projects_membership projects_membership_user_id_13374535_fk_users_user_id    FK CONSTRAINT     �   ALTER TABLE ONLY public.projects_membership
    ADD CONSTRAINT projects_membership_user_id_13374535_fk_users_user_id FOREIGN KEY (user_id) REFERENCES public.users_user(id) DEFERRABLE INITIALLY DEFERRED;
 s   ALTER TABLE ONLY public.projects_membership DROP CONSTRAINT projects_membership_user_id_13374535_fk_users_user_id;
       public          taiga    false    4071    213    207            �           2606    9776974 J   projects_points projects_points_project_id_3b8f7b42_fk_projects_project_id    FK CONSTRAINT     �   ALTER TABLE ONLY public.projects_points
    ADD CONSTRAINT projects_points_project_id_3b8f7b42_fk_projects_project_id FOREIGN KEY (project_id) REFERENCES public.projects_project(id) DEFERRABLE INITIALLY DEFERRED;
 t   ALTER TABLE ONLY public.projects_points DROP CONSTRAINT projects_points_project_id_3b8f7b42_fk_projects_project_id;
       public          taiga    false    215    4125    221            �           2606    9776980 N   projects_priority projects_priority_project_id_936c75b2_fk_projects_project_id    FK CONSTRAINT     �   ALTER TABLE ONLY public.projects_priority
    ADD CONSTRAINT projects_priority_project_id_936c75b2_fk_projects_project_id FOREIGN KEY (project_id) REFERENCES public.projects_project(id) DEFERRABLE INITIALLY DEFERRED;
 x   ALTER TABLE ONLY public.projects_priority DROP CONSTRAINT projects_priority_project_id_936c75b2_fk_projects_project_id;
       public          taiga    false    215    223    4125            �           2606    9777931 L   projects_project projects_project_creation_template_id_b5a97819_fk_projects_    FK CONSTRAINT     �   ALTER TABLE ONLY public.projects_project
    ADD CONSTRAINT projects_project_creation_template_id_b5a97819_fk_projects_ FOREIGN KEY (creation_template_id) REFERENCES public.projects_projecttemplate(id) DEFERRABLE INITIALLY DEFERRED;
 v   ALTER TABLE ONLY public.projects_project DROP CONSTRAINT projects_project_creation_template_id_b5a97819_fk_projects_;
       public          taiga    false    215    4169    225            �           2606    9777924 L   projects_project projects_project_default_epic_status__1915e581_fk_projects_    FK CONSTRAINT     �   ALTER TABLE ONLY public.projects_project
    ADD CONSTRAINT projects_project_default_epic_status__1915e581_fk_projects_ FOREIGN KEY (default_epic_status_id) REFERENCES public.projects_epicstatus(id) DEFERRABLE INITIALLY DEFERRED;
 v   ALTER TABLE ONLY public.projects_project DROP CONSTRAINT projects_project_default_epic_status__1915e581_fk_projects_;
       public          taiga    false    269    215    4330            �           2606    9777011 L   projects_project projects_project_default_issue_status_6aebe7fd_fk_projects_    FK CONSTRAINT     �   ALTER TABLE ONLY public.projects_project
    ADD CONSTRAINT projects_project_default_issue_status_6aebe7fd_fk_projects_ FOREIGN KEY (default_issue_status_id) REFERENCES public.projects_issuestatus(id) DEFERRABLE INITIALLY DEFERRED;
 v   ALTER TABLE ONLY public.projects_project DROP CONSTRAINT projects_project_default_issue_status_6aebe7fd_fk_projects_;
       public          taiga    false    217    4145    215            �           2606    9777016 L   projects_project projects_project_default_issue_type_i_89e9b202_fk_projects_    FK CONSTRAINT     �   ALTER TABLE ONLY public.projects_project
    ADD CONSTRAINT projects_project_default_issue_type_i_89e9b202_fk_projects_ FOREIGN KEY (default_issue_type_id) REFERENCES public.projects_issuetype(id) DEFERRABLE INITIALLY DEFERRED;
 v   ALTER TABLE ONLY public.projects_project DROP CONSTRAINT projects_project_default_issue_type_i_89e9b202_fk_projects_;
       public          taiga    false    219    4154    215            �           2606    9777021 I   projects_project projects_project_default_points_id_6c6701c2_fk_projects_    FK CONSTRAINT     �   ALTER TABLE ONLY public.projects_project
    ADD CONSTRAINT projects_project_default_points_id_6c6701c2_fk_projects_ FOREIGN KEY (default_points_id) REFERENCES public.projects_points(id) DEFERRABLE INITIALLY DEFERRED;
 s   ALTER TABLE ONLY public.projects_project DROP CONSTRAINT projects_project_default_points_id_6c6701c2_fk_projects_;
       public          taiga    false    215    221    4159            �           2606    9777026 K   projects_project projects_project_default_priority_id_498ad5e0_fk_projects_    FK CONSTRAINT     �   ALTER TABLE ONLY public.projects_project
    ADD CONSTRAINT projects_project_default_priority_id_498ad5e0_fk_projects_ FOREIGN KEY (default_priority_id) REFERENCES public.projects_priority(id) DEFERRABLE INITIALLY DEFERRED;
 u   ALTER TABLE ONLY public.projects_project DROP CONSTRAINT projects_project_default_priority_id_498ad5e0_fk_projects_;
       public          taiga    false    223    4164    215            �           2606    9777031 K   projects_project projects_project_default_severity_id_34b7fa94_fk_projects_    FK CONSTRAINT     �   ALTER TABLE ONLY public.projects_project
    ADD CONSTRAINT projects_project_default_severity_id_34b7fa94_fk_projects_ FOREIGN KEY (default_severity_id) REFERENCES public.projects_severity(id) DEFERRABLE INITIALLY DEFERRED;
 u   ALTER TABLE ONLY public.projects_project DROP CONSTRAINT projects_project_default_severity_id_34b7fa94_fk_projects_;
       public          taiga    false    227    215    4174            �           2606    9778743 K   projects_project projects_project_default_swimlane_id_14643d1a_fk_projects_    FK CONSTRAINT     �   ALTER TABLE ONLY public.projects_project
    ADD CONSTRAINT projects_project_default_swimlane_id_14643d1a_fk_projects_ FOREIGN KEY (default_swimlane_id) REFERENCES public.projects_swimlane(id) DEFERRABLE INITIALLY DEFERRED;
 u   ALTER TABLE ONLY public.projects_project DROP CONSTRAINT projects_project_default_swimlane_id_14643d1a_fk_projects_;
       public          taiga    false    215    4480    320            �           2606    9777036 L   projects_project projects_project_default_task_status__3be95fee_fk_projects_    FK CONSTRAINT     �   ALTER TABLE ONLY public.projects_project
    ADD CONSTRAINT projects_project_default_task_status__3be95fee_fk_projects_ FOREIGN KEY (default_task_status_id) REFERENCES public.projects_taskstatus(id) DEFERRABLE INITIALLY DEFERRED;
 v   ALTER TABLE ONLY public.projects_project DROP CONSTRAINT projects_project_default_task_status__3be95fee_fk_projects_;
       public          taiga    false    4179    229    215            �           2606    9777041 L   projects_project projects_project_default_us_status_id_cc989d55_fk_projects_    FK CONSTRAINT     �   ALTER TABLE ONLY public.projects_project
    ADD CONSTRAINT projects_project_default_us_status_id_cc989d55_fk_projects_ FOREIGN KEY (default_us_status_id) REFERENCES public.projects_userstorystatus(id) DEFERRABLE INITIALLY DEFERRED;
 v   ALTER TABLE ONLY public.projects_project DROP CONSTRAINT projects_project_default_us_status_id_cc989d55_fk_projects_;
       public          taiga    false    215    4188    231            �           2606    9778697 D   projects_project projects_project_owner_id_b940de39_fk_users_user_id    FK CONSTRAINT     �   ALTER TABLE ONLY public.projects_project
    ADD CONSTRAINT projects_project_owner_id_b940de39_fk_users_user_id FOREIGN KEY (owner_id) REFERENCES public.users_user(id) DEFERRABLE INITIALLY DEFERRED;
 n   ALTER TABLE ONLY public.projects_project DROP CONSTRAINT projects_project_owner_id_b940de39_fk_users_user_id;
       public          taiga    false    4071    207    215            �           2606    9778751 D   projects_project projects_project_workspace_id_7ea54f67_fk_workspace    FK CONSTRAINT     �   ALTER TABLE ONLY public.projects_project
    ADD CONSTRAINT projects_project_workspace_id_7ea54f67_fk_workspace FOREIGN KEY (workspace_id) REFERENCES public.workspaces_workspace(id) DEFERRABLE INITIALLY DEFERRED;
 n   ALTER TABLE ONLY public.projects_project DROP CONSTRAINT projects_project_workspace_id_7ea54f67_fk_workspace;
       public          taiga    false    4460    312    215                       2606    9777728 S   projects_projectmodulesconfig projects_projectmodu_project_id_eff1c253_fk_projects_    FK CONSTRAINT     �   ALTER TABLE ONLY public.projects_projectmodulesconfig
    ADD CONSTRAINT projects_projectmodu_project_id_eff1c253_fk_projects_ FOREIGN KEY (project_id) REFERENCES public.projects_project(id) DEFERRABLE INITIALLY DEFERRED;
 }   ALTER TABLE ONLY public.projects_projectmodulesconfig DROP CONSTRAINT projects_projectmodu_project_id_eff1c253_fk_projects_;
       public          taiga    false    263    4125    215            �           2606    9776987 N   projects_severity projects_severity_project_id_9ab920cd_fk_projects_project_id    FK CONSTRAINT     �   ALTER TABLE ONLY public.projects_severity
    ADD CONSTRAINT projects_severity_project_id_9ab920cd_fk_projects_project_id FOREIGN KEY (project_id) REFERENCES public.projects_project(id) DEFERRABLE INITIALLY DEFERRED;
 x   ALTER TABLE ONLY public.projects_severity DROP CONSTRAINT projects_severity_project_id_9ab920cd_fk_projects_project_id;
       public          taiga    false    215    4125    227            <           2606    9778713 N   projects_swimlane projects_swimlane_project_id_06871cf8_fk_projects_project_id    FK CONSTRAINT     �   ALTER TABLE ONLY public.projects_swimlane
    ADD CONSTRAINT projects_swimlane_project_id_06871cf8_fk_projects_project_id FOREIGN KEY (project_id) REFERENCES public.projects_project(id) DEFERRABLE INITIALLY DEFERRED;
 x   ALTER TABLE ONLY public.projects_swimlane DROP CONSTRAINT projects_swimlane_project_id_06871cf8_fk_projects_project_id;
       public          taiga    false    4125    320    215            =           2606    9778727 U   projects_swimlaneuserstorystatus projects_swimlaneuse_status_id_2f3fda91_fk_projects_    FK CONSTRAINT     �   ALTER TABLE ONLY public.projects_swimlaneuserstorystatus
    ADD CONSTRAINT projects_swimlaneuse_status_id_2f3fda91_fk_projects_ FOREIGN KEY (status_id) REFERENCES public.projects_userstorystatus(id) DEFERRABLE INITIALLY DEFERRED;
    ALTER TABLE ONLY public.projects_swimlaneuserstorystatus DROP CONSTRAINT projects_swimlaneuse_status_id_2f3fda91_fk_projects_;
       public          taiga    false    231    322    4188            >           2606    9778732 W   projects_swimlaneuserstorystatus projects_swimlaneuse_swimlane_id_1d3f2b21_fk_projects_    FK CONSTRAINT     �   ALTER TABLE ONLY public.projects_swimlaneuserstorystatus
    ADD CONSTRAINT projects_swimlaneuse_swimlane_id_1d3f2b21_fk_projects_ FOREIGN KEY (swimlane_id) REFERENCES public.projects_swimlane(id) DEFERRABLE INITIALLY DEFERRED;
 �   ALTER TABLE ONLY public.projects_swimlaneuserstorystatus DROP CONSTRAINT projects_swimlaneuse_swimlane_id_1d3f2b21_fk_projects_;
       public          taiga    false    320    322    4480            :           2606    9778683 T   projects_taskduedate projects_taskduedate_project_id_775d850d_fk_projects_project_id    FK CONSTRAINT     �   ALTER TABLE ONLY public.projects_taskduedate
    ADD CONSTRAINT projects_taskduedate_project_id_775d850d_fk_projects_project_id FOREIGN KEY (project_id) REFERENCES public.projects_project(id) DEFERRABLE INITIALLY DEFERRED;
 ~   ALTER TABLE ONLY public.projects_taskduedate DROP CONSTRAINT projects_taskduedate_project_id_775d850d_fk_projects_project_id;
       public          taiga    false    215    316    4125            �           2606    9776993 R   projects_taskstatus projects_taskstatus_project_id_8b32b2bb_fk_projects_project_id    FK CONSTRAINT     �   ALTER TABLE ONLY public.projects_taskstatus
    ADD CONSTRAINT projects_taskstatus_project_id_8b32b2bb_fk_projects_project_id FOREIGN KEY (project_id) REFERENCES public.projects_project(id) DEFERRABLE INITIALLY DEFERRED;
 |   ALTER TABLE ONLY public.projects_taskstatus DROP CONSTRAINT projects_taskstatus_project_id_8b32b2bb_fk_projects_project_id;
       public          taiga    false    4125    229    215            ;           2606    9778689 O   projects_userstoryduedate projects_userstorydu_project_id_ab7b1680_fk_projects_    FK CONSTRAINT     �   ALTER TABLE ONLY public.projects_userstoryduedate
    ADD CONSTRAINT projects_userstorydu_project_id_ab7b1680_fk_projects_ FOREIGN KEY (project_id) REFERENCES public.projects_project(id) DEFERRABLE INITIALLY DEFERRED;
 y   ALTER TABLE ONLY public.projects_userstoryduedate DROP CONSTRAINT projects_userstorydu_project_id_ab7b1680_fk_projects_;
       public          taiga    false    4125    215    318            �           2606    9776999 N   projects_userstorystatus projects_userstoryst_project_id_cdf95c9c_fk_projects_    FK CONSTRAINT     �   ALTER TABLE ONLY public.projects_userstorystatus
    ADD CONSTRAINT projects_userstoryst_project_id_cdf95c9c_fk_projects_ FOREIGN KEY (project_id) REFERENCES public.projects_project(id) DEFERRABLE INITIALLY DEFERRED;
 x   ALTER TABLE ONLY public.projects_userstorystatus DROP CONSTRAINT projects_userstoryst_project_id_cdf95c9c_fk_projects_;
       public          taiga    false    4125    231    215            ?           2606    9778768 O   references_reference references_reference_content_type_id_c134e05e_fk_django_co    FK CONSTRAINT     �   ALTER TABLE ONLY public.references_reference
    ADD CONSTRAINT references_reference_content_type_id_c134e05e_fk_django_co FOREIGN KEY (content_type_id) REFERENCES public.django_content_type(id) DEFERRABLE INITIALLY DEFERRED;
 y   ALTER TABLE ONLY public.references_reference DROP CONSTRAINT references_reference_content_type_id_c134e05e_fk_django_co;
       public          taiga    false    205    324    4066            @           2606    9778773 T   references_reference references_reference_project_id_00275368_fk_projects_project_id    FK CONSTRAINT     �   ALTER TABLE ONLY public.references_reference
    ADD CONSTRAINT references_reference_project_id_00275368_fk_projects_project_id FOREIGN KEY (project_id) REFERENCES public.projects_project(id) DEFERRABLE INITIALLY DEFERRED;
 ~   ALTER TABLE ONLY public.references_reference DROP CONSTRAINT references_reference_project_id_00275368_fk_projects_project_id;
       public          taiga    false    324    215    4125            A           2606    9778800 R   settings_userprojectsettings settings_userproject_project_id_0bc686ce_fk_projects_    FK CONSTRAINT     �   ALTER TABLE ONLY public.settings_userprojectsettings
    ADD CONSTRAINT settings_userproject_project_id_0bc686ce_fk_projects_ FOREIGN KEY (project_id) REFERENCES public.projects_project(id) DEFERRABLE INITIALLY DEFERRED;
 |   ALTER TABLE ONLY public.settings_userprojectsettings DROP CONSTRAINT settings_userproject_project_id_0bc686ce_fk_projects_;
       public          taiga    false    4125    327    215            B           2606    9778805 [   settings_userprojectsettings settings_userprojectsettings_user_id_0e7fdc25_fk_users_user_id    FK CONSTRAINT     �   ALTER TABLE ONLY public.settings_userprojectsettings
    ADD CONSTRAINT settings_userprojectsettings_user_id_0e7fdc25_fk_users_user_id FOREIGN KEY (user_id) REFERENCES public.users_user(id) DEFERRABLE INITIALLY DEFERRED;
 �   ALTER TABLE ONLY public.settings_userprojectsettings DROP CONSTRAINT settings_userprojectsettings_user_id_0e7fdc25_fk_users_user_id;
       public          taiga    false    4071    327    207                       2606    9777579 >   tasks_task tasks_task_assigned_to_id_e8821f61_fk_users_user_id    FK CONSTRAINT     �   ALTER TABLE ONLY public.tasks_task
    ADD CONSTRAINT tasks_task_assigned_to_id_e8821f61_fk_users_user_id FOREIGN KEY (assigned_to_id) REFERENCES public.users_user(id) DEFERRABLE INITIALLY DEFERRED;
 h   ALTER TABLE ONLY public.tasks_task DROP CONSTRAINT tasks_task_assigned_to_id_e8821f61_fk_users_user_id;
       public          taiga    false    4071    207    259                       2606    9777637 F   tasks_task tasks_task_milestone_id_64cc568f_fk_milestones_milestone_id    FK CONSTRAINT     �   ALTER TABLE ONLY public.tasks_task
    ADD CONSTRAINT tasks_task_milestone_id_64cc568f_fk_milestones_milestone_id FOREIGN KEY (milestone_id) REFERENCES public.milestones_milestone(id) DEFERRABLE INITIALLY DEFERRED;
 p   ALTER TABLE ONLY public.tasks_task DROP CONSTRAINT tasks_task_milestone_id_64cc568f_fk_milestones_milestone_id;
       public          taiga    false    241    4224    259                       2606    9777589 8   tasks_task tasks_task_owner_id_db3dcc3e_fk_users_user_id    FK CONSTRAINT     �   ALTER TABLE ONLY public.tasks_task
    ADD CONSTRAINT tasks_task_owner_id_db3dcc3e_fk_users_user_id FOREIGN KEY (owner_id) REFERENCES public.users_user(id) DEFERRABLE INITIALLY DEFERRED;
 b   ALTER TABLE ONLY public.tasks_task DROP CONSTRAINT tasks_task_owner_id_db3dcc3e_fk_users_user_id;
       public          taiga    false    259    4071    207                       2606    9777594 @   tasks_task tasks_task_project_id_a2815f0c_fk_projects_project_id    FK CONSTRAINT     �   ALTER TABLE ONLY public.tasks_task
    ADD CONSTRAINT tasks_task_project_id_a2815f0c_fk_projects_project_id FOREIGN KEY (project_id) REFERENCES public.projects_project(id) DEFERRABLE INITIALLY DEFERRED;
 j   ALTER TABLE ONLY public.tasks_task DROP CONSTRAINT tasks_task_project_id_a2815f0c_fk_projects_project_id;
       public          taiga    false    259    4125    215                       2606    9777632 B   tasks_task tasks_task_status_id_899d2b90_fk_projects_taskstatus_id    FK CONSTRAINT     �   ALTER TABLE ONLY public.tasks_task
    ADD CONSTRAINT tasks_task_status_id_899d2b90_fk_projects_taskstatus_id FOREIGN KEY (status_id) REFERENCES public.projects_taskstatus(id) DEFERRABLE INITIALLY DEFERRED;
 l   ALTER TABLE ONLY public.tasks_task DROP CONSTRAINT tasks_task_status_id_899d2b90_fk_projects_taskstatus_id;
       public          taiga    false    229    259    4179                       2606    9778841 H   tasks_task tasks_task_user_story_id_47ceaf1d_fk_userstories_userstory_id    FK CONSTRAINT     �   ALTER TABLE ONLY public.tasks_task
    ADD CONSTRAINT tasks_task_user_story_id_47ceaf1d_fk_userstories_userstory_id FOREIGN KEY (user_story_id) REFERENCES public.userstories_userstory(id) DEFERRABLE INITIALLY DEFERRED;
 r   ALTER TABLE ONLY public.tasks_task DROP CONSTRAINT tasks_task_user_story_id_47ceaf1d_fk_userstories_userstory_id;
       public          taiga    false    247    259    4254                       2606    9777763 I   timeline_timeline timeline_timeline_content_type_id_5731a0c6_fk_django_co    FK CONSTRAINT     �   ALTER TABLE ONLY public.timeline_timeline
    ADD CONSTRAINT timeline_timeline_content_type_id_5731a0c6_fk_django_co FOREIGN KEY (content_type_id) REFERENCES public.django_content_type(id) DEFERRABLE INITIALLY DEFERRED;
 s   ALTER TABLE ONLY public.timeline_timeline DROP CONSTRAINT timeline_timeline_content_type_id_5731a0c6_fk_django_co;
       public          taiga    false    4066    205    265                       2606    9777758 N   timeline_timeline timeline_timeline_data_content_type_id_0689742e_fk_django_co    FK CONSTRAINT     �   ALTER TABLE ONLY public.timeline_timeline
    ADD CONSTRAINT timeline_timeline_data_content_type_id_0689742e_fk_django_co FOREIGN KEY (data_content_type_id) REFERENCES public.django_content_type(id) DEFERRABLE INITIALLY DEFERRED;
 x   ALTER TABLE ONLY public.timeline_timeline DROP CONSTRAINT timeline_timeline_data_content_type_id_0689742e_fk_django_co;
       public          taiga    false    205    4066    265                       2606    9777780 N   timeline_timeline timeline_timeline_project_id_58d5eadd_fk_projects_project_id    FK CONSTRAINT     �   ALTER TABLE ONLY public.timeline_timeline
    ADD CONSTRAINT timeline_timeline_project_id_58d5eadd_fk_projects_project_id FOREIGN KEY (project_id) REFERENCES public.projects_project(id) DEFERRABLE INITIALLY DEFERRED;
 x   ALTER TABLE ONLY public.timeline_timeline DROP CONSTRAINT timeline_timeline_project_id_58d5eadd_fk_projects_project_id;
       public          taiga    false    4125    215    265            D           2606    9778904 R   token_denylist_denylistedtoken token_denylist_denyl_token_id_dca79910_fk_token_den    FK CONSTRAINT     �   ALTER TABLE ONLY public.token_denylist_denylistedtoken
    ADD CONSTRAINT token_denylist_denyl_token_id_dca79910_fk_token_den FOREIGN KEY (token_id) REFERENCES public.token_denylist_outstandingtoken(id) DEFERRABLE INITIALLY DEFERRED;
 |   ALTER TABLE ONLY public.token_denylist_denylistedtoken DROP CONSTRAINT token_denylist_denyl_token_id_dca79910_fk_token_den;
       public          taiga    false    333    4512    331            C           2606    9778897 R   token_denylist_outstandingtoken token_denylist_outst_user_id_c6f48986_fk_users_use    FK CONSTRAINT     �   ALTER TABLE ONLY public.token_denylist_outstandingtoken
    ADD CONSTRAINT token_denylist_outst_user_id_c6f48986_fk_users_use FOREIGN KEY (user_id) REFERENCES public.users_user(id) DEFERRABLE INITIALLY DEFERRED;
 |   ALTER TABLE ONLY public.token_denylist_outstandingtoken DROP CONSTRAINT token_denylist_outst_user_id_c6f48986_fk_users_use;
       public          taiga    false    331    207    4071                       2606    9777663 ?   users_authdata users_authdata_user_id_9625853a_fk_users_user_id    FK CONSTRAINT     �   ALTER TABLE ONLY public.users_authdata
    ADD CONSTRAINT users_authdata_user_id_9625853a_fk_users_user_id FOREIGN KEY (user_id) REFERENCES public.users_user(id) DEFERRABLE INITIALLY DEFERRED;
 i   ALTER TABLE ONLY public.users_authdata DROP CONSTRAINT users_authdata_user_id_9625853a_fk_users_user_id;
       public          taiga    false    4071    261    207            �           2606    9777140 @   users_role users_role_project_id_2837f877_fk_projects_project_id    FK CONSTRAINT     �   ALTER TABLE ONLY public.users_role
    ADD CONSTRAINT users_role_project_id_2837f877_fk_projects_project_id FOREIGN KEY (project_id) REFERENCES public.projects_project(id) DEFERRABLE INITIALLY DEFERRED;
 j   ALTER TABLE ONLY public.users_role DROP CONSTRAINT users_role_project_id_2837f877_fk_projects_project_id;
       public          taiga    false    211    215    4125            E           2606    9778942 J   users_workspacerole users_workspacerole_workspace_id_30155f00_fk_workspace    FK CONSTRAINT     �   ALTER TABLE ONLY public.users_workspacerole
    ADD CONSTRAINT users_workspacerole_workspace_id_30155f00_fk_workspace FOREIGN KEY (workspace_id) REFERENCES public.workspaces_workspace(id) DEFERRABLE INITIALLY DEFERRED;
 t   ALTER TABLE ONLY public.users_workspacerole DROP CONSTRAINT users_workspacerole_workspace_id_30155f00_fk_workspace;
       public          taiga    false    335    312    4460            F           2606    9778965 T   userstorage_storageentry userstorage_storageentry_owner_id_c4c1ffc0_fk_users_user_id    FK CONSTRAINT     �   ALTER TABLE ONLY public.userstorage_storageentry
    ADD CONSTRAINT userstorage_storageentry_owner_id_c4c1ffc0_fk_users_user_id FOREIGN KEY (owner_id) REFERENCES public.users_user(id) DEFERRABLE INITIALLY DEFERRED;
 ~   ALTER TABLE ONLY public.userstorage_storageentry DROP CONSTRAINT userstorage_storageentry_owner_id_c4c1ffc0_fk_users_user_id;
       public          taiga    false    337    4071    207            �           2606    9777380 O   userstories_rolepoints userstories_rolepoin_user_story_id_ddb4c558_fk_userstori    FK CONSTRAINT     �   ALTER TABLE ONLY public.userstories_rolepoints
    ADD CONSTRAINT userstories_rolepoin_user_story_id_ddb4c558_fk_userstori FOREIGN KEY (user_story_id) REFERENCES public.userstories_userstory(id) DEFERRABLE INITIALLY DEFERRED;
 y   ALTER TABLE ONLY public.userstories_rolepoints DROP CONSTRAINT userstories_rolepoin_user_story_id_ddb4c558_fk_userstori;
       public          taiga    false    4254    245    247            �           2606    9777385 V   userstories_rolepoints userstories_rolepoints_points_id_cfcc5a79_fk_projects_points_id    FK CONSTRAINT     �   ALTER TABLE ONLY public.userstories_rolepoints
    ADD CONSTRAINT userstories_rolepoints_points_id_cfcc5a79_fk_projects_points_id FOREIGN KEY (points_id) REFERENCES public.projects_points(id) DEFERRABLE INITIALLY DEFERRED;
 �   ALTER TABLE ONLY public.userstories_rolepoints DROP CONSTRAINT userstories_rolepoints_points_id_cfcc5a79_fk_projects_points_id;
       public          taiga    false    245    221    4159            �           2606    9777321 O   userstories_rolepoints userstories_rolepoints_role_id_94ac7663_fk_users_role_id    FK CONSTRAINT     �   ALTER TABLE ONLY public.userstories_rolepoints
    ADD CONSTRAINT userstories_rolepoints_role_id_94ac7663_fk_users_role_id FOREIGN KEY (role_id) REFERENCES public.users_role(id) DEFERRABLE INITIALLY DEFERRED;
 y   ALTER TABLE ONLY public.userstories_rolepoints DROP CONSTRAINT userstories_rolepoints_role_id_94ac7663_fk_users_role_id;
       public          taiga    false    211    245    4085            �           2606    9777407 U   userstories_userstory userstories_userstor_generated_from_issue_afe43198_fk_issues_is    FK CONSTRAINT     �   ALTER TABLE ONLY public.userstories_userstory
    ADD CONSTRAINT userstories_userstor_generated_from_issue_afe43198_fk_issues_is FOREIGN KEY (generated_from_issue_id) REFERENCES public.issues_issue(id) DEFERRABLE INITIALLY DEFERRED;
    ALTER TABLE ONLY public.userstories_userstory DROP CONSTRAINT userstories_userstor_generated_from_issue_afe43198_fk_issues_is;
       public          taiga    false    4234    247    243            �           2606    9779046 U   userstories_userstory userstories_userstor_generated_from_task__8e958d43_fk_tasks_tas    FK CONSTRAINT     �   ALTER TABLE ONLY public.userstories_userstory
    ADD CONSTRAINT userstories_userstor_generated_from_task__8e958d43_fk_tasks_tas FOREIGN KEY (generated_from_task_id) REFERENCES public.tasks_task(id) DEFERRABLE INITIALLY DEFERRED;
    ALTER TABLE ONLY public.userstories_userstory DROP CONSTRAINT userstories_userstor_generated_from_task__8e958d43_fk_tasks_tas;
       public          taiga    false    4295    259    247            �           2606    9777338 M   userstories_userstory userstories_userstor_milestone_id_37f31d22_fk_milestone    FK CONSTRAINT     �   ALTER TABLE ONLY public.userstories_userstory
    ADD CONSTRAINT userstories_userstor_milestone_id_37f31d22_fk_milestone FOREIGN KEY (milestone_id) REFERENCES public.milestones_milestone(id) DEFERRABLE INITIALLY DEFERRED;
 w   ALTER TABLE ONLY public.userstories_userstory DROP CONSTRAINT userstories_userstor_milestone_id_37f31d22_fk_milestone;
       public          taiga    false    4224    241    247                        2606    9777348 K   userstories_userstory userstories_userstor_project_id_03e85e9c_fk_projects_    FK CONSTRAINT     �   ALTER TABLE ONLY public.userstories_userstory
    ADD CONSTRAINT userstories_userstor_project_id_03e85e9c_fk_projects_ FOREIGN KEY (project_id) REFERENCES public.projects_project(id) DEFERRABLE INITIALLY DEFERRED;
 u   ALTER TABLE ONLY public.userstories_userstory DROP CONSTRAINT userstories_userstor_project_id_03e85e9c_fk_projects_;
       public          taiga    false    215    4125    247                       2606    9777353 J   userstories_userstory userstories_userstor_status_id_858671dd_fk_projects_    FK CONSTRAINT     �   ALTER TABLE ONLY public.userstories_userstory
    ADD CONSTRAINT userstories_userstor_status_id_858671dd_fk_projects_ FOREIGN KEY (status_id) REFERENCES public.projects_userstorystatus(id) DEFERRABLE INITIALLY DEFERRED;
 t   ALTER TABLE ONLY public.userstories_userstory DROP CONSTRAINT userstories_userstor_status_id_858671dd_fk_projects_;
       public          taiga    false    4188    247    231                       2606    9779057 L   userstories_userstory userstories_userstor_swimlane_id_8ecab79d_fk_projects_    FK CONSTRAINT     �   ALTER TABLE ONLY public.userstories_userstory
    ADD CONSTRAINT userstories_userstor_swimlane_id_8ecab79d_fk_projects_ FOREIGN KEY (swimlane_id) REFERENCES public.projects_swimlane(id) DEFERRABLE INITIALLY DEFERRED;
 v   ALTER TABLE ONLY public.userstories_userstory DROP CONSTRAINT userstories_userstor_swimlane_id_8ecab79d_fk_projects_;
       public          taiga    false    247    4480    320            G           2606    9779036 W   userstories_userstory_assigned_users userstories_userstor_user_id_6de6e8a7_fk_users_use    FK CONSTRAINT     �   ALTER TABLE ONLY public.userstories_userstory_assigned_users
    ADD CONSTRAINT userstories_userstor_user_id_6de6e8a7_fk_users_use FOREIGN KEY (user_id) REFERENCES public.users_user(id) DEFERRABLE INITIALLY DEFERRED;
 �   ALTER TABLE ONLY public.userstories_userstory_assigned_users DROP CONSTRAINT userstories_userstor_user_id_6de6e8a7_fk_users_use;
       public          taiga    false    4071    207    339            H           2606    9779031 \   userstories_userstory_assigned_users userstories_userstor_userstory_id_fcb98e26_fk_userstori    FK CONSTRAINT     �   ALTER TABLE ONLY public.userstories_userstory_assigned_users
    ADD CONSTRAINT userstories_userstor_userstory_id_fcb98e26_fk_userstori FOREIGN KEY (userstory_id) REFERENCES public.userstories_userstory(id) DEFERRABLE INITIALLY DEFERRED;
 �   ALTER TABLE ONLY public.userstories_userstory_assigned_users DROP CONSTRAINT userstories_userstor_userstory_id_fcb98e26_fk_userstori;
       public          taiga    false    339    247    4254                       2606    9777328 T   userstories_userstory userstories_userstory_assigned_to_id_5ba80653_fk_users_user_id    FK CONSTRAINT     �   ALTER TABLE ONLY public.userstories_userstory
    ADD CONSTRAINT userstories_userstory_assigned_to_id_5ba80653_fk_users_user_id FOREIGN KEY (assigned_to_id) REFERENCES public.users_user(id) DEFERRABLE INITIALLY DEFERRED;
 ~   ALTER TABLE ONLY public.userstories_userstory DROP CONSTRAINT userstories_userstory_assigned_to_id_5ba80653_fk_users_user_id;
       public          taiga    false    207    247    4071                       2606    9779051 N   userstories_userstory userstories_userstory_owner_id_df53c64e_fk_users_user_id    FK CONSTRAINT     �   ALTER TABLE ONLY public.userstories_userstory
    ADD CONSTRAINT userstories_userstory_owner_id_df53c64e_fk_users_user_id FOREIGN KEY (owner_id) REFERENCES public.users_user(id) DEFERRABLE INITIALLY DEFERRED;
 x   ALTER TABLE ONLY public.userstories_userstory DROP CONSTRAINT userstories_userstory_owner_id_df53c64e_fk_users_user_id;
       public          taiga    false    207    247    4071            I           2606    9779085 H   votes_vote votes_vote_content_type_id_c8375fe1_fk_django_content_type_id    FK CONSTRAINT     �   ALTER TABLE ONLY public.votes_vote
    ADD CONSTRAINT votes_vote_content_type_id_c8375fe1_fk_django_content_type_id FOREIGN KEY (content_type_id) REFERENCES public.django_content_type(id) DEFERRABLE INITIALLY DEFERRED;
 r   ALTER TABLE ONLY public.votes_vote DROP CONSTRAINT votes_vote_content_type_id_c8375fe1_fk_django_content_type_id;
       public          taiga    false    4066    341    205            J           2606    9779104 7   votes_vote votes_vote_user_id_24a74629_fk_users_user_id    FK CONSTRAINT     �   ALTER TABLE ONLY public.votes_vote
    ADD CONSTRAINT votes_vote_user_id_24a74629_fk_users_user_id FOREIGN KEY (user_id) REFERENCES public.users_user(id) DEFERRABLE INITIALLY DEFERRED;
 a   ALTER TABLE ONLY public.votes_vote DROP CONSTRAINT votes_vote_user_id_24a74629_fk_users_user_id;
       public          taiga    false    4071    341    207            K           2606    9779097 J   votes_votes votes_votes_content_type_id_29583576_fk_django_content_type_id    FK CONSTRAINT     �   ALTER TABLE ONLY public.votes_votes
    ADD CONSTRAINT votes_votes_content_type_id_29583576_fk_django_content_type_id FOREIGN KEY (content_type_id) REFERENCES public.django_content_type(id) DEFERRABLE INITIALLY DEFERRED;
 t   ALTER TABLE ONLY public.votes_votes DROP CONSTRAINT votes_votes_content_type_id_29583576_fk_django_content_type_id;
       public          taiga    false    343    205    4066            L           2606    9779131 L   webhooks_webhook webhooks_webhook_project_id_76846b5e_fk_projects_project_id    FK CONSTRAINT     �   ALTER TABLE ONLY public.webhooks_webhook
    ADD CONSTRAINT webhooks_webhook_project_id_76846b5e_fk_projects_project_id FOREIGN KEY (project_id) REFERENCES public.projects_project(id) DEFERRABLE INITIALLY DEFERRED;
 v   ALTER TABLE ONLY public.webhooks_webhook DROP CONSTRAINT webhooks_webhook_project_id_76846b5e_fk_projects_project_id;
       public          taiga    false    4125    345    215            M           2606    9779137 R   webhooks_webhooklog webhooks_webhooklog_webhook_id_646c2008_fk_webhooks_webhook_id    FK CONSTRAINT     �   ALTER TABLE ONLY public.webhooks_webhooklog
    ADD CONSTRAINT webhooks_webhooklog_webhook_id_646c2008_fk_webhooks_webhook_id FOREIGN KEY (webhook_id) REFERENCES public.webhooks_webhook(id) DEFERRABLE INITIALLY DEFERRED;
 |   ALTER TABLE ONLY public.webhooks_webhooklog DROP CONSTRAINT webhooks_webhooklog_webhook_id_646c2008_fk_webhooks_webhook_id;
       public          taiga    false    345    347    4548                        2606    9778034 F   wiki_wikilink wiki_wikilink_project_id_7dc700d7_fk_projects_project_id    FK CONSTRAINT     �   ALTER TABLE ONLY public.wiki_wikilink
    ADD CONSTRAINT wiki_wikilink_project_id_7dc700d7_fk_projects_project_id FOREIGN KEY (project_id) REFERENCES public.projects_project(id) DEFERRABLE INITIALLY DEFERRED;
 p   ALTER TABLE ONLY public.wiki_wikilink DROP CONSTRAINT wiki_wikilink_project_id_7dc700d7_fk_projects_project_id;
       public          taiga    false    273    4125    215            !           2606    9778042 F   wiki_wikipage wiki_wikipage_last_modifier_id_38be071c_fk_users_user_id    FK CONSTRAINT     �   ALTER TABLE ONLY public.wiki_wikipage
    ADD CONSTRAINT wiki_wikipage_last_modifier_id_38be071c_fk_users_user_id FOREIGN KEY (last_modifier_id) REFERENCES public.users_user(id) DEFERRABLE INITIALLY DEFERRED;
 p   ALTER TABLE ONLY public.wiki_wikipage DROP CONSTRAINT wiki_wikipage_last_modifier_id_38be071c_fk_users_user_id;
       public          taiga    false    207    275    4071            "           2606    9778047 >   wiki_wikipage wiki_wikipage_owner_id_f1f6c5fd_fk_users_user_id    FK CONSTRAINT     �   ALTER TABLE ONLY public.wiki_wikipage
    ADD CONSTRAINT wiki_wikipage_owner_id_f1f6c5fd_fk_users_user_id FOREIGN KEY (owner_id) REFERENCES public.users_user(id) DEFERRABLE INITIALLY DEFERRED;
 h   ALTER TABLE ONLY public.wiki_wikipage DROP CONSTRAINT wiki_wikipage_owner_id_f1f6c5fd_fk_users_user_id;
       public          taiga    false    207    4071    275            #           2606    9778052 F   wiki_wikipage wiki_wikipage_project_id_03a1e2ca_fk_projects_project_id    FK CONSTRAINT     �   ALTER TABLE ONLY public.wiki_wikipage
    ADD CONSTRAINT wiki_wikipage_project_id_03a1e2ca_fk_projects_project_id FOREIGN KEY (project_id) REFERENCES public.projects_project(id) DEFERRABLE INITIALLY DEFERRED;
 p   ALTER TABLE ONLY public.wiki_wikipage DROP CONSTRAINT wiki_wikipage_project_id_03a1e2ca_fk_projects_project_id;
       public          taiga    false    275    4125    215            8           2606    9778634 L   workspaces_workspace workspaces_workspace_owner_id_d8b120c0_fk_users_user_id    FK CONSTRAINT     �   ALTER TABLE ONLY public.workspaces_workspace
    ADD CONSTRAINT workspaces_workspace_owner_id_d8b120c0_fk_users_user_id FOREIGN KEY (owner_id) REFERENCES public.users_user(id) DEFERRABLE INITIALLY DEFERRED;
 v   ALTER TABLE ONLY public.workspaces_workspace DROP CONSTRAINT workspaces_workspace_owner_id_d8b120c0_fk_users_user_id;
       public          taiga    false    207    4071    312            N           2606    9779180 Q   workspaces_workspacemembership workspaces_workspace_user_id_091e94f3_fk_users_use    FK CONSTRAINT     �   ALTER TABLE ONLY public.workspaces_workspacemembership
    ADD CONSTRAINT workspaces_workspace_user_id_091e94f3_fk_users_use FOREIGN KEY (user_id) REFERENCES public.users_user(id) DEFERRABLE INITIALLY DEFERRED;
 {   ALTER TABLE ONLY public.workspaces_workspacemembership DROP CONSTRAINT workspaces_workspace_user_id_091e94f3_fk_users_use;
       public          taiga    false    349    4071    207            O           2606    9779185 V   workspaces_workspacemembership workspaces_workspace_workspace_id_d634b215_fk_workspace    FK CONSTRAINT     �   ALTER TABLE ONLY public.workspaces_workspacemembership
    ADD CONSTRAINT workspaces_workspace_workspace_id_d634b215_fk_workspace FOREIGN KEY (workspace_id) REFERENCES public.workspaces_workspace(id) DEFERRABLE INITIALLY DEFERRED;
 �   ALTER TABLE ONLY public.workspaces_workspacemembership DROP CONSTRAINT workspaces_workspace_workspace_id_d634b215_fk_workspace;
       public          taiga    false    4460    349    312            P           2606    9779190 [   workspaces_workspacemembership workspaces_workspace_workspace_role_id_39c459bf_fk_users_wor    FK CONSTRAINT     �   ALTER TABLE ONLY public.workspaces_workspacemembership
    ADD CONSTRAINT workspaces_workspace_workspace_role_id_39c459bf_fk_users_wor FOREIGN KEY (workspace_role_id) REFERENCES public.users_workspacerole(id) DEFERRABLE INITIALLY DEFERRED;
 �   ALTER TABLE ONLY public.workspaces_workspacemembership DROP CONSTRAINT workspaces_workspace_workspace_role_id_39c459bf_fk_users_wor;
       public          taiga    false    335    349    4519            �      xڋ���� � �      �      xڋ���� � �             xڋ���� � �      �   �
  xڍ��r�:���S�	nY��z�3ۙͭ�Rlu��m�l�Sy��H�8 ����E~e$!�"��p����6�/��1�׬�L��!/-u���]��eO�y\"ֵ![[��4~IrmA�	^����-+����y��Q�w�zD�w��������8_����ۘU�	ߴ���}�`���,⽃�/�ψ��
�
^?F�^k�ʋ�e���}d̻��]c�z�.xt��w���w�X�̳}̋:��w���B�{�rϮ!g�c��=�=k�c�?�RL���q����n8 &���u����1��_^���br�^�� ��_v Lm�m����=<���iX���~}^�J�iļL�ٌ�w�I���YϘ��5�?���x�.�F;�JLg%��F1��ƻi`�+�@��,�}0ι	h��G��&a%���)4�Dā�P�����P��Ș��c�����[����j�V@�m�k3I����hJJ����,)���2���x�>O�e<�ȭ5��%"2S*?<%���)!DrJf��D��y:�]a��My#�\����h�<<��va�l��ZǾ��6�� X�����XX�G�mrX,��e�.��m�?>�[V�Ր[�F$��� -r��� �n!H���$g��}��x\�­��1o��!�'w���ސ8�2����pԚm�sM~��|d�sͶ������G!Q��B ���k���vWv���u{�5�賃�1�诃��[B�Wr$��麘�e�=�:F�g���/��G��3�'�D�p���򝕵���9�r&2�"����L�����g#s~:��d����yX���p����
�����T	�(��2�05p��=��7�4��C+�����<Q0�D�P��?V�Ѵ��xn�^�|��"�"�{������"1��_D+qְ��o�>�<l;i���dp$�&>�(%�U��������T\���<>�C��=+:�������
	m@Fd�OE��!cD�(�{)��Kd g�?��1�=~6�>���6�[u���ɿ�b/�D�� x�"ޏY�"��+�x�=���ɣ<��e�6�'^T�2Ƣ��"\�X�`��Ƃ(m0^���B��!y�D��@aI�BP���4B&�m���Ʉ�[��qBau:��V&V�A�k�����]��g�4p�
1*΀�2P� !��!�
�a"mV{�s�=Ym��P4(m�J�1m+��U뗐�$^�����x�G��p�uh0�,}!I0�ea*��%1D]a�x�~|��\vòܧ��a����}yQ%��)���Ķ>es�6���)�#��J�J-oB���Z�Δr�6Ѩ\�29U�h�ܚ2r��w�\�m�2�j;��ܛ2�`m����)kqNVְ.����R�"r���ٜ��z�A�k��@B�?۬^���!��f�*���f�����֪~+��V�2��v0���eL����d��!���B����l��c���N���_2/�0�����f���7��1��p%O2:aT�L�R�,�n�ᘣM4꼓2'm���@)�0����o��i��&�m^�4��b�b�������,b��������x���ܤt��jw�����,5+��Fd{��#�4�͕)�9[_�e�������hp��u����"+�E�Wi�("�T�����^��#}��+�e�@^���[�GK�+R���9�{&͕���0�?u�g����c<e��~�G��}���d ҧ� B��}g���-�۰��h4"��d�R�,�R� b%��S:7*��aR�p���@�jw"���!Y�"�������C�����(g���/�(���O�^"������fժ������R��M��OxD�!�OxB� ;T�]	�V�\0�^��N�P{a!pc�Z�E�#+ �X��h�:f�;o���O�H�V��V��k�K� �}_P�����ө��k?,�Q��u� Q�w��l��(�~��Ms�Pu������EE��2Tk�8*ڤġz�Ģ����j���}il�p��l,e�7��V���.�p'+𥼚t���T�7k�j��6J�+B�Q�]��Ta�d�ve�1���8�fW�L�!>���p�4H-WN�y�%Y�tG���J�������t�`��`��̿"|�7 G���9����8�o�����P"�H�-�"nK+,�&�tk*s���6���t���9/eES��g�%��g��K"�����M���e�>��5��B��;*��M�����V���p/���H�L��G��CX�>�2b]?L�!ֵ	]4L���L�Ja�@�
Z�ѹL��L�1kݚG�1��
FE�"J9�Q�W]�`����8�ކ��M[�R��MeyMK�˱JD�Vy�cĴ�؁Ċ�������Ǽ�e-�x���"��Ȼ{�bWOm�=TŞ�W���F�L�!넃K'�$�$^���V�K4���N�L��V�J6�!y%y%����w�W8����X���l�"q�.���t.���в%�G",T����B<<a�Nݶ�z9f��(���x��J��+��� "p�
�+	�
`�XI �'`�N%A���y_<�%pOy)�'��_�D42Fs	�Xd�}�%>�}</o�a:g���@�󐤴��l�0%f���.5�iOw'�����f�Ⱥ�t�����t?��#��"����;��r�B;��z����b��e\�έ��:�Nny�R��&�r/�T��8��MrR�v�J��_y���$�u             xڋ���� � �      7      xڋ���� � �      9      xڋ���� � �      +      xڋ���� � �      1      xڋ���� � �      -      xڋ���� � �      3      xڋ���� � �      /      xڋ���� � �      5      xڋ���� � �      �      xڋ���� � �      �   �  xڕUђ� }&sGT��˝�PM+���]��FE�jwf�����D8���Y��S�)�!^��5C	+����{t����l�V�U�4k̓Xv����W����������e�3z	�A%�-�7V>��}q�9�A}�P��r���;/u��c� ���U�*0�_���U�=}��[UJ?��ӟ��\�ޚ,�cv7
�V=��x~�:S-:��]=�/���T���_^�Z�1��h��(�	�o�ՀTN�8~)�t��&�o�t�2V��]�?qw	�=p��������>���=U�J��Dg�X��������i3�w��K�	]tW�U���R��@H�7�-�[�aOU=�7Ĺ'f��Hݧl�����ft�]�+?�~�f�Y���}��4f�xu����j5�&m�-k�i��T���S���
RqT���e�(\Y���v2�9kUC�M+��4S��
�ew�NQ;{�	�D|i�y����vV�o�l�H�2&CO���fg"�6�WY�e���jԼ�46A/�U�,.�H��_�0�#jm�i�._[{+`���U���bvG�n�l6!�K����4n KO=��ד�{v�5��2 �Y��I�� vnJ7+J7^}=t7M�f��r�l"���ʊ���9� [��2dJOO�� �?����      �      xڕ\�r븎}vżO	�z�e�T��8�����������E���KwbK��@n�ڜ���x���.+�����x��
�������ͿM���k��7��J����p^"�m�U�=��"h:1�t�ӎVz�ݝ���g�����[�� �1섁�u��:������u��Ӹ!�X|d(7�4�ǃ�FEVQ;Y�)됥���|�{�\h����B#��TP�<����q�_����@����1IoZ�%!i�2������a���a���f����C��E���ЋX#�ĘA`b*�BG@Zqu��9�����G��� �"��#��*�r�we���b� �^���t�6��"#*/�͑�}9��HwZ�'ˉB�a nNV������"�G�19�+z��kC��@2P�d`��p�a�\�9���_�~8��$���E�p����~ܿ��Ur:�wS��҂N_���N������+G��^�{/�& X���(�v����}K�^u��' ƪ���A|Y�O����t�$���ӹ;�K�{D�m��w� *畚�(���H�AGˠBļc��U�ڝO�_�`���K0w�պ��"��_�+�|���q����,NZɱ�$njq���Z���s�Փtcw_���l�)�c�ӧ�f�BE�e3���$[���6^߾7�����GC��lV�q?\���
}p9�]ю|�rk�]*9�l\"	��&K���<kTZA���9v�~w���iJukt!�@��2��D�J64j�a��ig����3�܍��4�C��蓑A�"��@`�+���Z�߇�p�2\0�dڈs�P�����Y��q����3���8-m� z�|�?�V���a
��6L����,Qٌ��v��#��䕼�饥��B��^�c�"'��}"Ĥ�s�]�2^����:�����I��ɣ59�����H�u`U-�8�v^Q6W�`�j@� �.w3ʊ �	!@`��K�*�>��v8>�֧�'J��8�Am>�#U)��"YM�̘������1�0�!/�>����xb��|����*�؃�d����Zy���y��\|��Ƿ�ۍ;%8�y����_>_ڤ��6d�q�.��*$�5��C5�c_���\#;=a�e1�ă�9�8����˯Q�b��$�*a�< ea���3��o�����GH<2�M�v7�IJ��ِ޴��w@��OZ3L_�,N%Y�����O�|HiP�������0��Z<�v�D�#�h�*�X-�\�QAidq�������42������(��!%��=Y�x��qx�.΅�!=4���Cq.�sy���A�m�z�w�cR�7@x �G��K�y9> ��tѓ�g�7y��_~���7[.�ޟīH~�j�����u��J�ke�XTBhzE��^NF�H�7!��%*rz�A0S����� L!uUz�����W$ n-! ҧ	��O�������8�w���c���94FJ,�a�=�����T;��@�$�%{���6Pp�QNF��]Cc���d4*�P+[:��qvh���~���A�j�6G�dC3��2]�A�y.RO���u�)]��TA�T6�)q� r-cݴ��-am!�\���F��%�|.�eg�&cc�Pk��z8{��}����8��d`�%z"#�����$Դ!rI���k%��MB�"�$���OA-�݌M� 8.�e{�\��؄O
�� L��>P�9?	8�k�cWl�'%�
b:}��]�����d�m�`q�?_wț���"t�T5��WR^���/=Ug��"Q�_bڝDa���@����Y�d�3	"x��{DLedw8���/��H�g��"�T�0��჈G�A����'�;���������O@P;_՘(�;������z�?����L�k_�G����Q�����S5�I�(BϷ�@4�c��6Z64��b14�ت��{S�����T�������~s�>^e0�9ʼ��b���,&*cd��9��4�����J� � [6���lM�K�p�Py��S6PCP���(Cx�##��A���y7<���T��z�Х��U�CU}�Si_��c=*���MPe��0�*R�M,CH+ ��*��_)���� ��J�B�PYƵ�4�wZst܄��؜i5eLp�w����gpD(md���"�P�Q��6mM34쓭	���5�:���H#���2n�ml�N���5nH����{��0�(W`��jk?#�G|R���-���j!���5�(K��s	I�����M$*B�[�@پHO�i (q[�pbOa=�Sl⩵�P!���(���\��P[ͤ)�*&�A�@E��, ��߼�ް���d3���"{fGeO�?4��������P��]�>����ݟ\�@l0:����� 8s"�ࢸ��E�Sרt)��� M�Y�v{jih8;g_#ۻ������/Ҹ���<���o��Q�5�XR��價����Ue��e7ѣ(�ɹr�E�i֨]Á��b����,'�e��yBQ�m����b;?D%sb��	v��n��o�<�6Ş����"���cqd3�15c�8d���\k3$襎��
�4�a,M	�9_O;֩�6�48��|$�A;���6,�#G���S	��>�}��	&*�n% m���]>NW9fDn$�wlG@a~
�b�� �±X#�v�@��*��@Ĝ&�������W�kk=�m%���&c��jX��h�.4Yx�I(Rp+&����崋�/W�oZ�O[�Ƿ������a�)�0�����O��`�c�'_�ۣ���z,?0��iy=81Tr�����g����*�
2��6��p������/���؝ޞX��T�A;�g�� HYP�2!�6�vF�ru�����,Z�2�¬CP=�Wt2Vh�S��9Η�2R�!i�t!EE�pA��j���bZS�%;ŖWl�`(�����F���N��N�P�e�XSМ�ˈXsm> ����b,f�RY�X�ٙ���Ol
Tf����6�9�7���|��U0#���沔�����rPj3@ebE��j�/���~ގty�|�q����a�};��#we�/��W	����X�h����"N�f��[$��6�I�愴��� ��'��	�-�Ǭ��������k�f8ko�)�𽪢��TH�9���<�#��<Bau*�BSGTHV�#.����c� �9�(��b���އa��o>_+�{p�<կv#���k����@`�}�D��rRT�XI��#��� ��R�D�ڝvv:�D>/5�Ę�`�K�ގ�ܺ�
ZFgcVs��0��q>�K�'b՛[�c��˙M�Y����qCNŔ�2s���Ѹ�ې�
����M�zP�Qu �Dy>؝'�{f�^��v��OM\ue�0�¥/�TH&���/��5@8.;=��5�q�IߗQ��y�p|�>� @��w���I�~���i�AS0�3ԩ;5�A^��t��>)���b2�UPf����y��7��d�XV�6^}���cE^KC��@;ϲ��V�A��?AX4�\�h����񚧶ND1T�E;�r�9P5/Bx"���:]A�Dd���s�v��&w�����-+� z��4`�B4��M���ʙ���x���AĘ�B;�r�.7;{#�P �9�B;�rӄs;������֕��#+�']��;�y ��hs ��N7���##Ĩ����8�䟚�]�}G)�AQHc�~o<k6����P��.����i��#Kx��*��*�t�QI30�>�y�\y�!4�A[�Z��k ���e�2�8>dI\]�re����DCr��x�-�s��r/	��M��2a֞���� i���腬�@��*��'yx�E�:���鬲^9���qY>���~8ח��Y0�yd'!�R�ê;�D�x"Ep��e�Xn��gG�KH�JÀ�Y#��bx����^�s�o[��
޴�|�+�@y8O��*ޠHw��':�J�v�ʺ� �  �,�Ck���8�AP�97���*^��P���(S(WM� lRv������/��D&;m5�[.ʣ_�6��f~l5��΍eӽ�'o�K�����:5��A�Z�'�S�L5�����H�Y~D�J��3���|�TpH۞���DM�x�i^���DV%�T�&�RE@�>F,C����eT�&���t��~lG������dq�id֥#��ƽ(��JT��L͔�D�r;�MƆvY^%qG�)+�NV�nYZ�+����du�	�?�TK%����������u����mq.	����oO�rc��C-	�<|����'�ش����K�tk�������1N,w���ʐ}���p(�&��k�T�LW�z"1�����E�˕��of��.�n8gZ�6���/1)�n~MS/�T|_��v��5M�U����J�R]Y��w5AUH��=}37?62M��L �V����@-���O�_�DG�c>�@�~j�^�钒Jl͕��(Uo����F���}#]���?�`����)��7�~F�4����Z���	p��0�%'�7�BE��X8�#K�3����k�HҞ�di��Y'����c+T`����Y�[�����6�J>�������� �s��$0^�~��T-��*�s��eA�pW���3�,�5�1�A�g��_�?Sv�      V      xڋ���� � �      :      xڋ���� � �      <      xڋ���� � �      >      xڋ���� � �      @      xڋ���� � �      '      xڋ���� � �      )      xڋ���� � �      A      xڋ���� � �      C      xڋ���� � �      E      xڋ���� � �      %      xڋ���� � �            xڋ���� � �            xڋ���� � �            xڋ���� � �            xڋ���� � �            xڋ���� � �            xڋ���� � �      
   :  x�}�Kn[1E��*:/��b��et�(�He�� ���u���ŋ�Ϣ?t~�~j|.����{�TN�����{3�x�$eEs�� P~1��5"z@
@�#6�Th��/0aLN��)$���O�L���#P�,t�Ҝ�`��:��B��z8�8�b����+΃���:C鞉������m�e�w�Z BN��+�aF���c���Wz5)���GTi�Wf�iC�&�����	y�Ad���_�T��]x+"Uڿ�פA��ە���!�w�t2S_2�nZFv�r�NV4�����v�7R����6.#�-;AR���4cB��R�e�M�3���O�@���=���.�]�̈�Q�}�O-���e���q�rg*떻���~��ߕ������o�30p�����u�	�;��u��*��۝�$��c�Ҷ����}"�2�!���oq��ΐ�Q�t���U�W1���B�ޕ�^��ߡi%�Leݹ�'��,t�Ҿ�u	����f�7�^n�X������[$]��O0&����[$%D��쐔���Z%eD��+e�g@�&* ��7�H��Uz�H
I�.��;2i&��䥒 )�>�Ε@�"�\�2�>����J�pD��'���@����ZԼ�%�(�1H�4�P-�F��x��ۓ�<���	��G`�*�*�}On$�F^t��*���}ld�6R�MW�~��{H�pb��Wi_`Ӂ!mHr6�04G�g�ÂWz4bn����*5�v�F��Y?�N���UY�[�	�x�F���>I��� �=UڧE������~���o �            xڋ���� � �      G      xڋ���� � �         r  xڕ�1k�0����W2�X��rƒ�ХC�.�8��]�@���:����~$�Y����@Wڗ���Gz�?.�4ݟqig�&�D/��{?�~��k8�O뮜��N���]�iw����c��O��:��8�tY�n��Di�g�\�3F�Lg�|t�1rh�C"��)��f��sM��)tOD(�Qᨉ"�E3G]�&��GsM�.�r�Em�zD[N�(R]�p�Em�zD1�D��']�&��G�c�D��G]�&��GsM�.�t�6�e�A�>k�K�����j��u9a�^Oh�m�a�j���e�Um����-��K�-��-�b+�nآm�t�
�V����� R)i      K   �   x�}�1n�@Dњs
�%�+i{�r 7B,UA\X��g0�?�*��m����0�î����_������|�Y�n�}��ʖ�������,G�����XQ�hRLJ�JL,RLt%&�(��]���P�Th����6)t��e\��:#�D]�l���e�
ek
�I���B������d������b������R�jT9��<�zZ��q1V�.��z^��}1�? �h.�      �   �  x�}����0����=�h��ftL�-쥔�{)�N�R���};�H�[�ٟH�̷�À9�'�������tμ7�����_.���hw������]&�7?�_o�6�Ἱ�����H{����m���۰C��;\�7��j�n�M�^��]���l^����y���G��q������K�vI����t��rG��p���㸄n� ���%��zǅ�M]�ۂ�G8@M�98��$|���v@�B������9�Z|_���+?i|/������w���;W�q��{���a���|j|\�.j|��T���G�O?L|oU~����G�w5~X��k� ���p�������X���'�s>����?.����P��;�������GT���1��T����V>i|��\��'�O�l��@�s����G~�5>��<��,�!��|燨�Y�৙�*?����G~�5~Z�4~�����Ow~�
?	~�2w��A�@����	P5z�z�f��� )�cE�X-}�8����F���G��+ʏ�鷶���i�'�O@Y�T& �HzB^�ܬ@(2��k�ځ�� +!�Y+A�)�e
�܂�� �1�����Z��� �9Y&�Aa҂d��aN¤'!�M��ME�j�Z�I�BȲ0)Y��օ ��秮���r��      �   �   x�u�;N�@������c<���I�� �{�m���~鋊���EL�n�� ���������$�t�U}V������=�)-�v{ٽX =#kAF 3#[A(����!�K�xҠt�e��P<�AY�#S|���iʀ�L�œeB4S|�B�ԃ�A�L�}���� [��m��q����q=�����M�{���W�f��'�Buco�K�|����ޟ < ���N      �   1  xڍ�K�1EǕU0G��̈�&H|� !��?��^�)Du{���8��o�hۗ�ϯ�?���߾~�}���ǆ�M�70^�e��f�.��������}���jT��������-~)$,���P��V)<|L
m�B�F=(����G�8�?�{c|I?��[:1��<�Q�D]�])1K]�I����#)j<C�A����5)��4(�HLL
�4G�T)��J�.Q%��e�*/�@�%��?�KGsA��9�er䜿�A3POL&���ή�IM�q/b�g�m�ԩgy\�Jdڗ���8���ǣ�����GS���r����ez-w�D��4mHU�ub���sB��c���d89�x'0L[���4�Ph'�O�Yj��@������ h��r�M�*ɹ�qjhV���8Ȥdͤ�T!F!�N��a	��1�aBNv |ݺ�n�3n7���E�b*),��5��S����`�.����TÄ5v2��,Z�cC�&�k{�c���s0F�u�,:���5sU_�}9�bo�f��������,�U��U�3%�>9�M�cP����=bW5L��BbN3S�Pq0)�&��Λ�Cbɸ,i8�U�P�X��Ҳ-/�=�øCj���!j�^�a'����B�*%�5�E�RhJ���$U� KR�.	S���~�Ha�#7��Q���C��������
��ʸ���,��B���O�v����3l�ɪ�]I'd�B8P�!������i�}F��t���s�E6�`ˮM˹�O5�\I�5
ǞG�IٛjL!>�Zk��r�      �   ^  x�U��q�@C��bq�ur������KOF
��Lpx���������{TZ����|P�/أ2�s{T&~j���{Tv��Qy�>�_*�j%ޢZ*��-ZK�ߟ���K�Qq�6�uW�A�Q�FU�|*!������N�~;�;5�3:!��	������':!jtB��	��N�~;�����h�S����:u���5:!��آb�N��t��	�n'о�@/;OtB��	X�b�N�=:!��8��:� �v��Ӑ��N e�)�r#f����~#RpD�H���SVr�%�A��%��#fǁt��#�qD:�d�q��8 9J�������M���@:�HǷ�t��#�q��8 9J������+/G̎��-��2-�L�-�s���5�(�n�\7L����I���x�@�h��w��t�����wN0�i�gj�y�?w�>�Sop���9�����o�.��|����7�����Cq������ā;q�R:��p�����6�|V���8���nǁ�1܏��9�9�9�%9�-9�5iqOyQ�arRܔG��U9pVwW�iX�iY�iZ��/��05      �   �   x�m�1N1D��u��W�n{<�"�' !$�J$\�rZ��K/�V^���<���T^^�?��%���*c����g��2CLM��g��T:����e�P�*��,[VW��;�e���m�7�ȘuW�v�1�)fs�;<2fm�ٺ��e�:��:G��=*��AM=GZ�Ŝc�����fN�ͨ�Y �͜fclz�5��n3��߮ ����      �   	  xڽX�n�F}����7m��}��l�Lf���m�� @���E*$5�&��Ӵ�HY���m�d���:]uN5���w��x��6�Ƈ�W��#�]��pk�Z譅~�����M�c�i$هD����4���=َ�S��K�l���O{���;8�>�������W��n^��5^⊌)c���2N�%\}���L^2ˤ�c��Uq]���*s��?�0W���Cn=�q����C���h���v~Ka^�_ի�R�I*]g�E#2��� Ytޥd� Tc����,;帖�6"�̛U7\����M�2�����n�D�]!E��usKg?}l�+����HAm[ͧ��ē.�t񤯦�������a���n�i�s;��:��yN�%y�{��z���j�|,���H�1��c�]͸:�e���	X��a��cXJ'�9�ү�J��Jx�C*�BL�{��*e钓)8�a�)�pץ��MSKQ�Y���x5��Y��/�>���*�Y��B�Xg��z���H��#��F��0�d�{8�q�����yJ�/�F�9^�ǡH�.���6�D��� eȖEV����\e�s�2׵�������ˊ_�2�o�a��A�ø!��8�y���R��1�ڹ
'^�x�{/z�?��֛�ݼ�F���|j����L[sXwO��=y8�@sō;�@b��[��lccJ�(�%��I�f�*�N5K*x�8fj� �O6I��c�*qQ�9<��vӖu��1�-6�k{�p�.���v�W�O'z�D�����Ë���0&����\.�yLi��G ($I)��Ȟ�6��Q҂s�ϡ���	(q�4���x&˄S�&����t1Jk'���� �S�.d���9�&8�X��3�-��9*m�5��*U&]&�z���~H1m@�4�-�L;P�vc��wn�č����>�[��^yp���0�<�
i��r@8�e}D\i�?[y-t`a�Z�q6��e�qZ�Ip�ǚ�&�F
-���!��<@�2�P~袼����zK��/R�#z�A�݄��M���!Pkm���:2�k�t���aڶ�9q���l�U��P8_��)h@$�	��bWn���N�Sh,���	5�&4:k��ɳEuˮ�^ۆ+k��1�A1U}a�$^.���>uȑ��ڏ���@�Ԕ� �js�H��H���<ܼ��h�f(fO&eT�i��Řzخ0R�A-� ^>!�9;�I�V�$��M0��I&)4�#a�)��$�xh"�y���JGB�22,֍��^@��$�hXσ�̾pe���T5�nN73�R?A�~Bn��������y�[/����
o���ZC<��fJݧ4T�"��Q��C)wc�%y��y=`�'S(<��a�0n���9܊U=������r<�Pi�b��K�1��xTN�&��sǼo ��Űv
�FZ���Yƌ<���j�bo�B�K��J�I?�%�Z]��WV��z�#/z�E���o~R��ү�趶/-�5��6B��1M�n�F�X}#cRn�_JY�K�E��1F��A9�+� ��n"XG���RV��`!Rb�k����*DѠ�19I�B�5�*h��5���p�I�\����w���?�>|�m0�\�,����v�X.�:�b����xJH#�Y`}8 �R|��@�z�3���{,1Ԋ��(څ(ھ��)��m�����A��/�|�k�et��PQ����?ZƧ���������ӻ��4=�O�ǧe|�m��tuS�D\�M��%U���Z�0�v���10�m~I����/��Ve���%!GџB��u����|I��p���.Mˊ�-#���<�Ew{=�	d���e��xI���·[�.�A6G#���3$μߢ���Ӳg����AT�TZ�M�b����Δq�S��J��:'�4Ԩ�25��5�+�|l�mru�A����V��1\:�H&s�$_6(^�����f(�:����T푁n�4��r'�W�@��M���B{�:0)h�3qw-ɹ��P�t\y�|>�{�=�+㯻�0l6x�rQ��T�6Cl�-?�w�.�b��������7���rv �)V-��t��l]I�ŗ���4���ߡ�n�SU�j�Lu�Q��pu���֫Фڋ�Y�p��A!5�3X%�n����C__�e���"G;�v�������劮�W{�U�6	�i9���G�y��0��Yha��˥�>���@z}W���h�2:2�DJ��6f��^���j��MH8��k�>�$|4^?�R��ˋ��� `b�f            xڋ���� � �      �   �  x��X�o�6~v�
�{��lO����K�&�Vt�@��`���F"U�����w�%��S;풢�<�>�������e��T�����H!ERƚ���6s�8�	S��S&$��_HH
T�ɘ��)�ωZ�Ih��	��H	�2��<6�1�2L�%���#�n�Т�V�Z�~@��Q.4��RT��Di��0����3�s�XHY��HS�	g$".s@��#�c��X����z�;QP!7s����KByB��s�"��`T3�������V�3�H\*-r��x~8��a��4����Qtr���G�Co:B�OO|ꍦad�$g��{)�����^�S�W�?%����[�2�K!s���;ؕ�j���e5��FƔ*a�W��rn�P�xWUSu�9���w���i����6�z�LH3�a�M��/F&dF�Wfgq&$8Ni� eKV�2�3�2^f�Z��x���u��de���`�Uz��<���d���a0>��6��y��`�O�G�hPz',C|2l�ؐ�_��§�t!8�@�z�u65d��Z�,���Y��B@-������幍��+Q��k���h'��J��;x�v�6���s���vmU#W�����߲���QZ��v��qK1�'�b�R�ڊSKq�^��{5;!r`����8f}{���]7W}{�B�{���_9�AOu��z:_?�<�ɾK"|�x:�/E^�T�;��!��[�?�^���Bk����M��{ww��$S���%��w�c��P��W�c�j#ۗ��ÙYz�"�;��,q���?�;pf��X5�U���J�-N�� �C9�ܖ�{3ҙ��/݅���S�	<Ȏ�?G�C���zL�&�_������y���{M���]��0��3ӝ`($�B:�Qշ<p���R)yQjz��VV�̱�0�$
��w����3�q�6?MS����z~�n�jD�u6���k@�$�1�l���(�4ԃ\$,]���?�d�
{z3�4��D3tp������Է葾]��,�����~�>ݛ?�u��Hi��p�$1x���7�YRkoR;�+5�b�<�p\�@�h_�izr��T����8��}��yK�&�Ɂ?�z���"�E�1�9
zo(���w��Z��Thz!����)�sCU�r�� �Y
y[���@^,��Y����Xg5ˁ�-���\���p���8�M�9�j�9��o@���(4�� i�4좡D$�"G�)�}MIV��ļaixǍC��90kJ�*2����
*���
,TŴT������V�)�XB	��y���h2�>�jF���j���v�f�jv�f�jv�f�jv�f�j~���7��ٱ��d5w�x���͛ì�N"<��f(����ϲ�;�#X̓o�j~_�fб���qw]d��|��~ttt�*u��      �   :  x�uԻj�0��z�5�K_�ƁI�&͒&���ߟo�����(�����,�͒5C;��͒g�Xn�ղ5��1Lj�>���|�b��8G��a�׿���o��5sL�w6�˶��y��az��e�s���\��˞Z����`�TA��DhTGdx����TegxF�::;ϵS���ԀNut��k�"8U��{A�::/�S���ԀNut�^j�"8U�9z�S�'�کNUvj@�::S�QC�
�=3UK��}@l�'ߐ*}D�_���4�8{bU+���,����=�UI�| ��b,�A�Jb�q�����w�^�}�      Q      xڋ���� � �      S      xڋ���� � �      M   �   x�}�1n�@Dњs
�%�+i{�r 7B,UA\X��g0�?�*��m����0�î����_������|�Y�n�}��ʖ�������,G�����XQ�hRLJ�JL,RLt%&�(��]���P�Th����6)t��e\��:#�D]�l���e�
ek
�I���B������d������b������R�jT9��<�zZ��q1V�.��z^��}1�? �h.�      �   �  x�}�OK�@����Sz�t�o�R+x��ً�T
�HR(~{7�$f2;sg���O���.����?x���]{��x�v?C�5��(�t?4�x�v�|��xk?ο�K?�n�x:?=���a:��XO�ʈ�w?�ga�M��ɤW�闕�-�yܽt�^���X�ÓNI�P_�r�X�bO+P�b�-nJ�j.�*Y���D�:5K�Y�h�:�m�,B�%��� S��M[��b�]�6s�"��:[am���im��m�٪�m�lRۂl��r6��`6��PvQ��ٚ�v�l��}�ִ���V�o�uQ�/٤��X;�lZ;�lV;��v�����k7)����6�v���E�f�&�����3u���g���my<��׆OiK���2o�eF���g��-��R�S	����ZZ�����bڲ����v��
�y5�g���h7]�}NG���t�<��q���xw4��쾬����|�?TU���      O   �   x�}�1n�@Dњs
�%�+i{�r 7B,UA\X��g0�?�*��m����0�î����_������|�Y�n�}��ʖ�������,G�����XQ�hRLJ�JL,RLt%&�(��]���P�Th����6)t��e\��:#�D]�l���e�
ek
�I���B������d������b������R�jT9��<�zZ��q1V�.��z^��}1�? �h.�      �   U  xڅֽn�0�ᙼ
�]���@�����f��H���l��D�C�	�`��@��_D'�A������qx�I%^��÷P��'c��q{�I-�����Oߞ�B��po����q�;iƷm�S����0���S�{�v8���;i����
+.�a��`�x�>�����ߏ�� ��J��~��+���"�2���i�J�P2��M�� �RE%(���LДSON04T'(ؒT�RW�jB��T'�g�z%���_mCKM�*(IM&U�"5�R�I��ReX�YJ���6J-��KR�K}Ej	i �6Ju�J�R����I���9E��L�k1r�RM��%)�#���=�(e����X$̫[+�K]$�R�	�RC�OR��'�)���Z�<!��䓔/�_I�"�Ij�"�$��"�LjkE
�_)]���/RXJ-Y��o�2I.$k�I��[�R|�JKWi���������.A�H��H�Hr啔�$W�I�Pr�R��Ra+�ƒ#�q.9&O0&W��	k�b3!](H�	�D�j5!�(��	�H����X)ȇ�2�rB�S����vB�TǓgR�z��VA>�|-V@�'O�
Ҁ�|�`���~H)�0MPp      U      xڋ���� � �      X      xڋ���� � �            xڋ���� � �      Z      xڋ���� � �         �  x���r۶�������ā8�.�C�=��9����&a�1E� ������DRtt0��X�E�D~��~�X D�(XTƞ�դ�{�X�&��U��q���	��8K�}������� �puB�D�CHqV��MR����&
~��IH'�r��!Uȕ�tS�;Uy�"�V�<P+U妪v�J�|�z���T�NՈk��JU$\ɶ�uI�SXP�[]��G]�[Ws�aP��0u�;����a�0sf;�S!oM`	o���2ߩ�C�e�*���wq��H�[Y1"i�L�m��$�I��j23�S8�4�w� p
[�fp����"�5�?KgY�U����V�_୍/^k��k�f��"K�i�\��rQ�h^�Yru��|q�*W��^�?xS?�ԔMM��l^ge��=;3�ŉA	T����c[_��5MQOг>za��?�,�ȡP\�Y
׎�i\����\�O��#k�Ҧ�c���&g6!�F�l8 ͆~��G������=7��q�0yz���g^c�h��{���B��;xoKA7 �[�l+������..&E�E^g�����8Gge��P�v>�^_���U��JxY	��ދ�Ŗ���b>/m��lfP9�4�K[T�զ���q����$�[���k)��L�)���Ǟ
*yon9<�c��C�>���R�;��a���?{�����{��@U�y�\SB�������8��$��:%'��9��x��C�|l�kϼaNYH���M=�щp1�˅g�0g�Rҹ\��#�����=j!z=��m�G=�{�.���P�=��Тo�f=����{��Co���*�9�5���t`΃>�q�7��6�7����!��yY��,A���8��5� ��n�.�O���-Pߘ�ɷMM����K��*K�q����z(:cF������}D%#���ژtZ�*#@��>�9���F����ɏ��*<��:+�}6�D5���E���l���!��Z�T�}�V��x�Lg۞��}��F3s��Y$#)��I;�O��h�+>�Ϣ��L�\w>��1�uSj9�v���t�,
N�	��9�u�<,`Ń�<�{7F������̢�FUe��	 ��Q�u9�yV�U�2]$u�1��M�����<������_���Xi:]d9�͜5���oL����y�G�][]?����^�J�s�F��T]�T�@^U���.���R=�#R ��ݧ$tz�C�I�^��i��k�<̻�GQ8�7ա�dLȮ3�M��0o�	,����1v@<����B#�T��y3O����'9t���K�E��<ϛyN1�?١�Z�ޟ�k�<ϛy���E��qꨛ�i����(ő�~�c� �؄I�r�󱿗yl���25��Hqj���@�b��@ha͐缫�����k�_>���l��WpfEQ_v/%�]�(�c�艵��{L=~`J�y̩c�i-���o����C���i�/��'�zL��1����Y���i���Z�K�߆��O�»��B;��yb�r�G���:�������<��c�G����4e]M2���k�����OL2�/~�����X�1�!���Un�wi��3|���/wɋ��"�ڲ(�`�
�aa�����s�����S�:Kr�r��䨬�p��ҨiYͳz��>	#.��L������������EO(����v�����'�T8���aуg��<�kV������A?ҽ�[m�w�s��^.7{�&�Xe1��m�kk��I�5Wj��kq��z�U�����s����e�)��
�q�jZ.�U�8�'��"MM(�K@�(gW-�}t�P��[�.
�toK���>-����˶*����{[� W��]��j��.O��.�ho�Ȫ`���.��|�}���p*��E�73x�;� �f{|a��e���:��W��
������^�ɷ ~�lSb>��8+��K.�%\�mA΍]����*61��2N�[�)פ���U�����j����Oԍ( ���spC?�l����;�o�ϙ���TCz��ܜ���_��ʷPz636K�٦3\�O�>�	�Ͽ�n��@�����"
5��	S8�;y�]�m_�i��p�Ν���AD�w������å ��Z��s�����ǋ[ĉߑ�Ԥ��.�0��7��ޭA�Q?5��ƍ���'ͣ~�)���,�%� �c��0��;2������i��A^�8�{rtt����i      ^      xڋ���� � �      \      xڋ���� � �            xڋ���� � �      �   u  x�͖MK�0���oqu��G{ѓ 
�����n۬M����ݙ�iΡ�d��)��u��)Bl��۠r���Mo��֗0�g���1�a>�Q�>m�54��Z�����9*����&�tPAR�w����3���8��'��^�kz�ӏ��,t��M�H�E�1(A�� �������F�q��d����HdiBH�raBH�`���d�+RB��)!��!#$I�+0�����h�-+ L�8���u���0�<XIa�}���0�@ؿR�W�����[l荷����W�fj�p1�Qݶ+�d�-��x�ɺ� D� ����d2TW��ʯ�U��2�ݬ�5�>�+x�C��[����N��s�� �ڵ      �     xڕ�iS"��?3���f(�/F��#��b���Dܨ�E�f��_R�ށ9��6m覊筬7�1-�쓏�?�!\�1G�S~��vz"s��j�ߞ��]#7W��(k��W��g��w��4*�8=8��64/��_��I)��U��0��9�a���R���IGa��(�,-�G��b�R� B>�j�c��9RT!F���}��K?�� &ra4�6JF�Se����y�����f_?<�kv�8m>��[��Һ��˫�%}�w����z�еt�aO�zp��fk�z7���Ȥ{M3M>p���-�i-�N\i�����
���]�$l��q����Ģ�ac��_ug�ո�^�nm��{z�z6�tH�lrV���������_Vx1�vX���E���m��bIv�έ�Ly�5�F�D�T�Dx�6`�H3~����OKvT؅{
�!	HP�b@�2d���+Ǵ�����q� �&����ǧJ��a�m�C����
��

�[Yj0�^�()��I̬C�0�(��Eű9iL�I6Ȏf�`+��M�bSN�adÝ��0k���Q�)a��v]NRZ��`T�0άacj�V���Rɱ��8�՟޷�VcT4E8,������+�;��!T�0���q�"QN�5�-Z!p#G�Q�4{��E*����V~�J��UQ�qaٱ"SB(�t]+�S����6X�0BNc�
rX����+z�/Z�h��+Q��� H+]1�'D��N&���K�}�F:Mc�-�H�@dS�t��Њ*BvI�<3Eka���N[i� ����R��J��DhM9,G�qFd"��e�	%l���6d����P��"(�P�$:F{�G(�Z���b��6\�H�4���""����.�FB
�K%��$j	�	��\\��RV���o��a��M��.:m|K�˕��_����4҄MSz{��|�=��Z.����1\0aFO���[cz�{HSq���� 0���Q���#�M�����Ѽ�M����a��N���}��O������荅�U&�F�E�*���.ީ��ժ�ܰ�9���i���	������U�����{E���W���yrW��\y~�R_�V��Y��,�����|��>�K��J3���wv"�s%��ʠw1Ti촄b��lث���G�Bzgs����rB}��m�4Z��s����K��ǝ�[���������jQ{���X�*n��g���LFK�������!ʕ�݈Pp_�'���5X
��U!x�n�V}M���}��j��Y�[�'y2�����q���y�Թ=��Vj�.��+�1l�5Z���������P��̃!@�3<lÕ!�c {Od�%���1Q)e����u\�5���?�8�������1�K��������ߐ���\̺*^��Ѳ9��5\��_5]�f��'�bY���3����
�(	�������uN�"Z��v�-k�֙$�q����z*.��C5�U��h�Ӑ5�y:�˪�yP_d��&]���|7a�B��,-�4��gF嬢[�!l'o�`�$x-c:0)	��0��:�΋��mv�ת������|yQy��c�=�&��a����j���ӗ����sv��+Vq��7���w�`�Cp�ȩ�x5c��9���FZ����{��C� R�����|ܭ�.�/A:�^ٷ1yu:�ly�����k֮s�Y�d.�D���z�ր�*n{H�e`W)l_m�;޶}�J������t�D*��ъ�k�%�$7���ѷo��X��      `   w   xڝ�;�0D���Z������G$�`r�l���[�jt�Ӎ�����$[֔��)�-�}�״䟝��:7E?>��QԤ�aHiА�AK�);���1�r�H�אW���Z��	�H���      b      xڋ���� � �            xڋ���� � �            xڋ���� � �      d      xڋ���� � �      f      xڋ���� � �      h      xڋ���� � �      j      xڋ���� � �      l      xڋ���� � �      "      xڋ���� � �      $      xڋ���� � �      I   >  x�}�Ko� ��̯`_���&�N�V��Q��n0fG`OU�{���8��+�#��{�L����j�;#��U��ʊ�Q� �Y K|��M��фRH���4�Iz��S�&!qZZ�������V����'͠@Ե��6+<d?�k��B�������;n_���h�@�pl
���4J�,-�SC��^X���O��^��� ���kTF�s�_	�)���e���8�����^p�`��B�#нj�B,5�x�
���Ƭ�<�i(�b��1�V��4�u�s:@�!����7����x�U���dJR m�2�C?+��k<8e��*Z�x
�|6�*�F�2�z{:N��ɚ!����~����%ކ64n0� l��uz�&e���� tJP�6��l�]�4����
w@�G0!P��?�]l����p�I�|��޲�~����w�P~y렯`_}�;�l2�X\�J��TV�G�U�����x!�I M��՗�(�$e�/�)�G"�lp}���޹{!����ޝ����˕��'Eq�rGw��g���j�����      n   H   x�˹ !�@[�˗��q����2�T5��`�:.t��9���O-|��Ɨo%�\�t���$��d�     