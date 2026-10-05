select * from Goals;
select * from Matches;
select * from Players;
select * from Stadium;
select * from teams;

-- Goal Table analysis
--1.	Which player scored the most goals in a each season?

WITH GoalCounts AS (
    SELECT 
        m.season,
        g.pid,
        COUNT(*) AS total_goals,
        ROW_NUMBER() OVER (
            PARTITION BY m.season 
            ORDER BY COUNT(*) DESC
        ) AS rn
    FROM Goals g
    JOIN Matches m ON g.match_id = m.match_id
    GROUP BY m.season, g.pid
)

SELECT 
    season,
    pid,
    total_goals
FROM GoalCounts
WHERE rn = 1;
--2.	How many goals did each player score in a given season?
select 
     Goals.pid,
	 Matches.season as Season,
	 count(*) as Total_Goals
from Goals
join Matches
on Goals.match_id = Matches.match_id
group by Season, Goals.pid
order by Season;
--3.	What is the total number of goals scored in ‘mt403’ match?
select 
     match_id,
	 count(*) as Total_goals
from Goals
where match_id = 'mt403'
group by match_id;
--4.	Which player assisted the most goals in a each season?
with AssistRank as(
select 
    Goals.assist as Player,
	Matches.season as Seasons,
	Players.first_name || ' ' || Players.last_name AS Player_Name,
	count(*) as Total_assist,
	Row_number() over(
          partition by Matches.season
		  order by count(*) desc
	) as rn
from Goals
join Matches on Goals.match_id = Matches.match_id
LEFT JOIN Players ON Goals.assist = Players.player_id
group by Player , Seasons , Player_name
order by Total_assist desc
)
select * from AssistRank
where rn = 1;
--5.	Which players have scored goals in more than 10 matches?
SELECT 
    pid,
    COUNT(DISTINCT match_id) AS matches_with_goals
FROM Goals
GROUP BY pid
HAVING COUNT(DISTINCT match_id) > 10;
--6.	What is the average number of goals scored per match in a given season?
select 
    Count(Distinct Goals.match_id) as Matches , 
	Matches.season as Season,
	count(*) as Total_goals,
	ROUND(COUNT(*) * 1.0 / COUNT(DISTINCT Goals.match_id), 2) AS Avg_Goals_Per_Match
from Goals
join Matches on Goals.match_id = Matches.match_id
group by Season;
--7.	Which player has the most goals in a single match?
select 
    pid,
	match_id,
	Count(*) as Goals_per_match
from Goals
group by pid, match_id
order by Goals_per_match desc;
--8.	Which team scored the most goals in the all seasons?
select Team , sum(Total_goals) as Overall_Goals
from(
   select
        home_team as Team,
		sum(home_team_score) as Total_goals
		from Matches
		group by Team
	union all
	select 
	     away_team as Team,
		 sum(away_team_score) as Total_goals
		 from Matches
		 group by Team
) as Team_Goals
Group by Team
order by Overall_Goals desc;
--9.	Which stadium hosted the most goals scored in a single season?
WITH Stadium_goals_analysis AS (
    SELECT 
        Matches.stadium AS Stadium,
        Matches.season AS Season,
        COUNT(*) AS Total_goals,
        ROW_NUMBER() OVER (
            PARTITION BY Matches.season 
            ORDER BY COUNT(*) DESC
        ) AS rn
    FROM Goals
    JOIN Matches ON Goals.match_id = Matches.match_id
    GROUP BY Matches.stadium, Matches.season
)
SELECT * 
FROM Stadium_goals_analysis
WHERE rn = 1;

--Match Analysis (From the Matches table)
--10.	What was the highest-scoring match in a particular season?
WITH match_goals AS (
    SELECT 
        match_id,
        season,
        stadium,
        home_team_score + away_team_score AS total_goals
    FROM Matches
),
ranked_matches AS (
    SELECT 
        match_id,
        season,
        stadium,
        total_goals,
        ROW_NUMBER() OVER (
            PARTITION BY season
            ORDER BY total_goals DESC
        ) AS rn
    FROM match_goals
)
SELECT * 
FROM ranked_matches
WHERE rn = 1;
SELECT 
  season, 
  COUNT(match_id) AS total_matches_in_draw
FROM Matches
WHERE away_team_score = home_team_score
GROUP BY season
ORDER BY season;
--12.	Which team had the highest average score (home and away) in the season 2021-2022?
SELECT 
  team,
  SUM(total_goals) AS total_goals,
  ROUND(SUM(total_goals) * 1.0 / SUM(matches_played), 2) AS average_goals
