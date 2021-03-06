# Zhe Lin 109369879
# Sean Pesce 107102508
# Weichao Zhao 109957656
#
# CSE305 Database Project Part 3
# Database Schema - Functional Transactions (Procedures)


########################################
####### Manager-Level Procedures #######
########################################

# Add a movie:
DELIMITER $$
CREATE PROCEDURE AddMovie (IN new_Title VARCHAR(64), new_Genre ENUM ('Comedy', 'Drama', 'Action', 'Foreign'), new_Fee FLOAT, new_TotalCopies INT UNSIGNED)
BEGIN
	START TRANSACTION;
        INSERT INTO Movie (Title, Genre, Fee, TotalCopies)
        VALUES (new_Title, new_Genre, new_Fee, new_TotalCopies);
    COMMIT;
END;
$$
DELIMITER ;

# Edit a movie:
DELIMITER $$
CREATE PROCEDURE EditMovie (IN MovieID INT UNSIGNED, _Attribute VARCHAR(64), new_Value VARCHAR(256))
BEGIN
    START TRANSACTION;
        SET @editmovie_str = CONCAT('UPDATE Movie SET ', _Attribute, '=', new_Value, ' WHERE ID=', MovieID);
        PREPARE editmovie_stmt FROM @editmovie_str;
        EXECUTE editmovie_stmt;
        DEALLOCATE PREPARE editmovie_stmt;
    COMMIT;
END;
$$
DELIMITER ;

# Delete a movie:
DELIMITER $$
CREATE PROCEDURE DeleteMovie (IN MovieID INT UNSIGNED)
BEGIN
    START TRANSACTION;
        DELETE FROM Movie
        WHERE ID=MovieID;
    COMMIT;
END;
$$
DELIMITER ;

# Add an Actor:
DELIMITER $$
CREATE PROCEDURE AddActor (IN new_FirstName VARCHAR(64), new_LastName VARCHAR(64), new_Gender ENUM ('M', 'F'), new_Age INT UNSIGNED, new_Rating INT UNSIGNED)
BEGIN
	START TRANSACTION;
        INSERT INTO Actor (FirstName, LastName, Gender, Age, Rating)
        VALUES (new_FirstName, new_LastName, new_Gender, new_Age, new_Rating);
    COMMIT;
END;
$$
DELIMITER ;

# Edit an Actor:
DELIMITER $$
CREATE PROCEDURE EditActor (IN ActorID INT UNSIGNED, _Attribute VARCHAR(64), new_Value VARCHAR(256))
BEGIN
    START TRANSACTION;
        SET @editActor_str = CONCAT('UPDATE Actor SET ', _Attribute, '=', new_Value, ' WHERE ID=', ActorID);
        PREPARE editActor_stmt FROM @editActor_str;
        EXECUTE editActor_stmt;
        DEALLOCATE PREPARE editActor_stmt;
    COMMIT;
END;
$$
DELIMITER ;

# Delete an Actor:
DELIMITER $$
CREATE PROCEDURE DeleteActor (IN ActorID INT UNSIGNED)
BEGIN
    START TRANSACTION;
        DELETE FROM Actor
        WHERE ID=ActorID;
    COMMIT;
END;
$$
DELIMITER ;

# Add an Actor to the cast of a Movie:
DELIMITER $$
CREATE PROCEDURE AddRole (IN new_ActorID INT UNSIGNED, new_MovieID INT UNSIGNED)
BEGIN
	START TRANSACTION;
        INSERT INTO Casted (ActorID, MovieID)
        VALUES (new_ActorID, new_MovieID);
    COMMIT;
END;
$$
DELIMITER ;

# Edit a casting role:
DELIMITER $$
CREATE PROCEDURE EditRole (IN ActorID INT UNSIGNED, MovieID INT UNSIGNED, _Attribute VARCHAR(64), new_Value VARCHAR(256))
BEGIN
    START TRANSACTION;
        SET @editCasted_str = CONCAT('UPDATE Casted SET ', _Attribute, '=', new_Value, ' WHERE ActorID=', ActorID, ' AND MovieID=', MovieID);
        PREPARE editCasted_stmt FROM @editCasted_str;
        EXECUTE editCasted_stmt;
        DEALLOCATE PREPARE editCasted_stmt;
    COMMIT;
END;
$$
DELIMITER ;

# Delete a casting role:
DELIMITER $$
CREATE PROCEDURE DeleteRole (IN Actor INT UNSIGNED, Movie INT UNSIGNED)
BEGIN
    START TRANSACTION;
        DELETE FROM Casted
        WHERE ActorID=Actor AND MovieID=Movie;
    COMMIT;
