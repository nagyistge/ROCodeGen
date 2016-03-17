﻿import Sugar
import Sugar.IO
import RemObjects.SDK.CodeGen4

func writeSyntax() {
	writeLn("Syntax:")
	writeLn()
	writeLn("  CodeGen4 <file.rodl> --type:<type> --platform:<platform> --language:<language> --namespace:<namespace>")
	writeLn("  CodeGen4 <file.rodl> --service:<name> --platform:<platform> --language:<language> --namespace:<namespace>")
	writeLn("  CodeGen4 <file.rodl> --services --platform:<platform> --language:<language> --namespace:<namespace>")
	writeLn()
	writeLn("Valid <type> values:")
	writeLn()
	writeLn("  - intf")
	writeLn("  - invk (not supported yet)")
	writeLn("  - impl (not supported yet")
	writeLn("  - events")
	writeLn()
	writeLn("Valid <platform> values:")
	writeLn()
	#if ECHOES
	writeLn("  - .net, net, echoes")
	#endif
	writeLn("  - cocoa, xcode, nougat")
	writeLn("  - java, cooper")
	writeLn("  - delphi, c++builder, bcb")
	writeLn("  - javascript, js (not supported yet)")
	writeLn()
	writeLn("Valid <language> values:")
	writeLn()
	writeLn("  - oxygene, pas")
	writeLn("  - hydrogene, c#, cs")
	writeLn("  - silver")
	writeLn("  - swift (Apple Swift)")
	writeLn("  - objective-c, Objc")
	writeLn("  - delphi, pas, c++builder, cpp, c++")
	writeLn("  - java)")
	writeLn()
	
	#hint add --await
}

let options = [String:String]()

func parseParameters(cmdlineParams: [String]) {
	for s in cmdlineParams {
		var param: Sugar.String = s
		if param.StartsWith("--") {
			param = param.Substring(2)
			var p = param.IndexOf(":")
			if p > 0 {
				var name = param.Substring(0, p)
				var value = param.Substring(p+1)
				options[name.ToLower()] = value // retest 72610: Nougat: Sugar mapping fails at runtime, trying to call the mapped method
				//(options as! NSMutableDictionary)[name] = value.ToLower() // Parameter 1 is "String", should be "TValue", in call to NSMutableDictionary<TKey,TValue>!.setObject(anObject: TValue, forKeyedSubscript aKey: TKey)
																		  // Parameter 2 is "String!", should be "TKey", in call to NSMutableDictionary<TKey,TValue>!.setObject(anObject: TValue, forKeyedSubscript aKey: TKey)
			}
			else {
				options[param] = ""
			}
		} 
	}
}

writeLn("RemObjects SDK Service Interface Code Generator, based on CodeGen4 (https://github.com/remobjects/codegen4)")
writeLn()

let params = C_ARGV
parseParameters(params)

if params.count < 1 { //70956: Silver: problem with boolean short circuit
	writeSyntax()
	return 1
}
if params.count < 1 || !FileUtils.Exists(params[0]) {
	//writeLn("File \(params[0]) not found")
	writeLn()
	writeSyntax()
	return 1
}

if options["platform"] == nil {
	writeSyntax()
	return 1
}
if options["type"] == nil && options["service"] == nil && options["services"] == nil {
	writeSyntax()
	return 1
}
if options["platform"]?.ToLower() == "delphi" || options["language"] == nil {
	options["language"] = "delphi"
}  
if options["language"] == nil {
	writeSyntax()
	return 1
}

if options["namespace"] == nil {
	options["namespace"] = "YourNamespace"
}

let rodlFileName = params[0];
writeLn("Processing RODL file "+rodlFileName)
let rodlLibrary = RodlLibrary(rodlFileName) // todo:handle remoteRodl files

switch options["type"]?.ToLower() {
	case "intf": break
	case "invk": break
	case "events": break
	case "async": break
	case "impl": break
	default:
		writeSyntax()
		writeLn("Unsupported type: "+options["type"])
		return 2
}