FROM (
    SELECT 
      home_team AS team,
      SUM(home_team_score) AS total_goals,
      COUNT(*) AS matches_played
    FROM Matches
    WHERE season = '2021-2022'
    GROUP BY home_team

    UNION ALL

    SELECT 
      away_team AS team,
      SUM(away_team_score) AS total_goals,
      COUNT(*) AS matches_played
    FROM Matches
    WHERE season = '2021-2022'
    GROUP BY away_team
) AS team_goals
GROUP BY team
ORDER BY total_goals DESC;
--13.	How many penalty shootouts occurred in a each season?
SELECT
  COUNT(penalty_shoot_out) AS penalty_shootout,
  season
FROM matches
WHERE penalty_shoot_out = 1
GROUP BY season;
--14.	What is the average attendance for home teams in the 2021-2022 season?
SELECT 
    Home_team,
    attendance AS Total_attendance,
    ROUND(attendance::numeric / matches_played) AS Average_attendance
FROM (
    SELECT 
        home_team AS Home_team,
        SUM(attendance) AS attendance,
        COUNT(*) AS matches_played
    FROM Matches
    WHERE season = '2021-2022'
    GROUP BY home_team
) AS avg_attendance;
--15.	Which stadium hosted the most matches in a each season?
with Stadium_matches_per_season as(
select 
   stadium,
   season,
   count(*) as Matches_played,
   row_number() over(
   partition by season
   order by count(*) desc
   )as rn
from Matches
group by stadium,season
)
select * from Stadium_matches_per_season
where rn = 1;
--16.	What is the distribution of matches played in different countries in a season?
select 
    Matches.season , 
	stadium.country,
	count(*) as Matches_played,
	ROUND(100.0 * COUNT(*) / SUM(COUNT(*)) OVER (PARTITION BY Matches.season), 2) AS percentage_of_total
from Matches
join stadium on Matches.stadium = stadium.name
group by Matches.season , stadium.country
ORDER BY Matches.season, matches_played DESC;
--17.	What was the most common result in matches (home win, away win, draw)?
SELECT 
    result,
    COUNT(*) AS match_count
FROM (
    SELECT 
        CASE
            WHEN home_team_score > away_team_score THEN 'Home Win'
            WHEN home_team_score < away_team_score THEN 'Away Win'
            ELSE 'Draw'
        END AS result
    FROM Matches
) AS result_table
GROUP BY result
ORDER BY match_count DESC;
--Player Analysis (From the Players table)
--18.	Which players have the highest total goals scored (including assists)?
-- a. Create view for total goals
CREATE OR REPLACE VIEW Total_goals_score AS 
SELECT 
    players.player_id,
    players.first_name,
    players.last_name,
    COUNT(*) AS total_goals
FROM goals
JOIN players ON goals.pid = players.player_id
GROUP BY players.player_id, players.first_name, players.last_name;

-- b. Create view for total assists
CREATE OR REPLACE VIEW Total_assist AS
SELECT 
    players.player_id,
    players.first_name,
    players.last_name,
    COUNT(*) AS total_assists
FROM goals
JOIN players ON goals.assist = players.player_id
WHERE goals.assist IS NOT NULL
GROUP BY players.player_id, players.first_name, players.last_name;

-- c. Final combined query
SELECT 
    g.player_id,
    g.first_name,
    g.last_name,
    COALESCE(g.total_goals, 0) + COALESCE(a.total_assists, 0) AS total_goals_and_assists
FROM Total_goals_score g
JOIN Total_assist a ON g.player_id = a.player_id
ORDER BY total_goals_and_assists DESC;

--19.	What is the average height and weight of players per position?
SELECT
    position,
    ROUND(SUM(height)::numeric / COUNT(*), 2) AS average_height,
    ROUND(SUM(weight)::numeric / COUNT(*), 2) AS average_weight,
    COUNT(*) as total_players
FROM players
GROUP BY position
HAVING COUNT(*) >= 100;
--20.	Which player has the most goals scored with their left foot?
with Goals_by_foot as(
select 
    players.player_id as Player_id,
	players.first_name as First_name,
	players.last_name as Last_name,
	players.foot as Foot,
	count(*) as Total_Goals
from goals
join players
on goals.pid = players.player_id
group by player_id,First_name,Last_name,Foot
)
select * from Goals_by_foot
where Foot = 'L'
order by total_goals desc
limit 3;
--21.	What is the average age of players per team?
SELECT 
    team AS Team,
    ROUND(AVG(DATE_PART('year', AGE(CURRENT_DATE, dob)))::NUMERIC, 2) AS Average_Age
