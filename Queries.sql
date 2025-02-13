SELECT * FROM tRecintoAlfandegado

ALTER TABLE tRecintoAlfandegado
ALTER COLUMN cEstadoRecinto VARCHAR(100);
GO

ALTER TABLE tRecintoAlfandegado
ALTER COLUMN cNomeRecinto VARCHAR(255);
GO

UPDATE tRecintoAlfandegado
SET cNomeRecinto = 'Inst.Por.Fluv.ALF-uso privativo-Chibatao NAV. COM'
WHERE iRecintoID = 2

USE ProcessosTemporarios;
GO

SELECT * FROM tRecintoAlfandegado

SELECT COLUMN_NAME, DATA_TYPE, CHARACTER_MAXIMUM_LENGTH 
FROM INFORMATION_SCHEMA.COLUMNS 
WHERE TABLE_NAME = 'tRecintoAlfandegado' AND COLUMN_NAME = 'cNomeRecinto';

SELECT name 
FROM sys.triggers 
WHERE parent_id = OBJECT_ID('tRecintoAlfandegado');

DELETE FROM tRecintoAlfandegado;

ALTER SEQUENCE seqRecintoID RESTART WITH 1;