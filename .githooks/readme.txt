
Document For Git leaks
Resticing access for Commiting and Pushing sensitive information

Requirements
 -Gitleaks (https://github.com/zricethezav/gitleaks)
 -Git hooks script for resticting the commit and push (https://git-scm.com/book/en/v2/Customizing-Git-Git-Hooks)
    

Please reffer githuburl
 It has mainly 3 things
    - Makefile   ( It is used to build the setup)
    - pre-commit  ( Scans the staged documents )
    - pre-push    ( Scans all the commits )


 1)If Docker

   a)running in non root
     (if Docker is running as non-root)
      $ cd .githooks OS=XXXX
      $ make docker-init 
     ex: make docker-init OS=windows
         /make docker-inti OS=linux

   b)running as root
     (if Docker is running as root) 
      $ cd .githooks OS=XXXX
      $ make docker-sudo-init
     ex: make docker-sudo-init OS=windows
         /make docker-sudo-inti OS=linux   

   c)Running on remote host please run as
      $ cd .githooks
      $ make docker-custom-init OS=XXXX CUSTOM_COMMAND=XXXX
      ex: make docker-custom-init OS=windows CUSTOM_COMMAND= tcp://localhost:2375
          which runs on tcp://localhost:2375 dcoker deamon

 2)If windows
   Please install gitleaks , Install Latest Version -url(https://github.com/zricethezav/gitleaks/releases)
   $ cd .githooks
   $ make windows-init   


 3)If Linux
   Please install gitleaks , Install Latest Version  -url(https://github.com/zricethezav/gitleaks/releases)
   $ cd .githooks
   $ make linux-init 
        

To Verfiy Run
 $ .githooks/test-sample
 
Additional featuers
  Can use the same setup to verify other things as well. 
  Can add more conditions in pre-commit & pre-push to validate other things as well,ex: validating yaml file

   