FROM players
GROUP BY team;
--22.	How many players are listed as playing for a each team in a season?
SELECT 
    m.season,
    p.team,
    COUNT(DISTINCT p.player_id) AS Total_Players
FROM players p
JOIN matches m
  ON p.team = m.home_team OR p.team = m.away_team
GROUP BY m.season, p.team
ORDER BY m.season, Total_Players DESC;
--23.	Which player has played in the most matches in the each season?
--24.	What is the most common position for players across all teams?
select 
    Distinct(position) as Position,
	count(position) as Position_count
from players
group by position
order by Position_count desc;
--25.	Which players have never scored a goal?
with Player_goals as(
select 
    p.player_id as Player_id,
	p.first_name,
	p.last_name,
    count(g.pid) as Total_goals
from players p
left join goals g on p.player_id = g.pid
group by p.player_id,p.first_name,p.last_name
) 
select * from Player_goals
where total_goals = 0;
--Team Analysis (From the Teams table)
--26.	Which team has the largest home stadium in terms of capacity?
select
   m.home_team as Home_team,
   s.name as Home_team_stadium,
   s.capacity
from stadium s
join Matches m on s.name = m.stadium
order by capacity desc
limit 1;
--27.	Which teams from a each country participated in the UEFA competition in a season?
select 
    t.country as Country,
	m.season as Season,
	count(t.team_name) as Team_count
from teams t
left join Matches m 
on t.team_name  = m.home_team OR t.team_name = m.away_team
group by Country,Season
order by Season;
--28.	Which team scored the most goals across home and away matches in a given season?
SELECT 
  team,
  season,
  SUM(total_goals) AS total_goals
FROM (
    SELECT 
      home_team AS team,
      season,
      SUM(home_team_score) AS total_goals
    FROM Matches
    GROUP BY home_team, season

    UNION ALL

    SELECT 
      away_team AS team,
      season,
      SUM(away_team_score) AS total_goals
    FROM Matches
    GROUP BY away_team, season
) AS team_goal
GROUP BY team, season
ORDER BY season,total_goals DESC;
--29.	How many teams have home stadiums in a each city or country?
SELECT 
    s.city,
    s.country,
    COUNT(DISTINCT t.team_name) AS team_count
FROM teams t
JOIN stadium s ON t.home_stadium = s.name
GROUP BY s.city, s.country
ORDER BY s.country, s.city;
--30.	Which teams had the most home wins in the 2021-2022 season?
SELECT 
    home_team AS team,
    COUNT(*) AS home_wins
FROM matches
WHERE season = '2021-2022'
  AND home_team_score > away_team_score
GROUP BY home_team
ORDER BY home_wins DESC;
--Stadium Analysis (From the Stadiums table)
--31.	Which stadium has the highest capacity?
select
    name,
	capacity
from stadium
order by capacity desc;
--32.	How many stadiums are located in a ‘Russia’ country or ‘London’ city?
select 
    count(*)
from stadium
where country = 'Russia' or city = 'London';
--33.	Which stadium hosted the most matches during a season?
with Stadium_matches_per_season as(
select 
   stadium,
   season,
   count(*) as Matches_played,
   row_number() over(
   partition by season
   order by count(*) desc
   )as rn
from Matches
group by stadium,season
)
select * from Stadium_matches_per_season
where rn = 1;
--34.	What is the average stadium capacity for teams participating in a each season?
SELECT 
    m.season,
    m.stadium,
    s.capacity
FROM matches m
JOIN stadium s ON m.stadium = s.name
GROUP BY m.season, m.stadium, s.capacity
ORDER BY m.season, s.capacity DESC;
--35.	How many teams play in stadiums with a capacity of more than 50,000?
select 
    t.team_name,
	s.capacity
from stadium s
join teams t on s.name = t.home_stadium
where s.capacity > 50000;
--36.	Which stadium had the highest attendance on average during a season?
WITH stadium_attendance AS (
    SELECT 
        season,
        stadium,
        ROUND(AVG(attendance)) AS avg_attendance,
        ROW_NUMBER() OVER (PARTITION BY season ORDER BY AVG(attendance) DESC) AS rn
    FROM matches
    WHERE attendance IS NOT NULL
    GROUP BY season, stadium
)
SELECT 
    season, 
    stadium, 
    avg_attendance
FROM stadium_attendance
WHERE rn = 1;

--37.	What is the distribution of stadium capacities by country?
SELECT 
    country,
    COUNT(*) AS stadium_count,
    ROUND(AVG(capacity)) AS avg_capacity,
    MAX(capacity) AS max_capacity,
    MIN(capacity) AS min_capacity