var activeRodlCodeGen: RodlCodeGen?
switch options["platform"]?.ToLower() {
	case "cooper", "java":
		options["platform"] = "java"
		if options["language"] == "swift" {
			options["language"] = "silver" // force our Swift
		}
		activeRodlCodeGen = JavaRodlCodeGen()
	case "nougat", "cocoa", "xcode":
		options["platform"] = "cocoa"
		if options["language"]?.ToLower() == "swift" && options["platform"]?.ToLower() == "nougat" {
				options["language"] = "silver" // force our Swift
		}
		activeRodlCodeGen = CocoaRodlCodeGen()
	case "echoes", "net", ".net":
		options["platform"] = ".net"
		#if ECHOES
		activeRodlCodeGen = EchoesCodeDomRodlCodeGen()
		#else
		//activeRodlCodeGen = DotNetRodlCodeGen()
		writeLn(".NET codegen is not supported in the Mac version of rodl2code, sorry. Use 'mono rodl2code.exe', instead.")
		return 2
		#endif
	case "delphi":
		options["platform"] = "delphi"
		options["language"] = "delphi" // force language to Delphi
		activeRodlCodeGen = DelphiRodlCodeGen()
		return 2
	case "bcb", "c++builder":
		options["platform"] = "bcb"
		options["language"] = "bcb" // force language to C++(Builder)
		activeRodlCodeGen = CPlusPlusBuilderRodlCodeGen()
		return 2
	case "javascript", "js":
		options["platform"] = "javascript"
		//activeRodlCodeGen = JavaScriptRodlCodeGen()
		writeLn("javaScript RODL codegen is not supported in rodl2code yet, sorry.")
		return 2
	default:
}

var codegen: CGCodeGenerator?

var fileExtension = "txt"
switch options["language"]?.ToLower() {
	case "oxygene", "pas":
		options["language"] = "oxygene"
		codegen = CGOxygeneCodeGenerator()
		fileExtension = "pas"
	case "hydrogene", "csharp", "c#", "cs":
		options["language"] = "c#"
		codegen = CGCSharpCodeGenerator(dialect: CGCSharpCodeGeneratorDialect.Hydrogene)
		fileExtension = "cs"
	case "visual-c#", "visualcsharp", "vc#", "standard-csharp":
		options["language"] = "standard-c#"
		codegen = CGCSharpCodeGenerator(dialect: CGCSharpCodeGeneratorDialect.Standard)
		fileExtension = "cs"
	case "visual-basic", "visualbasic", "visualbasic.net", "vb", "vb.ndet":
		options["language"] = "vb"
		fileExtension = "vb"
	case "silver":
		options["language"] = "swift"
		codegen = CGSwiftCodeGenerator(dialect: CGSwiftCodeGeneratorDialect.Silver)
		fileExtension = "swift"
		if let cocoaRodlCodeGen = activeRodlCodeGen as? CocoaRodlCodeGen {
			cocoaRodlCodeGen.SwiftDialect = .Silver
		}
	case  "swift", "apple-swift", "standard-swift":
		options["language"] = "standard-swift"
		codegen = CGSwiftCodeGenerator(dialect: CGSwiftCodeGeneratorDialect.Standard)
		if let cocoaRodlCodeGen = activeRodlCodeGen as? CocoaRodlCodeGen {
			cocoaRodlCodeGen.SwiftDialect = .Standard
		}
		fileExtension = "swift"
	case "objc", "objectivec", "objective-c":
		options["language"] = "objc"
		codegen = CGObjectiveCMCodeGenerator()
		fileExtension = "m"
	case "delphi":
		options["language"] = "delphi"
		codegen = CGDelphiCodeGenerator()
		fileExtension = "pas"
	case "bcb", "cpp", "c++", "c++builder":
		options["language"] = "cpp"
		codegen = CGCPlusPlusCPPCodeGenerator(dialect: .CPlusPlusBuilder)
		fileExtension = "cpp"
	case "java":
		options["language"] = "java"
		codegen = CGJavaCodeGenerator()
		fileExtension = "java"
	case "javascript", "js":
		options["language"] = "javascript"
		codegen = CGJavaScriptCodeGenerator()
		writeLn("JavaScript language codegen is not supported in rodl2code yet, sorry.")
		fileExtension = "js"
		return 2
	default:
}

