-- SCHEMA: dbUninaDelivery
CREATE SCHEMA "dbUninaDelivery";
SET search_path TO "dbUninaDelivery";

-- TABLE: Indirizzo
CREATE TABLE Indirizzo
(
	IDIndirizzo		SERIAL			PRIMARY KEY,
	Via 			VARCHAR(255) 	NOT NULL,
	Provincia 		CHAR(2) 		NOT NULL,
	Citta 			VARCHAR(255) 	NOT NULL,
	CAP 			CHAR(5) 		NOT NULL,
	NumeroCivico 	VARCHAR(3) 		NOT NULL
);

-- CONSTRAINTS: Indirizzo
ALTER TABLE Indirizzo
ADD	CONSTRAINT	isProvinciaValido		CHECK	(Indirizzo.Provincia ~ '^[A-Z]{2}$'),
ADD	CONSTRAINT	isCapValido				CHECK	(Indirizzo.CAP ~ '^[0-9]{5}$'),
ADD	CONSTRAINT	isNumeroCivicoValido	CHECK	(Indirizzo.NumeroCivico ~ '^[0-9]{1,3}$')
;

-- TABLE: Azienda
CREATE TABLE Azienda
(
	PartitaIva		CHAR(11) 		PRIMARY KEY,
	Nome 			VARCHAR(255) 	NOT NULL 	UNIQUE,
	NumeroTelefono 	CHAR(10) 		NOT NULL	UNIQUE,
	Mail 			VARCHAR(255) 	NOT NULL	UNIQUE,
	SitoWeb 		VARCHAR(255) 	NOT NULL	UNIQUE,
	CEO 			VARCHAR(255) 	NOT NULL,
	Slogan 			VARCHAR(1000),
	FormaSocietaria VARCHAR(10) 	NOT NULL,
	IDIndirizzo		INTEGER			NOT NULL
);

-- CONSTRAINTS: Azienda
ALTER TABLE Azienda
ADD	CONSTRAINT 	isPartitaIvaValida		CHECK	(Azienda.PartitaIva ~ '^[0-9]{11}$'),
ADD	CONSTRAINT 	isNumeroTelefonoValido 	CHECK 	(Azienda.NumeroTelefono ~ '^[0-9]{10}$'),
ADD	CONSTRAINT 	isMailValido			CHECK 	(Azienda.Mail ~ '^[A-Za-z0-9._%-]+@[A-Za-z0-9.-]+\.[A-Z|a-z]{2,4}$'),
ADD	CONSTRAINT 	isSitoWebValido			CHECK	(Azienda.SitoWeb ~ '^www.[A-Za-z0-9.-]+.[A-Z|a-z]{2,6}$'),
ADD CONSTRAINT	FK_Indirizzo_Azienda	FOREIGN KEY	(IDIndirizzo)	REFERENCES	Indirizzo (IDIndirizzo)
;

-- SEQUENCE: Matricola per Operatore e Corriere
CREATE SEQUENCE matricola_seq
AS INTEGER
MINVALUE 1000
START 1000;

-- TABLE: Operatore
CREATE TABLE Operatore
(
	Matricola		INTEGER			PRIMARY KEY DEFAULT nextval('matricola_seq'),
	Nome			VARCHAR(255)	NOT NULL,
	Cognome			VARCHAR(255)	NOT NULL,
	CodiceFiscale	CHAR(16)		NOT NULL UNIQUE,
	Eta				INTEGER			NOT NULL,
	Stipendio		NUMERIC			NOT NULL,
	PasswordOp		VARCHAR(255)	NOT NULL,
	DataNascita		DATE			NOT NULL,
	DataAssunzione	DATE			NOT NULL,
	PivaAzienda		CHAR(11)		NOT NULL
);

