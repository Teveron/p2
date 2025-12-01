------------------------------------------------------------
-- Group 14
-- Pj2_14_build.sql  
------------------------------------------------------------


------------------------------------------------------------
-- Build database
------------------------------------------------------------

-- Force all users off the DB so DROP DATABASE always succeeds
USE master;
GO

IF DB_ID('Pj2_14') IS NOT NULL
BEGIN
    ALTER DATABASE Pj2_14 SET SINGLE_USER WITH ROLLBACK IMMEDIATE;
    DROP DATABASE Pj2_14;
END
GO

-- Create fresh database
CREATE DATABASE Pj2_14;
GO

USE Pj2_14;
GO

-- Create schema
CREATE SCHEMA Bellini;
GO


------------------------------------------------------------
-- Term
------------------------------------------------------------
CREATE TABLE Bellini.Term (
    TermID        INT IDENTITY(1,1) PRIMARY KEY,
    TermName      NVARCHAR(50) NOT NULL,  -- 'Fall 2025', 'Spring 2026'
    TermStartDate DATE NOT NULL,
    TermEndDate   DATE NOT NULL
);
GO


------------------------------------------------------------
-- Catalog (depends on Term)
------------------------------------------------------------
CREATE TABLE Bellini.Catalog (
    CatalogID        INT IDENTITY(1,1) PRIMARY KEY,
    CatalogYearLabel NVARCHAR(20) NOT NULL,  -- '2022-2023, 2023-2024'
    StartTermID      INT NOT NULL,
    EndTermID        INT NOT NULL,
    CONSTRAINT FK_Catalog_StartTerm
        FOREIGN KEY (StartTermID)
        REFERENCES Bellini.Term(TermID),
    CONSTRAINT FK_Catalog_EndTerm
        FOREIGN KEY (EndTermID)
        REFERENCES Bellini.Term(TermID)
);
GO


------------------------------------------------------------
-- Major
------------------------------------------------------------
CREATE TABLE Bellini.Major (
    MajorID   INT IDENTITY(1,1) PRIMARY KEY,
    MajorCode NVARCHAR(10) NOT NULL,       -- BSCS, BSCP, BSIT, BSCyS
    MajorName NVARCHAR(100) NOT NULL
);
GO

------------------------------------------------------------
-- Instructor
------------------------------------------------------------
CREATE TABLE Bellini.Instructor (
    InstructorID     INT IDENTITY(1,1) PRIMARY KEY,
    InstructorName   NVARCHAR(100) NOT NULL,
    InstructorOffice NVARCHAR(50)  NULL,
    InstructorEmail  NVARCHAR(100) NULL,
    InstructorPhone  NVARCHAR(30)  NULL
);
GO


------------------------------------------------------------
-- Student
------------------------------------------------------------
CREATE TABLE Bellini.Student (
    StudentID        INT IDENTITY(1,1) PRIMARY KEY,
    USF_ID           CHAR(10) NOT NULL UNIQUE,  -- 'U000000001'
    FirstName        NVARCHAR(50) NOT NULL,
    LastName         NVARCHAR(50) NOT NULL,
    MajorID          INT NOT NULL,
    AdmissionTermID  INT NOT NULL,
    AdmissionDate    DATE NOT NULL,
    Email            NVARCHAR(100) NULL,
    Phone            NVARCHAR(30)  NULL,
    CONSTRAINT FK_Student_Major
        FOREIGN KEY (MajorID)
        REFERENCES Bellini.Major(MajorID),
    CONSTRAINT FK_Student_AdmissionTerm
        FOREIGN KEY (AdmissionTermID)
        REFERENCES Bellini.Term(TermID)
);
GO


------------------------------------------------------------
-- MajorHistory (composite PK: StudentID, ChangeTermID)
------------------------------------------------------------
CREATE TABLE Bellini.MajorHistory (
    StudentID    INT NOT NULL,
    ChangeTermID INT NOT NULL,
    ChangeDate   DATE NOT NULL,
    OldMajorID   INT NOT NULL,
    NewMajorID   INT NOT NULL,
    CONSTRAINT PK_MajorHistory
        PRIMARY KEY (StudentID, ChangeTermID),
    CONSTRAINT FK_MH_Student
        FOREIGN KEY (StudentID)
        REFERENCES Bellini.Student(StudentID),
    CONSTRAINT FK_MH_ChangeTerm
        FOREIGN KEY (ChangeTermID)
        REFERENCES Bellini.Term(TermID),
    CONSTRAINT FK_MH_OldMajor
        FOREIGN KEY (OldMajorID)
        REFERENCES Bellini.Major(MajorID),
    CONSTRAINT FK_MH_NewMajor
        FOREIGN KEY (NewMajorID)
        REFERENCES Bellini.Major(MajorID)
);
GO


------------------------------------------------------------
-- Course
------------------------------------------------------------
CREATE TABLE Bellini.Course (
    CourseID          INT IDENTITY(1,1) PRIMARY KEY,
    CoursePrefix      NVARCHAR(10) NOT NULL,   -- CIS, COP, MAC etc.
    CourseNumber      NVARCHAR(10) NOT NULL,   -- 2510, 3515, 4622L etc.
    CourseTitle       NVARCHAR(200) NOT NULL,
    Credits           INT NOT NULL,
    CourseDescription NVARCHAR(MAX) NULL,
    CourseLevel       INT NOT NULL,            -- 2000, 3000, 4000 etc.
    CONSTRAINT UQ_Course_PrefixNumber
        UNIQUE (CoursePrefix, CourseNumber)
);
GO


------------------------------------------------------------
-- CourseRequirement (composite PK + CatalogID)
------------------------------------------------------------
CREATE TABLE Bellini.CourseRequirement (
    MajorID          INT NOT NULL,
    CourseID         INT NOT NULL,
    CatalogID        INT NOT NULL,
    RequirementType  NVARCHAR(30) NOT NULL,    -- 'Core', 'Elective', 'StateMandated'
    MinGradeRequired CHAR(2) NOT NULL,         -- 'C', 'B', etc.
    CONSTRAINT PK_CourseRequirement
        PRIMARY KEY (MajorID, CourseID, CatalogID),
    CONSTRAINT FK_CR_Major
        FOREIGN KEY (MajorID)
        REFERENCES Bellini.Major(MajorID),
    CONSTRAINT FK_CR_Course
        FOREIGN KEY (CourseID)
        REFERENCES Bellini.Course(CourseID),
    CONSTRAINT FK_CR_Catalog
        FOREIGN KEY (CatalogID)
        REFERENCES Bellini.Catalog(CatalogID)
);
GO

------------------------------------------------------------
-- RequirementGroup (per-major + per-catalog)
------------------------------------------------------------
CREATE TABLE Bellini.RequirementGroup (
    RequirementGroupID INT IDENTITY(1,1) PRIMARY KEY,
    MajorID            INT NOT NULL,
    CatalogID          INT NOT NULL,
    GroupCode          NVARCHAR(50) NOT NULL,   -- 'BSCS23_CALC1'
    GroupName          NVARCHAR(100) NOT NULL,  -- 'Calc I Requirement'
    MinCoursesRequired INT NOT NULL,
    CONSTRAINT FK_RG_Major
        FOREIGN KEY (MajorID)
        REFERENCES Bellini.Major(MajorID),
    CONSTRAINT FK_RG_Catalog
        FOREIGN KEY (CatalogID)
        REFERENCES Bellini.Catalog(CatalogID)
);
GO


------------------------------------------------------------
-- RequirementGroupCourse (composite PK)
------------------------------------------------------------
CREATE TABLE Bellini.RequirementGroupCourse (
    RequirementGroupID INT NOT NULL,
    CourseID           INT NOT NULL,
    CONSTRAINT PK_RGC
        PRIMARY KEY (RequirementGroupID, CourseID),
    CONSTRAINT FK_RGC_Group
        FOREIGN KEY (RequirementGroupID)
        REFERENCES Bellini.RequirementGroup(RequirementGroupID),
    CONSTRAINT FK_RGC_Course
        FOREIGN KEY (CourseID)
        REFERENCES Bellini.Course(CourseID)
);
GO


------------------------------------------------------------
-- CoursePrereq
------------------------------------------------------------
CREATE TABLE Bellini.CoursePrereq (
    CourseID        INT NOT NULL,
    PrereqCourseID  INT NOT NULL,
    MinGradeRequired CHAR(2) NOT NULL,
    CONSTRAINT PK_CoursePrereq
        PRIMARY KEY (CourseID, PrereqCourseID),
    CONSTRAINT FK_Pr_Course
        FOREIGN KEY (CourseID)
        REFERENCES Bellini.Course(CourseID),
    CONSTRAINT FK_Pr_Prereq
        FOREIGN KEY (PrereqCourseID)
        REFERENCES Bellini.Course(CourseID)
);
GO


------------------------------------------------------------
-- CourseCoreq
------------------------------------------------------------
CREATE TABLE Bellini.CourseCoreq (
    CourseID      INT NOT NULL,
    CoreqCourseID INT NOT NULL,
    CONSTRAINT PK_CourseCoreq
        PRIMARY KEY (CourseID, CoreqCourseID),
    CONSTRAINT FK_Co_Course
        FOREIGN KEY (CourseID)
        REFERENCES Bellini.Course(CourseID),
    CONSTRAINT FK_Co_Coreq
        FOREIGN KEY (CoreqCourseID)
        REFERENCES Bellini.Course(CourseID)
);
GO


------------------------------------------------------------
-- Section
------------------------------------------------------------
CREATE TABLE Bellini.Section (
    SectionID     INT IDENTITY(1,1) PRIMARY KEY,
    CourseID      INT NOT NULL,
    TermID        INT NOT NULL,
    SectionNumber NVARCHAR(10) NOT NULL,     -- '001'
    CRN           INT NOT NULL,              -- unique per term
    Type          NVARCHAR(20) NOT NULL,     -- 'Lecture', 'Lab'
    Status        NVARCHAR(10) NOT NULL,     -- 'Open', 'Closed'
    Capacity      INT NOT NULL,
    Location      NVARCHAR(50) NULL,
    Schedule      NVARCHAR(100) NULL,        -- e.g. 'MW 09:30-10:45'
    InstructorID  INT NOT NULL,
    CONSTRAINT UQ_Section_Term_CRN
        UNIQUE (TermID, CRN),
    CONSTRAINT FK_Section_Course
        FOREIGN KEY (CourseID)
        REFERENCES Bellini.Course(CourseID),
    CONSTRAINT FK_Section_Term
        FOREIGN KEY (TermID)
        REFERENCES Bellini.Term(TermID),
    CONSTRAINT FK_Section_Instructor
        FOREIGN KEY (InstructorID)
        REFERENCES Bellini.Instructor(InstructorID)
);
GO


------------------------------------------------------------
-- TAAssignment
------------------------------------------------------------
CREATE TABLE Bellini.TAAssignment (
    SectionID INT NOT NULL,
    StudentID INT NOT NULL,
    Role      NVARCHAR(30) NOT NULL,         -- 'TA', 'Grader'
    CONSTRAINT PK_TAAssignment
        PRIMARY KEY (SectionID, StudentID),
    CONSTRAINT FK_TA_Section
        FOREIGN KEY (SectionID)
        REFERENCES Bellini.Section(SectionID),
    CONSTRAINT FK_TA_Student
        FOREIGN KEY (StudentID)
        REFERENCES Bellini.Student(StudentID)
);
GO


------------------------------------------------------------
-- Enrollment (PK: SectionID, StudentID)
------------------------------------------------------------
CREATE TABLE Bellini.Enrollment (
    SectionID        INT NOT NULL,
    StudentID        INT NOT NULL,
    EnrollDate       DATE NOT NULL,
    EnrollmentStatus NVARCHAR(20) NOT NULL,   -- 'Registered','Completed','Dropped'
    LetterGrade      CHAR(2) NULL,
    NumericGrade     DECIMAL(5,2) NULL,
    GradePoints      DECIMAL(4,2) NULL,
    CONSTRAINT PK_Enrollment
        PRIMARY KEY (SectionID, StudentID),
    CONSTRAINT FK_Enroll_Section
        FOREIGN KEY (SectionID)
        REFERENCES Bellini.Section(SectionID),
    CONSTRAINT FK_Enroll_Student
        FOREIGN KEY (StudentID)
        REFERENCES Bellini.Student(StudentID)
);
GO


------------------------------------------------------------
-- StudyPlan (BCNF: surrogate key PlanEntryID)
------------------------------------------------------------
CREATE TABLE Bellini.StudyPlan (
    PlanEntryID INT IDENTITY(1,1) PRIMARY KEY,
    StudentID   INT NOT NULL,
    TermID      INT NOT NULL,
    CourseID    INT NOT NULL,
    CONSTRAINT FK_SP_Student
        FOREIGN KEY (StudentID)
        REFERENCES Bellini.Student(StudentID),
    CONSTRAINT FK_SP_Term
        FOREIGN KEY (TermID)
        REFERENCES Bellini.Term(TermID),
    CONSTRAINT FK_SP_Course
        FOREIGN KEY (CourseID)
        REFERENCES Bellini.Course(CourseID)
);
GO


------------------------------------------------------------
/* 
   ===============   VARIABLE DECLARATIONS   ==================
   */

-- All DML happens in one batch
DECLARE
    -- Terms
    @TERM_FALL_2022   INT,   
    @TERM_SPRING_2023 INT,
    @TERM_SUMMER_2023 INT,
    @TERM_FALL_2023   INT,
    @TERM_SPRING_2024 INT,
    @TERM_SUMMER_2024 INT,
    @TERM_FALL_2024   INT,
    @TERM_SPRING_2025 INT,
    @TERM_SUMMER_2025 INT,
    @TERM_FALL_2025   INT,
    @TERM_SPRING_2026 INT,
    @TERM_FALL_2026   INT,
    @TERM_SPRING_2027 INT,

    -- Majors
    @MAJOR_BSCP  INT,
    @MAJOR_BSCS  INT,
    @MAJOR_BSIT  INT,
    @MAJOR_BSCyS INT,

    -- Catalogs
    @CATALOG_2022_2023 INT,
    @CATALOG_2023_2024 INT,

    -- Instructors
    @INSTRUCTOR_1 INT,
    @INSTRUCTOR_2 INT,
    @INSTRUCTOR_3 INT,

    -- Courses
    @COURSE_AMH_2020  INT,
    @COURSE_ANT_2000  INT,
    @COURSE_ARH_2000  INT,
    @COURSE_AST_2002  INT,
    @COURSE_BSC_1005  INT,
    @COURSE_BSC_2010  INT,
    @COURSE_BSC_2010L INT,
    @COURSE_BSC_2085  INT,
    @COURSE_BSC_2085L INT,
    @COURSE_CAP_4034  INT,
    @COURSE_CAP_4063  INT,
    @COURSE_CAP_4103  INT,
    @COURSE_CAP_4111  INT,
    @COURSE_CAP_4136  INT,
    @COURSE_CAP_4160  INT,
    @COURSE_CAP_4401  INT,
    @COURSE_CAP_4410  INT,
    @COURSE_CAP_4621  INT,
    @COURSE_CAP_4628  INT,
    @COURSE_CAP_4637  INT,
    @COURSE_CAP_4641  INT,
    @COURSE_CAP_4662  INT,
    @COURSE_CAP_4744  INT,
    @COURSE_CAP_4773  INT,
    @COURSE_CDA_3103  INT,
    @COURSE_CDA_3201  INT,
    @COURSE_CDA_3201L INT,
    @COURSE_CDA_4203  INT,
    @COURSE_CDA_4203L INT,
    @COURSE_CDA_4205  INT,
    @COURSE_CDA_4205L INT,
    @COURSE_CDA_4213  INT,
    @COURSE_CDA_4213L INT,
    @COURSE_CDA_4253  INT,
    @COURSE_CDA_4321  INT,
    @COURSE_CDA_4322  INT,
    @COURSE_CDA_4323  INT,
    @COURSE_CDA_4621  INT,
    @COURSE_CEN_3722  INT,
    @COURSE_CEN_4020  INT,
    @COURSE_CEN_4072  INT,
    @COURSE_CEN_4360  INT,
    @COURSE_CGS_1540  INT,
    @COURSE_CGS_2100  INT,
    @COURSE_CGS_3303  INT,
    @COURSE_CGS_3853  INT,
    @COURSE_CHM_2020  INT,
    @COURSE_CHM_2045  INT,
    @COURSE_CHM_2045L INT,
    @COURSE_CHS_2440  INT,
    @COURSE_CHS_2440L INT,
    @COURSE_CIS_3213  INT,
    @COURSE_CIS_3360  INT,
    @COURSE_CIS_3362  INT,
    @COURSE_CIS_3363  INT,
    @COURSE_CIS_3433  INT,
    @COURSE_CIS_4083  INT,
    @COURSE_CIS_4200  INT,
    @COURSE_CIS_4203  INT,
    @COURSE_CIS_4212  INT,
    @COURSE_CIS_4219  INT,
    @COURSE_CIS_4250  INT,
    @COURSE_CIS_4253  INT,
    @COURSE_CIS_4345  INT,
    @COURSE_CIS_4361  INT,
    @COURSE_CIS_4364  INT,
    @COURSE_CIS_4368  INT,
    @COURSE_CIS_4622  INT,
    @COURSE_CIS_4623  INT,
    @COURSE_CIS_4900  INT,
    @COURSE_CIS_4910  INT,
    @COURSE_CIS_4915  INT,
    @COURSE_CIS_4930  INT,
    @COURSE_CIS_4935  INT,
    @COURSE_CIS_4940  INT,
    @COURSE_CIS_4947  INT,
    @COURSE_CNT_4004  INT,
    @COURSE_CNT_4104  INT,
    @COURSE_CNT_4104L INT,
    @COURSE_CNT_4403  INT,
    @COURSE_CNT_4411  INT,
    @COURSE_CNT_4419  INT,
    @COURSE_CNT_4603  INT,
    @COURSE_CNT_4716C INT,
    @COURSE_CNT_4800  INT,
    @COURSE_COP_2030  INT,
    @COURSE_COP_2510  INT,
    @COURSE_COP_2512  INT,
    @COURSE_COP_2513  INT,
    @COURSE_COP_2700  INT,
    @COURSE_COP_3331  INT,
    @COURSE_COP_3353  INT,
    @COURSE_COP_3514  INT,
    @COURSE_COP_3515  INT,
    @COURSE_COP_3718  INT,
    @COURSE_COP_4020  INT,
    @COURSE_COP_4365  INT,
    @COURSE_COP_4368  INT,
    @COURSE_COP_4520  INT,
    @COURSE_COP_4530  INT,
    @COURSE_COP_4538  INT,
    @COURSE_COP_4564  INT,
    @COURSE_COP_4600  INT,
    @COURSE_COP_4620  INT,
    @COURSE_COP_4656  INT,
    @COURSE_COP_4703  INT,
    @COURSE_COP_4710  INT,
    @COURSE_COP_4883  INT,
    @COURSE_COP_4900  INT,
    @COURSE_COP_4931  INT,
    @COURSE_COT_3100  INT,
    @COURSE_COT_4210  INT,
    @COURSE_COT_4400  INT,
    @COURSE_COT_4521  INT,
    @COURSE_COT_4601  INT,
    @COURSE_CTS_4337  INT,
    @COURSE_ECO_2013  INT,
    @COURSE_EDG_3801  INT,
    @COURSE_EEE_3394  INT,
    @COURSE_EGN_3000  INT,
    @COURSE_EGN_3000L INT,
    @COURSE_EGN_3373  INT,
    @COURSE_EGN_3433  INT,
    @COURSE_EGN_3443  INT,
    @COURSE_EGN_3615  INT,
    @COURSE_EGN_4450  INT,
    @COURSE_ENC_1101  INT,
    @COURSE_ENC_1102  INT,
    @COURSE_ENC_3246  INT,
    @COURSE_ESC_2000  INT,
    @COURSE_EVR_2001  INT,
    @COURSE_HUM_1020  INT,
    @COURSE_INR_3033  INT,
    @COURSE_ISM_3011  INT,
    @COURSE_ISM_4041  INT,
    @COURSE_ISM_4323  INT,
    @COURSE_LIS_4414  INT,
    @COURSE_LIS_4779  INT,
    @COURSE_LIT_2000  INT,
    @COURSE_MAC_1105  INT,
    @COURSE_MAC_1147  INT,
    @COURSE_MAC_2281  INT,
    @COURSE_MAC_2282  INT,
    @COURSE_MAC_2283  INT,
    @COURSE_MAC_2311  INT,
    @COURSE_MAC_2312  INT,
    @COURSE_MAC_2313  INT,
    @COURSE_MAD_2104  INT,
    @COURSE_MAP_2302  INT,
    @COURSE_MAT_1033  INT,
    @COURSE_MGF_1106  INT,
    @COURSE_MGF_1107  INT,
    @COURSE_MUL_2010  INT,
    @COURSE_PHI_2010  INT,
    @COURSE_PHY_2020  INT,
    @COURSE_PHY_2048  INT,
    @COURSE_PHY_2048L INT,
    @COURSE_PHY_2049  INT,
    @COURSE_PHY_2049L INT,
    @COURSE_PHY_2053  INT,
    @COURSE_PHY_2053L INT,
    @COURSE_PHY_2060  INT,
    @COURSE_POS_2041  INT,
    @COURSE_PSY_2012  INT,
    @COURSE_STA_2023  INT,
    @COURSE_SYG_2000  INT,
    @COURSE_THE_2000  INT,
    @COURSE_XXX_ELECTIVE INT,

    -- Course Groups
    @GROUP_BSCP_2022_2023_GECH INT,
    @GROUP_BSCP_2022_2023_GECS INT,
    @GROUP_BSCP_2022_2023_CALC_1 INT,
    @GROUP_BSCP_2022_2023_CALC_2 INT,
    @GROUP_BSCP_2022_2023_CALC_3 INT,
    @GROUP_BSCP_2022_2023_DIFF_EQ INT,
    @GROUP_BSCP_2022_2023_CHEM_1 INT,
    @GROUP_BSCP_2022_2023_CHEM_1_LAB INT,
    @GROUP_BSCP_2022_2023_HARDWARE_ELECTIVES INT,
    @GROUP_BSCP_2022_2023_ELECTIVES INT,

    @GROUP_BSCP_2023_2024_GECH INT,
    @GROUP_BSCP_2023_2024_GECS INT,
    @GROUP_BSCP_2023_2024_CALC_1 INT,
    @GROUP_BSCP_2023_2024_CALC_2 INT,
    @GROUP_BSCP_2023_2024_CALC_3 INT,
    @GROUP_BSCP_2023_2024_DIFF_EQ INT,
    @GROUP_BSCP_2023_2024_CHEM_1 INT,
    @GROUP_BSCP_2023_2024_CHEM_1_LAB INT,
    @GROUP_BSCP_2023_2024_HARDWARE_ELECTIVES INT,
    @GROUP_BSCP_2023_2024_ELECTIVES INT,

    @GROUP_BSCS_2022_2023_GECH INT,
    @GROUP_BSCS_2022_2023_GECS INT,
    @GROUP_BSCS_2022_2023_CALC_1 INT,
    @GROUP_BSCS_2022_2023_CALC_2 INT,
    @GROUP_BSCS_2022_2023_CALC_3 INT,
    @GROUP_BSCS_2022_2023_ELECTIVES INT,

    @GROUP_BSCS_2023_2024_GECH INT,
    @GROUP_BSCS_2023_2024_GECS INT,
    @GROUP_BSCS_2023_2024_CALC_1 INT,
    @GROUP_BSCS_2023_2024_CALC_2 INT,
    @GROUP_BSCS_2023_2024_CALC_3 INT,
    @GROUP_BSCS_2023_2024_SOFTWARE_ELECTIVES INT,
    @GROUP_BSCS_2023_2024_THEORY_ELECTIVES INT,
    @GROUP_BSCS_2023_2024_ELECTIVES INT,

    @GROUP_BSCYS_2022_2023_GECH INT,
    @GROUP_BSCYS_2022_2023_GECS INT,
    @GROUP_BSCYS_2022_2023_ELECTIVES INT,

    @GROUP_BSCYS_2023_2024_GECH INT,
    @GROUP_BSCYS_2023_2024_GECS INT,
    @GROUP_BSCYS_2023_2024_ELECTIVES INT,

    @GROUP_BSIT_2022_2023_GECH INT,
    @GROUP_BSIT_2022_2023_GECS INT,
    @GROUP_BSIT_2022_2023_GENERAL_ADDON INT,
    @GROUP_BSIT_2022_2023_ELECTIVES INT,

    @GROUP_BSIT_2023_2024_GECH INT,
    @GROUP_BSIT_2023_2024_GECS INT,
    @GROUP_BSIT_2023_2024_GENERAL_ADDON INT,
    @GROUP_BSIT_2023_2024_ELECTIVES INT,



    -- Students
    @STUDENT_1 INT,
    @STUDENT_2 INT,
    @STUDENT_3 INT,
    @STUDENT_4 INT,
    @STUDENT_5 INT,
    @STUDENT_6 INT,
    @STUDENT_7 INT,
    @STUDENT_8 INT,
    @STUDENT_9 INT,
    @STUDENT_10 INT,
    @STUDENT_11 INT,
    @STUDENT_12 INT,
    @STUDENT_13 INT,
    @STUDENT_14 INT,
    @STUDENT_15 INT,
    @STUDENT_16 INT,
    @STUDENT_17 INT,
    @STUDENT_18 INT,
    @STUDENT_19 INT,
    @STUDENT_20 INT,

    -- TAs
    @TA_1 INT,
    @TA_2 INT,

    -- Sections
    @S_F25_COP2510 INT,
    @S_F25_COP3515 INT,
    @S_F25_CIS4250 INT,
    @S_F25_CIS4622 INT,
    @S_S26_COP2510 INT,
    @S_S26_COP3515 INT;


------------------------------------------------------------
--                      SEED DATA                         --
------------------------------------------------------------

------------------------------------------------------------
-- Terms
------------------------------------------------------------
INSERT INTO Bellini.Term (TermName, TermStartDate, TermEndDate)
VALUES
    ('Fall 2022',   '2022-08-22', '2022-12-08'),
    ('Spring 2023', '2023-01-09', '2023-05-04'),
    ('Summer 2023', '2023-05-15', '2023-07-21'),
    ('Fall 2023',   '2023-08-21', '2023-12-07'),
    ('Spring 2024', '2024-01-08', '2024-05-02'),
    ('Summer 2024', '2024-05-13', '2024-08-02'),
    ('Fall 2024',   '2024-08-26', '2024-12-12'),
    ('Spring 2025', '2025-01-13', '2025-05-08'),
    ('Summer 2025', '2025-05-19', '2025-08-08'),
    ('Fall 2025',   '2025-08-25', '2025-12-11'),
    ('Spring 2026', '2026-01-12', '2026-05-07'),
    ('Fall 2026',   '2022-08-22', '2022-12-08'),
    ('Spring 2027', '2023-01-09', '2023-05-04');

SELECT @TERM_FALL_2022   = TermID FROM Bellini.Term WHERE TermName = 'Fall 2022';
SELECT @TERM_SPRING_2023 = TermID FROM Bellini.Term WHERE TermName = 'Spring 2023';
SELECT @TERM_SUMMER_2023 = TermID FROM Bellini.Term WHERE TermName = 'Summer 2023';
SELECT @TERM_FALL_2023   = TermID FROM Bellini.Term WHERE TermName = 'Fall 2023';
SELECT @TERM_SPRING_2024 = TermID FROM Bellini.Term WHERE TermName = 'Spring 2024';
SELECT @TERM_SUMMER_2024 = TermID FROM Bellini.Term WHERE TermName = 'Summer 2024';
SELECT @TERM_FALL_2024   = TermID FROM Bellini.Term WHERE TermName = 'Fall 2025';
SELECT @TERM_SPRING_2025 = TermID FROM Bellini.Term WHERE TermName = 'Spring 2025';
SELECT @TERM_SUMMER_2025 = TermID FROM Bellini.Term WHERE TermName = 'Summer 2025';
SELECT @TERM_FALL_2025   = TermID FROM Bellini.Term WHERE TermName = 'Fall 2025';
SELECT @TERM_SPRING_2026 = TermID FROM Bellini.Term WHERE TermName = 'Spring 2026';
SELECT @TERM_FALL_2026   = TermID FROM Bellini.Term WHERE TermName = 'Fall 2026';
SELECT @TERM_SPRING_2027 = TermID FROM Bellini.Term WHERE TermName = 'Spring 2027';


------------------------------------------------------------
-- Majors
------------------------------------------------------------
INSERT INTO Bellini.Major (MajorCode, MajorName)
VALUES
    ('BSCP',  'Computer Engineering'),
    ('BSCS',  'Computer Science'),
    ('BSIT',  'Information Technology'),
    ('BSCyS', 'Cyber Security');

SELECT @MAJOR_BSCP  = MajorID FROM Bellini.Major WHERE MajorCode = 'BSCP';
SELECT @MAJOR_BSCS  = MajorID FROM Bellini.Major WHERE MajorCode = 'BSCS';
SELECT @MAJOR_BSIT  = MajorID FROM Bellini.Major WHERE MajorCode = 'BSIT';
SELECT @MAJOR_BSCyS = MajorID FROM Bellini.Major WHERE MajorCode = 'BSCyS';


------------------------------------------------------------
-- Catalogs
------------------------------------------------------------
INSERT INTO Bellini.Catalog (CatalogYearLabel, StartTermID, EndTermID)
VALUES
    ('2022-2023', @TERM_FALL_2022, @TERM_SUMMER_2023),
    ('2023-2024', @TERM_FALL_2023, @TERM_SUMMER_2024);

SELECT @CATALOG_2022_2023 = CatalogID FROM Bellini.Catalog WHERE CatalogYearLabel = '2022-2023';
SELECT @CATALOG_2023_2024 = CatalogID FROM Bellini.Catalog WHERE CatalogYearLabel = '2023-2024';


------------------------------------------------------------
-- Instructors
------------------------------------------------------------
INSERT INTO Bellini.Instructor (InstructorName, InstructorOffice, InstructorEmail, InstructorPhone)
VALUES
    ('Dr. Alice Smith', 'ENB 101', 'asmith@usf.edu',   '813-974-1001'),
    ('Dr. Bob Johnson', 'ENB 102', 'bjohnson@usf.edu', '813-974-1002'),
    ('Dr. Carol Lee',   'ENB 103', 'clee@usf.edu',     '813-974-1003');

SELECT @INSTRUCTOR_1 = InstructorID FROM Bellini.Instructor WHERE InstructorName = 'Dr. Alice Smith';
SELECT @INSTRUCTOR_2 = InstructorID FROM Bellini.Instructor WHERE InstructorName = 'Dr. Bob Johnson';
SELECT @INSTRUCTOR_3 = InstructorID FROM Bellini.Instructor WHERE InstructorName = 'Dr. Carol Lee';


