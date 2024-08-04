# Paperless Import  
A script to import my file-basis pdf-bill-archive to my selfhosted Paperless-Instance.  
Imports pdf of a folder to a specific correspondent.  

## Requirements  
Written on my Mac with JQ located in script-folder.  
Maybe edit line 48 in `paperless_migrate_datecorrect.sh`.  

## Customize url and cookie data in scripts.  
There are variables for that.  

## Making executable  
`chmod +x paperless_migrate*.sh`  

## Import data   
Edit folder path with variable "foldername"  
Execute the script: `./paperless_migrate.sh`  

## Change creation date  
Paperless detect the creation date itself, even if the filename contains the date.  
Sometimes no date or a wrong date detected  
Get all the metadata: https://paperless.<your>.<domain>/api/documents/?format=json&ordering=title&page=1&page_size=5000&truncate_content=true  
Finde the differences with a script or excel ;)  
Paste the IDs in "paperless_documents_list.txt"  
And execute the script: `./paperless_migrate_datecorrect.sh`  
The script take the first 10 Numbers of the filename and set it to the creation date.  
