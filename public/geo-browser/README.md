=====================================================
Install DARIAH-DE Geo-Browser und Datasheet Editor v2
=====================================================


1. Check out Geo-Browser main folder
   $ git clone git://git.projects.gwdg.de/geo-browser.git
   $ cd geo-browser

2. Check out the platin code into a PLATIN folder (from DARIAH-DE PLATIN fork)
   $ git clone https://github.com/DARIAH-DE/PLATIN.git

3. Build all the PLATIN stuff
   $ cd PLATIN
   $ rake all

4. Create bower_components folder by copying from existing Geo-Browser instance or installing via bower (see edit/README.md file)
   $ cd edit
   $ bower install

5. Enjoy your new Geo-Browser installation!
