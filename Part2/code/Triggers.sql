# Zhe Lin 109369879
# Sean Pesce 107102508
# Weichao Zhao 109957656
#
# CSE305 Database Project Part 2
# Database Schema - Procedures & Triggers



############################
#########Procedures#########
############################


# Checks that an employee began working before they helped with an order:
DELIMITER $$
CREATE PROCEDURE EmployeeExistsBeforeOrder (IN New_EmployeeID INT(9) UNSIGNED ZEROFILL, New_OrderID INT UNSIGNED)
BEGIN
	IF (SELECT DATE(OrderDate)
		FROM _Order
		WHERE New_OrderID = ID)
		<
		(SELECT StartDate
			FROM Employee
			WHERE New_EmployeeID = Employee.SSN
		)
	THEN 
		SIGNAL SQLSTATE 'E0451'
            SET MESSAGE_TEXT = 'Date conflict: Order date precedes Employee start date.';
    END IF;
END;
$$
DELIMITER ;


# Checks that a customer's account was created before they placed an order:
DELIMITER $$
CREATE PROCEDURE AccountExistsBeforeOrder (IN New_AccountID INT UNSIGNED, New_OrderID INT UNSIGNED)
BEGIN
	IF  (SELECT DATE(OrderDate)
		FROM _Order O
		WHERE New_OrderID = O.ID)
		<
		(SELECT A.Created
			FROM Account A
			WHERE New_AccountID = A.ID
		)
	THEN 
		SIGNAL SQLSTATE 'E0451'
            SET MESSAGE_TEXT = 'Date conflict: Order date precedes Customer\'s account creation.';
    END IF;
END;
$$
DELIMITER ;


# Checks that an account was created before they put a movie in their queue:
DELIMITER $$
CREATE PROCEDURE AccountExistsBeforeQueue (IN New_AccountID INT UNSIGNED, New_DateAdded DATETIME)
BEGIN
	IF DATE(New_DateAdded) < (SELECT A.Created
			FROM Account A
			WHERE New_AccountID = A.ID
		)
	THEN 
		SIGNAL SQLSTATE 'E0451'
            SET MESSAGE_TEXT = 'Date conflict: Date of queue insertion precedes Customer\'s account creation.';
    END IF;
END;
$$
DELIMITER ;


# Checks that an order's OrderDate precedes the ReturnDate:
DELIMITER $$
CREATE PROCEDURE CantReturnBeforeRenting (New_OrderDate DATETIME, New_ReturnDate DATETIME)
BEGIN
	IF	 (New_ReturnDate != NULL) AND
		New_ReturnDate < New_OrderDate
	THEN 
		SIGNAL SQLSTATE 'E0451'
            SET MESSAGE_TEXT = 'Date conflict: Date of return precedes date when order was placed.';
    END IF;
END;
$$
DELIMITER ;


# Checks that an account isn't renting 2 copies of the same movie at the same time:
DELIMITER $$
CREATE PROCEDURE CantHaveTwoCopies (
	IN New_OrderID INT UNSIGNED, New_AccountID INT UNSIGNED, New_MovieID INT UNSIGNED)
BEGIN
	IF 	(NULL = (SELECT ReturnDate
				FROM _Order O1
				WHERE O1.ID = New_OrderID))
		AND
		EXISTS (SELECT *
			FROM Rental R1 JOIN _Order O2 ON (R1.OrderID = O2.ID)
			WHERE
				New_AccountID = R1.AccountID AND
				New_MovieID = R1.MovieID AND
				O2.ReturnDate = NULL AND
				New_OrderID != O2.ID
		)
	THEN 
		SIGNAL SQLSTATE 'E0928'
            SET MESSAGE_TEXT = 'Rental conflict: Customer is already renting a copy of this movie.';
    END IF;
END;
$$
DELIMITER ;


