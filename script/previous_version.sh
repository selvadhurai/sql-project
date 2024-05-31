#!/bin/bash

 # Identify previous version SQL script
   previous_sql_file=$(ls -1t release_sql/*.sql | tail -1)
   echo "Previous SQL file: $previous_sql_file"