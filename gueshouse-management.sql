-------------------------------------------------------------
-- 1. Verificare disponibilitate cameră (cursor explicit)
-------------------------------------------------------------
DECLARE
    v_id_camera INT;
    v_data_inceput DATE := TO_DATE('2023-04-15', 'YYYY-MM-DD');
    v_data_sfarsit DATE := TO_DATE('2023-04-20', 'YYYY-MM-DD');
    v_camera_disponibila BOOLEAN := TRUE;

    CURSOR c_rezervari_camera IS
        SELECT ID_Rezervare
        FROM REZERVARI
        WHERE ID_Camera = v_id_camera
        AND (DataInceput BETWEEN v_data_inceput AND v_data_sfarsit
             OR DataSfarsit BETWEEN v_data_inceput AND v_data_sfarsit);
BEGIN
    DBMS_OUTPUT.PUT_LINE('Introduceti ID-ul camerei:');
    v_id_camera := &v_id_camera; 

    OPEN c_rezervari_camera;
    FETCH c_rezervari_camera INTO v_id_camera;
    IF c_rezervari_camera%FOUND THEN
        v_camera_disponibila := FALSE;
        DBMS_OUTPUT.PUT_LINE('Camera nu este disponibila in intervalul specificat.');
    ELSE
        DBMS_OUTPUT.PUT_LINE('Camera este disponibila.');
    END IF;
    CLOSE c_rezervari_camera;
END;
/

-------------------------------------------------------------
-- 2. Rezervările și plățile unui client
-------------------------------------------------------------
DECLARE
    v_id_client CLIENTI.ID_Client%TYPE;
    v_nume CLIENTI.Nume%TYPE;
    v_prenume CLIENTI.Prenume%TYPE;

    CURSOR client_rezervari_plati_cursor IS 
        SELECT r.ID_Rezervare, r.DataInceput, r.DataSfarsit, p.Suma
        FROM REZERVARI r
        JOIN PLATI p ON r.ID_Rezervare = p.ID_Rezervare
        WHERE r.ID_Client = v_id_client;
BEGIN
    DBMS_OUTPUT.PUT_LINE('Introduceti ID-ul clientului:');
    v_id_client := &id_client; 

    SELECT Nume, Prenume INTO v_nume, v_prenume
    FROM CLIENTI
    WHERE ID_Client = v_id_client;

    DBMS_OUTPUT.PUT_LINE('Rezervari si plati pentru clientul ' || v_nume || ' ' || v_prenume || ':');
    FOR rec IN client_rezervari_plati_cursor LOOP
        DBMS_OUTPUT.PUT_LINE('Rezervarea ' || rec.ID_Rezervare ||
                             ' (' || TO_CHAR(rec.DataInceput, 'dd-mm-yyyy') ||
                             ' - ' || TO_CHAR(rec.DataSfarsit, 'dd-mm-yyyy') ||
                             '), Suma: ' || rec.Suma);
    END LOOP;
EXCEPTION
    WHEN NO_DATA_FOUND THEN
        DBMS_OUTPUT.PUT_LINE('Nu exista date pentru clientul introdus.');
END;
/

-------------------------------------------------------------
-- 3. Cursor pentru clienții care au plătit cu cardul
-------------------------------------------------------------
DECLARE
    CURSOR c_plati_card IS
        SELECT c.Nume, c.Prenume
        FROM CLIENTI c
        JOIN REZERVARI r ON c.ID_Client = r.ID_Client
        JOIN PLATI p ON r.ID_Rezervare = p.ID_Rezervare
        WHERE p.Modalitate = 'Card';
BEGIN
    FOR client IN c_plati_card LOOP
        DBMS_OUTPUT.PUT_LINE('Clientul ' || client.Nume || ' ' || client.Prenume || ' a efectuat o plata cu cardul.');
    END LOOP;
END;
/

-------------------------------------------------------------
-- 4. Reducere plăți în funcție de sumă
-------------------------------------------------------------
DECLARE
    v_id_rezervare NUMBER;
    v_suma_initiala NUMBER;
    v_noua_suma NUMBER;
