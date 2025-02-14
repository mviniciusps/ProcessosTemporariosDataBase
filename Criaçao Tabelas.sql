/*------------------------------------------------------------
Autor   : Marcus Paiva
Banco	: ProcessosTemporarios
Objetivo: Transferir dados da planilha
Data	: 01/02/2025
------------------------------------------------------------*/

CREATE DATABASE ProcessosTemporarios
-- arquivo onde contem os metadados e objetos principais (tabelas, indices, etc)
ON
(
	NAME = ProcessosTemporarios_dados,
	FILENAME = 'C:\Dados\ProcessosTemporarios.mdf',
	SIZE = 100MB,
	MAXSIZE = UNLIMITED,
	FILEGROWTH = 10MB
)
-- arquivo de log de transações (recupera caso haja falha)
LOG ON
(
	NAME = ProcessosTemporarios_log,
	FILENAME = 'C:\Log\ProcessosTemporarios.ldf',
	SIZE = 50MB,
	MAXSIZE = 1GB,
	FILEGROWTH = 5MB
)

--Consultar todos os Sequences
SELECT * FROM sys.sequences

--Deletar Sequences
DROP SEQUENCE seqID_CE_ID;


--Ver quantas transações estão abertas
SELECT @@TRANCOUNT


USE ProcessosTemporarios

--Sequenciador para o ID da Tabela TB_CE_MERCANTE
CREATE SEQUENCE seqID_CE_ID
	AS INT
	START WITH 0
	INCREMENT BY 1
GO

EXECUTE sp_rename 'TB_CE_MERCANTE', 'tCeMercante'
--Criar tabela TB_CE_MERCANTE
BEGIN TRANSACTION

	CREATE TABLE tCeMercante
	(
		CE_ID INT NOT NULL DEFAULT (NEXT VALUE FOR seqID_CE_ID), --PK
		Status_CE VARCHAR(15) NOT NULL,
		Numero_CE CHAR(15), --UNIQUE
		CONSTRAINT PK_CE_ID PRIMARY KEY(CE_ID),
		CONSTRAINT UQ_NUMERO_CE UNIQUE(Numero_CE)
	)

	SELECT * FROM  tCeMercante--Testar tabela TB_CE_MERCANTE criada

	COMMIT
	--ROLLBACK
GO
--Fim da criaçao TB_CE_MERCANTE


--Sequenciador para o ID da Tabela TB_RECINTO_ALFANDEGADO
CREATE SEQUENCE seqRecintoID
	AS INT
	START WITH 0
	INCREMENT BY 1
GO

DROP SEQUENCE seqRecintoID;

EXECUTE sp_rename 'TB_RECINTO_ALFANDEGADO', 'tRecintoAlfandegado'

--Criar tabela TB_RECINTO_ALFANDEGADO
BEGIN TRANSACTION

	CREATE TABLE tRecintoAlfandegado
	(
		RecintoID INT NOT NULL DEFAULT(NEXT VALUE FOR seqRecintoID), --PK
		NumeroRecintoAduaneiro CHAR(7) NOT NULL, --UNIQUE
		NomeRecinto VARCHAR(100) NOT NULL,
		CidadeRecinto VARCHAR(100) NOT NULL,
		EstadoRecinto VARCHAR(100) NOT NULL,
		UnidadeReceitaFederal CHAR(7) NOT NULL,
		CONSTRAINT PK_RECINTO_ID PRIMARY KEY(RecintoID),
		CONSTRAINT UQ_NUMERO_RECINTO UNIQUE(NumeroRecintoAduaneiro)
	)

	SELECT * FROM tRecintoAlfandegado
	
	COMMIT
	--ROLLBACK
GO

DROP TABLE tRecintoAlfandegado
--Fim da criaçao TB_RECINTO_ALFANDEGADO




--Sequenciador para o ID da Tabela TB_APOLICE_SEGURO_GARANTIA
CREATE SEQUENCE seqApoliceID
	AS INT
	START WITH 0
	INCREMENT BY 1
GO

EXECUTE sp_rename 'TB_APOLICE_SEGURO_GARANTIA', 'tApoliceSeguroGarantia'

