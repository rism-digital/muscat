<?xml version="1.0" encoding="UTF-8"?>

<!--
	
	marcxml2marctxt.xsl - XSLT (2.0) stylesheet for transformation of RISM MARC XML to MARC text
	
	Tested with Saxon 9
	
	Laurent Pugin <laurent.pugin@rism-ch.org>
	Swiss RISM Office
	Written: 2011-05-03
	Last modified: 2012-12-10
	
	For info on MARC XML, see http://www.loc.gov/marc/marcxml.html
	For info on RISM, see http://www.rism-ch.org
	
	Modifications:
	- 2014/21/07: adding marc namespace; adding $ escaping
	- 2015/11/02: updating documentation
		
-->

<xsl:stylesheet version="2.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:marc="http://www.loc.gov/MARC21/slim">
    <xsl:output method="text" encoding="UTF-8" indent="no"/>
    <xsl:strip-space elements="*"/>

    <xsl:template match="/">
        <xsl:apply-templates/>
    </xsl:template>

    <xsl:template match="marc:record">
        <xsl:text>=000  </xsl:text>
        <xsl:value-of select="marc:leader"/>
        <xsl:text>&#xa;</xsl:text>
        <xsl:apply-templates select="marc:datafield|marc:controlfield"/>
    </xsl:template>

    <xsl:template match="marc:controlfield">
        <xsl:text>=</xsl:text>
        <xsl:value-of select="@tag"/>
        <xsl:text>  </xsl:text>
        <xsl:value-of select="."/>
        <xsl:text>&#xa;</xsl:text>
    </xsl:template>

    <xsl:template match="marc:datafield">
        <xsl:text>=</xsl:text>
        <xsl:value-of select="@tag"/>
        <xsl:text>  </xsl:text>
        <xsl:value-of select="translate(@ind1,' ','#')"/>
        <xsl:value-of select="translate(@ind2,' ','#')"/>
        <xsl:apply-templates select="marc:subfield"/>
        <xsl:text>&#xa;</xsl:text>
    </xsl:template>

    <xsl:template match="marc:subfield">
        <xsl:text>$</xsl:text>
        <xsl:value-of select="@code"/>
        <xsl:value-of select="replace(current(),'\$','_DOLLAR_')"/>
    </xsl:template>

</xsl:stylesheet>
 
