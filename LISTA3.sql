set serveroutput on;

--34
DECLARE
    liczba_kotow    INTEGER;
    szukana_funkcja VARCHAR2(50) := '&funkcja';
BEGIN
    SELECT COUNT(*)
    INTO liczba_kotow
    FROM KOCURY
    WHERE FUNKCJA = szukana_funkcja;
    IF liczba_kotow > 0 THEN
        DBMS_OUTPUT.PUT_LINE('Znaleziono koty o funkcji: ' || szukana_funkcja);
    ELSE
        DBMS_OUTPUT.PUT_LINE('Nie znaleziono.');
    END IF;
END;
/

--35
DECLARE
    imie_kota           KOCURY.IMIE%TYPE;
    przydzial_roczny    NUMBER;
    miesiac_przyst      NUMBER;
    odpowiada_kryteriom BOOLEAN := FALSE;
BEGIN
    SELECT IMIE,
           (NVL(PRZYDZIAL_MYSZY, 0) + NVL(MYSZY_EXTRA, 0)) * 12,
           EXTRACT(MONTH FROM W_STADKU_OD)
    INTO imie_kota, przydzial_roczny, miesiac_przyst
    FROM KOCURY
    WHERE PSEUDO = '&pseudo';
    IF przydzial_roczny > 700
    THEN
        odpowiada_kryteriom := TRUE;
        DBMS_OUTPUT.PUT_LINE('calkowity roczny przydzial myszy >700');
    END IF;
    IF imie_kota LIKE '%A%'
    THEN
        odpowiada_kryteriom := TRUE;
        DBMS_OUTPUT.PUT_LINE('imie zawiera litere A');
    END IF;
    IF miesiac_przyst = 5
    THEN
        odpowiada_kryteriom := TRUE;
        DBMS_OUTPUT.PUT_LINE('maj jest miesiacem przystapienia do stadka');
    END IF;
    IF NOT odpowiada_kryteriom
    THEN
        DBMS_OUTPUT.PUT_LINE('nie odpowiada kryteriom');
    END IF;
EXCEPTION
    WHEN NO_DATA_FOUND THEN
        DBMS_OUTPUT.PUT_LINE('nie znaleziono kota o podanym pseudo');
END;
/

--36
DECLARE
    CURSOR do_podwyzki IS
        SELECT PSEUDO,
               NVL(PRZYDZIAL_MYSZY, 0) ZJADA,
               F.MAX_MYSZY             MAX
        FROM KOCURY
                 JOIN FUNKCJE F ON KOCURY.FUNKCJA = F.FUNKCJA
        ORDER BY "ZJADA"
            FOR UPDATE OF PRZYDZIAL_MYSZY;
    suma_przedzialow NUMBER := 0;
    ile_zmian        NUMBER := 0;
    kot              do_podwyzki%ROWTYPE;
BEGIN
    SELECT SUM(NVL(PRZYDZIAL_MYSZY, 0)) INTO suma_przedzialow FROM KOCURY;
    OPEN do_podwyzki;
    WHILE suma_przedzialow <= 1050
        LOOP
            FETCH do_podwyzki INTO kot;

            IF do_podwyzki%NOTFOUND THEN
                CLOSE do_podwyzki;
                OPEN do_podwyzki;
                FETCH do_podwyzki INTO kot;
            END IF;

            IF ROUND(kot.ZJADA * 1.1) <= kot.MAX THEN
                suma_przedzialow := suma_przedzialow + ROUND(kot.ZJADA * 0.1);
                ile_zmian := ile_zmian + 1;
                UPDATE KOCURY
                    SET PRZYDZIAL_MYSZY = ROUND(PRZYDZIAL_MYSZY * 1.1)
                WHERE 
                    CURRENT OF do_podwyzki;
            ELSIF kot.ZJADA <> kot.MAX THEN
                suma_przedzialow := suma_przedzialow + kot.MAX - kot.ZJADA;
                ile_zmian := ile_zmian + 1;
                
                UPDATE KOCURY 
                    SET PRZYDZIAL_MYSZY = kot.MAX
                WHERE 
                    CURRENT OF do_podwyzki;
            END IF;

        END LOOP;
    DBMS_OUTPUT.PUT_LINE(
                'Calk. przydzial w stadku - ' || TO_CHAR(suma_przedzialow) || ' Zmian - ' || TO_CHAR(ile_zmian));
    CLOSE do_podwyzki;
