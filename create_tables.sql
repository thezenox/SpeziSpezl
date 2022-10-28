--
-- PostgreSQL database dump
--

-- Dumped from database version 13.7 (Debian 13.7-0+deb11u1)
-- Dumped by pg_dump version 13.7 (Debian 13.7-0+deb11u1)

SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SELECT pg_catalog.set_config('search_path', '', false);
SET check_function_bodies = false;
SET xmloption = content;
SET client_min_messages = warning;
SET row_security = off;

--
-- Name: spezispezl; Type: SCHEMA; Schema: -; Owner: spezl
--

CREATE SCHEMA spezispezl;


ALTER SCHEMA spezispezl OWNER TO spezl;

--
-- Name: add_balance(bigint, numeric, text); Type: FUNCTION; Schema: public; Owner: spezl
--

CREATE FUNCTION public.add_balance(userid bigint, price numeric, tname text) RETURNS void
    LANGUAGE plpgsql
    AS $$
BEGIN
        insert into spezispezl.transactions (user_id, source, product, price, balance_new, sender,
                          verified, committed)
        values (userid,'paypal', 'deposit', price, (select balance from spezispezl."user" where "user".user_id = userid) + price, tname , true, true );

        update spezispezl."user" set balance = balance + price where user_id = userid;
END;
$$;


ALTER FUNCTION public.add_balance(userid bigint, price numeric, tname text) OWNER TO spezl;

--
-- Name: get_price(text, text); Type: FUNCTION; Schema: spezispezl; Owner: spezl
--

CREATE FUNCTION spezispezl.get_price(card text, device text) RETURNS TABLE(slot integer, product_id integer, items integer, price numeric, price_fix numeric, name text, display_name text, property integer)
    LANGUAGE plpgsql
    AS $$
BEGIN
        return query
            EXECUTE format('select c.slot,p.product_id, c.items, p.%s as price, p.price_fix as price_fix, p.name, p.display_name , p.property from spezispezl.config c, spezispezl.products p where c.device = ''%s'' and p.name = c.product',
        (select price_group from spezispezl.user where user_id = (select user_id from spezispezl.cards where card_id = card)), device);
END;
$$;


ALTER FUNCTION spezispezl.get_price(card text, device text) OWNER TO spezl;

--
-- Name: get_price_from_token(text, text); Type: FUNCTION; Schema: spezispezl; Owner: spezl
--

CREATE FUNCTION spezispezl.get_price_from_token(utoken text, device text) RETURNS TABLE(slot integer, product_id integer, items integer, price numeric, price_fix numeric, name text, display_name text, property integer, price_group text)
    LANGUAGE plpgsql
    AS $$
BEGIN
        return query
            EXECUTE format('select c.slot,p.product_id, c.items, p.%s as price, p.price_fix as price_fix, p.name, p.display_name , p.property , ''%s'' as price_group from spezispezl.config c, spezispezl.products p where c.device = ''%s'' and p.name = c.product and p.visible',
        (select u.price_group from spezispezl.user u where user_id = (select t.user_id from spezispezl.token t where t.token = utoken)), (select u.price_group from spezispezl.user u where user_id = (select t.user_id from spezispezl.token t where t.token = utoken)), device);

END;
$$;


ALTER FUNCTION spezispezl.get_price_from_token(utoken text, device text) OWNER TO spezl;

SET default_tablespace = '';

SET default_table_access_method = heap;

--
-- Name: cards; Type: TABLE; Schema: spezispezl; Owner: spezl
--

CREATE TABLE spezispezl.cards (
    card_id text NOT NULL,
    user_id bigint,
    active boolean DEFAULT true,
    time_added timestamp with time zone DEFAULT CURRENT_TIMESTAMP
);


ALTER TABLE spezispezl.cards OWNER TO spezl;

--
-- Name: config; Type: TABLE; Schema: spezispezl; Owner: spezl
--

CREATE TABLE spezispezl.config (
    device text,
    slot integer,
    product text,
    items integer DEFAULT 0,
    last_request timestamp with time zone,
    max_slots integer,
    max_items integer
);


ALTER TABLE spezispezl.config OWNER TO spezl;

--
-- Name: products; Type: TABLE; Schema: spezispezl; Owner: spezl
--

CREATE TABLE spezispezl.products (
    name text NOT NULL,
    display_name text,
    price_reg numeric(6,4),
    price_asc numeric(6,4),
    product_id integer NOT NULL,
    visible boolean DEFAULT false,
    property integer DEFAULT 0,
    price_maintenance numeric(6,4) DEFAULT 0,
    price_fix numeric(6,4) DEFAULT 0,
    price_purchase numeric(6,4) DEFAULT 0,
    caffeine integer DEFAULT 0,
    alcohol integer DEFAULT 0
);


