<?xml version="1.0"?>
<xsl:stylesheet version="2.0" exclude-result-prefixes="m xhtml" xmlns:xhtml="http://www.w3.org/1999/xhtml" xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:m="http://www.music-encoding.org/ns/mei">
    <xsl:output method="html"/>
    
    <xsl:template match="/">
        <xsl:apply-templates select="m:sourceDesc/m:source"/>
        <xsl:apply-templates/>
    </xsl:template>
    
    <xsl:template match="m:sourceDesc/m:source">
        <h4>ID: 
            <xsl:value-of select="./@xml:id"/>
        </h4>
    </xsl:template>
    
    <xsl:template match="m:fileDesc/m:titleStmt/m:respStmt/m:persName">
        <h4>Composer</h4>
        <p>
            <xsl:value-of select="."/>
        </p>
    </xsl:template>
    
    <xsl:template match="m:fileDesc/m:titleStmt/m:title[@type='uniform']">
        <h4>Uniform title</h4>
        <p>
            <xsl:value-of select="."/>
        </p>
    </xsl:template>
    
    <xsl:template match="m:fileDesc/m:titleStmt/m:title[@type='proper']">
        <h4>Diplomatic title</h4>
        <p>
            <xsl:value-of select="."/>
        </p>
    </xsl:template>
    
    <xsl:template match="node() | @*">
		<xsl:result-document href="#mei-html-output">
        	<xsl:apply-templates/>
		</xsl:result-document>
    </xsl:template>
    
</xsl:stylesheet>