------------------------------------------------------------
-- Courses
------------------------------------------------------------
INSERT INTO Bellini.Course (CoursePrefix, CourseNumber, CourseTitle, Credits, CourseDescription, CourseLevel)
VALUES
    ('AMH', '2020', 'American History II', 3, 'A history of the United States with attention given to relevant developments in the Western Hemisphere from 1877 to the present.', 2000),
    ('ANT', '2000', 'Introduction to Anthropology', 3, 'The cross-cultural study of the human species in biological and social perspective. Surveys the four major branches of anthropology: physical anthropology, archaeology, linguistic anthropology, and cultural anthropology.', 2000),
    ('ARH', '2000', 'Art and Culture', 3, 'This course offers students an enhanced appreciation and understanding of art. Student will critically evaluate a broad range of imagery, media, artists, movements and historical periods in the visual arts.', 2000),
    ('AST', '2002', 'Descriptive Astronomy', 3, 'An introductory and overview of astronomy course. It is designed to introduce a broad range of topics in astronomy that will be discussed in greater detail in more advanced classes.', 2000),
    ('BSC', '1005', 'Biological Principles for Non-Majors', 3, 'A comprehensive introduction to living systems, including the scientific basis of biology, cell structure and function, genetic mechanisms, human anatomy and physiology, and ecological and evolutionary processes.', 1000),
    ('BSC', '2010', 'Cellular Processes', 3, 'This course deals with biological systems at the cellular and subcellular levels. Topics include an introduction to biochemistry, cell structure and function, enzymes, respiration, mitosis and meiosis, genetics and gene expressi', 2000),
    ('BSC', '2010L', 'Cellular Processes Laboratory', 1, 'Laboratory portion of Biology I Cellular Processes relating to cellular and subcellular structure and function. Mitosis, meiosis, and Mendelian genetics will be stressed.', 2000),
    ('BSC', '2085', 'Anatomy and Physiology I For Health Professionals', 3, 'Introduction to the normal structure, function and selected pathological conditions for physiologic systems. Focus on understanding how the body functions in preparing for careers in nursing or healthrelated professions.', 2000),
    ('BSC', '2085L', 'Anatomy and Physiology Lab I for Nursing and other Healthcare Professionals', 1, 'Laboratory exercises and virtual dissections linked to the basic content of Anatomy & Physiology I for Health Professionals.', 2000),
    ('CAP', '4034', 'Computer Animation Fundamentals', 3, 'An introductory course to computer animation. Topics include storyboarding, camera control, hierarchical character modeling, inverse kinematics, keyframing, motion capture, dynamic simulation, and facial animation.', 4000),
    ('CAP', '4063', 'Web Application Design', 3, 'Analysis, design, and development of software that operates on web servers and web browsers, supporting multiple concurrent users.', 4000),
    ('CAP', '4103', 'Mobile Biometrics', 3, 'Topics include foundations of biometric systems, mobile biometric modalities and features, and adversary attacks.', 4000),
    ('CAP', '4111', 'Introduction to Augmented and Virtual Reality', 3, 'This course introduces students to computer graphics techniques, computer vision techniques, and hardware designs that make augmented and virtual reality systems immersive.', 4000),
    ('CAP', '4136', 'Malware Analysis and Reverse Engineering', 3, 'This course will introduce students to the technical definition of malware, to the various malware analysis techniques (including reverse engineering of malware), and how to mitigate a malware attack.', 4000),
    ('CAP', '4160', 'Brain-Computer Interfaces', 3, 'This course involves the exploration of new forms of Human-Computer Interaction (HCI) based on a passive measurement of neurophysiological states (cognitive and affective). These include measuring cognitive workload and affective engagement. Students will read research papers in several related disciplines (i.e. Neuroscience, Cognitive Psychology, Cognitive Science, Medical BCI, Computational Neuroscience, and others) and present and discuss them in the course. We will explore the uses of noninvasive ubiquitous electroencephalographic (EEG) brain technologies. Also, students will learn the basics of other brain imaging technologies such as nearinfrared spectroscopy (fNIRS) and Functional Magnetic Resonance Imaging (fMRI) and how they relate to the field of computing. We will also explore ways to use such measurements as a form of machine control', 4000),
    ('CAP', '4401', 'Image Processing Fundamentals', 3, 'Practical introduction to a range of fundamental image processing algorithms. Extensive programming, with emphasis on image analysis and transformation techniques. Image transformation and manipulation.', 4000),
    ('CAP', '4410', 'Computer Vision', 3, 'Introduction to topics such as image formation, segmentation, feature extraction, matching, shape recovery, texture analysis, object recognition, and dynamic scene analysis.', 4000),
    ('CAP', '4621', 'Introduction to Artificial Intelligence', 3, 'Introduction to Artificial Intelligence covers basic concepts, tools, and techniques used to produce artificial intelligence. Basic machine learning concepts. Use of different software tools for searching, reasoning and learning.', 4000),
    ('CAP', '4628', 'Affective Computing', 3, 'The study of systems that can recognize, interpret, process, and simulate human affect. Topics may include physiology of emotion, lie detection, wearable devices, music, gaming, and ethical concerns associated with affective computing.', 4000),
    ('CAP', '4637', 'Automated Reasoning and Theorem Proving', 3, 'This course covers the principles of automated reasoning/mechanical theorem proving. Topics to be covered include propositional logic, predicate logic, skolem standard forms, various resolution principles and methods, and non-classical logics.', 4000),
    ('CAP', '4641', 'Natural Language Processing', 3, 'The concepts and principles of computer processing of natural language, including linguistic phenomena, formal methods, and applications.', 4000),
    ('CAP', '4662', 'Introduction to Robotics', 3, 'An introduction to the fundamentals of robotics. Students will learn the fundamentals of robotics including kinematics, inverse kinematics, Jacobian, velocity, configuration space, motion planning, and path planning algorithms.', 4000),
    ('CAP', '4744', 'Interactive Data Visualization', 3, 'This course introduces the techniques used for developing effective visual analysis tools. The course covers principles from perception and design, and the algorithms used in visualizing a broad range of data types.', 4000),
    ('CAP', '4773', 'Social Media Mining', 3, 'This course introduces useful techniques to model, analyze, and understand large-scale social media, with focus on social network analysis, user modeling, bot detection, and dynamical processes over social and information networks.', 4000),
    ('CDA', '3103', 'Computer Organization', 3, 'Introduction to computer hardware, logic elements and Boolean algebra, computer arithmetic, the central processing unit, assembly language programming, input/output, and memory.', 3000),
    ('CDA', '3201', 'Computer Logic and Design', 3, 'CSE and EE majors. Others by special permission. Advanced coverage of Boolean Algebra, introduction to minimization of combinational logic circuits, analysis and synthesis of sequential circuits, testing of logic circuits and programmable logic devices.', 3000),
    ('CDA', '3201L', 'Computer Logic and Design Lab ', 1, 'Laboratory component of the Computer Logic and Design class.', 3000),
    ('CDA', '4203', 'Computer System Design', 3, 'Design Methods, Top-Down design, Building Blocks, Instruction and addressing models, minicomputer design, interfacing.', 4000),
    ('CDA', '4203L', 'Computer System Design Lab ', 1, 'This lab introduces the student to the concept of system design. Several projects are given including building timing circuits, memory-based and communication circuits, and microcomputer-based designs.', 4000),
    ('CDA', '4205', 'Computer Architecture', 3, 'Principles of the design of computer systems, processors, memories, and switches. Consideration of the register transfer representation of a computer, ALU''s and their implementation, control units, memory and I/O, and the hardware support of operation systems.', 4000),
    ('CDA', '4205L', 'Computer Architecture Lab ', 1, 'Laboratory component of the Computer Architecture class.', 4000),
    ('CDA', '4213', 'CMOS-VLSI Design', 3, 'Covers analysis and design of CMOS processing technology, CMOS logic and circuit design, layout timing and delay, and power and thermal issues. CMOS transistor theory. VLSI system design, case studies and rapid prototype chip design.', 4000),
    ('CDA', '4213L', 'CMOS-VLSI Design Lab ', 1, 'Scalable CMOS layout design, circuit extraction, transistor-level and lay-out level simulation, SPICE parameters/modeling, transistor sizing, standard and macro-cell based layout, static/dynamic CMOS, combinational/sequential block layout, memory I/O design.', 4000),
    ('CDA', '4253', 'Field Programmable Gate Array System Design and Analysis', 3, 'Covers analysis and design of digital systems using VHDL simulation. Provides experience with field programmable logic gates and gate arrays. Introduces the requirements for field programmable systems; testing of circuitry, and analysis of system design.', 4000),
    ('CDA', '4321', 'Cryptographic Hardware and Embedded Systems', 3, 'Efficient hardware implementation of cryptographic algorithms is presented to meet the performance and cost requirements of computing platforms from handheld to server-level computers. Cryptographic implementation attacks and countermeasures are covered.', 4000),
    ('CDA', '4322', 'Principles of Secure Hardware Design', 3, 'This course introduces the fundamentals of hardware security for integrated circuits, intellectual property, and reconfigurable devices, including hardware security primitives, Trojans, physical and side-channel attacks, and emerging countermeasures.', 4000),
    ('CDA', '4323', 'Practical Hardware Security', 3, 'This course introduces practical aspects of hardware security for integrated circuits and reconfigurable hardware, with hands-on assignments introducing physical, side channel, and system-level attacks and countermeasures.', 4000),
    ('CDA', '4621', 'Control of Mobile Robots', 3, 'Mobile Robotic Control Systems design and implementation. Includes microcontroller, sensor, and actuator control processes for localization and navigation. Team project development of software interface for robot control.', 4000),
    ('CEN', '3722', 'Human Computer Interfaces for Information Technology', 3, 'The basics of HCI in terms of psychology, computers, and their integration into design and practice are discussed. A life-cycle development framework is presented where user needs, functionality, interaction, and usability are taken into account.', 3000),
    ('CEN', '4020', 'Software Engineering', 3, 'An overview of software engineering techniques for producing high quality software. Student will participate in a software development team.', 4000),
    ('CEN', '4072', 'Software Testing', 3, 'The course provides the fundamental principles and tools for testing and validating large-scale software systems. The course is open to majors as well as non-majors.', 4000),
    ('CEN', '4360', 'Mobile Applications Development for IT', 3, 'The development architecture for mobile apps is presented as are a number of development tools. Students design and implement mobile apps of varying complexity with a focus on the project development process.', 4000),
    ('CGS', '1540', 'Introduction to Databases for Information Technology', 3, 'An introduction to databases, their uses, design, and implementation with IT applications. Query languages, data organization, and modeling are covered. The course emphasizes standard practices for managing information.', 1000),
    ('CGS', '2100', 'Computers in Business', 3, 'A study of the use and impact of computers in all areas of business organizations. Course includes hands-on experience and the use of software packages for business analysis', 2000),
    ('CGS', '3303', 'IT Concepts', 3, 'Elements of computers are discussed. Core areas of IT are introduced: human computer interaction, information management, networking, system administration and maintenance, system integration and architecture, and web systems and technologies.', 3000),
    ('CGS', '3853', 'Web Systems for IT', 3, 'Examines how web sites are developed. Focus on client-side and server-side scripting including HTML, JavaScript, and CSS. A substantial project requiring the design and implementation of an online web site is required.', 3000),
    ('CHM', '2020', 'Chemistry for Liberal Studies I', 3, 'This course is designed for liberal arts students to learn basic chemical principles. Students will learn about reactions, energy and the scientific method. The course will have an emphasis on the chemistry of global climate change.', 2000),
    ('CHM', '2045', 'General Chemistry I', 3, 'Principles and applications of chemistry including properties of substances and reactions, thermochemistry, atomic-molecular structure and bonding, periodic properties of elements and compounds.', 2000),
    ('CHM', '2045L', 'General Chemistry I Laboratory ', 1, 'Laboratory portion of General Chemistry I. Introduction to laboratory techniques; study of properties of elements and compounds; synthesis and analysis of natural and commercial materials.', 2000),
    ('CHS', '2440', 'General Chemistry for Engineers', 3, 'Introduction to important concepts and principles of chemistry with emphasis on areas considered most relevant in an engineering context.', 2000),
    ('CHS', '2440L', 'General Chemistry for Engineers Lab ', 1, 'Laboratory portion of General Chemistry for Engineers. Introduction to laboratory techniques, study of properties of elements, synthesis and analysis of natural and commercial materials.', 2000),
    ('CIS', '3213', 'Foundations of Cybersecurity', 3, 'The fundamentals of cyber security are introduced. Students learn to identify attack phases, understand the adversary''s motivations, the resources and techniques they use, and the intended end-game. Techniques for mitigating threats are described.', 3000),
    ('CIS', '3360', 'Principles of Information Security', 3, 'Board review of Information Security and related elements. Includes terminology, history of the discipline, overview of information security program management. Suitable for IS, criminal justice, political science, accounting information systems students', 3000),
    ('CIS', '3362', 'Cryptography and Information Security', 3, 'This course examines classical cryptography, entropy, stream and block ciphers, public key versus symmetric cryptography, one-way and trap-door functions, plus other specific tools and techniques in popular use.', 3000),
    ('CIS', '3363', 'Information Technology Systems Security', 3, 'This course covers foundations of systems security, including availability, authentication, access control, network penetration/defense, reverse engineering, cyber physical systems, forensics, supply chain management security, and secure systems design.', 3000),
    ('CIS', '3433', 'System Integration and Architecture for IT', 3, 'Role of systems architecture in systems integration, performance, and effectiveness. Principles and concepts of "devops" (development operations) interplay between IT applications roll-out and related organizational processes.', 3000),
    ('CIS', '4083', 'Cloud Computing for IT', 3, 'This is a hand-on class in the methods and technologies of cloud computing. Upon completion of this course students will be able to create, configure, build, deploy, and manage a variety of cloud based solutions.', 4000),
    ('CIS', '4200', 'Penetration Testing for IT', 3, 'Penetration testing and related software tools are presented. Legalities and various cyber-attacks such distributed denial of service, man-in-the-middle, and password attacks are covered. Methods to correct security flaws are given.', 4000),
    ('CIS', '4203', 'Cyber Forensics and Investigations', 3, 'Teaches the methods of acquiring, preserving, retrieving, and presenting data that have been processed electronically and stored on computer media for use in legal proceedings. Focus on MS Windows systems.', 4000),
    ('CIS', '4212', 'Privacy-Preserving and Trustworthy Cyber-Infrastructures', 3, 'This course will explore emerging cyber-security technologies addressing security issues of cyberinfrastructures. It will cover privacy-enhancing and trustworthy techniques for cloud computing and internet of thing systems.', 4000),
    ('CIS', '4219', 'Human Aspects of Cybersecurity', 3, 'This course will study the human aspects of cybersecurity and cover such topics as: identity management, social engineering, societal behaviors, privacy and security, and individual awareness and understanding of cybersecurity.', 4000),
    ('CIS', '4250', 'Ethical Issues and Professional Conduct', 3, 'This course introduces students to ethical issues and professional responsibilities arising in the computer sciences. Students will develop ethical solutions to real-world problems and present them.', 4000),
    ('CIS', '4253', 'Ethics for Information Technology', 3, 'This course covers the professional code of ethics and a survey of ethical issues in computing such as intellectual property, security, privacy, and copyright. Class discussions cover ethical responsibilities of IT professionals and issues that are shaping our society.', 4000),
    ('CIS', '4345', 'Big Data Storage and Analysis with Hadoop', 3, 'This is an introductory course for big data storage and analysis in Hadoop cluster. Topics include Hadoop file system, Hadoop cluster architectures, Hadoop ecosystems, and big data processing frameworks MapReduce, Spark, Pig and Hive.', 4000),
    ('CIS', '4361', 'Information Assurance and Security Management for IT', 3, 'The CIANA model, information security management techniques, and security concerns are presented. Topics include access control systems, network security, security management practices, cryptography, disaster recovery planning, and others.', 4000),
    ('CIS', '4364', 'Cryptology and Information Security', 3, 'Covers the fundamentals of computer security. The following topics are addressed: Network Security, Cryptography, Access Control, Security Architecture and Models, Applications and Systems Development, Vulnerability Assessment.', 4000),
    ('CIS', '4368', 'Database Security and Audits', 3, 'An in-depth look at database security concepts and auditing techniques. Hands-on approach when examining security techniques. Examines different security strategies and advancements in implementation as well as problem solving.', 4000),
    ('CIS', '4622', 'Hands-on Cybersecurity', 3, 'This course covers hands-on skills for cybersecurity -- how to perform common offense and defense activities on computer networks, penetration testing, software exploit basics, basic network forensics, and basics on incident response.', 4000),
    ('CIS', '4623', 'Practical Cybersecurity', 3, 'This course covers how to protect the security of realworld systems -- configuring host/network security settings, penetration testing, software exploit basics, and basics on incident response and forensics.', 4000),
    ('CIS', '4900', 'Independent Study in Computer Science', 1-5, 'Specialized independent study determined by the needs and interests of the student.', 4000),
    ('CIS', '4910', 'Computer Science and Engineering Project', 3, 'Offers a focused team-based design experience incorporating appropriate engineering standards and multiple realistic constraints. Projects are proposed by industry and/or other partners and are completed within a defined development process.', 4000),
    ('CIS', '4915', 'Supervised Research in Computer Science', 1-5, 'Supervised research determined by the needs and interests of the student.', 4000),
    ('CIS', '4930', 'Special Topics in Computer Science I', 1-3, 'Special topics in computer science and computer engineering.', 4000),
    ('CIS', '4935', 'Senior Project in Information Technology', 4, 'This course is the capstone project for IT majors. Students are required to design, implement, and deliver a complete IT solution to a problem leveraging discipline-specific, critical thinking, and communication skills acquired in this major.', 4000),
    ('CIS', '4940', 'Industry Internship', 0-6, 'Individual study as practical computer science and/or computer engineering work under industrial supervision with a faculty approved outline and endof-semester report.', 4000),
    ('CIS', '4947', 'Industry Internship for IT', 1-5, 'Practical information technology work under industrial supervision with a faculty-approved outline and endof-semester report.', 4000),
    ('CNT', '4004', 'Computer Networks I', 3, 'An introduction to the design and analysis of computer communication networks. Topics include application layer protocols, Internet protocols, network interfaces, local and wide area networks, wireless networks, bridging and routing, and current topics.', 4000),
    ('CNT', '4104', 'Computer Information Networks for Information Technology', 3, 'Presents the design and analysis of computer networks. The emphasis is on application- and Internet-layer protocols. Network interfaces, Internet protocols, wireless networks, routing, and security issues are introduced.', 4000),
    ('CNT', '4104L', 'Computer Information Networks Laboratory for Information Technology ', 1, 'This lab provides a hands-on introduction to computer networking and the protocols used to coordinate and control communications on them.', 4000),
    ('CNT', '4403', 'Network Security and Firewalls', 3, 'This course surveys network security standards and emphasizes applications that are widely used on the Internet and for corporate networks. This course also examines Firewalls and related tools used to provide both network and perimeter security.', 4000),
    ('CNT', '4411', 'Computing and Network Security', 3, 'The course is a study of fundamental concepts and principles of computing and network security. The course covers basic security topics, including symmetric and public key cryptography, digital signatures, hash functions,and network security protocols.', 4000),
    ('CNT', '4419', 'Secure Coding', 3, 'Principles and practices for secure computing and writing secure software, including software for performing information management and networking and communications.', 4000),
    ('CNT', '4603', 'System Administration and Maintenance for Information Technology', 3, 'Examines the activities related to the selection, installation and management of computer systems. Covers concepts essential to the administration of OS, networks, and services. Covers system documentation, policies and procedures.', 4000),
    ('CNT', '4716C', 'Network Programming for IT ', 3, 'This course presents the fundamentals of network programming in C# .NET. In this course, the student will learn how to use the Visual Studio development environment to create Windows client and server applications. Topics include network object oriented programming, the study of network protocols, client/server applications, peer-to-peer applications, ASP.NET, Web Services, cloud computing and an introduction to Windows 8 Phone development.', 4000),
    ('CNT', '4800', 'Network Science', 3, 'This course introduces the science of networks via elements of graph theory and practical analysis of real-life datasets.', 4000),
    ('COP', '2030', 'Programming Concepts I', 3, 'This course covers basic programming concepts using the Python language for implementation and developing problem solving skills.', 2000),
    ('COP', '2510', 'Programming Concepts', 3, 'An examination of a modern programming language emphasizing programming concepts and design methodology.', 2000),
    ('COP', '2512', 'Programming Fundamentals for Information Technology', 3, 'An introduction to computer programming using a modern high-level language with IT applications. Topics include variables, types, expressions, and assignment, control structures, I/O, functions, and structured decomposition.', 2000),
    ('COP', '2513', 'Object Oriented Programming for Information Technology', 3, 'An introduction to object oriented programming emphasizing an objects first approach with applications to IT. Objects, methods, and classes are studied in detail. Students design and implement object-oriented programs to solve IT problems.', 2000),
    ('COP', '2700', 'Database Systems Basics', 3, 'Database systems are described with particular emphasis on Relational Database Management Systems (RDBMS). SQLite is the target RDBMS. It is programmatically driven with the Python language and OpenOffice base.', 2000),
    ('COP', '3331', 'Object Oriented Software Design', 3, 'Design of a computer program using an ObjectOriented programming language. Extension of programming knowledge from a procedural language to an object-oriented language. Analysis of program requirements.', 3000),
    ('COP', '3353', 'User-Level Introduction to Linux for IT', 3, 'Description Introduction to a modern Linux distribution; installation in a desktop-friendly virtualized environment, users and software packages management, usage of the shell for navigation, and text processing command line tools.', 3000),
    ('COP', '3514', 'Program Design', 3, 'The class extends students'' programming knowledge by systematically considering the concepts involved in program design and creation. Students will also build upon their previous programming experience by learning to use the C programming language in a networked environment.', 3000),
    ('COP', '3515', 'Advanced Program Design for Information Technology', 3, 'Covers problem solving with an emphasis on the creation of programs to be developed and maintained in a variety of environments from small to large IT organizations. Concepts relating to program efficiency are studied.', 3000),
    ('COP', '3718', 'Database Systems Design', 3, 'This course provides an in-depth treatment of working with Relational Database Management System (DBMS), with particular reference to MySQL. It also shows how to interface with MySQL using both PHP and Java languages.', 3000),
    ('COP', '4020', 'Programming Languages', 3, 'An introduction to the specification, design, and analysis of programming languages. Topics include syntax, operational semantics, type systems, type safety, lambda calculus, functional programming, polymorphism, side effects, and objects.', 4000),
    ('COP', '4365', 'Software System Development', 3, 'Analysis, design, and development of software systems using objective methodology with object oriented programming and advanced software development tools (such as integrated development environments).', 4000),
    ('COP', '4368', 'Adv Object-Oriented Programming for IT', 3, 'Advanced object-oriented programming techniques and applications. Topics include GUI design, visual objects, event handling, data validation, interfaces, database connection, etc.', 4000),
    ('COP', '4520', 'Computing in Massively Parallel Systems', 3, 'This course will cover basics in large-scale parallel computing and CUDA programming, and advanced techniques for parallel code optimization and domain-specific case studies.', 4000),
    ('COP', '4530', 'Data Structures', 3, 'Understand and implement fundamentals of concise data structure and organization for program efficiency, clarity and simplification. Implementation of different data types and structures. Understanding of current data structures. Functional programming concepts will be covered.', 4000),
    ('COP', '4538', 'Data Structures and Algorithms for Information Technology', 3, 'Formalizes the concepts of algorithm and time complexity. Data structures such as heaps, lists, queues, stacks, and various forms of trees are covered. Students design and analyze algorithms. Numerous classic algorithms are covered.', 4000),
    ('COP', '4564', 'Application Maintenance & Debugging for IT', 3, 'Addresses the software-development cycle and code maintenance, as well as software correctness. Various code testing strategies and debugging methods are presented along with tools for software maintenance and debugging.', 4000),
    ('COP', '4600', 'Operating Systems', 3, 'Introduction to systems programming. Design of operating systems. Concurrent processing, synchronization, and storage management policies.', 4000),
    ('COP', '4620', 'Compilers', 3, 'Introduction to techniques for compiling software; lexical, syntactic, and semantic analyses; abstract syntax trees; symbol tables; code generation and optimization.', 4000),
    ('COP', '4656', 'Software Development for Mobile Devices', 3, 'This course covers software development for mobile devices, mainly cellular phones. The primary goal of the course is to teach students how to design, develop, and deploy complete market-ready applications for mobile devices.', 4000),
    ('COP', '4703', 'Advanced Database Systems for Information Technology', 3, 'Database management systems are presented, covering relational, CODASYL, network, hierarchical, and object-oriented models. Backups and database server admin are covered. Best practices for information management are covered.', 4000),
    ('COP', '4710', 'Database Design', 3, 'This course covers the fundamentals and applications of database management systems, including data models, relational database design, query languages, and web-based database applications.', 4000),
    ('COP', '4883', 'Java Programming for Information Technology', 3, 'This course covers object-oriented programming in Java and Java foundation classes. Topics include classes, inheritance, interfaces, graphical user interfaces (GUIs), event-driven programming, exception handling, and networking.', 4000),
    ('COP', '4900', 'Independent Study in Information Technology', 1-5, 'Specialized independent study determined by the needs and interests of the student.', 4000),
    ('COP', '4931', 'Special Topics for Information Technology', 3, 'Topics to be chosen by students and instructor permitting newly developing sub-disciplinary special interests to be explored.', 4000),
    ('COT', '3100', 'Introduction to Discrete Structures', 3, 'Introduction to set algebra, propositional calculus and finite algebraic structures as they apply to computer systems.', 3000),
    ('COT', '4210', 'Automata Theory and Formal Languages', 3, 'Introduction to the theory and application of various types of computing devices and the languages they recognize.', 4000),
    ('COT', '4400', 'Analysis of Algorithms', 3, 'Design principles and analysis techniques applicable to various classes of computer algorithms frequently used in practice.', 4000),
    ('COT', '4521', 'Computational Geometry', 3, 'Computational geometry is the study of efficient algorithms to solve geometric problems. Topics covered include Polygonal Triangulations, Polygon Partitioning, Convex Hulls, Voronoi Diagrams, Arrangements, Search and Intersection, and Motion Planning.', 4000),
    ('COT', '4601', 'Quantum Computing and Quantum Algorithms', 3, 'Introduction to and survey of quantum computing. Theory of qubits and quantum computation are studied including entanglement, superdense coding, quantum teleportation, and current topics. Students will also program simulated and real quantum computers.', 4000),
    ('CTS', '4337', 'Linux Workstations System Administration for IT', 3, 'Students learn to install, configure, tune, and administer a Linux system. Administration focuses on managing user accounts, file systems, and processes. System commands are presented and students learn to write basic scripts.', 4000),
    ('ECO', '2013', 'Economic Principles (Macroeconomics)', 3, 'ECO 2013 introduces students to basic economic terminology, definitions and measurements of macroeconomic data, simple macroeconomic models, fiscal and monetary policy, and international macroeconomic linkages.', 2000),
    ('EDG', '3801', 'Cybersecurity and the Everyday Citizen', 3, 'This course explores the human side of cybersecurity in a globally connected world. We will focus on personal, social and policy issues as well as address strategies to secure our digital footprints and promote safe interactions.', 3000),
    ('EEE', '3394', 'Electrical Engineering Science I - Electronic Materials', 3, 'This course provides electrical and computer engineering students with a strong background in material science and quantum physics as they relate to electrical/electronic material and device properties and applications.', 3000),
    ('EGN', '3000', 'Foundations of Engineering', 0-3, 'Introduction to the USF College of Engineering disciplines and the engineering profession. Course will provide you with knowledge of resources to help you succeed. Course topics include academic policies and procedures, study skills, and career planning.', 3000),
    ('EGN', '3000L', 'Foundations of Engineering Lab ', 3, 'Introduction to Engineering and its disciplines incorporating examples of tools and techniques used in design and presentation. Laboratory exercises will include computer tools, engineering design, team projects, and oral and written communication skills.', 3000),
    ('EGN', '3373', 'Electrical Systems I', 3, 'A first course in electrical systems: AC/DC circuit analysis, electronics (diodes, transistors, operational amplifiers), digital circuits (logic gates, K-maps), control systems concepts (final value theorem), electrical safety, and AC power.', 3000),
    ('EGN', '3433', 'Modeling and Analysis of Engineering Systems', 3, 'Dynamic analysis of electrical, mechanical, hydraulic and thermal systems; Laplace transforms; numerical methods; use of computers in dynamic systems; analytical solution to first and second order ODEs. Restricted to majors.', 3000),
    ('EGN', '3443', 'Probability and Statistics for Engineers', 3, 'An introduction to concepts of probability and statistical analysis with special emphasis on critical interpretation of data, comparing and contrasting claims, critical thinking, problem solving, and writing.', 3000),
    ('EGN', '3615', 'Engineering Economics with Social and Global Implications', 3, 'Presents basic economic models used to evaluate engineering project investments with an understanding of the implications of human and cultural diversity on financial decisions through lectures, problem solving, and critical writing.', 3000),
    ('EGN', '4450', 'Introduction to Linear Systems', 2, 'Study and application of matrix algebra, differential equations and calculus of finite differences.', 4000),
    ('ENC', '1101', 'Composition I', 3, 'This course helps prepare students for academic work by emphasizing expository writing, the basics of library research, and the conventions of academic discourse.', 1000),
    ('ENC', '1102', 'Composition II', 3, 'This course emphasizes argument, research, and style. As students engage in creative and critical thinking, they learn to support assertions based on audience and purpose; students apply library research, strategies for revision, and peer response.', 1000),
    ('ENC', '3246', 'Communication for Engineers', 3, 'Focuses on writing concerns of engineers. Deals with the content, organization, format, and style of specific types of engineering documents. Provides opportunity to improve oral presentations.', 3000),
    ('ESC', '2000', 'Introduction to Earth Science', 3, 'An introductory course in the Earth Sciences. Topics covered include geology, weather, climate change, ocean dynamics, and the history of the Earth, the solar system and beyond', 2000),
    ('EVR', '2001', 'Introduction to Environmental Science', 3, 'An introductory lecture course linking the human and physical/biological world. The course will develop an understanding of population and resource interactions.', 2000),
    ('HUM', '1020', 'Introduction to Humanities', 3, 'Analysis of selected works of literature, music, film, and visual art, representing artists of diverse periods, cultures, genders, and races. Especially recommended for students who later take 4000-level Humanities courses.', 1000),
    ('INR', '3033', 'International Political Cultures', 3, 'This course will explore ways in which culture influences the nature of government, economic success or failure, and constructive and destructive modes of self and social identification.', 3000),
    ('ISM', '3011', 'Information Systems in Organizations', 3, 'An introduction to the language, concepts, structures and processes involved in the management of information systems including fundamentals of computer-based technology and the use of businessbased software for support of managerial decisions.', 3000),
    ('ISM', '4041', 'Global Cyber Ethics', 3, 'This course provides students an in-depth look at the social costs and moral problems that have arisen by the expanded use of the Internet, and offers up-todate legal and philosophical perspectives on the global scale for the business community.', 4000),
    ('ISM', '4323', 'Information Security and IT Risk Management', 3, 'Senior standing, all majors. Introduction to information security and IT risk management in organizations. Covers essential IT general controls and frameworks to assess IT risk in a business environment.', 4000),
    ('LIS', '4414', 'Information Policy and Ethics', 3, 'Examines issues related to information and cybersecurity technology development and use in a global society. Topics include governmental regulations, policy and ethical perspectives related to information literacy, access, security and the digital divide.', 4000),
    ('LIS', '4779', 'Health Information Security', 3, 'Examines soft and technological threats to protected heath information and methods for reducing these threats with a focus on HIPAA compliance.', 4000),
    ('LIT', '2000', 'Introduction to Literature', 3, 'This course will introduce students to the three major literary forms of prose, poetry and drama as well as to various "schools" of literary criticism.', 2000),
    ('MAC', '1105', 'College Algebra', 3, 'Concepts of the real number system, functions, graphs, and complex numbers. Analytic skills for solving linear, quadratic, polynomial, exponential, and logarithmic equations. Mathematical modeling of real life applications. College Algebra may be taken either for General Education credit or as preparation for a pre-calculus course.', 1000),
    ('MAC', '1147', 'Precalculus Algebra and Trigonometry', 4, 'This is an accelerated combination of MAC 1140 and MAC 1114 ; this course is best for students who have already seen some trigonometry. See the descriptions of MAC 1140 and MAC 1114 .', 1000),
    ('MAC', '2281', 'Engineering Calculus I', 4, 'Differentiation, limits, differentials, extremes, indefinite integral. No credit for mathematics majors.', 2000),
    ('MAC', '2282', 'Engineering Calculus II', 4, 'Definite integral, trigonometric functions, log, exponential, series, applications.', 2000),
    ('MAC', '2283', 'Engineering Calculus III', 4, 'Techniques of integration, numerical methods, analytic geometry, polar coordinates, Vector algebra, applications.', 2000),
    ('MAC', '2311', 'Calculus I', 4, 'Differentiation, limits, differentials, extremes, indefinite integral.', 2000),
    ('MAC', '2312', 'Calculus II', 4, 'Antiderivatives, the definite integral, applications, series, log, exponential and trig functions.', 2000),
    ('MAC', '2313', 'Calculus III', 4, 'Integration, polar coordinates, conic sections, vectors, indeterminate forms and proper integrals.', 2000),
    ('MAD', '2104', 'Discrete Mathematics', 3, 'This course covers set theory, logic, proofs, counting techniques, and graph theory.', 2000),
    ('MAP', '2302', 'Differential Equations', 3, 'First order linear and nonlinear differential equations, higher order linear equations, applications.', 2000),
    ('MAT', '1033', 'Intermediate Algebra', 3, 'This course provides students with an opportunity to develop algebraic knowledge needed for further study in several fields such as engineering, business, science, computer technology, and mathematics.', 1000),
    ('MGF', '1106', 'Finite Mathematics', 3, 'Concepts and analytical skills in areas of logic, linear equations, linear programming, mathematics of finance, permutations and combinations, probability, and descriptive statistics.', 1000),
    ('MGF', '1107', 'Mathematics for Liberal Arts', 3, 'This terminal course is intended to present topics which demonstrate the beauty and utility of mathematics to the general student population. Among the topics which might be included are: Financial Mathematics, Linear and Exponential Growth, Numbers and Number Systems, Elementary Number Theory, Voting Techniques, Graph Theory, and the History of Mathematics.', 1000),
    ('MUL', '2010', 'Music and Culture', 3, 'This course is intended to expose students to a variety of music and musical experiences through lecture, discussion, and direct experience involving critical listening. Students will enhance their awareness of the various elements, origins, and developments in music, as well as enrich critical thinking skills related to evaluating music. Students will prepare critiques of music performances in writing. By the end of the course, the student should have the background for appreciating the major genres of music, as well as having an enhanced ability to appreciate the various primary elements of any musical creation and /or performance.', 2000),
    ('PHI', '2010', 'Introduction to Philosophy', 3, 'An introduction to several major themes in philosophy, as well as central philosophical concepts, texts, and methods.', 2000),
    ('PHY', '2020', 'Conceptual Physics', 3, 'A qualitative investigation of physics concepts. Emphasis is placed on using physics to describe how common things work. No previous physics knowledge required.', 2000),
    ('PHY', '2048', 'General Physics I - Calculus Based', 3, 'First semester of a two-semester sequence of calculus-based General Physics which includes a study of mechanics, wave motion, sound, thermodynamics, geometrical and physical optics, electricity and magnetism for students majoring in Physics, Chemistry and Engineering.', 2000),
    ('PHY', '2048L', 'General Physics I Laboratory ', 1, 'First semester of a two-semester sequence of general physics (mechanics, wave motion, sound, thermodynamics, geometrical and physical optics, electricity, and magnetism) and laboratory for physics majors and engineering students.', 2000),
    ('PHY', '2049', 'General Physics II - Calculus Based', 3, 'Second semester of calculus based general physics. Topics studied include wave mechanics, electricity and magnetism, and optics.', 2000),
    ('PHY', '2049L', 'General Physics II Laboratory ', 1, 'Second semester of general physics and laboratory for physics majors and engineering students.', 2000),
    ('PHY', '2053', 'General Physics I', 3, 'First semester of a two semester sequence of noncalculus-based general physics (mechanics, heat, wave motion, sound, electricity, magnetism, optics, modern physics) for science students.', 2000),
    ('PHY', '2053L', 'General Physics I Laboratory ', 1, 'First semester of a two semester sequence of general physics (mechanics, heat, wave motion, sound, electricity, magnetism, optics, modern physics) laboratory for science students.', 2000),
    ('PHY', '2060', 'Enriched General Physics I with Calculus', 3, 'First semester of an enriched sequence of calculus based general physics designed for physics majors and other students seeking a deeper understanding of mechanics, kinematics, conservation laws, central forces, harmonic motion, and mechanical waves.', 2000),
    ('POS', '2041', 'American National Government', 3, 'This course is intended to introduce students to the theory, institutions, and processes of American government and politics. In addition to learning fundamental information about the American political system, this course is designed to help students think critically about American government and politics.', 2000),
    ('PSY', '2012', 'Introduction to Psychological Science', 3, 'This course is an introduction to psychology for majors and nonmajors. It presents psychological theory and methods in a survey of various areas of psychology including clinical, cognitive, developmental, health, industrial, social and biopsychology.', 2000),
    ('STA', '2023', 'Introductory Statistics I', 3, 'Descriptive and Inferential Statistics; Principles of Probability Theory, Discrete and Continuous Probability Distributions: Binomial Probability Distribution, Poisson Probability Distribution, Uniform Probability Distribution, Normal Dist and more.', 2000),
    ('SYG', '2000', 'Principles of Sociology', 3, 'This course introduces undergraduate students to the discipline of sociology. During the semester, we will analyze sociological theories, core concepts, and issues through readings, lectures, discussions, films, and hands-on research assignments.', 2000),
    ('THE', '2000', 'Theater and Culture', 3, 'This course explores the contributions of theater practitioners and audiences to the performance experience, aspects of theater making and an overview of theater history.', 2000),
    ('XXX', 'ELECTIVE', 'Elective', 3, 'Placeholder elective', 1000);

