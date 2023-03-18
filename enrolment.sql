-- Вывести абитуриентов, которые хотят поступать на образовательную программу «Мехатроника и робототехника» в отсортированном по фамилиям виде.

SELECT name_enrollee
FROM enrollee 
    INNER JOIN program_enrollee USING(enrollee_id)
    INNER JOIN program USING(program_id)
WHERE name_program = 'Мехатроника и робототехника'
ORDER BY name_enrollee;

-- Вывести образовательные программы, на которые для поступления необходим предмет «Информатика». Программы отсортировать в обратном алфавитном порядке.

SELECT name_program
FROM program INNER JOIN program_subject USING(program_id) INNER JOIN subject USING(subject_id)
WHERE name_subject = 'Информатика'
ORDER BY name_program DESC;

-- Выведите количество абитуриентов, сдавших ЕГЭ по каждому предмету, максимальное, минимальное и среднее значение баллов по предмету ЕГЭ. Вычисляемые столбцы назвать Количество, Максимум, Минимум, Среднее. Информацию отсортировать по названию предмета в алфавитном порядке, среднее значение округлить до одного знака после запятой.

SELECT name_subject, COUNT(enrollee_id) AS Количество, MAX(result) AS Максимум, MIN(result) AS Минимум, ROUND(AVG(result),1) AS Среднее
FROM subject INNER JOIN enrollee_subject USING(subject_id)
GROUP BY subject_id
ORDER BY 1;

-- Вывести образовательные программы, для которых минимальный балл ЕГЭ по каждому предмету больше или равен 40 баллам. Программы вывести в отсортированном по алфавиту виде.

SELECT name_program
FROM program
    INNER JOIN program_subject USING(program_id)
GROUP BY name_program
HAVING MIN(min_result) >= 40
ORDER BY 1;

-- Посчитать, сколько дополнительных баллов получит каждый абитуриент. Столбец с дополнительными баллами назвать Бонус. Информацию вывести в отсортированном по фамилиям виде.

SELECT name_enrollee, if(sum(bonus) is null, 0, sum(bonus)) AS Бонус
FROM enrollee
    LEFT JOIN enrollee_achievement USING(enrollee_id)
    LEFT JOIN achievement USING(achievement_id)
GROUP BY name_enrollee
ORDER BY name_enrollee;

-- Вывести образовательные программы, на которые для поступления необходимы предмет «Информатика» и «Математика» в отсортированном по названию программ виде.

select name_program
from program 
    inner join program_subject using(program_id)
    inner join subject using(subject_id)
where name_subject = 'Математика' or name_subject = 'Информатика'
group by name_program
having count(name_subject) = 2
order by 1;

-- Посчитать количество баллов каждого абитуриента на каждую образовательную программу, на которую он подал заявление, по результатам ЕГЭ. В результат включить название образовательной программы, фамилию и имя абитуриента, а также столбец с суммой баллов, который назвать itog. 
-- Информацию вывести в отсортированном сначала по образовательной программе, а потом по убыванию суммы баллов виде.

select name_program, name_enrollee, sum(result) as itog
from enrollee
    inner join program_enrollee using(enrollee_id)
    inner join program using(program_id)
    inner join program_subject using(program_id)
    inner join subject using(subject_id)
    inner join enrollee_subject on subject.subject_id = enrollee_subject.subject_id 
and enrollee_subject.enrollee_id = enrollee.enrollee_id
group by name_program, name_enrollee
order by name_program, itog desc;

-- Вывести название образовательной программы и фамилию тех абитуриентов, которые подавали документы на эту образовательную программу, но не могут быть зачислены на нее. 
-- Эти абитуриенты имеют результат по одному или нескольким предметам ЕГЭ, необходимым для поступления на эту образовательную программу, меньше минимального балла. 
-- Информацию вывести в отсортированном сначала по программам, а потом по фамилиям абитуриентов виде.

select name_program, name_enrollee
from enrollee
    inner join program_enrollee using(enrollee_id)
    inner join program using(program_id)
    inner join program_subject using(program_id)
    inner join subject using(subject_id)
    inner join enrollee_subject on subject.subject_id = enrollee_subject.subject_id 
and enrollee_subject.enrollee_id = enrollee.enrollee_id
where enrollee_subject.result < program_subject.min_result
group by name_program, name_enrollee
order by 1,2;

----------------------------------------------------------------------------------------------------------------------------------------

-- Создать вспомогательную таблицу applicant,  куда включить id образовательной программы, id абитуриента, сумму баллов абитуриентов в отсортированном сначала по id образовательной программы, а потом по убыванию суммы баллов виде.

CREATE TABLE applicant AS
SELECT program_id, enrollee.enrollee_id, SUM(result) AS itog
from enrollee
    inner join program_enrollee using(enrollee_id)
    inner join program using(program_id)
    inner join program_subject using(program_id)
    inner join subject using(subject_id)
    inner join enrollee_subject on subject.subject_id = enrollee_subject.subject_id 
and enrollee_subject.enrollee_id = enrollee.enrollee_id
group by program_id, enrollee.enrollee_id
order by program_id, itog desc;

SELECT * FROM applicant;

-- Из таблицы applicant, созданной на предыдущем шаге, удалить записи, если абитуриент на выбранную образовательную программу не набрал минимального балла хотя бы по одному предмету.

DELETE FROM applicant
WHERE (program_id, enrollee_id) IN 
(
    SELECT DISTINCT program_id, enrollee.enrollee_id
    from enrollee
    inner join program_enrollee using(enrollee_id)
    inner join program using(program_id)
    inner join program_subject using(program_id)
    inner join subject using(subject_id)
    inner join enrollee_subject on subject.subject_id = enrollee_subject.subject_id 
and enrollee_subject.enrollee_id = enrollee.enrollee_id
where enrollee_subject.result < program_subject.min_result
group by name_program, name_enrollee
);

-- Повысить итоговые баллы абитуриентов в таблице applicant на значения дополнительных баллов.

UPDATE 
    applicant
    INNER JOIN (SELECT enrollee_id, if(sum(bonus) is null, 0, sum(bonus)) AS bonuss
                    FROM enrollee
                        LEFT JOIN enrollee_achievement USING(enrollee_id)
                        LEFT JOIN achievement USING(achievement_id)
                    GROUP BY enrollee_id) as bob USING(enrollee_id)
SET itog = itog + bonuss;
SELECT * FROM applicant