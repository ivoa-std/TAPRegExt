<!--
  -  a stylesheet for preformatting the definitions from an XML Schema
  -  that follows the VOResource schema conventions.  The output is intended
  -  to be pasted into an IVOA specification document.
  -->
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
                xmlns:xs="http://www.w3.org/2001/XMLSchema" 
                xmlns="http://www.w3.org/2001/XMLSchema" 
                xmlns:vm="http://www.ivoa.net/xml/VOMetadata/v0.1" 
                xmlns:vr="http://www.ivoa.net/xml/VOResource/v1.0" 
                version="1.0">

    <xsl:import href="vor2spec.xsl"/>

    <xsl:output method="xml"/>

    <xsl:param name="schemaName" select="xs:schema/xs:annotation/xs:appinfo/xs:schemaName"/>

    <xsl:template match="/" xml:space="preserve">
<html>
<head><title><xsl:value-of select="$schemaName"/> (Internal Working Draft)</title>

<style type="text/css">
    .issue {background-color: yellow}
    .postponedissue {background-color: yellow}
    .def code
    .future {background-color: pink}
    .draftedit {background-color: white}
    .draftdelete {background-color: white}
    .note { margin-left: 4em }
    code { font-weight: bold;
           font-family: monospace } 

div.exampleInner pre { margin-left: 1em;
                       margin-top: 0em; margin-bottom: 0em}
div.exampleOuter {border: 4px double gray;
                  margin: 0em; padding: 0em}
div.exampleInner { border-top-width: 4px;
                   border-top-style: double;
                   border-top-color: white;
                   border-bottom-width: 4px;
                   border-bottom-style: double;
                   border-bottom-color: white;
                   padding: 0px; margin: 0em }
div.exampleWrapper { margin: 4px }
div.exampleHeader { font-weight: bold;
                    margin: 4px}

div.schemaInner pre { margin-left: 1em;
                      margin-top: 0em; margin-bottom: 0em;
                       }
div.schemaOuter {border: 4px double gray; padding: 0em}
div.schemaInner { background-color: #eeeeee;
                   border-top-width: 4px;
                   border-top-style: double;
                   border-top-color: #d3d3d3;
                   border-bottom-width: 4px;
                   border-bottom-style: double;
                   border-bottom-color: #d3d3d3;
                   padding: 4px; margin: 0em }
div.schemaHeader { font-weight: bold;
                    margin: 4px}
</style>
<link href="http://www.ivoa.net/misc/ivoa_a.html" rel="stylesheet" type="text/css" />
<link href="http://www.ivoa.net/misc/ivoa_wd.css" rel="stylesheet" type="text/css" />
</head>
<body bgcolor="white">

<xsl:apply-templates select="xs:schema" />

</body>
</html>


    </xsl:template>

    <xsl:template match="xs:schema" xml:space="preserve">
<h1><xsl:value-of select="$schemaName"/> Content Model Descriptions </h1>
      <xsl:apply-templates select="/xs:schema/xs:complexType|/xs:schema/xs:simpleType" mode="def"/>
    </xsl:template>

    <xsl:template match="xs:complexType|xs:simpleType" mode="def" xml:space="preserve">
<a name="d:{@name}">
<h2><xsl:value-of select="@name"/></h2></a>

<xsl:apply-templates select="." mode="xsddef"/>
<xsl:apply-templates select="." mode="content"/>
<xsl:apply-templates select="." mode="attributes"/>
    </xsl:template>

    <xsl:template match="xs:complexType|xs:simpleType" mode="xsddef" xml:space="preserve">
<div class="schemaOuter">
<a name="s:{@name}">
</a><div class="schemaHeader"><xsl:apply-templates select="." mode="schemaDefTitle"/></div>
<div class="schemaInner">
<pre><xsl:apply-templates select="." mode="xsdcode"/></pre>
</div></div>
    </xsl:template>

    <xsl:template match="xs:complexType[xs:simpleContent]" mode="content"/>

    <xsl:template match="xs:complexType" mode="content" xml:space="preserve">