# Checks that customer can't rent a movie if no copies are available:
DELIMITER $$
CREATE PROCEDURE CantRentUnavailable (IN New_OrderID INT UNSIGNED, New_MovieID INT UNSIGNED)
BEGIN
	IF 	(NULL = (SELECT O1.ReturnDate
				FROM _Order O1
				WHERE New_OrderID = O1.ID))
				AND (
				(SELECT TotalCopies
				FROM Movie M
				WHERE M.ID = New_MovieID
				)
				<=
				(SELECT COUNT(*)
				FROM Rental R JOIN _Order O2 ON (R.OrderID = O2.ID)
				WHERE New_MovieID = R.MovieID AND
				O2.ReturnDate = NULL AND
				New_OrderID != O2.ID
				))
	THEN 
		SIGNAL SQLSTATE 'E0928'
            SET MESSAGE_TEXT = 'Rental conflict: There are no available copies of this movie.';
    END IF;
END;
$$
DELIMITER ;


# If a movie is rented and not expired, delete from Queued:
DELIMITER $$
CREATE PROCEDURE DeleteFromQueue (IN New_AccountID INT UNSIGNED, New_MovieID INT UNSIGNED, New_OrderID INT UNSIGNED) # @TODO: Delete this procedure? Can movies be queued while checked out?
BEGIN
	IF	(NULL = (SELECT ReturnDate
				FROM _Order
				WHERE New_OrderID = ID))
	THEN
		DELETE FROM Queued WHERE Queued.MovieID = New_MovieID AND Queued.AccountID = New_AccountID;
	END IF;
END;
$$
DELIMITER ;


# Make sure there is always at least 1 manager:
DELIMITER $$
CREATE PROCEDURE ManagerExistsOnUpdate (IN Old_EmployeeID INT(9) UNSIGNED ZEROFILL, New_Position ENUM('Manager', 'Customer Rep'), Old_Position ENUM('Manager', 'Customer Rep'))  # @TODO: Add this procedure/trigger for Person (with extra check that the person is a manager)
BEGIN
	IF	('Manager' != New_Position) AND ('Manager' = Old_Position)
		AND NOT EXISTS 	(SELECT *
						FROM Employee E
						WHERE E.SSN != Old_EmployeeID AND E.Position = 'Manager')
			
	THEN
		SIGNAL SQLSTATE 'E1991'
            SET MESSAGE_TEXT = 'Staff conflict: Company requires at least 1 employee to retain \'Manager\' status at all times.';
	END IF;
END;
$$
DELIMITER ;

# Make sure there is always at least 1 manager:
DELIMITER $$
CREATE PROCEDURE ManagerExistsOnDelete (IN EmployeeID INT(9) UNSIGNED ZEROFILL, Pos ENUM('Manager', 'Customer Rep')) # @TODO: Add this procedure/trigger for Person (with extra check that the person is a manager)
BEGIN
	IF	('Manager' = Pos) AND
		NOT EXISTS 	(SELECT *
						FROM Employee E
						WHERE E.SSN != EmployeeID AND E.Position = 'Manager')
			
	THEN
		SIGNAL SQLSTATE 'E1991'
            SET MESSAGE_TEXT = 'Staff conflict: Company requires at least 1 employee to retain \'Manager\' status at all times.';
	END IF;
END;
$$
DELIMITER ;





############################
##########Triggers##########
############################

# Pre-INSERT trigger for Rental:
DELIMITER $$
CREATE TRIGGER Rental_PreInsert_Checks BEFORE INSERT ON Rental
FOR EACH ROW BEGIN
	CALL CantRentUnavailable(NEW.OrderID, NEW.MovieID);
	CALL CantHaveTwoCopies(NEW.OrderID, NEW.AccountID, NEW.MovieID);
	CALL AccountExistsBeforeOrder (NEW.AccountID, NEW.OrderID);
	CALL EmployeeExistsBeforeOrder(NEW.EmployeeID, NEW.OrderID);