SELECT @COURSE_AMH_2020  = CourseID FROM Bellini.Course WHERE CoursePrefix = 'AMH' AND CourseNumber = '2020';
SELECT @COURSE_ANT_2000  = CourseID FROM Bellini.Course WHERE CoursePrefix = 'ANT' AND CourseNumber = '2000';
SELECT @COURSE_ARH_2000  = CourseID FROM Bellini.Course WHERE CoursePrefix = 'ARH' AND CourseNumber = '2000';
SELECT @COURSE_AST_2002  = CourseID FROM Bellini.Course WHERE CoursePrefix = 'AST' AND CourseNumber = '2002';
SELECT @COURSE_BSC_1005  = CourseID FROM Bellini.Course WHERE CoursePrefix = 'BSC' AND CourseNumber = '1005';
SELECT @COURSE_BSC_2010  = CourseID FROM Bellini.Course WHERE CoursePrefix = 'BSC' AND CourseNumber = '2010';
SELECT @COURSE_BSC_2010L = CourseID FROM Bellini.Course WHERE CoursePrefix = 'BSC' AND CourseNumber = '2010L';
SELECT @COURSE_BSC_2085  = CourseID FROM Bellini.Course WHERE CoursePrefix = 'BSC' AND CourseNumber = '2085';
SELECT @COURSE_BSC_2085L = CourseID FROM Bellini.Course WHERE CoursePrefix = 'BSC' AND CourseNumber = '2085L';
SELECT @COURSE_CAP_4034  = CourseID FROM Bellini.Course WHERE CoursePrefix = 'CAP' AND CourseNumber = '4034';
SELECT @COURSE_CAP_4063  = CourseID FROM Bellini.Course WHERE CoursePrefix = 'CAP' AND CourseNumber = '4063';
SELECT @COURSE_CAP_4103  = CourseID FROM Bellini.Course WHERE CoursePrefix = 'CAP' AND CourseNumber = '4103';
SELECT @COURSE_CAP_4111  = CourseID FROM Bellini.Course WHERE CoursePrefix = 'CAP' AND CourseNumber = '4111';
SELECT @COURSE_CAP_4136  = CourseID FROM Bellini.Course WHERE CoursePrefix = 'CAP' AND CourseNumber = '4136';
SELECT @COURSE_CAP_4160  = CourseID FROM Bellini.Course WHERE CoursePrefix = 'CAP' AND CourseNumber = '4160';
SELECT @COURSE_CAP_4401  = CourseID FROM Bellini.Course WHERE CoursePrefix = 'CAP' AND CourseNumber = '4401';
SELECT @COURSE_CAP_4410  = CourseID FROM Bellini.Course WHERE CoursePrefix = 'CAP' AND CourseNumber = '4410';
SELECT @COURSE_CAP_4621  = CourseID FROM Bellini.Course WHERE CoursePrefix = 'CAP' AND CourseNumber = '4621';
SELECT @COURSE_CAP_4628  = CourseID FROM Bellini.Course WHERE CoursePrefix = 'CAP' AND CourseNumber = '4628';
SELECT @COURSE_CAP_4637  = CourseID FROM Bellini.Course WHERE CoursePrefix = 'CAP' AND CourseNumber = '4637';
SELECT @COURSE_CAP_4641  = CourseID FROM Bellini.Course WHERE CoursePrefix = 'CAP' AND CourseNumber = '4641';
SELECT @COURSE_CAP_4662  = CourseID FROM Bellini.Course WHERE CoursePrefix = 'CAP' AND CourseNumber = '4662';
SELECT @COURSE_CAP_4744  = CourseID FROM Bellini.Course WHERE CoursePrefix = 'CAP' AND CourseNumber = '4744';
SELECT @COURSE_CAP_4773  = CourseID FROM Bellini.Course WHERE CoursePrefix = 'CAP' AND CourseNumber = '4773';
SELECT @COURSE_CDA_3103  = CourseID FROM Bellini.Course WHERE CoursePrefix = 'CDA' AND CourseNumber = '3103';
SELECT @COURSE_CDA_3201  = CourseID FROM Bellini.Course WHERE CoursePrefix = 'CDA' AND CourseNumber = '3201';
SELECT @COURSE_CDA_3201L = CourseID FROM Bellini.Course WHERE CoursePrefix = 'CDA' AND CourseNumber = '3201L';
SELECT @COURSE_CDA_4203  = CourseID FROM Bellini.Course WHERE CoursePrefix = 'CDA' AND CourseNumber = '4203';
SELECT @COURSE_CDA_4203L = CourseID FROM Bellini.Course WHERE CoursePrefix = 'CDA' AND CourseNumber = '4203L';
SELECT @COURSE_CDA_4205  = CourseID FROM Bellini.Course WHERE CoursePrefix = 'CDA' AND CourseNumber = '4205';
SELECT @COURSE_CDA_4205L = CourseID FROM Bellini.Course WHERE CoursePrefix = 'CDA' AND CourseNumber = '4205L';
SELECT @COURSE_CDA_4213  = CourseID FROM Bellini.Course WHERE CoursePrefix = 'CDA' AND CourseNumber = '4213';
SELECT @COURSE_CDA_4213L = CourseID FROM Bellini.Course WHERE CoursePrefix = 'CDA' AND CourseNumber = '4213L';
SELECT @COURSE_CDA_4253  = CourseID FROM Bellini.Course WHERE CoursePrefix = 'CDA' AND CourseNumber = '4253';
SELECT @COURSE_CDA_4321  = CourseID FROM Bellini.Course WHERE CoursePrefix = 'CDA' AND CourseNumber = '4321';
SELECT @COURSE_CDA_4322  = CourseID FROM Bellini.Course WHERE CoursePrefix = 'CDA' AND CourseNumber = '4322';
SELECT @COURSE_CDA_4323  = CourseID FROM Bellini.Course WHERE CoursePrefix = 'CDA' AND CourseNumber = '4323';
SELECT @COURSE_CDA_4621  = CourseID FROM Bellini.Course WHERE CoursePrefix = 'CDA' AND CourseNumber = '4621';
SELECT @COURSE_CEN_3722  = CourseID FROM Bellini.Course WHERE CoursePrefix = 'CEN' AND CourseNumber = '3722';
SELECT @COURSE_CEN_4020  = CourseID FROM Bellini.Course WHERE CoursePrefix = 'CEN' AND CourseNumber = '4020';
SELECT @COURSE_CEN_4072  = CourseID FROM Bellini.Course WHERE CoursePrefix = 'CEN' AND CourseNumber = '4072';
SELECT @COURSE_CEN_4360  = CourseID FROM Bellini.Course WHERE CoursePrefix = 'CEN' AND CourseNumber = '4360';
SELECT @COURSE_CGS_1540  = CourseID FROM Bellini.Course WHERE CoursePrefix = 'CGS' AND CourseNumber = '1540';
SELECT @COURSE_CGS_2100  = CourseID FROM Bellini.Course WHERE CoursePrefix = 'CGS' AND CourseNumber = '2100';
SELECT @COURSE_CGS_3303  = CourseID FROM Bellini.Course WHERE CoursePrefix = 'CGS' AND CourseNumber = '3303';
SELECT @COURSE_CGS_3853  = CourseID FROM Bellini.Course WHERE CoursePrefix = 'CGS' AND CourseNumber = '3853';
SELECT @COURSE_CHM_2020  = CourseID FROM Bellini.Course WHERE CoursePrefix = 'CHM' AND CourseNumber = '2020';
SELECT @COURSE_CHM_2045  = CourseID FROM Bellini.Course WHERE CoursePrefix = 'CHM' AND CourseNumber = '2045';
SELECT @COURSE_CHM_2045L = CourseID FROM Bellini.Course WHERE CoursePrefix = 'CHM' AND CourseNumber = '2045L';
SELECT @COURSE_CHS_2440  = CourseID FROM Bellini.Course WHERE CoursePrefix = 'CHS' AND CourseNumber = '2440';
SELECT @COURSE_CHS_2440L = CourseID FROM Bellini.Course WHERE CoursePrefix = 'CHS' AND CourseNumber = '2440L';
SELECT @COURSE_CIS_3213  = CourseID FROM Bellini.Course WHERE CoursePrefix = 'CIS' AND CourseNumber = '3213';
SELECT @COURSE_CIS_3360  = CourseID FROM Bellini.Course WHERE CoursePrefix = 'CIS' AND CourseNumber = '3360';
SELECT @COURSE_CIS_3362  = CourseID FROM Bellini.Course WHERE CoursePrefix = 'CIS' AND CourseNumber = '3362';
SELECT @COURSE_CIS_3363  = CourseID FROM Bellini.Course WHERE CoursePrefix = 'CIS' AND CourseNumber = '3363';
SELECT @COURSE_CIS_3433  = CourseID FROM Bellini.Course WHERE CoursePrefix = 'CIS' AND CourseNumber = '3433';
SELECT @COURSE_CIS_4083  = CourseID FROM Bellini.Course WHERE CoursePrefix = 'CIS' AND CourseNumber = '4083';
SELECT @COURSE_CIS_4200  = CourseID FROM Bellini.Course WHERE CoursePrefix = 'CIS' AND CourseNumber = '4200';
SELECT @COURSE_CIS_4203  = CourseID FROM Bellini.Course WHERE CoursePrefix = 'CIS' AND CourseNumber = '4203';
SELECT @COURSE_CIS_4212  = CourseID FROM Bellini.Course WHERE CoursePrefix = 'CIS' AND CourseNumber = '4212';
SELECT @COURSE_CIS_4219  = CourseID FROM Bellini.Course WHERE CoursePrefix = 'CIS' AND CourseNumber = '4219';
SELECT @COURSE_CIS_4250  = CourseID FROM Bellini.Course WHERE CoursePrefix = 'CIS' AND CourseNumber = '4250';
SELECT @COURSE_CIS_4253  = CourseID FROM Bellini.Course WHERE CoursePrefix = 'CIS' AND CourseNumber = '4253';
SELECT @COURSE_CIS_4345  = CourseID FROM Bellini.Course WHERE CoursePrefix = 'CIS' AND CourseNumber = '4345';
SELECT @COURSE_CIS_4361  = CourseID FROM Bellini.Course WHERE CoursePrefix = 'CIS' AND CourseNumber = '4361';
SELECT @COURSE_CIS_4364  = CourseID FROM Bellini.Course WHERE CoursePrefix = 'CIS' AND CourseNumber = '4364';
SELECT @COURSE_CIS_4368  = CourseID FROM Bellini.Course WHERE CoursePrefix = 'CIS' AND CourseNumber = '4368';
SELECT @COURSE_CIS_4622  = CourseID FROM Bellini.Course WHERE CoursePrefix = 'CIS' AND CourseNumber = '4622';
SELECT @COURSE_CIS_4623  = CourseID FROM Bellini.Course WHERE CoursePrefix = 'CIS' AND CourseNumber = '4623';
SELECT @COURSE_CIS_4900  = CourseID FROM Bellini.Course WHERE CoursePrefix = 'CIS' AND CourseNumber = '4900';
SELECT @COURSE_CIS_4910  = CourseID FROM Bellini.Course WHERE CoursePrefix = 'CIS' AND CourseNumber = '4910';
SELECT @COURSE_CIS_4915  = CourseID FROM Bellini.Course WHERE CoursePrefix = 'CIS' AND CourseNumber = '4915';
SELECT @COURSE_CIS_4930  = CourseID FROM Bellini.Course WHERE CoursePrefix = 'CIS' AND CourseNumber = '4930';
SELECT @COURSE_CIS_4935  = CourseID FROM Bellini.Course WHERE CoursePrefix = 'CIS' AND CourseNumber = '4935';
SELECT @COURSE_CIS_4940  = CourseID FROM Bellini.Course WHERE CoursePrefix = 'CIS' AND CourseNumber = '4940';
SELECT @COURSE_CIS_4947  = CourseID FROM Bellini.Course WHERE CoursePrefix = 'CIS' AND CourseNumber = '4947';
SELECT @COURSE_CNT_4004  = CourseID FROM Bellini.Course WHERE CoursePrefix = 'CNT' AND CourseNumber = '4004';
SELECT @COURSE_CNT_4104  = CourseID FROM Bellini.Course WHERE CoursePrefix = 'CNT' AND CourseNumber = '4104';
SELECT @COURSE_CNT_4104L = CourseID FROM Bellini.Course WHERE CoursePrefix = 'CNT' AND CourseNumber = '4104L';
SELECT @COURSE_CNT_4403  = CourseID FROM Bellini.Course WHERE CoursePrefix = 'CNT' AND CourseNumber = '4403';
SELECT @COURSE_CNT_4411  = CourseID FROM Bellini.Course WHERE CoursePrefix = 'CNT' AND CourseNumber = '4411';
SELECT @COURSE_CNT_4419  = CourseID FROM Bellini.Course WHERE CoursePrefix = 'CNT' AND CourseNumber = '4419';
SELECT @COURSE_CNT_4603  = CourseID FROM Bellini.Course WHERE CoursePrefix = 'CNT' AND CourseNumber = '4603';
SELECT @COURSE_CNT_4716C = CourseID FROM Bellini.Course WHERE CoursePrefix = 'CNT' AND CourseNumber = '4716C';
SELECT @COURSE_CNT_4800  = CourseID FROM Bellini.Course WHERE CoursePrefix = 'CNT' AND CourseNumber = '4800';
SELECT @COURSE_COP_2030  = CourseID FROM Bellini.Course WHERE CoursePrefix = 'COP' AND CourseNumber = '2030';
SELECT @COURSE_COP_2510  = CourseID FROM Bellini.Course WHERE CoursePrefix = 'COP' AND CourseNumber = '2510';
SELECT @COURSE_COP_2512  = CourseID FROM Bellini.Course WHERE CoursePrefix = 'COP' AND CourseNumber = '2512';
SELECT @COURSE_COP_2513  = CourseID FROM Bellini.Course WHERE CoursePrefix = 'COP' AND CourseNumber = '2513';
SELECT @COURSE_COP_2700  = CourseID FROM Bellini.Course WHERE CoursePrefix = 'COP' AND CourseNumber = '2700';
SELECT @COURSE_COP_3331  = CourseID FROM Bellini.Course WHERE CoursePrefix = 'COP' AND CourseNumber = '3331';
SELECT @COURSE_COP_3353  = CourseID FROM Bellini.Course WHERE CoursePrefix = 'COP' AND CourseNumber = '3353';
SELECT @COURSE_COP_3514  = CourseID FROM Bellini.Course WHERE CoursePrefix = 'COP' AND CourseNumber = '3514';
SELECT @COURSE_COP_3515  = CourseID FROM Bellini.Course WHERE CoursePrefix = 'COP' AND CourseNumber = '3515';
SELECT @COURSE_COP_3718  = CourseID FROM Bellini.Course WHERE CoursePrefix = 'COP' AND CourseNumber = '3718';
SELECT @COURSE_COP_4020  = CourseID FROM Bellini.Course WHERE CoursePrefix = 'COP' AND CourseNumber = '4020';
SELECT @COURSE_COP_4365  = CourseID FROM Bellini.Course WHERE CoursePrefix = 'COP' AND CourseNumber = '4365';
SELECT @COURSE_COP_4368  = CourseID FROM Bellini.Course WHERE CoursePrefix = 'COP' AND CourseNumber = '4368';
SELECT @COURSE_COP_4520  = CourseID FROM Bellini.Course WHERE CoursePrefix = 'COP' AND CourseNumber = '4520';
SELECT @COURSE_COP_4530  = CourseID FROM Bellini.Course WHERE CoursePrefix = 'COP' AND CourseNumber = '4530';
SELECT @COURSE_COP_4538  = CourseID FROM Bellini.Course WHERE CoursePrefix = 'COP' AND CourseNumber = '4538';
SELECT @COURSE_COP_4564  = CourseID FROM Bellini.Course WHERE CoursePrefix = 'COP' AND CourseNumber = '4564';
SELECT @COURSE_COP_4600  = CourseID FROM Bellini.Course WHERE CoursePrefix = 'COP' AND CourseNumber = '4600';
SELECT @COURSE_COP_4620  = CourseID FROM Bellini.Course WHERE CoursePrefix = 'COP' AND CourseNumber = '4620';
SELECT @COURSE_COP_4656  = CourseID FROM Bellini.Course WHERE CoursePrefix = 'COP' AND CourseNumber = '4656';
SELECT @COURSE_COP_4703  = CourseID FROM Bellini.Course WHERE CoursePrefix = 'COP' AND CourseNumber = '4703';
SELECT @COURSE_COP_4710  = CourseID FROM Bellini.Course WHERE CoursePrefix = 'COP' AND CourseNumber = '4710';
SELECT @COURSE_COP_4883  = CourseID FROM Bellini.Course WHERE CoursePrefix = 'COP' AND CourseNumber = '4883';
SELECT @COURSE_COP_4900  = CourseID FROM Bellini.Course WHERE CoursePrefix = 'COP' AND CourseNumber = '4900';
SELECT @COURSE_COP_4931  = CourseID FROM Bellini.Course WHERE CoursePrefix = 'COP' AND CourseNumber = '4931';
SELECT @COURSE_COT_3100  = CourseID FROM Bellini.Course WHERE CoursePrefix = 'COT' AND CourseNumber = '3100';
SELECT @COURSE_COT_4210  = CourseID FROM Bellini.Course WHERE CoursePrefix = 'COT' AND CourseNumber = '4210';
SELECT @COURSE_COT_4400  = CourseID FROM Bellini.Course WHERE CoursePrefix = 'COT' AND CourseNumber = '4400';
SELECT @COURSE_COT_4521  = CourseID FROM Bellini.Course WHERE CoursePrefix = 'COT' AND CourseNumber = '4521';
SELECT @COURSE_COT_4601  = CourseID FROM Bellini.Course WHERE CoursePrefix = 'COT' AND CourseNumber = '4601';
SELECT @COURSE_CTS_4337  = CourseID FROM Bellini.Course WHERE CoursePrefix = 'CTS' AND CourseNumber = '4337';
SELECT @COURSE_ECO_2013  = CourseID FROM Bellini.Course WHERE CoursePrefix = 'ECO' AND CourseNumber = '2013';
SELECT @COURSE_EDG_3801  = CourseID FROM Bellini.Course WHERE CoursePrefix = 'EDG' AND CourseNumber = '3801';
SELECT @COURSE_EEE_3394  = CourseID FROM Bellini.Course WHERE CoursePrefix = 'EEE' AND CourseNumber = '3394';
SELECT @COURSE_EGN_3000  = CourseID FROM Bellini.Course WHERE CoursePrefix = 'EGN' AND CourseNumber = '3000';
SELECT @COURSE_EGN_3000L = CourseID FROM Bellini.Course WHERE CoursePrefix = 'EGN' AND CourseNumber = '3000L';
SELECT @COURSE_EGN_3373  = CourseID FROM Bellini.Course WHERE CoursePrefix = 'EGN' AND CourseNumber = '3373';
SELECT @COURSE_EGN_3433  = CourseID FROM Bellini.Course WHERE CoursePrefix = 'EGN' AND CourseNumber = '3433';
SELECT @COURSE_EGN_3443  = CourseID FROM Bellini.Course WHERE CoursePrefix = 'EGN' AND CourseNumber = '3443';
SELECT @COURSE_EGN_3615  = CourseID FROM Bellini.Course WHERE CoursePrefix = 'EGN' AND CourseNumber = '3615';
SELECT @COURSE_EGN_4450  = CourseID FROM Bellini.Course WHERE CoursePrefix = 'EGN' AND CourseNumber = '4450';
SELECT @COURSE_ENC_1101  = CourseID FROM Bellini.Course WHERE CoursePrefix = 'ENC' AND CourseNumber = '1101';
SELECT @COURSE_ENC_1102  = CourseID FROM Bellini.Course WHERE CoursePrefix = 'ENC' AND CourseNumber = '1102';
SELECT @COURSE_ENC_3246  = CourseID FROM Bellini.Course WHERE CoursePrefix = 'ENC' AND CourseNumber = '3246';
SELECT @COURSE_ESC_2000  = CourseID FROM Bellini.Course WHERE CoursePrefix = 'ESC' AND CourseNumber = '2000';
SELECT @COURSE_EVR_2001  = CourseID FROM Bellini.Course WHERE CoursePrefix = 'EVR' AND CourseNumber = '2001';
SELECT @COURSE_HUM_1020  = CourseID FROM Bellini.Course WHERE CoursePrefix = 'HUM' AND CourseNumber = '1020';
SELECT @COURSE_INR_3033  = CourseID FROM Bellini.Course WHERE CoursePrefix = 'INR' AND CourseNumber = '3033';
SELECT @COURSE_ISM_3011  = CourseID FROM Bellini.Course WHERE CoursePrefix = 'ISM' AND CourseNumber = '3011';
SELECT @COURSE_ISM_4041  = CourseID FROM Bellini.Course WHERE CoursePrefix = 'ISM' AND CourseNumber = '4041';
SELECT @COURSE_ISM_4323  = CourseID FROM Bellini.Course WHERE CoursePrefix = 'ISM' AND CourseNumber = '4323';
SELECT @COURSE_LIS_4414  = CourseID FROM Bellini.Course WHERE CoursePrefix = 'LIS' AND CourseNumber = '4414';
SELECT @COURSE_LIS_4779  = CourseID FROM Bellini.Course WHERE CoursePrefix = 'LIS' AND CourseNumber = '4779';
SELECT @COURSE_LIT_2000  = CourseID FROM Bellini.Course WHERE CoursePrefix = 'LIT' AND CourseNumber = '2000';
SELECT @COURSE_MAC_1105  = CourseID FROM Bellini.Course WHERE CoursePrefix = 'MAC' AND CourseNumber = '1105';
SELECT @COURSE_MAC_1147  = CourseID FROM Bellini.Course WHERE CoursePrefix = 'MAC' AND CourseNumber = '1147';
SELECT @COURSE_MAC_2281  = CourseID FROM Bellini.Course WHERE CoursePrefix = 'MAC' AND CourseNumber = '2281';
SELECT @COURSE_MAC_2282  = CourseID FROM Bellini.Course WHERE CoursePrefix = 'MAC' AND CourseNumber = '2282';
SELECT @COURSE_MAC_2283  = CourseID FROM Bellini.Course WHERE CoursePrefix = 'MAC' AND CourseNumber = '2283';
SELECT @COURSE_MAC_2311  = CourseID FROM Bellini.Course WHERE CoursePrefix = 'MAC' AND CourseNumber = '2311';
SELECT @COURSE_MAC_2312  = CourseID FROM Bellini.Course WHERE CoursePrefix = 'MAC' AND CourseNumber = '2312';
SELECT @COURSE_MAC_2313  = CourseID FROM Bellini.Course WHERE CoursePrefix = 'MAC' AND CourseNumber = '2313';
SELECT @COURSE_MAD_2104  = CourseID FROM Bellini.Course WHERE CoursePrefix = 'MAD' AND CourseNumber = '2104';
SELECT @COURSE_MAP_2302  = CourseID FROM Bellini.Course WHERE CoursePrefix = 'MAP' AND CourseNumber = '2302';
SELECT @COURSE_MAT_1033  = CourseID FROM Bellini.Course WHERE CoursePrefix = 'MAT' AND CourseNumber = '1033';
SELECT @COURSE_MGF_1106  = CourseID FROM Bellini.Course WHERE CoursePrefix = 'MGF' AND CourseNumber = '1106';
SELECT @COURSE_MGF_1107  = CourseID FROM Bellini.Course WHERE CoursePrefix = 'MGF' AND CourseNumber = '1107';
SELECT @COURSE_MUL_2010  = CourseID FROM Bellini.Course WHERE CoursePrefix = 'MUL' AND CourseNumber = '2010';
SELECT @COURSE_PHI_2010  = CourseID FROM Bellini.Course WHERE CoursePrefix = 'PHI' AND CourseNumber = '2010';
SELECT @COURSE_PHY_2020  = CourseID FROM Bellini.Course WHERE CoursePrefix = 'PHY' AND CourseNumber = '2020';
SELECT @COURSE_PHY_2048  = CourseID FROM Bellini.Course WHERE CoursePrefix = 'PHY' AND CourseNumber = '2048';
SELECT @COURSE_PHY_2048L = CourseID FROM Bellini.Course WHERE CoursePrefix = 'PHY' AND CourseNumber = '2048L';
SELECT @COURSE_PHY_2049  = CourseID FROM Bellini.Course WHERE CoursePrefix = 'PHY' AND CourseNumber = '2049';
SELECT @COURSE_PHY_2049L = CourseID FROM Bellini.Course WHERE CoursePrefix = 'PHY' AND CourseNumber = '2049L';
SELECT @COURSE_PHY_2053  = CourseID FROM Bellini.Course WHERE CoursePrefix = 'PHY' AND CourseNumber = '2053';
SELECT @COURSE_PHY_2053L = CourseID FROM Bellini.Course WHERE CoursePrefix = 'PHY' AND CourseNumber = '2053L';
SELECT @COURSE_PHY_2060  = CourseID FROM Bellini.Course WHERE CoursePrefix = 'PHY' AND CourseNumber = '2060';
SELECT @COURSE_POS_2041  = CourseID FROM Bellini.Course WHERE CoursePrefix = 'POS' AND CourseNumber = '2041';
SELECT @COURSE_PSY_2012  = CourseID FROM Bellini.Course WHERE CoursePrefix = 'PSY' AND CourseNumber = '2012';
SELECT @COURSE_STA_2023  = CourseID FROM Bellini.Course WHERE CoursePrefix = 'STA' AND CourseNumber = '2023';
SELECT @COURSE_SYG_2000  = CourseID FROM Bellini.Course WHERE CoursePrefix = 'SYG' AND CourseNumber = '2000';
SELECT @COURSE_THE_2000  = CourseID FROM Bellini.Course WHERE CoursePrefix = 'THE' AND CourseNumber = '2000';
SELECT @COURSE_XXX_ELECTIVE = CourseID FROM Bellini.Course WHERE CoursePrefix = 'XXX' AND CourseNumber = 'ELECTIVE';


------------------------------------------------------------
-- Course Requirements
------------------------------------------------------------
-- BSCP core
INSERT INTO Bellini.CourseRequirement (MajorID, CourseID, CatalogID, RequirementType, MinGradeRequired)
VALUES
    -- 2022-2023
    (@MAJOR_BSCP, @COURSE_CDA_3103,  @CATALOG_2022_2023, 'BSCP Core', 'C'),
    (@MAJOR_BSCP, @COURSE_CDA_3201,  @CATALOG_2022_2023, 'BSCP Core', 'C'),
    (@MAJOR_BSCP, @COURSE_CDA_3201L, @CATALOG_2022_2023, 'BSCP Core', 'C'),
    (@MAJOR_BSCP, @COURSE_CDA_4203,  @CATALOG_2022_2023, 'BSCP Core', 'C'),
    (@MAJOR_BSCP, @COURSE_CDA_4203L, @CATALOG_2022_2023, 'BSCP Core', 'C'),
    (@MAJOR_BSCP, @COURSE_CDA_4205,  @CATALOG_2022_2023, 'BSCP Core', 'C'),
    (@MAJOR_BSCP, @COURSE_CDA_4205L, @CATALOG_2022_2023, 'BSCP Core', 'C'),
    (@MAJOR_BSCP, @COURSE_CDA_4213,  @CATALOG_2022_2023, 'BSCP Core', 'C'),
    (@MAJOR_BSCP, @COURSE_CDA_4213L, @CATALOG_2022_2023, 'BSCP Core', 'C'),
    (@MAJOR_BSCP, @COURSE_CIS_4250,  @CATALOG_2022_2023, 'BSCP Core', 'C'),
    (@MAJOR_BSCP, @COURSE_CIS_4910,  @CATALOG_2022_2023, 'BSCP Core', 'C'),
    (@MAJOR_BSCP, @COURSE_COP_2510,  @CATALOG_2022_2023, 'BSCP Core', 'C'),
    (@MAJOR_BSCP, @COURSE_COP_3514,  @CATALOG_2022_2023, 'BSCP Core', 'C'),
    (@MAJOR_BSCP, @COURSE_COP_4530,  @CATALOG_2022_2023, 'BSCP Core', 'C'),
    (@MAJOR_BSCP, @COURSE_COP_4600,  @CATALOG_2022_2023, 'BSCP Core', 'C'),
    (@MAJOR_BSCP, @COURSE_COT_3100,  @CATALOG_2022_2023, 'BSCP Core', 'C'),
    (@MAJOR_BSCP, @COURSE_COT_4400,  @CATALOG_2022_2023, 'BSCP Core', 'C'),
    (@MAJOR_BSCP, @COURSE_EEE_3394,  @CATALOG_2022_2023, 'BSCP Core', 'C'),
    (@MAJOR_BSCP, @COURSE_EGN_3000,  @CATALOG_2022_2023, 'BSCP Core', 'C'),
    (@MAJOR_BSCP, @COURSE_EGN_3000L, @CATALOG_2022_2023, 'BSCP Core', 'C'),
    (@MAJOR_BSCP, @COURSE_EGN_3373,  @CATALOG_2022_2023, 'BSCP Core', 'C'),
    (@MAJOR_BSCP, @COURSE_EGN_3443,  @CATALOG_2022_2023, 'BSCP Core', 'C'),
    (@MAJOR_BSCP, @COURSE_EGN_3615,  @CATALOG_2022_2023, 'BSCP Core', 'C'),
    (@MAJOR_BSCP, @COURSE_EGN_4450,  @CATALOG_2022_2023, 'BSCP Core', 'C'),
    (@MAJOR_BSCP, @COURSE_ENC_1101,  @CATALOG_2022_2023, 'BSCP Core', 'C'),
    (@MAJOR_BSCP, @COURSE_ENC_1102,  @CATALOG_2022_2023, 'BSCP Core', 'C'),
    (@MAJOR_BSCP, @COURSE_ENC_3246,  @CATALOG_2022_2023, 'BSCP Core', 'C'),
    (@MAJOR_BSCP, @COURSE_PHY_2048,  @CATALOG_2022_2023, 'BSCP Core', 'C'),
    (@MAJOR_BSCP, @COURSE_PHY_2048L, @CATALOG_2022_2023, 'BSCP Core', 'C'),
    (@MAJOR_BSCP, @COURSE_PHY_2049,  @CATALOG_2022_2023, 'BSCP Core', 'C'),
    (@MAJOR_BSCP, @COURSE_PHY_2049L, @CATALOG_2022_2023, 'BSCP Core', 'C'),
    -- 2023-2024
    (@MAJOR_BSCP, @COURSE_CDA_3103,  @CATALOG_2023_2024, 'BSCP Core', 'C'),
    (@MAJOR_BSCP, @COURSE_CDA_3201,  @CATALOG_2023_2024, 'BSCP Core', 'C'),
    (@MAJOR_BSCP, @COURSE_CDA_3201L, @CATALOG_2023_2024, 'BSCP Core', 'C'),
    (@MAJOR_BSCP, @COURSE_CDA_4203,  @CATALOG_2023_2024, 'BSCP Core', 'C'),
    (@MAJOR_BSCP, @COURSE_CDA_4203L, @CATALOG_2023_2024, 'BSCP Core', 'C'),
    (@MAJOR_BSCP, @COURSE_CDA_4205,  @CATALOG_2023_2024, 'BSCP Core', 'C'),
    (@MAJOR_BSCP, @COURSE_CDA_4205L, @CATALOG_2023_2024, 'BSCP Core', 'C'),
    (@MAJOR_BSCP, @COURSE_CDA_4213,  @CATALOG_2023_2024, 'BSCP Core', 'C'),
    (@MAJOR_BSCP, @COURSE_CDA_4213L, @CATALOG_2023_2024, 'BSCP Core', 'C'),
    (@MAJOR_BSCP, @COURSE_CIS_4250,  @CATALOG_2023_2024, 'BSCP Core', 'C'),
    (@MAJOR_BSCP, @COURSE_CIS_4910,  @CATALOG_2023_2024, 'BSCP Core', 'C'),
    (@MAJOR_BSCP, @COURSE_COP_2510,  @CATALOG_2023_2024, 'BSCP Core', 'C'),
    (@MAJOR_BSCP, @COURSE_COP_3514,  @CATALOG_2023_2024, 'BSCP Core', 'C'),
    (@MAJOR_BSCP, @COURSE_COP_4530,  @CATALOG_2023_2024, 'BSCP Core', 'C'),
    (@MAJOR_BSCP, @COURSE_COP_4600,  @CATALOG_2023_2024, 'BSCP Core', 'C'),
    (@MAJOR_BSCP, @COURSE_COT_3100,  @CATALOG_2023_2024, 'BSCP Core', 'C'),
    (@MAJOR_BSCP, @COURSE_COT_4400,  @CATALOG_2023_2024, 'BSCP Core', 'C'),
    (@MAJOR_BSCP, @COURSE_EEE_3394,  @CATALOG_2023_2024, 'BSCP Core', 'C'),
    (@MAJOR_BSCP, @COURSE_EGN_3000,  @CATALOG_2023_2024, 'BSCP Core', 'C'),
    (@MAJOR_BSCP, @COURSE_EGN_3000L, @CATALOG_2023_2024, 'BSCP Core', 'C'),
    (@MAJOR_BSCP, @COURSE_EGN_3373,  @CATALOG_2023_2024, 'BSCP Core', 'C'),
    (@MAJOR_BSCP, @COURSE_EGN_3443,  @CATALOG_2023_2024, 'BSCP Core', 'C'),
    (@MAJOR_BSCP, @COURSE_EGN_3615,  @CATALOG_2023_2024, 'BSCP Core', 'C'),
    (@MAJOR_BSCP, @COURSE_EGN_4450,  @CATALOG_2023_2024, 'BSCP Core', 'C'),
    (@MAJOR_BSCP, @COURSE_ENC_1101,  @CATALOG_2023_2024, 'BSCP Core', 'C'),
    (@MAJOR_BSCP, @COURSE_ENC_1102,  @CATALOG_2023_2024, 'BSCP Core', 'C'),
    (@MAJOR_BSCP, @COURSE_ENC_3246,  @CATALOG_2023_2024, 'BSCP Core', 'C'),
    (@MAJOR_BSCP, @COURSE_PHY_2048,  @CATALOG_2023_2024, 'BSCP Core', 'C'),
    (@MAJOR_BSCP, @COURSE_PHY_2048L, @CATALOG_2023_2024, 'BSCP Core', 'C'),
    (@MAJOR_BSCP, @COURSE_PHY_2049,  @CATALOG_2023_2024, 'BSCP Core', 'C'),
    (@MAJOR_BSCP, @COURSE_PHY_2049L, @CATALOG_2023_2024, 'BSCP Core', 'C');

-- BSCP core
INSERT INTO Bellini.CourseRequirement (MajorID, CourseID, CatalogID, RequirementType, MinGradeRequired)
VALUES
    -- 2022-2023
    (@MAJOR_BSCS, @COURSE_CDA_3103,  @CATALOG_2022_2023, 'BSCS Core', 'C'),
    (@MAJOR_BSCS, @COURSE_CDA_3201,  @CATALOG_2022_2023, 'BSCS Core', 'C'),
    (@MAJOR_BSCS, @COURSE_CDA_3201L, @CATALOG_2022_2023, 'BSCS Core', 'C'),
    (@MAJOR_BSCS, @COURSE_CDA_4205,  @CATALOG_2022_2023, 'BSCS Core', 'C'),
    (@MAJOR_BSCS, @COURSE_CDA_4205L, @CATALOG_2022_2023, 'BSCS Core', 'C'),
    (@MAJOR_BSCS, @COURSE_CEN_4020,  @CATALOG_2022_2023, 'BSCS Core', 'C'),
    (@MAJOR_BSCS, @COURSE_CIS_4250,  @CATALOG_2022_2023, 'BSCS Core', 'C'),
    (@MAJOR_BSCS, @COURSE_CNT_4419,  @CATALOG_2022_2023, 'BSCS Core', 'C'),
    (@MAJOR_BSCS, @COURSE_COP_2510,  @CATALOG_2022_2023, 'BSCS Core', 'C'),
    (@MAJOR_BSCS, @COURSE_COP_3514,  @CATALOG_2022_2023, 'BSCS Core', 'C'),
    (@MAJOR_BSCS, @COURSE_COP_4530,  @CATALOG_2022_2023, 'BSCS Core', 'C'),
    (@MAJOR_BSCS, @COURSE_COP_4600,  @CATALOG_2022_2023, 'BSCS Core', 'C'),
    (@MAJOR_BSCS, @COURSE_COT_3100,  @CATALOG_2022_2023, 'BSCS Core', 'C'),
    (@MAJOR_BSCS, @COURSE_COT_4400,  @CATALOG_2022_2023, 'BSCS Core', 'C'),
    (@MAJOR_BSCS, @COURSE_EGN_3000,  @CATALOG_2022_2023, 'BSCS Core', 'C'),
    (@MAJOR_BSCS, @COURSE_EGN_3000L, @CATALOG_2022_2023, 'BSCS Core', 'C'),
    (@MAJOR_BSCS, @COURSE_EGN_3443,  @CATALOG_2022_2023, 'BSCS Core', 'C'),
    (@MAJOR_BSCS, @COURSE_EGN_4450,  @CATALOG_2022_2023, 'BSCS Core', 'C'),
    (@MAJOR_BSCS, @COURSE_ENC_1101,  @CATALOG_2022_2023, 'BSCS Core', 'C'),
    (@MAJOR_BSCS, @COURSE_ENC_1102,  @CATALOG_2022_2023, 'BSCS Core', 'C'),
    (@MAJOR_BSCS, @COURSE_ENC_3246,  @CATALOG_2022_2023, 'BSCS Core', 'C'),
    (@MAJOR_BSCS, @COURSE_PHY_2048,  @CATALOG_2022_2023, 'BSCS Core', 'C'),
    (@MAJOR_BSCS, @COURSE_PHY_2048L, @CATALOG_2022_2023, 'BSCS Core', 'C'),
    (@MAJOR_BSCS, @COURSE_PHY_2049,  @CATALOG_2022_2023, 'BSCS Core', 'C'),
    (@MAJOR_BSCS, @COURSE_PHY_2049L, @CATALOG_2022_2023, 'BSCS Core', 'C'),
    -- 2023-2024
    (@MAJOR_BSCS, @COURSE_CDA_3103,  @CATALOG_2023_2024, 'BSCS Core', 'C'),
    (@MAJOR_BSCS, @COURSE_CDA_3201,  @CATALOG_2023_2024, 'BSCS Core', 'C'),
    (@MAJOR_BSCS, @COURSE_CDA_3201L, @CATALOG_2023_2024, 'BSCS Core', 'C'),
    (@MAJOR_BSCS, @COURSE_CDA_4205,  @CATALOG_2023_2024, 'BSCS Core', 'C'),
    (@MAJOR_BSCS, @COURSE_CDA_4205L, @CATALOG_2023_2024, 'BSCS Core', 'C'),
    (@MAJOR_BSCS, @COURSE_CEN_4020,  @CATALOG_2023_2024, 'BSCS Core', 'C'),
    (@MAJOR_BSCS, @COURSE_CIS_4250,  @CATALOG_2023_2024, 'BSCS Core', 'C'),
    (@MAJOR_BSCS, @COURSE_CNT_4419,  @CATALOG_2023_2024, 'BSCS Core', 'C'),
    (@MAJOR_BSCS, @COURSE_COP_2510,  @CATALOG_2023_2024, 'BSCS Core', 'C'),
    (@MAJOR_BSCS, @COURSE_COP_3514,  @CATALOG_2023_2024, 'BSCS Core', 'C'),
    (@MAJOR_BSCS, @COURSE_COP_4530,  @CATALOG_2023_2024, 'BSCS Core', 'C'),
    (@MAJOR_BSCS, @COURSE_COP_4600,  @CATALOG_2023_2024, 'BSCS Core', 'C'),
    (@MAJOR_BSCS, @COURSE_COT_3100,  @CATALOG_2023_2024, 'BSCS Core', 'C'),
    (@MAJOR_BSCS, @COURSE_COT_4400,  @CATALOG_2023_2024, 'BSCS Core', 'C'),
    (@MAJOR_BSCS, @COURSE_EGN_3000,  @CATALOG_2023_2024, 'BSCS Core', 'C'),
    (@MAJOR_BSCS, @COURSE_EGN_3000L, @CATALOG_2023_2024, 'BSCS Core', 'C'),
    (@MAJOR_BSCS, @COURSE_EGN_3443,  @CATALOG_2023_2024, 'BSCS Core', 'C'),
    (@MAJOR_BSCS, @COURSE_EGN_4450,  @CATALOG_2023_2024, 'BSCS Core', 'C'),
    (@MAJOR_BSCS, @COURSE_ENC_1101,  @CATALOG_2023_2024, 'BSCS Core', 'C'),
    (@MAJOR_BSCS, @COURSE_ENC_1102,  @CATALOG_2023_2024, 'BSCS Core', 'C'),
    (@MAJOR_BSCS, @COURSE_ENC_3246,  @CATALOG_2023_2024, 'BSCS Core', 'C'),
    (@MAJOR_BSCS, @COURSE_PHY_2048,  @CATALOG_2023_2024, 'BSCS Core', 'C'),
    (@MAJOR_BSCS, @COURSE_PHY_2048L, @CATALOG_2023_2024, 'BSCS Core', 'C'),
    (@MAJOR_BSCS, @COURSE_PHY_2049,  @CATALOG_2023_2024, 'BSCS Core', 'C'),
    (@MAJOR_BSCS, @COURSE_PHY_2049L, @CATALOG_2023_2024, 'BSCS Core', 'C');