-- CONSTRAINTS: Operatore
ALTER TABLE Operatore
ADD	CONSTRAINT	isCodiceFiscaleValido	CHECK	(Operatore.CodiceFiscale ~ '^[A-Z]{6}[0-9]{2}[A-Z]{1}[0-9]{2}[A-Z]{1}[0-9]{3}[A-Z]{1}$'),
ADD	CONSTRAINT	isEtaValida			    CHECK	(Operatore.Eta BETWEEN 18 AND 67),
ADD	CONSTRAINT	isStipendioValido		CHECK	(Operatore.Stipendio > 0),
ADD	CONSTRAINT	isDataAssunzioneValida  CHECK	(Operatore.DataAssunzione > (Operatore.DataNascita + 6574)),
ADD CONSTRAINT	FK_Operatore_Azienda	FOREIGN KEY	(PivaAzienda) REFERENCES Azienda(PartitaIva) ON DELETE CASCADE
;

-- TABLE: Corriere
CREATE TABLE Corriere
(
	Matricola		INTEGER			PRIMARY KEY DEFAULT nextval('matricola_seq'),
	Nome			VARCHAR(255)	NOT NULL,
	Cognome			VARCHAR(255)	NOT NULL,
	CodiceFiscale	CHAR(16)		NOT NULL UNIQUE,
	Eta				INTEGER			NOT NULL,
	Stipendio		NUMERIC			NOT NULL,
	PasswordCr		VARCHAR(255)	NOT NULL,
	DataNascita		DATE			NOT NULL,
	DataAssunzione	DATE			NOT NULL,
	PivaAzienda		CHAR(11)		NOT NULL
);

-- CONSTRAINTS: Corriere
ALTER TABLE Corriere
ADD	CONSTRAINT	isCodiceFiscaleValido	CHECK	(Corriere.CodiceFiscale ~ '^[A-Z]{6}[0-9]{2}[A-Z]{1}[0-9]{2}[A-Z]{1}[0-9]{3}[A-Z]{1}$'),
ADD	CONSTRAINT	isEtaValida 			CHECK	(Corriere.Eta BETWEEN 18 AND 67),
ADD	CONSTRAINT	isStipendioValido		CHECK	(Corriere.Stipendio > 0),
ADD	CONSTRAINT	isDataAssunzioneValida  CHECK	(Corriere.DataAssunzione > (Corriere.DataNascita + 6574)),
ADD CONSTRAINT	FK_Corriere_Azienda		FOREIGN KEY	(PivaAzienda) REFERENCES Azienda(PartitaIva) ON DELETE CASCADE
;

-- TRIGGER E FUNCTION TRIGGER: Controlla Corriere Esistente
CREATE FUNCTION ControllaCorriereEsistente()
RETURNS TRIGGER
AS $$
DECLARE
BEGIN
	IF EXISTS (SELECT 1
				FROM Corriere
				WHERE Corriere.CodiceFiscale = NEW.CodiceFiscale)
	THEN
		RETURN NULL;
	END IF;
RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER TriggerControllaCorriereEsistente
BEFORE INSERT ON Operatore
FOR EACH ROW
EXECUTE PROCEDURE ControllaCorriereEsistente();

-- TRIGGER E FUNCTION TRIGGER: Controlla Operatore Esistente
CREATE FUNCTION ControllaOperatoreEsistente()
RETURNS TRIGGER
AS $$
DECLARE
BEGIN
	IF EXISTS (SELECT 1
				FROM Operatore
				WHERE Operatore.CodiceFiscale = NEW.CodiceFiscale)
	THEN
		RETURN NULL;
	END IF;
RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER TriggerControllaOperatoreEsistente
BEFORE INSERT ON Corriere
FOR EACH ROW
EXECUTE PROCEDURE ControllaOperatoreEsistente();


-- CREAZIONE TIPI ENUM: MezzoTrasporto
CREATE TYPE enum_veicolo AS ENUM('Furgone', 'Autocarro', 'Automobile', 'Motociclo');

-- TABLE: MezzoTrasporto
CREATE TABLE MezzoTrasporto
(
	Targa				CHAR(7)			PRIMARY KEY,
	Modello				VARCHAR(255)	NOT NULL,
	CapienzaPeso		NUMERIC			NOT NULL,
	CapienzaLitri		NUMERIC			NOT NULL,
	Marca				VARCHAR(255)	NOT NULL,
	Tipo				enum_veicolo	NOT NULL
);

