CREATE DATABASE FormularioObito;
USE FormularioObito;

CREATE TABLE DECLARACAO_OBITO (
    numero_do_obito INT PRIMARY KEY
);

CREATE TABLE CARTORIO (
    id_cartorio      INT PRIMARY KEY,
    nome_cartorio      VARCHAR(64),
    cod_cartorio       VARCHAR(20),
    numero_registro    INT,
    registro           DATE,
    municipio_cartorio VARCHAR(64),
    uf_cartorio        VARCHAR(2),
    nome_cemiterio     VARCHAR(64)
);

CREATE TABLE RESIDENCIA_FALECIDO (
    id_residencia        INT PRIMARY KEY,
    logradouro           VARCHAR(128),
    cep_residencia       VARCHAR(16),
    bairro_distrito      VARCHAR(32),
    municipio_residencia VARCHAR(64),
    cod_municipio        VARCHAR(7),
    uf_residencia        VARCHAR(2)
);

CREATE TABLE LOCAL_OCORRENCIA (
    id_ocorrencia            INT PRIMARY KEY,
    local_ocorrencia         ENUM('Hospital','Outros Estab. Saúde','Domicilio','Via Publica','Outros','Ignorado'),
    nome_estabelecimento     VARCHAR(64),
    cod_estabelecimento      VARCHAR(20),
    endereco_ocorrencia      VARCHAR(64),
    cep_ocorrencia           VARCHAR(16),
    bairro_ocorrencia        VARCHAR(32),
    municipio_ocorrencia     VARCHAR(64),
    cod_municipio_ibge_ocorr VARCHAR(7),
    uf_ocorrencia            VARCHAR(2)
);
 
CREATE TABLE MEDICO (
    crm                  INT PRIMARY KEY,
    nome_medico          VARCHAR(64),
    atendimento_falecido ENUM('Sim','Substituto','IML','SVO','Outros'),
    condicao_atestante   VARCHAR(64),
    meio_contato         VARCHAR(64),
    data_atestado        DATE
);
 
CREATE TABLE FALECIDO (
    id_falecido       INT PRIMARY KEY,
    tipo_obito        ENUM('Fetal','Não fetal'),
    data_obito        DATE,
    hora_obito        TIME,
    ric               VARCHAR(16),
    naturalidade      VARCHAR(64),
    nome_falecido     VARCHAR(64),
    nome_pai          VARCHAR(64),
    nome_mae          VARCHAR(64),
    data_nascimento   DATE,
    idade             VARCHAR(64),
    sexo              ENUM('Masculino','Feminino','Ignorado'),
    raca_cor          ENUM('Branca','Preta','Amarela','Parda','Indigena'),
    estado_civil      ENUM('Solteiro','Casado','Viúvo','Separado Judicialmente','União Consensual','Ignorado'),
    escolaridade      ENUM('Nenhuma','De 1 a 3','De 4 a 7','De 8 a 11','12 e Mais','Ignorado'),
    ocupacao_habitual VARCHAR(64),
    numero_do_obito   INT,
    id_cartorio       INT,
    crm               INT,
    id_residencia     INT,
    id_ocorrencia     INT,
    FOREIGN KEY (numero_do_obito) REFERENCES DECLARACAO_OBITO(numero_do_obito),
    FOREIGN KEY (id_cartorio)     REFERENCES CARTORIO(id_cartorio),
    FOREIGN KEY (crm)             REFERENCES MEDICO(crm),
    FOREIGN KEY (id_residencia)   REFERENCES RESIDENCIA_FALECIDO(id_residencia),
    FOREIGN KEY (id_ocorrencia)   REFERENCES LOCAL_OCORRENCIA(id_ocorrencia)
);

