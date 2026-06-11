CREATE TABLE salaries (
    salary_id INT AUTO_INCREMENT PRIMARY KEY,
    work_year INT,
    experience_level VARCHAR(50),
    employment_type VARCHAR(50),
    job_title VARCHAR(255),
    salary_in_usd FLOAT,
    employee_residence VARCHAR(100),
    remote_ratio VARCHAR(50),
    company_location VARCHAR(100),
    company_size VARCHAR(10)
);

CREATE TABLE companies (
    company_id BIGINT PRIMARY KEY,
    name VARCHAR(255),
    company_size FLOAT,
    state VARCHAR(100),
    country VARCHAR(50),
    city VARCHAR(100),
    company_size_label VARCHAR(100)
);

CREATE TABLE job_postings (
    job_id BIGINT PRIMARY KEY,
    company_id BIGINT,
    title VARCHAR(255),
    description TEXT,
    max_salary FLOAT,
    med_salary FLOAT,
    min_salary FLOAT,
    pay_period VARCHAR(50),
    formatted_work_type VARCHAR(50),
    location VARCHAR(255),
    formatted_experience_level VARCHAR(100),
    work_type VARCHAR(50),
    currency VARCHAR(20),
    compensation_type VARCHAR(50),
    salary_disclosed BOOLEAN,

    CONSTRAINT fk_company
    FOREIGN KEY (company_id)
    REFERENCES companies(company_id)
);

CREATE TABLE company_industries (
    company_id BIGINT,
    industry VARCHAR(255),

    PRIMARY KEY (company_id, industry),

    CONSTRAINT fk_company_industry
    FOREIGN KEY (company_id)
    REFERENCES companies(company_id)
);

CREATE TABLE job_skills (
    job_id BIGINT,
    skill_abr VARCHAR(20),
    skill_name VARCHAR(100),

    PRIMARY KEY (job_id, skill_abr),

    CONSTRAINT fk_job_skills
    FOREIGN KEY (job_id)
    REFERENCES job_postings(job_id)
);
