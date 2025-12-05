--
-- PostgreSQL database dump
--

\restrict tdJDYFFfBr1hZYAWkP1H9PteuNMwSiqucP9pDKK2vpsGD3tUWRuNk4B9E9cZ0DP

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
    CONSTRAINT app_user_role_check CHECK ((role = ANY (ARRAY['student'::text, 'teacher'::text, 'admin'::text])))
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
4	student003@2526-45810-a.local	Adriana Moyo Sánchez	student	t	2025-11-18 23:18:21.545234+00	06024021
7	student006@2526-45810-a.local	Alejandro de la Maza Segura	student	t	2025-11-18 23:18:21.545234+00	48109544
41	student040@2526-45810-a.local	Laura Yebra de Llano	student	t	2025-11-18 23:18:21.545234+00	49333504
5	student004@2526-45810-a.local	Alejandro Sainz Carpio	student	t	2025-11-18 23:18:21.545234+00	54352724
37	student036@2526-45810-a.local	Julián Nicolás Moldovan Irimie	student	t	2025-11-18 23:18:21.545234+00	60129522
26	student025@2526-45810-a.local	Isabella Rivera Alderete	student	t	2025-11-18 23:18:21.545234+00	N11897829
3	student002@2526-45810-a.local	Adriana Arias Giménez	student	t	2025-11-18 23:18:21.545234+00	49442937
66	student065@2526-45810-a.local	Sofía Mazón Caballero	student	t	2025-11-18 23:18:21.545234+00	02569318
70	student069@2526-45810-a.local	Álvaro Adeva Torres	student	t	2025-11-18 23:18:21.545234+00	48225548
73	student072@2526-45810-a.local	Álvaro de Celis Muñoz	student	t	2025-11-18 23:18:21.545234+00	54189676
46	student045@2526-45810-a.local	Marina Casero López	student	t	2025-11-18 23:18:21.545234+00	11874784
67	student066@2526-45810-a.local	Tomás Cavassa Aparicio	student	t	2025-11-18 23:18:21.545234+00	Y8840042
8	student007@2526-45810-a.local	Ana Zitao Pérez Martínez	student	t	2025-11-18 23:18:21.545234+00	47315562
9	student008@2526-45810-a.local	Andrea García Soria	student	t	2025-11-18 23:18:21.545234+00	47588042
64	student063@2526-45810-a.local	Sergio Ruiz Carrasco	student	t	2025-11-18 23:18:21.545234+00	51009659
13	student012@2526-45810-a.local	Claudia Serrada de Pedraza	student	t	2025-11-18 23:18:21.545234+00	06618119
15	student014@2526-45810-a.local	Daira García Gómez	student	t	2025-11-18 23:18:21.545234+00	51007316
61	student060@2526-45810-a.local	Raúl Cerezo Resino	student	t	2025-11-18 23:18:21.545234+00	05963339
16	student015@2526-45810-a.local	Diego López Ruiz	student	t	2025-11-18 23:18:21.545234+00	54369131
72	student071@2526-45810-a.local	Álvaro Goizueta Granda	student	t	2025-11-18 23:18:21.545234+00	02578999
11	student010@2526-45810-a.local	Beltrán García Enamorado	student	t	2025-11-18 23:18:21.545234+00	50347682
19	student018@2526-45810-a.local	Erik Wolfang Moericke Serrano	student	t	2025-11-18 23:18:21.545234+00	06001051
18	student017@2526-45810-a.local	Elizabeth Crende Daou	student	t	2025-11-18 23:18:21.545234+00	48206010
23	student022@2526-45810-a.local	Gonzalo de Mier Fernández-Caro	student	t	2025-11-18 23:18:21.545234+00	48034111
20	student019@2526-45810-a.local	Gonzalo Carrasco Barros	student	t	2025-11-18 23:18:21.545234+00	05952488
57	student056@2526-45810-a.local	Pablo Moreno Rivas	student	t	2025-11-18 23:18:21.545234+00	54022654
43	student042@2526-45810-a.local	Luisa Herrero San Pío	student	t	2025-11-18 23:18:21.545234+00	70269287
22	student021@2526-45810-a.local	Gonzalo Salas Dorado	student	t	2025-11-18 23:18:21.545234+00	54369366
27	student026@2526-45810-a.local	Iván Alba Eguinoa	student	t	2025-11-18 23:18:21.545234+00	02566101
50	student049@2526-45810-a.local	Martín Hernández-Palacios Prados	student	t	2025-11-18 23:18:21.545234+00	71990541
51	student050@2526-45810-a.local	María Lilia Riancho Pena	student	t	2025-11-18 23:18:21.545234+00	54440992
28	student027@2526-45810-a.local	Jaime Serna González	student	t	2025-11-18 23:18:21.545234+00	45332592
38	student037@2526-45810-a.local	Laura Chun Nombela Terrado	student	t	2025-11-18 23:18:21.545234+00	51494038
71	student070@2526-45810-a.local	Álvaro Esteban de Nicolás	student	t	2025-11-18 23:18:21.545234+00	51134411
21	student020@2526-45810-a.local	Gonzalo Ramírez Sánchez-Marcos	student	t	2025-11-18 23:18:21.545234+00	54189426
32	student031@2526-45810-a.local	Jesús Ramírez Vega	student	t	2025-11-18 23:18:21.545234+00	54211682
49	student048@2526-45810-a.local	Marta Sánchez López	student	t	2025-11-18 23:18:21.545234+00	54366778
33	student032@2526-45810-a.local	Jorge Asenjo Martín	student	t	2025-11-18 23:18:21.545234+00	53846543
35	student034@2526-45810-a.local	Juan Manuel Pedraza Rioboo	student	t	2025-11-18 23:18:21.545234+00	05961361
40	student039@2526-45810-a.local	Laura Reyero González-Noriega	student	t	2025-11-18 23:18:21.545234+00	53989108
39	student038@2526-45810-a.local	Laura Jiménez Jiménez	student	t	2025-11-18 23:18:21.545234+00	54495191
12	student011@2526-45810-a.local	Bilin Weng Chen	student	t	2025-11-18 23:18:21.545234+00	79406939
45	student044@2526-45810-a.local	Marcos López Domínguez	student	t	2025-11-18 23:18:21.545234+00	54494079
47	student046@2526-45810-a.local	Mario Marín Fernández	student	t	2025-11-18 23:18:21.545234+00	47317452
42	student041@2526-45810-a.local	Lucas Román Vidal	student	t	2025-11-18 23:18:21.545234+00	51536693
63	student062@2526-45810-a.local	Samuel Pardo Acosta	student	t	2025-11-18 23:18:21.545234+00	BD607403
52	student051@2526-45810-a.local	Miguel Poudereux López-Barrantes	student	t	2025-11-18 23:18:21.545234+00	51501099
53	student052@2526-45810-a.local	Nicolás Abal Miranda	student	t	2025-11-18 23:18:21.545234+00	54480534
17	student016@2526-45810-a.local	Diego Sánchez Núñez	student	t	2025-11-18 23:18:21.545234+00	02595244
25	student024@2526-45810-a.local	Ignacio Valiente Saludes	student	t	2025-11-18 23:18:21.545234+00	51758855
31	student030@2526-45810-a.local	Javier Molinuevo Quevedo	student	t	2025-11-18 23:18:21.545234+00	70426250
24	student023@2526-45810-a.local	Ian David Isla de Cegama	student	t	2025-11-18 23:18:21.545234+00	08015151
6	student005@2526-45810-a.local	Alejandro Valverde Albaladejo	student	t	2025-11-18 23:18:21.545234+00	48081409
55	student054@2526-45810-a.local	Pablo Abad Pérez	student	t	2025-11-18 23:18:21.545234+00	06610675
14	student013@2526-45810-a.local	Cristina Azcue Aseguinolaza	student	t	2025-11-18 23:18:21.545234+00	73040721
58	student057@2526-45810-a.local	Pablo Palma Pérez	student	t	2025-11-18 23:18:21.545234+00	51484099
36	student035@2526-45810-a.local	Julio Peral Renedo	student	t	2025-11-18 23:18:21.545234+00	06021048
56	student055@2526-45810-a.local	Pablo Morenilla López	student	t	2025-11-18 23:18:21.545234+00	51818627
10	student009@2526-45810-a.local	Andrés Lucas Núñez	student	t	2025-11-18 23:18:21.545234+00	47583769
30	student029@2526-45810-a.local	Javier Fernández Cuesta	student	t	2025-11-18 23:18:21.545234+00	54298243
59	student058@2526-45810-a.local	Pablo de Santos Burgueño	student	t	2025-11-18 23:18:21.545234+00	54210699
2	student001@2526-45810-a.local	Adriana Alexandra Soria Aranguren	student	t	2025-11-18 23:18:21.545234+00	Z2102203
60	student059@2526-45810-a.local	Paula Esnarrizaga Rodríguez	student	t	2025-11-18 23:18:21.545234+00	54191100
48	student047@2526-45810-a.local	Marlon Sieira Martínez	student	t	2025-11-18 23:18:21.545234+00	50491223
62	student061@2526-45810-a.local	Raúl Soligo Sierra	student	t	2025-11-18 23:18:21.545234+00	51708892
65	student064@2526-45810-a.local	Sofía González Hernández	student	t	2025-11-18 23:18:21.545234+00	49155842
34	student033@2526-45810-a.local	Juan Gutiérrez García	student	t	2025-11-18 23:18:21.545234+00	02316928
68	student067@2526-45810-a.local	Tomás Herrera Londoño	student	t	2025-11-18 23:18:21.545234+00	43924576
69	student068@2526-45810-a.local	Xavier Alcocer Soberani	student	t	2025-11-18 23:18:21.545234+00	60344836
54	student053@2526-45810-a.local	Olivia Bidmead Serrano	student	t	2025-11-18 23:18:21.545234+00	70429033
44	student043@2526-45810-a.local	Marcos Cruces García	student	t	2025-11-18 23:18:21.545234+00	70069968
\.