FROM stadium
GROUP BY country
ORDER BY avg_capacity DESC;
--Cross-Table Analysis (Combining multiple tables)
--38.	Which players scored the most goals in matches held at a specific stadium?
select 
    g.pid as Player_id,
    count(g.pid) as Total_goals,
	Matches.stadium as Stadium
from goals g
join Matches on g.match_id = Matches.match_id
group by Player_id,Stadium
order by Total_goals desc;
--39.	Which team won the most home matches in the season 2021-2022 (based on match scores)?
SELECT 
    home_team,
    COUNT(*) AS home_wins
FROM Matches
WHERE season = '2021-2022'
  AND home_team_score > away_team_score
GROUP BY home_team
ORDER BY home_wins DESC
LIMIT 1;
--40.	Which players played for a team that scored the most goals in the 2021-2022 season?
create view  Team_goals_2021_2022_season as
select Team , sum(Total_goals) as Overall_Goals
from(
   select
        home_team as Team,
		sum(home_team_score) as Total_goals
		from Matches
		where season = '2021-2022'
		group by Team
	union all
	select 
	     away_team as Team,
		 sum(away_team_score) as Total_goals
		 from Matches
		 where season = '2021-2022'
		 group by Team
) as Team_Goals
Group by Team
order by Overall_Goals desc;

WITH Top_Team AS (
    SELECT Team
    FROM Team_goals_2021_2022_season
    ORDER BY Overall_Goals DESC
    LIMIT 1
)
SELECT 
    p.first_name,
    p.last_name,
    p.player_id,
    p.team
FROM players p
JOIN Top_Team t ON p.team = t.Team;

--41.	How many goals were scored by home teams in matches where the attendance was above 50,000?
select *from Matches;
select 
    home_team,
	sum(home_team_score)as Home_team_score
from Matches
where attendance >= 50000
group by home_team;
-- Alternate
SELECT 
    SUM(home_team_score) AS total_home_goals_above_50k
FROM Matches
WHERE attendance >= 50000;
--42.	Which players played in matches where the score difference (home team score - away team score) was the highest?
WITH match_goal_diff AS (
  SELECT 
    match_id,
    ABS(home_team_score - away_team_score) AS goal_diff,
    home_team,
    away_team
  FROM Matches
),
max_diff AS (
  SELECT MAX(goal_diff) AS max_diff FROM match_goal_diff
),
highest_diff_matches AS (
  SELECT * FROM match_goal_diff WHERE goal_diff = (SELECT max_diff FROM max_diff)
)
SELECT 
  p.player_id,
  p.first_name,
  p.last_name,
  m.match_id,
  m.goal_diff
FROM highest_diff_matches m
JOIN players p ON p.team = m.home_team OR p.team = m.away_team
ORDER BY m.match_id;
--43.	How many goals did players score in matches that ended in penalty shootouts?
SELECT 
    COUNT(g.pid) AS total_goals_in_penalty_matches
FROM goals g
JOIN Matches m ON g.match_id = m.match_id
WHERE m.penalty_shoot_out = 1;
--44.	What is the distribution of home team wins vs away team wins by country for all seasons?
SELECT 
    s.country,
    result,
    COUNT(*) AS match_count
FROM (
    SELECT 
        match_id,
        stadium,
        CASE
            WHEN home_team_score > away_team_score THEN 'Home Win'
            WHEN away_team_score > home_team_score THEN 'Away Win'
            ELSE 'Draw'
        END AS result
    FROM Matches
) AS match_results
JOIN stadium s ON match_results.stadium = s.name
WHERE result IN ('Home Win', 'Away Win')
GROUP BY s.country, result
ORDER BY s.country, result;
--45.	Which team scored the most goals in the highest-attended matches?
select 
    match_id,
	home_team,
	away_team,
	home_team_score,
	away_team_score,
	attendance
from Matches
order by attendance desc
limit 1;
--46.	Which players assisted the most goals in matches where their team lost(you can include 3)?
SELECT 
    p.player_id,
    p.first_name,
    p.last_name,
    COUNT(*) AS total_assists_in_losses
FROM goals g
JOIN matches m ON g.match_id = m.match_id
JOIN players p ON g.assist = p.player_id
WHERE 
    g.assist IS NOT NULL AND (
        -- Case where player's team was home and lost
        (p.team = m.home_team AND m.home_team_score < m.away_team_score) OR
        -- Case where player's team was away and lost
        (p.team = m.away_team AND m.away_team_score < m.home_team_score)
    )
GROUP BY p.player_id, p.first_name, p.last_name
ORDER BY total_assists_in_losses DESC
LIMIT 3;
--47.	What is the total number of goals scored by players who are positioned as defenders?
select
   count(g.pid) as Total_Goals,
   p.position as Position
