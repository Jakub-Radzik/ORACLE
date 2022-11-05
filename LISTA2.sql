-- zad 17
SELECT K.PSEUDO "POLUJE W POLU", 
        K.PRZYDZIAL_MYSZY "PRZYDZIAL MYSZY", 
        B.NAZWA "BANDA"
FROM Kocury K
INNER JOIN Bandy B
ON K.NR_BANDY = B.NR_BANDY
WHERE B.TEREN IN ('POLE', 'CALOSC') AND K.PRZYDZIAL_MYSZY > 50;

-- zad 18
SELECT K1.IMIE, K1.W_STADKU_OD 
FROM KOCURY K1
INNER JOIN KOCURY K2
ON K2.IMIE = 'JACEK' AND K1.W_STADKU_OD < K2.W_STADKU_OD
ORDER BY K1.W_STADKU_OD DESC;

--zad 19a 
SELECT
    K.imie "Imie",
    '|' " ",
    K.funkcja "Funkcja",
    '|' " ",
    K1.imie "Szef 1",
    '|' " ",
    NVL(K2.imie, ' ') "Szef 2",
    '|' " ",
    NVL(K3.imie, ' ') "Szef 3"
FROM 
    Kocury K
INNER JOIN Kocury K1 ON K.szef = K1.pseudo
LEFT JOIN Kocury K2 ON K1.szef = K2.pseudo
LEFT JOIN Kocury K3 ON K2.szef = K3.pseudo
WHERE K.funkcja IN ('KOT', 'MILUSIA');

--zad19b
select Imie,Funkcja, Szef1, Szef2,Szef3
from 
    (select 
        connect_by_root imie, 
        connect_by_root funkcja as funkcja,
        imie, 
        level "LVL"
    from Kocury
    connect by prior szef = pseudo
    start with 
        funkcja in ('KOT','MILUSIA')
    ) pivot (
        max(imie) 
        for LVL 
        in (1 Imie,2 szef1, 3 szef2, 4 szef3)    
   );
--zad19c
SELECT CONNECT_BY_ROOT IMIE    "Imie",
       CONNECT_BY_ROOT FUNKCJA "Funkcja",
       SUBSTR(SYS_CONNECT_BY_PATH(IMIE, '| '), LENGTH(CONNECT_BY_ROOT IMIE) + 4)
                               "Imiona kolejnych szefow"
FROM KOCURY
WHERE SZEF IS NULL
CONNECT BY PRIOR SZEF = PSEUDO
START WITH FUNKCJA IN ('KOT', 'MILUSIA');
--zad 20
SELECT 
    K.IMIE "Imie kotki",
    B.NAZWA "Nazwa bandy",
    WK.IMIE_WROGA "Imie wroga",
    W.STOPIEN_WROGOSCI "Ocena wroga",
    WK.DATA_INCYDENTU "Data inc."
FROM KOCURY K
INNER JOIN wrogowie_kocurow WK
    ON WK.PSEUDO = K.PSEUDO
INNER JOIN BANDY B
    ON B.NR_BANDY = K.NR_BANDY
INNER JOIN wrogowie W
    ON WK.IMIE_WROGA = W.IMIE_WROGA
WHERE WK.data_incydentu > '2007-01-01' AND K.plec = 'D';

--zad 21
SELECT B.NAZWA "Nazwa bandy",
    COUNT(DISTINCT K.PSEUDO) "Koty z wrogami"
    FROM KOCURY K
INNER JOIN BANDY B
    ON B.NR_BANDY = K.NR_BANDY
INNER JOIN WROGOWIE_KOCUROW WK
    ON WK.PSEUDO = K.PSEUDO
GROUP BY B.NAZWA;

--zad 22
SELECT
       K.FUNKCJA "Funkcja",
       K.PSEUDO "Pseudonim kota",
       COUNT(K.FUNKCJA) "Liczba wrogow"
FROM 
    KOCURY K
RIGHT JOIN 
    Wrogowie_Kocurow WK 
    ON K.PSEUDO = WK.PSEUDO