--
-- Data for Name: course; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.course (id, code, name, description, owner_id, academic_year, class_group, is_active, created_at) FROM stdin;
1	2526-45810-A	Cloud Digital Leader – Google (Inglés)	Curso GCDL 2526, grupo A inglés	1	2526	A	t	2025-11-18 23:18:21.542375+00
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
126	1	21. BigQuery ML is a machine learning service that lets users: Build and evaluate machine learning models in BigQuery by using Python and Java.	single_choice	1.00	t	1	2025-11-20 23:23:53.501536+00
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
77	126	Build and evaluate machine learning models in BigQuery by using SQL.	t	1
78	126	Export small amounts of data to spreadsheets or other applications.	f	2
79	126	Seamlessly connect with a data science team to create an ML model.	f	3
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
203	159	Operational Excelence and Reliability at Scale	f	5
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
343	82	121	61	\N	\N	t	0.50	\N	\N	\N
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
\.


--
-- Data for Name: test; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.test (id, course_id, title, description, test_type, is_published, total_points, time_limit_minutes, max_attempts, grading_strategy, start_time, end_time, randomize_questions, randomize_options, created_by, created_at) FROM stdin;
27	1	borrar	Random 1-question test from course 2526-45810-A (Cloud Digital Leader – Google (Inglés)).	quiz	f	0.50	\N	1	latest	\N	\N	f	f	1	2025-12-04 20:25:15.241993+00
31	1	Grupo A	Random 20-question test from course 2526-45810-A (Cloud Digital Leader – Google (Inglés)).	quiz	f	10.00	\N	1	latest	\N	\N	f	f	\N	2025-12-05 09:32:01.326862+00
32	1	primero	Random 20-question test from course 2526-45810-A (Cloud Digital Leader – Google (Inglés)).	quiz	f	10.00	\N	\N	latest	\N	\N	f	f	\N	2025-12-05 10:06:28.096299+00
33	1	class 2	Random 20-question test from course 2526-45810-A (Cloud Digital Leader – Google (Inglés)).	quiz	f	10.00	\N	1	latest	\N	\N	f	f	\N	2025-12-05 11:15:24.147366+00
10	1	Mini test para puebas	Random 5-question test from course 2526-45810-A (Cloud Digital Leader – Google (Inglés)).	quiz	f	2.50	\N	\N	latest	\N	\N	f	f	\N	2025-11-24 11:19:27.669347+00
12	1	#1 de 20 preguntas (Laura)	Random 20-question test from course 2526-45810-A (Cloud Digital Leader – Google (Inglés)).	quiz	f	10.00	\N	\N	latest	\N	\N	f	f	\N	2025-11-25 11:58:55.558525+00
13	1	#2 de 20 preguntas (Laura)	Random 20-question test from course 2526-45810-A (Cloud Digital Leader – Google (Inglés)).	quiz	f	10.00	\N	\N	latest	\N	\N	f	f	\N	2025-11-25 12:15:23.968807+00
34	1	Random 20 – created by 49155842	Random 20-question test from course 2526-45810-A (Cloud Digital Leader – Google (Inglés)).	quiz	f	10.00	\N	\N	latest	\N	\N	f	f	\N	2025-12-05 16:52:08.404844+00
24	1	made by Ramiro	Random 10-question test from course 2526-45810-A (Cloud Digital Leader – Google (Inglés)).	quiz	f	5.00	\N	\N	latest	\N	\N	f	f	1	2025-12-04 20:12:41.894079+00
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
82	27	1	1	2025-12-04 20:25:15.543812+00	2025-12-04 20:25:25.82904+00	graded	0.50	0.50	100.00	t
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
578	27	121	1	1.00
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
660	33	126	17	1.00
661	33	128	4	1.00
662	33	131	13	1.00
663	33	144	16	1.00
664	33	147	1	1.00
665	33	154	19	1.00
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

SELECT pg_catalog.setval('public.course_id_seq', 2, true);


--
-- Name: question_bank_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.question_bank_id_seq', 218, true);


--
-- Name: question_option_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.question_option_id_seq', 438, true);


--
-- Name: student_answer_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.student_answer_id_seq', 449, true);


--
-- Name: test_attempt_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.test_attempt_id_seq', 97, true);


--
-- Name: test_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.test_id_seq', 34, true);


--
-- Name: test_question_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.test_question_id_seq', 699, true);


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

\unrestrict tdJDYFFfBr1hZYAWkP1H9PteuNMwSiqucP9pDKK2vpsGD3tUWRuNk4B9E9cZ0DP

