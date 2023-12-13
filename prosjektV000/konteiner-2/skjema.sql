CREATE TABLE Bruker (epost VARCHAR(128) PRIMARY KEY NOT NULL UNIQUE, passordhash VARCHAR(4096) NOT NULL, fornavn VARCHAR(64) NOT NULL, etternavn VARCHAR(64) NOT NULL);

CREATE TABLE Sesjon (sesjonsID VARCHAR(128) PRIMARY KEY NOT NULL UNIQUE, epost VARCHAR(128) NOT NULL, FOREIGN KEY(epost) REFERENCES Bruker(epost));

CREATE TABLE Dikt (diktID INTEGER PRIMARY KEY AUTOINCREMENT NOT NULL UNIQUE, dikt VARCHAR(4096) NOT NULL, epost VARCHAR(128) NOT NULL, FOREIGN KEY(epost) REFERENCES Bruker(epost));

INSERT INTO Bruker VALUES ('admin@usn.no', '$2a$12$08m2V1ya0LmEwBN69EaRwuDVTQ0fXX3mZbYLEhc8IPzOpVmhPko0O', 'Admin', 'Student');
INSERT INTO Bruker VALUES ('testbruker', 'e946fe28efd4208c0ba70e632669f5dad5d6fe61ccb09487048ce7cbffc8c0d29e1f654044198652171d78e9b3972a40482867d3a48f3425aff02aad64ea58ba', 'testus', 'brukerus');

INSERT INTO Sesjon VALUES ('a00033b01-1cde-44b5-4dfe908b6e42', 'admin@usn.no');

INSERT INTO Dikt (dikt, epost) VALUES ('This is a test', 'admin@usn.no');

