/*************************************************************************
* user_access_checks
**************************************************************************
* Original Author: Maddy Landon
* Last Updated: 2018-04-10
*
* Description:
* This should be used periodically to clean up Illuminate user access. The query pulls active Illuminate users
* and their role/site affiliations for a give school year
*
*/

SELECT
  users.user_id,
  local_user_id,
  last_name,
  first_name,
  email1,
  string_agg(DISTINCT(site_name), ',') AS sites,
  string_agg(DISTINCT(role_name), ',') AS roles,
  user_last_login.last_login_time :: DATE

FROM users
LEFT JOIN user_term_role_aff userrole ON (users.user_id = userrole.user_id)
LEFT JOIN terms ON userrole.term_id = terms.term_id
LEFT JOIN sessions ON terms.session_id = sessions.session_id
LEFT JOIN roles ON userrole.role_id = roles.role_id
LEFT JOIN user_term_site_aff usersite ON (users.user_id = usersite.user_id AND usersite.academic_year = sessions.academic_year)
LEFT JOIN sites ON sites.site_id = sessions.site_id
LEFT JOIN user_last_login ON users.user_id = user_last_login.user_id
WHERE active = TRUE
AND (sessions.academic_year = '2018' OR
      sessions.academic_year is NULL)
AND illuminate_employee = FALSE
GROUP BY  users.user_id,
  local_user_id,
  last_name,
  first_name,
  email1,
  user_last_login.last_login_time
ORDER BY last_login_time