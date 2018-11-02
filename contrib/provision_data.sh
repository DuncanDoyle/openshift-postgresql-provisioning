#!/bin/sh
# Export the password so psql does not prompt for it.
export PGPASSWORD=$POSTGRESQL_PASSWORD
# Create tables if they do not exist

DATABASE=postgres

echo "Provisioning database with demo data."
echo "Creating tables"
psql -h $POSTGRESQL_HOSTNAME -U $POSTGRESQL_USER -w -d $DATABASE --command "CREATE TABLE IF NOT EXISTS public.address(id bigint NOT NULL, country character varying(255), state character varying(255), street character varying(255), zipcode character varying(255), CONSTRAINT address_pkey PRIMARY KEY (id)) WITH (OIDS=FALSE); ALTER TABLE public.address OWNER TO \"$POSTGRESQL_USER\";"

psql -h $POSTGRESQL_HOSTNAME -U $POSTGRESQL_USER -w -d $DATABASE --command "CREATE TABLE IF NOT EXISTS public.client(id bigint NOT NULL, bic character varying(255), country character varying(255), creditscore integer, name character varying(255), phonenumber character varying(255), type character varying(255), address_id bigint, CONSTRAINT client_pkey PRIMARY KEY (id), CONSTRAINT fk_6nxjf59jdjxiysy7qke8l36j8 FOREIGN KEY (address_id) REFERENCES public.address (id) MATCH SIMPLE ON UPDATE NO ACTION ON DELETE NO ACTION) WITH (OIDS=FALSE); ALTER TABLE public.client OWNER TO \"$POSTGRESQL_USER\";"

psql -h $POSTGRESQL_HOSTNAME -U $POSTGRESQL_USER -w -d $DATABASE --command "CREATE TABLE IF NOT EXISTS public.party(id bigint NOT NULL, dateofbirth timestamp without time zone, email character varying(255), name character varying(255), ssn character varying(255), surname character varying(255), CONSTRAINT party_pkey PRIMARY KEY (id)) WITH (OIDS=FALSE); ALTER TABLE public.party OWNER TO \"$POSTGRESQL_USER\";"

psql -h $POSTGRESQL_HOSTNAME -U $POSTGRESQL_USER -w -d $DATABASE --command "CREATE TABLE IF NOT EXISTS public.relatedparty(id bigint NOT NULL, relationship character varying(255), party_id bigint, CONSTRAINT relatedparty_pkey PRIMARY KEY (id), CONSTRAINT fk_nh7uvuf3s5wnyd1hk6g63as4o FOREIGN KEY (party_id) REFERENCES public.party (id) MATCH SIMPLE ON UPDATE NO ACTION ON DELETE NO ACTION) WITH (OIDS=FALSE); ALTER TABLE public.relatedparty OWNER TO \"$POSTGRESQL_USER\";"

psql -h $POSTGRESQL_HOSTNAME -U $POSTGRESQL_USER -w -d $DATABASE --command "CREATE TABLE IF NOT EXISTS public.client_relatedparty(client_id bigint NOT NULL, relatedparties_id bigint NOT NULL, CONSTRAINT fk_hlitg8u2ekmbi7iu46s3gx9qt FOREIGN KEY (client_id) REFERENCES public.client (id) MATCH SIMPLE ON UPDATE NO ACTION ON DELETE NO ACTION, CONSTRAINT fk_jo4sssdi4ohcspogsu3ftkpec FOREIGN KEY (relatedparties_id) REFERENCES public.relatedparty (id) MATCH SIMPLE ON UPDATE NO ACTION ON DELETE NO ACTION, CONSTRAINT uk_jo4sssdi4ohcspogsu3ftkpec UNIQUE (relatedparties_id)) WITH (OIDS=FALSE); ALTER TABLE public.client_relatedparty OWNER TO \"$POSTGRESQL_USER\";"
