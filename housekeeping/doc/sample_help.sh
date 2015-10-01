#!/bin/bash

# example call
# ./help.sh de


lang="en"
marc="ch"
link_color="#822c0f"
name="RISM-CH-guidelines"
image="rism_300.png"

if [ $# -gt 0 ]; then
    lang=$1
fi

rails r housekeeping/doc/generate_doc.rb guidelines.yml ./public/guidelines/$marc/.output.html $lang

content="Content"
if [ $lang = "de" ]; then
    content="Inhalt"
fi

iconv -f UTF-8 -t ISO-8859-1 ../../public/help/$marc/title_$lang.html > ../../public/help/$marc/.title.html
iconv --unicode-subst=formatstring -f UTF-8 -t ISO-8859-1 ../../public/guidelines/$marc/.output.html > ../../public/help/$marc/.content.html

htmldoc \
	--titleimage ../../public/help/$marc/$image \
	--titlefile ../../public/help/$marc/.title.html \
	--footer hd1  \
	--textfont Helvetica \
	--bodyfont Helvetica \
	--fontsize 11  \
	--linkcolor $link_color  \
	--linkstyle "plain" \
 	--pagelayout tworight  \
	--toclevels 3 \
	--toctitle $content \
	--tocfooter .di \
	-f ../../public/guidelines/$marc/$name-$lang.pdf \
	-v ../../public/help/$marc/.content.html

rm ../../public/help/$marc/.title.html
rm ../../public/help/$marc/.content.html
rm ../../public/guidelines/$marc/.output.html