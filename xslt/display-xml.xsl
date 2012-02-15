<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" version="2.0">
	<xsl:output method="xml" encoding="UTF-8"/>

	<!-- change eXist URL if running on a server other than localhost -->
	<xsl:variable name="exist-url" select="/exist-url"/>
	<xsl:variable name="id" select="substring-before(tokenize(doc('input:request')/request/request-url, '/')[last()], '.xml')"/>
	

	<xsl:template match="/">
		<xsl:apply-templates select="document(concat($exist-url, 'nomisma/objects/', $id, '.xml'))/*"/>
	</xsl:template>

	<xsl:template match="@*|node()">
		<xsl:copy>
			<xsl:apply-templates select="@*|node()"/>
		</xsl:copy>
	</xsl:template>
	
	<!-- omit private data -->
	<xsl:template match="*[@audience='internal']"/>

</xsl:stylesheet>