BEGIN
    DBMS_OUTPUT.PUT_LINE('Introduceti ID-ul rezervarii pentru actualizare:');
    v_id_rezervare := &id_rezervare;

    SELECT Suma INTO v_suma_initiala FROM PLATI WHERE ID_Rezervare = v_id_rezervare;

    IF v_suma_initiala > 1000 THEN
        v_noua_suma := v_suma_initiala * 0.9;
    ELSIF v_suma_initiala > 500 THEN
        v_noua_suma := v_suma_initiala * 0.95;
    ELSE
        v_noua_suma := v_suma_initiala;
    END IF;

    UPDATE PLATI SET Suma = v_noua_suma WHERE ID_Rezervare = v_id_rezervare;

    DBMS_OUTPUT.PUT_LINE('ID rezervare: ' || v_id_rezervare);
    DBMS_OUTPUT.PUT_LINE('Suma initiala: ' || v_suma_initiala);
    DBMS_OUTPUT.PUT_LINE('Noua suma: ' || v_noua_suma);
END;
/

-------------------------------------------------------------
-- 5. Afișarea tuturor camerelor
-------------------------------------------------------------
DECLARE
    CURSOR camere_cursor IS SELECT PretNoapte, NumarCamera, Tip FROM CAMERE;
    v_pretNoapte CAMERE.PretNoapte%TYPE;
    v_numarCamera CAMERE.NumarCamera%TYPE;
    v_tip CAMERE.Tip%TYPE;
BEGIN
    OPEN camere_cursor;
    FETCH camere_cursor INTO v_pretNoapte, v_numarCamera, v_tip;
    WHILE camere_cursor%FOUND LOOP
        DBMS_OUTPUT.PUT_LINE('Numar: ' || v_numarCamera || ', Tip: ' || v_tip || ', Pret: ' || v_pretNoapte);
        FETCH camere_cursor INTO v_pretNoapte, v_numarCamera, v_tip;
    END LOOP;
    CLOSE camere_cursor;
END;
/

-------------------------------------------------------------
-- EXCEPTII
-------------------------------------------------------------
-- 1. Reducere cu excepție
SET SERVEROUTPUT ON
DECLARE
    plata_exception EXCEPTION;
BEGIN
    UPDATE PLATI
    SET SUMA = SUMA - 0.1
    WHERE ID_Rezervare = &id;
    IF SQL%NOTFOUND THEN
        RAISE plata_exception;
    ELSE 
        DBMS_OUTPUT.PUT_LINE('S-a aplicat reducerea');
    END IF;
EXCEPTION 
    WHEN plata_exception THEN
        DBMS_OUTPUT.PUT_LINE('NU S-A APLICAT NICIO REDUCERE');
END;
/

-- 2. Actualizare preț cameră + excepții
DECLARE
    invalid_camera EXCEPTION;
BEGIN
    UPDATE CAMERE SET PretNoapte = 450 WHERE ID_Camera = 11;
    IF SQL%NOTFOUND THEN
        RAISE invalid_camera;
    END IF;
EXCEPTION
    WHEN invalid_camera THEN
        DBMS_OUTPUT.PUT_LINE('Nu exista camera cu acest ID');
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('Eroare la actualizare pret camera');
END;
/

-- 3. Căutare client "Doe"
DECLARE
    CURSOR curs_client IS SELECT ID_Client FROM CLIENTI WHERE Nume = 'Doe';
    id_client_negasit EXCEPTION;
    id_client_val INT;
BEGIN
    OPEN curs_client;
    FETCH curs_client INTO id_client_val;
    IF curs_client%NOTFOUND THEN
        RAISE id_client_negasit;
    END IF;
    CLOSE curs_client;
EXCEPTION
    WHEN id_client_negasit THEN
        DBMS_OUTPUT.PUT_LINE('Clientul Doe nu a fost gasit.');
    WHEN NO_DATA_FOUND THEN
        DBMS_OUTPUT.PUT_LINE('Niciun rand nu corespunde criteriului.');
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('A aparut o alta eroare!');
END;
/

-- 4. Verificare preț cameră > 800
DECLARE
    valoare_invalida EXCEPTION;
    pret_camera DECIMAL(10,2) := 1000;
BEGIN
    IF pret_camera > 800 THEN
        RAISE valoare_invalida;
    END IF;
EXCEPTION
    WHEN valoare_invalida THEN
        DBMS_OUTPUT.PUT_LINE('Pretul camerei depaseste limita admisa.');
END;
/

-------------------------------------------------------------
-- CURSORI EXPLICITI SI IMPLICITI
-------------------------------------------------------------
-- Cursor explicit fără parametri
DECLARE
    CURSOR c_camere IS SELECT * FROM CAMERE WHERE Etaj = 1;
    v_camere CAMERE%ROWTYPE;