END ;

/

SELECT IMIE, PRZYDZIAL_MYSZY
FROM KOCURY;

/

ROLLBACK;

 -- zad 37
DECLARE
    CURSOR koty(liczba NUMBER) IS
        SELECT
            pseudo,
            przydzial_myszy + NVL(myszy_extra, 0) zjada
        FROM
            Kocury
        ORDER BY
            przydzial_myszy + NVL(myszy_extra, 0) DESC
        FETCH FIRST liczba ROWS ONLY;
    len INTEGER := 5;
    nr NUMBER := 1;
BEGIN
    DBMS_OUTPUT.PUT_LINE('Nr Pseudonim  Zjada');
    DBMS_OUTPUT.PUT_LINE('-------------------');
    FOR k in koty(len)
    LOOP
        DBMS_OUTPUT.PUT_LINE(RPAD(nr, 3 - LENGTH(nr)) || ' ' || k.pseudo || LPAD(k.zjada, 15 - LENGTH(k.pseudo)));
        nr := nr + 1;
    END LOOP;
END;
/

--38
DECLARE
    CURSOR koty IS
        SELECT
            K.imie im,
            K1.imie szef_1,
            NVL(K2.imie, ' ') szef_2,
            NVL(K3.imie, ' ') szef_3
        FROM 
            Kocury K
        INNER JOIN 
            Kocury K1 
        ON 
            K.szef = K1.pseudo 
        AND 
            K.funkcja IN ('KOT', 'MILUSIA')
        LEFT JOIN 
            Kocury K2 
        ON 
            K1.szef = K2.pseudo
        LEFT JOIN 
            Kocury K3 
        ON 
            K2.szef = K3.pseudo;
    liczba_przel NUMBER;
    str STRING(30);
BEGIN
    liczba_przel := &liczba_przelozonych;
    DBMS_OUTPUT.PUT_LINE(RPAD('Imie',10) || RPAD('Szef 1',10) || RPAD('Szef 2',10) || RPAD('Szef 3',10));   
    DBMS_OUTPUT.PUT_LINE('-------------------------');    
    FOR k IN koty
    LOOP
        str := RPAD(k.im, 10);
        IF liczba_przel >= 1
            THEN str := str || ' '  || k.szef_1;
        END IF;
        IF liczba_przel >= 2
            THEN str := str || ' '  || k.szef_2;
        END IF;
        IF liczba_przel >= 3
            THEN str := str || ' '  || k.szef_3;
        END IF;
        DBMS_OUTPUT.PUT_LINE(str);
    END LOOP;
END;
/

--39
DECLARE
    mniej_niz_zero EXCEPTION;
    PRAGMA EXCEPTION_INIT(mniej_niz_zero, -42069);
    index_bandy Bandy.nr_bandy%TYPE;
    nazwa_bandy Bandy.nazwa%TYPE;
    teren_bandy Bandy.teren%TYPE;
    licznik NUMBER;
    licznik_bledow NUMBER := 0;
BEGIN
    SAVEPOINT przedDodaniem;
    index_bandy := &index_bandy;
    
    IF index_bandy <=0
    THEN 
        RAISE mniej_niz_zero;
    END IF;
    
        
    SELECT 
        COUNT(*) INTO licznik 
    FROM 
        Bandy 
    WHERE 
        nr_bandy = index_bandy;
    IF licznik > 0
    THEN 
        DBMS_OUTPUT.PUT_LINE(index_bandy || ': juz istnieje');
        licznik_bledow := licznik_bledow + 1;
    END IF;
    
    nazwa_bandy := '&nazwa_bandy';    
    SELECT 
        COUNT(*) INTO licznik 
    FROM Bandy 
        WHERE nazwa = nazwa_bandy;
    IF licznik > 0
    THEN 
        DBMS_OUTPUT.PUT_LINE(nazwa_bandy || ': juz istnieje');
        licznik_bledow := licznik_bledow + 1;
    END IF;
    
    teren_bandy := '&teren_bandy';
    SELECT 
        COUNT(*) INTO licznik 
    FROM Bandy 
        WHERE teren = teren_bandy;
    IF licznik > 0
    THEN 
        DBMS_OUTPUT.PUT_LINE(teren_bandy || ': juz istnieje');
        licznik_bledow := licznik_bledow + 1;
    END IF;

    IF licznik_bledow = 0
    THEN
        DBMS_OUTPUT.PUT_LINE(index_bandy || ' ' || nazwa_bandy || ' ' || teren_bandy || ': utworzono');
        INSERT INTO Bandy 
            (nr_bandy, nazwa, teren) 
        VALUES 
            (index_bandy, nazwa_bandy, teren_bandy);
    END IF;
    ROLLBACK TO SAVEPOINT przedDodaniem;