GROUP BY
    K.pseudo, K.FUNKCJA
HAVING 
    COUNT(*) > 1;

--zad 23
SELECT
    IMIE,
    (NVL(PRZYDZIAL_MYSZY,0)+NVL(MYSZY_EXTRA,0))*12 "DAWKA ROCZNA",
    'powyzej 864' "DAWKA"
FROM 
    KOCURY
WHERE
    (NVL(PRZYDZIAL_MYSZY,0)+NVL(MYSZY_EXTRA,0))*12 > 864
UNION
SELECT
    IMIE,
    (NVL(PRZYDZIAL_MYSZY,0)+NVL(MYSZY_EXTRA,0))*12 "DAWKA ROCZNA",
    '864' "DAWKA"
FROM 
    KOCURY
WHERE
    (NVL(PRZYDZIAL_MYSZY,0)+NVL(MYSZY_EXTRA,0))*12 = 864
UNION
SELECT
    IMIE,
    (NVL(PRZYDZIAL_MYSZY,0)+NVL(MYSZY_EXTRA,0))*12 "DAWKA ROCZNA",
    'ponizej 864' "DAWKA"
FROM 
    KOCURY
WHERE
    (NVL(PRZYDZIAL_MYSZY,0)+NVL(MYSZY_EXTRA,0))*12 < 864
ORDER BY 
   2 DESC;

--zad 24
--a
SELECT
    B.NR_BANDY,
    B.NAZWA,
    B.TEREN
FROM 
    KOCURY K
RIGHT JOIN BANDY B
    ON B.NR_BANDY = K.NR_BANDY
WHERE K.PSEUDO IS NULL;    

--b
SELECT    
    B.nr_bandy "NR BANDY",
    B.nazwa,
    B.teren
FROM 
    BANDY B 
WHERE 
    B.NR_BANDY IN (
    SELECT
        nr_bandy
    FROM
        Bandy
    MINUS
    SELECT
        nr_bandy
    FROM 
        Kocury
    GROUP BY
        nr_bandy
);

--zad 25
SELECT 
IMIE,
FUNKCJA,
PRZYDZIAL_MYSZY
FROM KOCURY
WHERE PRZYDZIAL_MYSZY >= (
    SELECT 
        3*K.PRZYDZIAL_MYSZY
    FROM 
        KOCURY K
    INNER JOIN
        BANDY B
    ON B.NR_BANDY = K.NR_BANDY
    WHERE
        K.FUNKCJA = 'MILUSIA' AND
        B.TEREN IN ('SAD', 'CALOSC')
    ORDER BY 
        K.PRZYDZIAL_MYSZY DESC
    FETCH FIRST 1 ROW ONLY
);

--zad 26
SELECT
    funkcja,
    average "Srednio najw. i najm. myszy"
FROM
(
    SELECT
        funkcja,
        CEIL(AVG(przydzial_myszy + NVL(myszy_extra, 0))) average,
        row_number() over (order by CEIL(AVG(przydzial_myszy + NVL(myszy_extra, 0)))) as position,
        count(*) over () as count
    FROM
        Kocury
    WHERE 
        funkcja <> 'SZEFUNIO'
    GROUP BY
        funkcja
)
WHERE
    position = count OR position = 1; 

-- zad 27
ACCEPT x NUMBER PROMPT 'Prosze podac wartosc dla n: ';
-- a 
SELECT
    K.pseudo,
    K.przydzial_myszy + NVL(K.myszy_extra, 0) "ZJADA"
FROM
    Kocury K
WHERE
    (
        SELECT 
            COUNT(DISTINCT K2.przydzial_myszy + NVL(K2.myszy_extra, 0))
        FROM 
            Kocury K2 
        WHERE 
            K.przydzial_myszy + NVL(K.myszy_extra, 0) < K2.przydzial_myszy + NVL(K2.myszy_extra, 0)
    ) < &x
ORDER BY
    K.przydzial_myszy + NVL(K.myszy_extra, 0) DESC;