END;
$$
DELIMITER ;



# Add an Employee:
DELIMITER $$
CREATE PROCEDURE AddEmployee (IN    new_Position ENUM('Manager', 'Customer Rep'), new_SSN INT UNSIGNED, new_FirstName VARCHAR(64),
                                    new_LastName VARCHAR(64), new_Address VARCHAR(64), new_City VARCHAR(64), new_State CHAR(2),
                                    new_Zip INT(5) UNSIGNED, new_Phone BIGINT(10) UNSIGNED, new_StartDate DATE, new_Wage FLOAT)
BEGIN
    DECLARE current_person_index INT; # Needed if a customer exists with the new Employee's SSN
    SET new_SSN = IF(new_SSN=0, (SELECT AUTO_INC FROM PersonData LIMIT 1), new_SSN);
	START TRANSACTION;
    IF NOT EXISTS (SELECT * FROM Person WHERE ID = new_SSN) THEN
        INSERT INTO Person (ID, LastName, FirstName, Address, City, State, Zip, Phone)
        VALUES (new_SSN, new_LastName, new_FirstName, new_Address, new_City, UPPER(new_State), new_Zip, new_Phone);
    ELSEIF NOT EXISTS(SELECT * FROM Employee WHERE SSN=new_SSN) AND (
           new_FirstName != (SELECT FirstName from Person WHERE ID = new_SSN) OR    # Customer exists with the needed SSN; change the customer's ID:
           new_LastName != (SELECT LastName from Person WHERE ID = new_SSN)) THEN 
	    SET current_person_index = (SELECT AUTO_INC FROM PersonData WHERE ID='1'); # Get first free Person ID
        UPDATE Person SET ID=current_person_index WHERE ID=new_SSN; # Change the customer's CustomerID to the free Person ID
        INSERT INTO Person (ID, LastName, FirstName, Address, City, State, Zip, Phone)
        VALUES (new_SSN, new_LastName, new_FirstName, new_Address, new_City, UPPER(new_State), new_Zip, new_Phone);
    END IF;
    COMMIT;
    START TRANSACTION;
    INSERT INTO Employee (SSN, Position, StartDate, HourlyRate) VALUES (new_SSN, new_Position, new_StartDate, new_Wage);
    COMMIT;
END;
$$
DELIMITER ;

# Add a Manager:
DELIMITER $$
CREATE PROCEDURE AddManager (IN    new_SSN INT UNSIGNED, new_FirstName VARCHAR(64), new_LastName VARCHAR(64), new_Address VARCHAR(64),
                                    new_City VARCHAR(64), new_State CHAR(2), new_Zip INT(5) UNSIGNED, new_Phone BIGINT(10) UNSIGNED,
                                    new_StartDate DATE, new_Wage FLOAT)
BEGIN
    DECLARE current_person_index INT; # Needed if a customer exists with the new Employee's SSN
    SET new_SSN = IF(new_SSN=0, (SELECT AUTO_INC FROM PersonData LIMIT 1), new_SSN);
	START TRANSACTION;
    IF NOT EXISTS (SELECT * FROM Person WHERE ID = new_SSN) THEN
        INSERT INTO Person (ID, LastName, FirstName, Address, City, State, Zip, Phone)
        VALUES (new_SSN, new_LastName, new_FirstName, new_Address, new_City, UPPER(new_State), new_Zip, new_Phone);
    ELSEIF NOT EXISTS(SELECT * FROM Employee WHERE SSN=new_SSN) AND (
           new_FirstName != (SELECT FirstName from Person WHERE ID = new_SSN) OR    # Customer exists with the needed SSN; change the customer's ID:
           new_LastName != (SELECT LastName from Person WHERE ID = new_SSN)) THEN 
	    SET current_person_index = (SELECT AUTO_INC FROM PersonData WHERE ID='1'); # Get first free Person ID
        UPDATE Person SET ID=current_person_index WHERE ID=new_SSN; # Change the customer's CustomerID to the free Person ID
        INSERT INTO Person (ID, LastName, FirstName, Address, City, State, Zip, Phone)
        VALUES (new_SSN, new_LastName, new_FirstName, new_Address, new_City, UPPER(new_State), new_Zip, new_Phone);
    END IF;
    COMMIT;
    START TRANSACTION;
    INSERT INTO Employee (SSN, Position, StartDate, HourlyRate) VALUES (new_SSN, 'Manager', new_StartDate, new_Wage);
    COMMIT;
