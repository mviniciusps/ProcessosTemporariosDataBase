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
Objeto     : stp_inserirDadosTabelaRecintoAlfandegado
Objetivo   : Inserir varios dados (dataset) na tRecintoAlfandegado 
Projeto    : ProcessosTemporarios
Empresa Respons�vel: Braslog
Criado em  : 04/02/2025
Execu��o   : A procedure deve se executada quando se deseja novos dados        
Palavras-chave: INSERT INTO
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

	BEGIN TRY

		BEGIN TRANSACTION

		RAISERROR('Inserindo dados na tabela tRecintoAlfandegado...',10,1) WITH NOWAIT
		WAITFOR DELAY '00:00:05'

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
	(2931605, 'Inst.Por.Fluv.Alf-Uso Privativo-Chibatao Nav. Com-Manaus/Am', 'Porto De Manaus', 'PORTO DE MANAUS', 0227600),
	(8943209, 'Eadi-Lachmann Terminais Ltda.-Sao Bernardo Do Campo/Sp', 'S�o Paulo', 'S�O PAULO', 0817900)


	/*(3911301, 'Porto De Fortaleza - Cia. Docas do Ceara - Porto Maritimo ALF.', 'Fortaleza', 'Cear�', 0317900),
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
	(9801303, 'TCP - Terminal De Conteineres De Paranagua S/A', 'Paranagu�', 'Paran�', 0917800)*/

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

/*--------------------------------------------------------------------------------------------        
Tipo Objeto: Store Procedure
Objeto     : stp_inserirDadosTabelaCEMercante
Objetivo   : Inserir dataset nas colunas da tabela
Projeto    : ProcessosTemporarios
Empresa Respons�vel: Braslog
Criado em  : 13/02/2025
Execu��o   : Inserir varios dados de uma vez na tabela CE Mercante
Palavras-chave: INSERT INTO
----------------------------------------------------------------------------------------------        
Observa��es :        

----------------------------------------------------------------------------------------------        
Hist�rico:        
Autor                  IDBug Data			Descri��o
---------------------- ----- ---------- ------------------------------------------------------------        
Marcus V. Paiva Silveira               13/02/2025 Cria��o da Procedure */

--Criar variavel do tipo tabela
IF NOT EXISTS (SELECT * FROM sys.types WHERE name = 'dtInserirDadosCeMercante')
BEGIN
	CREATE TYPE dtInserirDadosCeMercante
	AS TABLE
	(
		cStatusCE VARCHAR(15),
		cNumeroCE CHAR(15)
	)
END
GO
------------------------------------------------------------------------------------------------------------------------------
CREATE OR ALTER PROCEDURE stp_inserirDadosTabelaCeMercante
@tInserirDados dtInserirDadosCeMercante READONLY
AS BEGIN

	SET NOCOUNT ON;

	BEGIN TRY
		
		BEGIN TRANSACTION

		RAISERROR('Inserindo dados na tabela tCeMercante...',10,1) WITH NOWAIT
		WAITFOR DELAY '00:00:05'

		INSERT INTO tCeMercante
		SELECT * FROM @tInserirDados

		IF @@ROWCOUNT = 0
			RAISERROR('Os dados n�o foram inseridos corretamente',10,1);

		COMMIT;

	END TRY
	BEGIN CATCH
		
		IF @@TRANCOUNT > 0
			ROLLBACK

		EXEC stp_ManipulaErro

	END CATCH

	SELECT * FROM tCeMercante

END
GO
------------------------------------------------------------------------------------------------------------------------------

--Declarar variavel do tipo tabela para inserir os dados
DECLARE @t_tempInserirDados dtInserirDadosCeMercante

SET NOCOUNT ON;
INSERT INTO @t_tempInserirDados VALUES
	('SUSPENSA', '072205154296309'),
	('SUSPENSA', '072405061514983'),
	('SUSPENSA', '072205156943263'),
	('SUSPENSA', '102205138266757'),
	('PAGA', '072105117508099'),
	('PAGA', '152005271192929'),
	('PAGA', '132105065072039'),
	('SUSPENSA', '132305053620239'),
	('SUSPENSA', '132305077973964'),
	('SUSPENSA', '162205256553652'),
	('SUSPENSA', '132205315120298'),
	('SUSPENSA', '132105211325331'),
	('SUSPENSA', '131705281227807'),
	('SUSPENSA', '131905052962183'),
	('PAGA', '131905052962345'),
	('SUSPENSA', '132105211325412'),
	('SUSPENSA', '072405055138258'),
	('SUSPENSA', '102205119780521'),
	('SUSPENSA', '102205119780440'),
	('SUSPENSA', '102205119780602'),
	('SUSPENSA', '102205119780793'),
	('SUSPENSA', '102205119780874'),
	('SUSPENSA', '132105237986793'),
	('SUSPENSA', '072205154324450'),
	('SUSPENSA', '072205188517243'),
	('SUSPENSA', '132305195841804'),
	('SUSPENSA', '152405318106469'),
	('SUSPENSA', '132305267830013'),
	('SUSPENSA', '152105242416074'),
	('SUSPENSA', '151805001998909'),
	('SUSPENSA', '132405221117348'),
	('SUSPENSA', '152205303647231'),
	('SUSPENSA', '152205303646693'),
	('PAGA', '151905198851634'),
	('SUSPENSA', '152305262872308'),
	('SUSPENSA', '152305251570810'),
	('SUSPENSA', '152405220231060')
	
