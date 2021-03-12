-- https://www.duhoctrungquoc.vn/wiki/be-tarask/MediaWiki:Gadget-nt.js
-- https://knihi.com/storage/pravapis2005.html#texth2_8
-- https://knihi.com/storage/pravapis2005.html#texth2_10

CREATE OR REPLACE FUNCTION be2be_tarask(varchar) RETURNS varchar AS $$
DECLARE
    word_str text;
    origin_chr varchar(2);
    chr varchar(2);
    chr_prev varchar(2) := '';
    chr_prev_prev varchar(2) := '';
    chr_prev_prev_prev varchar(2) := '';
    chr_prev_prev_prev_prev varchar(2) := '';
    is_soft bool := False;
    is_soft_prev bool := False;
    char_index int;
    word_end_index int := 0;
    word varchar(2)[];
    reversed_result varchar(2)[] := array[]::varchar(2)[];
    soft_vowels_and_sign varchar(2)[] := array['ь','і','я','е','ё','ю'];
    soft_consonant varchar(2)[] := array['б','в','дз','з','л','м','н','п','с','ц','ф'];  -- without ['г','ґ','к','х']
    vowels varchar(2)[] := array['а', 'е', 'ё', 'і', 'о', 'у', 'ы', 'э', 'ю', 'я'];
    consonant varchar(2)[] := array[
        'б', 'в', 'г', 'ґ', 'д', 'дж', 'дз', 'ж', 'з', 'й', 'к', 'л', 'м', 'н',
        'п', 'р', 'с', 'т', 'ў', 'ф', 'х', 'ц', 'ч', 'ш'
    ];
    letters varchar(2)[] := array[
        'а', 'б', 'в', 'г', 'ґ', 'д', 'дж', 'дз', 'е', 'ё', 'ж', 'з', 'і', 'й', 'к', 'л', 'м', 'н',
        'о', 'п', 'р', 'с', 'т', 'у', 'ў', 'ф', 'х', 'ц', 'ч', 'ш', 'ы', 'ь', 'э', 'ю', 'я'
    ];
    word_stress varchar(2) := E'\u0301';