-- CONSTRAINTS: MezzoTrasporto
ALTER TABLE MezzoTrasporto
ADD CONSTRAINT	isTargaValida			CHECK	(MezzoTrasporto.Targa ~ '^[A-Z]{2}[0-9]{3}[A-Z]{2}$'),
ADD CONSTRAINT	isCapienzaPesoValida	CHECK	(MezzoTrasporto.CapienzaPeso > 0),
ADD CONSTRAINT	isCapienzaLitriValida	CHECK	(MezzoTrasporto.CapienzaLitri > 0)
;

-- TABLE: Prodotto
CREATE TABLE Prodotto
(
	CodiceProdotto		SERIAL			PRIMARY KEY,
	Nome				VARCHAR(255)	NOT NULL,
	Prezzo				NUMERIC			NOT NULL,
	Peso				NUMERIC			NOT NULL,
	Categoria			VARCHAR(255)	NOT NULL,
	Descrizione			VARCHAR(1000)	NOT NULL
);

-- CONSTRAINTS: Prodotto
ALTER TABLE Prodotto
ADD CONSTRAINT	isPrezzoProdottoValido	CHECK	(Prodotto.Prezzo > 0),
ADD CONSTRAINT	isPesoProdottoValido	CHECK	(Prodotto.Peso > 0)
;

-- TABLE: Magazzino
CREATE TABLE Magazzino
(
	Numero			SERIAL			PRIMARY KEY,
	IDIndirizzo		INTEGER			NOT NULL
);

-- CONSTRAINTS: Magazzino
ALTER TABLE Magazzino
ADD CONSTRAINT	FK_Indirizzo_Magazzino	FOREIGN KEY	(IDIndirizzo)	REFERENCES	Indirizzo (IDIndirizzo)
;

-- CREAZIONE TIPO ENUM: Cliente
CREATE TYPE enum_cliente AS ENUM('Aziendale', 'Privato');
CREATE TYPE enum_ruolo AS ENUM('Mittente', 'Destinatario', 'MittenteDestinatario');

-- TABLE: Cliente
CREATE TABLE Cliente
(
	NumeroTelefono		CHAR(10)		PRIMARY KEY,
	Mail				VARCHAR(255)	NOT NULL UNIQUE,
	CodiceFiscale		CHAR(16)		UNIQUE,
	DataNascita			DATE,
	Nome				VARCHAR(255),
	Cognome				VARCHAR(255),
	NomeAzienda			VARCHAR(255)	UNIQUE,
	PartitaIva			CHAR(11)		UNIQUE,
	Tipo				enum_cliente	NOT NULL,
	Ruolo               enum_ruolo      NOT NULL,
	IDIndirizzo			INTEGER			NOT NULL
);

-- CONSTRAINTS: Cliente
ALTER TABLE Cliente
ADD	CONSTRAINT 	isNumeroTelefonoValido 		CHECK 	(Cliente.NumeroTelefono ~ '^[0-9]{10}$'),
ADD	CONSTRAINT 	isMailValido				CHECK 	(Cliente.Mail ~ '^[A-Za-z0-9._%-]+@[A-Za-z0-9.-]+\.[A-Z|a-z]{2,4}$'),
ADD	CONSTRAINT	isCodiceFiscaleValido		CHECK	(Cliente.CodiceFiscale ~ '^[A-Z]{6}[0-9]{2}[A-Z]{1}[0-9]{2}[A-Z]{1}[0-9]{3}[A-Z]{1}$'),
ADD	CONSTRAINT 	isPartitaIvaValida			CHECK	(Cliente.PartitaIva ~ '^[0-9]{11}$'),
ADD CONSTRAINT	CheckTipoCliente			CHECK	((Cliente.Tipo = 'Privato' AND Cliente.CodiceFiscale IS NOT NULL AND Cliente.DataNascita IS NOT NULL
													  AND Cliente.Nome IS NOT NULL AND Cliente.Cognome IS NOT NULL
													  AND Cliente.NomeAzienda IS NULL AND Cliente.PartitaIva IS NULL)
													OR (Cliente.Tipo = 'Aziendale' AND Cliente.CodiceFiscale IS NULL AND Cliente.DataNascita IS NULL
													  AND Cliente.Nome IS NULL AND Cliente.Cognome IS NULL AND
														Cliente.NomeAzienda IS NOT NULL AND Cliente.PartitaIva IS NOT NULL)),
