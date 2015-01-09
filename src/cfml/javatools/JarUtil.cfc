/* Document Information -----------------------------------------------------
Title:      JarUtil.cfc
Author:     Denny Valliant
Email:      valliantster@gmail.com
Website:    http://coldshen.com
Purpose:    Jars up directories
Usage:      createJarFile(sources,destJarFile,jarEntryPrefix)
Modification Log:
Name			Date			Description
================================================================================
Denny Valliant		03/07/2008		Created
----------------------------------------------------------------------------*/
component name="JarUtil" hint="Component for createing jar files" {
	instance = StructNew();

public JarUtil function init() hint="Constructor" {
		return this;
}

public function createJarFile(srcPath ,destFile ="#arguments.srcPath#/wee.jar ",jarPrefix =" ")  {
		var src = createObject("java", "java.io.File").init(arguments.srcPath);
		var prefix = arguments.jarPrefix;
//		var out = CreateObject("java","java.io.ByteArrayOutputStream").init();
		var destF = CreateObject("java","java.io.File").init(arguments.destFile);
//		var wee = dumpvar(destFile & destF.exists());
	  	var out = CreateObject("java","java.io.FileOutputStream").init(destF);
	  	var manifest = createObject("java","java.util.jar.Manifest").init();
 		//manifest.getMainAttributes().put(Attributes.Name.MANIFEST_VERSION, "1.0");

	    var jout = createObject("java","java.util.jar.JarOutputStream").init(out, manifest);
	    for(var dir in directorylist(srcPath)) {
	    	var fdir = createObject("java", "java.io.File").init(dir);
			jar(jout,fdir, prefix);
	    }
		jout.close();
		out.close();
/*
	<cffile action="write" file="#arguments.destFile#" output="#out.toString()#" />
*/
}

private function jar(jaroutstream ,srcPath ,inbuffer =" ",jarprefix =" ") hint="recursive adding action" {
		var prefix = arguments.jarPrefix;
    	var jout = arguments.jaroutstream;
		var byteClass = createObject("java", "java.lang.Byte");
		var buffer = createObject("java","java.lang.reflect.Array").newInstance(byteClass["TYPE"],1024);
		var src = arguments.srcPath;
		var entry = "";
		var len = "";
		var files = "";
		var i = 0;
		var infile = "";
        if (src.isDirectory())
        {
           // create / init the zip entry
           prefix = prefix & src.getName() & "/";
           entry = createObject("java","java.util.zip.ZipEntry").init(prefix);
           entry.setTime(src.lastModified());
           entry.setMethod(jout.STORED);
           entry.setSize(0);
           entry.setCrc(0);
           jout.putNextEntry(entry);
           jout.closeEntry();

           // process the sub-directories
           files = src.listFiles();
           for (i = 1; i lte arrayLen(files); i = i + 1)
           {
              jar(arguments.jaroutstream,files[i], buffer, prefix);
           }
        }
        else if (src.isFile())
        {
           prefix = trim(prefix & src.getName());
           entry = createObject("java","java.util.zip.ZipEntry").init(prefix);
           entry.setTime(src.lastModified());
           jout.putNextEntry(entry);

           infile = CreateObject("java","java.io.FileInputStream").init(src);

           len = infile.read(buffer, 0, len(buffer));
           while (len neq -1) {
             jout.write(buffer, 0, len);
             len = infile.read(buffer, 0, len(buffer));
           }
           infile.close();
           jout.closeEntry();
        }
}


}