BEGIN
    word_str := $1;
    IF word_str IS NOT NULL THEN
        word_str := replace(word_str, E'праспе\u0301кт', E'праспэ\u0301кт');
        word_str := replace(word_str, 'праспект', 'праспэкт');

        word := regexp_split_to_array(word_str, '');
        char_index := array_length(word, 1);
        WHILE char_index >= 1 LOOP
            origin_chr := word[char_index];
            chr := lower(origin_chr);
            IF chr = ' ' THEN
                word_end_index := 0;
            ELSIF chr = ANY(letters) THEN
                word_end_index := word_end_index + 1;
            END IF;
            IF chr != word_stress AND chr != ' ' THEN
                -- дз/дж as single letter
                IF chr = 'з' AND char_index > 1 AND lower(word[char_index - 1]) = 'д' THEN
                    chr := 'дз';
                    IF word[char_index - 1] = 'д' THEN
                        origin_chr := 'зд';  -- reverse('дз')
                    ELSE
                        origin_chr := 'зД';  -- reverse('Дз')
                    END IF;
                    char_index := char_index - 1;
                ELSEIF chr = 'ж' AND char_index > 1 AND lower(word[char_index - 1]) = 'д' THEN
                    chr := 'дж';
                    IF word[char_index - 1] = 'д' THEN
                        origin_chr := 'жд';  -- reverse('дж')
                    ELSE
                        origin_chr := 'жД';  -- reverse('Дж')
                    END IF;
                    char_index := char_index - 1;
                END IF;

                is_soft := chr_prev = ANY(soft_vowels_and_sign) AND chr = ANY(soft_consonant);

                -- з'ява -> зьява
                IF (chr = 'з' OR chr = 'с') AND chr_prev = E'\'' AND chr_prev_prev = ANY(soft_vowels_and_sign) THEN
                    reversed_result := reversed_result[1:array_length(reversed_result, 1) - 1];
                    word_end_index := word_end_index - 1;
                    reversed_result := array_append(reversed_result, 'ь');
                    word_end_index := word_end_index + 1;
                    is_soft := True;
                ELSIF is_soft_prev AND (
                    -- збег -> зьбег, снег -> сьнег
                    ((chr = 'з' OR chr = 'с') AND chr_prev = ANY(soft_consonant))
                    -- дзвіна -> дзьвіна
                    OR ((chr = 'ц' OR chr = 'дз') AND chr_prev = 'в')
                    -- насенне -> насеньне
                    OR (chr = chr_prev AND (chr = 'н' OR chr = 'л' OR chr = 'ц' OR chr = 'с'))

                ) THEN
                    reversed_result := array_append(reversed_result, 'ь');
                    word_end_index := word_end_index + 1;
                    is_soft := True;
                ELSEIF (
                    -- стагоддзе -> стагодзьдзе, аддзел -> аддзел
                    is_soft_prev AND chr = 'д' AND chr_prev = 'дз' AND chr_prev_prev = ANY (soft_vowels_and_sign) AND
                    word_end_index = 3
                ) THEN
                    reversed_result := array_append(reversed_result, 'ь');
                    word_end_index := word_end_index + 1;
                    origin_chr := 'зд';
                    is_soft := True;
                END IF;

                IF (
                    -- казахскі -> казаскі, двухскладовы -> двухскладовы
                    (
                        chr = ANY (array ['з', 'с', 'ж', 'ш', 'г', 'х'])
                        AND chr_prev = 'с'
                        AND chr_prev_prev = 'к'
                        AND word_end_index = ANY (array [4, 5])
                    )
                    OR (
                        chr = ANY (array ['з', 'с', 'ж', 'ш', 'г', 'х'])
                        AND chr_prev = 'с'
                        AND chr_prev_prev = 'т'
                        AND chr_prev_prev_prev = 'в'
                        AND word_end_index = ANY (array [5, 6])
                    )
                ) THEN
                    origin_chr := '';
                    word_end_index := word_end_index - 1;
                ELSEIF (
                    -- цюркскі -> цюрскі
                    (
                        chr = ANY (consonant)
                        AND chr_prev = 'к'
                        AND chr_prev_prev = 'с'
                        AND chr_prev_prev_prev = 'к'
                        AND word_end_index = ANY (array [5, 6])
                    )
                    OR (
                        chr = ANY (consonant)
                        AND chr_prev = 'к'
                        AND chr_prev_prev = 'с'
                        AND chr_prev_prev_prev = 'т'
                        AND chr_prev_prev_prev_prev = 'в'
                        AND word_end_index = ANY (array [6, 7])
                    )
                ) THEN
                    reversed_result := reversed_result[1:array_length(reversed_result, 1) - 1];
                    word_end_index := word_end_index - 1;
                ELSEIF (
                    -- ільнаводства -> ільнаводзтва, кембрыджскі -> кембрыдзкі
                    (
                        chr = ANY (array ['д', 'дз', 'дж'])
                        AND chr_prev = 'с'
                        AND chr_prev_prev = 'к'
                        AND word_end_index = ANY (array [4, 5])
                    )
                    OR (
                        chr = ANY (array ['д', 'дз', 'дж'])
                        AND chr_prev = 'с'
                        AND chr_prev_prev = 'т'
                        AND chr_prev_prev_prev = 'в'
                        AND word_end_index = ANY (array [5, 6])
                    )
                ) THEN
                    reversed_result := reversed_result[1:array_length(reversed_result, 1) - 1];
                    word_end_index := word_end_index - 1;
                    origin_chr := 'зд';
                ELSEIF (
                    -- смалявічскі -> смалявіцкі
                    (
                        chr = ANY (array ['т', 'ц', 'ч'])
                        AND chr_prev = 'с'
                        AND chr_prev_prev = 'к'
                        AND word_end_index = ANY (array [4, 5])
                    )
                    OR (
                        chr = ANY (array ['т', 'ц', 'ч'])
                        AND chr_prev = 'с'
                        AND chr_prev_prev = 'т'
                        AND chr_prev_prev_prev = 'в'
                        AND word_end_index = ANY (array [5, 6])
                    )
                ) THEN
                    reversed_result := reversed_result[1:array_length(reversed_result, 1) - 1];
                    word_end_index := word_end_index - 1;
                    origin_chr := 'ц';
                ELSEIF (
                    -- іракскі -> ірацкі
                    (
                        chr = ANY (vowels)
                        AND chr_prev = 'к'
                        AND chr_prev_prev = 'с'
                        AND chr_prev_prev_prev = 'к'
                        AND word_end_index = ANY (array [5, 6])
                    )
                    OR (
                        chr = ANY (vowels)
                        AND chr_prev = 'к'
                        AND chr_prev_prev = 'с'
                        AND chr_prev_prev_prev = 'т'
                        AND chr_prev_prev_prev_prev = 'в'
                        AND word_end_index = ANY (array [6, 7])
                    )
                ) THEN
                    reversed_result := reversed_result[1:array_length(reversed_result, 1) - 2];
                    word_end_index := word_end_index - 2;
                    reversed_result := array_append(reversed_result, 'ц');
                    word_end_index := word_end_index + 1;
                END IF;

                chr_prev_prev_prev_prev = chr_prev_prev_prev;
                chr_prev_prev_prev = chr_prev_prev;
                chr_prev_prev := chr_prev;
                chr_prev := chr;
                is_soft_prev := is_soft;
            END IF;

            reversed_result := array_append(reversed_result, origin_chr);
            char_index := char_index - 1;
        END LOOP;
        word_str := reverse(array_to_string(reversed_result, '', ''));
    END IF;
    RETURN word_str;
END;
$$ LANGUAGE plpgsql;

-- TEST
SELECT
    origin,
    be2be_tarask(origin) AS result,
    should_be,
    origin || ', ' || origin AS origin2,
    be2be_tarask(origin || ', ' || origin) AS result2,
    should_be || ', ' || should_be AS should_be2,
    (be2be_tarask(origin) = should_be AND be2be_tarask(origin || ', ' || origin) = (should_be || ', ' || should_be))
    OR (be2be_tarask(origin) IS NULL AND should_be IS NULL) AS correct
FROM (
    VALUES
    (NULL, NULL),
    ('', ''),

    (E'з\'ява', 'зьява'),
    ('снег', 'сьнег'),
    ('бясснежны', 'бясьсьнежны'),
    ('дзвіна', 'дзьвіна'),
    ('насенне', 'насеньне'),

    ('стагоддзе', 'стагодзьдзе'),
    ('аддзел', 'аддзел'),

    ('казахскі', 'казаскі'),
    ('казахская', 'казаская'),
    ('двухскладовы', 'двухскладовы'),
    ('цюркскі', 'цюрскі'),
    ('цюркская', 'цюрская'),
    ('ільнаводства', 'ільнаводзтва'),
    ('кембрыджскі', 'кембрыдзкі'),
    ('кембрыджская', 'кембрыдзкая'),
    ('смалявічскі', 'смалявіцкі'),
    ('смалявічская', 'смалявіцкая'),
    ('іракскі', 'ірацкі'),
    ('іракская', 'ірацкая')
) AS t (origin, should_be)
ORDER BY correct;
