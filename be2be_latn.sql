-- https://be-tarask.wikipedia.org/wiki/%D0%9B%D0%B0%D1%86%D1%96%D0%BD%D0%BA%D0%B0

CREATE OR REPLACE FUNCTION be2be_latn(varchar) RETURNS varchar AS $$
DECLARE
    word_str text;
    word varchar(2)[];
    chr varchar(1);
    chr_prev varchar(1) := '';
    str_len int;
    char_index int;
    detected bool;
    signs varchar(2)[] := array['Ь','ь'];
    signs_l varchar(2)[] := array['Ь','І','Я','Е','Ё','Ю','ь','і','я','е','ё','ю'];
    consonant varchar(1)[] := array[
        'Б', 'В', 'Г', 'Ґ', 'Д', 'Ж', 'З', 'К', 'Л', 'М', 'Н', 'П', 'Р', 'С', 'Т', 'Ф', 'Х', 'Ц', 'Ч', 'Ш',
        'б', 'в', 'г', 'ґ', 'д', 'ж', 'з', 'к', 'л', 'м', 'н', 'п', 'р', 'с', 'т', 'ф', 'х', 'ц', 'ч', 'ш'
    ];
    cyr_letters varchar(1)[] := array[
        'А', 'Б', 'В', 'Г', 'Ґ', 'Д', 'Е', 'Ё', 'Ж', 'З', 'І', 'Й', 'К', 'Л', 'М', 'Н', 'О',
        'П', 'Р', 'С', 'Т', 'У', 'Ў', 'Ф', 'Х', 'Ц', 'Ч', 'Ш', 'Ы', 'Ь', 'Э', 'Ю', 'Я',
        'а', 'б', 'в', 'г', 'ґ', 'д', 'е', 'ё', 'ж', 'з', 'і', 'й', 'к', 'л', 'м', 'н', 'о',
        'п', 'р', 'с', 'т', 'у', 'ў', 'ф', 'х', 'ц', 'ч', 'ш', 'ы', 'ь', 'э', 'ю', 'я',
        '’', E'\''
    ];
    lat_letters varchar(2)[] := array[
        'A', 'B', 'V', 'H', 'G', 'D', 'Je', 'Jo', 'Ž', 'Z', 'I', 'J', 'K', 'Ł', 'M', 'N', 'O',
        'P', 'R', 'S', 'T', 'U', 'Ŭ', 'F', 'Ch', 'C', 'Č', 'Š', 'Y', '', 'E', 'Ju', 'Ja',
        'a', 'b', 'v', 'h', 'g', 'd', 'je', 'jo', 'ž', 'z', 'i', 'j', 'k', 'ł', 'm', 'n', 'o',
        'p', 'r', 's', 't', 'u', 'ŭ', 'f', 'ch', 'c', 'č', 'š', 'y', '', 'e', 'ju', 'ja',
        '', ''
    ];
    -- _Е - Je - Io, _Ё - Jo - Io, _Ю - Ju - Iu, _Я - Ja - Ia
    -- Зь - Z - Ź, Ль - Ł - L, Нь - N - Ń, Сь - S - Ś, Ць - C - Ć
    -- _е - je - io, _ё - jo - io, _ю - ju - iu, _я - ja - ia
    -- зь - z - ź, ль - ł - l, нь - n - ń, сь - s - ś, ць - c - ć
    word_stress varchar(1) := E'\u0301';
    result varchar(2)[] := array[]::varchar(2)[];
