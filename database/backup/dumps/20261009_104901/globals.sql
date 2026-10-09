--
-- PostgreSQL database cluster dump
--

\restrict kri2agpeHMrwoUeutCeTQoQIQboIKiB8wTQbKfONZ78MniNfo31wbV7GeBXwiik

SET default_transaction_read_only = off;

SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;

--
-- Roles
--

CREATE ROLE hims;
ALTER ROLE hims WITH NOSUPERUSER INHERIT NOCREATEROLE CREATEDB LOGIN NOREPLICATION NOBYPASSRLS;
CREATE ROLE oneintellecthr;
ALTER ROLE oneintellecthr WITH SUPERUSER INHERIT CREATEROLE CREATEDB LOGIN NOREPLICATION NOBYPASSRLS;
CREATE ROLE postgres;
ALTER ROLE postgres WITH SUPERUSER INHERIT CREATEROLE CREATEDB LOGIN REPLICATION BYPASSRLS;
CREATE ROLE "user";
ALTER ROLE "user" WITH NOSUPERUSER INHERIT NOCREATEROLE NOCREATEDB LOGIN NOREPLICATION NOBYPASSRLS;
CREATE ROLE venkat;
ALTER ROLE venkat WITH NOSUPERUSER INHERIT NOCREATEROLE NOCREATEDB LOGIN NOREPLICATION NOBYPASSRLS;

--
-- User Configurations
--

--
-- User Config "oneintellecthr"
--

ALTER ROLE oneintellecthr SET "TimeZone" TO 'UTC';








\unrestrict kri2agpeHMrwoUeutCeTQoQIQboIKiB8wTQbKfONZ78MniNfo31wbV7GeBXwiik

--
-- PostgreSQL database cluster dump complete
--

