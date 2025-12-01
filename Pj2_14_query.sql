------------------------------------------------------------
-- Pj2_14_query.sql
-- Group 14 – Functional Requirements 3.8.1 ~ 3.8.16
------------------------------------------------------------

------------------------------------------------------------
-- 3.8.1  Open classes for registration (Spring 2026)
------------------------------------------------------------
SELECT 
    sec.SectionID,
    c.CoursePrefix,
    c.CourseNumber,
    c.CourseTitle,
    sec.CRN,
    sec.SectionNumber,
    sec.Capacity,
    (SELECT COUNT(*) FROM Bellini.Enrollment e WHERE e.SectionID = sec.SectionID) AS CurrentEnrollment
FROM Bellini.Section sec
JOIN Bellini.Course c ON sec.CourseID = c.CourseID
JOIN Bellini.Term t ON sec.TermID = t.TermID
WHERE t.TermName = 'Spring 2026'
  AND sec.Status = 'Open'
  AND (SELECT COUNT(*) FROM Bellini.Enrollment e WHERE e.SectionID = sec.SectionID) < sec.Capacity
ORDER BY c.CoursePrefix, c.CourseNumber;


------------------------------------------------------------
-- 3.8.2  Required courses + total hours for BSCS
------------------------------------------------------------
SELECT 
    m.MajorName,
    c.CoursePrefix,
    c.CourseNumber,
    c.CourseTitle,
    c.Credits,
    cr.RequirementType
FROM Bellini.CourseRequirement cr
JOIN Bellini.Course c ON cr.CourseID = c.CourseID
JOIN Bellini.Major m ON cr.MajorID = m.MajorID
WHERE m.MajorCode = 'BSCS'
ORDER BY c.CoursePrefix, c.CourseNumber;

SELECT 
    m.MajorName,
    SUM(c.Credits) AS TotalRequiredCredits
FROM Bellini.CourseRequirement cr
JOIN Bellini.Course c ON cr.CourseID = c.CourseID
JOIN Bellini.Major m ON cr.MajorID = m.MajorID
WHERE m.MajorCode = 'BSCS'
GROUP BY m.MajorName;


------------------------------------------------------------
-- 3.8.3  Required but not yet registered + remaining hours
------------------------------------------------------------
SELECT 
    c.CoursePrefix,
    c.CourseNumber,
    c.CourseTitle,
    c.Credits
FROM Bellini.CourseRequirement cr
JOIN Bellini.Course c ON cr.CourseID = c.CourseID
JOIN Bellini.Student s ON cr.MajorID = s.MajorID
WHERE s.USF_ID = 'U000000001'
AND cr.CourseID NOT IN (
    SELECT c2.CourseID
    FROM Bellini.Enrollment e
    JOIN Bellini.Section sec ON e.SectionID = sec.SectionID
    JOIN Bellini.Course c2 ON sec.CourseID = c2.CourseID
    WHERE e.StudentID = s.StudentID
)
ORDER BY c.CoursePrefix, c.CourseNumber;

SELECT 
    SUM(c.Credits) AS RemainingCredits
FROM Bellini.CourseRequirement cr
JOIN Bellini.Course c ON cr.CourseID = c.CourseID
JOIN Bellini.Student s ON cr.MajorID = s.MajorID
WHERE s.USF_ID = 'U000000001'
AND cr.CourseID NOT IN (
    SELECT c2.CourseID
    FROM Bellini.Enrollment e
    JOIN Bellini.Section sec ON e.SectionID = sec.SectionID
    JOIN Bellini.Course c2 ON sec.CourseID = c2.CourseID
    WHERE e.StudentID = s.StudentID
);


------------------------------------------------------------
-- 3.8.4  4-year study plan
------------------------------------------------------------
SELECT
    s.USF_ID,
    s.FirstName,
    s.LastName,
    t.TermName,
    c.CoursePrefix,
    c.CourseNumber,
    c.CourseTitle
FROM Bellini.StudyPlan sp
JOIN Bellini.Student s ON sp.StudentID = s.StudentID
JOIN Bellini.Term t ON sp.TermID = t.TermID
JOIN Bellini.Course c ON sp.CourseID = c.CourseID
WHERE s.USF_ID = 'U000000001'
ORDER BY t.TermStartDate;


