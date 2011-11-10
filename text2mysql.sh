#!/bin/bash


# By brian@brianyoungblood.com to keep original files and import based on tab delimited data
# orginal script based on work from Eric London. http://ericlondon.com/bash-shell-script-import-large-number-csv-files-mysql

# show commands being executed, per debug
#set -x

# define database connectivity
_db="mydatabase"
_db_user="root"
_db_password="root"
_db_host="127.0.0.1"
_db_port="3306"

# define directory containing CSV files
_csv_directory=""


# go into directory
cd $_csv_directory

# get a list of CSV files in directory
_csv_files_origin=`ls -1 *.txt`

# loop through files and fix the linefeeds
for _csv_file_origin in ${_csv_files_origin[@]}
do
  _csv_file_origin_extensionless=`echo $_csv_file_origin | sed 's/\(.*\)\..*/\1/'`
  # change linefeeds to unix sed for no dependancies
  echo "Changing linefeeds and removing date from column headers. This can take a little while. Saving as $_csv_file_origin_extensionless.fixed"
 # sed -e 's/.$//' $_csv_file_origin > $_csv_file_origin_extensionless.fixed

done


# get a list of files in directory after we've fixed them
_csv_files=`ls -1 *.txt`

# loop through csv files
for _csv_file in ${_csv_files[@]}
do


  # remove file extension
  _csv_file_extensionless=`echo $_csv_file | sed 's/\(.*\)\..*/\1/'`
  
  
  # define table name
  _table_name="${_csv_file_extensionless}"
  
  # get header columns from CSV file and remove the appending date from the name
  _header_columns=`head -1 $_csv_directory/$_csv_file | tr ',' '\n' | sed -e 's/^"//' -e 's/"$//' -e 's/ /_/g'`
  _header_columns_string=`head -1 $_csv_directory/$_csv_file | tr '\t' ','`
  
  # ensure table exists
  echo "Creating table $_table_name and truncating if present"
  mysql -u $_db_user -p$_db_password -h$_db_host -P$_db_port $_db << eof
    CREATE TABLE IF NOT EXISTS \`$_table_name\` (
      id int(11) NOT NULL auto_increment,
      PRIMARY KEY  (id)
    ) ENGINE=MyISAM DEFAULT CHARSET=latin1;
    TRUNCATE \`$_table_name\`
eof
  
  # loop through header columns
  for _header in ${_header_columns[@]}
  do
	echo "Creating a column for $_header"
    # add column
    mysql -u $_db_user -p$_db_password -h$_db_host -P$_db_port $_db --execute="alter table \`$_table_name\` add column \`$_header\` text"

  done

  # import csv into mysql
  echo "Importing into $_db.$_table_name"
  mysqlimport --fields-terminated-by="\t" --lines-terminated-by="\n" --columns="$_header_columns_string" -u $_db_user -p$_db_password -h$_db_host -P$_db_port $_db $_csv_directory/$_csv_file  
  
done
exit