EXEC stp_inserirDadosTabelaCeMercante @tInserirDados = @t_tempInserirDados;
GO
------------------------------------------------------------------------------------------------------------------------------

/*--------------------------------------------------------------------------------------------        
Tipo Objeto: Store Procedure
Objeto     : stp_inserirDadosTabelaCEMercante
Objetivo   : Inserir dataset nas colunas da tabela
Projeto    : ProcessosTemporarios
Empresa Respons�vel: Braslog
Criado em  : 13/02/2025
Execu��o   : Inserir varios dados de uma vez na tabela CE Mercante
Palavras-chave: INSERT INTO
----------------------------------------------------------------------------------------------        
Observa��es :        

----------------------------------------------------------------------------------------------        
Hist�rico:        
Autor                  IDBug Data			Descri��o
---------------------- ----- ---------- ------------------------------------------------------------        
Marcus V. Paiva Silveira               13/02/2025 Cria��o da Procedure */

--Criar variavel do tipo tabela
IF NOT EXISTS (SELECT * FROM sys.types WHERE name = 'dtInserirDadosApoliceGarantia')
BEGIN
	CREATE TYPE dtInserirDadosApoliceGarantia
	AS TABLE
	(
		cNumeroApolice VARCHAR(100),
		dVencimentoGarantia DATE,
		iRecintoID INT
	)
END
GO
------------------------------------------------------------------------------------------------------------------------------
CREATE OR ALTER PROCEDURE stp_inserirDadosTabelaApoliceGarantia
@tInserirDados dtInserirDadosApoliceGarantia READONLY
AS BEGIN

	SET NOCOUNT ON;

	BEGIN TRY
		
		BEGIN TRANSACTION

		RAISERROR('Inserindo dados na tabela tApoliceSeguroGarantia...',10,1) WITH NOWAIT
		WAITFOR DELAY '00:00:05'

		INSERT INTO tApoliceSeguroGarantia (cNumeroApolice, dVencimentoGarantia, iRecintoID)
		SELECT * FROM @tInserirDados

		IF @@ROWCOUNT = 0
			RAISERROR('Os dados n�o foram inseridos corretamente',10,1);

		COMMIT;

	END TRY
	BEGIN CATCH
		
		IF @@TRANCOUNT > 0
			ROLLBACK

		EXEC stp_ManipulaErro

	END CATCH

	SELECT * FROM tApoliceSeguroGarantia

END
GO
------------------------------------------------------------------------------------------------------------------------------

--Declarar variavel do tipo tabela para inserir os dados
DECLARE @t_tempInserirDados dtInserirDadosApoliceGarantia

SET NOCOUNT ON;
INSERT INTO @t_tempInserirDados VALUES
	('02-0775-0995466', '2027-06-17', 5),
	('02-0775-0929867', '2026-06-17', 3),
	('02-0775-0929900', '2026-03-24', 10),
	('02-0775-0990491', '2028-04-28', 9),
	('02-0775-0971950', '2027-10-28', 17),
	('02-0775-0925644', '2028-06-23', 10),
	('0775.22.1.817-7', '2025-04-20', 10),
	('02-0775-0931811', '2026-07-23', 10),
	('02-0775-0929956', '2026-07-23', 7),
	('0775.22.1.816-9', '2025-04-23', 10),
	('02-0775-0917395', '2027-06-02', 6),
	('02-0775-0917390', '2027-06-02', 6),
	('02-0775-0919034', '2027-06-02', 6),
	('02-0775-0920542', '2027-06-02', 6),
	('02-0775-0916249', '2027-07-20', 4),
	('02-0775-0948641', '2027-09-25', 3),
	('0306920239907750984452000', '2025-08-25', 7),
	('0306920239907751014466000', '2025-09-20', 12),
	('0306920239907751029642000', '2025-10-27', 10)

EXEC stp_inserirDadosTabelaApoliceGarantia @tInserirDados = @t_tempInserirDados;
GO
------------------------------------------------------------------------------------------------------------------------------