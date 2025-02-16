/*--------------------------------------------------------------------------------------------        
Tipo Objeto: Store Procedure
Objeto     : stp_ManipulaErro
Objetivo   : Utilizada na area CATCH para capturas os erros no Event Viewer do Windows
             e para gravar na tabela tLOGEventos.
Projeto    : ProcessosTemporarios          
Empresa Responsável: Braslog
Criado em  : 01/02/2025
Execução   : a procedure deve se executada na area de CATCH         
Palavras-chave: Erro, tratamento, catch, avisos
----------------------------------------------------------------------------------------------        
Observações :        

----------------------------------------------------------------------------------------------        
Histórico:        
Autor                  IDBug Data       Descrição        
---------------------- ----- ---------- ------------------------------------------------------------        
Marcus V. Paiva Silveira               01/02/2025 Criação da Procedure */

CREATE OR ALTER PROCEDURE stp_ManipulaErro
AS
BEGIN
	--Área configuraçao da sessão
	SET NOCOUNT ON

	--Declaraçao das variáveis
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

		--cálculo e processamento sem o tratamento de erro ou transaçao.
		SET @cMensagem = FORMATMESSAGE('MsgID %d. %s. Severidade %d. Status %d. Procedure %s. Linha %d.', @nErrorNumber, @cMensagem, @nErrorSeverity, @nErrorState, @nErrorProcedure, @nErrorLine)

		SET @niIDEvento = NEXT VALUE FOR seqIIDEvento

		--Gravaçao na tabela
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
Objetivo   : Fazer backup para o diretório C:\Backup
Projeto    : ProcessosTemporarios
Empresa Responsável: Braslog
Criado em  : 04/02/2025
Execução   : a procedure deve se executada diariamente, em um horário específico        
Palavras-chave: Backup
----------------------------------------------------------------------------------------------        
Observações :        

----------------------------------------------------------------------------------------------        
Histórico:        
Autor                  IDBug Data       Descrição        
---------------------- ----- ---------- ------------------------------------------------------------        
Marcus V. Paiva Silveira               04/02/2025 Criação da Procedure */

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
Empresa Responsável: Braslog
Criado em  : 04/02/2025
Execução   : a procedure deve se executada quando se deseja novos dados        
Palavras-chave: INSERT INTO
----------------------------------------------------------------------------------------------        
Observações :        

----------------------------------------------------------------------------------------------        
Histórico:        
Autor                  IDBug Data			Descrição
Marcus Vinicius	     		 08/02/2025		Passar um data set como parametro
Marcus Vinicius		   00001 11/02/2025		Tabela UDTT e Tabela original criadas com as mesmas colunas e parametros, porem aparece o erro de inserçao (truncated in table 'tempdb.dbo.#A3D0A620')
---------------------- ----- ---------- ------------------------------------------------------------        
Marcus V. Paiva Silveira               04/02/2025 Criação da Procedure */

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
			RAISERROR('Os dados não foram inseridos corretamente',10,1);

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
	(2931605, 'Inst.Por.Fluv.Alf-Uso Privativo-Chibatao Nav. Com-Manaus/Am', 'Porto de Manaus', 'PORTO de MANAUS', 0227600),
	(8943209, 'Eadi-Lachmann Terminais Ltda.-Sao Bernardo Do Campo/Sp', 'São Paulo', 'SÃO PAULO', 0817900)
	(3911301, 'Porto de Fortaleza - Cia. Docas do Ceara - Porto Maritimo ALF.', 'Fortaleza', 'Ceará', 0317900),
	(3931301, 'Aurora Terminais e Serviços Ltda.', 'São Luís', 'Maranhão', 0317903),
	(4931304, 'Inst. Port. Uso Publ. - Suata Serv. Log. Ltda.', 'Ipojuca', 'Pernambuco', 0417902),
	(4931305, 'Inst. Port. Uso Publ. - Atlântico Terminais S. A.', 'Porto de Suape', 'Pernambuco', 0417902),
	(5921301, 'Porto de Salvador - Codeba - Porto Marit. Alf. - Uso Publico', 'Salvador', 'Bahia', 0517800),
	(5921304, 'Inst. Port. Uso Público - Intermarítima Terminais Ltda.', 'Salvador', 'Bahia', 0517800),
	(7301402, 'Tmult - Porto do Açú Operações S.A.', 'Campos dos Goytacazes', 'Rio de Janeiro', 0710400),
	(7920001, 'Pátio do Porto Do Rio de Janeiro', 'Rio de Janeiro', 'Rio de Janeiro', 0717600),
	(7921302, 'ICTSI Rio Brasil Terminal 1 S.A.', 'Rio de Janeiro', 'Rio de Janeiro', 0717600),
	(7921303, 'Inst. Port. Mar. Alf. Uso Publ. Cons. Mult Rio-T.II - Porto Rj', 'Rio de Janeiro', 'Rio de Janeiro', 0717600),
	(8813201, 'EADI - Aurora Terminais e Serviços Ltda.', 'Sorocaba', 'São Paulo', 0811000),
	(8911101, 'Concessionária do Aeroporto Internacional de Guarulhos S.A.', 'Guarulhos', 'São Paulo', 0817600),
	(8931359, 'Brasil Terminal Portuário S.A.', 'Santos', 'São Paulo', 0817800),
	(8943204, 'EADI - Embragem - Av.Mackenzie, 137, Jaguare', 'São Paulo', 'São Paulo', 0817900),
	(8943208, 'EADI Santo Andre Terminal de Cargas Ltda.', 'São Paulo', 'São Paulo', 0815500),
	(8943213, 'Aurora Terminais e Serviços Ltda.', 'São Paulo', 'São Paulo', 0817900),
	(9801303, 'TCP - Terminal de Conteineres de Paranagua S/A', 'Paranaguá', 'Paraná', 0917800)

