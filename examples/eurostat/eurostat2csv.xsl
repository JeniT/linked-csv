<?xml version="1.0" encoding="UTF-8"?>
<!--
This stylesheet converts Eurostat XML for individual tables which are accessible from
  http://epp.eurostat.ec.europa.eu/portal/page/portal/statistics/themes
into linked CSV format. It creates a directory that contains an index CSV file, a CSV
file for the data itself, and a CSV file for each of the codelists used within the data.

Note that the original XML data doesn't contain all the information which could be
included; more is available from the bulk download Eurostat service.
	-->
<xsl:stylesheet version="2.0"
	xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
	xmlns:xs="http://www.w3.org/2001/XMLSchema"
	exclude-result-prefixes="xs">

<xsl:output method="text" encoding="UTF-8" />

<xsl:strip-space elements="*"/>

<xsl:key name="codes" match="Element[@name = 'code']" use="@value" />
<xsl:key name="english-codes" match="Group[@type = 'language' and @value = 'en']//Element[@name = 'code']" use="@value" />
<xsl:key name="dictionaries" match="Group[@type = 'dictionary']" use="@value" />

<xsl:template match="Table">
	<xsl:apply-templates select="Information" />
</xsl:template>

<xsl:template match="Information">
	<xsl:variable name="information" as="element(Information)" select="." />
	<xsl:variable name="context" as="xs:string" select="Group[@type = 'context']/Element[@name = 'table']/@value" />
	<xsl:variable name="languages" as="xs:string+" select="Group[@type = 'nomenclature']/Group[@type = 'language']/@value" />
	<xsl:variable name="flags" as="xs:string*" select="distinct-values(../Grid//Ref/@value)" />
	<xsl:variable name="headers" as="element(cell)+">
		<xsl:apply-templates select="../Grid" mode="header" />
	</xsl:variable>
	<xsl:variable name="footnotes" as="element(Element)*" select=".//Group[@type = 'dictionary' and @value = 'flagsfootnotes']/Element[@name = 'code' and not(@value = $flags)]" />
	<xsl:variable name="flagrefs" as="element(Ref)*" select="../Grid//Ref" />
	<xsl:variable name="tables">
		<table context="{$context}" name="index">
			<row>
				<cell>#</cell>
				<cell>$id</cell>
				<xsl:for-each select="$languages">
					<cell>title (<xsl:value-of select="." />)</cell>
				</xsl:for-each>
			</row>
			<row>
				<cell>lang</cell>
				<cell></cell>
				<xsl:for-each select="$languages">
					<cell><xsl:value-of select="." /></cell>
				</xsl:for-each>
			</row>
			<row>
				<cell>prop</cell>
				<cell></cell>
				<xsl:for-each select="$languages">
					<cell>dc:title</cell>
				</xsl:for-each>
			</row>
			<row>
				<cell></cell>
				<cell><xsl:value-of select="$context" />.csv</cell>
				<xsl:for-each select="key('codes', $context, $information)">
					<cell><xsl:apply-templates select="." mode="label" /></cell>
				</xsl:for-each>
			</row>
			<xsl:for-each select="$headers[@url = 'true']">
				<row>
					<cell></cell>
					<cell><xsl:value-of select="." />.csv</cell>
					<xsl:for-each select="key('codes', ., $information)">
						<cell><xsl:apply-templates select="." mode="label" /></cell>
					</xsl:for-each>
				</row>
			</xsl:for-each>
		</table>
		<table context="{$context}" name="{$context}">
			<row>
				<cell>#</cell>
				<cell>$id</cell>
				<xsl:for-each select="$headers">
					<cell><xsl:apply-templates select="key('english-codes', ., $information)" mode="label" /></cell>
				</xsl:for-each>
				<cell><xsl:apply-templates select="key('english-codes', $context, $information)" mode="label" /></cell>
			</row>
			<row>
				<cell>prop</cell>
				<cell></cell>
				<xsl:for-each select="$headers">
					<cell>http://epp.eurostat.ec.europa.eu/def/<xsl:value-of select="$context" />#<xsl:value-of select="." /></cell>
				</xsl:for-each>
				<cell>http://epp.eurostat.ec.europa.eu/def/<xsl:value-of select="$context" />#<xsl:value-of select="$context" /></cell>
			</row>
			<row>
				<cell>type</cell>
				<cell></cell>
				<xsl:for-each select="$headers">
					<cell>
						<xsl:choose>
							<xsl:when test="@url = 'true'">url</xsl:when>
							<xsl:when test=". = 'time'">time</xsl:when>
						</xsl:choose>
					</cell>
				</xsl:for-each>
				<cell></cell>
			</row>
			<row>
				<cell>see</cell>
				<cell></cell>
				<xsl:for-each select="$headers">
					<cell>
						<xsl:if test="@url = 'true'"><xsl:value-of select="." />.csv</xsl:if>
					</cell>
				</xsl:for-each>
				<cell></cell>
			</row>
			<row>
				<cell>meta</cell>
				<cell></cell>
				<cell>source</cell>
				<cell>url</cell>
				<cell>http://epp.eurostat.ec.europa.eu/cache/ITY_FIXDST/<xsl:value-of select="$context" />.xml</cell>
				<cell>dc:source</cell>
			</row>
			<xsl:for-each select="$footnotes">
				<xsl:variable name="lang" as="xs:string" select="ancestor::Group[@type = 'language']/@value" />
				<row>
					<cell>meta</cell>
					<cell>#col=<xsl:value-of select="count($headers) + 2" /></cell>
					<cell>footnote</cell>
					<cell><xsl:value-of select="$lang" /></cell>
					<cell><xsl:value-of select="@value" /> = <xsl:apply-templates select="." mode="label" /></cell>
					<cell>rdfs:comment</cell>
				</row>
			</xsl:for-each>
			<xsl:for-each select="../Grid//Cell">
				<xsl:variable name="cell" as="element(Cell)" select="." />
				<row>
					<!-- # --><cell></cell>
					<!-- $id --><cell></cell>
					<xsl:for-each select="$headers">
						<xsl:variable name="header" as="xs:string" select="." />
						<xsl:variable name="value" as="xs:string" select="$cell/ancestor::Position[../@name = $header]/@value" />
						<cell>
							<xsl:choose>
								<xsl:when test="@url = 'true'">http://epp.eurostat.ec.europa.eu/def/<xsl:value-of select="." />#<xsl:value-of select="$value" /></xsl:when>
								<xsl:otherwise><xsl:value-of select="$value" /></xsl:otherwise>
							</xsl:choose>
						</cell>
					</xsl:for-each>
					<cell><xsl:value-of select="@value" /></cell>
				</row>
			</xsl:for-each>
			<xsl:for-each select="$flagrefs">
				<xsl:variable name="row" as="xs:integer" select="count(../preceding::Cell) + 4 + count($footnotes)" />
				<xsl:variable name="flag" as="element(Element)+" select="key('codes', @value, $information)" />
				<xsl:for-each select="$flag">
					<xsl:variable name="lang" as="xs:string" select="ancestor::Group[@type = 'language']/@value" />
					<row>
						<cell>meta</cell>
						<cell>#cell=<xsl:value-of select="$row" />,<xsl:value-of select="count($headers) + 2" /></cell>
						<cell>flag</cell>
						<cell><xsl:value-of select="$lang" /></cell>
						<cell><xsl:apply-templates select="." mode="label" /></cell>
						<cell>rdfs:comment</cell>
					</row>
				</xsl:for-each>
			</xsl:for-each>
		</table>
		<xsl:for-each select="$headers[@url = 'true']">
			<xsl:variable name="header" as="xs:string" select="." />
			<xsl:variable name="dictionaries" as="element(Group)+" select="key('dictionaries', $header, $information)" />
			<xsl:variable name="codes" as="xs:string+" select="distinct-values($dictionaries/Element[@name = 'code']/@value)" />
			<table context="{$context}" name="{$header}">
				<row>
					<cell>#</cell>
					<cell>$id</cell>
					<xsl:for-each select="$languages">
						<cell>label (<xsl:value-of select="." />)</cell>
					</xsl:for-each>
				</row>
				<row>
					<cell>prop</cell>
					<cell></cell>
					<xsl:for-each select="$languages">
						<cell>rdfs:label</cell>
					</xsl:for-each>
				</row>
				<row>
					<cell>lang</cell>
					<cell></cell>
					<xsl:for-each select="$languages">
						<cell><xsl:value-of select="." /></cell>
					</xsl:for-each>
				</row>
				<xsl:for-each select="key('codes', $header, $information)">
					<xsl:variable name="lang" as="xs:string" select="ancestor::Group[@type = 'language']/@value" />
					<row>
						<cell>meta</cell>
						<cell></cell>
						<cell>title (<xsl:value-of select="$lang" />)</cell>
						<cell><xsl:value-of select="$lang" /></cell>
						<cell><xsl:apply-templates select="." mode="label" /></cell>
						<cell>dc:title</cell>
					</row>
				</xsl:for-each>
				<row>
					<cell>meta</cell>
					<cell></cell>
					<cell>source</cell>
					<cell>url</cell>
					<cell>http://epp.eurostat.ec.europa.eu/cache/ITY_FIXDST/<xsl:value-of select="$context" />.xml</cell>
					<cell>dc:source</cell>
				</row>
				<xsl:for-each select="$codes">
					<xsl:variable name="code" as="xs:string" select="." />
					<row>
						<cell></cell>
						<cell>http://epp.eurostat.ec.europa.eu/def/<xsl:value-of select="$header" />#<xsl:value-of select="$code" /></cell>
						<xsl:for-each select="$languages">
							<xsl:variable name="lang" as="xs:string" select="." />
							<cell><xsl:apply-templates select="$dictionaries[../@value = $lang]/Element[@name = 'code' and @value = $code]" mode="label" /></cell>
						</xsl:for-each>
					</row>
				</xsl:for-each>
			</table>
		</xsl:for-each>
	</xsl:variable>
	<xsl:apply-templates select="$tables" mode="csv" />
