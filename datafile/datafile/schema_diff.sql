838,873d837
< -- Name: sample_table; Type: TABLE; Schema: public; Owner: postgres
< --
< 
< CREATE TABLE public.sample_table (
<     id integer NOT NULL,
<     name character varying(100) NOT NULL,
<     age integer NOT NULL,
<     email character varying(100) NOT NULL
< );
< 
< 
< ALTER TABLE public.sample_table OWNER TO postgres;
< 
< --
< -- Name: sample_table_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
< --
< 
< CREATE SEQUENCE public.sample_table_id_seq
<     AS integer
<     START WITH 1
<     INCREMENT BY 1
<     NO MINVALUE
<     NO MAXVALUE
<     CACHE 1;
< 
< 
< ALTER TABLE public.sample_table_id_seq OWNER TO postgres;
< 
< --
< -- Name: sample_table_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
< --
< 
< ALTER SEQUENCE public.sample_table_id_seq OWNED BY public.sample_table.id;
< 
< 
< --
902,908d865
< -- Name: sample_table id; Type: DEFAULT; Schema: public; Owner: postgres
< --
< 
< ALTER TABLE ONLY public.sample_table ALTER COLUMN id SET DEFAULT nextval('public.sample_table_id_seq'::regclass);
< 
< 
< --
1226,1241d1182
< 
< 
< --
< -- Name: sample_table sample_table_email_key; Type: CONSTRAINT; Schema: public; Owner: postgres
< --
< 
< ALTER TABLE ONLY public.sample_table
<     ADD CONSTRAINT sample_table_email_key UNIQUE (email);
< 
< 
< --
< -- Name: sample_table sample_table_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
< --
< 
< ALTER TABLE ONLY public.sample_table
<     ADD CONSTRAINT sample_table_pkey PRIMARY KEY (id);
