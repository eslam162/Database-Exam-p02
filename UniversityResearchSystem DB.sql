USE UniversityResearchSystem;

ALTER Authorization ON Database :: UniversityResearchSystem TO [DESKTOP-GAIATQI\Abdulrahman];

--Question1
SELECT r.Id, CONCAT_WS(' ', r.FirstName, r.MiddleName, r.LastName) AS FullName, p.Title 
FROM Researcher r
LEFT JOIN Workson w ON r.Id = w.ResearcherId
LEFT JOIN ResearchProject p ON p.Id = w.ProjectId;

--Question2
SELECT p.Id, p.Title, CONCAT_WS(' ', r.FirstName, r.MiddleName, r.LastName) AS LeadFullName, r.Email
FROM ResearchProject p
JOIN Researcher r ON r.Id = p.LeaderId
WHERE p.Id IN (
SELECT ProjectId 
FROM Funds
);

--Question3
SELECT r.Id, r.FirstName, p.Id, p.Title
FROM Researcher r CROSS JOIN Publication p;
-- It produces a Cartesian product, returning all possible combinations of rows

--Question4
SELECT CONCAT_WS(' ', Supervisor.FirstName, Supervisor.LastName) AS SupervisorName,
       CONCAT_WS(' ', Supervisee.FirstName, Supervisee.LastName) AS SuperviseeName,
       s.SupervisionStartDate, s.[Role]
FROM Supervises s
JOIN Researcher Supervisor ON s.SupervisorId = Supervisor.Id
JOIN Researcher Supervisee ON s.SupervisedId = Supervisee.Id;

--Question5
SELECT DISTINCT r.Id, CONCAT_WS(' ', r.FirstName, r.MiddleName, r.LastName) AS FullName
FROM Researcher r
JOIN Publishes p ON r.Id = p.ResearcherId
WHERE r.Id NOT IN (
    SELECT w.ResearcherId 
    FROM WorksOn w
    JOIN ResearchProject rp ON w.ProjectId = rp.Id 
    WHERE rp.Status = 'Active'
);

--Question6
SELECT TOP 5 WITH TIES Id, Title, CitationCount
FROM Publication 
ORDER BY CitationCount DESC;

--Question7
SELECT * 
FROM Researcher 
ORDER BY LastName 
OFFSET 10 ROWS FETCH NEXT 10 ROWS ONLY;

--Question8
/*
They are functionally identical for getting the first few rows
OFFSET-FETCH is ANSI SQL standard and natively supports pagination (skipping rows before fetching)
TOP is SQL Server specific and requires subqueries to paginate
*/

--Question9
SELECT Id, FirstName, Building, DateOfBirth,
       ROW_NUMBER() OVER(PARTITION BY Building ORDER BY DateOfBirth ASC) AS SeqIndex
FROM Researcher;

--Question10
SELECT Title, [Type], CitationCount,
       RANK() OVER(PARTITION BY [Type] ORDER BY CitationCount DESC) AS [Rank]
FROM Publication;

--Question11
SELECT Id, Title, [Status], Budget,
       RANK() OVER(PARTITION BY [Status] ORDER BY Budget DESC) AS BudgetRankWithGaps,
       DENSE_RANK() OVER(PARTITION BY [Status] ORDER BY Budget DESC) AS BudgetRankWithoutGaps
FROM ResearchProject;
/*
Ranking with gaps (RANK()) skips sequence numbers if there is a tie (1, 2, 2, 4) 
Ranking without gaps (DENSE_RANK()) maintains sequential numbering even after a tie (1, 2, 2, 3).
*/

--Question12
SELECT 
    r.Id, 
    r.FirstName, 
    COUNT(p.PublicationId) AS PubCount,
    NTILE(4) OVER(ORDER BY COUNT(p.PublicationId) DESC) AS GroupNum
FROM Researcher r 
LEFT JOIN Publishes p ON r.Id = p.ResearcherId
GROUP BY r.Id, r.FirstName;

--Question13
/*
1. FROM and JOINs
2. WHERE
3. GROUP BY
4. HAVING
5. SELECT
6. ORDER BY
7. TOP/OFFSET-FETCH
*/

--Question14
/*
The error occurs because the WHERE clause is processed before the SELECT clause, 
meaning the alias ProjectCount is not yet defined
Also, aggregate functions like COUNT cannot be evaluated in the WHERE clause; HAVING must be used
*/

--Question15
SELECT CONCAT_WS(' ', FirstName, MiddleName, LastName) AS FullName,
       LOWER(Email) AS Email,
       DATEDIFF(YEAR, DateOfBirth, GETDATE()) AS Age
FROM Researcher;