EXEC stp_inserirDadosTabelaRecintoAlfandegado @tInserirDados = @t_tempInserirDados;

------------------------------------------------------------------------------------------------------------------------------
-- 00001 - Tentando resolver o erro truncated table de forma manual (resolvido, variavel do tipo tabela excluída e criada novamente, dados inseridos sem erro)
SELECT @@TRANCOUNT --verificar se tem transaçao aberta

--Tabela original dados sao inseridos sem erro
INSERT INTO tRecintoAlfandegado
( cNumeroRecintoAduaneiro,
			cNomeRecinto,
			cCidadeRecinto,
			cEstadoRecinto,
			cUnidadeReceitaFederal)
VALUES
(3911301, 'Porto de Fortaleza - Cia. Docas do Ceara - Porto Maritimo ALF.', 'Fortaleza', 'Ceará', 0317900),
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

SELECT LEN('Porto de Fortaleza - Cia. Docas do Ceara - Porto Maritimo ALF.') -- verificar tamanho de caracteres do texto
------------------------------------------------------------------------------------------------------------------------------

/*--------------------------------------------------------------------------------------------        
Tipo Objeto: Store Procedure
Objeto     : stp_inserirDadosTabelaCEMercante
Objetivo   : Inserir dataset nas colunas da tabela
Projeto    : ProcessosTemporarios
Empresa Responsável: Braslog
Criado em  : 13/02/2025
Execução   : Inserir varios dados de uma vez na tabela CE Mercante
Palavras-chave: INSERT INTO
----------------------------------------------------------------------------------------------        
Observações :        

----------------------------------------------------------------------------------------------        
Histórico:        
Autor                  IDBug Data			Descrição
---------------------- ----- ---------- ------------------------------------------------------------        
Marcus V. Paiva Silveira               13/02/2025 Criação da Procedure */

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
			RAISERROR('Os dados não foram inseridos corretamente',10,1);

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
Empresa Responsável: Braslog
Criado em  : 13/02/2025
Execução   : Inserir varios dados de uma vez na tabela CE Mercante
Palavras-chave: INSERT INTO
----------------------------------------------------------------------------------------------        
Observações :        

----------------------------------------------------------------------------------------------        
Histórico:        
Autor                  IDBug Data			Descrição
---------------------- ----- ---------- ------------------------------------------------------------        
Marcus V. Paiva Silveira               13/02/2025 Criação da Procedure */

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
			RAISERROR('Os dados não foram inseridos corretamente',10,1);

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
/*--------------------------------------------------------------------------------------------        
Object type: Stored Procedure
Object     : stp_InsertDataContractTable
Goal	   : Insert dataset in Contract Table
Project    : Temporaries
Criation   : 15/02/2025
Execution  : Insert at the same time dataset into Contract table
Keywords   : INSERT INTO
----------------------------------------------------------------------------------------------        
Observation:        

----------------------------------------------------------------------------------------------        
History:        
Author                  IDBug Date		Description
---------------------- ----- ---------- ------------------------------------------------------------        
Marcus V. Paiva Silveira                15/02/2025 Procedure created */

IF NOT EXISTS (SELECT *  FROM sys.types WHERE NAME = 'dtInsertDataContractTable')
BEGIN
	CREATE TYPE dtInsertDataContractTable
	AS TABLE
	(
		cNumeroNomeContrato VARCHAR(100),
		cContratoTipo VARCHAR(20),
		dContratoDataAssinatura DATE,
		dContratoVencimento DATE,
		iNumeroProrrogacao INT
	)
END
GO

CREATE OR ALTER PROCEDURE stp_inserirDadosNaTabelaContrato
@tInserirDados dtInsertDataContractTable READONLY
AS BEGIN

	SET NOCOUNT ON;

	BEGIN TRY

		BEGIN TRANSACTION

		RAISERROR('Inserindo dados na tabele tContrato...',10,1) WITH NOWAIT;
		WAITFOR DELAY '00:00:05';

		INSERT INTO tContrato (cNumeroNomeContrato, cContratoTipo, dContratoDataAssinatura, dContratoVencimento, iNumeroProrrogacao)
		SELECT * FROM @tInserirDados;

		IF @@ROWCOUNT = 0
			RAISERROR('Dados não foram inseridos corretamente!',10,1);

		COMMIT;

	END TRY
	BEGIN CATCH
		
		IF @@TRANCOUNT > 0
			ROLLBACK

		EXECUTE stp_ManipulaErro

	END CATCH

	SELECT * FROM tContrato