--b
SELECT PSEUDO, NVL(PRZYDZIAL_MYSZY, 0) + NVL(MYSZY_EXTRA, 0) "ZJADA"
FROM KOCURY
WHERE NVL(PRZYDZIAL_MYSZY, 0) + NVL(MYSZY_EXTRA, 0)
          IN (SELECT "ZJADA"
              FROM (SELECT DISTINCT NVL(PRZYDZIAL_MYSZY, 0) + NVL(MYSZY_EXTRA, 0) "ZJADA"
                    FROM KOCURY
                    ORDER BY "ZJADA" DESC)
              WHERE ROWNUM <= &x);
-- c
SELECT
    K.pseudo pseudo,
    K.przydzial_myszy + NVL(K.myszy_extra, 0) zjada
FROM
    Kocury K
LEFT JOIN Kocury K2 ON 
    K.przydzial_myszy + NVL(K.myszy_extra, 0) < K2.przydzial_myszy + NVL(K2.myszy_extra, 0)
GROUP BY
    K.pseudo,
    K.przydzial_myszy + NVL(K.myszy_extra, 0)
HAVING
    COUNT( K2.przydzial_myszy + NVL(K2.myszy_extra, 0)) < &x
ORDER BY
    MAX(K.przydzial_myszy + NVL(K.myszy_extra, 0)) DESC;

-- d
SELECT 
    pseudo, 
    "ZJADA"
FROM(
    SELECT 
        pseudo,
        przydzial_myszy + NVL(myszy_extra, 0) "ZJADA",
        DENSE_RANK() OVER (ORDER BY przydzial_myszy + NVL(myszy_extra, 0) DESC) AS RANKING
    FROM
    Kocury
)
WHERE RANKING <= &x;

-- zad 28
with Lata
    as (
        select 
            extract(year from W_STADKU_OD) "YEAR", 
            count(*) "COUNT"
        from   
            Kocury
        group by extract(year from W_STADKU_OD)
    )
select TO_CHAR(YEAR),   
        COUNT
from Lata
where COUNT = (select MAX(COUNT)
               from Lata
               where COUNT<= (select AVG(ROUND(COUNT,7))
                              from LATA))
or 
COUNT = (select MIN(COUNT)
               from Lata
               where COUNT >= (select AVG(ROUND(COUNT,7))
                              from LATA))
union 
(SELECT 'Srednia' "YEAR", ROUND(AVG(COUNT), 7)
FROM Lata)
order by 2; 

-- 29
--a
SELECT
    K1.imie,
    MIN(K1.przydzial_myszy + NVL(K1.myszy_extra, 0)) "ZJADA",
    K1.nr_bandy "NR BANDY",
    AVG(NVL(K2.przydzial_myszy,0)+NVL(K2.myszy_extra,0)) "SREDNIA BANDY"
FROM
    KOCURY K1
JOIN
    KOCURY K2
ON 
    K1.nr_bandy = K2.nr_bandy
WHERE
    k1.PLEC = 'M'
GROUP BY
    K1.IMIE, K1.NR_BANDY
having 
    MIN(NVL(K1.przydzial_myszy,0)+NVL(K1.myszy_extra,0))<
    AVG(NVL(K2.przydzial_myszy,0)+NVL(K2.myszy_extra,0));

--b
select 
    K1.imie, 
    NVL(K1.przydzial_myszy,0)+NVL(K1.myszy_extra,0) "ZJADA",
    K1.nr_bandy "NR Bandy", 
    K2_AVG.AVG
from (
    select 
        K2.nr_bandy,
        AVG(NVL(K2.przydzial_myszy,0)+NVL(K2.myszy_extra,0)) "AVG"
    from 
        Kocury K2
    group by 
        K2.nr_bandy
    ) K2_AVG 
join
    Kocury K1 
on 
    K1.nr_bandy = K2_AVG.nr_bandy and 
    NVL(K1.przydzial_myszy,0) + NVL(K1.myszy_extra,0) < K2_AVG.AVG
