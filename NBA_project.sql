/*
Exploration queries
*/

-- 1. What counries has the most NBA players
SELECT country, COUNT(DISTINCT player_name) AS player_count
FROM plr_info
GROUP BY country ORDER BY player_count DESC;


-- 2. What colleges has the most NBA players
SELECT college, COUNT(DISTINCT player_name) AS player_count
FROM plr_info 
WHERE college != 'None'
GROUP BY college ORDER BY player_count DESC;


-- 3. Does the NBA draft more/less players over the years
SELECT draft_year, COUNT(DISTINCT player_name) AS player_count
FROM plr_info 
WHERE draft_year != 'Undrafted'
GROUP BY draft_year ORDER BY draft_year ASC;


-- 4. What teams had the most top 10 picks in the draft
SELECT team_abbreviation, 
	COUNT(DISTINCT player_name) AS top10_picks
FROM plr_info 
WHERE draft_round = '1' AND draft_number BETWEEN '1' AND '10'
GROUP BY team_abbreviation ORDER BY top10_picks DESC;


-- 5. Do players of certain height get drafted more often
WITH height_cnt (player_height_range, drafted_players, player_count)
AS (
	SELECT CAST(player_height - (player_height % 10) AS int) AS player_height_range,
		CAST(COUNT(DISTINCT player_name)AS numeric) AS drafted_players,
		(SELECT CAST(COUNT(DISTINCT player_name)AS numeric) FROM plr_info ) AS player_count 
	FROM plr_info 
	WHERE draft_number != 'Undrafted'
	GROUP BY player_height_range ORDER BY player_height_range ASC
	)
SELECT player_height_range, drafted_players, 
	ROUND((drafted_players /player_count)*100 ,2) AS drafted_percent
FROM height_cnt


-- 6. Does this height perference in the draft changed over time
SELECT draft_year, ROUND(AVG(player_height),2) AS player_avg_height
FROM plr_info 
WHERE draft_number != 'Undrafted'
GROUP BY draft_year ORDER BY draft_year;


-- 7. Did the average player got better over time
SELECT pi.season, 
	ROUND(AVG(ps.pts), 2) AS average_points, 
	ROUND(AVG(ps.ast), 2) AS average_assist, 
	ROUND(AVG(ps.reb), 2) AS average_rebounds
FROM plr_info AS pi 
LEFT JOIN plr_stats AS ps
ON pi."#" = ps."#"
GROUP BY pi.season ORDER BY pi.season;


-- 8. What team had the best player averages
SELECT DISTINCT pi.team_abbreviation, 
	ROUND(AVG(ps.pts) OVER (PARTITION BY pi.team_abbreviation), 2) AS points_avg, 
	ROUND(AVG(ps.ast) OVER (PARTITION BY pi.team_abbreviation), 2) AS assists_avg, 
	ROUND(AVG(ps.reb) OVER (PARTITION BY pi.team_abbreviation), 2) AS rebound_avg
FROM plr_info AS pi 
JOIN plr_stats AS ps
ON pi."#" = ps."#"
ORDER BY pi.team_abbreviation ASC;


-- 9. Does players height affect their stats
SELECT CAST(pi.player_height - (pi.player_height % 10) AS int) AS player_height_range,
	ROUND(AVG(ps.pts),2) AS points_avg, 
	ROUND(AVG(ps.ast),2) AS assists_avg, 	
	ROUND(AVG(ps.reb),2) AS rebound_avg,
	ROUND(AVG(ps.ast_pct),3) AS assists_pct,  
	ROUND(AVG(ps.dreb_pct),3) AS defensive_reb_pct, 
	ROUND(AVG(ps.oreb_pct),3) AS offensive_reb_pct
FROM plr_info AS pi 
JOIN plr_stats AS ps
ON pi."#" = ps."#"
GROUP BY player_height_range ORDER BY player_height_range ASC;


-- 10. Does players age affect their stats
SELECT pi.age,
	ROUND(AVG(ps.pts),2) AS points_avg, 
	ROUND(AVG(ps.ast),2) AS assists_avg, 	
	ROUND(AVG(ps.reb),2) AS rebound_avg,
	ROUND(AVG(ps.ast_pct),3) AS assists_pct,  
	ROUND(AVG(ps.dreb_pct),3) AS defensive_reb_pct, 
	ROUND(AVG(ps.oreb_pct),3) AS offensive_reb_pct
FROM plr_info AS pi 
JOIN plr_stats AS ps
ON pi."#" = ps."#"
GROUP BY pi.age ORDER BY pi.age ASC;

/*
Create views for Tableau Public visualizations
*/

-- Players info & stats table
CREATE VIEW nba_players AS
	SELECT pi.season, pi.team_abbreviation, pi.player_name, pi.age, pi.player_height, pi.player_weight,
		pi.country, pi.college, pi.draft_year, pi.draft_round, pi.draft_number,
		ps.gp, ps.pts, ps.ast, ps.reb, ps.ts_pct, ps.ast_pct, ps.dreb_pct, ps.oreb_pct,
		ps.usg_pct, ps.net_rating
	FROM plr_info AS pi
	JOIN plr_stats AS ps
	ON ps."#" = pi."#"
	ORDER BY 1,2,3


-- Lebron James's career view
CREATE VIEW lebronjames_career AS
	SELECT pi.season, pi.team_abbreviation, pi.age, 
		ps.gp, ps.pts, ps.ts_pct, 
		ps.ast, ps.ast_pct, 
		ps.reb, ps.dreb_pct, ps.oreb_pct, 
		ps.net_rating
	FROM plr_info AS pi 
	JOIN plr_stats AS ps
	ON pi."#" = ps."#"
	WHERE pi.player_name LIKE 'LeBron%'