--Question16
SELECT Id, Title, 
       DATEDIFF(DAY, StartDate, ISNULL(EndDate, GETDATE())) AS DurationInDays,
       MONTH(StartDate) AS StartMonth, 
       YEAR(StartDate) AS StartYear
FROM ResearchProject;

--Question17
SELECT Id, FirstName, Email 
FROM Researcher 
WHERE Email LIKE '%@university.edu';

--Question18
SELECT Id, FirstName, ISNULL(MiddleName, 'N/A') AS MiddleName, ISNULL(RoomNumber, 'N/A') AS RoomNumber
FROM Researcher;

--Question19
SELECT Id, Title, Budget,
       CASE WHEN Budget < 50000 THEN 'Small'
            WHEN Budget <= 150000 THEN 'Medium'
            ELSE 'Large' 
       END AS BudgetCategory
FROM ResearchProject;

--Question20
SELECT r.Id, CONCAT_WS(' ', r.FirstName, r.MiddleName, r.LastName) AS FullName, SUM(p.Budget) AS TotalBudget
FROM Researcher r JOIN ResearchProject p ON r.Id = p.LeaderId
GROUP BY r.Id, r.FirstName, r.MiddleName, r.LastName;

--Question21
SELECT Building, COUNT(Id) AS ResearcherCount
FROM Researcher 
GROUP BY Building 
HAVING COUNT(Id) > 3;

--Question22
SELECT [Type], AVG(CAST(CitationCount AS FLOAT)) AS AvgCitations, SUM(CitationCount) AS TotalCitations, COUNT(Id) AS PubCount
FROM Publication 
GROUP BY [Type] 
HAVING AVG(CAST(CitationCount AS FLOAT)) > 50;

--Question23
SELECT ResearcherId, COUNT(ProjectId) AS ProjectCount, SUM(HoursPerWeek) AS TotalHours
FROM WorksOn 
GROUP BY ResearcherId
HAVING COUNT(ProjectId) > 2 AND SUM(HoursPerWeek) > 60;

--Question24
SELECT Id, Title, Budget 
FROM ResearchProject 
WHERE Budget > (
SELECT AVG(Budget) FROM ResearchProject
);

--Question25
SELECT Id, PublicationCount, AvgPublication
FROM (
    SELECT 
        r.Id,
        COUNT(p.PublicationId) AS PublicationCount,
        AVG(CAST(COUNT(p.PublicationId) AS FLOAT)) OVER(PARTITION BY r.Building) AS AvgPublication
    FROM Researcher r 
    LEFT JOIN Publishes p ON r.Id = p.ResearcherId
    GROUP BY r.Id, r.Building
) AS StatsTable
WHERE PublicationCount > AvgPublication;

--Question26
SELECT Id, CONCAT_WS(' ', FirstName, MiddleName, LastName) AS FullName
FROM Researcher r
WHERE EXISTS (SELECT 1 FROM Supervises s WHERE r.Id = s.SupervisorId);

--Question27
SELECT p.Id, p.Title, (
SELECT COUNT(*) FROM WorksOn w WHERE w.ProjectId = p.Id
) AS TotalResearchers
FROM ResearchProject p;

--Question28
SELECT MAX(Budget) AS SecondHighest 
FROM ResearchProject 
WHERE Budget < (SELECT MAX(Budget) FROM ResearchProject);

--Question29
SELECT DISTINCT w.ResearcherId 
FROM WorksOn w
WHERE NOT EXISTS (SELECT 1 FROM Publishes p WHERE p.ResearcherId = w.ResearcherId);

--Question30
SELECT DISTINCT LeaderId 
FROM ResearchProject
INTERSECT
SELECT DISTINCT SupervisorId 
FROM Supervises;

--Question31
GO
CREATE OR ALTER FUNCTION dbo.GetActiveDays(@ProjectId INT) 
RETURNS INT 
AS
BEGIN
    RETURN (SELECT DATEDIFF(DAY, StartDate, ISNULL(EndDate, GETDATE())) 
            FROM ResearchProject 
            WHERE Id = @ProjectId);
END;

--Question32
GO
CREATE OR ALTER FUNCTION GetResearcherProjects(@ResearcherId INT) 
RETURNS TABLE 
AS 
RETURN(SELECT p.Title, w.Role, w.HoursPerWeek 
       FROM WorksOn w JOIN ResearchProject p ON w.ProjectId = p.Id 
       WHERE w.ResearcherId = @ResearcherId);

