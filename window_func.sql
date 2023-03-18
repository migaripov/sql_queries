-- Queries With Window Functions

-- Rank. Top Earning Employees in Each Department

with q1 as (select
  dense_rank() over w as `rank`,
  name, department, salary, id
from employees
window w as (partition by department order by salary desc)
order by `rank`, id
    ) 
    
select id, name, department, max(salary) as salary
from q1
group by department, id, name
limit 3;

-- Lag. For Each Employee (in ascending order by salary) Show Salary of the Previous and Next Employee.

select
  name, department,
  lag(salary, 1) over w as prev,
  salary,
  lead(salary, 1) over w as next
from employees
window w as (order by salary)
order by salary, id;

-- Employee Salary to Max. Salary in the City Ratio

select name, city, salary, round(salary*100 / last_value(salary) over w) as percent
from employees
window w as (
  partition by city
  order by salary
  rows between unbounded preceding and unbounded following
	)
order by city, salary;

-- For Every Employee:
	-- how many people in department
	-- average salary in department
	-- salary to average salary ratio

select name, department, salary,
    count(id) over w as emp_cnt,
    round(avg(salary) over w) as sal_avg,
    round((salary - avg(salary) over w) * 100.0 / avg(salary) over w) as diff
from employees
window w as (partition by department)
order by 2, 3, 1;

-- Rolling Sum of Salaries by Department

select id, name, department, salary,
    sum(salary) over w as total
from employees
window w as (
    partition by department
    rows between unbounded preceding and current row)
order by department, salary, id

