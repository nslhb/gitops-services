
Document For Git leaks
Resticing access for Commiting and Pushing sensitive information

Prerequisite
  For windows
    Need to install Makefile support
    https://dzone.com/articles/makefile-command-in-windows

Requirements
 -Gitleaks (https://github.com/zricethezav/gitleaks)
 -Git hooks script for resticting the commit and push (https://git-scm.com/book/en/v2/Customizing-Git-Git-Hooks)
    

Please reffer githuburl
 It has mainly 3 things
    - Makefile   ( It is used to build the setup)
    - pre-commit  ( Scans the staged documents )
    - pre-push    ( Scans all the commits )


 1)Linux ,Please Follow one methods 

   a)Direct 
    Please install gitleaks , Install Latest Version  -url(https://github.com/zricethezav/gitleaks/releases)
     $ cd .githooks
     $ make linux-init

   b)Docker running in non root
     (if Docker is running as non-root)
      $ cd .githooks 
      $ make docker-init 

   c)Docker running as root
     (if Docker is running as root) 
      $ cd .githooks 
      $ make docker-sudo-init  


 2)Windows ,Please Follow one methods 
    
    a)Direct 
      Please install gitleaks , Install Latest Version -url(https://github.com/zricethezav/gitleaks/releases)
       $ cd .githooks
       $ git config core.hooksPath .githooks
       $ type precommit-windows.sample >> pre-commit
       $ type prepush-windows.sample >> pre-push        

    b)Docker running in non root
     (if Docker is running as non-root)
      $ git config core.hooksPath .githooks
      $ cd .githooks
      $ type precommit-docker.sample >> pre-commit
	 $ type prepush-docker.sample >> pre-push

   c)Docker running as root
     (if Docker is running as root) 
      $ git config core.hooksPath .githooks
      $ cd .githooks
      $ type precommit-docker-sudo.sample >> pre-commit
	 $ type prepush-docker-sudo.sample >> pre-push 

To skip tests
  --no-verify 

Please edit the below files,To add additoinal feature 
 .githooks/pre-commit
 .githooks/pre-push


Additional featuers
  Can use the same setup to verify other things as well. 
  Can add more conditions in pre-commit & pre-push to validate other things as well,ex: validating yaml file
   