from Goals g
join players p on g.pid = p.player_id
where position = 'Defender'
group by Position;
--48.	Which players scored goals in matches that were held in stadiums with a capacity over 60,000?
SELECT DISTINCT
    p.player_id,
    p.first_name,
    p.last_name,
    s.name AS stadium_name,
    s.capacity
FROM goals g
JOIN players p ON g.pid = p.player_id
JOIN matches m ON g.match_id = m.match_id
JOIN stadium s ON m.stadium = s.name
WHERE s.capacity > 60000;
--49.	How many goals were scored in matches played in cities with specific stadiums in a season?
SELECT 
    s.city,
    m.season,
    COUNT(*) AS total_goals
FROM goals g
JOIN matches m ON g.match_id = m.match_id
JOIN stadium s ON m.stadium = s.name
WHERE s.city = 'CityName' AND m.season = '2021-2022'
GROUP BY s.city, m.season;
-- Replace CityName and Season as Necessary
--50.	Which players scored goals in matches with the highest attendance (over 100,000)?
SELECT DISTINCT
    p.player_id,
    p.first_name,
    p.last_name,
    m.match_id,
    m.attendance
FROM goals g
JOIN players p ON g.pid = p.player_id
JOIN matches m ON g.match_id = m.match_id
WHERE m.attendance > 100000;
--Additional Complex Queries (Combining multiple aspects)
--51.	What is the average number of goals scored by each team in the first 30 minutes of a match?
WITH early_goals AS (
    SELECT 
        m.home_team AS team,
        COUNT(*) AS goals
    FROM goals g
    JOIN matches m ON g.match_id = m.match_id
    WHERE g.duration <= 30
    GROUP BY m.home_team

    UNION ALL

    SELECT 
        m.away_team AS team,
        COUNT(*) AS goals
    FROM goals g
    JOIN matches m ON g.match_id = m.match_id
    WHERE g.duration <= 30
    GROUP BY m.away_team
),
matches_played AS (
    SELECT home_team AS team, COUNT(*) AS matches FROM matches GROUP BY home_team
    UNION ALL
    SELECT away_team AS team, COUNT(*) AS matches FROM matches GROUP BY away_team
),
team_goals AS (
    SELECT team, SUM(goals) AS total_goals FROM early_goals GROUP BY team
),
team_matches AS (
    SELECT team, SUM(matches) AS total_matches FROM matches_played GROUP BY team
)

SELECT 
    tg.team,
    tg.total_goals,
    tm.total_matches,
    ROUND(tg.total_goals::numeric / tm.total_matches, 2) AS avg_goals_in_first_30_min
FROM team_goals tg
JOIN team_matches tm ON tg.team = tm.team
ORDER BY avg_goals_in_first_30_min DESC;
--52.	Which stadium had the highest average score difference between home and away teams?
SELECT 
    stadium,
    ROUND(AVG(ABS(home_team_score - away_team_score)), 2) AS avg_score_diff
FROM matches
GROUP BY stadium
ORDER BY avg_score_diff DESC
LIMIT 1;

--53.	How many players scored in every match they played during a given season?
--54.	Which teams won the most matches with a goal difference of 3 or more in the 2021-2022 season?
SELECT 
    winner AS team,
    COUNT(*) AS big_wins
FROM (
    SELECT 
        CASE
            WHEN home_team_score - away_team_score >= 3 THEN home_team
            WHEN away_team_score - home_team_score >= 3 THEN away_team
        END AS winner
    FROM matches
    WHERE season = '2021-2022'
) AS big_margin_wins
WHERE winner IS NOT NULL
GROUP BY winner
ORDER BY big_wins DESC;

--55.	Which player from a specific country has the highest goals per match ratio?
WITH goals_per_player AS (
    SELECT pid, COUNT(*) AS total_goals
    FROM goals
    GROUP BY pid
),
matches_per_player AS (
    SELECT pid, COUNT(DISTINCT match_id) AS total_matches
    FROM appearances
    GROUP BY pid
),
goals_ratio AS (
    SELECT 
        p.player_id,
        p.first_name,
        p.last_name,
        p.country,
        g.total_goals,
        m.total_matches,
        ROUND(g.total_goals::numeric / m.total_matches, 2) AS goals_per_match
    FROM goals_per_player g
    JOIN matches_per_player m ON g.pid = m.pid
    JOIN players p ON p.player_id = g.pid
    WHERE m.total_matches > 0
)
SELECT *
FROM goals_ratio
WHERE country = 'YourCountryHere'
ORDER BY goals_per_match DESC
LIMIT 1;
--Chane country to your desired country



	 


	
	