where 
    K1.plec='M';

--c
select 
    K1.imie, 
    NVL(K1.przydzial_myszy,0) + NVL(K1.myszy_extra,0) "ZJADA",
    K1.nr_bandy "NR Bandy",
    (
     select 
        AVG(NVL(K2.przydzial_myszy,0)+NVL(K2.myszy_extra,0))
     from 
        Kocury K2
     where 
        K2.nr_bandy = K1.nr_bandy
     group by 
        K2.nr_bandy
     ) "SREDNIA BANDY"
from Kocury K1
where plec = 'M'
and NVL(K1.przydzial_myszy,0)+NVL(K1.myszy_extra,0)<
    (
    select 
        AVG(NVL(K2.przydzial_myszy,0) + NVL(K2.myszy_extra,0))
     from 
        Kocury K2
     where 
        K2.nr_bandy = K1.nr_bandy
     group by 
        K2.nr_bandy
    );

-- 30
WITH daty AS
(
SELECT 
    K.nr_bandy,
    MAX(B.nazwa) nazwa,
    MAX(K.w_stadku_od) najmlodszy,
    MIN(K.w_stadku_od) najstarszy
FROM 
    Kocury K
INNER JOIN 
    Bandy B
ON 
    K.nr_bandy = B.nr_bandy
GROUP BY
    K.nr_bandy
)(
SELECT
    K.IMIE,
    K.W_STADKU_OD "WSTAPIL DO STADKA",
    '<--- NAJSTARSZY STAZEM W BANDZIE ' || D.nazwa " "
FROM
    Kocury K
INNER JOIN
    daty D
ON 
    D.nr_bandy = K.nr_bandy
WHERE 
    K.w_stadku_od = D.najstarszy
    
UNION

SELECT
    K.IMIE,
    K.W_STADKU_OD "WSTAPIL DO STADKA",
    '<--- NAJMLODSZY STAZEM W BANDZIE ' || D.nazwa " "
FROM
    Kocury K
INNER JOIN
    daty D
ON 
    D.nr_bandy = K.nr_bandy
WHERE 
    K.w_stadku_od = D.najmlodszy
    
UNION

SELECT
    K.IMIE,
    K.W_STADKU_OD "WSTAPIL DO STADKA",
    ' '
FROM
    Kocury K
INNER JOIN
    daty D
ON 
    D.nr_bandy = K.nr_bandy
WHERE 
    NOT K.w_stadku_od = D.najstarszy AND
    NOT K.w_stadku_od = D.najmlodszy 
);
   
--31
CREATE OR REPLACE VIEW Spozycie (NAZWA_BANDY, SRE_SPOZ, MAX_SPOZ, MIN_SPOZ, KOTY, KOTY_Z_DOD)
AS (
SELECT 
    B.NAZWA "NAZWA BANDY",
    AVG(K.PRZYDZIAL_MYSZY) "SRE_SPOZ",
    MAX(K.PRZYDZIAL_MYSZY) "MAX_SPOZ",
    MIN(K.PRZYDZIAL_MYSZY) "MIN_SPOZ",
    COUNT(*) "KOTY",
    COUNT(K.MYSZY_EXTRA) "KOTY_Z_DOD"
FROM 
    BANDY B
INNER JOIN
    KOCURY K
ON 
    K.NR_BANDY = B.NR_BANDY
GROUP BY
    B.NAZWA);

SELECT 
    * 
FROM 
    Spozycie;
    
    
SELECT 
    K.PSEUDO "PSEUDONIM",
    K.IMIE,
    K.FUNKCJA,
    K.przydzial_myszy + NVL(K.myszy_extra, 0) "ZJADA",
    'OD ' || S.MIN_SPOZ || ' DO ' || S.MAX_SPOZ "GRANICE SPOZYCIA",
    K.w_stadku_od "LOWI OD"
FROM 
    KOCURY K
INNER JOIN  
    BANDY B
ON
    B.NR_BANDY = K.NR_BANDY
