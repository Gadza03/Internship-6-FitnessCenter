CREATE TABLE Countries (
    CountryId SERIAL PRIMARY KEY,
    Name VARCHAR(50) NOT NULL,
    Population INT NOT NULL,
    AverageSalary NUMERIC(10, 2) NOT NULL
);

CREATE TABLE FitnessCenters (
    CenterId SERIAL PRIMARY KEY,
    Name VARCHAR(100) NOT NULL,
    WorkingHours VARCHAR(50) NOT NULL
);
ALTER TABLE FitnessCenters
	ADD COLUMN CountryId INT NOT NULL REFERENCES Countries(CountryId);

CREATE TABLE ActivityTypes (
    TypeId SERIAL PRIMARY KEY,
    Name VARCHAR(50) NOT NULL
);

CREATE TABLE Activities (
    ActivityId SERIAL PRIMARY KEY,
    TypeId INT NOT NULL REFERENCES ActivityTypes(TypeId),
    CenterId INT NOT NULL REFERENCES FitnessCenters(CenterId)
);

CREATE TABLE Trainers (
    TrainerId SERIAL PRIMARY KEY,
    FirstName VARCHAR(50) NOT NULL,
    LastName VARCHAR(50) NOT NULL,
    DateOfBirth DATE NOT NULL,
    Gender VARCHAR(20) NOT NULL CHECK (Gender IN ('Male', 'Female', 'Unknown', 'Other')),
    CountryId INT NOT NULL REFERENCES Countries(CountryId),
    CenterId INT NOT NULL REFERENCES FitnessCenters(CenterId)
);

CREATE TABLE Activity_Trainers (
    ActivityId INT NOT NULL REFERENCES Activities(ActivityId),
    TrainerId INT NOT NULL REFERENCES Trainers(TrainerId),
    TrainerRole VARCHAR(20) NOT NULL CHECK (TrainerRole IN ('Head', 'Assistant')),
    PRIMARY KEY (ActivityId, TrainerId)
);
--Trigger za trenere
CREATE OR REPLACE FUNCTION check_head_trainer_count() 
RETURNS TRIGGER AS $$
BEGIN   
    IF (SELECT COUNT(*)
         FROM Activity_Trainers
         WHERE TrainerId = NEW.TrainerId AND TrainerRole = 'Head') >= 3 THEN
        RAISE EXCEPTION 'Trainer with ID % cannot be assigned as Head on more than 2 activities.', NEW.TrainerId;
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_check_head_trainer_count
BEFORE INSERT ON Activity_Trainers
FOR EACH ROW
EXECUTE FUNCTION check_head_trainer_count();

CREATE TABLE Schedules (
    ScheduleId SERIAL PRIMARY KEY,
    ActivityId INT NOT NULL REFERENCES Activities(ActivityId),
    Date TIMESTAMP NOT NULL,
    CurrentParticipants INT NOT NULL DEFAULT 0,
    MaxParticipants INT NOT NULL,
    PricePerSession NUMERIC(10, 2) NOT NULL,
    CONSTRAINT check_price_per_session CHECK (PricePerSession >= 0)
);

ALTER TABLE Schedules 
    ADD COLUMN IsActive BOOLEAN;


CREATE TABLE Users (
    UserId SERIAL PRIMARY KEY,
    FirstName VARCHAR(50) NOT NULL,
    LastName VARCHAR(50) NOT NULL,
    Email VARCHAR(50) NOT NULL
);

CREATE TABLE Participations (
    ScheduleId INT NOT NULL REFERENCES Schedules(ScheduleId),
    UserId INT NOT NULL REFERENCES Users(UserId),
    PRIMARY KEY (ScheduleId, UserId)
);

CREATE OR REPLACE FUNCTION update_current_participants()
RETURNS TRIGGER AS $$
BEGIN
    UPDATE Schedules
    SET CurrentParticipants = CurrentParticipants + 1
    WHERE ScheduleId = NEW.ScheduleId;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_update_current_participants
AFTER INSERT ON Participations
FOR EACH ROW
EXECUTE FUNCTION update_current_participants();