-- BSCyS core
INSERT INTO Bellini.CourseRequirement (MajorID, CourseID, CatalogID, RequirementType, MinGradeRequired)
VALUES
    -- 2022-2023
    (@MAJOR_BSCyS, @COURSE_CEN_3722,  @CATALOG_2022_2023, 'BSCyS Core', 'C'),
    (@MAJOR_BSCyS, @COURSE_CGS_1540,  @CATALOG_2022_2023, 'BSCyS Core', 'C'),
    (@MAJOR_BSCyS, @COURSE_CGS_3303,  @CATALOG_2022_2023, 'BSCyS Core', 'C'),
    (@MAJOR_BSCyS, @COURSE_CGS_3853,  @CATALOG_2022_2023, 'BSCyS Core', 'C'),
    (@MAJOR_BSCyS, @COURSE_CIS_3213,  @CATALOG_2022_2023, 'BSCyS Core', 'C'),
    (@MAJOR_BSCyS, @COURSE_CIS_3363,  @CATALOG_2022_2023, 'BSCyS Core', 'C'),
    (@MAJOR_BSCyS, @COURSE_CIS_4200,  @CATALOG_2022_2023, 'BSCyS Core', 'C'),
    (@MAJOR_BSCyS, @COURSE_CIS_4219,  @CATALOG_2022_2023, 'BSCyS Core', 'C'),
    (@MAJOR_BSCyS, @COURSE_CIS_4622,  @CATALOG_2022_2023, 'BSCyS Core', 'C'),
    (@MAJOR_BSCyS, @COURSE_CIS_4935,  @CATALOG_2022_2023, 'BSCyS Core', 'C'),
    (@MAJOR_BSCyS, @COURSE_CNT_4104,  @CATALOG_2022_2023, 'BSCyS Core', 'C'),
    (@MAJOR_BSCyS, @COURSE_CNT_4104L, @CATALOG_2022_2023, 'BSCyS Core', 'C'),
    (@MAJOR_BSCyS, @COURSE_CNT_4403,  @CATALOG_2022_2023, 'BSCyS Core', 'C'),
    (@MAJOR_BSCyS, @COURSE_COP_2512,  @CATALOG_2022_2023, 'BSCyS Core', 'C'),
    (@MAJOR_BSCyS, @COURSE_COP_2513,  @CATALOG_2022_2023, 'BSCyS Core', 'C'),
    (@MAJOR_BSCyS, @COURSE_COP_3515,  @CATALOG_2022_2023, 'BSCyS Core', 'C'),
    (@MAJOR_BSCyS, @COURSE_COP_4538,  @CATALOG_2022_2023, 'BSCyS Core', 'C'),
    (@MAJOR_BSCyS, @COURSE_COP_4703,  @CATALOG_2022_2023, 'BSCyS Core', 'C'),
    (@MAJOR_BSCyS, @COURSE_ECO_2013,  @CATALOG_2022_2023, 'BSCyS Core', 'C'),
    (@MAJOR_BSCyS, @COURSE_EGN_3000,  @CATALOG_2022_2023, 'BSCyS Core', 'C'),
    (@MAJOR_BSCyS, @COURSE_EGN_3000L, @CATALOG_2022_2023, 'BSCyS Core', 'C'),
    (@MAJOR_BSCyS, @COURSE_ENC_1101,  @CATALOG_2022_2023, 'BSCyS Core', 'C'),
    (@MAJOR_BSCyS, @COURSE_ENC_1102,  @CATALOG_2022_2023, 'BSCyS Core', 'C'),
    (@MAJOR_BSCyS, @COURSE_ENC_3246,  @CATALOG_2022_2023, 'BSCyS Core', 'C'),
    (@MAJOR_BSCyS, @COURSE_ISM_4323,  @CATALOG_2022_2023, 'BSCyS Core', 'C'),
    (@MAJOR_BSCyS, @COURSE_LIS_4414,  @CATALOG_2022_2023, 'BSCyS Core', 'C'),
    (@MAJOR_BSCyS, @COURSE_MAC_1147,  @CATALOG_2022_2023, 'BSCyS Core', 'C'),
    (@MAJOR_BSCyS, @COURSE_MAD_2104,  @CATALOG_2022_2023, 'BSCyS Core', 'C'),
    (@MAJOR_BSCyS, @COURSE_PHY_2020,  @CATALOG_2022_2023, 'BSCyS Core', 'C'),
    (@MAJOR_BSCyS, @COURSE_PSY_2012,  @CATALOG_2022_2023, 'BSCyS Core', 'C'),
    (@MAJOR_BSCyS, @COURSE_STA_2023,  @CATALOG_2022_2023, 'BSCyS Core', 'C'),
    -- 2023-2024
    (@MAJOR_BSCyS, @COURSE_CEN_3722,  @CATALOG_2023_2024, 'BSCyS Core', 'C'),
    (@MAJOR_BSCyS, @COURSE_CGS_1540,  @CATALOG_2023_2024, 'BSCyS Core', 'C'),
    (@MAJOR_BSCyS, @COURSE_CGS_3303,  @CATALOG_2023_2024, 'BSCyS Core', 'C'),
    (@MAJOR_BSCyS, @COURSE_CGS_3853,  @CATALOG_2023_2024, 'BSCyS Core', 'C'),
    (@MAJOR_BSCyS, @COURSE_CIS_3213,  @CATALOG_2023_2024, 'BSCyS Core', 'C'),
    (@MAJOR_BSCyS, @COURSE_CIS_3363,  @CATALOG_2023_2024, 'BSCyS Core', 'C'),
    (@MAJOR_BSCyS, @COURSE_CIS_4200,  @CATALOG_2023_2024, 'BSCyS Core', 'C'),
    (@MAJOR_BSCyS, @COURSE_CIS_4219,  @CATALOG_2023_2024, 'BSCyS Core', 'C'),
    (@MAJOR_BSCyS, @COURSE_CIS_4622,  @CATALOG_2023_2024, 'BSCyS Core', 'C'),
    (@MAJOR_BSCyS, @COURSE_CIS_4935,  @CATALOG_2023_2024, 'BSCyS Core', 'C'),
    (@MAJOR_BSCyS, @COURSE_CNT_4104,  @CATALOG_2023_2024, 'BSCyS Core', 'C'),
    (@MAJOR_BSCyS, @COURSE_CNT_4104L, @CATALOG_2023_2024, 'BSCyS Core', 'C'),
    (@MAJOR_BSCyS, @COURSE_CNT_4403,  @CATALOG_2023_2024, 'BSCyS Core', 'C'),
    (@MAJOR_BSCyS, @COURSE_COP_2512,  @CATALOG_2023_2024, 'BSCyS Core', 'C'),
    (@MAJOR_BSCyS, @COURSE_COP_2513,  @CATALOG_2023_2024, 'BSCyS Core', 'C'),
    (@MAJOR_BSCyS, @COURSE_COP_3515,  @CATALOG_2023_2024, 'BSCyS Core', 'C'),
    (@MAJOR_BSCyS, @COURSE_COP_4538,  @CATALOG_2023_2024, 'BSCyS Core', 'C'),
    (@MAJOR_BSCyS, @COURSE_COP_4703,  @CATALOG_2023_2024, 'BSCyS Core', 'C'),
    (@MAJOR_BSCyS, @COURSE_ECO_2013,  @CATALOG_2023_2024, 'BSCyS Core', 'C'),
    (@MAJOR_BSCyS, @COURSE_EGN_3000,  @CATALOG_2023_2024, 'BSCyS Core', 'C'),
    (@MAJOR_BSCyS, @COURSE_EGN_3000L, @CATALOG_2023_2024, 'BSCyS Core', 'C'),
    (@MAJOR_BSCyS, @COURSE_ENC_1101,  @CATALOG_2023_2024, 'BSCyS Core', 'C'),
    (@MAJOR_BSCyS, @COURSE_ENC_1102,  @CATALOG_2023_2024, 'BSCyS Core', 'C'),
    (@MAJOR_BSCyS, @COURSE_ENC_3246,  @CATALOG_2023_2024, 'BSCyS Core', 'C'),
    (@MAJOR_BSCyS, @COURSE_ISM_4323,  @CATALOG_2023_2024, 'BSCyS Core', 'C'),
    (@MAJOR_BSCyS, @COURSE_LIS_4414,  @CATALOG_2023_2024, 'BSCyS Core', 'C'),
    (@MAJOR_BSCyS, @COURSE_MAC_1147,  @CATALOG_2023_2024, 'BSCyS Core', 'C'),
    (@MAJOR_BSCyS, @COURSE_MAD_2104,  @CATALOG_2023_2024, 'BSCyS Core', 'C'),
    (@MAJOR_BSCyS, @COURSE_PHY_2020,  @CATALOG_2023_2024, 'BSCyS Core', 'C'),
    (@MAJOR_BSCyS, @COURSE_PSY_2012,  @CATALOG_2023_2024, 'BSCyS Core', 'C'),
    (@MAJOR_BSCyS, @COURSE_STA_2023,  @CATALOG_2023_2024, 'BSCyS Core', 'C');

-- BSIT core
INSERT INTO Bellini.CourseRequirement (MajorID, CourseID, CatalogID, RequirementType, MinGradeRequired)
VALUES
    -- 2022-2023
    (@MAJOR_BSIT, @COURSE_CEN_3722,  @CATALOG_2022_2023, 'BSIT Core', 'C'),
    (@MAJOR_BSIT, @COURSE_CGS_1540,  @CATALOG_2022_2023, 'BSIT Core', 'C'),
    (@MAJOR_BSIT, @COURSE_CGS_3303,  @CATALOG_2022_2023, 'BSIT Core', 'C'),
    (@MAJOR_BSIT, @COURSE_CGS_3853,  @CATALOG_2022_2023, 'BSIT Core', 'C'),
    (@MAJOR_BSIT, @COURSE_CIS_3213,  @CATALOG_2022_2023, 'BSIT Core', 'C'),
    (@MAJOR_BSIT, @COURSE_CIS_3433,  @CATALOG_2022_2023, 'BSIT Core', 'C'),
    (@MAJOR_BSIT, @COURSE_CIS_4083,  @CATALOG_2022_2023, 'BSIT Core', 'C'),
    (@MAJOR_BSIT, @COURSE_CIS_4935,  @CATALOG_2022_2023, 'BSIT Core', 'C'),
    (@MAJOR_BSIT, @COURSE_CNT_4104,  @CATALOG_2022_2023, 'BSIT Core', 'C'),
    (@MAJOR_BSIT, @COURSE_CNT_4104L, @CATALOG_2022_2023, 'BSIT Core', 'C'),
    (@MAJOR_BSIT, @COURSE_CNT_4603,  @CATALOG_2022_2023, 'BSIT Core', 'C'),
    (@MAJOR_BSIT, @COURSE_COP_2512,  @CATALOG_2022_2023, 'BSIT Core', 'C'),
    (@MAJOR_BSIT, @COURSE_COP_2513,  @CATALOG_2022_2023, 'BSIT Core', 'C'),
    (@MAJOR_BSIT, @COURSE_COP_3515,  @CATALOG_2022_2023, 'BSIT Core', 'C'),
    (@MAJOR_BSIT, @COURSE_COP_4538,  @CATALOG_2022_2023, 'BSIT Core', 'C'),
    (@MAJOR_BSIT, @COURSE_COP_4703,  @CATALOG_2022_2023, 'BSIT Core', 'C'),
    (@MAJOR_BSIT, @COURSE_ECO_2013,  @CATALOG_2022_2023, 'BSIT Core', 'C'),
    (@MAJOR_BSIT, @COURSE_EGN_3000,  @CATALOG_2022_2023, 'BSIT Core', 'C'),
    (@MAJOR_BSIT, @COURSE_EGN_3000L, @CATALOG_2022_2023, 'BSIT Core', 'C'),
    (@MAJOR_BSIT, @COURSE_ENC_1101,  @CATALOG_2022_2023, 'BSIT Core', 'C'),
    (@MAJOR_BSIT, @COURSE_ENC_1102,  @CATALOG_2022_2023, 'BSIT Core', 'C'),
    (@MAJOR_BSIT, @COURSE_ENC_3246,  @CATALOG_2022_2023, 'BSIT Core', 'C'),
    (@MAJOR_BSIT, @COURSE_INR_3033,  @CATALOG_2022_2023, 'BSIT Core', 'C'),
    (@MAJOR_BSIT, @COURSE_MAC_1147,  @CATALOG_2022_2023, 'BSIT Core', 'C'),
    (@MAJOR_BSIT, @COURSE_MAD_2104,  @CATALOG_2022_2023, 'BSIT Core', 'C'),
    (@MAJOR_BSIT, @COURSE_PHY_2020,  @CATALOG_2022_2023, 'BSIT Core', 'C'),
    (@MAJOR_BSIT, @COURSE_PSY_2012,  @CATALOG_2022_2023, 'BSIT Core', 'C'),
    (@MAJOR_BSIT, @COURSE_STA_2023,  @CATALOG_2022_2023, 'BSIT Core', 'C'),
    -- 2023-2024
    (@MAJOR_BSIT, @COURSE_CEN_3722,  @CATALOG_2023_2024, 'BSIT Core', 'C'),
    (@MAJOR_BSIT, @COURSE_CGS_1540,  @CATALOG_2023_2024, 'BSIT Core', 'C'),
    (@MAJOR_BSIT, @COURSE_CGS_3303,  @CATALOG_2023_2024, 'BSIT Core', 'C'),
    (@MAJOR_BSIT, @COURSE_CGS_3853,  @CATALOG_2023_2024, 'BSIT Core', 'C'),
    (@MAJOR_BSIT, @COURSE_CIS_3213,  @CATALOG_2023_2024, 'BSIT Core', 'C'),
    (@MAJOR_BSIT, @COURSE_CIS_3433,  @CATALOG_2023_2024, 'BSIT Core', 'C'),
    (@MAJOR_BSIT, @COURSE_CIS_4083,  @CATALOG_2023_2024, 'BSIT Core', 'C'),
    (@MAJOR_BSIT, @COURSE_CIS_4935,  @CATALOG_2023_2024, 'BSIT Core', 'C'),
    (@MAJOR_BSIT, @COURSE_CNT_4104,  @CATALOG_2023_2024, 'BSIT Core', 'C'),
    (@MAJOR_BSIT, @COURSE_CNT_4104L, @CATALOG_2023_2024, 'BSIT Core', 'C'),
    (@MAJOR_BSIT, @COURSE_CNT_4603,  @CATALOG_2023_2024, 'BSIT Core', 'C'),
    (@MAJOR_BSIT, @COURSE_COP_2512,  @CATALOG_2023_2024, 'BSIT Core', 'C'),
    (@MAJOR_BSIT, @COURSE_COP_2513,  @CATALOG_2023_2024, 'BSIT Core', 'C'),
    (@MAJOR_BSIT, @COURSE_COP_3515,  @CATALOG_2023_2024, 'BSIT Core', 'C'),
    (@MAJOR_BSIT, @COURSE_COP_4538,  @CATALOG_2023_2024, 'BSIT Core', 'C'),
    (@MAJOR_BSIT, @COURSE_COP_4703,  @CATALOG_2023_2024, 'BSIT Core', 'C'),
    (@MAJOR_BSIT, @COURSE_ECO_2013,  @CATALOG_2023_2024, 'BSIT Core', 'C'),
    (@MAJOR_BSIT, @COURSE_EGN_3000,  @CATALOG_2023_2024, 'BSIT Core', 'C'),
    (@MAJOR_BSIT, @COURSE_EGN_3000L, @CATALOG_2023_2024, 'BSIT Core', 'C'),
    (@MAJOR_BSIT, @COURSE_ENC_1101,  @CATALOG_2023_2024, 'BSIT Core', 'C'),
    (@MAJOR_BSIT, @COURSE_ENC_1102,  @CATALOG_2023_2024, 'BSIT Core', 'C'),
    (@MAJOR_BSIT, @COURSE_ENC_3246,  @CATALOG_2023_2024, 'BSIT Core', 'C'),
    (@MAJOR_BSIT, @COURSE_INR_3033,  @CATALOG_2023_2024, 'BSIT Core', 'C'),
    (@MAJOR_BSIT, @COURSE_MAC_1147,  @CATALOG_2023_2024, 'BSIT Core', 'C'),
    (@MAJOR_BSIT, @COURSE_MAD_2104,  @CATALOG_2023_2024, 'BSIT Core', 'C'),
    (@MAJOR_BSIT, @COURSE_PHY_2020,  @CATALOG_2023_2024, 'BSIT Core', 'C'),
    (@MAJOR_BSIT, @COURSE_PSY_2012,  @CATALOG_2023_2024, 'BSIT Core', 'C'),
    (@MAJOR_BSIT, @COURSE_STA_2023,  @CATALOG_2023_2024, 'BSIT Core', 'C');


------------------------------------------------------------
-- RequirementGroups
------------------------------------------------------------
INSERT INTO Bellini.RequirementGroup (MajorID, CatalogID, GroupCode, GroupName, MinCoursesRequired)
VALUES
    -- BSCP 2022-2023
    (@MAJOR_BSCP, @CATALOG_2022_2023, 'GROUP_BSCP_GECH', 'BSCP General Education Core Humanities', 2),
    (@MAJOR_BSCP, @CATALOG_2022_2023, 'GROUP_BSCP_GECS', 'BSCP General Education Core Social Sciences', 2),
    (@MAJOR_BSCP, @CATALOG_2022_2023, 'GROUP_BSCP_CALC_1', 'BSCP Calculus I', 1),
    (@MAJOR_BSCP, @CATALOG_2022_2023, 'GROUP_BSCP_CALC_2', 'BSCP Calculus II', 1),
    (@MAJOR_BSCP, @CATALOG_2022_2023, 'GROUP_BSCP_CALC_3', 'BSCP Calculus III', 1),
    (@MAJOR_BSCP, @CATALOG_2022_2023, 'GROUP_BSCP_DIFF_EQ', 'BSCP Differential Equations', 1),
    (@MAJOR_BSCP, @CATALOG_2022_2023, 'GROUP_BSCP_CHEM_1', 'BSCP Chemistry I', 1),
    (@MAJOR_BSCP, @CATALOG_2022_2023, 'GROUP_BSCP_CHEM_1_LAB', 'BSCP Chemistry I Lab', 1),
    (@MAJOR_BSCP, @CATALOG_2022_2023, 'GROUP_BSCP_HARDWARE_ELECTIVES', 'BSCP 2022 Hardware Electives', 2),
    (@MAJOR_BSCP, @CATALOG_2022_2023, 'GROUP_BSCP_ELECTIVES', 'BSCP 2022 Electives', 2),
    -- BSCP 2023-2024
    (@MAJOR_BSCP, @CATALOG_2023_2024, 'GROUP_BSCP_GECH', 'BSCP General Education Core Humanities', 2),
    (@MAJOR_BSCP, @CATALOG_2023_2024, 'GROUP_BSCP_GECS', 'BSCP General Education Core Social Sciences', 2),
    (@MAJOR_BSCP, @CATALOG_2023_2024, 'GROUP_BSCP_CALC_1', 'BSCP Calculus I', 1),
    (@MAJOR_BSCP, @CATALOG_2023_2024, 'GROUP_BSCP_CALC_2', 'BSCP Calculus II', 1),
    (@MAJOR_BSCP, @CATALOG_2023_2024, 'GROUP_BSCP_CALC_3', 'BSCP Calculus III', 1),
    (@MAJOR_BSCP, @CATALOG_2023_2024, 'GROUP_BSCP_DIFF_EQ', 'BSCP Differential Equations', 1),
    (@MAJOR_BSCP, @CATALOG_2023_2024, 'GROUP_BSCP_CHEM_1', 'BSCP Chemistry I', 1),
    (@MAJOR_BSCP, @CATALOG_2023_2024, 'GROUP_BSCP_CHEM_1_LAB', 'BSCP Chemistry I Lab', 1),
    (@MAJOR_BSCP, @CATALOG_2023_2024, 'GROUP_BSCP_HARDWARE_ELECTIVES', 'BSCP 2023 Hardware Electives', 2),
    (@MAJOR_BSCP, @CATALOG_2023_2024, 'GROUP_BSCP_ELECTIVES', 'BSCP 2023 Electives', 2),
    -- BSCS 2022-2023
    (@MAJOR_BSCS, @CATALOG_2022_2023, 'GROUP_BSCS_GECH', 'BSCS General Education Core Humanities', 2),
    (@MAJOR_BSCS, @CATALOG_2022_2023, 'GROUP_BSCS_GECS', 'BSCS General Education Core Social Sciences', 2),
    (@MAJOR_BSCS, @CATALOG_2022_2023, 'GROUP_BSCS_CALC_1', 'BSCS Calculus I', 1),
    (@MAJOR_BSCS, @CATALOG_2022_2023, 'GROUP_BSCS_CALC_2', 'BSCS Calculus II', 1),
    (@MAJOR_BSCS, @CATALOG_2022_2023, 'GROUP_BSCS_CALC_3', 'BSCS Calculus III', 1),
    (@MAJOR_BSCS, @CATALOG_2022_2023, 'GROUP_BSCS_ELECTIVES', 'BSCS 2022 Electives', 7),
    -- BSCS 2023-2024
    (@MAJOR_BSCS, @CATALOG_2023_2024, 'GROUP_BSCS_GECH', 'BSCS General Education Core Humanities', 2),
    (@MAJOR_BSCS, @CATALOG_2023_2024, 'GROUP_BSCS_GECS', 'BSCS General Education Core Social Sciences', 2),
    (@MAJOR_BSCS, @CATALOG_2023_2024, 'GROUP_BSCS_CALC_1', 'BSCS Calculus I', 1),
    (@MAJOR_BSCS, @CATALOG_2023_2024, 'GROUP_BSCS_CALC_2', 'BSCS Calculus II', 1),
    (@MAJOR_BSCS, @CATALOG_2023_2024, 'GROUP_BSCS_CALC_3', 'BSCS Calculus III', 1),
    (@MAJOR_BSCS, @CATALOG_2023_2024, 'GROUP_BSCS_SOFTWARE_ELECTIVES', 'BSCS 2023 Software Electives', 2),
    (@MAJOR_BSCS, @CATALOG_2023_2024, 'GROUP_BSCS_THEORY_ELECTIVES', 'BSCS 2023 Theory Eelectives', 1),
    (@MAJOR_BSCS, @CATALOG_2023_2024, 'GROUP_BSCS_ELECTIVES', 'BSCS 2023 Electives', 4),
    -- BSCyS 2022-2023
    (@MAJOR_BSCYS, @CATALOG_2022_2023, 'GROUP_BSCYS_GECH', 'BSCYS General Education Core Humanities', 2),
    (@MAJOR_BSCYS, @CATALOG_2022_2023, 'GROUP_BSCYS_GECS', 'BSCYS General Education Core Social Sciences', 2),
    (@MAJOR_BSCYS, @CATALOG_2022_2023, 'GROUP_BSCYS_ELECTIVES', 'BSCYS 2022 Electives', 3),
    -- BSCyS 2023-2024
    (@MAJOR_BSCYS, @CATALOG_2023_2024, 'GROUP_BSCYS_GECH', 'BSCYS General Education Core Humanities', 2),
    (@MAJOR_BSCYS, @CATALOG_2023_2024, 'GROUP_BSCYS_GECS', 'BSCYS General Education Core Social Sciences', 2),
    (@MAJOR_BSCYS, @CATALOG_2023_2024, 'GROUP_BSCYS_ELECTIVES', 'BSCYS 2023 Electives', 3),
    -- BSIT 2022-2023
    (@MAJOR_BSIT, @CATALOG_2022_2023, 'GROUP_BSIT_GECH', 'BSIT General Education Core Humanities', 2),
    (@MAJOR_BSIT, @CATALOG_2022_2023, 'GROUP_BSIT_GECS', 'BSIT General Education Core Social Sciences', 2),
    (@MAJOR_BSIT, @CATALOG_2022_2023, 'GROUP_BSIT_GENERAL_ADDON', 'BSIT 2022 General Add-On', 1),
    (@MAJOR_BSIT, @CATALOG_2022_2023, 'GROUP_BSIT_ELECTIVES', 'BSIT 2022 Electives', 5),
    -- BSIT 2023-2024
    (@MAJOR_BSIT, @CATALOG_2023_2024, 'GROUP_BSIT_GECH', 'BSIT General Education Core Humanities', 2),
    (@MAJOR_BSIT, @CATALOG_2023_2024, 'GROUP_BSIT_GECS', 'BSIT General Education Core Social Sciences', 2),
    (@MAJOR_BSIT, @CATALOG_2023_2024, 'GROUP_BSIT_GENERAL_ADDON', 'BSIT 2023 General Add-On', 1),
    (@MAJOR_BSIT, @CATALOG_2023_2024, 'GROUP_BSIT_ELECTIVES', 'BSIT 2023 Electives', 5);

SELECT @GROUP_BSCP_2022_2023_GECH = RequirementGroupID FROM Bellini.RequirementGroup WHERE MajorID = @MAJOR_BSCP AND CatalogID = @CATALOG_2022_2023 AND GroupCode = 'GROUP_BSCP_GECH';
SELECT @GROUP_BSCP_2022_2023_GECS = RequirementGroupID FROM Bellini.RequirementGroup WHERE MajorID = @MAJOR_BSCP AND CatalogID = @CATALOG_2022_2023 AND GroupCode = 'GROUP_BSCP_GECS';
SELECT @GROUP_BSCP_2022_2023_CALC_1 = RequirementGroupID FROM Bellini.RequirementGroup WHERE MajorID = @MAJOR_BSCP AND CatalogID = @CATALOG_2022_2023 AND GroupCode = 'GROUP_BSCP_CALC_1';
SELECT @GROUP_BSCP_2022_2023_CALC_2 = RequirementGroupID FROM Bellini.RequirementGroup WHERE MajorID = @MAJOR_BSCP AND CatalogID = @CATALOG_2022_2023 AND GroupCode = 'GROUP_BSCP_CALC_2';
SELECT @GROUP_BSCP_2022_2023_CALC_3 = RequirementGroupID FROM Bellini.RequirementGroup WHERE MajorID = @MAJOR_BSCP AND CatalogID = @CATALOG_2022_2023 AND GroupCode = 'GROUP_BSCP_CALC_3';
SELECT @GROUP_BSCP_2022_2023_DIFF_EQ = RequirementGroupID FROM Bellini.RequirementGroup WHERE MajorID = @MAJOR_BSCP AND CatalogID = @CATALOG_2022_2023 AND GroupCode = 'GROUP_BSCP_DIFF_EQ';
SELECT @GROUP_BSCP_2022_2023_CHEM_1 = RequirementGroupID FROM Bellini.RequirementGroup WHERE MajorID = @MAJOR_BSCP AND CatalogID = @CATALOG_2022_2023 AND GroupCode = 'GROUP_BSCP_CHEM_1';
SELECT @GROUP_BSCP_2022_2023_CHEM_1_LAB = RequirementGroupID FROM Bellini.RequirementGroup WHERE MajorID = @MAJOR_BSCP AND CatalogID = @CATALOG_2022_2023 AND GroupCode = 'GROUP_BSCP_CHEM_1_LAB';
SELECT @GROUP_BSCP_2022_2023_HARDWARE_ELECTIVES = RequirementGroupID FROM Bellini.RequirementGroup WHERE MajorID = @MAJOR_BSCP AND CatalogID = @CATALOG_2022_2023 AND GroupCode = 'GROUP_BSCP_HARDWARE_ELECTIVES';
SELECT @GROUP_BSCP_2022_2023_ELECTIVES = RequirementGroupID FROM Bellini.RequirementGroup WHERE MajorID = @MAJOR_BSCP AND CatalogID = @CATALOG_2022_2023 AND GroupCode = 'GROUP_BSCP_ELECTIVES';

SELECT @GROUP_BSCP_2023_2024_GECH = RequirementGroupID FROM Bellini.RequirementGroup WHERE MajorID = @MAJOR_BSCP AND CatalogID = @CATALOG_2023_2024 AND GroupCode = 'GROUP_BSCP_GECH';
SELECT @GROUP_BSCP_2023_2024_GECS = RequirementGroupID FROM Bellini.RequirementGroup WHERE MajorID = @MAJOR_BSCP AND CatalogID = @CATALOG_2023_2024 AND GroupCode = 'GROUP_BSCP_GECS';
SELECT @GROUP_BSCP_2023_2024_CALC_1 = RequirementGroupID FROM Bellini.RequirementGroup WHERE MajorID = @MAJOR_BSCP AND CatalogID = @CATALOG_2023_2024 AND GroupCode = 'GROUP_BSCP_CALC_1';
SELECT @GROUP_BSCP_2023_2024_CALC_2 = RequirementGroupID FROM Bellini.RequirementGroup WHERE MajorID = @MAJOR_BSCP AND CatalogID = @CATALOG_2023_2024 AND GroupCode = 'GROUP_BSCP_CALC_2';
SELECT @GROUP_BSCP_2023_2024_CALC_3 = RequirementGroupID FROM Bellini.RequirementGroup WHERE MajorID = @MAJOR_BSCP AND CatalogID = @CATALOG_2023_2024 AND GroupCode = 'GROUP_BSCP_CALC_3';
SELECT @GROUP_BSCP_2023_2024_DIFF_EQ = RequirementGroupID FROM Bellini.RequirementGroup WHERE MajorID = @MAJOR_BSCP AND CatalogID = @CATALOG_2023_2024 AND GroupCode = 'GROUP_BSCP_DIFF_EQ';
SELECT @GROUP_BSCP_2023_2024_CHEM_1 = RequirementGroupID FROM Bellini.RequirementGroup WHERE MajorID = @MAJOR_BSCP AND CatalogID = @CATALOG_2023_2024 AND GroupCode = 'GROUP_BSCP_CHEM_1';
SELECT @GROUP_BSCP_2023_2024_CHEM_1_LAB = RequirementGroupID FROM Bellini.RequirementGroup WHERE MajorID = @MAJOR_BSCP AND CatalogID = @CATALOG_2023_2024 AND GroupCode = 'GROUP_BSCP_CHEM_1_LAB';
SELECT @GROUP_BSCP_2023_2024_HARDWARE_ELECTIVES = RequirementGroupID FROM Bellini.RequirementGroup WHERE MajorID = @MAJOR_BSCP AND CatalogID = @CATALOG_2023_2024 AND GroupCode = 'GROUP_BSCP_HARDWARE_ELECTIVES';
SELECT @GROUP_BSCP_2023_2024_ELECTIVES = RequirementGroupID FROM Bellini.RequirementGroup WHERE MajorID = @MAJOR_BSCP AND CatalogID = @CATALOG_2023_2024 AND GroupCode = 'GROUP_BSCP_ELECTIVES';

SELECT @GROUP_BSCS_2022_2023_GECH = RequirementGroupID FROM Bellini.RequirementGroup WHERE MajorID = @MAJOR_BSCS AND CatalogID = @CATALOG_2022_2023 AND GroupCode = 'GROUP_BSCS_GECH';
SELECT @GROUP_BSCS_2022_2023_GECS = RequirementGroupID FROM Bellini.RequirementGroup WHERE MajorID = @MAJOR_BSCS AND CatalogID = @CATALOG_2022_2023 AND GroupCode = 'GROUP_BSCS_GECS';
SELECT @GROUP_BSCS_2022_2023_CALC_1 = RequirementGroupID FROM Bellini.RequirementGroup WHERE MajorID = @MAJOR_BSCS AND CatalogID = @CATALOG_2022_2023 AND GroupCode = 'GROUP_BSCS_CALC_1';
SELECT @GROUP_BSCS_2022_2023_CALC_2 = RequirementGroupID FROM Bellini.RequirementGroup WHERE MajorID = @MAJOR_BSCS AND CatalogID = @CATALOG_2022_2023 AND GroupCode = 'GROUP_BSCS_CALC_2';
SELECT @GROUP_BSCS_2022_2023_CALC_3 = RequirementGroupID FROM Bellini.RequirementGroup WHERE MajorID = @MAJOR_BSCS AND CatalogID = @CATALOG_2022_2023 AND GroupCode = 'GROUP_BSCS_CALC_3';
SELECT @GROUP_BSCS_2022_2023_ELECTIVES = RequirementGroupID FROM Bellini.RequirementGroup WHERE MajorID = @MAJOR_BSCS AND CatalogID = @CATALOG_2022_2023 AND GroupCode = 'GROUP_BSCS_ELECTIVES';

SELECT @GROUP_BSCS_2023_2024_GECH = RequirementGroupID FROM Bellini.RequirementGroup WHERE MajorID = @MAJOR_BSCS AND CatalogID = @CATALOG_2023_2024 AND GroupCode = 'GROUP_BSCS_GECH';
SELECT @GROUP_BSCS_2023_2024_GECS = RequirementGroupID FROM Bellini.RequirementGroup WHERE MajorID = @MAJOR_BSCS AND CatalogID = @CATALOG_2023_2024 AND GroupCode = 'GROUP_BSCS_GECS';
SELECT @GROUP_BSCS_2023_2024_CALC_1 = RequirementGroupID FROM Bellini.RequirementGroup WHERE MajorID = @MAJOR_BSCS AND CatalogID = @CATALOG_2023_2024 AND GroupCode = 'GROUP_BSCS_CALC_1';
SELECT @GROUP_BSCS_2023_2024_CALC_2 = RequirementGroupID FROM Bellini.RequirementGroup WHERE MajorID = @MAJOR_BSCS AND CatalogID = @CATALOG_2023_2024 AND GroupCode = 'GROUP_BSCS_CALC_2';
SELECT @GROUP_BSCS_2023_2024_CALC_3 = RequirementGroupID FROM Bellini.RequirementGroup WHERE MajorID = @MAJOR_BSCS AND CatalogID = @CATALOG_2023_2024 AND GroupCode = 'GROUP_BSCS_CALC_3';
SELECT @GROUP_BSCS_2023_2024_SOFTWARE_ELECTIVES = RequirementGroupID FROM Bellini.RequirementGroup WHERE MajorID = @MAJOR_BSCS AND CatalogID = @CATALOG_2023_2024 AND GroupCode = 'GROUP_BSCS_SOFTWARE_ELECTIVES';
SELECT @GROUP_BSCS_2023_2024_THEORY_ELECTIVES = RequirementGroupID FROM Bellini.RequirementGroup WHERE MajorID = @MAJOR_BSCS AND CatalogID = @CATALOG_2023_2024 AND GroupCode = 'GROUP_BSCS_THEORY_ELECTIVES';
SELECT @GROUP_BSCS_2023_2024_ELECTIVES = RequirementGroupID FROM Bellini.RequirementGroup WHERE MajorID = @MAJOR_BSCS AND CatalogID = @CATALOG_2023_2024 AND GroupCode = 'GROUP_BSCS_ELECTIVES';

SELECT @GROUP_BSCYS_2022_2023_GECH = RequirementGroupID FROM Bellini.RequirementGroup WHERE MajorID = @MAJOR_BSCYS AND CatalogID = @CATALOG_2022_2023 AND GroupCode = 'GROUP_BSCYS_GECH';
SELECT @GROUP_BSCYS_2022_2023_GECS = RequirementGroupID FROM Bellini.RequirementGroup WHERE MajorID = @MAJOR_BSCYS AND CatalogID = @CATALOG_2022_2023 AND GroupCode = 'GROUP_BSCYS_GECS';
SELECT @GROUP_BSCYS_2022_2023_ELECTIVES = RequirementGroupID FROM Bellini.RequirementGroup WHERE MajorID = @MAJOR_BSCYS AND CatalogID = @CATALOG_2022_2023 AND GroupCode = 'GROUP_BSCYS_ELECTIVES';

SELECT @GROUP_BSCYS_2023_2024_GECH = RequirementGroupID FROM Bellini.RequirementGroup WHERE MajorID = @MAJOR_BSCYS AND CatalogID = @CATALOG_2023_2024 AND GroupCode = 'GROUP_BSCYS_GECH';
SELECT @GROUP_BSCYS_2023_2024_GECS = RequirementGroupID FROM Bellini.RequirementGroup WHERE MajorID = @MAJOR_BSCYS AND CatalogID = @CATALOG_2023_2024 AND GroupCode = 'GROUP_BSCYS_GECS';
SELECT @GROUP_BSCYS_2023_2024_ELECTIVES = RequirementGroupID FROM Bellini.RequirementGroup WHERE MajorID = @MAJOR_BSCYS AND CatalogID = @CATALOG_2023_2024 AND GroupCode = 'GROUP_BSCYS_ELECTIVES';