CREATE TABLE INF_MAE (
    id_dados_mae             INT PRIMARY KEY,
    idade_mae                INT,
    escolaridade_mae         ENUM('Nenhuma','1 a 3','4 a 7','8 a 11','12 mais','Ignorado'),
    ocupacao_mae             VARCHAR(64),
    duracao_gestacao_semanas ENUM('Menos de 22','De 22 a 27','De 28 a 31','De 32 a 36','De 37 a 41','42 e mais','Ignorado'),
    tipo_gravidez            ENUM('Única','Dupla','Tripla e mais','Ignorada'),
    tipo_parto               ENUM('Vaginal','Cesáreo','Ignorado'),
    id_falecido              INT UNIQUE,
    FOREIGN KEY (id_falecido) REFERENCES FALECIDO(id_falecido)
);
 
CREATE TABLE NUMFILHOS (
    id_numfilhos    INT PRIMARY KEY,
    NascidosVivos   INT,
    NascidosMortos  INT,
    abortos         INT,
    id_dados_mae    INT UNIQUE,
    FOREIGN KEY (id_dados_mae) REFERENCES INF_MAE(id_dados_mae)
);
 
CREATE TABLE FETAL (
    id_fetal                 INT PRIMARY KEY,
    MorteRelParto            ENUM('Antes','Durante','Depois','Ignorado'),
    PesoNasc                 INT,
    numero_decl_nascido_vivo VARCHAR(20),
    id_falecido              INT UNIQUE,
    FOREIGN KEY (id_falecido) REFERENCES FALECIDO(id_falecido)
);

CREATE TABLE OBITOS_MULHERES (
    id_obito_mulheres INT PRIMARY KEY,
    dur_gravidez_p_a  ENUM('Sim','Não','Ignorado'),
    dur_puerperio     ENUM('Sim, Até 42 dias','Sim, 43 dias a 1 ano','Não','Ignorado'),
    id_falecido       INT UNIQUE,
    FOREIGN KEY (id_falecido) REFERENCES FALECIDO(id_falecido)
);

CREATE TABLE CAUSA_MORTE (
    id_causa           INT PRIMARY KEY,
    assistencia_medica ENUM('Sim','Não','Ignorado'),
    id_falecido        INT UNIQUE,
    FOREIGN KEY (id_falecido) REFERENCES FALECIDO(id_falecido)
);
 
CREATE TABLE DIAGNOSTICO (
    id_diagnostico  INT PRIMARY KEY,
    ExameComp       ENUM('Sim','Não','Ignorado'),
    Cirurgia        ENUM('Sim','Não','Ignorado'),
    Necropsia       ENUM('Sim','Não','Ignorado'),
    id_causa        INT,
    FOREIGN KEY (id_causa)     REFERENCES CAUSA_MORTE(id_causa)
);

CREATE TABLE CAUSAMORTE_PT1 (
    id_causa_pt1    INT PRIMARY KEY,
    CausaAnteced    VARCHAR(300),
    CID             VARCHAR(16),
    TempoAnteced    VARCHAR(50),
    id_causa        INT,
    FOREIGN KEY (id_causa)     REFERENCES CAUSA_MORTE(id_causa)
);

CREATE TABLE CAUSAMORTE_PT2 (
    id_causa_pt2    INT PRIMARY KEY,
    CausaAnteced2   VARCHAR(300),
    Parte2_tempo    VARCHAR(50),
    parte2_cid10    VARCHAR(100),
    id_causa        INT,
    FOREIGN KEY (id_causa)     REFERENCES CAUSA_MORTE(id_causa)
);
 
CREATE TABLE CAUSA_EXTERNA (
    id_causa_externa         INT PRIMARY KEY,
    tipo_morte_nao_natural   ENUM('Acidente','Suicídio','Homicídio','Outros','Ignorado'),
    acidente_trabalho        ENUM('Sim','Não','Ignorado'),
    fonte_informacao         ENUM('Boletim de Ocorrência','Hospital','Família','Outra','Ignorada'),
    descricao_sumaria_evento VARCHAR(256),
    id_falecido              INT UNIQUE,
    FOREIGN KEY (id_falecido) REFERENCES FALECIDO(id_falecido)
);
 
CREATE TABLE OCORRENCIA_VIA_PUBLICA (
    id_ocorr_via_pub         INT PRIMARY KEY,
    Logradouro               VARCHAR(64),
    Cod                      INT,
    id_causa_externa         INT,
    FOREIGN KEY (id_causa_externa) REFERENCES CAUSA_EXTERNA(id_causa_externa)
);
 