END
GO
------------------------------------------------------------------------------------------------------------------------------      
DECLARE @t_tempInserirDados dtInsertDataContractTable

SET NOCOUNT ON

INSERT INTO @t_tempInserirDados VALUES
	('3º Aditivo ao Contrato de Locaçao', 'Aluguel', '2024-06-24', '2024-11-28', 3),
	('3º Aditivo ao Contrato de Locaçao', 'Aluguel', '2024-06-20', '2024-11-28', NULL),
	('3º Aditivo ao Contrato de Comodato', 'Comodato', '2024-10-22', '2024-12-03', 3),
	('4º Aditivo ao Contrato de Locaçao', 'Aluguel', '2024-10-24', '2024-12-12', 4),
	('3º Aditivo ao Contrato de Locaçao', 'Aluguel', '2024-11-12', '2024-12-20', 3),
	('Contrato de Afretamento por Tempo para Embarcações de Apoio Offshore', 'Afretamento', '2024-05-14', '2024-12-31', NULL),
	('9º Aditivo ao Contrato de Locaçao', 'Aluguel', '2024-12-12', '2025-01-21', 9),
	('Relatório Técnico de Envio de motor em Garantia para Collin', 'Reparo', NULL, '2025-01-22', 2),
	('Instrumento Particular de Contrato de Locaçao de Equipamentos nº DH-MEGA17', 'Aluguel', '2020-11-30', '2025-02-04', NULL),
	('Primeiro Aditamento de Contrato nº 01 de Afretamento de Draga a Casco Nu', 'Afretamento', '2024-10-07', '2025-02-18', NULL),
	('5º Termo Aditivo ao Contrato Nº BPCRC-014-2022-PRD', 'Aluguel', '2024-11-15', '2025-03-09',NULL ),
	('5º Termo Aditivo ao Contrato Nº BPCRC-014-2022-PRD', 'Aluguel', '2024-11-15', '2025-03-09',NULL ),
	('9º Aditivo ao Contrato de Locaçao', 'Aluguel', '2024-12-20', '2025-03-26', 9),
	('5º Aditivo ao Contrato de Locaçao', 'Aluguel', '2024-11-27', '2025-03-30', 5),
	('5º Aditivo ao Contrato de Locaçao', 'Aluguel', '2024-11-28', '2025-04-03', 5),
	('5º Aditivo ao Contrato de Locaçao', 'Aluguel', '2024-12-04', '2025-04-12', 5),
	('5º Aditivo ao Contrato de Locaçao', 'Aluguel', '2024-12-09', '2025-04-19', 5),
	('8º Aditivo ao Contrato de Locaçao', 'Aluguel', '2024-12-09', '2025-04-20', 8),
	('18º Aditivo ao Contrato de Locaçao', 'Aluguel', '2024-12-18', '2025-04-23', 18),
	('14º Aditivo ao Contrato de Locaçao', 'Aluguel', '2024-12-19', '2025-04-23', 14),
	('14º Aditivo ao Contrato de Locaçao', 'Aluguel', '2024-12-12', '2025-04-23', 14),
	('15º Aditivo ao Contrato de Locaçao', 'Aluguel', '2024-12-12', '2025-04-23', 8),
	('3º Aditivo ao Contrato de Comodato', 'Comodato', '2024-12-18', '2025-04-25', 3),
	('5º Aditivo ao Contrato de Locaçao', 'Aluguel', '2024-12-18', '2025-04-28', 5),
	('5º Aditivo ao Contrato de Locaçao', 'Aluguel', '2024-12-18', '2025-04-28', 5),
	('5º Aditivo ao Contrato de Locaçao', 'Aluguel', '2024-12-18', '2025-04-28', 5),
	('5º Aditivo ao Contrato de Locaçao', 'Aluguel', '2024-12-18', '2025-04-29', 5),
	('Laudo de identificaçao de Mercadorias para Exportaçao Temporária', 'Reparo', '2024-03-28', '2025-05-01',NULL ),
	('9º Aditivo ao Contrato de Locaçao', 'Aluguel', '2024-11-24', '2025-05-04', 9),
	('12º Aditivo ao Contrato de Locaçao', 'Aluguel', '2024-11-28', '2025-05-06', 12),
	('Instrumento Particular de Contrato de Comodato', 'Comodato', '2024-05-13', '2025-05-13',NULL ),
	('5º Aditivo ao Contrato de Locaçao', 'Aluguel', '2024-11-07', '2025-05-21', 5),
	('4º Aditivo ao Contrato de Comodato', 'Comodato', '2024-11-27', '2025-05-29', 4),
	('8º Aditivo ao Contrato de Comodato', 'Comodato', '2024-11-29', '2025-06-06', 8),
	('8º Aditivo ao Contrato de Comodato', 'Comodato', '2024-12-04', '2025-06-11', 8),
	('6º Aditivo ao Contrato de Locaçao', 'Aluguel', '2024-12-09', '2025-06-21', 6),
	('5º Aditivo ao Contrato de Locaçao', 'Aluguel', '2024-12-12', '2025-06-22', 5),
	('Contrato de Fretamento por Período Embarcações de Apoio Marítimo', 'Afretamento', '2024-09-18', '2025-07-11',NULL ),
	('Lease Agreement (Bare Rental) Addedum 2022208', 'Aluguel', '2024-07-08', '2025-08-21', 1),
	('Contrato', 'Emprestimo', '2023-10-27', '2025-09-01',NULL ),
	('Instrumento Particular de Contrato de Comodato', 'Comodato', '2024-09-11', '2025-09-11',NULL ),
	('Primeiro Aditivo Contratual', 'Comodato', '2024-08-26', '2025-09-20', 1),
	('Lease Agreement (Bare Rental) Addedum 2023099-1', 'Aluguel', NULL, '2025-10-21', 1),
	('Instrumento Particular de Contrato de Locaçao de Equipamentos nº DH-MEGA18', 'Aluguel', '2021-07-07', '2025-10-26',NULL ),
	('1º Termo Aditivo ao Instrumento Particular de Contrato de Locaçao de Equipamentos nº DH-MEGA15', 'Aluguel', '2022-01-11', '2026-02-09', 1),
	('Lease Agreement (Bare Rental) Addedum 2022208', 'Aluguel', '2024-07-08', '2026-02-22',NULL ),
	('Contrato de Emprestimo Agency Agreement', 'Emprestimo', '2024-03-11', '2026-03-10',NULL ),
	('Instrumento Particular de Contrato de Locaçao de Equipamentos nº DH-MEGA20', 'Aluguel', '2022-10-20', '2026-12-28',NULL ),
	('Instrumento Particular de Contrato de Locaçao de Equipamentos nº DH-MEGA19', 'Aluguel', '2022-09-21', '2027-01-01',NULL ),
	('2º Termo Aditivo ao Instrumento Particular de Contrato de Locaçao de Equipamentos nº DH-MEGA7-19', 'Aluguel', '2023-03-03', '2027-08-08', 2),
	('2º Termo Aditivo ao Instrumento Particular de Contrato de Locaçao de Equipamentos nº DH-MEGA6-19', 'Aluguel', '2023-03-03', '2027-08-08', 2),
	('2º Termo Aditivo ao Instrumento Particular de Contrato de Locaçao de Equipamentos nº DH-MEGA16', 'Aluguel', '2023-10-02', '2027-11-25', 1),
	('Instrumento Particular de Contrato de Locaçao de Equipamentos nº DH-MEGA23', 'Aluguel', '2023-09-01', '2027-11-27',NULL ),
	('Instrumento Particular de Contrato de Locaçao de Equipamentos nº DH-MEGA21-22', 'Aluguel', '2023-08-11', '2027-12-01',NULL ),
	('Instrumento Particular de Contrato de Locaçao de Equipamentos nº DH-MEGA24', 'Aluguel', '2024-04-01', '2028-08-16',NULL )