INNER JOIN 
    Spozycie S
ON
    S.nazwa_bandy = B.nazwa
WHERE
    K.PSEUDO = '&pseudo'
;    

--32
CREATE OR REPLACE VIEW Podwyzki_dla AS 
SELECT 
    pseudo,
    plec, 
    przydzial_myszy, 
    myszy_extra,
    nr_bandy
FROM 
    Kocury 
where pseudo in 
(
    SELECT pseudo
    FROM Kocury JOIN Bandy B 
    ON Kocury.nr_bandy = B.nr_bandy
    WHERE B.nazwa = 'CZARNI RYCERZE'
    ORDER BY w_stadku_od
    FETCH NEXT 3 ROWS ONLY
) 
or pseudo in 
(
    SELECT pseudo
    FROM Kocury join Bandy B 
    ON Kocury.nr_bandy = B.nr_bandy
    WHERE B.nazwa = 'LACIACI MYSLIWI'
    ORDER BY w_stadku_od
    FETCH NEXT 3 ROWS ONLY
);

SELECT * FROM Podwyzki_dla;

UPDATE Podwyzki_dla
SET 
    przydzial_myszy = przydzial_myszy + DECODE(plec, 'D', 0.1 * (SELECT MIN(przydzial_myszy) FROM Kocury), 10),
    myszy_extra = NVL(myszy_extra, 0) + 0.15 * (SELECT AVG(NVl(Kocury.myszy_extra, 0)) FROM Kocury WHERE Podwyzki_dla.nr_bandy = nr_bandy);

SELECT * FROM Podwyzki_dla;

ROLLBACK;

--33
--a
CREATE OR REPLACE VIEW Suma_myszy_kocurow AS
SELECT 
    B.nazwa "NAZWA",
    CASE K.plec
        WHEN 'D' THEN 'Kotka'
        ELSE 'Kocur'
        END "PLEC",
    COUNT(*) ile,
    SUM(DECODE(K.funkcja, 'SZEFUNIO', K.przydzial_myszy + NVL(K.myszy_extra, 0), 0)) "SZEFUNIO", 
    SUM(DECODE(K.funkcja, 'BANDZIOR', K.przydzial_myszy + NVL(K.myszy_extra, 0), 0)) "BANDZIOR", 
    SUM(DECODE(K.funkcja, 'LOWCZY', K.przydzial_myszy + NVL(K.myszy_extra, 0), 0)) "LOWCZY", 
    SUM(DECODE(K.funkcja, 'LAPACZ', K.przydzial_myszy + NVL(K.myszy_extra, 0), 0)) "LAPACZ", 
    SUM(DECODE(K.funkcja, 'KOT', K.przydzial_myszy + NVL(K.myszy_extra, 0), 0)) "KOT", 
    SUM(DECODE(K.funkcja, 'MILUSIA', K.przydzial_myszy + NVL(K.myszy_extra, 0), 0)) "MILUSIA", 
    SUM(DECODE(K.funkcja, 'DZIELCZY', K.przydzial_myszy + NVL(K.myszy_extra, 0), 0)) "DZIELCZY",
    SUM(K.przydzial_myszy + NVL(K.myszy_extra, 0)) "Suma"
FROM
    Kocury K        
INNER JOIN
    Bandy B ON B.nr_bandy = K.nr_bandy
GROUP BY
    B.nazwa, K.plec
ORDER BY 
    B.nazwa, K.plec;

SELECT 
    * 
FROM 
    Suma_myszy_kocurow;
 
 
SELECT
    banda "NAZWA BANDY",
    "PLEC",
    "ILE",
    "SZEFUNIO", 
    "BANDZIOR", 
    "LOWCZY",  
    "LAPACZ",  
    "KOT",  
    "MILUSIA",  
    "DZIELCZY", 
    "Suma"
