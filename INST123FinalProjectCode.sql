-- setup
DROP TABLE IF EXISTS course_raw;
DROP TABLE IF EXISTS unofficial_raw;
DROP TABLE IF EXISTS required_raw;
DROP TABLE IF EXISTS course;
DROP TABLE IF EXISTS unofficial;
DROP TABLE IF EXISTS required;

CREATE TABLE course_raw (
    subject VARCHAR(10),
    course_code VARCHAR(10),
    course_name VARCHAR(200),
    professor VARCHAR(200),
    grad_req VARCHAR(10),
    gen_ed VARCHAR(100),
    has_prereqs VARCHAR(10),
    prereqs VARCHAR(500),
    credits INTEGER,
    is_lab VARCHAR(10),
    required_texts VARCHAR(200)
);

CREATE TABLE required_raw (
    id INTEGER,
    text_name VARCHAR(255),
    "subject" VARCHAR(10),
    "course_code" VARCHAR(10),
    has_practice VARCHAR(10),
    "ISBN/link" VARCHAR(500),
    "free" VARCHAR(10)
);

CREATE TABLE unofficial_raw (
    id INTEGER,
    resource_name VARCHAR(255),
    "resource_type" VARCHAR(100),
    "subject" VARCHAR(10),
    "course_code" VARCHAR(10),
    resource_link VARCHAR(500)
);

COPY course_raw
FROM 'C:\Users\thou1\OneDrive - University of Maryland\Documents\assignments\INST123\Final\Course.csv'
WITH (FORMAT csv, HEADER true);

COPY required_raw
FROM 'C:\Users\thou1\OneDrive - University of Maryland\Documents\assignments\INST123\Final\Required.csv'
WITH (FORMAT csv, HEADER true);

COPY unofficial_raw
FROM 'C:\Users\thou1\OneDrive - University of Maryland\Documents\assignments\INST123\Final\Unofficial.csv'
WITH (FORMAT csv, HEADER true);


CREATE TABLE course (
	id SERIAL PRIMARY KEY,
    subject VARCHAR(10),
    course_code VARCHAR(10),
    course_name VARCHAR(200),
    professor VARCHAR(200),
    grad_req BOOLEAN,
    gen_ed VARCHAR(100),
    has_prereqs BOOLEAN,
    prereqs VARCHAR(500),
    credits INTEGER,
    is_lab BOOLEAN, 
	required_text_ids TEXT[]
);
INSERT INTO course 
	(subject, course_code, course_name, professor, grad_req, 
	gen_ed, has_prereqs, prereqs, credits, is_lab, required_text_ids)
SELECT subject, course_code, course_name, professor, grad_req::boolean, 
	   gen_ed, has_prereqs::boolean, prereqs, credits, is_lab::boolean, 
	   CASE 
	   	WHEN required_texts IS NULL OR btrim(required_texts) IN ('', '[]') THEN NULL
        ELSE string_to_array(regexp_replace(required_texts, '\[|\]|\s', '', 'g'), ',')
    END AS required_text_ids
FROM course_raw;

CREATE TABLE required (
    id INTEGER PRIMARY KEY,
    text_name VARCHAR(255),
    subject VARCHAR(10),
    course_code VARCHAR(10),
    has_practice BOOLEAN,
    isbn_link VARCHAR(500),
    is_free BOOLEAN
);
select * from required_raw;
INSERT INTO required
	(id, text_name, subject, course_code, has_practice, isbn_link, is_free)
SELECT id AS id, text_name, "subject" AS subject, "course_code" AS course_code,
    COALESCE(has_practice, 'false')::boolean AS has_practice, 
	"ISBN/link" AS isbn_link, "free"::boolean AS is_free
FROM required_raw;

CREATE TABLE unofficial (
    id INTEGER PRIMARY KEY,
    resource_name VARCHAR(255),
    resource_type VARCHAR(100),
    subject VARCHAR(10),
    course_code VARCHAR(10),
    resource_link VARCHAR(500)
);
INSERT INTO unofficial
	(id, resource_name, resource_type, subject, course_code, resource_link)
SELECT id, resource_name, "resource_type" AS resource_type,
    "subject" AS subject, "course_code" AS course_code, resource_link
FROM unofficial_raw;

--show sample data
TABLE course;
TABLE required;
TABLE unofficial;

--dictionary operations
--(Subject to modification)

--sample scenarios
-- Q: I am planning to take the course ENEE459B next semester and I heard that it is difficult. Do they have a required textbook that I can have a preview with at my own pace?
-- A: 
SELECT c.subject, c.course_code, c.course_name, c.professor,
  r.id AS required_text_id, r.text_name, r.isbn_link, 
  r.has_practice, r.is_free
FROM course AS c
JOIN required AS r
  ON r.id = ANY (c.required_text_ids::int[])
WHERE c.subject = 'ENEE' AND c.course_code = '459B';

-- Q: Unfortunately, I do not have the best professor for the course MATH141 this semester. His homework problems are too easy and I do not learn anything from them. I am afraid that I am not prepared for the coming exam. Can I find some resources that contain practice problems that could help me?
-- A:
SELECT r.text_name, r.isbn_link
FROM required AS r
WHERE r.subject = 'MATH' AND r.course_code = '141' AND r.has_practice = true;

-- Q: I am a student in the ECE department, and I am going to be a senior next semester. I know that I can take a lot of elective courses (to be more specific, I want to take ENEE4xx courses). Moreover, I would prefer a course with some lab exercises to build my research skills and/or projects on my resume. Can I see a list of such courses in my department?
-- A:
SELECT subject, course_code, course_name, professor, credits
FROM course
WHERE subject = 'ENEE' 
  AND course_code LIKE '4%' 
  AND is_lab = TRUE;

-- Q: My favorite professor is Justin Wyss-Gallifent. How many courses have my favorite professor taught, and what are they?
-- A: 
SELECT DISTINCT ON (course_name) 
	subject, course_code, course_name
FROM course
WHERE professor = 'Justin Wyss-Gallifent';

-- Q: I have been debugging this piece of code about blockchain for 10 hours. Is there a Youtube video that explains the theory of how such a data structure works so that I can check if I have understood something correctly?
-- A: 
SELECT u.resource_name, u.resource_type, u.resource_link
FROM unofficial AS u
WHERE u.resource_name ILIKE '%blockchain%'
  AND u.resource_link ILIKE '%youtube%'
ORDER BY u.resource_name;