EXECUTE stp_inserirDadosNaTabelaContrato @tInserirDados = @t_tempInserirDados
GO
------------------------------------------------------------------------------------------------------------------------------

/*--------------------------------------------------------------------------------------------        
Object type: Stored Procedure
Object     : stp_inserirDadosTabelaCNPJ
Goal	   : Insert dataset in CNPJ table
Project    : Temporaries
Criation   : 15/02/2025
Execution  : Insert at the same time dataset into CNPJ table
Keywords   : INSERT INTO
----------------------------------------------------------------------------------------------        
Observation:        

----------------------------------------------------------------------------------------------        
History:        
Author                  IDBug Date		Description
---------------------- ----- ---------- ------------------------------------------------------------        
Marcus V. Paiva Silveira                15/02/2025 Procedure created */


IF NOT EXISTS (SELECT * FROM sys.types WHERE NAME = 'dtInsertDataCNPJTable')
BEGIN
	CREATE TYPE dtInsertDataCNPJTable
	AS TABLE
	(
		cNumeroInscricao CHAR(14),
		cNomeEmpresarial VARCHAR(100),
		cLogradouro VARCHAR(100),
		cNumeroLogradouro VARCHAR(10),
		cBairroLogradouro VARCHAR(50),
		cCidadelogradouro VARCHAR(50),
		cEstadoLogradouro VARCHAR(50)
	)
END
GO

