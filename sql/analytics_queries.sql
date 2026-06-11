
-- JOBPULSE — FINAL HIGH-VALUE SQL QUERIES
-- Based on actual data analysis of your 5 tablee
-- SECTION 1 — CORE JOIN (Foundation for all queries below)
-- 1.1  job_postings + companies + company_industries
SELECT
    jp.job_id,
    jp.title,
    jp.location,
    jp.formatted_work_type,
    jp.formatted_experience_level,
    jp.min_salary,
    jp.max_salary,
    c.name                  AS company_name,
    c.company_size,
    c.city                  AS company_city,
    c.country               AS company_country,
    ci.industry
FROM job_postings jp
INNER JOIN companies c
        ON jp.company_id = c.company_id
LEFT  JOIN company_industries ci
        ON c.company_id   = ci.company_id
LIMIT 5;


-- 1.2  Skills-enriched view: job_postings + job_skills (with decoded names)
SELECT
    jp.job_id,
    jp.title,
    jp.formatted_experience_level,
    jp.location,
    js.skill_abr,
    js.skill_name

FROM job_postings jp

INNER JOIN job_skills js
ON jp.job_id = js.job_id

LIMIT 5;


-- ================================================================
-- SECTION 2 — INDUSTRY INSIGHTS
-- (join: job_postings → companies → company_industries)
-- ================================================================

-- 2.1  Top 15 Industries by Hiring Volume
--      INSIGHT: Where are the most jobs?
SELECT
    ci.industry,
    COUNT(DISTINCT jp.job_id)   AS total_jobs,
    COUNT(DISTINCT jp.company_id) AS unique_companies
FROM job_postings jp
INNER JOIN companies c  ON jp.company_id = c.company_id
INNER JOIN company_industries ci ON c.company_id = ci.company_id
GROUP BY ci.industry
ORDER BY total_jobs DESC
LIMIT 5;


-- 2.2  Industry Salary Benchmark
--      INSIGHT: Which industries pay the most?
--      Filter: salary between $15k–$800k to remove bad data
-- Industry Salary Benchmark
-- Which industries offer the highest salaries?

SELECT
    ci.industry,
    COUNT(jp.job_id) AS jobs_with_salary,
    ROUND(AVG(jp.min_salary), 0) AS avg_min_salary,
    ROUND(AVG(jp.max_salary), 0) AS avg_max_salary,
    ROUND(AVG((jp.min_salary + jp.max_salary) / 2), 0) AS avg_mid_salary

FROM job_postings jp

INNER JOIN companies c
    ON jp.company_id = c.company_id

INNER JOIN company_industries ci
    ON c.company_id = ci.company_id

WHERE jp.min_salary IS NOT NULL
  AND jp.max_salary IS NOT NULL
  AND jp.min_salary BETWEEN 15000 AND 800000
  AND jp.max_salary BETWEEN 15000 AND 800000

GROUP BY ci.industry

HAVING COUNT(jp.job_id) >= 5

ORDER BY avg_mid_salary DESC

LIMIT 5;

-- 2.3  Salary Transparency Rate by Industry
--      INSIGHT: Which industries are most open about pay?
SELECT
    ci.industry,
    COUNT(jp.job_id) AS total_postings,
    SUM(CASE WHEN jp.min_salary IS NOT NULL THEN 1 ELSE 0 END)  AS disclosed_salary,
    ROUND(
        100.0 * SUM(CASE WHEN jp.min_salary IS NOT NULL THEN 1 ELSE 0 END)
        / COUNT(jp.job_id), 1
    ) AS transparency_pct
FROM job_postings jp
INNER JOIN companies c  ON jp.company_id = c.company_id
INNER JOIN company_industries ci ON c.company_id = ci.company_id
GROUP BY ci.industry
HAVING COUNT(jp.job_id) >= 30
ORDER BY transparency_pct DESC
LIMIT 15;


