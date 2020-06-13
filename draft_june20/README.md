# GITHUB / OVERLEAF SYNC 

The overleaf project for a given document (e.g. a draft) shall be organized in a single main folder that can be considered as an another independent yet-connected repo living in master.  

Overleaf communicates ONLY with master. It is not possible to use branches. When the document is modified online, you need to pull it also to the master repo in order to have a local copy. When new outcomes are pushed to master instead, they must be pushed to the Overleaf repo as well to update the online document. You need to use the terminal to push changes to overleaf. Local changes can instead by normally pushed via GitHub Desktop (you must do it before pushing to Overleaf). 

Once updated, all files and folder of the master repo will appear in Overleaf. Figures and tables can therefore be added to the text using their original location path (e.g. analysis/event_study/output/figurexx.png). 

Note that deleting and modifying the uploaded folder coming from master will affect the original repo once the Overleaf repo is pulled. You SHALL NOT delete or modify any file or folder outside the Overleaf main folder. If that happens, shall discard the commit that is created locally (e.g. from GitHub Desktop). 



## TO UPDATE FIGURES AND TABLES: 

1) commit and push desired output to master

2) pull Overleaf: git pull overleaf master

3) pust last update to Overleaf: git push overleaf master



## TO UPDATE MASTER FROM OVERLEAF (I.E. ADDED TEXT IN DRAFT/PAPER):

1) pull from Overleaf: git pull overleaf master   