CREATE OR ALTER PROCEDURE stp_inserirDadosTabelaApoliceGarantia
@tInserirDados dtInsertDataCNPJTable READONLY
AS BEGIN

	SET NOCOUNT ON;

	BEGIN TRY

		BEGIN TRANSACTION;

		RAISERROR('Inserindo os dados na tabela tCNPJ...',10,1) WITH NOWAIT;
		WAITFOR DELAY '00:00:05';

		INSERT INTO tCNPJ
		(
			cNumeroInscricao,
			cNomeEmpresarial,
			cLogradouro,
			cNumeroLogradouro,
			cBairroLogradouro,
			cCidadelogradouro,
			cEstadoLogradouro
		)
		SELECT * FROM @tInserirDados;

		IF @@ROWCOUNT = 0
			RAISERROR('Dados nao foram inseridos com sucesso!',10,1);

		COMMIT;

	END TRY
	BEGIN CATCH
		
		IF @@TRANCOUNT > 0
			ROLLBACK

		EXECUTE stp_ManipulaErro;

	END CATCH

	SELECT * FROM tCNPJ

END
GO

DECLARE @t_tempInserirDados dtInsertDataCNPJTable;

SET NOCOUNT ON;
INSERT INTO @t_tempInserirDados VALUES
	('02295964000130', 'Megasil Comercio De Produtos Agricolas E Servicos De Colheitas Ltda', 'Rua Dom Jose Carlos Aguirre', '1365', 'Vila Ozorio', 'Itarare', 'São Paulo'),
	('02385674000187', 'Dta Engenharia Ltda', 'Rua Jeronimo Da Veiga', '45', 'Jardim Europa', 'São Paulo', 'São Paulo'),
	('05061157000140', 'Bowline Marine & Cargo Consultants Ltda', 'Rua Xv De Novembro', '65', 'Centro', 'Santos', 'São Paulo'),
	('10567976000102', 'Nea - Comercial De Produtos Industriais Ltda', 'Rua Lino Peixoto Amorim', '1000', 'Paineiras', 'Itupeva', 'São Paulo'),
	('11426377000123', 'Mammoet Brasil Guindastes Ltda.', 'Rua Carlos Lisdegno Carlucci', '519', 'Jardim Peir Peri', 'São Paulo', 'São Paulo'),
	('11426377000638', 'Mammoet Brasil Guindastes Ltda.', 'Av Presidente Wilson', '231', 'Centro', 'Rio De Janeiro', 'Rio De Janeiro'),
	('15563826000489', 'Tse S/A', 'Estrada De Acesso A Br 135', 'Null', 'Zona Industrial', 'Santo Antonio Dos Lopes', 'Maranhão'),
	('23955189000171', 'Mitsubishi Power South America Limitada', 'Alameda Santo', '415', 'Cerqueira Cesar', 'São Paulo', 'São Paulo'),
	('29884534000290', 'Marlim Azul Energia S.A.', 'Rua Dos Garçons', 'Null', 'Horto', 'Macaé', 'Rio De Janeiro'),
	('43053081001334', 'Transdata Engenharia E Movimentacao Ltda', 'Avenida Rio Branco', '37', 'Centro', 'Rio De Janeiro', 'Rio De Janeiro'),
	('47098918000693', 'Veolia Water Technologies And Solutions Brasil Tratamento De Aguas Ltda', 'Rua Osasco', '28', 'Parque Industrial Anhanguera', 'Cajamar', 'São Paulo'),
	('51254159000173', 'Karina Plasticos Ltda', 'Avenida Antranig Guerekmezian', '788', 'Jardim Cumbica', 'Guarulhos', 'São Paulo')

EXECUTE stp_inserirDadosTabelaApoliceGarantia @tInserirDados = @t_tempInserirDados;
------------------------------------------------------------------------------------------------------------------------------

/*--------------------------------------------------------------------------------------------        
Object type: Stored Procedure
Object     : stp_inserirDadosTabelaDeclaracao
Goal	   : Insert dataset in Declaracao table
Project    : Temporaries
Criation   : 15/02/2025
Execution  : Insert at the same time dataset into Declaracao table
Keywords   : INSERT INTO
----------------------------------------------------------------------------------------------        
Observation:        

----------------------------------------------------------------------------------------------        
History:        
Author                  IDBug Date		Description
---------------------- ----- ---------- ------------------------------------------------------------        
Marcus V. Paiva Silveira                15/02/2025 Procedure created */

BEGIN TRANSACTION

	BEGIN TRY

	IF NOT EXISTS (SELECT * FROM sys.types WHERE NAME = 'dtInsertDataDeclaracaoTable')
		BEGIN
			CREATE TYPE dtInsertDataDeclaracaoTable
			AS TABLE
			(
				cNumeroDeclaracao VARCHAR(12),
				iCNPJID INT,
				cReferenciaBraslog CHAR(13),
				cReferenciaCliente VARCHAR(100),
				dDataRegistroDeclaracao DATE,
				dDataDesembaracoDeclaracao DATE,
				iCEID INT,
				iRecintoID INT,
				cNumeroDOSSIE CHAR(15),
				cNumeroProcessoAdministrativo CHAR(100),
				iContratoID INT,
				iApoliceID INT,
				cModal VARCHAR(15)
			)
		END

		COMMIT

	END TRY
	BEGIN CATCH		
		
		IF @@TRANCOUNT > 0
			ROLLBACK;

		EXEC stp_ManipulaErro;

	END CATCH;
