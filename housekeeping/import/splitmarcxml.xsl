<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet version="2.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:marc="http://www.loc.gov/MARC21/slim">
    <xsl:output method="xml" indent="yes"/>
    <xsl:param name="recordNumber" select="100000"/>
    <xsl:template match="marc:collection">
        <xsl:for-each-group select="marc:record"
            group-adjacent="(position()-1) idiv $recordNumber">
            <xsl:result-document  href="{base-uri(.)}-{current-grouping-key()}.xml">
                <collection xmlns="http://www.loc.gov/MARC21/slim">
                    <xsl:copy-of select="current-group()"/>
                </collection>
            </xsl:result-document>
        </xsl:for-each-group>
    </xsl:template>
</xsl:stylesheet>