------------------------------------------------------------
-- 3.8.5  Course info (credits, prereqs, coreqs, description)
------------------------------------------------------------
SELECT 
    c.CoursePrefix,
    c.CourseNumber,
    c.CourseTitle,
    c.Credits,
    c.CourseDescription
FROM Bellini.Course c
WHERE c.CoursePrefix = 'CAP' AND c.CourseNumber = '4034';

SELECT 
    p.CoursePrefix AS PrereqPrefix,
    p.CourseNumber AS PrereqNumber,
    cp.MinGradeRequired
FROM Bellini.CoursePrereq cp
JOIN Bellini.Course p ON cp.PrereqCourseID = p.CourseID
JOIN Bellini.Course c ON cp.CourseID = c.CourseID
WHERE c.CoursePrefix = 'CAP' AND c.CourseNumber = '4034';

SELECT 
    p.CoursePrefix AS CoreqPrefix,
    p.CourseNumber AS CoreqNumber
FROM Bellini.CourseCoreq cc
JOIN Bellini.Course p ON cc.CoreqCourseID = p.CourseID
JOIN Bellini.Course c ON cc.CourseID = c.CourseID
WHERE c.CoursePrefix = 'CAP' AND c.CourseNumber = '4034';


------------------------------------------------------------
-- 3.8.6  Class/section info (Fall 2025 / Spring 2026)
------------------------------------------------------------
SELECT
    sec.SectionID,
    t.TermName,
    c.CoursePrefix,
    c.CourseNumber,
    sec.SectionNumber,
    sec.CRN,
    sec.Type,
    sec.Status,
    sec.Capacity,
    sec.Location,
    sec.Schedule,
    i.InstructorName,
    (SELECT COUNT(*) FROM Bellini.TAAssignment ta WHERE ta.SectionID = sec.SectionID) AS TA_Count,
    (SELECT COUNT(*) FROM Bellini.Enrollment e WHERE e.SectionID = sec.SectionID) AS EnrollmentCount
FROM Bellini.Section sec
JOIN Bellini.Course c ON sec.CourseID = c.CourseID
JOIN Bellini.Term t ON sec.TermID = t.TermID
JOIN Bellini.Instructor i ON sec.InstructorID = i.InstructorID
WHERE t.TermName IN ('Fall 2025', 'Spring 2026')
ORDER BY t.TermStartDate, c.CoursePrefix, c.CourseNumber;


------------------------------------------------------------
-- 3.8.7  Instructor info + schedule
------------------------------------------------------------
SELECT 
    i.InstructorName,
    i.InstructorOffice,
    i.InstructorEmail,
    i.InstructorPhone,
    t.TermName,
    c.CoursePrefix,
    c.CourseNumber,
    sec.SectionNumber,
    sec.Schedule,
    sec.Location
FROM Bellini.Instructor i
JOIN Bellini.Section sec ON sec.InstructorID = i.InstructorID
JOIN Bellini.Course c ON sec.CourseID = c.CourseID
JOIN Bellini.Term t ON sec.TermID = t.TermID
WHERE i.InstructorName = 'Dr. Alice Smith'
ORDER BY t.TermStartDate;


------------------------------------------------------------
-- 3.8.8  Modify Spring 2026 class info
------------------------------------------------------------
UPDATE Bellini.Section
SET Location = 'ENB 120', Capacity = 40
WHERE SectionID = (
    SELECT TOP 1 SectionID 
    FROM Bellini.Section 
    WHERE CRN = 93002
);


------------------------------------------------------------
-- 3.8.9  GPA summary by major
------------------------------------------------------------
SELECT
    m.MajorName,
    AVG(e.NumericGrade) AS AvgGrade,
    MAX(e.NumericGrade) AS HighestGrade,
    MIN(e.NumericGrade) AS LowestGrade,
    COUNT(DISTINCT s.StudentID) AS TotalStudents
FROM Bellini.Enrollment e
JOIN Bellini.Student s ON e.StudentID = s.StudentID
JOIN Bellini.Major m ON s.MajorID = m.MajorID
WHERE e.LetterGrade IS NOT NULL
GROUP BY m.MajorName;