SELECT @GROUP_BSIT_2022_2023_GECH = RequirementGroupID FROM Bellini.RequirementGroup WHERE MajorID = @MAJOR_BSIT AND CatalogID = @CATALOG_2022_2023 AND GroupCode = 'GROUP_BSIT_GECH';
SELECT @GROUP_BSIT_2022_2023_GECS = RequirementGroupID FROM Bellini.RequirementGroup WHERE MajorID = @MAJOR_BSIT AND CatalogID = @CATALOG_2022_2023 AND GroupCode = 'GROUP_BSIT_GECS';
SELECT @GROUP_BSIT_2022_2023_GENERAL_ADDON = RequirementGroupID FROM Bellini.RequirementGroup WHERE MajorID = @MAJOR_BSIT AND CatalogID = @CATALOG_2022_2023 AND GroupCode = 'GROUP_BSIT_GENERAL_ADDON';
SELECT @GROUP_BSIT_2022_2023_ELECTIVES = RequirementGroupID FROM Bellini.RequirementGroup WHERE MajorID = @MAJOR_BSIT AND CatalogID = @CATALOG_2022_2023 AND GroupCode = 'GROUP_BSIT_ELECTIVES';

SELECT @GROUP_BSIT_2023_2024_GECH = RequirementGroupID FROM Bellini.RequirementGroup WHERE MajorID = @MAJOR_BSIT AND CatalogID = @CATALOG_2023_2024 AND GroupCode = 'GROUP_BSIT_GECH';
SELECT @GROUP_BSIT_2023_2024_GECS = RequirementGroupID FROM Bellini.RequirementGroup WHERE MajorID = @MAJOR_BSIT AND CatalogID = @CATALOG_2023_2024 AND GroupCode = 'GROUP_BSIT_GECS';
SELECT @GROUP_BSIT_2023_2024_GENERAL_ADDON = RequirementGroupID FROM Bellini.RequirementGroup WHERE MajorID = @MAJOR_BSIT AND CatalogID = @CATALOG_2023_2024 AND GroupCode = 'GROUP_BSIT_GENERAL_ADDON';
SELECT @GROUP_BSIT_2023_2024_ELECTIVES = RequirementGroupID FROM Bellini.RequirementGroup WHERE MajorID = @MAJOR_BSIT AND CatalogID = @CATALOG_2023_2024 AND GroupCode = 'GROUP_BSIT_ELECTIVES';


------------------------------------------------------------
-- RequirementGroupCourse
------------------------------------------------------------
INSERT INTO Bellini.RequirementGroupCourse (RequirementGroupID, CourseID)
VALUES
    (@GROUP_BSCP_2022_2023_GECH, @COURSE_ARH_2000),
    (@GROUP_BSCP_2022_2023_GECH, @COURSE_HUM_1020),
    (@GROUP_BSCP_2022_2023_GECH, @COURSE_LIT_2000),
    (@GROUP_BSCP_2022_2023_GECH, @COURSE_MUL_2010),
    (@GROUP_BSCP_2022_2023_GECH, @COURSE_PHI_2010),
    (@GROUP_BSCP_2022_2023_GECH, @COURSE_THE_2000),

    (@GROUP_BSCP_2022_2023_GECS, @COURSE_AMH_2020),
    (@GROUP_BSCP_2022_2023_GECS, @COURSE_ANT_2000),
    (@GROUP_BSCP_2022_2023_GECS, @COURSE_ECO_2013),
    (@GROUP_BSCP_2022_2023_GECS, @COURSE_POS_2041),
    (@GROUP_BSCP_2022_2023_GECS, @COURSE_PSY_2012),
    (@GROUP_BSCP_2022_2023_GECS, @COURSE_SYG_2000),

    (@GROUP_BSCP_2022_2023_CALC_1, @COURSE_MAC_2281),
    (@GROUP_BSCP_2022_2023_CALC_1, @COURSE_MAC_2311),
    
    (@GROUP_BSCP_2022_2023_CALC_2, @COURSE_MAC_2282),
    (@GROUP_BSCP_2022_2023_CALC_2, @COURSE_MAC_2312),
    
    (@GROUP_BSCP_2022_2023_CALC_3, @COURSE_MAC_2283),
    (@GROUP_BSCP_2022_2023_CALC_3, @COURSE_MAC_2313),
    
    (@GROUP_BSCP_2022_2023_DIFF_EQ, @COURSE_MAP_2302),
    (@GROUP_BSCP_2022_2023_DIFF_EQ, @COURSE_EGN_3433),
    
    (@GROUP_BSCP_2022_2023_CHEM_1, @COURSE_CHM_2045),
    (@GROUP_BSCP_2022_2023_CHEM_1, @COURSE_CHS_2440),
    
    (@GROUP_BSCP_2022_2023_CHEM_1_LAB, @COURSE_CHM_2045L),
    (@GROUP_BSCP_2022_2023_CHEM_1_LAB, @COURSE_CHS_2440L),
    
    (@GROUP_BSCP_2022_2023_HARDWARE_ELECTIVES, @COURSE_CDA_4253),
    (@GROUP_BSCP_2022_2023_HARDWARE_ELECTIVES, @COURSE_CDA_4322),
    (@GROUP_BSCP_2022_2023_HARDWARE_ELECTIVES, @COURSE_CDA_4621),
    
    (@GROUP_BSCP_2022_2023_ELECTIVES, @COURSE_CAP_4034),
    (@GROUP_BSCP_2022_2023_ELECTIVES, @COURSE_CAP_4063),
    (@GROUP_BSCP_2022_2023_ELECTIVES, @COURSE_CAP_4111),
    (@GROUP_BSCP_2022_2023_ELECTIVES, @COURSE_CAP_4401),
    (@GROUP_BSCP_2022_2023_ELECTIVES, @COURSE_CAP_4410),
    (@GROUP_BSCP_2022_2023_ELECTIVES, @COURSE_CAP_4662),
    (@GROUP_BSCP_2022_2023_ELECTIVES, @COURSE_CDA_4253),
    (@GROUP_BSCP_2022_2023_ELECTIVES, @COURSE_CDA_4322),
    (@GROUP_BSCP_2022_2023_ELECTIVES, @COURSE_CDA_4621),
    (@GROUP_BSCP_2022_2023_ELECTIVES, @COURSE_CEN_4020),
    (@GROUP_BSCP_2022_2023_ELECTIVES, @COURSE_CEN_4072),
    (@GROUP_BSCP_2022_2023_ELECTIVES, @COURSE_CIS_4212),
    (@GROUP_BSCP_2022_2023_ELECTIVES, @COURSE_CIS_4345),
    (@GROUP_BSCP_2022_2023_ELECTIVES, @COURSE_CIS_4364),
    (@GROUP_BSCP_2022_2023_ELECTIVES, @COURSE_CIS_4623),
    (@GROUP_BSCP_2022_2023_ELECTIVES, @COURSE_CIS_4900),
    (@GROUP_BSCP_2022_2023_ELECTIVES, @COURSE_CIS_4915),
    (@GROUP_BSCP_2022_2023_ELECTIVES, @COURSE_CIS_4940),
    (@GROUP_BSCP_2022_2023_ELECTIVES, @COURSE_CNT_4004),
    (@GROUP_BSCP_2022_2023_ELECTIVES, @COURSE_CNT_4411),
    (@GROUP_BSCP_2022_2023_ELECTIVES, @COURSE_CNT_4419),
    (@GROUP_BSCP_2022_2023_ELECTIVES, @COURSE_CNT_4800),
    (@GROUP_BSCP_2022_2023_ELECTIVES, @COURSE_COP_4020),
    (@GROUP_BSCP_2022_2023_ELECTIVES, @COURSE_COP_4365),
    (@GROUP_BSCP_2022_2023_ELECTIVES, @COURSE_COP_4520),
    (@GROUP_BSCP_2022_2023_ELECTIVES, @COURSE_COP_4620),
    (@GROUP_BSCP_2022_2023_ELECTIVES, @COURSE_COP_4656),
    (@GROUP_BSCP_2022_2023_ELECTIVES, @COURSE_COP_4710),
    (@GROUP_BSCP_2022_2023_ELECTIVES, @COURSE_COT_4210),
    (@GROUP_BSCP_2022_2023_ELECTIVES, @COURSE_COT_4521),
    
    (@GROUP_BSCP_2023_2024_GECH, @COURSE_ARH_2000),
    (@GROUP_BSCP_2023_2024_GECH, @COURSE_HUM_1020),
    (@GROUP_BSCP_2023_2024_GECH, @COURSE_LIT_2000),
    (@GROUP_BSCP_2023_2024_GECH, @COURSE_MUL_2010),
    (@GROUP_BSCP_2023_2024_GECH, @COURSE_PHI_2010),
    (@GROUP_BSCP_2023_2024_GECH, @COURSE_THE_2000),
    
    (@GROUP_BSCP_2023_2024_GECS, @COURSE_AMH_2020),
    (@GROUP_BSCP_2023_2024_GECS, @COURSE_ANT_2000),
    (@GROUP_BSCP_2023_2024_GECS, @COURSE_ECO_2013),
    (@GROUP_BSCP_2023_2024_GECS, @COURSE_POS_2041),
    (@GROUP_BSCP_2023_2024_GECS, @COURSE_PSY_2012),
    (@GROUP_BSCP_2023_2024_GECS, @COURSE_SYG_2000),
    
    (@GROUP_BSCP_2023_2024_CALC_1, @COURSE_MAC_2281),
    (@GROUP_BSCP_2023_2024_CALC_1, @COURSE_MAC_2311),
    
    (@GROUP_BSCP_2023_2024_CALC_2, @COURSE_MAC_2282),
    (@GROUP_BSCP_2023_2024_CALC_2, @COURSE_MAC_2312),
    
    (@GROUP_BSCP_2023_2024_CALC_3, @COURSE_MAC_2283),
    (@GROUP_BSCP_2023_2024_CALC_3, @COURSE_MAC_2313),
    
    (@GROUP_BSCP_2023_2024_DIFF_EQ, @COURSE_MAP_2302),
    (@GROUP_BSCP_2023_2024_DIFF_EQ, @COURSE_EGN_3433),
    
    (@GROUP_BSCP_2023_2024_CHEM_1, @COURSE_CHM_2045),
    (@GROUP_BSCP_2023_2024_CHEM_1, @COURSE_CHS_2440),
    
    (@GROUP_BSCP_2023_2024_CHEM_1_LAB, @COURSE_CHM_2045L),
    (@GROUP_BSCP_2023_2024_CHEM_1_LAB, @COURSE_CHS_2440L),
    
    (@GROUP_BSCP_2023_2024_HARDWARE_ELECTIVES, @COURSE_CDA_4253),
    (@GROUP_BSCP_2023_2024_HARDWARE_ELECTIVES, @COURSE_CDA_4321),
    (@GROUP_BSCP_2023_2024_HARDWARE_ELECTIVES, @COURSE_CDA_4322),
    (@GROUP_BSCP_2023_2024_HARDWARE_ELECTIVES, @COURSE_CDA_4621),
    
    (@GROUP_BSCP_2023_2024_ELECTIVES, @COURSE_CAP_4034),
    (@GROUP_BSCP_2023_2024_ELECTIVES, @COURSE_CAP_4103),
    (@GROUP_BSCP_2023_2024_ELECTIVES, @COURSE_CAP_4111),
    (@GROUP_BSCP_2023_2024_ELECTIVES, @COURSE_CAP_4160),
    (@GROUP_BSCP_2023_2024_ELECTIVES, @COURSE_CAP_4401),
    (@GROUP_BSCP_2023_2024_ELECTIVES, @COURSE_CAP_4410),
    (@GROUP_BSCP_2023_2024_ELECTIVES, @COURSE_CAP_4621),
    (@GROUP_BSCP_2023_2024_ELECTIVES, @COURSE_CAP_4628),
    (@GROUP_BSCP_2023_2024_ELECTIVES, @COURSE_CAP_4641),
    (@GROUP_BSCP_2023_2024_ELECTIVES, @COURSE_CAP_4662),
    (@GROUP_BSCP_2023_2024_ELECTIVES, @COURSE_CAP_4744),
    (@GROUP_BSCP_2023_2024_ELECTIVES, @COURSE_CDA_4253),
    (@GROUP_BSCP_2023_2024_ELECTIVES, @COURSE_CDA_4321),
    (@GROUP_BSCP_2023_2024_ELECTIVES, @COURSE_CDA_4322),
    (@GROUP_BSCP_2023_2024_ELECTIVES, @COURSE_CDA_4323),
    (@GROUP_BSCP_2023_2024_ELECTIVES, @COURSE_CDA_4621),
    (@GROUP_BSCP_2023_2024_ELECTIVES, @COURSE_CEN_4020),
    (@GROUP_BSCP_2023_2024_ELECTIVES, @COURSE_CEN_4072),
    (@GROUP_BSCP_2023_2024_ELECTIVES, @COURSE_CIS_4212),
    (@GROUP_BSCP_2023_2024_ELECTIVES, @COURSE_CIS_4345),
    (@GROUP_BSCP_2023_2024_ELECTIVES, @COURSE_CIS_4900),
    (@GROUP_BSCP_2023_2024_ELECTIVES, @COURSE_CIS_4915),
    (@GROUP_BSCP_2023_2024_ELECTIVES, @COURSE_CIS_4930),
    (@GROUP_BSCP_2023_2024_ELECTIVES, @COURSE_CIS_4940),
    (@GROUP_BSCP_2023_2024_ELECTIVES, @COURSE_CNT_4004),
    (@GROUP_BSCP_2023_2024_ELECTIVES, @COURSE_CNT_4411),
    (@GROUP_BSCP_2023_2024_ELECTIVES, @COURSE_CNT_4419),
    (@GROUP_BSCP_2023_2024_ELECTIVES, @COURSE_COP_4020),
    (@GROUP_BSCP_2023_2024_ELECTIVES, @COURSE_COP_4365),
    (@GROUP_BSCP_2023_2024_ELECTIVES, @COURSE_COP_4520),
    (@GROUP_BSCP_2023_2024_ELECTIVES, @COURSE_COP_4620),
    (@GROUP_BSCP_2023_2024_ELECTIVES, @COURSE_COP_4656),
    (@GROUP_BSCP_2023_2024_ELECTIVES, @COURSE_COP_4710),
    (@GROUP_BSCP_2023_2024_ELECTIVES, @COURSE_COT_4210),
    (@GROUP_BSCP_2023_2024_ELECTIVES, @COURSE_COT_4521),
    (@GROUP_BSCP_2023_2024_ELECTIVES, @COURSE_COT_4601),

    (@GROUP_BSCS_2022_2023_GECH, @COURSE_ARH_2000),
    (@GROUP_BSCS_2022_2023_GECH, @COURSE_HUM_1020),
    (@GROUP_BSCS_2022_2023_GECH, @COURSE_LIT_2000),
    (@GROUP_BSCS_2022_2023_GECH, @COURSE_MUL_2010),
    (@GROUP_BSCS_2022_2023_GECH, @COURSE_PHI_2010),
    (@GROUP_BSCS_2022_2023_GECH, @COURSE_THE_2000),
    
    (@GROUP_BSCS_2022_2023_GECS, @COURSE_AMH_2020),
    (@GROUP_BSCS_2022_2023_GECS, @COURSE_ANT_2000),
    (@GROUP_BSCS_2022_2023_GECS, @COURSE_ECO_2013),
    (@GROUP_BSCS_2022_2023_GECS, @COURSE_POS_2041),
    (@GROUP_BSCS_2022_2023_GECS, @COURSE_PSY_2012),
    (@GROUP_BSCS_2022_2023_GECS, @COURSE_SYG_2000),
    
    (@GROUP_BSCS_2022_2023_CALC_1, @COURSE_MAC_2281),
    (@GROUP_BSCS_2022_2023_CALC_1, @COURSE_MAC_2311),
    
    (@GROUP_BSCS_2022_2023_CALC_2, @COURSE_MAC_2282),
    (@GROUP_BSCS_2022_2023_CALC_2, @COURSE_MAC_2312),
    
    (@GROUP_BSCS_2022_2023_CALC_3, @COURSE_MAC_2283),
    (@GROUP_BSCS_2022_2023_CALC_3, @COURSE_MAC_2313),
    
    (@GROUP_BSCS_2022_2023_ELECTIVES, @COURSE_CAP_4034),
    (@GROUP_BSCS_2022_2023_ELECTIVES, @COURSE_CAP_4063),
    (@GROUP_BSCS_2022_2023_ELECTIVES, @COURSE_CAP_4111),
    (@GROUP_BSCS_2022_2023_ELECTIVES, @COURSE_CAP_4401),
    (@GROUP_BSCS_2022_2023_ELECTIVES, @COURSE_CAP_4410),
    (@GROUP_BSCS_2022_2023_ELECTIVES, @COURSE_CAP_4662),
    (@GROUP_BSCS_2022_2023_ELECTIVES, @COURSE_CDA_4203),
    (@GROUP_BSCS_2022_2023_ELECTIVES, @COURSE_CDA_4203L),
    (@GROUP_BSCS_2022_2023_ELECTIVES, @COURSE_CDA_4213),
    (@GROUP_BSCS_2022_2023_ELECTIVES, @COURSE_CDA_4213L),
    (@GROUP_BSCS_2022_2023_ELECTIVES, @COURSE_CDA_4253),
    (@GROUP_BSCS_2022_2023_ELECTIVES, @COURSE_CDA_4322),
    (@GROUP_BSCS_2022_2023_ELECTIVES, @COURSE_CDA_4621),
    (@GROUP_BSCS_2022_2023_ELECTIVES, @COURSE_CEN_4072),
    (@GROUP_BSCS_2022_2023_ELECTIVES, @COURSE_CIS_4212),
    (@GROUP_BSCS_2022_2023_ELECTIVES, @COURSE_CIS_4345),
    (@GROUP_BSCS_2022_2023_ELECTIVES, @COURSE_CIS_4364),
    (@GROUP_BSCS_2022_2023_ELECTIVES, @COURSE_CIS_4623),
    (@GROUP_BSCS_2022_2023_ELECTIVES, @COURSE_CIS_4900),
    (@GROUP_BSCS_2022_2023_ELECTIVES, @COURSE_CIS_4910),
    (@GROUP_BSCS_2022_2023_ELECTIVES, @COURSE_CIS_4915),
    (@GROUP_BSCS_2022_2023_ELECTIVES, @COURSE_CIS_4940),
    (@GROUP_BSCS_2022_2023_ELECTIVES, @COURSE_CNT_4004),
    (@GROUP_BSCS_2022_2023_ELECTIVES, @COURSE_CNT_4411),
    (@GROUP_BSCS_2022_2023_ELECTIVES, @COURSE_CNT_4800),
    (@GROUP_BSCS_2022_2023_ELECTIVES, @COURSE_COP_4020),
    (@GROUP_BSCS_2022_2023_ELECTIVES, @COURSE_COP_4365),
    (@GROUP_BSCS_2022_2023_ELECTIVES, @COURSE_COP_4520),
    (@GROUP_BSCS_2022_2023_ELECTIVES, @COURSE_COP_4620),
    (@GROUP_BSCS_2022_2023_ELECTIVES, @COURSE_COP_4656),
    (@GROUP_BSCS_2022_2023_ELECTIVES, @COURSE_COP_4710),
    (@GROUP_BSCS_2022_2023_ELECTIVES, @COURSE_COT_4210),
    (@GROUP_BSCS_2022_2023_ELECTIVES, @COURSE_COT_4521),
    
    (@GROUP_BSCS_2023_2024_GECH, @COURSE_ARH_2000),
    (@GROUP_BSCS_2023_2024_GECH, @COURSE_HUM_1020),
    (@GROUP_BSCS_2023_2024_GECH, @COURSE_LIT_2000),
    (@GROUP_BSCS_2023_2024_GECH, @COURSE_MUL_2010),
    (@GROUP_BSCS_2023_2024_GECH, @COURSE_PHI_2010),
    (@GROUP_BSCS_2023_2024_GECH, @COURSE_THE_2000),
    
    (@GROUP_BSCS_2023_2024_GECS, @COURSE_AMH_2020),
    (@GROUP_BSCS_2023_2024_GECS, @COURSE_ANT_2000),
    (@GROUP_BSCS_2023_2024_GECS, @COURSE_ECO_2013),
    (@GROUP_BSCS_2023_2024_GECS, @COURSE_POS_2041),
    (@GROUP_BSCS_2023_2024_GECS, @COURSE_PSY_2012),
    (@GROUP_BSCS_2023_2024_GECS, @COURSE_SYG_2000),
    
    (@GROUP_BSCS_2023_2024_CALC_1, @COURSE_MAC_2281),
    (@GROUP_BSCS_2023_2024_CALC_1, @COURSE_MAC_2311),
    
    (@GROUP_BSCS_2023_2024_CALC_2, @COURSE_MAC_2282),
    (@GROUP_BSCS_2023_2024_CALC_2, @COURSE_MAC_2312),
    
    (@GROUP_BSCS_2023_2024_CALC_3, @COURSE_MAC_2283),
    (@GROUP_BSCS_2023_2024_CALC_3, @COURSE_MAC_2313),
    
    (@GROUP_BSCS_2023_2024_SOFTWARE_ELECTIVES, @COURSE_CAP_4034),
    (@GROUP_BSCS_2023_2024_SOFTWARE_ELECTIVES, @COURSE_CAP_4103),
    (@GROUP_BSCS_2023_2024_SOFTWARE_ELECTIVES, @COURSE_CAP_4111),
    (@GROUP_BSCS_2023_2024_SOFTWARE_ELECTIVES, @COURSE_CAP_4160),
    (@GROUP_BSCS_2023_2024_SOFTWARE_ELECTIVES, @COURSE_CAP_4401),
    (@GROUP_BSCS_2023_2024_SOFTWARE_ELECTIVES, @COURSE_CAP_4410),
    (@GROUP_BSCS_2023_2024_SOFTWARE_ELECTIVES, @COURSE_CAP_4621),
    (@GROUP_BSCS_2023_2024_SOFTWARE_ELECTIVES, @COURSE_CAP_4628),
    (@GROUP_BSCS_2023_2024_SOFTWARE_ELECTIVES, @COURSE_CAP_4641),
    (@GROUP_BSCS_2023_2024_SOFTWARE_ELECTIVES, @COURSE_CAP_4662),
    (@GROUP_BSCS_2023_2024_SOFTWARE_ELECTIVES, @COURSE_CAP_4744),
    (@GROUP_BSCS_2023_2024_SOFTWARE_ELECTIVES, @COURSE_CDA_4621),
    (@GROUP_BSCS_2023_2024_SOFTWARE_ELECTIVES, @COURSE_CEN_4072),
    (@GROUP_BSCS_2023_2024_SOFTWARE_ELECTIVES, @COURSE_CIS_4345),
    (@GROUP_BSCS_2023_2024_SOFTWARE_ELECTIVES, @COURSE_CNT_4004),
    (@GROUP_BSCS_2023_2024_SOFTWARE_ELECTIVES, @COURSE_CNT_4411),
    (@GROUP_BSCS_2023_2024_SOFTWARE_ELECTIVES, @COURSE_COP_4020),
    (@GROUP_BSCS_2023_2024_SOFTWARE_ELECTIVES, @COURSE_COP_4365),
    (@GROUP_BSCS_2023_2024_SOFTWARE_ELECTIVES, @COURSE_COP_4520),
    (@GROUP_BSCS_2023_2024_SOFTWARE_ELECTIVES, @COURSE_COP_4620),
    (@GROUP_BSCS_2023_2024_SOFTWARE_ELECTIVES, @COURSE_COP_4710),
    
    (@GROUP_BSCS_2023_2024_THEORY_ELECTIVES, @COURSE_CIS_4212),
    (@GROUP_BSCS_2023_2024_THEORY_ELECTIVES, @COURSE_COT_4210),
    (@GROUP_BSCS_2023_2024_THEORY_ELECTIVES, @COURSE_COT_4521),
    (@GROUP_BSCS_2023_2024_THEORY_ELECTIVES, @COURSE_COT_4601),
    
    (@GROUP_BSCS_2023_2024_ELECTIVES, @COURSE_CAP_4034),
    (@GROUP_BSCS_2023_2024_ELECTIVES, @COURSE_CAP_4103),
    (@GROUP_BSCS_2023_2024_ELECTIVES, @COURSE_CAP_4111),
    (@GROUP_BSCS_2023_2024_ELECTIVES, @COURSE_CAP_4160),
    (@GROUP_BSCS_2023_2024_ELECTIVES, @COURSE_CAP_4401),
    (@GROUP_BSCS_2023_2024_ELECTIVES, @COURSE_CAP_4410),
    (@GROUP_BSCS_2023_2024_ELECTIVES, @COURSE_CAP_4628),
    (@GROUP_BSCS_2023_2024_ELECTIVES, @COURSE_CAP_4637),
    (@GROUP_BSCS_2023_2024_ELECTIVES, @COURSE_CAP_4641),
    (@GROUP_BSCS_2023_2024_ELECTIVES, @COURSE_CAP_4662),
    (@GROUP_BSCS_2023_2024_ELECTIVES, @COURSE_CAP_4744),
    (@GROUP_BSCS_2023_2024_ELECTIVES, @COURSE_CDA_4203),
    (@GROUP_BSCS_2023_2024_ELECTIVES, @COURSE_CDA_4203L),
    (@GROUP_BSCS_2023_2024_ELECTIVES, @COURSE_CDA_4213),
    (@GROUP_BSCS_2023_2024_ELECTIVES, @COURSE_CDA_4213L),
    (@GROUP_BSCS_2023_2024_ELECTIVES, @COURSE_CDA_4253),
    (@GROUP_BSCS_2023_2024_ELECTIVES, @COURSE_CDA_4321),
    (@GROUP_BSCS_2023_2024_ELECTIVES, @COURSE_CDA_4322),
    (@GROUP_BSCS_2023_2024_ELECTIVES, @COURSE_CDA_4323),
    (@GROUP_BSCS_2023_2024_ELECTIVES, @COURSE_CDA_4621),
    (@GROUP_BSCS_2023_2024_ELECTIVES, @COURSE_CEN_4072),
    (@GROUP_BSCS_2023_2024_ELECTIVES, @COURSE_CIS_4212),
    (@GROUP_BSCS_2023_2024_ELECTIVES, @COURSE_CIS_4345),
    (@GROUP_BSCS_2023_2024_ELECTIVES, @COURSE_CIS_4900),
    (@GROUP_BSCS_2023_2024_ELECTIVES, @COURSE_CIS_4910),
    (@GROUP_BSCS_2023_2024_ELECTIVES, @COURSE_CIS_4915),
    (@GROUP_BSCS_2023_2024_ELECTIVES, @COURSE_CIS_4930),
    (@GROUP_BSCS_2023_2024_ELECTIVES, @COURSE_CIS_4940),
    (@GROUP_BSCS_2023_2024_ELECTIVES, @COURSE_CNT_4004),
    (@GROUP_BSCS_2023_2024_ELECTIVES, @COURSE_CNT_4411),
    (@GROUP_BSCS_2023_2024_ELECTIVES, @COURSE_COP_4020),
    (@GROUP_BSCS_2023_2024_ELECTIVES, @COURSE_COP_4365),
    (@GROUP_BSCS_2023_2024_ELECTIVES, @COURSE_COP_4520),
    (@GROUP_BSCS_2023_2024_ELECTIVES, @COURSE_COP_4620),
    (@GROUP_BSCS_2023_2024_ELECTIVES, @COURSE_COP_4710),
    (@GROUP_BSCS_2023_2024_ELECTIVES, @COURSE_COT_4210),
    (@GROUP_BSCS_2023_2024_ELECTIVES, @COURSE_COT_4521),
    (@GROUP_BSCS_2023_2024_ELECTIVES, @COURSE_COT_4601),
    
    (@GROUP_BSCYS_2022_2023_GECH, @COURSE_ARH_2000),
    (@GROUP_BSCYS_2022_2023_GECH, @COURSE_HUM_1020),
    (@GROUP_BSCYS_2022_2023_GECH, @COURSE_LIT_2000),
    (@GROUP_BSCYS_2022_2023_GECH, @COURSE_MUL_2010),
    (@GROUP_BSCYS_2022_2023_GECH, @COURSE_PHI_2010),
    (@GROUP_BSCYS_2022_2023_GECH, @COURSE_THE_2000),
    
    (@GROUP_BSCYS_2022_2023_GECS, @COURSE_AMH_2020),
    (@GROUP_BSCYS_2022_2023_GECS, @COURSE_ANT_2000),
    (@GROUP_BSCYS_2022_2023_GECS, @COURSE_ECO_2013),
    (@GROUP_BSCYS_2022_2023_GECS, @COURSE_POS_2041),
    (@GROUP_BSCYS_2022_2023_GECS, @COURSE_PSY_2012),
    (@GROUP_BSCYS_2022_2023_GECS, @COURSE_SYG_2000),
    
    (@GROUP_BSCYS_2022_2023_ELECTIVES, @COURSE_CIS_3360),
    (@GROUP_BSCYS_2022_2023_ELECTIVES, @COURSE_CIS_3362),
    (@GROUP_BSCYS_2022_2023_ELECTIVES, @COURSE_CIS_4203),
    (@GROUP_BSCYS_2022_2023_ELECTIVES, @COURSE_EDG_3801),
    (@GROUP_BSCYS_2022_2023_ELECTIVES, @COURSE_ISM_4041),
    (@GROUP_BSCYS_2022_2023_ELECTIVES, @COURSE_LIS_4779),
    
    (@GROUP_BSCYS_2023_2024_GECH, @COURSE_ARH_2000),
    (@GROUP_BSCYS_2023_2024_GECH, @COURSE_HUM_1020),
    (@GROUP_BSCYS_2023_2024_GECH, @COURSE_LIT_2000),
    (@GROUP_BSCYS_2023_2024_GECH, @COURSE_MUL_2010),
    (@GROUP_BSCYS_2023_2024_GECH, @COURSE_PHI_2010),
    (@GROUP_BSCYS_2023_2024_GECH, @COURSE_THE_2000),
    
    (@GROUP_BSCYS_2023_2024_GECS, @COURSE_AMH_2020),
    (@GROUP_BSCYS_2023_2024_GECS, @COURSE_ANT_2000),
    (@GROUP_BSCYS_2023_2024_GECS, @COURSE_ECO_2013),
    (@GROUP_BSCYS_2023_2024_GECS, @COURSE_POS_2041),
    (@GROUP_BSCYS_2023_2024_GECS, @COURSE_PSY_2012),
    (@GROUP_BSCYS_2023_2024_GECS, @COURSE_SYG_2000),
    
    (@GROUP_BSCYS_2023_2024_ELECTIVES, @COURSE_CAP_4136),
    (@GROUP_BSCYS_2023_2024_ELECTIVES, @COURSE_CIS_4947),
    (@GROUP_BSCYS_2023_2024_ELECTIVES, @COURSE_CNT_4716C),
    (@GROUP_BSCYS_2023_2024_ELECTIVES, @COURSE_COP_4368),
    (@GROUP_BSCYS_2023_2024_ELECTIVES, @COURSE_COP_4900),
    (@GROUP_BSCYS_2023_2024_ELECTIVES, @COURSE_COP_4931),
    (@GROUP_BSCYS_2023_2024_ELECTIVES, @COURSE_CIS_3360),
    (@GROUP_BSCYS_2023_2024_ELECTIVES, @COURSE_CIS_3362),
    (@GROUP_BSCYS_2023_2024_ELECTIVES, @COURSE_CIS_4361),
    (@GROUP_BSCYS_2023_2024_ELECTIVES, @COURSE_LIS_4779),
    (@GROUP_BSCYS_2023_2024_ELECTIVES, @COURSE_CIS_4203),
    (@GROUP_BSCYS_2023_2024_ELECTIVES, @COURSE_CIS_4368),
    (@GROUP_BSCYS_2023_2024_ELECTIVES, @COURSE_ISM_4041),
    (@GROUP_BSCYS_2023_2024_ELECTIVES, @COURSE_EDG_3801),
    
    (@GROUP_BSIT_2022_2023_GECH, @COURSE_ARH_2000),
    (@GROUP_BSIT_2022_2023_GECH, @COURSE_HUM_1020),
    (@GROUP_BSIT_2022_2023_GECH, @COURSE_LIT_2000),
    (@GROUP_BSIT_2022_2023_GECH, @COURSE_MUL_2010),
    (@GROUP_BSIT_2022_2023_GECH, @COURSE_PHI_2010),
    (@GROUP_BSIT_2022_2023_GECH, @COURSE_THE_2000),
    
    (@GROUP_BSIT_2022_2023_GECS, @COURSE_AMH_2020),
    (@GROUP_BSIT_2022_2023_GECS, @COURSE_ANT_2000),
    (@GROUP_BSIT_2022_2023_GECS, @COURSE_ECO_2013),
    (@GROUP_BSIT_2022_2023_GECS, @COURSE_POS_2041),
    (@GROUP_BSIT_2022_2023_GECS, @COURSE_PSY_2012),
    (@GROUP_BSIT_2022_2023_GECS, @COURSE_SYG_2000),
    
    (@GROUP_BSIT_2022_2023_GENERAL_ADDON, @COURSE_CIS_4253),
    
    (@GROUP_BSIT_2022_2023_ELECTIVES, @COURSE_CAP_4136),
    (@GROUP_BSIT_2022_2023_ELECTIVES, @COURSE_CEN_4360),
    (@GROUP_BSIT_2022_2023_ELECTIVES, @COURSE_CIS_4200),
    (@GROUP_BSIT_2022_2023_ELECTIVES, @COURSE_CIS_4361),
    (@GROUP_BSIT_2022_2023_ELECTIVES, @COURSE_CIS_4947),
    (@GROUP_BSIT_2022_2023_ELECTIVES, @COURSE_CNT_4403),
    (@GROUP_BSIT_2022_2023_ELECTIVES, @COURSE_COP_3353),
    (@GROUP_BSIT_2022_2023_ELECTIVES, @COURSE_COP_4564),
    (@GROUP_BSIT_2022_2023_ELECTIVES, @COURSE_COP_4883),
    (@GROUP_BSIT_2022_2023_ELECTIVES, @COURSE_COP_4900),
    (@GROUP_BSIT_2022_2023_ELECTIVES, @COURSE_CTS_4337),
    
    (@GROUP_BSIT_2023_2024_GECH, @COURSE_ARH_2000),
    (@GROUP_BSIT_2023_2024_GECH, @COURSE_HUM_1020),
    (@GROUP_BSIT_2023_2024_GECH, @COURSE_LIT_2000),
    (@GROUP_BSIT_2023_2024_GECH, @COURSE_MUL_2010),
    (@GROUP_BSIT_2023_2024_GECH, @COURSE_PHI_2010),
    (@GROUP_BSIT_2023_2024_GECH, @COURSE_THE_2000),
    
    (@GROUP_BSIT_2023_2024_GECS, @COURSE_AMH_2020),
    (@GROUP_BSIT_2023_2024_GECS, @COURSE_ANT_2000),
    (@GROUP_BSIT_2023_2024_GECS, @COURSE_ECO_2013),
    (@GROUP_BSIT_2023_2024_GECS, @COURSE_POS_2041),
    (@GROUP_BSIT_2023_2024_GECS, @COURSE_PSY_2012),
    (@GROUP_BSIT_2023_2024_GECS, @COURSE_SYG_2000),
    
    (@GROUP_BSIT_2023_2024_GENERAL_ADDON, @COURSE_CIS_4253),
    (@GROUP_BSIT_2023_2024_GENERAL_ADDON, @COURSE_LIS_4414),
    
    (@GROUP_BSIT_2023_2024_ELECTIVES, @COURSE_CAP_4136),
    (@GROUP_BSIT_2023_2024_ELECTIVES, @COURSE_CIS_4947),
    (@GROUP_BSIT_2023_2024_ELECTIVES, @COURSE_CNT_4716C),
    (@GROUP_BSIT_2023_2024_ELECTIVES, @COURSE_COP_3353),
    (@GROUP_BSIT_2023_2024_ELECTIVES, @COURSE_COP_4883),
    (@GROUP_BSIT_2023_2024_ELECTIVES, @COURSE_COP_4900),
    (@GROUP_BSIT_2023_2024_ELECTIVES, @COURSE_COP_4931);