ADD CONSTRAINT	FK_Indirizzo_Cliente		FOREIGN KEY	(IDIndirizzo)	REFERENCES	Indirizzo (IDIndirizzo)
;

-- TABLE: Ordine
CREATE TYPE enum_grandezze AS ENUM ('Piccolo', 'Medio', 'Grande');

CREATE TABLE Ordine
(
	NumeroOrdine		SERIAL			PRIMARY KEY,
	Peso				NUMERIC			NOT NULL DEFAULT 0,
	MetodoPagamento		VARCHAR(255)	NOT NULL,
	Grandezza			enum_grandezze	NOT NULL,
	Prezzo				NUMERIC			NOT NULL DEFAULT 0,
	DataOrdine			DATE			NOT NULL,
	NumeroTelefonoDt	CHAR(10)		NOT NULL,
	NumeroTelefonoMt	CHAR(10)		NOT NULL
);

--CONSTRAINTS: Ordine
ALTER TABLE Ordine
ADD CONSTRAINT	FK_Ordine_Destinatario	FOREIGN KEY	(NumeroTelefonoDt) REFERENCES Cliente(NumeroTelefono) ON DELETE CASCADE,
ADD CONSTRAINT	FK_Ordine_Mittente		FOREIGN KEY	(NumeroTelefonoMT) REFERENCES Cliente(NumeroTelefono) ON DELETE CASCADE
;

-- TABELLA PONTE Corriere-MezzoTrasporto: MezziInUso
CREATE TABLE MezziInUso
(
	MatricolaCorriere	INTEGER		NOT NULL,
	Targa				CHAR(7)		NOT NULL,
	DataUtilizzo		DATE		NOT NULL
)
;

-- CONSTRAINTS: MezziInUso
ALTER TABLE MezziInUso
ADD CONSTRAINT	FK_Corriere_MezziInUso			FOREIGN KEY (MatricolaCorriere)	REFERENCES Corriere(Matricola) ON DELETE CASCADE,
ADD CONSTRAINT	FK_MezzoTrasporto_MezziInUso	FOREIGN KEY (Targa)				REFERENCES MezzoTrasporto(Targa) ON DELETE CASCADE
;

-- TABELLA PONTE Ordine-Prodotto: ProdottiVenduti
CREATE TABLE ProdottiVenduti
(
	NumeroOrdine		INTEGER		NOT NULL,
	CodiceProdotto		INTEGER		NOT NULL,
	Quantita			INTEGER		NOT NULL
);

-- CONSTRAINTS: ProdottiVenduti
ALTER TABLE ProdottiVenduti
ADD CONSTRAINT	FK_Ordine_ProdottiVenduti	FOREIGN KEY (NumeroOrdine)		REFERENCES Ordine(NumeroOrdine) ON DELETE CASCADE,
ADD CONSTRAINT	FK_Prodotto_ProdottiVenduti	FOREIGN KEY (CodiceProdotto)	REFERENCES Prodotto(CodiceProdotto) ON DELETE CASCADE
;

-- TABELLA PONTE Magazzino-Prodotto: ProdottiDisponibili
CREATE TABLE ProdottiDisponibili
(
	NumeroMagazzino		INTEGER		NOT NULL,
	CodiceProdotto		INTEGER		NOT NULL,
	Disponibilita		INTEGER		NOT NULL	DEFAULT 0
);