GO

CREATE OR ALTER PROCEDURE stp_inserirDadosNaTabelaDeclaracao
@tInserirDados dtInsertDataDeclaracaoTable READONLY
AS BEGIN

	SET NOCOUNT ON

	BEGIN TRANSACTION

	BEGIN TRY

		RAISERROR('Inserindo dados na tabela tDeclaraçao...',10,1) WITH NOWAIT;
		WAITFOR DELAY '00:00:02';

		INSERT INTO tDeclaracao
		(
			cNumeroDeclaracao,
			iCNPJID,
			cReferenciaBraslog,
			cReferenciaCliente,
			dDataRegistroDeclaracao,
			dDataDesembaracoDeclaracao,
			iCEID,
			iRecintoID,
			cNumeroDOSSIE,
			cNumeroProcessoAdministrativo,
			iContratoID,
			iApoliceID,
			cModal
		)
		SELECT * FROM @tInserirDados;

		IF @@ROWCOUNT = 0
		BEGIN
			RAISERROR('Dados nao foram inseridos com sucesso!',10,1);
			ROLLBACK;
			RETURN;
		END

		DECLARE @iNumeroColunas INT = (SELECT COUNT(COLUMN_NAME) FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_NAME = 'tDeclaracao');
		DECLARE @iContador INT = 1;
		DECLARE @cNomeColuna VARCHAR(50);

		WHILE @iContador <= @iNumeroColunas
		BEGIN
			
			SET @cNomeColuna = (SELECT NAME FROM sys.columns WHERE OBJECT_ID = OBJECT_ID('tDeclaracao') AND column_id = @iContador);
			RAISERROR('Populando coluna %s na tabela tDeclaracao...',10,1,@cNomeColuna) WITH NOWAIT;
			WAITFOR DELAY '00:00:02';

			SET @iContador += 1;

		END

		RAISERROR('Todos os dados foram inseridos com sucesso!',10,1) WITH NOWAIT;
		WAITFOR DELAY '00:00:05';

		COMMIT;

	END TRY
	BEGIN CATCH
		
		IF @@TRANCOUNT > 0
			ROLLBACK

		EXECUTE stp_ManipulaErro;

	END CATCH;

	SELECT * FROM tDeclaracao;

END
GO

DECLARE @t_tempInserirDados dtInsertDataDeclaracaoTable

