<?xml version="1.0" encoding="UTF-8"?>

<!--
	
	marcxml2marctxt_1.0.xsl - XSLT (1.0) stylesheet for transformation of RISM MARC XML to MARC text
	
	Laurent Pugin <laurent.pugin@rism-ch.org>
	Swiss RISM Office
	Written: 2011-05-03
	Last modified: 2012-12-10
	
	For info on MARC XML, see http://www.loc.gov/marc/marcxml.html
	For info on RISM, see http://www.rism-ch.org
	
	Modifications:
	- 2014/21/07: adding marc namespace; adding $ escaping
	- 2014/21/10: changed for use with libxml xslt 1.0 (replace function)
	- 2015/11/02: fixing namespace
		
-->

<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:marc="http://www.loc.gov/MARC21/slim">
    <xsl:output method="text" encoding="UTF-8" indent="no" omit-xml-declaration="yes" />
    <xsl:strip-space elements="*"/>

    <xsl:template match="/">
        <xsl:apply-templates/>
    </xsl:template>

    <xsl:template name="string-replace-all">
      <xsl:param name="text" />
      <xsl:param name="replace" />
      <xsl:param name="by" />
      <xsl:choose>
        <xsl:when test="contains($text, $replace)">
          <xsl:value-of select="substring-before($text,$replace)" />
          <xsl:value-of select="$by" />
          <xsl:call-template name="string-replace-all">
            <xsl:with-param name="text"
             select="substring-after($text,$replace)" />
            <xsl:with-param name="replace" select="$replace" />
            <xsl:with-param name="by" select="$by" />
          </xsl:call-template>
        </xsl:when>
        <xsl:otherwise>
          <xsl:value-of select="$text" />
        </xsl:otherwise>
      </xsl:choose>
    </xsl:template>

    <xsl:template match="marc:record">
      <xsl:text>=000  </xsl:text>
        <xsl:value-of select="."/>
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
        <xsl:variable name="newtext">
           <xsl:call-template name="string-replace-all">
              <xsl:with-param name="text" select="current()" />
              <xsl:with-param name="replace" select="'$'" />
              <xsl:with-param name="by" select="'_DOLLAR_'" />
            </xsl:call-template>
        </xsl:variable>
        <xsl:value-of select="$newtext"/>
    </xsl:template>
</xsl:stylesheet>
 
