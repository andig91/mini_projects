# Bookstack Import  
A script to import my file-basis Markdown-Wiki to my selfhosted Bookstack-Instance.  
Imports a single file or folder in a specified book.  

## Requirements  
Written on my Mac with JQ located in script-folder.  
Maybe edit line 54 in `bookstack_upload_single.sh`.  

## Customize cred.txt  
First line Token_ID, second line Token_Secret  
See and rename cred.txt.example  

## Making executable  
`chmod +x bookstack_upload*.sh`  

## Execute the script  
### Single file  
`./bookstack_upload_folder.sh <path/to/folder>`  

### Folder with .md-files  
`./bookstack_upload_single.sh <path/to/file.md>`  