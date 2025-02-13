/*--------------------------------------------------------------------------------------------        
Tipo Objeto: Store Procedure
Objeto     : stp_ManipulaErro
Objetivo   : Utilizada na area CATCH para capturas os erros no Event Viewer do Windows
             e para gravar na tabela tLOGEventos.
Projeto    : ProcessosTemporarios          
Empresa Respons�vel: Braslog
Criado em  : 01/02/2025
Execu��o   : A procedure deve se executada na area de CATCH         
Palavras-chave: Erro, tratamento, catch, avisos
----------------------------------------------------------------------------------------------        
Observa��es :        

----------------------------------------------------------------------------------------------        
Hist�rico:        
Autor                  IDBug Data       Descri��o        
---------------------- ----- ---------- ------------------------------------------------------------        
Marcus V. Paiva Silveira               01/02/2025 Cria��o da Procedure */

CREATE OR ALTER PROCEDURE stp_ManipulaErro
AS
BEGIN
	--�rea configura�ao da sess�o
	SET NOCOUNT ON

	--Declara�ao das vari�veis
	DECLARE @nRetorno INT = 0;
    DECLARE @niIDEvento INT = 0,
            @cMensagem VARCHAR(MAX),
            @nErrorNumber INT,
            @nErrorMessage VARCHAR(200),
            @nErrorSeverity TINYINT,
            @nErrorState TINYINT,
            @nErrorProcedure VARCHAR(128),
            @nErrorLine INT;

	BEGIN TRY

		RETURN @nRetorno;
	END TRY
	BEGIN CATCH
		
		SET @nErrorNumber = ERROR_NUMBER();
        SET @nErrorMessage = ERROR_MESSAGE();
        SET @nErrorSeverity = ERROR_SEVERITY();
        SET @nErrorState = ERROR_STATE();
        SET @nErrorProcedure = ERROR_PROCEDURE();
        SET @nErrorLine = ERROR_LINE();

		--c�lculo e processamento sem o tratamento de erro ou transa�ao.
		SET @cMensagem = FORMATMESSAGE('MsgID %d. %s. Severidade %d. Status %d. Procedure %s. Linha %d.', @nErrorNumber, @cMensagem, @nErrorSeverity, @nErrorState, @nErrorProcedure, @nErrorLine)

		SET @niIDEvento = NEXT VALUE FOR seqIIDEvento

		--Grava�ao na tabela
		INSERT INTO tLOGEventos (iIDEvento, cMensagem)
		VALUES
		(@niIDEvento, @cMensagem)

		SET @nRetorno = @niIDEvento

		RETURN @nRetorno
	END CATCH;
END
GO

/*--------------------------------------------------------------------------------------------        
Tipo Objeto: Store Procedure
Objeto     : stp_BackupProcessosTemporarios
Objetivo   : Fazer backup para o diret�rio C:\Backup
Projeto    : ProcessosTemporarios
Empresa Respons�vel: Braslog
Criado em  : 04/02/2025
Execu��o   : A procedure deve se executada diariamente, em um hor�rio espec�fico        
Palavras-chave: Backup
----------------------------------------------------------------------------------------------        
Observa��es :        

----------------------------------------------------------------------------------------------        
Hist�rico:        
Autor                  IDBug Data       Descri��o        
---------------------- ----- ---------- ------------------------------------------------------------        
Marcus V. Paiva Silveira               04/02/2025 Cria��o da Procedure */

CREATE OR ALTER PROCEDURE stp_BackupProcessosTemporarios
AS
BEGIN
	
	DECLARE @cArquivoBackup VARCHAR(100)

	SET @cArquivoBackup = 'C:\Backup\ProcessosTemporarios_' + FORMAT(GETDATE(), 'DDMM') + '.bkp'

	BACKUP DATABASE ProcessosTemporarios
	TO DISK = @cArquivoBackup
	WITH STATS = 1, INIT