END;
$$
DELIMITER ;

# Add a Customer Rep:
DELIMITER $$
CREATE PROCEDURE AddCustomerRep (IN new_SSN INT UNSIGNED, new_FirstName VARCHAR(64), new_LastName VARCHAR(64), new_Address VARCHAR(64),
                                    new_City VARCHAR(64), new_State CHAR(2), new_Zip INT(5) UNSIGNED, new_Phone BIGINT(10) UNSIGNED,
                                    new_StartDate DATE, new_Wage FLOAT)
BEGIN
    DECLARE current_person_index INT; # Needed if a customer exists with the new Employee's SSN
    SET new_SSN = IF(new_SSN=0, (SELECT AUTO_INC FROM PersonData LIMIT 1), new_SSN);
	START TRANSACTION;
    IF NOT EXISTS (SELECT * FROM Person WHERE ID = new_SSN) THEN
        INSERT INTO Person (ID, LastName, FirstName, Address, City, State, Zip, Phone)
        VALUES (new_SSN, new_LastName, new_FirstName, new_Address, new_City, UPPER(new_State), new_Zip, new_Phone);
    ELSEIF NOT EXISTS(SELECT * FROM Employee WHERE SSN=new_SSN) AND (
           new_FirstName != (SELECT FirstName from Person WHERE ID = new_SSN) OR    # Customer exists with the needed SSN; change the customer's ID:
           new_LastName != (SELECT LastName from Person WHERE ID = new_SSN)) THEN 
	    SET current_person_index = (SELECT AUTO_INC FROM PersonData WHERE ID='1'); # Get first free Person ID
        UPDATE Person SET ID=current_person_index WHERE ID=new_SSN; # Change the customer's CustomerID to the free Person ID
        INSERT INTO Person (ID, LastName, FirstName, Address, City, State, Zip, Phone)
        VALUES (new_SSN, new_LastName, new_FirstName, new_Address, new_City, UPPER(new_State), new_Zip, new_Phone);
    END IF;
    COMMIT;
    START TRANSACTION;
    INSERT INTO Employee (SSN, Position, StartDate, HourlyRate) VALUES (new_SSN, 'Customer Rep', new_StartDate, new_Wage);
    COMMIT;
END;
$$
DELIMITER ;


# Edit Employee data:
DELIMITER $$
CREATE PROCEDURE EditEmployee (IN EmployeeSSN INT UNSIGNED, _Attribute VARCHAR(64), new_Value VARCHAR(256))
BEGIN
    START TRANSACTION;
        IF _Attribute IN ('ID', 'FirstName', 'LastName', 'Address', 'City', 'State', 'Zip', 'Phone') THEN
            SET @editEmployee_str = CONCAT('UPDATE Person SET ', _Attribute, '=', new_Value, ' WHERE ID=', EmployeeSSN);
            PREPARE editEmployee_stmt FROM @editEmployee_str;
            EXECUTE editEmployee_stmt;
            DEALLOCATE PREPARE editEmployee_stmt;
        ELSE
            SET @editEmployee_str = CONCAT('UPDATE Employee SET ', _Attribute, '=', new_Value, ' WHERE SSN=', EmployeeSSN);
            PREPARE editEmployee_stmt FROM @editEmployee_str;
            EXECUTE editEmployee_stmt;
            DEALLOCATE PREPARE editEmployee_stmt;
        END IF;
    COMMIT;
END;
$$
DELIMITER ;

# Delete an Employee:
DELIMITER $$
CREATE PROCEDURE DeleteEmployee (IN EmployeeSSN INT UNSIGNED)
BEGIN
    IF EXISTS(SELECT * FROM Employee WHERE SSN = EmployeeSSN) THEN
        START TRANSACTION;
            DELETE FROM Person
            WHERE ID=EmployeeSSN;
        COMMIT;
    ELSE
        SIGNAL SQLSTATE 'EI928'
            SET MESSAGE_TEXT = 'Invalid Parameter: Employee does not exist.';
    END IF;
END;
$$
DELIMITER ;

# Obtain a sales report (i.e. the overall income from all active subscriptions) for a particular month:
DELIMITER $$
CREATE PROCEDURE ViewSales (IN FromDate DATE, OUT Monthly_Revenue VARCHAR(32))
BEGIN
    # To calculate income for a given month, find all accounts created before the beginning of the FOLLOWING month:
    SET Monthly_Revenue =   CONCAT('$', FORMAT((SELECT SUM(S.Income)
                                                FROM SalesReport S     # SalesReport is a View
                                                WHERE S.AccountCreated < FromDate), 2));
    SET Monthly_Revenue = IFNULL(Monthly_Revenue, '$0.00');
    SELECT Monthly_Revenue;