-- CONSTRAINTS: ProdottiDisponibili
ALTER TABLE ProdottiDisponibili
ADD CONSTRAINT	FK_Magazzino_ProdottiDisponibili	FOREIGN KEY (NumeroMagazzino)	REFERENCES Magazzino(Numero) ON DELETE CASCADE,
ADD CONSTRAINT	FK_Prodotto_ProdottiDisponibili		FOREIGN KEY (CodiceProdotto)	REFERENCES Prodotto(CodiceProdotto) ON DELETE CASCADE
;



-- CREAZIONE TIPI ENUM: Spedizione
CREATE TYPE enum_stato AS ENUM('In preparazione', 'Spedito', 'In transito', 'Completato');
CREATE TYPE enum_porto AS ENUM('Franco', 'Assegnato');
CREATE TYPE enum_spedizione AS ENUM('Singola', 'Settimanale', 'Mensile', 'Annuale');

-- TABLE: Spedizione
CREATE TABLE Spedizione
(
	NumeroTracciamento		SERIAL				PRIMARY KEY,
	Descrizione				VARCHAR(1000),
	Stato					enum_stato 			NOT NULL DEFAULT 'In preparazione',
	DataAffidamento			DATE				NOT NULL DEFAULT CURRENT_DATE,
	DataPrevista			DATE				NOT NULL,
	DataConsegna			DATE,
	PrezzoSpedizione		NUMERIC				NOT NULL,
	Porto					enum_porto			NOT NULL,
	Tipo					enum_spedizione		NOT NULL,
	MatricolaOperatore		INTEGER				NOT NULL,				
	MatricolaCorriere		INTEGER				NOT NULL,				
	TargaTrasporto			CHAR(7)				NOT NULL,				
	NumeroOrdine			INTEGER				NOT NULL
);

-- CONSTRAINTS: Spedizione
ALTER TABLE Spedizione
ADD CONSTRAINT	checkSpedizioneCompletata	CHECK	((Spedizione.Stato = 'Completato' AND Spedizione.DataConsegna IS NOT NULL) OR 
														(Spedizione.Stato <> 'Completato' AND Spedizione.DataConsegna IS NULL)),
ADD CONSTRAINT	FK_Spedizione_Operatore		FOREIGN KEY	(MatricolaOperatore) REFERENCES Operatore(Matricola) ON DELETE CASCADE,
ADD CONSTRAINT	FK_Spedizione_Corriere		FOREIGN KEY	(MatricolaCorriere) REFERENCES Corriere(Matricola) ON DELETE CASCADE,
ADD CONSTRAINT	FK_Spedizione_MezzoTrasporto FOREIGN KEY (TargaTrasporto) REFERENCES MezzoTrasporto(Targa) ON DELETE CASCADE,
ADD CONSTRAINT	FK_Spedizione_Ordine		FOREIGN KEY	(NumeroOrdine)	REFERENCES Ordine(NumeroOrdine) ON DELETE CASCADE
;

-- TRIGGER E FUNCTION TRIGGER: Spedizione
CREATE FUNCTION CheckIntervalloData()
RETURNS TRIGGER
AS $$
DECLARE
	Controllo	INTEGER;
BEGIN
	IF (NEW.DataAffidamento > NEW.DataPrevista) THEN
		RETURN NULL;
	END IF;
	
	IF (NEW.DataAffidamento > COALESCE(NEW.DataConsegna, NEW.DataPrevista)) THEN
		RETURN NULL;
	END IF;

	SELECT COUNT(*)
		INTO Controllo
		FROM Ordine AS O
		WHERE O.NumeroOrdine = NEW.NumeroOrdine AND NEW.DataAffidamento >= O.DataOrdine;
	
	IF controllo = 0 THEN
		RETURN NULL;
	END IF;

	RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER TriggerControllaDataSpedizione
BEFORE INSERT ON Spedizione
FOR EACH ROW
EXECUTE PROCEDURE CheckIntervalloData();

-- TRIGGER E FUNCTION TRIGGER: Spedizione Programmata
CREATE FUNCTION CreaOrdineProgrammato()
RETURNS TRIGGER
AS $$
DECLARE
	quanto_aggiungere 		INTEGER;
	OrdineSucc				INTEGER;
	recupera_prodotti		CURSOR FOR SELECT	CodiceProdotto, Quantita
										FROM	ProdottiVenduti
										WHERE	NumeroOrdine = NEW.NumeroOrdine;
