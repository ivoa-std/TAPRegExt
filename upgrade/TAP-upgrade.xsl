<?xml version="1.0" encoding="UTF-8"?>
<!--
  -  This will convert records that have a TAP capability to use the 
  -  v1.0 version of the TAPRegExt extension.  If the resource file
  -  only cites the TAP standard ID but otherwise does not use any 
  -  (proto) version of the TAP registry schema, this stylesheet will 
  -  fill in minimal default information: namely, the support for ADQL 2.0.  
  -
  -  Note that this stylesheet requires an XSLT version 2 engine.  It has 
  -  has been tested against Saxon v8, which is available via
  -  http://wiki.ivoa.net/internal/IVOA/RegUpgradeSummer2006/saxon8.jar.
  -  To run, type: 
  -
  -     java -jar saxon8.jar tapresource.xml TAP-upgrade.xsl [param=val ...]
  -        > updresource.xml
  -  
  -  This stylesheet tries to neaten things up a bit:
  -    o  all VOResource related namespaces are declared at the resource root
  -    o  The TAP and VODataService namespaces will only be declared if they 
  -         are actually used.  (Other schemas which appear to be superfluous 
  -         are still passed.)
  -    o  pretty indentation can be applied (over-riding the original 
  -         indentation) can be turned on by setting the prettyPrint parameter
  -         to true.  (The ident parameter overrides the default indentation.)
  -         Otherwise, the original indentation is preserved.  
  -  
  -  Other Features:
  -    o  If the VOResource is wrapped in a non-VO envelope (e.g. OAI envelope),
  -         it will be passed unchanged.  
  -    o  VODataService v1.0 is transformed to VODataService v1.1
  -    o  If the transTAPonly is true (the default), a record will be updated
  -         only if it describes a TAP service; if it doesn't, 
  -         VODataService v1.0 will not be tranformed.  If transTAPonly 
  -         is false, VODataService v1.0 is always transformed to 
  -         VODataService v1.1, regardless of whether the TAP extension is 
  -         invoked.
  -    o  see parameter documentation below for further controls.  
  -->
