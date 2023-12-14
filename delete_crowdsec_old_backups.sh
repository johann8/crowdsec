#!/bin/bash
#
# Debug enable
#set -x
#
set -o errexit

#
### === Set variables ===
#
STORAGE="/opt/crowdsec/data/crowdsec/backup"
DIR_DELETE="/opt/crowdsec/data/crowdsec/backup"
BACKUPDIRS_DELETE=3
SCRIPT_VERSION="0.1"                       # Set script version
TIMESTAMP=$(date "+%Y-%m-%d %H:%M:%S")     # time stamp

#
### === Run Script ===
#

echo -e "Host: $(hostname -f)"
echo -e "Run script at ${TIMESTAMP}"
echo "---------------------------------"
echo "Number of backup DIR's that should remain: \"${BACKUPDIRS_DELETE}\""
echo ""

if [ -d ${STORAGE} ]; then

   # Delete old files
   echo "Storage path: \"${STORAGE}\""

   # Number of existing backup dirs
   COUNT_DIRS=$(ls -t ${DIR_DELETE} |sort | uniq -u |wc -l)
   echo "There are a total of \"${COUNT_DIRS}\" folders"

   if [ ${COUNT_DIRS} -le ${BACKUPDIRS_DELETE} ]; then
      echo "SKIP: There are too few DIR's to delete: \"${COUNT_DIRS}\""
      echo ""
      exit 0
   else
      echo "Old DIR's are deleted..."
      cd ${DIR_DELETE}
      # Only for test
      #(ls ${DIR_DELETE} -t | head -n ${BACKUPDIRS_DELETE};ls ${DIR_DELETE} ) | sort | uniq -u | wc -l
      (ls ${DIR_DELETE} -t | head -n ${BACKUPDIRS_DELETE};ls ${DIR_DELETE} ) | sort | uniq -u | xargs rm -rf

      # Check result
      if [ "$?" = "0" ]; then
         echo "Old DIR's were deleted."
         echo ""
         echo "List \"${STORAGE} \":"
         echo "---------------------------------"
         # ls -lah1t ${STORAGE} |grep "backup" | awk 'NR==1, NR==6 {print $9,$5}' |column -t # NR: Zeigt nur die ersten 1 bis 6 Lines an.
         # ls -lah1t ${STORAGE} |grep "mailcow" | awk '{print $9}' |column -t
         #tree -ifFrh ${STORAGE} |grep 'vmail' |grep -v '/$'
         tree -L 1 ${STORAGE}
      else
         echo "Error: Old DIR's could not be deleted!"
         exit 0
      fi
   fi
else
   echo "Error: The folder \"${STORAGE}\" does not exist."
   exit 1
fi