BEGIN
	IF (NEW.tipo = 'Settimanale') THEN
		quanto_aggiungere := 7;
	ELSIF (NEW.tipo = 'Mensile') THEN
		quanto_aggiungere := 28;
	ELSIF (NEW.tipo = 'Annuale') THEN
		quanto_aggiungere := 365;
	END IF;
	
	INSERT INTO Ordine (NumeroOrdine, Peso, MetodoPagamento, Grandezza, Prezzo, DataOrdine, NumeroTelefonoDt, NumeroTelefonoMT)
	(SELECT NEXTVAL('ordine_numeroordine_seq'), 0, MetodoPagamento, Grandezza, 0, CURRENT_DATE, NumeroTelefonoDt, NumeroTelefonoMT
		FROM Ordine
		WHERE NumeroOrdine = NEW.NumeroOrdine);
	
	FOR prodotto_corrente IN recupera_prodotti
	LOOP
		INSERT INTO ProdottiVenduti (NumeroOrdine, CodiceProdotto, Quantita)
		VALUES (LASTVAL(), prodotto_corrente.CodiceProdotto, prodotto_corrente.Quantita);
	END LOOP;
	
	INSERT INTO Spedizione (NumeroTracciamento, Descrizione, Stato, DataAffidamento, DataPrevista, DataConsegna, PrezzoSpedizione, Porto, Tipo, MatricolaOperatore, MatricolaCorriere, TargaTrasporto, NumeroOrdine)
	VALUES (NEXTVAL('spedizione_numerotracciamento_seq'), NEW.Descrizione, 'In preparazione', CURRENT_DATE, NEW.DataPrevista + quanto_aggiungere, NULL, NEW.prezzospedizione, NEW.Porto, NEW.Tipo,
			NEW.MatricolaOperatore, NEW.MatricolaCorriere, NEW.TargaTrasporto, CURRVAL('ordine_numeroordine_seq'));
RETURN NULL;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER TriggerSpedizioneProgrammata
AFTER UPDATE ON Spedizione
FOR EACH ROW
WHEN (OLD.Tipo <> 'Singola' AND NEW.Stato = 'Completato')
EXECUTE PROCEDURE CreaOrdineProgrammato();

-- TRIGGER E FUNCTION TRIGGER: Controllo Nuova Spedizione
CREATE FUNCTION ControllaDisponibilitaMerci()
RETURNS TRIGGER
AS $$
DECLARE
	recupera_prodotti		CURSOR FOR SELECT	CodiceProdotto, Quantita
										FROM	ProdottiVenduti
										WHERE	NumeroOrdine = NEW.NumeroOrdine;
	prodotto_corrente		RECORD;
BEGIN
	OPEN recupera_prodotti;
	LOOP
		FETCH recupera_prodotti INTO prodotto_corrente;
		EXIT WHEN NOT FOUND;
		IF prodotto_corrente.Quantita > (SELECT SUM(Disponibilita)
											FROM ProdottiDisponibili AS PD
											WHERE PD.CodiceProdotto = prodotto_corrente.CodiceProdotto
											GROUP BY PD.CodiceProdotto)
		THEN
			CLOSE recupera_prodotti;
			RETURN NULL;
		END IF;
	END LOOP;
	CLOSE recupera_prodotti;
RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER TriggerNuovaSpedizioneBefore
BEFORE INSERT ON Spedizione
FOR EACH ROW
EXECUTE PROCEDURE ControllaDisponibilitaMerci();

-- TRIGGER E FUNCTION TRIGGER: Aggiorna Disponibilita Merci
CREATE OR REPLACE FUNCTION AggiornaDisponibilitaMerci()
RETURNS TRIGGER
AS $$
DECLARE
	quanto_sottrarre		INTEGER;
	recupera_prodotti		CURSOR FOR SELECT	CodiceProdotto, Quantita
										FROM	ProdottiVenduti
										WHERE	NumeroOrdine = NEW.NumeroOrdine;
	scorri_magazzini		REFCURSOR;
	magazzino_corrente		RECORD;