<xsl:stylesheet xmlns:vr="http://www.ivoa.net/xml/VOResource/v1.0" 
                xmlns:vs="http://www.ivoa.net/xml/VODataService/v1.1" 
                xmlns:tap="http://www.ivoa.net/xml/TAP/v1.0" 
                xmlns:stc="http://www.ivoa.net/xml/STC/stc-v1.30.xsd" 
                xmlns:vs2="http://www.ivoa.net/xml/VODataService/v1.0" 
                xmlns:tap0="http://www.ivoa.net/xml/TAP/v0.1" 
                xmlns:xlink="http://www.w3.org/1999/xlink" 
                xmlns:xsl="http://www.w3.org/1999/XSL/Transform" 
                xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" 
                xmlns=""
                exclude-result-prefixes="#all" 
                version="2.0">

   <!-- 
     -  Stylesheet to convert VOResource records from VODataService v1.0
     -   to VODataService v1.1
     -->
   <xsl:output method="xml" encoding="UTF-8" indent="yes" />

   <xsl:preserve-space elements="*"/>

   <!--
     -  If true, insert carriage returns and indentation to produce a neatly 
     -  formatted output.  If false, any spacing between tags in the source
     -  document will be preserved.  
     -->
   <xsl:param name="prettyPrint" select="false()"/>

   <xsl:param name="useAutoIndent">
     <xsl:choose>
        <xsl:when test="$prettyPrint">yes</xsl:when>
        <xsl:otherwise>no</xsl:otherwise>
     </xsl:choose>
   </xsl:param>

   <!--
     -  the per-level indentation.  Set this to a sequence of spaces when
     -  pretty printing is turned on.
     -->
   <xsl:param name="indent">
      <xsl:for-each select="/*/*[2]">
         <xsl:call-template name="getindent"/>
      </xsl:for-each>
   </xsl:param>

   <!--
     -  The prefix to prepend to schema files listed in the xsi:schemaLocation
     -  (if used).  The value should include a trailing slash as necessary.
     -  The default is an empty string, which indicates the current working 
     -  directory (where output is used).  Note that the xsi:schemaLocation 
     -  is only set if it is set on the input.
     -->
   <xsl:param name="schemaLocationPrefix"/>

   <!--
     -  Set to 1 if the xsi:schemaLocation should be set or zero if it should
     -  not be.  If not set at all (default), xsi:schemaLocation is only set 
     -  if it is set on the input.
     -->
   <xsl:param name="setSchemaLocation"/>

   <!--
     -  Set to 0 or greater if a default validationLevel should set
     -  as all possible locations.  If greater than -1, the value will 
     -  be the value of the validationLevel.  You must also provide
     -  an ID to the validatedBy parameter below in order for the level
     -  to be set.  
     -->
   <xsl:param name="validationLevel" select="-1"/>

   <!-- 
     -  Set to the IVOA identifier of your validating registry.  This 
     -  must be set for validation levels to be added.  
     -->
   <xsl:param name="validatedBy"/>

   <!--
     -  If set, the updated atribute will be set to this value
     -->
   <xsl:param name="today"/>

   <!--
     -  If true, transform only records that describe tap services; otherwise,
     -  any record that simple invokes VODataService v1.0 will be converted
     -  to use VODataService v1.1.  If false or not set, non-TAP services 
     -  invoking VODataService v1.0 will be passed unchanged.  
     -->
   <xsl:param name="transTAPonly" select="true()"/>

   <!--
     -  If set, the output document will have a root element of this
     -  name and a namespace given by $resourceNS and it will contain
     -  the VOResource metadata.
     -
     -  the default setting will produce records
     -  that can be inserted directly into a Harvest response record.
     -->
   <xsl:param name="resourceElement">Resource</xsl:param>

   <!--
     -  If resourceName is set (with an non-empty value), the output 
     -  document will have a root element of $resourceName and a 
     -  this namespace.  It will contain the VOResource metadata; all 
     -  other wrapping elements from the input will be filtered out. 
     -->
   <xsl:param name="resourceNS">http://www.ivoa.net/xml/RegistryInterface/v1.0</xsl:param>

   <!--
     -  The namespace to assign to the VOResource root element in the output
     -  document.  This defaults to the value of $resourceNS (which 
     -  defaults to the IVOA RegistryInterface namespace).
     -->
   <xsl:param name="newResourceNS" select="$resourceNS"/>

   <!-- 
     -  The prefix to assign to the namespace for the output root element.
     -  The default is ri.
     -->
   <xsl:param name="newResourcePrefix">ri</xsl:param>

   <!--
     -  The name to give to the VOResource root element in the output
     -  document.  This defaults to the value of $resourceName (which 
     -  defaults to "Resource").
     -->
   <xsl:param name="newResourceElement" 
              select="concat($newResourcePrefix,':',$resourceElement)"/>

   <xsl:param name="xsi">http://www.w3.org/2001/XMLSchema-instance</xsl:param>
   <xsl:param name="vs10">http://www.ivoa.net/xml/VODataService/v1.0</xsl:param>
   <xsl:param name="vs11">http://www.ivoa.net/xml/VODataService/v1.1</xsl:param>
   <xsl:param name="tap10">http://www.ivoa.net/xml/TAP/v1.0</xsl:param>
   <xsl:variable name="TAPstdID">ivo://ivoa.net/std/TAP</xsl:variable>
   <xsl:variable name="SIAstdID">ivo://ivoa.net/std/SIA</xsl:variable>
   <xsl:variable name="SSAstdID">ivo://ivoa.net/std/SSA</xsl:variable>
   <xsl:variable name="SLAstdID">ivo://ivoa.net/std/SLAP</xsl:variable>
   <xsl:variable name="SCSstdID">ivo://ivoa.net/std/ConeSearch</xsl:variable>

   <xsl:variable name="hasVS10">
      <xsl:for-each select="//@xsi:type">
         <xsl:if test="namespace-uri-for-prefix(substring-before(.,':'),..)=$vs10">1</xsl:if>
      </xsl:for-each>
   </xsl:variable>
   <xsl:variable name="hasVS11">
      <xsl:for-each select="//@xsi:type">
         <xsl:if test="namespace-uri-for-prefix(substring-before(.,':'),..)=$vs11">1</xsl:if>
      </xsl:for-each>
   </xsl:variable>
   <xsl:variable name="needVS11" 
                 select="boolean($hasVS10) or boolean($hasVS11)"/>

   <xsl:variable name="setSL">
      <xsl:choose>
         <xsl:when test="$setSchemaLocation=''">
            <xsl:choose>
               <xsl:when test="/*/@xsi:schemaLocation">
                  <xsl:copy-of select="1"/>
               </xsl:when>
               <xsl:otherwise><xsl:copy-of select="0"/></xsl:otherwise>
            </xsl:choose>
         </xsl:when>
         <xsl:otherwise>
            <xsl:copy-of select="number($setSchemaLocation)"/>
         </xsl:otherwise>
      </xsl:choose>
   </xsl:variable>

   <xsl:variable name="cr"><xsl:text>