END;
/
--40
CREATE OR REPLACE PROCEDURE dodawanie_bandy(index_bandy Bandy.nr_bandy%TYPE, 
                            nazwa_bandy Bandy.nazwa%TYPE, 
                            teren_bandy Bandy.teren%TYPE) AS
    mniej_niz_zero EXCEPTION;
    PRAGMA EXCEPTION_INIT(mniej_niz_zero, -42069);
    licznik NUMBER;
    licznik_bledow NUMBER := 0;
BEGIN
    SAVEPOINT przedDodaniem;
    
    IF index_bandy <=0
    THEN 
        RAISE mniej_niz_zero;
    END IF;
    SELECT COUNT(*) INTO licznik FROM Bandy WHERE nr_bandy = index_bandy;
    IF licznik > 0
    THEN 
        DBMS_OUTPUT.PUT_LINE(index_bandy || ': ju? istnieje');
        licznik_bledow := licznik_bledow + 1;
    END IF;
       
    SELECT COUNT(*) INTO licznik FROM Bandy WHERE nazwa = nazwa_bandy;
    IF licznik > 0
    THEN 
        DBMS_OUTPUT.PUT_LINE(nazwa_bandy || ': ju? istnieje');
        licznik_bledow := licznik_bledow + 1;
    END IF;
    
    SELECT COUNT(*) INTO licznik FROM Bandy WHERE teren = teren_bandy;
    IF licznik > 0
    THEN 
        DBMS_OUTPUT.PUT_LINE(teren_bandy || ': ju? istnieje');
        licznik_bledow := licznik_bledow + 1;
    END IF;

    IF licznik_bledow = 0
    THEN
        DBMS_OUTPUT.PUT_LINE(index_bandy || ' ' || nazwa_bandy || ' ' || teren_bandy || ': utworzono');
        INSERT INTO Bandy 
        (nr_bandy, nazwa, teren) 
        VALUES 
        (index_bandy, nazwa_bandy, teren_bandy);
    END IF;
    ROLLBACK TO SAVEPOINT przedDodaniem;
END;
/
BEGIN
dodawanie_bandy(10, 'testowa', 'testowy');
END;
/

--41
CREATE OR REPLACE TRIGGER nowa_banda
BEFORE INSERT ON Bandy
FOR EACH ROW
DECLARE
    nr NUMBER;
BEGIN
    SELECT MAX(nr_bandy) INTO nr FROM Bandy;
    nr := nr + 1;
    :NEW.nr_bandy := nr;
    DBMS_OUTPUT.PUT_LINE('Utworzono bande o numerze: ' || nr);
END;
/

BEGIN
dodawanie_bandy(10, 'testowa', 'testowy');
END;
ROLLBACK;

--42.1 

SET SERVEROUTPUT ON;
CREATE OR REPLACE PACKAGE zmiana_przydzialu 
IS 
   PROCEDURE inicjalizacja; 
 
   PROCEDURE dodaj_kota ( 
      pseudo_kota_nowy IN Kocury.pseudo%TYPE 
    , przydzial_kota_nowy IN Kocury.przydzial_myszy%TYPE 
   ); 
 
   PROCEDURE popraw_przydzialy; 
END;
/