BEGIN
	FOR prodotto_corrente IN recupera_prodotti
	LOOP
		quanto_sottrarre := prodotto_corrente.Quantita;
		OPEN scorri_magazzini FOR SELECT NumeroMagazzino, CodiceProdotto, Disponibilita
									FROM ProdottiDisponibili AS PD
									WHERE PD.CodiceProdotto = prodotto_corrente.CodiceProdotto
									ORDER BY Disponibilita DESC;
		LOOP
			FETCH scorri_magazzini INTO magazzino_corrente;
			EXIT WHEN NOT FOUND;
			IF quanto_sottrarre <= magazzino_corrente.Disponibilita THEN

				UPDATE ProdottiDisponibili
				SET Disponibilita = Disponibilita - quanto_sottrarre
				WHERE NumeroMagazzino = magazzino_corrente.NumeroMagazzino AND CodiceProdotto = magazzino_corrente.CodiceProdotto;

				quanto_sottrarre := 0;
			ELSE
				quanto_sottrarre := quanto_sottrarre - magazzino_corrente.Disponibilita;

				UPDATE ProdottiDisponibili
				SET Disponibilita = 0
				WHERE NumeroMagazzino = magazzino_corrente.NumeroMagazzino AND CodiceProdotto = magazzino_corrente.CodiceProdotto;
			END IF;
			EXIT WHEN quanto_sottrarre = 0;
		END LOOP;
		CLOSE scorri_magazzini;
	END LOOP;
RETURN NULL;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE TRIGGER TriggerNuovaSpedizioneAfter
AFTER INSERT ON Spedizione
FOR EACH ROW
EXECUTE PROCEDURE AggiornaDisponibilitaMerci();

-- TRIGGER E FUNCTION TRIGGER: CalcolaSpecificheOrdine
CREATE FUNCTION CalcolaSpecificheOrdine()
RETURNS TRIGGER
AS $$
DECLARE
	prezzo_da_aggiungere	NUMERIC;
	peso_da_aggiungere		NUMERIC;
BEGIN
	SELECT Prezzo, Peso
	INTO prezzo_da_aggiungere, peso_da_aggiungere 
	FROM Prodotto
	WHERE CodiceProdotto = NEW.CodiceProdotto;

	prezzo_da_aggiungere := prezzo_da_aggiungere * NEW.Quantita;
	peso_da_aggiungere := peso_da_aggiungere * NEW.Quantita;

	UPDATE Ordine
	SET Prezzo = Prezzo + prezzo_da_aggiungere,
		Peso = Peso + peso_da_aggiungere
	WHERE NumeroOrdine = NEW.NumeroOrdine;
RETURN NULL;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER TriggerSpecificheOrdine
AFTER INSERT ON ProdottiVenduti
FOR EACH ROW
EXECUTE PROCEDURE CalcolaSpecificheOrdine();

-- TRIGGER E FUNCTION TRIGGER: ControllaOrdineTipoCliente
CREATE FUNCTION ControllaOrdineTipoCliente()
RETURNS TRIGGER
AS $$
DECLARE
	tipoCliente	VARCHAR(50);
BEGIN
	SELECT tipo
	INTO tipoCliente
	FROM Cliente
	WHERE NumeroTelefono = NEW.NumeroTelefonoDT;

	IF (tipoCliente = 'Mittente') THEN
		RETURN NULL;
	END IF;

	SELECT tipo
	INTO tipoCliente
	FROM Cliente
	WHERE NumeroTelefono = NEW.NumeroTelefonoMT;

	IF (tipoCliente = 'Destinatario') THEN
		RETURN NULL;
	END IF;

RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER TriggerControllaOrdineTipoCliente
BEFORE INSERT ON Ordine
FOR EACH ROW
EXECUTE PROCEDURE ControllaOrdineTipoCliente();