------------------------------------------------------------
-- 3.8.10  What-if GPA (all A's Spring 2026)
------------------------------------------------------------
SELECT
    s.StudentID,
    s.FirstName,
    s.LastName,
    SUM(4.0 * c.Credits) / SUM(c.Credits) AS WhatIfGPA
FROM Bellini.Enrollment e
JOIN Bellini.Student s ON e.StudentID = s.StudentID
JOIN Bellini.Section sec ON e.SectionID = sec.SectionID
JOIN Bellini.Course c ON sec.CourseID = c.CourseID
JOIN Bellini.Term t ON sec.TermID = t.TermID
WHERE s.USF_ID = 'U000000001'
  AND t.TermName = 'Spring 2026'
GROUP BY s.StudentID, s.FirstName, s.LastName;


------------------------------------------------------------
-- 3.8.11  Semester transcript (Fall 2025)
------------------------------------------------------------
SELECT
    s.StudentID,
    s.FirstName,
    s.LastName,
    c.CoursePrefix,
    c.CourseNumber,
    c.CourseTitle,
    e.LetterGrade,
    e.NumericGrade,
    t.TermName
FROM Bellini.Enrollment e
JOIN Bellini.Student s ON e.StudentID = s.StudentID
JOIN Bellini.Section sec ON e.SectionID = sec.SectionID
JOIN Bellini.Course c ON sec.CourseID = c.CourseID
JOIN Bellini.Term t ON sec.TermID = t.TermID
WHERE s.USF_ID = 'U000000001'
  AND t.TermName = 'Fall 2025'
ORDER BY c.CoursePrefix, c.CourseNumber;


------------------------------------------------------------
-- 3.8.12  Overall transcript
------------------------------------------------------------
SELECT
    s.StudentID,
    s.FirstName,
    s.LastName,
    c.CoursePrefix,
    c.CourseNumber,
    c.CourseTitle,
    e.LetterGrade,
    e.NumericGrade,
    t.TermName
FROM Bellini.Enrollment e
JOIN Bellini.Student s ON e.StudentID = s.StudentID
JOIN Bellini.Section sec ON e.SectionID = sec.SectionID
JOIN Bellini.Course c ON sec.CourseID = c.CourseID
JOIN Bellini.Term t ON sec.TermID = t.TermID
WHERE s.USF_ID = 'U000000001'
ORDER BY t.TermStartDate;


------------------------------------------------------------
-- 3.8.13  Register a course (safe insert)
------------------------------------------------------------
INSERT INTO Bellini.Enrollment (SectionID, StudentID, EnrollDate, EnrollmentStatus)
SELECT sec.SectionID, s.StudentID, GETDATE(), 'Registered'
FROM Bellini.Student s
JOIN Bellini.Section sec ON sec.CRN = 93001
WHERE s.USF_ID = 'U000000001'
AND NOT EXISTS (
    SELECT 1 FROM Bellini.Enrollment e
    WHERE e.SectionID = sec.SectionID
      AND e.StudentID = s.StudentID
);


------------------------------------------------------------
-- 3.8.14  Drop a course
------------------------------------------------------------
DELETE FROM Bellini.Enrollment
WHERE SectionID = (
    SELECT TOP 1 SectionID FROM Bellini.Section WHERE CRN = 93001
)
AND StudentID = (
    SELECT TOP 1 StudentID FROM Bellini.Student WHERE USF_ID = 'U000000001'
);


------------------------------------------------------------
-- 3.8.15  Modify grades
------------------------------------------------------------
UPDATE Bellini.Enrollment
SET LetterGrade = 'A', NumericGrade = 95, GradePoints = 4.0
WHERE SectionID = (
    SELECT TOP 1 SectionID FROM Bellini.Section WHERE CRN = 92002
)
AND StudentID = (
    SELECT TOP 1 StudentID FROM Bellini.Student WHERE USF_ID = 'U000000006'
);


------------------------------------------------------------
-- 3.8.16  Class roster + grade distribution
------------------------------------------------------------
SELECT 
    s.StudentID,
    s.FirstName,
    s.LastName,
    e.LetterGrade,
    e.NumericGrade
FROM Bellini.Enrollment e
JOIN Bellini.Student s ON e.StudentID = s.StudentID
WHERE e.SectionID = (
    SELECT TOP 1 SectionID FROM Bellini.Section WHERE CRN = 92001
)
ORDER BY s.LastName, s.FirstName;

SELECT 
    e.LetterGrade,
    COUNT(*) AS CountStudents
FROM Bellini.Enrollment e
WHERE e.SectionID = (
    SELECT TOP 1 SectionID FROM Bellini.Section WHERE CRN = 92001
)
GROUP BY e.LetterGrade
ORDER BY e.LetterGrade;