</xsl:template>

<xsl:template match="*[starts-with(name(.), 'Axis')]" mode="header">
	<xsl:variable name="dictionaries" as="element(Group)+" select="key('dictionaries', @name)" />
	<cell url="{exists($dictionaries/Element[@name = 'code' and not(@value = AttList/Att[@name = 'label'])])}">
		<xsl:value-of select="@name" />
	</cell>
	<xsl:apply-templates select="(.//*[starts-with(name(.), 'Axis')])[1]" mode="#current" />
</xsl:template>

<xsl:template match="Element" mode="label">
	<xsl:value-of select="normalize-space(AttList/Att[@name = 'label'])" />
</xsl:template>

<xsl:template match="table" mode="csv">
	<xsl:result-document method="text" encoding="UTF-8" byte-order-mark="yes" media-type="text/csv" href="{@context}/{@name}.csv">
		<xsl:apply-templates select="row" mode="csv">
			<xsl:with-param name="cells" select="max(row/count(cell))" />
		</xsl:apply-templates>
	</xsl:result-document>
</xsl:template>

<xsl:template match="row" mode="csv">
	<xsl:param name="cells" as="xs:integer" required="yes" />
	<xsl:for-each select="cell">
		<xsl:choose>
			<xsl:when test="contains(., ',') or contains(., '&quot;')">"<xsl:value-of select="replace(., '&quot;', '&quot;&quot;')" />"</xsl:when>
			<xsl:otherwise><xsl:value-of select="." /></xsl:otherwise>
		</xsl:choose>
		<xsl:if test="position() != last()">,</xsl:if>
	</xsl:for-each>
	<xsl:for-each select="count(cell) to $cells - 1">,</xsl:for-each>
	<xsl:text>&#xD;&#xA;</xsl:text>
</xsl:template>

</xsl:stylesheet>