CREATE OR REPLACE PACKAGE BODY zmiana_przydzialu 
IS   
   TYPE kot_rd IS RECORD (   
        pseudo_kota Kocury.pseudo%TYPE, 
        przydzial_kota Kocury.przydzial_myszy%TYPE   
   );   
   
   TYPE koty_t IS TABLE OF kot_rd   
      INDEX BY PLS_INTEGER;   
   
   koty_info   koty_t;   
   poprawianie_w_trakcie BOOLEAN := FALSE;   
   
   PROCEDURE inicjalizacja   
   IS   
   BEGIN   
      koty_info.DELETE;   
   END;   
   
   PROCEDURE dodaj_kota (    
      pseudo_kota_nowy IN Kocury.pseudo%TYPE 
    , przydzial_kota_nowy IN Kocury.przydzial_myszy%TYPE 
   )   
   IS   
      index_kota   PLS_INTEGER := koty_info.COUNT + 1;   
   BEGIN   
      IF NOT poprawianie_w_trakcie   
      THEN   
         koty_info (index_kota).pseudo_kota := pseudo_kota_nowy;   
         koty_info (index_kota).przydzial_kota := przydzial_kota_nowy;  
      END IF;   
   END;   
   
   PROCEDURE popraw_przydzialy   
   IS   
      przydzial_tygrysa   Kocury.przydzial_myszy%TYPE;   
      index_kota         PLS_INTEGER;   
      zmiana NUMBER;
   BEGIN   
      IF NOT poprawianie_w_trakcie   
      THEN   
         poprawianie_w_trakcie := TRUE;   
   
         SELECT przydzial_myszy INTO przydzial_tygrysa
         FROM Kocury WHERE pseudo='TYGRYS';   
   
         WHILE (koty_info.COUNT > 0)   
         LOOP   
            index_kota := koty_info.FIRST;   
            
            SELECT przydzial_myszy - koty_info (index_kota).przydzial_kota 
            INTO zmiana
            FROM Kocury 
            WHERE pseudo = koty_info (index_kota).pseudo_kota;
            
            DBMS_OUTPUT.PUT_LINE('dane kota: ' || index_kota || ' ' || koty_info (index_kota).pseudo_kota || ' ' || koty_info (index_kota).przydzial_kota || ' ' || przydzial_tygrysa);
            DBMS_OUTPUT.PUT_LINE('zmiana: ' || zmiana);
            DBMS_OUTPUT.PUT_LINE('przydzial_tygrysa * 0.1: ' || przydzial_tygrysa * 0.1);
            
            IF zmiana < przydzial_tygrysa * 0.1
                THEN 
                    UPDATE Kocury 
                    SET 
                        przydzial_myszy = przydzial_myszy + zmiana, 
                        myszy_extra = NVL(myszy_extra, 0) + 5
                    WHERE funkcja = 'MILUSIA';
                    UPDATE Kocury
                    SET
                        przydzial_myszy = przydzial_myszy * 0.9
                    WHERE pseudo = 'TYGRYS';
                ELSE 
                    UPDATE Kocury
                    SET
                        myszy_extra = NVL(myszy_extra, 0) + 5
                    WHERE pseudo = 'TYGRYS';            
                END IF;
        
            koty_info.DELETE (koty_info.FIRST);   
         END LOOP;   
         poprawianie_w_trakcie := FALSE;  
      END IF;   
   END;   
END;

/
CREATE OR REPLACE TRIGGER zmiana_przydzialu_inicjalizaja 
   BEFORE INSERT OR UPDATE  
   ON Kocury 
BEGIN 
   LOCK TABLE Kocury IN EXCLUSIVE MODE; 
   zmiana_przydzialu.inicjalizacja; 
END;
/
CREATE OR REPLACE TRIGGER zmiana_przydzialu_dodaj_koty  
   AFTER INSERT OR UPDATE OF przydzial_myszy  
   ON Kocury  
   FOR EACH ROW  
BEGIN  
   zmiana_przydzialu.dodaj_kota (
      :OLD.pseudo, :OLD.przydzial_myszy);  
END;
/
CREATE OR REPLACE TRIGGER zmiana_przydzialu_popraw  
   AFTER INSERT OR UPDATE OF przydzial_myszy  
   ON Kocury  
BEGIN  
   zmiana_przydzialu.popraw_przydzialy;  
END;
/

update Kocury
set przydzial_myszy = (przydzial_myszy +15) where funkcja='MILUSIA';
rollback ;
/

--42.2