SET NOCOUNT ON
INSERT INTO @t_tempInserirDados VALUES
	('2213721580', 5, 'I-22/0968-MBG', NULL, '2022-07-19', '2022-07-27', 1, 4, '202200158843967', NULL, 1, NULL, 'MARÍTIMO'),
	('2406902926', 5, 'I-24/0271-MBG', 'CABOS E CONTRAPESO', '2024-04-02', '2024-04-04', 2, 3, '202400232144540', NULL, 3, NULL, 'MARÍTIMO'),
	('2215388101', 5, 'I-22/1149-MBG', NULL, '2022-08-10', '2022-08-12', 3, 4, '202200161707530', NULL, 4, NULL, 'MARÍTIMO'),
	('2211469948', 5, 'I-22/0680-MBG', 'CC3800-1', '2022-06-17', '2022-06-29', 4, 5, '202200155225677', NULL, 1, 1, 'MARÍTIMO'),
	('2411169727', 2, 'I-24/1100-DTE', 'DRAGA FENFORD', '2024-05-27', '2024-05-27', NULL, 8, '202400238873528', NULL, 6, NULL, 'MEIOS PRÓPRIOS'),
	('2111602972', 5, 'I-21/0721-MBG', 'LTM1500-8.1', '2021-06-17', '2021-06-21', 5, 3, '202100109389832', NULL, 7, 2, 'MARÍTIMO'),
	('240010523748', 12, 'E-24/0208-KRN', 'EXP TEMPORARIA', '2024-06-24', '2024-06-25', NULL, 12, '202400242169252', NULL, 8, NULL, 'AÉREO'),
	('2102189170', 1, 'I-20/1533-MEG', 'FORRAGEIRA + PLATAFORMA', '2021-02-03', '2021-02-04', 6, 11, '202100097363944', NULL, 9, NULL, 'MARÍTIMO'),
	('2412607809', 2, 'I-24/1261-DTE', 'DRAGA ELBE', '2024-06-14', '2024-06-18', NULL, 1, '202400241046459', NULL, 10, NULL, 'MEIOS PRÓPRIOS'),
	('240003252912', 4, 'E-24/0052-NEA', NULL, '2024-02-27', '2024-02-28', NULL, 13, '202400227845285', NULL, 11, NULL, 'AÉREO'),
	('240000198208', 4, 'E-24/0004-NEA', NULL, '2024-01-05', '2024-01-12', NULL, 13, '202400222101024', NULL, 11, NULL, 'AÉREO'),
	('2105759393', 6, 'I-21/0343-MBG', 'EXP-MUSA-12521', '2021-03-24', '2021-03-26', 7, 10, '202100103816828', NULL, 7, 3, 'MARÍTIMO'),
	('2306782082', 5, 'I-23/0175-MBG', 'REP. DOMINICANA', '2023-04-10', '2023-04-13', 8, 9, '202300188957138', NULL, 14, NULL, 'MARÍTIMO'),
	('2308248563', 5, 'I-23/0432-MBG', 'REP. LINHA DE EIXO', '2023-04-28', '2023-05-10', 9, 9, '202300191329045', NULL, 14, 4, 'MARÍTIMO'),
	('2221403214', 5, 'I-22/1173-MBG', 'EXPO-CHL-BRL-034', '2022-10-28', '2022-11-08', 10, 17, '202200171178807', NULL, 14, 5, 'MARÍTIMO'),
	('2225612292', 5, 'I-22/1955-MBG', 'CC 2800-1', '2022-12-26', '2023-01-19', 11, 10, '202200177717807', NULL, 14, 6, 'MARÍTIMO'),
	('2117258092', 6, 'I-21/1420-MBG', 'CKE1100G-2', '2021-09-17', '2021-09-20', 12, 10, '202100119574713', NULL, 18, 7, 'MARÍTIMO'),
	('1801413543', 6, 'I-17/2116-MBG', 'LINHA DE EIXO + POWER PACK', '2018-01-22', '2018-02-19', 13, 10, '201800018270352', '10711.720099/2018-34', 19, 8, 'MARÍTIMO'),
	('1905629534', 6, 'I-19/0083-MBG', 'GUINDASTE CC 2800-1', '2019-03-28', '2019-04-09', 14, 7, '201900038644169', '10120.004639/0319-51', 20, 9, 'MARÍTIMO'),
	('1906086887', 6, 'I-19/0142-MBG', 'CONTAINER OFICINA', '2019-04-04', '2019-04-09', 15, 7, '201900038679949', '10120.004638/0319-14', 20, NULL, 'MARÍTIMO'),
	('2117294706', 6, 'I-21/1419-MBG', 'CC2800-1', '2021-09-10', '2021-09-20', 16, 10, '202100119592274', NULL, 22, 10, 'MARÍTIMO'),
	('2406046760', 5, 'I-24/0252-MBG', 'JIB', '2024-03-20', '2024-03-25', 17, 3, '202400230765378', NULL, 3, NULL, 'MARÍTIMO'),
	('2210462397', 5, 'I-22/0623-MBG', 'CKE1100G2 - KOBELCO', '2022-06-02', '2022-06-28', 18, 6, '202200151499195', NULL, 14, 11, 'MARÍTIMO'),
	('2210427150', 5, 'I-22/0631-MBG', 'LR1300', '2022-06-02', '2022-06-28', 19, 6, '202200151629293', NULL, 14, 12, 'MARÍTIMO'),
	('2210450267', 5, 'I-22/0621-MBG', 'CK1100 (KOBELCO)', '2022-06-02', '2022-06-28', 20, 6, '202200151434298', NULL, 14, 13, 'MARÍTIMO'),
	('2210475103', 5, 'I-22/0630-MBG', 'RT890E', '2022-06-02', '2022-06-29', 21, 6, '202200151564345', NULL, 14, 14, 'MARÍTIMO'),
	('240006359556', 9, 'E-24/0119-MRL', NULL, '2024-04-17', '2024-05-01', NULL, 12, '202400233843302', NULL, 28, NULL, 'AÉREO'),
	('2104031884', 5, 'I-21/0242-MBG', 'MID POINTS', '2021-03-01', '2021-03-08', NULL, 14, '202100101144776', '13032.193464/2021-68', 7, NULL, 'AÉREO'),
	('1908940648', 5, 'I-19/0475-MBG', 'PENOANT', '2019-05-20', '2019-06-06', NULL, 14, '201900042372208', '10120.004974/0519-84', 30, NULL, 'AÉREO'),
	('2410910580', 11, 'I-24/1022-VEO', 'Aquaforce 7500', '2024-05-23', '2024-05-23', NULL, 12, '202400238478718', NULL, 31, NULL, 'AÉREO'),
	('230002563884', 5, 'E-23/0033-MBG', '001/23', '2023-02-16', '2023-02-22', NULL, 10, '202300183358937', NULL, 14, NULL, 'AÉREO'),
	('2210492504', 5, 'I-22/0632-MBG', 'PEÇAS SPMT', '2022-06-02', '2022-06-29', 22, 6, '202200151601747', NULL, 33, NULL, 'MARÍTIMO'),
	('2119044286', 6, 'I-21/1596-MBG', 'MOITAO CC2800', '2021-10-05', '2021-10-06', 23, 10, '202100123107563', NULL, 34, NULL, 'MARÍTIMO'),
	('2106758145', 5, 'I-21/0555-MBG', 'ATUADRO CC2800', '2021-04-08', '2021-04-14', NULL, 14, '202100105179086', NULL, 34, NULL, 'AÉREO'),
	('2213762170', 5, 'I-22/0809-MBG', NULL, '2022-07-20', '2022-07-28', 24, 4, '202200158856694', NULL, 36, 15, 'MARÍTIMO'),
	('2216549737', 5, 'I-22/0688-MBG', 'SPMT (REP. DOMINICANA)', '2022-08-25', '2022-09-22', 25, 3, '202200163555567', NULL, 14, 16, 'MARÍTIMO'),
	('2422306844', 2, 'I-24/2191-DTE', 'DRAGA LINDWAY', '2024-10-11', '2024-10-14', NULL, 18, '202400256103291', NULL, 38, NULL, 'MEIOS PRÓPRIOS'),
	('2316367940', 10, 'I-23/0861-TRA', 'ADM TEMP M18000', '2023-08-21', '2023-08-30', 26, 7, '202300205397590', NULL, 39, 17, 'MARÍTIMO'),
	('2420073435', 7, 'I-24/1189-TOY', 'TRN030', '2024-09-16', '2024-09-18', NULL, 2, '202400252826140', NULL, 40, NULL, 'AÉREO'),
	('2425413366', 11, 'I-24/1826-VEO', 'PILOT TEST PETROBRÁS', '2024-11-19', '2024-11-19', 27, 19, '202400261377728', NULL, 31, NULL, 'MARÍTIMO'),
	('2319009484', 8, 'I-23/1919-MIT', 'TL 58415', '2023-09-26', '2023-10-09', NULL, 12, '202300209954280', NULL, 42, 18, 'AÉREO'),
	('2321191189', 10, 'I-23/1722-TRA', 'PPU + SPTM', '2023-10-26', '2023-11-13', 28, 10, '202300214163318', NULL, 43, 19, 'MARÍTIMO'),
	('2119807018', 1, 'I-21/1334-MEG', 'WS21-1', '2021-10-15', '2021-10-26', 29, 11, '202100116268220', NULL, 44, NULL, 'MARÍTIMO'),
	('1802261224', 1, 'I-17/1964-MEG', 'US17-2', '2018-02-05', '2018-02-09', 30, 11, '201800018565140', '10010.005227/0118-79', 45, NULL, 'MARÍTIMO'),
	('2418067180', 10, 'I-24/1778-TRA', 'MOITÃO', '2024-08-22', '2024-08-26', 31, 9, '202400249262029', NULL, 39, NULL, 'MARÍTIMO'),
	('2310336557', 3, 'I-24/0782-BWL', 'ADM TEMP', '2024-05-15', '2024-05-22', NULL, 19, '202400237510057', NULL, 47, NULL, 'AÉREO'),
	('2225695775', 1, 'I-22/1926-MEG', 'PFWS22-4', '2022-12-27', '2022-12-30', 32, 16, '202200177701960', NULL, 48, NULL, 'MARÍTIMO'),
	('2300245000', 1, 'I-22/1689-MEG', 'WS22-3VEICULO', '2023-01-04', '2023-01-09', 33, 16, '202300178529346', NULL, 49, NULL, 'MARÍTIMO'),
	('1102552358', 1, 'I-10/1287-MEG', 'DIETHELM WS 102', '2011-02-09', '2011-02-14', NULL, 15, NULL, '10314.002198/2011-47', 50, NULL, 'MEIOS PRÓPRIOS'),
	('1102548903', 1, 'I-10/1199-MEG', 'DIETHELM WS 101', '2011-02-09', '2011-02-14', NULL, 15, NULL, '10314.002197/2011-01', 51, NULL, 'MEIOS PRÓPRIOS'),
	('1919661001', 1, 'I-19/1042-MEG', 'PFWS19-2', '2019-10-23', '2019-10-25', 34, 11, '201900055854940', '10010.079669/0919-44', 52, NULL, 'MARÍTIMO'),
	('2323396780', 1, 'I-23/1812-MEG', 'ADM', '2023-11-28', '2023-11-29', 35, 16, '202300217735169', NULL, 53, NULL, 'MARÍTIMO'),
	('2323376321', 1, 'I-23/1653-MEG', 'WS23-1', '2023-01-27', '2023-12-01', 36, 16, '202300217734367', NULL, 54, NULL, 'MARÍTIMO'),
	('2417609524', 1, 'I-24/0785-MEG', 'WS24-1', '2024-08-16', '2024-08-21', 37, 16, '202400248810936', NULL, 55, NULL, 'MARÍTIMO')

EXECUTE stp_inserirDadosNaTabelaDeclaracao @tInserirDados = @t_tempInserirDados;

DROP PROCEDURE stp_inserirDadosNaTabelaDeclaracao;
DROP TYPE dtInsertDataDeclaracaoTable;
DELETE FROM tDeclaracao;
ALTER SEQUENCE seqDeclaracaoID RESTART WITH 1;

SELECT * FROM tDeclaracao;