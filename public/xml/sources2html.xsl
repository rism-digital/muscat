<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet version="1.0" xmlns:zs="http://www.loc.gov/zing/srw/" xmlns:marc="http://www.loc.gov/MARC21/slim" xmlns:rdf="http://www.w3.org/1999/02/22-rdf-syntax-ns#" xmlns:dc="http://purl.org/dc/elements/1.1/" xmlns:xsl="http://www.w3.org/1999/XSL/Transform" exclude-result-prefixes="marc">
<xsl:output method="html"/>
<xsl:template match="marc:collection">
	

  <xsl:for-each select="marc:record">

<!--ID-->
<tr>
<xsl:for-each select="marc:controlfield[@tag=001]">
<td><xsl:value-of select="."/></td>
</xsl:for-each>
<!--AUTHOR-->
<td>

<xsl:choose>
  <xsl:when test="marc:datafield[@tag=100]">
    <xsl:for-each select="marc:datafield[@tag=100]">
      <xsl:value-of select="marc:subfield[@code='a']"/>
    </xsl:for-each>
  </xsl:when>
  <xsl:otherwise>
    Collection
  </xsl:otherwise>
</xsl:choose>

<!--TITLE-->
<td>
<xsl:if test="marc:datafield[@tag=130]">
  <xsl:for-each select="marc:datafield[@tag=130]">
    <xsl:value-of select="marc:subfield[@code='a']"/>
  </xsl:for-each>
</xsl:if>
<xsl:if test="marc:datafield[@tag=240]">
  <xsl:for-each select="marc:datafield[@tag=240]">
    <xsl:value-of select="marc:subfield[@code='a']"/>
  </xsl:for-each>
</xsl:if>
</td>

<td>
<xsl:for-each select="marc:datafield[@tag=240]">
<xsl:value-of select="marc:subfield[@code='m']"/>
</xsl:for-each>
</td>

<td>
<xsl:for-each select="marc:datafield[@tag=852]">
  <xsl:value-of select="marc:subfield[@code='a']"/>
  <xsl:choose>
    <xsl:when test="position() != last()">, </xsl:when>
  </xsl:choose>

</xsl:for-each>
</td>

<td>
<xsl:for-each select="marc:datafield[@tag=852]">
  <xsl:value-of select="marc:subfield[@code='c']"/>
</xsl:for-each>
</td>
</tr>

</xsl:for-each>
</xsl:template>
</xsl:stylesheet>