SET SERVEROUTPUT ON;
CREATE OR REPLACE TRIGGER zmiana_przydzialu_compound
FOR UPDATE OF przydzial_myszy 
ON Kocury
COMPOUND TRIGGER
    TYPE kot_rd IS RECORD (   
        pseudo_kota Kocury.pseudo%TYPE, 
        przydzial_kota Kocury.przydzial_myszy%TYPE   
    );   
    
    TYPE koty_t IS TABLE OF kot_rd   
      INDEX BY PLS_INTEGER;   
    
    koty_info   koty_t;   
    poprawianie_w_trakcie BOOLEAN := FALSE;   
    
    BEFORE STATEMENT IS
    BEGIN      
        koty_info.DELETE;   
    END BEFORE STATEMENT;

    AFTER EACH ROW IS
        index_kota   PLS_INTEGER := koty_info.COUNT + 1;   
    BEGIN
        IF NOT poprawianie_w_trakcie   
        THEN   
            koty_info (index_kota).pseudo_kota := :OLD.pseudo;   
            koty_info (index_kota).przydzial_kota := :OLD.przydzial_myszy;  
        END IF;   
    END AFTER EACH ROW;
    
    AFTER STATEMENT IS
        przydzial_tygrysa   Kocury.przydzial_myszy%TYPE;   
        index_kota  PLS_INTEGER;   
        zmiana  NUMBER;
    BEGIN   
        IF NOT poprawianie_w_trakcie   
        THEN   
            poprawianie_w_trakcie := TRUE;   
            
            SELECT przydzial_myszy INTO przydzial_tygrysa
            FROM Kocury WHERE pseudo='TYGRYS';   
            
            WHILE (koty_info.COUNT > 0)   
            LOOP   
                index_kota := koty_info.FIRST;   
                
                SELECT przydzial_myszy - koty_info (index_kota).przydzial_kota 
                INTO zmiana
                FROM Kocury 
                WHERE pseudo = koty_info (index_kota).pseudo_kota;
                
                DBMS_OUTPUT.PUT_LINE('dane kota: ' || index_kota || ' ' || koty_info (index_kota).pseudo_kota || ' ' || koty_info (index_kota).przydzial_kota || ' ' || przydzial_tygrysa);
                DBMS_OUTPUT.PUT_LINE('zmiana: ' || zmiana);
                DBMS_OUTPUT.PUT_LINE('przydzial_tygrysa * 0.1: ' || przydzial_tygrysa * 0.1);
                
                IF zmiana < przydzial_tygrysa * 0.1
                    THEN 
                        UPDATE Kocury 
                        SET 
                            przydzial_myszy = przydzial_myszy + zmiana, 
                            myszy_extra = NVL(myszy_extra, 0) + 5
                        WHERE funkcja = 'MILUSIA';
                        UPDATE Kocury
                        SET
                            przydzial_myszy = przydzial_myszy * 0.9
                        WHERE pseudo = 'TYGRYS';
                    ELSE 
                        UPDATE Kocury
                        SET
                            myszy_extra = NVL(myszy_extra, 0) + 5
                        WHERE pseudo = 'TYGRYS';            
                    END IF;
                koty_info.DELETE (koty_info.FIRST);   
            END LOOP;   
            poprawianie_w_trakcie := FALSE;  
        END IF;   
    END AFTER STATEMENT;
END;
/


SAVEPOINT przed_zmiana_przydzialu;
ROLLBACK TO SAVEPOINT przed_zmiana_przydzialu;

BEGIN
    UPDATE Kocury SET przydzial_myszy = 45 WHERE pseudo = 'ZERO';
    ROLLBACK;
END;

BEGIN
    UPDATE Kocury SET przydzial_myszy = 60 WHERE pseudo = 'ZERO';
    ROLLBACK;
END;
/

--43
SET SERVEROUTPUT ON
DECLARE
      polecenie1 STRING(2000);
      polecenie2 STRING(2000);
      rc1 SYS_REFCURSOR;
      rc2 SYS_REFCURSOR;
      CURSOR funkcje IS
            SELECT
                  funkcja
            FROM
                  Funkcje;
