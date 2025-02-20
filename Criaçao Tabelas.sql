/*------------------------------------------------------------
Author   : Marcus Paiva
DataBase : ProcessosTemporarios
Objective: Transfer datas from spreadsheet
Date	 : 01/02/2025
------------------------------------------------------------*/
CREATE DATABASE ProcessosTemporarios
-- Metadata file that contains main objects (tables, indexes, etc)
ON
(
	NAME = ProcessosTemporarios_dados,
	FILENAME = 'C:\Dados\ProcessosTemporarios.mdf',
	SIZE = 100MB,
	MAXSIZE = UNLIMITED,
	FILEGROWTH = 10MB
)
-- transaction log file (recovery if it makes mistake)
LOG ON
(
	NAME = ProcessosTemporarios_log,
	FILENAME = 'C:\Log\ProcessosTemporarios.ldf',
	SIZE = 50MB,
	MAXSIZE = 1GB,
	FILEGROWTH = 5MB
);
GO

USE ProcessosTemporarios; -- select database
GO
-------------------------------------------------------------------------- END DATABASE
/*
*/
-------------------------------------------------------------------------- BEGIN tCeMercante
--START CREATING tCeMercante TABLE

--sequence as id for table
CREATE SEQUENCE seqID_CE_ID
	AS INT
	START WITH 0
	INCREMENT BY 1;
GO

--creating tCeMercante using standard way
BEGIN TRANSACTION

	CREATE TABLE tCeMercante
	(
		iCEID INT NOT NULL DEFAULT (NEXT VALUE FOR seqID_CE_ID), --primary key
		cStatusCE VARCHAR(15) NOT NULL,
		cNumeroCE CHAR(15), --accept unique values
		CONSTRAINT PK_CE_ID PRIMARY KEY(iCEID),
		CONSTRAINT UQ_NUMERO_CE UNIQUE(cNumeroCE)
	);

	SELECT * FROM  tCeMercante;--select table just be created

	--COMMIT
	--ROLLBACK
GO
-------------------------------------------------------------------------- END tCeMercante
/*
*/
-------------------------------------------------------------------------- BEGIN tRecintoAlfandegado
--START CREATING tRecintoAlfandegado TABLE

--sequence as id for table
CREATE SEQUENCE seqRecintoID
	AS INT
	START WITH 0
	INCREMENT BY 1;
GO

--creating tRecintoAlfandegado using standard way
BEGIN TRANSACTION

	CREATE TABLE tRecintoAlfandegado
	(
		iRecintoID INT NOT NULL DEFAULT(NEXT VALUE FOR seqRecintoID), --primary key
		cNumeroRecintoAduaneiro CHAR(7) NOT NULL, --unique values
		cNomeRecinto VARCHAR(255),
		cCidadeRecinto VARCHAR(100),
		cEstadoRecinto VARCHAR(100),
		cUnidadeReceitaFederal CHAR(7) NOT NULL,
		CONSTRAINT PK_RECINTO_ID PRIMARY KEY(iRecintoID),
		CONSTRAINT UQ_NUMERO_RECINTO UNIQUE(cNumeroRecintoAduaneiro)
	);

	SELECT * FROM tRecintoAlfandegado--select table just be created
	
	--COMMIT
	--ROLLBACK
GO
-------------------------------------------------------------------------- END tRecintoAlfandegado
/*
*/
-------------------------------------------------------------------------- BEGIN tApoliceSeguroGarantia
--START CREATING tApoliceSeguroGarantia TABLE

--sequence as id for table
CREATE SEQUENCE seqApoliceID
	AS INT
	START WITH 0
	INCREMENT BY 1;
GO

--creating tApoliceSeguroGarantia using dinamic way with variables
BEGIN TRANSACTION

