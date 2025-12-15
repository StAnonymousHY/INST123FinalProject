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
FROM 'C:\Program Files\PostgreSQL\17\data\CLASSCSV\Course.csv'
WITH (FORMAT csv, HEADER true);

COPY required_raw
FROM 'C:\Program Files\PostgreSQL\17\data\CLASSCSV\Required.csv'
WITH (FORMAT csv, HEADER true);

COPY unofficial_raw
FROM 'C:\Program Files\PostgreSQL\17\data\CLASSCSV\Unofficial.csv'
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