</xsl:text></xsl:variable>

   <xsl:variable name="istep">
      <xsl:if test="$prettyPrint">
         <xsl:value-of select="$indent"/>
      </xsl:if>
   </xsl:variable>
   <xsl:variable name="isp">
      <xsl:value-of select="$cr"/>
   </xsl:variable>

   <!-- ==========================================================
     -  General templates
     -  ========================================================== -->

   <xsl:template match="/">
      <xsl:apply-templates select="*">
         <xsl:with-param name="sp">
            <xsl:if test="$prettyPrint">
              <xsl:value-of select="$cr"/>
            </xsl:if>
         </xsl:with-param>
         <xsl:with-param name="step">
            <xsl:if test="$prettyPrint">
              <xsl:value-of select="$indent"/>
            </xsl:if>
         </xsl:with-param>
      </xsl:apply-templates>
   </xsl:template>

   <xsl:template match="*[local-name()=$resourceElement and 
                          namespace-uri()=$resourceNS]"  priority="2">
      <xsl:param name="sp"/>
      <xsl:param name="step"/>

      <xsl:choose>
         <xsl:when test="not($transTAPonly) or .//*[@standardID=$TAPstdID]">
            <xsl:apply-templates select="." mode="VOResourceRoot">
               <xsl:with-param name="sp" select="$sp"/>
               <xsl:with-param name="step" select="$step"/>
            </xsl:apply-templates>
         </xsl:when>
         <xsl:otherwise>
            <xsl:apply-templates select="." mode="nonvor">
               <xsl:with-param name="sp" select="$sp"/>
               <xsl:with-param name="step" select="$step"/>
            </xsl:apply-templates>
         </xsl:otherwise>
      </xsl:choose>
   </xsl:template>

   <xsl:template match="*" mode="VOResourceRoot">
      <xsl:param name="sp"/>
      <xsl:param name="step"/>

      <xsl:param name="updatingprefixes">
         <xsl:text>#</xsl:text>
         <xsl:value-of select="$newResourcePrefix"/>
         <xsl:text>#</xsl:text>
         <xsl:if test="@xsi:type[starts-with(.,'vs:')]">
            <xsl:text>vs#</xsl:text>
         </xsl:if>
         <xsl:if test="*//@xsi:type[starts-with(.,'tap:')]">tap#</xsl:if>
      </xsl:param>

      <xsl:variable name="inheritedprefixes">
         <xsl:for-each select="parent::element()">
            <xsl:call-template name="newprefixes"/>
         </xsl:for-each>
      </xsl:variable>

      <xsl:variable name="curel" select="."/>

      <xsl:element name="{$newResourceElement}" namespace="{$newResourceNS}">
         <!-- the ri namespace (user-controlled) -->
         <xsl:namespace name="{$newResourcePrefix}" select="$newResourceNS"/>

         <!-- the VODataService v1.1 namespace -->
         <xsl:if test="$needVS11">
           <xsl:namespace name="vs" select="$vs11"/>
         </xsl:if>

         <!--
           -  add the TAP namespace as needed
           -->
         <xsl:if test="*//@xsi:type[starts-with(.,'tap:')]|
                       capability[@standardID=$TAPstdID]">
            <xsl:namespace name="tap" select="$tap10"/>
         </xsl:if>

         <xsl:for-each select="in-scope-prefixes(.)">
            <xsl:if test="not(contains($updatingprefixes, .)) and 
                          not(contains($inheritedprefixes, .)) and 
                          $curel//*[starts-with(@xsi:type, concat(.,'#'))]">
               <!-- this if is meant to avoid declaring namespaces that are 
                    not used. -->
               <xsl:namespace name="{.}" 
                              select="namespace-uri-for-prefix(.,$curel)"/>
            </xsl:if>
         </xsl:for-each>

         <xsl:apply-templates select="@status" mode="vor"/>
         <xsl:apply-templates select="@created" mode="vor"/>
         <xsl:attribute name="updated">
            <xsl:choose>
               <xsl:when test="$today">
                  <xsl:value-of select="$today"/>
               </xsl:when>
               <xsl:otherwise>
                  <xsl:value-of select="@updated"/>
               </xsl:otherwise>
            </xsl:choose>
         </xsl:attribute>
         <xsl:apply-templates select="@*[local-name()!='updated' and 
                                         local-name()!='created' and 
                                         local-name()!='status' and 
                                         not(local-name()='type' and 
                                             namespace-uri()=$xsi)]"  
                              mode="vor" />
         <xsl:apply-templates select="@xsi:type"/>

         <xsl:variable name="defined">
            <xsl:value-of select="$inheritedprefixes"/>
            <xsl:value-of select="$updatingprefixes"/>
            <xsl:for-each select="in-scope-prefixes(.)">
              <xsl:if test="not(contains($updatingprefixes, .)) and 
                            not(contains($inheritedprefixes, .)) and 
                            $curel//*[starts-with(@xsi:type, concat(.,'#'))]">
                <xsl:value-of select="."/>
                <xsl:text>#</xsl:text>
              </xsl:if>
            </xsl:for-each>
         </xsl:variable>

         <xsl:apply-templates select="*|text()" mode="vor">
            <xsl:with-param name="sp" select="concat($sp,$step)"/>
            <xsl:with-param name="step" select="$step"/>
            <xsl:with-param name="pfx" select="$defined"/>
         </xsl:apply-templates>
         <xsl:value-of select="$sp"/>
      </xsl:element>
   </xsl:template>

   <!--
     -  Handle table descriptions from DataCollection resources.
     -  catalog -> schema; wrap them in a tableset
     -->
   <xsl:template match="catalog[position()=1]">
      <xsl:param name="sp"/>
      <xsl:param name="step"/>

      <xsl:variable name="usesp">
         <xsl:choose>
           <xsl:when test="$prettyPrint">
             <xsl:value-of select="$sp"/>
           </xsl:when>
           <xsl:otherwise>
             <xsl:apply-templates 
                  select="preceding-sibling::text()[position()=last()]" />
           </xsl:otherwise>
         </xsl:choose>
      </xsl:variable>
      <xsl:variable name="childsp">
         <xsl:apply-templates select="preceding-sibling::curation/text()[1]" />
      </xsl:variable>
      <xsl:variable name="usestep">
         <xsl:choose>
            <xsl:when test="$prettyPrint">
               <xsl:value-of select="$step"/>
            </xsl:when>
            <xsl:when 
                 test="string-length(substring-after($childsp,$usesp)) &gt; 0">
               <xsl:value-of select="substring-after($childsp,$usesp)"/>
            </xsl:when>
            <xsl:otherwise>
               <xsl:value-of select="$indent"/>
            </xsl:otherwise>
         </xsl:choose>
      </xsl:variable>

      <xsl:value-of select="$usesp"/>
      <tableset>
         <xsl:apply-templates select="../catalog" mode="newtables">
            <xsl:with-param name="sp" select="concat($usesp,$usestep)"/>
            <xsl:with-param name="step" select="$usestep"/>
         </xsl:apply-templates>
         <xsl:value-of select="$usesp"/>
      </tableset>

   </xsl:template>
   <xsl:template match="catalog" priority="-1"/>

   <xsl:template match="catalog" mode="newtables">
      <xsl:param name="sp"/>
      <xsl:param name="step"/>

      <xsl:variable name="subsp" select="concat($sp,$step)"/>

      <xsl:value-of select="$sp"/>
      <schema>
         <xsl:value-of select="$subsp"/>
         <name>c<xsl:value-of select="position()"/></name>
         <xsl:value-of select="$subsp"/>
         <description>
            <xsl:value-of select="concat($subsp,'  ')"/>
            <xsl:text>The catalog: </xsl:text>
            <xsl:value-of select="../title"/>
            <xsl:value-of select="$subsp"/>
         </description>
         <xsl:apply-templates select="table" mode="newtables">
            <xsl:with-param name="sp" select="concat($sp,$step)"/>
            <xsl:with-param name="step" select="$step"/>
         </xsl:apply-templates>
         <xsl:value-of select="$sp"/>
      </schema>
   </xsl:template>

   <!-- 
     -  this will handle tables from the various Service resources
     -  which need to be wrapped in tablesets.  
     -->
   <xsl:template match="table[position()=1]" mode="vor">
      <xsl:param name="sp"/>
      <xsl:param name="step"/>

      <xsl:variable name="usesp">
         <xsl:choose>
           <xsl:when test="$prettyPrint">
             <xsl:value-of select="$sp"/>
           </xsl:when>
           <xsl:otherwise>
             <xsl:apply-templates 
                  select="preceding-sibling::text()[position()=last()]" />
           </xsl:otherwise>
         </xsl:choose>
      </xsl:variable>
      <xsl:variable name="childsp">
         <xsl:apply-templates select="preceding-sibling::curation/text()[1]" />
      </xsl:variable>
      <xsl:variable name="usestep">
         <xsl:choose>
            <xsl:when test="$prettyPrint">
               <xsl:value-of select="$step"/>
            </xsl:when>
            <xsl:when 
                 test="string-length(substring-after($childsp,$usesp)) &gt; 0">
               <xsl:value-of select="substring-after($childsp,$usesp)"/>
            </xsl:when>
            <xsl:otherwise>
               <xsl:value-of select="$indent"/>
            </xsl:otherwise>
         </xsl:choose>
      </xsl:variable>

      <xsl:variable name="description">
         <xsl:value-of select="concat($usesp,$usestep,$usestep,'  ')"/>
         <xsl:choose>
            <xsl:when test="../capability[@standardID=$TAPstdID]">
               <xsl:text>The catalog: </xsl:text>
               <xsl:value-of select="../title"/>
               <xsl:text>,</xsl:text>
               <xsl:value-of select="concat($usesp,$usestep,$usestep,'  ')"/>
               <xsl:text>available via the TAP interface.</xsl:text>
            </xsl:when>
            <xsl:otherwise>
               <xsl:text>The query response table.  Queries to this service will return</xsl:text>
               <xsl:value-of select="concat($usesp,$usestep,$usestep,'  ')"/>
               <xsl:text>a VOTable with the structure described here.</xsl:text>
            </xsl:otherwise>
         </xsl:choose>
      </xsl:variable>

      <xsl:value-of select="$usesp"/>
      <tableset>
        <xsl:value-of select="concat($usesp,$usestep)"/>
        <schema>
          <xsl:value-of select="concat($usesp,$usestep,$usestep)"/>
          <name>c</name>
          <xsl:value-of select="concat($usesp,$usestep,$usestep)"/>
          <description>
             <xsl:value-of select="$description"/>
             <xsl:value-of select="concat($usesp,$usestep,$usestep)"/>
          </description>
          <xsl:apply-templates select="../table" mode="newtables">
            <xsl:with-param name="sp" select="concat($usesp,$usestep,$usestep)"/>
            <xsl:with-param name="step" select="$step"/>
          </xsl:apply-templates>
          <xsl:value-of select="concat($usesp,$usestep)"/>
        </schema>
        <xsl:value-of select="$usesp"/>
      </tableset>
   </xsl:template>
   <xsl:template match="table" priority="-1"/>

   <xsl:template match="table" mode="newtables">
      <xsl:param name="sp"/>
      <xsl:param name="step"/>

      <xsl:variable name="myoldsp" 
                    select="preceding-sibling::text()[position()=last()]"/>
      <xsl:variable name="childsp" select="text()[1]"/>
      <xsl:variable name="usestep">
         <xsl:choose>
            <xsl:when test="$prettyPrint">
               <xsl:value-of select="$step"/>
            </xsl:when>
            <xsl:when 
                 test="string-length(substring-after($childsp,$myoldsp)) &gt; 0">
               <xsl:value-of select="substring-after($childsp,$myoldsp)"/>
            </xsl:when>
            <xsl:otherwise>
               <xsl:value-of select="$indent"/>
            </xsl:otherwise>
         </xsl:choose>
      </xsl:variable>

      <xsl:value-of select="$sp"/>

      <xsl:element name="table">
        <xsl:choose>
          <xsl:when test="@role='out' or 
                          (@role!='base_table' and @role!='view' and 
                           ../capability[@standardID=$SIAstdID or 
                                         @standardID=$SSAstdID or 
                                         @standardID=$SCSstdID or 
                                         @standardID=$SLAstdID])">
             <xsl:attribute name="type">output</xsl:attribute>
          </xsl:when>
          <xsl:when test="@role='base_table' or @role='view'">
             <xsl:attribute name="type">
                <xsl:value-of select="@role"/>
             </xsl:attribute>
          </xsl:when>
        </xsl:choose>

        <xsl:apply-templates select="*" mode="vor">
           <xsl:with-param name="sp" select="concat($sp,$usestep)"/>
           <xsl:with-param name="step" select="$usestep"/>
        </xsl:apply-templates>

        <xsl:value-of select="$sp"/>
      </xsl:element>

   </xsl:template>

   <!--
     -  table description (tweak the spacing)
     -->
   <xsl:template match="table/description" mode="vor">
      <xsl:param name="sp"/>
      <xsl:param name="step"/>

      <xsl:value-of select="$sp"/>
      <description>
         <xsl:apply-templates select="text()"  mode="vor"/>
         <xsl:if test="contains(.,$cr)">
            <xsl:value-of select="$sp"/>
         </xsl:if>
      </description>
   </xsl:template>

   <!--
     -  table column description
     -->
   <xsl:template match="column" mode="vor">
      <xsl:param name="sp"/>
      <xsl:param name="step"/>

      <xsl:value-of select="$sp"/>
      <column>
        <xsl:copy-of select="@std"/>

        <xsl:apply-templates select="*" mode="vor">
          <xsl:with-param name="sp" select="concat($sp,$step)"/>
          <xsl:with-param name="step" select="$step"/>
        </xsl:apply-templates>

        <xsl:value-of select="$sp"/>
      </column>
   </xsl:template>

   <xsl:template match="*[@xsi:type]" priority="1" mode="vor">
      <xsl:param name="sp"/>
      <xsl:param name="step"/>
      <xsl:param name="pfx" select="'#'"/>

      <xsl:variable name="newp">
         <xsl:call-template name="newprefixes">
            <xsl:with-param name="pfx" select="$pfx"/>
         </xsl:call-template>
      </xsl:variable>

      <xsl:variable name="prefix" select="substring-before(@xsi:type,':')"/>
      <xsl:variable name="fp">
         <xsl:value-of select="$pfx"/>
         <xsl:if test="not(contains($pfx,concat('#',$prefix,'#')))">
            <xsl:value-of select="$prefix"/><xsl:text>#</xsl:text>
         </xsl:if>
      </xsl:variable>

      <xsl:value-of select="$sp"/>
      <xsl:element name="{local-name()}">
         <xsl:for-each select="@*">
            <xsl:copy/>
         </xsl:for-each>
         <xsl:if test="not(contains($pfx,concat('#',$prefix,'#')))">
            <xsl:namespace name="{$prefix}" 
                           select="namespace-uri-for-prefix($prefix,.)"/>
         </xsl:if>

         <xsl:apply-templates select="*|text()" mode="vor">
            <xsl:with-param name="sp" select="concat($sp,$step)"/>
            <xsl:with-param name="step" select="$step"/>
            <xsl:with-param name="pfx" select="$fp"/>
         </xsl:apply-templates>

         <xsl:if test="*">
            <xsl:value-of select="$sp"/>
         </xsl:if>
      </xsl:element>
      
   </xsl:template>

   <!--
     -  TAP capability: when we don't invoke an extension schema via 
     -  xsi:type, fill in some defaults
     -->
   <xsl:template match="capability[@standardID=$TAPstdID and not(@xsi:type)]"
                 mode="vor" priority="2">
      <xsl:param name="sp"/>
      <xsl:param name="step"/>
      <xsl:param name="pfx" select="'#'"/>

      <xsl:variable name="newpfx">
         <xsl:value-of select="pfx"/>
         <xsl:if test="not(contains($pfx,'#tap#'))">tap#</xsl:if>
      </xsl:variable>

      <xsl:variable name="subsp">
         <xsl:choose>
            <xsl:when test="$prettyPrint">
               <xsl:value-of select="concat($sp,$step)"/>
            </xsl:when>
            <xsl:when test="text()">
               <xsl:value-of select="text()[1]"/>
            </xsl:when>
            <xsl:otherwise>
               <xsl:value-of 
                    select="preceding-sibling::text()[position()=last()]"/>
               <xsl:value-of select="$indent"/>
            </xsl:otherwise>
         </xsl:choose>
      </xsl:variable>

      <xsl:variable name="substep">
         <xsl:choose>
            <xsl:when test="$prettyPrint">
               <xsl:value-of select="$step"/>
            </xsl:when>
            <xsl:when 
                 test="string-length(substring-after($subsp,$subsp)) &gt; 0">
               <xsl:value-of select="substring-after($subsp,$subsp)"/>
            </xsl:when>
            <xsl:otherwise>
               <xsl:value-of select="$indent"/>
            </xsl:otherwise>
         </xsl:choose>
      </xsl:variable>

      <xsl:variable name="subsubsp">
         <xsl:value-of select="concat($subsp,$substep)"/>
      </xsl:variable>

      <xsl:value-of select="$sp"/>
      <xsl:element name="capability">
         <xsl:for-each select="@*">
            <xsl:copy/>
         </xsl:for-each>
         <xsl:if test="not(contains($pfx,'#tap#'))">
            <xsl:namespace name="tap" select="$tap10"/>
         </xsl:if>
         <xsl:attribute name="xsi:type">tap:TableAccess</xsl:attribute>

         <xsl:apply-templates mode="vor"
              select="*|text()[following-sibling::element()]" >
               <xsl:with-param name="sp" select="concat($sp,$step)"/>
               <xsl:with-param name="step" select="$step"/>
               <xsl:with-param name="pfx" select="$newpfx"/>
         </xsl:apply-templates>

         <xsl:value-of select="$subsp"/>

         <language>
            <xsl:value-of select="$subsubsp"/>
            <name>ADQL</name>
            <xsl:value-of select="$subsubsp"/>
            <version ivo-id="ivo://ivoa.net/std/ADQL#v2.0">2.0</version>
            <xsl:value-of select="$subsubsp"/>
            <description>Astronomical Data Query Language v2.0</description>
            <xsl:value-of select="$subsp"/>
         </language>
         <xsl:value-of select="text()[position()=last()]"/>
      </xsl:element>
   </xsl:template>

   <!--
     -  Copy non-VOResource elements unchanged by default
     -->
   <xsl:template match="*" priority="-2">
      <xsl:param name="sp"/>
      <xsl:param name="step"/>
      <xsl:param name="pfx" select="'#'"/>

      <xsl:apply-templates select="." mode="nonvor">
         <xsl:with-param name="sp" select="$sp"/>
         <xsl:with-param name="step" select="$step"/>
         <xsl:with-param name="pfx" select="$pfx"/>
      </xsl:apply-templates>
   </xsl:template>
   <xsl:template match="*" priority="-2" mode="nonvor">
      <xsl:param name="sp"/>
      <xsl:param name="step"/>
      <xsl:param name="pfx" select="'#'"/>

      <xsl:variable name="newp">
         <xsl:call-template name="newprefixes">
            <xsl:with-param name="pfx" select="$pfx"/>
         </xsl:call-template>
      </xsl:variable>
      <xsl:variable name="fp" select="concat($pfx,substring($newp,1))"/>

      <xsl:value-of select="$sp"/>

      <xsl:copy>
         <xsl:for-each select="@*">
            <xsl:copy/>
         </xsl:for-each>

         <xsl:apply-templates select="child::node()">
            <xsl:with-param name="sp" select="concat($sp,$step)"/>
            <xsl:with-param name="step" select="$step"/>
            <xsl:with-param name="pfx" select="$fp"/>
         </xsl:apply-templates>

         <xsl:if test="$prettyPrint and contains(text()[1],$cr)">
           <xsl:value-of select="$sp"/>
         </xsl:if>
      </xsl:copy>

   </xsl:template>

   <!--
     -  Copy VOResource elements unchanged by default.  The difference is
     -  that we control namespace nodes explicitly by using the 
     -  <xsl:element> directive rather than <xsl:copy>
     -->
   <xsl:template match="*" priority="-2" mode="vor">
      <xsl:param name="sp"/>
      <xsl:param name="step"/>
      <xsl:param name="pfx" select="'#'"/>

      <xsl:variable name="newp">
         <xsl:call-template name="newprefixes">
            <xsl:with-param name="pfx" select="$pfx"/>
         </xsl:call-template>
      </xsl:variable>
      <xsl:variable name="fp" select="concat($pfx,substring($newp,1))"/>

      <xsl:value-of select="$sp"/>

      <xsl:element name="{local-name()}">
         <xsl:for-each select="@*">
            <xsl:copy/>
         </xsl:for-each>

         <xsl:apply-templates select="child::node()" mode="vor">
            <xsl:with-param name="sp" select="concat($sp,$step)"/>
            <xsl:with-param name="step" select="$step"/>
            <xsl:with-param name="pfx" select="$pfx"/>
         </xsl:apply-templates>

         <xsl:if test="$prettyPrint and contains(text()[1],$cr)">
           <xsl:value-of select="$sp"/>
         </xsl:if>
      </xsl:element>

   </xsl:template>

   <xsl:template match="@*" priority="-1">
      <xsl:copy/>
   </xsl:template>

   <xsl:template match="@*" mode="VOResourceRoot">
      <xsl:copy/>
   </xsl:template>

   <xsl:template match="@*" mode="vor">
      <xsl:copy/>
   </xsl:template>

   <!--
     -  template for handling ignorable whitespace
     -->
   <xsl:template match="text()" priority="-1">
      <xsl:variable name="trimmed" select="normalize-space(.)"/>
      <xsl:if test="not($prettyPrint) or string-length($trimmed) &gt; 0">
         <xsl:copy/>
      </xsl:if>
   </xsl:template>

   <!--
     -  template for handling ignorable whitespace
     -->
   <xsl:template match="text()" priority="-1" mode="vor">
      <xsl:variable name="trimmed" select="normalize-space(.)"/>
      <xsl:if test="not($prettyPrint) or string-length($trimmed) &gt; 0">
         <xsl:copy/>
      </xsl:if>
   </xsl:template>