BEGIN
    OPEN c_camere;
    LOOP
        FETCH c_camere INTO v_camere;
        EXIT WHEN c_camere%NOTFOUND;
        DBMS_OUTPUT.PUT_LINE('Camera ' || v_camere.NumarCamera || ' este la etajul ' || v_camere.Etaj);
    END LOOP;
    CLOSE c_camere;
END;
/

-- Cursor explicit cu parametri
DECLARE
    v_status_rezervare VARCHAR2(50) := 'Confirmat';
    CURSOR c_rezervari(status_rezervare VARCHAR2) IS 
        SELECT ID_Rezervare, ID_Client, ID_Camera, DataInceput, DataSfarsit
        FROM REZERVARI
        WHERE Status = status_rezervare;
    v_rezervare c_rezervari%ROWTYPE;
BEGIN
    OPEN c_rezervari(v_status_rezervare);
    LOOP
        FETCH c_rezervari INTO v_rezervare;
        EXIT WHEN c_rezervari%NOTFOUND;
        DBMS_OUTPUT.PUT_LINE('Rezervare ID: ' || v_rezervare.ID_Rezervare);
    END LOOP;
    CLOSE c_rezervari;
END;
/

-- Cursor implicit fără parametri
BEGIN
    FOR v_client IN (SELECT * FROM CLIENTI WHERE Prenume LIKE 'A%') LOOP
        DBMS_OUTPUT.PUT_LINE('Client: ' || v_client.Nume || ' ' || v_client.Prenume);
    END LOOP;
END;
/

-- Cursor implicit cu parametri
DECLARE
    v_tip VARCHAR2(50) := 'Dubla Lux';
BEGIN
    FOR v_camera IN (SELECT * FROM CAMERE WHERE Tip = v_tip) LOOP
        DBMS_OUTPUT.PUT_LINE('Camera ' || v_camera.NumarCamera || ' de tip ' || v_camera.Tip);
    END LOOP;
END;
/

-------------------------------------------------------------
-- FUNCTII
-------------------------------------------------------------
CREATE OR REPLACE FUNCTION CalculPretTotal(pret_noapte IN NUMBER, nr_nopti IN NUMBER) RETURN NUMBER IS
    pret_total NUMBER;
BEGIN
    pret_total := pret_noapte * nr_nopti;
    RETURN pret_total;
END;
/

CREATE OR REPLACE FUNCTION VerificaClientFidel(numar_rezervari IN NUMBER) RETURN VARCHAR2 IS
BEGIN
    IF numar_rezervari > 5 THEN
        RETURN 'Client fidel';
    ELSE
        RETURN 'Client nefidel';
    END IF;
END;
/

CREATE OR REPLACE FUNCTION GetNumeComplet(id_client IN NUMBER) RETURN VARCHAR2 IS
    nume_complet VARCHAR2(255);
BEGIN
    SELECT Nume || ' ' || Prenume INTO nume_complet
    FROM CLIENTI WHERE ID_Client = id_client AND ROWNUM = 1;
    RETURN nume_complet;
EXCEPTION
    WHEN NO_DATA_FOUND THEN
        RETURN 'Nume client inexistent';
END;
/

-------------------------------------------------------------
-- PROCEDURI
-------------------------------------------------------------
CREATE OR REPLACE PROCEDURE FinalizeazaRezervare(id_rezervare IN NUMBER) IS
BEGIN
    UPDATE REZERVARI SET Status = 'Finalizat' WHERE ID_Rezervare = id_rezervare;
    COMMIT;
END;
/

CREATE OR REPLACE PROCEDURE AnuleazaRezervare(id_rezervare IN NUMBER) IS
BEGIN
    DELETE FROM REZERVARI WHERE ID_Rezervare = id_rezervare;
    COMMIT;
END;
/

CREATE OR REPLACE PROCEDURE VerificaDisponibilitateCamera1(id_camera IN NUMBER, data_inceput IN DATE, data_sfarsit IN DATE) IS
    v_count NUMBER;
BEGIN
    SELECT COUNT(*) INTO v_count
    FROM REZERVARI
    WHERE ID_Camera = id_camera
    AND ((data_inceput BETWEEN DataInceput AND DataSfarsit)
         OR (data_sfarsit BETWEEN DataInceput AND DataSfarsit));
    IF v_count > 0 THEN
        DBMS_OUTPUT.PUT_LINE('Camera nu este disponibila');
    ELSE
        DBMS_OUTPUT.PUT_LINE('Camera este disponibila');
    END IF;
END;
/