--Question33
GO
CREATE OR ALTER FUNCTION GetResearcherStats(@ResearcherId INT)
RETURNS @Stats 
TABLE (TotalProjects INT, TotalPubs INT, TotalHours INT, AvgCitations FLOAT)
AS
BEGIN
    INSERT INTO @Stats
    SELECT 
        (SELECT COUNT(*) FROM WorksOn WHERE ResearcherId = @ResearcherId),
        (SELECT COUNT(*) FROM Publishes WHERE ResearcherId = @ResearcherId),
        (SELECT SUM(HoursPerWeek) FROM WorksOn WHERE ResearcherId = @ResearcherId),
        (SELECT AVG(CAST(CitationCount AS FLOAT)) FROM Publication p JOIN Publishes pb ON p.Id = pb.PublicationId WHERE pb.ResearcherId = @ResearcherId);
    RETURN;
END;
/*
A multi-statement Table-Valued Function (TVF) is preferred when complex procedural logic (like IF/ELSE, WHILE loops,
or declaring temporary variables) is required before returning the result set
Inline TVFs perform better but are limited to a single SELECT statement
*/

--Question34
GO
CREATE NONCLUSTERED INDEX IX_ResearchProject_Status_StartDate 
ON ResearchProject([Status], StartDate);

--Question35
/*
A clustered index physically sorts the data on disk based on the key so a table can only have one
A non-clustered index is a separate structure containing pointers to the physical data
Creating a new clustered index automatically forces a rebuild of all non-clustered indexes
*/

--Question36
CREATE NONCLUSTERED INDEX IX_Researcher_Email 
ON Researcher(Email) 
INCLUDE (FirstName, LastName);
/*
A covering index includes all the columns referenced in a query (in SELECT, JOIN, and WHERE)
It improves performance by eliminating the need for the engine to perform "Key Lookups" to the base table
*/

--Question37
GO
CREATE OR ALTER VIEW ActiveProjectSummary 
AS
SELECT p.Title, CONCAT_WS(' ', l.FirstName, l.MiddleName, l.LastName) AS LeaderName,
       COUNT(w.ResearcherId) AS TeamMembersCount, SUM(w.HoursPerWeek) AS TotalHoursAllocated, p.Budget
FROM ResearchProject p JOIN Researcher l ON p.LeaderId = l.Id
LEFT JOIN WorksOn w ON p.Id = w.ProjectId 
WHERE p.Status = 'Active'
GROUP BY p.Id, p.Title, l.FirstName, l.MiddleName, l.LastName, p.Budget;

--Question38
GO
CREATE OR ALTER VIEW ResearcherPublicationStats WITH SCHEMABINDING 
AS
SELECT r.Id AS ResearcherId, r.FirstName, r.MiddleName, r.LastName, COUNT_BIG(*) AS TotalPubs
FROM dbo.Researcher r JOIN dbo.Publishes p ON r.Id = p.ResearcherId
GROUP BY r.Id, r.FirstName, r.MiddleName, r.LastName;

GO
CREATE UNIQUE CLUSTERED INDEX CIX_ResPubStats 
ON ResearcherPublicationStats(ResearcherId);

--Question39
/*
Requirements: Must use WITH SCHEMABINDING, specify two-part table names, use COUNT_BIG(*) for aggregations,
and create a unique clustered index
Benefits: Physically stores the result set on disk, significantly improving read performance 
Best for heavy-read/low-update scenarios like Dashboards
*/

--Question40
GO
CREATE OR ALTER PROCEDURE AddResearcherToProject
    @ResearcherId INT, @ProjectId INT, @JoinDate DATE, @Role VARCHAR(50), @HoursPerWeek INT
AS
BEGIN
    IF NOT EXISTS (SELECT 1 FROM Researcher WHERE Id = @ResearcherId) OR NOT EXISTS (SELECT 1 FROM ResearchProject WHERE Id = @ProjectId) RETURN -1;
    IF EXISTS (SELECT 1 FROM WorksOn WHERE ResearcherId = @ResearcherId AND ProjectId = @ProjectId) RETURN -1;
    INSERT INTO WorksOn (ResearcherId, ProjectId, JoinDate, Role, HoursPerWeek) 
    VALUES (@ResearcherId, @ProjectId, @JoinDate, @Role, @HoursPerWeek);
    RETURN 0;
END;

--Question41
GO
CREATE OR ALTER PROCEDURE UpdateProjectStatus 
    @ProjectId INT 
    AS
BEGIN
    BEGIN TRY
        IF EXISTS (SELECT 1 FROM WorksOn WHERE ProjectId = @ProjectId) AND EXISTS (SELECT 1 FROM Funds WHERE ProjectId = @ProjectId)
            UPDATE ResearchProject 
            SET Status = 'Active' 
            WHERE Id = @ProjectId AND Status = 'Pending';
    END TRY
    BEGIN CATCH 
        PRINT ERROR_MESSAGE(); 
    END CATCH
