--Ime, prezime, spol (ispisati ‘MUŠKI’, ‘ŽENSKI’, ‘NEPOZNATO’, ‘OSTALO’), ime države i prosječna plaća u toj državi za svakog trenera.
SELECT t.FirstName,t.LastName, UPPER(t.gender), c.Name, c.averagesalary FROM Trainers t
INNER JOIN Countries c on t.CountryId = c.CountryId

--Naziv i termin održavanja svake sportske igre zajedno s imenima glavnih trenera (u formatu Prezime, I.; npr. Horvat, M.; Petrović, T.).
SELECT aty.Name, s.date AS EventDate,CONCAT(t.LastName, ', ', SUBSTRING(t.FirstName, 1, 1) || '.') AS TrainerName
FROM Schedules s
JOIN Activity_Trainers at ON s.ScheduleId = at.ActivityId
JOIN Activities a on at.ActivityId = a.ActivityId
JOIN ActivityTypes aty on a.TypeId = aty.TypeId
JOIN Trainers t ON at.TrainerId = t.trainerId
WHERE AT.TrainerRole = 'Head'
GROUP BY s.date,  t.FirstName, t.LastName, aty.Name

--Top 3 fitness centra s najvećim brojem aktivnosti u rasporedu
SELECT fc.CenterId, fc.Name, COUNT(s.ActivityId) AS ActivityCount
FROM Schedules s
JOIN Activities a ON s.ActivityId = a.ActivityId
JOIN FitnessCenters fc ON a.CenterId = fc.CenterId
GROUP BY fc.CenterId, fc.Name
ORDER BY ActivityCount DESC
LIMIT 3

--Po svakom terneru koliko trenutno aktivnosti vodi; ako nema aktivnosti, ispiši “DOSTUPAN”, ako ima do 3 ispiši “AKTIVAN”, a ako je na više ispiši “POTPUNO ZAUZET”
SELECT 
t.FirstName || ' ' || t.LastName as FullName,
COUNT(a.ActivityId) AS ActivityCount,
CASE
	WHEN COUNT(a.ActivityId) < 1 THEN 'DOSTUPAN'
	WHEN COUNT(a.ActivityId) BETWEEN 1 AND 3 THEN 'AKTIVAN'
	ELSE 'POTPUNO ZAUZET'
	END as STATUS
FROM Trainers t
LEFT JOIN Activity_Trainers at on t.TrainerId = at.TrainerId
LEFT JOIN Activities a on at.ActivityId = a.ActivityId
GROUP BY t.FirstName, t.LastName

--Imena svih članova koji trenutno sudjeluju na nekoj aktivnosti.
SELECT DISTINCT u.FirstName || ' ' || u.LastName as ActivityUsers, u.Email FROM Users u
JOIN Participations p On u.UserId = p.UserId
JOIN Schedules s ON p.ScheduleId = s.ScheduleId
WHERE s.IsActive = true

--Sve trenere koji su vodili barem jednu aktivnost između 2019. i 2022.
SELECT t.TrainerId, t.FirstName, Count(s.ActivityId) FROM Trainers t
JOIN Activity_Trainers at on t.TrainerId = at.TrainerId
JOIN Activities a on at.ActivityId = a.ActivityId
JOIN Schedules s on a.ActivityId = s.ActivityId
WHERE s.Date BETWEEN '2019-01-01' AND '2022-12-31'
GROUP BY t.FirstName,t.TrainerId

--Prosječan broj sudjelovanja po tipu aktivnosti po svakoj državi.
SELECT c.Name AS CountryName,aty.Name, ROUND(AVG(participation_count),2) AS AvgParticipationCount
FROM 
    (
        SELECT s.ScheduleId,COUNT(*) AS participation_count
        FROM Participations p
        JOIN Schedules s ON p.ScheduleId = s.ScheduleId
        GROUP BY s.ScheduleId
    ) AS participation_counts
JOIN Schedules s on participation_counts.ScheduleId = s.ScheduleId
JOIN Activities a ON s.ActivityId = a.ActivityId
JOIN ActivityTypes aty on a.TypeId = aty.TypeId
JOIN FitnessCenters fc on a.CenterId = fc.CenterId
JOIN Countries c on fc.CountryId = c.CountryId
GROUP BY c.Name, aty.Name
ORDER BY c.Name

--Top 10 država s najvećim brojem sudjelovanja u injury rehabilitation tipu aktivnosti
SELECT c.Name, COUNT(aty.TypeId) AS InjuryCount FROM Countries c
JOIN FitnessCenters fc on c.CountryId = fc.CountryId
JOIN Activities a on fc.CenterId = a.CenterId
JOIN ActivityTypes aty on a.TypeId = aty.TypeId
WHERE aty.Name =  'Injury Rehabilitation'
GROUP BY c.Name
ORDER BY InjuryCount DESC
LIMIT 10

--Ako aktivnost nije popunjena, ispiši uz nju “IMA MJESTA”, a ako je popunjena ispiši “POPUNJENO” 
-- ID 9 je popunjen ima 10 od 10  user-a
SELECT
s.ScheduleId,
CASE
	WHEN s.CurrentParticipants < s.MaxParticipants THEN 'IMA MJESTA'
	ELSE 'POPUNJENO'
END as Status,
s.CurrentParticipants,
s.MaxParticipants
FROM Schedules s
ORDER BY s.ScheduleId

--10 najplaćenijih trenera, ako po svakoj aktivnosti dobije prihod kao brojSudionika * cijenaPoTerminu
SELECT t.FirstName, t.LastName, SUM(s.CurrentParticipants * s.PricePerSession) AS SalarySum
FROM Trainers t
JOIN Activity_Trainers at on t.TrainerId = at.TrainerId
JOIN Activities a on at.ActivityId = a.ActivityId
JOIN Schedules s on a.ActivityId = s.ActivityId
GROUP BY t.FirstName, t.LastName
ORDER BY SalarySum DESC
LIMIT 10