-- Criar tabela TB_APOLICE_SEGURO_GARANTIA (dinamico)
BEGIN TRANSACTION

SET NOCOUNT ON
	BEGIN TRY

		DECLARE @NomeTabelaApolice NVARCHAR(128)
		SET @NomeTabelaApolice = 'TB_APOLICE_SEGURO_GARANTIA'


		DECLARE @SQLCriarTabelaApolice NVARCHAR(MAX)
		SET @SQLCriarTabelaApolice = 'CREATE TABLE ' + @NomeTabelaApolice + '(
			ApoliceID INT NOT NULL DEFAULT(NEXT VALUE FOR seqApoliceID), --PK
			NumeroApolice VARCHAR(100),
			VencimentoGarantia DATE NOT NULL,
			RecintoID INT NOT NULL, --FK
			CONSTRAINT PK_APOLICE_ID PRIMARY KEY(ApoliceID),
			CONSTRAINT FK_RECINTO_ID FOREIGN KEY(RecintoID) REFERENCES TB_RECINTO_ALFANDEGADO(RecintoID)
		)'

		EXEC sp_executesql @SQLCriarTabelaApolice

		DECLARE @mensagemCriacao NVARCHAR(255)
		SET @mensagemCriacao = 'Tabela ' + @NomeTabelaApolice + ' criada com sucesso'

		RAISERROR( @mensagemCriacao, 10, 1) WITH NOWAIT;

		COMMIT

	END TRY
	BEGIN CATCH
		
		ROLLBACK

	END CATCH

	SELECT *  FROM TB_APOLICE_SEGURO_GARANTIA
GO
--Fim da criaçao TB_APOLICE_SEGURO_GARANTIA




--Sequenciador para o ID da Tabela TB_CONTRATO
CREATE SEQUENCE seqContratoID
	AS INT
	START WITH 0
	INCREMENT BY 1
GO

EXECUTE sp_rename 'TB_CONTRATO', 'tContrato'


-- Criar tabela TB_CONTRATO (dinamico)
BEGIN TRANSACTION

	SET NOCOUNT ON
	DECLARE @nRetorno INT = 0

	BEGIN TRY

		IF @@TRANCOUNT > 1
		BEGIN
			RAISERROR('Há transações abertas, fechando transações, execute o codigo novamente...',10,1);
			ROLLBACK;
			RETURN;
		END;

		DECLARE @NomeTabela NVARCHAR(128);
		SET @NomeTabela = 'TB_CONTRATO';

		RAISERROR('Tabela %s sendo criada...', 10, 1, @NomeTabela) WITH NOWAIT;

		WAITFOR DELAY '00:00:05';

		DECLARE @SQLCriarTabela NVARCHAR(MAX);
		SET @SQLCriarTabela = 'CREATE TABLE ' + @NomeTabela + '(
			ContratoID INT NOT NULL DEFAULT(NEXT VALUE FOR seqContratoID), --PK
			NumeroNomeContrato VARCHAR(100) NOT NULL,
			ContratoTipo VARCHAR(20) NOT NULL,
			ContratoDataAssinatura DATE NOT NULL,
			ContratoVencimento DATE NOT NULL, --Procedure UPDATE em dias
			NumeroProrrogacao INT,
			CONSTRAINT PK_CONTRATO_ID PRIMARY KEY(ContratoID)
		)'
				        
		EXEC sp_executesql @SQLCriarTabela;

		WAITFOR DELAY '00:00:05';
		
		RAISERROR( 'Tabela %s criada com sucesso', 10, 1, @NomeTabela) WITH NOWAIT;

		COMMIT;

	END TRY
	BEGIN CATCH
		
		IF @@TRANCOUNT > 0
		ROLLBACK

		EXECUTE @nRetorno = stp_ManipulaErro

	END CATCH
GO



--Sequenciador para o ID Tabela TB_CNPJ
CREATE SEQUENCE seqCNPJID
	AS INT
	START WITH 0
	INCREMENT BY 1
GO