------------------------------------------------------------
-- Course Prereqs
------------------------------------------------------------
INSERT INTO Bellini.CoursePrereq (CourseID, PrereqCourseID, MinGradeRequired)
VALUES
    (@COURSE_CAP_4034, @COURSE_COP_3514, 'C'),
    (@COURSE_CAP_4063, @COURSE_COP_4530, 'C'),
    (@COURSE_CAP_4103, @COURSE_COP_3331, 'C'),
    (@COURSE_CAP_4111, @COURSE_COP_4530, 'C'),
    (@COURSE_CAP_4136, @COURSE_COP_3515, 'C'),
    (@COURSE_CAP_4160, @COURSE_CDA_3201, 'C'),
    (@COURSE_CAP_4401, @COURSE_COP_4530, 'C'),
    (@COURSE_CAP_4410, @COURSE_COP_4530, 'C'),
    (@COURSE_CAP_4621, @COURSE_COP_4530, 'C'),
    (@COURSE_CAP_4628, @COURSE_COP_4530, 'C'),
    (@COURSE_CAP_4637, @COURSE_COP_4530, 'C'),
    (@COURSE_CAP_4641, @COURSE_COP_4530, 'C'),
    (@COURSE_CAP_4662, @COURSE_COP_4530, 'C'),
    (@COURSE_CAP_4662, @COURSE_EGN_4450, 'C'),
    (@COURSE_CAP_4744, @COURSE_COP_4530, 'C'),
    (@COURSE_CAP_4773, @COURSE_COP_4530, 'C'),
    (@COURSE_CAP_4773, @COURSE_CDA_3201, 'C'),
    (@COURSE_CDA_3103, @COURSE_COP_2510, 'C'),
    (@COURSE_CDA_3201, @COURSE_CDA_3103, 'C'),
    (@COURSE_CDA_3201, @COURSE_COP_3514, 'C'),
    (@COURSE_CDA_4203, @COURSE_CDA_3201, 'C'),
    (@COURSE_CDA_4203, @COURSE_CDA_3201L, 'C'),
    (@COURSE_CDA_4205, @COURSE_CDA_3201, 'C'),
    (@COURSE_CDA_4205, @COURSE_CDA_3201L, 'C'),
    (@COURSE_CDA_4205L, @COURSE_CDA_3201, 'C'),
    (@COURSE_CDA_4213, @COURSE_CDA_3201, 'C'),
    (@COURSE_CDA_4213, @COURSE_CDA_3201L, 'C'),
    (@COURSE_CDA_4213L, @COURSE_CDA_3201, 'C'),
    (@COURSE_CDA_4213L, @COURSE_CDA_3201L, 'C'),
    (@COURSE_CDA_4253, @COURSE_CDA_3201, 'C'),
    (@COURSE_CDA_4253, @COURSE_CDA_3201L, 'C'),
    (@COURSE_CDA_4321, @COURSE_CDA_3201, 'C'),
    (@COURSE_CDA_4322, @COURSE_CDA_3201, 'C'),
    (@COURSE_CDA_4322, @COURSE_CDA_3201L, 'C'),
    (@COURSE_CDA_4323, @COURSE_CDA_3201, 'C'),
    (@COURSE_CDA_4323, @COURSE_CDA_3201L, 'C'),
    (@COURSE_CDA_4621, @COURSE_CDA_3201, 'C'),
    (@COURSE_CEN_3722, @COURSE_COP_3515, 'C'),
    (@COURSE_CEN_4020, @COURSE_COP_4530, 'C'),
    (@COURSE_CEN_4072, @COURSE_COP_2510, 'C'),
    (@COURSE_CEN_4072, @COURSE_COP_4530, 'C'),
    (@COURSE_CEN_4360, @COURSE_COP_3515, 'C'),
    (@COURSE_CGS_3303, @COURSE_CGS_1540, 'C'),
    (@COURSE_CGS_3853, @COURSE_CEN_3722, 'C'),
    (@COURSE_CHM_2045L, @COURSE_CHS_2440, 'C'),
    (@COURSE_CIS_3213, @COURSE_COP_2512, 'C'),
    (@COURSE_CIS_3362, @COURSE_MAD_2104, 'C'),
    (@COURSE_CIS_3363, @COURSE_MAD_2104, 'C'),
    (@COURSE_CIS_3363, @COURSE_CIS_3213, 'C'),
    (@COURSE_CIS_3363, @COURSE_COP_2513, 'C'),
    (@COURSE_CIS_3433, @COURSE_CGS_3303, 'C'),
    (@COURSE_CIS_4083, @COURSE_COP_3515, 'C'),
    (@COURSE_CIS_4200, @COURSE_COP_3515, 'C'),
    (@COURSE_CIS_4203, @COURSE_COP_2030, 'C'),
    (@COURSE_CIS_4203, @COURSE_MAD_2104, 'C'),
    (@COURSE_CIS_4219, @COURSE_CIS_3363, 'C'),
    (@COURSE_CIS_4345, @COURSE_COP_3331, 'C'),
    (@COURSE_CIS_4361, @COURSE_COP_3515, 'C'),
    (@COURSE_CIS_4364, @COURSE_COP_4530, 'C'),
    (@COURSE_CIS_4368, @COURSE_COP_3718, 'C'),
    (@COURSE_CIS_4622, @COURSE_COP_2513, 'C'),
    (@COURSE_CIS_4623, @COURSE_COP_3331, 'C'),
    (@COURSE_CIS_4900, @COURSE_COP_4530, 'C'),
    (@COURSE_CIS_4900, @COURSE_CDA_3201, 'C'),
    (@COURSE_CIS_4910, @COURSE_COP_4530, 'C'),
    (@COURSE_CIS_4915, @COURSE_COP_4530, 'C'),
    (@COURSE_CIS_4915, @COURSE_CDA_3201, 'C'),
    (@COURSE_CIS_4930, @COURSE_COP_4530, 'C'),
    (@COURSE_CIS_4930, @COURSE_CDA_3201, 'C'),
    (@COURSE_CIS_4940, @COURSE_COP_4530, 'C'),
    (@COURSE_CIS_4940, @COURSE_CDA_3201, 'C'),
    (@COURSE_CNT_4004, @COURSE_COP_3514, 'C'),
    (@COURSE_CNT_4104, @COURSE_COP_3515, 'C'),
    (@COURSE_CNT_4104L, @COURSE_COP_3515, 'C'),
    (@COURSE_CNT_4403, @COURSE_CNT_4104, 'C'),
    (@COURSE_CNT_4411, @COURSE_COT_3100, 'C'),
    (@COURSE_CNT_4419, @COURSE_COP_4530, 'C'),
    (@COURSE_CNT_4603, @COURSE_CNT_4104, 'C'),
    (@COURSE_CNT_4716C, @COURSE_CNT_4104, 'C'),
    (@COURSE_CNT_4800, @COURSE_COP_4530, 'C'),
    (@COURSE_COP_2510, @COURSE_MAC_2281, 'C'),
    (@COURSE_COP_2513, @COURSE_COP_2512, 'C'),
    (@COURSE_COP_2700, @COURSE_COP_2030, 'C'),
    (@COURSE_COP_3331, @COURSE_COP_3514, 'C'),
    (@COURSE_COP_3353, @COURSE_COP_2512, 'C'),
    (@COURSE_COP_3514, @COURSE_COP_2510, 'C'),
    (@COURSE_COP_3515, @COURSE_MAD_2104, 'C'),
    (@COURSE_COP_3515, @COURSE_COP_2513, 'C'),
    (@COURSE_COP_3718, @COURSE_COP_2700, 'C'),
    (@COURSE_COP_4020, @COURSE_COP_4530, 'C'),
    (@COURSE_COP_4365, @COURSE_COP_4530, 'C'),
    (@COURSE_COP_4368, @COURSE_COP_2513, 'C'),
    (@COURSE_COP_4520, @COURSE_COP_4530, 'C'),
    (@COURSE_COP_4530, @COURSE_COP_3514, 'C'),
    (@COURSE_COP_4530, @COURSE_CDA_3103, 'C'),
    (@COURSE_COP_4538, @COURSE_COP_3515, 'C'),
    (@COURSE_COP_4564, @COURSE_COP_3515, 'C'),
    (@COURSE_COP_4600, @COURSE_COP_4530, 'C'),
    (@COURSE_COP_4620, @COURSE_COP_4530, 'C'),
    (@COURSE_COP_4656, @COURSE_COP_4530, 'C'),
    (@COURSE_COP_4703, @COURSE_COP_4538, 'C'),
    (@COURSE_COP_4710, @COURSE_COP_3331, 'C'),
    (@COURSE_COP_4883, @COURSE_COP_4538, 'C'),
    (@COURSE_COT_3100, @COURSE_MAC_2281, 'C'),
    (@COURSE_COT_4210, @COURSE_COT_3100, 'C'),
    (@COURSE_COT_4400, @COURSE_COT_3100, 'C'),
    (@COURSE_COT_4400, @COURSE_COP_4530, 'C'),
    (@COURSE_COT_4521, @COURSE_COP_4530, 'C'),
    (@COURSE_COT_4521, @COURSE_COT_4400, 'C'),
    (@COURSE_COT_4601, @COURSE_EGN_4450, 'C'),
    (@COURSE_COT_4601, @COURSE_CDA_3103, 'C'),
    (@COURSE_COT_4601, @COURSE_COP_4530, 'C'),
    (@COURSE_CTS_4337, @COURSE_COP_3353, 'C'),
    (@COURSE_EEE_3394, @COURSE_CHS_2440, 'C'),
    (@COURSE_EEE_3394, @COURSE_PHY_2048, 'C'),
    (@COURSE_EGN_3433, @COURSE_MAC_2283, 'C'),
    (@COURSE_EGN_3433, @COURSE_PHY_2049, 'C'),
    (@COURSE_EGN_3443, @COURSE_MAC_2282, 'C'),
    (@COURSE_EGN_4450, @COURSE_MAC_2282, 'C'),
    (@COURSE_ENC_1102, @COURSE_ENC_1101, 'C'),
    (@COURSE_ENC_3246, @COURSE_ENC_1102, 'C'),
    (@COURSE_ISM_3011, @COURSE_CGS_2100, 'C'),
    (@COURSE_ISM_4041, @COURSE_ISM_3011, 'C'),
    (@COURSE_ISM_4323, @COURSE_ISM_3011, 'C'),
    (@COURSE_MAC_1105, @COURSE_MAT_1033, 'C'),
    (@COURSE_MAC_1147, @COURSE_MAC_1105, 'C'),
    (@COURSE_MAC_2281, @COURSE_MAC_1147, 'C'),
    (@COURSE_MAC_2282, @COURSE_MAC_2281, 'C'),
    (@COURSE_MAC_2283, @COURSE_MAC_2282, 'C'),
    (@COURSE_MAC_2311, @COURSE_MAC_1147, 'C'),
    (@COURSE_MAC_2312, @COURSE_MAC_2281, 'C'),
    (@COURSE_MAC_2313, @COURSE_MAC_2282, 'C'),
    (@COURSE_MAP_2302, @COURSE_MAC_2282, 'C'),
    (@COURSE_PHY_2048, @COURSE_MAC_2281, 'C'),
    (@COURSE_PHY_2048L, @COURSE_MAC_2281, 'C'),
    (@COURSE_PHY_2049, @COURSE_PHY_2048L, 'C'),
    (@COURSE_PHY_2049, @COURSE_MAC_2282, 'C'),
    (@COURSE_PHY_2049, @COURSE_PHY_2048, 'C'),
    (@COURSE_PHY_2049L, @COURSE_PHY_2048L, 'C'),
    (@COURSE_PHY_2049L, @COURSE_MAC_2282, 'C'),
    (@COURSE_PHY_2049L, @COURSE_PHY_2048, 'C'),
    (@COURSE_PHY_2053, @COURSE_MAC_1147, 'C'),
    (@COURSE_PHY_2060, @COURSE_MAC_2281, 'C'),
    (@COURSE_STA_2023, @COURSE_MAT_1033, 'C');


------------------------------------------------------------
-- Course Coreqs
------------------------------------------------------------
INSERT INTO Bellini.CourseCoreq (CourseID, CoreqCourseID)
VALUES
    (@COURSE_BSC_2010, @COURSE_BSC_2010L),
    (@COURSE_BSC_2010L, @COURSE_BSC_2010),
    (@COURSE_BSC_2085, @COURSE_BSC_2085L),
    (@COURSE_BSC_2085L, @COURSE_BSC_2085),
    (@COURSE_CAP_4034, @COURSE_COP_4530),
    (@COURSE_CDA_3201, @COURSE_CDA_3201L),
    (@COURSE_CDA_3201L, @COURSE_CDA_3201),
    (@COURSE_CDA_4203L, @COURSE_CDA_4203),
    (@COURSE_CDA_4205L, @COURSE_CDA_4205),
    (@COURSE_CDA_4213L, @COURSE_CDA_4213),
    (@COURSE_CHM_2045L, @COURSE_CHM_2045),
    (@COURSE_CHS_2440L, @COURSE_CHS_2440),
    (@COURSE_CIS_4212, @COURSE_COP_4530),
    (@COURSE_CIS_4364, @COURSE_COP_4600),
    (@COURSE_CNT_4004, @COURSE_COP_4530),
    (@COURSE_CNT_4104, @COURSE_CNT_4104L),
    (@COURSE_CNT_4104L, @COURSE_CNT_4104),
    (@COURSE_CNT_4411, @COURSE_COP_4530),
    (@COURSE_COP_3331, @COURSE_CDA_3103),
    (@COURSE_COP_4710, @COURSE_COP_4530),
    (@COURSE_EEE_3394, @COURSE_MAC_2283),
    (@COURSE_EGN_3373, @COURSE_EGN_3433),
    (@COURSE_PHY_2048, @COURSE_PHY_2048L),
    (@COURSE_PHY_2048L, @COURSE_PHY_2048),
    (@COURSE_PHY_2049, @COURSE_PHY_2049L),
    (@COURSE_PHY_2049L, @COURSE_PHY_2049),
    (@COURSE_PHY_2053, @COURSE_PHY_2053L),
    (@COURSE_PHY_2053L, @COURSE_PHY_2053),
    (@COURSE_PHY_2060, @COURSE_PHY_2048L);




------------------------------------------------------------
-- Students (20 total, across all four majors)
------------------------------------------------------------
INSERT INTO Bellini.Student (USF_ID, FirstName, LastName, MajorID, AdmissionTermID, AdmissionDate, Email, Phone)
VALUES
    ('U000000001','John','Doe',        @MAJOR_BSCS,  @TERM_FALL_2022, '2024-08-20', 'jdoe@usf.edu','813-555-2001'),
    ('U000000002','Jane','Smith',      @MAJOR_BSCS,  @TERM_FALL_2022, '2024-08-20', 'jsmith@usf.edu','813-555-2002'),
    ('U000000003','Alex','Brown',      @MAJOR_BSIT,  @TERM_FALL_2022, '2024-08-20', 'abrown@usf.edu','813-555-2003'),
    ('U000000004','Maria','Lopez',     @MAJOR_BSIT,  @TERM_FALL_2022, '2024-08-20', 'mlopez@usf.edu','813-555-2004'),
    ('U000000005','Luke','Miller',     @MAJOR_BSCP,  @TERM_FALL_2022, '2024-08-20', 'lmiller@usf.edu','813-555-2005'),
    ('U000000006','Sarah','Wilson',    @MAJOR_BSCP,  @TERM_FALL_2022, '2024-08-20', 'swilson@usf.edu','813-555-2006'),
    ('U000000007','Noah','Davis',      @MAJOR_BSCyS, @TERM_FALL_2022, '2024-08-20', 'ndavis@usf.edu','813-555-2007'),
    ('U000000008','Emma','Taylor',     @MAJOR_BSCyS, @TERM_FALL_2022, '2024-08-20', 'etaylor@usf.edu','813-555-2008'),
    ('U000000009','Liam','Clark',      @MAJOR_BSCS,  @TERM_FALL_2022, '2024-08-20', 'lclark@usf.edu','813-555-2009'),
    ('U000000010','Olivia','Lewis',    @MAJOR_BSIT,  @TERM_FALL_2022, '2024-08-20', 'olewis@usf.edu','813-555-2010'),
    ('U000000011','Mason','Hall',      @MAJOR_BSCS,  @TERM_FALL_2023, '2024-08-20', 'mhall@usf.edu','813-555-2011'),
    ('U000000012','Ava','Young',       @MAJOR_BSCP,  @TERM_FALL_2023, '2024-08-20', 'ayoung@usf.edu','813-555-2012'),
    ('U000000013','Ethan','King',      @MAJOR_BSCyS, @TERM_FALL_2023, '2024-08-20', 'eking@usf.edu','813-555-2013'),
    ('U000000014','Sophia','Wright',   @MAJOR_BSIT,  @TERM_FALL_2023, '2024-08-20', 'swright@usf.edu','813-555-2014'),
    ('U000000015','Logan','Scott',     @MAJOR_BSCS,  @TERM_FALL_2023, '2024-08-20', 'lscott@usf.edu','813-555-2015'),
    ('U000000016','Isabella','Green',  @MAJOR_BSCS,  @TERM_FALL_2023, '2024-08-20', 'igreen@usf.edu','813-555-2016'),
    ('U000000017','James','Adams',     @MAJOR_BSIT,  @TERM_FALL_2023, '2024-08-20', 'jadams@usf.edu','813-555-2017'),
    ('U000000018','Mia','Nelson',      @MAJOR_BSCP,  @TERM_FALL_2023, '2024-08-20', 'mnelson@usf.edu','813-555-2018'),
    ('U000000019','Benjamin','Perez',  @MAJOR_BSCyS, @TERM_FALL_2023, '2024-08-20', 'bperez@usf.edu','813-555-2019'),
    ('U000000020','Charlotte','Moore', @MAJOR_BSCS,  @TERM_FALL_2023, '2024-08-20', 'cmoore@usf.edu','813-555-2020');

-- For MajorHistory and TA
SELECT @STUDENT_1  = StudentID FROM Bellini.Student WHERE USF_ID = 'U000000001';
SELECT @STUDENT_2  = StudentID FROM Bellini.Student WHERE USF_ID = 'U000000002';
SELECT @STUDENT_3  = StudentID FROM Bellini.Student WHERE USF_ID = 'U000000003';
SELECT @STUDENT_4  = StudentID FROM Bellini.Student WHERE USF_ID = 'U000000004';
SELECT @STUDENT_5  = StudentID FROM Bellini.Student WHERE USF_ID = 'U000000005';
SELECT @STUDENT_6  = StudentID FROM Bellini.Student WHERE USF_ID = 'U000000006';
SELECT @STUDENT_7  = StudentID FROM Bellini.Student WHERE USF_ID = 'U000000007';
SELECT @STUDENT_8  = StudentID FROM Bellini.Student WHERE USF_ID = 'U000000008';
SELECT @STUDENT_9  = StudentID FROM Bellini.Student WHERE USF_ID = 'U000000009';
SELECT @STUDENT_10 = StudentID FROM Bellini.Student WHERE USF_ID = 'U000000010';
SELECT @STUDENT_11 = StudentID FROM Bellini.Student WHERE USF_ID = 'U000000011';
SELECT @STUDENT_12 = StudentID FROM Bellini.Student WHERE USF_ID = 'U000000012';
SELECT @STUDENT_13 = StudentID FROM Bellini.Student WHERE USF_ID = 'U000000013';
SELECT @STUDENT_14 = StudentID FROM Bellini.Student WHERE USF_ID = 'U000000014';
SELECT @STUDENT_15 = StudentID FROM Bellini.Student WHERE USF_ID = 'U000000015';
SELECT @STUDENT_16 = StudentID FROM Bellini.Student WHERE USF_ID = 'U000000016';
SELECT @STUDENT_17 = StudentID FROM Bellini.Student WHERE USF_ID = 'U000000017';
SELECT @STUDENT_18 = StudentID FROM Bellini.Student WHERE USF_ID = 'U000000018';
SELECT @STUDENT_19 = StudentID FROM Bellini.Student WHERE USF_ID = 'U000000019';
SELECT @STUDENT_20 = StudentID FROM Bellini.Student WHERE USF_ID = 'U000000020';

SELECT @TA_1 = StudentID FROM Bellini.Student WHERE USF_ID = 'U000000001';
SELECT @TA_2 = StudentID FROM Bellini.Student WHERE USF_ID = 'U000000002';


-- MajorHistory (3 students changed majors)
INSERT INTO Bellini.MajorHistory (StudentID, ChangeTermID, ChangeDate, OldMajorID, NewMajorID)
VALUES
    (@STUDENT_1,  @TERM_SPRING_2026, '2025-11-01', @MAJOR_BSIT, @MAJOR_BSCyS),
    (@STUDENT_2,  @TERM_SPRING_2026, '2025-11-05', @MAJOR_BSIT, @MAJOR_BSCS),
    (@STUDENT_3, @TERM_SPRING_2026, '2025-11-10', @MAJOR_BSIT, @MAJOR_BSCP);


------------------------------------------------------------
-- Sections for Fall 2025 and Spring 2026
------------------------------------------------------------
INSERT INTO Bellini.Section (CourseID, TermID, SectionNumber, CRN, Type, Status, Capacity, Location, Schedule, InstructorID)
VALUES
    (@COURSE_COP_2510, @TERM_FALL_2025,  '001', 92001, 'Lecture', 'Open',   30, 'ENB 109', 'MW 09:30-10:45', @INSTRUCTOR_1),
    (@COURSE_COP_3515, @TERM_FALL_2025,  '001', 92002, 'Lecture', 'Open',   30, 'ENB 110', 'TR 11:00-12:15', @INSTRUCTOR_2),
    (@COURSE_CIS_4250, @TERM_FALL_2025,  '001', 92003, 'Lecture', 'Closed', 25, 'ENB 111', 'MW 12:30-13:45', @INSTRUCTOR_3),
    (@COURSE_CIS_4622, @TERM_FALL_2025,  '001', 92004, 'Lecture', 'Open',   20, 'ENB 112', 'TR 14:00-15:15', @INSTRUCTOR_3),

    (@COURSE_COP_2510, @TERM_SPRING_2026,'001', 93001, 'Lecture', 'Open',   30, 'ENB 109', 'MW 09:30-10:45', @INSTRUCTOR_1),
    (@COURSE_COP_3515, @TERM_SPRING_2026,'001', 93002, 'Lecture', 'Open',   30, 'ENB 110', 'TR 11:00-12:15', @INSTRUCTOR_2),
    (@COURSE_CIS_4250, @TERM_SPRING_2026,'001', 93003, 'Lecture', 'Open',   25, 'ENB 111', 'MW 12:30-13:45', @INSTRUCTOR_3),
    (@COURSE_CIS_4622, @TERM_SPRING_2026,'001', 93004, 'Lecture', 'Open',   20, 'ENB 112', 'TR 14:00-15:15', @INSTRUCTOR_3);

SELECT @S_F25_COP2510 = SectionID FROM Bellini.Section WHERE CRN=92001;
SELECT @S_F25_COP3515 = SectionID FROM Bellini.Section WHERE CRN=92002;
SELECT @S_F25_CIS4250 = SectionID FROM Bellini.Section WHERE CRN=92003;
SELECT @S_F25_CIS4622 = SectionID FROM Bellini.Section WHERE CRN=92004;

SELECT @S_S26_COP2510 = SectionID FROM Bellini.Section WHERE CRN=93001;
SELECT @S_S26_COP3515 = SectionID FROM Bellini.Section WHERE CRN=93002;


------------------------------------------------------------
-- Enrollment: Fall 2025 (with grades)
------------------------------------------------------------
/*
-- COP2510 Fall 2025
INSERT INTO Bellini.Enrollment (SectionID, StudentID, EnrollDate, EnrollmentStatus, LetterGrade, NumericGrade, GradePoints)
SELECT @S_F25_COP2510, s.StudentID, '2025-08-27', 'Completed', 'A', 95.00, 4.00
FROM Bellini.Student s
WHERE s.USF_ID IN ('U000000001','U000000002','U000000003','U000000004','U000000005');

-- COP3515 Fall 2025 (mixed grades)
INSERT INTO Bellini.Enrollment (SectionID, StudentID, EnrollDate, EnrollmentStatus, LetterGrade, NumericGrade, GradePoints)
SELECT @S_F25_COP3515, s.StudentID, '2025-08-27', 'Completed',
       CASE s.USF_ID 
         WHEN 'U000000006' THEN 'A'
         WHEN 'U000000007' THEN 'B'
         WHEN 'U000000008' THEN 'C'
         WHEN 'U000000009' THEN 'A'
         ELSE 'B'
       END AS LetterGrade,
       90.00 AS NumericGrade,
       CASE s.USF_ID 
         WHEN 'U000000006' THEN 4.00
         WHEN 'U000000007' THEN 3.00
         WHEN 'U000000008' THEN 2.00
         WHEN 'U000000009' THEN 4.00
         ELSE 3.00
       END AS GradePoints
FROM Bellini.Student s
WHERE s.USF_ID IN ('U000000006','U000000007','U000000008','U000000009','U000000010');

-- CIS4250 Fall 2025
INSERT INTO Bellini.Enrollment (SectionID, StudentID, EnrollDate, EnrollmentStatus, LetterGrade, NumericGrade, GradePoints)
SELECT @S_F25_CIS4250, s.StudentID, '2025-08-27', 'Completed','A',92.00,4.00
FROM Bellini.Student s
WHERE s.USF_ID IN ('U000000011','U000000012','U000000013');

-- CIS4622 Fall 2025
INSERT INTO Bellini.Enrollment (SectionID, StudentID, EnrollDate, EnrollmentStatus, LetterGrade, NumericGrade, GradePoints)
SELECT @S_F25_CIS4622, s.StudentID, '2025-08-27', 'Completed','B',85.00,3.00
FROM Bellini.Student s
WHERE s.USF_ID IN ('U000000019','U000000020');


-- Enrollment: Spring 2026 (registered, no grades yet)
INSERT INTO Bellini.Enrollment (SectionID, StudentID, EnrollDate, EnrollmentStatus, LetterGrade, NumericGrade, GradePoints)
SELECT @S_S26_COP2510, s.StudentID, '2026-01-07', 'Registered', NULL, NULL, NULL
FROM Bellini.Student s
WHERE s.USF_ID IN ('U000000001','U000000002','U000000003');

INSERT INTO Bellini.Enrollment (SectionID, StudentID, EnrollDate, EnrollmentStatus, LetterGrade, NumericGrade, GradePoints)
SELECT @S_S26_COP3515, s.StudentID, '2026-01-07', 'Registered', NULL, NULL, NULL
FROM Bellini.Student s
WHERE s.USF_ID IN ('U000000006','U000000007');


-- TA Assignments: at least 2 students as TAs for a Fall 2025 class
INSERT INTO Bellini.TAAssignment (SectionID, StudentID, Role)
VALUES
    (@S_F25_COP3515, @TA_1, 'TA'),
    (@S_F25_COP3515, @TA_2, 'TA');
*/