END;
$$
DELIMITER ;

# Produce a list of movie rentals by movie name/title:
DELIMITER $$
CREATE PROCEDURE RentalsByMovie (IN MovieTitle VARCHAR(64), OUT OrderID INT UNSIGNED, AccountID INT UNSIGNED,
                                EmployeeID INT(9) UNSIGNED ZEROFILL, MovieID INT UNSIGNED, Title VARCHAR(64))
BEGIN
    SELECT *
    FROM RentalsByMovie     # View
    WHERE Title = MovieTitle;
END;
$$
DELIMITER ;

# Produce a list of movie rentals by movie type (genre):
DELIMITER $$
CREATE PROCEDURE RentalsByGenre (IN MovieGenre VARCHAR(64), OUT OrderID INT UNSIGNED, AccountID INT UNSIGNED,
                                EmployeeID INT(9) UNSIGNED ZEROFILL, MovieID INT UNSIGNED, Genre ENUM ('Comedy', 'Drama', 'Action', 'Foreign'))
BEGIN
    SELECT *
    FROM RentalsByGenre     # View
    WHERE Genre = MovieGenre;
END;
$$
DELIMITER ;

# Produce a list of movie rentals by Customer name:
DELIMITER $$
CREATE PROCEDURE RentalsByCustomer (IN CustName VARCHAR(64), OUT OrderID INT UNSIGNED, AccountID INT UNSIGNED,
                                EmployeeID INT(9) UNSIGNED ZEROFILL, MovieID INT UNSIGNED, CustomerName VARCHAR(129))
BEGIN
    SELECT *
    FROM RentalsByCustomer     # View
    WHERE CustomerName = CustName;
END;
$$
DELIMITER ;

# Determine which customer representative oversaw the most transactions (rentals):
DELIMITER $$
CREATE PROCEDURE MostTransactions(OUT Transactions INT UNSIGNED, Employee INT(9) UNSIGNED ZEROFILL, Name VARCHAR(129))
BEGIN
    SELECT *
    FROM RepRentalCount # View
    LIMIT 1;
END;
$$
DELIMITER ;

# Produce a list of most active customers:
DELIMITER $$
CREATE PROCEDURE ActiveCustomers(OUT AccountID INT UNSIGNED, CustomerID INT(9) UNSIGNED ZEROFILL, Rating INT UNSIGNED, JoinDate DATE)
BEGIN
    SELECT *
    FROM MostActiveCustomers; # View
END;
$$
DELIMITER ;

# Produce a list of most actively rented movies:
DELIMITER $$
CREATE PROCEDURE PopularMovies(OUT RentalCount INT UNSIGNED, MovieID INT UNSIGNED, Title VARCHAR(64))
BEGIN
    SELECT *
    FROM PopularMovies; # View
END;
$$
DELIMITER ;







##############################################
####### Customer Rep-Level Procedures ########
##############################################

# Add a customer:
DELIMITER $$
CREATE PROCEDURE AddCustomer (IN new_FirstName VARCHAR(64), new_LastName VARCHAR(64), new_Address VARCHAR(64),
                                    new_City VARCHAR(64), new_State CHAR(2), new_Zip INT(5) UNSIGNED, new_Phone BIGINT(10) UNSIGNED,
                                    new_Email VARCHAR(64), new_CreditCard BIGINT(16) UNSIGNED ZEROFILL)
BEGIN
	START TRANSACTION;
        INSERT INTO Person (FirstName, LastName, Address, City, State, Zip, Phone)
        VALUES (new_FirstName, new_LastName, new_Address, new_City, new_State, new_Zip, new_Phone);

        INSERT INTO Customer (Email, CreditCard, ID)
        VALUES (new_Email, new_CreditCard, (SELECT ID
                                            FROM Person P
                                            WHERE P.LastName = new_LastName
                                            AND P.FirstName = new_FirstName
                                            AND P.Address = new_Address
                                            AND P.City = new_City
                                            AND P.State = new_State
                                            AND P.Zip = new_Zip));
    COMMIT;
END;
$$
DELIMITER ;