BEGIN
    word_str := $1;
    IF word_str IS NOT NULL THEN
        word := regexp_split_to_array(word_str, '');
        str_len := array_length(word, 1);
        char_index := 1;
        chr_prev := '';
        WHILE char_index <= str_len LOOP
            chr := word[char_index];
            -- handle ЕЁЮЯеёюя
            IF chr = 'Е' THEN
                IF chr_prev = ANY(consonant) THEN
                    result := array_append(result, 'Ie');
                ELSE
                    result := array_append(result, 'Je');
                END IF;
            ELSEIF chr = 'е' THEN
                IF chr_prev = ANY(consonant) THEN
                    result := array_append(result, 'ie');
                ELSE
                    result := array_append(result, 'je');
                END IF;
            ELSEIF chr = 'Ё' THEN
                IF chr_prev = ANY(consonant) THEN
                    result := array_append(result, 'Io');
                ELSE
                    result := array_append(result, 'Jo');
                END IF;
            ELSEIF chr = 'ё' THEN
                IF chr_prev = ANY(consonant) THEN
                    result := array_append(result, 'io');
                ELSE
                    result := array_append(result, 'jo');
                END IF;
            ELSEIF chr = 'Ю' THEN
                IF chr_prev = ANY(consonant) THEN
                    result := array_append(result, 'Iu');
                ELSE
                    result := array_append(result, 'Ju');
                END IF;
            ELSEIF chr = 'ю' THEN
                IF chr_prev = ANY(consonant) THEN
                    result := array_append(result, 'iu');
                ELSE
                    result := array_append(result, 'ju');
                END IF;
            ELSEIF chr = 'Я' THEN
                IF chr_prev = ANY(consonant) THEN
                    result := array_append(result, 'Ia');
                ELSE
                    result := array_append(result, 'Ja');
                END IF;
            ELSEIF chr = 'я' THEN
                IF chr_prev = ANY(consonant) THEN
                    result := array_append(result, 'ia');
                ELSE
                    result := array_append(result, 'ja');
                END IF;
            -- handle Лл
            ELSEIF chr = 'Л' AND char_index < str_len AND word[char_index + 1] = ANY(signs_l) THEN
                result := array_append(result, 'L');
                -- handle ЕЁЮЯеёюя after Л
                IF word[char_index + 1] = 'Е' THEN
                    result := array_append(result, 'E');
                    chr_prev := chr;
                    char_index := char_index + 1;
                ELSEIF word[char_index + 1] = 'е' THEN
                    result := array_append(result, 'e');
                    chr_prev := chr;
                    char_index := char_index + 1;
                ELSEIF word[char_index + 1] = 'Ё' THEN
                    result := array_append(result, 'O');
                    chr_prev := chr;
                    char_index := char_index + 1;
                ELSEIF word[char_index + 1] = 'ё' THEN
                    result := array_append(result, 'o');
                    chr_prev := chr;
                    char_index := char_index + 1;
                ELSEIF word[char_index + 1] = 'Ю' THEN
                    result := array_append(result, 'U');
                    chr_prev := chr;
                    char_index := char_index + 1;
                ELSEIF word[char_index + 1] = 'ю' THEN
                    result := array_append(result, 'u');
                    chr_prev := chr;
                    char_index := char_index + 1;
                ELSEIF word[char_index + 1] = 'Я' THEN
                    result := array_append(result, 'A');
                    chr_prev := chr;
                    char_index := char_index + 1;
                ELSEIF word[char_index + 1] = 'я' THEN
                    result := array_append(result, 'a');
                    chr_prev := chr;
                    char_index := char_index + 1;
                END IF;
            ELSEIF chr = 'л' AND char_index < str_len AND word[char_index + 1] = ANY(signs_l) THEN
                result := array_append(result, 'l');
                -- handle ЕЁЮЯеёюя after л
                IF word[char_index + 1] = 'Е' THEN
                    result := array_append(result, 'E');
                    chr_prev := chr;
                    char_index := char_index + 1;
                ELSEIF word[char_index + 1] = 'е' THEN
                    result := array_append(result, 'e');
                    chr_prev := chr;
                    char_index := char_index + 1;
                ELSEIF word[char_index + 1] = 'Ё' THEN
                    result := array_append(result, 'O');
                    chr_prev := chr;
                    char_index := char_index + 1;
                ELSEIF word[char_index + 1] = 'ё' THEN
                    result := array_append(result, 'o');
                    chr_prev := chr;
                    char_index := char_index + 1;
                ELSEIF word[char_index + 1] = 'Ю' THEN
                    result := array_append(result, 'U');
                    chr_prev := chr;
                    char_index := char_index + 1;
                ELSEIF word[char_index + 1] = 'ю' THEN
                    result := array_append(result, 'u');
                    chr_prev := chr;
                    char_index := char_index + 1;
                ELSEIF word[char_index + 1] = 'Я' THEN
                    result := array_append(result, 'A');
                    chr_prev := chr;
                    char_index := char_index + 1;
                ELSEIF word[char_index + 1] = 'я' THEN
                    result := array_append(result, 'a');
                    chr_prev := chr;
                    char_index := char_index + 1;
                END IF;
            -- handle soft consonant ЗНСЦзнсц
            ELSEIF chr = 'З' AND char_index < str_len AND word[char_index + 1] = ANY(signs) THEN
                result := array_append(result, 'Ź');
            ELSEIF chr = 'з' AND char_index < str_len AND word[char_index + 1] = ANY(signs) THEN
                result := array_append(result, 'ź');
            ELSEIF chr = 'Н' AND char_index < str_len AND word[char_index + 1] = ANY(signs) THEN
                result := array_append(result, 'Ń');
            ELSEIF chr = 'н' AND char_index < str_len AND word[char_index + 1] = ANY(signs) THEN
                result := array_append(result, 'ń');
            ELSEIF chr = 'С' AND char_index < str_len AND word[char_index + 1] = ANY(signs) THEN
                result := array_append(result, 'Ś');
            ELSEIF chr = 'с' AND char_index < str_len AND word[char_index + 1] = ANY(signs) THEN
                result := array_append(result, 'ś');
             ELSEIF chr = 'Ц' AND char_index < str_len AND word[char_index + 1] = ANY(signs) THEN
                result := array_append(result, 'Ć');
            ELSEIF chr = 'ц' AND char_index < str_len AND word[char_index + 1] = ANY(signs) THEN
                result := array_append(result, 'ć');
            ELSE
                -- handle other letters
                detected := FALSE;
                FOR i IN 1..array_length(cyr_letters, 1) LOOP
                    IF chr = cyr_letters[i] THEN
                        detected := TRUE;
                        result := array_append(result, lat_letters[i]);
                        EXIT;
                    END IF;
                END LOOP;
                -- handle other symbols
                IF NOT detected THEN
                    result := array_append(result, chr);
                END IF;
            END IF;

            -- handle stress char
            IF chr != word_stress THEN
                chr_prev := chr;
            END IF;
            char_index := char_index + 1;
        END LOOP;
        word_str := array_to_string(result, '', '');
    END IF;
    RETURN word_str;