-- 2.4  Work Type Distribution by Industry
--      INSIGHT: Which industries hire the most contractors vs full-timers?
SELECT
    ci.industry,
    COUNT(jp.job_id) AS total_jobs,
    SUM(CASE WHEN jp.formatted_work_type = 'Full-time'  THEN 1 ELSE 0 END) AS full_time,
    SUM(CASE WHEN jp.formatted_work_type = 'Contract'   THEN 1 ELSE 0 END) AS contract,
    SUM(CASE WHEN jp.formatted_work_type = 'Part-time'  THEN 1 ELSE 0 END) AS part_time,
    ROUND(100.0 * SUM(CASE WHEN jp.formatted_work_type = 'Contract' THEN 1 ELSE 0 END)
          / COUNT(jp.job_id), 1)  AS contract_pct
FROM job_postings jp
INNER JOIN companies c  ON jp.company_id = c.company_id
INNER JOIN company_industries ci ON c.company_id = ci.company_id
GROUP BY ci.industry
HAVING COUNT(jp.job_id) >= 50
ORDER BY contract_pct DESC
LIMIT 15;


-- ================================================================
-- SECTION 3 — SKILLS DEMAND ANALYTICS
-- (join: job_postings → job_skills)
-- ================================================================

-- 3.1  Top 10 Most In-Demand Skills
--      INSIGHT: What skills do employers value most?
SELECT
    skill_name,
    skill_abr,
    COUNT(*) AS total_demand,
    ROUND(
        100.0 * COUNT(*) /
        (SELECT COUNT(*) FROM job_skills),
        1
    ) AS pct_of_all_jobs

FROM job_skills

GROUP BY skill_name, skill_abr

ORDER BY total_demand DESC

LIMIT 10;


-- 3.2  Skills Demand by Experience Level
--      INSIGHT: Entry-level vs Senior — do skill requirements change?
SELECT
    jp.formatted_experience_level AS experience_level,
    js.skill_name,
    COUNT(*) AS demand_count
FROM job_postings jp
INNER JOIN job_skills js
ON jp.job_id = js.job_id

WHERE jp.formatted_experience_level IN (
    'Entry level',
    'Mid-Senior level',
    'Director',
    'Executive'
)
GROUP BY
    jp.formatted_experience_level,
    js.skill_name
ORDER BY
    jp.formatted_experience_level,
    demand_count DESC;


-- 3.3  Top 3 Skills per Experience Level  (Window Function — RANK)
--      INSIGHT: Skill priorities shift clearly across career levels
WITH skill_ranked AS (

    SELECT
        jp.formatted_experience_level AS experience_level,
        js.skill_name,
        COUNT(*) AS demand_count,

        RANK() OVER (
            PARTITION BY jp.formatted_experience_level
            ORDER BY COUNT(*) DESC
        ) AS rnk

    FROM job_postings jp

    INNER JOIN job_skills js
    ON jp.job_id = js.job_id

    WHERE jp.formatted_experience_level IS NOT NULL

    GROUP BY
        jp.formatted_experience_level,
        js.skill_name
)
SELECT
    experience_level,
    skill_name,
    demand_count,
    rnk
FROM skill_ranked
WHERE rnk <= 3
ORDER BY experience_level, rnk;

-- SECTION 4 — COMPANY ANALYTICS
-- 4.1-- Top Companies Hiring Across Industries

SELECT
    c.name,
    ci.industry,
    COUNT(jp.job_id) AS total_jobs
FROM companies c
JOIN job_postings jp
    ON c.company_id = jp.company_id
JOIN company_industries ci
    ON c.company_id = ci.company_id
GROUP BY c.name, ci.industry
ORDER BY total_jobs DESC
LIMIT 10;

--SECTION 5 — SALARY ANALYTICS
-- 5.1Salary trend over years (from survey data)
SELECT
    work_year,
    experience_level,
    COUNT(*)                       AS respondents,
    ROUND(AVG(salary_in_usd), 0)  AS avg_salary,
    ROUND(MIN(salary_in_usd), 0)  AS min_salary,
    ROUND(MAX(salary_in_usd), 0)  AS max_salary
FROM salaries
WHERE salary_in_usd BETWEEN 20000 AND 500000
GROUP BY work_year, experience_level
ORDER BY work_year DESC, avg_salary DESC;