<p>
<table border="2" width="100%">
<thead>
  <tr><th colspan="2" align="left"><xsl:apply-templates select="." mode="MetadataTitle"/></th>
  </tr><tr><th>Element</th><th>Definition</th>
</tr></thead>
<tbody>
<xsl:apply-templates select=".//xs:element" mode="content"/>
</tbody>
</table>
</p>
    </xsl:template>

    <xsl:template match="xs:simpleType" mode="content"/>

    <xsl:template match="xs:complexType|xs:simpleType" mode="attributes">
      <xsl:if test=".//xs:attribute" xml:space="preserve">
<p>
<table border="2" width="100%">
<thead>
  <tr><th colspan="2" align="left"><xsl:apply-templates select="." mode="attributeTitle"/></th>
  </tr><tr><th>Attribute</th><th>Definition</th>
</tr></thead>
<tbody>
<xsl:apply-templates select=".//xs:attribute" mode="attributes"/>
</tbody>
</table>
</p>
      </xsl:if>
    </xsl:template>

    <xsl:template match="xs:element" mode="content" xml:space="preserve">
  <tr><td valign="top"><xsl:value-of select="@name"/></td>
      <td valign="top"><table border="0" width="100%"><tbody>
<xsl:apply-templates select="." mode="nextContentItem"/>      </tbody></table>
  </td></tr>
    </xsl:template>

    <xsl:template match="xs:attribute" mode="attributes" xml:space="preserve">
  <tr><td valign="top"><xsl:value-of select="@name"/></td>
      <td valign="top"><table border="0" width="100%"><tbody>
<xsl:apply-templates select="." mode="nextContentItem"/>      </tbody></table>
  </td></tr>
    </xsl:template>

    <xsl:template match="xs:element" mode="content.rmname">
        <xsl:param name="row" select="1"/>

        <xsl:for-each select="." xml:space="preserve">          <tr bgcolor="#dddddd"><td nowrap="nowrap" valign="top"><em>RM Name:</em></td>
              <td valign="top"><xsl:for-each select="xs:annotation/xs:appinfo/vm:dcterm" xml:space="default">
              <xsl:if test="position()!=1">
                 <xsl:text>, </xsl:text>
              </xsl:if>
              <xsl:value-of select="."/>
            </xsl:for-each></td>
          </tr>
</xsl:for-each>
    </xsl:template>

    <xsl:template match="xs:element|xs:attribute" mode="content.type">
        <xsl:param name="row" select="1"/>

        <xsl:variable name="type">
           <xsl:choose>
              <xsl:when test="@type">
                 <xsl:apply-templates select="@type" mode="type"/>
              </xsl:when>
              <xsl:otherwise>
                 <xsl:apply-templates select="xs:complexType|xs:simpleType" 
                                      mode="type"/>
              </xsl:otherwise>
           </xsl:choose>
        </xsl:variable>

        <xsl:variable name="color">
           <xsl:call-template name="rowBgColor">
              <xsl:with-param name="row" select="$row"/>
           </xsl:call-template>
        </xsl:variable>

        <xsl:for-each select="." xml:space="preserve">          <tr bgcolor="{$color}"><td nowrap="nowrap" valign="top"><em>Value type:</em></td>
              <td valign="top"><xsl:copy-of select="$type"/></td>
          </tr>
</xsl:for-each>
    </xsl:template>

    <xsl:template match="xs:element|xs:attribute" mode="content.meaning">
        <xsl:param name="row" select="1"/>

        <xsl:variable name="color">
           <xsl:call-template name="rowBgColor">
              <xsl:with-param name="row" select="$row"/>
           </xsl:call-template>
        </xsl:variable>

        <xsl:for-each select="." xml:space="preserve">          <tr bgcolor="{$color}"><td nowrap="nowrap" valign="top"><em>Semantic Meaning:</em></td>
              <td valign="top" width="90%"><xsl:value-of select="xs:annotation/xs:documentation[1]"/></td>
          </tr>