SET NOCOUNT ON;

	BEGIN TRY

		DECLARE @NomeTabelaApolice NVARCHAR(128);
		SET @NomeTabelaApolice = 'tApoliceSeguroGarantia';


		DECLARE @SQLCriarTabelaApolice NVARCHAR(MAX);
		SET @SQLCriarTabelaApolice = 'CREATE TABLE ' + @NomeTabelaApolice + '(
			iApoliceID INT NOT NULL DEFAULT(NEXT VALUE FOR seqApoliceID), --primary key
			cNumeroApolice VARCHAR(100),
			cVencimentoGarantia DATE NOT NULL,
			iRecintoID INT NOT NULL, --foreign key
			CONSTRAINT PK_APOLICE_ID PRIMARY KEY(iApoliceID),
			CONSTRAINT FK_RECINTO_ID FOREIGN KEY(iRecintoID) REFERENCES tRecintoAlfandegado(iRecintoID)
		)';

		EXEC sp_executesql @SQLCriarTabelaApolice;

		DECLARE @mensagemCriacao NVARCHAR(255);
		SET @mensagemCriacao = 'Table' + @NomeTabelaApolice + ' created!';

		RAISERROR( @mensagemCriacao, 10, 1) WITH NOWAIT;

		COMMIT;

	END TRY
	BEGIN CATCH
		
		ROLLBACK;

	END CATCH

	SELECT *  FROM tApoliceSeguroGarantia;
GO
-------------------------------------------------------------------------- END tApoliceSeguroGarantia
/*
*/
-------------------------------------------------------------------------- BEGIN tContrato
--START CREATING tContrato TABLE

--sequence as id for table
CREATE SEQUENCE seqContratoID
	AS INT
	START WITH 0
	INCREMENT BY 1;
GO

--creating tContrato using dinamic way with variables
BEGIN TRANSACTION

	SET NOCOUNT ON;

	DECLARE @nRetorno INT = 0;

	BEGIN TRY

		IF @@TRANCOUNT > 1
		BEGIN
			RAISERROR('There are open transactions, closing all...',10,1);
			ROLLBACK;
			RETURN;
		END;

		DECLARE @NomeTabela NVARCHAR(128);
		SET @NomeTabela = 'tContrato';

		RAISERROR('Table %s is being created...', 10, 1, @NomeTabela) WITH NOWAIT;

		WAITFOR DELAY '00:00:05';

		DECLARE @SQLCriarTabela NVARCHAR(MAX);
		SET @SQLCriarTabela = 'CREATE TABLE ' + @NomeTabela + '(
			iContratoID INT NOT NULL DEFAULT(NEXT VALUE FOR seqContratoID), --primary key
			cNumeroNomeContrato VARCHAR(100) NOT NULL,
			cContratoTipo VARCHAR(20) NOT NULL,
			dContratoDataAssinatura DATE,
			dContratoVencimento DATE NOT NULL, --Procedure update using days
			iNumeroProrrogacao INT,
			CONSTRAINT PK_CONTRATO_ID PRIMARY KEY(ContratoID)
		)';
				        
		EXEC sp_executesql @SQLCriarTabela;

		WAITFOR DELAY '00:00:05';
		
		RAISERROR( 'Table %s created', 10, 1, @NomeTabela) WITH NOWAIT;

		COMMIT;

	END TRY
	BEGIN CATCH
		
		IF @@TRANCOUNT > 0
			ROLLBACK;

		EXECUTE @nRetorno = stp_ManipulaErro;

	END CATCH
GO
-------------------------------------------------------------------------- END tContrato
/*
*/
-------------------------------------------------------------------------- BEGIN tCNPJ
--START CREATING tContrato TABLE

--sequence as id for table
CREATE SEQUENCE seqCNPJID
	AS INT
	START WITH 0
	INCREMENT BY 1
GO

--creating tContrato using dinamic way with variables
BEGIN TRANSACTION

	SET NOCOUNT ON;	

	BEGIN TRY

		IF @@TRANCOUNT > 1
		BEGIN
			RAISERROR('There are open transactions, closing all...',10,1);
			ROLLBACK;
			RETURN;
		END;
				
		DECLARE @nRetorno INT = 0;
		DECLARE @NomeTabela NVARCHAR(128);
		SET @NomeTabela = 'tCNPJ';

		RAISERROR('table %s is been created...', 10, 1, @NomeTabela) WITH NOWAIT;

		WAITFOR DELAY '00:00:05';

		DECLARE @SQLCriarTabela NVARCHAR(MAX);
		SET @SQLCriarTabela = 'CREATE TABLE ' + @NomeTabela + '(
			iCNPJID INT NOT NULL DEFAULT(NEXT VALUE FOR seqCNPJID), --primary key
			cNumeroInscricao CHAR(14) NOT NULL, --unique values
			cNomeEmpresarial VARCHAR(100) NOT NULL,
			cLogradouro VARCHAR(100) NOT NULL,
			cNumeroLogradouro VARCHAR(10),
			cBairroLogradouro VARCHAR(50),
			cCidadeLogradouro VARCHAR(50) NOT NULL,
			cEstadoLogradouro VARCHAR(50) NOT NULL,
			CONSTRAINT PK_CNPJ_ID PRIMARY KEY(iCNPJID),
			CONSTRAINT UQ_CNPJ_INSCRICAO UNIQUE(cNumeroInscricao)
		)';
				        
		EXECUTE sp_executesql @SQLCriarTabela;

		WAITFOR DELAY '00:00:05';
		
		RAISERROR( 'Tabela %s criada com sucesso', 10, 1, @NomeTabela) WITH NOWAIT;

		COMMIT;

	END TRY
	BEGIN CATCH
		
		IF @@TRANCOUNT > 0
		ROLLBACK;

		EXECUTE stp_ManipulaErro;

	END CATCH