# Edit Customer info:
DELIMITER $$
CREATE PROCEDURE EditCustomer (IN CustomerID INT UNSIGNED, _Attribute VARCHAR(64), new_Value VARCHAR(256))
BEGIN
    START TRANSACTION;
        IF _Attribute IN ('ID', 'FirstName', 'LastName', 'Address', 'City', 'State', 'Zip', 'Phone') THEN
            SET @editCustomer_str = CONCAT('UPDATE Person SET ', _Attribute, '=', new_Value, ' WHERE ID=', CustomerID);
            PREPARE editCustomer_stmt FROM @editCustomer_str;
            EXECUTE editCustomer_stmt;
            DEALLOCATE PREPARE editCustomer_stmt;
        ELSE
            SET @editCustomer_str = CONCAT('UPDATE Customer SET ', _Attribute, '=', new_Value, ' WHERE ID=', CustomerID);
            PREPARE editCustomer_stmt FROM @editCustomer_str;
            EXECUTE editCustomer_stmt;
            DEALLOCATE PREPARE editCustomer_stmt;
        END IF;
    COMMIT;
END;
$$
DELIMITER ;

# Delete a Customer:
DELIMITER $$
CREATE PROCEDURE DeleteCustomer (IN CustomerID INT UNSIGNED)
BEGIN
    IF EXISTS(SELECT * FROM Customer WHERE ID = CustomerID) THEN
        START TRANSACTION;
            DELETE FROM Person
            WHERE ID=CustomerID;
        COMMIT;
    ELSE
        SIGNAL SQLSTATE 'EI928'
            SET MESSAGE_TEXT = 'Invalid Parameter: Customer does not exist.';
    END IF;
END;
$$
DELIMITER ;


# Record an Order:
DELIMITER $$
CREATE PROCEDURE CreateOrder(IN new_OrderDate DATETIME, new_AccountID INT UNSIGNED, new_MovieID INT UNSIGNED, new_EmployeeID INT(9) UNSIGNED ZEROFILL)
BEGIN
    START TRANSACTION;
        INSERT INTO _Order (OrderDate)
        VALUES (new_OrderDate); # If new_OrderDate is NULL, the current date/time is generated for this record

        INSERT INTO Rental (AccountID, MovieID, EmployeeID, OrderID)
        VALUES (new_AccountID, new_MovieID, new_EmployeeID, (SELECT LAST_INSERT_ID()));
    COMMIT;
END;
$$
DELIMITER ;

# Edit an Order:
DELIMITER $$
CREATE PROCEDURE EditOrder (IN _OrderID INT UNSIGNED, _Attribute VARCHAR(64), new_Value VARCHAR(256))
BEGIN
    START TRANSACTION;
        IF _Attribute IN ('ID', 'OrderDate', 'ReturnDate') THEN
            SET @editOrder_str = CONCAT('UPDATE _Order SET ', _Attribute, '=', new_Value, ' WHERE ID=', _OrderID);
            PREPARE editOrder_stmt FROM @editOrder_str;
            EXECUTE editOrder_stmt;
            DEALLOCATE PREPARE editOrder_stmt;
        ELSE
            SET @editOrder_str = CONCAT('UPDATE Rental SET ', _Attribute, '=', new_Value, ' WHERE OrderID=', _OrderID, ' LIMIT 1');
            PREPARE editOrder_stmt FROM @editCustomer_str;
            EXECUTE editOrder_stmt;
            DEALLOCATE PREPARE editOrder_stmt;
        END IF;
    COMMIT;
END;
$$
DELIMITER ;

# Delete an Order:
DELIMITER $$
CREATE PROCEDURE DeleteOrder (IN _OrderID INT UNSIGNED)
BEGIN
    IF EXISTS(SELECT * FROM Rental WHERE OrderID = _OrderID) THEN
        START TRANSACTION;
            DELETE FROM Rental
            WHERE OrderID=_OrderID;
        COMMIT;
    END IF;
    START TRANSACTION;
        DELETE FROM _Order
        WHERE ID=_OrderID;
    COMMIT;
END;
$$
DELIMITER ;


# Create a customer account:
DELIMITER $$
CREATE PROCEDURE CreateAccount(IN new_CustomerID INT(9) UNSIGNED ZEROFILL, new_Subscription ENUM('Limited', 'Unlimited', 'Unlimited+', 'Unlimited++'), new_Created DATE)
BEGIN
    START TRANSACTION;
        INSERT INTO Account(CustomerID, Subscription, Created)
        VALUES (new_CustomerID, new_Subscription, new_Created); # If new_Created is NULL, the current date/time is generated for this record
    COMMIT;
END;
$$
DELIMITER ;