END
GO

/*--------------------------------------------------------------------------------------------        
Tipo Objeto: Store Procedure
Objeto     : stp_BackupProcessosTemporarios
Objetivo   : Fazer backup para o diret�rio C:\Backup
Projeto    : ProcessosTemporarios
Empresa Respons�vel: Braslog
Criado em  : 04/02/2025
Execu��o   : A procedure deve se executada diariamente, em um hor�rio espec�fico        
Palavras-chave: Backup
----------------------------------------------------------------------------------------------        
Observa��es :        

----------------------------------------------------------------------------------------------        
Hist�rico:        
Autor                  IDBug Data			Descri��o
Marcus Vinicius	     		 08/02/2025		Passar um data set como parametro
Marcus Vinicius		   00001 11/02/2025		Tabela UDTT e Tabela original criadas com as mesmas colunas e parametros, porem aparece o erro de inser�ao (truncated in table 'tempdb.dbo.#A3D0A620')
---------------------- ----- ---------- ------------------------------------------------------------        
Marcus V. Paiva Silveira               04/02/2025 Cria��o da Procedure */

--Criar variavel do tipo tabela
IF NOT EXISTS (SELECT * FROM sys.types WHERE name = 'dtInserirDados')
BEGIN
	CREATE TYPE dtInserirDados
	AS TABLE
	(
			cNumeroRecintoAduaneiro CHAR(7),
			cNomeRecinto VARCHAR(500),
			cCidadeRecinto VARCHAR(100),
			cEstadoRecinto VARCHAR(100),
			cUnidadeReceitaFederal CHAR(7)
	)
END
GO

------------------------------------------------------------------------------------------------------------------------------
CREATE OR ALTER PROCEDURE stp_inserirDadosTabelaRecintoAlfandegado
@tInserirDados dtInserirDados READONLY
AS
BEGIN

	SET NOCOUNT ON

	ALTER DATABASE SCOPED CONFIGURATION 
    SET VERBOSE_TRUNCATION_WARNINGS = ON;

	BEGIN TRY

		BEGIN TRANSACTION

		RAISERROR('Inserindo dados na tabela tRecintoAlfandegado...',10,1) WITH NOWAIT
		WAITFOR DELAY '00:00:05'

		SELECT *  FROM @tInserirDados;

		INSERT INTO tRecintoAlfandegado
		(
			cNumeroRecintoAduaneiro,
			cNomeRecinto,
			cCidadeRecinto,
			cEstadoRecinto,
			cUnidadeReceitaFederal
		)
		SELECT 
			cNumeroRecintoAduaneiro, 
			cNomeRecinto,
			cCidadeRecinto, 
			cEstadoRecinto, 
			cUnidadeReceitaFederal
		FROM @tInserirDados;
		

		IF @@ROWCOUNT = 0
			RAISERROR('Os dados n�o foram inseridos corretamente',10,1);

		COMMIT;

	END TRY
	BEGIN CATCH
		
		IF @@TRANCOUNT > 0
			ROLLBACK;

		EXEC stp_ManipulaErro;

	END CATCH

	SELECT * FROM tRecintoAlfandegado;
END
GO
------------------------------------------------------------------------------------------------------------------------------

--Declarar variavel do tipo tabela para inserir os dados
DECLARE @t_tempInserirDados dtInserirDados;

