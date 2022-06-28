<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:marc="http://www.loc.gov/MARC21/slim">
	<!-- output method set to html because with text Nokogiri does not remove the xml declaration -->
	<xsl:output method="html" encoding="UTF-8" indent="no" omit-xml-declaration="yes"/>
	
	<xsl:strip-space elements="*"/>
	
	<xsl:template match="/">
		<xsl:apply-templates/>
	</xsl:template>
	
	<xsl:template name="string-replace-all">
		<xsl:param name="text"/>
		<xsl:param name="replace"/>
		<xsl:param name="by"/>
		<xsl:choose>
			<xsl:when test="contains($text, $replace)">
				<xsl:value-of select="substring-before($text, $replace)"/>
				<xsl:value-of select="$by"/>
				<xsl:call-template name="string-replace-all">
					<xsl:with-param name="text" select="substring-after($text, $replace)"/>
					<xsl:with-param name="replace" select="$replace"/>
					<xsl:with-param name="by" select="$by"/>
				</xsl:call-template>
			</xsl:when>
			<xsl:otherwise>
				<xsl:value-of select="$text"/>
			</xsl:otherwise>
		</xsl:choose>
	</xsl:template>
	
	<xsl:template match="marc:record">
		<xsl:apply-templates select="marc:datafield|marc:controlfield"/>
	</xsl:template>
	
	<xsl:template match="marc:controlfield">
		<!-- the list of control fields we want to keep -->
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
		<xsl:value-of select="translate(@ind1, ' ', '#')"/>
		<xsl:value-of select="translate(@ind2, ' ', '#')"/>
		<xsl:apply-templates select="marc:subfield"/>
		<xsl:text>&#xa;</xsl:text>
	</xsl:template>
	
	<xsl:template match="marc:subfield">
		<xsl:text>$</xsl:text>
		<xsl:value-of select="@code"/>
		<xsl:variable name="newtext">
			<xsl:call-template name="string-replace-all">
				<xsl:with-param name="text" select="current()"/>
				<xsl:with-param name="replace" select="'$'"/>
				<xsl:with-param name="by" select="'_DOLLAR_'"/>
			</xsl:call-template>
		</xsl:variable>
		<xsl:value-of select="$newtext"/>
	</xsl:template>
	
</xsl:stylesheet>