</xsl:for-each>
    </xsl:template>

    <xsl:template match="xs:attribute" mode="content.default">
        <xsl:param name="row" select="1"/>

        <xsl:variable name="color">
           <xsl:call-template name="rowBgColor">
              <xsl:with-param name="row" select="$row"/>
           </xsl:call-template>
        </xsl:variable>

        <xsl:for-each select="." xml:space="preserve">          <tr bgcolor="{$color}"><td nowrap="nowrap"
              valign="top"><em>Default Value:</em></td>
              <td valign="top" width="90%"><code><xsl:value-of select="@default"/></code></td> 
          </tr>
</xsl:for-each>
    </xsl:template>

    <xsl:template match="xs:element|xs:attribute" mode="content.occurrences">
        <xsl:param name="row" select="1"/>

        <xsl:variable name="color">
           <xsl:call-template name="rowBgColor">
              <xsl:with-param name="row" select="$row"/>
           </xsl:call-template>
        </xsl:variable>

        <xsl:for-each select="." xml:space="preserve">          <tr bgcolor="{$color}"><td nowrap="nowrap" valign="top"><em>Occurrences:</em></td>
              <td valign="top"><xsl:apply-templates select="." mode="occurrences"/></td>
          </tr>
</xsl:for-each>
    </xsl:template>

    <xsl:template match="xs:element|xs:attribute" mode="content.allowedValues">
        <xsl:param name="row" select="1"/>
        <xsl:param name="type" select="@type"/>

        <xsl:variable name="color">
           <xsl:call-template name="rowBgColor">
              <xsl:with-param name="row" select="$row"/>
           </xsl:call-template>
        </xsl:variable>

        <xsl:for-each select="." xml:space="preserve">          <tr bgcolor="{$color}"><td nowrap="nowrap" valign="top"><em>Allowed Values:</em></td>
              <td valign="top"><xsl:apply-templates select="xs:simpleType/xs:restriction|/xs:schema/xs:simpleType[@name=substring-after($type,':')]/xs:restriction" mode="howtolist" /></td> 
          </tr>
</xsl:for-each>
    </xsl:template>

    <xsl:template match="xs:restriction[xs:enumeration]" mode="howtolist">
      <xsl:choose>
        <xsl:when test="xs:enumeration/xs:annotation/xs:documentation"
                  xml:space="preserve"><table border="0" width="100%"><tbody>
<xsl:apply-templates select="xs:enumeration" mode="controlledVocab" />
              </tbody></table></xsl:when>
        <xsl:otherwise>
           <xsl:for-each select="xs:enumeration">
              <code><xsl:value-of select="@value"/></code>
              <xsl:if test="position()!=last()">
                 <xsl:text>, </xsl:text>
              </xsl:if>
</xsl:for-each>
        </xsl:otherwise>
      </xsl:choose>
    </xsl:template>

    <xsl:template match="xs:enumeration" mode="controlledVocab" xml:space="preserve">
                 <tr><td valign="top"><code><xsl:value-of select="@value"/></code> </td>
                     <td><xsl:value-of select="xs:annotation/xs:documentation"/></td></tr>
    </xsl:template>

    <xsl:template match="xs:element|xs:attribute" mode="content.comment">
        <xsl:param name="row" select="1"/>

        <xsl:variable name="color">
           <xsl:call-template name="rowBgColor">
              <xsl:with-param name="row" select="$row"/>
           </xsl:call-template>
        </xsl:variable>

        <xsl:for-each select="." xml:space="preserve">          <tr bgcolor="{$color}"><td nowrap="nowrap" valign="top"><em>Comments:</em></td>
              <td valign="top"><xsl:for-each select="xs:annotation/xs:documentation[position() > 1]">
<p><xsl:value-of select="."/></p>
              </xsl:for-each></td> 
          </tr>
</xsl:for-each>
    </xsl:template>



    <xsl:template name="rowBgColor">
       <xsl:param name="row" select="1"/>
       <xsl:choose>
          <xsl:when test="$row mod 2 = 1">#dddddd</xsl:when>
          <xsl:otherwise>#f5f5f5</xsl:otherwise>
       </xsl:choose>
    </xsl:template>    

</xsl:stylesheet>
