6103,6114d6102
< -- Data for Name: sample_table; Type: TABLE DATA; Schema: public; Owner: postgres
< --
< 
< COPY public.sample_table (id, name, age, email) FROM stdin;
< 1	John Doe	30	john.doe@example.com
< 2	Jane Smith	25	jane.smith@example.com
< 3	Alice Johnson	28	alice.johnson@example.com
< 4	Bob Brown	35	bob.brown@example.com
< \.
< 
< 
< --
6140,6146d6127
< 
< 
< --
< -- Name: sample_table_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
< --
< 
< SELECT pg_catalog.setval('public.sample_table_id_seq', 4, true);