ALTER TABLE spezispezl.products OWNER TO spezl;

--
-- Name: COLUMN products.caffeine; Type: COMMENT; Schema: spezispezl; Owner: spezl
--

COMMENT ON COLUMN spezispezl.products.caffeine IS 'mg per product';


--
-- Name: COLUMN products.alcohol; Type: COMMENT; Schema: spezispezl; Owner: spezl
--

COMMENT ON COLUMN spezispezl.products.alcohol IS 'ml per product';


--
-- Name: sensors; Type: TABLE; Schema: spezispezl; Owner: spezl
--

CREATE TABLE spezispezl.sensors (
    sensor_id integer,
    "time" timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    value double precision NOT NULL
);


ALTER TABLE spezispezl.sensors OWNER TO spezl;

--
-- Name: token; Type: TABLE; Schema: spezispezl; Owner: spezl
--

CREATE TABLE spezispezl.token (
    user_id integer NOT NULL,
    token text,
    time_created timestamp without time zone DEFAULT CURRENT_TIMESTAMP
);


ALTER TABLE spezispezl.token OWNER TO spezl;

--
-- Name: transactions; Type: TABLE; Schema: spezispezl; Owner: spezl
--

CREATE TABLE spezispezl.transactions (
    id bigint NOT NULL,
    user_id bigint,
    source text,
    slot integer,
    product text,
    price numeric(5,2),
    "time" timestamp with time zone DEFAULT CURRENT_TIMESTAMP,
    balance_new numeric(7,2),
    transaction_id text,
    sender text,
    verified boolean DEFAULT false,
    items integer,
    committed boolean DEFAULT true,
    fee numeric(5,2) DEFAULT 0,
    parameter real
);


ALTER TABLE spezispezl.transactions OWNER TO spezl;

--
-- Name: transactions_id_seq; Type: SEQUENCE; Schema: spezispezl; Owner: spezl
--

CREATE SEQUENCE spezispezl.transactions_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE spezispezl.transactions_id_seq OWNER TO spezl;

--
-- Name: transactions_id_seq; Type: SEQUENCE OWNED BY; Schema: spezispezl; Owner: spezl
--

ALTER SEQUENCE spezispezl.transactions_id_seq OWNED BY spezispezl.transactions.id;


--
-- Name: user; Type: TABLE; Schema: spezispezl; Owner: spezl
--

CREATE TABLE spezispezl."user" (
    user_id bigint NOT NULL,
    name text,
    surname text,
    mail text NOT NULL,
    user_level text DEFAULT 'user'::text,
    balance numeric(7,2) DEFAULT 0,
    price_group text DEFAULT 'price_reg'::text NOT NULL,
    trusted boolean DEFAULT false,
    password text,
    mail_verified boolean DEFAULT false,
    is_filler boolean DEFAULT false,
    balance_alert numeric(7,2) DEFAULT '-1'::integer,
    research_group text,
    is_host boolean DEFAULT false
);


ALTER TABLE spezispezl."user" OWNER TO spezl;

--
-- Name: COLUMN "user".is_host; Type: COMMENT; Schema: spezispezl; Owner: spezl
--

COMMENT ON COLUMN spezispezl."user".is_host IS 'is allowed to host guests';


--
-- Name: user_user_id_seq; Type: SEQUENCE; Schema: spezispezl; Owner: spezl
--

CREATE SEQUENCE spezispezl.user_user_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE spezispezl.user_user_id_seq OWNER TO spezl;

--
-- Name: user_user_id_seq; Type: SEQUENCE OWNED BY; Schema: spezispezl; Owner: spezl
--

ALTER SEQUENCE spezispezl.user_user_id_seq OWNED BY spezispezl."user".user_id;


--
-- Name: transactions id; Type: DEFAULT; Schema: spezispezl; Owner: spezl
--

ALTER TABLE ONLY spezispezl.transactions ALTER COLUMN id SET DEFAULT nextval('spezispezl.transactions_id_seq'::regclass);


--
-- Name: user user_id; Type: DEFAULT; Schema: spezispezl; Owner: spezl
--

ALTER TABLE ONLY spezispezl."user" ALTER COLUMN user_id SET DEFAULT nextval('spezispezl.user_user_id_seq'::regclass);