INSERT INTO @t_tempInserirDados VALUES
	(3911301, 'Porto De Fortaleza - Cia. Docas do Ceara - Porto Maritimo ALF.', 'Fortaleza', 'Cear�', 0317900),
	(3931301, 'Aurora Terminais e Servi�os Ltda.', 'S�o Lu�s', 'Maranh�o', 0317903),
	(4931304, 'Inst. Port. Uso Publ. - Suata Serv. Log. Ltda.', 'Ipojuca', 'Pernambuco', 0417902),
	(4931305, 'Inst. Port. Uso Publ. - Atl�ntico Terminais S. A.', 'Porto De Suape', 'Pernambuco', 0417902),
	(5921301, 'Porto de Salvador - Codeba - Porto Marit. Alf. - Uso Publico', 'Salvador', 'Bahia', 0517800),
	(5921304, 'Inst. Port. Uso P�blico - Intermar�tima Terminais Ltda.', 'Salvador', 'Bahia', 0517800),
	(7301402, 'Tmult - Porto do A�� Opera��es S.A.', 'Campos dos Goytacazes', 'Rio de Janeiro', 0710400),
	(7920001, 'P�tio do Porto Do Rio De Janeiro', 'Rio De Janeiro', 'Rio de Janeiro', 0717600),
	(7921302, 'ICTSI Rio Brasil Terminal 1 S.A.', 'Rio De Janeiro', 'Rio de Janeiro', 0717600),
	(7921303, 'Inst. Port. Mar. Alf. Uso Publ. Cons. Mult Rio-T.II - Porto Rj', 'Rio De Janeiro', 'Rio de Janeiro', 0717600),
	(8813201, 'EADI - Aurora Terminais E Servi�os Ltda.', 'Sorocaba', 'S�o Paulo', 0811000),
	(8911101, 'Concession�ria do Aeroporto Internacional de Guarulhos S.A.', 'Guarulhos', 'S�o Paulo', 0817600),
	(8931359, 'Brasil Terminal Portu�rio S.A.', 'Santos', 'S�o Paulo', 0817800),
	(8943204, 'EADI - Embragem - Av.Mackenzie, 137, Jaguare', 'S�o Paulo', 'S�o Paulo', 0817900),
	(8943208, 'EADI Santo Andre Terminal de Cargas Ltda.', 'S�o Paulo', 'S�o Paulo', 0815500),
	(8943213, 'Aurora Terminais e Servi�os Ltda.', 'S�o Paulo', 'S�o Paulo', 0817900),
	(9801303, 'TCP - Terminal De Conteineres De Paranagua S/A', 'Paranagu�', 'Paran�', 0917800)

EXEC stp_inserirDadosTabelaRecintoAlfandegado @tInserirDados = @t_tempInserirDados;

------------------------------------------------------------------------------------------------------------------------------
-- 00001 - Tentando resolver o erro truncated table de forma manual (resolvido, variavel do tipo tabela exclu�da e criada novamente, dados inseridos sem erro)
SELECT @@TRANCOUNT --verificar se tem transa�ao aberta

--Tabela original dados sao inseridos sem erro
INSERT INTO tRecintoAlfandegado
( cNumeroRecintoAduaneiro,
			cNomeRecinto,
			cCidadeRecinto,
			cEstadoRecinto,
			cUnidadeReceitaFederal)
VALUES
(3911301, 'Porto De Fortaleza - Cia. Docas do Ceara - Porto Maritimo ALF.', 'Fortaleza', 'Cear�', 0317900),
(5921301, 'Porto de Salvador - Codeba - Porto Marit. Alf. - Uso Publico', 'Salvador', 'Bahia', 0517800)

DROP PROCEDURE stp_inserirDadosTabelaRecintoAlfandegado --excluir procedure que contem a variavel tipo tabela

DROP TYPE dtInserirDados;--excluir a variavel do tipo tabela

CREATE TYPE dtInserirDados --criada variavel do tipo tabela novamente
AS TABLE
(
		cNumeroRecintoAduaneiro CHAR(7),
		cNomeRecinto VARCHAR(500),
		cCidadeRecinto VARCHAR(100),
		cEstadoRecinto VARCHAR(100),
		cUnidadeReceitaFederal CHAR(7)
)

SELECT LEN('Porto De Fortaleza - Cia. Docas do Ceara - Porto Maritimo ALF.') -- verificar tamanho de caracteres do texto
------------------------------------------------------------------------------------------------------------------------------