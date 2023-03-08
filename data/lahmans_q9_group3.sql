-- ## Lahman Baseball Database Exercise
-- - this data has been made available [online](http://www.seanlahman.com/baseball-archive/statistics/) by Sean Lahman
-- - you can find a data dictionary [here](http://www.seanlahman.com/files/database/readme2016.txt)

-- ### Use SQL queries to find answers to the *Initial Questions*. If time permits, choose one (or more) of the *Open-Ended Questions*. Toward the end of the bootcamp, we will revisit this data if time allows to combine SQL, Excel Power Pivot, and/or Python to answer more of the *Open-Ended Questions*.



-- **Initial Questions**

-- 1. What range of years for baseball games played does the provided database cover? 

	SELECT MAX(yearid), MIN(yearid)
	FROM teams

	--ANSWER: 1871 through 2016
	
-- 2. Find the name and height of the shortest player in the database. How many games did he play in? What is the name of the team for which he played?
   
   SELECT namefirst, namelast, height
   FROM people
   WHERE height = 
   		(
		SELECT MIN(height)
		FROM people
		)
		
	--ANSWER: "Eddie"	"Gaedel"	43		
   

-- 3. Find all players in the database who played at Vanderbilt University. Create a list showing each player’s first and last names as well as the total salary they earned in the major leagues. Sort this list in descending order by the total salary earned. Which Vanderbilt player earned the most money in the majors?
	
	SELECT p.namefirst, p.namelast, SUM(sal.salary) AS tot_sal
	FROM people AS p
	INNER JOIN salaries AS sal USING(playerid)
	WHERE playerid IN 
			(
			SELECT DISTINCT c.playerid
			FROM schools AS s
			INNER JOIN collegeplaying AS c USING (schoolid)
			WHERE schoolname LIKE '%Vanderbilt%'
			)
	GROUP BY playerid
	ORDER BY tot_sal DESC

-- 4. Using the fielding table, group players into three groups based on their position: label players with position OF as "Outfield", those with position "SS", "1B", "2B", and "3B" as "Infield", and those with position "P" or "C" as "Battery". Determine the number of putouts made by each of these three groups in 2016.
   
   SELECT
   	CASE WHEN pos = 'OF' THEN 'Outfield'
		WHEN pos = 'SS' OR pos = '1B' OR pos = '2B' OR pos = '3B' THEN 'Infield'
		WHEN pos = 'P' OR pos = 'C' THEN 'Battery'
		ELSE 'Idk' END AS posti,
	SUM(po) AS putouts
   FROM fielding
   WHERE yearid = 2016
   GROUP BY posti
   
-- 5. Find the average number of strikeouts per game by decade since 1920. Round the numbers you report to 2 decimal places. Do the same for home runs per game. Do you see any trends?
	
  		SELECT
	  CASE WHEN yearid >= 1920 AND yearid <= 1929 THEN '1920s'
		WHEN yearid >= 1930 AND yearid <= 1939 THEN '1930s'
		WHEN yearid >= 1940 AND yearid <= 1949 THEN '1940s'
		WHEN yearid >= 1950 AND yearid <= 1959 THEN '1950s'
		WHEN yearid >= 1960 AND yearid <= 1969 THEN '1960s'
		WHEN yearid >= 1970 AND yearid <= 1979 THEN '1970s'
		WHEN yearid >= 1980 AND yearid <= 1989 THEN '1980s'
		WHEN yearid >= 1990 AND yearid <= 1999 THEN '1990s'
		WHEN yearid >= 2000 AND yearid <= 2009 THEN '2000s'
		WHEN yearid >= 2010 AND yearid <= 2019 THEN '2010s'
		END AS decades,
		ROUND(AVG(so),1) AS avg_so,
		ROUND(AVG(hr),1) AS avg_hr
  			FROM batting
		WHERE yearid > 1919
		GROUP BY decades
  	  
-- 6. Find the player who had the most success stealing bases in 2016, where __success__ is measured as the percentage of stolen base attempts which are successful. (A stolen base attempt results either in a stolen base or being caught stealing.) Consider only players who attempted _at least_ 20 stolen bases.
		 
	SELECT DISTINCT namefirst, namelast, sbt+cst AS tot_attempt, ROUND((sbt/(sbt+cst))*100, 2) AS pct_success
	FROM
		(
			SELECT playerid, CAST(SUM(sb) AS numeric(7,2)) AS sbt, CAST(SUM(cs) AS numeric(7,2)) AS cst
			FROM batting
			WHERE (sb+cs) >= 20 AND yearid = 2016
			GROUP BY playerid
		) AS b
	INNER JOIN people AS p USING(playerid)
	ORDER BY pct_success DESC
	  
-- 7.  From 1970 – 2016, what is the largest number of wins for a team that did not win the world series? What is the smallest number of wins for a team that did win the world series? Doing this will probably result in an unusually small number of wins for a world series champion – determine why this is the case. Then redo your query, excluding the problem year. How often from 1970 – 2016 was it the case that a team with the most wins also won the world series? What percentage of the time?
	
	SELECT name, max(w) AS wins, yearid
	FROM teams
	WHERE yearid between 1970 AND 2016 AND WSWin = 'N'
	GROUP BY name, yearid
	ORDER BY wins DESC
	LIMIT 1
	
	SELECT name, min(w) AS wins, yearid
	FROM teams
	WHERE yearid between 1970 AND 2016 AND WSWin ='Y' AND yearid <> 1981
	GROUP BY name, yearid
	ORDER BY wins ASC
	LIMIT 1
	
WITH maxw AS (
SELECT yearid, MAX(w) AS most
FROM teams
GROUP BY yearid
)	
	SELECT t.name, COUNT(t.yearid) OVER(), t.yearid, 
		( 
		SELECT COUNT(*)
		FROM teams 
		WHERE yearid between 1970 AND 2016 and WSWin = 'Y'
		) AS y
		
	FROM teams AS t
	INNER JOIN maxw AS mx
	ON t.yearid = mx.yearid AND mx.most = t.w
	WHERE t.yearid between 1970 AND 2016
	GROUP BY t.name, t.yearid
	
	--group wokr answer:
	
		with maxwins AS (
		SELECT yearid, MAX(w) AS mostwins
		FROM teams
		GROUP BY yearid
		),
	cte AS (
		SELECT t.yearid, t.name, mostwins, t.wswin, SUM(CASE WHEN wswin ='Y' THEN 1 ELSE 0 END) :: numeric AS wins
	FROM teams AS t
	LEFT JOIN maxwins AS m
	ON t.yearid = m.yearid AND t.w = m.mostwins
	WHERE t.yearid > 1969
	AND m.mostwins IS NOT NULL
	AND wswin IS NOT NULL
	GROUP BY t.yearid, t.name, mostwins, t.wswin
	ORDER BY t.yearid
		)
	SELECT SUM(wins) OVER () / COUNT(yearid) OVER () *100 AS percent_winners
	FROM cte

-- 8. Using the attendance figures from the homegames table, find the teams and parks which had the top 5 average attendance per game in 2016 (where average attendance is defined as total attendance divided by number of games). Only consider parks where there were at least 10 games played. Report the park name, team name, and average attendance. Repeat for the lowest 5 average attendance.
	
	WITH cte AS
	(
	SELECT name, park, attendance, teamidbr
	FROM teams
	)
	SELECT p.park_name, p.park, h.team, h.attendance/h.games AS att_per_game
	FROM homegames AS h
	INNER JOIN parks AS p USING(park)
	INNER JOIN cte AS c
	ON c.park = p.park_name AND h.team = c.teamidbr
	WHERE year = 2016
	GROUP BY p.park_name, h.team, p.park, h.attendance, h.games
	ORDER BY att_per_game DESC
	LIMIT 5
	
	SELECT *
	FROM teams
	
	SELECT park, games
	FROM homegames
	WHERE year = 2016
	
	SELECT park, team, attendance/games AS att_per_game
	FROM homegames
	WHERE year = 2016 AND park <> 'FTB01'
	ORDER BY att_per_game ASC
	LIMIT 5
	
-- 9. Which managers have won the TSN Manager of the Year award in both the National League (NL) and the American League (AL)? Give their full name and the teams that they were managing when they won the award.

	

	SELECT p.namefirst, p.namelast, t.name
	FROM awardsmanagers AS a
	INNER JOIN people AS p USING (playerid)
	INNER JOIN teams AS t USING (yearid, lgid)
	WHERE a.awardid LIKE 'TSN Manager of the Year' 
		AND a.lgid IN ('AL','NL')
	GROUP BY p.namefirst, p.namelast, t.name

WITH cte AS 
	(
	SELECT playerid
	FROM awardsmanagers
	WHERE awardid LIKE 'TSN Manager of the Year' 
		AND lgid IN ('AL')
	INTERSECT
	SELECT playerid
	FROM awardsmanagers
	WHERE awardid LIKE 'TSN Manager of the Year'
		AND lgid IN ('NL')	
	)
	SELECT playerid, a.yearid
	FROM cte AS c
	INNER JOIN awardsmanagers AS a USING(playerid)
	
	--GROUP ANSWER:
	SELECT DISTINCT (a.yearid), a.playerid, p.namefirst, p.namelast, t.name, a.lgid
FROM people AS p
LEFT JOIN awardsmanagers AS a
USING (playerid)
LEFT JOIN managers AS m
ON m.yearid = a.yearid
AND m.playerid = a.playerid
LEFT JOIN teams AS t
ON m.teamid = t.teamid
AND m.yearid = t.yearid
WHERE a.playerid IN 
		(SELECT playerid
		FROM awardsmanagers
		WHERE awardid = 'TSN Manager of the Year'
		AND lgid =  'AL'
		INTERSECT
		SELECT playerid
		FROM awardsmanagers
		WHERE awardid = 'TSN Manager of the Year'
		AND lgid = 'NL')

-- 10. Find all players who hit their career highest number of home runs in 2016. Consider only players who have played in the league for at least 10 years, and who hit at least one home run in 2016. Report the players' first and last names and the number of home runs they hit in 2016.
	
	--GROUP ANSWER 
	select s. teamid, AVG(sum(salary)) OVER(PARTITION BY teamid) as total_salary, AVG(AVG(t.w)) OVER(PARTITION BY teamid) as wins
	from salaries as s
	left join teams as t
	USING (teamid, yearid)
	where s. yearid >= 2000
	group by s.teamid
	order by s.teamid
	
	
	
	SELECT s.teamid, s.yearid, SUM(salary) AS teamsalary, t.w, 
	AVG(SUM(salary)) OVER (PARTITION BY s.teamid) AS avg_team_salary
	FROM salaries AS s
	FULL JOIN teams AS t
	ON s.yearid = t.yearid
	AND s.teamid = t.teamid
	WHERE s.yearid >= 2000
	GROUP BY s.teamid, s.yearid, t.w
	ORDER BY teamid, yearid

-- **Open-ended questions**

-- 11. Is there any correlation between number of wins and team salary? Use data from 2000 and later to answer this question. As you do this analysis, keep in mind that salaries across the whole league tend to increase together, so you may want to look on a year-by-year basis.

-- 12. In this question, you will explore the connection between number of wins and attendance.
--     <ol type="a">
--       <li>Does there appear to be any correlation between attendance at home games and number of wins? </li>
--       <li>Do teams that win the world series see a boost in attendance the following year? What about teams that made the playoffs? Making the playoffs means either being a division winner or a wild card winner.</li>
--     </ol>


-- 13. It is thought that since left-handed pitchers are more rare, causing batters to face them less often, that they are more effective. Investigate this claim and present evidence to either support or dispute this claim. First, determine just how rare left-handed pitchers are compared with right-handed pitchers. Are left-handed pitchers more likely to win the Cy Young Award? Are they more likely to make it into the hall of fame?

  