CREATE TABLE LOCALIDADE_SEM_MEDICO (
    id_sem_medico         INT PRIMARY KEY,
    nome_declarante       VARCHAR(64),
    assinatura_declarante VARCHAR(64),
    testemunha1           VARCHAR(64),
    testemunha2           VARCHAR(64),
    id_falecido           INT UNIQUE,
    FOREIGN KEY (id_falecido) REFERENCES FALECIDO(id_falecido)
);

-- Populando o Banco de dados 
USE FormularioObito;

INSERT INTO DECLARACAO_OBITO (numero_do_obito) VALUES
	(1001), 
    (1002), 
    (1003), 
    (1004), 
    (1005);

INSERT INTO CARTORIO (id_cartorio, nome_cartorio, cod_cartorio, numero_registro, registro, municipio_cartorio, uf_cartorio, nome_cemiterio) VALUES
	(1, 'Cartório Silva', 'CRT123', 5543, '2026-02-15', 'São Paulo', 'SP', 'Cemitério da Consolação'),
	(2, 'Cartório Central', 'CRT998', 1122, '2026-03-20', 'Rio de Janeiro', 'RJ', 'Cemitério São João Batista');

INSERT INTO RESIDENCIA_FALECIDO (id_residencia, logradouro, cep_residencia, bairro_distrito, municipio_residencia, cod_municipio, uf_residencia) VALUES
	(10, 'Rua das Flores, 123', '01234-000', 'Centro', 'São Paulo', '3550308', 'SP'),
	(20, 'Av. Atlântica, 456', '22020-001', 'Copacabana', 'Rio de Janeiro', '3304557', 'RJ'),
	(30, 'Rua Piauí, 78', '30150-120', 'Funcionários', 'Belo Horizonte', '3106200', 'MG');

INSERT INTO LOCAL_OCORRENCIA (id_ocorrencia, local_ocorrencia, nome_estabelecimento, cod_estabelecimento, endereco_ocorrencia, cep_ocorrencia, bairro_ocorrencia, municipio_ocorrencia, cod_municipio_ibge_ocorr, uf_ocorrencia) VALUES
	(100, 'Hospital', 'Hospital das Clínicas', 'HOSP776', 'Av. Enéas de Carvalho, 255', '05403-000', 'Pinheiros', 'São Paulo', '3550308', 'SP'),
	(200, 'Via Publica', NULL, NULL, 'Av. Brasil, km 12', '21040-361', 'Bonsucesso', 'Rio de Janeiro', '3304557', 'RJ'),
	(300, 'Domicilio', NULL, NULL, 'Rua das Flores, 123', '01234-000', 'Centro', 'São Paulo', '3550308', 'SP');

INSERT INTO MEDICO (crm, nome_medico, atendimento_falecido, condicao_atestante, meio_contato, data_atestado) VALUES
	(123456, 'Dr. Roberto Almeida', 'Sim', 'Médico Assistente', 'roberto@email.com', '2026-02-14'),
	(654321, 'Dra. Sandra Souza', 'IML', 'Médico Legista', 'sandra.iml@email.com', '2026-03-19');

