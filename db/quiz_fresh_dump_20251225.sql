--
-- PostgreSQL database dump
--

\restrict XthN5LtghEj0vd44od7fQTfQqqcirbRR8YJ1e2azWOTNl16l6IIQIuGXFEGOB98

-- Dumped from database version 15.14 (Debian 15.14-0+deb12u1)
-- Dumped by pg_dump version 15.14 (Debian 15.14-0+deb12u1)

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

SET default_tablespace = '';

SET default_table_access_method = heap;

--
-- Name: app_user; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.app_user (
    id bigint NOT NULL,
    email character varying(255) NOT NULL,
    full_name character varying(255) NOT NULL,
    role text NOT NULL,
    is_active boolean DEFAULT true NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    dni character varying(32),
    CONSTRAINT app_user_role_check CHECK ((role = ANY (ARRAY['student'::text, 'teacher'::text, 'admin'::text, 'power_student'::text])))
);


--
-- Name: app_user_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.app_user_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: app_user_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.app_user_id_seq OWNED BY public.app_user.id;


--
-- Name: course; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.course (
    id bigint NOT NULL,
    code character varying(50) NOT NULL,
    name character varying(255) NOT NULL,
    description text,
    owner_id bigint,
    academic_year integer NOT NULL,
    class_group character varying(50) NOT NULL,
    is_active boolean DEFAULT true NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    CONSTRAINT course_academic_year_check CHECK (((academic_year >= 2000) AND (academic_year <= 9999)))
);


--
-- Name: course_enrollment; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.course_enrollment (
    id bigint NOT NULL,
    course_id bigint NOT NULL,
    user_id bigint NOT NULL,
    role_in_course text DEFAULT 'student'::text NOT NULL,
    enrolled_at timestamp with time zone DEFAULT now() NOT NULL,
    CONSTRAINT course_enrollment_role_in_course_check CHECK ((role_in_course = ANY (ARRAY['student'::text, 'assistant'::text, 'teacher'::text])))
);


--
-- Name: course_enrollment_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.course_enrollment_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: course_enrollment_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.course_enrollment_id_seq OWNED BY public.course_enrollment.id;


--
-- Name: course_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.course_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: course_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.course_id_seq OWNED BY public.course.id;


--
-- Name: question_bank; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.question_bank (
    id bigint NOT NULL,
    course_id bigint NOT NULL,
    question_text text NOT NULL,
    question_type text NOT NULL,
    default_points numeric(6,2) DEFAULT 1 NOT NULL,
    is_active boolean DEFAULT true NOT NULL,
    created_by bigint,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    CONSTRAINT question_bank_question_type_check CHECK ((question_type = ANY (ARRAY['single_choice'::text, 'multiple_choice'::text, 'open'::text, 'numeric'::text])))
);


--
-- Name: question_bank_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.question_bank_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: question_bank_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.question_bank_id_seq OWNED BY public.question_bank.id;


--
-- Name: question_option; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.question_option (
    id bigint NOT NULL,
    question_id bigint NOT NULL,
    option_text text NOT NULL,
    is_correct boolean DEFAULT false NOT NULL,
    order_index integer NOT NULL
);


--
-- Name: question_option_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.question_option_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: question_option_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.question_option_id_seq OWNED BY public.question_option.id;


--
-- Name: staging_dni; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.staging_dni (
    ll1alu text,
    ll2alu text,
    nomalu text,
    alu_dnialu text
);


--
-- Name: student_answer; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.student_answer (
    id bigint NOT NULL,
    attempt_id bigint NOT NULL,
    question_id bigint NOT NULL,
    selected_option_id bigint,
    free_text_answer text,
    numeric_answer numeric(10,2),
    is_correct boolean,
    score numeric(6,2),
    feedback text,
    graded_by bigint,
    graded_at timestamp with time zone
);


--
-- Name: student_answer_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.student_answer_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: student_answer_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.student_answer_id_seq OWNED BY public.student_answer.id;


--
-- Name: test; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.test (
    id bigint NOT NULL,
    course_id bigint NOT NULL,
    title character varying(255) NOT NULL,
    description text,
    test_type text DEFAULT 'quiz'::text NOT NULL,
    is_published boolean DEFAULT false NOT NULL,
    total_points numeric(7,2) DEFAULT 0,
    time_limit_minutes integer,
    max_attempts integer DEFAULT 1,
    grading_strategy text DEFAULT 'latest'::text NOT NULL,
    start_time timestamp with time zone,
    end_time timestamp with time zone,
    randomize_questions boolean DEFAULT false NOT NULL,
    randomize_options boolean DEFAULT false NOT NULL,
    created_by bigint,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    CONSTRAINT test_grading_strategy_check CHECK ((grading_strategy = ANY (ARRAY['latest'::text, 'highest'::text, 'first'::text]))),
    CONSTRAINT test_test_type_check CHECK ((test_type = ANY (ARRAY['quiz'::text, 'exam'::text, 'practice'::text])))
);


--
-- Name: test_attempt; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.test_attempt (
    id bigint NOT NULL,
    test_id bigint NOT NULL,
    student_id bigint NOT NULL,
    attempt_number integer DEFAULT 1 NOT NULL,
    started_at timestamp with time zone DEFAULT now() NOT NULL,
    submitted_at timestamp with time zone,
    status text DEFAULT 'in_progress'::text NOT NULL,
    score numeric(7,2),
    max_score numeric(7,2),
    percentage numeric(5,2),
    auto_graded boolean DEFAULT false NOT NULL,
    CONSTRAINT test_attempt_status_check CHECK ((status = ANY (ARRAY['in_progress'::text, 'submitted'::text, 'graded'::text])))
);


--
-- Name: test_attempt_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.test_attempt_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: test_attempt_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.test_attempt_id_seq OWNED BY public.test_attempt.id;


--
-- Name: test_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.test_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: test_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.test_id_seq OWNED BY public.test.id;


--
-- Name: test_question; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.test_question (
    id bigint NOT NULL,
    test_id bigint NOT NULL,
    question_id bigint NOT NULL,
    order_index integer NOT NULL,
    points numeric(6,2)
);


--
-- Name: test_question_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.test_question_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: test_question_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.test_question_id_seq OWNED BY public.test_question.id;


--
-- Name: app_user id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.app_user ALTER COLUMN id SET DEFAULT nextval('public.app_user_id_seq'::regclass);


--
-- Name: course id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.course ALTER COLUMN id SET DEFAULT nextval('public.course_id_seq'::regclass);


--
-- Name: course_enrollment id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.course_enrollment ALTER COLUMN id SET DEFAULT nextval('public.course_enrollment_id_seq'::regclass);


--
-- Name: question_bank id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.question_bank ALTER COLUMN id SET DEFAULT nextval('public.question_bank_id_seq'::regclass);


--
-- Name: question_option id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.question_option ALTER COLUMN id SET DEFAULT nextval('public.question_option_id_seq'::regclass);


--
-- Name: student_answer id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.student_answer ALTER COLUMN id SET DEFAULT nextval('public.student_answer_id_seq'::regclass);


--
-- Name: test id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.test ALTER COLUMN id SET DEFAULT nextval('public.test_id_seq'::regclass);


--
-- Name: test_attempt id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.test_attempt ALTER COLUMN id SET DEFAULT nextval('public.test_attempt_id_seq'::regclass);


--
-- Name: test_question id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.test_question ALTER COLUMN id SET DEFAULT nextval('public.test_question_id_seq'::regclass);


--
-- Data for Name: app_user; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.app_user (id, email, full_name, role, is_active, created_at, dni) FROM stdin;
29	student028@2526-45810-a.local	Javier Echávarri Espinosa	student	t	2025-11-18 23:18:21.545234+00	54294677
1	ramiro.rego@ufv.es	Ramiro Rego Álvarez	teacher	t	2025-11-18 23:18:21.494901+00	09393767
4	student003@2526-45810-a.local	Adriana Moyo Sánchez	power_student	t	2025-11-18 23:18:21.545234+00	06024021
100	ramiro.rego@gmail.es	Guybrush Threepwood	power_student	t	2025-12-25 09:25:39.254858+00	09393768
7	student006@2526-45810-a.local	Alejandro de la Maza Segura	student	t	2025-11-18 23:18:21.545234+00	48109544
5	student004@2526-45810-a.local	Alejandro Sainz Carpio	student	t	2025-11-18 23:18:21.545234+00	54352724
3	student002@2526-45810-a.local	Adriana Arias Giménez	student	t	2025-11-18 23:18:21.545234+00	49442937
70	student069@2526-45810-a.local	Álvaro Adeva Torres	student	t	2025-11-18 23:18:21.545234+00	48225548
73	student072@2526-45810-a.local	Álvaro de Celis Muñoz	student	t	2025-11-18 23:18:21.545234+00	54189676
46	student045@2526-45810-a.local	Marina Casero López	student	t	2025-11-18 23:18:21.545234+00	11874784
9	student008@2526-45810-a.local	Andrea García Soria	student	t	2025-11-18 23:18:21.545234+00	47588042
64	student063@2526-45810-a.local	Sergio Ruiz Carrasco	student	t	2025-11-18 23:18:21.545234+00	51009659
13	student012@2526-45810-a.local	Claudia Serrada de Pedraza	student	t	2025-11-18 23:18:21.545234+00	06618119
15	student014@2526-45810-a.local	Daira García Gómez	student	t	2025-11-18 23:18:21.545234+00	51007316
61	student060@2526-45810-a.local	Raúl Cerezo Resino	student	t	2025-11-18 23:18:21.545234+00	05963339
16	student015@2526-45810-a.local	Diego López Ruiz	student	t	2025-11-18 23:18:21.545234+00	54369131
72	student071@2526-45810-a.local	Álvaro Goizueta Granda	student	t	2025-11-18 23:18:21.545234+00	02578999
18	student017@2526-45810-a.local	Elizabeth Crende Daou	student	t	2025-11-18 23:18:21.545234+00	48206010
23	student022@2526-45810-a.local	Gonzalo de Mier Fernández-Caro	student	t	2025-11-18 23:18:21.545234+00	48034111
20	student019@2526-45810-a.local	Gonzalo Carrasco Barros	student	t	2025-11-18 23:18:21.545234+00	05952488
43	student042@2526-45810-a.local	Luisa Herrero San Pío	student	t	2025-11-18 23:18:21.545234+00	70269287
22	student021@2526-45810-a.local	Gonzalo Salas Dorado	student	t	2025-11-18 23:18:21.545234+00	54369366
27	student026@2526-45810-a.local	Iván Alba Eguinoa	student	t	2025-11-18 23:18:21.545234+00	02566101
50	student049@2526-45810-a.local	Martín Hernández-Palacios Prados	student	t	2025-11-18 23:18:21.545234+00	71990541
28	student027@2526-45810-a.local	Jaime Serna González	student	t	2025-11-18 23:18:21.545234+00	45332592
71	student070@2526-45810-a.local	Álvaro Esteban de Nicolás	student	t	2025-11-18 23:18:21.545234+00	51134411
21	student020@2526-45810-a.local	Gonzalo Ramírez Sánchez-Marcos	student	t	2025-11-18 23:18:21.545234+00	54189426
32	student031@2526-45810-a.local	Jesús Ramírez Vega	student	t	2025-11-18 23:18:21.545234+00	54211682
49	student048@2526-45810-a.local	Marta Sánchez López	student	t	2025-11-18 23:18:21.545234+00	54366778
35	student034@2526-45810-a.local	Juan Manuel Pedraza Rioboo	student	t	2025-11-18 23:18:21.545234+00	05961361
45	student044@2526-45810-a.local	Marcos López Domínguez	student	t	2025-11-18 23:18:21.545234+00	54494079
47	student046@2526-45810-a.local	Mario Marín Fernández	student	t	2025-11-18 23:18:21.545234+00	47317452
63	student062@2526-45810-a.local	Samuel Pardo Acosta	student	t	2025-11-18 23:18:21.545234+00	BD607403
52	student051@2526-45810-a.local	Miguel Poudereux López-Barrantes	student	t	2025-11-18 23:18:21.545234+00	51501099
53	student052@2526-45810-a.local	Nicolás Abal Miranda	student	t	2025-11-18 23:18:21.545234+00	54480534
25	student024@2526-45810-a.local	Ignacio Valiente Saludes	student	t	2025-11-18 23:18:21.545234+00	51758855
24	student023@2526-45810-a.local	Ian David Isla de Cegama	student	t	2025-11-18 23:18:21.545234+00	08015151
6	student005@2526-45810-a.local	Alejandro Valverde Albaladejo	student	t	2025-11-18 23:18:21.545234+00	48081409
55	student054@2526-45810-a.local	Pablo Abad Pérez	student	t	2025-11-18 23:18:21.545234+00	06610675
14	student013@2526-45810-a.local	Cristina Azcue Aseguinolaza	student	t	2025-11-18 23:18:21.545234+00	73040721
58	student057@2526-45810-a.local	Pablo Palma Pérez	student	t	2025-11-18 23:18:21.545234+00	51484099
36	student035@2526-45810-a.local	Julio Peral Renedo	student	t	2025-11-18 23:18:21.545234+00	06021048
56	student055@2526-45810-a.local	Pablo Morenilla López	student	t	2025-11-18 23:18:21.545234+00	51818627
10	student009@2526-45810-a.local	Andrés Lucas Núñez	student	t	2025-11-18 23:18:21.545234+00	47583769
59	student058@2526-45810-a.local	Pablo de Santos Burgueño	student	t	2025-11-18 23:18:21.545234+00	54210699
2	student001@2526-45810-a.local	Adriana Alexandra Soria Aranguren	student	t	2025-11-18 23:18:21.545234+00	Z2102203
60	student059@2526-45810-a.local	Paula Esnarrizaga Rodríguez	student	t	2025-11-18 23:18:21.545234+00	54191100
48	student047@2526-45810-a.local	Marlon Sieira Martínez	student	t	2025-11-18 23:18:21.545234+00	50491223
8	student007@2526-45810-a.local	Ana Zitao Pérez Martínez	power_student	t	2025-11-18 23:18:21.545234+00	47315562
11	student010@2526-45810-a.local	Beltrán García Enamorado	power_student	t	2025-11-18 23:18:21.545234+00	50347682
12	student011@2526-45810-a.local	Bilin Weng Chen	power_student	t	2025-11-18 23:18:21.545234+00	79406939
17	student016@2526-45810-a.local	Diego Sánchez Núñez	power_student	t	2025-11-18 23:18:21.545234+00	02595244
19	student018@2526-45810-a.local	Erik Wolfang Moericke Serrano	power_student	t	2025-11-18 23:18:21.545234+00	06001051
26	student025@2526-45810-a.local	Isabella Rivera Alderete	power_student	t	2025-11-18 23:18:21.545234+00	N11897829
31	student030@2526-45810-a.local	Javier Molinuevo Quevedo	power_student	t	2025-11-18 23:18:21.545234+00	70426250
33	student032@2526-45810-a.local	Jorge Asenjo Martín	power_student	t	2025-11-18 23:18:21.545234+00	53846543
37	student036@2526-45810-a.local	Julián Nicolás Moldovan Irimie	power_student	t	2025-11-18 23:18:21.545234+00	60129522
38	student037@2526-45810-a.local	Laura Chun Nombela Terrado	power_student	t	2025-11-18 23:18:21.545234+00	51494038
39	student038@2526-45810-a.local	Laura Jiménez Jiménez	power_student	t	2025-11-18 23:18:21.545234+00	54495191
40	student039@2526-45810-a.local	Laura Reyero González-Noriega	power_student	t	2025-11-18 23:18:21.545234+00	53989108
41	student040@2526-45810-a.local	Laura Yebra de Llano	power_student	t	2025-11-18 23:18:21.545234+00	49333504
42	student041@2526-45810-a.local	Lucas Román Vidal	power_student	t	2025-11-18 23:18:21.545234+00	51536693
51	student050@2526-45810-a.local	María Lilia Riancho Pena	power_student	t	2025-11-18 23:18:21.545234+00	54440992
57	student056@2526-45810-a.local	Pablo Moreno Rivas	power_student	t	2025-11-18 23:18:21.545234+00	54022654
66	student065@2526-45810-a.local	Sofía Mazón Caballero	power_student	t	2025-11-18 23:18:21.545234+00	02569318
67	student066@2526-45810-a.local	Tomás Cavassa Aparicio	power_student	t	2025-11-18 23:18:21.545234+00	Y8840042
62	student061@2526-45810-a.local	Raúl Soligo Sierra	student	t	2025-11-18 23:18:21.545234+00	51708892
34	student033@2526-45810-a.local	Juan Gutiérrez García	student	t	2025-11-18 23:18:21.545234+00	02316928
68	student067@2526-45810-a.local	Tomás Herrera Londoño	student	t	2025-11-18 23:18:21.545234+00	43924576
54	student053@2526-45810-a.local	Olivia Bidmead Serrano	student	t	2025-11-18 23:18:21.545234+00	70429033
44	student043@2526-45810-a.local	Marcos Cruces García	student	t	2025-11-18 23:18:21.545234+00	70069968
30	student029@2526-45810-a.local	Javier Fernández Cuesta	power_student	t	2025-11-18 23:18:21.545234+00	54298243
65	student064@2526-45810-a.local	Sofía González Hernández	power_student	t	2025-11-18 23:18:21.545234+00	49155842
69	student068@2526-45810-a.local	Xavier Alcocer Soberani	power_student	t	2025-11-18 23:18:21.545234+00	60344836
\.


--
-- Data for Name: course; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.course (id, code, name, description, owner_id, academic_year, class_group, is_active, created_at) FROM stdin;
3	2526-ANBA-3-5354-A	Big Data III: Visualization	Curso de visualización, grupo A inglés	\N	2526	A	t	2025-12-13 17:58:49.153507+00
1	2526-45810-A	Google Cloud Digital Leader	Curso GCDL 2526, grupo A inglés	1	2526	A	t	2025-11-18 23:18:21.542375+00
\.


--
-- Data for Name: course_enrollment; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.course_enrollment (id, course_id, user_id, role_in_course, enrolled_at) FROM stdin;
1	1	1	teacher	2025-11-18 23:18:21.545234+00
\.


--
-- Data for Name: question_bank; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.question_bank (id, course_id, question_text, question_type, default_points, is_active, created_by, created_at) FROM stdin;
106	1	1. A financial services organization has bank branches in a number of countries, and has built an application that needs to run in different configurations based on the local regulations of each country. How can cloud infrastructure help achieve this goal?	single_choice	1.00	t	1	2025-11-20 23:23:53.501536+00
107	1	2. An organization has shifted from a CapEx to OpEx based spending model. Which of these statements is true?	single_choice	1.00	t	1	2025-11-20 23:23:53.501536+00
108	1	3. An organization wants to ensure they have redundancy of their resources so their application remains available in the event of a disaster. How can they ensure this happens?	single_choice	1.00	t	1	2025-11-20 23:23:53.501536+00
109	1	4. In the cloud computing shared responsibility model, what types of content are customers always responsible for, regardless of the computing model chosen?	single_choice	1.00	t	1	2025-11-20 23:23:53.501536+00
110	1	5. Which option best describes a benefit of Infrastructure as a Service (IaaS)?	single_choice	1.00	t	1	2025-11-20 23:23:53.501536+00
111	1	6. Which cloud computing service model offers a develop-and-deploy environment to build cloud applications?	single_choice	1.00	t	1	2025-11-20 23:23:53.501536+00
112	1	7. An organization wants to move to cloud-based collaboration software, but due to limited IT staff one of their main drivers is having low maintenance needs. Which cloud computing model would best suit their requirements?	single_choice	1.00	t	1	2025-11-20 23:23:53.501536+00
113	1	8. Google applies generative AI to products like Google Workspace, but what is generative AI?	single_choice	1.00	t	1	2025-11-20 23:23:53.501536+00
114	1	9. Which use case demonstrates ML’s ability to process natural language?	single_choice	1.00	t	1	2025-11-20 23:23:53.501536+00
115	1	10. What does the consistency dimension refer to when data quality is being measured?	single_choice	1.00	t	1	2025-11-20 23:23:53.501536+00
116	1	11. You’re watching a video on YouTube and are shown a list of videos that YouTube thinks you are interested in. What ML solution powers this feature?	single_choice	1.00	t	1	2025-11-20 23:23:53.501536+00
117	1	12. Google's AI principles are a set of guiding values that help develop and use artificial intelligence responsibly. Which of these is one of Google’s AI principles?	single_choice	1.00	t	1	2025-11-20 23:23:53.501536+00
118	1	13. Which option refers to the use of technologies to build machines and computers that can mimic cognitive functions associated with human intelligence?	single_choice	1.00	t	1	2025-11-20 23:23:53.501536+00
119	1	14. Artificial intelligence is best suited for replacing or simplifying rule-based systems. Which is an example of this in action?	single_choice	1.00	t	1	2025-11-20 23:23:53.501536+00
120	1	15. How do data analytics and business intelligence differ from AI and ML?	single_choice	1.00	t	1	2025-11-20 23:23:53.501536+00
121	1	16. An online retailer wants to help users find specific products faster on their website. One idea is to allow shoppers to upload an image of the product they’re looking to purchase. Which of Google’s pre-trained APIs could the retailer use to expand this functionality?	single_choice	1.00	t	1	2025-11-20 23:23:53.501536+00
122	1	17. Which Google Cloud AI solution is designed to help businesses automate document processing?	single_choice	1.00	t	1	2025-11-20 23:23:53.501536+00
123	1	18. Which Google Cloud AI solution is designed to help businesses improve their customer service?	single_choice	1.00	t	1	2025-11-20 23:23:53.501536+00
124	1	19. What’s the name of Google’s application-specific integrated circuit (ASIC) that is used to accelerate machine learning workloads?	single_choice	1.00	t	1	2025-11-20 23:23:53.501536+00
125	1	20. A large media company wants to improve how they moderate online content. Currently, they have a team of human moderators that review content for appropriateness, but are looking to leverage artificial intelligence to improve efficiency. Which of Google’s pre-trained APIs could they use to identify and remove inappropriate content from the media company's website and social media platforms.	single_choice	1.00	t	1	2025-11-20 23:23:53.501536+00
127	1	22. Google Cloud offers four options for building machine learning models. Which is best when a business wants to code their own machine learning environment, the training, and the deployment?	single_choice	1.00	t	1	2025-11-20 23:23:53.501536+00
128	1	23. Which feature of Vertex AI lets users build and train end-to-end machine learning models by using a GUI (graphical user interface), without writing a line of code. Custom training	single_choice	1.00	t	1	2025-11-20 23:23:53.501536+00
129	1	24. A manufacturing company is considering shifting their on-premises infrastructure to the cloud, but are concerned that access to their data and applications won’t be available when they need them. They want to ensure that if one data center goes down, another will be available to prevent any disruption of service. What does this refer to?	single_choice	1.00	t	1	2025-11-20 23:23:53.501536+00
130	1	25. What computing option automatically provisions resources, like compute power, in the background as needed?	single_choice	1.00	t	1	2025-11-20 23:23:53.501536+00
131	1	26. What portion of a machine does a container virtualize?	single_choice	1.00	t	1	2025-11-20 23:23:53.501536+00
132	1	27. What phrase refers to when a workload is rehosted without changing anything in the workload's code or architecture.	single_choice	1.00	t	1	2025-11-20 23:23:53.501536+00
133	1	28. What term is commonly used to describe a rehost migration strategy for an organization that runs specialized legacy applications that aren’t compatible with cloud-native applications?	single_choice	1.00	t	1	2025-11-20 23:23:53.501536+00
134	1	29. What term describes a set of instructions that lets different software programs communicate with each other?	single_choice	1.00	t	1	2025-11-20 23:23:53.501536+00
135	1	30. In modern cloud application development, what name is given to independently deployable, scalable, and maintainable components that can be used to build a wide range of applications?	single_choice	1.00	t	1	2025-11-20 23:23:53.501536+00
136	1	31. Which is a fully managed cloud infrastructure solution that lets organizations run their Oracle workloads on dedicated servers in the cloud?	single_choice	1.00	t	1	2025-11-20 23:23:53.501536+00
137	1	32. What name is given to an environment where an organization uses more than one public cloud provider as part of its architecture?	single_choice	1.00	t	1	2025-11-20 23:23:53.501536+00
138	1	33. What name is given to an environment that comprises some combination of on-premises or private cloud infrastructure and public cloud services?	single_choice	1.00	t	1	2025-11-20 23:23:53.501536+00
139	1	34. Which is the responsibility of the cloud provider in a cloud security model?	single_choice	1.00	t	1	2025-11-20 23:23:53.501536+00
140	1	35. Which is a benefit of cloud security over traditional on-premises security?	single_choice	1.00	t	1	2025-11-20 23:23:53.501536+00
141	1	36. Which three essential aspects of cloud security form the foundation of the CIA triad?	single_choice	1.00	t	1	2025-11-20 23:23:53.501536+00
142	1	37. Which definition best describes a firewall?	single_choice	1.00	t	1	2025-11-20 23:23:53.501536+00
143	1	38. Which security principle advocates granting users only the access they need to perform their job responsibilities?	single_choice	1.00	t	1	2025-11-20 23:23:53.501536+00
144	1	39. Which practice involves a combination of processes and technologies that help reduce the risk of data breaches, system outages, and other security incidents in the cloud?	single_choice	1.00	t	1	2025-11-20 23:23:53.501536+00
145	1	40. Which is a powerful encryption algorithm trusted by governments and businesses worldwide?	single_choice	1.00	t	1	2025-11-20 23:23:53.501536+00
146	1	41. Select the correct statement about Identity and Access Management (IAM). IAM is a system that detects and prevents malicious traffic from entering a cloud network.	single_choice	1.00	t	1	2025-11-20 23:23:53.501536+00
147	1	42. What metric does Google Cloud use to measure the efficiency of its data centers to achieve cost savings and a reduced carbon footprint?	single_choice	1.00	t	1	2025-11-20 23:23:53.501536+00
148	1	43. Google Cloud encrypts data at various states. Which state refers to when data is being actively processed by a computer?	single_choice	1.00	t	1	2025-11-20 23:23:53.501536+00
149	1	44. What security feature adds an extra layer of protection to cloud-based systems?	single_choice	1.00	t	1	2025-11-20 23:23:53.501536+00
150	1	45. Where can you find details about certifications and compliance standards met by Google Cloud?	single_choice	1.00	t	1	2025-11-20 23:23:53.501536+00
151	1	46. Which report provides a way for Google Cloud to share data about how the policies and actions of governments and corporations affect privacy, security, and access to information?	single_choice	1.00	t	1	2025-11-20 23:23:53.501536+00
152	1	47. Which is one of Google Cloud’s seven trust principles?	single_choice	1.00	t	1	2025-11-20 23:23:53.501536+00
153	1	48. Which term describes the concept that data is subject to the laws and regulations of the country where it resides?	single_choice	1.00	t	1	2025-11-20 23:23:53.501536+00
154	1	49. Which term describes a centralized hub within an organization composed of a partnership across finance, technology, and business functions?	single_choice	1.00	t	1	2025-11-20 23:23:53.501536+00
155	1	50. Which represents the lowest level in the Google Cloud resource hierarchy?	single_choice	1.00	t	1	2025-11-20 23:23:53.501536+00
156	1	51. Which offers a reactive method to help you track and understand what you’ve already spent on Google Cloud resources and provide ways to help optimize your costs?	single_choice	1.00	t	1	2025-11-20 23:23:53.501536+00
157	1	52. Why is it a benefit that the Google Cloud resource hierarchy follows inheritance and propagation rules?	single_choice	1.00	t	1	2025-11-20 23:23:53.501536+00
158	1	53. Which feature lets you set limits on the amount of resources that can be used by a project or user?	single_choice	1.00	t	1	2025-11-20 23:23:53.501536+00
159	1	54. Which feature lets you set alerts for when cloud costs exceed a certain limit?	single_choice	1.00	t	1	2025-11-20 23:23:53.501536+00
160	1	55. Whose job is to ensure the reliability, availability, and efficiency of software systems and services deployed in the cloud?	single_choice	1.00	t	1	2025-11-20 23:23:53.501536+00
161	1	56. What does the Cloud Profiler tool do?	single_choice	1.00	t	1	2025-11-20 23:23:53.501536+00
162	1	57. One of the four golden signals is latency. What does latency measure?	single_choice	1.00	t	1	2025-11-20 23:23:53.501536+00
163	1	58. How does replication help the design of resilient and fault-tolerant infrastructure and processes in a cloud environment?	single_choice	1.00	t	1	2025-11-20 23:23:53.501536+00
164	1	59. Which metric shows how well a system or service is performing?	single_choice	1.00	t	1	2025-11-20 23:23:53.501536+00
165	1	60. Which of these measures should be automated on a regular basis and stored in geographically separate locations to allow for rapid recovery from disasters or failures?	single_choice	1.00	t	1	2025-11-20 23:23:53.501536+00
166	1	61. Kaluza is an electric vehicle smart-charging solution. How does it use BigQuery and Looker Studio?	single_choice	1.00	t	1	2025-11-20 23:23:53.501536+00
167	1	62. What sustainability goal does Google aim to achieve by the year 2030?	single_choice	1.00	t	1	2025-11-20 23:23:53.501536+00
168	1	63. Google's data centers were the first to achieve ISO 14001 certification. What is this standard’s purpose?	single_choice	1.00	t	1	2025-11-20 23:23:53.501536+00
169	1	64. An organization has a new application, and user subscriptions are growing faster than on-premises infrastructure can handle. What benefit of the cloud might help them in this situation?	single_choice	1.00	t	1	2025-11-20 23:23:53.501536+00
170	1	65. An organization has made significant investments in their own infrastructure and has regulatory requirements for their data to be hosted on-premises. Which cloud implementation would best suit their needs?	single_choice	1.00	t	1	2025-11-20 23:23:53.501536+00
171	1	66. What is the benefit of implementing a transformation cloud that is based on open infrastructure?	single_choice	1.00	t	1	2025-11-20 23:23:53.501536+00
172	1	67. Select the two capabilities that form the basis of a transformation cloud? Select two correct answers.	multiple_choice	1.00	t	1	2025-11-20 23:23:53.501536+00
173	1	68. As the world and business changes, organizations have to decide between embracing new technology and transforming, or keeping their technology and approaches the same. What risks might an organization face by not transforming as their market evolves?	single_choice	1.00	t	1	2025-11-20 23:23:53.501536+00
174	1	69. What is seen as a limitation of on-premises infrastructure, when compared to cloud infrastructure?	single_choice	1.00	t	1	2025-11-20 23:23:53.501536+00
175	1	70. What is the cloud?	single_choice	1.00	t	1	2025-11-20 23:23:53.501536+00
176	1	71. Which item describes a goal of an organization seeking digital transformation?	single_choice	1.00	t	1	2025-11-20 23:23:53.501536+00
177	1	72. Select the definition of digital transformation.	single_choice	1.00	t	1	2025-11-20 23:23:53.501536+00
178	1	73. What is data governance?	single_choice	1.00	t	1	2025-11-20 23:23:53.501536+00
179	1	74. A car insurance company has a large database that stores customer details, including the vehicles they own and past claims. The structure of the database means that information is stored in tables, rows, and columns. What type of database is this?	single_choice	1.00	t	1	2025-11-20 23:23:53.501536+00
216	1	103. What is one way that organizations can create new revenue streams through APIs?	single_choice	1.00	t	1	2025-11-20 23:23:53.501536+00
180	1	75. A solar energy company wants to analyze weather data to better understand the seasonal impact on their business. On which platform could they find free-to-use weather datasets?	single_choice	1.00	t	1	2025-11-20 23:23:53.501536+00
181	1	76. Which data type is highly organized and well-defined?	single_choice	1.00	t	1	2025-11-20 23:23:53.501536+00
182	1	76. What is Google Cloud’s modern and serverless data warehousing solution?	single_choice	1.00	t	1	2025-11-20 23:23:53.501536+00
183	1	77. Which is a repository designed to ingest, store, explore, process, and analyze any type or volume of raw data, regardless of the source?	single_choice	1.00	t	1	2025-11-20 23:23:53.501536+00
184	1	78. An online retailer uses a smart analytics tool to ingest real-time customer behavior data to surface the best suggestions for particular users. How can machine learning guide this activity?	single_choice	1.00	t	1	2025-11-20 23:23:53.501536+00
185	1	79. Which step in the data value chain is where collected raw data is transformed into a form that’s ready to derive insights from?	single_choice	1.00	t	1	2025-11-20 23:23:53.501536+00
186	1	80. New cloud tools make it possible to harness the potential of unstructured data. Which of these use cases best demonstrates this?	single_choice	1.00	t	1	2025-11-20 23:23:53.501536+00
187	1	81. Which represents the proprietary customer datasets that a business collects from customer or audience transactions and interactions?	single_choice	1.00	t	1	2025-11-20 23:23:53.501536+00
188	1	82. Which characteristic is true for all Cloud Storage classes?	single_choice	1.00	t	1	2025-11-20 23:23:53.501536+00
189	1	83. What are the two services that BigQuery provides?	single_choice	1.00	t	1	2025-11-20 23:23:53.501536+00
190	1	84. Which Google Cloud product can be used to synchronize data across databases, storage systems, and applications?	single_choice	1.00	t	1	2025-11-20 23:23:53.501536+00
191	1	85. Which would be the best SQL-based storage option for a transactional workload that requires global scalability?	single_choice	1.00	t	1	2025-11-20 23:23:53.501536+00
192	1	85. What is Google Cloud’s distributed messaging service that can receive messages from various device streams such as gaming events, Internet of Things (IoT) devices, and application streams?	single_choice	1.00	t	1	2025-11-20 23:23:53.501536+00
193	1	86. Which strategy describes when databases are migrated from on-premises and private cloud environments to the same type of database hosted by a public cloud provider?	single_choice	1.00	t	1	2025-11-20 23:23:53.501536+00
194	1	86. What feature of Looker makes it easy to integrate into existing workflows and share with multiple teams at an organization?	single_choice	1.00	t	1	2025-11-20 23:23:53.501536+00
195	1	87. A data analyst for an online retailer must produce a sales report at the end of each quarter. Which Cloud Storage class should the retailer use for data accessed every 90 days?	single_choice	1.00	t	1	2025-11-20 23:23:53.501536+00
196	1	87. What Google Cloud business intelligence platform is designed to help individuals and teams analyze, visualize, and share data?	single_choice	1.00	t	1	2025-11-20 23:23:53.501536+00
197	1	88. Data in the form of video, pictures, and audio recordings is well suited to object storage. Which product is best for storing this kind of data?	single_choice	1.00	t	1	2025-11-20 23:23:53.501536+00
198	1	88. Streaming analytics is the processing and analyzing of data records continuously instead of in batches. Which option is a source of streaming data?	single_choice	1.00	t	1	2025-11-20 23:23:53.501536+00
199	1	89. What is Google's big data database service that powers many core Google services, including Google Search, Google Analytics, Google Maps Platform, and Gmail?	single_choice	1.00	t	1	2025-11-20 23:23:53.501536+00
200	1	89. What does ETL stand for in the context of data processing?	single_choice	1.00	t	1	2025-11-20 23:23:53.501536+00
201	1	90. Which is the best SQL-based storage option for a transactional workload that requires local or regional scalability?	single_choice	1.00	t	1	2025-11-20 23:23:53.501536+00
202	1	90. Which statement is true about Dataflow?	single_choice	1.00	t	1	2025-11-20 23:23:53.501536+00
203	1	91. BigQuery works in a multicloud environment. How do organizations benefit from this feature?	single_choice	1.00	t	1	2025-11-20 23:23:53.501536+00
204	1	91. What open source platform, originally developed by Google, manages containerized workloads and services?	single_choice	1.00	t	1	2025-11-20 23:23:53.501536+00
205	1	92. A travel company is in the early stages of developing a new application and wants to test it on a variety of configurations: different operating systems, processors, and storage options. What cloud computing option should they use?	single_choice	1.00	t	1	2025-11-20 23:23:53.501536+00
206	1	93. What portion of a machine does a container virtualize?	single_choice	1.00	t	1	2025-11-20 23:23:53.501536+00
207	1	94. A manufacturing company is considering shifting their on-premises infrastructure to the cloud, but are concerned that access to their data and applications won’t be available when they need them. They want to ensure that if one data center goes down, another will be available to prevent any disruption of service. What does this refer to?	single_choice	1.00	t	1	2025-11-20 23:23:53.501536+00
208	1	95. What computing option automatically provisions resources, like compute power, in the background as needed?	single_choice	1.00	t	1	2025-11-20 23:23:53.501536+00
209	1	96. In modern cloud application development, what name is given to independently deployable, scalable, and maintainable components that can be used to build a wide range of applications?	single_choice	1.00	t	1	2025-11-20 23:23:53.501536+00
210	1	97. What term describes a set of instructions that lets different software programs communicate with each other?	single_choice	1.00	t	1	2025-11-20 23:23:53.501536+00
211	1	98. What term is commonly used to describe a rehost migration strategy for an organization that runs specialized legacy applications that aren’t compatible with cloud-native applications?	single_choice	1.00	t	1	2025-11-20 23:23:53.501536+00
212	1	99. What name is given to an environment that comprises some combination of on-premises or private cloud infrastructure and public cloud services?	single_choice	1.00	t	1	2025-11-20 23:23:53.501536+00
213	1	100. Which is a fully managed cloud infrastructure solution that lets organizations run their Oracle workloads on dedicated servers in the cloud?	single_choice	1.00	t	1	2025-11-20 23:23:53.501536+00
214	1	101. In modern application development, which is responsible for the day-to-day management of cloud-based infrastructure, such as patching, upgrades, and monitoring?	single_choice	1.00	t	1	2025-11-20 23:23:53.501536+00
215	1	102. What’s the name of Google Cloud’s production-ready platform for running Kuberenetes applications across multiple cloud environments?	single_choice	1.00	t	1	2025-11-20 23:23:53.501536+00
217	1	104. What is the name of Google Cloud's API management service that can operate APIs with enhanced scale, security, and automation?	single_choice	1.00	t	1	2025-11-20 23:23:53.501536+00
218	1	105. What name is given to an environment where an organization uses more than one public cloud provider as part of its architecture?	single_choice	1.00	t	1	2025-11-20 23:23:53.501536+00
219	1	106. Which cybersecurity threat demands a ransom payment from a victim to regain access to their files and systems.	single_choice	0.50	t	\N	2025-12-11 13:19:25.029071+00
221	1	108. Which is a benefit of cloud security over traditional on-premises security?	single_choice	0.50	t	\N	2025-12-11 13:19:25.029071+00
222	1	109. Which is the responsibility of the cloud provider in a cloud security model?	single_choice	0.50	t	\N	2025-12-11 13:19:25.029071+00
223	1	110. Which cloud security principle ensures that security practices and measures align with established standards and guidelines?	single_choice	0.50	t	\N	2025-12-11 13:19:25.029071+00
224	1	111.  Which security principle advocates granting users only the access they need to perform their job responsibilities?	single_choice	0.50	t	\N	2025-12-11 13:19:25.029071+00
225	1	112. Which cybersecurity threat occurs when errors arise during the setup of resources, inadvertently exposing sensitive data and systems to unauthorized access?	single_choice	0.50	t	\N	2025-12-11 13:19:25.029071+00
226	1	113. What common cybersecurity threat involves tricking users into revealing sensitive information or performing actions that compromise security?	single_choice	0.50	t	\N	2025-12-11 13:19:25.029071+00
227	1	114. Which cloud security principle relates to keeping data accurate and trustworthy?	single_choice	0.50	t	\N	2025-12-11 13:19:25.029071+00
228	1	115. Which three essential aspects of cloud security form the foundation of the CIA triad?	single_choice	0.50	t	\N	2025-12-11 13:19:25.029071+00
229	1	116. \vWhich definition best describes a firewall?	single_choice	0.50	t	\N	2025-12-11 13:19:25.029071+00
231	1	118. What is Google Cloud’s distributed messaging service that can receive messages from various device streams such as gaming events, Internet of Things (IoT) devices, and application streams?	single_choice	0.50	t	\N	2025-12-11 13:19:25.029071+00
126	1	21. BigQuery ML is a machine learning service that lets users:	single_choice	1.00	t	1	2025-11-20 23:23:53.501536+00
220	1	107. Which is a benefit of cloud security over traditional on-premises security?	single_choice	0.50	t	\N	2025-12-11 13:19:25.029071+00
230	1	117. What is Google Cloud’s modern and serverless data warehousing solution?	single_choice	0.50	t	\N	2025-12-11 13:19:25.029071+00
1205	1	1. A financial services organization has bank branches in a number of countries, and has built an application that needs to run in different configurations based on the local regulations of each country. How can cloud infrastructure help achieve this goal?	single_choice	0.50	t	\N	2025-12-15 13:52:49.479952+00
1206	1	2. An organization has shifted from a CapEx to OpEx based spending model. Which of these statements is true?	single_choice	0.50	t	\N	2025-12-15 13:52:49.479952+00
1207	1	3. An organization wants to ensure they have redundancy of their resources so their application remains available in the event of a disaster. How can they ensure this happens?	single_choice	0.50	t	\N	2025-12-15 13:52:49.479952+00
1208	1	4. In the cloud computing shared responsibility model, what types of content are customers always responsible for, regardless of the computing model chosen?	single_choice	0.50	t	\N	2025-12-15 13:52:49.479952+00
1209	1	5. Which option best describes a benefit of Infrastructure as a Service (IaaS)?	single_choice	0.50	t	\N	2025-12-15 13:52:49.479952+00
1210	1	6. Which cloud computing service model offers a develop-and-deploy environment to build cloud applications?	single_choice	0.50	t	\N	2025-12-15 13:52:49.479952+00
1211	1	7. An organization wants to move to cloud-based collaboration software, but due to limited IT staff one of their main drivers is having low maintenance needs. Which cloud computing model would best suit their requirements?	single_choice	0.50	t	\N	2025-12-15 13:52:49.479952+00
1212	1	8. Google applies generative AI to products like Google Workspace, but what is generative AI?	single_choice	0.50	t	\N	2025-12-15 13:52:49.479952+00
1213	1	9. Which use case demonstrates ML’s ability to process natural language?	single_choice	0.50	t	\N	2025-12-15 13:52:49.479952+00
1214	1	10. What does the consistency dimension refer to when data quality is being measured?	single_choice	0.50	t	\N	2025-12-15 13:52:49.479952+00
1215	1	11. You’re watching a video on YouTube and are shown a list of videos that YouTube thinks you are interested in. What ML solution powers this feature?	single_choice	0.50	t	\N	2025-12-15 13:52:49.479952+00
1216	1	12. Google's AI principles are a set of guiding values that help develop and use artificial intelligence responsibly. Which of these is one of Google’s AI principles?	single_choice	0.50	t	\N	2025-12-15 13:52:49.479952+00
1217	1	13. Which option refers to the use of technologies to build machines and computers that can mimic cognitive functions associated with human intelligence?	single_choice	0.50	t	\N	2025-12-15 13:52:49.479952+00
1218	1	14. Artificial intelligence is best suited for replacing or simplifying rule-based systems. Which is an example of this in action?	single_choice	0.50	t	\N	2025-12-15 13:52:49.479952+00
1219	1	15. How do data analytics and business intelligence differ from AI and ML?	single_choice	0.50	t	\N	2025-12-15 13:52:49.479952+00
1220	1	16. An online retailer wants to help users find specific products faster on their website. One idea is to allow shoppers to upload an image of the product they’re looking to purchase. Which of Google’s pre-trained APIs could the retailer use to expand this functionality?	single_choice	0.50	t	\N	2025-12-15 13:52:49.479952+00
1221	1	17. Which Google Cloud AI solution is designed to help businesses automate document processing?	single_choice	0.50	t	\N	2025-12-15 13:52:49.479952+00
1222	1	18. Which Google Cloud AI solution is designed to help businesses improve their customer service?	single_choice	0.50	t	\N	2025-12-15 13:52:49.479952+00
1223	1	19. What’s the name of Google’s application-specific integrated circuit (ASIC) that is used to accelerate machine learning workloads?	single_choice	0.50	t	\N	2025-12-15 13:52:49.479952+00
1224	1	20. A large media company wants to improve how they moderate online content. Currently, they have a team of human moderators that review content for appropriateness, but are looking to leverage artificial intelligence to improve efficiency. Which of Google’s pre-trained APIs could they use to identify and remove inappropriate content from the media company's website and social media platforms.	single_choice	0.50	t	\N	2025-12-15 13:52:49.479952+00
1225	1	21. BigQuery ML is a machine learning service that lets users: Build and evaluate machine learning models in BigQuery by using Python and Java.	single_choice	0.50	t	\N	2025-12-15 13:52:49.479952+00
1226	1	22. Google Cloud offers four options for building machine learning models. Which is best when a business wants to code their own machine learning environment, the training, and the deployment?	single_choice	0.50	t	\N	2025-12-15 13:52:49.479952+00
1227	1	23. Which feature of Vertex AI lets users build and train end-to-end machine learning models by using a GUI (graphical user interface), without writing a line of code.	single_choice	0.50	t	\N	2025-12-15 13:52:49.479952+00
1228	1	24. A manufacturing company is considering shifting their on-premises infrastructure to the cloud, but are concerned that access to their data and applications won’t be available when they need them. They want to ensure that if one data center goes down, another will be available to prevent any disruption of service. What does this refer to?	single_choice	0.50	t	\N	2025-12-15 13:52:49.479952+00
1229	1	25. What computing option automatically provisions resources, like compute power, in the background as needed?	single_choice	0.50	t	\N	2025-12-15 13:52:49.479952+00
1230	1	26. What portion of a machine does a container virtualize?	single_choice	0.50	t	\N	2025-12-15 13:52:49.479952+00
1231	1	27. What phrase refers to when a workload is rehosted without changing anything in the workload's code or architecture.	single_choice	0.50	t	\N	2025-12-15 13:52:49.479952+00
1232	1	28. What term is commonly used to describe a rehost migration strategy for an organization that runs specialized legacy applications that aren’t compatible with cloud-native applications?	single_choice	0.50	t	\N	2025-12-15 13:52:49.479952+00
1233	1	29. What term describes a set of instructions that lets different software programs communicate with each other?	single_choice	0.50	t	\N	2025-12-15 13:52:49.479952+00
1234	1	30. In modern cloud application development, what name is given to independently deployable, scalable, and maintainable components that can be used to build a wide range of applications?	single_choice	0.50	t	\N	2025-12-15 13:52:49.479952+00
1235	1	31. Which is a fully managed cloud infrastructure solution that lets organizations run their Oracle workloads on dedicated servers in the cloud?	single_choice	0.50	t	\N	2025-12-15 13:52:49.479952+00
1236	1	32. What name is given to an environment where an organization uses more than one public cloud provider as part of its architecture?	single_choice	0.50	t	\N	2025-12-15 13:52:49.479952+00
1237	1	33. What name is given to an environment that comprises some combination of on-premises or private cloud infrastructure and public cloud services?	single_choice	0.50	t	\N	2025-12-15 13:52:49.479952+00
1238	1	34. Which is the responsibility of the cloud provider in a cloud security model?	single_choice	0.50	t	\N	2025-12-15 13:52:49.479952+00
1239	1	35. Which is a benefit of cloud security over traditional on-premises security?	single_choice	0.50	t	\N	2025-12-15 13:52:49.479952+00
1240	1	36. Which three essential aspects of cloud security form the foundation of the CIA triad?	single_choice	0.50	t	\N	2025-12-15 13:52:49.479952+00
1241	1	37. Which definition best describes a firewall?	single_choice	0.50	t	\N	2025-12-15 13:52:49.479952+00
1242	1	38. Which security principle advocates granting users only the access they need to perform their job responsibilities?	single_choice	0.50	t	\N	2025-12-15 13:52:49.479952+00
1243	1	39. Which practice involves a combination of processes and technologies that help reduce the risk of data breaches, system outages, and other security incidents in the cloud?	single_choice	0.50	t	\N	2025-12-15 13:52:49.479952+00
1244	1	40. Which is a powerful encryption algorithm trusted by governments and businesses worldwide?	single_choice	0.50	t	\N	2025-12-15 13:52:49.479952+00
1245	1	41. Select the correct statement about Identity and Access Management (IAM). IAM is a system that detects and prevents malicious traffic from entering a cloud network.	single_choice	0.50	t	\N	2025-12-15 13:52:49.479952+00
1246	1	42. What metric does Google Cloud use to measure the efficiency of its data centers to achieve cost savings and a reduced carbon footprint?	single_choice	0.50	t	\N	2025-12-15 13:52:49.479952+00
1247	1	43. Google Cloud encrypts data at various states. Which state refers to when data is being actively processed by a computer?	single_choice	0.50	t	\N	2025-12-15 13:52:49.479952+00
1248	1	44. What security feature adds an extra layer of protection to cloud-based systems?	single_choice	0.50	t	\N	2025-12-15 13:52:49.479952+00
1249	1	45. Where can you find details about certifications and compliance standards met by Google Cloud?	single_choice	0.50	t	\N	2025-12-15 13:52:49.479952+00
1250	1	46. Which report provides a way for Google Cloud to share data about how the policies and actions of governments and corporations affect privacy, security, and access to information?	single_choice	0.50	t	\N	2025-12-15 13:52:49.479952+00
1251	1	47. Which is one of Google Cloud’s seven trust principles?	single_choice	0.50	t	\N	2025-12-15 13:52:49.479952+00
1252	1	48. Which term describes the concept that data is subject to the laws and regulations of the country where it resides?	single_choice	0.50	t	\N	2025-12-15 13:52:49.479952+00
1253	1	49. Which term describes a centralized hub within an organization composed of a partnership across finance, technology, and business functions?	single_choice	0.50	t	\N	2025-12-15 13:52:49.479952+00
1254	1	50. Which represents the lowest level in the Google Cloud resource hierarchy?	single_choice	0.50	t	\N	2025-12-15 13:52:49.479952+00
1255	1	51. Which offers a reactive method to help you track and understand what you’ve already spent on Google Cloud resources and provide ways to help optimize your costs?	single_choice	0.50	t	\N	2025-12-15 13:52:49.479952+00
1256	1	52. Why is it a benefit that the Google Cloud resource hierarchy follows inheritance and propagation rules?	single_choice	0.50	t	\N	2025-12-15 13:52:49.479952+00
1257	1	53. Which feature lets you set limits on the amount of resources that can be used by a project or user?	single_choice	0.50	t	\N	2025-12-15 13:52:49.479952+00
1258	1	54. Which feature lets you set alerts for when cloud costs exceed a certain limit?	single_choice	0.50	t	\N	2025-12-15 13:52:49.479952+00
1259	1	55. Whose job is to ensure the reliability, availability, and efficiency of software systems and services deployed in the cloud?	single_choice	0.50	t	\N	2025-12-15 13:52:49.479952+00
1260	1	56. What does the Cloud Profiler tool do?	single_choice	0.50	t	\N	2025-12-15 13:52:49.479952+00
1261	1	57. One of the four golden signals is latency. What does latency measure?	single_choice	0.50	t	\N	2025-12-15 13:52:49.479952+00
1262	1	58. How does replication help the design of resilient and fault-tolerant infrastructure and processes in a cloud environment?	single_choice	0.50	t	\N	2025-12-15 13:52:49.479952+00
1263	1	59. Which metric shows how well a system or service is performing?	single_choice	0.50	t	\N	2025-12-15 13:52:49.479952+00
1264	1	60. Which of these measures should be automated on a regular basis and stored in geographically separate locations to allow for rapid recovery from disasters or failures?	single_choice	0.50	t	\N	2025-12-15 13:52:49.479952+00
1265	1	61. Kaluza is an electric vehicle smart-charging solution. How does it use BigQuery and Looker Studio?	single_choice	0.50	t	\N	2025-12-15 13:52:49.479952+00
1266	1	62. What sustainability goal does Google aim to achieve by the year 2030?	single_choice	0.50	t	\N	2025-12-15 13:52:49.479952+00
1267	1	63. Google's data centers were the first to achieve ISO 14001 certification. What is this standard’s purpose?	single_choice	0.50	t	\N	2025-12-15 13:52:49.479952+00
1268	1	64. An organization has a new application, and user subscriptions are growing faster than on-premises infrastructure can handle. What benefit of the cloud might help them in this situation?	single_choice	0.50	t	\N	2025-12-15 13:52:49.479952+00
1269	1	65. An organization has made significant investments in their own infrastructure and has regulatory requirements for their data to be hosted on-premises. Which cloud implementation would best suit their needs?	single_choice	0.50	t	\N	2025-12-15 13:52:49.479952+00
1270	1	66. What is the benefit of implementing a transformation cloud that is based on open infrastructure?	single_choice	0.50	t	\N	2025-12-15 13:52:49.479952+00
1271	1	67. Select the two capabilities that form the basis of a transformation cloud?	single_choice	0.50	t	\N	2025-12-15 13:52:49.479952+00
1272	1	68. As the world and business changes, organizations have to decide between embracing new technology and transforming, or keeping their technology and approaches the same. What risks might an organization face by not transforming as their market evolves?	single_choice	0.50	t	\N	2025-12-15 13:52:49.479952+00
1273	1	69. What is seen as a limitation of on-premises infrastructure, when compared to cloud infrastructure?	single_choice	0.50	t	\N	2025-12-15 13:52:49.479952+00
1274	1	70. What is the cloud?	single_choice	0.50	t	\N	2025-12-15 13:52:49.479952+00
1275	1	71. Which item describes a goal of an organization seeking digital transformation?	single_choice	0.50	t	\N	2025-12-15 13:52:49.479952+00
1276	1	72. Select the definition of digital transformation.	single_choice	0.50	t	\N	2025-12-15 13:52:49.479952+00
1277	1	73. What is data governance?	single_choice	0.50	t	\N	2025-12-15 13:52:49.479952+00
1278	1	74. A car insurance company has a large database that stores customer details, including the vehicles they own and past claims. The structure of the database means that information is stored in tables, rows, and columns. What type of database is this?	single_choice	0.50	t	\N	2025-12-15 13:52:49.479952+00
331	1	1. A financial services organization has bank branches in a number of countries, and has built an application that needs to run in different configurations based on the local regulations of each country. How can cloud infrastructure help achieve this goal?	single_choice	0.50	t	\N	2025-12-13 18:16:21.870208+00
332	1	2. An organization has shifted from a CapEx to OpEx based spending model. Which of these statements is true?	single_choice	0.50	t	\N	2025-12-13 18:16:21.870208+00
333	1	3. An organization wants to ensure they have redundancy of their resources so their application remains available in the event of a disaster. How can they ensure this happens?	single_choice	0.50	t	\N	2025-12-13 18:16:21.870208+00
334	1	4. In the cloud computing shared responsibility model, what types of content are customers always responsible for, regardless of the computing model chosen?	single_choice	0.50	t	\N	2025-12-13 18:16:21.870208+00
335	1	5. Which option best describes a benefit of Infrastructure as a Service (IaaS)?	single_choice	0.50	t	\N	2025-12-13 18:16:21.870208+00
336	1	6. Which cloud computing service model offers a develop-and-deploy environment to build cloud applications?	single_choice	0.50	t	\N	2025-12-13 18:16:21.870208+00
337	1	7. An organization wants to move to cloud-based collaboration software, but due to limited IT staff one of their main drivers is having low maintenance needs. Which cloud computing model would best suit their requirements?	single_choice	0.50	t	\N	2025-12-13 18:16:21.870208+00
338	1	8. Google applies generative AI to products like Google Workspace, but what is generative AI?	single_choice	0.50	t	\N	2025-12-13 18:16:21.870208+00
339	1	9. Which use case demonstrates ML’s ability to process natural language?	single_choice	0.50	t	\N	2025-12-13 18:16:21.870208+00
340	1	10. What does the consistency dimension refer to when data quality is being measured?	single_choice	0.50	t	\N	2025-12-13 18:16:21.870208+00
341	1	11. You’re watching a video on YouTube and are shown a list of videos that YouTube thinks you are interested in. What ML solution powers this feature?	single_choice	0.50	t	\N	2025-12-13 18:16:21.870208+00
342	1	12. Google's AI principles are a set of guiding values that help develop and use artificial intelligence responsibly. Which of these is one of Google’s AI principles?	single_choice	0.50	t	\N	2025-12-13 18:16:21.870208+00
343	1	13. Which option refers to the use of technologies to build machines and computers that can mimic cognitive functions associated with human intelligence?	single_choice	0.50	t	\N	2025-12-13 18:16:21.870208+00
344	1	14. Artificial intelligence is best suited for replacing or simplifying rule-based systems. Which is an example of this in action?	single_choice	0.50	t	\N	2025-12-13 18:16:21.870208+00
345	1	15. How do data analytics and business intelligence differ from AI and ML?	single_choice	0.50	t	\N	2025-12-13 18:16:21.870208+00
346	1	16. An online retailer wants to help users find specific products faster on their website. One idea is to allow shoppers to upload an image of the product they’re looking to purchase. Which of Google’s pre-trained APIs could the retailer use to expand this functionality?	single_choice	0.50	t	\N	2025-12-13 18:16:21.870208+00
347	1	17. Which Google Cloud AI solution is designed to help businesses automate document processing?	single_choice	0.50	t	\N	2025-12-13 18:16:21.870208+00
348	1	18. Which Google Cloud AI solution is designed to help businesses improve their customer service?	single_choice	0.50	t	\N	2025-12-13 18:16:21.870208+00
349	1	19. What’s the name of Google’s application-specific integrated circuit (ASIC) that is used to accelerate machine learning workloads?	single_choice	0.50	t	\N	2025-12-13 18:16:21.870208+00
350	1	20. A large media company wants to improve how they moderate online content. Currently, they have a team of human moderators that review content for appropriateness, but are looking to leverage artificial intelligence to improve efficiency. Which of Google’s pre-trained APIs could they use to identify and remove inappropriate content from the media company's website and social media platforms.	single_choice	0.50	t	\N	2025-12-13 18:16:21.870208+00
351	1	21. BigQuery ML is a machine learning service that lets users: Build and evaluate machine learning models in BigQuery by using Python and Java.	single_choice	0.50	t	\N	2025-12-13 18:16:21.870208+00
352	1	22. Google Cloud offers four options for building machine learning models. Which is best when a business wants to code their own machine learning environment, the training, and the deployment?	single_choice	0.50	t	\N	2025-12-13 18:16:21.870208+00
353	1	23. Which feature of Vertex AI lets users build and train end-to-end machine learning models by using a GUI (graphical user interface), without writing a line of code.	single_choice	0.50	t	\N	2025-12-13 18:16:21.870208+00
354	1	24. A manufacturing company is considering shifting their on-premises infrastructure to the cloud, but are concerned that access to their data and applications won’t be available when they need them. They want to ensure that if one data center goes down, another will be available to prevent any disruption of service. What does this refer to?	single_choice	0.50	t	\N	2025-12-13 18:16:21.870208+00
355	1	25. What computing option automatically provisions resources, like compute power, in the background as needed?	single_choice	0.50	t	\N	2025-12-13 18:16:21.870208+00
356	1	26. What portion of a machine does a container virtualize?	single_choice	0.50	t	\N	2025-12-13 18:16:21.870208+00
357	1	27. What phrase refers to when a workload is rehosted without changing anything in the workload's code or architecture.	single_choice	0.50	t	\N	2025-12-13 18:16:21.870208+00
358	1	28. What term is commonly used to describe a rehost migration strategy for an organization that runs specialized legacy applications that aren’t compatible with cloud-native applications?	single_choice	0.50	t	\N	2025-12-13 18:16:21.870208+00
359	1	29. What term describes a set of instructions that lets different software programs communicate with each other?	single_choice	0.50	t	\N	2025-12-13 18:16:21.870208+00
360	1	30. In modern cloud application development, what name is given to independently deployable, scalable, and maintainable components that can be used to build a wide range of applications?	single_choice	0.50	t	\N	2025-12-13 18:16:21.870208+00
361	1	31. Which is a fully managed cloud infrastructure solution that lets organizations run their Oracle workloads on dedicated servers in the cloud?	single_choice	0.50	t	\N	2025-12-13 18:16:21.870208+00
362	1	32. What name is given to an environment where an organization uses more than one public cloud provider as part of its architecture?	single_choice	0.50	t	\N	2025-12-13 18:16:21.870208+00
363	1	33. What name is given to an environment that comprises some combination of on-premises or private cloud infrastructure and public cloud services?	single_choice	0.50	t	\N	2025-12-13 18:16:21.870208+00
364	1	34. Which is the responsibility of the cloud provider in a cloud security model?	single_choice	0.50	t	\N	2025-12-13 18:16:21.870208+00
365	1	35. Which is a benefit of cloud security over traditional on-premises security?	single_choice	0.50	t	\N	2025-12-13 18:16:21.870208+00
366	1	36. Which three essential aspects of cloud security form the foundation of the CIA triad?	single_choice	0.50	t	\N	2025-12-13 18:16:21.870208+00
367	1	37. Which definition best describes a firewall?	single_choice	0.50	t	\N	2025-12-13 18:16:21.870208+00
368	1	38. Which security principle advocates granting users only the access they need to perform their job responsibilities?	single_choice	0.50	t	\N	2025-12-13 18:16:21.870208+00
369	1	39. Which practice involves a combination of processes and technologies that help reduce the risk of data breaches, system outages, and other security incidents in the cloud?	single_choice	0.50	t	\N	2025-12-13 18:16:21.870208+00
370	1	40. Which is a powerful encryption algorithm trusted by governments and businesses worldwide?	single_choice	0.50	t	\N	2025-12-13 18:16:21.870208+00
371	1	41. Select the correct statement about Identity and Access Management (IAM). IAM is a system that detects and prevents malicious traffic from entering a cloud network.	single_choice	0.50	t	\N	2025-12-13 18:16:21.870208+00
372	1	42. What metric does Google Cloud use to measure the efficiency of its data centers to achieve cost savings and a reduced carbon footprint?	single_choice	0.50	t	\N	2025-12-13 18:16:21.870208+00
373	1	43. Google Cloud encrypts data at various states. Which state refers to when data is being actively processed by a computer?	single_choice	0.50	t	\N	2025-12-13 18:16:21.870208+00
374	1	44. What security feature adds an extra layer of protection to cloud-based systems?	single_choice	0.50	t	\N	2025-12-13 18:16:21.870208+00
375	1	45. Where can you find details about certifications and compliance standards met by Google Cloud?	single_choice	0.50	t	\N	2025-12-13 18:16:21.870208+00
376	1	46. Which report provides a way for Google Cloud to share data about how the policies and actions of governments and corporations affect privacy, security, and access to information?	single_choice	0.50	t	\N	2025-12-13 18:16:21.870208+00
377	1	47. Which is one of Google Cloud’s seven trust principles?	single_choice	0.50	t	\N	2025-12-13 18:16:21.870208+00
378	1	48. Which term describes the concept that data is subject to the laws and regulations of the country where it resides?	single_choice	0.50	t	\N	2025-12-13 18:16:21.870208+00
379	1	49. Which term describes a centralized hub within an organization composed of a partnership across finance, technology, and business functions?	single_choice	0.50	t	\N	2025-12-13 18:16:21.870208+00
380	1	50. Which represents the lowest level in the Google Cloud resource hierarchy?	single_choice	0.50	t	\N	2025-12-13 18:16:21.870208+00
381	1	51. Which offers a reactive method to help you track and understand what you’ve already spent on Google Cloud resources and provide ways to help optimize your costs?	single_choice	0.50	t	\N	2025-12-13 18:16:21.870208+00
382	1	52. Why is it a benefit that the Google Cloud resource hierarchy follows inheritance and propagation rules?	single_choice	0.50	t	\N	2025-12-13 18:16:21.870208+00
383	1	53. Which feature lets you set limits on the amount of resources that can be used by a project or user?	single_choice	0.50	t	\N	2025-12-13 18:16:21.870208+00
384	1	54. Which feature lets you set alerts for when cloud costs exceed a certain limit?	single_choice	0.50	t	\N	2025-12-13 18:16:21.870208+00
385	1	55. Whose job is to ensure the reliability, availability, and efficiency of software systems and services deployed in the cloud?	single_choice	0.50	t	\N	2025-12-13 18:16:21.870208+00
386	1	56. What does the Cloud Profiler tool do?	single_choice	0.50	t	\N	2025-12-13 18:16:21.870208+00
387	1	57. One of the four golden signals is latency. What does latency measure?	single_choice	0.50	t	\N	2025-12-13 18:16:21.870208+00
388	1	58. How does replication help the design of resilient and fault-tolerant infrastructure and processes in a cloud environment?	single_choice	0.50	t	\N	2025-12-13 18:16:21.870208+00
389	1	59. Which metric shows how well a system or service is performing?	single_choice	0.50	t	\N	2025-12-13 18:16:21.870208+00
390	1	60. Which of these measures should be automated on a regular basis and stored in geographically separate locations to allow for rapid recovery from disasters or failures?	single_choice	0.50	t	\N	2025-12-13 18:16:21.870208+00
391	1	61. Kaluza is an electric vehicle smart-charging solution. How does it use BigQuery and Looker Studio?	single_choice	0.50	t	\N	2025-12-13 18:16:21.870208+00
392	1	62. What sustainability goal does Google aim to achieve by the year 2030?	single_choice	0.50	t	\N	2025-12-13 18:16:21.870208+00
393	1	63. Google's data centers were the first to achieve ISO 14001 certification. What is this standard’s purpose?	single_choice	0.50	t	\N	2025-12-13 18:16:21.870208+00
394	1	64. An organization has a new application, and user subscriptions are growing faster than on-premises infrastructure can handle. What benefit of the cloud might help them in this situation?	single_choice	0.50	t	\N	2025-12-13 18:16:21.870208+00
395	1	65. An organization has made significant investments in their own infrastructure and has regulatory requirements for their data to be hosted on-premises. Which cloud implementation would best suit their needs?	single_choice	0.50	t	\N	2025-12-13 18:16:21.870208+00
396	1	66. What is the benefit of implementing a transformation cloud that is based on open infrastructure?	single_choice	0.50	t	\N	2025-12-13 18:16:21.870208+00
397	1	67. Select the two capabilities that form the basis of a transformation cloud?	single_choice	0.50	t	\N	2025-12-13 18:16:21.870208+00
398	1	68. As the world and business changes, organizations have to decide between embracing new technology and transforming, or keeping their technology and approaches the same. What risks might an organization face by not transforming as their market evolves?	single_choice	0.50	t	\N	2025-12-13 18:16:21.870208+00
399	1	69. What is seen as a limitation of on-premises infrastructure, when compared to cloud infrastructure?	single_choice	0.50	t	\N	2025-12-13 18:16:21.870208+00
400	1	70. What is the cloud?	single_choice	0.50	t	\N	2025-12-13 18:16:21.870208+00
401	1	71. Which item describes a goal of an organization seeking digital transformation?	single_choice	0.50	t	\N	2025-12-13 18:16:21.870208+00
402	1	72. Select the definition of digital transformation.	single_choice	0.50	t	\N	2025-12-13 18:16:21.870208+00
403	1	73. What is data governance?	single_choice	0.50	t	\N	2025-12-13 18:16:21.870208+00
404	1	74. A car insurance company has a large database that stores customer details, including the vehicles they own and past claims. The structure of the database means that information is stored in tables, rows, and columns. What type of database is this?	single_choice	0.50	t	\N	2025-12-13 18:16:21.870208+00
405	1	75. A solar energy company wants to analyze weather data to better understand the seasonal impact on their business. On which platform could they find free-to-use weather datasets?	single_choice	0.50	t	\N	2025-12-13 18:16:21.870208+00
406	1	76. Which data type is highly organized and well-defined?	single_choice	0.50	t	\N	2025-12-13 18:16:21.870208+00
407	1	77. Which is a repository designed to ingest, store, explore, process, and analyze any type or volume of raw data, regardless of the source?	single_choice	0.50	t	\N	2025-12-13 18:16:21.870208+00
408	1	78. An online retailer uses a smart analytics tool to ingest real-time customer behavior data to surface the best suggestions for particular users. How can machine learning guide this activity?	single_choice	0.50	t	\N	2025-12-13 18:16:21.870208+00
409	1	79. Which step in the data value chain is where collected raw data is transformed into a form that’s ready to derive insights from?	single_choice	0.50	t	\N	2025-12-13 18:16:21.870208+00
410	1	80. New cloud tools make it possible to harness the potential of unstructured data. Which of these use cases best demonstrates this?	single_choice	0.50	t	\N	2025-12-13 18:16:21.870208+00
411	1	81. Which represents the proprietary customer datasets that a business collects from customer or audience transactions and interactions?	single_choice	0.50	t	\N	2025-12-13 18:16:21.870208+00
412	1	82. Which characteristic is true for all Cloud Storage classes?	single_choice	0.50	t	\N	2025-12-13 18:16:21.870208+00
413	1	83. What are the two services that BigQuery provides?	single_choice	0.50	t	\N	2025-12-13 18:16:21.870208+00
414	1	84. Which Google Cloud product can be used to synchronize data across databases, storage systems, and applications?	single_choice	0.50	t	\N	2025-12-13 18:16:21.870208+00
415	1	85. Which would be the best SQL-based storage option for a transactional workload that requires global scalability?	single_choice	0.50	t	\N	2025-12-13 18:16:21.870208+00
416	1	86. Which strategy describes when databases are migrated from on-premises and private cloud environments to the same type of database hosted by a public cloud provider?	single_choice	0.50	t	\N	2025-12-13 18:16:21.870208+00
417	1	87. A data analyst for an online retailer must produce a sales report at the end of each quarter. Which Cloud Storage class should the retailer use for data accessed every 90 days?	single_choice	0.50	t	\N	2025-12-13 18:16:21.870208+00
418	1	88. Data in the form of video, pictures, and audio recordings is well suited to object storage. Which product is best for storing this kind of data?	single_choice	0.50	t	\N	2025-12-13 18:16:21.870208+00
419	1	89. What is Google's big data database service that powers many core Google services, including Google Search, Google Analytics, Google Maps Platform, and Gmail?	single_choice	0.50	t	\N	2025-12-13 18:16:21.870208+00
420	1	90. Which is the best SQL-based storage option for a transactional workload that requires local or regional scalability?	single_choice	0.50	t	\N	2025-12-13 18:16:21.870208+00
421	1	91. BigQuery works in a multicloud environment. How do organizations benefit from this feature?	single_choice	0.50	t	\N	2025-12-13 18:16:21.870208+00
422	1	86. What feature of Looker makes it easy to integrate into existing workflows and share with multiple teams at an organization?	single_choice	0.50	t	\N	2025-12-13 18:16:21.870208+00
423	1	87. What Google Cloud business intelligence platform is designed to help individuals and teams analyze, visualize, and share data?	single_choice	0.50	t	\N	2025-12-13 18:16:21.870208+00
424	1	88. Streaming analytics is the processing and analyzing of data records continuously instead of in batches. Which option is a source of streaming data?	single_choice	0.50	t	\N	2025-12-13 18:16:21.870208+00
425	1	89. What does ETL stand for in the context of data processing?	single_choice	0.50	t	\N	2025-12-13 18:16:21.870208+00
426	1	90. Which statement is true about Dataflow?	single_choice	0.50	t	\N	2025-12-13 18:16:21.870208+00
427	1	91. What open source platform, originally developed by Google, manages containerized workloads and services?	single_choice	0.50	t	\N	2025-12-13 18:16:21.870208+00
428	1	92. A travel company is in the early stages of developing a new application and wants to test it on a variety of configurations: different operating systems, processors, and storage options. What cloud computing option should they use?	single_choice	0.50	t	\N	2025-12-13 18:16:21.870208+00
429	1	93. What portion of a machine does a container virtualize?	single_choice	0.50	t	\N	2025-12-13 18:16:21.870208+00
430	1	94. A manufacturing company is considering shifting their on-premises infrastructure to the cloud, but are concerned that access to their data and applications won’t be available when they need them. They want to ensure that if one data center goes down, another will be available to prevent any disruption of service. What does this refer to?	single_choice	0.50	t	\N	2025-12-13 18:16:21.870208+00
431	1	95. What computing option automatically provisions resources, like compute power, in the background as needed?	single_choice	0.50	t	\N	2025-12-13 18:16:21.870208+00
432	1	96. In modern cloud application development, what name is given to independently deployable, scalable, and maintainable components that can be used to build a wide range of applications?	single_choice	0.50	t	\N	2025-12-13 18:16:21.870208+00
433	1	97. What term describes a set of instructions that lets different software programs communicate with each other?	single_choice	0.50	t	\N	2025-12-13 18:16:21.870208+00
434	1	98. What term is commonly used to describe a rehost migration strategy for an organization that runs specialized legacy applications that aren’t compatible with cloud-native applications?	single_choice	0.50	t	\N	2025-12-13 18:16:21.870208+00
435	1	99. What name is given to an environment that comprises some combination of on-premises or private cloud infrastructure and public cloud services?	single_choice	0.50	t	\N	2025-12-13 18:16:21.870208+00
436	1	100. Which is a fully managed cloud infrastructure solution that lets organizations run their Oracle workloads on dedicated servers in the cloud?	single_choice	0.50	t	\N	2025-12-13 18:16:21.870208+00
437	1	101. In modern application development, which is responsible for the day-to-day management of cloud-based infrastructure, such as patching, upgrades, and monitoring?	single_choice	0.50	t	\N	2025-12-13 18:16:21.870208+00
438	1	102. What’s the name of Google Cloud’s production-ready platform for running Kuberenetes applications across multiple cloud environments?	single_choice	0.50	t	\N	2025-12-13 18:16:21.870208+00
439	1	103. What is one way that organizations can create new revenue streams through APIs?	single_choice	0.50	t	\N	2025-12-13 18:16:21.870208+00
440	1	104. What is the name of Google Cloud's API management service that can operate APIs with enhanced scale, security, and automation?	single_choice	0.50	t	\N	2025-12-13 18:16:21.870208+00
441	1	105. What name is given to an environment where an organization uses more than one public cloud provider as part of its architecture?	single_choice	0.50	t	\N	2025-12-13 18:16:21.870208+00
442	1	106. Which cybersecurity threat demands a ransom payment from a victim to regain access to their files and systems.	single_choice	0.50	t	\N	2025-12-13 18:16:21.870208+00
443	1	107. Which is a benefit of cloud security over traditional on-premises security?\vcheck	single_choice	0.50	t	\N	2025-12-13 18:16:21.870208+00
444	1	108. Which is a benefit of cloud security over traditional on-premises security?	single_choice	0.50	t	\N	2025-12-13 18:16:21.870208+00
445	1	109. Which is the responsibility of the cloud provider in a cloud security model?	single_choice	0.50	t	\N	2025-12-13 18:16:21.870208+00
446	1	110. Which cloud security principle ensures that security practices and measures align with established standards and guidelines?	single_choice	0.50	t	\N	2025-12-13 18:16:21.870208+00
447	1	111.  Which security principle advocates granting users only the access they need to perform their job responsibilities?	single_choice	0.50	t	\N	2025-12-13 18:16:21.870208+00
448	1	112. Which cybersecurity threat occurs when errors arise during the setup of resources, inadvertently exposing sensitive data and systems to unauthorized access?	single_choice	0.50	t	\N	2025-12-13 18:16:21.870208+00
449	1	113. What common cybersecurity threat involves tricking users into revealing sensitive information or performing actions that compromise security?	single_choice	0.50	t	\N	2025-12-13 18:16:21.870208+00
450	1	114. Which cloud security principle relates to keeping data accurate and trustworthy?	single_choice	0.50	t	\N	2025-12-13 18:16:21.870208+00
451	1	115. Which three essential aspects of cloud security form the foundation of the CIA triad?	single_choice	0.50	t	\N	2025-12-13 18:16:21.870208+00
452	1	116. \vWhich definition best describes a firewall?	single_choice	0.50	t	\N	2025-12-13 18:16:21.870208+00
453	1	117. What is Google Cloud’s modern and serverless data warehousing solution?	single_choice	0.50	t	\N	2025-12-13 18:16:21.870208+00
454	1	118. What is Google Cloud’s distributed messaging service that can receive messages from various device streams such as gaming events, Internet of Things (IoT) devices, and application streams?	single_choice	0.50	t	\N	2025-12-13 18:16:21.870208+00
1279	1	75. A solar energy company wants to analyze weather data to better understand the seasonal impact on their business. On which platform could they find free-to-use weather datasets?	single_choice	0.50	t	\N	2025-12-15 13:52:49.479952+00
1280	1	76. Which data type is highly organized and well-defined?	single_choice	0.50	t	\N	2025-12-15 13:52:49.479952+00
1281	1	77. Which is a repository designed to ingest, store, explore, process, and analyze any type or volume of raw data, regardless of the source?	single_choice	0.50	t	\N	2025-12-15 13:52:49.479952+00
1282	1	78. An online retailer uses a smart analytics tool to ingest real-time customer behavior data to surface the best suggestions for particular users. How can machine learning guide this activity?	single_choice	0.50	t	\N	2025-12-15 13:52:49.479952+00
1283	1	79. Which step in the data value chain is where collected raw data is transformed into a form that’s ready to derive insights from?	single_choice	0.50	t	\N	2025-12-15 13:52:49.479952+00
1284	1	80. New cloud tools make it possible to harness the potential of unstructured data. Which of these use cases best demonstrates this?	single_choice	0.50	t	\N	2025-12-15 13:52:49.479952+00
1285	1	81. Which represents the proprietary customer datasets that a business collects from customer or audience transactions and interactions?	single_choice	0.50	t	\N	2025-12-15 13:52:49.479952+00
1286	1	82. Which characteristic is true for all Cloud Storage classes?	single_choice	0.50	t	\N	2025-12-15 13:52:49.479952+00
1287	1	83. What are the two services that BigQuery provides?	single_choice	0.50	t	\N	2025-12-15 13:52:49.479952+00
1288	1	84. Which Google Cloud product can be used to synchronize data across databases, storage systems, and applications?	single_choice	0.50	t	\N	2025-12-15 13:52:49.479952+00
1289	1	85. Which would be the best SQL-based storage option for a transactional workload that requires global scalability?	single_choice	0.50	t	\N	2025-12-15 13:52:49.479952+00
1290	1	86. Which strategy describes when databases are migrated from on-premises and private cloud environments to the same type of database hosted by a public cloud provider?	single_choice	0.50	t	\N	2025-12-15 13:52:49.479952+00
1291	1	87. A data analyst for an online retailer must produce a sales report at the end of each quarter. Which Cloud Storage class should the retailer use for data accessed every 90 days?	single_choice	0.50	t	\N	2025-12-15 13:52:49.479952+00
1292	1	88. Data in the form of video, pictures, and audio recordings is well suited to object storage. Which product is best for storing this kind of data?	single_choice	0.50	t	\N	2025-12-15 13:52:49.479952+00
1293	1	89. What is Google's big data database service that powers many core Google services, including Google Search, Google Analytics, Google Maps Platform, and Gmail?	single_choice	0.50	t	\N	2025-12-15 13:52:49.479952+00
1294	1	90. Which is the best SQL-based storage option for a transactional workload that requires local or regional scalability?	single_choice	0.50	t	\N	2025-12-15 13:52:49.479952+00
1295	1	91. BigQuery works in a multicloud environment. How do organizations benefit from this feature?	single_choice	0.50	t	\N	2025-12-15 13:52:49.479952+00
1296	1	86. What feature of Looker makes it easy to integrate into existing workflows and share with multiple teams at an organization?	single_choice	0.50	t	\N	2025-12-15 13:52:49.479952+00
1297	1	87. What Google Cloud business intelligence platform is designed to help individuals and teams analyze, visualize, and share data?	single_choice	0.50	t	\N	2025-12-15 13:52:49.479952+00
1298	1	88. Streaming analytics is the processing and analyzing of data records continuously instead of in batches. Which option is a source of streaming data?	single_choice	0.50	t	\N	2025-12-15 13:52:49.479952+00
1299	1	89. What does ETL stand for in the context of data processing?	single_choice	0.50	t	\N	2025-12-15 13:52:49.479952+00
1300	1	90. Which statement is true about Dataflow?	single_choice	0.50	t	\N	2025-12-15 13:52:49.479952+00
1301	1	91. What open source platform, originally developed by Google, manages containerized workloads and services?	single_choice	0.50	t	\N	2025-12-15 13:52:49.479952+00
1302	1	92. A travel company is in the early stages of developing a new application and wants to test it on a variety of configurations: different operating systems, processors, and storage options. What cloud computing option should they use?	single_choice	0.50	t	\N	2025-12-15 13:52:49.479952+00
1303	1	93. What portion of a machine does a container virtualize?	single_choice	0.50	t	\N	2025-12-15 13:52:49.479952+00
1304	1	94. A manufacturing company is considering shifting their on-premises infrastructure to the cloud, but are concerned that access to their data and applications won’t be available when they need them. They want to ensure that if one data center goes down, another will be available to prevent any disruption of service. What does this refer to?	single_choice	0.50	t	\N	2025-12-15 13:52:49.479952+00
1305	1	95. What computing option automatically provisions resources, like compute power, in the background as needed?	single_choice	0.50	t	\N	2025-12-15 13:52:49.479952+00
1306	1	96. In modern cloud application development, what name is given to independently deployable, scalable, and maintainable components that can be used to build a wide range of applications?	single_choice	0.50	t	\N	2025-12-15 13:52:49.479952+00
1307	1	97. What term describes a set of instructions that lets different software programs communicate with each other?	single_choice	0.50	t	\N	2025-12-15 13:52:49.479952+00
1308	1	98. What term is commonly used to describe a rehost migration strategy for an organization that runs specialized legacy applications that aren’t compatible with cloud-native applications?	single_choice	0.50	t	\N	2025-12-15 13:52:49.479952+00
1309	1	99. What name is given to an environment that comprises some combination of on-premises or private cloud infrastructure and public cloud services?	single_choice	0.50	t	\N	2025-12-15 13:52:49.479952+00
1310	1	100. Which is a fully managed cloud infrastructure solution that lets organizations run their Oracle workloads on dedicated servers in the cloud?	single_choice	0.50	t	\N	2025-12-15 13:52:49.479952+00
1311	1	101. In modern application development, which is responsible for the day-to-day management of cloud-based infrastructure, such as patching, upgrades, and monitoring?	single_choice	0.50	t	\N	2025-12-15 13:52:49.479952+00
1312	1	102. What’s the name of Google Cloud’s production-ready platform for running Kuberenetes applications across multiple cloud environments?	single_choice	0.50	t	\N	2025-12-15 13:52:49.479952+00
1313	1	103. What is one way that organizations can create new revenue streams through APIs?	single_choice	0.50	t	\N	2025-12-15 13:52:49.479952+00
1314	1	104. What is the name of Google Cloud's API management service that can operate APIs with enhanced scale, security, and automation?	single_choice	0.50	t	\N	2025-12-15 13:52:49.479952+00
1315	1	105. What name is given to an environment where an organization uses more than one public cloud provider as part of its architecture?	single_choice	0.50	t	\N	2025-12-15 13:52:49.479952+00
1316	1	106. Which cybersecurity threat demands a ransom payment from a victim to regain access to their files and systems.	single_choice	0.50	t	\N	2025-12-15 13:52:49.479952+00
1317	1	107. Which is a benefit of cloud security over traditional on-premises security?\vcheck	single_choice	0.50	t	\N	2025-12-15 13:52:49.479952+00
1318	1	108. Which is a benefit of cloud security over traditional on-premises security?	single_choice	0.50	t	\N	2025-12-15 13:52:49.479952+00
1319	1	109. Which is the responsibility of the cloud provider in a cloud security model?	single_choice	0.50	t	\N	2025-12-15 13:52:49.479952+00
1320	1	110. Which cloud security principle ensures that security practices and measures align with established standards and guidelines?	single_choice	0.50	t	\N	2025-12-15 13:52:49.479952+00
1321	1	111.  Which security principle advocates granting users only the access they need to perform their job responsibilities?	single_choice	0.50	t	\N	2025-12-15 13:52:49.479952+00
1322	1	112. Which cybersecurity threat occurs when errors arise during the setup of resources, inadvertently exposing sensitive data and systems to unauthorized access?	single_choice	0.50	t	\N	2025-12-15 13:52:49.479952+00
1323	1	113. What common cybersecurity threat involves tricking users into revealing sensitive information or performing actions that compromise security?	single_choice	0.50	t	\N	2025-12-15 13:52:49.479952+00
1324	1	114. Which cloud security principle relates to keeping data accurate and trustworthy?	single_choice	0.50	t	\N	2025-12-15 13:52:49.479952+00
1325	1	115. Which three essential aspects of cloud security form the foundation of the CIA triad?	single_choice	0.50	t	\N	2025-12-15 13:52:49.479952+00
1326	1	116. \vWhich definition best describes a firewall?	single_choice	0.50	t	\N	2025-12-15 13:52:49.479952+00
1327	1	117. What is Google Cloud’s modern and serverless data warehousing solution?	single_choice	0.50	t	\N	2025-12-15 13:52:49.479952+00
1328	1	118. What is Google Cloud’s distributed messaging service that can receive messages from various device streams such as gaming events, Internet of Things (IoT) devices, and application streams?	single_choice	0.50	t	\N	2025-12-15 13:52:49.479952+00
1329	3	What is the main purpose of a business data visualization?	single_choice	0.50	t	\N	2025-12-15 13:56:45.629974+00
1330	3	Which statement best defines a metric versus a KPI (key performance indicator)?	single_choice	0.50	t	\N	2025-12-15 13:56:45.629974+00
1331	3	What is the first question to ask before choosing a chart type?	single_choice	0.50	t	\N	2025-12-15 13:56:45.629974+00
1332	3	In storytelling with data, what does adding context mainly help with?	single_choice	0.50	t	\N	2025-12-15 13:56:45.629974+00
1333	3	Which is a common sign of 'chartjunk'?	single_choice	0.50	t	\N	2025-12-15 13:56:45.629974+00
1334	3	What does 'data-ink ratio' try to maximize?	single_choice	0.50	t	\N	2025-12-15 13:56:45.629974+00
1335	3	A 'vanity metric' is best described as a metric that:	single_choice	0.50	t	\N	2025-12-15 13:56:45.629974+00
1336	3	Which practice most improves interpretability of a chart for executives?	single_choice	0.50	t	\N	2025-12-15 13:56:45.629974+00
1337	3	What is the biggest risk of showing too many KPIs (key performance indicators) on one dashboard?	single_choice	0.50	t	\N	2025-12-15 13:56:45.629974+00
1338	3	Which is the best definition of a dashboard in business analytics?	single_choice	0.50	t	\N	2025-12-15 13:56:45.629974+00
1339	3	Preattentive processing mainly helps viewers to:	single_choice	0.50	t	\N	2025-12-15 13:56:45.629974+00
1340	3	Which visual encoding is generally most accurate for comparing values?	single_choice	0.50	t	\N	2025-12-15 13:56:45.629974+00
1341	3	Working memory (WM) limitations imply that dashboards should:	single_choice	0.50	t	\N	2025-12-15 13:56:45.629974+00
1342	3	Which type of cognitive load is caused by poor design choices like clutter and irrelevant decoration?	single_choice	0.50	t	\N	2025-12-15 13:56:45.629974+00
1343	3	Germane load is best described as:	single_choice	0.50	t	\N	2025-12-15 13:56:45.629974+00
1344	3	Change blindness refers to the difficulty of:	single_choice	0.50	t	\N	2025-12-15 13:56:45.629974+00
1345	3	Which eye-tracking measure is most directly linked to where attention is held longer?	single_choice	0.50	t	\N	2025-12-15 13:56:45.629974+00
1346	3	In visual perception, a saccade is:	single_choice	0.50	t	\N	2025-12-15 13:56:45.629974+00
1347	3	If users repeatedly miss an important KPI on a dashboard, a likely cause is:	single_choice	0.50	t	\N	2025-12-15 13:56:45.629974+00
1348	3	What is a practical benefit of using small multiples (facets)?	single_choice	0.50	t	\N	2025-12-15 13:56:45.629974+00
1349	3	Gestalt principle of proximity suggests that elements close together are perceived as:	single_choice	0.50	t	\N	2025-12-15 13:56:45.629974+00
1350	3	Gestalt principle of similarity suggests that elements with similar color or shape are perceived as:	single_choice	0.50	t	\N	2025-12-15 13:56:45.629974+00
1351	3	Gestalt principle of closure explains why people can recognize incomplete shapes as:	single_choice	0.50	t	\N	2025-12-15 13:56:45.629974+00
1352	3	Gestalt principle of continuity suggests viewers prefer interpretations that follow:	single_choice	0.50	t	\N	2025-12-15 13:56:45.629974+00
1353	3	Gestalt principle of figure-ground is most relevant to:	single_choice	0.50	t	\N	2025-12-15 13:56:45.629974+00
1354	3	Which design choice best supports Gestalt grouping by proximity?	single_choice	0.50	t	\N	2025-12-15 13:56:45.629974+00
1355	3	Which design choice best supports grouping by similarity?	single_choice	0.50	t	\N	2025-12-15 13:56:45.629974+00
1356	3	Common fate (a Gestalt-like cue) is most related to:	single_choice	0.50	t	\N	2025-12-15 13:56:45.629974+00
1357	3	Which is an example of using enclosure to create grouping?	single_choice	0.50	t	\N	2025-12-15 13:56:45.629974+00
1358	3	Which situation most risks a false grouping effect?	single_choice	0.50	t	\N	2025-12-15 13:56:45.629974+00
1359	3	A bar chart is best for:	single_choice	0.50	t	\N	2025-12-15 13:56:45.629974+00
1360	3	A line chart is best for:	single_choice	0.50	t	\N	2025-12-15 13:56:45.629974+00
1361	3	A scatter plot is best for:	single_choice	0.50	t	\N	2025-12-15 13:56:45.629974+00
1362	3	A histogram is primarily used to show:	single_choice	0.50	t	\N	2025-12-15 13:56:45.629974+00
1363	3	A box plot is most useful to compare:	single_choice	0.50	t	\N	2025-12-15 13:56:45.629974+00
1364	3	A violin plot adds which extra information compared to a box plot?	single_choice	0.50	t	\N	2025-12-15 13:56:45.629974+00
1365	3	A treemap is best suited to visualize:	single_choice	0.50	t	\N	2025-12-15 13:56:45.629974+00
1366	3	A heatmap is commonly used to show:	single_choice	0.50	t	\N	2025-12-15 13:56:45.629974+00
1367	3	When is a pie chart most appropriate?	single_choice	0.50	t	\N	2025-12-15 13:56:45.629974+00
1368	3	Which alternative often works better than a pie chart for comparing parts?	single_choice	0.50	t	\N	2025-12-15 13:56:45.629974+00
1369	3	A radar chart is commonly (but cautiously) used to:	single_choice	0.50	t	\N	2025-12-15 13:56:45.629974+00
1370	3	Parallel coordinates are best for:	single_choice	0.50	t	\N	2025-12-15 13:56:45.629974+00
1371	3	A dendrogram is used to visualize:	single_choice	0.50	t	\N	2025-12-15 13:56:45.629974+00
1372	3	Which plot best reveals outliers in a numeric variable by group?	single_choice	0.50	t	\N	2025-12-15 13:56:45.629974+00
1373	3	Overplotting happens most often when:	single_choice	0.50	t	\N	2025-12-15 13:56:45.629974+00
1374	3	A good strategy to reduce overplotting in large scatter plots is:	single_choice	0.50	t	\N	2025-12-15 13:56:45.629974+00
1375	3	A choropleth map is most appropriate when values are:	single_choice	0.50	t	\N	2025-12-15 13:56:45.629974+00
1376	3	Why can bubble charts be misleading for comparison?	single_choice	0.50	t	\N	2025-12-15 13:56:45.629974+00
1377	3	Which visualization is best for showing cumulative totals over time?	single_choice	0.50	t	\N	2025-12-15 13:56:45.629974+00
1378	3	In the Grammar of Graphics, 'aesthetics' refers to:	single_choice	0.50	t	\N	2025-12-15 13:56:45.629974+00
1379	3	In Grammar of Graphics, 'geoms' are best described as:	single_choice	0.50	t	\N	2025-12-15 13:56:45.629974+00
1380	3	In Grammar of Graphics, 'scales' are responsible for:	single_choice	0.50	t	\N	2025-12-15 13:56:45.629974+00
1381	3	In Grammar of Graphics, 'facets' enable:	single_choice	0.50	t	\N	2025-12-15 13:56:45.629974+00
1382	3	Which is an example of layering in a visualization?	single_choice	0.50	t	\N	2025-12-15 13:56:45.629974+00
1383	3	Which is NOT a typical component of a Grammar of Graphics view?	single_choice	0.50	t	\N	2025-12-15 13:56:45.629974+00
1384	3	What does a coordinate system change most directly?	single_choice	0.50	t	\N	2025-12-15 13:56:45.629974+00
1385	3	A key advantage of a grammar-based approach is that it:	single_choice	0.50	t	\N	2025-12-15 13:56:45.629974+00
1386	3	In ggplot-style thinking, mapping 'sales' to y-position is an example of:	single_choice	0.50	t	\N	2025-12-15 13:56:45.629974+00
1387	3	A common mistake when mixing multiple geoms is:	single_choice	0.50	t	\N	2025-12-15 13:56:45.629974+00
1388	3	Which variable type is best described as nominal?	single_choice	0.50	t	\N	2025-12-15 13:56:45.629974+00
1389	3	Which variable type is best described as ordinal?	single_choice	0.50	t	\N	2025-12-15 13:56:45.629974+00
1390	3	A truncated y-axis on a bar chart most commonly risks:	single_choice	0.50	t	\N	2025-12-15 13:56:45.629974+00
1391	3	Why is a zero baseline often recommended for bar charts?	single_choice	0.50	t	\N	2025-12-15 13:56:45.629974+00
1392	3	A log scale is most appropriate when:	single_choice	0.50	t	\N	2025-12-15 13:56:45.629974+00
1393	3	Dual y-axes are risky because they can:	single_choice	0.50	t	\N	2025-12-15 13:56:45.629974+00
1394	3	Which encoding is typically less precise for value comparison than position or length?	single_choice	0.50	t	\N	2025-12-15 13:56:45.629974+00
1395	3	If you want to compare two distributions across many groups, a strong option is:	single_choice	0.50	t	\N	2025-12-15 13:56:45.629974+00
1396	3	Which label practice most improves readability?	single_choice	0.50	t	\N	2025-12-15 13:56:45.629974+00
1397	3	Which is the best practice for ordering categories in a bar chart?	single_choice	0.50	t	\N	2025-12-15 13:56:45.629974+00
1398	3	A sequential color scale is best for:	single_choice	0.50	t	\N	2025-12-15 13:56:45.629974+00
1399	3	A diverging color scale is best for:	single_choice	0.50	t	\N	2025-12-15 13:56:45.629974+00
1400	3	A categorical palette is best for:	single_choice	0.50	t	\N	2025-12-15 13:56:45.629974+00
1401	3	Why should dashboards avoid relying on color alone to encode meaning?	single_choice	0.50	t	\N	2025-12-15 13:56:45.629974+00
1402	3	What is a strong use of annotation in business charts?	single_choice	0.50	t	\N	2025-12-15 13:56:45.629974+00
1403	3	Which approach usually reduces visual clutter the most?	single_choice	0.50	t	\N	2025-12-15 13:56:45.629974+00
1404	3	When labeling lines in a line chart, a best practice is to:	single_choice	0.50	t	\N	2025-12-15 13:56:45.629974+00
1405	3	What is a strong reason to use whitespace in dashboards?	single_choice	0.50	t	\N	2025-12-15 13:56:45.629974+00
1406	3	If two colors appear equally salient but mean different categories, what risk increases?	single_choice	0.50	t	\N	2025-12-15 13:56:45.629974+00
1407	3	Which is a good practice for legends?	single_choice	0.50	t	\N	2025-12-15 13:56:45.629974+00
1408	3	A leading indicator is best described as a measure that:	single_choice	0.50	t	\N	2025-12-15 13:56:45.629974+00
1409	3	A lagging indicator is best described as a measure that:	single_choice	0.50	t	\N	2025-12-15 13:56:45.629974+00
1410	3	Which pair is a good example of leading versus lagging indicators?	single_choice	0.50	t	\N	2025-12-15 13:56:45.629974+00
1411	3	A well-designed KPI (key performance indicator) should be:	single_choice	0.50	t	\N	2025-12-15 13:56:45.629974+00
1412	3	What is a key difference between real-time and static dashboards?	single_choice	0.50	t	\N	2025-12-15 13:56:45.629974+00
1413	3	Which use case most benefits from real-time dashboards?	single_choice	0.50	t	\N	2025-12-15 13:56:45.629974+00
1414	3	Visual hierarchy in dashboards primarily helps users to:	single_choice	0.50	t	\N	2025-12-15 13:56:45.629974+00
1415	3	Which is a strong guideline for KPI count per dashboard (typical executive view)?	single_choice	0.50	t	\N	2025-12-15 13:56:45.629974+00
1416	3	Which is the best example of adding context to a KPI?	single_choice	0.50	t	\N	2025-12-15 13:56:45.629974+00
1417	3	A KPI without a clear owner and action plan is often:	single_choice	0.50	t	\N	2025-12-15 13:56:45.629974+00
1418	3	Which is a common ethical risk in data visualization?	single_choice	0.50	t	\N	2025-12-15 13:56:45.629974+00
1419	3	Cherry-picking in visualization most closely means:	single_choice	0.50	t	\N	2025-12-15 13:56:45.629974+00
1420	3	What is a best practice to support trust and transparency?	single_choice	0.50	t	\N	2025-12-15 13:56:45.629974+00
1421	3	When visualizing uncertainty, a common approach is to use:	single_choice	0.50	t	\N	2025-12-15 13:56:45.629974+00
1422	3	In a user study of dashboard comprehension, a strong outcome measure is:	single_choice	0.50	t	\N	2025-12-15 13:56:45.629974+00
1423	3	Which approach best evaluates whether a redesign reduced extraneous load?	single_choice	0.50	t	\N	2025-12-15 13:56:45.629974+00
1424	3	Which is a common privacy concern in business dashboards?	single_choice	0.50	t	\N	2025-12-15 13:56:45.629974+00
1425	3	A key big data visualization principle is to:	single_choice	0.50	t	\N	2025-12-15 13:56:45.629974+00
1426	3	Which interaction best supports 'overview first, zoom and filter, then details'?	single_choice	0.50	t	\N	2025-12-15 13:56:45.629974+00
1427	3	Which is a valid reason to avoid a rainbow color map in analytic charts?	single_choice	0.50	t	\N	2025-12-15 13:56:45.629974+00
1428	3	Which is a strong reason to add reference lines (for example, targets)?	single_choice	0.50	t	\N	2025-12-15 13:56:45.629974+00
1429	3	Which chart best supports comparing composition over time with a few categories?	single_choice	0.50	t	\N	2025-12-15 13:56:45.629974+00
1430	3	What is the biggest downside of too many interactive controls on a dashboard?	single_choice	0.50	t	\N	2025-12-15 13:56:45.629974+00
1431	3	A good filter default state should usually be:	single_choice	0.50	t	\N	2025-12-15 13:56:45.629974+00
1432	3	What is the main benefit of using benchmarks in KPI charts?	single_choice	0.50	t	\N	2025-12-15 13:56:45.629974+00
1433	3	In visualization design, 'accuracy' most directly means:	single_choice	0.50	t	\N	2025-12-15 13:56:45.629974+00
1434	3	Which is a common pitfall when comparing two time series with different units?	single_choice	0.50	t	\N	2025-12-15 13:56:45.629974+00
1435	3	A useful technique for showing distribution and individual points together is:	single_choice	0.50	t	\N	2025-12-15 13:56:45.629974+00
1436	3	Which visual element most directly supports quick scanning in dashboards?	single_choice	0.50	t	\N	2025-12-15 13:56:45.629974+00
1437	3	What is the main benefit of using consistent scales across small multiples?	single_choice	0.50	t	\N	2025-12-15 13:56:45.629974+00
1438	3	If a dashboard is meant for daily operations, KPI update frequency should usually be:	single_choice	0.50	t	\N	2025-12-15 13:56:45.629974+00
1439	3	Which is the most reasonable goal of interaction in business dashboards?	single_choice	0.50	t	\N	2025-12-15 13:56:45.629974+00
1440	3	When a KPI is red, the best practice is to also provide:	single_choice	0.50	t	\N	2025-12-15 13:56:45.629974+00
1441	3	Which is a valid reason to use median instead of mean in a KPI summary?	single_choice	0.50	t	\N	2025-12-15 13:56:45.629974+00
1442	3	A KPI definition should clearly specify:	single_choice	0.50	t	\N	2025-12-15 13:56:45.629974+00
1443	3	Which choice best supports cross-dashboard consistency?	single_choice	0.50	t	\N	2025-12-15 13:56:45.629974+00
1444	3	A key reason to avoid misleading visualizations is that they can:	single_choice	0.50	t	\N	2025-12-15 13:56:45.629974+00
1445	3	In big data contexts, why is aggregation useful for visualization?	single_choice	0.50	t	\N	2025-12-15 13:56:45.629974+00
1446	3	Which approach is most appropriate for visualizing streaming data?	single_choice	0.50	t	\N	2025-12-15 13:56:45.629974+00
1447	3	What is the primary goal of visual analytics?	single_choice	0.50	t	\N	2025-12-15 13:56:45.629974+00
1448	1	1. A financial services organization has bank branches in a number of countries, and has built an application that needs to run in different configurations based on the local regulations of each country. How can cloud infrastructure help achieve this goal?	single_choice	0.50	t	\N	2025-12-15 13:59:48.153009+00
1449	1	2. An organization has shifted from a CapEx to OpEx based spending model. Which of these statements is true?	single_choice	0.50	t	\N	2025-12-15 13:59:48.153009+00
1450	1	3. An organization wants to ensure they have redundancy of their resources so their application remains available in the event of a disaster. How can they ensure this happens?	single_choice	0.50	t	\N	2025-12-15 13:59:48.153009+00
1451	1	4. In the cloud computing shared responsibility model, what types of content are customers always responsible for, regardless of the computing model chosen?	single_choice	0.50	t	\N	2025-12-15 13:59:48.153009+00
1452	1	5. Which option best describes a benefit of Infrastructure as a Service (IaaS)?	single_choice	0.50	t	\N	2025-12-15 13:59:48.153009+00
1453	1	6. Which cloud computing service model offers a develop-and-deploy environment to build cloud applications?	single_choice	0.50	t	\N	2025-12-15 13:59:48.153009+00
1454	1	7. An organization wants to move to cloud-based collaboration software, but due to limited IT staff one of their main drivers is having low maintenance needs. Which cloud computing model would best suit their requirements?	single_choice	0.50	t	\N	2025-12-15 13:59:48.153009+00
1455	1	8. Google applies generative AI to products like Google Workspace, but what is generative AI?	single_choice	0.50	t	\N	2025-12-15 13:59:48.153009+00
1456	1	9. Which use case demonstrates ML’s ability to process natural language?	single_choice	0.50	t	\N	2025-12-15 13:59:48.153009+00
1457	1	10. What does the consistency dimension refer to when data quality is being measured?	single_choice	0.50	t	\N	2025-12-15 13:59:48.153009+00
1458	1	11. You’re watching a video on YouTube and are shown a list of videos that YouTube thinks you are interested in. What ML solution powers this feature?	single_choice	0.50	t	\N	2025-12-15 13:59:48.153009+00
1459	1	12. Google's AI principles are a set of guiding values that help develop and use artificial intelligence responsibly. Which of these is one of Google’s AI principles?	single_choice	0.50	t	\N	2025-12-15 13:59:48.153009+00
1460	1	13. Which option refers to the use of technologies to build machines and computers that can mimic cognitive functions associated with human intelligence?	single_choice	0.50	t	\N	2025-12-15 13:59:48.153009+00
1461	1	14. Artificial intelligence is best suited for replacing or simplifying rule-based systems. Which is an example of this in action?	single_choice	0.50	t	\N	2025-12-15 13:59:48.153009+00
1462	1	15. How do data analytics and business intelligence differ from AI and ML?	single_choice	0.50	t	\N	2025-12-15 13:59:48.153009+00
1463	1	16. An online retailer wants to help users find specific products faster on their website. One idea is to allow shoppers to upload an image of the product they’re looking to purchase. Which of Google’s pre-trained APIs could the retailer use to expand this functionality?	single_choice	0.50	t	\N	2025-12-15 13:59:48.153009+00
1464	1	17. Which Google Cloud AI solution is designed to help businesses automate document processing?	single_choice	0.50	t	\N	2025-12-15 13:59:48.153009+00
1465	1	18. Which Google Cloud AI solution is designed to help businesses improve their customer service?	single_choice	0.50	t	\N	2025-12-15 13:59:48.153009+00
1466	1	19. What’s the name of Google’s application-specific integrated circuit (ASIC) that is used to accelerate machine learning workloads?	single_choice	0.50	t	\N	2025-12-15 13:59:48.153009+00
1467	1	20. A large media company wants to improve how they moderate online content. Currently, they have a team of human moderators that review content for appropriateness, but are looking to leverage artificial intelligence to improve efficiency. Which of Google’s pre-trained APIs could they use to identify and remove inappropriate content from the media company's website and social media platforms.	single_choice	0.50	t	\N	2025-12-15 13:59:48.153009+00
1468	1	21. BigQuery ML is a machine learning service that lets users: Build and evaluate machine learning models in BigQuery by using Python and Java.	single_choice	0.50	t	\N	2025-12-15 13:59:48.153009+00
1469	1	22. Google Cloud offers four options for building machine learning models. Which is best when a business wants to code their own machine learning environment, the training, and the deployment?	single_choice	0.50	t	\N	2025-12-15 13:59:48.153009+00
1470	1	23. Which feature of Vertex AI lets users build and train end-to-end machine learning models by using a GUI (graphical user interface), without writing a line of code.	single_choice	0.50	t	\N	2025-12-15 13:59:48.153009+00
1471	1	24. A manufacturing company is considering shifting their on-premises infrastructure to the cloud, but are concerned that access to their data and applications won’t be available when they need them. They want to ensure that if one data center goes down, another will be available to prevent any disruption of service. What does this refer to?	single_choice	0.50	t	\N	2025-12-15 13:59:48.153009+00
1472	1	25. What computing option automatically provisions resources, like compute power, in the background as needed?	single_choice	0.50	t	\N	2025-12-15 13:59:48.153009+00
1473	1	26. What portion of a machine does a container virtualize?	single_choice	0.50	t	\N	2025-12-15 13:59:48.153009+00
1474	1	27. What phrase refers to when a workload is rehosted without changing anything in the workload's code or architecture.	single_choice	0.50	t	\N	2025-12-15 13:59:48.153009+00
1475	1	28. What term is commonly used to describe a rehost migration strategy for an organization that runs specialized legacy applications that aren’t compatible with cloud-native applications?	single_choice	0.50	t	\N	2025-12-15 13:59:48.153009+00
1476	1	29. What term describes a set of instructions that lets different software programs communicate with each other?	single_choice	0.50	t	\N	2025-12-15 13:59:48.153009+00
1477	1	30. In modern cloud application development, what name is given to independently deployable, scalable, and maintainable components that can be used to build a wide range of applications?	single_choice	0.50	t	\N	2025-12-15 13:59:48.153009+00
1478	1	31. Which is a fully managed cloud infrastructure solution that lets organizations run their Oracle workloads on dedicated servers in the cloud?	single_choice	0.50	t	\N	2025-12-15 13:59:48.153009+00
1479	1	32. What name is given to an environment where an organization uses more than one public cloud provider as part of its architecture?	single_choice	0.50	t	\N	2025-12-15 13:59:48.153009+00
1480	1	33. What name is given to an environment that comprises some combination of on-premises or private cloud infrastructure and public cloud services?	single_choice	0.50	t	\N	2025-12-15 13:59:48.153009+00
1481	1	34. Which is the responsibility of the cloud provider in a cloud security model?	single_choice	0.50	t	\N	2025-12-15 13:59:48.153009+00
1482	1	35. Which is a benefit of cloud security over traditional on-premises security?	single_choice	0.50	t	\N	2025-12-15 13:59:48.153009+00
1483	1	36. Which three essential aspects of cloud security form the foundation of the CIA triad?	single_choice	0.50	t	\N	2025-12-15 13:59:48.153009+00
1484	1	37. Which definition best describes a firewall?	single_choice	0.50	t	\N	2025-12-15 13:59:48.153009+00
1485	1	38. Which security principle advocates granting users only the access they need to perform their job responsibilities?	single_choice	0.50	t	\N	2025-12-15 13:59:48.153009+00
1486	1	39. Which practice involves a combination of processes and technologies that help reduce the risk of data breaches, system outages, and other security incidents in the cloud?	single_choice	0.50	t	\N	2025-12-15 13:59:48.153009+00
1487	1	40. Which is a powerful encryption algorithm trusted by governments and businesses worldwide?	single_choice	0.50	t	\N	2025-12-15 13:59:48.153009+00
1488	1	41. Select the correct statement about Identity and Access Management (IAM). IAM is a system that detects and prevents malicious traffic from entering a cloud network.	single_choice	0.50	t	\N	2025-12-15 13:59:48.153009+00
1489	1	42. What metric does Google Cloud use to measure the efficiency of its data centers to achieve cost savings and a reduced carbon footprint?	single_choice	0.50	t	\N	2025-12-15 13:59:48.153009+00
1490	1	43. Google Cloud encrypts data at various states. Which state refers to when data is being actively processed by a computer?	single_choice	0.50	t	\N	2025-12-15 13:59:48.153009+00
1491	1	44. What security feature adds an extra layer of protection to cloud-based systems?	single_choice	0.50	t	\N	2025-12-15 13:59:48.153009+00
1492	1	45. Where can you find details about certifications and compliance standards met by Google Cloud?	single_choice	0.50	t	\N	2025-12-15 13:59:48.153009+00
1493	1	46. Which report provides a way for Google Cloud to share data about how the policies and actions of governments and corporations affect privacy, security, and access to information?	single_choice	0.50	t	\N	2025-12-15 13:59:48.153009+00
1494	1	47. Which is one of Google Cloud’s seven trust principles?	single_choice	0.50	t	\N	2025-12-15 13:59:48.153009+00
1495	1	48. Which term describes the concept that data is subject to the laws and regulations of the country where it resides?	single_choice	0.50	t	\N	2025-12-15 13:59:48.153009+00
1496	1	49. Which term describes a centralized hub within an organization composed of a partnership across finance, technology, and business functions?	single_choice	0.50	t	\N	2025-12-15 13:59:48.153009+00
1497	1	50. Which represents the lowest level in the Google Cloud resource hierarchy?	single_choice	0.50	t	\N	2025-12-15 13:59:48.153009+00
1498	1	51. Which offers a reactive method to help you track and understand what you’ve already spent on Google Cloud resources and provide ways to help optimize your costs?	single_choice	0.50	t	\N	2025-12-15 13:59:48.153009+00
1499	1	52. Why is it a benefit that the Google Cloud resource hierarchy follows inheritance and propagation rules?	single_choice	0.50	t	\N	2025-12-15 13:59:48.153009+00
1500	1	53. Which feature lets you set limits on the amount of resources that can be used by a project or user?	single_choice	0.50	t	\N	2025-12-15 13:59:48.153009+00
1501	1	54. Which feature lets you set alerts for when cloud costs exceed a certain limit?	single_choice	0.50	t	\N	2025-12-15 13:59:48.153009+00
1502	1	55. Whose job is to ensure the reliability, availability, and efficiency of software systems and services deployed in the cloud?	single_choice	0.50	t	\N	2025-12-15 13:59:48.153009+00
1503	1	56. What does the Cloud Profiler tool do?	single_choice	0.50	t	\N	2025-12-15 13:59:48.153009+00
1504	1	57. One of the four golden signals is latency. What does latency measure?	single_choice	0.50	t	\N	2025-12-15 13:59:48.153009+00
1505	1	58. How does replication help the design of resilient and fault-tolerant infrastructure and processes in a cloud environment?	single_choice	0.50	t	\N	2025-12-15 13:59:48.153009+00
1506	1	59. Which metric shows how well a system or service is performing?	single_choice	0.50	t	\N	2025-12-15 13:59:48.153009+00
1507	1	60. Which of these measures should be automated on a regular basis and stored in geographically separate locations to allow for rapid recovery from disasters or failures?	single_choice	0.50	t	\N	2025-12-15 13:59:48.153009+00
1508	1	61. Kaluza is an electric vehicle smart-charging solution. How does it use BigQuery and Looker Studio?	single_choice	0.50	t	\N	2025-12-15 13:59:48.153009+00
1509	1	62. What sustainability goal does Google aim to achieve by the year 2030?	single_choice	0.50	t	\N	2025-12-15 13:59:48.153009+00
1510	1	63. Google's data centers were the first to achieve ISO 14001 certification. What is this standard’s purpose?	single_choice	0.50	t	\N	2025-12-15 13:59:48.153009+00
1511	1	64. An organization has a new application, and user subscriptions are growing faster than on-premises infrastructure can handle. What benefit of the cloud might help them in this situation?	single_choice	0.50	t	\N	2025-12-15 13:59:48.153009+00
1512	1	65. An organization has made significant investments in their own infrastructure and has regulatory requirements for their data to be hosted on-premises. Which cloud implementation would best suit their needs?	single_choice	0.50	t	\N	2025-12-15 13:59:48.153009+00
1513	1	66. What is the benefit of implementing a transformation cloud that is based on open infrastructure?	single_choice	0.50	t	\N	2025-12-15 13:59:48.153009+00
1514	1	67. Select the two capabilities that form the basis of a transformation cloud?	single_choice	0.50	t	\N	2025-12-15 13:59:48.153009+00
1515	1	68. As the world and business changes, organizations have to decide between embracing new technology and transforming, or keeping their technology and approaches the same. What risks might an organization face by not transforming as their market evolves?	single_choice	0.50	t	\N	2025-12-15 13:59:48.153009+00
1516	1	69. What is seen as a limitation of on-premises infrastructure, when compared to cloud infrastructure?	single_choice	0.50	t	\N	2025-12-15 13:59:48.153009+00
1517	1	70. What is the cloud?	single_choice	0.50	t	\N	2025-12-15 13:59:48.153009+00
1518	1	71. Which item describes a goal of an organization seeking digital transformation?	single_choice	0.50	t	\N	2025-12-15 13:59:48.153009+00
1519	1	72. Select the definition of digital transformation.	single_choice	0.50	t	\N	2025-12-15 13:59:48.153009+00
1520	1	73. What is data governance?	single_choice	0.50	t	\N	2025-12-15 13:59:48.153009+00
1521	1	74. A car insurance company has a large database that stores customer details, including the vehicles they own and past claims. The structure of the database means that information is stored in tables, rows, and columns. What type of database is this?	single_choice	0.50	t	\N	2025-12-15 13:59:48.153009+00
1522	1	75. A solar energy company wants to analyze weather data to better understand the seasonal impact on their business. On which platform could they find free-to-use weather datasets?	single_choice	0.50	t	\N	2025-12-15 13:59:48.153009+00
1523	1	76. Which data type is highly organized and well-defined?	single_choice	0.50	t	\N	2025-12-15 13:59:48.153009+00
1524	1	77. Which is a repository designed to ingest, store, explore, process, and analyze any type or volume of raw data, regardless of the source?	single_choice	0.50	t	\N	2025-12-15 13:59:48.153009+00
1525	1	78. An online retailer uses a smart analytics tool to ingest real-time customer behavior data to surface the best suggestions for particular users. How can machine learning guide this activity?	single_choice	0.50	t	\N	2025-12-15 13:59:48.153009+00
1526	1	79. Which step in the data value chain is where collected raw data is transformed into a form that’s ready to derive insights from?	single_choice	0.50	t	\N	2025-12-15 13:59:48.153009+00
1527	1	80. New cloud tools make it possible to harness the potential of unstructured data. Which of these use cases best demonstrates this?	single_choice	0.50	t	\N	2025-12-15 13:59:48.153009+00
1528	1	81. Which represents the proprietary customer datasets that a business collects from customer or audience transactions and interactions?	single_choice	0.50	t	\N	2025-12-15 13:59:48.153009+00
1529	1	82. Which characteristic is true for all Cloud Storage classes?	single_choice	0.50	t	\N	2025-12-15 13:59:48.153009+00
1530	1	83. What are the two services that BigQuery provides?	single_choice	0.50	t	\N	2025-12-15 13:59:48.153009+00
1531	1	84. Which Google Cloud product can be used to synchronize data across databases, storage systems, and applications?	single_choice	0.50	t	\N	2025-12-15 13:59:48.153009+00
1532	1	85. Which would be the best SQL-based storage option for a transactional workload that requires global scalability?	single_choice	0.50	t	\N	2025-12-15 13:59:48.153009+00
1533	1	86. Which strategy describes when databases are migrated from on-premises and private cloud environments to the same type of database hosted by a public cloud provider?	single_choice	0.50	t	\N	2025-12-15 13:59:48.153009+00
1534	1	87. A data analyst for an online retailer must produce a sales report at the end of each quarter. Which Cloud Storage class should the retailer use for data accessed every 90 days?	single_choice	0.50	t	\N	2025-12-15 13:59:48.153009+00
1535	1	88. Data in the form of video, pictures, and audio recordings is well suited to object storage. Which product is best for storing this kind of data?	single_choice	0.50	t	\N	2025-12-15 13:59:48.153009+00
1536	1	89. What is Google's big data database service that powers many core Google services, including Google Search, Google Analytics, Google Maps Platform, and Gmail?	single_choice	0.50	t	\N	2025-12-15 13:59:48.153009+00
1537	1	90. Which is the best SQL-based storage option for a transactional workload that requires local or regional scalability?	single_choice	0.50	t	\N	2025-12-15 13:59:48.153009+00
1538	1	91. BigQuery works in a multicloud environment. How do organizations benefit from this feature?	single_choice	0.50	t	\N	2025-12-15 13:59:48.153009+00
1539	1	86. What feature of Looker makes it easy to integrate into existing workflows and share with multiple teams at an organization?	single_choice	0.50	t	\N	2025-12-15 13:59:48.153009+00
1540	1	87. What Google Cloud business intelligence platform is designed to help individuals and teams analyze, visualize, and share data?	single_choice	0.50	t	\N	2025-12-15 13:59:48.153009+00
1541	1	88. Streaming analytics is the processing and analyzing of data records continuously instead of in batches. Which option is a source of streaming data?	single_choice	0.50	t	\N	2025-12-15 13:59:48.153009+00
1542	1	89. What does ETL stand for in the context of data processing?	single_choice	0.50	t	\N	2025-12-15 13:59:48.153009+00
1543	1	90. Which statement is true about Dataflow?	single_choice	0.50	t	\N	2025-12-15 13:59:48.153009+00
1544	1	91. What open source platform, originally developed by Google, manages containerized workloads and services?	single_choice	0.50	t	\N	2025-12-15 13:59:48.153009+00
1545	1	92. A travel company is in the early stages of developing a new application and wants to test it on a variety of configurations: different operating systems, processors, and storage options. What cloud computing option should they use?	single_choice	0.50	t	\N	2025-12-15 13:59:48.153009+00
1546	1	93. What portion of a machine does a container virtualize?	single_choice	0.50	t	\N	2025-12-15 13:59:48.153009+00
1547	1	94. A manufacturing company is considering shifting their on-premises infrastructure to the cloud, but are concerned that access to their data and applications won’t be available when they need them. They want to ensure that if one data center goes down, another will be available to prevent any disruption of service. What does this refer to?	single_choice	0.50	t	\N	2025-12-15 13:59:48.153009+00
1548	1	95. What computing option automatically provisions resources, like compute power, in the background as needed?	single_choice	0.50	t	\N	2025-12-15 13:59:48.153009+00
1549	1	96. In modern cloud application development, what name is given to independently deployable, scalable, and maintainable components that can be used to build a wide range of applications?	single_choice	0.50	t	\N	2025-12-15 13:59:48.153009+00
1550	1	97. What term describes a set of instructions that lets different software programs communicate with each other?	single_choice	0.50	t	\N	2025-12-15 13:59:48.153009+00
1551	1	98. What term is commonly used to describe a rehost migration strategy for an organization that runs specialized legacy applications that aren’t compatible with cloud-native applications?	single_choice	0.50	t	\N	2025-12-15 13:59:48.153009+00
1552	1	99. What name is given to an environment that comprises some combination of on-premises or private cloud infrastructure and public cloud services?	single_choice	0.50	t	\N	2025-12-15 13:59:48.153009+00
1553	1	100. Which is a fully managed cloud infrastructure solution that lets organizations run their Oracle workloads on dedicated servers in the cloud?	single_choice	0.50	t	\N	2025-12-15 13:59:48.153009+00
1554	1	101. In modern application development, which is responsible for the day-to-day management of cloud-based infrastructure, such as patching, upgrades, and monitoring?	single_choice	0.50	t	\N	2025-12-15 13:59:48.153009+00
1555	1	102. What’s the name of Google Cloud’s production-ready platform for running Kuberenetes applications across multiple cloud environments?	single_choice	0.50	t	\N	2025-12-15 13:59:48.153009+00
1556	1	103. What is one way that organizations can create new revenue streams through APIs?	single_choice	0.50	t	\N	2025-12-15 13:59:48.153009+00
1557	1	104. What is the name of Google Cloud's API management service that can operate APIs with enhanced scale, security, and automation?	single_choice	0.50	t	\N	2025-12-15 13:59:48.153009+00
1558	1	105. What name is given to an environment where an organization uses more than one public cloud provider as part of its architecture?	single_choice	0.50	t	\N	2025-12-15 13:59:48.153009+00
1559	1	106. Which cybersecurity threat demands a ransom payment from a victim to regain access to their files and systems.	single_choice	0.50	t	\N	2025-12-15 13:59:48.153009+00
1560	1	107. Which is a benefit of cloud security over traditional on-premises security?\vcheck	single_choice	0.50	t	\N	2025-12-15 13:59:48.153009+00
1561	1	108. Which is a benefit of cloud security over traditional on-premises security?	single_choice	0.50	t	\N	2025-12-15 13:59:48.153009+00
1562	1	109. Which is the responsibility of the cloud provider in a cloud security model?	single_choice	0.50	t	\N	2025-12-15 13:59:48.153009+00
1563	1	110. Which cloud security principle ensures that security practices and measures align with established standards and guidelines?	single_choice	0.50	t	\N	2025-12-15 13:59:48.153009+00
1564	1	111.  Which security principle advocates granting users only the access they need to perform their job responsibilities?	single_choice	0.50	t	\N	2025-12-15 13:59:48.153009+00
1565	1	112. Which cybersecurity threat occurs when errors arise during the setup of resources, inadvertently exposing sensitive data and systems to unauthorized access?	single_choice	0.50	t	\N	2025-12-15 13:59:48.153009+00
1566	1	113. What common cybersecurity threat involves tricking users into revealing sensitive information or performing actions that compromise security?	single_choice	0.50	t	\N	2025-12-15 13:59:48.153009+00
1567	1	114. Which cloud security principle relates to keeping data accurate and trustworthy?	single_choice	0.50	t	\N	2025-12-15 13:59:48.153009+00
830	3	What is the main purpose of a business data visualization?	single_choice	0.50	t	\N	2025-12-13 18:26:14.560347+00
831	3	Which statement best defines a metric versus a KPI (key performance indicator)?	single_choice	0.50	t	\N	2025-12-13 18:26:14.560347+00
832	3	What is the first question to ask before choosing a chart type?	single_choice	0.50	t	\N	2025-12-13 18:26:14.560347+00
833	3	In storytelling with data, what does adding context mainly help with?	single_choice	0.50	t	\N	2025-12-13 18:26:14.560347+00
834	3	Which is a common sign of 'chartjunk'?	single_choice	0.50	t	\N	2025-12-13 18:26:14.560347+00
835	3	What does 'data-ink ratio' try to maximize?	single_choice	0.50	t	\N	2025-12-13 18:26:14.560347+00
836	3	A 'vanity metric' is best described as a metric that:	single_choice	0.50	t	\N	2025-12-13 18:26:14.560347+00
837	3	Which practice most improves interpretability of a chart for executives?	single_choice	0.50	t	\N	2025-12-13 18:26:14.560347+00
838	3	What is the biggest risk of showing too many KPIs (key performance indicators) on one dashboard?	single_choice	0.50	t	\N	2025-12-13 18:26:14.560347+00
839	3	Which is the best definition of a dashboard in business analytics?	single_choice	0.50	t	\N	2025-12-13 18:26:14.560347+00
840	3	Preattentive processing mainly helps viewers to:	single_choice	0.50	t	\N	2025-12-13 18:26:14.560347+00
841	3	Which visual encoding is generally most accurate for comparing values?	single_choice	0.50	t	\N	2025-12-13 18:26:14.560347+00
842	3	Working memory (WM) limitations imply that dashboards should:	single_choice	0.50	t	\N	2025-12-13 18:26:14.560347+00
843	3	Which type of cognitive load is caused by poor design choices like clutter and irrelevant decoration?	single_choice	0.50	t	\N	2025-12-13 18:26:14.560347+00
844	3	Germane load is best described as:	single_choice	0.50	t	\N	2025-12-13 18:26:14.560347+00
845	3	Change blindness refers to the difficulty of:	single_choice	0.50	t	\N	2025-12-13 18:26:14.560347+00
846	3	Which eye-tracking measure is most directly linked to where attention is held longer?	single_choice	0.50	t	\N	2025-12-13 18:26:14.560347+00
847	3	In visual perception, a saccade is:	single_choice	0.50	t	\N	2025-12-13 18:26:14.560347+00
848	3	If users repeatedly miss an important KPI on a dashboard, a likely cause is:	single_choice	0.50	t	\N	2025-12-13 18:26:14.560347+00
849	3	What is a practical benefit of using small multiples (facets)?	single_choice	0.50	t	\N	2025-12-13 18:26:14.560347+00
850	3	Gestalt principle of proximity suggests that elements close together are perceived as:	single_choice	0.50	t	\N	2025-12-13 18:26:14.560347+00
851	3	Gestalt principle of similarity suggests that elements with similar color or shape are perceived as:	single_choice	0.50	t	\N	2025-12-13 18:26:14.560347+00
852	3	Gestalt principle of closure explains why people can recognize incomplete shapes as:	single_choice	0.50	t	\N	2025-12-13 18:26:14.560347+00
853	3	Gestalt principle of continuity suggests viewers prefer interpretations that follow:	single_choice	0.50	t	\N	2025-12-13 18:26:14.560347+00
854	3	Gestalt principle of figure-ground is most relevant to:	single_choice	0.50	t	\N	2025-12-13 18:26:14.560347+00
855	3	Which design choice best supports Gestalt grouping by proximity?	single_choice	0.50	t	\N	2025-12-13 18:26:14.560347+00
856	3	Which design choice best supports grouping by similarity?	single_choice	0.50	t	\N	2025-12-13 18:26:14.560347+00
857	3	Common fate (a Gestalt-like cue) is most related to:	single_choice	0.50	t	\N	2025-12-13 18:26:14.560347+00
858	3	Which is an example of using enclosure to create grouping?	single_choice	0.50	t	\N	2025-12-13 18:26:14.560347+00
859	3	Which situation most risks a false grouping effect?	single_choice	0.50	t	\N	2025-12-13 18:26:14.560347+00
860	3	A bar chart is best for:	single_choice	0.50	t	\N	2025-12-13 18:26:14.560347+00
861	3	A line chart is best for:	single_choice	0.50	t	\N	2025-12-13 18:26:14.560347+00
862	3	A scatter plot is best for:	single_choice	0.50	t	\N	2025-12-13 18:26:14.560347+00
863	3	A histogram is primarily used to show:	single_choice	0.50	t	\N	2025-12-13 18:26:14.560347+00
864	3	A box plot is most useful to compare:	single_choice	0.50	t	\N	2025-12-13 18:26:14.560347+00
865	3	A violin plot adds which extra information compared to a box plot?	single_choice	0.50	t	\N	2025-12-13 18:26:14.560347+00
866	3	A treemap is best suited to visualize:	single_choice	0.50	t	\N	2025-12-13 18:26:14.560347+00
867	3	A heatmap is commonly used to show:	single_choice	0.50	t	\N	2025-12-13 18:26:14.560347+00
868	3	When is a pie chart most appropriate?	single_choice	0.50	t	\N	2025-12-13 18:26:14.560347+00
869	3	Which alternative often works better than a pie chart for comparing parts?	single_choice	0.50	t	\N	2025-12-13 18:26:14.560347+00
870	3	A radar chart is commonly (but cautiously) used to:	single_choice	0.50	t	\N	2025-12-13 18:26:14.560347+00
871	3	Parallel coordinates are best for:	single_choice	0.50	t	\N	2025-12-13 18:26:14.560347+00
872	3	A dendrogram is used to visualize:	single_choice	0.50	t	\N	2025-12-13 18:26:14.560347+00
873	3	Which plot best reveals outliers in a numeric variable by group?	single_choice	0.50	t	\N	2025-12-13 18:26:14.560347+00
874	3	Overplotting happens most often when:	single_choice	0.50	t	\N	2025-12-13 18:26:14.560347+00
875	3	A good strategy to reduce overplotting in large scatter plots is:	single_choice	0.50	t	\N	2025-12-13 18:26:14.560347+00
876	3	A choropleth map is most appropriate when values are:	single_choice	0.50	t	\N	2025-12-13 18:26:14.560347+00
877	3	Why can bubble charts be misleading for comparison?	single_choice	0.50	t	\N	2025-12-13 18:26:14.560347+00
878	3	Which visualization is best for showing cumulative totals over time?	single_choice	0.50	t	\N	2025-12-13 18:26:14.560347+00
879	3	In the Grammar of Graphics, 'aesthetics' refers to:	single_choice	0.50	t	\N	2025-12-13 18:26:14.560347+00
880	3	In Grammar of Graphics, 'geoms' are best described as:	single_choice	0.50	t	\N	2025-12-13 18:26:14.560347+00
881	3	In Grammar of Graphics, 'scales' are responsible for:	single_choice	0.50	t	\N	2025-12-13 18:26:14.560347+00
882	3	In Grammar of Graphics, 'facets' enable:	single_choice	0.50	t	\N	2025-12-13 18:26:14.560347+00
883	3	Which is an example of layering in a visualization?	single_choice	0.50	t	\N	2025-12-13 18:26:14.560347+00
884	3	Which is NOT a typical component of a Grammar of Graphics view?	single_choice	0.50	t	\N	2025-12-13 18:26:14.560347+00
885	3	What does a coordinate system change most directly?	single_choice	0.50	t	\N	2025-12-13 18:26:14.560347+00
886	3	A key advantage of a grammar-based approach is that it:	single_choice	0.50	t	\N	2025-12-13 18:26:14.560347+00
887	3	In ggplot-style thinking, mapping 'sales' to y-position is an example of:	single_choice	0.50	t	\N	2025-12-13 18:26:14.560347+00
888	3	A common mistake when mixing multiple geoms is:	single_choice	0.50	t	\N	2025-12-13 18:26:14.560347+00
889	3	Which variable type is best described as nominal?	single_choice	0.50	t	\N	2025-12-13 18:26:14.560347+00
890	3	Which variable type is best described as ordinal?	single_choice	0.50	t	\N	2025-12-13 18:26:14.560347+00
891	3	A truncated y-axis on a bar chart most commonly risks:	single_choice	0.50	t	\N	2025-12-13 18:26:14.560347+00
892	3	Why is a zero baseline often recommended for bar charts?	single_choice	0.50	t	\N	2025-12-13 18:26:14.560347+00
893	3	A log scale is most appropriate when:	single_choice	0.50	t	\N	2025-12-13 18:26:14.560347+00
894	3	Dual y-axes are risky because they can:	single_choice	0.50	t	\N	2025-12-13 18:26:14.560347+00
895	3	Which encoding is typically less precise for value comparison than position or length?	single_choice	0.50	t	\N	2025-12-13 18:26:14.560347+00
896	3	If you want to compare two distributions across many groups, a strong option is:	single_choice	0.50	t	\N	2025-12-13 18:26:14.560347+00
897	3	Which label practice most improves readability?	single_choice	0.50	t	\N	2025-12-13 18:26:14.560347+00
898	3	Which is the best practice for ordering categories in a bar chart?	single_choice	0.50	t	\N	2025-12-13 18:26:14.560347+00
899	3	A sequential color scale is best for:	single_choice	0.50	t	\N	2025-12-13 18:26:14.560347+00
900	3	A diverging color scale is best for:	single_choice	0.50	t	\N	2025-12-13 18:26:14.560347+00
901	3	A categorical palette is best for:	single_choice	0.50	t	\N	2025-12-13 18:26:14.560347+00
902	3	Why should dashboards avoid relying on color alone to encode meaning?	single_choice	0.50	t	\N	2025-12-13 18:26:14.560347+00
903	3	What is a strong use of annotation in business charts?	single_choice	0.50	t	\N	2025-12-13 18:26:14.560347+00
904	3	Which approach usually reduces visual clutter the most?	single_choice	0.50	t	\N	2025-12-13 18:26:14.560347+00
905	3	When labeling lines in a line chart, a best practice is to:	single_choice	0.50	t	\N	2025-12-13 18:26:14.560347+00
906	3	What is a strong reason to use whitespace in dashboards?	single_choice	0.50	t	\N	2025-12-13 18:26:14.560347+00
907	3	If two colors appear equally salient but mean different categories, what risk increases?	single_choice	0.50	t	\N	2025-12-13 18:26:14.560347+00
908	3	Which is a good practice for legends?	single_choice	0.50	t	\N	2025-12-13 18:26:14.560347+00
909	3	A leading indicator is best described as a measure that:	single_choice	0.50	t	\N	2025-12-13 18:26:14.560347+00
910	3	A lagging indicator is best described as a measure that:	single_choice	0.50	t	\N	2025-12-13 18:26:14.560347+00
911	3	Which pair is a good example of leading versus lagging indicators?	single_choice	0.50	t	\N	2025-12-13 18:26:14.560347+00
912	3	A well-designed KPI (key performance indicator) should be:	single_choice	0.50	t	\N	2025-12-13 18:26:14.560347+00
913	3	What is a key difference between real-time and static dashboards?	single_choice	0.50	t	\N	2025-12-13 18:26:14.560347+00
914	3	Which use case most benefits from real-time dashboards?	single_choice	0.50	t	\N	2025-12-13 18:26:14.560347+00
915	3	Visual hierarchy in dashboards primarily helps users to:	single_choice	0.50	t	\N	2025-12-13 18:26:14.560347+00
916	3	Which is a strong guideline for KPI count per dashboard (typical executive view)?	single_choice	0.50	t	\N	2025-12-13 18:26:14.560347+00
917	3	Which is the best example of adding context to a KPI?	single_choice	0.50	t	\N	2025-12-13 18:26:14.560347+00
918	3	A KPI without a clear owner and action plan is often:	single_choice	0.50	t	\N	2025-12-13 18:26:14.560347+00
919	3	Which is a common ethical risk in data visualization?	single_choice	0.50	t	\N	2025-12-13 18:26:14.560347+00
920	3	Cherry-picking in visualization most closely means:	single_choice	0.50	t	\N	2025-12-13 18:26:14.560347+00
921	3	What is a best practice to support trust and transparency?	single_choice	0.50	t	\N	2025-12-13 18:26:14.560347+00
922	3	When visualizing uncertainty, a common approach is to use:	single_choice	0.50	t	\N	2025-12-13 18:26:14.560347+00
923	3	In a user study of dashboard comprehension, a strong outcome measure is:	single_choice	0.50	t	\N	2025-12-13 18:26:14.560347+00
924	3	Which approach best evaluates whether a redesign reduced extraneous load?	single_choice	0.50	t	\N	2025-12-13 18:26:14.560347+00
925	3	Which is a common privacy concern in business dashboards?	single_choice	0.50	t	\N	2025-12-13 18:26:14.560347+00
926	3	A key big data visualization principle is to:	single_choice	0.50	t	\N	2025-12-13 18:26:14.560347+00
927	3	Which interaction best supports 'overview first, zoom and filter, then details'?	single_choice	0.50	t	\N	2025-12-13 18:26:14.560347+00
928	3	Which is a valid reason to avoid a rainbow color map in analytic charts?	single_choice	0.50	t	\N	2025-12-13 18:26:14.560347+00
929	3	Which is a strong reason to add reference lines (for example, targets)?	single_choice	0.50	t	\N	2025-12-13 18:26:14.560347+00
930	3	Which chart best supports comparing composition over time with a few categories?	single_choice	0.50	t	\N	2025-12-13 18:26:14.560347+00
931	3	What is the biggest downside of too many interactive controls on a dashboard?	single_choice	0.50	t	\N	2025-12-13 18:26:14.560347+00
932	3	A good filter default state should usually be:	single_choice	0.50	t	\N	2025-12-13 18:26:14.560347+00
933	3	What is the main benefit of using benchmarks in KPI charts?	single_choice	0.50	t	\N	2025-12-13 18:26:14.560347+00
934	3	In visualization design, 'accuracy' most directly means:	single_choice	0.50	t	\N	2025-12-13 18:26:14.560347+00
935	3	Which is a common pitfall when comparing two time series with different units?	single_choice	0.50	t	\N	2025-12-13 18:26:14.560347+00
936	3	A useful technique for showing distribution and individual points together is:	single_choice	0.50	t	\N	2025-12-13 18:26:14.560347+00
937	3	Which visual element most directly supports quick scanning in dashboards?	single_choice	0.50	t	\N	2025-12-13 18:26:14.560347+00
938	3	What is the main benefit of using consistent scales across small multiples?	single_choice	0.50	t	\N	2025-12-13 18:26:14.560347+00
939	3	If a dashboard is meant for daily operations, KPI update frequency should usually be:	single_choice	0.50	t	\N	2025-12-13 18:26:14.560347+00
940	3	Which is the most reasonable goal of interaction in business dashboards?	single_choice	0.50	t	\N	2025-12-13 18:26:14.560347+00
941	3	When a KPI is red, the best practice is to also provide:	single_choice	0.50	t	\N	2025-12-13 18:26:14.560347+00
942	3	Which is a valid reason to use median instead of mean in a KPI summary?	single_choice	0.50	t	\N	2025-12-13 18:26:14.560347+00
943	3	A KPI definition should clearly specify:	single_choice	0.50	t	\N	2025-12-13 18:26:14.560347+00
944	3	Which choice best supports cross-dashboard consistency?	single_choice	0.50	t	\N	2025-12-13 18:26:14.560347+00
945	3	A key reason to avoid misleading visualizations is that they can:	single_choice	0.50	t	\N	2025-12-13 18:26:14.560347+00
946	3	In big data contexts, why is aggregation useful for visualization?	single_choice	0.50	t	\N	2025-12-13 18:26:14.560347+00
947	3	Which approach is most appropriate for visualizing streaming data?	single_choice	0.50	t	\N	2025-12-13 18:26:14.560347+00
948	3	What is the primary goal of visual analytics?	single_choice	0.50	t	\N	2025-12-13 18:26:14.560347+00
949	3	In Cleveland and McGill’s ranking of graphical perception tasks, which encoding is typically most accurate for quantitative comparison?	single_choice	0.50	t	\N	2025-12-13 18:26:25.243971+00
950	3	Which statement best captures the main implication of limited visual working memory for dashboard design?	single_choice	0.50	t	\N	2025-12-13 18:26:25.243971+00
951	3	What is the best interpretation of a long average fixation duration on a chart element in an eye-tracking study?	single_choice	0.50	t	\N	2025-12-13 18:26:25.243971+00
952	3	Time to first fixation (TTFF) on a KPI area of interest (AOI) primarily measures:	single_choice	0.50	t	\N	2025-12-13 18:26:25.243971+00
953	3	Which phenomenon best explains why users may fail to notice a major change in a dashboard after a refresh?	single_choice	0.50	t	\N	2025-12-13 18:26:25.243971+00
954	3	A conjunctive visual search (for example, red and square) is generally slower than a feature search because it requires:	single_choice	0.50	t	\N	2025-12-13 18:26:25.243971+00
955	3	In cognitive load theory, which design choice most directly reduces extraneous load in a dashboard?	single_choice	0.50	t	\N	2025-12-13 18:26:25.243971+00
956	3	Which experimental design best controls for individual differences in an eye-tracking dashboard study with two layouts (A and B)?	single_choice	0.50	t	\N	2025-12-13 18:26:25.243971+00
957	3	A key threat to validity if you always show layout A before layout B is:	single_choice	0.50	t	\N	2025-12-13 18:26:25.243971+00
958	3	In dashboard scanning, a strong proxy for "visual competition" between elements is often:	single_choice	0.50	t	\N	2025-12-13 18:26:25.243971+00
959	3	Which is the most defensible conclusion from a lower mean task time with unchanged accuracy after a redesign?	single_choice	0.50	t	\N	2025-12-13 18:26:25.243971+00
960	3	Which measure best captures "how much" of an AOI was viewed overall?	single_choice	0.50	t	\N	2025-12-13 18:26:25.243971+00
961	3	If users answer correctly but show very long fixations and many back-and-forth saccades, the redesign likely increased:	single_choice	0.50	t	\N	2025-12-13 18:26:25.243971+00
962	3	Which statement about preattentive features is most accurate?	single_choice	0.50	t	\N	2025-12-13 18:26:25.243971+00
963	3	In an eye-tracking heatmap, "hot" regions indicate:	single_choice	0.50	t	\N	2025-12-13 18:26:25.243971+00
964	3	Which is the strongest reason to use task-based questions in a visualization user study?	single_choice	0.50	t	\N	2025-12-13 18:26:25.243971+00
965	3	If two dashboard designs differ in color palette only, and you observe better performance in one, the most plausible primary mechanism is:	single_choice	0.50	t	\N	2025-12-13 18:26:25.243971+00
966	3	Which concept best describes the risk of interpreting aggregated regional data as if it applied to individuals?	single_choice	0.50	t	\N	2025-12-13 18:26:25.243971+00
967	3	A visual illusion caused by context that shifts perceived length or position would most directly threaten:	single_choice	0.50	t	\N	2025-12-13 18:26:25.243971+00
968	3	Which is a defensible way to operationalize "comprehension" in a visualization experiment?	single_choice	0.50	t	\N	2025-12-13 18:26:25.243971+00
969	3	Gestalt proximity most directly affects grouping because the visual system assumes:	single_choice	0.50	t	\N	2025-12-13 18:26:25.243971+00
970	3	A common Gestalt failure in dashboards is when similarity cues cause users to:	single_choice	0.50	t	\N	2025-12-13 18:26:25.243971+00
971	3	Which design choice best leverages figure-ground separation for readability?	single_choice	0.50	t	\N	2025-12-13 18:26:25.243971+00
972	3	Enclosure (common region) primarily helps by:	single_choice	0.50	t	\N	2025-12-13 18:26:25.243971+00
973	3	Which is the best explanation for why misalignment across KPI cards harms comparison?	single_choice	0.50	t	\N	2025-12-13 18:26:25.243971+00
974	3	If two charts share the same colors for different categories on different pages, the primary risk is:	single_choice	0.50	t	\N	2025-12-13 18:26:25.243971+00
975	3	In layout design, what is the strongest rationale for a consistent grid?	single_choice	0.50	t	\N	2025-12-13 18:26:25.243971+00
976	3	Which Gestalt cue is most likely to conflict with proximity and create ambiguity?	single_choice	0.50	t	\N	2025-12-13 18:26:25.243971+00
977	3	Which choice best supports "progressive disclosure" in dashboards?	single_choice	0.50	t	\N	2025-12-13 18:26:25.243971+00
978	3	A strong reason to minimize chart borders and heavy gridlines is that they:	single_choice	0.50	t	\N	2025-12-13 18:26:25.243971+00
979	3	Which statement about pie charts is most technically defensible?	single_choice	0.50	t	\N	2025-12-13 18:26:25.243971+00
980	3	A bar chart with a truncated y-axis is especially misleading because bars encode magnitude via:	single_choice	0.50	t	\N	2025-12-13 18:26:25.243971+00
981	3	If you must compare two variables with different units over time, which is usually the safest design?	single_choice	0.50	t	\N	2025-12-13 18:26:25.243971+00
982	3	Simpson’s paradox warns that a trend seen in aggregated data can:	single_choice	0.50	t	\N	2025-12-13 18:26:25.243971+00
983	3	When visualizing rates on a choropleth map, the most critical step to avoid misleading comparisons is:	single_choice	0.50	t	\N	2025-12-13 18:26:25.243971+00
984	3	The modifiable areal unit problem (MAUP) in spatial visualization implies that results can change when you:	single_choice	0.50	t	\N	2025-12-13 18:26:25.243971+00
985	3	Which practice best supports honest communication of uncertainty in forecasts?	single_choice	0.50	t	\N	2025-12-13 18:26:25.243971+00
986	3	In a histogram, changing the bin width primarily changes:	single_choice	0.50	t	\N	2025-12-13 18:26:25.243971+00
987	3	A kernel density estimate (KDE) differs from a histogram mainly by:	single_choice	0.50	t	\N	2025-12-13 18:26:25.243971+00
988	3	Why are bubble charts often poor for precise comparison?	single_choice	0.50	t	\N	2025-12-13 18:26:25.243971+00
989	3	Which is the most defensible reason to use a log scale on the y-axis?	single_choice	0.50	t	\N	2025-12-13 18:26:25.243971+00
990	3	If you want to compare growth rates rather than absolute values across entities, a good transformation is often:	single_choice	0.50	t	\N	2025-12-13 18:26:25.243971+00
991	3	Which visualization best reveals heteroscedasticity in a regression context?	single_choice	0.50	t	\N	2025-12-13 18:26:25.243971+00
992	3	A chart that exaggerates effects by showing a large visual change for a small numeric change violates which principle most directly?	single_choice	0.50	t	\N	2025-12-13 18:26:25.243971+00
993	3	When comparing slopes visually across line charts, the key design risk is that slope perception changes with:	single_choice	0.50	t	\N	2025-12-13 18:26:25.243971+00
994	3	Banking to 45 degrees is a design idea meant to improve:	single_choice	0.50	t	\N	2025-12-13 18:26:25.243971+00
995	3	Which is the strongest reason to avoid 3D bar charts for business reporting?	single_choice	0.50	t	\N	2025-12-13 18:26:25.243971+00
996	3	A stacked bar chart is weakest when the main task is to compare:	single_choice	0.50	t	\N	2025-12-13 18:26:25.243971+00
997	3	Which chart most directly supports comparing distributions across many categories with limited space?	single_choice	0.50	t	\N	2025-12-13 18:26:25.243971+00
998	3	In a time series, what is the best way to avoid implying nonexistent continuity?	single_choice	0.50	t	\N	2025-12-13 18:26:25.243971+00
999	3	When a distribution is highly skewed with extreme outliers, which summary visualization is often most robust?	single_choice	0.50	t	\N	2025-12-13 18:26:25.243971+00
1000	3	Which choice best explains why sorting bars by value can improve accuracy of comparison?	single_choice	0.50	t	\N	2025-12-13 18:26:25.243971+00
1001	3	A cumulative sum chart can mislead if viewers confuse it with:	single_choice	0.50	t	\N	2025-12-13 18:26:25.243971+00
1002	3	Which approach best separates "signal" from "noise" in large time series without hiding uncertainty?	single_choice	0.50	t	\N	2025-12-13 18:26:25.243971+00
1003	3	Which statement about correlation in scatter plots is most correct?	single_choice	0.50	t	\N	2025-12-13 18:26:25.243971+00
1004	3	Overplotting in large scatter plots is best addressed by:	single_choice	0.50	t	\N	2025-12-13 18:26:25.243971+00
1005	3	When using a diverging color scale, the most important design requirement is:	single_choice	0.50	t	\N	2025-12-13 18:26:25.243971+00
1006	3	Perceptual uniformity in a color scale primarily means that equal steps in data produce:	single_choice	0.50	t	\N	2025-12-13 18:26:25.243971+00
1007	3	Why is rainbow coloring often problematic for ordered numeric data?	single_choice	0.50	t	\N	2025-12-13 18:26:25.243971+00
1008	3	Which practice most improves accessibility for color vision deficiencies?	single_choice	0.50	t	\N	2025-12-13 18:26:25.243971+00
1009	3	In heatmaps, a key reason to order rows and columns (for example, by clustering) is to:	single_choice	0.50	t	\N	2025-12-13 18:26:25.243971+00
1010	3	Which is the strongest caution when using red as an alert color in dashboards?	single_choice	0.50	t	\N	2025-12-13 18:26:25.243971+00
1011	3	In the Grammar of Graphics, what is the most accurate meaning of an aesthetic mapping?	single_choice	0.50	t	\N	2025-12-13 18:26:25.243971+00
1012	3	Which change most directly modifies a coordinate system rather than a scale?	single_choice	0.50	t	\N	2025-12-13 18:26:25.243971+00
1013	3	In layered graphics (for example, points plus a trend line), what is the main risk if layers use different scales unintentionally?	single_choice	0.50	t	\N	2025-12-13 18:26:25.243971+00
1014	3	Faceting (small multiples) is most powerful when it preserves:	single_choice	0.50	t	\N	2025-12-13 18:26:25.243971+00
1015	3	Which is the most defensible reason to use direct labeling instead of a legend?	single_choice	0.50	t	\N	2025-12-13 18:26:25.243971+00
1016	3	In big data visualization, progressive rendering primarily addresses:	single_choice	0.50	t	\N	2025-12-13 18:26:25.243971+00
1017	3	The "overview first, zoom and filter, then details on demand" mantra is most aligned with:	single_choice	0.50	t	\N	2025-12-13 18:26:25.243971+00
1018	3	Which interaction technique links selections across multiple coordinated views?	single_choice	0.50	t	\N	2025-12-13 18:26:25.243971+00
1019	3	Why can sampling be dangerous in exploratory visual analytics if done naively?	single_choice	0.50	t	\N	2025-12-13 18:26:25.243971+00
1020	3	In a streaming dashboard, what is a key reason to use time windows (for example, tumbling windows)?	single_choice	0.50	t	\N	2025-12-13 18:26:25.243971+00
1021	3	A key ethical risk of showing individual-level customer data in a dashboard is:	single_choice	0.50	t	\N	2025-12-13 18:26:25.243971+00
1022	3	What is the best reason to include metric definitions and data provenance notes near a dashboard?	single_choice	0.50	t	\N	2025-12-13 18:26:25.243971+00
1023	3	Which is the most defensible criticism of the "data-ink ratio" idea when applied blindly?	single_choice	0.50	t	\N	2025-12-13 18:26:25.243971+00
1024	3	Which statement is most correct about using area to encode quantity (for example, treemaps)?	single_choice	0.50	t	\N	2025-12-13 18:26:25.243971+00
1025	3	In a treemap, what is a key reason small differences are hard to compare?	single_choice	0.50	t	\N	2025-12-13 18:26:25.243971+00
1026	3	A slopegraph is best used when you need to show:	single_choice	0.50	t	\N	2025-12-13 18:26:25.243971+00
1027	3	What is the primary risk of using a stacked area chart with many categories?	single_choice	0.50	t	\N	2025-12-13 18:26:25.243971+00
1028	3	In a waterfall chart, the strongest interpretive value is showing:	single_choice	0.50	t	\N	2025-12-13 18:26:25.243971+00
1029	3	If you must encode a third quantitative variable in a scatter plot, the least bad additional channel is often:	single_choice	0.50	t	\N	2025-12-13 18:26:25.243971+00
1030	3	What is the strongest argument for using dot plots instead of bars in some cases?	single_choice	0.50	t	\N	2025-12-13 18:26:25.243971+00
1031	3	Which statement about KPI targets is most correct?	single_choice	0.50	t	\N	2025-12-13 18:26:25.243971+00
1032	3	In metric design, a key risk of mixing definitions across teams is:	single_choice	0.50	t	\N	2025-12-13 18:26:25.243971+00
1033	3	Which dashboard element most directly supports "diagnosis" rather than "monitoring"?	single_choice	0.50	t	\N	2025-12-13 18:26:25.243971+00
1034	3	What is the most defensible reason to separate operational and strategic dashboards?	single_choice	0.50	t	\N	2025-12-13 18:26:25.243971+00
1035	3	A leading indicator is most valuable when it is:	single_choice	0.50	t	\N	2025-12-13 18:26:25.243971+00
1036	3	If a KPI is highly volatile day-to-day, a strong visualization approach is to:	single_choice	0.50	t	\N	2025-12-13 18:26:25.243971+00
1037	3	Which is the strongest reason to include units and time window in KPI labels?	single_choice	0.50	t	\N	2025-12-13 18:26:25.243971+00
1038	3	What is the strongest reason to avoid mixing absolute values and percentages in the same visual channel without clear cues?	single_choice	0.50	t	\N	2025-12-13 18:26:25.243971+00
1039	3	In a KPI red/amber/green scheme, a best practice is to base thresholds on:	single_choice	0.50	t	\N	2025-12-13 18:26:25.243971+00
1040	3	Which choice best reduces the risk of spurious precision in dashboards?	single_choice	0.50	t	\N	2025-12-13 18:26:25.243971+00
1041	3	Why can ranking dashboards (league tables) be misleading without uncertainty?	single_choice	0.50	t	\N	2025-12-13 18:26:25.243971+00
1042	3	Which is the strongest reason to show denominators for rates (for example, conversion rate with sessions)?	single_choice	0.50	t	\N	2025-12-13 18:26:25.243971+00
1043	3	In network visualizations, a major readability problem that most directly degrades comprehension is:	single_choice	0.50	t	\N	2025-12-13 18:26:25.243971+00
1044	3	Which strategy most directly helps reduce a "hairball" effect in large graphs?	single_choice	0.50	t	\N	2025-12-13 18:26:25.243971+00
1045	3	In parallel coordinates, a common interpretive pitfall is that correlations can appear to change due to:	single_choice	0.50	t	\N	2025-12-13 18:26:25.243971+00
1046	3	A dendrogram is most directly tied to which analytic method?	single_choice	0.50	t	\N	2025-12-13 18:26:25.243971+00
1047	3	If you display a PCA scatter plot, what is the strongest practice to support interpretation?	single_choice	0.50	t	\N	2025-12-13 18:26:25.243971+00
1048	3	Which is the best reason to prefer small multiples over animation for comparisons across time slices?	single_choice	0.50	t	\N	2025-12-13 18:26:25.243971+00
1049	3	A scatter plot matrix (SPLOM) is primarily used to:	single_choice	0.50	t	\N	2025-12-13 18:26:25.243971+00
1050	3	Why is it risky to use a choropleth to show absolute counts (for example, total sales) by region?	single_choice	0.50	t	\N	2025-12-13 18:26:25.243971+00
1051	3	In map projections, the key unavoidable tradeoff is that you cannot preserve simultaneously:	single_choice	0.50	t	\N	2025-12-13 18:26:25.243971+00
1052	3	Which choice best supports truthful comparison of two groups with different sample sizes in a distribution plot?	single_choice	0.50	t	\N	2025-12-13 18:26:25.243971+00
1053	3	If you choose a sequential palette for nominal categories, the main risk is that it:	single_choice	0.50	t	\N	2025-12-13 18:26:25.243971+00
1054	3	Which scale property is most important for a sequential palette representing increasing magnitude?	single_choice	0.50	t	\N	2025-12-13 18:26:25.243971+00
1055	3	Which is the strongest reason to avoid using too many saturated colors in one dashboard?	single_choice	0.50	t	\N	2025-12-13 18:26:25.243971+00
1056	3	A diverging palette is least appropriate when the data has:	single_choice	0.50	t	\N	2025-12-13 18:26:25.243971+00
1057	3	Which is the strongest reason to use color sparingly for emphasis rather than everywhere?	single_choice	0.50	t	\N	2025-12-13 18:26:25.243971+00
1058	3	In a heatmap, what is a key risk if the colorbar range changes between views without warning?	single_choice	0.50	t	\N	2025-12-13 18:26:25.243971+00
1059	3	Which layer of the "visualization pipeline" most directly changes what data is available to be encoded?	single_choice	0.50	t	\N	2025-12-13 18:26:25.243971+00
1060	3	If a dashboard appears "correct" but users systematically answer the wrong business question, the most likely root cause is:	single_choice	0.50	t	\N	2025-12-13 18:26:25.243971+00
1061	3	Which is the strongest justification for including benchmarks alongside trends?	single_choice	0.50	t	\N	2025-12-13 18:26:25.243971+00
1062	3	In evaluation, which result best supports the claim that a new dashboard improves both effectiveness and efficiency?	single_choice	0.50	t	\N	2025-12-13 18:26:25.243971+00
1063	3	Which practice best reduces "metric gaming" risk when dashboards drive incentives?	single_choice	0.50	t	\N	2025-12-13 18:26:25.243971+00
1064	3	In a business A/B test visualization, what is the strongest reason to show confidence intervals for the lift?	single_choice	0.50	t	\N	2025-12-13 18:26:25.243971+00
1065	3	If a dashboard KPI is a ratio (for example, conversion rate), a major interpretive pitfall is ignoring:	single_choice	0.50	t	\N	2025-12-13 18:26:25.243971+00
1066	3	Which visualization best avoids misleading emphasis when comparing two groups with different base rates?	single_choice	0.50	t	\N	2025-12-13 18:26:25.243971+00
1067	3	A major reason to annotate business events (campaigns, outages) on time series charts is to:	single_choice	0.50	t	\N	2025-12-13 18:26:25.243971+00
1068	3	Which is the strongest reason to avoid using too many KPI cards with large numbers and no trend context?	single_choice	0.50	t	\N	2025-12-13 18:26:25.243971+00
1069	3	In an eye-tracking study, why is it important to define AOIs before analyzing results?	single_choice	0.50	t	\N	2025-12-13 18:26:25.243971+00
1070	3	Which is the strongest reason to randomize task order in a multi-task dashboard experiment?	single_choice	0.50	t	\N	2025-12-13 18:26:25.243971+00
1071	3	If you observe fewer fixations but lower accuracy after a redesign, the most plausible interpretation is:	single_choice	0.50	t	\N	2025-12-13 18:26:25.243971+00
1072	3	Which outcome best indicates improved "findability" of a critical KPI in eye-tracking?	single_choice	0.50	t	\N	2025-12-13 18:26:25.243971+00
1073	3	Which is the strongest limitation of eye-tracking as evidence for "understanding"?	single_choice	0.50	t	\N	2025-12-13 18:26:25.243971+00
1074	3	A key reason to avoid excessive drill-down depth is that it can:	single_choice	0.50	t	\N	2025-12-13 18:26:25.243971+00
1075	3	In interactive dashboards, what is a primary risk of high latency after user actions?	single_choice	0.50	t	\N	2025-12-13 18:26:25.243971+00
1076	3	Which is the strongest argument for using level-of-detail (LOD) techniques in massive datasets?	single_choice	0.50	t	\N	2025-12-13 18:26:25.243971+00
1077	3	In streaming analytics visualization, a key risk of cumulative plots without reset is that they:	single_choice	0.50	t	\N	2025-12-13 18:26:25.243971+00
1078	3	Which is the strongest reason to include data refresh timestamps on dashboards?	single_choice	0.50	t	\N	2025-12-13 18:26:25.243971+00
1079	3	Which is the most defensible principle when designing a chart for executives under time pressure?	single_choice	0.50	t	\N	2025-12-13 18:26:25.243971+00
1080	3	If a visualization is correct but not actionable, the most likely missing element is:	single_choice	0.50	t	\N	2025-12-13 18:26:25.243971+00
1081	3	What is the best reason to avoid showing too many significant digits in a KPI card?	single_choice	0.50	t	\N	2025-12-13 18:26:25.243971+00
1082	3	When designing a dashboard for multiple roles, the most defensible approach is to:	single_choice	0.50	t	\N	2025-12-13 18:26:25.243971+00
1083	3	Which best describes a "guardrail metric" in a KPI system?	single_choice	0.50	t	\N	2025-12-13 18:26:25.243971+00
1084	3	In visualization ethics, what is the most defensible reason to avoid "cherry-picked" time windows?	single_choice	0.50	t	\N	2025-12-13 18:26:25.243971+00
1085	3	What is the best practice when missing data could meaningfully change interpretation?	single_choice	0.50	t	\N	2025-12-13 18:26:25.243971+00
1086	3	Which is the strongest reason to audit dashboards for bias and fairness when they influence decisions?	single_choice	0.50	t	\N	2025-12-13 18:26:25.243971+00
1087	3	Which method best supports comparing many categories with long labels while preserving readability?	single_choice	0.50	t	\N	2025-12-13 18:26:25.243971+00
1088	3	If you want to show both magnitude and composition for categories, a better alternative than a complex stacked bar is often:	single_choice	0.50	t	\N	2025-12-13 18:26:25.243971+00
1089	3	Which is the strongest reason to show distributions instead of only averages in business dashboards?	single_choice	0.50	t	\N	2025-12-13 18:26:25.243971+00
1090	3	A Q-Q plot is primarily used to assess:	single_choice	0.50	t	\N	2025-12-13 18:26:25.243971+00
1091	3	When showing effect sizes across many experiments, which visualization is most appropriate?	single_choice	0.50	t	\N	2025-12-13 18:26:25.243971+00
1151	3	Which is a simple way to show a target on a chart?	single_choice	0.50	t	\N	2025-12-13 18:26:30.334574+00
1092	3	In a KPI system, which is the strongest reason to separate "input" metrics from "outcome" metrics?	single_choice	0.50	t	\N	2025-12-13 18:26:25.243971+00
1093	3	Which is the strongest reason to avoid mixing levels of aggregation (daily and monthly) on the same axis without clear encoding?	single_choice	0.50	t	\N	2025-12-13 18:26:25.243971+00
1094	3	Which approach best supports comparing performance across entities with different scales (for example, stores with different traffic)?	single_choice	0.50	t	\N	2025-12-13 18:26:25.243971+00
1095	3	Which is the most defensible way to compare seasonality across years in time series visualization?	single_choice	0.50	t	\N	2025-12-13 18:26:25.243971+00
1096	3	A funnel chart is most appropriate when the process is:	single_choice	0.50	t	\N	2025-12-13 18:26:25.243971+00
1097	3	Why do slope comparisons become invalid when two line charts use different axis ranges but look visually similar?	single_choice	0.50	t	\N	2025-12-13 18:26:25.243971+00
1098	3	Which is the strongest reason to use a reference distribution (for example, historical baseline) when flagging anomalies?	single_choice	0.50	t	\N	2025-12-13 18:26:25.243971+00
1099	3	If a KPI threshold is set too tight, the most likely operational consequence is:	single_choice	0.50	t	\N	2025-12-13 18:26:25.243971+00
1100	3	Which statement is most correct about "significance" in visual comparisons?	single_choice	0.50	t	\N	2025-12-13 18:26:25.243971+00
1101	3	Which is the most defensible purpose of a KPI "owner" field in governance?	single_choice	0.50	t	\N	2025-12-13 18:26:25.243971+00
1102	3	Which is the strongest reason to separate "exploration" views from "official reporting" views?	single_choice	0.50	t	\N	2025-12-13 18:26:25.243971+00
1103	3	In large-scale dashboards, why is consistent filtering logic across pages critical?	single_choice	0.50	t	\N	2025-12-13 18:26:25.243971+00
1104	3	Which is a key risk of using min-max normalization across entities when there are strong outliers?	single_choice	0.50	t	\N	2025-12-13 18:26:25.243971+00
1105	3	Which practice best supports reproducibility of a visualization analysis pipeline?	single_choice	0.50	t	\N	2025-12-13 18:26:25.243971+00
1106	3	What is the main purpose of a data visualization in business?	single_choice	0.50	t	\N	2025-12-13 18:26:30.334574+00
1107	3	Which chart is usually best to compare values across categories?	single_choice	0.50	t	\N	2025-12-13 18:26:30.334574+00
1108	3	Which chart is usually best to show a trend over time?	single_choice	0.50	t	\N	2025-12-13 18:26:30.334574+00
1109	3	What does a KPI (key performance indicator) represent?	single_choice	0.50	t	\N	2025-12-13 18:26:30.334574+00
1110	3	Which is a good practice for chart titles?	single_choice	0.50	t	\N	2025-12-13 18:26:30.334574+00
1111	3	What does the x-axis usually represent in a time series chart?	single_choice	0.50	t	\N	2025-12-13 18:26:30.334574+00
1112	3	Which is a common problem with 3D bar charts?	single_choice	0.50	t	\N	2025-12-13 18:26:30.334574+00
1113	3	What is a legend used for?	single_choice	0.50	t	\N	2025-12-13 18:26:30.334574+00
1114	3	Which of these is usually best for part-to-whole at a single point in time (few categories)?	single_choice	0.50	t	\N	2025-12-13 18:26:30.334574+00
1115	3	What is 'data-ink' in a chart?	single_choice	0.50	t	\N	2025-12-13 18:26:30.334574+00
1116	3	Which is an example of categorical data?	single_choice	0.50	t	\N	2025-12-13 18:26:30.334574+00
1117	3	Which is an example of quantitative data?	single_choice	0.50	t	\N	2025-12-13 18:26:30.334574+00
1118	3	What does 'annotation' mean in a chart?	single_choice	0.50	t	\N	2025-12-13 18:26:30.334574+00
1119	3	What is the main job of an axis label?	single_choice	0.50	t	\N	2025-12-13 18:26:30.334574+00
1120	3	Which is a good rule for using colors in dashboards?	single_choice	0.50	t	\N	2025-12-13 18:26:30.334574+00
1121	3	Which chart is best to show the relationship between two numeric variables?	single_choice	0.50	t	\N	2025-12-13 18:26:30.334574+00
1122	3	What does a filter do in a dashboard?	single_choice	0.50	t	\N	2025-12-13 18:26:30.334574+00
1123	3	What is a 'dashboard' in business analytics?	single_choice	0.50	t	\N	2025-12-13 18:26:30.334574+00
1124	3	Which is a good reason to sort bars by value?	single_choice	0.50	t	\N	2025-12-13 18:26:30.334574+00
1125	3	What does 'trend' mean?	single_choice	0.50	t	\N	2025-12-13 18:26:30.334574+00
1126	3	Which chart is commonly used to show distribution of a numeric variable?	single_choice	0.50	t	\N	2025-12-13 18:26:30.334574+00
1127	3	What is the main purpose of a gridline in a chart?	single_choice	0.50	t	\N	2025-12-13 18:26:30.334574+00
1128	3	What is a common best practice for gridlines?	single_choice	0.50	t	\N	2025-12-13 18:26:30.334574+00
1129	3	What does 'outlier' mean?	single_choice	0.50	t	\N	2025-12-13 18:26:30.334574+00
1130	3	Which visualization is a common way to show a part-to-whole breakdown with many categories?	single_choice	0.50	t	\N	2025-12-13 18:26:30.334574+00
1131	3	Which statement about pie charts is usually correct?	single_choice	0.50	t	\N	2025-12-13 18:26:30.334574+00
1132	3	What is a 'data label'?	single_choice	0.50	t	\N	2025-12-13 18:26:30.334574+00
1133	3	What does 'interactive' mean in a dashboard context?	single_choice	0.50	t	\N	2025-12-13 18:26:30.334574+00
1134	3	Which is a good first step before choosing a chart type?	single_choice	0.50	t	\N	2025-12-13 18:26:30.334574+00
1135	3	What does a bar length represent in a standard bar chart?	single_choice	0.50	t	\N	2025-12-13 18:26:30.334574+00
1136	3	Which axis usually shows the measured values in a vertical bar chart?	single_choice	0.50	t	\N	2025-12-13 18:26:30.334574+00
1137	3	What is the purpose of a tooltip in many dashboards?	single_choice	0.50	t	\N	2025-12-13 18:26:30.334574+00
1138	3	Which visualization is often used to show geographic patterns?	single_choice	0.50	t	\N	2025-12-13 18:26:30.334574+00
1139	3	What is a choropleth map?	single_choice	0.50	t	\N	2025-12-13 18:26:30.334574+00
1140	3	Which is a good practice for units in a dashboard?	single_choice	0.50	t	\N	2025-12-13 18:26:30.334574+00
1141	3	Which chart is commonly used to show a process over time with start and end dates for tasks?	single_choice	0.50	t	\N	2025-12-13 18:26:30.334574+00
1142	3	Which is a common advantage of a line chart?	single_choice	0.50	t	\N	2025-12-13 18:26:30.334574+00
1143	3	Which chart is usually best for ranking categories from highest to lowest?	single_choice	0.50	t	\N	2025-12-13 18:26:30.334574+00
1144	3	What is a 'baseline' in a bar chart?	single_choice	0.50	t	\N	2025-12-13 18:26:30.334574+00
1145	3	What does 'correlation' describe in a scatter plot context?	single_choice	0.50	t	\N	2025-12-13 18:26:30.334574+00
1146	3	Which statement is true about correlation and causation?	single_choice	0.50	t	\N	2025-12-13 18:26:30.334574+00
1147	3	What is a 'distribution'?	single_choice	0.50	t	\N	2025-12-13 18:26:30.334574+00
1148	3	Which is a common way to summarize a distribution quickly?	single_choice	0.50	t	\N	2025-12-13 18:26:30.334574+00
1149	3	What does 'median' mean?	single_choice	0.50	t	\N	2025-12-13 18:26:30.334574+00
1150	3	What does 'mean' mean?	single_choice	0.50	t	\N	2025-12-13 18:26:30.334574+00
1152	3	What is 'drill-down' in dashboards?	single_choice	0.50	t	\N	2025-12-13 18:26:30.334574+00
1153	3	What is 'aggregation'?	single_choice	0.50	t	\N	2025-12-13 18:26:30.334574+00
1154	3	Which is an example of aggregation?	single_choice	0.50	t	\N	2025-12-13 18:26:30.334574+00
1155	3	What is a good practice for readable dashboards?	single_choice	0.50	t	\N	2025-12-13 18:26:30.334574+00
1156	3	What does 'whitespace' help with in dashboards?	single_choice	0.50	t	\N	2025-12-13 18:26:30.334574+00
1157	3	Which is a common use for a table in a dashboard?	single_choice	0.50	t	\N	2025-12-13 18:26:30.334574+00
1158	3	Which is usually easier for humans: comparing bar lengths or comparing pie slice angles?	single_choice	0.50	t	\N	2025-12-13 18:26:30.334574+00
1159	3	What is a 'scale' in a chart?	single_choice	0.50	t	\N	2025-12-13 18:26:30.334574+00
1160	3	What does a 'categorical color palette' represent?	single_choice	0.50	t	\N	2025-12-13 18:26:30.334574+00
1161	3	What does a 'sequential color palette' represent?	single_choice	0.50	t	\N	2025-12-13 18:26:30.334574+00
1162	3	Which is a good reason to use a divergent color palette?	single_choice	0.50	t	\N	2025-12-13 18:26:30.334574+00
1163	3	What is a common benefit of consistent color meaning across dashboards?	single_choice	0.50	t	\N	2025-12-13 18:26:30.334574+00
1164	3	What is a 'metric definition'?	single_choice	0.50	t	\N	2025-12-13 18:26:30.334574+00
1165	3	Which is a good practice to avoid confusion with percentages?	single_choice	0.50	t	\N	2025-12-13 18:26:30.334574+00
1166	3	What is the main purpose of a dashboard filter like 'Last 30 days'?	single_choice	0.50	t	\N	2025-12-13 18:26:30.334574+00
1167	3	Which is a common way to reduce clutter in a chart?	single_choice	0.50	t	\N	2025-12-13 18:26:30.334574+00
1168	3	What is a common problem with too many categories in one pie chart?	single_choice	0.50	t	\N	2025-12-13 18:26:30.334574+00
1169	3	Which is a good alternative to a pie chart with many categories?	single_choice	0.50	t	\N	2025-12-13 18:26:30.334574+00
1170	3	What does 'benchmark' mean in reporting?	single_choice	0.50	t	\N	2025-12-13 18:26:30.334574+00
1171	3	What is a 'target' in KPI reporting?	single_choice	0.50	t	\N	2025-12-13 18:26:30.334574+00
1172	3	Which chart is commonly used to show parts of a total over time?	single_choice	0.50	t	\N	2025-12-13 18:26:30.334574+00
1173	3	What is a common use of a box plot?	single_choice	0.50	t	\N	2025-12-13 18:26:30.334574+00
1174	3	Why is labeling axes important?	single_choice	0.50	t	\N	2025-12-13 18:26:30.334574+00
1175	3	Which is a good practice for decimals in KPI cards?	single_choice	0.50	t	\N	2025-12-13 18:26:30.334574+00
1176	3	What is the purpose of a reference line in a chart?	single_choice	0.50	t	\N	2025-12-13 18:26:30.334574+00
1177	3	Which visualization is best to show a simple yes/no status for a few items?	single_choice	0.50	t	\N	2025-12-13 18:26:30.334574+00
1178	3	What does 'real-time' usually mean in dashboards?	single_choice	0.50	t	\N	2025-12-13 18:26:30.334574+00
1179	3	Which is a good practice for dashboard layout?	single_choice	0.50	t	\N	2025-12-13 18:26:30.334574+00
1180	3	What does 'drill-through' usually mean?	single_choice	0.50	t	\N	2025-12-13 18:26:30.334574+00
1181	3	Which is a reason to keep a consistent font style in dashboards?	single_choice	0.50	t	\N	2025-12-13 18:26:30.334574+00
1182	3	What is a 'time window' in reporting?	single_choice	0.50	t	\N	2025-12-13 18:26:30.334574+00
1183	3	What is the main purpose of a dashboard 'overview' page?	single_choice	0.50	t	\N	2025-12-13 18:26:30.334574+00
1184	3	Which is a common KPI example in e-commerce?	single_choice	0.50	t	\N	2025-12-13 18:26:30.334574+00
1185	3	Which chart is best to show a single value compared to a target?	single_choice	0.50	t	\N	2025-12-13 18:26:30.334574+00
1186	3	What is a common issue with gauge charts when used too much?	single_choice	0.50	t	\N	2025-12-13 18:26:30.334574+00
1187	3	What is the purpose of a subtitle in a chart or dashboard?	single_choice	0.50	t	\N	2025-12-13 18:26:30.334574+00
1188	3	Which is a good practice for naming metrics?	single_choice	0.50	t	\N	2025-12-13 18:26:30.334574+00
1189	3	What is 'refresh rate' in dashboards?	single_choice	0.50	t	\N	2025-12-13 18:26:30.334574+00
1190	3	What is a good way to show a sharp change or anomaly in a time series?	single_choice	0.50	t	\N	2025-12-13 18:26:30.334574+00
1191	3	What does 'sorting' mean in a chart?	single_choice	0.50	t	\N	2025-12-13 18:26:30.334574+00
1192	3	Which is a common reason to use a horizontal bar chart?	single_choice	0.50	t	\N	2025-12-13 18:26:30.334574+00
1193	3	What is a 'category' in a bar chart?	single_choice	0.50	t	\N	2025-12-13 18:26:30.334574+00
1194	3	What is a 'metric'?	single_choice	0.50	t	\N	2025-12-13 18:26:30.334574+00
1195	3	What is a good use of a line chart with two lines?	single_choice	0.50	t	\N	2025-12-13 18:26:30.334574+00
1196	3	Which is a good practice for legends?	single_choice	0.50	t	\N	2025-12-13 18:26:30.334574+00
1197	3	What is 'drill-up' in dashboards?	single_choice	0.50	t	\N	2025-12-13 18:26:30.334574+00
1198	3	Which is a common goal of data storytelling?	single_choice	0.50	t	\N	2025-12-13 18:26:30.334574+00
1199	3	What is a 'callout' in a chart?	single_choice	0.50	t	\N	2025-12-13 18:26:30.334574+00
1200	3	Which chart is usually best to show proportions of a whole across time?	single_choice	0.50	t	\N	2025-12-13 18:26:30.334574+00
1201	3	What is a good reason to add a short data source note?	single_choice	0.50	t	\N	2025-12-13 18:26:30.334574+00
1202	3	What is the main purpose of a dashboard 'filter panel'?	single_choice	0.50	t	\N	2025-12-13 18:26:30.334574+00
1203	3	What is a 'time series'?	single_choice	0.50	t	\N	2025-12-13 18:26:30.334574+00
1204	3	Which of these is a good default chart for showing change over time?	single_choice	0.50	t	\N	2025-12-13 18:26:30.334574+00
1568	1	115. Which three essential aspects of cloud security form the foundation of the CIA triad?	single_choice	0.50	t	\N	2025-12-15 13:59:48.153009+00
1569	1	116. \vWhich definition best describes a firewall?	single_choice	0.50	t	\N	2025-12-15 13:59:48.153009+00
1570	1	117. What is Google Cloud’s modern and serverless data warehousing solution?	single_choice	0.50	t	\N	2025-12-15 13:59:48.153009+00
1571	1	118. What is Google Cloud’s distributed messaging service that can receive messages from various device streams such as gaming events, Internet of Things (IoT) devices, and application streams?	single_choice	0.50	t	\N	2025-12-15 13:59:48.153009+00
\.


--
-- Data for Name: question_option; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.question_option (id, question_id, option_text, is_correct, order_index) FROM stdin;
1	106	Reliability of the infrastructure availability.	f	1
2	106	Total cost of ownership of the infrastructure.	f	2
3	106	Scalability of infrastructure to needs.	f	3
4	106	Flexibility of infrastructure configuration.	t	4
5	107	Budgeting will only happen on an annual basis.	f	1
6	107	They will only pay for what they forecast.	f	2
7	107	Hardware procurement is done by a centralized team.	f	3
8	107	They will only pay for what they use.	t	4
9	108	Using the edge network to cache the whole application image in a backup.	f	1
10	108	By assigning a different IP address to each resource.	f	2
11	108	By putting resources in the Domain Name System (DNS).	f	3
12	108	By putting resources in different zones.	t	4
13	109	The customer is responsible for securing anything that they create within the cloud, such as the configurations, access policies, and user data.	t	1
14	109	The customer is responsible for security of the operating system, software stack required to run their applications and any hardware, networks, and physical security.	f	2
15	109	The customer is not responsible for any of the data in the cloud, as data management is the responsibility of the cloud provider who is hosting the data.	f	3
16	109	The customer is responsible for all infrastructure decisions, server configurations and database monitoring.	f	4
17	110	It's cost-effective, as all infrastructure costs are handled under a single monthly or annual subscription fee.	f	1
18	110	It’s efficient, as IaaS resources are available when needed and resources aren’t wasted by overbuilding capacity.	t	2
19	110	It reduces development time, as developers can go straight to coding instead of spending time setting up and maintaining a development environment.	f	3
20	110	It has low management overhead, as all administration and management tasks for data, servers, storage, and updates are handled by the cloud vendor.	f	4
21	111	Infrastructure as a Service (IaaS)	f	1
22	111	Software as a Service (SaaS)	f	2
23	111	Function as a Service (FaaS)	f	3
24	111	Platform as a Service (PaaS)	t	4
25	112	Software as a Service (SaaS)	t	1
26	112	IT as a service (ITaaS)	f	2
27	112	Infrastructure as a Service (IaaS)	f	3
28	112	Platform as a Service (PaaS)	f	4
29	113	A type of artificial intelligence that can create and sustain its own consciousness.	f	1
30	113	A type of artificial intelligence that can make decisions and take actions.	f	2
31	113	A type of artificial intelligence that can understand and respond to human emotions.	f	3
32	113	A type of artificial intelligence that can produce new content, including text, images, audio, and synthetic data.	t	4
33	114	Segmenting images into different parts or regions to extract information, such as the text on a sign.	f	1
34	114	Identifying the artist, title, or genre of a song to create playlists based on the user's listening habits.	f	2
35	114	Detecting people and objects in surveillance footage to use as evidence in criminal cases.	f	3
36	114	Identifying the topic and sentiment of customer email messages so that they can be routed to the relevant department.	t	4
37	115	Whether all the required information is present.	f	1
38	115	Whether the data is uniform and doesn’t contain any contradictory information.	t	2
39	115	Whether the data is up-to-date and reflects the current state of the phenomenon that is being modeled.	f	3
40	115	Whether a dataset is free from duplicate values that could prevent an ML model from learning accurately.	f	4
41	116	Content moderation	f	1
42	116	Clickbait detection	f	2
43	116	Video transcription	f	3
44	116	Personalized recommendations	t	4
45	117	AI should create unfair bias.	f	1
46	117	Google makes tools that empower others to harness AI for individual and collective benefit.	t	2
47	117	AI should gather or use information for surveillance.	f	3
48	117	Google makes tools that uphold high standards of operational excellence.	f	4
49	118	Machine learning	f	1
50	118	Artificial intelligence	t	2
51	118	Deep learning	f	3
52	118	Natural language processing	f	4
53	119	Implementing AI to develop a new product or service that has never been seen before.	f	1
54	119	Training a machine learning model to predict a search result ranking.	t	2
55	119	Using AI to replace a human decision-maker in complex situations, such as those involving life-or-death choices.	f	3
56	119	Using a reinforcement learning algorithm to train autonomous drones for package delivery.	f	4
57	120	Data analytics and business intelligence are used only in small businesses, whereas AI and ML are used exclusively by large corporations.	f	1
58	120	Data analytics and business intelligence identify trends from historical data, whereas AI and ML use data to make decisions for future business.	t	2
59	120	Data analytics and business intelligence use automated decision-making processes, whereas AI and ML require human intervention and interpretation of data.	f	3
60	120	Data analytics and business intelligence involve advanced algorithms for predicting future trends, whereas AI and ML focus on processing historical data.	f	4
61	121	Vision API	t	1
62	121	Natural Language API	f	2
63	121	Video Intelligence API	f	3
64	121	Speech-to-Text API	f	4
65	122	Discovery AI for Retail	f	1
66	122	Document AI	t	2
67	123	Contact Center AI	t	1
68	123	Document AI	f	2
69	124	Graphic Processing Unit (GPU)	f	1
70	124	Tensor Processing Unit (TPU)	t	2
71	124	Central Processing Unit (CPU)	f	3
72	124	Vertex Processing Unit (VPU)	f	4
73	125	Video Intelligence API	f	1
74	125	Vision API	f	2
75	125	Natural Language API	t	3
76	125	Speech-to-Text API	f	4
4373	1205	Reliability of the infrastructure availability.	f	1
4374	1205	Total cost of ownership of the infrastructure.	f	2
4375	1205	Scalability of infrastructure to needs.	f	3
80	127	BigQuery ML	f	1
81	127	AutoML	f	2
82	127	Custom training	t	3
83	127	Pre-trained APIs	f	4
84	128	Managed ML environment	f	1
85	128	AutoML	t	2
86	128	MLOps	f	3
87	128	Modernize Infrastructure and Applications with Google Cloud	f	4
88	129	Reliability	t	1
89	129	Total cost of ownership	f	2
90	130	Traditional on-premises computing	f	1
91	130	Serverless computing	t	2
92	130	PaaS (platform as a service)	f	3
93	130	IaaS (infrastructure as a service)	f	4
94	131	Software layers above the firmware level	f	1
95	131	Software layers above the operating system level	t	2
96	131	Hardware layers above the electrical level	f	3
97	131	The entire machine	f	4
98	132	Move and improve	f	1
99	132	Refactor and reshape	f	2
100	132	Lift and shift	t	3
101	132	Reimagine and plan	f	4
102	133	Build and deploy	f	1
103	133	Move and improve	f	2
104	133	Lift and shift	t	3
105	133	Install and fall	f	4
106	134	Programming communication	f	1
107	134	Application programming interface	t	2
108	134	Communication link interface	f	3
109	134	Network programming interface	f	4
110	135	Microservices	t	1
111	135	DevOps	f	2
112	136	Bare metal solution	t	1
113	136	SQL Server on Google Cloud	f	2
114	136	Google Cloud VMware Engine	f	3
115	136	AppEngine	f	4
116	137	Hybrid cloud	f	1
117	137	Multicloud	t	2
118	137	Edge cloud	f	3
119	137	Community cloud	f	4
120	138	Secure cloud	f	1
121	138	Hybrid cloud	t	2
122	138	Smart cloud	f	3
123	139	Configuring the customer's applications.	f	1
124	139	Maintaining the customer's infrastructure.	t	2
125	139	Securing the customer's data.	f	3
126	139	Managing the customer's user access.	f	4
127	140	Large upfront capital investment.	f	1
128	140	Having physical access to hardware.	f	2
129	140	Only having to install security updates on a weekly basis.	f	3
130	140	Increased scalability.	t	4
131	141	Certificates, intelligence, and authentication	f	1
132	141	Confidentiality, integrity, and availability	t	2
133	141	Compliance, identity, and access management	f	3
134	141	Containers, infrastructure, and architecture	f	4
135	142	A network security device that monitors and controls incoming and outgoing network traffic based on predefined security rules	t	1
136	142	A set of security measures designed to protect a computer system or network from cyber attacks	f	2
137	142	A software program that encrypts data to make it unreadable to unauthorized users	f	3
138	142	A security model that assumes no user or device can be trusted by default	f	4
139	143	Security by default	f	1
140	143	Privileged access	f	2
141	143	Zero-trust architecture	f	3
142	143	Least privilege	t	4
143	144	Zero trust security	f	1
144	144	Cloud security posture management (CSPM)	f	2
145	144	Site reliability engineering (SRE)	f	3
146	144	Security operations (SecOps)	t	4
147	145	Lattice-Based Cryptography (LBC)	f	1
148	145	Post-quantum cryptography (PQC)	f	2
149	145	Advanced Encryption Standard (AES)	t	3
150	145	Isomorphic encryption (IE)	f	4
151	146	IAM provides granular control over who has access to Google Cloud resources and what they can do with those resources.	t	1
152	146	IAM is a cloud service that encrypts cloud-based data at rest and in transit.	f	2
153	146	IAM is a cloud security information and event management solution that collects and analyzes log data from cloud security devices and applications.	f	3
154	147	Data Center Infrastructure Efficiency (DCiE)	f	1
155	147	Power Usage Effectiveness (PUE)	t	2
156	147	Energy Efficiency Ratio (EER)	f	3
157	147	Total cost of ownership (TCO)	f	4
158	148	Data in transit	f	1
159	148	Data lake	f	2
160	148	Data in use	t	3
161	148	Data at rest	f	4
162	149	Security information and event management (SIEM)	f	1
163	149	Firewall as a service (FaaS)	f	2
164	149	Data loss prevention (DLP)	f	3
165	149	Two-step verification (2SV)	t	4
166	149	Trust and Security with Google Cloud	f	5
167	150	Google Cloud console	f	1
168	150	Cloud Storage client libraries	f	2
169	150	Compliance resource center	t	3
170	151	Compliance reports	f	1
171	151	Billing reports	f	2
172	151	Transparency reports	t	3
173	151	Security reports	f	4
174	152	All customer data is encrypted by default.	t	1
175	152	We give "backdoor" access to government entities when requested.	f	2
176	152	Google sells customer data to third parties.	f	3
177	152	Google Cloud uses customer data for advertising.	f	4
178	153	Data consistency	f	1
179	153	Data redundancy	f	2
180	153	Data sovereignty	t	3
181	153	Data residency	f	4
182	154	Competency center	f	1
183	154	Center of innovation	f	2
184	154	Center of excellence	t	3
185	154	Hub center	f	4
186	155	Resources	t	1
187	155	Organization node	f	2
188	156	Cost forecasting	f	1
189	156	Cloud billing reports	t	2
190	156	Resource usage	f	3
191	157	Inheritance in the hierarchy reduces the overall cost of cloud computing.	f	1
192	157	Faster propagation can simplify a cloud migration.	f	2
193	157	Resources at lower levels can improve the performance of cloud applications.	f	3
194	157	Permissions set at higher levels of the resource hierarchy are automatically inherited by lower-level resources.	t	4
195	158	Billing reports	f	1
196	158	Invoicing limits	f	2
197	158	Quota policies	t	3
198	158	Committed use discounts	f	4
199	159	Budget threshold rules	t	1
200	159	Billing reports	f	2
201	159	Cost optimization recommendations	f	3
202	159	Cost forecasting	f	4
4376	1205	Flexibility of infrastructure configuration.	t	4
204	160	Site reliability engineer	t	1
205	160	Cloud architect	f	2
206	160	DevOps engineer	f	3
207	160	Cloud security engineer	f	4
208	161	It provides a comprehensive view of your cloud infrastructure and applications.	f	1
209	161	It identifies how much CPU power, memory, and other resources an application uses.	t	2
210	161	It collects and stores all application and infrastructure logs.	f	3
211	161	It counts, analyzes, and aggregates the crashes in running cloud services in real-time.	f	4
212	162	How long it takes for a particular part of a system to return a result.	t	1
213	162	How close to capacity a system is.	f	2
214	162	How many requests reach a system.	f	3
215	162	System failures or other issues.	f	4
216	163	It duplicates critical components or resources to provide backup alternatives.	f	1
217	163	It monitors and controls incoming and outgoing network traffic based on predetermined security rules.	f	2
218	163	It scales infrastructure to handle varying workloads and accommodate increased demand.	f	3
219	163	It creates multiple copies of data or services and distributes them across different servers or locations.	t	4
220	164	Service level contracts	f	1
221	164	Service level indicators	t	2
222	164	Service level objectives	f	3
223	164	Service level agreements	f	4
224	165	Backups	t	1
225	165	Security patches	f	2
226	165	Inventory data	f	3
227	165	Log files	f	4
228	166	It uses BigQuery and Looker Studio to build and deploy machine learning models.	f	1
229	166	It uses BigQuery and Looker Studio to create dashboards that provide granular operational insights.	t	2
230	166	It uses BigQuery and Looker Studio to containerize workloads.	f	3
231	166	It uses BigQuery and Looker Studio to comply with government regulations.	f	4
232	167	To be the first major company to operate completely carbon free.	t	1
233	167	To be the first major company to run its own wind farm.	f	2
234	167	To be the first major company to be carbon neutral.	f	3
235	167	To be the first major company to achieve 100% renewable energy.	f	4
236	168	It’s a framework for sustainable procurement, which is the process of purchasing goods and services in a way that minimizes environmental and social impacts.	f	1
237	168	It’s a framework for identifying, predicting, and evaluating the environmental impacts of a proposed project.	f	2
238	168	It’s a framework for an organization to enhance its environmental performance through improving resource efficiency and reducing waste.	t	3
239	168	It’s a framework for carbon footprinting that calculates the total amount of greenhouse gas emissions associated with a product, service, or organization.	f	4
240	169	It's cost effective, so the organization will no longer have to pay for computing once the app is in the cloud.	t	1
241	169	It's scalable, so the organization could shorten their infrastructure deployment time.	f	2
242	169	It provides physical access, so the organization can deploy servers faster.	f	3
243	169	It's secure, so the organization won't have to worry about the new subscribers data.	f	4
244	170	Software as a service	f	1
245	170	Public Cloud	f	2
246	170	Private Cloud	t	3
247	170	Platform as a service	f	4
248	171	Open source software makes it easier to patent proprietary software.	f	1
249	171	Open standards make it easier to hire more developers.	f	2
250	171	Open source software reduces the chance of vendor lock-in.	t	3
251	171	On-premises software isn't open source, so cloud applications are more portable.	f	4
252	172	Sustainable cloud ensures the costs of cloud resources are controlled to prevent budget overrun.	f	1
253	172	A trusted cloud gives control of all resources to the user to ensure high availability at all times.	f	2
254	172	Data cloud provides a unified solution to manage data across the entire data lifecycle.	t	3
255	172	Open infrastructure gives the freedom to innovate by running applications in the place that makes the most sense.	t	4
256	173	Organizations risk losing market leadership if they spend too much time on digital transformation.	f	1
257	173	Embracing new technology can cause organizations to overspend on innovation.	f	2
258	173	Focusing on ‘why’ they operate can lead to inefficient use of resources and disruption.	f	3
259	173	Focusing on ‘how’ they operate can prevent organizations from seeing transformation opportunities.	t	4
260	174	Maintenance workers do not have physical access to the servers.	f	1
261	174	Scaling processing is too difficult due to power consumption.	f	2
262	174	The on-premises networking is more complicated.	f	3
263	174	The on-premises hardware procurement process can take a long time.	t	4
264	175	A Google product for computing large amounts of data.	f	1
265	175	A metaphor for the networking capability of internet providers.	f	2
266	175	A metaphor for a network of data centers.	t	3
267	175	A Google product made up of on-premises IT infrastructure.	f	4
268	176	Ensure better security by decoupling teams and their data.	f	1
269	176	Break down data silos and generate real time insights.	t	2
270	176	Streamline their hardware procurement process to forecast at least a quarter into the future.	f	3
271	176	Reduce emissions by using faster networks in their on-premises workloads.	f	4
272	177	When an organization uses new digital technologies to create or modify on-premises business processes.	f	1
273	177	When an organization uses new digital technologies to create or modify technology infrastructure to focus on cost saving.	f	2
274	177	When an organization uses new digital technologies to create or modify business processes, culture, and customer experiences.	t	3
275	177	When an organization uses new digital technologies to create or modify financial models for how a business is run.	f	4
276	178	The process of collecting and storing data for future use	f	1
277	178	The process of analyzing data to gain insights and make informed decisions	f	2
278	178	The process of setting internal data policies and ensuring compliance with external standards	t	3
279	178	The process of deleting unnecessary data to save storage space	f	4
280	179	A relational database	t	1
281	179	An XML database	f	2
282	179	An object database	f	3
283	179	A non-relational database	f	4
284	180	Google Cloud Marketplace	t	1
285	180	App Engine	f	2
286	180	Google Cloud console	f	3
287	180	Google Play	f	4
288	181	Semi-structured data	f	1
289	181	Unstructured data	f	2
290	181	Structured data	t	3
291	181	A hybrid of structured, semi-structured, and unstructured data	f	4
292	182	Cloud Storage	f	1
293	182	Compute Engine	f	2
294	182	BigQuery	t	3
295	182	Vertex AI	f	4
296	183	Data lake	t	1
297	183	Data warehouse	f	2
298	183	Database	f	3
299	183	Data archive	f	4
300	184	Through machine learning, with every click that the user makes, their website experience becomes increasingly personalized.	t	1
301	184	Machine learning can be used to make all users see the same product recommendations, regardless of their preferences or behavior.	f	2
302	184	Machine learning can help identify user behavior in real time, but cannot make personalized suggestions based on the data.	f	3
303	184	Through machine learning, a user’s credit card transactions can be analyzed to determine regular purchases.	f	4
304	185	Data analysis	f	1
305	185	Data processing	t	2
306	185	Data storage	f	3
307	185	Data genesis	f	4
308	186	Using GPS coordinates to power a ride-sharing app	f	1
309	186	Analyzing historical sales figures to predict future trends	f	2
310	186	Creating visualizations from seasonal weather data	f	3
311	186	Analyzing social media posts to identify sentiment toward a brand	t	4
312	187	Second-party data	f	1
313	187	Third-party data	f	2
314	187	First-party data	t	3
315	188	Accessibility only within one region	f	1
316	188	Geo-redundancy if data is stored in a multi-region or dual-region	t	2
317	188	Maximum storage limits	f	3
318	188	High latency and low durability	f	4
319	189	Storage and analytics	t	1
320	189	Compute and analytics	f	2
321	189	Migration and analytics	f	3
322	189	Networking and storage	f	4
323	190	Dataprep	f	1
324	190	Datastream	t	2
325	190	Pub/Sub	f	3
326	190	Dataproc	f	4
327	191	Cloud SQL	f	1
328	191	Bigtable	f	2
329	191	Firestore	f	3
330	191	Spanner	t	4
331	192	Looker	f	1
332	192	Pub/Sub	t	2
333	192	Dataproc	f	3
334	192	Dataplex	f	4
335	193	Lift and shift	t	1
336	193	Refactoring	f	2
337	193	Managed database migration	f	3
338	193	Remain on-premises	f	4
339	194	It supports over 60 different SQL databases.	f	1
340	194	It’s cost effective.	f	2
341	194	It’s 100% web based.	t	3
342	194	It creates easy to understand visualizations.	f	4
343	195	Archive	f	1
344	195	Coldline	t	2
345	195	Standard	f	3
346	195	Nearline	f	4
347	196	Dataplex	f	1
348	196	Cloud Storage	f	2
349	196	Looker	t	3
350	196	Dataflow	f	4
351	197	Cloud Storage	t	1
352	197	Cloud SQL	f	2
353	197	Firestore	f	3
354	197	BigQuery	f	4
355	198	Medical test results	f	1
356	198	Payroll records	f	2
357	198	Customer email addresses	f	3
358	198	Temperature sensors	t	4
359	199	Spanner	f	1
360	199	Cloud SQL	f	2
361	199	Bigtable	t	3
362	199	Cloud Storage	f	4
363	200	Enhanced transaction logic	f	1
364	200	Event-time logic	f	2
365	200	Extract, transform, and load	t	3
366	200	Enrichment, tagging, and labeling	f	4
367	201	Cloud Storage	f	1
368	201	Spanner	f	2
369	201	Bigtable	f	3
370	201	Cloud SQL	t	4
371	202	It’s a cloud-based data warehouse for storing and analyzing streaming and batch data.	f	1
372	202	It’s a messaging service for receiving messages from various device streams.	f	2
373	202	It handles infrastructure setup and maintenance for processing pipelines.	t	3
374	202	It allows easy data cleaning and transformation through visual tools and machine learning-based suggestions.	f	4
375	203	Security is more effective when BigQuery is run in on-premises environments.	f	1
376	203	Data teams can eradicate data silos by analyzing data across multiple cloud providers.	t	2
377	203	BigQuery lets organizations save costs by limiting the number of cloud providers they use.	f	3
378	203	Multicloud support in BigQuery is only intended for use in disaster recovery scenarios.	f	4
379	204	Kubernetes	t	1
380	204	Go	f	2
381	204	TensorFlow	f	3
382	204	Angular	f	4
383	205	Containers	f	1
384	205	Virtual machine instances	t	2
385	205	Colocation	f	3
386	205	A local development environment	f	4
387	206	Software layers above the operating system level	t	1
388	206	The entire machine	f	2
389	206	Software layers above the firmware level	f	3
390	206	Hardware layers above the electrical level	f	4
391	207	Security	f	1
392	207	Total cost of ownership	f	2
393	207	Flexibility	f	3
394	207	Reliability	t	4
395	208	Traditional on-premises computing	f	1
396	208	PaaS (platform as a service)	f	2
397	208	IaaS (infrastructure as a service)	f	3
398	208	Serverless computing	t	4
399	209	Monoliths	f	1
400	209	Containers	f	2
401	209	DevOps	f	3
402	209	Microservices	t	4
403	210	Programming communication link	f	1
404	210	Network programming interface	f	2
405	210	Communication link interface	f	3
406	210	Application programming interface	t	4
407	211	Lift and shift	t	1
408	211	Build and deploy	f	2
409	211	Move and improve	f	3
410	211	Install and fall	f	4
411	212	Hybrid cloud	t	1
412	212	Secure cloud	f	2
413	212	Smart cloud	f	3
414	212	Multicloud	f	4
415	213	Bare metal solution	t	1
416	213	App Engine	f	2
417	213	SQL Server on Google Cloud	f	3
418	213	Google Cloud VMware Engine	f	4
419	214	Containers	f	1
420	214	DevOps	f	2
421	214	Cloud security	f	3
422	214	Managed services	t	4
423	215	Container Registry	f	1
424	215	Google Kubernetes Engine	f	2
425	215	Knative	f	3
426	215	GKE Enterprise	t	4
427	216	By developing new products and services internally	f	1
428	216	By allowing developers to access their data for free	f	2
429	216	By using APIs to track customer shipments	f	3
430	216	By charging developers to access their APIs	t	4
431	217	Apigee	t	1
432	217	AppSheet	f	2
433	217	App Engine	f	3
434	217	Cloud API Manager	f	4
435	218	Hybrid cloud	f	1
436	218	Community cloud	f	2
437	218	Multicloud	t	3
438	218	Edge cloud	f	4
439	219	Ransomware	t	1
440	219	Spyware	f	2
441	219	Virus	f	3
442	219	Trojan	f	4
443	219	Which cybersecurity threat demands a ransom payment from a victim to regain access to their files and systems.	f	5
448	221	Increased scalability.	t	1
449	221	Only having to install security updates on a weekly basis.	f	2
450	221	Having physical access to hardware.	f	3
451	221	Large upfront capital investment.	f	4
452	222	Configuring the customer's applications.	f	1
453	222	Securing the customer's data.	f	2
454	222	Managing the customer's user access.	f	3
455	222	Maintaining the customer's infrastructure.	t	4
456	223	Integrity	f	1
457	223	Confidentiality	f	2
458	223	Control	f	3
459	223	Compliance	t	4
460	224	Least privilege	t	1
461	224	Zero-trust architecture	f	2
462	224	Privileged access	f	3
463	224	Security by default	f	4
464	225	Configuration mishaps	t	1
465	225	Phishing	f	2
466	225	Virus	f	3
467	225	Malware	f	4
468	226	Ransomware	f	1
469	226	Malware	f	2
470	226	Phishing	t	3
471	226	Configuration mishap	f	4
472	227	Confidentiality	f	1
473	227	Compliance	f	2
474	227	Integrity	t	3
475	227	Control	f	4
476	228	Certificates, intelligence, and authentication	f	1
477	228	Compliance, identity, and access management	f	2
478	228	Containers, infrastructure, and architecture	f	3
479	228	Confidentiality, integrity, and availability	t	4
480	229	A software program that encrypts data to make it unreadable to unauthorized users	f	1
481	229	A security model that assumes no user or device can be trusted by default	f	2
482	229	A network security device that monitors and controls incoming and outgoing network traffic based on predefined security rules	t	3
483	229	A set of security measures designed to protect a computer system or network from cyber attacks	f	4
488	231	Looker	f	1
489	231	Pub/Sub	t	2
490	231	Dataproc	f	3
491	231	Dataplex	f	4
77	126	Build and evaluate machine learning models in BigQuery by using SQL.	t	1
78	126	Export small amounts of data to spreadsheets or other applications.	f	2
79	126	Seamlessly connect with a data science team to create an ML model.	f	3
492	126	Improve reliability by ignoring data null values	f	4
444	220	Increased scalability	t	1
445	220	Only having to install security updates on a weekly basis.	f	2
446	220	Having physical access to hardware.	f	3
447	220	Large upfront capital investment.	f	4
484	230	Cloud Storage	f	1
485	230	Compute Engine	f	2
486	230	BigQuery	t	3
487	230	Vertex AI	f	4
4377	1206	Budgeting will only happen on an annual basis.	f	1
4378	1206	They will only pay for what they forecast.	f	2
4379	1206	Hardware procurement is done by a centralized team.	f	3
4380	1206	They will only pay for what they use.	t	4
4381	1207	Using the edge network to cache the whole application image in a backup.	f	1
4382	1207	By assigning a different IP address to each resource.	f	2
4383	1207	By putting resources in the Domain Name System (DNS).	f	3
4384	1207	By putting resources in different zones.	t	4
4385	1208	The customer is responsible for securing anything that they create within the cloud, such as the configurations, access policies, and user data.	t	1
4386	1208	The customer is responsible for security of the operating system, software stack required to run their applications and any hardware, networks, and physical security.	f	2
4387	1208	The customer is not responsible for any of the data in the cloud, as data management is the responsibility of the cloud provider who is hosting the data.	f	3
4388	1208	The customer is responsible for all infrastructure decisions, server configurations and database monitoring.	f	4
4389	1209	It's cost-effective, as all infrastructure costs are handled under a single monthly or annual subscription fee.	f	1
4390	1209	It’s efficient, as IaaS resources are available when needed and resources aren’t wasted by overbuilding capacity.	t	2
4391	1209	It reduces development time, as developers can go straight to coding instead of spending time setting up and maintaining a development environment.	f	3
4392	1209	It has low management overhead, as all administration and management tasks for data, servers, storage, and updates are handled by the cloud vendor.	f	4
4393	1210	Infrastructure as a Service (IaaS)	f	1
4394	1210	Software as a Service (SaaS)	f	2
4395	1210	Function as a Service (FaaS)	f	3
4396	1210	Platform as a Service (PaaS)	t	4
4397	1211	Software as a Service (SaaS)	t	1
4398	1211	IT as a service (ITaaS)	f	2
4399	1211	Infrastructure as a Service (IaaS)	f	3
4400	1211	Platform as a Service (PaaS)	f	4
4401	1212	A type of artificial intelligence that can create and sustain its own consciousness.	f	1
4402	1212	A type of artificial intelligence that can make decisions and take actions.	f	2
4403	1212	A type of artificial intelligence that can understand and respond to human emotions.	f	3
4404	1212	A type of artificial intelligence that can produce new content, including text, images, audio, and synthetic data.	t	4
4405	1213	Segmenting images into different parts or regions to extract information, such as the text on a sign.	f	1
4406	1213	Identifying the artist, title, or genre of a song to create playlists based on the user's listening habits.	f	2
4407	1213	Detecting people and objects in surveillance footage to use as evidence in criminal cases.	f	3
4408	1213	Identifying the topic and sentiment of customer email messages so that they can be routed to the relevant department.	t	4
4409	1214	Whether all the required information is present.	f	1
4410	1214	Whether the data is uniform and doesn’t contain any contradictory information.	t	2
4411	1214	Whether the data is up-to-date and reflects the current state of the phenomenon that is being modeled.	f	3
4412	1214	Whether a dataset is free from duplicate values that could prevent an ML model from learning accurately.	f	4
4413	1215	Content moderation	f	1
4414	1215	Clickbait detection	f	2
4415	1215	Video transcription	f	3
4416	1215	Personalized recommendations	t	4
4417	1216	AI should create unfair bias.	f	1
4418	1216	Google makes tools that empower others to harness AI for individual and collective benefit.	t	2
4419	1216	AI should gather or use information for surveillance.	f	3
4420	1216	Google makes tools that uphold high standards of operational excellence.	f	4
4421	1217	Machine learning	f	1
4422	1217	Artificial intelligence	t	2
4423	1217	Deep learning	f	3
4424	1217	Natural language processing	f	4
4425	1218	Implementing AI to develop a new product or service that has never been seen before.	f	1
4426	1218	Training a machine learning model to predict a search result ranking.	t	2
4427	1218	Using AI to replace a human decision-maker in complex situations, such as those involving life-or-death choices.	f	3
4428	1218	Using a reinforcement learning algorithm to train autonomous drones for package delivery.	f	4
4429	1219	Data analytics and business intelligence are used only in small businesses, whereas AI and ML are used exclusively by large corporations.	f	1
4430	1219	Data analytics and business intelligence identify trends from historical data, whereas AI and ML use data to make decisions for future business.	t	2
4431	1219	Data analytics and business intelligence use automated decision-making processes, whereas AI and ML require human intervention and interpretation of data.	f	3
4432	1219	Data analytics and business intelligence involve advanced algorithms for predicting future trends, whereas AI and ML focus on processing historical data.	f	4
4433	1220	Vision API	t	1
4434	1220	Natural Language API	f	2
4435	1220	Video Intelligence API	f	3
4436	1220	Speech-to-Text API	f	4
4437	1221	Discovery AI for Retail	f	1
4438	1221	Document AI	t	2
4439	1222	Contact Center AI	t	1
4440	1222	Document AI	f	2
4441	1223	Graphic Processing Unit (GPU)	f	1
4442	1223	Tensor Processing Unit (TPU)	t	2
4443	1223	Central Processing Unit (CPU)	f	3
4444	1223	Vertex Processing Unit (VPU)	f	4
4445	1224	Video Intelligence API	f	1
4446	1224	Vision API	f	2
4447	1224	Natural Language API	t	3
4448	1224	Speech-to-Text API	f	4
4449	1225	Build and evaluate machine learning models in BigQuery by using SQL.	t	1
4450	1225	Export small amounts of data to spreadsheets or other applications.	f	2
4451	1225	Seamlessly connect with a data science team to create an ML model.	f	3
4452	1226	BigQuery ML	f	1
4453	1226	AutoML	f	2
4454	1226	Custom training	t	3
4455	1226	Pre-trained APIs	f	4
4456	1227	Custome training	f	1
4457	1227	Managed ML environment	f	2
4458	1227	AutoML	t	3
4459	1227	MLOps	f	4
4460	1228	Reliability	t	1
4461	1228	Total cost of ownership	f	2
4462	1229	Traditional on-premises computing	f	1
4463	1229	Serverless computing	t	2
4464	1229	PaaS (platform as a service)	f	3
4465	1229	IaaS (infrastructure as a service)	f	4
4466	1230	Software layers above the firmware level	f	1
4467	1230	Software layers above the operating system level	t	2
4468	1230	Hardware layers above the electrical level	f	3
4469	1230	The entire machine	f	4
4470	1231	Move and improve	f	1
4471	1231	Refactor and reshape	f	2
4472	1231	Lift and shift	t	3
4473	1231	Reimagine and plan	f	4
4474	1232	Build and deploy	f	1
4475	1232	Move and improve	f	2
4476	1232	Lift and shift	t	3
4477	1232	Install and fall	f	4
4478	1233	Programming communication link	f	1
4479	1233	Application programming interface	t	2
4480	1233	Communication link interface	f	3
4481	1233	Network programming interface	f	4
4482	1234	Microservices	t	1
4483	1234	DevOps	f	2
4484	1235	Bare metal solution	t	1
4485	1235	SQL Server on Google Cloud	f	2
4486	1235	Google Cloud VMware Engine	f	3
4487	1235	AppEngine	f	4
4488	1236	Hybrid cloud	f	1
4489	1236	Multicloud	t	2
4490	1236	Edge cloud	f	3
4491	1236	Community cloud	f	4
4492	1237	Secure cloud	f	1
4493	1237	Hybrid cloud	t	2
4494	1237	Smart cloud	f	3
4495	1237	Agile cloud	f	4
4496	1238	Configuring the customer's applications.	f	1
4497	1238	Maintaining the customer's infrastructure.	t	2
4498	1238	Securing the customer's data.	f	3
4499	1238	Managing the customer's user access.	f	4
4500	1239	Large upfront capital investment.	f	1
4501	1239	Having physical access to hardware.	f	2
4502	1239	Only having to install security updates on a weekly basis.	f	3
4503	1239	Increased scalability.	t	4
4504	1240	Certificates, intelligence, and authentication	f	1
4505	1240	Confidentiality, integrity, and availability	t	2
4506	1240	Compliance, identity, and access management	f	3
4507	1240	Containers, infrastructure, and architecture	f	4
4508	1241	A network security device that monitors and controls incoming and outgoing network traffic based on predefined security rules	t	1
4509	1241	A set of security measures designed to protect a computer system or network from cyber attacks	f	2
4510	1241	A software program that encrypts data to make it unreadable to unauthorized users	f	3
4511	1241	A security model that assumes no user or device can be trusted by default	f	4
4512	1242	Security by default	f	1
4513	1242	Privileged access	f	2
4514	1242	Zero-trust architecture	f	3
4515	1242	Least privilege	t	4
4516	1243	Zero trust security	f	1
4517	1243	Cloud security posture management (CSPM)	f	2
4518	1243	Site reliability engineering (SRE)	f	3
4519	1243	Security operations (SecOps)	t	4
4520	1244	Lattice-Based Cryptography (LBC)	f	1
4521	1244	Post-quantum cryptography (PQC)	f	2
4522	1244	Advanced Encryption Standard (AES)	t	3
4523	1244	Isomorphic encryption (IE)	f	4
4524	1245	IAM provides granular control over who has access to Google Cloud resources and what they can do with those resources.	t	1
4525	1245	IAM is a cloud service that encrypts cloud-based data at rest and in transit.	f	2
4526	1245	IAM is a cloud security information and event management solution that collects and analyzes log data from cloud security devices and applications.	f	3
4527	1246	Data Center Infrastructure Efficiency (DCiE)	f	1
4528	1246	Power Usage Effectiveness (PUE)	t	2
4529	1246	Energy Efficiency Ratio (EER)	f	3
4530	1246	Total cost of ownership (TCO)	f	4
4531	1247	Data in transit	f	1
4532	1247	Data lake	f	2
4533	1247	Data in use	t	3
4534	1247	Data at rest	f	4
4535	1248	Security information and event management (SIEM)	f	1
4536	1248	Firewall as a service (FaaS)	f	2
4537	1248	Data loss prevention (DLP)	f	3
4538	1248	Two-step verification (2SV)	t	4
4539	1248	Trust and Security with Google Cloud	f	5
4540	1249	Google Cloud console	f	1
4541	1249	Cloud Storage client libraries	f	2
4542	1249	Compliance resource center	t	3
4543	1250	Compliance reports	f	1
4544	1250	Billing reports	f	2
4545	1250	Transparency reports	t	3
4546	1250	Security reports	f	4
4547	1251	All customer data is encrypted by default.	t	1
4548	1251	We give "backdoor" access to government entities when requested.	f	2
4549	1251	Google sells customer data to third parties.	f	3
4550	1251	Google Cloud uses customer data for advertising.	f	4
4551	1252	Data consistency	f	1
4552	1252	Data redundancy	f	2
4553	1252	Data sovereignty	t	3
4554	1252	Data residency	f	4
4555	1253	Competency center	f	1
4556	1253	Center of innovation	f	2
4557	1253	Center of excellence	t	3
4558	1253	Hub center	f	4
4559	1254	Resources	t	1
4560	1254	Organization node	f	2
4561	1255	Cost forecasting	f	1
4562	1255	Cloud billing reports	t	2
4563	1255	Resource usage	f	3
4564	1255	Cost bugdet	f	4
4565	1256	Inheritance in the hierarchy reduces the overall cost of cloud computing.	f	1
4566	1256	Faster propagation can simplify a cloud migration.	f	2
4567	1256	Resources at lower levels can improve the performance of cloud applications.	f	3
4568	1256	Permissions set at higher levels of the resource hierarchy are automatically inherited by lower-level resources.	t	4
4569	1257	Billing reports	f	1
4570	1257	Invoicing limits	f	2
4571	1257	Quota policies	t	3
4572	1257	Committed use discounts	f	4
4573	1258	Budget threshold rules	t	1
4574	1258	Billing reports	f	2
4575	1258	Cost optimization recommendations	f	3
4576	1258	Cost forecasting	f	4
4577	1259	Site reliability engineer	t	1
4578	1259	Cloud architect	f	2
4579	1259	DevOps engineer	f	3
4580	1259	Cloud security engineer	f	4
4581	1260	It provides a comprehensive view of your cloud infrastructure and applications.	f	1
4582	1260	It identifies how much CPU power, memory, and other resources an application uses.	t	2
4583	1260	It collects and stores all application and infrastructure logs.	f	3
4584	1260	It counts, analyzes, and aggregates the crashes in running cloud services in real-time.	f	4
4585	1261	How long it takes for a particular part of a system to return a result.	t	1
4586	1261	How close to capacity a system is.	f	2
4587	1261	How many requests reach a system.	f	3
4588	1261	System failures or other issues.	f	4
4589	1262	It duplicates critical components or resources to provide backup alternatives.	f	1
4590	1262	It monitors and controls incoming and outgoing network traffic based on predetermined security rules.	f	2
4591	1262	It scales infrastructure to handle varying workloads and accommodate increased demand.	f	3
4592	1262	It creates multiple copies of data or services and distributes them across different servers or locations.	t	4
4593	1263	Service level contracts	f	1
4594	1263	Service level indicators	t	2
4595	1263	Service level objectives	f	3
4596	1263	Service level agreements	f	4
4597	1264	Backups	t	1
4598	1264	Security patches	f	2
4599	1264	Inventory data	f	3
4600	1264	Log files	f	4
4601	1265	It uses BigQuery and Looker Studio to build and deploy machine learning models.	f	1
4602	1265	It uses BigQuery and Looker Studio to create dashboards that provide granular operational insights.	t	2
4603	1265	It uses BigQuery and Looker Studio to containerize workloads.	f	3
4604	1265	It uses BigQuery and Looker Studio to comply with government regulations.	f	4
4605	1266	To be the first major company to operate completely carbon free.	t	1
4606	1266	To be the first major company to run its own wind farm.	f	2
4607	1266	To be the first major company to be carbon neutral.	f	3
4608	1266	To be the first major company to achieve 100% renewable energy.	f	4
4609	1267	It’s a framework for sustainable procurement, which is the process of purchasing goods and services in a way that minimizes environmental and social impacts.	f	1
4610	1267	It’s a framework for identifying, predicting, and evaluating the environmental impacts of a proposed project.	f	2
4611	1267	It’s a framework for an organization to enhance its environmental performance through improving resource efficiency and reducing waste.	t	3
4612	1267	It’s a framework for carbon footprinting that calculates the total amount of greenhouse gas emissions associated with a product, service, or organization.	f	4
4613	1268	It's cost effective, so the organization will no longer have to pay for computing once the app is in the cloud.	t	1
4614	1268	It's scalable, so the organization could shorten their infrastructure deployment time.	f	2
4615	1268	It provides physical access, so the organization can deploy servers faster.	f	3
4616	1268	It's secure, so the organization won't have to worry about the new subscribers data.	f	4
4617	1269	Software as a service	f	1
4618	1269	Public Cloud	f	2
4619	1269	Private Cloud	t	3
4620	1269	Platform as a service	f	4
4621	1270	Open source software makes it easier to patent proprietary software.	f	1
4622	1270	Open standards make it easier to hire more developers.	f	2
4623	1270	Open source software reduces the chance of vendor lock-in.	t	3
4624	1270	On-premises software isn't open source, so cloud applications are more portable.	f	4
4625	1271	Sustainable cloud ensures the costs of cloud resources are controlled to prevent budget overrun.	f	1
4626	1271	A trusted cloud gives control of all resources to the user to ensure high availability at all times.	f	2
4627	1271	Data cloud provides a unified solution to manage data across the entire data lifecycle.	t	3
4628	1271	Open infrastructure gives the freedom to innovate by buying cheaper more hardware and software.	f	4
4629	1272	Organizations risk losing market leadership if they spend too much time on digital transformation.	f	1
4630	1272	Embracing new technology can cause organizations to overspend on innovation.	f	2
4631	1272	Focusing on ‘why’ they operate can lead to inefficient use of resources and disruption.	f	3
4632	1272	Focusing on ‘how’ they operate can prevent organizations from seeing transformation opportunities.	t	4
4633	1273	Maintenance workers do not have physical access to the servers.	f	1
4634	1273	Scaling processing is too difficult due to power consumption.	f	2
4635	1273	The on-premises networking is more complicated.	f	3
4636	1273	The on-premises hardware procurement process can take a long time.	t	4
4637	1274	A Google product for computing large amounts of data.	f	1
4638	1274	A metaphor for the networking capability of internet providers.	f	2
4639	1274	A metaphor for a network of data centers.	t	3
4640	1274	A Google product made up of on-premises IT infrastructure.	f	4
4641	1275	Ensure better security by decoupling teams and their data.	f	1
4642	1275	Break down data silos and generate real time insights.	t	2
4643	1275	Streamline their hardware procurement process to forecast at least a quarter into the future.	f	3
4644	1275	Reduce emissions by using faster networks in their on-premises workloads.	f	4
4645	1276	When an organization uses new digital technologies to create or modify on-premises business processes.	f	1
4646	1276	When an organization uses new digital technologies to create or modify technology infrastructure to focus on cost saving.	f	2
4647	1276	When an organization uses new digital technologies to create or modify business processes, culture, and customer experiences.	t	3
4648	1276	When an organization uses new digital technologies to create or modify financial models for how a business is run.	f	4
4649	1277	The process of collecting and storing data for future use	f	1
4650	1277	The process of analyzing data to gain insights and make informed decisions	f	2
4651	1277	The process of setting internal data policies and ensuring compliance with external standards	t	3
4652	1277	The process of deleting unnecessary data to save storage space	f	4
4653	1278	A relational database	t	1
4654	1278	An XML database	f	2
4655	1278	An object database	f	3
4656	1278	A non-relational database	f	4
4657	1279	Google Cloud Marketplace	t	1
4658	1279	App Engine	f	2
4659	1279	Google Cloud console	f	3
4660	1279	Google Play	f	4
4661	1280	Semi-structured data	f	1
4662	1280	Unstructured data	f	2
4663	1280	Structured data	t	3
4664	1280	A hybrid of structured, semi-structured, and unstructured data	f	4
4665	1281	Data lake	t	1
4666	1281	Data warehouse	f	2
4667	1281	Database	f	3
4668	1281	Data archive	f	4
4669	1282	Through machine learning, with every click that the user makes, their website experience becomes increasingly personalized.	t	1
4670	1282	Machine learning can be used to make all users see the same product recommendations, regardless of their preferences or behavior.	f	2
4671	1282	Machine learning can help identify user behavior in real time, but cannot make personalized suggestions based on the data.	f	3
4672	1282	Through machine learning, a user’s credit card transactions can be analyzed to determine regular purchases.	f	4
4673	1283	Data analysis	f	1
4674	1283	Data processing	t	2
4675	1283	Data storage	f	3
4676	1283	Data genesis	f	4
4677	1284	Using GPS coordinates to power a ride-sharing app	f	1
4678	1284	Analyzing historical sales figures to predict future trends	f	2
4679	1284	Creating visualizations from seasonal weather data	f	3
4680	1284	Analyzing social media posts to identify sentiment toward a brand	t	4
4681	1285	Second-party data	f	1
4682	1285	Third-party data	f	2
4683	1285	First-party data	t	3
4684	1286	Accessibility only within one region	f	1
889	331	Reliability of the infrastructure availability.	f	1
890	331	Total cost of ownership of the infrastructure.	f	2
891	331	Scalability of infrastructure to needs.	f	3
892	331	Flexibility of infrastructure configuration.	t	4
893	332	Budgeting will only happen on an annual basis.	f	1
894	332	They will only pay for what they forecast.	f	2
895	332	Hardware procurement is done by a centralized team.	f	3
896	332	They will only pay for what they use.	t	4
897	333	Using the edge network to cache the whole application image in a backup.	f	1
898	333	By assigning a different IP address to each resource.	f	2
899	333	By putting resources in the Domain Name System (DNS).	f	3
900	333	By putting resources in different zones.	t	4
901	334	The customer is responsible for securing anything that they create within the cloud, such as the configurations, access policies, and user data.	t	1
902	334	The customer is responsible for security of the operating system, software stack required to run their applications and any hardware, networks, and physical security.	f	2
903	334	The customer is not responsible for any of the data in the cloud, as data management is the responsibility of the cloud provider who is hosting the data.	f	3
904	334	The customer is responsible for all infrastructure decisions, server configurations and database monitoring.	f	4
905	335	It's cost-effective, as all infrastructure costs are handled under a single monthly or annual subscription fee.	f	1
906	335	It’s efficient, as IaaS resources are available when needed and resources aren’t wasted by overbuilding capacity.	t	2
907	335	It reduces development time, as developers can go straight to coding instead of spending time setting up and maintaining a development environment.	f	3
908	335	It has low management overhead, as all administration and management tasks for data, servers, storage, and updates are handled by the cloud vendor.	f	4
909	336	Infrastructure as a Service (IaaS)	f	1
910	336	Software as a Service (SaaS)	f	2
911	336	Function as a Service (FaaS)	f	3
912	336	Platform as a Service (PaaS)	t	4
913	337	Software as a Service (SaaS)	t	1
914	337	IT as a service (ITaaS)	f	2
915	337	Infrastructure as a Service (IaaS)	f	3
916	337	Platform as a Service (PaaS)	f	4
917	338	A type of artificial intelligence that can create and sustain its own consciousness.	f	1
918	338	A type of artificial intelligence that can make decisions and take actions.	f	2
919	338	A type of artificial intelligence that can understand and respond to human emotions.	f	3
920	338	A type of artificial intelligence that can produce new content, including text, images, audio, and synthetic data.	t	4
921	339	Segmenting images into different parts or regions to extract information, such as the text on a sign.	f	1
922	339	Identifying the artist, title, or genre of a song to create playlists based on the user's listening habits.	f	2
1013	364	Maintaining the customer's infrastructure.	t	2
923	339	Detecting people and objects in surveillance footage to use as evidence in criminal cases.	f	3
924	339	Identifying the topic and sentiment of customer email messages so that they can be routed to the relevant department.	t	4
925	340	Whether all the required information is present.	f	1
926	340	Whether the data is uniform and doesn’t contain any contradictory information.	t	2
927	340	Whether the data is up-to-date and reflects the current state of the phenomenon that is being modeled.	f	3
928	340	Whether a dataset is free from duplicate values that could prevent an ML model from learning accurately.	f	4
929	341	Content moderation	f	1
930	341	Clickbait detection	f	2
931	341	Video transcription	f	3
932	341	Personalized recommendations	t	4
933	342	AI should create unfair bias.	f	1
934	342	Google makes tools that empower others to harness AI for individual and collective benefit.	t	2
935	342	AI should gather or use information for surveillance.	f	3
936	342	Google makes tools that uphold high standards of operational excellence.	f	4
937	343	Machine learning	f	1
938	343	Artificial intelligence	t	2
939	343	Deep learning	f	3
940	343	Natural language processing	f	4
941	344	Implementing AI to develop a new product or service that has never been seen before.	f	1
942	344	Training a machine learning model to predict a search result ranking.	t	2
943	344	Using AI to replace a human decision-maker in complex situations, such as those involving life-or-death choices.	f	3
944	344	Using a reinforcement learning algorithm to train autonomous drones for package delivery.	f	4
945	345	Data analytics and business intelligence are used only in small businesses, whereas AI and ML are used exclusively by large corporations.	f	1
946	345	Data analytics and business intelligence identify trends from historical data, whereas AI and ML use data to make decisions for future business.	t	2
947	345	Data analytics and business intelligence use automated decision-making processes, whereas AI and ML require human intervention and interpretation of data.	f	3
948	345	Data analytics and business intelligence involve advanced algorithms for predicting future trends, whereas AI and ML focus on processing historical data.	f	4
949	346	Vision API	t	1
950	346	Natural Language API	f	2
951	346	Video Intelligence API	f	3
952	346	Speech-to-Text API	f	4
953	347	Discovery AI for Retail	f	1
954	347	Document AI	t	2
955	348	Contact Center AI	t	1
956	348	Document AI	f	2
957	349	Graphic Processing Unit (GPU)	f	1
958	349	Tensor Processing Unit (TPU)	t	2
959	349	Central Processing Unit (CPU)	f	3
960	349	Vertex Processing Unit (VPU)	f	4
961	350	Video Intelligence API	f	1
962	350	Vision API	f	2
963	350	Natural Language API	t	3
964	350	Speech-to-Text API	f	4
965	351	Build and evaluate machine learning models in BigQuery by using SQL.	t	1
966	351	Export small amounts of data to spreadsheets or other applications.	f	2
967	351	Seamlessly connect with a data science team to create an ML model.	f	3
968	352	BigQuery ML	f	1
969	352	AutoML	f	2
970	352	Custom training	t	3
971	352	Pre-trained APIs	f	4
972	353	Custome training	f	1
973	353	Managed ML environment	f	2
974	353	AutoML	t	3
975	353	MLOps	f	4
976	354	Reliability	t	1
977	354	Total cost of ownership	f	2
978	355	Traditional on-premises computing	f	1
979	355	Serverless computing	t	2
980	355	PaaS (platform as a service)	f	3
981	355	IaaS (infrastructure as a service)	f	4
982	356	Software layers above the firmware level	f	1
983	356	Software layers above the operating system level	t	2
984	356	Hardware layers above the electrical level	f	3
985	356	The entire machine	f	4
986	357	Move and improve	f	1
987	357	Refactor and reshape	f	2
988	357	Lift and shift	t	3
989	357	Reimagine and plan	f	4
990	358	Build and deploy	f	1
991	358	Move and improve	f	2
992	358	Lift and shift	t	3
993	358	Install and fall	f	4
994	359	Programming communication link	f	1
995	359	Application programming interface	t	2
996	359	Communication link interface	f	3
997	359	Network programming interface	f	4
998	360	Microservices	t	1
999	360	DevOps	f	2
1000	361	Bare metal solution	t	1
1001	361	SQL Server on Google Cloud	f	2
1002	361	Google Cloud VMware Engine	f	3
1003	361	AppEngine	f	4
1004	362	Hybrid cloud	f	1
1005	362	Multicloud	t	2
1006	362	Edge cloud	f	3
1007	362	Community cloud	f	4
1008	363	Secure cloud	f	1
1009	363	Hybrid cloud	t	2
1010	363	Smart cloud	f	3
1011	363	Agile cloud	f	4
1012	364	Configuring the customer's applications.	f	1
1014	364	Securing the customer's data.	f	3
1015	364	Managing the customer's user access.	f	4
1016	365	Large upfront capital investment.	f	1
1017	365	Having physical access to hardware.	f	2
1018	365	Only having to install security updates on a weekly basis.	f	3
1019	365	Increased scalability.	t	4
1020	366	Certificates, intelligence, and authentication	f	1
1021	366	Confidentiality, integrity, and availability	t	2
1022	366	Compliance, identity, and access management	f	3
1023	366	Containers, infrastructure, and architecture	f	4
1024	367	A network security device that monitors and controls incoming and outgoing network traffic based on predefined security rules	t	1
1025	367	A set of security measures designed to protect a computer system or network from cyber attacks	f	2
1026	367	A software program that encrypts data to make it unreadable to unauthorized users	f	3
1027	367	A security model that assumes no user or device can be trusted by default	f	4
1028	368	Security by default	f	1
1029	368	Privileged access	f	2
1030	368	Zero-trust architecture	f	3
1031	368	Least privilege	t	4
1032	369	Zero trust security	f	1
1033	369	Cloud security posture management (CSPM)	f	2
1034	369	Site reliability engineering (SRE)	f	3
1035	369	Security operations (SecOps)	t	4
1036	370	Lattice-Based Cryptography (LBC)	f	1
1037	370	Post-quantum cryptography (PQC)	f	2
1038	370	Advanced Encryption Standard (AES)	t	3
1039	370	Isomorphic encryption (IE)	f	4
1040	371	IAM provides granular control over who has access to Google Cloud resources and what they can do with those resources.	t	1
1041	371	IAM is a cloud service that encrypts cloud-based data at rest and in transit.	f	2
1042	371	IAM is a cloud security information and event management solution that collects and analyzes log data from cloud security devices and applications.	f	3
1043	372	Data Center Infrastructure Efficiency (DCiE)	f	1
1044	372	Power Usage Effectiveness (PUE)	t	2
1045	372	Energy Efficiency Ratio (EER)	f	3
1046	372	Total cost of ownership (TCO)	f	4
1047	373	Data in transit	f	1
1048	373	Data lake	f	2
1049	373	Data in use	t	3
1050	373	Data at rest	f	4
1051	374	Security information and event management (SIEM)	f	1
1052	374	Firewall as a service (FaaS)	f	2
1053	374	Data loss prevention (DLP)	f	3
1054	374	Two-step verification (2SV)	t	4
1055	374	Trust and Security with Google Cloud	f	5
1056	375	Google Cloud console	f	1
1057	375	Cloud Storage client libraries	f	2
1058	375	Compliance resource center	t	3
1059	376	Compliance reports	f	1
1060	376	Billing reports	f	2
1061	376	Transparency reports	t	3
1062	376	Security reports	f	4
1063	377	All customer data is encrypted by default.	t	1
1064	377	We give "backdoor" access to government entities when requested.	f	2
1065	377	Google sells customer data to third parties.	f	3
1066	377	Google Cloud uses customer data for advertising.	f	4
1067	378	Data consistency	f	1
1068	378	Data redundancy	f	2
1069	378	Data sovereignty	t	3
1070	378	Data residency	f	4
1071	379	Competency center	f	1
1072	379	Center of innovation	f	2
1073	379	Center of excellence	t	3
1074	379	Hub center	f	4
1075	380	Resources	t	1
1076	380	Organization node	f	2
1077	381	Cost forecasting	f	1
1078	381	Cloud billing reports	t	2
1079	381	Resource usage	f	3
1080	381	Cost bugdet	f	4
1081	382	Inheritance in the hierarchy reduces the overall cost of cloud computing.	f	1
1082	382	Faster propagation can simplify a cloud migration.	f	2
1083	382	Resources at lower levels can improve the performance of cloud applications.	f	3
1084	382	Permissions set at higher levels of the resource hierarchy are automatically inherited by lower-level resources.	t	4
1085	383	Billing reports	f	1
1086	383	Invoicing limits	f	2
1087	383	Quota policies	t	3
1088	383	Committed use discounts	f	4
1089	384	Budget threshold rules	t	1
1090	384	Billing reports	f	2
1091	384	Cost optimization recommendations	f	3
1092	384	Cost forecasting	f	4
1093	385	Site reliability engineer	t	1
1094	385	Cloud architect	f	2
1095	385	DevOps engineer	f	3
1096	385	Cloud security engineer	f	4
1097	386	It provides a comprehensive view of your cloud infrastructure and applications.	f	1
1098	386	It identifies how much CPU power, memory, and other resources an application uses.	t	2
1099	386	It collects and stores all application and infrastructure logs.	f	3
1100	386	It counts, analyzes, and aggregates the crashes in running cloud services in real-time.	f	4
1101	387	How long it takes for a particular part of a system to return a result.	t	1
1102	387	How close to capacity a system is.	f	2
1103	387	How many requests reach a system.	f	3
1104	387	System failures or other issues.	f	4
1105	388	It duplicates critical components or resources to provide backup alternatives.	f	1
1106	388	It monitors and controls incoming and outgoing network traffic based on predetermined security rules.	f	2
1107	388	It scales infrastructure to handle varying workloads and accommodate increased demand.	f	3
1108	388	It creates multiple copies of data or services and distributes them across different servers or locations.	t	4
1109	389	Service level contracts	f	1
1110	389	Service level indicators	t	2
1111	389	Service level objectives	f	3
1112	389	Service level agreements	f	4
1113	390	Backups	t	1
1114	390	Security patches	f	2
1115	390	Inventory data	f	3
1116	390	Log files	f	4
1117	391	It uses BigQuery and Looker Studio to build and deploy machine learning models.	f	1
1118	391	It uses BigQuery and Looker Studio to create dashboards that provide granular operational insights.	t	2
1119	391	It uses BigQuery and Looker Studio to containerize workloads.	f	3
1120	391	It uses BigQuery and Looker Studio to comply with government regulations.	f	4
1121	392	To be the first major company to operate completely carbon free.	t	1
1122	392	To be the first major company to run its own wind farm.	f	2
1123	392	To be the first major company to be carbon neutral.	f	3
1124	392	To be the first major company to achieve 100% renewable energy.	f	4
1125	393	It’s a framework for sustainable procurement, which is the process of purchasing goods and services in a way that minimizes environmental and social impacts.	f	1
1126	393	It’s a framework for identifying, predicting, and evaluating the environmental impacts of a proposed project.	f	2
1127	393	It’s a framework for an organization to enhance its environmental performance through improving resource efficiency and reducing waste.	t	3
1128	393	It’s a framework for carbon footprinting that calculates the total amount of greenhouse gas emissions associated with a product, service, or organization.	f	4
1129	394	It's cost effective, so the organization will no longer have to pay for computing once the app is in the cloud.	t	1
1130	394	It's scalable, so the organization could shorten their infrastructure deployment time.	f	2
1131	394	It provides physical access, so the organization can deploy servers faster.	f	3
1132	394	It's secure, so the organization won't have to worry about the new subscribers data.	f	4
1133	395	Software as a service	f	1
1134	395	Public Cloud	f	2
1135	395	Private Cloud	t	3
1136	395	Platform as a service	f	4
1137	396	Open source software makes it easier to patent proprietary software.	f	1
1138	396	Open standards make it easier to hire more developers.	f	2
1139	396	Open source software reduces the chance of vendor lock-in.	t	3
1140	396	On-premises software isn't open source, so cloud applications are more portable.	f	4
1141	397	Sustainable cloud ensures the costs of cloud resources are controlled to prevent budget overrun.	f	1
1142	397	A trusted cloud gives control of all resources to the user to ensure high availability at all times.	f	2
1143	397	Data cloud provides a unified solution to manage data across the entire data lifecycle.	t	3
1144	397	Open infrastructure gives the freedom to innovate by buying cheaper more hardware and software.	f	4
1145	398	Organizations risk losing market leadership if they spend too much time on digital transformation.	f	1
1146	398	Embracing new technology can cause organizations to overspend on innovation.	f	2
1147	398	Focusing on ‘why’ they operate can lead to inefficient use of resources and disruption.	f	3
1148	398	Focusing on ‘how’ they operate can prevent organizations from seeing transformation opportunities.	t	4
1149	399	Maintenance workers do not have physical access to the servers.	f	1
1150	399	Scaling processing is too difficult due to power consumption.	f	2
1151	399	The on-premises networking is more complicated.	f	3
1152	399	The on-premises hardware procurement process can take a long time.	t	4
1153	400	A Google product for computing large amounts of data.	f	1
1154	400	A metaphor for the networking capability of internet providers.	f	2
1155	400	A metaphor for a network of data centers.	t	3
1156	400	A Google product made up of on-premises IT infrastructure.	f	4
1157	401	Ensure better security by decoupling teams and their data.	f	1
1158	401	Break down data silos and generate real time insights.	t	2
1159	401	Streamline their hardware procurement process to forecast at least a quarter into the future.	f	3
1160	401	Reduce emissions by using faster networks in their on-premises workloads.	f	4
1161	402	When an organization uses new digital technologies to create or modify on-premises business processes.	f	1
1162	402	When an organization uses new digital technologies to create or modify technology infrastructure to focus on cost saving.	f	2
1163	402	When an organization uses new digital technologies to create or modify business processes, culture, and customer experiences.	t	3
1164	402	When an organization uses new digital technologies to create or modify financial models for how a business is run.	f	4
1165	403	The process of collecting and storing data for future use	f	1
1166	403	The process of analyzing data to gain insights and make informed decisions	f	2
1167	403	The process of setting internal data policies and ensuring compliance with external standards	t	3
1168	403	The process of deleting unnecessary data to save storage space	f	4
1169	404	A relational database	t	1
1170	404	An XML database	f	2
1171	404	An object database	f	3
1172	404	A non-relational database	f	4
1173	405	Google Cloud Marketplace	t	1
1174	405	App Engine	f	2
1175	405	Google Cloud console	f	3
1176	405	Google Play	f	4
1177	406	Semi-structured data	f	1
1178	406	Unstructured data	f	2
1179	406	Structured data	t	3
1180	406	A hybrid of structured, semi-structured, and unstructured data	f	4
1181	407	Data lake	t	1
1182	407	Data warehouse	f	2
1183	407	Database	f	3
1184	407	Data archive	f	4
1185	408	Through machine learning, with every click that the user makes, their website experience becomes increasingly personalized.	t	1
1186	408	Machine learning can be used to make all users see the same product recommendations, regardless of their preferences or behavior.	f	2
1187	408	Machine learning can help identify user behavior in real time, but cannot make personalized suggestions based on the data.	f	3
1188	408	Through machine learning, a user’s credit card transactions can be analyzed to determine regular purchases.	f	4
1189	409	Data analysis	f	1
1190	409	Data processing	t	2
1191	409	Data storage	f	3
1192	409	Data genesis	f	4
1193	410	Using GPS coordinates to power a ride-sharing app	f	1
1194	410	Analyzing historical sales figures to predict future trends	f	2
1195	410	Creating visualizations from seasonal weather data	f	3
1196	410	Analyzing social media posts to identify sentiment toward a brand	t	4
1197	411	Second-party data	f	1
1198	411	Third-party data	f	2
1199	411	First-party data	t	3
1200	412	Accessibility only within one region	f	1
1201	412	Geo-redundancy if data is stored in a multi-region or dual-region	t	2
1202	412	Maximum storage limits	f	3
1203	412	High latency and low durability	f	4
1204	413	Storage and analytics	t	1
1205	413	Compute and analytics	f	2
1206	413	Migration and analytics	f	3
1207	413	Networking and storage	f	4
1208	414	Dataprep	f	1
1209	414	Datastream	t	2
1210	414	Pub/Sub	f	3
1211	414	Dataproc	f	4
1212	415	Cloud SQL	f	1
1213	415	Bigtable	f	2
1214	415	Firestore	f	3
1215	415	Spanner	t	4
1216	416	Lift and shift	t	1
1217	416	Refactoring	f	2
1218	416	Managed database migration	f	3
1219	416	Remain on-premises	f	4
1220	417	Archive	f	1
1221	417	Coldline	t	2
1222	417	Standard	f	3
1223	417	Nearline	f	4
1224	418	Cloud Storage	t	1
1225	418	Cloud SQL	f	2
1226	418	Firestore	f	3
1227	418	BigQuery	f	4
1228	419	Spanner	f	1
1229	419	Cloud SQL	f	2
1230	419	Bigtable	t	3
1231	419	Cloud Storage	f	4
1232	420	Cloud Storage	f	1
1233	420	Spanner	f	2
1234	420	Bigtable	f	3
1235	420	Cloud SQL	t	4
1236	421	Security is more effective when BigQuery is run in on-premises environments.	f	1
1237	421	Data teams can eradicate data silos by analyzing data across multiple cloud providers.	t	2
1238	421	BigQuery lets organizations save costs by limiting the number of cloud providers they use.	f	3
1239	421	Multicloud support in BigQuery is only intended for use in disaster recovery scenarios.	f	4
1240	422	It supports over 60 different SQL databases.	f	1
1241	422	It’s cost effective.	f	2
1242	422	It’s 100% web based.	t	3
1243	422	It creates easy to understand visualizations.	f	4
1244	423	Dataplex	f	1
1245	423	Cloud Storage	f	2
1246	423	Looker	t	3
1247	423	Dataflow	f	4
1248	424	Medical test results	f	1
1249	424	Payroll records	f	2
1250	424	Customer email addresses	f	3
1251	424	Temperature sensors	t	4
1252	425	Enhanced transaction logic	f	1
1253	425	Event-time logic	f	2
1254	425	Extract, transform, and load	t	3
1255	425	Enrichment, tagging, and labeling	f	4
1256	426	It’s a cloud-based data warehouse for storing and analyzing streaming and batch data.	f	1
1257	426	It’s a messaging service for receiving messages from various device streams.	f	2
1258	426	It handles infrastructure setup and maintenance for processing pipelines.	t	3
1259	426	It allows easy data cleaning and transformation through visual tools and machine learning-based suggestions.	f	4
1260	427	Kubernetes	t	1
1261	427	Go	f	2
1262	427	TensorFlow	f	3
1263	427	Angular	f	4
1264	428	Containers	f	1
1265	428	Virtual machine instances	t	2
1266	428	Colocation	f	3
1267	428	A local development environment	f	4
1268	429	Software layers above the operating system level	t	1
1269	429	The entire machine	f	2
1270	429	Software layers above the firmware level	f	3
1271	429	Hardware layers above the electrical level	f	4
1272	430	Security	f	1
1273	430	Total cost of ownership	f	2
1274	430	Flexibility	f	3
1275	430	Reliability	t	4
1276	431	Traditional on-premises computing	f	1
1277	431	PaaS (platform as a service)	f	2
1278	431	IaaS (infrastructure as a service)	f	3
1279	431	Serverless computing	t	4
1280	432	Monoliths	f	1
1281	432	Containers	f	2
1282	432	DevOps	f	3
1283	432	Microservices	t	4
1284	433	Programming communication link	f	1
1285	433	Network programming interface	f	2
1286	433	Communication link interface	f	3
1287	433	Application programming interface	t	4
1288	434	Lift and shift	t	1
1289	434	Build and deploy	f	2
1290	434	Move and improve	f	3
1291	434	Install and fall	f	4
1292	435	Hybrid cloud	t	1
1293	435	Secure cloud	f	2
1294	435	Smart cloud	f	3
1295	435	Multicloud	f	4
1296	436	Bare metal solution	t	1
1297	436	App Engine	f	2
1298	436	SQL Server on Google Cloud	f	3
1299	436	Google Cloud VMware Engine	f	4
1300	437	Containers	f	1
1301	437	DevOps	f	2
1302	437	Cloud security	f	3
1303	437	Managed services	t	4
1304	438	Container Registry	f	1
1305	438	Google Kubernetes Engine	f	2
1306	438	Knative	f	3
1307	438	GKE Enterprise	t	4
1308	439	By developing new products and services internally	f	1
1309	439	By allowing developers to access their data for free	f	2
1310	439	By using APIs to track customer shipments	f	3
1311	439	By charging developers to access their APIs	t	4
1312	440	Apigee	t	1
1313	440	AppSheet	f	2
1314	440	App Engine	f	3
1315	440	Cloud API Manager	f	4
1316	441	Hybrid cloud	f	1
1317	441	Community cloud	f	2
1318	441	Multicloud	t	3
1319	441	Edge cloud	f	4
1320	442	Ransomware	t	1
1321	442	Spyware	f	2
1322	442	Virus	f	3
1323	442	Trojan	f	4
1324	442	Which cybersecurity threat demands a ransom payment from a victim to regain access to their files and systems.	f	5
1325	443	Increased scalability	t	1
1326	443	Only having to install security updates on a weekly basis.	f	2
1327	443	Having physical access to hardware.	f	3
1328	443	Large upfront capital investment.	f	4
1329	444	Increased scalability.	t	1
1330	444	Only having to install security updates on a weekly basis.	f	2
1331	444	Having physical access to hardware.	f	3
1332	444	Large upfront capital investment.	f	4
1333	445	Configuring the customer's applications.	f	1
1334	445	Securing the customer's data.	f	2
1335	445	Managing the customer's user access.	f	3
1336	445	Maintaining the customer's infrastructure.	t	4
1337	446	Integrity	f	1
1338	446	Confidentiality	f	2
1339	446	Control	f	3
1340	446	Compliance	t	4
1341	447	Least privilege	t	1
1342	447	Zero-trust architecture	f	2
1343	447	Privileged access	f	3
1344	447	Security by default	f	4
1345	448	Configuration mishaps	t	1
1346	448	Phishing	f	2
1347	448	Virus	f	3
1348	448	Malware	f	4
1349	449	Ransomware	f	1
1350	449	Malware	f	2
1351	449	Phishing	t	3
1352	449	Configuration mishap	f	4
1353	450	Confidentiality	f	1
1354	450	Compliance	f	2
1355	450	Integrity	t	3
1356	450	Control	f	4
1357	451	Certificates, intelligence, and authentication	f	1
1358	451	Compliance, identity, and access management	f	2
1359	451	Containers, infrastructure, and architecture	f	3
1360	451	Confidentiality, integrity, and availability	t	4
1361	452	A software program that encrypts data to make it unreadable to unauthorized users	f	1
1362	452	A security model that assumes no user or device can be trusted by default	f	2
1363	452	A network security device that monitors and controls incoming and outgoing network traffic based on predefined security rules	t	3
1364	452	A set of security measures designed to protect a computer system or network from cyber attacks	f	4
1365	453	Cloud Storage	f	1
1366	453	Compute Engine	f	2
1367	453	BigQuery	t	3
1368	453	Vertex AI	f	4
1369	454	Looker	f	1
1370	454	Pub/Sub	t	2
1371	454	Dataproc	f	3
1372	454	Dataplex	f	4
4685	1286	Geo-redundancy if data is stored in a multi-region or dual-region	t	2
4686	1286	Maximum storage limits	f	3
4687	1286	High latency and low durability	f	4
4688	1287	Storage and analytics	t	1
4689	1287	Compute and analytics	f	2
4690	1287	Migration and analytics	f	3
4691	1287	Networking and storage	f	4
4692	1288	Dataprep	f	1
4693	1288	Datastream	t	2
4694	1288	Pub/Sub	f	3
4695	1288	Dataproc	f	4
4696	1289	Cloud SQL	f	1
4697	1289	Bigtable	f	2
4698	1289	Firestore	f	3
4699	1289	Spanner	t	4
4700	1290	Lift and shift	t	1
4701	1290	Refactoring	f	2
4702	1290	Managed database migration	f	3
4703	1290	Remain on-premises	f	4
4704	1291	Archive	f	1
4705	1291	Coldline	t	2
4706	1291	Standard	f	3
4707	1291	Nearline	f	4
4708	1292	Cloud Storage	t	1
4709	1292	Cloud SQL	f	2
4710	1292	Firestore	f	3
4711	1292	BigQuery	f	4
4712	1293	Spanner	f	1
4713	1293	Cloud SQL	f	2
4714	1293	Bigtable	t	3
4715	1293	Cloud Storage	f	4
4716	1294	Cloud Storage	f	1
4717	1294	Spanner	f	2
4718	1294	Bigtable	f	3
4719	1294	Cloud SQL	t	4
4720	1295	Security is more effective when BigQuery is run in on-premises environments.	f	1
4721	1295	Data teams can eradicate data silos by analyzing data across multiple cloud providers.	t	2
4722	1295	BigQuery lets organizations save costs by limiting the number of cloud providers they use.	f	3
4723	1295	Multicloud support in BigQuery is only intended for use in disaster recovery scenarios.	f	4
4724	1296	It supports over 60 different SQL databases.	f	1
4725	1296	It’s cost effective.	f	2
4726	1296	It’s 100% web based.	t	3
4727	1296	It creates easy to understand visualizations.	f	4
4728	1297	Dataplex	f	1
4729	1297	Cloud Storage	f	2
4730	1297	Looker	t	3
4731	1297	Dataflow	f	4
4732	1298	Medical test results	f	1
4733	1298	Payroll records	f	2
4734	1298	Customer email addresses	f	3
4735	1298	Temperature sensors	t	4
4736	1299	Enhanced transaction logic	f	1
4737	1299	Event-time logic	f	2
4738	1299	Extract, transform, and load	t	3
4739	1299	Enrichment, tagging, and labeling	f	4
4740	1300	It’s a cloud-based data warehouse for storing and analyzing streaming and batch data.	f	1
4741	1300	It’s a messaging service for receiving messages from various device streams.	f	2
4742	1300	It handles infrastructure setup and maintenance for processing pipelines.	t	3
4743	1300	It allows easy data cleaning and transformation through visual tools and machine learning-based suggestions.	f	4
4744	1301	Kubernetes	t	1
4745	1301	Go	f	2
4746	1301	TensorFlow	f	3
4747	1301	Angular	f	4
4748	1302	Containers	f	1
4749	1302	Virtual machine instances	t	2
4750	1302	Colocation	f	3
4751	1302	A local development environment	f	4
4752	1303	Software layers above the operating system level	t	1
4753	1303	The entire machine	f	2
4754	1303	Software layers above the firmware level	f	3
4755	1303	Hardware layers above the electrical level	f	4
4756	1304	Security	f	1
4757	1304	Total cost of ownership	f	2
4758	1304	Flexibility	f	3
4759	1304	Reliability	t	4
4760	1305	Traditional on-premises computing	f	1
4761	1305	PaaS (platform as a service)	f	2
4762	1305	IaaS (infrastructure as a service)	f	3
4763	1305	Serverless computing	t	4
4764	1306	Monoliths	f	1
4765	1306	Containers	f	2
4766	1306	DevOps	f	3
4767	1306	Microservices	t	4
4768	1307	Programming communication link	f	1
4769	1307	Network programming interface	f	2
4770	1307	Communication link interface	f	3
4771	1307	Application programming interface	t	4
4772	1308	Lift and shift	t	1
4773	1308	Build and deploy	f	2
4774	1308	Move and improve	f	3
4775	1308	Install and fall	f	4
4776	1309	Hybrid cloud	t	1
4777	1309	Secure cloud	f	2
4778	1309	Smart cloud	f	3
4779	1309	Multicloud	f	4
4780	1310	Bare metal solution	t	1
4781	1310	App Engine	f	2
4782	1310	SQL Server on Google Cloud	f	3
4783	1310	Google Cloud VMware Engine	f	4
4784	1311	Containers	f	1
4785	1311	DevOps	f	2
4786	1311	Cloud security	f	3
4787	1311	Managed services	t	4
4788	1312	Container Registry	f	1
4789	1312	Google Kubernetes Engine	f	2
4790	1312	Knative	f	3
4791	1312	GKE Enterprise	t	4
4792	1313	By developing new products and services internally	f	1
4793	1313	By allowing developers to access their data for free	f	2
4794	1313	By using APIs to track customer shipments	f	3
4795	1313	By charging developers to access their APIs	t	4
4796	1314	Apigee	t	1
4797	1314	AppSheet	f	2
4798	1314	App Engine	f	3
4799	1314	Cloud API Manager	f	4
4800	1315	Hybrid cloud	f	1
4801	1315	Community cloud	f	2
4802	1315	Multicloud	t	3
4803	1315	Edge cloud	f	4
4804	1316	Ransomware	t	1
4805	1316	Spyware	f	2
4806	1316	Virus	f	3
4807	1316	Trojan	f	4
4808	1316	Which cybersecurity threat demands a ransom payment from a victim to regain access to their files and systems.	f	5
4809	1317	Increased scalability	t	1
4810	1317	Only having to install security updates on a weekly basis.	f	2
4811	1317	Having physical access to hardware.	f	3
4812	1317	Large upfront capital investment.	f	4
4813	1318	Increased scalability.	t	1
4814	1318	Only having to install security updates on a weekly basis.	f	2
4815	1318	Having physical access to hardware.	f	3
4816	1318	Large upfront capital investment.	f	4
4817	1319	Configuring the customer's applications.	f	1
4818	1319	Securing the customer's data.	f	2
4819	1319	Managing the customer's user access.	f	3
4820	1319	Maintaining the customer's infrastructure.	t	4
4821	1320	Integrity	f	1
4822	1320	Confidentiality	f	2
4823	1320	Control	f	3
4824	1320	Compliance	t	4
4825	1321	Least privilege	t	1
4826	1321	Zero-trust architecture	f	2
4827	1321	Privileged access	f	3
4828	1321	Security by default	f	4
4829	1322	Configuration mishaps	t	1
4830	1322	Phishing	f	2
4831	1322	Virus	f	3
4832	1322	Malware	f	4
4833	1323	Ransomware	f	1
4834	1323	Malware	f	2
4835	1323	Phishing	t	3
4836	1323	Configuration mishap	f	4
4837	1324	Confidentiality	f	1
4838	1324	Compliance	f	2
4839	1324	Integrity	t	3
4840	1324	Control	f	4
4841	1325	Certificates, intelligence, and authentication	f	1
4842	1325	Compliance, identity, and access management	f	2
4843	1325	Containers, infrastructure, and architecture	f	3
4844	1325	Confidentiality, integrity, and availability	t	4
4845	1326	A software program that encrypts data to make it unreadable to unauthorized users	f	1
4846	1326	A security model that assumes no user or device can be trusted by default	f	2
4847	1326	A network security device that monitors and controls incoming and outgoing network traffic based on predefined security rules	t	3
4848	1326	A set of security measures designed to protect a computer system or network from cyber attacks	f	4
4849	1327	Cloud Storage	f	1
4850	1327	Compute Engine	f	2
4851	1327	BigQuery	t	3
4852	1327	Vertex AI	f	4
4853	1328	Looker	f	1
4854	1328	Pub/Sub	t	2
4855	1328	Dataproc	f	3
4856	1328	Dataplex	f	4
4857	1329	To decorate a report with charts	f	1
4858	1329	To enable understanding and decisions	t	2
4859	1329	To increase the number of metrics shown	f	3
4860	1329	To replace analysis with visuals	f	4
4861	1330	A KPI is always less specific than a metric	f	1
4862	1330	A metric is always tied to a strategic goal	f	2
4863	1330	All KPIs are metrics, but not all metrics are KPIs	t	3
4864	1330	Metrics and KPIs are identical terms	f	4
4865	1331	Which color palette looks best?	f	1
4866	1331	What business question am I answering?	t	2
4867	1331	How many categories can I fit?	f	3
4868	1331	Can I make it interactive?	f	4
4869	1332	Making the chart more colorful	f	1
4870	1332	Reducing the need for data	f	2
4871	1332	Helping the audience interpret meaning	t	3
4872	1332	Replacing labels with icons	f	4
4873	1333	Clear axis labels	f	1
4874	1333	Unnecessary 3D effects and decorations	t	2
4875	1333	A concise title	f	3
4876	1333	Consistent scales	f	4
4877	1334	Ink used for non-data decoration	f	1
4878	1334	Ink used to represent data	t	2
4879	1334	The number of gridlines	f	3
4880	1334	The number of colors	f	4
4881	1335	Looks good but is not actionable	t	1
4882	1335	Has a clear owner and action plan	f	2
4883	1335	Is always a leading indicator	f	3
4884	1335	Is required for financial reporting	f	4
4885	1336	Remove all annotations	f	1
4886	1336	Add a clear takeaway title and brief labels	t	2
4887	1336	Use a rainbow palette	f	3
4888	1336	Use 3D bars to highlight differences	f	4
4889	1337	The dashboard becomes less interactive	f	1
4890	1337	Decision-makers lose focus and miss key signals	t	2
4891	1337	The data becomes more accurate	f	3
4892	1337	The KPIs become leading indicators	f	4
4893	1338	A collection of every chart available	f	1
4894	1338	A decision-support view of key measures and trends	t	2
4895	1338	A replacement for databases	f	3
4896	1338	A static report with no interaction	f	4
4897	1339	Read detailed annotations faster	f	1
4898	1339	Quickly detect simple visual differences	t	2
4899	1339	Compute exact averages visually	f	3
4900	1339	Ignore all visual cues	f	4
4901	1340	Angle in a pie chart	f	1
4902	1340	Area of bubbles	f	2
4903	1340	Position on a common scale	t	3
4904	1340	Color hue	f	4
4905	1341	Show as many charts as possible	f	1
4906	1341	Rely on long legends and dense text	f	2
4907	1341	Use clear hierarchy and reduce clutter	t	3
4908	1341	Avoid any labels to reduce reading	f	4
4909	1342	Intrinsic load	f	1
4910	1342	Extraneous load	t	2
4911	1342	Germane load	f	3
4912	1342	Motor load	f	4
4913	1343	Effort spent on irrelevant visual features	f	1
4914	1343	Effort spent building useful understanding	t	2
4915	1343	Effort caused by data size only	f	3
4916	1343	Effort caused by using colorblind palettes	f	4
4917	1344	Seeing any colors	f	1
4918	1344	Noticing changes without attention cues	t	2
4919	1344	Reading axis titles	f	3
4920	1344	Comparing bar heights	f	4
4921	1345	Fixation duration	t	1
4922	1345	Saccade amplitude	f	2
4923	1345	Blink rate only	f	3
4924	1345	Screen refresh rate	f	4
4925	1346	A slow drift during reading	f	1
4926	1346	A rapid eye movement between fixations	t	2
4927	1346	A type of color scale	f	3
4928	1346	A dashboard filter	f	4
4929	1347	Too much visual competition and weak hierarchy	t	1
4930	1347	Using a bar chart instead of a pie chart	f	2
4931	1347	Having a title	f	3
4932	1347	Using a consistent axis	f	4
4933	1348	They hide variation across groups	f	1
4934	1348	They allow comparison across consistent scales	t	2
4935	1348	They eliminate the need for data cleaning	f	3
4936	1348	They always reduce computation cost	f	4
4937	1349	Unrelated	f	1
4938	1349	Part of the same group	t	2
4939	1349	Always larger	f	3
4940	1349	Always more important	f	4
4941	1350	Random noise	f	1
4942	1350	Belonging together	t	2
4943	1350	Less relevant	f	3
4944	1350	Numerically equal	f	4
4945	1351	Complete forms	t	1
4946	1351	More colorful	f	2
4947	1351	Always misleading	f	3
4948	1351	Only decorative	f	4
4949	1352	Smooth, continuous paths	t	1
4950	1352	Maximum number of angles	f	2
4951	1352	Random direction changes	f	3
4952	1352	Only vertical lines	f	4
4953	1353	Distinguishing foreground marks from background	t	1
4954	1353	Choosing a database schema	f	2
4955	1353	Computing medians	f	3
4956	1353	Sorting a table alphabetically	f	4
4957	1354	Place related filters near the charts they control	t	1
4958	1354	Use random spacing between related items	f	2
4959	1354	Use different fonts for each label	f	3
4960	1354	Hide legends to reduce space	f	4
4961	1355	Use the same color for the same category across views	t	1
4962	1355	Change category colors on every chart	f	2
4963	1355	Use 3D shading for all marks	f	3
4964	1355	Use different units per chart without labels	f	4
4965	1356	Elements moving together are grouped	t	1
4966	1356	Elements with different sizes are grouped	f	2
4967	1356	Elements with different fonts are grouped	f	3
4968	1356	Elements on different pages are grouped	f	4
4969	1357	Putting related KPIs inside the same panel box	t	1
4970	1357	Changing all axis titles to italics	f	2
4971	1357	Using a rainbow palette	f	3
4972	1357	Removing all whitespace	f	4
4973	1358	Using consistent legend placement	f	1
4974	1358	Using the same color for different categories	t	2
4975	1358	Using clear units on axes	f	3
4976	1358	Using a single scale in small multiples	f	4
4977	1359	Comparing quantities across categories	t	1
4978	1359	Showing distribution shape of one variable	f	2
4979	1359	Showing relationship between two numeric variables	f	3
4980	1359	Showing network connectivity	f	4
4981	1360	Ranking product categories	f	1
4982	1360	Trends over ordered time	t	2
4983	1360	Part-to-whole at one time point	f	3
4984	1360	Comparing medians across groups	f	4
4985	1361	Showing correlation or relationship between two numeric variables	t	1
4986	1361	Showing a single total	f	2
4987	1361	Showing text narratives only	f	3
4988	1361	Showing hierarchical decomposition only	f	4
4989	1362	A time-series trend	f	1
4990	1362	A frequency distribution	t	2
4991	1362	A part-to-whole breakdown	f	3
4992	1362	A network of entities	f	4
4993	1363	Means only	f	1
4994	1363	Distributions across groups (median, spread, outliers)	t	2
4995	1363	Only correlations	f	3
4996	1363	Only proportions	f	4
4997	1364	Kernel density shape of the distribution	t	1
4998	1364	Exact minimum and maximum only	f	2
4999	1364	A second y-axis	f	3
5000	1364	A regression line	f	4
5001	1365	Hierarchical part-to-whole structure	t	1
5002	1365	Precise comparison of small differences	f	2
5003	1365	Correlation between two variables	f	3
5004	1365	A timeline with events	f	4
5005	1366	A single total by category	f	1
5006	1366	Intensity values across a grid (two dimensions)	t	2
5007	1366	Only ranks of categories	f	3
5008	1366	Only a story narrative	f	4
5009	1367	When there are many categories (10+)	f	1
5010	1367	When comparing small differences precisely	f	2
5011	1367	When showing a few parts of a whole (with clear differences)	t	3
5012	1367	When showing trends over time	f	4
5013	1368	Stacked bar chart	t	1
5014	1368	3D pie chart	f	2
5015	1368	Word cloud	f	3
5016	1368	Random scatter plot	f	4
5017	1369	Compare multiple metrics for a few entities	t	1
5018	1369	Show distributions of one variable	f	2
5019	1369	Show causal effects conclusively	f	3
5020	1369	Replace time series analysis	f	4
5021	1370	High-dimensional data patterns	t	1
5022	1370	Only two-variable comparisons	f	2
5023	1370	Only part-to-whole	f	3
5024	1370	Only storytelling titles	f	4
5025	1371	Hierarchical clustering structure	t	1
5026	1371	Time series seasonality	f	2
5027	1371	A single KPI trend	f	3
5028	1371	A map projection	f	4
5029	1372	Box plot	t	1
5030	1372	Pie chart	f	2
5031	1372	Area chart	f	3
5032	1372	Simple table only	f	4
5033	1373	There are too few data points	f	1
5034	1373	Many points overlap in the same area	t	2
5035	1373	Axes start at zero	f	3
5036	1373	You use clear labels	f	4
5037	1374	Use hexbin or density plots	t	1
5038	1374	Add 3D perspective	f	2
5039	1374	Remove the axes	f	3
5040	1374	Use more random colors	f	4
5041	1375	Attached to geographic areas (regions)	t	1
5042	1375	Attached to individual customers only	f	2
5043	1375	Purely categorical with no location meaning	f	3
5044	1375	Only time-based with no spatial dimension	f	4
5045	1376	People compare diameter or area inconsistently	t	1
5046	1376	They always start at zero	f	2
5047	1376	They have too many labels by definition	f	3
5048	1376	They cannot show categories	f	4
5049	1377	Area chart	t	1
5050	1377	Pie chart	f	2
5051	1377	Dendrogram	f	3
5052	1377	Word cloud	f	4
5053	1378	Making the chart look beautiful only	f	1
5054	1378	Mapping data fields to visual properties	t	2
5055	1378	Choosing a database	f	3
5056	1378	Writing a narrative paragraph	f	4
5057	1379	Database joins	f	1
5058	1379	Graphical marks like points, lines, and bars	t	2
5059	1379	Only chart titles	f	3
5060	1379	Only color palettes	f	4
5061	1380	Transforming data values into visual space	t	1
5062	1380	Writing tooltips	f	2
5063	1380	Collecting raw data	f	3
5064	1380	Removing outliers automatically	f	4
5065	1381	Splitting a plot into small multiples by category	t	1
5066	1381	Hiding missing values	f	2
5067	1381	Making a chart 3D	f	3
5068	1381	Removing axes	f	4
5069	1382	A scatter plot with a regression line on top	t	1
5070	1382	Changing the font size of the title	f	2
5071	1382	Sorting a table alphabetically	f	3
5072	1382	Deleting the legend	f	4
5073	1383	Data	f	1
5074	1383	Geoms	f	2
5075	1383	Scales	f	3
5076	1383	Randomness generator	t	4
5077	1384	How data is filtered	f	1
5078	1384	How data is mapped into x and y space (for example, polar)	t	2
5079	1384	How many rows exist in the dataset	f	3
5080	1384	Whether data is valid	f	4
5081	1385	Limits you to a fixed catalog of chart types	f	1
5082	1385	Builds many visual forms from reusable components	t	2
5083	1385	Eliminates the need for scales	f	3
5084	1385	Avoids encoding decisions	f	4
5085	1386	An aesthetic mapping	t	1
5086	1386	A data join	f	2
5087	1386	A database index	f	3
5088	1386	A colorblind correction	f	4
5089	1387	Ensuring consistent scales	f	1
5090	1387	Creating visual clutter without a clear purpose	t	2
5091	1387	Using a single legend	f	3
5092	1387	Adding an informative annotation	f	4
5093	1388	Customer segment name	t	1
5094	1388	Rank position (1st, 2nd, 3rd)	f	2
5095	1388	Temperature in Celsius	f	3
5096	1388	Revenue in euros	f	4
5097	1389	Product ID number	f	1
5098	1389	Satisfaction rating (low, medium, high)	t	2
5099	1389	Longitude coordinate	f	3
5100	1389	Exact salary value	f	4
5101	1390	Reducing file size	f	1
5102	1390	Exaggerating differences visually	t	2
5103	1390	Improving accuracy	f	3
5104	1390	Preventing comparisons	f	4
5105	1391	Because bars encode values by length	t	1
5106	1391	Because bars encode values by color hue	f	2
5107	1391	Because it makes the chart more colorful	f	3
5108	1391	Because it increases the number of categories	f	4
5109	1392	Values are all between 0 and 1	f	1
5110	1392	Data spans multiple orders of magnitude	t	2
5111	1392	Categories are nominal only	f	3
5112	1392	You want to hide variation	f	4
5113	1393	Make unrelated trends look correlated	t	1
5114	1393	Increase data accuracy	f	2
5115	1393	Reduce the need for labels	f	3
5116	1393	Always improve clarity	f	4
5117	1394	Color luminance or saturation	t	1
5118	1394	Aligned position	f	2
5119	1394	Length on a common baseline	f	3
5120	1394	Ordered position on an axis	f	4
5121	1395	Small multiple box plots	t	1
5122	1395	A single pie chart	f	2
5123	1395	A 3D area chart	f	3
5124	1395	A word cloud	f	4
5125	1396	Use vague titles like 'Chart 1'	f	1
5126	1396	Include units and clear axis descriptions	t	2
5127	1396	Use rotated text everywhere	f	3
5128	1396	Remove labels to reduce clutter always	f	4
5129	1397	Random order to avoid bias	f	1
5130	1397	Alphabetical order always	f	2
5131	1397	Order by value when comparison is the goal	t	3
5132	1397	Order by color brightness	f	4
5133	1398	Ordered numeric intensity (low to high)	t	1
5134	1398	Unordered categories	f	2
5135	1398	Two-sided deviation around zero only	f	3
5136	1398	Labeling axes	f	4
5137	1399	Categorical product types	f	1
5138	1399	Values around a meaningful midpoint (for example, 0)	t	2
5139	1399	Time ordering	f	3
5140	1399	Random sampling	f	4
5141	1400	Ordered magnitudes	f	1
5142	1400	Distinct groups with no inherent order	t	2
5143	1400	Log-transformed values	f	3
5144	1400	Error bars only	f	4
5145	1401	Because color printing is impossible	f	1
5146	1401	Because of accessibility and color vision differences	t	2
5147	1401	Because color always reduces accuracy	f	3
5148	1401	Because legends cannot be used with color	f	4
5149	1402	Explaining a spike due to a known event	t	1
5150	1402	Adding decorative clipart	f	2
5151	1402	Removing all axis titles	f	3
5152	1402	Adding 3D shadows to bars	f	4
5153	1403	More gridlines	f	1
5154	1403	More chart borders	f	2
5155	1403	Remove non-essential elements and emphasize key marks	t	3
5156	1403	Use more fonts to separate sections	f	4
5157	1404	Use a long legend far from the lines	f	1
5158	1404	Directly label lines near their endpoints when possible	t	2
5159	1404	Use random abbreviations	f	3
5160	1404	Hide labels and rely on memory	f	4
5161	1405	To waste space and reduce information	f	1
5162	1405	To separate groups and improve scanning	t	2
5163	1405	To avoid any alignment	f	3
5164	1405	To hide missing data	f	4
5165	1406	False equivalence between categories	t	1
5166	1406	Better precision	f	2
5167	1406	Lower cognitive load	f	3
5168	1406	More accurate inference	f	4
5169	1407	Place the legend close to what it explains	t	1
5170	1407	Use different category names in each chart	f	2
5171	1407	Hide the legend to save space always	f	3
5172	1407	Use only acronyms with no expansion	f	4
5173	1408	Predicts future performance	t	1
5174	1408	Summarizes past outcomes only	f	2
5175	1408	Is always financial	f	3
5176	1408	Cannot be acted upon	f	4
5177	1409	Predicts next quarter exactly	f	1
5178	1409	Measures past performance outcomes	t	2
5179	1409	Is always a vanity metric	f	3
5180	1409	Is always real-time	f	4
5181	1410	Customer churn (leading) and website visits (lagging)	f	1
5182	1410	Website engagement (leading) and quarterly revenue (lagging)	t	2
5183	1410	Quarterly revenue (leading) and NPS (lagging)	f	3
5184	1410	Profit (leading) and conversion rate (lagging)	f	4
5185	1411	Actionable and tied to a goal	t	1
5186	1411	As complex as possible	f	2
5187	1411	Independent of business strategy	f	3
5188	1411	Unchanged forever	f	4
5189	1412	Real-time dashboards update continuously	t	1
5190	1412	Static dashboards cannot include charts	f	2
5191	1412	Real-time dashboards are always simpler	f	3
5192	1412	Static dashboards always predict the future	f	4
5193	1413	Quarterly board reporting	f	1
5194	1413	Fraud detection monitoring	t	2
5195	1413	Annual strategy review	f	3
5196	1413	Writing a textbook	f	4
5197	1414	Find the most important information first	t	1
5198	1414	Avoid reading titles	f	2
5199	1414	Increase the number of charts	f	3
5200	1414	Make all metrics equally prominent	f	4
5201	1415	20 to 30 KPIs to cover everything	f	1
5202	1415	3 to 7 core KPIs with supporting context	t	2
5203	1415	0 KPIs, only raw tables	f	3
5204	1415	Exactly 15 KPIs, no more, no less	f	4
5205	1416	Show churn rate with last month and target benchmark	t	1
5206	1416	Show churn rate with no units and no history	f	2
5207	1416	Show churn rate using random colors only	f	3
5208	1416	Show churn rate without defining churn	f	4
5209	1417	More predictive	f	1
5210	1417	Hard to use for decisions	t	2
5211	1417	Automatically ethical	f	3
5212	1417	More accurate	f	4
5213	1418	Providing clear definitions	f	1
5214	1418	Misleading scales that exaggerate effects	t	2
5215	1418	Including data sources	f	3
5216	1418	Using accessible colors	f	4
5217	1419	Selecting only data that supports a desired conclusion	t	1
5218	1419	Using seasonal colors	f	2
5219	1419	Choosing a bar chart for categories	f	3
5220	1419	Adding error bars	f	4
5221	1420	Hide data sources to avoid scrutiny	f	1
5222	1420	Include data source and definition notes	t	2
5223	1420	Use 3D effects to show confidence	f	3
5224	1420	Avoid uncertainty communication	f	4
5225	1421	Error bars or confidence bands	t	1
5226	1421	Random clipart icons	f	2
5227	1421	Only pie charts	f	3
5228	1421	No labels or scales	f	4
5229	1422	Time to answer business questions correctly	t	1
5230	1422	Number of colors used	f	2
5231	1422	Font family preference only	f	3
5232	1422	Number of animations	f	4
5233	1423	Compare accuracy and time before and after redesign	t	1
5234	1423	Count how many icons were used	f	2
5235	1423	Ask only if users like the colors	f	3
5236	1423	Remove all charts	f	4
5237	1424	Showing aggregated metrics only	f	1
5238	1424	Exposing individual-level sensitive data without need	t	2
5239	1424	Using clear axis labels	f	3
5240	1424	Using consistent category names	f	4
5241	1425	Always plot every raw point at once	f	1
5242	1425	Use aggregation, sampling, or density when needed	t	2
5243	1425	Avoid interaction	f	3
5244	1425	Avoid scales to keep it simple	f	4
5245	1426	A dashboard with drill-down and filtering	t	1
5246	1426	A static PDF screenshot only	f	2
5247	1426	A 3D spinning chart	f	3
5248	1426	A legend hidden behind menus	f	4
5249	1427	It can create false boundaries and uneven perception	t	1
5250	1427	It always improves accessibility	f	2
5251	1427	It reduces file size	f	3
5252	1427	It guarantees correct interpretation	f	4
5253	1428	They provide context for judging performance	t	1
5254	1428	They replace the need for units	f	2
5255	1428	They increase decoration	f	3
5256	1428	They make all charts 3D	f	4
5257	1429	Stacked area chart	t	1
5258	1429	Single pie chart	f	2
5259	1429	Dendrogram	f	3
5260	1429	Histogram	f	4
5261	1430	They reduce user agency	f	1
5262	1430	They can increase extraneous cognitive load	t	2
5263	1430	They always improve speed	f	3
5264	1430	They prevent filtering	f	4
5265	1431	A blank view with no data	f	1
5266	1431	A meaningful overview (for example, last 30 days)	t	2
5267	1431	A random segment each time	f	3
5268	1431	All possible dimensions expanded	f	4
5269	1432	They increase decoration	f	1
5270	1432	They add interpretive context (good or bad relative to something)	t	2
5271	1432	They reduce the need for axes	f	3
5272	1432	They turn lagging indicators into leading	f	4
5273	1433	Using many colors	f	1
5274	1433	Representing data truthfully without distortion	t	2
5275	1433	Making charts look modern	f	3
5276	1433	Maximizing animation usage	f	4
5277	1434	Using clear labels	f	1
5278	1434	Using a dual axis that can be scaled to suggest any relationship	t	2
5279	1434	Using a single axis	f	3
5280	1434	Using small multiples	f	4
5281	1435	Box plot with jittered points	t	1
5282	1435	3D pie chart	f	2
5283	1435	Word cloud	f	3
5284	1435	Single KPI card only	f	4
5285	1436	Consistent alignment and grid layout	t	1
5286	1436	Random placement of charts	f	2
5287	1436	Different font per widget	f	3
5288	1436	Hidden titles	f	4
5289	1437	It enables fair comparisons across panels	t	1
5290	1437	It increases decoration	f	2
5291	1437	It guarantees causality	f	3
5292	1437	It hides variability	f	4
5293	1438	Aligned with decision cadence (often daily or near real-time)	t	1
5294	1438	Once per year	f	2
5295	1438	Only when someone asks	f	3
5296	1438	Never updated to maintain consistency	f	4
5297	1439	Let users answer variations of the business question quickly	t	1
5298	1439	Add complexity regardless of need	f	2
5299	1439	Hide all data behind clicks	f	3
5300	1439	Replace definitions and documentation	f	4
5301	1440	A vague warning with no details	f	1
5302	1440	Drill-down or explanation to diagnose drivers	t	2
5303	1440	A 3D animation	f	3
5304	1440	More decorative icons	f	4
5305	1441	Median is more robust to outliers	t	1
5306	1441	Median always equals mean	f	2
5307	1441	Median requires no data	f	3
5308	1441	Median is only for categorical data	f	4
5309	1442	Only the color used	f	1
5310	1442	Formula, units, and time window	t	2
5311	1442	Only the chart type	f	3
5312	1442	Only the font	f	4
5313	1443	Different meanings for the same color on each page	f	1
5314	1443	Standardized naming, units, and color semantics	t	2
5315	1443	Random ordering of widgets	f	3
5316	1443	A different layout grid every time	f	4
5317	1444	Improve trust in analytics	f	1
5318	1444	Drive wrong decisions and harm credibility	t	2
5319	1444	Increase data quality automatically	f	3
5320	1444	Reduce the need for governance	f	4
5321	1445	It can reveal patterns hidden by raw-point overload	t	1
5322	1445	It always removes bias	f	2
5323	1445	It eliminates the need for labels	f	3
5324	1445	It guarantees causal inference	f	4
5325	1446	A continuously updating time-series with windowing	t	1
5326	1446	A static quarterly PDF	f	2
5327	1446	A pie chart for every event	f	3
5328	1446	A dendrogram updated yearly	f	4
5329	1447	Make data processing transparent and support analytic reasoning	t	1
5330	1447	Replace humans with automation	f	2
5331	1447	Use 3D charts everywhere	f	3
5332	1447	Avoid interaction and exploration	f	4
5333	1448	Reliability of the infrastructure availability.	f	1
5334	1448	Total cost of ownership of the infrastructure.	f	2
5335	1448	Scalability of infrastructure to needs.	f	3
5336	1448	Flexibility of infrastructure configuration.	t	4
5337	1449	Budgeting will only happen on an annual basis.	f	1
5338	1449	They will only pay for what they forecast.	f	2
5339	1449	Hardware procurement is done by a centralized team.	f	3
5340	1449	They will only pay for what they use.	t	4
5341	1450	Using the edge network to cache the whole application image in a backup.	f	1
5342	1450	By assigning a different IP address to each resource.	f	2
5343	1450	By putting resources in the Domain Name System (DNS).	f	3
5344	1450	By putting resources in different zones.	t	4
5345	1451	The customer is responsible for securing anything that they create within the cloud, such as the configurations, access policies, and user data.	t	1
5346	1451	The customer is responsible for security of the operating system, software stack required to run their applications and any hardware, networks, and physical security.	f	2
5347	1451	The customer is not responsible for any of the data in the cloud, as data management is the responsibility of the cloud provider who is hosting the data.	f	3
5348	1451	The customer is responsible for all infrastructure decisions, server configurations and database monitoring.	f	4
5349	1452	It's cost-effective, as all infrastructure costs are handled under a single monthly or annual subscription fee.	f	1
5350	1452	It’s efficient, as IaaS resources are available when needed and resources aren’t wasted by overbuilding capacity.	t	2
5351	1452	It reduces development time, as developers can go straight to coding instead of spending time setting up and maintaining a development environment.	f	3
5352	1452	It has low management overhead, as all administration and management tasks for data, servers, storage, and updates are handled by the cloud vendor.	f	4
5353	1453	Infrastructure as a Service (IaaS)	f	1
5354	1453	Software as a Service (SaaS)	f	2
5355	1453	Function as a Service (FaaS)	f	3
5356	1453	Platform as a Service (PaaS)	t	4
5357	1454	Software as a Service (SaaS)	t	1
5358	1454	IT as a service (ITaaS)	f	2
5359	1454	Infrastructure as a Service (IaaS)	f	3
5360	1454	Platform as a Service (PaaS)	f	4
5361	1455	A type of artificial intelligence that can create and sustain its own consciousness.	f	1
5362	1455	A type of artificial intelligence that can make decisions and take actions.	f	2
5363	1455	A type of artificial intelligence that can understand and respond to human emotions.	f	3
5364	1455	A type of artificial intelligence that can produce new content, including text, images, audio, and synthetic data.	t	4
5365	1456	Segmenting images into different parts or regions to extract information, such as the text on a sign.	f	1
5366	1456	Identifying the artist, title, or genre of a song to create playlists based on the user's listening habits.	f	2
5367	1456	Detecting people and objects in surveillance footage to use as evidence in criminal cases.	f	3
5368	1456	Identifying the topic and sentiment of customer email messages so that they can be routed to the relevant department.	t	4
5369	1457	Whether all the required information is present.	f	1
5370	1457	Whether the data is uniform and doesn’t contain any contradictory information.	t	2
5371	1457	Whether the data is up-to-date and reflects the current state of the phenomenon that is being modeled.	f	3
5372	1457	Whether a dataset is free from duplicate values that could prevent an ML model from learning accurately.	f	4
5373	1458	Content moderation	f	1
5374	1458	Clickbait detection	f	2
5375	1458	Video transcription	f	3
5376	1458	Personalized recommendations	t	4
5377	1459	AI should create unfair bias.	f	1
5378	1459	Google makes tools that empower others to harness AI for individual and collective benefit.	t	2
5379	1459	AI should gather or use information for surveillance.	f	3
5380	1459	Google makes tools that uphold high standards of operational excellence.	f	4
5381	1460	Machine learning	f	1
5382	1460	Artificial intelligence	t	2
5383	1460	Deep learning	f	3
5384	1460	Natural language processing	f	4
5385	1461	Implementing AI to develop a new product or service that has never been seen before.	f	1
5386	1461	Training a machine learning model to predict a search result ranking.	t	2
5387	1461	Using AI to replace a human decision-maker in complex situations, such as those involving life-or-death choices.	f	3
5388	1461	Using a reinforcement learning algorithm to train autonomous drones for package delivery.	f	4
5389	1462	Data analytics and business intelligence are used only in small businesses, whereas AI and ML are used exclusively by large corporations.	f	1
5390	1462	Data analytics and business intelligence identify trends from historical data, whereas AI and ML use data to make decisions for future business.	t	2
5391	1462	Data analytics and business intelligence use automated decision-making processes, whereas AI and ML require human intervention and interpretation of data.	f	3
5392	1462	Data analytics and business intelligence involve advanced algorithms for predicting future trends, whereas AI and ML focus on processing historical data.	f	4
5393	1463	Vision API	t	1
5394	1463	Natural Language API	f	2
5395	1463	Video Intelligence API	f	3
5396	1463	Speech-to-Text API	f	4
5397	1464	Discovery AI for Retail	f	1
5398	1464	Document AI	t	2
5399	1465	Contact Center AI	t	1
5400	1465	Document AI	f	2
5401	1466	Graphic Processing Unit (GPU)	f	1
5402	1466	Tensor Processing Unit (TPU)	t	2
5403	1466	Central Processing Unit (CPU)	f	3
5404	1466	Vertex Processing Unit (VPU)	f	4
5405	1467	Video Intelligence API	f	1
5406	1467	Vision API	f	2
5407	1467	Natural Language API	t	3
5408	1467	Speech-to-Text API	f	4
5409	1468	Build and evaluate machine learning models in BigQuery by using SQL.	t	1
5410	1468	Export small amounts of data to spreadsheets or other applications.	f	2
5411	1468	Seamlessly connect with a data science team to create an ML model.	f	3
5412	1469	BigQuery ML	f	1
5413	1469	AutoML	f	2
5414	1469	Custom training	t	3
5415	1469	Pre-trained APIs	f	4
5416	1470	Custome training	f	1
5417	1470	Managed ML environment	f	2
5418	1470	AutoML	t	3
5419	1470	MLOps	f	4
5420	1471	Reliability	t	1
5421	1471	Total cost of ownership	f	2
5422	1472	Traditional on-premises computing	f	1
5423	1472	Serverless computing	t	2
5424	1472	PaaS (platform as a service)	f	3
5425	1472	IaaS (infrastructure as a service)	f	4
5426	1473	Software layers above the firmware level	f	1
5427	1473	Software layers above the operating system level	t	2
5428	1473	Hardware layers above the electrical level	f	3
5429	1473	The entire machine	f	4
5430	1474	Move and improve	f	1
5431	1474	Refactor and reshape	f	2
5432	1474	Lift and shift	t	3
5433	1474	Reimagine and plan	f	4
5434	1475	Build and deploy	f	1
5435	1475	Move and improve	f	2
5436	1475	Lift and shift	t	3
5437	1475	Install and fall	f	4
5438	1476	Programming communication link	f	1
5439	1476	Application programming interface	t	2
5440	1476	Communication link interface	f	3
5441	1476	Network programming interface	f	4
5442	1477	Microservices	t	1
5443	1477	DevOps	f	2
5444	1478	Bare metal solution	t	1
5445	1478	SQL Server on Google Cloud	f	2
5446	1478	Google Cloud VMware Engine	f	3
5447	1478	AppEngine	f	4
5448	1479	Hybrid cloud	f	1
5449	1479	Multicloud	t	2
5450	1479	Edge cloud	f	3
5451	1479	Community cloud	f	4
5452	1480	Secure cloud	f	1
5453	1480	Hybrid cloud	t	2
5454	1480	Smart cloud	f	3
5455	1480	Agile cloud	f	4
5456	1481	Configuring the customer's applications.	f	1
5457	1481	Maintaining the customer's infrastructure.	t	2
5458	1481	Securing the customer's data.	f	3
5459	1481	Managing the customer's user access.	f	4
5460	1482	Large upfront capital investment.	f	1
5461	1482	Having physical access to hardware.	f	2
5462	1482	Only having to install security updates on a weekly basis.	f	3
5463	1482	Increased scalability.	t	4
5464	1483	Certificates, intelligence, and authentication	f	1
5465	1483	Confidentiality, integrity, and availability	t	2
5466	1483	Compliance, identity, and access management	f	3
5467	1483	Containers, infrastructure, and architecture	f	4
5468	1484	A network security device that monitors and controls incoming and outgoing network traffic based on predefined security rules	t	1
5469	1484	A set of security measures designed to protect a computer system or network from cyber attacks	f	2
5470	1484	A software program that encrypts data to make it unreadable to unauthorized users	f	3
5471	1484	A security model that assumes no user or device can be trusted by default	f	4
5472	1485	Security by default	f	1
5473	1485	Privileged access	f	2
5474	1485	Zero-trust architecture	f	3
5475	1485	Least privilege	t	4
5476	1486	Zero trust security	f	1
5477	1486	Cloud security posture management (CSPM)	f	2
5478	1486	Site reliability engineering (SRE)	f	3
5479	1486	Security operations (SecOps)	t	4
5480	1487	Lattice-Based Cryptography (LBC)	f	1
5481	1487	Post-quantum cryptography (PQC)	f	2
5482	1487	Advanced Encryption Standard (AES)	t	3
5483	1487	Isomorphic encryption (IE)	f	4
5484	1488	IAM provides granular control over who has access to Google Cloud resources and what they can do with those resources.	t	1
5485	1488	IAM is a cloud service that encrypts cloud-based data at rest and in transit.	f	2
5486	1488	IAM is a cloud security information and event management solution that collects and analyzes log data from cloud security devices and applications.	f	3
5487	1489	Data Center Infrastructure Efficiency (DCiE)	f	1
5488	1489	Power Usage Effectiveness (PUE)	t	2
5489	1489	Energy Efficiency Ratio (EER)	f	3
5490	1489	Total cost of ownership (TCO)	f	4
5491	1490	Data in transit	f	1
5492	1490	Data lake	f	2
5493	1490	Data in use	t	3
5494	1490	Data at rest	f	4
5495	1491	Security information and event management (SIEM)	f	1
5496	1491	Firewall as a service (FaaS)	f	2
5497	1491	Data loss prevention (DLP)	f	3
5498	1491	Two-step verification (2SV)	t	4
5499	1491	Trust and Security with Google Cloud	f	5
5500	1492	Google Cloud console	f	1
5501	1492	Cloud Storage client libraries	f	2
5502	1492	Compliance resource center	t	3
5503	1493	Compliance reports	f	1
5504	1493	Billing reports	f	2
5505	1493	Transparency reports	t	3
5506	1493	Security reports	f	4
5507	1494	All customer data is encrypted by default.	t	1
5508	1494	We give "backdoor" access to government entities when requested.	f	2
5509	1494	Google sells customer data to third parties.	f	3
5510	1494	Google Cloud uses customer data for advertising.	f	4
5511	1495	Data consistency	f	1
5512	1495	Data redundancy	f	2
5513	1495	Data sovereignty	t	3
5514	1495	Data residency	f	4
5515	1496	Competency center	f	1
5516	1496	Center of innovation	f	2
5517	1496	Center of excellence	t	3
5518	1496	Hub center	f	4
5519	1497	Resources	t	1
5520	1497	Organization node	f	2
5521	1498	Cost forecasting	f	1
5522	1498	Cloud billing reports	t	2
5523	1498	Resource usage	f	3
5524	1498	Cost bugdet	f	4
5525	1499	Inheritance in the hierarchy reduces the overall cost of cloud computing.	f	1
5526	1499	Faster propagation can simplify a cloud migration.	f	2
5527	1499	Resources at lower levels can improve the performance of cloud applications.	f	3
5528	1499	Permissions set at higher levels of the resource hierarchy are automatically inherited by lower-level resources.	t	4
5529	1500	Billing reports	f	1
5530	1500	Invoicing limits	f	2
5531	1500	Quota policies	t	3
5532	1500	Committed use discounts	f	4
5533	1501	Budget threshold rules	t	1
5534	1501	Billing reports	f	2
5535	1501	Cost optimization recommendations	f	3
5536	1501	Cost forecasting	f	4
5537	1502	Site reliability engineer	t	1
5538	1502	Cloud architect	f	2
5539	1502	DevOps engineer	f	3
5540	1502	Cloud security engineer	f	4
5541	1503	It provides a comprehensive view of your cloud infrastructure and applications.	f	1
5542	1503	It identifies how much CPU power, memory, and other resources an application uses.	t	2
5543	1503	It collects and stores all application and infrastructure logs.	f	3
5544	1503	It counts, analyzes, and aggregates the crashes in running cloud services in real-time.	f	4
5545	1504	How long it takes for a particular part of a system to return a result.	t	1
5546	1504	How close to capacity a system is.	f	2
5547	1504	How many requests reach a system.	f	3
5548	1504	System failures or other issues.	f	4
5549	1505	It duplicates critical components or resources to provide backup alternatives.	f	1
5550	1505	It monitors and controls incoming and outgoing network traffic based on predetermined security rules.	f	2
5551	1505	It scales infrastructure to handle varying workloads and accommodate increased demand.	f	3
5552	1505	It creates multiple copies of data or services and distributes them across different servers or locations.	t	4
5553	1506	Service level contracts	f	1
5554	1506	Service level indicators	t	2
5555	1506	Service level objectives	f	3
5556	1506	Service level agreements	f	4
5557	1507	Backups	t	1
5558	1507	Security patches	f	2
5559	1507	Inventory data	f	3
5560	1507	Log files	f	4
5561	1508	It uses BigQuery and Looker Studio to build and deploy machine learning models.	f	1
5562	1508	It uses BigQuery and Looker Studio to create dashboards that provide granular operational insights.	t	2
5563	1508	It uses BigQuery and Looker Studio to containerize workloads.	f	3
5564	1508	It uses BigQuery and Looker Studio to comply with government regulations.	f	4
5565	1509	To be the first major company to operate completely carbon free.	t	1
5566	1509	To be the first major company to run its own wind farm.	f	2
5567	1509	To be the first major company to be carbon neutral.	f	3
5568	1509	To be the first major company to achieve 100% renewable energy.	f	4
5569	1510	It’s a framework for sustainable procurement, which is the process of purchasing goods and services in a way that minimizes environmental and social impacts.	f	1
5570	1510	It’s a framework for identifying, predicting, and evaluating the environmental impacts of a proposed project.	f	2
5571	1510	It’s a framework for an organization to enhance its environmental performance through improving resource efficiency and reducing waste.	t	3
5572	1510	It’s a framework for carbon footprinting that calculates the total amount of greenhouse gas emissions associated with a product, service, or organization.	f	4
5573	1511	It's cost effective, so the organization will no longer have to pay for computing once the app is in the cloud.	t	1
5574	1511	It's scalable, so the organization could shorten their infrastructure deployment time.	f	2
5575	1511	It provides physical access, so the organization can deploy servers faster.	f	3
5576	1511	It's secure, so the organization won't have to worry about the new subscribers data.	f	4
5577	1512	Software as a service	f	1
5578	1512	Public Cloud	f	2
5579	1512	Private Cloud	t	3
5580	1512	Platform as a service	f	4
5581	1513	Open source software makes it easier to patent proprietary software.	f	1
5582	1513	Open standards make it easier to hire more developers.	f	2
5583	1513	Open source software reduces the chance of vendor lock-in.	t	3
5584	1513	On-premises software isn't open source, so cloud applications are more portable.	f	4
5585	1514	Sustainable cloud ensures the costs of cloud resources are controlled to prevent budget overrun.	f	1
5586	1514	A trusted cloud gives control of all resources to the user to ensure high availability at all times.	f	2
5587	1514	Data cloud provides a unified solution to manage data across the entire data lifecycle.	t	3
5588	1514	Open infrastructure gives the freedom to innovate by buying cheaper more hardware and software.	f	4
5589	1515	Organizations risk losing market leadership if they spend too much time on digital transformation.	f	1
5590	1515	Embracing new technology can cause organizations to overspend on innovation.	f	2
5591	1515	Focusing on ‘why’ they operate can lead to inefficient use of resources and disruption.	f	3
5592	1515	Focusing on ‘how’ they operate can prevent organizations from seeing transformation opportunities.	t	4
5593	1516	Maintenance workers do not have physical access to the servers.	f	1
5594	1516	Scaling processing is too difficult due to power consumption.	f	2
5595	1516	The on-premises networking is more complicated.	f	3
5596	1516	The on-premises hardware procurement process can take a long time.	t	4
5597	1517	A Google product for computing large amounts of data.	f	1
5598	1517	A metaphor for the networking capability of internet providers.	f	2
5599	1517	A metaphor for a network of data centers.	t	3
5600	1517	A Google product made up of on-premises IT infrastructure.	f	4
5601	1518	Ensure better security by decoupling teams and their data.	f	1
5602	1518	Break down data silos and generate real time insights.	t	2
5603	1518	Streamline their hardware procurement process to forecast at least a quarter into the future.	f	3
5604	1518	Reduce emissions by using faster networks in their on-premises workloads.	f	4
5605	1519	When an organization uses new digital technologies to create or modify on-premises business processes.	f	1
5606	1519	When an organization uses new digital technologies to create or modify technology infrastructure to focus on cost saving.	f	2
5607	1519	When an organization uses new digital technologies to create or modify business processes, culture, and customer experiences.	t	3
5608	1519	When an organization uses new digital technologies to create or modify financial models for how a business is run.	f	4
5609	1520	The process of collecting and storing data for future use	f	1
5610	1520	The process of analyzing data to gain insights and make informed decisions	f	2
5611	1520	The process of setting internal data policies and ensuring compliance with external standards	t	3
5612	1520	The process of deleting unnecessary data to save storage space	f	4
5613	1521	A relational database	t	1
5614	1521	An XML database	f	2
5615	1521	An object database	f	3
5616	1521	A non-relational database	f	4
5617	1522	Google Cloud Marketplace	t	1
5618	1522	App Engine	f	2
5619	1522	Google Cloud console	f	3
5620	1522	Google Play	f	4
5621	1523	Semi-structured data	f	1
5622	1523	Unstructured data	f	2
5623	1523	Structured data	t	3
5624	1523	A hybrid of structured, semi-structured, and unstructured data	f	4
5625	1524	Data lake	t	1
5626	1524	Data warehouse	f	2
5627	1524	Database	f	3
5628	1524	Data archive	f	4
5629	1525	Through machine learning, with every click that the user makes, their website experience becomes increasingly personalized.	t	1
5630	1525	Machine learning can be used to make all users see the same product recommendations, regardless of their preferences or behavior.	f	2
5631	1525	Machine learning can help identify user behavior in real time, but cannot make personalized suggestions based on the data.	f	3
5632	1525	Through machine learning, a user’s credit card transactions can be analyzed to determine regular purchases.	f	4
5633	1526	Data analysis	f	1
5634	1526	Data processing	t	2
5635	1526	Data storage	f	3
5636	1526	Data genesis	f	4
5637	1527	Using GPS coordinates to power a ride-sharing app	f	1
5638	1527	Analyzing historical sales figures to predict future trends	f	2
5639	1527	Creating visualizations from seasonal weather data	f	3
5640	1527	Analyzing social media posts to identify sentiment toward a brand	t	4
5641	1528	Second-party data	f	1
5642	1528	Third-party data	f	2
5643	1528	First-party data	t	3
5644	1529	Accessibility only within one region	f	1
5645	1529	Geo-redundancy if data is stored in a multi-region or dual-region	t	2
5646	1529	Maximum storage limits	f	3
5647	1529	High latency and low durability	f	4
5648	1530	Storage and analytics	t	1
5649	1530	Compute and analytics	f	2
5650	1530	Migration and analytics	f	3
5651	1530	Networking and storage	f	4
5652	1531	Dataprep	f	1
5653	1531	Datastream	t	2
5654	1531	Pub/Sub	f	3
5655	1531	Dataproc	f	4
3138	896	A single pie chart	f	2
5656	1532	Cloud SQL	f	1
5657	1532	Bigtable	f	2
5658	1532	Firestore	f	3
5659	1532	Spanner	t	4
5660	1533	Lift and shift	t	1
5661	1533	Refactoring	f	2
5662	1533	Managed database migration	f	3
5663	1533	Remain on-premises	f	4
5664	1534	Archive	f	1
5665	1534	Coldline	t	2
5666	1534	Standard	f	3
5667	1534	Nearline	f	4
5668	1535	Cloud Storage	t	1
5669	1535	Cloud SQL	f	2
5670	1535	Firestore	f	3
5671	1535	BigQuery	f	4
5672	1536	Spanner	f	1
5673	1536	Cloud SQL	f	2
5674	1536	Bigtable	t	3
5675	1536	Cloud Storage	f	4
5676	1537	Cloud Storage	f	1
5677	1537	Spanner	f	2
5678	1537	Bigtable	f	3
5679	1537	Cloud SQL	t	4
5680	1538	Security is more effective when BigQuery is run in on-premises environments.	f	1
5681	1538	Data teams can eradicate data silos by analyzing data across multiple cloud providers.	t	2
5682	1538	BigQuery lets organizations save costs by limiting the number of cloud providers they use.	f	3
5683	1538	Multicloud support in BigQuery is only intended for use in disaster recovery scenarios.	f	4
5684	1539	It supports over 60 different SQL databases.	f	1
5685	1539	It’s cost effective.	f	2
5686	1539	It’s 100% web based.	t	3
5687	1539	It creates easy to understand visualizations.	f	4
5688	1540	Dataplex	f	1
5689	1540	Cloud Storage	f	2
5690	1540	Looker	t	3
5691	1540	Dataflow	f	4
5692	1541	Medical test results	f	1
5693	1541	Payroll records	f	2
5694	1541	Customer email addresses	f	3
5695	1541	Temperature sensors	t	4
5696	1542	Enhanced transaction logic	f	1
5697	1542	Event-time logic	f	2
5698	1542	Extract, transform, and load	t	3
5699	1542	Enrichment, tagging, and labeling	f	4
5700	1543	It’s a cloud-based data warehouse for storing and analyzing streaming and batch data.	f	1
5701	1543	It’s a messaging service for receiving messages from various device streams.	f	2
5702	1543	It handles infrastructure setup and maintenance for processing pipelines.	t	3
5703	1543	It allows easy data cleaning and transformation through visual tools and machine learning-based suggestions.	f	4
5704	1544	Kubernetes	t	1
5705	1544	Go	f	2
5706	1544	TensorFlow	f	3
5707	1544	Angular	f	4
5708	1545	Containers	f	1
5709	1545	Virtual machine instances	t	2
5710	1545	Colocation	f	3
5711	1545	A local development environment	f	4
5712	1546	Software layers above the operating system level	t	1
5713	1546	The entire machine	f	2
5714	1546	Software layers above the firmware level	f	3
5715	1546	Hardware layers above the electrical level	f	4
5716	1547	Security	f	1
5717	1547	Total cost of ownership	f	2
5718	1547	Flexibility	f	3
5719	1547	Reliability	t	4
5720	1548	Traditional on-premises computing	f	1
5721	1548	PaaS (platform as a service)	f	2
5722	1548	IaaS (infrastructure as a service)	f	3
5723	1548	Serverless computing	t	4
5724	1549	Monoliths	f	1
5725	1549	Containers	f	2
5726	1549	DevOps	f	3
5727	1549	Microservices	t	4
5728	1550	Programming communication link	f	1
5729	1550	Network programming interface	f	2
5730	1550	Communication link interface	f	3
5731	1550	Application programming interface	t	4
5732	1551	Lift and shift	t	1
5733	1551	Build and deploy	f	2
5734	1551	Move and improve	f	3
5735	1551	Install and fall	f	4
5736	1552	Hybrid cloud	t	1
5737	1552	Secure cloud	f	2
5738	1552	Smart cloud	f	3
5739	1552	Multicloud	f	4
5740	1553	Bare metal solution	t	1
5741	1553	App Engine	f	2
5742	1553	SQL Server on Google Cloud	f	3
5743	1553	Google Cloud VMware Engine	f	4
5744	1554	Containers	f	1
5745	1554	DevOps	f	2
5746	1554	Cloud security	f	3
5747	1554	Managed services	t	4
5748	1555	Container Registry	f	1
5749	1555	Google Kubernetes Engine	f	2
5750	1555	Knative	f	3
5751	1555	GKE Enterprise	t	4
5752	1556	By developing new products and services internally	f	1
5753	1556	By allowing developers to access their data for free	f	2
5754	1556	By using APIs to track customer shipments	f	3
5755	1556	By charging developers to access their APIs	t	4
5756	1557	Apigee	t	1
5757	1557	AppSheet	f	2
5758	1557	App Engine	f	3
5759	1557	Cloud API Manager	f	4
5760	1558	Hybrid cloud	f	1
5761	1558	Community cloud	f	2
5762	1558	Multicloud	t	3
5763	1558	Edge cloud	f	4
5764	1559	Ransomware	t	1
5765	1559	Spyware	f	2
5766	1559	Virus	f	3
5767	1559	Trojan	f	4
5768	1559	Which cybersecurity threat demands a ransom payment from a victim to regain access to their files and systems.	f	5
5769	1560	Increased scalability	t	1
5770	1560	Only having to install security updates on a weekly basis.	f	2
5771	1560	Having physical access to hardware.	f	3
5772	1560	Large upfront capital investment.	f	4
5773	1561	Increased scalability.	t	1
5774	1561	Only having to install security updates on a weekly basis.	f	2
5775	1561	Having physical access to hardware.	f	3
5776	1561	Large upfront capital investment.	f	4
5777	1562	Configuring the customer's applications.	f	1
5778	1562	Securing the customer's data.	f	2
5779	1562	Managing the customer's user access.	f	3
5780	1562	Maintaining the customer's infrastructure.	t	4
5781	1563	Integrity	f	1
5782	1563	Confidentiality	f	2
5783	1563	Control	f	3
5784	1563	Compliance	t	4
5785	1564	Least privilege	t	1
5786	1564	Zero-trust architecture	f	2
5787	1564	Privileged access	f	3
5788	1564	Security by default	f	4
5789	1565	Configuration mishaps	t	1
5790	1565	Phishing	f	2
5791	1565	Virus	f	3
5792	1565	Malware	f	4
5793	1566	Ransomware	f	1
5794	1566	Malware	f	2
5795	1566	Phishing	t	3
5796	1566	Configuration mishap	f	4
5797	1567	Confidentiality	f	1
5798	1567	Compliance	f	2
5799	1567	Integrity	t	3
5800	1567	Control	f	4
5801	1568	Certificates, intelligence, and authentication	f	1
5802	1568	Compliance, identity, and access management	f	2
5803	1568	Containers, infrastructure, and architecture	f	3
5804	1568	Confidentiality, integrity, and availability	t	4
5805	1569	A software program that encrypts data to make it unreadable to unauthorized users	f	1
5806	1569	A security model that assumes no user or device can be trusted by default	f	2
5807	1569	A network security device that monitors and controls incoming and outgoing network traffic based on predefined security rules	t	3
5808	1569	A set of security measures designed to protect a computer system or network from cyber attacks	f	4
5809	1570	Cloud Storage	f	1
5810	1570	Compute Engine	f	2
5811	1570	BigQuery	t	3
5812	1570	Vertex AI	f	4
5813	1571	Looker	f	1
5814	1571	Pub/Sub	t	2
5815	1571	Dataproc	f	3
5816	1571	Dataplex	f	4
2873	830	To decorate a report with charts	f	1
2874	830	To enable understanding and decisions	t	2
2875	830	To increase the number of metrics shown	f	3
2876	830	To replace analysis with visuals	f	4
2877	831	A KPI is always less specific than a metric	f	1
2878	831	A metric is always tied to a strategic goal	f	2
2879	831	All KPIs are metrics, but not all metrics are KPIs	t	3
2880	831	Metrics and KPIs are identical terms	f	4
2881	832	Which color palette looks best?	f	1
2882	832	What business question am I answering?	t	2
2883	832	How many categories can I fit?	f	3
2884	832	Can I make it interactive?	f	4
2885	833	Making the chart more colorful	f	1
2886	833	Reducing the need for data	f	2
2887	833	Helping the audience interpret meaning	t	3
2888	833	Replacing labels with icons	f	4
2889	834	Clear axis labels	f	1
2890	834	Unnecessary 3D effects and decorations	t	2
2891	834	A concise title	f	3
2892	834	Consistent scales	f	4
2893	835	Ink used for non-data decoration	f	1
2894	835	Ink used to represent data	t	2
2895	835	The number of gridlines	f	3
2896	835	The number of colors	f	4
2897	836	Looks good but is not actionable	t	1
2898	836	Has a clear owner and action plan	f	2
2899	836	Is always a leading indicator	f	3
2900	836	Is required for financial reporting	f	4
2901	837	Remove all annotations	f	1
2902	837	Add a clear takeaway title and brief labels	t	2
2903	837	Use a rainbow palette	f	3
2904	837	Use 3D bars to highlight differences	f	4
2905	838	The dashboard becomes less interactive	f	1
2906	838	Decision-makers lose focus and miss key signals	t	2
2907	838	The data becomes more accurate	f	3
2908	838	The KPIs become leading indicators	f	4
2909	839	A collection of every chart available	f	1
2910	839	A decision-support view of key measures and trends	t	2
2911	839	A replacement for databases	f	3
2912	839	A static report with no interaction	f	4
2913	840	Read detailed annotations faster	f	1
2914	840	Quickly detect simple visual differences	t	2
2915	840	Compute exact averages visually	f	3
2916	840	Ignore all visual cues	f	4
2917	841	Angle in a pie chart	f	1
2918	841	Area of bubbles	f	2
2919	841	Position on a common scale	t	3
2920	841	Color hue	f	4
2921	842	Show as many charts as possible	f	1
2922	842	Rely on long legends and dense text	f	2
2923	842	Use clear hierarchy and reduce clutter	t	3
2924	842	Avoid any labels to reduce reading	f	4
2925	843	Intrinsic load	f	1
2926	843	Extraneous load	t	2
2927	843	Germane load	f	3
2928	843	Motor load	f	4
2929	844	Effort spent on irrelevant visual features	f	1
2930	844	Effort spent building useful understanding	t	2
2931	844	Effort caused by data size only	f	3
2932	844	Effort caused by using colorblind palettes	f	4
2933	845	Seeing any colors	f	1
2934	845	Noticing changes without attention cues	t	2
2935	845	Reading axis titles	f	3
2936	845	Comparing bar heights	f	4
2937	846	Fixation duration	t	1
2938	846	Saccade amplitude	f	2
2939	846	Blink rate only	f	3
2940	846	Screen refresh rate	f	4
2941	847	A slow drift during reading	f	1
2942	847	A rapid eye movement between fixations	t	2
2943	847	A type of color scale	f	3
2944	847	A dashboard filter	f	4
2945	848	Too much visual competition and weak hierarchy	t	1
2946	848	Using a bar chart instead of a pie chart	f	2
2947	848	Having a title	f	3
2948	848	Using a consistent axis	f	4
2949	849	They hide variation across groups	f	1
2950	849	They allow comparison across consistent scales	t	2
2951	849	They eliminate the need for data cleaning	f	3
2952	849	They always reduce computation cost	f	4
2953	850	Unrelated	f	1
2954	850	Part of the same group	t	2
2955	850	Always larger	f	3
2956	850	Always more important	f	4
2957	851	Random noise	f	1
2958	851	Belonging together	t	2
2959	851	Less relevant	f	3
2960	851	Numerically equal	f	4
2961	852	Complete forms	t	1
2962	852	More colorful	f	2
2963	852	Always misleading	f	3
2964	852	Only decorative	f	4
2965	853	Smooth, continuous paths	t	1
2966	853	Maximum number of angles	f	2
2967	853	Random direction changes	f	3
2968	853	Only vertical lines	f	4
2969	854	Distinguishing foreground marks from background	t	1
2970	854	Choosing a database schema	f	2
2971	854	Computing medians	f	3
2972	854	Sorting a table alphabetically	f	4
2973	855	Place related filters near the charts they control	t	1
2974	855	Use random spacing between related items	f	2
2975	855	Use different fonts for each label	f	3
2976	855	Hide legends to reduce space	f	4
2977	856	Use the same color for the same category across views	t	1
2978	856	Change category colors on every chart	f	2
2979	856	Use 3D shading for all marks	f	3
2980	856	Use different units per chart without labels	f	4
2981	857	Elements moving together are grouped	t	1
2982	857	Elements with different sizes are grouped	f	2
2983	857	Elements with different fonts are grouped	f	3
2984	857	Elements on different pages are grouped	f	4
2985	858	Putting related KPIs inside the same panel box	t	1
2986	858	Changing all axis titles to italics	f	2
2987	858	Using a rainbow palette	f	3
2988	858	Removing all whitespace	f	4
2989	859	Using consistent legend placement	f	1
2990	859	Using the same color for different categories	t	2
2991	859	Using clear units on axes	f	3
2992	859	Using a single scale in small multiples	f	4
2993	860	Comparing quantities across categories	t	1
2994	860	Showing distribution shape of one variable	f	2
2995	860	Showing relationship between two numeric variables	f	3
2996	860	Showing network connectivity	f	4
2997	861	Ranking product categories	f	1
2998	861	Trends over ordered time	t	2
2999	861	Part-to-whole at one time point	f	3
3000	861	Comparing medians across groups	f	4
3001	862	Showing correlation or relationship between two numeric variables	t	1
3002	862	Showing a single total	f	2
3003	862	Showing text narratives only	f	3
3004	862	Showing hierarchical decomposition only	f	4
3005	863	A time-series trend	f	1
3006	863	A frequency distribution	t	2
3007	863	A part-to-whole breakdown	f	3
3008	863	A network of entities	f	4
3009	864	Means only	f	1
3010	864	Distributions across groups (median, spread, outliers)	t	2
3011	864	Only correlations	f	3
3012	864	Only proportions	f	4
3013	865	Kernel density shape of the distribution	t	1
3014	865	Exact minimum and maximum only	f	2
3015	865	A second y-axis	f	3
3016	865	A regression line	f	4
3017	866	Hierarchical part-to-whole structure	t	1
3018	866	Precise comparison of small differences	f	2
3019	866	Correlation between two variables	f	3
3020	866	A timeline with events	f	4
3021	867	A single total by category	f	1
3022	867	Intensity values across a grid (two dimensions)	t	2
3023	867	Only ranks of categories	f	3
3024	867	Only a story narrative	f	4
3025	868	When there are many categories (10+)	f	1
3026	868	When comparing small differences precisely	f	2
3027	868	When showing a few parts of a whole (with clear differences)	t	3
3028	868	When showing trends over time	f	4
3029	869	Stacked bar chart	t	1
3030	869	3D pie chart	f	2
3031	869	Word cloud	f	3
3032	869	Random scatter plot	f	4
3033	870	Compare multiple metrics for a few entities	t	1
3034	870	Show distributions of one variable	f	2
3035	870	Show causal effects conclusively	f	3
3036	870	Replace time series analysis	f	4
3037	871	High-dimensional data patterns	t	1
3038	871	Only two-variable comparisons	f	2
3039	871	Only part-to-whole	f	3
3040	871	Only storytelling titles	f	4
3041	872	Hierarchical clustering structure	t	1
3042	872	Time series seasonality	f	2
3043	872	A single KPI trend	f	3
3044	872	A map projection	f	4
3045	873	Box plot	t	1
3046	873	Pie chart	f	2
3047	873	Area chart	f	3
3048	873	Simple table only	f	4
3049	874	There are too few data points	f	1
3050	874	Many points overlap in the same area	t	2
3051	874	Axes start at zero	f	3
3052	874	You use clear labels	f	4
3053	875	Use hexbin or density plots	t	1
3054	875	Add 3D perspective	f	2
3055	875	Remove the axes	f	3
3056	875	Use more random colors	f	4
3057	876	Attached to geographic areas (regions)	t	1
3058	876	Attached to individual customers only	f	2
3059	876	Purely categorical with no location meaning	f	3
3060	876	Only time-based with no spatial dimension	f	4
3061	877	People compare diameter or area inconsistently	t	1
3062	877	They always start at zero	f	2
3063	877	They have too many labels by definition	f	3
3064	877	They cannot show categories	f	4
3065	878	Area chart	t	1
3066	878	Pie chart	f	2
3067	878	Dendrogram	f	3
3068	878	Word cloud	f	4
3069	879	Making the chart look beautiful only	f	1
3070	879	Mapping data fields to visual properties	t	2
3071	879	Choosing a database	f	3
3072	879	Writing a narrative paragraph	f	4
3073	880	Database joins	f	1
3074	880	Graphical marks like points, lines, and bars	t	2
3075	880	Only chart titles	f	3
3076	880	Only color palettes	f	4
3077	881	Transforming data values into visual space	t	1
3078	881	Writing tooltips	f	2
3079	881	Collecting raw data	f	3
3080	881	Removing outliers automatically	f	4
3081	882	Splitting a plot into small multiples by category	t	1
3082	882	Hiding missing values	f	2
3083	882	Making a chart 3D	f	3
3084	882	Removing axes	f	4
3085	883	A scatter plot with a regression line on top	t	1
3086	883	Changing the font size of the title	f	2
3087	883	Sorting a table alphabetically	f	3
3088	883	Deleting the legend	f	4
3089	884	Data	f	1
3090	884	Geoms	f	2
3091	884	Scales	f	3
3092	884	Randomness generator	t	4
3093	885	How data is filtered	f	1
3094	885	How data is mapped into x and y space (for example, polar)	t	2
3095	885	How many rows exist in the dataset	f	3
3096	885	Whether data is valid	f	4
3097	886	Limits you to a fixed catalog of chart types	f	1
3098	886	Builds many visual forms from reusable components	t	2
3099	886	Eliminates the need for scales	f	3
3100	886	Avoids encoding decisions	f	4
3101	887	An aesthetic mapping	t	1
3102	887	A data join	f	2
3103	887	A database index	f	3
3104	887	A colorblind correction	f	4
3105	888	Ensuring consistent scales	f	1
3106	888	Creating visual clutter without a clear purpose	t	2
3107	888	Using a single legend	f	3
3108	888	Adding an informative annotation	f	4
3109	889	Customer segment name	t	1
3110	889	Rank position (1st, 2nd, 3rd)	f	2
3111	889	Temperature in Celsius	f	3
3112	889	Revenue in euros	f	4
3113	890	Product ID number	f	1
3114	890	Satisfaction rating (low, medium, high)	t	2
3115	890	Longitude coordinate	f	3
3116	890	Exact salary value	f	4
3117	891	Reducing file size	f	1
3118	891	Exaggerating differences visually	t	2
3119	891	Improving accuracy	f	3
3120	891	Preventing comparisons	f	4
3121	892	Because bars encode values by length	t	1
3122	892	Because bars encode values by color hue	f	2
3123	892	Because it makes the chart more colorful	f	3
3124	892	Because it increases the number of categories	f	4
3125	893	Values are all between 0 and 1	f	1
3126	893	Data spans multiple orders of magnitude	t	2
3127	893	Categories are nominal only	f	3
3128	893	You want to hide variation	f	4
3129	894	Make unrelated trends look correlated	t	1
3130	894	Increase data accuracy	f	2
3131	894	Reduce the need for labels	f	3
3132	894	Always improve clarity	f	4
3133	895	Color luminance or saturation	t	1
3134	895	Aligned position	f	2
3135	895	Length on a common baseline	f	3
3136	895	Ordered position on an axis	f	4
3137	896	Small multiple box plots	t	1
3139	896	A 3D area chart	f	3
3140	896	A word cloud	f	4
3141	897	Use vague titles like 'Chart 1'	f	1
3142	897	Include units and clear axis descriptions	t	2
3143	897	Use rotated text everywhere	f	3
3144	897	Remove labels to reduce clutter always	f	4
3145	898	Random order to avoid bias	f	1
3146	898	Alphabetical order always	f	2
3147	898	Order by value when comparison is the goal	t	3
3148	898	Order by color brightness	f	4
3149	899	Ordered numeric intensity (low to high)	t	1
3150	899	Unordered categories	f	2
3151	899	Two-sided deviation around zero only	f	3
3152	899	Labeling axes	f	4
3153	900	Categorical product types	f	1
3154	900	Values around a meaningful midpoint (for example, 0)	t	2
3155	900	Time ordering	f	3
3156	900	Random sampling	f	4
3157	901	Ordered magnitudes	f	1
3158	901	Distinct groups with no inherent order	t	2
3159	901	Log-transformed values	f	3
3160	901	Error bars only	f	4
3161	902	Because color printing is impossible	f	1
3162	902	Because of accessibility and color vision differences	t	2
3163	902	Because color always reduces accuracy	f	3
3164	902	Because legends cannot be used with color	f	4
3165	903	Explaining a spike due to a known event	t	1
3166	903	Adding decorative clipart	f	2
3167	903	Removing all axis titles	f	3
3168	903	Adding 3D shadows to bars	f	4
3169	904	More gridlines	f	1
3170	904	More chart borders	f	2
3171	904	Remove non-essential elements and emphasize key marks	t	3
3172	904	Use more fonts to separate sections	f	4
3173	905	Use a long legend far from the lines	f	1
3174	905	Directly label lines near their endpoints when possible	t	2
3175	905	Use random abbreviations	f	3
3176	905	Hide labels and rely on memory	f	4
3177	906	To waste space and reduce information	f	1
3178	906	To separate groups and improve scanning	t	2
3179	906	To avoid any alignment	f	3
3180	906	To hide missing data	f	4
3181	907	False equivalence between categories	t	1
3182	907	Better precision	f	2
3183	907	Lower cognitive load	f	3
3184	907	More accurate inference	f	4
3185	908	Place the legend close to what it explains	t	1
3186	908	Use different category names in each chart	f	2
3187	908	Hide the legend to save space always	f	3
3188	908	Use only acronyms with no expansion	f	4
3189	909	Predicts future performance	t	1
3190	909	Summarizes past outcomes only	f	2
3191	909	Is always financial	f	3
3192	909	Cannot be acted upon	f	4
3193	910	Predicts next quarter exactly	f	1
3194	910	Measures past performance outcomes	t	2
3195	910	Is always a vanity metric	f	3
3196	910	Is always real-time	f	4
3197	911	Customer churn (leading) and website visits (lagging)	f	1
3198	911	Website engagement (leading) and quarterly revenue (lagging)	t	2
3199	911	Quarterly revenue (leading) and NPS (lagging)	f	3
3200	911	Profit (leading) and conversion rate (lagging)	f	4
3201	912	Actionable and tied to a goal	t	1
3202	912	As complex as possible	f	2
3203	912	Independent of business strategy	f	3
3204	912	Unchanged forever	f	4
3205	913	Real-time dashboards update continuously	t	1
3206	913	Static dashboards cannot include charts	f	2
3207	913	Real-time dashboards are always simpler	f	3
3208	913	Static dashboards always predict the future	f	4
3209	914	Quarterly board reporting	f	1
3210	914	Fraud detection monitoring	t	2
3211	914	Annual strategy review	f	3
3212	914	Writing a textbook	f	4
3213	915	Find the most important information first	t	1
3214	915	Avoid reading titles	f	2
3215	915	Increase the number of charts	f	3
3216	915	Make all metrics equally prominent	f	4
3217	916	20 to 30 KPIs to cover everything	f	1
3218	916	3 to 7 core KPIs with supporting context	t	2
3219	916	0 KPIs, only raw tables	f	3
3220	916	Exactly 15 KPIs, no more, no less	f	4
3221	917	Show churn rate with last month and target benchmark	t	1
3222	917	Show churn rate with no units and no history	f	2
3223	917	Show churn rate using random colors only	f	3
3224	917	Show churn rate without defining churn	f	4
3225	918	More predictive	f	1
3226	918	Hard to use for decisions	t	2
3227	918	Automatically ethical	f	3
3228	918	More accurate	f	4
3229	919	Providing clear definitions	f	1
3230	919	Misleading scales that exaggerate effects	t	2
3231	919	Including data sources	f	3
3232	919	Using accessible colors	f	4
3233	920	Selecting only data that supports a desired conclusion	t	1
3234	920	Using seasonal colors	f	2
3235	920	Choosing a bar chart for categories	f	3
3236	920	Adding error bars	f	4
3237	921	Hide data sources to avoid scrutiny	f	1
3238	921	Include data source and definition notes	t	2
3239	921	Use 3D effects to show confidence	f	3
3240	921	Avoid uncertainty communication	f	4
3241	922	Error bars or confidence bands	t	1
3242	922	Random clipart icons	f	2
3243	922	Only pie charts	f	3
3244	922	No labels or scales	f	4
3245	923	Time to answer business questions correctly	t	1
3246	923	Number of colors used	f	2
3247	923	Font family preference only	f	3
3248	923	Number of animations	f	4
3249	924	Compare accuracy and time before and after redesign	t	1
3250	924	Count how many icons were used	f	2
3251	924	Ask only if users like the colors	f	3
3252	924	Remove all charts	f	4
3253	925	Showing aggregated metrics only	f	1
3254	925	Exposing individual-level sensitive data without need	t	2
3255	925	Using clear axis labels	f	3
3256	925	Using consistent category names	f	4
3257	926	Always plot every raw point at once	f	1
3258	926	Use aggregation, sampling, or density when needed	t	2
3259	926	Avoid interaction	f	3
3260	926	Avoid scales to keep it simple	f	4
3261	927	A dashboard with drill-down and filtering	t	1
3262	927	A static PDF screenshot only	f	2
3263	927	A 3D spinning chart	f	3
3264	927	A legend hidden behind menus	f	4
3265	928	It can create false boundaries and uneven perception	t	1
3266	928	It always improves accessibility	f	2
3267	928	It reduces file size	f	3
3268	928	It guarantees correct interpretation	f	4
3269	929	They provide context for judging performance	t	1
3270	929	They replace the need for units	f	2
3271	929	They increase decoration	f	3
3272	929	They make all charts 3D	f	4
3273	930	Stacked area chart	t	1
3274	930	Single pie chart	f	2
3275	930	Dendrogram	f	3
3276	930	Histogram	f	4
3277	931	They reduce user agency	f	1
3278	931	They can increase extraneous cognitive load	t	2
3279	931	They always improve speed	f	3
3280	931	They prevent filtering	f	4
3281	932	A blank view with no data	f	1
3282	932	A meaningful overview (for example, last 30 days)	t	2
3283	932	A random segment each time	f	3
3284	932	All possible dimensions expanded	f	4
3285	933	They increase decoration	f	1
3286	933	They add interpretive context (good or bad relative to something)	t	2
3287	933	They reduce the need for axes	f	3
3288	933	They turn lagging indicators into leading	f	4
3289	934	Using many colors	f	1
3290	934	Representing data truthfully without distortion	t	2
3291	934	Making charts look modern	f	3
3292	934	Maximizing animation usage	f	4
3293	935	Using clear labels	f	1
3294	935	Using a dual axis that can be scaled to suggest any relationship	t	2
3295	935	Using a single axis	f	3
3296	935	Using small multiples	f	4
3297	936	Box plot with jittered points	t	1
3298	936	3D pie chart	f	2
3299	936	Word cloud	f	3
3300	936	Single KPI card only	f	4
3301	937	Consistent alignment and grid layout	t	1
3302	937	Random placement of charts	f	2
3303	937	Different font per widget	f	3
3304	937	Hidden titles	f	4
3305	938	It enables fair comparisons across panels	t	1
3306	938	It increases decoration	f	2
3307	938	It guarantees causality	f	3
3308	938	It hides variability	f	4
3309	939	Aligned with decision cadence (often daily or near real-time)	t	1
3310	939	Once per year	f	2
3311	939	Only when someone asks	f	3
3312	939	Never updated to maintain consistency	f	4
3313	940	Let users answer variations of the business question quickly	t	1
3314	940	Add complexity regardless of need	f	2
3315	940	Hide all data behind clicks	f	3
3316	940	Replace definitions and documentation	f	4
3317	941	A vague warning with no details	f	1
3318	941	Drill-down or explanation to diagnose drivers	t	2
3319	941	A 3D animation	f	3
3320	941	More decorative icons	f	4
3321	942	Median is more robust to outliers	t	1
3322	942	Median always equals mean	f	2
3323	942	Median requires no data	f	3
3324	942	Median is only for categorical data	f	4
3325	943	Only the color used	f	1
3326	943	Formula, units, and time window	t	2
3327	943	Only the chart type	f	3
3328	943	Only the font	f	4
3329	944	Different meanings for the same color on each page	f	1
3330	944	Standardized naming, units, and color semantics	t	2
3331	944	Random ordering of widgets	f	3
3332	944	A different layout grid every time	f	4
3333	945	Improve trust in analytics	f	1
3334	945	Drive wrong decisions and harm credibility	t	2
3335	945	Increase data quality automatically	f	3
3336	945	Reduce the need for governance	f	4
3337	946	It can reveal patterns hidden by raw-point overload	t	1
3338	946	It always removes bias	f	2
3339	946	It eliminates the need for labels	f	3
3340	946	It guarantees causal inference	f	4
3341	947	A continuously updating time-series with windowing	t	1
3342	947	A static quarterly PDF	f	2
3343	947	A pie chart for every event	f	3
3344	947	A dendrogram updated yearly	f	4
3345	948	Make data processing transparent and support analytic reasoning	t	1
3346	948	Replace humans with automation	f	2
3347	948	Use 3D charts everywhere	f	3
3348	948	Avoid interaction and exploration	f	4
3349	949	Color hue	f	1
3350	949	Area of circles	f	2
3351	949	Position on a common scale	t	3
3352	949	Angle in a pie slice	f	4
3353	950	Users can compare many unrelated items equally well	f	1
3354	950	Users can hold only a few items, so reduce simultaneous comparisons	t	2
3355	950	Users cannot detect trends without animation	f	3
3356	950	Users should avoid all categorical encodings	f	4
3357	951	The element is always well understood	f	1
3358	951	The element received sustained attention, possibly due to complexity	t	2
3359	951	The user disliked the colors	f	3
3360	951	The user never looked at the element	f	4
3361	952	How long the KPI is remembered after the task	f	1
3362	952	How quickly the KPI attracts gaze after stimulus onset	t	2
3363	952	How many saccades occurred overall	f	3
3364	952	Whether the user agrees with the KPI value	f	4
3365	953	Pareidolia	f	1
3366	953	Change blindness	t	2
3367	953	Regression to the mean	f	3
3368	953	Ecological fallacy	f	4
3369	954	No attention at all	f	1
3370	954	Serial attention and feature binding	t	2
3371	954	Only peripheral vision	f	3
3372	954	Only color processing in V1	f	4
3373	955	Add decorative icons to every KPI	f	1
3374	955	Remove redundant legends by direct labeling where possible	t	2
3375	955	Increase the number of fonts to separate sections	f	3
3376	955	Use 3D effects to make bars more visible	f	4
3377	956	Between-subjects only	f	1
3378	956	Within-subjects with counterbalanced order	t	2
3379	956	No randomization	f	3
3380	956	Observational study without tasks	f	4
3381	957	Sampling error	f	1
3382	957	Order and learning effects	t	2
3383	957	Instrument calibration improving accuracy	f	3
3384	957	Increased statistical power	f	4
3385	958	Higher TTFF for critical AOIs and more scattered scanpaths	t	1
3386	958	Lower screen resolution	f	2
3387	958	Using a single font family	f	3
3388	958	Having any title on the page	f	4
3389	959	The redesign improved efficiency for the measured tasks	t	1
3390	959	The redesign proves causality for business outcomes	f	2
3391	959	The redesign eliminated intrinsic load	f	3
3392	959	The redesign increased bias in the dataset	f	4
3393	960	Total dwell time on the AOI	t	1
3394	960	Saccade amplitude only	f	2
3395	960	Blink rate only	f	3
3396	960	Pointer speed	f	4
3397	961	Germane load only	f	1
3398	961	Extraneous load and search cost	t	2
3399	961	Data quality	f	3
3400	961	Statistical power	f	4
3401	962	They enable instant precise numerical estimation	f	1
3402	962	They can support rapid detection of simple differences	t	2
3403	962	They remove the need for labels in all cases	f	3
3404	962	They work only for text, not for shapes	f	4
3405	963	Areas with higher revenue	f	1
3406	963	Areas with more or longer fixations aggregated across viewers	t	2
3407	963	Areas with higher pixel brightness	f	3
3408	963	Areas that always cause comprehension	f	4
3409	964	To maximize aesthetic preference ratings	f	1
3410	964	To connect performance measures to real decision goals	t	2
3411	964	To avoid collecting any quantitative data	f	3
3412	964	To ensure all participants behave identically	f	4
3413	965	Improved perceptual discriminability and reduced search	t	1
3414	965	Reduced intrinsic complexity of the business question	f	2
3415	965	Better database indexing	f	3
3416	965	Guaranteed higher data accuracy	f	4
3417	966	Ecological fallacy	t	1
3418	966	Simpson’s paradox	f	2
3419	966	Hawthorne effect	f	3
3420	966	P-hacking	f	4
3421	967	Perceptual accuracy of the encoding	t	1
3422	967	Database normalization	f	2
3423	967	Data lineage	f	3
3424	967	Sampling frame	f	4
3425	968	Ask if the chart looks modern	f	1
3426	968	Score correct answers to interpretation questions	t	2
3427	968	Count how many colors are used	f	3
3428	968	Measure screen size	f	4
3429	969	Nearby items likely belong to the same structure	t	1
3430	969	Distant items always have equal importance	f	2
3431	969	Color is irrelevant to grouping	f	3
3432	969	Text is always grouped by font size only	f	4
3433	970	Ignore axes completely	f	1
3434	970	Mis-group measures that are semantically different	t	2
3435	970	Read faster without errors	f	3
3436	970	Prefer pie charts over bars	f	4
3437	971	High-contrast marks with subdued background gridlines	t	1
3438	971	Equal emphasis on background and foreground	f	2
3439	971	Dense texture behind key KPIs	f	3
3440	971	Random background gradients	f	4
3441	972	Increasing the number of encoded variables	f	1
3442	972	Creating perceptual grouping boundaries	t	2
3443	972	Forcing a log scale on the axes	f	3
3444	972	Eliminating the need for titles	f	4
3445	973	It increases the need for mental coordinate transforms	t	1
3446	973	It increases dataset variance	f	2
3447	973	It changes the data type from nominal to ordinal	f	3
3448	973	It converts bars into lines	f	4
3449	974	False consistency and category confusion	t	1
3450	974	Improved preattentive pop-out	f	2
3451	974	Reduced need for legends	f	3
3452	974	Guaranteed accessibility	f	4
3453	975	It maximizes decoration	f	1
3454	975	It supports predictable scanning and reduces search cost	t	2
3455	975	It forces all charts to use the same units	f	3
3456	975	It eliminates the need for filtering	f	4
3457	976	Similarity (for example, same color across distant items)	t	1
3458	976	Using whitespace	f	2
3459	976	Using consistent scales	f	3
3460	976	Adding units to axes	f	4
3461	977	Show every detail at once	f	1
3462	977	Start with an overview and allow drill-down to details	t	2
3463	977	Hide the overview and show only raw tables	f	3
3464	977	Use 3D charts to encode more variables	f	4
3465	978	Increase data density without benefit	f	1
3466	978	Compete with data marks and reduce figure-ground clarity	t	2
3467	978	Improve accuracy of slope estimation	f	3
3468	978	Guarantee colorblind accessibility	f	4
3469	979	They optimize precision for small differences	f	1
3470	979	They rely on angle or area judgments, which are less precise than position	t	2
3471	979	They are best for time series trends	f	3
3472	979	They reduce cognitive load by default	f	4
3473	980	Color hue	f	1
3474	980	Length from a baseline	t	2
3475	980	Texture frequency	f	3
3476	980	Legend ordering	f	4
3477	981	Dual y-axes with arbitrary scaling	f	1
3478	981	Small multiples with aligned time axes	t	2
3479	981	A single stacked area chart	f	3
3480	981	A 3D surface plot	f	4
3481	982	Always be replicated in each subgroup	f	1
3482	982	Reverse when data is disaggregated by a confounder	t	2
3483	982	Disappear only due to random noise	f	3
3484	982	Prove causality in the subgroups	f	4
3485	983	Use random colors for each region	f	1
3486	983	Normalize by an appropriate denominator (for example, per capita)	t	2
3487	983	Use the largest regions as darkest always	f	3
3488	983	Remove the legend	f	4
3489	984	Change aggregation boundaries or scale of regions	t	1
3490	984	Change font size of titles	f	2
3491	984	Use a different bar chart color	f	3
3492	984	Add a filter for time only	f	4
3493	985	Show a single line only to avoid confusion	f	1
3494	985	Show prediction intervals or confidence bands	t	2
3495	985	Use 3D shading to suggest confidence	f	3
3496	985	Hide the model horizon	f	4
3497	986	The underlying data generating process	f	1
3498	986	The apparent shape and granularity of the distribution	t	2
3499	986	The mean of the data	f	3
3500	986	The units of measurement	f	4
3501	987	Replacing binning with a smooth estimate controlled by bandwidth	t	1
3502	987	Forcing values to be integers	f	2
3503	987	Removing all outliers automatically	f	3
3504	987	Changing data from numeric to categorical	f	4
3505	988	People judge area nonlinearly and inconsistently	t	1
3506	988	They cannot show labels	f	2
3507	988	They require log scales	f	3
3508	988	They always have missing data	f	4
3509	989	To make all trends look linear	f	1
3510	989	To represent multiplicative changes across orders of magnitude	t	2
3511	989	To hide negative values	f	3
3512	989	To remove the need for units	f	4
3513	990	Plot raw totals only	f	1
3514	990	Index values to a baseline (for example, 100 at start)	t	2
3515	990	Use random jitter on y	f	3
3516	990	Convert numbers to categories	f	4
3517	991	Residuals versus fitted values plot	t	1
3518	991	Pie chart of coefficients	f	2
3519	991	Treemap of features	f	3
3520	991	Radar chart of p-values	f	4
3521	992	Proximity grouping	f	1
3522	992	Graphical integrity (lie factor)	t	2
3523	992	Common fate	f	3
3524	992	Nominal scaling	f	4
3525	993	Aspect ratio and axis scaling	t	1
3526	993	Font choice only	f	2
3527	993	Legend position only	f	3
3528	993	File format only	f	4
3529	994	Colorblind accessibility	f	1
3530	994	Perceptual discrimination of line slopes	t	2
3531	994	Accuracy of area judgments	f	3
3532	994	Precision of pie slice angles	f	4
3533	995	They increase occlusion and distort length perception	t	1
3534	995	They reduce file size	f	2
3535	995	They force categorical variables to be numeric	f	3
3536	995	They cannot be printed	f	4
3537	996	The total across bars	f	1
3538	996	Non-baseline segment sizes across categories	t	2
3539	996	Whether totals meet a target	f	3
3540	996	The number of categories	f	4
3541	997	Small multiple box plots	t	1
3542	997	One large pie chart	f	2
3543	997	A single KPI card	f	3
3544	997	A 3D surface plot	f	4
3545	998	Connect points even when time gaps are irregular and unknown	f	1
3546	998	Make missing intervals explicit (gaps) and label sampling	t	2
3547	998	Remove the x-axis labels	f	3
3548	998	Use a pie chart instead	f	4
3549	999	Mean-only KPI card	f	1
3550	999	Median with interquartile range (for example, box plot)	t	2
3551	999	3D exploded pie chart	f	3
3552	999	Unlabeled scatter plot	f	4
3553	1000	It reduces the need for mental reordering and scanning	t	1
3554	1000	It changes nominal data into ratio data	f	2
3555	1000	It increases the number of data points	f	3
3556	1000	It removes sampling bias	f	4
3557	1001	A rate of change chart	t	1
3558	1001	A categorical palette	f	2
3559	1001	A histogram	f	3
3560	1001	A dendrogram	f	4
3561	1002	Apply smoothing and also show raw data or bands as context	t	1
3562	1002	Show only the smoothed line and hide everything else	f	2
3563	1002	Switch to a pie chart	f	3
3564	1002	Randomly drop points without explanation	f	4
3565	1003	Correlation always implies causation	f	1
3566	1003	Correlation can be driven by confounding or aggregation choices	t	2
3567	1003	Correlation is visible only with 3D plots	f	3
3568	1003	Correlation cannot be affected by outliers	f	4
3569	1004	Increasing marker size for visibility	f	1
3570	1004	Density-based encodings (hexbin) or transparency and sampling	t	2
3571	1004	Using a pie chart overlay	f	3
3572	1004	Removing axes and gridlines	f	4
3573	1005	A meaningful central reference value (for example, 0 or target)	t	1
3574	1005	As many hues as possible	f	2
3575	1005	Random midpoint selection	f	3
3576	1005	Only categorical data	f	4
3577	1006	Equal perceived changes in color	t	1
3578	1006	Equal file sizes across exports	f	2
3579	1006	Equal numbers of categories	f	3
3580	1006	Equal chart heights	f	4
3581	1007	It introduces non-monotonic luminance and false boundaries	t	1
3582	1007	It always improves accessibility	f	2
3583	1007	It increases precision of area judgments	f	3
3584	1007	It prevents any grouping cues	f	4
3585	1008	Use color alone with subtle hue shifts	f	1
3586	1008	Add redundant encodings (shape, labels) and ensure sufficient contrast	t	2
3587	1008	Prefer red-green contrasts for key alerts	f	3
3588	1008	Remove legends entirely	f	4
3589	1009	Increase the number of colors needed	f	1
3590	1009	Reveal structure and patterns by placing similar items together	t	2
3591	1009	Hide missing values	f	3
3592	1009	Guarantee causal inference	f	4
3593	1010	Red cannot be displayed on monitors	f	1
3594	1010	Overuse reduces salience and can cause alarm fatigue	t	2
3595	1010	Red always encodes nominal data	f	3
3596	1010	Red guarantees higher accuracy	f	4
3597	1011	Choosing a modern theme	f	1
3598	1011	Linking data variables to visual properties (x, y, color, size)	t	2
3599	1011	Writing a narrative caption	f	3
3600	1011	Selecting a storage engine	f	4
3601	1012	Switching from Cartesian to polar coordinates	t	1
3602	1012	Changing linear to log mapping on y	f	2
3603	1012	Changing a palette from blue to green	f	3
3604	1012	Filtering rows to last 30 days	f	4
3605	1013	The chart becomes a histogram	f	1
3606	1013	Visual comparisons become invalid due to mismatched mappings	t	2
3607	1013	The data becomes categorical	f	3
3608	1013	The legend disappears automatically	f	4
3609	1014	Different scales per panel to maximize differences	f	1
3610	1014	Consistent scales to support direct comparison	t	2
3611	1014	Random ordering of panels	f	3
3612	1014	No axes to reduce clutter	f	4
3613	1015	It eliminates the need for any data cleaning	f	1
3614	1015	It reduces eye movements and lookup cost between marks and legend	t	2
3615	1015	It increases the number of categories possible	f	3
3616	1015	It guarantees better aesthetics	f	4
3617	1016	Legal compliance	f	1
3618	1016	Perceived latency and interactivity under heavy computation	t	2
3619	1016	Colorblind accessibility	f	3
3620	1016	Replacing aggregation with raw points always	f	4
3621	1017	Static reporting only	f	1
3622	1017	Information-seeking and interactive visual analytics	t	2
3623	1017	Pure decoration	f	3
3624	1017	Avoiding user control	f	4
3625	1018	Brushing and linking	t	1
3626	1018	Exploded 3D rotation	f	2
3627	1018	Font substitution	f	3
3628	1018	Axis truncation	f	4
3629	1019	It always improves representativeness	f	1
3630	1019	It can miss rare but important patterns and introduce bias	t	2
3631	1019	It forces log scales	f	3
3632	1019	It prevents any filtering	f	4
3633	1020	To turn time into a nominal variable	f	1
3634	1020	To compute stable aggregates over recent intervals	t	2
3635	1020	To eliminate concept drift	f	3
3636	1020	To avoid timestamps entirely	f	4
3637	1021	Higher chart resolution	f	1
3638	1021	Unnecessary exposure of sensitive information and re-identification	t	2
3639	1021	Better personalization	f	3
3640	1021	Lower cognitive load	f	4
3641	1022	To increase decoration	f	1
3642	1022	To support interpretability and trust through transparency	t	2
3643	1022	To reduce the number of users	f	3
3644	1022	To avoid using benchmarks	f	4
3645	1023	It can remove helpful context like reference lines and annotations	t	1
3646	1023	It always increases chartjunk	f	2
3647	1023	It prohibits all labels by definition	f	3
3648	1023	It forces pie charts over bars	f	4
3649	1024	Area judgments are generally less precise than position judgments	t	1
3650	1024	Area judgments are always more precise than length judgments	f	2
3651	1024	Area encoding eliminates the need for labels	f	3
3652	1024	Area encoding is invalid for any business use	f	4
3653	1025	Rectangles encode values by area without a shared baseline	t	1
3654	1025	Rectangles cannot be colored	f	2
3655	1025	Treemaps require time series data	f	3
3656	1025	Treemaps always use dual axes	f	4
3657	1026	Change between two time points for multiple items	t	1
3658	1026	A distribution of one variable	f	2
3659	1026	A part-to-whole breakdown at a single time	f	3
3660	1026	A network topology	f	4
3661	1027	It becomes impossible to compute means	f	1
3662	1027	Non-baseline layers lose a common baseline and become hard to compare	t	2
3663	1027	It cannot show totals	f	3
3664	1027	It forces categorical palettes	f	4
3665	1028	Incremental contributions that bridge start and end totals	t	1
3666	1028	Only a distribution shape	f	2
3667	1028	Only a correlation matrix	f	3
3668	1028	Only spatial density	f	4
3669	1029	Marker size (with caution and labeling)	t	1
3670	1029	Random jitter direction	f	2
3671	1029	3D depth with perspective	f	3
3672	1029	Changing font weight of the title	f	4
3673	1030	They reduce ink and emphasize position comparisons cleanly	t	1
3674	1030	They automatically show uncertainty	f	2
3675	1030	They require no axis	f	3
3676	1030	They make nominal variables ratio-scaled	f	4
3677	1031	Targets are optional decoration with no analytic value	f	1
3678	1031	Targets add reference context that supports decision-making	t	2
3679	1031	Targets always increase extraneous load	f	3
3680	1031	Targets replace the need for historical trend	f	4
3681	1032	Improved comparability	f	1
3682	1032	Inconsistent decisions due to semantic drift and mismatched formulas	t	2
3683	1032	Lower data volume	f	3
3684	1032	Higher color contrast	f	4
3685	1033	A single KPI card with no context	f	1
3686	1033	A drill-down view showing drivers and segment breakdowns	t	2
3687	1033	A decorative banner image	f	3
3688	1033	A random color palette	f	4
3689	1034	They require different decision cadence and level of detail	t	1
3690	1034	Operational dashboards cannot use charts	f	2
3691	1034	Strategic dashboards must be real-time	f	3
3692	1034	They cannot share any metrics	f	4
3693	1035	Easy to measure but unrelated to actions	f	1
3694	1035	Actionable and plausibly predictive of later outcomes	t	2
3695	1035	Always financial	f	3
3696	1035	Only available annually	f	4
3697	1036	Hide the data and show only a number	f	1
3698	1036	Show both raw values and a smoothed trend or rolling average	t	2
3699	1036	Use a pie chart	f	3
3700	1036	Use dual axes with arbitrary scaling	f	4
3701	1037	It reduces the need for data governance	f	1
3702	1037	It prevents misinterpretation of what the number represents	t	2
3703	1037	It increases chartjunk	f	3
3704	1037	It ensures higher screen resolution	f	4
3705	1038	It breaks the JSON export	f	1
3706	1038	It invites invalid comparisons and confusion about scale	t	2
3707	1038	It always reduces data size	f	3
3708	1038	It prevents sorting categories	f	4
3709	1039	Arbitrary aesthetic preference	f	1
3710	1039	Business targets, risk tolerance, and historical variability	t	2
3711	1039	The number of categories in the dataset	f	3
3712	1039	The maximum screen brightness	f	4
3713	1040	Show many decimal places to look scientific	f	1
3714	1040	Round appropriately and show uncertainty when relevant	t	2
3715	1040	Remove all axes	f	3
3716	1040	Use 3D charts	f	4
3717	1041	Rankings cannot be sorted	f	1
3718	1041	Small differences may be within noise, yet ranks imply certainty	t	2
3719	1041	Rankings always require log scales	f	3
3720	1041	Rankings cannot use color	f	4
3721	1042	To increase decoration	f	1
3722	1042	To contextualize stability and interpretability of the rate	t	2
3723	1042	To eliminate the need for targets	f	3
3724	1042	To force categorical encoding	f	4
3725	1043	Too much whitespace	f	1
3726	1043	Edge crossings and hairball density	t	2
3727	1043	Having node labels	f	3
3728	1043	Using a sequential palette	f	4
3729	1044	Add more random edges	f	1
3730	1044	Filter, cluster, and use aggregation or edge bundling	t	2
3731	1044	Switch to 3D perspective	f	3
3732	1044	Remove all interaction	f	4
3733	1045	Axis ordering	t	1
3734	1045	File compression	f	2
3735	1045	Legend font choice	f	3
3736	1045	Monitor refresh rate	f	4
3737	1046	Hierarchical clustering	t	1
3738	1046	Linear regression	f	2
3739	1046	Time series decomposition	f	3
3740	1046	Principal component analysis only	f	4
3741	1047	Hide axis labels to reduce clutter	f	1
3742	1047	Label axes with explained variance and clarify what components mean	t	2
3743	1047	Use 3D depth as a default	f	3
3744	1047	Use a rainbow palette for the background	f	4
3745	1048	Small multiples reduce memory demands by showing states simultaneously	t	1
3746	1048	Animation always improves precision	f	2
3747	1048	Small multiples require no space	f	3
3748	1048	Animation eliminates change blindness	f	4
3749	1049	Show all pairwise relationships among several numeric variables	t	1
3750	1049	Show part-to-whole composition	f	2
3751	1049	Show hierarchical decomposition only	f	3
3752	1049	Show only categorical ranking	f	4
3753	1050	Counts cannot be colored	f	1
3754	1050	Large areas may appear more important regardless of population or denominator	t	2
3755	1050	It forces log scales	f	3
3756	1050	It prevents labeling	f	4
3757	1051	Area, shape, distance, and direction perfectly	t	1
3758	1051	Color and texture perfectly	f	2
3759	1051	Legends and titles perfectly	f	3
3760	1051	Nominal and ordinal variables perfectly	f	4
3761	1052	Hide sample sizes to avoid bias	f	1
3762	1052	Show distributions and annotate n (sample size) for each group	t	2
3763	1052	Use 3D bars with shadows	f	3
3764	1052	Use only means with no spread	f	4
3765	1053	Suggests an ordering that does not exist	t	1
3766	1053	Improves categorical discrimination	f	2
3767	1053	Eliminates the legend	f	3
3768	1053	Forces a log scale	f	4
3769	1054	Monotonic change in luminance	t	1
3770	1054	Random hue cycling	f	2
3771	1054	Maximum number of distinct hues	f	3
3772	1054	Using only red and green	f	4
3773	1055	Saturated colors cannot be printed	f	1
3774	1055	They compete for attention and weaken visual hierarchy	t	2
3775	1055	They force nominal variables to be ratio	f	3
3776	1055	They eliminate overplotting	f	4
3777	1056	A meaningful midpoint (target, zero, average)	f	1
3778	1056	No meaningful midpoint and only positive magnitudes	t	2
3779	1056	Signed values around zero	f	3
3780	1056	Deviations from a benchmark	f	4
3781	1057	Color cannot encode categories	f	1
3782	1057	Selective color creates preattentive pop-out for key items	t	2
3783	1057	Color always increases numeric precision	f	3
3784	1057	Color eliminates the need for legends	f	4
3785	1058	Users cannot filter the data	f	1
3786	1058	Users may miscompare intensity because the same color means different values	t	2
3787	1058	The heatmap becomes categorical	f	3
3788	1058	The gridlines become thicker	f	4
3789	1059	Data transformation and aggregation	t	1
3790	1059	Font choice	f	2
3791	1059	Legend placement	f	3
3792	1059	Chart border thickness	f	4
3793	1060	Misalignment between user goals and the encoded measures	t	1
3794	1060	Too few pixels on screen	f	2
3795	1060	Using a grid layout	f	3
3796	1060	Having tooltips enabled	f	4
3797	1061	Benchmarks remove the need for history	f	1
3798	1061	Benchmarks enable judgment relative to goals or norms	t	2
3799	1061	Benchmarks guarantee causality	f	3
3800	1061	Benchmarks eliminate all variance	f	4
3801	1062	Higher aesthetic ratings only	f	1
3802	1062	Higher accuracy and lower task time on predefined tasks	t	2
3803	1062	More colors used	f	3
3804	1062	More charts per page	f	4
3805	1063	Use one KPI only and hide all context	f	1
3806	1063	Balance KPIs with guardrail metrics and clear definitions	t	2
3807	1063	Use 3D charts to increase trust	f	3
3808	1063	Remove targets entirely	f	4
3809	1064	To make the chart look more advanced	f	1
3810	1064	To communicate uncertainty and avoid overinterpreting noise	t	2
3811	1064	To remove the need for sample size	f	3
3812	1064	To convert nominal variables to ratio	f	4
3813	1065	The denominator size and variability	t	1
3814	1065	The font size of the title	f	2
3815	1065	The file extension of the export	f	3
3816	1065	The number of gridlines	f	4
3817	1066	Raw counts only	f	1
3818	1066	Rates with denominators and uncertainty, possibly as small multiples	t	2
3819	1066	Exploded 3D pie chart	f	3
3820	1066	Random color-coded table	f	4
3821	1067	Replace the x-axis	f	1
3822	1067	Support causal hypotheses and interpretation of anomalies	t	2
3823	1067	Increase data-ink ratio	f	3
3824	1067	Ensure correlation equals causation	f	4
3825	1068	Numbers cannot be compared	f	1
3826	1068	It encourages snapshot thinking and hides variation and direction	t	2
3827	1068	It forces a log axis	f	3
3828	1068	It improves preattentive processing	f	4
3829	1069	To avoid any quantitative analysis	f	1
3830	1069	To ensure consistent measurement and reduce researcher degrees of freedom	t	2
3831	1069	To maximize participant fatigue	f	3
3832	1069	To guarantee significant p-values	f	4
3833	1070	To guarantee perfect calibration	f	1
3834	1070	To reduce learning, fatigue, and sequence confounds	t	2
3835	1070	To increase chartjunk	f	3
3836	1070	To remove the need for counterbalancing	f	4
3837	1071	Users understood better with less effort	f	1
3838	1071	Users may be missing key information due to poor salience or misleading cues	t	2
3839	1071	The dataset became larger	f	3
3840	1071	The color space changed automatically	f	4
3841	1072	Higher blink rate	f	1
3842	1072	Lower time to first fixation on the KPI AOI	t	2
3843	1072	More gridlines	f	3
3844	1072	More decorative icons	f	4
3845	1073	It cannot measure where eyes look	f	1
3846	1073	Looking does not guarantee comprehension or correct inference	t	2
3847	1073	It only works with pie charts	f	3
3848	1073	It replaces the need for task metrics	f	4
3849	1074	Reduce the number of available metrics	f	1
3850	1074	Increase navigation overhead and working memory burden	t	2
3851	1074	Guarantee better decision-making	f	3
3852	1074	Eliminate the need for overview	f	4
3853	1075	Users will always trust results more	f	1
3854	1075	Users lose the sense of control and stop exploring	t	2
3855	1075	Color perception improves	f	3
3856	1075	Sampling bias disappears	f	4
3857	1076	To avoid any aggregation	f	1
3858	1076	To preserve interactivity by rendering appropriate summaries at each zoom	t	2
3859	1076	To make all charts 3D	f	3
3860	1076	To remove uncertainty	f	4
3861	1077	Hide recent changes because scale expands continuously	t	1
3862	1077	Cannot be updated	f	2
3863	1077	Force categorical palettes	f	3
3864	1077	Eliminate noise automatically	f	4
3865	1078	To make the header look fuller	f	1
3866	1078	To prevent decisions based on stale data	t	2
3867	1078	To increase data-ink ratio	f	3
3868	1078	To reduce need for filters	f	4
3869	1079	Maximize the number of encodings per chart	f	1
3870	1079	Make the key message immediately visible and provide optional detail	t	2
3871	1079	Avoid any annotation to keep it pure	f	3
3872	1079	Always choose the most novel chart type	f	4
3873	1080	A clear decision hook (what to do if high or low) and ownership	t	1
3874	1080	A 3D effect	f	2
3875	1080	A rainbow palette	f	3
3876	1080	More gridlines	f	4
3877	1081	It increases perceived precision beyond measurement reliability	t	1
3878	1081	It increases dataset size	f	2
3879	1081	It prevents sorting	f	3
3880	1081	It forces log scales	f	4
3881	1082	Create one page with all possible metrics	f	1
3882	1082	Create role-specific views or guided navigation aligned to tasks	t	2
3883	1082	Hide filters to avoid misuse	f	3
3884	1082	Use only pie charts for simplicity	f	4
3885	1083	A purely decorative metric for layout balance	f	1
3886	1083	A metric that prevents optimizing one KPI at the expense of harm elsewhere	t	2
3887	1083	A KPI that is always leading	f	3
3888	1083	A metric that cannot be measured	f	4
3889	1084	They reduce file size	f	1
3890	1084	They can misrepresent trends and manipulate conclusions	t	2
3891	1084	They make charts too simple	f	3
3892	1084	They prevent use of benchmarks	f	4
3893	1085	Silently omit missing periods	f	1
3894	1085	Make missingness visible and annotate its implications	t	2
3895	1085	Replace missing values with zero without note	f	3
3896	1085	Remove the axis	f	4
3897	1086	Bias only matters in academic studies	f	1
3898	1086	Visualizations can encode and amplify inequities through data and framing	t	2
3899	1086	Bias disappears with more colors	f	3
3900	1086	Fairness is guaranteed by interactivity	f	4
3901	1087	Horizontal bar chart sorted by value	t	1
3902	1087	Exploded pie chart with legend	f	2
3903	1087	3D clustered bars with rotation	f	3
3904	1087	Radar chart with 20 axes	f	4
3905	1088	A treemap only with no totals	f	1
3906	1088	Small multiples of simple bars by component	t	2
3907	1088	A single pie chart per category	f	3
3908	1088	Dual-axis stacked area chart	f	4
3909	1089	Averages can hide variability, multimodality, and outliers	t	1
3910	1089	Distributions always require less space	f	2
3911	1089	Averages cannot be computed	f	3
3912	1089	Distributions eliminate the need for context	f	4
3913	1090	Whether a sample follows a theoretical distribution (for example, normality)	t	1
3914	1090	Part-to-whole breakdown	f	2
3915	1090	Network centrality	f	3
3916	1090	Geographic density	f	4
3917	1091	Forest plot	t	1
3918	1091	Radar chart	f	2
3919	1091	Exploded pie chart	f	3
3920	1091	Treemap with random ordering	f	4
3921	1092	They update at different cadences and support different interventions	t	1
3922	1092	Outcome metrics cannot be visualized	f	2
3923	1092	Input metrics are always vanity metrics	f	3
3924	1092	They require different fonts	f	4
3925	1093	It increases file size	f	1
3926	1093	It confuses temporal granularity and can mislead trend interpretation	t	2
3927	1093	It prevents any legend use	f	3
3928	1093	It forces categorical variables	f	4
3929	1094	Compare raw totals only	f	1
3930	1094	Use normalized rates (per unit) and show denominators for context	t	2
3931	1094	Use a single pie chart for all stores	f	3
3932	1094	Use 3D bars to show size	f	4
3933	1095	Overlay each year aligned by day or week on a common axis	t	1
3934	1095	Use a treemap by year	f	2
3935	1095	Use a single pie chart per year	f	3
3936	1095	Hide the x-axis	f	4
3937	1096	A sequential stage progression with drop-off between steps	t	1
3938	1096	A distribution of continuous values	f	2
3939	1096	A network topology	f	3
3940	1096	A purely geographic intensity map	f	4
3941	1097	Because slopes are scale-dependent and the mapping changes perceived rate	t	1
3942	1097	Because legends cannot be used across charts	f	2
3943	1097	Because color hue changes the mean	f	3
3944	1097	Because faceting prevents comparison	f	4
3945	1098	To guarantee no false positives	f	1
3946	1098	To distinguish normal variation from meaningful deviation	t	2
3947	1098	To avoid updating the dashboard	f	3
3948	1098	To remove the need for labels	f	4
3949	1099	Reduced alarm frequency	f	1
3950	1099	Alert fatigue and loss of trust in the dashboard	t	2
3951	1099	Guaranteed profitability	f	3
3952	1099	Elimination of extraneous load	f	4
3953	1100	Any visible difference is statistically significant	f	1
3954	1100	A visible difference may still be noise without uncertainty context	t	2
3955	1100	Statistical significance guarantees business relevance	f	3
3956	1100	Uncertainty cannot be visualized	f	4
3957	1101	To choose the color palette	f	1
3958	1101	To ensure accountability for definition, quality, and action	t	2
3959	1101	To reduce the need for data sources	f	3
3960	1101	To increase the number of KPIs	f	4
3961	1102	Exploration tolerates ambiguity and iteration, reporting requires stable definitions	t	1
3962	1102	Exploration cannot use charts	f	2
3963	1102	Reporting must be interactive always	f	3
3964	1102	They must use different data types	f	4
3965	1103	It ensures colors are brighter	f	1
3966	1103	It prevents contradictory numbers caused by hidden filter states	t	2
3967	1103	It forces all charts to be histograms	f	3
3968	1103	It removes the need for benchmarks	f	4
3969	1104	Outliers compress the scale and hide meaningful differences among typical cases	t	1
3970	1104	It guarantees better interpretability	f	2
3971	1104	It prevents any comparisons	f	3
3972	1104	It converts numeric data to nominal	f	4
3973	1105	Manual edits in screenshots only	f	1
3974	1105	Documented transformations, versioned data sources, and consistent metric definitions	t	2
3975	1105	Randomly changing filters for exploration	f	3
3976	1105	Removing titles and labels	f	4
3977	1106	To decorate a report	f	1
3978	1106	To help people understand data and make decisions	t	2
3979	1106	To replace data collection	f	3
3980	1106	To avoid using numbers	f	4
3981	1107	Bar chart	t	1
3982	1107	Pie chart	f	2
3983	1107	Word cloud	f	3
3984	1107	Gauge only	f	4
3985	1108	Line chart	t	1
3986	1108	Pie chart	f	2
3987	1108	Treemap	f	3
3988	1108	Table only	f	4
3989	1109	A decorative icon	f	1
3990	1109	A key metric used to track performance toward a goal	t	2
3991	1109	A type of database	f	3
3992	1109	A chart format	f	4
3993	1110	Use vague titles like 'Data'	f	1
3994	1110	Use a clear title that explains what the chart shows	t	2
3995	1110	Avoid titles to reduce clutter	f	3
3996	1110	Use only abbreviations	f	4
3997	1111	Time	t	1
3998	1111	Profit only	f	2
3999	1111	Random categories	f	3
4000	1111	Always percentages	f	4
4001	1112	They can distort how big bars look	t	1
4002	1112	They always improve accuracy	f	2
4003	1112	They remove the need for axes	f	3
4004	1112	They work only with time data	f	4
4005	1113	To explain what colors or symbols mean	t	1
4006	1113	To increase the dataset size	f	2
4007	1113	To change the data	f	3
4008	1113	To calculate averages	f	4
4009	1114	Pie chart (few slices)	t	1
4010	1114	3D surface plot	f	2
4011	1114	Network graph	f	3
4012	1114	Scatter plot	f	4
4013	1115	Only the ink used to show data (not decoration)	t	1
4014	1115	Only the background color	f	2
4015	1115	Only the title font	f	3
4016	1115	Only the legend box	f	4
4017	1116	Product category	t	1
4018	1116	Temperature in Celsius	f	2
4019	1116	Revenue in euros	f	3
4020	1116	Time in seconds	f	4
4021	1117	Sales amount	t	1
4022	1117	Customer segment name	f	2
4023	1117	Country name	f	3
4024	1117	Department label	f	4
4025	1118	A note that explains a key point in the data	t	1
4026	1118	A random color change	f	2
4027	1118	A hidden filter	f	3
4028	1118	A file format	f	4
4029	1119	To show what the axis values mean (units, variable)	t	1
4030	1119	To make the chart look modern	f	2
4031	1119	To replace the legend	f	3
4032	1119	To hide uncertainty	f	4
4033	1120	Use color consistently and sparingly for emphasis	t	1
4034	1120	Use as many bright colors as possible	f	2
4035	1120	Change color meaning on each page	f	3
4036	1120	Use red and green only	f	4
4037	1121	Scatter plot	t	1
4038	1121	Pie chart	f	2
4039	1121	Stacked bar only	f	3
4040	1121	Icon chart	f	4
4041	1122	Shows only a selected subset of the data	t	1
4042	1122	Changes the original data permanently	f	2
4043	1122	Deletes columns in the database	f	3
4044	1122	Adds random noise	f	4
4045	1123	A visual summary of key metrics and insights	t	1
4046	1123	A raw database table	f	2
4047	1123	A spreadsheet formula	f	3
4048	1123	A programming language	f	4
4049	1124	It makes comparisons easier	t	1
4050	1124	It hides low values	f	2
4051	1124	It changes the data	f	3
4052	1124	It increases the number of categories	f	4
4053	1125	A general direction of change over time	t	1
4054	1125	A single data point	f	2
4055	1125	A legend item	f	3
4056	1125	A category name	f	4
4057	1126	Histogram	t	1
4058	1126	Pie chart	f	2
4059	1126	Sankey diagram	f	3
4060	1126	Map projection	f	4
4061	1127	To help estimate values on the axis	t	1
4062	1127	To add decoration only	f	2
4063	1127	To increase the dataset size	f	3
4064	1127	To replace data labels always	f	4
4065	1128	Make them light so they do not compete with data	t	1
4066	1128	Make them thick and dark	f	2
4067	1128	Use random colors	f	3
4068	1128	Remove axes if gridlines exist	f	4
4069	1129	A value very different from most others	t	1
4070	1129	A value exactly equal to the mean	f	2
4071	1129	A missing label	f	3
4072	1129	A type of legend	f	4
4073	1130	Treemap	t	1
4074	1130	Single pie chart	f	2
4075	1130	Single dot	f	3
4076	1130	Q-Q plot	f	4
4077	1131	They work best with few slices and clear differences	t	1
4078	1131	They are best for time trends	f	2
4079	1131	They are best for precise comparison of many categories	f	3
4080	1131	They replace the need for labels	f	4
4081	1132	Text showing the value of a mark (bar, point, slice)	t	1
4082	1132	A database table name	f	2
4083	1132	A file header	f	3
4084	1132	A chart background color	f	4
4085	1133	The user can filter, drill down, or explore data	t	1
4086	1133	The dashboard prints automatically	f	2
4087	1133	The dashboard changes the database schema	f	3
4088	1133	The dashboard uses only tables	f	4
4089	1134	Define the question you want to answer	t	1
4090	1134	Pick the most colorful chart	f	2
4091	1134	Remove all labels	f	3
4092	1134	Use 3D by default	f	4
4093	1135	Magnitude from a baseline	t	1
4094	1135	Only category name	f	2
4095	1135	Only color meaning	f	3
4096	1135	Only chart style	f	4
4097	1136	Y-axis	t	1
4098	1136	X-axis	f	2
4099	1136	Neither axis	f	3
4100	1136	Only the legend	f	4
4101	1137	To show extra details when you hover or click	t	1
4102	1137	To change the dataset permanently	f	2
4103	1137	To hide labels forever	f	3
4104	1137	To remove uncertainty	f	4
4105	1138	Map	t	1
4106	1138	Radar chart	f	2
4107	1138	Gantt chart	f	3
4108	1138	Box plot only	f	4
4109	1139	A map where regions are colored by a value	t	1
4110	1139	A map with only city labels	f	2
4111	1139	A 3D terrain model	f	3
4112	1139	A network graph	f	4
4113	1140	Show units clearly (€, %, days, etc.)	t	1
4114	1140	Hide units to avoid clutter	f	2
4115	1140	Use different units without labels	f	3
4116	1140	Use units only in the legend	f	4
4117	1141	Gantt chart	t	1
4118	1141	Pie chart	f	2
4119	1141	Histogram	f	3
4120	1141	Box plot	f	4
4121	1142	It shows direction and change over time clearly	t	1
4122	1142	It is best for part-to-whole at one time	f	2
4123	1142	It is best for comparing many categories without time	f	3
4124	1142	It avoids the need for axes	f	4
4125	1143	Sorted bar chart	t	1
4126	1143	Pie chart	f	2
4127	1143	Line chart	f	3
4128	1143	Map only	f	4
4129	1144	The reference line where bars start (often zero)	t	1
4130	1144	The legend title	f	2
4131	1144	The chart border	f	3
4132	1144	The tooltip text	f	4
4133	1145	How two variables tend to move together	t	1
4134	1145	A guaranteed cause-and-effect link	f	2
4135	1145	A type of color palette	f	3
4136	1145	A file compression method	f	4
4137	1146	Correlation does not automatically mean causation	t	1
4138	1146	Correlation always proves causation	f	2
4139	1146	Causation is visible in any chart	f	3
4140	1146	Causation can be ignored in business	f	4
4141	1147	How values are spread across a range	t	1
4142	1147	A chart border style	f	2
4143	1147	A type of legend	f	3
4144	1147	A dashboard filter	f	4
4145	1148	Mean and median	t	1
4146	1148	Only the title font	f	2
4147	1148	Only the background color	f	3
4148	1148	Only the number of categories	f	4
4149	1149	The middle value when data is sorted	t	1
4150	1149	The highest value	f	2
4151	1149	The sum of all values	f	3
4152	1149	A type of color scale	f	4
4153	1150	The average value	t	1
4154	1150	The most common category	f	2
4155	1150	The axis title	f	3
4156	1150	A chart type	f	4
4157	1151	Add a horizontal reference line at the target value	t	1
4158	1151	Change all bars to 3D	f	2
4159	1151	Remove the axis	f	3
4160	1151	Use random colors	f	4
4161	1152	Going from summary to more detailed data	t	1
4162	1152	Deleting data	f	2
4163	1152	Changing the color palette automatically	f	3
4164	1152	Printing a report	f	4
4165	1153	Combining data points into summaries (sum, average, count)	t	1
4166	1153	Adding more raw rows	f	2
4167	1153	Changing a chart title	f	3
4168	1153	Making a chart 3D	f	4
4169	1154	Monthly total sales from daily sales	t	1
4170	1154	Changing the font to Arial	f	2
4171	1154	Moving the legend to the left	f	3
4172	1154	Adding a background image	f	4
4173	1155	Use consistent layout and alignment	t	1
4174	1155	Use many unrelated fonts	f	2
4175	1155	Avoid whitespace completely	f	3
4176	1155	Hide labels and units	f	4
4177	1156	Separating sections and improving readability	t	1
4178	1156	Reducing data accuracy	f	2
4179	1156	Increasing file size only	f	3
4180	1156	Removing the need for titles	f	4
4181	1157	Showing exact values and detailed records	t	1
4182	1157	Showing trends better than lines	f	2
4183	1157	Replacing all charts always	f	3
4184	1157	Encoding values with 3D effects	f	4
4185	1158	Comparing bar lengths	t	1
4186	1158	Comparing pie slice angles	f	2
4187	1158	They are always equal	f	3
4188	1158	Neither can be compared	f	4
4189	1159	A mapping from data values to visual positions or colors	t	1
4190	1159	A chart border	f	2
4191	1159	A file type	f	3
4192	1159	A legend item	f	4
4193	1160	Different colors for different categories	t	1
4194	1160	A gradual change for ordered values	f	2
4195	1160	Only one color for all values	f	3
4196	1160	A palette used only for maps	f	4
4197	1161	A gradual light-to-dark change for ordered values	t	1
4198	1161	Random colors for categories	f	2
4199	1161	Only red and green	f	3
4200	1161	Only black and white	f	4
4201	1162	To show values above and below a meaningful midpoint	t	1
4202	1162	To show unordered categories	f	2
4203	1162	To show only positive values with no midpoint	f	3
4204	1162	To replace the need for an axis	f	4
4205	1163	It reduces confusion and improves interpretation speed	t	1
4206	1163	It increases data size	f	2
4207	1163	It guarantees higher profit	f	3
4208	1163	It removes the need for any labels	f	4
4209	1164	A clear explanation of how a metric is calculated and what it means	t	1
4210	1164	A chart color rule	f	2
4211	1164	A legend position	f	3
4212	1164	A font family	f	4
4213	1165	Label clearly with % and define the denominator	t	1
4214	1165	Hide the % sign to reduce clutter	f	2
4215	1165	Mix % and totals in one axis without labels	f	3
4216	1165	Use random rounding rules	f	4
4217	1166	To limit the data to a specific time window	t	1
4218	1166	To change the units of the KPI	f	2
4219	1166	To increase the number of charts	f	3
4220	1166	To create outliers	f	4
4221	1167	Remove unnecessary decoration and keep labels readable	t	1
4222	1167	Add more shadows	f	2
4223	1167	Add more 3D effects	f	3
4224	1167	Hide the axes always	f	4
4225	1168	Slices become hard to compare	t	1
4226	1168	It becomes a histogram	f	2
4227	1168	It forces log scales	f	3
4228	1168	It increases correlation	f	4
4229	1169	Bar chart	t	1
4230	1169	3D pie chart	f	2
4231	1169	Word cloud	f	3
4232	1169	No chart at all	f	4
4233	1170	A reference value used for comparison	t	1
4234	1170	A random category	f	2
4235	1170	A chart border	f	3
4236	1170	A font style	f	4
4237	1171	A desired value you want to achieve	t	1
4238	1171	A random value from last year	f	2
4239	1171	A legend label	f	3
4240	1171	A color palette type	f	4
4241	1172	Stacked area chart	t	1
4242	1172	Single pie chart	f	2
4243	1172	Box plot	f	3
4244	1172	Radar chart	f	4
4245	1173	To summarize distribution (median, spread, outliers)	t	1
4246	1173	To show a timeline of tasks	f	2
4247	1173	To show network connections	f	3
4248	1173	To show part-to-whole of categories	f	4
4249	1174	So viewers know what values and units they are seeing	t	1
4250	1174	So the chart uses more ink	f	2
4251	1174	So the chart becomes interactive	f	3
4252	1174	So the data becomes cleaner	f	4
4253	1175	Use only as many decimals as needed for the decision	t	1
4254	1175	Always show 6 decimals	f	2
4255	1175	Never show any decimals	f	3
4256	1175	Use random decimals for variety	f	4
4257	1176	To provide context like a target or average	t	1
4258	1176	To replace the axis labels	f	2
4259	1176	To hide outliers	f	3
4260	1176	To add decoration only	f	4
4261	1177	Table with icons or color status	t	1
4262	1177	3D surface chart	f	2
4263	1177	Pie chart with 20 slices	f	3
4264	1177	Network graph	f	4
4265	1178	Data updates frequently with low delay	t	1
4266	1178	Data is updated once a year	f	2
4267	1178	Data is always perfect	f	3
4268	1178	Data needs no cleaning	f	4
4269	1179	Put the most important information where users look first	t	1
4270	1179	Hide the main KPIs at the bottom	f	2
4271	1179	Use random placement for variety	f	3
4272	1179	Avoid alignment completely	f	4
4273	1180	Open a detailed page or record from a summary view	t	1
4274	1180	Delete the current chart	f	2
4275	1180	Change the dataset schema	f	3
4276	1180	Export only the title	f	4
4277	1181	It improves readability and visual consistency	t	1
4278	1181	It makes the data larger	f	2
4279	1181	It removes the need for charts	f	3
4280	1181	It guarantees higher accuracy	f	4
4281	1182	A defined period like last week, last month, or last 30 days	t	1
4282	1182	A chart border thickness	f	2
4283	1182	A color palette type	f	3
4284	1182	A file format	f	4
4285	1183	To show the key metrics at a glance	t	1
4286	1183	To show every raw record	f	2
4287	1183	To hide filters	f	3
4288	1183	To display only decoration	f	4
4289	1184	Conversion rate	t	1
4290	1184	Font size	f	2
4291	1184	Background image	f	3
4292	1184	Chart border radius	f	4
4293	1185	Bullet chart	t	1
4294	1185	Pie chart with many slices	f	2
4295	1185	Network graph	f	3
4296	1185	Scatter plot matrix	f	4
4297	1186	They use a lot of space for little data	t	1
4298	1186	They always show distributions	f	2
4299	1186	They are best for comparing many categories	f	3
4300	1186	They remove the need for targets	f	4
4301	1187	To add context like time window, filters, or definition	t	1
4302	1187	To replace the data	f	2
4303	1187	To hide the source	f	3
4304	1187	To change the data type	f	4
4305	1188	Use clear, unambiguous names	t	1
4306	1188	Use internal codes only	f	2
4307	1188	Use different names for the same metric	f	3
4308	1188	Avoid naming metrics at all	f	4
4309	1189	How often the dashboard data updates	t	1
4310	1189	How often you change colors	f	2
4311	1189	How often you change fonts	f	3
4312	1189	How often you export to PDF	f	4
4313	1190	Annotate the point and add context if possible	t	1
4314	1190	Hide that point to avoid confusion	f	2
4315	1190	Switch to a pie chart	f	3
4316	1190	Remove the x-axis labels	f	4
4317	1191	Ordering items based on a rule (for example, highest to lowest)	t	1
4318	1191	Deleting items randomly	f	2
4319	1191	Changing the units	f	3
4320	1191	Changing the chart type automatically	f	4
4321	1192	It fits long category names better	t	1
4322	1192	It removes the need for labels	f	2
4323	1192	It is always more accurate than any other chart	f	3
4324	1192	It forces time series	f	4
4325	1193	A named group like product, region, or department	t	1
4326	1193	A decimal value	f	2
4327	1193	A file type	f	3
4328	1193	A chart border	f	4
4329	1194	A measured value used to track something	t	1
4330	1194	A chart template	f	2
4331	1194	A color palette	f	3
4332	1194	A legend position	f	4
4333	1195	Comparing two series over time	t	1
4334	1195	Showing part-to-whole at one time	f	2
4335	1195	Showing only categories with no numbers	f	3
4336	1195	Replacing the need for axes	f	4
4337	1196	Place them close to the data and keep them clear	t	1
4338	1196	Hide them even when needed	f	2
4339	1196	Use tiny text to save space	f	3
4340	1196	Change legend meaning by page	f	4
4341	1197	Going back to a higher-level summary	t	1
4342	1197	Deleting details	f	2
4343	1197	Turning on 3D mode	f	3
4344	1197	Changing the database schema	f	4
4345	1198	Explain insights with context and a clear message	t	1
4346	1198	Use as many chart types as possible	f	2
4347	1198	Avoid any narrative	f	3
4348	1198	Replace analysis with decoration	f	4
4349	1199	A highlight or label pointing to an important value	t	1
4350	1199	A database function	f	2
4351	1199	A legend type	f	3
4352	1199	A file export option	f	4
4353	1200	100% stacked area or 100% stacked bar	t	1
4354	1200	Single pie chart	f	2
4355	1200	Scatter plot	f	3
4356	1200	Box plot	f	4
4357	1201	To increase trust and transparency	t	1
4358	1201	To make the chart more colorful	f	2
4359	1201	To remove the need for units	f	3
4360	1201	To avoid any governance	f	4
4361	1202	To let users change what data they see (time, region, segment)	t	1
4362	1202	To increase chart thickness	f	2
4363	1202	To replace labels	f	3
4364	1202	To hide the KPI definitions	f	4
4365	1203	Data indexed by time (days, weeks, months)	t	1
4366	1203	Only categories with no numbers	f	2
4367	1203	Only geographic data	f	3
4368	1203	Only survey text	f	4
4369	1204	Line chart	t	1
4370	1204	Exploded pie chart	f	2
4371	1204	3D bar chart	f	3
4372	1204	Word cloud	f	4
\.


--
-- Data for Name: staging_dni; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.staging_dni (ll1alu, ll2alu, nomalu, alu_dnialu) FROM stdin;
Moyo	Sánchez	Adriana	06024021
de la Maza	Segura	Alejandro	48109544
Yebra	de Llano	Laura	49333504
Sainz	Carpio	Alejandro	54352724
Moldovan	Irimie	Julián Nicolás	60129522
Rivera	Alderete	Isabella	N11897829
Arias	Giménez	Adriana	49442937
Mazón	Caballero	Sofía	02569318
Adeva	Torres	Álvaro	48225548
de Celis	Muñoz	Álvaro	54189676
Casero	López	Marina	11874784
Cavassa	Aparicio	Tomás	Y8840042
Pérez	Martínez	Ana Zitao	47315562
García	Soria	Andrea	47588042
Ruiz	Carrasco	Sergio	51009659
Serrada	de Pedraza	Claudia	06618119
García	Gómez	Daira	51007316
Cerezo	Resino	Raúl	05963339
López	Ruiz	Diego	54369131
Goizueta	Granda	Álvaro	02578999
García	Enamorado	Beltrán	50347682
Moericke	Serrano	Erik Wolfang	06001051
Crende	Daou	Elizabeth	48206010
de Mier	Fernández-Caro	Gonzalo	48034111
Carrasco	Barros	Gonzalo	05952488
Moreno	Rivas	Pablo	54022654
Lanzós	Calero	Álvaro	70289098
Herrero	San Pío	Luisa	70269287
Salas	Dorado	Gonzalo	54369366
Alba	Eguinoa	Iván	02566101
Hernández-Palacios	Prados	Martín	71990541
Riancho	Pena	María Lilia	54440992
Serna	González	Jaime	45332592
Pemán	Sanchiz	Patricio	05464043
Nombela	Terrado	Laura Chun	51494038
Rodríguez	Martín	Jaime	77799399
Esteban	de Nicolás	Álvaro	51134411
Ramírez	Sánchez-Marcos	Gonzalo	54189426
Hita	Moyá	Alexandre	77043243
Ramírez	Vega	Jesús	54211682
Sánchez	López	Marta	54366778
Asenjo	Martín	Jorge	53846543
Pedraza	Rioboo	Juan Manuel	05961361
Madrid	Espinosa	Laura	26936803
Reyero	González-Noriega	Laura	53989108
Jiménez	Jiménez	Laura	54495191
Lozano	Fernández	Alejandro	09818282
Weng	Chen	Bilin	79406939
López	Domínguez	Marcos	54494079
Marín	Fernández	Mario	47317452
Román	Vidal	Lucas	51536693
Pardo	Acosta	Samuel	BD607403
Poudereux	López-Barrantes	Miguel	51501099
Abal	Miranda	Nicolás	54480534
Sánchez	Núñez	Diego	02595244
Valiente	Saludes	Ignacio	51758855
Molinuevo	Quevedo	Javier	70426250
Isla	de Cegama	Ian David	08015151
Valverde	Albaladejo	Alejandro	48081409
Abad	Pérez	Pablo	06610675
Azcue	Aseguinolaza	Cristina	73040721
Palma	Pérez	Pablo	51484099
Navas	López	Martín	05732702
Peral	Renedo	Julio	06021048
Morenilla	López	Pablo	51818627
Lucas	Núñez	Andrés	47583769
Fernández	Cuesta	Javier	54298243
De Santos	Burgueño	Pablo	54210699
Soria	Aranguren	Adriana Alexandra	Z2102203
Esnarrizaga	Rodríguez	Paula	54191100
Sieira	Martínez	Marlon	50491223
Soligo	Sierra	Raúl	51708892
González	Hernández	Sofía	49155842
Gutiérrez	García	Juan	02316928
Herrera	Londoño	Tomás	43924576
Alcocer	Soberani	Xavier	60344836
Bidmead	Serrano	Olivia	70429033
Cruces	García	Marcos	70069968
\.


--
-- Data for Name: student_answer; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.student_answer (id, attempt_id, question_id, selected_option_id, free_text_answer, numeric_answer, is_correct, score, feedback, graded_by, graded_at) FROM stdin;
103	34	150	169	\N	\N	t	0.50	\N	\N	\N
104	34	161	209	\N	\N	t	0.50	\N	\N	\N
105	34	183	296	\N	\N	t	0.50	\N	\N	\N
106	34	191	330	\N	\N	t	0.50	\N	\N	\N
107	34	204	379	\N	\N	t	0.50	\N	\N	\N
110	37	150	169	\N	\N	t	0.50	\N	\N	\N
111	37	161	209	\N	\N	t	0.50	\N	\N	\N
112	37	183	296	\N	\N	t	0.50	\N	\N	\N
113	37	191	327	\N	\N	f	-0.25	\N	\N	\N
114	37	204	379	\N	\N	t	0.50	\N	\N	\N
115	38	115	38	\N	\N	t	0.50	\N	\N	\N
116	38	117	46	\N	\N	t	0.50	\N	\N	\N
117	38	121	61	\N	\N	t	0.50	\N	\N	\N
118	38	122	66	\N	\N	t	0.50	\N	\N	\N
119	38	124	70	\N	\N	t	0.50	\N	\N	\N
120	38	125	74	\N	\N	f	-0.25	\N	\N	\N
121	38	127	82	\N	\N	t	0.50	\N	\N	\N
122	38	131	95	\N	\N	t	0.50	\N	\N	\N
123	38	134	107	\N	\N	t	0.50	\N	\N	\N
124	38	142	135	\N	\N	t	0.50	\N	\N	\N
125	38	146	151	\N	\N	t	0.50	\N	\N	\N
126	38	152	174	\N	\N	t	0.50	\N	\N	\N
127	38	155	186	\N	\N	t	0.50	\N	\N	\N
128	38	170	246	\N	\N	t	0.50	\N	\N	\N
129	38	192	332	\N	\N	t	0.50	\N	\N	\N
130	38	197	351	\N	\N	t	0.50	\N	\N	\N
131	38	202	371	\N	\N	f	-0.25	\N	\N	\N
132	38	213	415	\N	\N	t	0.50	\N	\N	\N
133	38	214	422	\N	\N	t	0.50	\N	\N	\N
134	38	218	435	\N	\N	f	-0.25	\N	\N	\N
136	40	150	169	\N	\N	t	0.50	\N	\N	\N
137	40	161	209	\N	\N	t	0.50	\N	\N	\N
138	40	183	296	\N	\N	t	0.50	\N	\N	\N
139	40	191	330	\N	\N	t	0.50	\N	\N	\N
140	40	204	379	\N	\N	t	0.50	\N	\N	\N
141	41	111	24	\N	\N	t	0.50	\N	\N	\N
142	41	112	25	\N	\N	t	0.50	\N	\N	\N
143	41	122	66	\N	\N	t	0.50	\N	\N	\N
144	41	140	129	\N	\N	f	-0.25	\N	\N	\N
145	41	141	132	\N	\N	t	0.50	\N	\N	\N
146	41	142	135	\N	\N	t	0.50	\N	\N	\N
147	41	145	149	\N	\N	t	0.50	\N	\N	\N
148	41	146	151	\N	\N	t	0.50	\N	\N	\N
149	41	149	165	\N	\N	t	0.50	\N	\N	\N
150	41	154	184	\N	\N	t	0.50	\N	\N	\N
151	41	155	186	\N	\N	t	0.50	\N	\N	\N
152	41	156	189	\N	\N	t	0.50	\N	\N	\N
153	41	160	204	\N	\N	t	0.50	\N	\N	\N
154	41	165	224	\N	\N	t	0.50	\N	\N	\N
155	41	168	238	\N	\N	t	0.50	\N	\N	\N
156	41	172	255	\N	\N	t	0.50	\N	\N	\N
157	41	185	305	\N	\N	t	0.50	\N	\N	\N
158	41	207	394	\N	\N	t	0.50	\N	\N	\N
159	41	209	402	\N	\N	t	0.50	\N	\N	\N
160	41	214	422	\N	\N	t	0.50	\N	\N	\N
161	42	150	169	\N	\N	t	0.50	\N	\N	\N
162	42	161	210	\N	\N	f	-0.25	\N	\N	\N
163	42	183	296	\N	\N	t	0.50	\N	\N	\N
164	42	191	327	\N	\N	f	-0.25	\N	\N	\N
165	42	204	379	\N	\N	t	0.50	\N	\N	\N
166	43	150	169	\N	\N	t	0.50	\N	\N	\N
167	43	161	209	\N	\N	t	0.50	\N	\N	\N
168	43	183	296	\N	\N	t	0.50	\N	\N	\N
169	43	191	330	\N	\N	t	0.50	\N	\N	\N
170	43	204	379	\N	\N	t	0.50	\N	\N	\N
171	45	150	167	\N	\N	f	-0.33	\N	\N	\N
172	45	161	209	\N	\N	t	0.50	\N	\N	\N
173	45	183	298	\N	\N	f	-0.25	\N	\N	\N
174	45	191	330	\N	\N	t	0.50	\N	\N	\N
175	45	204	379	\N	\N	t	0.50	\N	\N	\N
176	50	115	38	\N	\N	t	0.50	\N	\N	\N
177	50	117	46	\N	\N	t	0.50	\N	\N	\N
178	50	121	61	\N	\N	t	0.50	\N	\N	\N
179	50	122	65	\N	\N	f	-0.50	\N	\N	\N
180	50	124	70	\N	\N	t	0.50	\N	\N	\N
181	50	125	74	\N	\N	f	-0.25	\N	\N	\N
182	50	127	82	\N	\N	t	0.50	\N	\N	\N
183	50	131	95	\N	\N	t	0.50	\N	\N	\N
184	50	134	107	\N	\N	t	0.50	\N	\N	\N
185	50	142	135	\N	\N	t	0.50	\N	\N	\N
186	50	146	151	\N	\N	t	0.50	\N	\N	\N
187	50	152	174	\N	\N	t	0.50	\N	\N	\N
188	50	155	186	\N	\N	t	0.50	\N	\N	\N
189	50	170	246	\N	\N	t	0.50	\N	\N	\N
190	50	192	332	\N	\N	t	0.50	\N	\N	\N
191	50	197	351	\N	\N	t	0.50	\N	\N	\N
192	50	202	374	\N	\N	f	-0.25	\N	\N	\N
193	50	213	415	\N	\N	t	0.50	\N	\N	\N
194	50	214	422	\N	\N	t	0.50	\N	\N	\N
195	50	218	437	\N	\N	t	0.50	\N	\N	\N
196	53	150	167	\N	\N	f	-0.33	\N	\N	\N
197	53	161	209	\N	\N	t	0.50	\N	\N	\N
198	53	183	296	\N	\N	t	0.50	\N	\N	\N
199	53	191	330	\N	\N	t	0.50	\N	\N	\N
200	53	204	379	\N	\N	t	0.50	\N	\N	\N
201	54	150	169	\N	\N	t	0.50	\N	\N	\N
202	54	161	209	\N	\N	t	0.50	\N	\N	\N
203	54	183	296	\N	\N	t	0.50	\N	\N	\N
204	54	191	330	\N	\N	t	0.50	\N	\N	\N
205	54	204	379	\N	\N	t	0.50	\N	\N	\N
206	56	150	169	\N	\N	t	0.50	\N	\N	\N
207	56	161	209	\N	\N	t	0.50	\N	\N	\N
208	56	183	296	\N	\N	t	0.50	\N	\N	\N
209	56	191	330	\N	\N	t	0.50	\N	\N	\N
210	56	204	379	\N	\N	t	0.50	\N	\N	\N
211	58	150	169	\N	\N	t	0.50	\N	\N	\N
212	58	161	209	\N	\N	t	0.50	\N	\N	\N
213	58	183	296	\N	\N	t	0.50	\N	\N	\N
214	58	191	329	\N	\N	f	-0.25	\N	\N	\N
215	58	204	381	\N	\N	f	-0.25	\N	\N	\N
291	67	150	169	\N	\N	t	0.50	\N	\N	\N
292	67	161	209	\N	\N	t	0.50	\N	\N	\N
293	67	183	296	\N	\N	t	0.50	\N	\N	\N
294	67	191	330	\N	\N	t	0.50	\N	\N	\N
295	67	204	379	\N	\N	t	0.50	\N	\N	\N
296	69	150	169	\N	\N	t	0.50	\N	\N	\N
297	69	161	209	\N	\N	t	0.50	\N	\N	\N
298	69	183	296	\N	\N	t	0.50	\N	\N	\N
299	69	191	330	\N	\N	t	0.50	\N	\N	\N
300	69	204	379	\N	\N	t	0.50	\N	\N	\N
303	75	106	4	\N	\N	t	0.50	\N	\N	\N
304	75	109	13	\N	\N	t	0.50	\N	\N	\N
305	75	110	20	\N	\N	f	-0.25	\N	\N	\N
306	75	138	121	\N	\N	t	0.50	\N	\N	\N
307	75	143	141	\N	\N	f	-0.25	\N	\N	\N
308	75	153	180	\N	\N	t	0.50	\N	\N	\N
309	75	159	200	\N	\N	f	-0.20	\N	\N	\N
310	75	164	223	\N	\N	f	-0.25	\N	\N	\N
311	75	176	269	\N	\N	t	0.50	\N	\N	\N
312	75	214	422	\N	\N	t	0.50	\N	\N	\N
313	77	106	4	\N	\N	t	0.50	\N	\N	\N
314	77	109	13	\N	\N	t	0.50	\N	\N	\N
315	77	110	20	\N	\N	f	-0.25	\N	\N	\N
316	77	138	121	\N	\N	t	0.50	\N	\N	\N
317	77	143	142	\N	\N	t	0.50	\N	\N	\N
318	77	153	180	\N	\N	t	0.50	\N	\N	\N
319	77	159	200	\N	\N	f	-0.20	\N	\N	\N
320	77	164	223	\N	\N	f	-0.25	\N	\N	\N
321	77	176	269	\N	\N	t	0.50	\N	\N	\N
322	77	214	422	\N	\N	t	0.50	\N	\N	\N
323	79	106	4	\N	\N	t	0.50	\N	\N	\N
324	79	109	13	\N	\N	t	0.50	\N	\N	\N
325	79	110	20	\N	\N	f	-0.25	\N	\N	\N
326	79	138	121	\N	\N	t	0.50	\N	\N	\N
327	79	143	142	\N	\N	t	0.50	\N	\N	\N
328	79	153	180	\N	\N	t	0.50	\N	\N	\N
329	79	159	199	\N	\N	t	0.50	\N	\N	\N
330	79	164	221	\N	\N	t	0.50	\N	\N	\N
331	79	176	269	\N	\N	t	0.50	\N	\N	\N
332	79	214	422	\N	\N	t	0.50	\N	\N	\N
333	81	106	4	\N	\N	t	0.50	\N	\N	\N
334	81	109	13	\N	\N	t	0.50	\N	\N	\N
335	81	110	18	\N	\N	t	0.50	\N	\N	\N
336	81	138	121	\N	\N	t	0.50	\N	\N	\N
337	81	143	142	\N	\N	t	0.50	\N	\N	\N
338	81	153	180	\N	\N	t	0.50	\N	\N	\N
339	81	159	199	\N	\N	t	0.50	\N	\N	\N
340	81	164	221	\N	\N	t	0.50	\N	\N	\N
341	81	176	269	\N	\N	t	0.50	\N	\N	\N
342	81	214	422	\N	\N	t	0.50	\N	\N	\N
345	88	107	8	\N	\N	t	0.50	\N	\N	\N
346	88	116	44	\N	\N	t	0.50	\N	\N	\N
347	88	118	50	\N	\N	t	0.50	\N	\N	\N
348	88	120	58	\N	\N	t	0.50	\N	\N	\N
349	88	137	116	\N	\N	f	-0.25	\N	\N	\N
350	88	145	149	\N	\N	t	0.50	\N	\N	\N
351	88	148	160	\N	\N	t	0.50	\N	\N	\N
352	88	150	169	\N	\N	t	0.50	\N	\N	\N
353	88	153	180	\N	\N	t	0.50	\N	\N	\N
354	88	154	184	\N	\N	t	0.50	\N	\N	\N
355	88	164	221	\N	\N	t	0.50	\N	\N	\N
356	88	175	266	\N	\N	t	0.50	\N	\N	\N
357	88	178	278	\N	\N	t	0.50	\N	\N	\N
358	88	181	290	\N	\N	t	0.50	\N	\N	\N
359	88	189	319	\N	\N	t	0.50	\N	\N	\N
360	88	196	349	\N	\N	t	0.50	\N	\N	\N
361	88	197	351	\N	\N	t	0.50	\N	\N	\N
362	88	200	365	\N	\N	t	0.50	\N	\N	\N
363	88	201	370	\N	\N	t	0.50	\N	\N	\N
364	88	207	394	\N	\N	t	0.50	\N	\N	\N
365	90	107	8	\N	\N	t	0.50	\N	\N	\N
366	90	116	44	\N	\N	t	0.50	\N	\N	\N
367	90	118	50	\N	\N	t	0.50	\N	\N	\N
368	90	120	58	\N	\N	t	0.50	\N	\N	\N
369	90	137	116	\N	\N	f	-0.25	\N	\N	\N
370	90	145	149	\N	\N	t	0.50	\N	\N	\N
371	90	148	160	\N	\N	t	0.50	\N	\N	\N
372	90	150	169	\N	\N	t	0.50	\N	\N	\N
373	90	153	180	\N	\N	t	0.50	\N	\N	\N
374	90	154	184	\N	\N	t	0.50	\N	\N	\N
375	90	164	221	\N	\N	t	0.50	\N	\N	\N
376	90	175	266	\N	\N	t	0.50	\N	\N	\N
377	90	178	278	\N	\N	t	0.50	\N	\N	\N
378	90	181	290	\N	\N	t	0.50	\N	\N	\N
379	90	189	319	\N	\N	t	0.50	\N	\N	\N
380	90	196	349	\N	\N	t	0.50	\N	\N	\N
381	90	197	351	\N	\N	t	0.50	\N	\N	\N
382	90	200	365	\N	\N	t	0.50	\N	\N	\N
383	90	201	370	\N	\N	t	0.50	\N	\N	\N
384	90	207	394	\N	\N	t	0.50	\N	\N	\N
385	86	150	169	\N	\N	t	0.50	\N	\N	\N
386	86	161	211	\N	\N	f	-0.25	\N	\N	\N
387	86	183	296	\N	\N	t	0.50	\N	\N	\N
388	86	191	330	\N	\N	t	0.50	\N	\N	\N
389	86	204	381	\N	\N	f	-0.25	\N	\N	\N
390	92	126	77	\N	\N	t	0.50	\N	\N	\N
391	92	128	85	\N	\N	t	0.50	\N	\N	\N
392	92	131	95	\N	\N	t	0.50	\N	\N	\N
393	92	144	145	\N	\N	f	-0.25	\N	\N	\N
394	92	147	156	\N	\N	f	-0.25	\N	\N	\N
395	92	154	184	\N	\N	t	0.50	\N	\N	\N
396	92	155	186	\N	\N	t	0.50	\N	\N	\N
397	92	161	209	\N	\N	t	0.50	\N	\N	\N
398	92	166	229	\N	\N	t	0.50	\N	\N	\N
399	92	168	239	\N	\N	f	-0.25	\N	\N	\N
400	92	173	259	\N	\N	t	0.50	\N	\N	\N
401	92	174	263	\N	\N	t	0.50	\N	\N	\N
402	92	179	280	\N	\N	t	0.50	\N	\N	\N
403	92	184	300	\N	\N	t	0.50	\N	\N	\N
404	92	188	316	\N	\N	t	0.50	\N	\N	\N
405	92	198	358	\N	\N	t	0.50	\N	\N	\N
406	92	202	371	\N	\N	f	-0.25	\N	\N	\N
407	92	212	411	\N	\N	t	0.50	\N	\N	\N
408	92	214	422	\N	\N	t	0.50	\N	\N	\N
409	92	215	426	\N	\N	t	0.50	\N	\N	\N
410	94	126	78	\N	\N	f	-0.33	\N	\N	\N
411	94	128	85	\N	\N	t	0.50	\N	\N	\N
412	94	131	95	\N	\N	t	0.50	\N	\N	\N
413	94	144	146	\N	\N	t	0.50	\N	\N	\N
414	94	147	156	\N	\N	f	-0.25	\N	\N	\N
415	94	154	184	\N	\N	t	0.50	\N	\N	\N
416	94	155	186	\N	\N	t	0.50	\N	\N	\N
417	94	161	209	\N	\N	t	0.50	\N	\N	\N
418	94	166	229	\N	\N	t	0.50	\N	\N	\N
419	94	168	238	\N	\N	t	0.50	\N	\N	\N
420	94	173	259	\N	\N	t	0.50	\N	\N	\N
421	94	174	263	\N	\N	t	0.50	\N	\N	\N
422	94	179	280	\N	\N	t	0.50	\N	\N	\N
423	94	184	300	\N	\N	t	0.50	\N	\N	\N
424	94	188	316	\N	\N	t	0.50	\N	\N	\N
425	94	198	356	\N	\N	f	-0.25	\N	\N	\N
426	94	202	371	\N	\N	f	-0.25	\N	\N	\N
427	94	212	411	\N	\N	t	0.50	\N	\N	\N
428	94	214	422	\N	\N	t	0.50	\N	\N	\N
429	94	215	424	\N	\N	f	-0.25	\N	\N	\N
430	93	126	78	\N	\N	f	-0.33	\N	\N	\N
431	93	128	85	\N	\N	t	0.50	\N	\N	\N
432	93	131	95	\N	\N	t	0.50	\N	\N	\N
433	93	144	146	\N	\N	t	0.50	\N	\N	\N
434	93	147	156	\N	\N	f	-0.25	\N	\N	\N
435	93	154	185	\N	\N	f	-0.25	\N	\N	\N
436	93	155	186	\N	\N	t	0.50	\N	\N	\N
437	93	161	209	\N	\N	t	0.50	\N	\N	\N
438	93	166	229	\N	\N	t	0.50	\N	\N	\N
439	93	168	239	\N	\N	f	-0.25	\N	\N	\N
440	93	173	258	\N	\N	f	-0.25	\N	\N	\N
441	93	174	263	\N	\N	t	0.50	\N	\N	\N
442	93	179	280	\N	\N	t	0.50	\N	\N	\N
443	93	184	300	\N	\N	t	0.50	\N	\N	\N
444	93	188	316	\N	\N	t	0.50	\N	\N	\N
445	93	198	358	\N	\N	t	0.50	\N	\N	\N
446	93	202	371	\N	\N	f	-0.25	\N	\N	\N
447	93	212	411	\N	\N	t	0.50	\N	\N	\N
448	93	214	422	\N	\N	t	0.50	\N	\N	\N
449	93	215	424	\N	\N	f	-0.25	\N	\N	\N
450	99	128	85	\N	\N	t	0.50	\N	\N	\N
451	99	156	189	\N	\N	t	0.50	\N	\N	\N
452	99	174	263	\N	\N	t	0.50	\N	\N	\N
453	99	175	266	\N	\N	t	0.50	\N	\N	\N
454	99	206	387	\N	\N	t	0.50	\N	\N	\N
455	100	150	169	\N	\N	t	0.50	\N	\N	\N
456	100	161	209	\N	\N	t	0.50	\N	\N	\N
457	100	183	296	\N	\N	t	0.50	\N	\N	\N
458	100	191	330	\N	\N	t	0.50	\N	\N	\N
459	100	204	379	\N	\N	t	0.50	\N	\N	\N
460	101	107	8	\N	\N	t	0.50	\N	\N	\N
461	101	116	44	\N	\N	t	0.50	\N	\N	\N
462	101	118	50	\N	\N	t	0.50	\N	\N	\N
463	101	120	58	\N	\N	t	0.50	\N	\N	\N
464	101	137	117	\N	\N	t	0.50	\N	\N	\N
465	101	145	149	\N	\N	t	0.50	\N	\N	\N
466	101	148	160	\N	\N	t	0.50	\N	\N	\N
467	101	150	169	\N	\N	t	0.50	\N	\N	\N
468	101	153	180	\N	\N	t	0.50	\N	\N	\N
469	101	154	183	\N	\N	f	-0.25	\N	\N	\N
470	101	164	221	\N	\N	t	0.50	\N	\N	\N
471	101	175	266	\N	\N	t	0.50	\N	\N	\N
472	101	178	278	\N	\N	t	0.50	\N	\N	\N
473	101	181	290	\N	\N	t	0.50	\N	\N	\N
474	101	189	319	\N	\N	t	0.50	\N	\N	\N
475	101	196	349	\N	\N	t	0.50	\N	\N	\N
476	101	197	351	\N	\N	t	0.50	\N	\N	\N
477	101	200	365	\N	\N	t	0.50	\N	\N	\N
478	101	201	370	\N	\N	t	0.50	\N	\N	\N
479	101	207	394	\N	\N	t	0.50	\N	\N	\N
480	103	150	169	\N	\N	t	0.50	\N	\N	\N
481	103	161	209	\N	\N	t	0.50	\N	\N	\N
482	103	183	296	\N	\N	t	0.50	\N	\N	\N
483	103	191	330	\N	\N	t	0.50	\N	\N	\N
484	103	204	379	\N	\N	t	0.50	\N	\N	\N
485	104	108	11	\N	\N	f	-0.25	\N	\N	\N
486	104	111	24	\N	\N	t	0.50	\N	\N	\N
487	104	117	47	\N	\N	f	-0.25	\N	\N	\N
488	104	121	62	\N	\N	f	-0.25	\N	\N	\N
489	104	127	82	\N	\N	t	0.50	\N	\N	\N
490	104	131	94	\N	\N	f	-0.25	\N	\N	\N
491	104	136	112	\N	\N	t	0.50	\N	\N	\N
492	104	140	130	\N	\N	t	0.50	\N	\N	\N
493	104	149	165	\N	\N	t	0.50	\N	\N	\N
494	104	155	186	\N	\N	t	0.50	\N	\N	\N
495	104	158	197	\N	\N	t	0.50	\N	\N	\N
496	104	170	246	\N	\N	t	0.50	\N	\N	\N
497	104	180	284	\N	\N	t	0.50	\N	\N	\N
498	104	188	316	\N	\N	t	0.50	\N	\N	\N
499	104	194	341	\N	\N	t	0.50	\N	\N	\N
500	104	205	384	\N	\N	t	0.50	\N	\N	\N
501	104	209	402	\N	\N	t	0.50	\N	\N	\N
502	104	210	406	\N	\N	t	0.50	\N	\N	\N
503	104	211	408	\N	\N	f	-0.25	\N	\N	\N
504	104	218	437	\N	\N	t	0.50	\N	\N	\N
505	105	108	12	\N	\N	t	0.50	\N	\N	\N
506	105	111	24	\N	\N	t	0.50	\N	\N	\N
507	105	117	46	\N	\N	t	0.50	\N	\N	\N
508	105	121	61	\N	\N	t	0.50	\N	\N	\N
509	105	127	82	\N	\N	t	0.50	\N	\N	\N
510	105	131	95	\N	\N	t	0.50	\N	\N	\N
511	105	136	112	\N	\N	t	0.50	\N	\N	\N
512	105	140	130	\N	\N	t	0.50	\N	\N	\N
513	105	149	165	\N	\N	t	0.50	\N	\N	\N
514	105	155	186	\N	\N	t	0.50	\N	\N	\N
515	105	158	197	\N	\N	t	0.50	\N	\N	\N
516	105	170	246	\N	\N	t	0.50	\N	\N	\N
517	105	180	286	\N	\N	f	-0.25	\N	\N	\N
518	105	188	316	\N	\N	t	0.50	\N	\N	\N
519	105	194	341	\N	\N	t	0.50	\N	\N	\N
520	105	205	384	\N	\N	t	0.50	\N	\N	\N
521	105	209	402	\N	\N	t	0.50	\N	\N	\N
522	105	210	406	\N	\N	t	0.50	\N	\N	\N
523	105	211	407	\N	\N	t	0.50	\N	\N	\N
524	105	218	437	\N	\N	t	0.50	\N	\N	\N
525	106	106	3	\N	\N	f	-0.25	\N	\N	\N
526	106	109	13	\N	\N	t	0.50	\N	\N	\N
527	106	110	18	\N	\N	t	0.50	\N	\N	\N
528	106	138	121	\N	\N	t	0.50	\N	\N	\N
529	106	143	142	\N	\N	t	0.50	\N	\N	\N
530	106	153	180	\N	\N	t	0.50	\N	\N	\N
531	106	159	199	\N	\N	t	0.50	\N	\N	\N
532	106	164	221	\N	\N	t	0.50	\N	\N	\N
533	106	176	269	\N	\N	t	0.50	\N	\N	\N
534	106	214	422	\N	\N	t	0.50	\N	\N	\N
535	107	150	169	\N	\N	t	0.50	\N	\N	\N
536	107	161	209	\N	\N	t	0.50	\N	\N	\N
537	107	183	296	\N	\N	t	0.50	\N	\N	\N
538	107	191	330	\N	\N	t	0.50	\N	\N	\N
539	107	204	379	\N	\N	t	0.50	\N	\N	\N
540	109	150	168	\N	\N	f	-0.33	\N	\N	\N
541	109	161	209	\N	\N	t	0.50	\N	\N	\N
542	109	183	296	\N	\N	t	0.50	\N	\N	\N
543	109	191	327	\N	\N	f	-0.25	\N	\N	\N
544	109	204	379	\N	\N	t	0.50	\N	\N	\N
545	111	128	85	\N	\N	t	0.50	\N	\N	\N
546	111	156	189	\N	\N	t	0.50	\N	\N	\N
547	111	174	263	\N	\N	t	0.50	\N	\N	\N
548	111	175	266	\N	\N	t	0.50	\N	\N	\N
549	111	206	387	\N	\N	t	0.50	\N	\N	\N
550	112	106	4	\N	\N	t	0.50	\N	\N	\N
551	112	109	13	\N	\N	t	0.50	\N	\N	\N
552	112	110	18	\N	\N	t	0.50	\N	\N	\N
553	112	138	121	\N	\N	t	0.50	\N	\N	\N
554	112	143	142	\N	\N	t	0.50	\N	\N	\N
555	112	153	178	\N	\N	f	-0.25	\N	\N	\N
556	112	159	201	\N	\N	f	-0.25	\N	\N	\N
557	112	164	221	\N	\N	t	0.50	\N	\N	\N
558	112	176	269	\N	\N	t	0.50	\N	\N	\N
559	112	214	422	\N	\N	t	0.50	\N	\N	\N
560	113	111	24	\N	\N	t	0.50	\N	\N	\N
561	113	112	25	\N	\N	t	0.50	\N	\N	\N
562	113	122	66	\N	\N	t	0.50	\N	\N	\N
563	113	140	130	\N	\N	t	0.50	\N	\N	\N
564	113	141	132	\N	\N	t	0.50	\N	\N	\N
565	113	142	135	\N	\N	t	0.50	\N	\N	\N
566	113	145	149	\N	\N	t	0.50	\N	\N	\N
567	113	146	151	\N	\N	t	0.50	\N	\N	\N
568	113	149	165	\N	\N	t	0.50	\N	\N	\N
569	113	154	184	\N	\N	t	0.50	\N	\N	\N
570	113	155	186	\N	\N	t	0.50	\N	\N	\N
571	113	156	189	\N	\N	t	0.50	\N	\N	\N
572	113	160	207	\N	\N	f	-0.25	\N	\N	\N
573	113	165	224	\N	\N	t	0.50	\N	\N	\N
574	113	168	238	\N	\N	t	0.50	\N	\N	\N
575	113	172	254	\N	\N	t	0.50	\N	\N	\N
576	113	185	305	\N	\N	t	0.50	\N	\N	\N
577	113	207	391	\N	\N	f	-0.25	\N	\N	\N
578	113	209	402	\N	\N	t	0.50	\N	\N	\N
579	113	214	422	\N	\N	t	0.50	\N	\N	\N
580	114	150	169	\N	\N	t	0.50	\N	\N	\N
581	114	161	209	\N	\N	t	0.50	\N	\N	\N
582	114	183	296	\N	\N	t	0.50	\N	\N	\N
583	114	191	330	\N	\N	t	0.50	\N	\N	\N
584	114	204	379	\N	\N	t	0.50	\N	\N	\N
586	119	126	77	\N	\N	t	0.50	\N	\N	\N
587	119	128	85	\N	\N	t	0.50	\N	\N	\N
588	119	131	95	\N	\N	t	0.50	\N	\N	\N
589	119	144	145	\N	\N	f	-0.25	\N	\N	\N
590	119	147	155	\N	\N	t	0.50	\N	\N	\N
591	119	154	183	\N	\N	f	-0.25	\N	\N	\N
592	119	155	187	\N	\N	f	-0.50	\N	\N	\N
593	119	161	211	\N	\N	f	-0.25	\N	\N	\N
594	119	166	229	\N	\N	t	0.50	\N	\N	\N
595	119	168	237	\N	\N	f	-0.25	\N	\N	\N
596	119	173	258	\N	\N	f	-0.25	\N	\N	\N
597	119	174	262	\N	\N	f	-0.25	\N	\N	\N
598	119	179	280	\N	\N	t	0.50	\N	\N	\N
599	119	184	301	\N	\N	f	-0.25	\N	\N	\N
600	119	188	316	\N	\N	t	0.50	\N	\N	\N
601	119	198	357	\N	\N	f	-0.25	\N	\N	\N
602	119	202	373	\N	\N	t	0.50	\N	\N	\N
603	119	212	413	\N	\N	f	-0.25	\N	\N	\N
604	119	214	422	\N	\N	t	0.50	\N	\N	\N
605	119	215	424	\N	\N	f	-0.25	\N	\N	\N
606	120	128	85	\N	\N	t	0.50	\N	\N	\N
607	120	156	189	\N	\N	t	0.50	\N	\N	\N
608	120	174	261	\N	\N	f	-0.25	\N	\N	\N
609	120	175	266	\N	\N	t	0.50	\N	\N	\N
610	120	206	389	\N	\N	f	-0.25	\N	\N	\N
611	123	128	85	\N	\N	t	0.50	\N	\N	\N
612	123	156	189	\N	\N	t	0.50	\N	\N	\N
613	123	174	263	\N	\N	t	0.50	\N	\N	\N
614	123	175	266	\N	\N	t	0.50	\N	\N	\N
615	123	206	389	\N	\N	f	-0.25	\N	\N	\N
616	124	128	85	\N	\N	t	0.50	\N	\N	\N
617	124	156	189	\N	\N	t	0.50	\N	\N	\N
618	124	174	263	\N	\N	t	0.50	\N	\N	\N
619	124	175	266	\N	\N	t	0.50	\N	\N	\N
620	124	206	387	\N	\N	t	0.50	\N	\N	\N
621	129	115	38	\N	\N	t	0.50	\N	\N	\N
622	129	116	44	\N	\N	t	0.50	\N	\N	\N
623	129	120	59	\N	\N	f	-0.25	\N	\N	\N
624	129	123	67	\N	\N	t	0.50	\N	\N	\N
625	129	132	100	\N	\N	t	0.50	\N	\N	\N
626	129	155	187	\N	\N	f	-0.50	\N	\N	\N
627	129	156	189	\N	\N	t	0.50	\N	\N	\N
628	129	163	217	\N	\N	f	-0.25	\N	\N	\N
629	129	175	266	\N	\N	t	0.50	\N	\N	\N
630	129	182	292	\N	\N	f	-0.25	\N	\N	\N
631	129	183	296	\N	\N	t	0.50	\N	\N	\N
632	129	198	358	\N	\N	t	0.50	\N	\N	\N
633	129	204	379	\N	\N	t	0.50	\N	\N	\N
634	129	212	411	\N	\N	t	0.50	\N	\N	\N
635	129	214	422	\N	\N	t	0.50	\N	\N	\N
636	129	219	439	\N	\N	t	0.50	\N	\N	\N
637	129	225	464	\N	\N	t	0.50	\N	\N	\N
638	129	226	469	\N	\N	f	-0.25	\N	\N	\N
639	130	115	40	\N	\N	f	-0.25	\N	\N	\N
640	130	116	44	\N	\N	t	0.50	\N	\N	\N
641	130	120	58	\N	\N	t	0.50	\N	\N	\N
642	130	123	67	\N	\N	t	0.50	\N	\N	\N
643	130	132	100	\N	\N	t	0.50	\N	\N	\N
644	130	144	144	\N	\N	f	-0.25	\N	\N	\N
645	130	150	169	\N	\N	t	0.50	\N	\N	\N
646	130	155	186	\N	\N	t	0.50	\N	\N	\N
647	130	156	189	\N	\N	t	0.50	\N	\N	\N
648	130	163	219	\N	\N	t	0.50	\N	\N	\N
649	130	175	266	\N	\N	t	0.50	\N	\N	\N
650	130	182	294	\N	\N	t	0.50	\N	\N	\N
651	130	183	296	\N	\N	t	0.50	\N	\N	\N
652	130	198	358	\N	\N	t	0.50	\N	\N	\N
653	130	204	379	\N	\N	t	0.50	\N	\N	\N
654	130	212	411	\N	\N	t	0.50	\N	\N	\N
655	130	214	422	\N	\N	t	0.50	\N	\N	\N
656	130	219	439	\N	\N	t	0.50	\N	\N	\N
657	130	225	464	\N	\N	t	0.50	\N	\N	\N
658	130	226	470	\N	\N	t	0.50	\N	\N	\N
659	131	115	38	\N	\N	t	0.50	\N	\N	\N
660	131	116	44	\N	\N	t	0.50	\N	\N	\N
661	131	120	58	\N	\N	t	0.50	\N	\N	\N
662	131	123	67	\N	\N	t	0.50	\N	\N	\N
663	131	132	100	\N	\N	t	0.50	\N	\N	\N
664	131	144	146	\N	\N	t	0.50	\N	\N	\N
665	131	150	169	\N	\N	t	0.50	\N	\N	\N
666	131	155	186	\N	\N	t	0.50	\N	\N	\N
667	131	156	189	\N	\N	t	0.50	\N	\N	\N
668	131	163	219	\N	\N	t	0.50	\N	\N	\N
669	131	175	266	\N	\N	t	0.50	\N	\N	\N
670	131	182	294	\N	\N	t	0.50	\N	\N	\N
671	131	183	296	\N	\N	t	0.50	\N	\N	\N
672	131	198	358	\N	\N	t	0.50	\N	\N	\N
673	131	204	379	\N	\N	t	0.50	\N	\N	\N
674	131	212	411	\N	\N	t	0.50	\N	\N	\N
675	131	214	422	\N	\N	t	0.50	\N	\N	\N
676	131	219	439	\N	\N	t	0.50	\N	\N	\N
677	131	225	464	\N	\N	t	0.50	\N	\N	\N
678	131	226	470	\N	\N	t	0.50	\N	\N	\N
679	128	116	44	\N	\N	t	0.50	\N	\N	\N
680	128	121	61	\N	\N	t	0.50	\N	\N	\N
681	128	122	66	\N	\N	t	0.50	\N	\N	\N
682	128	125	75	\N	\N	t	0.50	\N	\N	\N
683	128	136	112	\N	\N	t	0.50	\N	\N	\N
684	128	142	135	\N	\N	t	0.50	\N	\N	\N
685	128	146	151	\N	\N	t	0.50	\N	\N	\N
686	128	170	246	\N	\N	t	0.50	\N	\N	\N
687	128	171	250	\N	\N	t	0.50	\N	\N	\N
688	128	175	266	\N	\N	t	0.50	\N	\N	\N
689	128	179	280	\N	\N	t	0.50	\N	\N	\N
690	128	184	300	\N	\N	t	0.50	\N	\N	\N
691	128	187	314	\N	\N	t	0.50	\N	\N	\N
692	128	189	319	\N	\N	t	0.50	\N	\N	\N
693	128	196	349	\N	\N	t	0.50	\N	\N	\N
694	128	199	362	\N	\N	f	-0.25	\N	\N	\N
695	128	204	379	\N	\N	t	0.50	\N	\N	\N
696	128	208	398	\N	\N	t	0.50	\N	\N	\N
697	128	217	431	\N	\N	t	0.50	\N	\N	\N
698	128	222	455	\N	\N	t	0.50	\N	\N	\N
699	134	150	169	\N	\N	t	0.50	\N	\N	\N
700	134	161	209	\N	\N	t	0.50	\N	\N	\N
701	134	183	296	\N	\N	t	0.50	\N	\N	\N
702	134	191	330	\N	\N	t	0.50	\N	\N	\N
703	134	204	379	\N	\N	t	0.50	\N	\N	\N
704	135	119	56	\N	\N	f	-0.25	\N	\N	\N
705	135	120	58	\N	\N	t	0.50	\N	\N	\N
706	135	137	117	\N	\N	t	0.50	\N	\N	\N
707	135	138	122	\N	\N	f	-0.33	\N	\N	\N
708	135	139	124	\N	\N	t	0.50	\N	\N	\N
709	135	143	142	\N	\N	t	0.50	\N	\N	\N
710	135	150	169	\N	\N	t	0.50	\N	\N	\N
711	135	152	174	\N	\N	t	0.50	\N	\N	\N
712	135	155	186	\N	\N	t	0.50	\N	\N	\N
713	135	184	300	\N	\N	t	0.50	\N	\N	\N
714	135	187	314	\N	\N	t	0.50	\N	\N	\N
715	135	194	341	\N	\N	t	0.50	\N	\N	\N
716	135	195	344	\N	\N	t	0.50	\N	\N	\N
717	135	199	362	\N	\N	f	-0.25	\N	\N	\N
718	135	207	394	\N	\N	t	0.50	\N	\N	\N
719	135	208	397	\N	\N	f	-0.25	\N	\N	\N
720	135	209	402	\N	\N	t	0.50	\N	\N	\N
721	135	212	411	\N	\N	t	0.50	\N	\N	\N
722	135	225	464	\N	\N	t	0.50	\N	\N	\N
723	135	230	486	\N	\N	t	0.50	\N	\N	\N
724	126	111	24	\N	\N	t	0.50	\N	\N	\N
725	137	106	4	\N	\N	t	0.50	\N	\N	\N
726	137	108	12	\N	\N	t	0.50	\N	\N	\N
727	137	112	25	\N	\N	t	0.50	\N	\N	\N
728	137	113	32	\N	\N	t	0.50	\N	\N	\N
729	137	121	61	\N	\N	t	0.50	\N	\N	\N
730	137	137	117	\N	\N	t	0.50	\N	\N	\N
731	137	142	135	\N	\N	t	0.50	\N	\N	\N
732	137	145	149	\N	\N	t	0.50	\N	\N	\N
733	137	147	155	\N	\N	t	0.50	\N	\N	\N
734	137	151	172	\N	\N	t	0.50	\N	\N	\N
735	137	152	174	\N	\N	t	0.50	\N	\N	\N
736	137	156	189	\N	\N	t	0.50	\N	\N	\N
737	137	158	197	\N	\N	t	0.50	\N	\N	\N
738	137	161	209	\N	\N	t	0.50	\N	\N	\N
739	137	162	212	\N	\N	t	0.50	\N	\N	\N
740	137	169	241	\N	\N	f	-0.25	\N	\N	\N
741	137	170	246	\N	\N	t	0.50	\N	\N	\N
742	137	171	250	\N	\N	t	0.50	\N	\N	\N
743	137	174	263	\N	\N	t	0.50	\N	\N	\N
744	137	176	269	\N	\N	t	0.50	\N	\N	\N
745	137	216	430	\N	\N	t	0.50	\N	\N	\N
746	137	186	311	\N	\N	t	0.50	\N	\N	\N
747	137	188	316	\N	\N	t	0.50	\N	\N	\N
748	137	194	341	\N	\N	t	0.50	\N	\N	\N
749	137	195	344	\N	\N	t	0.50	\N	\N	\N
750	137	198	358	\N	\N	t	0.50	\N	\N	\N
751	137	201	370	\N	\N	t	0.50	\N	\N	\N
752	137	203	376	\N	\N	t	0.50	\N	\N	\N
753	137	206	387	\N	\N	t	0.50	\N	\N	\N
754	137	207	394	\N	\N	t	0.50	\N	\N	\N
755	137	209	400	\N	\N	f	-0.25	\N	\N	\N
756	137	214	422	\N	\N	t	0.50	\N	\N	\N
757	137	218	437	\N	\N	t	0.50	\N	\N	\N
758	137	221	448	\N	\N	t	0.50	\N	\N	\N
759	137	225	464	\N	\N	t	0.50	\N	\N	\N
760	137	226	470	\N	\N	t	0.50	\N	\N	\N
761	137	228	479	\N	\N	t	0.50	\N	\N	\N
762	137	229	482	\N	\N	t	0.50	\N	\N	\N
763	137	230	486	\N	\N	t	0.50	\N	\N	\N
764	141	106	4	\N	\N	t	0.50	\N	\N	\N
765	141	108	12	\N	\N	t	0.50	\N	\N	\N
766	141	112	25	\N	\N	t	0.50	\N	\N	\N
767	141	113	32	\N	\N	t	0.50	\N	\N	\N
768	141	121	61	\N	\N	t	0.50	\N	\N	\N
769	141	126	77	\N	\N	t	0.50	\N	\N	\N
770	141	137	117	\N	\N	t	0.50	\N	\N	\N
771	141	142	135	\N	\N	t	0.50	\N	\N	\N
772	141	145	149	\N	\N	t	0.50	\N	\N	\N
773	141	147	155	\N	\N	t	0.50	\N	\N	\N
774	141	151	172	\N	\N	t	0.50	\N	\N	\N
775	141	152	174	\N	\N	t	0.50	\N	\N	\N
776	141	156	189	\N	\N	t	0.50	\N	\N	\N
777	141	158	197	\N	\N	t	0.50	\N	\N	\N
778	141	161	209	\N	\N	t	0.50	\N	\N	\N
779	141	162	212	\N	\N	t	0.50	\N	\N	\N
780	141	169	240	\N	\N	t	0.50	\N	\N	\N
781	141	170	245	\N	\N	f	-0.25	\N	\N	\N
782	141	171	250	\N	\N	t	0.50	\N	\N	\N
783	141	174	263	\N	\N	t	0.50	\N	\N	\N
784	141	176	269	\N	\N	t	0.50	\N	\N	\N
785	141	216	430	\N	\N	t	0.50	\N	\N	\N
786	141	186	311	\N	\N	t	0.50	\N	\N	\N
787	141	188	316	\N	\N	t	0.50	\N	\N	\N
788	141	194	341	\N	\N	t	0.50	\N	\N	\N
789	141	195	344	\N	\N	t	0.50	\N	\N	\N
790	141	198	358	\N	\N	t	0.50	\N	\N	\N
791	141	201	370	\N	\N	t	0.50	\N	\N	\N
792	141	203	376	\N	\N	t	0.50	\N	\N	\N
793	141	206	387	\N	\N	t	0.50	\N	\N	\N
794	141	207	394	\N	\N	t	0.50	\N	\N	\N
795	141	209	402	\N	\N	t	0.50	\N	\N	\N
796	141	214	422	\N	\N	t	0.50	\N	\N	\N
797	141	218	437	\N	\N	t	0.50	\N	\N	\N
798	141	221	448	\N	\N	t	0.50	\N	\N	\N
799	141	225	464	\N	\N	t	0.50	\N	\N	\N
800	141	226	470	\N	\N	t	0.50	\N	\N	\N
801	141	228	479	\N	\N	t	0.50	\N	\N	\N
802	141	229	482	\N	\N	t	0.50	\N	\N	\N
803	141	230	486	\N	\N	t	0.50	\N	\N	\N
804	144	150	169	\N	\N	t	0.50	\N	\N	\N
805	144	161	209	\N	\N	t	0.50	\N	\N	\N
806	144	183	296	\N	\N	t	0.50	\N	\N	\N
807	144	191	330	\N	\N	t	0.50	\N	\N	\N
808	144	204	379	\N	\N	t	0.50	\N	\N	\N
809	145	106	4	\N	\N	t	0.50	\N	\N	\N
810	145	109	14	\N	\N	f	-0.25	\N	\N	\N
811	145	110	18	\N	\N	t	0.50	\N	\N	\N
812	145	138	121	\N	\N	t	0.50	\N	\N	\N
813	145	143	142	\N	\N	t	0.50	\N	\N	\N
814	145	153	180	\N	\N	t	0.50	\N	\N	\N
815	145	159	199	\N	\N	t	0.50	\N	\N	\N
816	145	164	221	\N	\N	t	0.50	\N	\N	\N
817	145	176	269	\N	\N	t	0.50	\N	\N	\N
818	145	214	420	\N	\N	f	-0.25	\N	\N	\N
819	148	115	38	\N	\N	t	0.50	\N	\N	\N
820	148	116	44	\N	\N	t	0.50	\N	\N	\N
821	148	120	58	\N	\N	t	0.50	\N	\N	\N
822	148	123	67	\N	\N	t	0.50	\N	\N	\N
823	148	132	100	\N	\N	t	0.50	\N	\N	\N
824	148	144	146	\N	\N	t	0.50	\N	\N	\N
825	148	150	169	\N	\N	t	0.50	\N	\N	\N
826	148	155	186	\N	\N	t	0.50	\N	\N	\N
827	148	156	189	\N	\N	t	0.50	\N	\N	\N
828	148	163	219	\N	\N	t	0.50	\N	\N	\N
829	148	175	266	\N	\N	t	0.50	\N	\N	\N
830	148	182	294	\N	\N	t	0.50	\N	\N	\N
831	148	183	297	\N	\N	f	-0.25	\N	\N	\N
832	148	198	358	\N	\N	t	0.50	\N	\N	\N
833	148	204	379	\N	\N	t	0.50	\N	\N	\N
834	148	212	414	\N	\N	f	-0.25	\N	\N	\N
835	148	214	422	\N	\N	t	0.50	\N	\N	\N
836	148	219	439	\N	\N	t	0.50	\N	\N	\N
837	148	225	464	\N	\N	t	0.50	\N	\N	\N
838	148	226	470	\N	\N	t	0.50	\N	\N	\N
839	149	106	4	\N	\N	t	0.50	\N	\N	\N
840	149	108	12	\N	\N	t	0.50	\N	\N	\N
841	149	112	25	\N	\N	t	0.50	\N	\N	\N
842	149	113	32	\N	\N	t	0.50	\N	\N	\N
843	149	121	61	\N	\N	t	0.50	\N	\N	\N
844	149	126	77	\N	\N	t	0.50	\N	\N	\N
845	149	137	117	\N	\N	t	0.50	\N	\N	\N
846	149	142	135	\N	\N	t	0.50	\N	\N	\N
847	149	145	149	\N	\N	t	0.50	\N	\N	\N
848	149	147	155	\N	\N	t	0.50	\N	\N	\N
849	149	151	172	\N	\N	t	0.50	\N	\N	\N
850	149	152	174	\N	\N	t	0.50	\N	\N	\N
851	149	156	189	\N	\N	t	0.50	\N	\N	\N
852	149	158	197	\N	\N	t	0.50	\N	\N	\N
853	149	161	209	\N	\N	t	0.50	\N	\N	\N
854	149	162	212	\N	\N	t	0.50	\N	\N	\N
855	149	169	241	\N	\N	f	-0.25	\N	\N	\N
856	149	170	246	\N	\N	t	0.50	\N	\N	\N
857	149	171	250	\N	\N	t	0.50	\N	\N	\N
858	149	174	263	\N	\N	t	0.50	\N	\N	\N
859	149	176	269	\N	\N	t	0.50	\N	\N	\N
860	149	186	311	\N	\N	t	0.50	\N	\N	\N
861	149	188	316	\N	\N	t	0.50	\N	\N	\N
862	149	194	341	\N	\N	t	0.50	\N	\N	\N
863	149	195	344	\N	\N	t	0.50	\N	\N	\N
864	149	198	358	\N	\N	t	0.50	\N	\N	\N
865	149	201	370	\N	\N	t	0.50	\N	\N	\N
866	149	203	376	\N	\N	t	0.50	\N	\N	\N
867	149	206	387	\N	\N	t	0.50	\N	\N	\N
868	149	207	394	\N	\N	t	0.50	\N	\N	\N
869	149	209	402	\N	\N	t	0.50	\N	\N	\N
870	149	214	422	\N	\N	t	0.50	\N	\N	\N
871	149	216	430	\N	\N	t	0.50	\N	\N	\N
872	149	218	437	\N	\N	t	0.50	\N	\N	\N
873	149	221	448	\N	\N	t	0.50	\N	\N	\N
874	149	225	464	\N	\N	t	0.50	\N	\N	\N
875	149	226	470	\N	\N	t	0.50	\N	\N	\N
876	149	228	479	\N	\N	t	0.50	\N	\N	\N
877	149	229	482	\N	\N	t	0.50	\N	\N	\N
878	149	230	486	\N	\N	t	0.50	\N	\N	\N
879	150	106	4	\N	\N	t	0.50	\N	\N	\N
880	150	109	13	\N	\N	t	0.50	\N	\N	\N
881	150	110	18	\N	\N	t	0.50	\N	\N	\N
882	150	138	121	\N	\N	t	0.50	\N	\N	\N
883	150	143	142	\N	\N	t	0.50	\N	\N	\N
884	150	153	180	\N	\N	t	0.50	\N	\N	\N
885	150	159	199	\N	\N	t	0.50	\N	\N	\N
886	150	164	221	\N	\N	t	0.50	\N	\N	\N
887	150	176	269	\N	\N	t	0.50	\N	\N	\N
888	150	214	422	\N	\N	t	0.50	\N	\N	\N
889	151	128	85	\N	\N	t	0.50	\N	\N	\N
890	151	156	189	\N	\N	t	0.50	\N	\N	\N
891	151	174	263	\N	\N	t	0.50	\N	\N	\N
892	151	175	266	\N	\N	t	0.50	\N	\N	\N
893	151	206	387	\N	\N	t	0.50	\N	\N	\N
\.


--
-- Data for Name: test; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.test (id, course_id, title, description, test_type, is_published, total_points, time_limit_minutes, max_attempts, grading_strategy, start_time, end_time, randomize_questions, randomize_options, created_by, created_at) FROM stdin;
38	1	Random 20 – created by 09393767	Random 20-question test from course 2526-45810-A (Cloud Digital Leader – Google (Inglés)).	quiz	f	10.00	\N	1	latest	\N	\N	f	f	\N	2025-12-12 09:05:42.080448+00
39	1	Random 20 – created by 49333504	Random 20-question test from course 2526-45810-A (Cloud Digital Leader – Google (Inglés)).	quiz	f	10.00	\N	1	latest	\N	\N	f	f	\N	2025-12-12 09:07:20.415557+00
31	1	Grupo A	Random 20-question test from course 2526-45810-A (Cloud Digital Leader – Google (Inglés)).	quiz	f	10.00	\N	1	latest	\N	\N	f	f	\N	2025-12-05 09:32:01.326862+00
32	1	primero	Random 20-question test from course 2526-45810-A (Cloud Digital Leader – Google (Inglés)).	quiz	f	10.00	\N	\N	latest	\N	\N	f	f	\N	2025-12-05 10:06:28.096299+00
33	1	class 2	Random 20-question test from course 2526-45810-A (Cloud Digital Leader – Google (Inglés)).	quiz	f	10.00	\N	1	latest	\N	\N	f	f	\N	2025-12-05 11:15:24.147366+00
10	1	Mini test para puebas	Random 5-question test from course 2526-45810-A (Cloud Digital Leader – Google (Inglés)).	quiz	f	2.50	\N	\N	latest	\N	\N	f	f	\N	2025-11-24 11:19:27.669347+00
41	1	Random 20 – created by 53989108	Random 20-question test from course 2526-45810-A (Cloud Digital Leader – Google (Inglés)).	quiz	f	10.00	\N	1	latest	\N	\N	f	f	\N	2025-12-12 10:16:24.47423+00
42	1	Random 40 – created by 09393767	Random 40-question test from course 2526-45810-A (Cloud Digital Leader – Google (Inglés)).	quiz	f	20.00	\N	1	latest	\N	\N	f	f	\N	2025-12-12 10:19:25.363852+00
12	1	#1 de 20 preguntas (Laura)	Random 20-question test from course 2526-45810-A (Cloud Digital Leader – Google (Inglés)).	quiz	f	10.00	\N	\N	latest	\N	\N	f	f	\N	2025-11-25 11:58:55.558525+00
13	1	#2 de 20 preguntas (Laura)	Random 20-question test from course 2526-45810-A (Cloud Digital Leader – Google (Inglés)).	quiz	f	10.00	\N	\N	latest	\N	\N	f	f	\N	2025-11-25 12:15:23.968807+00
34	1	Random 20 – created by 49155842	Random 20-question test from course 2526-45810-A (Cloud Digital Leader – Google (Inglés)).	quiz	f	10.00	\N	\N	latest	\N	\N	f	f	\N	2025-12-05 16:52:08.404844+00
35	1	Random 5 – created by 49333504	Random 5-question test from course 2526-45810-A (Cloud Digital Leader – Google (Inglés)).	quiz	f	2.50	\N	\N	latest	\N	\N	f	f	\N	2025-12-06 12:12:39.592623+00
24	1	made by Ramiro	Random 10-question test from course 2526-45810-A (Cloud Digital Leader – Google (Inglés)).	quiz	f	5.00	\N	\N	latest	\N	\N	f	f	1	2025-12-04 20:12:41.894079+00
36	1	Random 20 – created by 49155842	Random 20-question test from course 2526-45810-A (Cloud Digital Leader – Google (Inglés)).	quiz	f	10.00	\N	1	latest	\N	\N	f	f	\N	2025-12-11 08:09:12.85186+00
37	1	Random 20 – created by 60344836	Random 20-question test from course 2526-45810-A (Cloud Digital Leader – Google (Inglés)).	quiz	f	10.00	\N	1	latest	\N	\N	f	f	\N	2025-12-12 08:02:52.289236+00
44	3	Random 20 – created by 09393767	Random 20-question test from course 2526-ANBA-3-5354-A (Big Data III: Visualization).	quiz	f	10.00	\N	1	latest	\N	\N	f	f	1	2025-12-18 17:43:05.60202+00
\.


--
-- Data for Name: test_attempt; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.test_attempt (id, test_id, student_id, attempt_number, started_at, submitted_at, status, score, max_score, percentage, auto_graded) FROM stdin;
42	10	1	2	2025-11-25 18:19:59.083872+00	2025-11-25 18:21:09.365329+00	graded	1.00	2.50	40.00	t
43	10	1	3	2025-11-25 22:25:53.417261+00	2025-11-25 22:27:50.361738+00	graded	2.50	2.50	100.00	t
44	10	12	1	2025-11-25 22:28:24.085736+00	\N	in_progress	\N	2.50	\N	f
45	10	12	2	2025-11-25 23:09:15.537319+00	2025-11-25 23:11:08.994166+00	graded	0.92	2.50	36.67	t
48	10	1	4	2025-11-26 15:11:27.038022+00	\N	in_progress	\N	2.50	\N	f
50	12	1	1	2025-11-27 10:10:31.23061+00	2025-11-27 10:15:58.820784+00	graded	7.50	10.00	75.00	t
51	12	1	2	2025-11-27 10:17:06.084058+00	\N	in_progress	\N	10.00	\N	f
52	12	1	3	2025-11-27 11:38:22.722334+00	\N	in_progress	\N	10.00	\N	f
53	10	1	5	2025-11-27 13:59:41.865923+00	2025-11-27 14:00:13.625443+00	graded	1.67	2.50	66.67	t
54	10	1	6	2025-11-27 14:00:26.09331+00	2025-11-27 14:00:39.618794+00	graded	2.50	2.50	100.00	t
55	12	1	4	2025-11-27 14:09:50.843172+00	\N	in_progress	\N	10.00	\N	f
56	10	1	7	2025-11-28 07:59:27.65336+00	2025-11-28 07:59:50.724852+00	graded	2.50	2.50	100.00	t
57	10	38	1	2025-11-28 08:26:42.212191+00	\N	in_progress	\N	2.50	\N	f
58	10	1	8	2025-11-28 17:30:32.750059+00	2025-11-28 17:30:46.223862+00	graded	1.00	2.50	40.00	t
108	10	65	3	2025-12-11 08:16:08.857858+00	\N	in_progress	\N	2.50	\N	f
109	10	8	1	2025-12-11 08:17:37.768197+00	2025-12-11 08:19:43.398215+00	graded	0.92	2.50	36.67	t
65	10	1	9	2025-12-02 14:03:03.070428+00	\N	in_progress	\N	2.50	\N	f
66	10	1	10	2025-12-02 14:50:31.041917+00	\N	in_progress	\N	2.50	\N	f
67	10	1	11	2025-12-02 14:50:42.181898+00	2025-12-02 14:50:51.800517+00	graded	2.50	2.50	100.00	t
68	10	1	12	2025-12-02 15:00:21.417757+00	\N	in_progress	\N	2.50	\N	f
69	10	1	13	2025-12-02 15:00:27.233343+00	2025-12-02 15:00:38.332209+00	graded	2.50	2.50	100.00	t
34	10	1	1	2025-11-24 11:19:35.913509+00	2025-11-24 11:20:11.681564+00	graded	2.50	2.50	100.00	t
87	10	38	3	2025-12-05 06:42:35.406155+00	\N	in_progress	\N	2.50	\N	f
37	10	40	1	2025-11-25 11:59:02.843142+00	2025-11-25 12:00:39.74972+00	graded	1.75	2.50	70.00	t
38	12	40	1	2025-11-25 12:01:05.198464+00	2025-11-25 12:12:26.301989+00	graded	7.75	10.00	77.50	t
89	10	69	1	2025-12-05 09:33:52.367543+00	\N	in_progress	\N	2.50	\N	f
40	10	40	2	2025-11-25 12:14:00.279968+00	2025-11-25 12:15:04.250816+00	graded	2.50	2.50	100.00	t
41	13	40	1	2025-11-25 12:32:43.196207+00	2025-11-25 12:40:52.364362+00	graded	9.25	10.00	92.50	t
75	24	1	1	2025-12-04 20:12:42.480307+00	2025-12-04 20:15:20.613044+00	graded	2.05	5.00	41.00	t
76	10	1	14	2025-12-04 20:16:33.62465+00	\N	in_progress	\N	2.50	\N	f
77	24	1	2	2025-12-04 20:16:47.271671+00	2025-12-04 20:18:10.263556+00	graded	2.80	5.00	56.00	t
79	24	1	3	2025-12-04 20:18:52.6936+00	2025-12-04 20:19:31.341789+00	graded	4.25	5.00	85.00	t
81	24	1	4	2025-12-04 20:20:12.970885+00	2025-12-04 20:20:42.551659+00	graded	5.00	5.00	100.00	t
88	31	1	1	2025-12-05 09:32:01.910071+00	2025-12-05 09:52:20.411915+00	graded	9.25	10.00	92.50	t
90	31	51	1	2025-12-05 09:39:00.704869+00	2025-12-05 09:52:21.042986+00	graded	9.25	10.00	92.50	t
91	32	40	1	2025-12-05 10:06:28.785196+00	\N	in_progress	\N	10.00	\N	f
86	10	38	2	2025-12-05 06:36:27.466425+00	2025-12-05 10:49:28.926651+00	graded	1.00	2.50	40.00	t
92	33	1	1	2025-12-05 11:15:24.806509+00	2025-12-05 11:24:55.867673+00	graded	7.00	10.00	70.00	t
94	33	70	1	2025-12-05 11:16:20.512695+00	2025-12-05 11:25:51.931746+00	graded	6.17	10.00	61.67	t
93	33	40	1	2025-12-05 11:16:19.878528+00	2025-12-05 11:26:57.367749+00	graded	4.67	10.00	46.67	t
95	31	40	1	2025-12-05 11:28:08.728592+00	\N	in_progress	\N	10.00	\N	f
96	34	65	1	2025-12-05 16:52:08.980848+00	\N	in_progress	\N	10.00	\N	f
97	10	38	4	2025-12-05 17:13:20.425685+00	\N	in_progress	\N	2.50	\N	f
98	34	65	2	2025-12-05 20:21:41.721113+00	\N	in_progress	\N	10.00	\N	f
99	35	41	1	2025-12-06 12:12:40.65065+00	2025-12-06 12:15:17.836168+00	graded	2.50	2.50	100.00	t
100	10	66	1	2025-12-06 13:25:24.286237+00	2025-12-06 13:28:28.183273+00	graded	2.50	2.50	100.00	t
101	31	66	1	2025-12-06 13:29:25.81478+00	2025-12-06 13:37:13.982421+00	graded	9.25	10.00	92.50	t
102	35	63	1	2025-12-09 09:53:27.062284+00	\N	in_progress	\N	2.50	\N	f
103	10	65	1	2025-12-11 08:07:37.058407+00	2025-12-11 08:08:19.029214+00	graded	2.50	2.50	100.00	t
104	36	65	1	2025-12-11 08:09:13.248645+00	2025-12-11 08:11:17.727173+00	graded	6.25	10.00	62.50	t
105	36	65	2	2025-12-11 08:11:34.868625+00	2025-12-11 08:13:10.664977+00	graded	9.25	10.00	92.50	t
106	24	65	1	2025-12-11 08:14:25.093826+00	2025-12-11 08:15:21.794544+00	graded	4.25	5.00	85.00	t
107	10	65	2	2025-12-11 08:15:35.456764+00	2025-12-11 08:16:06.607344+00	graded	2.50	2.50	100.00	t
110	10	8	2	2025-12-11 08:20:15.955638+00	\N	in_progress	\N	2.50	\N	f
111	35	8	1	2025-12-11 08:20:43.438604+00	2025-12-11 08:22:45.489305+00	graded	2.50	2.50	100.00	t
112	24	8	1	2025-12-11 08:23:03.657011+00	2025-12-11 08:27:35.056841+00	graded	3.50	5.00	70.00	t
113	13	8	1	2025-12-11 08:29:37.761359+00	2025-12-11 08:35:02.77807+00	graded	8.50	10.00	85.00	t
115	10	65	4	2025-12-11 08:35:54.475183+00	\N	in_progress	\N	2.50	\N	f
114	10	8	3	2025-12-11 08:35:32.742091+00	2025-12-11 08:36:12.699375+00	graded	2.50	2.50	100.00	t
118	10	8	4	2025-12-11 08:36:28.150996+00	\N	in_progress	\N	2.50	\N	f
119	33	65	1	2025-12-11 08:36:40.353473+00	2025-12-11 08:37:03.441987+00	graded	1.50	10.00	15.00	t
121	37	69	1	2025-12-12 08:02:53.077896+00	\N	in_progress	\N	10.00	\N	f
122	10	42	1	2025-12-12 08:04:33.116121+00	\N	in_progress	\N	2.50	\N	f
120	35	38	1	2025-12-12 07:58:04.863155+00	2025-12-12 08:05:17.481628+00	graded	1.00	2.50	40.00	t
123	35	38	2	2025-12-12 08:05:30.289797+00	2025-12-12 08:05:54.623157+00	graded	1.75	2.50	70.00	t
124	35	38	3	2025-12-12 08:06:06.223372+00	2025-12-12 08:06:22.775142+00	graded	2.50	2.50	100.00	t
125	36	41	1	2025-12-12 08:06:47.284397+00	\N	in_progress	\N	10.00	\N	f
127	36	41	2	2025-12-12 08:07:43.33744+00	\N	in_progress	\N	10.00	\N	f
129	39	41	1	2025-12-12 09:07:20.735955+00	2025-12-12 09:18:48.763753+00	graded	5.00	10.00	50.00	t
128	38	1	1	2025-12-12 09:05:42.682992+00	2025-12-12 09:53:10.156134+00	graded	9.25	10.00	92.50	t
126	36	38	1	2025-12-12 08:07:01.941624+00	2025-12-12 10:46:32.43169+00	graded	0.50	10.00	5.00	t
130	39	41	2	2025-12-12 09:20:28.434074+00	2025-12-12 09:23:57.267031+00	graded	8.50	10.00	85.00	t
131	39	41	3	2025-12-12 09:24:29.568438+00	2025-12-12 09:27:08.346405+00	graded	10.00	10.00	100.00	t
134	10	40	3	2025-12-12 10:14:04.044222+00	2025-12-12 10:16:14.266226+00	graded	2.50	2.50	100.00	t
136	12	65	1	2025-12-12 10:17:15.665426+00	\N	in_progress	\N	10.00	\N	f
138	10	39	1	2025-12-12 10:29:58.492585+00	\N	in_progress	\N	2.50	\N	f
139	12	39	1	2025-12-12 10:34:01.899926+00	\N	in_progress	\N	10.00	\N	f
135	41	40	1	2025-12-12 10:16:24.788054+00	2025-12-12 10:39:50.328113+00	graded	6.92	10.00	69.17	t
140	41	40	2	2025-12-12 10:40:20.46543+00	2025-12-12 10:41:47.622218+00	graded	0.00	10.00	0.00	t
137	42	1	1	2025-12-12 10:19:25.817402+00	2025-12-12 11:56:35.788994+00	graded	18.00	20.00	90.00	t
141	42	39	1	2025-12-12 10:41:36.027066+00	2025-12-12 11:57:15.997778+00	graded	19.25	20.00	96.25	t
142	36	1	1	2025-12-12 17:03:57.886056+00	\N	in_progress	\N	10.00	\N	f
143	42	67	1	2025-12-12 18:54:30.058574+00	\N	in_progress	\N	20.00	\N	f
144	10	31	1	2025-12-13 11:49:49.816987+00	2025-12-13 11:52:03.832811+00	graded	2.50	2.50	100.00	t
145	24	31	1	2025-12-13 11:52:39.5555+00	2025-12-13 11:55:32.637972+00	graded	3.50	5.00	70.00	t
147	44	1	1	2025-12-18 17:43:06.503941+00	\N	in_progress	\N	10.00	\N	f
148	39	7	1	2025-12-23 08:58:34.236214+00	2025-12-23 09:14:34.664308+00	graded	8.50	10.00	85.00	t
149	42	7	1	2025-12-23 09:16:29.066913+00	2025-12-23 09:53:55.258412+00	graded	19.25	20.00	96.25	t
150	24	7	1	2025-12-24 09:26:21.196432+00	2025-12-24 09:35:37.749253+00	graded	5.00	5.00	100.00	t
151	35	7	1	2025-12-24 09:36:20.652458+00	2025-12-24 09:44:20.992059+00	graded	2.50	2.50	100.00	t
152	12	7	1	2025-12-24 09:44:54.049072+00	\N	in_progress	\N	10.00	\N	f
\.


--
-- Data for Name: test_question; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.test_question (id, test_id, question_id, order_index, points) FROM stdin;
146	10	150	3	1.00
147	10	161	2	1.00
148	10	183	5	1.00
149	10	191	4	1.00
150	10	204	1	1.00
152	12	115	18	1.00
153	12	117	4	1.00
154	12	121	14	1.00
155	12	122	17	1.00
156	12	124	6	1.00
157	12	125	8	1.00
158	12	127	12	1.00
159	12	131	16	1.00
160	12	134	5	1.00
161	12	142	13	1.00
162	12	146	2	1.00
163	12	152	20	1.00
164	12	155	3	1.00
165	12	170	10	1.00
166	12	192	9	1.00
167	12	197	1	1.00
168	12	202	19	1.00
169	12	213	7	1.00
170	12	214	11	1.00
171	12	218	15	1.00
172	13	111	1	1.00
173	13	112	20	1.00
174	13	122	16	1.00
175	13	140	4	1.00
176	13	141	2	1.00
177	13	142	19	1.00
178	13	145	10	1.00
179	13	146	8	1.00
180	13	149	11	1.00
181	13	154	12	1.00
182	13	155	13	1.00
183	13	156	14	1.00
184	13	160	7	1.00
185	13	165	5	1.00
186	13	168	9	1.00
187	13	172	6	1.00
188	13	185	18	1.00
189	13	207	17	1.00
190	13	209	3	1.00
191	13	214	15	1.00
620	31	107	14	1.00
621	31	116	20	1.00
622	31	118	16	1.00
623	31	120	19	1.00
624	31	137	3	1.00
625	31	145	10	1.00
626	31	148	13	1.00
627	31	150	7	1.00
628	31	153	15	1.00
629	31	154	8	1.00
630	31	164	2	1.00
631	31	175	5	1.00
632	31	178	18	1.00
633	31	181	17	1.00
634	31	189	9	1.00
635	31	196	6	1.00
636	31	197	12	1.00
637	31	200	11	1.00
638	31	201	4	1.00
639	31	207	1	1.00
700	35	128	2	1.00
701	35	156	5	1.00
702	35	174	3	1.00
703	35	175	4	1.00
704	35	206	1	1.00
765	39	115	13	1.00
766	39	116	20	1.00
767	39	120	12	1.00
768	39	123	3	1.00
769	39	132	2	1.00
770	39	144	9	1.00
771	39	150	10	1.00
772	39	155	14	1.00
773	39	156	16	1.00
774	39	163	7	1.00
775	39	175	11	1.00
776	39	182	18	1.00
777	39	183	5	1.00
778	39	198	6	1.00
779	39	204	4	1.00
780	39	212	19	1.00
781	39	214	1	1.00
782	39	219	8	0.50
783	39	225	15	0.50
784	39	226	17	0.50
925	42	106	11	1.00
926	42	108	31	1.00
927	42	112	6	1.00
928	42	113	13	1.00
929	42	121	40	1.00
930	42	126	27	1.00
931	42	137	3	1.00
932	42	142	21	1.00
933	42	145	18	1.00
934	42	147	37	1.00
935	42	151	5	1.00
936	42	152	12	1.00
937	42	156	1	1.00
938	42	158	23	1.00
939	42	161	10	1.00
940	42	162	2	1.00
941	42	169	29	1.00
942	42	170	35	1.00
943	42	171	7	1.00
944	42	174	33	1.00
945	42	176	19	1.00
946	42	216	24	1.00
947	42	186	32	1.00
948	42	188	25	1.00
949	42	194	4	1.00
950	42	195	22	1.00
951	42	198	16	1.00
952	42	201	17	1.00
953	42	203	9	1.00
705	36	108	18	1.00
706	36	111	1	1.00
707	36	117	19	1.00
708	36	121	4	1.00
709	36	127	16	1.00
710	36	131	9	1.00
711	36	136	15	1.00
712	36	140	14	1.00
713	36	149	20	1.00
714	36	155	2	1.00
715	36	158	17	1.00
716	36	170	12	1.00
717	36	180	11	1.00
718	36	188	3	1.00
719	36	194	7	1.00
720	36	205	8	1.00
721	36	209	10	1.00
722	36	210	13	1.00
723	36	211	6	1.00
724	36	218	5	1.00
640	32	108	2	1.00
641	32	117	14	1.00
642	32	118	17	1.00
643	32	130	3	1.00
644	32	135	4	1.00
645	32	139	10	1.00
646	32	149	5	1.00
647	32	155	9	1.00
648	32	156	19	1.00
649	32	157	6	1.00
650	32	160	13	1.00
651	32	161	1	1.00
652	32	172	11	1.00
653	32	179	16	1.00
654	32	182	8	1.00
655	32	189	20	1.00
656	32	198	7	1.00
657	32	211	12	1.00
658	32	215	18	1.00
659	32	218	15	1.00
725	37	116	4	1.00
726	37	132	1	1.00
727	37	136	2	1.00
728	37	138	19	1.00
729	37	142	14	1.00
730	37	146	17	1.00
731	37	151	12	1.00
732	37	152	13	1.00
733	37	157	10	1.00
734	37	167	9	1.00
735	37	181	15	1.00
736	37	185	8	1.00
737	37	188	6	1.00
738	37	200	3	1.00
739	37	209	18	1.00
740	37	212	20	1.00
741	37	215	5	1.00
742	37	226	11	0.50
743	37	230	16	0.50
744	37	231	7	0.50
660	33	126	17	1.00
661	33	128	4	1.00
662	33	131	13	1.00
663	33	144	16	1.00
664	33	147	1	1.00
665	33	154	19	1.00
970	44	1179	469	0.50
971	44	1108	399	0.50
972	44	942	232	0.50
973	44	1138	429	0.50
974	44	1142	433	0.50
975	44	904	194	0.50
976	44	1372	44	0.50
977	44	1073	363	0.50
978	44	895	185	0.50
979	44	1183	473	0.50
980	44	925	215	0.50
981	44	1048	338	0.50
982	44	1135	426	0.50
983	44	1092	383	0.50
984	44	930	220	0.50
985	44	1002	292	0.50
986	44	1358	30	0.50
987	44	1198	488	0.50
988	44	1200	490	0.50
989	44	1382	54	0.50
954	42	206	30	1.00
955	42	207	20	1.00
956	42	209	36	1.00
957	42	214	38	1.00
958	42	218	8	1.00
959	42	221	15	0.50
960	42	225	39	0.50
961	42	226	14	0.50
962	42	228	34	0.50
963	42	229	26	0.50
964	42	230	28	0.50
666	33	155	8	1.00
667	33	161	11	1.00
668	33	166	5	1.00
669	33	168	2	1.00
670	33	173	14	1.00
671	33	174	20	1.00
672	33	179	18	1.00
673	33	184	10	1.00
674	33	188	9	1.00
675	33	198	15	1.00
676	33	202	3	1.00
677	33	212	7	1.00
678	33	214	6	1.00
679	33	215	12	1.00
745	38	116	3	1.00
680	34	113	16	1.00
681	34	122	9	1.00
682	34	125	13	1.00
683	34	127	12	1.00
684	34	133	18	1.00
528	24	106	10	1.00
529	24	109	3	1.00
530	24	110	8	1.00
531	24	138	4	1.00
532	24	143	1	1.00
533	24	153	7	1.00
534	24	159	2	1.00
535	24	164	5	1.00
536	24	176	6	1.00
537	24	214	9	1.00
685	34	136	4	1.00
686	34	147	3	1.00
687	34	149	19	1.00
688	34	157	5	1.00
689	34	175	8	1.00
690	34	180	11	1.00
691	34	182	2	1.00
692	34	185	10	1.00
693	34	191	1	1.00
694	34	192	17	1.00
695	34	193	14	1.00
696	34	201	7	1.00
697	34	208	20	1.00
698	34	211	15	1.00
699	34	212	6	1.00
746	38	121	1	1.00
747	38	122	13	1.00
748	38	125	18	1.00
749	38	136	7	1.00
750	38	142	20	1.00
751	38	146	14	1.00
752	38	170	8	1.00
753	38	171	6	1.00
754	38	175	5	1.00
755	38	179	11	1.00
756	38	184	10	1.00
757	38	187	4	1.00
758	38	189	12	1.00
759	38	196	15	1.00
760	38	199	19	1.00
761	38	204	16	1.00
762	38	208	17	1.00
763	38	217	9	1.00
764	38	222	2	0.50
905	41	119	11	1.00
906	41	120	13	1.00
907	41	137	12	1.00
908	41	138	4	1.00
909	41	139	19	1.00
910	41	143	15	1.00
911	41	150	16	1.00
912	41	152	1	1.00
913	41	155	8	1.00
914	41	184	10	1.00
915	41	187	20	1.00
916	41	194	2	1.00
917	41	195	7	1.00
918	41	199	18	1.00
919	41	207	14	1.00
920	41	208	5	1.00
921	41	209	3	1.00
922	41	212	17	1.00
923	41	225	6	0.50
924	41	230	9	0.50
\.


--
-- Name: app_user_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.app_user_id_seq', 73, true);


--
-- Name: course_enrollment_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.course_enrollment_id_seq', 1, true);


--
-- Name: course_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.course_id_seq', 3, true);


--
-- Name: question_bank_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.question_bank_id_seq', 1571, true);


--
-- Name: question_option_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.question_option_id_seq', 5816, true);


--
-- Name: student_answer_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.student_answer_id_seq', 893, true);


--
-- Name: test_attempt_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.test_attempt_id_seq', 152, true);


--
-- Name: test_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.test_id_seq', 44, true);


--
-- Name: test_question_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.test_question_id_seq', 989, true);


--
-- Name: app_user app_user_email_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.app_user
    ADD CONSTRAINT app_user_email_key UNIQUE (email);


--
-- Name: app_user app_user_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.app_user
    ADD CONSTRAINT app_user_pkey PRIMARY KEY (id);


--
-- Name: course course_code_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.course
    ADD CONSTRAINT course_code_key UNIQUE (code);


--
-- Name: course_enrollment course_enrollment_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.course_enrollment
    ADD CONSTRAINT course_enrollment_pkey PRIMARY KEY (id);


--
-- Name: course course_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.course
    ADD CONSTRAINT course_pkey PRIMARY KEY (id);


--
-- Name: question_bank question_bank_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.question_bank
    ADD CONSTRAINT question_bank_pkey PRIMARY KEY (id);


--
-- Name: question_option question_option_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.question_option
    ADD CONSTRAINT question_option_pkey PRIMARY KEY (id);


--
-- Name: student_answer student_answer_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.student_answer
    ADD CONSTRAINT student_answer_pkey PRIMARY KEY (id);


--
-- Name: test_attempt test_attempt_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.test_attempt
    ADD CONSTRAINT test_attempt_pkey PRIMARY KEY (id);


--
-- Name: test test_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.test
    ADD CONSTRAINT test_pkey PRIMARY KEY (id);


--
-- Name: test_question test_question_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.test_question
    ADD CONSTRAINT test_question_pkey PRIMARY KEY (id);


--
-- Name: student_answer uq_answer; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.student_answer
    ADD CONSTRAINT uq_answer UNIQUE (attempt_id, question_id);


--
-- Name: course_enrollment uq_course_user; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.course_enrollment
    ADD CONSTRAINT uq_course_user UNIQUE (course_id, user_id);


--
-- Name: question_option uq_question_option_order; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.question_option
    ADD CONSTRAINT uq_question_option_order UNIQUE (question_id, order_index);


--
-- Name: test_attempt uq_test_attempt; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.test_attempt
    ADD CONSTRAINT uq_test_attempt UNIQUE (test_id, student_id, attempt_number);


--
-- Name: test_question uq_test_question; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.test_question
    ADD CONSTRAINT uq_test_question UNIQUE (test_id, question_id);


--
-- Name: idx_course_year_group; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_course_year_group ON public.course USING btree (academic_year, class_group);


--
-- Name: idx_question_option_question; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_question_option_question ON public.question_option USING btree (question_id);


--
-- Name: idx_student_answer_attempt; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_student_answer_attempt ON public.student_answer USING btree (attempt_id);


--
-- Name: idx_student_answer_option; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_student_answer_option ON public.student_answer USING btree (selected_option_id);


--
-- Name: idx_student_answer_question; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_student_answer_question ON public.student_answer USING btree (question_id);


--
-- Name: idx_test_attempt_student; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_test_attempt_student ON public.test_attempt USING btree (student_id);


--
-- Name: idx_test_attempt_test; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_test_attempt_test ON public.test_attempt USING btree (test_id);


--
-- Name: idx_test_created_by; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_test_created_by ON public.test USING btree (created_by);


--
-- Name: idx_test_question_question; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_test_question_question ON public.test_question USING btree (question_id);


--
-- Name: idx_test_question_test; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_test_question_test ON public.test_question USING btree (test_id);


--
-- Name: uq_app_user_dni_not_null; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX uq_app_user_dni_not_null ON public.app_user USING btree (dni) WHERE (dni IS NOT NULL);


--
-- Name: course_enrollment course_enrollment_course_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.course_enrollment
    ADD CONSTRAINT course_enrollment_course_id_fkey FOREIGN KEY (course_id) REFERENCES public.course(id) ON DELETE CASCADE;


--
-- Name: course_enrollment course_enrollment_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.course_enrollment
    ADD CONSTRAINT course_enrollment_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.app_user(id) ON DELETE CASCADE;


--
-- Name: course course_owner_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.course
    ADD CONSTRAINT course_owner_id_fkey FOREIGN KEY (owner_id) REFERENCES public.app_user(id);


--
-- Name: question_bank question_bank_course_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.question_bank
    ADD CONSTRAINT question_bank_course_id_fkey FOREIGN KEY (course_id) REFERENCES public.course(id) ON DELETE CASCADE;


--
-- Name: question_bank question_bank_created_by_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.question_bank
    ADD CONSTRAINT question_bank_created_by_fkey FOREIGN KEY (created_by) REFERENCES public.app_user(id);


--
-- Name: question_option question_option_question_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.question_option
    ADD CONSTRAINT question_option_question_id_fkey FOREIGN KEY (question_id) REFERENCES public.question_bank(id) ON DELETE CASCADE;


--
-- Name: student_answer student_answer_attempt_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.student_answer
    ADD CONSTRAINT student_answer_attempt_id_fkey FOREIGN KEY (attempt_id) REFERENCES public.test_attempt(id) ON DELETE CASCADE;


--
-- Name: student_answer student_answer_graded_by_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.student_answer
    ADD CONSTRAINT student_answer_graded_by_fkey FOREIGN KEY (graded_by) REFERENCES public.app_user(id);


--
-- Name: student_answer student_answer_question_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.student_answer
    ADD CONSTRAINT student_answer_question_id_fkey FOREIGN KEY (question_id) REFERENCES public.question_bank(id) ON DELETE RESTRICT;


--
-- Name: student_answer student_answer_selected_option_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.student_answer
    ADD CONSTRAINT student_answer_selected_option_id_fkey FOREIGN KEY (selected_option_id) REFERENCES public.question_option(id);


--
-- Name: test_attempt test_attempt_student_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.test_attempt
    ADD CONSTRAINT test_attempt_student_id_fkey FOREIGN KEY (student_id) REFERENCES public.app_user(id) ON DELETE CASCADE;


--
-- Name: test_attempt test_attempt_test_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.test_attempt
    ADD CONSTRAINT test_attempt_test_id_fkey FOREIGN KEY (test_id) REFERENCES public.test(id) ON DELETE CASCADE;


--
-- Name: test test_course_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.test
    ADD CONSTRAINT test_course_id_fkey FOREIGN KEY (course_id) REFERENCES public.course(id) ON DELETE CASCADE;


--
-- Name: test test_created_by_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.test
    ADD CONSTRAINT test_created_by_fkey FOREIGN KEY (created_by) REFERENCES public.app_user(id);


--
-- Name: test_question test_question_question_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.test_question
    ADD CONSTRAINT test_question_question_id_fkey FOREIGN KEY (question_id) REFERENCES public.question_bank(id) ON DELETE RESTRICT;


--
-- Name: test_question test_question_test_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.test_question
    ADD CONSTRAINT test_question_test_id_fkey FOREIGN KEY (test_id) REFERENCES public.test(id) ON DELETE CASCADE;


--
-- PostgreSQL database dump complete
--

\unrestrict XthN5LtghEj0vd44od7fQTfQqqcirbRR8YJ1e2azWOTNl16l6IIQIuGXFEGOB98