func targetFileNameWithSuffix(suffix: String) -> String {
	return Path.Combine(Path.GetParentDirectory(rodlFileName), Path.GetFileNameWithoutExtension(rodlFileName)+"_"+suffix+"."+fileExtension)
}

if activeRodlCodeGen == nil {
	writeLn("Unsupported platform: "+options["platform"])
	return 2
}
#if ECHOES
if let echoesRodlCodegen = activeRodlCodeGen as? EchoesCodeDomRodlCodeGen {
	echoesRodlCodegen.Language = options["language"]
	if echoesRodlCodegen.GetCodeDomProviderForLanguage() == nil {
		writeLn("No CodeDom provider is registered for language: "+options["language"])
		return 2
	}
}
else
#endif
if codegen == nil {
	writeSyntax()
	writeLn("Unsupported language: "+options["language"])
	return 2
}

if options["service"] != nil {
	if options["platform"] != ".NET" && options["platform"] != "delphi" {
		writeLn("Generating server code is not supported for this platform.")
		return 2
	}

	writeLn("Generating Service "+options["service"])
	// to geneate service
} else if options["services"] != nil {
	if options["platform"] != ".NET" && options["platform"] != "delphi" {
		writeLn("Generating server code is not supported for this platform")
		return 2
	}

	writeLn("Generating All Services")
	// to geneate all services
}
if let type = options["type"] {
	if options["platform"] != ".NET" && options["platform"] != "delphi" {
		if type.ToLower() != "intf" {
			writeLn("Generating server code is not supported for this platform")
			return 2
		}
	}
	writeLn("Generating "+options["type"])

	if let activeRodlCodeGen = activeRodlCodeGen {
		switch type.ToLower() {
			case "intf":		

				if let codegen = codegen {
					codegen.splitLinesLongerThan = 200
				}
				
				activeRodlCodeGen.Generator = codegen
				if codegen is CGJavaCodeGenerator {
					let sourceFiles = activeRodlCodeGen.GenerateInterfaceFiles(rodlLibrary, options["namespace"])
					for name in sourceFiles.Keys {
						var fileName = Path.Combine(Path.GetParentDirectory(rodlFileName), name)
						FileUtils.WriteText(fileName, sourceFiles[name]);
						writeLn("Wrote file \(fileName)")
					}  
				} else {
					let source = activeRodlCodeGen?.GenerateInterfaceFile(rodlLibrary, options["namespace"], targetFileNameWithSuffix("Intf"))
					FileUtils.WriteText(targetFileNameWithSuffix("Intf"), source);
					writeLn("Wrote file \(targetFileNameWithSuffix("Intf"))")

					if options["language"] == "objc" {
						activeRodlCodeGen?.Generator = CGObjectiveCHCodeGenerator()
						let sourceH = activeRodlCodeGen?.GenerateInterfaceFile(rodlLibrary, options["namespace"], targetFileNameWithSuffix("Intf"))
						fileExtension = "h";
						FileUtils.WriteText(targetFileNameWithSuffix("Intf"), sourceH);
						writeLn("Wrote file \(targetFileNameWithSuffix("Intf"))")
					} else if options["language"] == "cpp" {
						activeRodlCodeGen?.Generator = CGCPlusPlusHCodeGenerator(dialect: .CPlusPlusBuilder)
						let sourceH = activeRodlCodeGen?.GenerateInterfaceFile(rodlLibrary, options["namespace"], targetFileNameWithSuffix("Intf"))
						fileExtension = "h";
						FileUtils.WriteText(targetFileNameWithSuffix("Intf"), sourceH);
						writeLn("Wrote file \(targetFileNameWithSuffix("Intf"))")
					}
				}
			
			case "impl": fallthrough
			case "invk": fallthrough
			case "events":
				writeLn("Generating this type is not supported in rodl2code yet.")
			return 2
			default:
		}	// todo: generate services
	}
}