--Criar Tabela tCNPJ (dinamico)
BEGIN TRANSACTION

	SET NOCOUNT ON
	

	BEGIN TRY

		IF @@TRANCOUNT > 1
		BEGIN
			RAISERROR('Há transações abertas, fechando transações, execute o codigo novamente...',10,1);
			ROLLBACK;
			RETURN;
		END;
				
		DECLARE @nRetorno INT = 0
		DECLARE @NomeTabela NVARCHAR(128)
		SET @NomeTabela = 'tCNPJ';

		RAISERROR('Tabela %s sendo criada...', 10, 1, @NomeTabela) WITH NOWAIT;

		WAITFOR DELAY '00:00:05';

		DECLARE @SQLCriarTabela NVARCHAR(MAX);
		SET @SQLCriarTabela = 'CREATE TABLE ' + @NomeTabela + '(
			CNPJ_ID INT IDENTITY(1,1), --PK
			NumeroInscricao CHAR(14) NOT NULL, --UNIQUE
			NomeEmpresarial VARCHAR(100) NOT NULL,
			Logradouro VARCHAR(100) NOT NULL,
			NumeroLogradouro VARCHAR(10) NULL,
			BairroLogradouro VARCHAR(50) NULL,
			CidadeLogradouro VARCHAR(50) NOT NULL,
			EstadoLogradouro VARCHAR(50) NOT NULL,
			CONSTRAINT PK_CNPJ_ID PRIMARY KEY(CNPJ_ID),
			CONSTRAINT UQ_CNPJ_INSCRICAO UNIQUE(NumeroInscricao)
		)'
				        
		EXECUTE sp_executesql @SQLCriarTabela;

		WAITFOR DELAY '00:00:05';
		
		RAISERROR( 'Tabela %s criada com sucesso', 10, 1, @NomeTabela) WITH NOWAIT;

		COMMIT;

	END TRY
	BEGIN CATCH
		
		IF @@TRANCOUNT > 0
		ROLLBACK

		EXECUTE stp_ManipulaErro

	END CATCH
GO


--Sequenciador Tabela tDeclaracao
CREATE SEQUENCE seqDeclaracaoID
	AS INT
	START WITH 0
	INCREMENT BY 1
GO

--Criar tabela tDeclaracao
CREATE TABLE tDeclaracao
(
	DeclaracaoID INT IDENTITY(1,1),
	NumeroDeclaracao VARCHAR(12) NOT NULL, -- CHECK/IF/UNIQUE
	CNPJ_ID INT NOT NULL, --FK
	ReferenciaBraslog CHAR(13) NOT NULL, --UNIQUE
	ReferenciaCliente VARCHAR(20) NOT NULL,
	DataRegistroDeclaracao DATE NOT NULL,
	DataDesembaracoDeclaracao DATE NOT NULL,
	CE_ID INT, --FK
	RecintoID INT NOT NULL, --FK
	NumeroDOSSIE CHAR(15), --UNIQUE
	NumeroProcessoAdministrativo CHAR(15),
	ContratoID INT, --FK
	ApoliceID INT, --FK
	Modal VARCHAR(15) NOT NULL,
	CONSTRAINT PK_DECLARACAO_ID PRIMARY KEY(DeclaracaoID),
	CONSTRAINT CHK_NUMERODECLARACAO_LENGTH CHECK(LEN(NumeroDeclaracao) BETWEEN 10 AND 12),
	CONSTRAINT FK_DECLARACAO_CNPJ_ID FOREIGN KEY(CNPJ_ID) REFERENCES tCNPJ(CNPJ_ID),
	CONSTRAINT FK_DECLARACAO_CE_ID FOREIGN KEY(CE_ID) REFERENCES tCeMercante(CE_ID),
	CONSTRAINT FK_DECLARACAO_RECINTO_ID FOREIGN KEY(RecintoID) REFERENCES tRecintoAlfandegado(RecintoID),
	CONSTRAINT FK_CONTRATO_ID FOREIGN KEY(ContratoID) REFERENCES tContrato(ContratoID),
	CONSTRAINT FK_APOLICE_ID FOREIGN KEY(ApoliceID) REFERENCES tApoliceSeguroGarantia(ApoliceID)
)

--Criar Tabela para armazenar os erros
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
