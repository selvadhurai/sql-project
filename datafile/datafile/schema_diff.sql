5c5
< -- Dumped from database version 14.11
---
> -- Dumped from database version 14.10
20c20
< -- Name: backend; Type: SCHEMA; Schema: -; Owner: postgres
---
> -- Name: SCHEMA public; Type: ACL; Schema: -; Owner: postgres
23,1792c23,26
< CREATE SCHEMA backend;
< 
< 
< ALTER SCHEMA backend OWNER TO postgres;
< 
< --
< -- Name: uuid-ossp; Type: EXTENSION; Schema: -; Owner: -
< --
< 
< CREATE EXTENSION IF NOT EXISTS "uuid-ossp" WITH SCHEMA backend;
< 
< 
< --
< -- Name: EXTENSION "uuid-ossp"; Type: COMMENT; Schema: -; Owner: 
< --
< 
< COMMENT ON EXTENSION "uuid-ossp" IS 'generate universally unique identifiers (UUIDs)';
< 
< 
< --
< -- Name: get_recommendations(json); Type: FUNCTION; Schema: backend; Owner: postgres
< --
< 
< CREATE FUNCTION backend.get_recommendations(patient_genes json) RETURNS json
<     LANGUAGE plpgsql
<     AS $$ 
< 
< DECLARE
<     matchfound boolean;
<     s record;
<     p record;
<     max_genes_length integer;
<     gene uuid;
<     drug uuid;
<     drug_name VARCHAR(50);
<     brand_name VARCHAR(50);
<     category VARCHAR(50);
<     gene_range uuid[];
<     impacted_recids uuid[];
<     standard_dose json[];
<     json_impacted json;
<     results json;
<     jkey text;
< 
< BEGIN
<     --In gene_range we have only id of genes given in the input json
<     FOR jkey IN SELECT * FROM json_object_keys(patient_genes) LOOP
<         SELECT ARRAY_APPEND(gene_range, (SELECT id FROM backend.genes WHERE jkey = genes.name)) INTO gene_range;
<     END LOOP;
< 
<     FOR drug,  brand_name, category IN SELECT d.id, d.name || ' (' || d.brand_name || ')', dc.name FROM backend.drugs d join backend.drug_categories dc on dc.id = d.drug_category_id LOOP
<         SELECT MAX(ARRAY_LENGTH(gene_ids, 1)) INTO max_genes_length FROM backend.recommendations rec WHERE rec.active = true and rec.drug_id = drug AND gene_ids <@ gene_range;
<         matchfound := TRUE;
<         FOR s IN SELECT * FROM backend.recommendations rec WHERE rec.active = true and rec.drug_id = drug AND gene_ids <@ gene_range AND ARRAY_LENGTH(gene_ids, 1) = max_genes_length LOOP
<             matchfound := FALSE;
<             CONTINUE WHEN s.clinicalimpact IS NULL;
<             FOR gene IN array_lower(s.gene_ids, 1)..array_upper(s.gene_ids, 1) LOOP
<                 
<                 SELECT * INTO p FROM backend.recommendation_details rd WHERE rd.active = true and rd.recommendation_id = s.id AND rd.gene_id = s.gene_ids[gene] AND rd.value = (patient_genes -> (SELECT name FROM backend.genes WHERE id = s.gene_ids[gene]) ->> (select name from backend.gene_properties where id = rd.gene_property_id ));
<                 EXIT WHEN NOT FOUND;
< 
<                 IF gene = array_upper(s.gene_ids, 1) THEN
<                     matchfound := TRUE;
<                 END IF;
< 
<             END LOOP;
< 
<             IF matchfound = TRUE THEN
<                 SELECT ARRAY_APPEND(impacted_recids, s.id) INTO impacted_recids;
<             END IF;
< 
<             EXIT WHEN matchfound = TRUE;
<         END LOOP;
<         IF matchfound = FALSE THEN
<             SELECT ARRAY_APPEND(standard_dose, json_build_object('name', brand_name, 'category', category)) INTO standard_dose;
<         END IF;
<         
<     END LOOP;
< 
<     SELECT json_agg(row_to_json(recom)) INTO json_impacted
<     FROM (
<         SELECT ARRAY(SELECT name from backend.genes where id = ANY(gene_ids)) as genes, (SELECT d.name || ' (' || d.brand_name || ')' as name from backend.drugs d WHERE d.id = rec.drug_id), (select dc.name as category from backend.drug_categories dc join backend.drugs d on d.drug_category_id = dc.id where d.id = rec.drug_id),clinicalguidance, clinicalimpact, citation from backend.recommendations rec WHERE rec.id = ANY(impacted_recids) and rec.active = true
<     ) recom;
< 
<     SELECT JSON_BUILD_OBJECT('standard', (array_to_json(standard_dose)), 'impacted', json_impacted) INTO results;
<     
<     RETURN results;
< 
< END;
< $$;
< 
< 
< ALTER FUNCTION backend.get_recommendations(patient_genes json) OWNER TO postgres;
< 
< --
< -- Name: trigger_set_timestamp(); Type: FUNCTION; Schema: backend; Owner: postgres
< --
< 
< CREATE FUNCTION backend.trigger_set_timestamp() RETURNS trigger
<     LANGUAGE plpgsql
<     AS $$
< BEGIN
<   NEW.updated_at = NOW();
<   RETURN NEW;
< END;
< $$;
< 
< 
< ALTER FUNCTION backend.trigger_set_timestamp() OWNER TO postgres;
< 
< SET default_tablespace = '';
< 
< SET default_table_access_method = heap;
< 
< --
< -- Name: audit_log; Type: TABLE; Schema: backend; Owner: postgres
< --
< 
< CREATE TABLE backend.audit_log (
<     id uuid DEFAULT backend.uuid_generate_v4() NOT NULL,
<     user_id uuid NOT NULL,
<     action_log character varying,
<     created_at timestamp with time zone DEFAULT now() NOT NULL,
<     updated_at timestamp with time zone DEFAULT now() NOT NULL
< );
< 
< 
< ALTER TABLE backend.audit_log OWNER TO postgres;
< 
< --
< -- Name: comment_categories; Type: TABLE; Schema: backend; Owner: postgres
< --
< 
< CREATE TABLE backend.comment_categories (
<     id integer NOT NULL,
<     name character varying NOT NULL,
<     created_at timestamp with time zone DEFAULT now() NOT NULL,
<     updated_at timestamp with time zone DEFAULT now() NOT NULL
< );
< 
< 
< ALTER TABLE backend.comment_categories OWNER TO postgres;
< 
< --
< -- Name: comment_categories_id_seq; Type: SEQUENCE; Schema: backend; Owner: postgres
< --
< 
< CREATE SEQUENCE backend.comment_categories_id_seq
<     AS integer
<     START WITH 1
<     INCREMENT BY 1
<     NO MINVALUE
<     NO MAXVALUE
<     CACHE 1;
< 
< 
< ALTER TABLE backend.comment_categories_id_seq OWNER TO postgres;
< 
< --
< -- Name: comment_categories_id_seq; Type: SEQUENCE OWNED BY; Schema: backend; Owner: postgres
< --
< 
< ALTER SEQUENCE backend.comment_categories_id_seq OWNED BY backend.comment_categories.id;
< 
< 
< --
< -- Name: comments; Type: TABLE; Schema: backend; Owner: postgres
< --
< 
< CREATE TABLE backend.comments (
<     id uuid DEFAULT backend.uuid_generate_v4() NOT NULL,
<     comment character varying NOT NULL,
<     in_report boolean,
<     category_id integer NOT NULL,
<     order_id uuid NOT NULL,
<     result_id uuid NOT NULL,
<     user_id uuid NOT NULL,
<     created_at timestamp with time zone DEFAULT now() NOT NULL,
<     updated_at timestamp with time zone DEFAULT now() NOT NULL
< );
< 
< 
< ALTER TABLE backend.comments OWNER TO postgres;
< 
< --
< -- Name: drug_categories; Type: TABLE; Schema: backend; Owner: postgres
< --
< 
< CREATE TABLE backend.drug_categories (
<     id uuid DEFAULT backend.uuid_generate_v4() NOT NULL,
<     name character varying NOT NULL,
<     created_at timestamp with time zone DEFAULT now() NOT NULL,
<     updated_at timestamp with time zone DEFAULT now() NOT NULL
< );
< 
< 
< ALTER TABLE backend.drug_categories OWNER TO postgres;
< 
< --
< -- Name: drugs; Type: TABLE; Schema: backend; Owner: postgres
< --
< 
< CREATE TABLE backend.drugs (
<     id uuid DEFAULT backend.uuid_generate_v4() NOT NULL,
<     name character varying NOT NULL,
<     brand_name character varying NOT NULL,
<     drug_category_id uuid,
<     created_at timestamp with time zone DEFAULT now() NOT NULL,
<     updated_at timestamp with time zone DEFAULT now() NOT NULL
< );
< 
< 
< ALTER TABLE backend.drugs OWNER TO postgres;
< 
< --
< -- Name: gene_properties; Type: TABLE; Schema: backend; Owner: postgres
< --
< 
< CREATE TABLE backend.gene_properties (
<     id uuid DEFAULT backend.uuid_generate_v4() NOT NULL,
<     name character varying NOT NULL,
<     created_at timestamp with time zone DEFAULT now() NOT NULL,
<     updated_at timestamp with time zone DEFAULT now() NOT NULL
< );
< 
< 
< ALTER TABLE backend.gene_properties OWNER TO postgres;
< 
< --
< -- Name: genes; Type: TABLE; Schema: backend; Owner: postgres
< --
< 
< CREATE TABLE backend.genes (
<     id uuid DEFAULT backend.uuid_generate_v4() NOT NULL,
<     name character varying NOT NULL,
<     created_at timestamp with time zone DEFAULT now() NOT NULL,
<     updated_at timestamp with time zone DEFAULT now() NOT NULL
< );
< 
< 
< ALTER TABLE backend.genes OWNER TO postgres;
< 
< --
< -- Name: genotypes; Type: TABLE; Schema: backend; Owner: postgres
< --
< 
< CREATE TABLE backend.genotypes (
<     id uuid DEFAULT backend.uuid_generate_v4() NOT NULL,
<     gene_id uuid NOT NULL,
<     info json NOT NULL,
<     status integer NOT NULL,
<     active boolean NOT NULL,
<     created_at timestamp with time zone DEFAULT now() NOT NULL,
<     updated_at timestamp with time zone DEFAULT now() NOT NULL
< );
< 
< 
< ALTER TABLE backend.genotypes OWNER TO postgres;
< 
< --
< -- Name: haplotypes; Type: TABLE; Schema: backend; Owner: postgres
< --
< 
< CREATE TABLE backend.haplotypes (
<     id uuid DEFAULT backend.uuid_generate_v4() NOT NULL,
<     gene_id uuid NOT NULL,
<     haplotype character varying NOT NULL,
<     score numeric(3,2),
<     population_frequency numeric,
<     function character varying,
<     status integer NOT NULL,
<     active boolean NOT NULL,
<     created_at timestamp with time zone DEFAULT now() NOT NULL,
<     updated_at timestamp with time zone DEFAULT now() NOT NULL
< );
< 
< 
< ALTER TABLE backend.haplotypes OWNER TO postgres;
< 
< --
< -- Name: mapping_status; Type: TABLE; Schema: backend; Owner: postgres
< --
< 
< CREATE TABLE backend.mapping_status (
<     id integer NOT NULL,
<     name character varying NOT NULL,
<     created_at timestamp with time zone DEFAULT now() NOT NULL,
<     updated_at timestamp with time zone DEFAULT now() NOT NULL
< );
< 
< 
< ALTER TABLE backend.mapping_status OWNER TO postgres;
< 
< --
< -- Name: mapping_status_id_seq; Type: SEQUENCE; Schema: backend; Owner: postgres
< --
< 
< CREATE SEQUENCE backend.mapping_status_id_seq
<     AS integer
<     START WITH 1
<     INCREMENT BY 1
<     NO MINVALUE
<     NO MAXVALUE
<     CACHE 1;
< 
< 
< ALTER TABLE backend.mapping_status_id_seq OWNER TO postgres;
< 
< --
< -- Name: mapping_status_id_seq; Type: SEQUENCE OWNED BY; Schema: backend; Owner: postgres
< --
< 
< ALTER SEQUENCE backend.mapping_status_id_seq OWNED BY backend.mapping_status.id;
< 
< 
< --
< -- Name: master_version_genotypes; Type: TABLE; Schema: backend; Owner: postgres
< --
< 
< CREATE TABLE backend.master_version_genotypes (
<     id uuid DEFAULT backend.uuid_generate_v4() NOT NULL,
<     master_version_id uuid NOT NULL,
<     genotype_id uuid NOT NULL,
<     created_at timestamp with time zone DEFAULT now() NOT NULL,
<     updated_at timestamp with time zone DEFAULT now() NOT NULL
< );
< 
< 
< ALTER TABLE backend.master_version_genotypes OWNER TO postgres;
< 
< --
< -- Name: master_version_haplotypes; Type: TABLE; Schema: backend; Owner: postgres
< --
< 
< CREATE TABLE backend.master_version_haplotypes (
<     id uuid DEFAULT backend.uuid_generate_v4() NOT NULL,
<     master_version_id uuid NOT NULL,
<     haplotype_id uuid NOT NULL,
<     created_at timestamp with time zone DEFAULT now() NOT NULL,
<     updated_at timestamp with time zone DEFAULT now() NOT NULL
< );
< 
< 
< ALTER TABLE backend.master_version_haplotypes OWNER TO postgres;
< 
< --
< -- Name: master_version_phenotypes; Type: TABLE; Schema: backend; Owner: postgres
< --
< 
< CREATE TABLE backend.master_version_phenotypes (
<     id uuid DEFAULT backend.uuid_generate_v4() NOT NULL,
<     master_version_id uuid NOT NULL,
<     phenotype_id uuid NOT NULL,
<     created_at timestamp with time zone DEFAULT now() NOT NULL,
<     updated_at timestamp with time zone DEFAULT now() NOT NULL
< );
< 
< 
< ALTER TABLE backend.master_version_phenotypes OWNER TO postgres;
< 
< --
< -- Name: master_version_recommendations; Type: TABLE; Schema: backend; Owner: postgres
< --
< 
< CREATE TABLE backend.master_version_recommendations (
<     id uuid DEFAULT backend.uuid_generate_v4() NOT NULL,
<     master_version_id uuid NOT NULL,
<     recommendation_id uuid NOT NULL,
<     created_at timestamp with time zone DEFAULT now() NOT NULL,
<     updated_at timestamp with time zone DEFAULT now() NOT NULL
< );
< 
< 
< ALTER TABLE backend.master_version_recommendations OWNER TO postgres;
< 
< --
< -- Name: master_versions; Type: TABLE; Schema: backend; Owner: postgres
< --
< 
< CREATE TABLE backend.master_versions (
<     id uuid DEFAULT backend.uuid_generate_v4() NOT NULL,
<     version character varying NOT NULL,
<     active boolean NOT NULL,
<     created_at timestamp with time zone DEFAULT now() NOT NULL,
<     updated_at timestamp with time zone DEFAULT now() NOT NULL
< );
< 
< 
< ALTER TABLE backend.master_versions OWNER TO postgres;
< 
< --
< -- Name: orders; Type: TABLE; Schema: backend; Owner: postgres
< --
< 
< CREATE TABLE backend.orders (
<     id uuid DEFAULT backend.uuid_generate_v4() NOT NULL,
<     number character varying NOT NULL,
<     plate character varying,
<     patient_id uuid NOT NULL,
<     status integer NOT NULL,
<     procedure_id uuid NOT NULL,
<     specimen character varying NOT NULL,
<     date_collected date NOT NULL,
<     provider character varying,
<     specimen_type character varying NOT NULL,
<     source_id character varying,
<     submitter character varying,
<     created_at timestamp with time zone DEFAULT now() NOT NULL,
<     updated_at timestamp with time zone DEFAULT now() NOT NULL
< );
< 
< 
< ALTER TABLE backend.orders OWNER TO postgres;
< 
< --
< -- Name: overrides; Type: TABLE; Schema: backend; Owner: postgres
< --
< 
< CREATE TABLE backend.overrides (
<     id uuid DEFAULT backend.uuid_generate_v4() NOT NULL,
<     order_id uuid NOT NULL,
<     result_id uuid NOT NULL,
<     result json NOT NULL,
<     overridden_by uuid NOT NULL,
<     active boolean NOT NULL,
<     created_at timestamp with time zone DEFAULT now() NOT NULL,
<     updated_at timestamp with time zone DEFAULT now() NOT NULL
< );
< 
< 
< ALTER TABLE backend.overrides OWNER TO postgres;
< 
< --
< -- Name: patients; Type: TABLE; Schema: backend; Owner: postgres
< --
< 
< CREATE TABLE backend.patients (
<     id uuid DEFAULT backend.uuid_generate_v4() NOT NULL,
<     mrn character varying NOT NULL,
<     first_name character varying NOT NULL,
<     middle_name character varying,
<     last_name character varying NOT NULL,
<     dob date NOT NULL,
<     gender character varying,
<     active boolean,
<     created_at timestamp with time zone DEFAULT now() NOT NULL,
<     updated_at timestamp with time zone DEFAULT now() NOT NULL
< );
< 
< 
< ALTER TABLE backend.patients OWNER TO postgres;
< 
< --
< -- Name: TABLE patients; Type: COMMENT; Schema: backend; Owner: postgres
< --
< 
< COMMENT ON TABLE backend.patients IS 'table to hold patient demo graphics';
< 
< 
< --
< -- Name: COLUMN patients.mrn; Type: COMMENT; Schema: backend; Owner: postgres
< --
< 
< COMMENT ON COLUMN backend.patients.mrn IS 'patietn medical record identifier';
< 
< 
< --
< -- Name: COLUMN patients.first_name; Type: COMMENT; Schema: backend; Owner: postgres
< --
< 
< COMMENT ON COLUMN backend.patients.first_name IS 'patietn first name';
< 
< 
< --
< -- Name: COLUMN patients.last_name; Type: COMMENT; Schema: backend; Owner: postgres
< --
< 
< COMMENT ON COLUMN backend.patients.last_name IS 'patient last name';
< 
< 
< --
< -- Name: patients_archive; Type: TABLE; Schema: backend; Owner: postgres
< --
< 
< CREATE TABLE backend.patients_archive (
<     id uuid NOT NULL,
<     mrn character varying NOT NULL,
<     first_name character varying NOT NULL,
<     last_name character varying NOT NULL,
<     middle_name character varying,
<     dob date NOT NULL,
<     gender character varying,
<     created_at timestamp with time zone DEFAULT now() NOT NULL,
<     updated_at timestamp with time zone DEFAULT now() NOT NULL
< );
< 
< 
< ALTER TABLE backend.patients_archive OWNER TO postgres;
< 
< --
< -- Name: TABLE patients_archive; Type: COMMENT; Schema: backend; Owner: postgres
< --
< 
< COMMENT ON TABLE backend.patients_archive IS 'table to hold patient demo graphics';
< 
< 
< --
< -- Name: COLUMN patients_archive.mrn; Type: COMMENT; Schema: backend; Owner: postgres
< --
< 
< COMMENT ON COLUMN backend.patients_archive.mrn IS 'patietn medical record identifier';
< 
< 
< --
< -- Name: COLUMN patients_archive.first_name; Type: COMMENT; Schema: backend; Owner: postgres
< --
< 
< COMMENT ON COLUMN backend.patients_archive.first_name IS 'patietn first name';
< 
< 
< --
< -- Name: COLUMN patients_archive.last_name; Type: COMMENT; Schema: backend; Owner: postgres
< --
< 
< COMMENT ON COLUMN backend.patients_archive.last_name IS 'patient last name';
< 
< 
< --
< -- Name: phenotypes; Type: TABLE; Schema: backend; Owner: postgres
< --
< 
< CREATE TABLE backend.phenotypes (
<     id uuid DEFAULT backend.uuid_generate_v4() NOT NULL,
<     gene_id uuid NOT NULL,
<     allele_1_function character varying,
<     allele_2_function character varying,
<     score_range_start numeric(4,2),
<     score_range_end numeric(4,2),
<     phenotype character varying,
<     status integer NOT NULL,
<     active boolean NOT NULL,
<     created_at timestamp with time zone DEFAULT now() NOT NULL,
<     updated_at timestamp with time zone DEFAULT now() NOT NULL
< );
< 
< 
< ALTER TABLE backend.phenotypes OWNER TO postgres;
< 
< --
< -- Name: predefined_comments; Type: TABLE; Schema: backend; Owner: postgres
< --
< 
< CREATE TABLE backend.predefined_comments (
<     id integer NOT NULL,
<     comment character varying NOT NULL,
<     category_id integer NOT NULL,
<     active boolean NOT NULL,
<     created_at timestamp with time zone DEFAULT now() NOT NULL,
<     updated_at timestamp with time zone DEFAULT now() NOT NULL
< );
< 
< 
< ALTER TABLE backend.predefined_comments OWNER TO postgres;
< 
< --
< -- Name: predefined_comments_id_seq; Type: SEQUENCE; Schema: backend; Owner: postgres
< --
< 
< CREATE SEQUENCE backend.predefined_comments_id_seq
<     AS integer
<     START WITH 1
<     INCREMENT BY 1
<     NO MINVALUE
<     NO MAXVALUE
<     CACHE 1;
< 
< 
< ALTER TABLE backend.predefined_comments_id_seq OWNER TO postgres;
< 
< --
< -- Name: predefined_comments_id_seq; Type: SEQUENCE OWNED BY; Schema: backend; Owner: postgres
< --
< 
< ALTER SEQUENCE backend.predefined_comments_id_seq OWNED BY backend.predefined_comments.id;
< 
< 
< --
< -- Name: procedure_details; Type: TABLE; Schema: backend; Owner: postgres
< --
< 
< CREATE TABLE backend.procedure_details (
<     id uuid DEFAULT backend.uuid_generate_v4() NOT NULL,
<     procedure_id uuid NOT NULL,
<     gene_id uuid NOT NULL,
<     positions character varying[] NOT NULL,
<     alleles character varying[],
<     created_at timestamp with time zone DEFAULT now() NOT NULL,
<     updated_at timestamp with time zone DEFAULT now() NOT NULL
< );
< 
< 
< ALTER TABLE backend.procedure_details OWNER TO postgres;
< 
< --
< -- Name: procedures; Type: TABLE; Schema: backend; Owner: postgres
< --
< 
< CREATE TABLE backend.procedures (
<     id uuid DEFAULT backend.uuid_generate_v4() NOT NULL,
<     code character varying NOT NULL,
<     name character varying NOT NULL,
<     created_at timestamp with time zone DEFAULT now() NOT NULL,
<     updated_at timestamp with time zone DEFAULT now() NOT NULL
< );
< 
< 
< ALTER TABLE backend.procedures OWNER TO postgres;
< 
< --
< -- Name: recommendation_details; Type: TABLE; Schema: backend; Owner: postgres
< --
< 
< CREATE TABLE backend.recommendation_details (
<     id uuid DEFAULT backend.uuid_generate_v4() NOT NULL,
<     recommendation_id uuid NOT NULL,
<     gene_id uuid NOT NULL,
<     gene_property_id uuid NOT NULL,
<     value character varying,
<     status integer NOT NULL,
<     active boolean NOT NULL,
<     created_at timestamp with time zone DEFAULT now() NOT NULL,
<     updated_at timestamp with time zone DEFAULT now() NOT NULL
< );
< 
< 
< ALTER TABLE backend.recommendation_details OWNER TO postgres;
< 
< --
< -- Name: recommendations; Type: TABLE; Schema: backend; Owner: postgres
< --
< 
< CREATE TABLE backend.recommendations (
<     id uuid DEFAULT backend.uuid_generate_v4() NOT NULL,
<     name character varying NOT NULL,
<     drug_id uuid NOT NULL,
<     gene_ids uuid[] NOT NULL,
<     clinicalguidance text,
<     citation text,
<     severity text,
<     clinicalimpact text,
<     status integer NOT NULL,
<     active boolean NOT NULL,
<     created_at timestamp with time zone DEFAULT now() NOT NULL,
<     updated_at timestamp with time zone DEFAULT now() NOT NULL
< );
< 
< 
< ALTER TABLE backend.recommendations OWNER TO postgres;
< 
< --
< -- Name: repeat_order_messages; Type: TABLE; Schema: backend; Owner: postgres
< --
< 
< CREATE TABLE backend.repeat_order_messages (
<     id uuid DEFAULT backend.uuid_generate_v4() NOT NULL,
<     incoming_message json NOT NULL,
<     active boolean NOT NULL,
<     created_at timestamp with time zone DEFAULT now() NOT NULL,
<     updated_at timestamp with time zone DEFAULT now() NOT NULL
< );
< 
< 
< ALTER TABLE backend.repeat_order_messages OWNER TO postgres;
< 
< --
< -- Name: result_drug_recommendations; Type: TABLE; Schema: backend; Owner: postgres
< --
< 
< CREATE TABLE backend.result_drug_recommendations (
<     id uuid DEFAULT backend.uuid_generate_v4() NOT NULL,
<     result_id uuid NOT NULL,
<     recommendations json NOT NULL,
<     active boolean NOT NULL,
<     created_by uuid NOT NULL,
<     created_at timestamp with time zone DEFAULT now() NOT NULL,
<     updated_at timestamp with time zone DEFAULT now() NOT NULL
< );
< 
< 
< ALTER TABLE backend.result_drug_recommendations OWNER TO postgres;
< 
< --
< -- Name: results; Type: TABLE; Schema: backend; Owner: postgres
< --
< 
< CREATE TABLE backend.results (
<     id uuid DEFAULT backend.uuid_generate_v4() NOT NULL,
<     order_id uuid NOT NULL,
<     vcf_id uuid NOT NULL,
<     result json NOT NULL,
<     mapping_status integer NOT NULL,
<     active boolean NOT NULL,
<     created_by uuid NOT NULL,
<     master_version_id uuid NOT NULL,
<     created_at timestamp with time zone DEFAULT now() NOT NULL,
<     updated_at timestamp with time zone DEFAULT now() NOT NULL
< );
< 
< 
< ALTER TABLE backend.results OWNER TO postgres;
< 
< --
< -- Name: roles; Type: TABLE; Schema: backend; Owner: postgres
< --
< 
< CREATE TABLE backend.roles (
<     id uuid DEFAULT backend.uuid_generate_v4() NOT NULL,
<     name character varying NOT NULL,
<     permissions json NOT NULL,
<     created_at timestamp with time zone DEFAULT now() NOT NULL,
<     updated_at timestamp with time zone DEFAULT now() NOT NULL
< );
< 
< 
< ALTER TABLE backend.roles OWNER TO postgres;
< 
< --
< -- Name: status; Type: TABLE; Schema: backend; Owner: postgres
< --
< 
< CREATE TABLE backend.status (
<     id integer NOT NULL,
<     name character varying NOT NULL,
<     created_at timestamp with time zone DEFAULT now() NOT NULL,
<     updated_at timestamp with time zone DEFAULT now() NOT NULL
< );
< 
< 
< ALTER TABLE backend.status OWNER TO postgres;
< 
< --
< -- Name: status_id_seq; Type: SEQUENCE; Schema: backend; Owner: postgres
< --
< 
< CREATE SEQUENCE backend.status_id_seq
<     AS integer
<     START WITH 1
<     INCREMENT BY 1
<     NO MINVALUE
<     NO MAXVALUE
<     CACHE 1;
< 
< 
< ALTER TABLE backend.status_id_seq OWNER TO postgres;
< 
< --
< -- Name: status_id_seq; Type: SEQUENCE OWNED BY; Schema: backend; Owner: postgres
< --
< 
< ALTER SEQUENCE backend.status_id_seq OWNED BY backend.status.id;
< 
< 
< --
< -- Name: tracker; Type: TABLE; Schema: backend; Owner: postgres
< --
< 
< CREATE TABLE backend.tracker (
<     id uuid DEFAULT backend.uuid_generate_v4() NOT NULL,
<     user_id uuid NOT NULL,
<     order_id uuid NOT NULL,
<     status integer NOT NULL,
<     created_at timestamp with time zone DEFAULT now() NOT NULL,
<     updated_at timestamp with time zone DEFAULT now() NOT NULL,
<     active boolean NOT NULL
< );
< 
< 
< ALTER TABLE backend.tracker OWNER TO postgres;
< 
< --
< -- Name: users; Type: TABLE; Schema: backend; Owner: postgres
< --
< 
< CREATE TABLE backend.users (
<     id uuid DEFAULT backend.uuid_generate_v4() NOT NULL,
<     first_name character varying NOT NULL,
<     last_name character varying NOT NULL,
<     image_url character varying,
<     role_id uuid NOT NULL,
<     active boolean DEFAULT false NOT NULL,
<     created_at timestamp with time zone DEFAULT now() NOT NULL,
<     updated_at timestamp with time zone DEFAULT now() NOT NULL,
<     credentials character varying
< );
< 
< 
< ALTER TABLE backend.users OWNER TO postgres;
< 
< --
< -- Name: vcfs; Type: TABLE; Schema: backend; Owner: postgres
< --
< 
< CREATE TABLE backend.vcfs (
<     id uuid DEFAULT backend.uuid_generate_v4() NOT NULL,
<     order_id uuid NOT NULL,
<     vcf_url character varying NOT NULL,
<     version numeric NOT NULL,
<     created_at timestamp with time zone DEFAULT now() NOT NULL,
<     updated_at timestamp with time zone DEFAULT now() NOT NULL
< );
< 
< 
< ALTER TABLE backend.vcfs OWNER TO postgres;
< 
< --
< -- Name: comment_categories id; Type: DEFAULT; Schema: backend; Owner: postgres
< --
< 
< ALTER TABLE ONLY backend.comment_categories ALTER COLUMN id SET DEFAULT nextval('backend.comment_categories_id_seq'::regclass);
< 
< 
< --
< -- Name: mapping_status id; Type: DEFAULT; Schema: backend; Owner: postgres
< --
< 
< ALTER TABLE ONLY backend.mapping_status ALTER COLUMN id SET DEFAULT nextval('backend.mapping_status_id_seq'::regclass);
< 
< 
< --
< -- Name: predefined_comments id; Type: DEFAULT; Schema: backend; Owner: postgres
< --
< 
< ALTER TABLE ONLY backend.predefined_comments ALTER COLUMN id SET DEFAULT nextval('backend.predefined_comments_id_seq'::regclass);
< 
< 
< --
< -- Name: status id; Type: DEFAULT; Schema: backend; Owner: postgres
< --
< 
< ALTER TABLE ONLY backend.status ALTER COLUMN id SET DEFAULT nextval('backend.status_id_seq'::regclass);
< 
< 
< --
< -- Name: audit_log audit_log_pkey; Type: CONSTRAINT; Schema: backend; Owner: postgres
< --
< 
< ALTER TABLE ONLY backend.audit_log
<     ADD CONSTRAINT audit_log_pkey PRIMARY KEY (id);
< 
< 
< --
< -- Name: comment_categories comment_categories_name_key; Type: CONSTRAINT; Schema: backend; Owner: postgres
< --
< 
< ALTER TABLE ONLY backend.comment_categories
<     ADD CONSTRAINT comment_categories_name_key UNIQUE (name);
< 
< 
< --
< -- Name: comment_categories comment_categories_pkey; Type: CONSTRAINT; Schema: backend; Owner: postgres
< --
< 
< ALTER TABLE ONLY backend.comment_categories
<     ADD CONSTRAINT comment_categories_pkey PRIMARY KEY (id);
< 
< 
< --
< -- Name: comments comments_pkey; Type: CONSTRAINT; Schema: backend; Owner: postgres
< --
< 
< ALTER TABLE ONLY backend.comments
<     ADD CONSTRAINT comments_pkey PRIMARY KEY (id);
< 
< 
< --
< -- Name: drug_categories drug_categories_pkey; Type: CONSTRAINT; Schema: backend; Owner: postgres
< --
< 
< ALTER TABLE ONLY backend.drug_categories
<     ADD CONSTRAINT drug_categories_pkey PRIMARY KEY (id);
< 
< 
< --
< -- Name: drugs drugs_pkey; Type: CONSTRAINT; Schema: backend; Owner: postgres
< --
< 
< ALTER TABLE ONLY backend.drugs
<     ADD CONSTRAINT drugs_pkey PRIMARY KEY (id);
< 
< 
< --
< -- Name: gene_properties gene_properties_pkey; Type: CONSTRAINT; Schema: backend; Owner: postgres
< --
< 
< ALTER TABLE ONLY backend.gene_properties
<     ADD CONSTRAINT gene_properties_pkey PRIMARY KEY (id);
< 
< 
< --
< -- Name: genes genes_name_key; Type: CONSTRAINT; Schema: backend; Owner: postgres
< --
< 
< ALTER TABLE ONLY backend.genes
<     ADD CONSTRAINT genes_name_key UNIQUE (name);
< 
< 
< --
< -- Name: genes genes_pkey; Type: CONSTRAINT; Schema: backend; Owner: postgres
< --
< 
< ALTER TABLE ONLY backend.genes
<     ADD CONSTRAINT genes_pkey PRIMARY KEY (id);
< 
< 
< --
< -- Name: genotypes genotypes_pkey; Type: CONSTRAINT; Schema: backend; Owner: postgres
< --
< 
< ALTER TABLE ONLY backend.genotypes
<     ADD CONSTRAINT genotypes_pkey PRIMARY KEY (id);
< 
< 
< --
< -- Name: haplotypes haplotypes_pkey; Type: CONSTRAINT; Schema: backend; Owner: postgres
< --
< 
< ALTER TABLE ONLY backend.haplotypes
<     ADD CONSTRAINT haplotypes_pkey PRIMARY KEY (id);
< 
< 
< --
< -- Name: mapping_status mapping_status_name_key; Type: CONSTRAINT; Schema: backend; Owner: postgres
< --
< 
< ALTER TABLE ONLY backend.mapping_status
<     ADD CONSTRAINT mapping_status_name_key UNIQUE (name);
< 
< 
< --
< -- Name: mapping_status mapping_status_pkey; Type: CONSTRAINT; Schema: backend; Owner: postgres
< --
< 
< ALTER TABLE ONLY backend.mapping_status
<     ADD CONSTRAINT mapping_status_pkey PRIMARY KEY (id);
< 
< 
< --
< -- Name: master_version_genotypes master_version_genotypes_pkey; Type: CONSTRAINT; Schema: backend; Owner: postgres
< --
< 
< ALTER TABLE ONLY backend.master_version_genotypes
<     ADD CONSTRAINT master_version_genotypes_pkey PRIMARY KEY (id);
< 
< 
< --
< -- Name: master_version_haplotypes master_version_haplotypes_pkey; Type: CONSTRAINT; Schema: backend; Owner: postgres
< --
< 
< ALTER TABLE ONLY backend.master_version_haplotypes
<     ADD CONSTRAINT master_version_haplotypes_pkey PRIMARY KEY (id);
< 
< 
< --
< -- Name: master_version_phenotypes master_version_phenotypes_pkey; Type: CONSTRAINT; Schema: backend; Owner: postgres
< --
< 
< ALTER TABLE ONLY backend.master_version_phenotypes
<     ADD CONSTRAINT master_version_phenotypes_pkey PRIMARY KEY (id);
< 
< 
< --
< -- Name: master_version_recommendations master_version_recommendations_pkey; Type: CONSTRAINT; Schema: backend; Owner: postgres
< --
< 
< ALTER TABLE ONLY backend.master_version_recommendations
<     ADD CONSTRAINT master_version_recommendations_pkey PRIMARY KEY (id);
< 
< 
< --
< -- Name: master_versions master_versions_pkey; Type: CONSTRAINT; Schema: backend; Owner: postgres
< --
< 
< ALTER TABLE ONLY backend.master_versions
<     ADD CONSTRAINT master_versions_pkey PRIMARY KEY (id);
< 
< 
< --
< -- Name: master_versions master_versions_version_key; Type: CONSTRAINT; Schema: backend; Owner: postgres
< --
< 
< ALTER TABLE ONLY backend.master_versions
<     ADD CONSTRAINT master_versions_version_key UNIQUE (version);
< 
< 
< --
< -- Name: orders orders_number_key; Type: CONSTRAINT; Schema: backend; Owner: postgres
< --
< 
< ALTER TABLE ONLY backend.orders
<     ADD CONSTRAINT orders_number_key UNIQUE (number);
< 
< 
< --
< -- Name: orders orders_pkey; Type: CONSTRAINT; Schema: backend; Owner: postgres
< --
< 
< ALTER TABLE ONLY backend.orders
<     ADD CONSTRAINT orders_pkey PRIMARY KEY (id);
< 
< 
< --
< -- Name: overrides overrides_pkey; Type: CONSTRAINT; Schema: backend; Owner: postgres
< --
< 
< ALTER TABLE ONLY backend.overrides
<     ADD CONSTRAINT overrides_pkey PRIMARY KEY (id);
< 
< 
< --
< -- Name: patients patients_pkey; Type: CONSTRAINT; Schema: backend; Owner: postgres
< --
< 
< ALTER TABLE ONLY backend.patients
<     ADD CONSTRAINT patients_pkey PRIMARY KEY (id);
< 
< 
< --
< -- Name: phenotypes phenotypes_pkey; Type: CONSTRAINT; Schema: backend; Owner: postgres
< --
< 
< ALTER TABLE ONLY backend.phenotypes
<     ADD CONSTRAINT phenotypes_pkey PRIMARY KEY (id);
< 
< 
< --
< -- Name: predefined_comments predefined_comments_comment_key; Type: CONSTRAINT; Schema: backend; Owner: postgres
< --
< 
< ALTER TABLE ONLY backend.predefined_comments
<     ADD CONSTRAINT predefined_comments_comment_key UNIQUE (comment);
< 
< 
< --
< -- Name: predefined_comments predefined_comments_pkey; Type: CONSTRAINT; Schema: backend; Owner: postgres
< --
< 
< ALTER TABLE ONLY backend.predefined_comments
<     ADD CONSTRAINT predefined_comments_pkey PRIMARY KEY (id);
< 
< 
< --
< -- Name: procedure_details procedure_details_pkey; Type: CONSTRAINT; Schema: backend; Owner: postgres
< --
< 
< ALTER TABLE ONLY backend.procedure_details
<     ADD CONSTRAINT procedure_details_pkey PRIMARY KEY (id);
< 
< 
< --
< -- Name: procedures procedures_code_key; Type: CONSTRAINT; Schema: backend; Owner: postgres
< --
< 
< ALTER TABLE ONLY backend.procedures
<     ADD CONSTRAINT procedures_code_key UNIQUE (code);
< 
< 
< --
< -- Name: procedures procedures_pkey; Type: CONSTRAINT; Schema: backend; Owner: postgres
< --
< 
< ALTER TABLE ONLY backend.procedures
<     ADD CONSTRAINT procedures_pkey PRIMARY KEY (id);
< 
< 
< --
< -- Name: recommendation_details recommendation_details_pkey; Type: CONSTRAINT; Schema: backend; Owner: postgres
< --
< 
< ALTER TABLE ONLY backend.recommendation_details
<     ADD CONSTRAINT recommendation_details_pkey PRIMARY KEY (id);
< 
< 
< --
< -- Name: recommendations recommendations_pkey; Type: CONSTRAINT; Schema: backend; Owner: postgres
< --
< 
< ALTER TABLE ONLY backend.recommendations
<     ADD CONSTRAINT recommendations_pkey PRIMARY KEY (id);
< 
< 
< --
< -- Name: repeat_order_messages repeat_order_messages_pkey; Type: CONSTRAINT; Schema: backend; Owner: postgres
< --
< 
< ALTER TABLE ONLY backend.repeat_order_messages
<     ADD CONSTRAINT repeat_order_messages_pkey PRIMARY KEY (id);
< 
< 
< --
< -- Name: result_drug_recommendations result_drug_recommendations_pkey; Type: CONSTRAINT; Schema: backend; Owner: postgres
< --
< 
< ALTER TABLE ONLY backend.result_drug_recommendations
<     ADD CONSTRAINT result_drug_recommendations_pkey PRIMARY KEY (id);
< 
< 
< --
< -- Name: results results_pkey; Type: CONSTRAINT; Schema: backend; Owner: postgres
< --
< 
< ALTER TABLE ONLY backend.results
<     ADD CONSTRAINT results_pkey PRIMARY KEY (id);
< 
< 
< --
< -- Name: roles roles_pkey; Type: CONSTRAINT; Schema: backend; Owner: postgres
< --
< 
< ALTER TABLE ONLY backend.roles
<     ADD CONSTRAINT roles_pkey PRIMARY KEY (id);
< 
< 
< --
< -- Name: status status_name_key; Type: CONSTRAINT; Schema: backend; Owner: postgres
< --
< 
< ALTER TABLE ONLY backend.status
<     ADD CONSTRAINT status_name_key UNIQUE (name);
< 
< 
< --
< -- Name: status status_pkey; Type: CONSTRAINT; Schema: backend; Owner: postgres
< --
< 
< ALTER TABLE ONLY backend.status
<     ADD CONSTRAINT status_pkey PRIMARY KEY (id);
< 
< 
< --
< -- Name: tracker tracker_pkey; Type: CONSTRAINT; Schema: backend; Owner: postgres
< --
< 
< ALTER TABLE ONLY backend.tracker
<     ADD CONSTRAINT tracker_pkey PRIMARY KEY (id);
< 
< 
< --
< -- Name: users users_pkey; Type: CONSTRAINT; Schema: backend; Owner: postgres
< --
< 
< ALTER TABLE ONLY backend.users
<     ADD CONSTRAINT users_pkey PRIMARY KEY (id);
< 
< 
< --
< -- Name: vcfs vcfs_pkey; Type: CONSTRAINT; Schema: backend; Owner: postgres
< --
< 
< ALTER TABLE ONLY backend.vcfs
<     ADD CONSTRAINT vcfs_pkey PRIMARY KEY (id);
< 
< 
< --
< -- Name: fki_overrides_orders_fkey; Type: INDEX; Schema: backend; Owner: postgres
< --
< 
< CREATE INDEX fki_overrides_orders_fkey ON backend.overrides USING btree (order_id);
< 
< 
< --
< -- Name: fki_overrides_results_fkey; Type: INDEX; Schema: backend; Owner: postgres
< --
< 
< CREATE INDEX fki_overrides_results_fkey ON backend.overrides USING btree (result_id);
< 
< 
< --
< -- Name: fki_results_orders_fkey; Type: INDEX; Schema: backend; Owner: postgres
< --
< 
< CREATE INDEX fki_results_orders_fkey ON backend.results USING btree (order_id);
< 
< 
< --
< -- Name: fki_tracker_orders_fkey; Type: INDEX; Schema: backend; Owner: postgres
< --
< 
< CREATE INDEX fki_tracker_orders_fkey ON backend.tracker USING btree (order_id);
< 
< 
< --
< -- Name: fki_vcfs_orders_fkey; Type: INDEX; Schema: backend; Owner: postgres
< --
< 
< CREATE INDEX fki_vcfs_orders_fkey ON backend.vcfs USING btree (order_id);
< 
< 
< --
< -- Name: idx_patients_mrn; Type: INDEX; Schema: backend; Owner: postgres
< --
< 
< CREATE INDEX idx_patients_mrn ON backend.patients USING btree (mrn);
< 
< 
< --
< -- Name: audit_log set_timestamp; Type: TRIGGER; Schema: backend; Owner: postgres
< --
< 
< CREATE TRIGGER set_timestamp BEFORE UPDATE ON backend.audit_log FOR EACH ROW EXECUTE FUNCTION backend.trigger_set_timestamp();
< 
< 
< --
< -- Name: comment_categories set_timestamp; Type: TRIGGER; Schema: backend; Owner: postgres
< --
< 
< CREATE TRIGGER set_timestamp BEFORE UPDATE ON backend.comment_categories FOR EACH ROW EXECUTE FUNCTION backend.trigger_set_timestamp();
< 
< 
< --
< -- Name: comments set_timestamp; Type: TRIGGER; Schema: backend; Owner: postgres
< --
< 
< CREATE TRIGGER set_timestamp BEFORE UPDATE ON backend.comments FOR EACH ROW EXECUTE FUNCTION backend.trigger_set_timestamp();
< 
< 
< --
< -- Name: drug_categories set_timestamp; Type: TRIGGER; Schema: backend; Owner: postgres
< --
< 
< CREATE TRIGGER set_timestamp BEFORE UPDATE ON backend.drug_categories FOR EACH ROW EXECUTE FUNCTION backend.trigger_set_timestamp();
< 
< 
< --
< -- Name: drugs set_timestamp; Type: TRIGGER; Schema: backend; Owner: postgres
< --
< 
< CREATE TRIGGER set_timestamp BEFORE UPDATE ON backend.drugs FOR EACH ROW EXECUTE FUNCTION backend.trigger_set_timestamp();
< 
< 
< --
< -- Name: gene_properties set_timestamp; Type: TRIGGER; Schema: backend; Owner: postgres
< --
< 
< CREATE TRIGGER set_timestamp BEFORE UPDATE ON backend.gene_properties FOR EACH ROW EXECUTE FUNCTION backend.trigger_set_timestamp();
< 
< 
< --
< -- Name: genes set_timestamp; Type: TRIGGER; Schema: backend; Owner: postgres
< --
< 
< CREATE TRIGGER set_timestamp BEFORE UPDATE ON backend.genes FOR EACH ROW EXECUTE FUNCTION backend.trigger_set_timestamp();
< 
< 
< --
< -- Name: genotypes set_timestamp; Type: TRIGGER; Schema: backend; Owner: postgres
< --
< 
< CREATE TRIGGER set_timestamp BEFORE UPDATE ON backend.genotypes FOR EACH ROW EXECUTE FUNCTION backend.trigger_set_timestamp();
< 
< 
< --
< -- Name: haplotypes set_timestamp; Type: TRIGGER; Schema: backend; Owner: postgres
< --
< 
< CREATE TRIGGER set_timestamp BEFORE UPDATE ON backend.haplotypes FOR EACH ROW EXECUTE FUNCTION backend.trigger_set_timestamp();
< 
< 
< --
< -- Name: mapping_status set_timestamp; Type: TRIGGER; Schema: backend; Owner: postgres
< --
< 
< CREATE TRIGGER set_timestamp BEFORE UPDATE ON backend.mapping_status FOR EACH ROW EXECUTE FUNCTION backend.trigger_set_timestamp();
< 
< 
< --
< -- Name: master_version_genotypes set_timestamp; Type: TRIGGER; Schema: backend; Owner: postgres
< --
< 
< CREATE TRIGGER set_timestamp BEFORE UPDATE ON backend.master_version_genotypes FOR EACH ROW EXECUTE FUNCTION backend.trigger_set_timestamp();
< 
< 
< --
< -- Name: master_version_haplotypes set_timestamp; Type: TRIGGER; Schema: backend; Owner: postgres
< --
< 
< CREATE TRIGGER set_timestamp BEFORE UPDATE ON backend.master_version_haplotypes FOR EACH ROW EXECUTE FUNCTION backend.trigger_set_timestamp();
< 
< 
< --
< -- Name: master_version_phenotypes set_timestamp; Type: TRIGGER; Schema: backend; Owner: postgres
< --
< 
< CREATE TRIGGER set_timestamp BEFORE UPDATE ON backend.master_version_phenotypes FOR EACH ROW EXECUTE FUNCTION backend.trigger_set_timestamp();
< 
< 
< --
< -- Name: master_version_recommendations set_timestamp; Type: TRIGGER; Schema: backend; Owner: postgres
< --
< 
< CREATE TRIGGER set_timestamp BEFORE UPDATE ON backend.master_version_recommendations FOR EACH ROW EXECUTE FUNCTION backend.trigger_set_timestamp();
< 
< 
< --
< -- Name: master_versions set_timestamp; Type: TRIGGER; Schema: backend; Owner: postgres
< --
< 
< CREATE TRIGGER set_timestamp BEFORE UPDATE ON backend.master_versions FOR EACH ROW EXECUTE FUNCTION backend.trigger_set_timestamp();
< 
< 
< --
< -- Name: orders set_timestamp; Type: TRIGGER; Schema: backend; Owner: postgres
< --
< 
< CREATE TRIGGER set_timestamp BEFORE UPDATE ON backend.orders FOR EACH ROW EXECUTE FUNCTION backend.trigger_set_timestamp();
< 
< 
< --
< -- Name: overrides set_timestamp; Type: TRIGGER; Schema: backend; Owner: postgres
< --
< 
< CREATE TRIGGER set_timestamp BEFORE UPDATE ON backend.overrides FOR EACH ROW EXECUTE FUNCTION backend.trigger_set_timestamp();
< 
< 
< --
< -- Name: patients set_timestamp; Type: TRIGGER; Schema: backend; Owner: postgres
< --
< 
< CREATE TRIGGER set_timestamp BEFORE UPDATE ON backend.patients FOR EACH ROW EXECUTE FUNCTION backend.trigger_set_timestamp();
< 
< 
< --
< -- Name: patients_archive set_timestamp; Type: TRIGGER; Schema: backend; Owner: postgres
< --
< 
< CREATE TRIGGER set_timestamp BEFORE UPDATE ON backend.patients_archive FOR EACH ROW EXECUTE FUNCTION backend.trigger_set_timestamp();
< 
< 
< --
< -- Name: phenotypes set_timestamp; Type: TRIGGER; Schema: backend; Owner: postgres
< --
< 
< CREATE TRIGGER set_timestamp BEFORE UPDATE ON backend.phenotypes FOR EACH ROW EXECUTE FUNCTION backend.trigger_set_timestamp();
< 
< 
< --
< -- Name: predefined_comments set_timestamp; Type: TRIGGER; Schema: backend; Owner: postgres
< --
< 
< CREATE TRIGGER set_timestamp BEFORE UPDATE ON backend.predefined_comments FOR EACH ROW EXECUTE FUNCTION backend.trigger_set_timestamp();
< 
< 
< --
< -- Name: procedure_details set_timestamp; Type: TRIGGER; Schema: backend; Owner: postgres
< --
< 
< CREATE TRIGGER set_timestamp BEFORE UPDATE ON backend.procedure_details FOR EACH ROW EXECUTE FUNCTION backend.trigger_set_timestamp();
< 
< 
< --
< -- Name: procedures set_timestamp; Type: TRIGGER; Schema: backend; Owner: postgres
< --
< 
< CREATE TRIGGER set_timestamp BEFORE UPDATE ON backend.procedures FOR EACH ROW EXECUTE FUNCTION backend.trigger_set_timestamp();
< 
< 
< --
< -- Name: recommendation_details set_timestamp; Type: TRIGGER; Schema: backend; Owner: postgres
< --
< 
< CREATE TRIGGER set_timestamp BEFORE UPDATE ON backend.recommendation_details FOR EACH ROW EXECUTE FUNCTION backend.trigger_set_timestamp();
< 
< 
< --
< -- Name: recommendations set_timestamp; Type: TRIGGER; Schema: backend; Owner: postgres
< --
< 
< CREATE TRIGGER set_timestamp BEFORE UPDATE ON backend.recommendations FOR EACH ROW EXECUTE FUNCTION backend.trigger_set_timestamp();
< 
< 
< --
< -- Name: result_drug_recommendations set_timestamp; Type: TRIGGER; Schema: backend; Owner: postgres
< --
< 
< CREATE TRIGGER set_timestamp BEFORE UPDATE ON backend.result_drug_recommendations FOR EACH ROW EXECUTE FUNCTION backend.trigger_set_timestamp();
< 
< 
< --
< -- Name: results set_timestamp; Type: TRIGGER; Schema: backend; Owner: postgres
< --
< 
< CREATE TRIGGER set_timestamp BEFORE UPDATE ON backend.results FOR EACH ROW EXECUTE FUNCTION backend.trigger_set_timestamp();
< 
< 
< --
< -- Name: roles set_timestamp; Type: TRIGGER; Schema: backend; Owner: postgres
< --
< 
< CREATE TRIGGER set_timestamp BEFORE UPDATE ON backend.roles FOR EACH ROW EXECUTE FUNCTION backend.trigger_set_timestamp();
< 
< 
< --
< -- Name: status set_timestamp; Type: TRIGGER; Schema: backend; Owner: postgres
< --
< 
< CREATE TRIGGER set_timestamp BEFORE UPDATE ON backend.status FOR EACH ROW EXECUTE FUNCTION backend.trigger_set_timestamp();
< 
< 
< --
< -- Name: tracker set_timestamp; Type: TRIGGER; Schema: backend; Owner: postgres
< --
< 
< CREATE TRIGGER set_timestamp BEFORE UPDATE ON backend.tracker FOR EACH ROW EXECUTE FUNCTION backend.trigger_set_timestamp();
< 
< 
< --
< -- Name: users set_timestamp; Type: TRIGGER; Schema: backend; Owner: postgres
< --
< 
< CREATE TRIGGER set_timestamp BEFORE UPDATE ON backend.users FOR EACH ROW EXECUTE FUNCTION backend.trigger_set_timestamp();
< 
< 
< --
< -- Name: vcfs set_timestamp; Type: TRIGGER; Schema: backend; Owner: postgres
< --
< 
< CREATE TRIGGER set_timestamp BEFORE UPDATE ON backend.vcfs FOR EACH ROW EXECUTE FUNCTION backend.trigger_set_timestamp();
< 
< 
< --
< -- Name: audit_log audit_log_user_id_fkey; Type: FK CONSTRAINT; Schema: backend; Owner: postgres
< --
< 
< ALTER TABLE ONLY backend.audit_log
<     ADD CONSTRAINT audit_log_user_id_fkey FOREIGN KEY (user_id) REFERENCES backend.users(id);
< 
< 
< --
< -- Name: comments comments_category_id_fkey; Type: FK CONSTRAINT; Schema: backend; Owner: postgres
< --
< 
< ALTER TABLE ONLY backend.comments
<     ADD CONSTRAINT comments_category_id_fkey FOREIGN KEY (category_id) REFERENCES backend.comment_categories(id);
< 
< 
< --
< -- Name: comments comments_order_id_fkey; Type: FK CONSTRAINT; Schema: backend; Owner: postgres
< --
< 
< ALTER TABLE ONLY backend.comments
<     ADD CONSTRAINT comments_order_id_fkey FOREIGN KEY (order_id) REFERENCES backend.orders(id);
< 
< 
< --
< -- Name: comments comments_result_id_fkey; Type: FK CONSTRAINT; Schema: backend; Owner: postgres
< --
< 
< ALTER TABLE ONLY backend.comments
<     ADD CONSTRAINT comments_result_id_fkey FOREIGN KEY (result_id) REFERENCES backend.results(id);
< 
< 
< --
< -- Name: comments comments_user_id_fkey; Type: FK CONSTRAINT; Schema: backend; Owner: postgres
< --
< 
< ALTER TABLE ONLY backend.comments
<     ADD CONSTRAINT comments_user_id_fkey FOREIGN KEY (user_id) REFERENCES backend.users(id);
< 
< 
< --
< -- Name: drugs drugs_drug_category_id_fkey; Type: FK CONSTRAINT; Schema: backend; Owner: postgres
< --
< 
< ALTER TABLE ONLY backend.drugs
<     ADD CONSTRAINT drugs_drug_category_id_fkey FOREIGN KEY (drug_category_id) REFERENCES backend.drug_categories(id);
< 
< 
< --
< -- Name: genotypes genotypes_gene_id_fkey; Type: FK CONSTRAINT; Schema: backend; Owner: postgres
< --
< 
< ALTER TABLE ONLY backend.genotypes
<     ADD CONSTRAINT genotypes_gene_id_fkey FOREIGN KEY (gene_id) REFERENCES backend.genes(id);
< 
< 
< --
< -- Name: haplotypes haplotypes_gene_id_fkey; Type: FK CONSTRAINT; Schema: backend; Owner: postgres
< --
< 
< ALTER TABLE ONLY backend.haplotypes
<     ADD CONSTRAINT haplotypes_gene_id_fkey FOREIGN KEY (gene_id) REFERENCES backend.genes(id);
< 
< 
< --
< -- Name: master_version_genotypes master_version_genotypes_genotype_id_fkey; Type: FK CONSTRAINT; Schema: backend; Owner: postgres
< --
< 
< ALTER TABLE ONLY backend.master_version_genotypes
<     ADD CONSTRAINT master_version_genotypes_genotype_id_fkey FOREIGN KEY (genotype_id) REFERENCES backend.genotypes(id);
< 
< 
< --
< -- Name: master_version_genotypes master_version_genotypes_master_version_id_fkey; Type: FK CONSTRAINT; Schema: backend; Owner: postgres
< --
< 
< ALTER TABLE ONLY backend.master_version_genotypes
<     ADD CONSTRAINT master_version_genotypes_master_version_id_fkey FOREIGN KEY (master_version_id) REFERENCES backend.master_versions(id);
< 
< 
< --
< -- Name: master_version_haplotypes master_version_haplotypes_haplotype_id_fkey; Type: FK CONSTRAINT; Schema: backend; Owner: postgres
< --
< 
< ALTER TABLE ONLY backend.master_version_haplotypes
<     ADD CONSTRAINT master_version_haplotypes_haplotype_id_fkey FOREIGN KEY (haplotype_id) REFERENCES backend.haplotypes(id);
< 
< 
< --
< -- Name: master_version_haplotypes master_version_haplotypes_master_version_id_fkey; Type: FK CONSTRAINT; Schema: backend; Owner: postgres
< --
< 
< ALTER TABLE ONLY backend.master_version_haplotypes
<     ADD CONSTRAINT master_version_haplotypes_master_version_id_fkey FOREIGN KEY (master_version_id) REFERENCES backend.master_versions(id);
< 
< 
< --
< -- Name: master_version_phenotypes master_version_phenotypes_master_version_id_fkey; Type: FK CONSTRAINT; Schema: backend; Owner: postgres
< --
< 
< ALTER TABLE ONLY backend.master_version_phenotypes
<     ADD CONSTRAINT master_version_phenotypes_master_version_id_fkey FOREIGN KEY (master_version_id) REFERENCES backend.master_versions(id);
< 
< 
< --
< -- Name: master_version_phenotypes master_version_phenotypes_phenotype_id_fkey; Type: FK CONSTRAINT; Schema: backend; Owner: postgres
< --
< 
< ALTER TABLE ONLY backend.master_version_phenotypes
<     ADD CONSTRAINT master_version_phenotypes_phenotype_id_fkey FOREIGN KEY (phenotype_id) REFERENCES backend.phenotypes(id);
< 
< 
< --
< -- Name: master_version_recommendations master_version_recommendations_master_version_id_fkey; Type: FK CONSTRAINT; Schema: backend; Owner: postgres
< --
< 
< ALTER TABLE ONLY backend.master_version_recommendations
<     ADD CONSTRAINT master_version_recommendations_master_version_id_fkey FOREIGN KEY (master_version_id) REFERENCES backend.master_versions(id);
< 
< 
< --
< -- Name: master_version_recommendations master_version_recommendations_recommendation_id_fkey; Type: FK CONSTRAINT; Schema: backend; Owner: postgres
< --
< 
< ALTER TABLE ONLY backend.master_version_recommendations
<     ADD CONSTRAINT master_version_recommendations_recommendation_id_fkey FOREIGN KEY (recommendation_id) REFERENCES backend.recommendations(id);
< 
< 
< --
< -- Name: orders orders_patient_id_fkey; Type: FK CONSTRAINT; Schema: backend; Owner: postgres
< --
< 
< ALTER TABLE ONLY backend.orders
<     ADD CONSTRAINT orders_patient_id_fkey FOREIGN KEY (patient_id) REFERENCES backend.patients(id);
< 
< 
< --
< -- Name: orders orders_procedure_id_fkey; Type: FK CONSTRAINT; Schema: backend; Owner: postgres
< --
< 
< ALTER TABLE ONLY backend.orders
<     ADD CONSTRAINT orders_procedure_id_fkey FOREIGN KEY (procedure_id) REFERENCES backend.procedures(id);
< 
< 
< --
< -- Name: orders orders_status_fkey; Type: FK CONSTRAINT; Schema: backend; Owner: postgres
< --
< 
< ALTER TABLE ONLY backend.orders
<     ADD CONSTRAINT orders_status_fkey FOREIGN KEY (status) REFERENCES backend.status(id);
< 
< 
< --
< -- Name: overrides overrides_order_id_fkey; Type: FK CONSTRAINT; Schema: backend; Owner: postgres
< --
< 
< ALTER TABLE ONLY backend.overrides
<     ADD CONSTRAINT overrides_order_id_fkey FOREIGN KEY (order_id) REFERENCES backend.orders(id);
< 
< 
< --
< -- Name: overrides overrides_overridden_by_fkey; Type: FK CONSTRAINT; Schema: backend; Owner: postgres
< --
< 
< ALTER TABLE ONLY backend.overrides
<     ADD CONSTRAINT overrides_overridden_by_fkey FOREIGN KEY (overridden_by) REFERENCES backend.users(id);
< 
< 
< --
< -- Name: overrides overrides_result_id_fkey; Type: FK CONSTRAINT; Schema: backend; Owner: postgres
< --
< 
< ALTER TABLE ONLY backend.overrides
<     ADD CONSTRAINT overrides_result_id_fkey FOREIGN KEY (result_id) REFERENCES backend.results(id);
< 
< 
< --
< -- Name: patients_archive patients_archive_id_fkey; Type: FK CONSTRAINT; Schema: backend; Owner: postgres
< --
< 
< ALTER TABLE ONLY backend.patients_archive
<     ADD CONSTRAINT patients_archive_id_fkey FOREIGN KEY (id) REFERENCES backend.patients(id);
< 
< 
< --
< -- Name: phenotypes phenotypes_gene_id_fkey; Type: FK CONSTRAINT; Schema: backend; Owner: postgres
< --
< 
< ALTER TABLE ONLY backend.phenotypes
<     ADD CONSTRAINT phenotypes_gene_id_fkey FOREIGN KEY (gene_id) REFERENCES backend.genes(id);
< 
< 
< --
< -- Name: predefined_comments predefined_comments_category_id_fkey; Type: FK CONSTRAINT; Schema: backend; Owner: postgres
< --
< 
< ALTER TABLE ONLY backend.predefined_comments
<     ADD CONSTRAINT predefined_comments_category_id_fkey FOREIGN KEY (category_id) REFERENCES backend.comment_categories(id);
< 
< 
< --
< -- Name: procedure_details procedure_details_gene_id_fkey; Type: FK CONSTRAINT; Schema: backend; Owner: postgres
< --
< 
< ALTER TABLE ONLY backend.procedure_details
<     ADD CONSTRAINT procedure_details_gene_id_fkey FOREIGN KEY (gene_id) REFERENCES backend.genes(id);
< 
< 
< --
< -- Name: procedure_details procedure_details_procedure_id_fkey; Type: FK CONSTRAINT; Schema: backend; Owner: postgres
< --
< 
< ALTER TABLE ONLY backend.procedure_details
<     ADD CONSTRAINT procedure_details_procedure_id_fkey FOREIGN KEY (procedure_id) REFERENCES backend.procedures(id);
< 
< 
< --
< -- Name: recommendation_details recommendation_details_gene_id_fkey; Type: FK CONSTRAINT; Schema: backend; Owner: postgres
< --
< 
< ALTER TABLE ONLY backend.recommendation_details
<     ADD CONSTRAINT recommendation_details_gene_id_fkey FOREIGN KEY (gene_id) REFERENCES backend.genes(id);
< 
< 
< --
< -- Name: recommendation_details recommendation_details_gene_property_id_fkey; Type: FK CONSTRAINT; Schema: backend; Owner: postgres
< --
< 
< ALTER TABLE ONLY backend.recommendation_details
<     ADD CONSTRAINT recommendation_details_gene_property_id_fkey FOREIGN KEY (gene_property_id) REFERENCES backend.gene_properties(id);
< 
< 
< --
< -- Name: recommendation_details recommendation_details_recommendation_id_fkey; Type: FK CONSTRAINT; Schema: backend; Owner: postgres
< --
< 
< ALTER TABLE ONLY backend.recommendation_details
<     ADD CONSTRAINT recommendation_details_recommendation_id_fkey FOREIGN KEY (recommendation_id) REFERENCES backend.recommendations(id);
< 
< 
< --
< -- Name: recommendations recommendations_drug_id_fkey; Type: FK CONSTRAINT; Schema: backend; Owner: postgres
< --
< 
< ALTER TABLE ONLY backend.recommendations
<     ADD CONSTRAINT recommendations_drug_id_fkey FOREIGN KEY (drug_id) REFERENCES backend.drugs(id);
< 
< 
< --
< -- Name: result_drug_recommendations result_drug_recommendations_created_by_fkey; Type: FK CONSTRAINT; Schema: backend; Owner: postgres
< --
< 
< ALTER TABLE ONLY backend.result_drug_recommendations
<     ADD CONSTRAINT result_drug_recommendations_created_by_fkey FOREIGN KEY (created_by) REFERENCES backend.users(id);
< 
< 
< --
< -- Name: result_drug_recommendations result_drug_recommendations_result_id_fkey; Type: FK CONSTRAINT; Schema: backend; Owner: postgres
< --
< 
< ALTER TABLE ONLY backend.result_drug_recommendations
<     ADD CONSTRAINT result_drug_recommendations_result_id_fkey FOREIGN KEY (result_id) REFERENCES backend.results(id);
< 
< 
< --
< -- Name: results results_created_by_fkey; Type: FK CONSTRAINT; Schema: backend; Owner: postgres
< --
< 
< ALTER TABLE ONLY backend.results
<     ADD CONSTRAINT results_created_by_fkey FOREIGN KEY (created_by) REFERENCES backend.users(id);
< 
< 
< --
< -- Name: results results_mapping_status_fkey; Type: FK CONSTRAINT; Schema: backend; Owner: postgres
< --
< 
< ALTER TABLE ONLY backend.results
<     ADD CONSTRAINT results_mapping_status_fkey FOREIGN KEY (mapping_status) REFERENCES backend.mapping_status(id);
< 
< 
< --
< -- Name: results results_master_version_id_fkey; Type: FK CONSTRAINT; Schema: backend; Owner: postgres
< --
< 
< ALTER TABLE ONLY backend.results
<     ADD CONSTRAINT results_master_version_id_fkey FOREIGN KEY (master_version_id) REFERENCES backend.master_versions(id);
< 
< 
< --
< -- Name: results results_order_id_fkey; Type: FK CONSTRAINT; Schema: backend; Owner: postgres
< --
< 
< ALTER TABLE ONLY backend.results
<     ADD CONSTRAINT results_order_id_fkey FOREIGN KEY (order_id) REFERENCES backend.orders(id);
< 
< 
< --
< -- Name: results results_vcf_id_fkey; Type: FK CONSTRAINT; Schema: backend; Owner: postgres
< --
< 
< ALTER TABLE ONLY backend.results
<     ADD CONSTRAINT results_vcf_id_fkey FOREIGN KEY (vcf_id) REFERENCES backend.vcfs(id);
< 
< 
< --
< -- Name: tracker tracker_order_id_fkey; Type: FK CONSTRAINT; Schema: backend; Owner: postgres
< --
< 
< ALTER TABLE ONLY backend.tracker
<     ADD CONSTRAINT tracker_order_id_fkey FOREIGN KEY (order_id) REFERENCES backend.orders(id);
< 
< 
< --
< -- Name: tracker tracker_status_fkey; Type: FK CONSTRAINT; Schema: backend; Owner: postgres
< --
< 
< ALTER TABLE ONLY backend.tracker
<     ADD CONSTRAINT tracker_status_fkey FOREIGN KEY (status) REFERENCES backend.status(id);
< 
< 
< --
< -- Name: tracker tracker_user_id_fkey; Type: FK CONSTRAINT; Schema: backend; Owner: postgres
< --
< 
< ALTER TABLE ONLY backend.tracker
<     ADD CONSTRAINT tracker_user_id_fkey FOREIGN KEY (user_id) REFERENCES backend.users(id);
< 
< 
< --
< -- Name: users users_role_id_fkey; Type: FK CONSTRAINT; Schema: backend; Owner: postgres
< --
< 
< ALTER TABLE ONLY backend.users
<     ADD CONSTRAINT users_role_id_fkey FOREIGN KEY (role_id) REFERENCES backend.roles(id);
< 
< 
< --
< -- Name: vcfs vcfs_order_id_fkey; Type: FK CONSTRAINT; Schema: backend; Owner: postgres
< --
< 
< ALTER TABLE ONLY backend.vcfs
<     ADD CONSTRAINT vcfs_order_id_fkey FOREIGN KEY (order_id) REFERENCES backend.orders(id);
---
> REVOKE ALL ON SCHEMA public FROM rdsadmin;
> REVOKE ALL ON SCHEMA public FROM PUBLIC;
> GRANT ALL ON SCHEMA public TO postgres;
> GRANT ALL ON SCHEMA public TO PUBLIC;
