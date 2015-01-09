component extends="mxunit.framework.TestCase" {

	function testCompileHelloWorld() {
		var compiler = new cfml.javatools.Compiler();
		var thisDir = getDirectoryFromPath(getMetadata(this).path);
		var src = thisDir & "/data/hello";
		var bin = thisDir & "/work/hello";
		if (directoryExists(bin))
			directoryDelete(bin,true);
		compiler.compile(src,bin);
		assertTrue(fileExists(bin & "/HelloWorld.class"));
	}

	function testCompileAndJarHelloWorld() {
		var compiler = new cfml.javatools.Compiler();
		var thisDir = getDirectoryFromPath(getMetadata(this).path);
		var src = thisDir & "/data/hello";
		var bin = thisDir & "/work/hello";
		var jar = thisDir & "/work/hello/helloworld.jar";
		var content = "";
		if (directoryExists(bin))
			directoryDelete(bin,true);
		compiler.compileAndJar(src, jar, bin);
		zip action="list" file=jar name="content";
		assertEquals("META-INF/MANIFEST.MF",content.name[1]);
		assertEquals("META-INF",content.directory[1]);
		assertEquals("HelloWorld.class",content.name[2]);
		assertEquals("",content.directory[2]);
		compiler.compileAndJar(src, jar);
		assertEquals("META-INF/MANIFEST.MF",content.name[1]);
		assertEquals("META-INF",content.directory[1]);
		assertEquals("HelloWorld.class",content.name[2]);
		assertEquals("",content.directory[2]);
	}
}