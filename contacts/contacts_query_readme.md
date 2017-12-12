# Query Overviews

## Contacts Query Starter
The query in the file `contact_info_starter-long_or_wide.sql` can be used as the starter for any query where current contact information is needed. Here are some things to know:
* The parts of the query that you need to modify don't start until near the bottom. There is a message that says where you should edit and where you should not.
* Depending on how you do the final query, this query can return contact information in long or wide form. There is a note in the query around line 407 that tells how to do this.
* It will not work out the box if we needed to query historical information (e.g. addresses of dwellings a household use to reside at). By design, this query pulls a row of information for each contact with their most recent information. 
* This same query will work for both CA and WA. The only difference is that CA has more `contact_type` options. The query is written to handle the superset of CA options and will work for WA too.

### QA
This query was QAed by Cherish Harris. Here is a list of checks that she ran:  
-Exported curent enrollment from Illuminate and VLOOKUP to check that every student is in the query
-Compared guardian 1 in query and primary contact from Illuminate (Contact OMs about discrepancies due to primary contact not being marked as legal)
-Crosschecked contacts with restraining orders in Illuminate and confirmed none of those contacts appear in the query
-Compared Illuminate primary contact email address with query
-Pciked students at random to check that guardian 1 in marked as legal and confirmed contact info
-Picked students at random to check that emergency contact is marked as emergency and not legal