<!-- for debugging:  uncomment this template to override the default
  -  handling of ignorable whitespace
   <xsl:template match="text()" priority="-0.8" mode="vor">
      <xsl:variable name="trimmed" select="normalize-space(.)"/>
      <xsl:if test="not($prettyPrint) or string-length($trimmed) &gt; 0">
         <xsl:text>[</xsl:text>
         <xsl:copy/>
         <xsl:text>]</xsl:text>
      </xsl:if>
   </xsl:template>
  -->

   <!--
     -  template for handling ignorable whitespace.  This version will
     -    shave off all but the last carriage return
     -->
   <xsl:template match="text()" priority="-1" mode="trim">
      <xsl:if test="not($prettyPrint)">
         <xsl:choose>
            <xsl:when test="contains(.,$cr)">
               <xsl:value-of select="$cr"/>
               <xsl:call-template name="afterLastCR">
                  <xsl:with-param name="text" select="."/>
               </xsl:call-template>
            </xsl:when>
            <xsl:otherwise>
               <xsl:copy/>
            </xsl:otherwise>
         </xsl:choose>
      </xsl:if>
   </xsl:template>

   <!-- ==========================================================
     -  Utility templates
     -  ========================================================== -->

   <xsl:template name="newprefixes">
      <xsl:param name="pfx" select="'#'"/>
      <xsl:param name="inscope">
         <xsl:value-of select="in-scope-prefixes(.)"/>
      </xsl:param>
      <xsl:param name="npfx" select="'#'"/>

      <xsl:variable name="firstpref">
         <xsl:choose>
            <xsl:when test="contains($inscope,' ')">
              <xsl:value-of select="substring-before($inscope,' ')"/>
            </xsl:when>
            <xsl:when test="string-length($inscope) &gt; 0">
              <xsl:value-of select="$inscope"/>
            </xsl:when>
         </xsl:choose>
      </xsl:variable>
      <xsl:variable name="restpref">
         <xsl:if test="contains($inscope,' ')">
           <xsl:value-of select="substring-after($inscope,' ')"/>
         </xsl:if>
      </xsl:variable>

      <xsl:choose>
         <xsl:when test="string-length($firstpref)=0">
            <xsl:value-of select="$npfx"/>
         </xsl:when>
         <xsl:when test="not(contains($pfx,concat('#',$firstpref,'#'))) and
                         not(contains($npfx,concat('#',$firstpref,'#')))">
            <xsl:call-template name="newprefixes">
               <xsl:with-param name="pfx" select="$pfx"/>
               <xsl:with-param name="npfx" 
                               select="concat($npfx,$firstpref,'#')"/>
               <xsl:with-param name="inscope" select="$restpref"/>
            </xsl:call-template>
         </xsl:when>
         <xsl:otherwise>
            <xsl:call-template name="newprefixes">
               <xsl:with-param name="pfx" select="$pfx"/>
               <xsl:with-param name="npfx" select="$npfx"/>
               <xsl:with-param name="inscope" select="$restpref"/>
            </xsl:call-template>
         </xsl:otherwise>
      </xsl:choose>
   </xsl:template>

   <!--
     -  convert the first character to a lower case
     -  @param in  the string to convert
     -->
   <xsl:template name="uncapitalize">
      <xsl:param name="in"/>
      <xsl:value-of select="translate(substring($in,1,1),
                                      'ABCDEFGHIJKLMNOPQRSTUVWXYZ',
                                      'abcdefghijklmnopqrstuvwxyz')"/>
      <xsl:value-of select="substring($in,2)"/>
   </xsl:template>

   <!--
     -  determine the indentation preceding the context element
     -->
   <xsl:template name="getindent">
      <xsl:variable name="prevsp">
         <xsl:for-each select="preceding-sibling::text()">
            <xsl:if test="position()=last()">
               <xsl:value-of select="."/>
            </xsl:if>
         </xsl:for-each>
      </xsl:variable>

      <xsl:choose>
         <xsl:when test="contains($prevsp,$cr)">
            <xsl:call-template name="afterLastCR">
               <xsl:with-param name="text" select="$prevsp"/>
            </xsl:call-template>
         </xsl:when>
         <xsl:when test="$prevsp">
            <xsl:value-of select="$prevsp"/>
         </xsl:when>
         <xsl:otherwise><xsl:text>    </xsl:text></xsl:otherwise>
      </xsl:choose>
   </xsl:template>

   <!--
     -  return the text that appears after the last carriage return
     -  in the input text
     -  @param text  the input text to process
     -->
   <xsl:template name="afterLastCR">
      <xsl:param name="text"/>
      <xsl:choose>
         <xsl:when test="contains($text,$cr)">
            <xsl:call-template name="afterLastCR">
               <xsl:with-param name="text" select="substring-after($text,$cr)"/>
            </xsl:call-template>
         </xsl:when>
         <xsl:otherwise><xsl:value-of select="$text"/></xsl:otherwise>
      </xsl:choose>
   </xsl:template>

   <!--
     -  indent the given number of levels.  The amount of indentation will 
     -  be nlev times the value of the global $indent.
     -  @param nlev   the number of indentations to insert.
     -  @param sp     the string representing the per-indentation space;
     -                  defaults to the value of $indent
     -->
   <xsl:template name="doindent">
      <xsl:param name="nlev" select="2"/>
      <xsl:param name="sp" select="$indent"/>

      <xsl:if test="$nlev &gt; 0">
         <xsl:value-of select="$sp"/>
         <xsl:if test="$nlev &gt; 1">
            <xsl:call-template name="doindent">
               <xsl:with-param name="nlev" select="$nlev - 1"/>
               <xsl:with-param name="sp" select="$sp"/>
            </xsl:call-template>
         </xsl:if>
      </xsl:if>
   </xsl:template>

   <!--
     -  convert all input characters to lower case
     -  @param in  the string to convert
     -->
   <xsl:template name="lower">
      <xsl:param name="in"/>
      <xsl:value-of select="translate($in,
                                      'ABCDEFGHIJKLMNOPQRSTUVWXYZ',
                                      'abcdefghijklmnopqrstuvwxyz')"/>
   </xsl:template>

   <!--
     -  convert the first character to an upper case
     -  @param in  the string to convert
     -->
   <xsl:template name="capitalize">
      <xsl:param name="in"/>
      <xsl:value-of select="translate(substring($in,1,1),
                                      'abcdefghijklmnopqrstuvwxyz',
                                      'ABCDEFGHIJKLMNOPQRSTUVWXYZ')"/>
      <xsl:value-of select="substring($in,2)"/>
   </xsl:template>

   <!--
     -  convert all input characters to lower case and then capitalize
     -  @param in  the string to convert
     -->
   <xsl:template name="lowerandcap">
      <xsl:param name="in"/>
      <xsl:call-template name="capitalize">
         <xsl:with-param name="in">
            <xsl:call-template name="lower">
               <xsl:with-param name="in" select="$in"/>
            </xsl:call-template>
         </xsl:with-param>
      </xsl:call-template>
   </xsl:template>

   <!--
     -  measure the indentation inside a node
     -  @param text   a text node containing the indentation
     -->
   <xsl:template name="measIndent">
      <xsl:param name="text"/>

      <xsl:variable name="indnt">
         <xsl:call-template name="afterLastCR">
            <xsl:with-param name="text" select="$text"/>
         </xsl:call-template>
      </xsl:variable>

      <xsl:value-of select="string-length($indnt)"/>
   </xsl:template>

   <!--
     -  attempt to return the extra indentation applied to children 
     -    of the current context node.  If a positive indentation cannot
     -    be returned, return the default indentation.
     -->
   <xsl:template match="*" mode="getIndentStep">
      <xsl:variable name="prevind">
         <xsl:call-template name="measIndent">
            <xsl:with-param name="text">
               <xsl:call-template name="getindent"/>
            </xsl:with-param>
         </xsl:call-template>
      </xsl:variable>
      <xsl:variable name="childind">
         <xsl:call-template name="measIndent">
            <xsl:with-param name="text">
               <xsl:for-each select="*[1]">
                  <xsl:call-template name="getindent"/>
               </xsl:for-each>
            </xsl:with-param>
         </xsl:call-template>
      </xsl:variable>
      <xsl:variable name="diff" select="$childind - $prevind"/>

      <xsl:choose>
         <xsl:when test="number($childind) &gt; number($prevind) and 
                         number($prevind) &gt; 0">
            <xsl:call-template name="doindent">
               <xsl:with-param name="nlev" select="$diff"/>
               <xsl:with-param name="sp" select="' '"/>
            </xsl:call-template>
         </xsl:when>
         <xsl:otherwise><xsl:value-of select="$indent"/></xsl:otherwise>
      </xsl:choose>
   </xsl:template>


</xsl:stylesheet>