END;

--Question42
GO
CREATE OR ALTER PROCEDURE GetResearcherMetrics
    @ResearcherId INT, @TotalProjects INT OUTPUT, @TotalPubs INT OUTPUT, @TotalHours INT OUTPUT
AS
BEGIN
    SELECT @TotalProjects = COUNT(*) FROM WorksOn WHERE ResearcherId = @ResearcherId;
    SELECT @TotalPubs = COUNT(*) FROM Publishes WHERE ResearcherId = @ResearcherId;
    SELECT @TotalHours = SUM(HoursPerWeek) FROM WorksOn WHERE ResearcherId = @ResearcherId;
END;

--Guestion43
GO
CREATE OR ALTER TRIGGER trg_LimitProjects 
ON WorksOn AFTER INSERT 
AS
BEGIN
    IF EXISTS (SELECT 1 FROM WorksOn w JOIN inserted i ON w.ResearcherId = i.ResearcherId 
    GROUP BY w.ResearcherId 
    HAVING COUNT(*) > 5)
    BEGIN
        RAISERROR ('Limit 5 projects exceeded.', 16, 1); 
        ROLLBACK TRANSACTION;
    END
END;

--Question44
GO
CREATE OR ALTER TRIGGER trg_CloseProject 
ON ResearchProject AFTER UPDATE 
AS
BEGIN
    IF UPDATE(EndDate)
    BEGIN
        UPDATE p SET Status = 'Completed' 
        FROM ResearchProject p JOIN inserted i ON p.Id = i.Id
        WHERE i.EndDate < GETDATE() AND p.Status != 'Completed';
    END
END;
/*
An AFTER trigger is preferred here
It allows the original UPDATE (setting the EndDate) to succeed normally 
and then executes the project status change as an automated side-effect
*/

--Question45
GO
CREATE TABLE GrantsAudit 
    (AuditId INT IDENTITY, GrantId INT, OldAmount DECIMAL, NewAmount DECIMAL, ModifiedBy NVARCHAR(50), ModifiedDate DATETIME);

GO
CREATE OR ALTER TRIGGER trg_AuditGrants 
ON Grants AFTER UPDATE 
AS
BEGIN
    IF UPDATE(Amount)
    BEGIN
        INSERT INTO GrantsAudit (GrantId, OldAmount, NewAmount, ModifiedBy, ModifiedDate)
        SELECT i.Id, d.Amount, i.Amount, SYSTEM_USER, GETDATE()
        FROM inserted i JOIN deleted d ON i.Id = d.Id 
        WHERE i.Amount != d.Amount;
    END
END;

--Question46
BEGIN TRY
    BEGIN TRANSACTION;
        DECLARE @NewId INT;
        INSERT INTO ResearchProject (Title, StartDate, Budget, [Status], LeaderId) 
        VALUES ('New AI', GETDATE(), 100000, 'Active', 1);
        SET @NewId = SCOPE_IDENTITY();
        INSERT INTO WorksOn (ResearcherId, ProjectId, Role) 
        VALUES (1, @NewId, 'Leader');
        INSERT INTO Funds (GrantId, ProjectId, AllocationAmount) 
        VALUES (1, @NewId, 100000);
    COMMIT TRANSACTION;
END TRY
BEGIN CATCH
    IF @@TRANCOUNT > 0 
       ROLLBACK TRANSACTION;
    PRINT ERROR_MESSAGE();
END CATCH;

--Question47
/*
Atomicity: All transaction parts succeed or fail together (adding a project and funding fails entirely if the funding part fails)

Consistency: Data remains valid according to rules (a grant cannot be assigned to a non-existent project)

Isolation: Concurrent transactions do not interfere (two users allocating funds from the same grant won't create a calculation error)

Durability: Committed data is permanently saved (a saved project remains even after a server crash)
*/

--Question48
/*
EXISTS generally performs better
The query optimizer uses "short-circuit" with EXISTS, stopping the search as soon as the first match is found
IN might build and evaluate the entire subquery list first
*/

--Question49
/*
1. Create indexes on Status and StartDate 
2. Convert LEFT JOIN to INNER JOIN (the WHERE clause already filters out NULLs)
3. Create a Covering Index on WorksOn and Researcher to avoid key lookups
*/

--Question50
/*
Ad-hoc (Option A): Flexible but incurs compilation overhead every run

View (Option B): Organizes code but provides no performance gain

Stored Procedure (Option C): Best choice. Excellent performance via execution plan caching and provides real-time data

Indexed View (Option D): Very fast for reads, but TOP and ORDER BY are not directly supported inside its definition
*/