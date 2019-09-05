"""

Summit Public Schools

- Connects to Illuminate CA + Illuminate WA databases
- Queries student demographics information from both databases based on this query:
https://github.com/SummitPublicSchools/Illuminate-Education/blob/master/Student_Demographics.sql
- Combines the CA + WA datasets into one dataset
- Uses the SPS Automation Starter scripts:
https://github.com/SummitPublicSchools/sps-automation-starter

"""

import psycopg2 as pg
import pandas as pd
import spsautomation as sps
import time
import requests


def download_sql_query_outputs():

    github_url = 'https://raw.githubusercontent.com/SummitPublicSchools/Illuminate-Education/master/Student_Demographics.sql'
    r = requests.get(github_url)
    query = r.text


    ## Illuminate CA
    # connect to Illuminate CA
    ca_host = sps.config_section_map('Illuminate')['ca_db_host']
    ca_port = sps.config_section_map('Illuminate')['ca_db_port']
    ca_dbname = sps.config_section_map('Illuminate')['ca_db_name']
    ca_user = sps.config_section_map('Illuminate')['ca_db_user']
    ca_password = sps.config_section_map('Illuminate')['ca_db_password']

    print ('\nIlluminate CA: Connecting to database...')
    connection_illuminate_ca = pg.connect(
        host = ca_host,
        port = ca_port,
        dbname = ca_dbname,
        user = ca_user,
        password = ca_password)
    print ('Illuminate CA: Connected!')

    # execute query
    print ('Illuminate CA: Executing query...')
    ca_df = pd.read_sql(query, connection_illuminate_ca)

    # return the number of records that resulted from the query
    ca_records = len(ca_df.index)
    print ('Illuminate CA: %d records returned' % ca_records)


    ## Illuminate WA
    # connect to Illuminate WA
    wa_host = sps.config_section_map('Illuminate')['wa_db_host']
    wa_port = sps.config_section_map('Illuminate')['wa_db_port']
    wa_dbname = sps.config_section_map('Illuminate')['wa_db_name']
    wa_user = sps.config_section_map('Illuminate')['wa_db_user']
    wa_password = sps.config_section_map('Illuminate')['wa_db_password']

    print ('\nIlluminate WA: Connecting to database...')
    connection_illuminate_wa = pg.connect(
        host = wa_host,
        port = wa_port,
        dbname = wa_dbname,
        user = wa_user,
        password = wa_password)
    print ('Illuminate WA: Connected!')

    # execute query
    print ('Illuminate WA: Executing query...')
    wa_df = pd.read_sql(query, connection_illuminate_wa)

    # return the number of records that resulted from the query
    wa_records = len(wa_df.index)
    print ('Illuminate WA: %d records returned' % wa_records)

    ## CA + WA
    records = ca_records + wa_records
    print ('\nIlluminate CA + WA: %d records returned' % records)

    ## write to csv
    current_date = time.strftime("%Y%m%d")
    filename = current_date + ' Illuminate Current Student Demographics.csv'
    # df = pd.DataFrame(records)

    df = pd.concat([ca_df, wa_df], axis = 0)

    df.to_csv(filename, header = True, index = False)

    print ('\nExported to \"%s Illuminate Current Student Demographics.csv\"\n' % current_date)


if __name__ == "__main__":
    sps.load_config()
    download_sql_query_outputs()