-------------------------------------------------------------
-- PACHETE
-------------------------------------------------------------
-- Pachet CLIENTI
CREATE OR REPLACE PACKAGE actualizare_clienti IS
  PROCEDURE adauga_client(p_id_client CLIENTI.ID_Client%TYPE, p_nume CLIENTI.Nume%TYPE,
                          p_prenume CLIENTI.Prenume%TYPE, p_email CLIENTI.Email%TYPE, p_telefon CLIENTI.Telefon%TYPE);
  PROCEDURE modifica_client(p_id_client CLIENTI.ID_Client%TYPE, p_nume CLIENTI.Nume%TYPE,
                            p_prenume CLIENTI.Prenume%TYPE, p_email CLIENTI.Email%TYPE, p_telefon CLIENTI.Telefon%TYPE);
  PROCEDURE modifica_client_email(p_id_client CLIENTI.ID_Client%TYPE, p_email CLIENTI.Email%TYPE);
  PROCEDURE sterge_client(p_id_client CLIENTI.ID_Client%TYPE);
  FUNCTION exista_client(p_id_client CLIENTI.ID_Client%TYPE) RETURN BOOLEAN;
  exceptie_client EXCEPTION;
END actualizare_clienti;
/

-- Pachet CAMERE
CREATE OR REPLACE PACKAGE actualizare_camere IS
  PROCEDURE adauga_camera(p_id_camera CAMERE.ID_Camera%TYPE, p_numarcamera CAMERE.NumarCamera%TYPE,
                          p_tip CAMERE.Tip%TYPE, p_pretnopate CAMERE.PretNoapte%TYPE, p_etaj CAMERE.Etaj%TYPE,
                          p_capacitate CAMERE.Capacitate%TYPE);
  PROCEDURE modifica_camera(p_id_camera CAMERE.ID_Camera%TYPE, p_numarcamera CAMERE.NumarCamera%TYPE,
                            p_tip CAMERE.Tip%TYPE, p_pretnopate CAMERE.PretNoapte%TYPE, p_etaj CAMERE.Etaj%TYPE,
                            p_capacitate CAMERE.Capacitate%TYPE);
  PROCEDURE modifica_camera_pret(p_id_camera CAMERE.ID_Camera%TYPE, p_pretnopate CAMERE.PretNoapte%TYPE);
  PROCEDURE sterge_camera(p_id_camera CAMERE.ID_Camera%TYPE);
  FUNCTION exista_camera(p_id_camera CAMERE.ID_Camera%TYPE) RETURN BOOLEAN;
  exceptie_camera EXCEPTION;
END actualizare_camere;
/

-------------------------------------------------------------
-- DECLANSATORI
-------------------------------------------------------------
-- Prevenire suprapuneri rezervări
CREATE OR REPLACE TRIGGER prevenire_suprapunere_rezervari
BEFORE INSERT ON REZERVARI
FOR EACH ROW
DECLARE v_count NUMBER;
BEGIN
  SELECT COUNT(*) INTO v_count
  FROM REZERVARI
  WHERE ID_Camera = :NEW.ID_Camera
    AND (:NEW.DataInceput BETWEEN DataInceput AND DataSfarsit
         OR :NEW.DataSfarsit BETWEEN DataInceput AND DataSfarsit
         OR :NEW.DataInceput <= DataInceput AND :NEW.DataSfarsit >= DataSfarsit);
  IF v_count > 0 THEN
    RAISE_APPLICATION_ERROR(-20001, 'Suprapunere rezervari detectata');
  END IF;
END;
/

-- Audit la ștergerea rezervărilor
CREATE TABLE AUDIT_REZERVARI (
  ID_Rezervare INT,
  ID_Client INT,
  ID_Camera INT,
  DataInceput DATE,
  DataSfarsit DATE,
  Status VARCHAR2(50),
  Data_Stergere DATE
);

CREATE OR REPLACE TRIGGER audit_stergere_rezervare
BEFORE DELETE ON REZERVARI
FOR EACH ROW
BEGIN
  INSERT INTO AUDIT_REZERVARI
  VALUES (:OLD.ID_Rezervare, :OLD.ID_Client, :OLD.ID_Camera, :OLD.DataInceput, :OLD.DataSfarsit, :OLD.Status, SYSDATE);
END;
/

-- Actualizare status cameră după rezervare
CREATE OR REPLACE TRIGGER actualizare_status_camera
AFTER INSERT ON REZERVARI
FOR EACH ROW
BEGIN
  UPDATE CAMERE SET Tip = 'Rezervata' WHERE ID_Camera = :NEW.ID_Camera;
END;
/