# Edit a customer Account:
DELIMITER $$
CREATE PROCEDURE EditAccount (IN AccountID INT UNSIGNED, _Attribute VARCHAR(64), new_Value VARCHAR(256))
BEGIN
    START TRANSACTION;
        SET @editAccount_str = CONCAT('UPDATE Account SET ', _Attribute, '=', new_Value, ' WHERE ID=', AccountID);
        PREPARE editAccount_stmt FROM @editAccount_str;
        EXECUTE editAccount_stmt;
        DEALLOCATE PREPARE editAccount_stmt;
    COMMIT;
END;
$$
DELIMITER ;

# Delete a customer Account:
DELIMITER $$
CREATE PROCEDURE DeleteAccount (IN AccountID INT UNSIGNED)
BEGIN
    START TRANSACTION;
        DELETE FROM Account
        WHERE ID=AccountID;
    COMMIT;
END;
$$
DELIMITER ;




##############################################
####### Customer-Level Procedures ########
##############################################

# Find all movies with the given keyword in the title:
DELIMITER $$
CREATE PROCEDURE SearchMovieByTitle(IN Keyword VARCHAR(64))
BEGIN
	SELECT ID, Title, Genre, Rating
	FROM Movie M
	WHERE M.Title LIKE CONCAT('%', Keyword, '%');

END;
$$
DELIMITER ;

# Find all movies whose genre contains the string MType
DELIMITER $$
CREATE PROCEDURE SearchMovieByType(IN MType VARCHAR(9))
BEGIN
    SELECT *
    FROM Movie M
    WHERE M.Genre LIKE CONCAT('%', MType, '%');
END;
$$
DELIMITER ;

# Find all movies whose genre contains the string MType
DELIMITER $$
CREATE PROCEDURE SearchMovieByGenre(IN MType VARCHAR(9))
BEGIN
    SELECT *
    FROM Movie M
    WHERE M.Genre LIKE CONCAT('%', MType, '%');
END;
$$
DELIMITER ;

# Find all movies with actors match the given name keyword
DELIMITER $$
CREATE PROCEDURE SearchMovieByActor(IN Name VARCHAR(64))
BEGIN
    SELECT M.ID AS MovieID, M.Title, M.Genre, M.Rating AS MovieRating, A.ID AS ActorID, A.FirstName, A.LastName, A.Rating AS ActorRating
    FROM Movie M JOIN (Actor A JOIN Casted C ON A.ID = C.ActorID) ON M.ID = C.MovieID
    WHERE A.FirstName LIKE CONCAT('%', Name, '%') OR A.LastName LIKE CONCAT('%', Name, '%');
END;
$$
DELIMITER ;



######################################
####### Root-Level Procedures ########
######################################
# These procedures will be used to build and debug the database during development

# Get the current AUTO_INCREMENT value for a given table:
DELIMITER $$
CREATE PROCEDURE GetAutoInc (IN _Table VARCHAR(64), OUT AUTO_INC_VAL BIGINT UNSIGNED)
BEGIN
	SET AUTO_INC_VAL = (SELECT AUTO_INCREMENT
                            FROM  INFORMATION_SCHEMA.TABLES
                            WHERE TABLE_SCHEMA = DATABASE()
                            AND   TABLE_NAME   = _Table);
    SELECT AUTO_INC_VAL;
END;
$$
DELIMITER ;

# Reset the current AUTO_INCREMENT value for a given table:
DELIMITER $$
CREATE PROCEDURE ResetAutoInc (IN _Table VARCHAR(64))
BEGIN
    SET @resetautoinc_str = CONCAT('ALTER TABLE ', _Table, ' AUTO_INCREMENT=1');
    PREPARE resetautoinc_stmt FROM @resetautoinc_str;
    EXECUTE resetautoinc_stmt;
    DEALLOCATE PREPARE resetautoinc_stmt;
END;
$$
DELIMITER ;

# Set the current AUTO_INCREMENT value for a given table:
DELIMITER $$
CREATE PROCEDURE SetAutoInc (IN _Table VARCHAR(64), new_AUTO_INC BIGINT UNSIGNED)
BEGIN
    SET @setautoinc_str = CONCAT('ALTER TABLE ', _Table, ' AUTO_INCREMENT=', new_AUTO_INC);
    PREPARE setautoinc_stmt FROM @setautoinc_str;
    EXECUTE setautoinc_stmt;
    DEALLOCATE PREPARE setautoinc_stmt;
END;
$$
DELIMITER ;