FROM
(
    (
    SELECT
        "NAZWA" || "PLEC" id_grupy,
        CASE "PLEC" 
            WHEN 'Kocur' THEN "NAZWA" 
            ELSE ' ' 
            END banda,
        "PLEC",
        TO_CHAR(ile) "ILE",
        "SZEFUNIO", 
        "BANDZIOR", 
        "LOWCZY",  
        "LAPACZ",  
        "KOT",  
        "MILUSIA",  
        "DZIELCZY", 
        "Suma"
    FROM Suma_myszy_kocurow
    )
    UNION
    (
    SELECT
        NULL,
        'SUMA',
        ' ',
        ' ',
        SUM("SZEFUNIO"), 
        SUM("BANDZIOR"), 
        SUM("LOWCZY"),  
        SUM("LAPACZ"),  
        SUM("KOT"),  
        SUM("MILUSIA"),  
        SUM("DZIELCZY"), 
        SUM("Suma")
    FROM
        Suma_myszy_kocurow
    )
);

--b
select *
from
(
  select TO_CHAR(DECODE(plec, 'D', nazwa, ' ')) "NAZWA BANDY",
    TO_CHAR(DECODE(plec, 'D', 'Kotka', 'Kocor')) "Plec",
    TO_CHAR(ile) "ILE",
    TO_CHAR(NVL(szefunio, 0)) "SZEFUNIO",
    TO_CHAR(NVL(bandzior,0)) "BANDZIOR",
    TO_CHAR(NVL(lowczy,0)) "LOWCZY",
    TO_CHAR(NVL(lapacz,0)) "LAPACZ",
    TO_CHAR(NVL(kot,0)) "KOT",
    TO_CHAR(NVL(milusia,0)) "MILUSIA",
    TO_CHAR(NVL(dzielczy,0)) "DZIELCZY",
    TO_CHAR(NVL(suma,0)) "SUMA"
  from
  (
    select nazwa, plec, funkcja, przydzial_myszy + NVL(myszy_extra, 0) liczba
    from Kocury join Bandy on Kocury.nr_bandy= Bandy.nr_bandy
  ) pivot (
      sum(liczba) for funkcja in (
      'SZEFUNIO' szefunio, 'BANDZIOR' bandzior, 'LOWCZY' lowczy, 'LAPACZ' lapacz,
      'KOT' kot, 'MILUSIA' milusia, 'DZIELCZY' dzielczy
    )
  ) join (
    select nazwa "N", plec "P", COUNT(pseudo) ile, SUM(przydzial_myszy + NVL(myszy_extra, 0)) suma
    from Kocury K join Bandy B on K.nr_bandy= B.nr_bandy
    group by nazwa, plec
    order by nazwa
  ) on N = nazwa and P = plec
)
union all

select 'Z--------------', '------', '--------', '---------', '---------', '--------', '--------', '--------', '--------', '--------', '--------' FROM DUAL

union all

select  'ZJADA RAZEM',
        ' ',
        ' ',
        TO_CHAR(NVL(szefunio, 0)) szefunio,
        TO_CHAR(NVL(bandzior, 0)) bandzior,
        TO_CHAR(NVL(lowczy, 0)) lowczy,
        TO_CHAR(NVL(lapacz, 0)) lapacz,
        TO_CHAR(NVL(kot, 0)) kot,
        TO_CHAR(NVL(milusia, 0)) milusia,
        TO_CHAR(NVL(dzielczy, 0)) dzielczy,
        TO_CHAR(NVL(suma, 0)) suma
from
(
  select      funkcja, przydzial_myszy + NVL(myszy_extra, 0) liczba
  from        Kocury join Bandy on Kocury.nr_bandy= Bandy.nr_bandy
) pivot (
    SUM(liczba) for funkcja in (
    'SZEFUNIO' szefunio, 'BANDZIOR' bandzior, 'LOWCZY' lowczy, 'LAPACZ' lapacz,
    'KOT' kot, 'MILUSIA' milusia, 'DZIELCZY' dzielczy
  )
) natural join (
  select      SUM(przydzial_myszy + NVL(myszy_extra, 0)) suma
  from       Kocury
);