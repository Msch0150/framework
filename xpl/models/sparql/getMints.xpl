<?xml version="1.0" encoding="UTF-8"?>
<!--
	XPL handling SPARQL queries from Fuseki	
-->
<p:config xmlns:p="http://www.orbeon.com/oxf/pipeline" xmlns:oxf="http://www.orbeon.com/oxf/processors" xmlns:rdf="http://www.w3.org/1999/02/22-rdf-syntax-ns#">

	<p:param type="input" name="data"/>
	<p:param type="output" name="data"/>

	<p:processor name="oxf:request">
		<p:input name="config">
			<config>
				<include>/request</include>
			</config>
		</p:input>
		<p:output name="data" id="request"/>
	</p:processor>

	<p:processor name="oxf:pipeline">
		<p:input name="config" href="../rdf/get-id.xpl"/>
		<p:output name="data" id="rdf"/>
	</p:processor>
	
	
	<p:choose href="#rdf">
		<!-- check to see whether the ID is a mint or region, if so, process the coordinates or geoJSON polygon in the RDF into geoJSON -->
		<p:when test="/rdf:RDF/*[1]/name() = 'nmo:Mint' or /rdf:RDF/*[1]/name() = 'nmo:Region'">
			<p:processor name="oxf:identity">
				<p:input name="data" href="#rdf"/>
				<p:output name="data" ref="data"/>
			</p:processor>
		</p:when>
		<!-- suppress any class of object for which we do not want to render a map -->
		<p:when test="/rdf:RDF/*[1]/name() = 'nmo:ReferenceWork' or /rdf:RDF/*[1]/name() = 'nmo:FieldOfNumismatics' or /rdf:RDF/*[1]/name() = 'nmo:NumismaticTerm' or  /rdf:RDF/*[1]/name() = 'org:Role' or  /rdf:RDF/*[1]/name() = 'nmo:Uncertainty' or  /rdf:RDF/*[1]/name() = 'nmo:CoinWear'">
			<p:processor name="oxf:identity">
				<p:input name="data">
					<null/>
				</p:input>
				<p:output name="data" ref="data"/>
			</p:processor>
		</p:when>
		<!-- apply alternate SPARQL query to get mints associated with a Hoard -->
		<p:otherwise>
			<p:processor name="oxf:unsafe-xslt">
				<p:input name="request" href="#request"/>
				<p:input name="data" href="#rdf"/>
				<p:input name="config-xml" href=" ../../../config.xml"/>
				<p:input name="config">
					<xsl:stylesheet version="2.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:xs="http://www.w3.org/2001/XMLSchema" xmlns:rdf="http://www.w3.org/1999/02/22-rdf-syntax-ns#">
						<xsl:param name="id" select="doc('input:request')/request/parameters/parameter[name='id']/value"/>
						<xsl:variable name="sparql_endpoint" select="doc('input:config-xml')/config/sparql_query"/>						
						<xsl:variable name="type" select="/rdf:RDF/*[1]/name()"/>
						
						<xsl:variable name="classes" as="item()*">
							<classes>
								<class prop="nmo:hasCollection">nmo:Collection</class>
								<class prop="nmo:hasDenomination">nmo:Denomination</class>
								<class prop="?prop">rdac:Family</class>
								<class prop="?prop">nmo:Ethnic</class>								
								<class prop="dcterms:isPartOf">nmo:Hoard</class>
								<class prop="nmo:hasManufacture">nmo:Manufacture</class>
								<class prop="nmo:hasMaterial">nmo:Material</class>
								<class prop="nmo:hasMint">nmo:Mint</class>								
								<class prop="nmo:representsObjectType">nmo:ObjectType</class>
								<class prop="?prop">foaf:Organization</class>
								<class prop="?prop">foaf:Person</class>								
								<class prop="nmo:hasRegion">nmo:Region</class>								
								<class prop="dcterms:source">nmo:TypeSeries</class>
							</classes>
						</xsl:variable>
						
						
						<xsl:variable name="query"><![CDATA[PREFIX rdf:      <http://www.w3.org/1999/02/22-rdf-syntax-ns#>
PREFIX dcterms:  <http://purl.org/dc/terms/>
PREFIX dcmitype:	<http://purl.org/dc/dcmitype/>
PREFIX nm:       <http://nomisma.org/id/>
PREFIX nmo:	<http://nomisma.org/ontology#>
PREFIX skos:      <http://www.w3.org/2004/02/skos/core#>
PREFIX geo: <http://www.w3.org/2003/01/geo/wgs84_pos#>
PREFIX osgeo:	<http://data.ordnancesurvey.co.uk/ontology/geometry/>]]>
<xsl:choose>
	<xsl:when test="$type='nmo:Hoard'"><![CDATA[SELECT DISTINCT ?place ?label ?lat ?long ?poly WHERE {
  ?coin dcterms:isPartOf nm:ID ;
  	rdf:type nmo:NumismaticObject
  {?coin nmo:hasTypeSeriesItem ?type .
        ?type nmo:hasMint ?place}
  UNION {?coin nmo:hasMint ?place}
   ?place skos:prefLabel ?label FILTER langMatches(lang(?label), "en") .
   ?place geo:location ?loc .
  {?loc geo:lat ?lat ;
       geo:long ?long }
  UNION {?loc osgeo:asGeoJSON ?poly }}]]>
	</xsl:when>
	<xsl:when test="$type='nmo:Collection'"><![CDATA[SELECT DISTINCT ?place ?label ?lat ?long ?poly WHERE {
  ?coin nmo:hasCollection nm:ID .
  {?coin nmo:hasTypeSeriesItem ?type .
        ?type nmo:hasMint ?place}
  UNION {?coin nmo:hasMint ?place}
  ?place skos:prefLabel ?label . FILTER langMatches(lang(?label), "en") .
  ?place geo:location ?loc .
  {?loc geo:lat ?lat ;
       geo:long ?long}
  UNION {?loc osgeo:asGeoJSON ?poly}
}]]>
	</xsl:when>
	<xsl:otherwise><![CDATA[SELECT DISTINCT ?place ?label ?lat ?long ?poly WHERE {
{?obj PROP nm:ID ;
          nmo:hasMint ?place .
  ?place geo:location ?loc .
  ?loc geo:lat ?lat ;
       geo:long ?long }
UNION { ?obj PROP nm:ID ;
          nmo:hasMint ?place .
  ?place geo:location ?loc .
  ?loc osgeo:asGeoJSON ?poly }
    ?place skos:prefLabel ?label . FILTER langMatches(lang(?label), "en")
}]]>
	</xsl:otherwise>
</xsl:choose>
</xsl:variable>
						
						<xsl:template match="/">
							<xsl:variable name="service">
								<xsl:choose>
									<xsl:when test="$type='nmo:Hoard' or $type='nmo:Collection'">
										<xsl:value-of select="concat($sparql_endpoint, '?query=', encode-for-uri(normalize-space(replace($query, 'ID', $id))), '&amp;output=xml')"/>
									</xsl:when>
									<xsl:otherwise>
										<xsl:value-of select="concat($sparql_endpoint, '?query=', encode-for-uri(normalize-space(replace(replace($query, 'ID', $id), 'PROP',
											$classes//class[text()=$type]/@prop))), '&amp;output=xml')"/>
									</xsl:otherwise>
								</xsl:choose>
							</xsl:variable>
							
							
							<config>
								<url>
									<xsl:value-of select="$service"/>
								</url>
								<content-type>application/xml</content-type>
								<encoding>utf-8</encoding>
							</config>
						</xsl:template>
						
					</xsl:stylesheet>
				</p:input>
				<p:output name="data" id="url-generator-config"/>
			</p:processor>
			
			<p:processor name="oxf:url-generator">
				<p:input name="config" href="#url-generator-config"/>
				<p:output name="data" ref="data"/>
			</p:processor>
		</p:otherwise>
	</p:choose>
</p:config>