END;
$$
DELIMITER ;
# Post-INSERT trigger for Rental:
DELIMITER $$
CREATE TRIGGER Rental_PostInsert_Checks AFTER INSERT ON Rental
FOR EACH ROW BEGIN
	CALL DeleteFromQueue(NEW.AccountID, NEW.MovieID, NEW.OrderID);
END;
$$
DELIMITER ;
# Pre-UPDATE trigger for Rental:
DELIMITER $$
CREATE TRIGGER Rental_PreUpdate_Checks BEFORE UPDATE ON Rental
FOR EACH ROW BEGIN
	CALL CantRentUnavailable(NEW.OrderID, NEW.MovieID);
	CALL CantHaveTwoCopies(NEW.OrderID, NEW.AccountID, NEW.MovieID);
	CALL AccountExistsBeforeOrder (NEW.AccountID, NEW.OrderID);
	CALL EmployeeExistsBeforeOrder(NEW.EmployeeID, NEW.OrderID);
END;
$$
DELIMITER ;
# Post-INSERT trigger for Rental:
DELIMITER $$
CREATE TRIGGER Rental_PostUpdate_Checks AFTER UPDATE ON Rental
FOR EACH ROW BEGIN
	CALL DeleteFromQueue(NEW.AccountID, NEW.MovieID, NEW.OrderID);
END;
$$
DELIMITER ;




# Pre-INSERT trigger for Queued:
DELIMITER $$
CREATE TRIGGER Queued_PreInsert_Checks BEFORE INSERT ON Queued
FOR EACH ROW BEGIN
	CALL AccountExistsBeforeQueue(NEW.AccountID, NEW.DateAdded);
END;
$$
DELIMITER ;
# Pre-UPDATE trigger for Queued:
DELIMITER $$
CREATE TRIGGER Queued_PreUpdate_Checks BEFORE UPDATE ON Queued
FOR EACH ROW BEGIN
	CALL AccountExistsBeforeQueue(NEW.AccountID, NEW.DateAdded);
END;
$$
DELIMITER ;




# Pre-UPDATE trigger for _Order:
DELIMITER $$
CREATE TRIGGER Order_PreUpdate_Checks BEFORE UPDATE ON _Order
FOR EACH ROW BEGIN
	CALL CantReturnBeforeRenting(NEW.OrderDate, NEW.ReturnDate);
END;
$$
DELIMITER ;
# Pre-INSERT trigger for _Order:
DELIMITER $$
CREATE TRIGGER Order_PreInsert_Checks BEFORE INSERT ON _Order
FOR EACH ROW BEGIN
	CALL CantReturnBeforeRenting(NEW.OrderDate, NEW.ReturnDate);
END;
$$
DELIMITER ;




# Pre-UPDATE trigger for Employee:
DELIMITER $$
CREATE TRIGGER Employee_PreUpdate_Checks BEFORE UPDATE ON Employee
FOR EACH ROW BEGIN
	CALL ManagerExistsOnUpdate(OLD.SSN, NEW.Position, OLD.Position);
END;
$$
DELIMITER ;
# Pre-DELETE trigger for Employee:
DELIMITER $$
CREATE TRIGGER Employee_PreDelete_Checks BEFORE DELETE ON Employee
FOR EACH ROW BEGIN
	CALL ManagerExistsOnDelete(OLD.SSN, OLD.Position);
END;
$$
DELIMITER ;




# Pre-INSERT trigger for Movie:
DELIMITER $$
CREATE TRIGGER Movie_PreInsert_Checks BEFORE INSERT ON Movie
FOR EACH ROW BEGIN
	# @TODO
END;
$$
DELIMITER ;
# Pre-UPDATE trigger for Movie:
DELIMITER $$
CREATE TRIGGER Movie_PreUpdate_Checks BEFORE UPDATE ON Movie
FOR EACH ROW BEGIN
	# @TODO
END;
$$
DELIMITER ;
