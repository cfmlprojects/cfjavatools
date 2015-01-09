<cfcomponent name="LibraryLoader" hint="Loads External Java Classes, while providing access to ColdFusion classes">

	<cfscript>
		instance = StructNew();
		instance.initialized = false;
		instance.useClassloader = true;  // try to load from classpath first
	</cfscript>

  <cffunction name="getClassloaderJars" output="false" returntype="any" access="public">
		<cfreturn getLoader().getClassloaderJars() />
	</cffunction>

	<cffunction name="getPaths" access="private" returntype="any">
	  <cfargument name="startpath" />
	  <cfargument name="patharray" type="array" />
	  <cfset var qpaths = arguments.patharray />
	  <cfset var retpaths = "" />
	  <cfset var qJars = "" />
	  <cfset var jarList = "" />
	  <cfset var libname = "" />
	  <cfset startpath = startpath.matches("[\\/]$") ? startpath : startpath &= "/" />
		<cfdirectory action="list" name="qJars" directory="#arguments.startpath#" filter="*.jar" sort="name desc"/>
		<cfloop query="qJars">
			<cfscript>
				libName = name;
				//let's not use the lib's that have the same name, but a lower datestamp
				if(NOT ListFind(jarList, libName))
				{
					ArrayAppend(qpaths, arguments.startpath  & name);
					jarList = ListAppend(jarList, libName);
				}
			</cfscript>
		</cfloop>
		<cfdirectory action="list" name="qProps" directory="#arguments.startpath#" filter="*.properties" sort="name desc"/>
		<cfloop query="qProps">
			<cfscript>
				var system = createObject("java","java.lang.System");
				var propfile = FileOpen(arguments.startpath &  name, "read");
				while(NOT FileisEOF(propfile))
				{
					var line = trim(FileReadLine(propfile));
					if(left(line,1) != '##' && len(line)) {
						System.setProperty(listFirst(line,"="),listLast(line,"="));
					}
				}
				FileClose(propfile);
			</cfscript>
		</cfloop>
	 	<cfdirectory action="list" name="retpaths" directory="#arguments.startpath#" sort="name desc"/>
	 	<cfloop query="retpaths">
		 	<cfif type eq "DIR" AND name NEQ ".svn">
				<cfdirectory action="list" name="qJars" directory="#arguments.startpath & "/" & name#" filter="*.jar" sort="name desc"/>
				<cfloop query="qJars">
					<cfscript>
						libName = name;
						//let's not use the lib's that have the same name, but a lower datestamp
						if(NOT ListFind(jarList, libName))
						{
							ArrayAppend(qpaths, arguments.startpath &  retpaths["name"][retpaths.currentrow] & "/" &name);
							jarList = ListAppend(jarList, libName);
						}
					</cfscript>
				</cfloop>
			</cfif>
		</cfloop>
		<cfreturn qpaths />
	</cffunction>

	<cffunction name="getLoader" hint="" access="public" returntype="any" output="false">
		<cfscript>
			return instance.javaloader;
		</cfscript>
	</cffunction>

	<cffunction name="init" hint="Constructor" access="public" returntype="any" output="false">
		<cfargument name="pathlist" required="true">
		<cfargument name="id" default="">
		<cfargument name="isolated" default="true">
		<cfargument name="force" default="false">
		<cfreturn getInstance(argumentCollection=arguments) />
	</cffunction>

	<cffunction name="getInstance" hint="Constructor" access="public" returntype="any" output="false">
		<cfargument name="pathlist" required="true">
		<cfargument name="id" default="">
		<cfargument name="isolated" default="true">
		<cfargument name="force" default="false">
		<cfset var key = id EQ "" ? hash(pathlist) : id />
		<cfif force OR NOT StructKeyExists(server, key) >
	    	<cflock name="javaloader.networkclassloader" throwontimeout="true" timeout="60">
	    	<cfscript>
	    		if(force OR NOT StructKeyExists(server, key)){
					server[key] = javacast("null","");
					instance = {useClassloader:true};
					var loadPaths = ArrayNew(1);
					var paths = arguments.pathlist;
					if(paths eq "") {
						paths = getDirectoryFromPath(getMetaData(this).path);
					}
					for(x = 1; x lte listLen(paths);x = x+1) {
						loadpaths = getPaths(listGetAt(paths,x),loadpaths);
					}
					//server[key] = createObject("component", "javaloader.JavaLoader").init(loadPaths=loadPaths,loadColdFusionClassPath=false,sourceDirectories=[getDirectoryFromPath(getMetaData(this).path)&"java/"]);
					instance.javaloader = createObject("component", "javaloader.JavaLoader").init(loadPaths=loadPaths,loadColdFusionClassPath=!isolated);
					instance.initialized = true;
					server[key] = this;
				}
			</cfscript>
    		</cflock>
		</cfif>
		<cfreturn server[key] />
	</cffunction>

	<cffunction name="create" access="public" returntype="any" output="false">
		<cfargument name="classnm" required="true">
		<cfset var retOb = "" />
		<cfif instance.useClassloader>
			<cfset retOb = getLoader().create(arguments.classnm) />
		<cfelse>
			<cftry>
				<cfset retOb = createObject("java",arguments.classnm) />
			<cfcatch>
				<cfif find("ClassNotFound", cfcatch.type) or find("NoClassDefFound", cfcatch.type) or find("can not load class",cfcatch.message)>
					<cfset instance.useClassloader = true>
					<cfset retOb = getLoader().create(arguments.classnm) />
				<cfelse>
					<cfrethrow>
				</cfif>
			</cfcatch>
			</cftry>
		</cfif>
		<cfreturn retOb />
	</cffunction>

</cfcomponent>