------------------------------------------------------------
-- StudyPlans
------------------------------------------------------------
INSERT INTO Bellini.StudyPlan (StudentID, TermID, CourseID)
VALUES
    (@STUDENT_1, @TERM_FALL_2022 , @COURSE_EGN_3000L),
    (@STUDENT_1, @TERM_FALL_2022 , @COURSE_ENC_1101),
    (@STUDENT_1, @TERM_FALL_2022 , @COURSE_MAC_2281),
    (@STUDENT_1, @TERM_FALL_2022 , @COURSE_XXX_ELECTIVE),
    (@STUDENT_1, @TERM_SPRING_2023 , @COURSE_COP_2510),
    (@STUDENT_1, @TERM_SPRING_2023 , @COURSE_ENC_1102),
    (@STUDENT_1, @TERM_SPRING_2023 , @COURSE_MAC_2282),
    (@STUDENT_1, @TERM_SPRING_2023 , @COURSE_PHY_2048),
    (@STUDENT_1, @TERM_SPRING_2023 , @COURSE_PHY_2048L),
    (@STUDENT_1, @TERM_FALL_2023 , @COURSE_CDA_3103),
    (@STUDENT_1, @TERM_FALL_2023 , @COURSE_COP_3514),
    (@STUDENT_1, @TERM_FALL_2023 , @COURSE_MAC_2283),
    (@STUDENT_1, @TERM_FALL_2023 , @COURSE_PHY_2049),
    (@STUDENT_1, @TERM_FALL_2023 , @COURSE_PHY_2049L),
    (@STUDENT_1, @TERM_SPRING_2024 , @COURSE_CDA_3201),
    (@STUDENT_1, @TERM_SPRING_2024 , @COURSE_CDA_3201L),
    (@STUDENT_1, @TERM_SPRING_2024 , @COURSE_COP_4530),
    (@STUDENT_1, @TERM_SPRING_2024 , @COURSE_COT_3100),
    (@STUDENT_1, @TERM_SPRING_2024 , @COURSE_XXX_ELECTIVE),
    (@STUDENT_1, @TERM_SUMMER_2024 , @COURSE_EGN_3443),
    (@STUDENT_1, @TERM_SUMMER_2024 , @COURSE_XXX_ELECTIVE),
    (@STUDENT_1, @TERM_SUMMER_2024 , @COURSE_XXX_ELECTIVE),
    (@STUDENT_1, @TERM_FALL_2024 , @COURSE_CDA_4205),
    (@STUDENT_1, @TERM_FALL_2024 , @COURSE_CDA_4205L),
    (@STUDENT_1, @TERM_FALL_2024 , @COURSE_XXX_ELECTIVE),
    (@STUDENT_1, @TERM_FALL_2024 , @COURSE_XXX_ELECTIVE),
    (@STUDENT_1, @TERM_FALL_2024 , @COURSE_EGN_4450),
    (@STUDENT_1, @TERM_FALL_2024 , @COURSE_XXX_ELECTIVE),
    (@STUDENT_1, @TERM_SPRING_2025 , @COURSE_COT_4400),
    (@STUDENT_1, @TERM_SPRING_2025 , @COURSE_XXX_ELECTIVE),
    (@STUDENT_1, @TERM_SPRING_2025 , @COURSE_XXX_ELECTIVE),
    (@STUDENT_1, @TERM_SPRING_2025 , @COURSE_ENC_3246),
    (@STUDENT_1, @TERM_SPRING_2025 , @COURSE_XXX_ELECTIVE),
    (@STUDENT_1, @TERM_FALL_2025 , @COURSE_CNT_4419),
    (@STUDENT_1, @TERM_FALL_2025 , @COURSE_COP_4600),
    (@STUDENT_1, @TERM_FALL_2025 , @COURSE_XXX_ELECTIVE),
    (@STUDENT_1, @TERM_FALL_2025 , @COURSE_XXX_ELECTIVE),
    (@STUDENT_1, @TERM_FALL_2025 , @COURSE_XXX_ELECTIVE),
    (@STUDENT_1, @TERM_SPRING_2026 , @COURSE_CEN_4020),
    (@STUDENT_1, @TERM_SPRING_2026 , @COURSE_CIS_4250),
    (@STUDENT_1, @TERM_SPRING_2026 , @COURSE_XXX_ELECTIVE),
    (@STUDENT_1, @TERM_SPRING_2026 , @COURSE_XXX_ELECTIVE),

    (@STUDENT_2, @TERM_FALL_2022 , @COURSE_EGN_3000),
    (@STUDENT_2, @TERM_FALL_2022 , @COURSE_EGN_3000L),
    (@STUDENT_2, @TERM_FALL_2022 , @COURSE_ENC_1101),
    (@STUDENT_2, @TERM_FALL_2022 , @COURSE_MAC_2281),
    (@STUDENT_2, @TERM_FALL_2022 , @COURSE_XXX_ELECTIVE),
    (@STUDENT_2, @TERM_SPRING_2023 , @COURSE_COP_2510),
    (@STUDENT_2, @TERM_SPRING_2023 , @COURSE_ENC_1102),
    (@STUDENT_2, @TERM_SPRING_2023 , @COURSE_MAC_2282),
    (@STUDENT_2, @TERM_SPRING_2023 , @COURSE_PHY_2048),
    (@STUDENT_2, @TERM_SPRING_2023 , @COURSE_PHY_2048L),
    (@STUDENT_2, @TERM_FALL_2023 , @COURSE_CDA_3103),
    (@STUDENT_2, @TERM_FALL_2023 , @COURSE_COP_3514),
    (@STUDENT_2, @TERM_FALL_2023 , @COURSE_MAC_2283),
    (@STUDENT_2, @TERM_FALL_2023 , @COURSE_PHY_2049),
    (@STUDENT_2, @TERM_FALL_2023 , @COURSE_PHY_2049L),
    (@STUDENT_2, @TERM_SPRING_2024 , @COURSE_CDA_3201),
    (@STUDENT_2, @TERM_SPRING_2024 , @COURSE_CDA_3201L),
    (@STUDENT_2, @TERM_SPRING_2024 , @COURSE_COP_4530),
    (@STUDENT_2, @TERM_SPRING_2024 , @COURSE_COT_3100),
    (@STUDENT_2, @TERM_SPRING_2024 , @COURSE_XXX_ELECTIVE),
    (@STUDENT_2, @TERM_SUMMER_2024 , @COURSE_EGN_3443),
    (@STUDENT_2, @TERM_SUMMER_2024 , @COURSE_XXX_ELECTIVE),
    (@STUDENT_2, @TERM_SUMMER_2024 , @COURSE_XXX_ELECTIVE),
    (@STUDENT_2, @TERM_FALL_2024 , @COURSE_CDA_4205),
    (@STUDENT_2, @TERM_FALL_2024 , @COURSE_CDA_4205L),
    (@STUDENT_2, @TERM_FALL_2024 , @COURSE_XXX_ELECTIVE),
    (@STUDENT_2, @TERM_FALL_2024 , @COURSE_XXX_ELECTIVE),
    (@STUDENT_2, @TERM_FALL_2024 , @COURSE_EGN_4450),
    (@STUDENT_2, @TERM_FALL_2024 , @COURSE_XXX_ELECTIVE),
    (@STUDENT_2, @TERM_SPRING_2025 , @COURSE_COT_4400),
    (@STUDENT_2, @TERM_SPRING_2025 , @COURSE_XXX_ELECTIVE),
    (@STUDENT_2, @TERM_SPRING_2025 , @COURSE_XXX_ELECTIVE),
    (@STUDENT_2, @TERM_SPRING_2025 , @COURSE_ENC_3246),
    (@STUDENT_2, @TERM_SPRING_2025 , @COURSE_XXX_ELECTIVE),
    (@STUDENT_2, @TERM_FALL_2025 , @COURSE_CNT_4419),
    (@STUDENT_2, @TERM_FALL_2025 , @COURSE_COP_4600),
    (@STUDENT_2, @TERM_FALL_2025 , @COURSE_XXX_ELECTIVE),
    (@STUDENT_2, @TERM_FALL_2025 , @COURSE_XXX_ELECTIVE),
    (@STUDENT_2, @TERM_FALL_2025 , @COURSE_XXX_ELECTIVE),
    (@STUDENT_2, @TERM_SPRING_2026 , @COURSE_CEN_4020),
    (@STUDENT_2, @TERM_SPRING_2026 , @COURSE_CIS_4250),
    (@STUDENT_2, @TERM_SPRING_2026 , @COURSE_XXX_ELECTIVE),
    (@STUDENT_2, @TERM_SPRING_2026 , @COURSE_XXX_ELECTIVE),

    (@STUDENT_3, @TERM_FALL_2022 , @COURSE_CGS_1540),
    (@STUDENT_3, @TERM_FALL_2022 , @COURSE_EGN_3000),
    (@STUDENT_3, @TERM_FALL_2022 , @COURSE_EGN_3000L),
    (@STUDENT_3, @TERM_FALL_2022 , @COURSE_ENC_1101),
    (@STUDENT_3, @TERM_FALL_2022 , @COURSE_MAC_1147),
    (@STUDENT_3, @TERM_SPRING_2023 , @COURSE_COP_2512),
    (@STUDENT_3, @TERM_SPRING_2023 , @COURSE_ENC_1102),
    (@STUDENT_3, @TERM_SPRING_2023 , @COURSE_MAD_2104),
    (@STUDENT_3, @TERM_SPRING_2023 , @COURSE_PHY_2020),
    (@STUDENT_3, @TERM_SPRING_2023 , @COURSE_XXX_ELECTIVE),
    (@STUDENT_3, @TERM_FALL_2023 , @COURSE_CGS_3303),
    (@STUDENT_3, @TERM_FALL_2023 , @COURSE_COP_2513),
    (@STUDENT_3, @TERM_FALL_2023 , @COURSE_ECO_2013),
    (@STUDENT_3, @TERM_FALL_2023 , @COURSE_STA_2023),
    (@STUDENT_3, @TERM_SPRING_2024 , @COURSE_CIS_3213),
    (@STUDENT_3, @TERM_SPRING_2024 , @COURSE_COP_3515),
    (@STUDENT_3, @TERM_SPRING_2024 , @COURSE_INR_3033),
    (@STUDENT_3, @TERM_SPRING_2024 , @COURSE_PSY_2012),
    (@STUDENT_3, @TERM_SUMMER_2024 , @COURSE_XXX_ELECTIVE),
    (@STUDENT_3, @TERM_SUMMER_2024 , @COURSE_XXX_ELECTIVE),
    (@STUDENT_3, @TERM_SUMMER_2024 , @COURSE_XXX_ELECTIVE),
    (@STUDENT_3, @TERM_FALL_2024 , @COURSE_CEN_3722),
    (@STUDENT_3, @TERM_FALL_2024 , @COURSE_CIS_3433),
    (@STUDENT_3, @TERM_FALL_2024 , @COURSE_COP_4538),
    (@STUDENT_3, @TERM_FALL_2024 , @COURSE_XXX_ELECTIVE),
    (@STUDENT_3, @TERM_FALL_2024 , @COURSE_XXX_ELECTIVE),
    (@STUDENT_3, @TERM_SPRING_2025 , @COURSE_CGS_3853),
    (@STUDENT_3, @TERM_SPRING_2025 , @COURSE_CNT_4104),
    (@STUDENT_3, @TERM_SPRING_2025 , @COURSE_CNT_4104L),
    (@STUDENT_3, @TERM_SPRING_2025 , @COURSE_ENC_3246),
    (@STUDENT_3, @TERM_SPRING_2025 , @COURSE_XXX_ELECTIVE),
    (@STUDENT_3, @TERM_SPRING_2025 , @COURSE_XXX_ELECTIVE),
    (@STUDENT_3, @TERM_FALL_2025 , @COURSE_XXX_ELECTIVE),
    (@STUDENT_3, @TERM_FALL_2025 , @COURSE_XXX_ELECTIVE),
    (@STUDENT_3, @TERM_FALL_2025 , @COURSE_CIS_4083),
    (@STUDENT_3, @TERM_FALL_2025 , @COURSE_CNT_4603),
    (@STUDENT_3, @TERM_FALL_2025 , @COURSE_COP_4703),
    (@STUDENT_3, @TERM_SPRING_2026 , @COURSE_XXX_ELECTIVE),
    (@STUDENT_3, @TERM_SPRING_2026 , @COURSE_XXX_ELECTIVE),
    (@STUDENT_3, @TERM_SPRING_2026 , @COURSE_CIS_4253),
    (@STUDENT_3, @TERM_SPRING_2026 , @COURSE_CIS_4935),

    (@STUDENT_4, @TERM_FALL_2022 , @COURSE_CGS_1540),
    (@STUDENT_4, @TERM_FALL_2022 , @COURSE_EGN_3000),
    (@STUDENT_4, @TERM_FALL_2022 , @COURSE_EGN_3000L),
    (@STUDENT_4, @TERM_FALL_2022 , @COURSE_ENC_1101),
    (@STUDENT_4, @TERM_FALL_2022 , @COURSE_MAC_1147),
    (@STUDENT_4, @TERM_SPRING_2023 , @COURSE_COP_2512),
    (@STUDENT_4, @TERM_SPRING_2023 , @COURSE_ENC_1102),
    (@STUDENT_4, @TERM_SPRING_2023 , @COURSE_MAD_2104),
    (@STUDENT_4, @TERM_SPRING_2023 , @COURSE_PHY_2020),
    (@STUDENT_4, @TERM_SPRING_2023 , @COURSE_XXX_ELECTIVE),
    (@STUDENT_4, @TERM_FALL_2023 , @COURSE_CGS_3303),
    (@STUDENT_4, @TERM_FALL_2023 , @COURSE_COP_2513),
    (@STUDENT_4, @TERM_FALL_2023 , @COURSE_ECO_2013),
    (@STUDENT_4, @TERM_FALL_2023 , @COURSE_STA_2023),
    (@STUDENT_4, @TERM_SPRING_2024 , @COURSE_CIS_3213),
    (@STUDENT_4, @TERM_SPRING_2024 , @COURSE_COP_3515),
    (@STUDENT_4, @TERM_SPRING_2024 , @COURSE_INR_3033),
    (@STUDENT_4, @TERM_SPRING_2024 , @COURSE_PSY_2012),
    (@STUDENT_4, @TERM_SUMMER_2024 , @COURSE_XXX_ELECTIVE),
    (@STUDENT_4, @TERM_SUMMER_2024 , @COURSE_XXX_ELECTIVE),
    (@STUDENT_4, @TERM_SUMMER_2024 , @COURSE_XXX_ELECTIVE),
    (@STUDENT_4, @TERM_FALL_2024 , @COURSE_CEN_3722),
    (@STUDENT_4, @TERM_FALL_2024 , @COURSE_CIS_3433),
    (@STUDENT_4, @TERM_FALL_2024 , @COURSE_COP_4538),
    (@STUDENT_4, @TERM_FALL_2024 , @COURSE_XXX_ELECTIVE),
    (@STUDENT_4, @TERM_FALL_2024 , @COURSE_XXX_ELECTIVE),
    (@STUDENT_4, @TERM_SPRING_2025 , @COURSE_CGS_3853),
    (@STUDENT_4, @TERM_SPRING_2025 , @COURSE_CNT_4104),
    (@STUDENT_4, @TERM_SPRING_2025 , @COURSE_CNT_4104L),
    (@STUDENT_4, @TERM_SPRING_2025 , @COURSE_ENC_3246),
    (@STUDENT_4, @TERM_SPRING_2025 , @COURSE_XXX_ELECTIVE),
    (@STUDENT_4, @TERM_SPRING_2025 , @COURSE_XXX_ELECTIVE),
    (@STUDENT_4, @TERM_FALL_2025 , @COURSE_XXX_ELECTIVE),
    (@STUDENT_4, @TERM_FALL_2025 , @COURSE_XXX_ELECTIVE),
    (@STUDENT_4, @TERM_FALL_2025 , @COURSE_CIS_4083),
    (@STUDENT_4, @TERM_FALL_2025 , @COURSE_CNT_4603),
    (@STUDENT_4, @TERM_FALL_2025 , @COURSE_COP_4703),
    (@STUDENT_4, @TERM_SPRING_2026 , @COURSE_XXX_ELECTIVE),
    (@STUDENT_4, @TERM_SPRING_2026 , @COURSE_XXX_ELECTIVE),
    (@STUDENT_4, @TERM_SPRING_2026 , @COURSE_CIS_4253),
    (@STUDENT_4, @TERM_SPRING_2026 , @COURSE_CIS_4935),

    (@STUDENT_5, @TERM_FALL_2022 , @COURSE_CHM_2045),
    (@STUDENT_5, @TERM_FALL_2022 , @COURSE_CHM_2045L),
    (@STUDENT_5, @TERM_FALL_2022 , @COURSE_EGN_3000),
    (@STUDENT_5, @TERM_FALL_2022 , @COURSE_EGN_3000L),
    (@STUDENT_5, @TERM_FALL_2022 , @COURSE_ENC_1101),
    (@STUDENT_5, @TERM_FALL_2022 , @COURSE_MAC_2281),
    (@STUDENT_5, @TERM_SPRING_2023 , @COURSE_COP_2510),
    (@STUDENT_5, @TERM_SPRING_2023 , @COURSE_ENC_1102),
    (@STUDENT_5, @TERM_SPRING_2023 , @COURSE_MAC_2282),
    (@STUDENT_5, @TERM_SPRING_2023 , @COURSE_PHY_2048),
    (@STUDENT_5, @TERM_SPRING_2023 , @COURSE_PHY_2048L),
    (@STUDENT_5, @TERM_FALL_2023 , @COURSE_CDA_3103),
    (@STUDENT_5, @TERM_FALL_2023 , @COURSE_COP_3514),
    (@STUDENT_5, @TERM_FALL_2023 , @COURSE_MAC_2283),
    (@STUDENT_5, @TERM_FALL_2023 , @COURSE_PHY_2049),
    (@STUDENT_5, @TERM_FALL_2023 , @COURSE_PHY_2049L),
    (@STUDENT_5, @TERM_SPRING_2024 , @COURSE_CDA_3201),
    (@STUDENT_5, @TERM_SPRING_2024 , @COURSE_CDA_3201L),
    (@STUDENT_5, @TERM_SPRING_2024 , @COURSE_COP_4530),
    (@STUDENT_5, @TERM_SPRING_2024 , @COURSE_COT_3100),
    (@STUDENT_5, @TERM_SPRING_2024 , @COURSE_EGN_3433),
    (@STUDENT_5, @TERM_SPRING_2024 , @COURSE_XXX_ELECTIVE),
    (@STUDENT_5, @TERM_SUMMER_2024 , @COURSE_EGN_3443),
    (@STUDENT_5, @TERM_SUMMER_2024 , @COURSE_XXX_ELECTIVE),
    (@STUDENT_5, @TERM_SUMMER_2024 , @COURSE_XXX_ELECTIVE),
    (@STUDENT_5, @TERM_FALL_2024 , @COURSE_CDA_4205),
    (@STUDENT_5, @TERM_FALL_2024 , @COURSE_CDA_4205L),
    (@STUDENT_5, @TERM_FALL_2024 , @COURSE_EEE_3394),
    (@STUDENT_5, @TERM_FALL_2024 , @COURSE_EGN_3373),
    (@STUDENT_5, @TERM_FALL_2024 , @COURSE_EGN_3615),
    (@STUDENT_5, @TERM_FALL_2024 , @COURSE_EGN_4450),
    (@STUDENT_5, @TERM_SPRING_2025 , @COURSE_CDA_4203),
    (@STUDENT_5, @TERM_SPRING_2025 , @COURSE_CDA_4203L),
    (@STUDENT_5, @TERM_SPRING_2025 , @COURSE_COT_4400),
    (@STUDENT_5, @TERM_SPRING_2025 , @COURSE_XXX_ELECTIVE),
    (@STUDENT_5, @TERM_SPRING_2025 , @COURSE_XXX_ELECTIVE),
    (@STUDENT_5, @TERM_FALL_2025 , @COURSE_CDA_4213),
    (@STUDENT_5, @TERM_FALL_2025 , @COURSE_CDA_4213L),
    (@STUDENT_5, @TERM_FALL_2025 , @COURSE_COP_4600),
    (@STUDENT_5, @TERM_FALL_2025 , @COURSE_XXX_ELECTIVE),
    (@STUDENT_5, @TERM_FALL_2025 , @COURSE_ENC_3246),
    (@STUDENT_5, @TERM_SPRING_2026 , @COURSE_CIS_4250),
    (@STUDENT_5, @TERM_SPRING_2026 , @COURSE_CIS_4910),
    (@STUDENT_5, @TERM_SPRING_2026 , @COURSE_XXX_ELECTIVE),
    (@STUDENT_5, @TERM_SPRING_2026 , @COURSE_XXX_ELECTIVE),

    (@STUDENT_6, @TERM_FALL_2022 , @COURSE_CHM_2045),
    (@STUDENT_6, @TERM_FALL_2022 , @COURSE_CHM_2045L),
    (@STUDENT_6, @TERM_FALL_2022 , @COURSE_EGN_3000),
    (@STUDENT_6, @TERM_FALL_2022 , @COURSE_EGN_3000L),
    (@STUDENT_6, @TERM_FALL_2022 , @COURSE_ENC_1101),
    (@STUDENT_6, @TERM_FALL_2022 , @COURSE_MAC_2281),
    (@STUDENT_6, @TERM_SPRING_2023 , @COURSE_COP_2510),
    (@STUDENT_6, @TERM_SPRING_2023 , @COURSE_ENC_1102),
    (@STUDENT_6, @TERM_SPRING_2023 , @COURSE_MAC_2282),
    (@STUDENT_6, @TERM_SPRING_2023 , @COURSE_PHY_2048),
    (@STUDENT_6, @TERM_SPRING_2023 , @COURSE_PHY_2048L),
    (@STUDENT_6, @TERM_FALL_2023 , @COURSE_CDA_3103),
    (@STUDENT_6, @TERM_FALL_2023 , @COURSE_COP_3514),
    (@STUDENT_6, @TERM_FALL_2023 , @COURSE_MAC_2283),
    (@STUDENT_6, @TERM_FALL_2023 , @COURSE_PHY_2049),
    (@STUDENT_6, @TERM_FALL_2023 , @COURSE_PHY_2049L),
    (@STUDENT_6, @TERM_SPRING_2024 , @COURSE_CDA_3201),
    (@STUDENT_6, @TERM_SPRING_2024 , @COURSE_CDA_3201L),
    (@STUDENT_6, @TERM_SPRING_2024 , @COURSE_COP_4530),
    (@STUDENT_6, @TERM_SPRING_2024 , @COURSE_COT_3100),
    (@STUDENT_6, @TERM_SPRING_2024 , @COURSE_EGN_3433),
    (@STUDENT_6, @TERM_SPRING_2024 , @COURSE_XXX_ELECTIVE),
    (@STUDENT_6, @TERM_SUMMER_2024 , @COURSE_EGN_3443),
    (@STUDENT_6, @TERM_SUMMER_2024 , @COURSE_XXX_ELECTIVE),
    (@STUDENT_6, @TERM_SUMMER_2024 , @COURSE_XXX_ELECTIVE),
    (@STUDENT_6, @TERM_FALL_2024 , @COURSE_CDA_4205),
    (@STUDENT_6, @TERM_FALL_2024 , @COURSE_CDA_4205L),
    (@STUDENT_6, @TERM_FALL_2024 , @COURSE_EEE_3394),
    (@STUDENT_6, @TERM_FALL_2024 , @COURSE_EGN_3373),
    (@STUDENT_6, @TERM_FALL_2024 , @COURSE_EGN_3615),
    (@STUDENT_6, @TERM_FALL_2024 , @COURSE_EGN_4450),
    (@STUDENT_6, @TERM_SPRING_2025 , @COURSE_CDA_4203),
    (@STUDENT_6, @TERM_SPRING_2025 , @COURSE_CDA_4203L),
    (@STUDENT_6, @TERM_SPRING_2025 , @COURSE_COT_4400),
    (@STUDENT_6, @TERM_SPRING_2025 , @COURSE_XXX_ELECTIVE),
    (@STUDENT_6, @TERM_SPRING_2025 , @COURSE_XXX_ELECTIVE),
    (@STUDENT_6, @TERM_FALL_2025 , @COURSE_CDA_4213),
    (@STUDENT_6, @TERM_FALL_2025 , @COURSE_CDA_4213L),
    (@STUDENT_6, @TERM_FALL_2025 , @COURSE_COP_4600),
    (@STUDENT_6, @TERM_FALL_2025 , @COURSE_XXX_ELECTIVE),
    (@STUDENT_6, @TERM_FALL_2025 , @COURSE_ENC_3246),
    (@STUDENT_6, @TERM_SPRING_2026 , @COURSE_CIS_4250),
    (@STUDENT_6, @TERM_SPRING_2026 , @COURSE_CIS_4910),
    (@STUDENT_6, @TERM_SPRING_2026 , @COURSE_XXX_ELECTIVE),
    (@STUDENT_6, @TERM_SPRING_2026 , @COURSE_XXX_ELECTIVE),

    (@STUDENT_7, @TERM_FALL_2022 , @COURSE_EGN_3000),
    (@STUDENT_7, @TERM_FALL_2022 , @COURSE_EGN_3000L),
    (@STUDENT_7, @TERM_FALL_2022 , @COURSE_ENC_1101),
    (@STUDENT_7, @TERM_FALL_2022 , @COURSE_MAC_1147),
    (@STUDENT_7, @TERM_SPRING_2023 , @COURSE_COP_2512),
    (@STUDENT_7, @TERM_SPRING_2023 , @COURSE_ENC_1102),
    (@STUDENT_7, @TERM_SPRING_2023 , @COURSE_MAD_2104),
    (@STUDENT_7, @TERM_SPRING_2023 , @COURSE_PHY_2020),
    (@STUDENT_7, @TERM_SPRING_2023 , @COURSE_XXX_ELECTIVE),
    (@STUDENT_7, @TERM_FALL_2023 , @COURSE_CGS_3303),
    (@STUDENT_7, @TERM_FALL_2023 , @COURSE_COP_2513),
    (@STUDENT_7, @TERM_FALL_2023 , @COURSE_ECO_2013),
    (@STUDENT_7, @TERM_FALL_2023 , @COURSE_STA_2023),
    (@STUDENT_7, @TERM_SPRING_2024 , @COURSE_CIS_3213),
    (@STUDENT_7, @TERM_SPRING_2024 , @COURSE_COP_3515),
    (@STUDENT_7, @TERM_SPRING_2024 , @COURSE_PSY_2012),
    (@STUDENT_7, @TERM_SPRING_2024 , @COURSE_XXX_ELECTIVE),
    (@STUDENT_7, @TERM_SUMMER_2024 , @COURSE_XXX_ELECTIVE),
    (@STUDENT_7, @TERM_SUMMER_2024 , @COURSE_XXX_ELECTIVE),
    (@STUDENT_7, @TERM_SUMMER_2024 , @COURSE_XXX_ELECTIVE),
    (@STUDENT_7, @TERM_FALL_2024 , @COURSE_CEN_3722),
    (@STUDENT_7, @TERM_FALL_2024 , @COURSE_CIS_3363),
    (@STUDENT_7, @TERM_FALL_2024 , @COURSE_CIS_4622),
    (@STUDENT_7, @TERM_FALL_2024 , @COURSE_COP_4538),
    (@STUDENT_7, @TERM_FALL_2024 , @COURSE_ISM_4323),
    (@STUDENT_7, @TERM_SPRING_2025 , @COURSE_CGS_3853),
    (@STUDENT_7, @TERM_SPRING_2025 , @COURSE_CIS_4219),
    (@STUDENT_7, @TERM_SPRING_2025 , @COURSE_CNT_4104),
    (@STUDENT_7, @TERM_SPRING_2025 , @COURSE_CNT_4104L),
    (@STUDENT_7, @TERM_SPRING_2025 , @COURSE_XXX_ELECTIVE),
    (@STUDENT_7, @TERM_SPRING_2025 , @COURSE_ENC_3246),
    (@STUDENT_7, @TERM_FALL_2025 , @COURSE_XXX_ELECTIVE),
    (@STUDENT_7, @TERM_FALL_2025 , @COURSE_CIS_4200),
    (@STUDENT_7, @TERM_FALL_2025 , @COURSE_CNT_4403),
    (@STUDENT_7, @TERM_FALL_2025 , @COURSE_COP_4703),
    (@STUDENT_7, @TERM_FALL_2025 , @COURSE_XXX_ELECTIVE),
    (@STUDENT_7, @TERM_SPRING_2026 , @COURSE_XXX_ELECTIVE),
    (@STUDENT_7, @TERM_SPRING_2026 , @COURSE_CIS_4935),
    (@STUDENT_7, @TERM_SPRING_2026 , @COURSE_XXX_ELECTIVE),
    (@STUDENT_7, @TERM_SPRING_2026 , @COURSE_LIS_4414),

    (@STUDENT_8, @TERM_FALL_2022 , @COURSE_EGN_3000),
    (@STUDENT_8, @TERM_FALL_2022 , @COURSE_EGN_3000L),
    (@STUDENT_8, @TERM_FALL_2022 , @COURSE_ENC_1101),
    (@STUDENT_8, @TERM_FALL_2022 , @COURSE_MAC_1147),
    (@STUDENT_8, @TERM_SPRING_2023 , @COURSE_COP_2512),
    (@STUDENT_8, @TERM_SPRING_2023 , @COURSE_ENC_1102),
    (@STUDENT_8, @TERM_SPRING_2023 , @COURSE_MAD_2104),
    (@STUDENT_8, @TERM_SPRING_2023 , @COURSE_PHY_2020),
    (@STUDENT_8, @TERM_SPRING_2023 , @COURSE_XXX_ELECTIVE),
    (@STUDENT_8, @TERM_FALL_2023 , @COURSE_CGS_3303),
    (@STUDENT_8, @TERM_FALL_2023 , @COURSE_COP_2513),
    (@STUDENT_8, @TERM_FALL_2023 , @COURSE_ECO_2013),
    (@STUDENT_8, @TERM_FALL_2023 , @COURSE_STA_2023),
    (@STUDENT_8, @TERM_SPRING_2024 , @COURSE_CIS_3213),
    (@STUDENT_8, @TERM_SPRING_2024 , @COURSE_COP_3515),
    (@STUDENT_8, @TERM_SPRING_2024 , @COURSE_PSY_2012),
    (@STUDENT_8, @TERM_SPRING_2024 , @COURSE_XXX_ELECTIVE),
    (@STUDENT_8, @TERM_SUMMER_2024 , @COURSE_XXX_ELECTIVE),
    (@STUDENT_8, @TERM_SUMMER_2024 , @COURSE_XXX_ELECTIVE),
    (@STUDENT_8, @TERM_SUMMER_2024 , @COURSE_XXX_ELECTIVE),
    (@STUDENT_8, @TERM_FALL_2024 , @COURSE_CEN_3722),
    (@STUDENT_8, @TERM_FALL_2024 , @COURSE_CIS_3363),
    (@STUDENT_8, @TERM_FALL_2024 , @COURSE_CIS_4622),
    (@STUDENT_8, @TERM_FALL_2024 , @COURSE_COP_4538),
    (@STUDENT_8, @TERM_FALL_2024 , @COURSE_ISM_4323),
    (@STUDENT_8, @TERM_SPRING_2025 , @COURSE_CGS_3853),
    (@STUDENT_8, @TERM_SPRING_2025 , @COURSE_CIS_4219),
    (@STUDENT_8, @TERM_SPRING_2025 , @COURSE_CNT_4104),
    (@STUDENT_8, @TERM_SPRING_2025 , @COURSE_CNT_4104L),
    (@STUDENT_8, @TERM_SPRING_2025 , @COURSE_XXX_ELECTIVE),
    (@STUDENT_8, @TERM_SPRING_2025 , @COURSE_ENC_3246),
    (@STUDENT_8, @TERM_FALL_2025 , @COURSE_XXX_ELECTIVE),
    (@STUDENT_8, @TERM_FALL_2025 , @COURSE_CIS_4200),
    (@STUDENT_8, @TERM_FALL_2025 , @COURSE_CNT_4403),
    (@STUDENT_8, @TERM_FALL_2025 , @COURSE_COP_4703),
    (@STUDENT_8, @TERM_FALL_2025 , @COURSE_XXX_ELECTIVE),
    (@STUDENT_8, @TERM_SPRING_2026 , @COURSE_XXX_ELECTIVE),
    (@STUDENT_8, @TERM_SPRING_2026 , @COURSE_CIS_4935),
    (@STUDENT_8, @TERM_SPRING_2026 , @COURSE_XXX_ELECTIVE),
    (@STUDENT_8, @TERM_SPRING_2026 , @COURSE_LIS_4414),

    (@STUDENT_9, @TERM_FALL_2022 , @COURSE_EGN_3000),
    (@STUDENT_9, @TERM_FALL_2022 , @COURSE_EGN_3000L),
    (@STUDENT_9, @TERM_FALL_2022 , @COURSE_ENC_1101),
    (@STUDENT_9, @TERM_FALL_2022 , @COURSE_MAC_2281),
    (@STUDENT_9, @TERM_FALL_2022 , @COURSE_XXX_ELECTIVE),
    (@STUDENT_9, @TERM_SPRING_2023 , @COURSE_COP_2510),
    (@STUDENT_9, @TERM_SPRING_2023 , @COURSE_ENC_1102),
    (@STUDENT_9, @TERM_SPRING_2023 , @COURSE_MAC_2282),
    (@STUDENT_9, @TERM_SPRING_2023 , @COURSE_PHY_2048),
    (@STUDENT_9, @TERM_SPRING_2023 , @COURSE_PHY_2048L),
    (@STUDENT_9, @TERM_FALL_2023 , @COURSE_CDA_3103),
    (@STUDENT_9, @TERM_FALL_2023 , @COURSE_COP_3514),
    (@STUDENT_9, @TERM_FALL_2023 , @COURSE_MAC_2283),
    (@STUDENT_9, @TERM_FALL_2023 , @COURSE_PHY_2049),
    (@STUDENT_9, @TERM_FALL_2023 , @COURSE_PHY_2049L),
    (@STUDENT_9, @TERM_SPRING_2024 , @COURSE_CDA_3201),
    (@STUDENT_9, @TERM_SPRING_2024 , @COURSE_CDA_3201L),
    (@STUDENT_9, @TERM_SPRING_2024 , @COURSE_COP_4530),
    (@STUDENT_9, @TERM_SPRING_2024 , @COURSE_COT_3100),
    (@STUDENT_9, @TERM_SPRING_2024 , @COURSE_XXX_ELECTIVE),
    (@STUDENT_9, @TERM_SUMMER_2024 , @COURSE_EGN_3443),
    (@STUDENT_9, @TERM_SUMMER_2024 , @COURSE_XXX_ELECTIVE),
    (@STUDENT_9, @TERM_SUMMER_2024 , @COURSE_XXX_ELECTIVE),
    (@STUDENT_9, @TERM_FALL_2024 , @COURSE_CDA_4205),
    (@STUDENT_9, @TERM_FALL_2024 , @COURSE_CDA_4205L),
    (@STUDENT_9, @TERM_FALL_2024 , @COURSE_XXX_ELECTIVE),
    (@STUDENT_9, @TERM_FALL_2024 , @COURSE_XXX_ELECTIVE),
    (@STUDENT_9, @TERM_FALL_2024 , @COURSE_EGN_4450),
    (@STUDENT_9, @TERM_FALL_2024 , @COURSE_XXX_ELECTIVE),
    (@STUDENT_9, @TERM_SPRING_2025 , @COURSE_COT_4400),
    (@STUDENT_9, @TERM_SPRING_2025 , @COURSE_XXX_ELECTIVE),
    (@STUDENT_9, @TERM_SPRING_2025 , @COURSE_XXX_ELECTIVE),
    (@STUDENT_9, @TERM_SPRING_2025 , @COURSE_ENC_3246),
    (@STUDENT_9, @TERM_SPRING_2025 , @COURSE_XXX_ELECTIVE),
    (@STUDENT_9, @TERM_FALL_2025 , @COURSE_CNT_4419),
    (@STUDENT_9, @TERM_FALL_2025 , @COURSE_COP_4600),
    (@STUDENT_9, @TERM_FALL_2025 , @COURSE_XXX_ELECTIVE),
    (@STUDENT_9, @TERM_FALL_2025 , @COURSE_XXX_ELECTIVE),
    (@STUDENT_9, @TERM_FALL_2025 , @COURSE_XXX_ELECTIVE),
    (@STUDENT_9, @TERM_SPRING_2026 , @COURSE_CEN_4020),
    (@STUDENT_9, @TERM_SPRING_2026 , @COURSE_CIS_4250),
    (@STUDENT_9, @TERM_SPRING_2026 , @COURSE_XXX_ELECTIVE),
    (@STUDENT_9, @TERM_SPRING_2026 , @COURSE_XXX_ELECTIVE),

    (@STUDENT_10, @TERM_FALL_2022 , @COURSE_CGS_1540),
    (@STUDENT_10, @TERM_FALL_2022 , @COURSE_EGN_3000),
    (@STUDENT_10, @TERM_FALL_2022 , @COURSE_EGN_3000L),
    (@STUDENT_10, @TERM_FALL_2022 , @COURSE_ENC_1101),
    (@STUDENT_10, @TERM_FALL_2022 , @COURSE_MAC_1147),
    (@STUDENT_10, @TERM_SPRING_2023 , @COURSE_COP_2512),
    (@STUDENT_10, @TERM_SPRING_2023 , @COURSE_ENC_1102),
    (@STUDENT_10, @TERM_SPRING_2023 , @COURSE_MAD_2104),
    (@STUDENT_10, @TERM_SPRING_2023 , @COURSE_PHY_2020),
    (@STUDENT_10, @TERM_SPRING_2023 , @COURSE_XXX_ELECTIVE),
    (@STUDENT_10, @TERM_FALL_2023 , @COURSE_CGS_3303),
    (@STUDENT_10, @TERM_FALL_2023 , @COURSE_COP_2513),
    (@STUDENT_10, @TERM_FALL_2023 , @COURSE_ECO_2013),
    (@STUDENT_10, @TERM_FALL_2023 , @COURSE_STA_2023),
    (@STUDENT_10, @TERM_SPRING_2024 , @COURSE_CIS_3213),
    (@STUDENT_10, @TERM_SPRING_2024 , @COURSE_COP_3515),
    (@STUDENT_10, @TERM_SPRING_2024 , @COURSE_INR_3033),
    (@STUDENT_10, @TERM_SPRING_2024 , @COURSE_PSY_2012),
    (@STUDENT_10, @TERM_SUMMER_2024 , @COURSE_XXX_ELECTIVE),
    (@STUDENT_10, @TERM_SUMMER_2024 , @COURSE_XXX_ELECTIVE),
    (@STUDENT_10, @TERM_SUMMER_2024 , @COURSE_XXX_ELECTIVE),
    (@STUDENT_10, @TERM_FALL_2024 , @COURSE_CEN_3722),
    (@STUDENT_10, @TERM_FALL_2024 , @COURSE_CIS_3433),
    (@STUDENT_10, @TERM_FALL_2024 , @COURSE_COP_4538),
    (@STUDENT_10, @TERM_FALL_2024 , @COURSE_XXX_ELECTIVE),
    (@STUDENT_10, @TERM_FALL_2024 , @COURSE_XXX_ELECTIVE),
    (@STUDENT_10, @TERM_SPRING_2025 , @COURSE_CGS_3853),
    (@STUDENT_10, @TERM_SPRING_2025 , @COURSE_CNT_4104),
    (@STUDENT_10, @TERM_SPRING_2025 , @COURSE_CNT_4104L),
    (@STUDENT_10, @TERM_SPRING_2025 , @COURSE_ENC_3246),
    (@STUDENT_10, @TERM_SPRING_2025 , @COURSE_XXX_ELECTIVE),
    (@STUDENT_10, @TERM_SPRING_2025 , @COURSE_XXX_ELECTIVE),
    (@STUDENT_10, @TERM_FALL_2025 , @COURSE_XXX_ELECTIVE),
    (@STUDENT_10, @TERM_FALL_2025 , @COURSE_XXX_ELECTIVE),
    (@STUDENT_10, @TERM_FALL_2025 , @COURSE_CIS_4083),
    (@STUDENT_10, @TERM_FALL_2025 , @COURSE_CNT_4603),
    (@STUDENT_10, @TERM_FALL_2025 , @COURSE_COP_4703),
    (@STUDENT_10, @TERM_SPRING_2026 , @COURSE_XXX_ELECTIVE),
    (@STUDENT_10, @TERM_SPRING_2026 , @COURSE_XXX_ELECTIVE),
    (@STUDENT_10, @TERM_SPRING_2026 , @COURSE_CIS_4253),
    (@STUDENT_10, @TERM_SPRING_2026 , @COURSE_CIS_4935),

    (@STUDENT_11, @TERM_FALL_2023 , @COURSE_EGN_3000),
    (@STUDENT_11, @TERM_FALL_2023 , @COURSE_EGN_3000L),
    (@STUDENT_11, @TERM_FALL_2023 , @COURSE_ENC_1101),
    (@STUDENT_11, @TERM_FALL_2023 , @COURSE_MAC_2281),
    (@STUDENT_11, @TERM_FALL_2023 , @COURSE_XXX_ELECTIVE),
    (@STUDENT_11, @TERM_SPRING_2024 , @COURSE_COP_2510),
    (@STUDENT_11, @TERM_SPRING_2024 , @COURSE_ENC_1102),
    (@STUDENT_11, @TERM_SPRING_2024 , @COURSE_MAC_2282),
    (@STUDENT_11, @TERM_SPRING_2024 , @COURSE_PHY_2048),
    (@STUDENT_11, @TERM_SPRING_2024 , @COURSE_PHY_2048L),
    (@STUDENT_11, @TERM_FALL_2024 , @COURSE_CDA_3103),
    (@STUDENT_11, @TERM_FALL_2024 , @COURSE_COP_3514),
    (@STUDENT_11, @TERM_FALL_2024 , @COURSE_COT_3100),
    (@STUDENT_11, @TERM_FALL_2024 , @COURSE_PHY_2049),
    (@STUDENT_11, @TERM_FALL_2024 , @COURSE_PHY_2049L),
    (@STUDENT_11, @TERM_SPRING_2025 , @COURSE_CDA_3201),
    (@STUDENT_11, @TERM_SPRING_2025 , @COURSE_CDA_3201L),
    (@STUDENT_11, @TERM_SPRING_2025 , @COURSE_COP_4530),
    (@STUDENT_11, @TERM_SPRING_2025 , @COURSE_XXX_ELECTIVE),
    (@STUDENT_11, @TERM_SPRING_2025 , @COURSE_XXX_ELECTIVE),
    (@STUDENT_11, @TERM_SUMMER_2025 , @COURSE_EGN_3443),
    (@STUDENT_11, @TERM_SUMMER_2025 , @COURSE_XXX_ELECTIVE),
    (@STUDENT_11, @TERM_SUMMER_2025 , @COURSE_XXX_ELECTIVE),
    (@STUDENT_11, @TERM_FALL_2025 , @COURSE_CDA_4205),
    (@STUDENT_11, @TERM_FALL_2025 , @COURSE_CDA_4205L),
    (@STUDENT_11, @TERM_FALL_2025 , @COURSE_EGN_4450),
    (@STUDENT_11, @TERM_FALL_2025 , @COURSE_XXX_ELECTIVE),
    (@STUDENT_11, @TERM_FALL_2025 , @COURSE_XXX_ELECTIVE),
    (@STUDENT_11, @TERM_FALL_2025 , @COURSE_XXX_ELECTIVE),
    (@STUDENT_11, @TERM_SPRING_2026 , @COURSE_COT_4400),
    (@STUDENT_11, @TERM_SPRING_2026 , @COURSE_ENC_3246),
    (@STUDENT_11, @TERM_SPRING_2026 , @COURSE_XXX_ELECTIVE),
    (@STUDENT_11, @TERM_SPRING_2026 , @COURSE_XXX_ELECTIVE),
    (@STUDENT_11, @TERM_SPRING_2026 , @COURSE_XXX_ELECTIVE),
    (@STUDENT_11, @TERM_FALL_2026 , @COURSE_CNT_4419),
    (@STUDENT_11, @TERM_FALL_2026 , @COURSE_COP_4600),
    (@STUDENT_11, @TERM_FALL_2026 , @COURSE_XXX_ELECTIVE),
    (@STUDENT_11, @TERM_FALL_2026 , @COURSE_XXX_ELECTIVE),
    (@STUDENT_11, @TERM_FALL_2026 , @COURSE_XXX_ELECTIVE),
    (@STUDENT_11, @TERM_SPRING_2027 , @COURSE_CEN_4020),
    (@STUDENT_11, @TERM_SPRING_2027 , @COURSE_CIS_4250),
    (@STUDENT_11, @TERM_SPRING_2027 , @COURSE_XXX_ELECTIVE),
    (@STUDENT_11, @TERM_SPRING_2027 , @COURSE_XXX_ELECTIVE),

    (@STUDENT_12, @TERM_FALL_2023 , @COURSE_CHM_2045),
    (@STUDENT_12, @TERM_FALL_2023 , @COURSE_CHM_2045L),
    (@STUDENT_12, @TERM_FALL_2023 , @COURSE_EGN_3000),
    (@STUDENT_12, @TERM_FALL_2023 , @COURSE_EGN_3000L),
    (@STUDENT_12, @TERM_FALL_2023 , @COURSE_ENC_1101),
    (@STUDENT_12, @TERM_FALL_2023 , @COURSE_MAC_2281),
    (@STUDENT_12, @TERM_SPRING_2024 , @COURSE_COP_2510),
    (@STUDENT_12, @TERM_SPRING_2024 , @COURSE_COT_3100),
    (@STUDENT_12, @TERM_SPRING_2024 , @COURSE_MAC_2282),
    (@STUDENT_12, @TERM_SPRING_2024 , @COURSE_PHY_2048),
    (@STUDENT_12, @TERM_SPRING_2024 , @COURSE_PHY_2048L),
    (@STUDENT_12, @TERM_FALL_2024 , @COURSE_CDA_3103),
    (@STUDENT_12, @TERM_FALL_2024 , @COURSE_COP_3514),
    (@STUDENT_12, @TERM_FALL_2024 , @COURSE_MAC_2283),
    (@STUDENT_12, @TERM_FALL_2024 , @COURSE_PHY_2049),
    (@STUDENT_12, @TERM_FALL_2024 , @COURSE_PHY_2049L),
    (@STUDENT_12, @TERM_SPRING_2025 , @COURSE_CDA_3201),
    (@STUDENT_12, @TERM_SPRING_2025 , @COURSE_CDA_3201L),
    (@STUDENT_12, @TERM_SPRING_2025 , @COURSE_COP_4530),
    (@STUDENT_12, @TERM_SPRING_2025 , @COURSE_EGN_3433),
    (@STUDENT_12, @TERM_SPRING_2025 , @COURSE_ENC_1102),
    (@STUDENT_12, @TERM_SPRING_2025 , @COURSE_XXX_ELECTIVE),
    (@STUDENT_12, @TERM_SUMMER_2025 , @COURSE_EGN_3443),
    (@STUDENT_12, @TERM_SUMMER_2025 , @COURSE_XXX_ELECTIVE),
    (@STUDENT_12, @TERM_SUMMER_2025 , @COURSE_XXX_ELECTIVE),
    (@STUDENT_12, @TERM_FALL_2025 , @COURSE_CDA_4205),
    (@STUDENT_12, @TERM_FALL_2025 , @COURSE_CDA_4205L),
    (@STUDENT_12, @TERM_FALL_2025 , @COURSE_EEE_3394),
    (@STUDENT_12, @TERM_FALL_2025 , @COURSE_EGN_3373),
    (@STUDENT_12, @TERM_FALL_2025 , @COURSE_EGN_3615),
    (@STUDENT_12, @TERM_FALL_2025 , @COURSE_EGN_4450),
    (@STUDENT_12, @TERM_SPRING_2026 , @COURSE_CDA_4203),
    (@STUDENT_12, @TERM_SPRING_2026 , @COURSE_CDA_4203L),
    (@STUDENT_12, @TERM_SPRING_2026 , @COURSE_COT_4400),
    (@STUDENT_12, @TERM_SPRING_2026 , @COURSE_XXX_ELECTIVE),
    (@STUDENT_12, @TERM_SPRING_2026 , @COURSE_XXX_ELECTIVE),
    (@STUDENT_12, @TERM_FALL_2026 , @COURSE_CDA_4213),
    (@STUDENT_12, @TERM_FALL_2026 , @COURSE_CDA_4213L),
    (@STUDENT_12, @TERM_FALL_2026 , @COURSE_COP_4600),
    (@STUDENT_12, @TERM_FALL_2026 , @COURSE_ENC_3246),
    (@STUDENT_12, @TERM_FALL_2026 , @COURSE_XXX_ELECTIVE),
    (@STUDENT_12, @TERM_SPRING_2027 , @COURSE_CIS_4250),
    (@STUDENT_12, @TERM_SPRING_2027 , @COURSE_CIS_4910),
    (@STUDENT_12, @TERM_SPRING_2027 , @COURSE_XXX_ELECTIVE),
    (@STUDENT_12, @TERM_SPRING_2027 , @COURSE_XXX_ELECTIVE),
    (@STUDENT_12, @TERM_SPRING_2026 , @COURSE_CDA_4203L),
    (@STUDENT_12, @TERM_SPRING_2026 , @COURSE_COT_4400),
    (@STUDENT_12, @TERM_SPRING_2026 , @COURSE_XXX_ELECTIVE),
    (@STUDENT_12, @TERM_SPRING_2026 , @COURSE_XXX_ELECTIVE),
    (@STUDENT_12, @TERM_FALL_2026 , @COURSE_CDA_4213),
    (@STUDENT_12, @TERM_FALL_2026 , @COURSE_CDA_4213L),
    (@STUDENT_12, @TERM_FALL_2026 , @COURSE_COP_4600),
    (@STUDENT_12, @TERM_FALL_2026 , @COURSE_ENC_3246),
    (@STUDENT_12, @TERM_FALL_2026 , @COURSE_XXX_ELECTIVE),
    (@STUDENT_12, @TERM_SPRING_2027 , @COURSE_CIS_4250),
    (@STUDENT_12, @TERM_SPRING_2027 , @COURSE_CIS_4910),
    (@STUDENT_12, @TERM_SPRING_2027 , @COURSE_XXX_ELECTIVE),
    (@STUDENT_12, @TERM_SPRING_2027 , @COURSE_XXX_ELECTIVE),

    (@STUDENT_13, @TERM_FALL_2023 , @COURSE_CGS_1540),
    (@STUDENT_13, @TERM_FALL_2023 , @COURSE_EGN_3000),
    (@STUDENT_13, @TERM_FALL_2023 , @COURSE_EGN_3000L),
    (@STUDENT_13, @TERM_FALL_2023 , @COURSE_ENC_1101),
    (@STUDENT_13, @TERM_FALL_2023 , @COURSE_MAC_1147),
    (@STUDENT_13, @TERM_SPRING_2024 , @COURSE_COP_2512),
    (@STUDENT_13, @TERM_SPRING_2024 , @COURSE_MAD_2104),
    (@STUDENT_13, @TERM_SPRING_2024 , @COURSE_ENC_1102),
    (@STUDENT_13, @TERM_SPRING_2024 , @COURSE_PHY_2020),
    (@STUDENT_13, @TERM_SPRING_2024 , @COURSE_XXX_ELECTIVE),
    (@STUDENT_13, @TERM_FALL_2024 , @COURSE_COP_2513),
    (@STUDENT_13, @TERM_FALL_2024 , @COURSE_CGS_3303),
    (@STUDENT_13, @TERM_FALL_2024 , @COURSE_ECO_2013),
    (@STUDENT_13, @TERM_FALL_2024 , @COURSE_STA_2023),
    (@STUDENT_13, @TERM_SPRING_2025 , @COURSE_CIS_3213),
    (@STUDENT_13, @TERM_SPRING_2025 , @COURSE_COP_3515),
    (@STUDENT_13, @TERM_SPRING_2025 , @COURSE_PSY_2012),
    (@STUDENT_13, @TERM_SPRING_2025 , @COURSE_XXX_ELECTIVE),
    (@STUDENT_13, @TERM_SUMMER_2025 , @COURSE_XXX_ELECTIVE),
    (@STUDENT_13, @TERM_SUMMER_2025 , @COURSE_XXX_ELECTIVE),
    (@STUDENT_13, @TERM_SUMMER_2025 , @COURSE_XXX_ELECTIVE),
    (@STUDENT_13, @TERM_FALL_2025 , @COURSE_CEN_3722),
    (@STUDENT_13, @TERM_FALL_2025 , @COURSE_CIS_3363),
    (@STUDENT_13, @TERM_FALL_2025 , @COURSE_CIS_4622),
    (@STUDENT_13, @TERM_FALL_2025 , @COURSE_COP_4538),
    (@STUDENT_13, @TERM_FALL_2025 , @COURSE_ISM_4323),
    (@STUDENT_13, @TERM_SPRING_2026 , @COURSE_CGS_3853),
    (@STUDENT_13, @TERM_SPRING_2026 , @COURSE_CIS_4219),
    (@STUDENT_13, @TERM_SPRING_2026 , @COURSE_CNT_4104),
    (@STUDENT_13, @TERM_SPRING_2026 , @COURSE_CNT_4104L),
    (@STUDENT_13, @TERM_SPRING_2026 , @COURSE_ENC_3246),
    (@STUDENT_13, @TERM_SPRING_2026 , @COURSE_XXX_ELECTIVE),
    (@STUDENT_13, @TERM_FALL_2026 , @COURSE_CIS_4200),
    (@STUDENT_13, @TERM_FALL_2026 , @COURSE_CNT_4403),
    (@STUDENT_13, @TERM_FALL_2026 , @COURSE_COP_4703),
    (@STUDENT_13, @TERM_FALL_2026 , @COURSE_XXX_ELECTIVE),
    (@STUDENT_13, @TERM_FALL_2026 , @COURSE_XXX_ELECTIVE),
    (@STUDENT_13, @TERM_SPRING_2027 , @COURSE_CIS_4935),
    (@STUDENT_13, @TERM_SPRING_2027 , @COURSE_LIS_4414),
    (@STUDENT_13, @TERM_SPRING_2027 , @COURSE_XXX_ELECTIVE),
    (@STUDENT_13, @TERM_SPRING_2027 , @COURSE_XXX_ELECTIVE),

    (@STUDENT_14, @TERM_FALL_2023 , @COURSE_CGS_1540),
    (@STUDENT_14, @TERM_FALL_2023 , @COURSE_EGN_3000),
    (@STUDENT_14, @TERM_FALL_2023 , @COURSE_EGN_3000L),
    (@STUDENT_14, @TERM_FALL_2023 , @COURSE_ENC_1101),
    (@STUDENT_14, @TERM_FALL_2023 , @COURSE_MAC_1147),
    (@STUDENT_14, @TERM_SPRING_2024 , @COURSE_COP_2512),
    (@STUDENT_14, @TERM_SPRING_2024 , @COURSE_MAD_2104),
    (@STUDENT_14, @TERM_SPRING_2024 , @COURSE_ENC_1102),
    (@STUDENT_14, @TERM_SPRING_2024 , @COURSE_PHY_2020),
    (@STUDENT_14, @TERM_SPRING_2024 , @COURSE_XXX_ELECTIVE),
    (@STUDENT_14, @TERM_FALL_2024 , @COURSE_COP_2513),
    (@STUDENT_14, @TERM_FALL_2024 , @COURSE_CGS_3303),
    (@STUDENT_14, @TERM_FALL_2024 , @COURSE_ECO_2013),
    (@STUDENT_14, @TERM_FALL_2024 , @COURSE_STA_2023),
    (@STUDENT_14, @TERM_SPRING_2025 , @COURSE_CIS_3213),
    (@STUDENT_14, @TERM_SPRING_2025 , @COURSE_COP_3515),
    (@STUDENT_14, @TERM_SPRING_2025 , @COURSE_INR_3033),
    (@STUDENT_14, @TERM_SPRING_2025 , @COURSE_PSY_2012),
    (@STUDENT_14, @TERM_SUMMER_2025 , @COURSE_XXX_ELECTIVE),
    (@STUDENT_14, @TERM_SUMMER_2025 , @COURSE_XXX_ELECTIVE),
    (@STUDENT_14, @TERM_SUMMER_2025 , @COURSE_XXX_ELECTIVE),
    (@STUDENT_14, @TERM_FALL_2025 , @COURSE_CEN_3722),
    (@STUDENT_14, @TERM_FALL_2025 , @COURSE_CIS_3433),
    (@STUDENT_14, @TERM_FALL_2025 , @COURSE_COP_4538),
    (@STUDENT_14, @TERM_FALL_2025 , @COURSE_XXX_ELECTIVE),
    (@STUDENT_14, @TERM_FALL_2025 , @COURSE_XXX_ELECTIVE),
    (@STUDENT_14, @TERM_SPRING_2026 , @COURSE_CGS_3853),
    (@STUDENT_14, @TERM_SPRING_2026 , @COURSE_CNT_4104),
    (@STUDENT_14, @TERM_SPRING_2026 , @COURSE_CNT_4104L),
    (@STUDENT_14, @TERM_SPRING_2026 , @COURSE_ENC_3246),
    (@STUDENT_14, @TERM_SPRING_2026 , @COURSE_XXX_ELECTIVE),
    (@STUDENT_14, @TERM_SPRING_2026 , @COURSE_XXX_ELECTIVE),
    (@STUDENT_14, @TERM_FALL_2026 , @COURSE_CIS_4083),
    (@STUDENT_14, @TERM_FALL_2026 , @COURSE_CNT_4603),
    (@STUDENT_14, @TERM_FALL_2026 , @COURSE_COP_4703),
    (@STUDENT_14, @TERM_FALL_2026 , @COURSE_XXX_ELECTIVE),
    (@STUDENT_14, @TERM_FALL_2026 , @COURSE_XXX_ELECTIVE),
    (@STUDENT_14, @TERM_SPRING_2027 , @COURSE_CIS_4253),
    (@STUDENT_14, @TERM_SPRING_2027 , @COURSE_CIS_4935),
    (@STUDENT_14, @TERM_SPRING_2027 , @COURSE_XXX_ELECTIVE),
    (@STUDENT_14, @TERM_SPRING_2027 , @COURSE_XXX_ELECTIVE),

    (@STUDENT_15, @TERM_FALL_2023 , @COURSE_EGN_3000),
    (@STUDENT_15, @TERM_FALL_2023 , @COURSE_EGN_3000L),
    (@STUDENT_15, @TERM_FALL_2023 , @COURSE_ENC_1101),
    (@STUDENT_15, @TERM_FALL_2023 , @COURSE_MAC_2281),
    (@STUDENT_15, @TERM_FALL_2023 , @COURSE_XXX_ELECTIVE),
    (@STUDENT_15, @TERM_SPRING_2024 , @COURSE_COP_2510),
    (@STUDENT_15, @TERM_SPRING_2024 , @COURSE_ENC_1102),
    (@STUDENT_15, @TERM_SPRING_2024 , @COURSE_MAC_2282),
    (@STUDENT_15, @TERM_SPRING_2024 , @COURSE_PHY_2048),
    (@STUDENT_15, @TERM_SPRING_2024 , @COURSE_PHY_2048L),
    (@STUDENT_15, @TERM_FALL_2024 , @COURSE_CDA_3103),
    (@STUDENT_15, @TERM_FALL_2024 , @COURSE_COP_3514),
    (@STUDENT_15, @TERM_FALL_2024 , @COURSE_COT_3100),
    (@STUDENT_15, @TERM_FALL_2024 , @COURSE_PHY_2049),
    (@STUDENT_15, @TERM_FALL_2024 , @COURSE_PHY_2049L),
    (@STUDENT_15, @TERM_SPRING_2025 , @COURSE_CDA_3201),
    (@STUDENT_15, @TERM_SPRING_2025 , @COURSE_CDA_3201L),
    (@STUDENT_15, @TERM_SPRING_2025 , @COURSE_COP_4530),
    (@STUDENT_15, @TERM_SPRING_2025 , @COURSE_XXX_ELECTIVE),
    (@STUDENT_15, @TERM_SPRING_2025 , @COURSE_XXX_ELECTIVE),
    (@STUDENT_15, @TERM_SUMMER_2025 , @COURSE_EGN_3443),
    (@STUDENT_15, @TERM_SUMMER_2025 , @COURSE_XXX_ELECTIVE),
    (@STUDENT_15, @TERM_SUMMER_2025 , @COURSE_XXX_ELECTIVE),
    (@STUDENT_15, @TERM_FALL_2025 , @COURSE_CDA_4205),
    (@STUDENT_15, @TERM_FALL_2025 , @COURSE_CDA_4205L),
    (@STUDENT_15, @TERM_FALL_2025 , @COURSE_EGN_4450),
    (@STUDENT_15, @TERM_FALL_2025 , @COURSE_XXX_ELECTIVE),
    (@STUDENT_15, @TERM_FALL_2025 , @COURSE_XXX_ELECTIVE),
    (@STUDENT_15, @TERM_FALL_2025 , @COURSE_XXX_ELECTIVE),
    (@STUDENT_15, @TERM_SPRING_2026 , @COURSE_COT_4400),
    (@STUDENT_15, @TERM_SPRING_2026 , @COURSE_ENC_3246),
    (@STUDENT_15, @TERM_SPRING_2026 , @COURSE_XXX_ELECTIVE),
    (@STUDENT_15, @TERM_SPRING_2026 , @COURSE_XXX_ELECTIVE),
    (@STUDENT_15, @TERM_SPRING_2026 , @COURSE_XXX_ELECTIVE),
    (@STUDENT_15, @TERM_FALL_2026 , @COURSE_CNT_4419),
    (@STUDENT_15, @TERM_FALL_2026 , @COURSE_COP_4600),
    (@STUDENT_15, @TERM_FALL_2026 , @COURSE_XXX_ELECTIVE),
    (@STUDENT_15, @TERM_FALL_2026 , @COURSE_XXX_ELECTIVE),
    (@STUDENT_15, @TERM_FALL_2026 , @COURSE_XXX_ELECTIVE),
    (@STUDENT_15, @TERM_SPRING_2027 , @COURSE_CEN_4020),
    (@STUDENT_15, @TERM_SPRING_2027 , @COURSE_CIS_4250),
    (@STUDENT_15, @TERM_SPRING_2027 , @COURSE_XXX_ELECTIVE),
    (@STUDENT_15, @TERM_SPRING_2027 , @COURSE_XXX_ELECTIVE),

    (@STUDENT_16, @TERM_FALL_2023 , @COURSE_EGN_3000),
    (@STUDENT_16, @TERM_FALL_2023 , @COURSE_EGN_3000L),
    (@STUDENT_16, @TERM_FALL_2023 , @COURSE_ENC_1101),
    (@STUDENT_16, @TERM_FALL_2023 , @COURSE_MAC_2281),
    (@STUDENT_16, @TERM_FALL_2023 , @COURSE_XXX_ELECTIVE),
    (@STUDENT_16, @TERM_SPRING_2024 , @COURSE_COP_2510),
    (@STUDENT_16, @TERM_SPRING_2024 , @COURSE_ENC_1102),
    (@STUDENT_16, @TERM_SPRING_2024 , @COURSE_MAC_2282),
    (@STUDENT_16, @TERM_SPRING_2024 , @COURSE_PHY_2048),
    (@STUDENT_16, @TERM_SPRING_2024 , @COURSE_PHY_2048L),
    (@STUDENT_16, @TERM_FALL_2024 , @COURSE_CDA_3103),
    (@STUDENT_16, @TERM_FALL_2024 , @COURSE_COP_3514),
    (@STUDENT_16, @TERM_FALL_2024 , @COURSE_COT_3100),
    (@STUDENT_16, @TERM_FALL_2024 , @COURSE_PHY_2049),
    (@STUDENT_16, @TERM_FALL_2024 , @COURSE_PHY_2049L),
    (@STUDENT_16, @TERM_SPRING_2025 , @COURSE_CDA_3201),
    (@STUDENT_16, @TERM_SPRING_2025 , @COURSE_CDA_3201L),
    (@STUDENT_16, @TERM_SPRING_2025 , @COURSE_COP_4530),
    (@STUDENT_16, @TERM_SPRING_2025 , @COURSE_XXX_ELECTIVE),
    (@STUDENT_16, @TERM_SPRING_2025 , @COURSE_XXX_ELECTIVE),
    (@STUDENT_16, @TERM_SUMMER_2025 , @COURSE_EGN_3443),
    (@STUDENT_16, @TERM_SUMMER_2025 , @COURSE_XXX_ELECTIVE),
    (@STUDENT_16, @TERM_SUMMER_2025 , @COURSE_XXX_ELECTIVE),
    (@STUDENT_16, @TERM_FALL_2025 , @COURSE_CDA_4205),
    (@STUDENT_16, @TERM_FALL_2025 , @COURSE_CDA_4205L),
    (@STUDENT_16, @TERM_FALL_2025 , @COURSE_EGN_4450),
    (@STUDENT_16, @TERM_FALL_2025 , @COURSE_XXX_ELECTIVE),
    (@STUDENT_16, @TERM_FALL_2025 , @COURSE_XXX_ELECTIVE),
    (@STUDENT_16, @TERM_FALL_2025 , @COURSE_XXX_ELECTIVE),
    (@STUDENT_16, @TERM_SPRING_2026 , @COURSE_COT_4400),
    (@STUDENT_16, @TERM_SPRING_2026 , @COURSE_ENC_3246),
    (@STUDENT_16, @TERM_SPRING_2026 , @COURSE_XXX_ELECTIVE),
    (@STUDENT_16, @TERM_SPRING_2026 , @COURSE_XXX_ELECTIVE),
    (@STUDENT_16, @TERM_SPRING_2026 , @COURSE_XXX_ELECTIVE),
    (@STUDENT_16, @TERM_FALL_2026 , @COURSE_CNT_4419),
    (@STUDENT_16, @TERM_FALL_2026 , @COURSE_COP_4600),
    (@STUDENT_16, @TERM_FALL_2026 , @COURSE_XXX_ELECTIVE),
    (@STUDENT_16, @TERM_FALL_2026 , @COURSE_XXX_ELECTIVE),
    (@STUDENT_16, @TERM_FALL_2026 , @COURSE_XXX_ELECTIVE),
    (@STUDENT_16, @TERM_SPRING_2027 , @COURSE_CEN_4020),
    (@STUDENT_16, @TERM_SPRING_2027 , @COURSE_CIS_4250),
    (@STUDENT_16, @TERM_SPRING_2027 , @COURSE_XXX_ELECTIVE),
    (@STUDENT_16, @TERM_SPRING_2027 , @COURSE_XXX_ELECTIVE),

    (@STUDENT_17, @TERM_FALL_2023 , @COURSE_CGS_1540),
    (@STUDENT_17, @TERM_FALL_2023 , @COURSE_EGN_3000),
    (@STUDENT_17, @TERM_FALL_2023 , @COURSE_EGN_3000L),
    (@STUDENT_17, @TERM_FALL_2023 , @COURSE_ENC_1101),
    (@STUDENT_17, @TERM_FALL_2023 , @COURSE_MAC_1147),
    (@STUDENT_17, @TERM_SPRING_2024 , @COURSE_COP_2512),
    (@STUDENT_17, @TERM_SPRING_2024 , @COURSE_MAD_2104),
    (@STUDENT_17, @TERM_SPRING_2024 , @COURSE_ENC_1102),
    (@STUDENT_17, @TERM_SPRING_2024 , @COURSE_PHY_2020),
    (@STUDENT_17, @TERM_SPRING_2024 , @COURSE_XXX_ELECTIVE),
    (@STUDENT_17, @TERM_FALL_2024 , @COURSE_COP_2513),
    (@STUDENT_17, @TERM_FALL_2024 , @COURSE_CGS_3303),
    (@STUDENT_17, @TERM_FALL_2024 , @COURSE_ECO_2013),
    (@STUDENT_17, @TERM_FALL_2024 , @COURSE_STA_2023),
    (@STUDENT_17, @TERM_SPRING_2025 , @COURSE_CIS_3213),
    (@STUDENT_17, @TERM_SPRING_2025 , @COURSE_COP_3515),
    (@STUDENT_17, @TERM_SPRING_2025 , @COURSE_INR_3033),
    (@STUDENT_17, @TERM_SPRING_2025 , @COURSE_PSY_2012),
    (@STUDENT_17, @TERM_SUMMER_2025 , @COURSE_XXX_ELECTIVE),
    (@STUDENT_17, @TERM_SUMMER_2025 , @COURSE_XXX_ELECTIVE),
    (@STUDENT_17, @TERM_SUMMER_2025 , @COURSE_XXX_ELECTIVE),
    (@STUDENT_17, @TERM_FALL_2025 , @COURSE_CEN_3722),
    (@STUDENT_17, @TERM_FALL_2025 , @COURSE_CIS_3433),
    (@STUDENT_17, @TERM_FALL_2025 , @COURSE_COP_4538),
    (@STUDENT_17, @TERM_FALL_2025 , @COURSE_XXX_ELECTIVE),
    (@STUDENT_17, @TERM_FALL_2025 , @COURSE_XXX_ELECTIVE),
    (@STUDENT_17, @TERM_SPRING_2026 , @COURSE_CGS_3853),
    (@STUDENT_17, @TERM_SPRING_2026 , @COURSE_CNT_4104),
    (@STUDENT_17, @TERM_SPRING_2026 , @COURSE_CNT_4104L),
    (@STUDENT_17, @TERM_SPRING_2026 , @COURSE_ENC_3246),
    (@STUDENT_17, @TERM_SPRING_2026 , @COURSE_XXX_ELECTIVE),
    (@STUDENT_17, @TERM_SPRING_2026 , @COURSE_XXX_ELECTIVE),
    (@STUDENT_17, @TERM_FALL_2026 , @COURSE_CIS_4083),
    (@STUDENT_17, @TERM_FALL_2026 , @COURSE_CNT_4603),
    (@STUDENT_17, @TERM_FALL_2026 , @COURSE_COP_4703),
    (@STUDENT_17, @TERM_FALL_2026 , @COURSE_XXX_ELECTIVE),
    (@STUDENT_17, @TERM_FALL_2026 , @COURSE_XXX_ELECTIVE),
    (@STUDENT_17, @TERM_SPRING_2027 , @COURSE_CIS_4253),
    (@STUDENT_17, @TERM_SPRING_2027 , @COURSE_CIS_4935),
    (@STUDENT_17, @TERM_SPRING_2027 , @COURSE_XXX_ELECTIVE),
    (@STUDENT_17, @TERM_SPRING_2027 , @COURSE_XXX_ELECTIVE),

    (@STUDENT_18, @TERM_FALL_2023 , @COURSE_CHM_2045),
    (@STUDENT_18, @TERM_FALL_2023 , @COURSE_CHM_2045L),
    (@STUDENT_18, @TERM_FALL_2023 , @COURSE_EGN_3000),
    (@STUDENT_18, @TERM_FALL_2023 , @COURSE_EGN_3000L),
    (@STUDENT_18, @TERM_FALL_2023 , @COURSE_ENC_1101),
    (@STUDENT_18, @TERM_FALL_2023 , @COURSE_MAC_2281),
    (@STUDENT_18, @TERM_SPRING_2024 , @COURSE_COP_2510),
    (@STUDENT_18, @TERM_SPRING_2024 , @COURSE_COT_3100),
    (@STUDENT_18, @TERM_SPRING_2024 , @COURSE_MAC_2282),
    (@STUDENT_18, @TERM_SPRING_2024 , @COURSE_PHY_2048),
    (@STUDENT_18, @TERM_SPRING_2024 , @COURSE_PHY_2048L),
    (@STUDENT_18, @TERM_FALL_2024 , @COURSE_CDA_3103),
    (@STUDENT_18, @TERM_FALL_2024 , @COURSE_COP_3514),
    (@STUDENT_18, @TERM_FALL_2024 , @COURSE_MAC_2283),
    (@STUDENT_18, @TERM_FALL_2024 , @COURSE_PHY_2049),
    (@STUDENT_18, @TERM_FALL_2024 , @COURSE_PHY_2049L),
    (@STUDENT_18, @TERM_SPRING_2025 , @COURSE_CDA_3201),
    (@STUDENT_18, @TERM_SPRING_2025 , @COURSE_CDA_3201L),
    (@STUDENT_18, @TERM_SPRING_2025 , @COURSE_COP_4530),
    (@STUDENT_18, @TERM_SPRING_2025 , @COURSE_EGN_3433),
    (@STUDENT_18, @TERM_SPRING_2025 , @COURSE_ENC_1102),
    (@STUDENT_18, @TERM_SPRING_2025 , @COURSE_XXX_ELECTIVE),
    (@STUDENT_18, @TERM_SUMMER_2025 , @COURSE_EGN_3443),
    (@STUDENT_18, @TERM_SUMMER_2025 , @COURSE_XXX_ELECTIVE),
    (@STUDENT_18, @TERM_SUMMER_2025 , @COURSE_XXX_ELECTIVE),
    (@STUDENT_18, @TERM_FALL_2025 , @COURSE_CDA_4205),
    (@STUDENT_18, @TERM_FALL_2025 , @COURSE_CDA_4205L),
    (@STUDENT_18, @TERM_FALL_2025 , @COURSE_EEE_3394),
    (@STUDENT_18, @TERM_FALL_2025 , @COURSE_EGN_3373),
    (@STUDENT_18, @TERM_FALL_2025 , @COURSE_EGN_3615),
    (@STUDENT_18, @TERM_FALL_2025 , @COURSE_EGN_4450),
    (@STUDENT_18, @TERM_SPRING_2026 , @COURSE_CDA_4203),
    (@STUDENT_18, @TERM_SPRING_2026 , @COURSE_CDA_4203L),
    (@STUDENT_18, @TERM_SPRING_2026 , @COURSE_COT_4400),
    (@STUDENT_18, @TERM_SPRING_2026 , @COURSE_XXX_ELECTIVE),
    (@STUDENT_18, @TERM_SPRING_2026 , @COURSE_XXX_ELECTIVE),
    (@STUDENT_18, @TERM_FALL_2026 , @COURSE_CDA_4213),
    (@STUDENT_18, @TERM_FALL_2026 , @COURSE_CDA_4213L),
    (@STUDENT_18, @TERM_FALL_2026 , @COURSE_COP_4600),
    (@STUDENT_18, @TERM_FALL_2026 , @COURSE_ENC_3246),
    (@STUDENT_18, @TERM_FALL_2026 , @COURSE_XXX_ELECTIVE),
    (@STUDENT_18, @TERM_SPRING_2027 , @COURSE_CIS_4250),
    (@STUDENT_18, @TERM_SPRING_2027 , @COURSE_CIS_4910),
    (@STUDENT_18, @TERM_SPRING_2027 , @COURSE_XXX_ELECTIVE),
    (@STUDENT_18, @TERM_SPRING_2027 , @COURSE_XXX_ELECTIVE),
    (@STUDENT_18, @TERM_SPRING_2026 , @COURSE_CDA_4203L),
    (@STUDENT_18, @TERM_SPRING_2026 , @COURSE_COT_4400),
    (@STUDENT_18, @TERM_SPRING_2026 , @COURSE_XXX_ELECTIVE),
    (@STUDENT_18, @TERM_SPRING_2026 , @COURSE_XXX_ELECTIVE),
    (@STUDENT_18, @TERM_FALL_2026 , @COURSE_CDA_4213),
    (@STUDENT_18, @TERM_FALL_2026 , @COURSE_CDA_4213L),
    (@STUDENT_18, @TERM_FALL_2026 , @COURSE_COP_4600),
    (@STUDENT_18, @TERM_FALL_2026 , @COURSE_ENC_3246),
    (@STUDENT_18, @TERM_FALL_2026 , @COURSE_XXX_ELECTIVE),
    (@STUDENT_18, @TERM_SPRING_2027 , @COURSE_CIS_4250),
    (@STUDENT_18, @TERM_SPRING_2027 , @COURSE_CIS_4910),
    (@STUDENT_18, @TERM_SPRING_2027 , @COURSE_XXX_ELECTIVE),
    (@STUDENT_18, @TERM_SPRING_2027 , @COURSE_XXX_ELECTIVE),

    (@STUDENT_19, @TERM_FALL_2023 , @COURSE_CGS_1540),
    (@STUDENT_19, @TERM_FALL_2023 , @COURSE_EGN_3000),
    (@STUDENT_19, @TERM_FALL_2023 , @COURSE_EGN_3000L),
    (@STUDENT_19, @TERM_FALL_2023 , @COURSE_ENC_1101),
    (@STUDENT_19, @TERM_FALL_2023 , @COURSE_MAC_1147),
    (@STUDENT_19, @TERM_SPRING_2024 , @COURSE_COP_2512),
    (@STUDENT_19, @TERM_SPRING_2024 , @COURSE_MAD_2104),
    (@STUDENT_19, @TERM_SPRING_2024 , @COURSE_ENC_1102),
    (@STUDENT_19, @TERM_SPRING_2024 , @COURSE_PHY_2020),
    (@STUDENT_19, @TERM_SPRING_2024 , @COURSE_XXX_ELECTIVE),
    (@STUDENT_19, @TERM_FALL_2024 , @COURSE_COP_2513),
    (@STUDENT_19, @TERM_FALL_2024 , @COURSE_CGS_3303),
    (@STUDENT_19, @TERM_FALL_2024 , @COURSE_ECO_2013),
    (@STUDENT_19, @TERM_FALL_2024 , @COURSE_STA_2023),
    (@STUDENT_19, @TERM_SPRING_2025 , @COURSE_CIS_3213),
    (@STUDENT_19, @TERM_SPRING_2025 , @COURSE_COP_3515),
    (@STUDENT_19, @TERM_SPRING_2025 , @COURSE_PSY_2012),
    (@STUDENT_19, @TERM_SPRING_2025 , @COURSE_XXX_ELECTIVE),
    (@STUDENT_19, @TERM_SUMMER_2025 , @COURSE_XXX_ELECTIVE),
    (@STUDENT_19, @TERM_SUMMER_2025 , @COURSE_XXX_ELECTIVE),
    (@STUDENT_19, @TERM_SUMMER_2025 , @COURSE_XXX_ELECTIVE),
    (@STUDENT_19, @TERM_FALL_2025 , @COURSE_CEN_3722),
    (@STUDENT_19, @TERM_FALL_2025 , @COURSE_CIS_3363),
    (@STUDENT_19, @TERM_FALL_2025 , @COURSE_CIS_4622),
    (@STUDENT_19, @TERM_FALL_2025 , @COURSE_COP_4538),
    (@STUDENT_19, @TERM_FALL_2025 , @COURSE_ISM_4323),
    (@STUDENT_19, @TERM_SPRING_2026 , @COURSE_CGS_3853),
    (@STUDENT_19, @TERM_SPRING_2026 , @COURSE_CIS_4219),
    (@STUDENT_19, @TERM_SPRING_2026 , @COURSE_CNT_4104),
    (@STUDENT_19, @TERM_SPRING_2026 , @COURSE_CNT_4104L),
    (@STUDENT_19, @TERM_SPRING_2026 , @COURSE_ENC_3246),
    (@STUDENT_19, @TERM_SPRING_2026 , @COURSE_XXX_ELECTIVE),
    (@STUDENT_19, @TERM_FALL_2026 , @COURSE_CIS_4200),
    (@STUDENT_19, @TERM_FALL_2026 , @COURSE_CNT_4403),
    (@STUDENT_19, @TERM_FALL_2026 , @COURSE_COP_4703),
    (@STUDENT_19, @TERM_FALL_2026 , @COURSE_XXX_ELECTIVE),
    (@STUDENT_19, @TERM_FALL_2026 , @COURSE_XXX_ELECTIVE),
    (@STUDENT_19, @TERM_SPRING_2027 , @COURSE_CIS_4935),
    (@STUDENT_19, @TERM_SPRING_2027 , @COURSE_LIS_4414),
    (@STUDENT_19, @TERM_SPRING_2027 , @COURSE_XXX_ELECTIVE),
    (@STUDENT_19, @TERM_SPRING_2027 , @COURSE_XXX_ELECTIVE),

    (@STUDENT_20, @TERM_FALL_2023 , @COURSE_EGN_3000),
    (@STUDENT_20, @TERM_FALL_2023 , @COURSE_EGN_3000L),
    (@STUDENT_20, @TERM_FALL_2023 , @COURSE_ENC_1101),
    (@STUDENT_20, @TERM_FALL_2023 , @COURSE_MAC_2281),
    (@STUDENT_20, @TERM_FALL_2023 , @COURSE_XXX_ELECTIVE),
    (@STUDENT_20, @TERM_SPRING_2024 , @COURSE_COP_2510),
    (@STUDENT_20, @TERM_SPRING_2024 , @COURSE_ENC_1102),
    (@STUDENT_20, @TERM_SPRING_2024 , @COURSE_MAC_2282),
    (@STUDENT_20, @TERM_SPRING_2024 , @COURSE_PHY_2048),
    (@STUDENT_20, @TERM_SPRING_2024 , @COURSE_PHY_2048L),
    (@STUDENT_20, @TERM_FALL_2024 , @COURSE_CDA_3103),
    (@STUDENT_20, @TERM_FALL_2024 , @COURSE_COP_3514),
    (@STUDENT_20, @TERM_FALL_2024 , @COURSE_COT_3100),
    (@STUDENT_20, @TERM_FALL_2024 , @COURSE_PHY_2049),
    (@STUDENT_20, @TERM_FALL_2024 , @COURSE_PHY_2049L),
    (@STUDENT_20, @TERM_SPRING_2025 , @COURSE_CDA_3201),
    (@STUDENT_20, @TERM_SPRING_2025 , @COURSE_CDA_3201L),
    (@STUDENT_20, @TERM_SPRING_2025 , @COURSE_COP_4530),
    (@STUDENT_20, @TERM_SPRING_2025 , @COURSE_XXX_ELECTIVE),
    (@STUDENT_20, @TERM_SPRING_2025 , @COURSE_XXX_ELECTIVE),
    (@STUDENT_20, @TERM_SUMMER_2025 , @COURSE_EGN_3443),
    (@STUDENT_20, @TERM_SUMMER_2025 , @COURSE_XXX_ELECTIVE),
    (@STUDENT_20, @TERM_SUMMER_2025 , @COURSE_XXX_ELECTIVE),
    (@STUDENT_20, @TERM_FALL_2025 , @COURSE_CDA_4205),
    (@STUDENT_20, @TERM_FALL_2025 , @COURSE_CDA_4205L),
    (@STUDENT_20, @TERM_FALL_2025 , @COURSE_EGN_4450),
    (@STUDENT_20, @TERM_FALL_2025 , @COURSE_XXX_ELECTIVE),
    (@STUDENT_20, @TERM_FALL_2025 , @COURSE_XXX_ELECTIVE),
    (@STUDENT_20, @TERM_FALL_2025 , @COURSE_XXX_ELECTIVE),
    (@STUDENT_20, @TERM_SPRING_2026 , @COURSE_COT_4400),
    (@STUDENT_20, @TERM_SPRING_2026 , @COURSE_ENC_3246),
    (@STUDENT_20, @TERM_SPRING_2026 , @COURSE_XXX_ELECTIVE),
    (@STUDENT_20, @TERM_SPRING_2026 , @COURSE_XXX_ELECTIVE),
    (@STUDENT_20, @TERM_SPRING_2026 , @COURSE_XXX_ELECTIVE),
    (@STUDENT_20, @TERM_FALL_2026 , @COURSE_CNT_4419),
    (@STUDENT_20, @TERM_FALL_2026 , @COURSE_COP_4600),
    (@STUDENT_20, @TERM_FALL_2026 , @COURSE_XXX_ELECTIVE),
    (@STUDENT_20, @TERM_FALL_2026 , @COURSE_XXX_ELECTIVE),
    (@STUDENT_20, @TERM_FALL_2026 , @COURSE_XXX_ELECTIVE),
    (@STUDENT_20, @TERM_SPRING_2027 , @COURSE_CEN_4020),
    (@STUDENT_20, @TERM_SPRING_2027 , @COURSE_CIS_4250),
    (@STUDENT_20, @TERM_SPRING_2027 , @COURSE_XXX_ELECTIVE),
    (@STUDENT_20, @TERM_SPRING_2027 , @COURSE_XXX_ELECTIVE);