END;
$$ LANGUAGE plpgsql;

-- TEST
SELECT
    origin,
    be2be_latn(origin) AS result,
    should_be,
    origin || ', ' || origin AS origin2,
    be2be_latn(origin || ', ' || origin) AS result2,
    should_be || ', ' || should_be AS should_be2,
    (be2be_latn(origin) = should_be AND be2be_latn(origin || ', ' || origin) = (should_be || ', ' || should_be))
    OR (be2be_latn(origin) IS NULL AND should_be IS NULL) AS correct
FROM (
    VALUES
    (NULL, NULL),
    ('', ''),

    ('Зьява', 'Źjava'),
    (E'З’ява', 'Zjava'),
    (E'З\'ява', 'Zjava'),
    (E'За\u0301ява', E'Za\u0301java'),
    (E'Зая\u0301ва', E'Zaja\u0301va'),
    (E'Заява\u0301', E'Zajava\u0301'),
    ('Заява', 'Zajava'),
    ('Йява', 'Jjava'),
    ('Ўява', 'Ŭjava'),
    ('Уява', 'Ujava'),
    ('Зява', 'Ziava'),
    ('Ява', 'Java'),
    ('А-ява', 'A-java'),
    ('Мая ява', 'Maja java'),

    ('Сязон', 'Siazon'),
    ('Сез', 'Siez'),
    ('Сень', 'Sień'),
    ('Сель', 'Siel'),
    ('Сесь', 'Sieś'),
    ('Сець', 'Sieć'),
    ('Сезь', 'Sieź'),

    ('Лда', 'Łda'),
    ('Лада', 'Łada'),
    ('Лода', 'Łoda'),
    ('Луда', 'Łuda'),
    ('Лыда', 'Łyda'),
    ('Лэда', 'Łeda'),
    ('Льда', 'Lda'),
    ('Ліда', 'Lida'),
    ('Леда', 'Leda'),
    ('Лёда', 'Loda'),
    ('Люда', 'Luda'),
    ('Ляда', 'Lada')
) AS t (origin, should_be)
ORDER BY correct;
