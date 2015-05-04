<?xml version="1.0"?>
<xsl:stylesheet version="2.0" 
  xmlns="http://www.w3.org/1999/xhtml" 
  xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
  xmlns:m="http://www.music-encoding.org/ns/mei">	
 
  <xsl:output method="html"/>
		<html>
			<head>
				<style type="text/css">
ul {
  list-style-type: disc;
}
				</style>
			</head>
			<body>
				<ul>
					<xsl:apply-templates select="m:fileDesc"/>
				</ul>
			</body>
		</html>

	<xsl:template match="m:fileDesc">
		<li>
		<b>Work: <xsl:value-of select="title"/> 
			<xsl:for-each select="title">
				<xsl:text> </xsl:text>
				<xsl:value-of select="."/>
			</xsl:for-each>
			</b>
			</li>

		<ul>
			<!--xsl:apply-templates select="frbr:expression"/-->
		</ul>
	</xsl:template>
  
</xsl:stylesheet>