INSERT INTO FALECIDO (id_falecido, tipo_obito, data_obito, hora_obito, ric, naturalidade, nome_falecido, nome_pai, nome_mae, data_nascimento, idade, sexo, raca_cor, estado_civil, escolaridade, ocupacao_habitual, numero_do_obito, id_cartorio, crm, id_residencia, id_ocorrencia) VALUES
	(1, 'Não fetal', '2026-02-14', '08:30:00', 'RIC111', 'São Paulo', 'Carlos Alberto Souza', 'José Souza', 'Maria Souza', '1955-05-12', '70 anos', 'Masculino', 'Branca', 'Casado', 'De 8 a 11', 'Aposentado', 1001, 1, 123456, 10, 100),
	(2, 'Não fetal', '2026-03-19', '23:15:00', 'RIC222', 'Niterói', 'Marcos Pereira Lima', 'Antônio Lima', 'Julia Pereira', '1988-09-24', '37 anos', 'Masculino', 'Parda', 'Solteiro', '12 e Mais', 'Engenheiro', 1002, 2, 654321, 20, 200),
	(3, 'Fetal', '2026-02-20', '02:10:00', NULL, 'São Paulo', 'Recém-nascido de Ana', 'Paulo Ramos', 'Ana Lucas Ramos', '2026-02-20', '0 dias', 'Masculino', 'Branca', 'Solteiro', 'Nenhuma', 'Nenhuma', 1003, 1, 123456, 10, 100),
	(4, 'Não fetal', '2026-04-05', '14:40:00', 'RIC444', 'Belo Horizonte', 'Mariana Oliveira Reis', 'Carlos Reis', 'Beatriz Oliveira', '1996-07-18', '29 anos', 'Feminino', 'Preta', 'União Consensual', '12 e Mais', 'Advogada', 1004, 2, 123456, 30, 100),
	(5, 'Fetal', '2026-05-12', '18:25:00', NULL, 'Rio de Janeiro', 'Natália Novaes (Fetal)', NULL, 'Carla Novaes', NULL, '0 dias', 'Feminino', 'Amarela', 'Solteiro', 'Nenhuma', 'Nenhuma', 1005, 2, 123456, 20, 100);

INSERT INTO INF_MAE (id_dados_mae, idade_mae, escolaridade_mae, ocupacao_mae, duracao_gestacao_semanas, tipo_gravidez, tipo_parto, id_falecido) VALUES
	(501, 28, '8 a 11', 'Vendedora', 'De 37 a 41', 'Única', 'Vaginal', 3),
	(502, 34, '12 mais', 'Autônoma', 'De 32 a 36', 'Única', 'Cesáreo', 5);

INSERT INTO NUMFILHOS (id_numfilhos, NascidosVivos, NascidosMortos, abortos, id_dados_mae) VALUES
	(601, 2, 0, 0, 501),
	(602, 0, 1, 1, 502);

INSERT INTO FETAL (id_fetal, MorteRelParto, PesoNasc, numero_decl_nascido_vivo, id_falecido) VALUES
	(701, 'Depois', 3150, 'NV-998877', 3),
	(702, 'Antes', 1800, NULL, 5);

INSERT INTO OBITOS_MULHERES (id_obito_mulheres, dur_gravidez_p_a, dur_puerperio, id_falecido) VALUES
	(801, 'Não', 'Sim, Até 42 dias', 4);

INSERT INTO CAUSA_MORTE (id_causa, assistencia_medica, id_falecido) VALUES
	(901, 'Sim', 1),
	(902, 'Não', 2),
	(903, 'Sim', 3),
	(904, 'Sim', 4),
	(905, 'Sim', 5);

INSERT INTO DIAGNOSTICO (id_diagnostico, ExameComp, Cirurgia, Necropsia, id_causa) VALUES
	(11, 'Sim', 'Não', 'Não', 901),
	(22, 'Não', 'Não', 'Sim', 902);

INSERT INTO CAUSAMORTE_PT1 (id_causa_pt1, CausaAnteced, CID, TempoAnteced, id_causa) VALUES
	(111, 'Infarto Agudo do Miocárdio', 'I21.9', '2 horas', 901),
	(222, 'Traumatismo Cranioencefálico', 'S06.9', 'Instantanêo', 902),
	(333, 'Insuficiência Respiratória Neonatal', 'P28.5', '30 minutos', 903);

INSERT INTO CAUSA_EXTERNA (id_causa_externa, tipo_morte_nao_natural, acidente_trabalho, fonte_informacao, descricao_sumaria_evento, id_falecido) VALUES
	(401, 'Acidente', 'Não', 'Boletim de Ocorrência', 'Colisão carro contra poste em via pública', 2);

INSERT INTO OCORRENCIA_VIA_PUBLICA (id_ocorr_via_pub, Logradouro, Cod, id_causa_externa) VALUES
	(51, 'Avenida Brasil', 9901, 401);
    
SELECT * FROM Falecido;