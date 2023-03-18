-- 1.1 Для начала давайте проанализируем, насколько быстро растёт аудитория нашего сервиса, и посмотрим на динамику числа пользователей и курьеров. 

SELECT qq1.date,
       new_users,
       new_couriers,
       sum(new_users::int) OVER (ORDER BY date rows between unbounded preceding and current row) as total_users,
       sum(new_couriers::int) OVER (ORDER BY date rows between unbounded preceding and current row) as total_couriers
FROM   (SELECT date,
               count(user_id) as new_users
        FROM   (SELECT DISTINCT user_id,
                                min(time::date) as date
                FROM   user_actions
                GROUP BY user_id) as q1
        GROUP BY date
        ORDER BY date) as qq1 join (SELECT date,
                                   count(courier_id) as new_couriers
                            FROM   (SELECT DISTINCT(courier_id),
                                                    min(time::date) as date
                                    FROM   courier_actions
                                    GROUP BY courier_id) as q2
                            GROUP BY date
                            ORDER BY date) as qq2 using(date)