GO
-------------------------------------------------------------------------- END tCNPJ
/*
*/
-------------------------------------------------------------------------- BEGIN tDeclaracao
--START CREATING tContrato TABLE

--sequence as id for table
CREATE SEQUENCE seqDeclaracaoID
	AS INT
	START WITH 0
	INCREMENT BY 1;
GO

--creating tRecintoAlfandegado using standard way
CREATE TABLE tDeclaracao
(
	iDeclaracaoID INT NOT NULL DEFAULT(NEXT VALUE FOR seqDeclaracaoID), --primary key
	cNumeroDeclaracao VARCHAR(12) NOT NULL, -- check using caracteres length and unique values
	iCNPJID INT NOT NULL, --foreign key
	cReferenciaBraslog CHAR(13) NOT NULL, --unique values
	cReferenciaCliente VARCHAR(100),
	dDataRegistroDeclaracao DATE NOT NULL,
	dDataDesembaracoDeclaracao DATE NOT NULL,
	iCEID INT, --foreign key
	iRecintoID INT NOT NULL, --foreign key
	cNumeroDOSSIE CHAR(15),
	cNumeroProcessoAdministrativo CHAR(15), --unique values (not allow cause there so many values null)
	iContratoID INT, --foreign key
	iApoliceID INT, --foreign key
	cModal VARCHAR(15) NOT NULL,
	CONSTRAINT PK_DECLARACAO_ID PRIMARY KEY(iDeclaracaoID),
	CONSTRAINT CHK_NUMERODECLARACAO_LENGTH CHECK(LEN(cNumeroDeclaracao) BETWEEN 10 AND 12),
	CONSTRAINT FK_DECLARACAO_CNPJ_ID FOREIGN KEY(iCNPJID) REFERENCES tCNPJ(iCNPJID),
	CONSTRAINT FK_DECLARACAO_CE_ID FOREIGN KEY(iCEID) REFERENCES tCeMercante(iCEID),
	CONSTRAINT FK_DECLARACAO_RECINTO_ID FOREIGN KEY(iRecintoID) REFERENCES tRecintoAlfandegado(iRecintoID),
	CONSTRAINT FK_CONTRATO_ID FOREIGN KEY(iContratoID) REFERENCES tContrato(iContratoID),
	CONSTRAINT FK_APOLICE_ID FOREIGN KEY(iApoliceID) REFERENCES tApoliceSeguroGarantia(iApoliceID),
	CONSTRAINT UQ_NUMERO_DECLARACAO UNIQUE(cNumeroDeclaracao),
	CONSTRAINT UQ_REF_BRASLOG UNIQUE(cReferenciaBraslog)
);
-------------------------------------------------------------------------- END tDeclaracao
/*
*/
-------------------------------------------------------------------------- BEGIN tLOGEventos
--Table created to store errors
DROP TABLE IF EXISTS tLOGEventos
GO

DROP SEQUENCE IF EXISTS seqIIDEvento
GO

CREATE SEQUENCE seqIIDEvento AS INT START WITH 1 INCREMENT BY 1
GO

CREATE TABLE tLOGEventos
(
	iIDEvento INT NOT NULL DEFAULT(NEXT VALUE FOR seqIIDEvento),
	dDataHora DATETIME NOT NULL DEFAULT GETDATE(),
	cMensagem VARCHAR(MAX) NOT NULL,
	CONSTRAINT PKEvento PRIMARY KEY (iIDEvento),
	CONSTRAINT CHKMensagem CHECK(cMensagem <> '')
)
GO