BEGIN
      polecenie1 := 'SELECT DECODE(K.plec, '||'''D'''||', B.nazwa, '' '') "NAZWA BANDY", DECODE(K.plec, '||'''D'''||', '||'''Kotka'''||', '||'''Kocur'''||') "Plec", TO_CHAR(COUNT(*)) "ILE"';
      FOR f IN funkcje
      LOOP
            polecenie1 := polecenie1 || ',TO_CHAR(SUM(DECODE(K.funkcja, ''' || f.funkcja || ''', K.przydzial_myszy + NVL(K.myszy_extra, 0), 0))) "' || f.funkcja || '"';
      END LOOP;
      polecenie1 := polecenie1 || ',TO_CHAR(SUM(K.przydzial_myszy + NVL(K.myszy_extra, 0))) "SUMA"
            FROM
                  Kocury K
            INNER JOIN
                  Bandy B ON B.nr_bandy = K.nr_bandy
            GROUP BY
                  B.nazwa, K.plec
            ORDER BY
                  B.nazwa, K.plec';
      OPEN rc1 FOR polecenie1;
      DBMS_SQL.RETURN_RESULT(rc1);
      
      polecenie2 := 'SELECT  '||'''ZJADA RAZEM         '' "ZJADA RAZEM"'||',
            '||'''     '' " "'||',
            '||'''                                       '' " "'||',';
      FOR f IN funkcje
      LOOP
            polecenie2 := polecenie2 || 'TO_CHAR(SUM(DECODE(funkcja, ''' || f.funkcja || ''', przydzial_myszy + NVL(myszy_extra, 0), 0))) " ", ';
      END LOOP;
      polecenie2 := polecenie2 ||  'TO_CHAR(SUM(przydzial_myszy + NVL(myszy_extra, 0))) " "
            FROM Kocury';

      OPEN rc2 FOR polecenie2;
      DBMS_SQL.RETURN_RESULT(rc2);
END;


--44
CREATE OR REPLACE FUNCTION podatek(pseudo_kota Kocury.pseudo%TYPE) RETURN NUMBER IS
    liczba_myszy Kocury.przydzial_myszy%TYPE;
    podatek_kota NUMBER := 0;
    liczba_podwladnych NUMBER := 0;
    liczba_wrogow NUMBER := 0;
    plec_kota Kocury.plec%TYPE;
BEGIN
    -- PODATEK BAZOWY
    SELECT
        SUM(przydzial_myszy + NVL(myszy_extra, 0))
    INTO
        liczba_myszy
    FROM
        Kocury
    WHERE
        pseudo = pseudo_kota;
    podatek_kota := podatek_kota + CEIL(liczba_myszy * 0.05);
    
    -- PODATEK ZA NIEUDOLNOSC W UMIZGACH O AWANAS
    SELECT
        COUNT(*)
    INTO
        liczba_podwladnych
    FROM
        Kocury
    WHERE
        szef = pseudo_kota;
    IF liczba_podwladnych = 0
        THEN podatek_kota := podatek_kota + 2;
    END IF;
    
    -- PODATEK ZA BRAK WROGOW
    SELECT
        COUNT(*)
    INTO
        liczba_wrogow
    FROM
        Wrogowie_Kocurow
    WHERE
         pseudo = pseudo_kota;
    IF liczba_wrogow = 0
        THEN podatek_kota := podatek_kota + 1;
    END IF;
    
    --PODATEK ZA BYCIE KOBIETA
    SELECT
        plec
    INTO
        plec_kota
    FROM
        KOCURY
    WHERE
         pseudo = pseudo_kota;
         
    IF plec_kota = 'D'
        THEN podatek_kota := podatek_kota + 1;
    END IF;
    
    DBMS_OUTPUT.PUT_LINE('podatek dla ' || pseudo_kota || ' => ' || podatek_kota);
    RETURN podatek_kota;
END;

/

SET SERVEROUTPUT ON
BEGIN
    DBMS_OUTPUT.PUT_LINE(podatek('TYGRYS'));
    --ma wroga - 0, ma podwladnych -0, facet - 0, podatek 5% -> 7
END;
/
SET SERVEROUTPUT ON
BEGIN
    DBMS_OUTPUT.PUT_LINE(podatek('ZOMBI'));
    --ma wroga - 0, ma podwladnych - 0, facet - 0, podatek 5% -> 5 
END;
/
SET SERVEROUTPUT ON
BEGIN
    DBMS_OUTPUT.PUT_LINE(podatek('RAFA'));
    --nie ma wroga - 1, ma podwladnych -0, facet - 0, podatek 5% -> 5
END;
/
SET SERVEROUTPUT ON
BEGIN
    DBMS_OUTPUT.PUT_LINE(podatek('LOLA'));
    --nie ma wroga-1, nie ma podwladnych -2, kobieta - 1, podatek 5% -> 8
END;
/

CREATE OR REPLACE PACKAGE pakiet IS
    PROCEDURE dodawanie_bandy(index_bandy Bandy.nr_bandy%TYPE, 
                            nazwa_bandy Bandy.nazwa%TYPE, 
                            teren_bandy Bandy.teren%TYPE);
    FUNCTION podatek(pseudo_kota Kocury.pseudo%TYPE) 
        RETURN NUMBER;
END;
/
CREATE OR REPLACE PACKAGE BODY pakiet IS
    PROCEDURE dodawanie_bandy(index_bandy Bandy.nr_bandy%TYPE, 
                                nazwa_bandy Bandy.nazwa%TYPE, 
                                teren_bandy Bandy.teren%TYPE) AS
        mniej_niz_zero EXCEPTION;
        PRAGMA EXCEPTION_INIT(mniej_niz_zero, -20000);
        licznik NUMBER;
        licznik_bledow NUMBER := 0;
    BEGIN
        SAVEPOINT przedDodaniem;
        IF index_bandy <=0
        THEN 
            RAISE mniej_niz_zero;
        END IF;
        SELECT COUNT(*) INTO licznik FROM Bandy WHERE nr_bandy = index_bandy;
        IF licznik > 0
        THEN 
            DBMS_OUTPUT.PUT_LINE(index_bandy || ': ju? istnieje');
            licznik_bledow := licznik_bledow + 1;
        END IF;
           
        SELECT COUNT(*) INTO licznik FROM Bandy WHERE nazwa = nazwa_bandy;
        IF licznik > 0
        THEN 
            DBMS_OUTPUT.PUT_LINE(nazwa_bandy || ': ju? istnieje');
            licznik_bledow := licznik_bledow + 1;
        END IF;
        
        SELECT COUNT(*) INTO licznik FROM Bandy WHERE teren = teren_bandy;
        IF licznik > 0
        THEN 
            DBMS_OUTPUT.PUT_LINE(teren_bandy || ': ju? istnieje');
            licznik_bledow := licznik_bledow + 1;
        END IF;
    
        IF licznik_bledow = 0
        THEN
            DBMS_OUTPUT.PUT_LINE(index_bandy || ' ' || nazwa_bandy || ' ' || teren_bandy || ': utworzono');
            INSERT INTO Bandy 
            (nr_bandy, nazwa, teren) 
            VALUES 
            (index_bandy, nazwa_bandy, teren_bandy);
        END IF;
        ROLLBACK TO SAVEPOINT przedDodaniem;
    END;

    FUNCTION podatek(pseudo_kota Kocury.pseudo%TYPE) RETURN NUMBER IS
    liczba_myszy Kocury.przydzial_myszy%TYPE;
    podatek_kota NUMBER := 0;
    liczba_podwladnych NUMBER := 0;
    liczba_wrogow NUMBER := 0;
    plec_kota Kocury.plec%TYPE;
    BEGIN
    
        -- PODATEK BAZOWY
        SELECT
            SUM(przydzial_myszy + NVL(myszy_extra, 0))
        INTO
            liczba_myszy
        FROM
            Kocury
        WHERE
            pseudo = pseudo_kota;
        podatek_kota := podatek_kota + CEIL(liczba_myszy * 0.05);
        
        -- PODATEK ZA NIEUDOLNOSC W UMIZGACH O AWANAS
        SELECT
            COUNT(*)
        INTO
            liczba_podwladnych
        FROM
            Kocury
        WHERE
            szef = pseudo_kota;
        IF liczba_podwladnych = 0
            THEN podatek_kota := podatek_kota + 2;
        END IF;
    
    -- PODATEK ZA BRAK WROGOW
        SELECT
            COUNT(*)
        INTO
            liczba_wrogow
        FROM
            Wrogowie_Kocurow
        WHERE
             pseudo = pseudo_kota;
        IF liczba_wrogow = 0
            THEN podatek_kota := podatek_kota + 1;
        END IF;
        
        --PODATEK ZA BYCIE KOBIETA
        SELECT
            plec
        INTO
            plec_kota
        FROM
            KOCURY
        WHERE
             pseudo = pseudo_kota;
             
        IF plec_kota = 'D'
            THEN podatek_kota := podatek_kota + 1;
        END IF;
        
        DBMS_OUTPUT.PUT_LINE('podatek dla ' || pseudo_kota || ' => ' || podatek_kota);
        RETURN podatek_kota;
    END;
END;
/
SET SERVEROUTPUT ON;
DECLARE
    CURSOR koty IS
        SELECT
            pseudo
        FROM
            Kocury;
    podatki NUMBER := 0;
BEGIN
    FOR k IN koty
    LOOP
        podatki := podatki + pakiet.podatek(k.pseudo);
    END LOOP;
    DBMS_OUTPUT.PUT_LINE('podatki: ' || podatki);
END;

--45
CREATE TABLE Dodatki_extra (
    pseudo VARCHAR2(15) NOT NULL,
    dod_extra NUMBER(3,0) NOT NULL
);

DROP TABLE Dodatki_extra;

CREATE OR REPLACE TRIGGER zmiana_przydzialu_milus
   AFTER UPDATE
   ON Kocury
   FOR EACH ROW
DECLARE
    pseudo Dodatki_extra.pseudo%TYPE;
    polecenie STRING(100);
BEGIN
    IF LOGIN_USER <> 'TYGRYS'
    THEN
        IF :OLD.funkcja = 'MILUSIA'
        THEN
            IF :NEW.przydzial_myszy > :OLD.przydzial_myszy OR :NEW.myszy_extra > :OLD.myszy_extra
            THEN
                pseudo := :NEW.pseudo;
                polecenie := 'INSERT INTO Dodatki_extra (pseudo, dod_extra) VALUES (''' || pseudo || ''', -10)';
                DBMS_OUTPUT.PUT_LINE(polecenie);
                EXECUTE IMMEDIATE polecenie;
            END IF;
        END IF;
    END IF;
END;
/
UPDATE Kocury SET przydzial_myszy = 25 WHERE pseudo = 'PUSZYSTA';
ROLLBACK;

DROP TRIGGER zmiana_przydzialu_milus;
DROP TRIGGER spr_zmiany_przydzialu;

--46
CREATE TABLE Niewlasciwe_przydzialy_myszy (
    kto VARCHAR2(15) NOT NULL,
    data DATE NOT NULL,
    kotu VARCHAR2(15) NOT NULL,
    operacja VARCHAR2(15) NOT NULL
);

DROP TABLE Niewlasciwe_przydzialy_myszy;

CREATE OR REPLACE TRIGGER spr_zmiany_przydzialu
BEFORE INSERT OR UPDATE OF przydzial_myszy
ON Kocury
FOR EACH ROW
DECLARE
    zly_przedial EXCEPTION;
    min_przydzial NUMBER;
    max_przydzial NUMBER;
    uzytk Niewlasciwe_przydzialy_myszy.kto%TYPE;
    data_pr Niewlasciwe_przydzialy_myszy.data%TYPE;
    pseudo Niewlasciwe_przydzialy_myszy.kotu%TYPE;
    oper Niewlasciwe_przydzialy_myszy.operacja%TYPE;
BEGIN
    SELECT
        min_myszy,
        max_myszy
    INTO
        min_przydzial,
        max_przydzial
    FROM Funkcje
    WHERE
        funkcja = :NEW.funkcja;

    IF (:NEW.przydzial_myszy < min_przydzial OR :NEW.przydzial_myszy > max_przydzial)
    THEN
        begin
            case
                when inserting then
                    oper:= 'INSERT';
                when updating then
                    oper:= 'UPDATE';
            end case;
        end;
        uzytk := LOGIN_USER;
        data_pr := SYSDATE;
        pseudo := :NEW.pseudo;
        INSERT INTO Niewlasciwe_przydzialy_myszy (kto, data, kotu, operacja)
        VALUES (uzytk, data_pr, pseudo, oper);
        RAISE zly_przedial;
    END IF;
    EXCEPTION
        WHEN zly_przedial
            THEN DBMS_OUTPUT.PUT_LINE('Wartosc nie miesci sie w zakresie przydzialu funkcji');
        WHEN OTHERS
            THEN DBMS_OUTPUT.PUT_LINE(SQLERRM);


END;
/
UPDATE Kocury SET przydzial_myszy = 300 WHERE pseudo = 'TYGRYS';

ROLLBACK;