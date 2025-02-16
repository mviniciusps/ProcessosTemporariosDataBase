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
			iCNPJID INT NOT NULL DEFAULT(NEXT VALUE FOR seqCNPJID), --PK
			cNumeroInscricao CHAR(14) NOT NULL, --UNIQUE
			cNomeEmpresarial VARCHAR(100) NOT NULL,
			cLogradouro VARCHAR(100) NOT NULL,
			cNumeroLogradouro VARCHAR(10) NULL,
			cBairroLogradouro VARCHAR(50) NULL,
			cCidadeLogradouro VARCHAR(50) NOT NULL,
			cEstadoLogradouro VARCHAR(50) NOT NULL,
			CONSTRAINT PK_CNPJ_ID PRIMARY KEY(iCNPJID),
			CONSTRAINT UQ_CNPJ_INSCRICAO UNIQUE(cNumeroInscricao)
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
	iDeclaracaoID INT NOT NULL DEFAULT(NEXT VALUE FOR seqDeclaracaoID),
	cNumeroDeclaracao VARCHAR(12) NOT NULL, -- CHECK/IF/UNIQUE
	iCNPJID INT NOT NULL, --FK
	cReferenciaBraslog CHAR(13) NOT NULL, --UNIQUE
	cReferenciaCliente VARCHAR(20) NOT NULL,
	dDataRegistroDeclaracao DATE NOT NULL,
	dDataDesembaracoDeclaracao DATE NOT NULL,
	iCEID INT, --FK
	iRecintoID INT NOT NULL, --FK
	cNumeroDOSSIE CHAR(15), --UNIQUE
	cNumeroProcessoAdministrativo CHAR(15),
	iContratoID INT, --FK
	iApoliceID INT, --FK
	cModal VARCHAR(15) NOT NULL,
	CONSTRAINT PK_DECLARACAO_ID PRIMARY KEY(iDeclaracaoID),
	CONSTRAINT CHK_NUMERODECLARACAO_LENGTH CHECK(LEN(cNumeroDeclaracao) BETWEEN 10 AND 12),
	CONSTRAINT FK_DECLARACAO_CNPJ_ID FOREIGN KEY(iCNPJID) REFERENCES tCNPJ(iCNPJID),
	CONSTRAINT FK_DECLARACAO_CE_ID FOREIGN KEY(iCEID) REFERENCES tCeMercante(iCEID),
	CONSTRAINT FK_DECLARACAO_RECINTO_ID FOREIGN KEY(iRecintoID) REFERENCES tRecintoAlfandegado(iRecintoID),
	CONSTRAINT FK_CONTRATO_ID FOREIGN KEY(iContratoID) REFERENCES tContrato(iContratoID),
	CONSTRAINT FK_APOLICE_ID FOREIGN KEY(iApoliceID) REFERENCES tApoliceSeguroGarantia(iApoliceID)
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
