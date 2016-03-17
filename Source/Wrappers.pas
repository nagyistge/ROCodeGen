﻿namespace RemObjects.SDK.CodeGen4;

interface

uses
  System.Runtime.InteropServices,
  RemObjects.CodeGen4,
  Sugar.*;

type
  [ComVisible(true)]
  Codegen4Platform = public enum (Cocoa, Delphi, Java, Net, CppBuilder);
  [ComVisible(true)]
  Codegen4Mode = public enum (Intf, Invk, Impl, &Async, All_Impl, _ServerAccess, All);
  [ComVisible(true)]
  Codegen4Language = public enum (Oxygene, CSharp, Standard_CSharp, VB, Silver, Standard_Swift, ObjC, Delphi, Java, CppBuilder);
  [ComVisible(true)]
  Codegen4FileType = public enum (&Unit, Header, Form);

  [ComVisible(true)]
  [Guid("F94EEEBC-9966-4B32-9C9C-763B22E31B24"),
        ClassInterface(ClassInterfaceType.AutoDual)]
  Codegen4Record = public class
  private
  public
    constructor (const aFileName, aContent: String;const aType: Codegen4FileType);
    property Filename: String; readonly;
    property Content: String; readonly;
    property &Type: Codegen4FileType; readonly;
  end;
{
  [ComVisible(true)]
  [Guid("F94EEEBC-9966-4B32-9C9C-763B22E31B23")]
  ICodegen4Records = public interface
    function Item(anIndex:Integer):Codegen4Record;
    function Count: Integer;
  end;}

  [ComVisible(true)]
  [Guid("F94EEEBC-9966-4B32-9C9C-763B22E31B22"),
        ClassInterface(ClassInterfaceType.AutoDual){,
        ComSourceInterfaces(typeOf(ICodegen4Records))}]
  Codegen4Records = public class//(ICodegen4Records)
  private
    fList: List<Codegen4Record> := new List<Codegen4Record>;
  assembly 
    method Add(anItem: Codegen4Record); 

  public
    function Item(anIndex:Integer):Codegen4Record;
    function Count: Integer;
    [ComVisible(False)]
    property Items: List<Codegen4Record> read fList;
  end;


  [ComVisible(true)]
  [Guid("F94EEEBC-9966-4B32-9C9C-763B22E31B21")]
  ICodegen4Wrapper = public interface
    method Generate(Platform: Codegen4Platform; Mode: Codegen4Mode; Generator:Codegen4Language; aRODLXML: String; AdditionalParameters: String): Codegen4Records;
  end;

  [ComVisible(true)]
  [Guid("F94EEEBC-9966-4B32-9C9C-763B22E31B20"),
        ClassInterface(ClassInterfaceType.AutoDual){,
        ComSourceInterfaces(typeOf(ICodegen4Wrapper))}]
  Codegen4Wrapper = public class //(ICodegen4Wrapper)
  public const 
    TargetNameSpace = 'Namespace';
    ServiceName = 'ServiceName';
    CustomAncestor = 'CustomAncestor';
    CustomUses = 'CustomUses';
    ServerAddress = 'ServerAddress';
    FullFramework = 'FullFramework';
    AsyncSupport = 'AsyncSupport';
  private
    method ParseAddParams(aParams: Dictionary<String,String>; aParamName:String):String;    
    method GenerateInterfaceFiles(Res: Codegen4Records; codegen :RodlCodeGen; rodl : RodlLibrary; &namespace: String; fileext: String);
    method GenerateAsyncFiles(Res: Codegen4Records; codegen :RodlCodeGen; rodl : RodlLibrary; &namespace: String; fileext: String);
    method GenerateInvokerFiles(Res: Codegen4Records; codegen :RodlCodeGen; rodl : RodlLibrary; &namespace: String; fileext: String);
    method GenerateImplFiles(Res: Codegen4Records; codegen :RodlCodeGen; rodl : RodlLibrary; &namespace: String; &params: Dictionary<String,String>; aServiceName: String := nil);
    method GenerateAllImplFiles(Res: Codegen4Records; codegen :RodlCodeGen; rodl : RodlLibrary; &namespace: String; &params: Dictionary<String,String>);
    method GenerateServerAccess(Res: Codegen4Records; codegen :RodlCodeGen; rodl : RodlLibrary; &namespace: String; fileext: String; &params: Dictionary<String,String>;&Platform: Codegen4Platform);
  protected
  public
    method Generate(&Platform: Codegen4Platform; Mode: Codegen4Mode; Language:Codegen4Language; aRODLXML: String; AdditionalParameters: String): Codegen4Records;
  end;

implementation

method Codegen4Wrapper.Generate(&Platform: Codegen4Platform; Mode: Codegen4Mode; Language:Codegen4Language; aRODLXML: String; AdditionalParameters: String): Codegen4Records;
begin
  if String.IsNullOrEmpty(AdditionalParameters) then AdditionalParameters := '';
  Result := new Codegen4Records;
  var rodl := new RodlLibrary;
  rodl.LoadFromXmlString(aRODLXML);

  var lparams := new Dictionary<String,String>();  
  for each p in AdditionalParameters.Split(';') do begin
    var l := p.Split(['='],2);
    if l.Count=2 then lparams[l[0]] := l[1];
  end;

  var llang := Language.ToString;
  var lfileext:= '';
  var codegen :RodlCodeGen; 
  case &Platform of
    Codegen4Platform.Delphi: codegen := new DelphiRodlCodeGen;
    Codegen4Platform.CppBuilder: codegen := new CPlusPlusBuilderRodlCodeGen;
    Codegen4Platform.Java: codegen := new JavaRodlCodeGen;
    Codegen4Platform.Cocoa: codegen := new CocoaRodlCodeGen;
    Codegen4Platform.Net: begin
      codegen := new EchoesCodeDomRodlCodeGen;
      EchoesCodeDomRodlCodeGen(codegen).AsyncSupport := ParseAddParams(lparams,AsyncSupport) <> '0';
      EchoesCodeDomRodlCodeGen(codegen).FullFramework:= ParseAddParams(lparams,FullFramework) <> '0';
    end;
   // Codegen4Platform.JavaScript: codegen := new JavaScriptRodlCodeGen;
  end;
  case Language of
    Codegen4Language.Oxygene: begin
      codegen.Generator := new CGOxygeneCodeGenerator();
      llang := 'oxygene';
      lfileext := 'pas';
    end;
    Codegen4Language.CSharp: begin
      codegen.Generator := new CGCSharpCodeGenerator(dialect:= CGCSharpCodeGeneratorDialect.Hydrogene);
      llang := 'c#';
      lfileext := 'cs';
    end;
    Codegen4Language.Standard_CSharp: begin
      codegen.Generator := new CGCSharpCodeGenerator(dialect:= CGCSharpCodeGeneratorDialect.Standard);
      llang := 'standard-c#';
      lfileext := 'cs';
    end;
    Codegen4Language.VB: begin
      llang := 'vb';
      lfileext := 'vb';
    end;
    Codegen4Language.Silver: begin
      codegen.Generator := new CGSwiftCodeGenerator(Dialect := CGSwiftCodeGeneratorDialect.Silver);
      llang := 'swift';
      lfileext := 'swift';
      if codegen is CocoaRodlCodeGen then 
        CocoaRodlCodeGen(codegen).SwiftDialect := CGSwiftCodeGeneratorDialect.Silver;
    end;
    Codegen4Language.Standard_Swift: begin
      codegen.Generator := new CGSwiftCodeGenerator(Dialect := CGSwiftCodeGeneratorDialect.Standard);
      llang := 'standard-swift';
      lfileext := 'swift';
      if codegen is CocoaRodlCodeGen then 
        CocoaRodlCodeGen(codegen).SwiftDialect := CGSwiftCodeGeneratorDialect.Standard;
    end;
    Codegen4Language.ObjC: begin
      codegen.Generator := new CGObjectiveCMCodeGenerator();
      llang := 'objc';
      lfileext := 'm';
    end;
    Codegen4Language.Delphi: begin
      codegen.Generator := new CGDelphiCodeGenerator(splitLinesLongerThan := 200);
      llang := 'delphi';
      lfileext := 'pas';
    end;
    Codegen4Language.Java: begin
      codegen.Generator := new CGJavaCodeGenerator();
      llang := 'java';
      lfileext := 'java';
    end;
    Codegen4Language.CppBuilder: begin
      codegen.Generator := new CGCPlusPlusCPPCodeGenerator(Dialect:=CGCPlusPlusCodeGeneratorDialect.CPlusPlusBuilder, splitLinesLongerThan := 200);
      llang := 'c++builder';
      lfileext := 'cpp';
    end;
  end;

  if codegen = nil then 
     raise new Exception("Unsupported platform: "+Language.ToString);

  if codegen is EchoesCodeDomRodlCodeGen then begin
    EchoesCodeDomRodlCodeGen(codegen).Language := llang;
    if EchoesCodeDomRodlCodeGen(codegen).GetCodeDomProviderForLanguage = nil then 
      raise new Exception("No CodeDom provider is registered for language: "+llang);
  end
  else if codegen.Generator = nil then 
    raise new Exception("Unsupported language: "+llang);

  if not (Platform in [Codegen4Platform.Delphi,Codegen4Platform.CppBuilder, Codegen4Platform.Net]) then 
    if Mode in [Codegen4Mode.Invk, Codegen4Mode.Impl,Codegen4Mode.All_Impl] then 
      raise new Exception("Generating server code is not supported for this platform.");

  var ltargetnamespace := ParseAddParams(lparams,TargetNameSpace);
  if String.IsNullOrEmpty(ltargetnamespace) then ltargetnamespace := rodl.Namespace;
  if String.IsNullOrEmpty(ltargetnamespace) then ltargetnamespace := rodl.Name;
  
  case Mode of
    Codegen4Mode.Intf: GenerateInterfaceFiles(result, codegen, rodl, ltargetnamespace, lfileext);
    Codegen4Mode.Invk: GenerateInvokerFiles(result, codegen, rodl, ltargetnamespace, lfileext);
    Codegen4Mode.Impl: GenerateImplFiles(result, codegen, rodl, ltargetnamespace, lparams, nil);
    Codegen4Mode.Async: GenerateAsyncFiles(result, codegen, rodl, ltargetnamespace, lfileext);
    Codegen4Mode.All_Impl: GenerateAllImplFiles(result, codegen, rodl, ltargetnamespace, lparams);
    Codegen4Mode._ServerAccess: GenerateServerAccess(result, codegen, rodl, ltargetnamespace, lfileext, lparams, &Platform);
    Codegen4Mode.All: begin
      GenerateInterfaceFiles(result, codegen, rodl, ltargetnamespace, lfileext);
      GenerateServerAccess(result, codegen, rodl, ltargetnamespace, lfileext, lparams, &Platform);
      if (Platform in [Codegen4Platform.Delphi,Codegen4Platform.CppBuilder, Codegen4Platform.Net]) then begin
        GenerateInvokerFiles(result, codegen, rodl, ltargetnamespace, lfileext);
        GenerateAllImplFiles(result, codegen, rodl, ltargetnamespace, lparams);
      end;
    end;
  end;  
end;

method Codegen4Wrapper.ParseAddParams(aParams: Dictionary<String,String>; aParamName: String): String;
begin
  exit iif(aParams.ContainsKey(aParamName),aParams[aParamName],'');
end;

method Codegen4Wrapper.GenerateInterfaceFiles(Res: Codegen4Records; codegen: RodlCodeGen; rodl: RodlLibrary; &namespace: String;fileext: String);
begin
  var lunitname := rodl.Name + '_Intf.'+fileext;
  if codegen.CodeUnitSupport then begin
    if (codegen is JavaRodlCodeGen) and (codegen.Generator is CGJavaCodeGenerator) then begin
      var r := codegen.GenerateInterfaceFiles(rodl,&namespace);
      for each l in r do
        Res.Add(new Codegen4Record(l.Key, l.Value, Codegen4FileType.Unit));
    end
    else begin
      var lunit := codegen.GenerateInterfaceCodeUnit(rodl,&namespace,lunitname);
      Res.Add(new Codegen4Record(lunitname, codegen.Generator.GenerateUnit(lunit), Codegen4FileType.Unit));
      
      if codegen.Generator is CGObjectiveCMCodeGenerator then begin
        var gen := new CGObjectiveCHCodeGenerator;
        gen.splitLinesLongerThan := codegen.Generator.splitLinesLongerThan;
        lunitname := Path.ChangeExtension(lunitname,gen.defaultFileExtension);
        Res.Add(new Codegen4Record(lunitname, gen.GenerateUnit(lunit), Codegen4FileType.Header));
      end;
      if codegen.Generator is CGCPlusPlusCPPCodeGenerator then begin
        var gen := new CGCPlusPlusHCodeGenerator(Dialect:=CGCPlusPlusCodeGenerator(codegen.Generator).Dialect, splitLinesLongerThan := codegen.Generator.splitLinesLongerThan);
        lunitname := Path.ChangeExtension(lunitname,gen.defaultFileExtension);
        Res.Add(new Codegen4Record(lunitname, gen.GenerateUnit(lunit), Codegen4FileType.Header));
      end;
    end;
  end
  else begin
    // external codegens aren't support Generate*CodeUnit
    Res.Add(new Codegen4Record(lunitname, codegen.GenerateInterfaceFile(rodl,&namespace,lunitname), Codegen4FileType.Unit));
  end;
end;

method Codegen4Wrapper.GenerateInvokerFiles(Res: Codegen4Records; codegen: RodlCodeGen; rodl: RodlLibrary; &namespace: String; fileext: String);
begin
  var lunitname := rodl.Name + '_Invk.'+fileext;
  if codegen.CodeUnitSupport then begin
    var lunit := codegen.GenerateInvokerCodeUnit(rodl,&namespace,lunitname);
    Res.Add(new Codegen4Record(lunitname, codegen.Generator.GenerateUnit(lunit), Codegen4FileType.Unit));
    if codegen.Generator is CGCPlusPlusCPPCodeGenerator then begin
      var gen := new CGCPlusPlusHCodeGenerator(Dialect:=CGCPlusPlusCodeGenerator(codegen.Generator).Dialect, splitLinesLongerThan := codegen.Generator.splitLinesLongerThan);
      lunitname := Path.ChangeExtension(lunitname,gen.defaultFileExtension);
      Res.Add(new Codegen4Record(lunitname, gen.GenerateUnit(lunit), Codegen4FileType.Header));
    end;
  end
  else begin    
    Res.Add(new Codegen4Record(lunitname, codegen.GenerateInvokerFile(rodl,&namespace,lunitname), Codegen4FileType.Unit));
  end;
end;

method Codegen4Wrapper.GenerateImplFiles(Res: Codegen4Records; codegen: RodlCodeGen; rodl: RodlLibrary; &namespace: String;  &params: Dictionary<String,String>;aServiceName: String);
begin
  var lServiceName := aServiceName;
  if codegen.CodeUnitSupport then begin
    // "pure" codegens require ServiceName
    if String.IsNullOrEmpty(lServiceName) then begin
      lServiceName := ParseAddParams(&params,ServiceName);
      if String.IsNullOrEmpty(lServiceName) then raise new Exception(String.Format('{0} parameter should be specified',[ServiceName]));
    end;
    if codegen is DelphiRodlCodeGen then begin
      DelphiRodlCodeGen(codegen).CustomAncestor := ParseAddParams(&params,CustomAncestor);
      DelphiRodlCodeGen(codegen).CustomUses := ParseAddParams(&params,CustomUses);
    end;

    var lunit := codegen.GenerateImplementationCodeUnit(rodl,&namespace,lServiceName);
    var r := codegen.GenerateImplementationFiles(lunit, rodl, lServiceName);
    Res.Add(new Codegen4Record(r.ElementAt(0).Key, r.ElementAt(0).Value, Codegen4FileType.Unit));
    if r.Count>1 then 
      Res.Add(new Codegen4Record(r.ElementAt(1).Key, r.ElementAt(1).Value, Codegen4FileType.Form));
    if codegen.Generator is CGCPlusPlusCPPCodeGenerator then begin
      var gen := new CGCPlusPlusHCodeGenerator(Dialect:=CGCPlusPlusCodeGenerator(codegen.Generator).Dialect, splitLinesLongerThan := codegen.Generator.splitLinesLongerThan);        
      var lunitname := Path.ChangeExtension(r.ElementAt(0).Key,gen.defaultFileExtension);
      Res.Add(new Codegen4Record(lunitname, gen.GenerateUnit(lunit), Codegen4FileType.Header));
    end;
  end
  else begin    
    //.NET based codegen doesn't use ServiceName
    var r := codegen.GenerateImplementationFiles(rodl,&namespace,lServiceName);
    Res.Add(new Codegen4Record(r.ElementAt(0).Key, r.ElementAt(0).Value, Codegen4FileType.Unit));
    if r.Count>1 then 
      Res.Add(new Codegen4Record(r.ElementAt(1).Key, r.ElementAt(1).Value, Codegen4FileType.Form));
  end;
end;

method Codegen4Wrapper.GenerateAllImplFiles(Res: Codegen4Records; codegen: RodlCodeGen; rodl: RodlLibrary; &namespace: String; &params: Dictionary<String,String>);
begin
  if codegen is EchoesCodeDomRodlCodeGen then begin
    GenerateImplFiles(Res, codegen,rodl,&namespace, &params, ServiceName); //EchoesCodeDomRodlCodeGen generates all services in one file
  end
  else begin  
    for serv in rodl.Services.Items do begin
      if serv.DontCodegen or serv.IsFromUsedRodl then continue;
      GenerateImplFiles(Res, codegen,rodl,&namespace, &params, serv.Name);
    end;
  end;  
end;

method Codegen4Wrapper.GenerateServerAccess(Res: Codegen4Records; codegen :RodlCodeGen; rodl : RodlLibrary; &namespace: String; fileext: String; &params: Dictionary<String,String>;&Platform: Codegen4Platform);
begin
  var sa : ServerAccessCodeGen;
  case &Platform of
    Codegen4Platform.Delphi: sa := new DelphiServerAccessCodeGen withrodl(rodl);
    Codegen4Platform.CppBuilder: sa := new CPlusPlusBuilderServerAccessCodeGen withrodl(rodl);
    Codegen4Platform.Java: sa:= new JavaServerAccessCodeGen withrodl(rodl);    
    Codegen4Platform.Cocoa: sa := new CocoaServerAccessCodeGen(rodl) swiftDialect(iif(codegen is CocoaRodlCodeGen, CocoaRodlCodeGen(codegen).SwiftDialect, CGSwiftCodeGeneratorDialect.Standard));
    Codegen4Platform.Net: sa := new NetServerAccessCodeGen(rodl) &namespace(TargetNameSpace);
    // Codegen4Platform.JavaScript: codegen := new JavaScriptServerAccessCodeGen;
  else
    exit;
  end;     
  if not assigned(codegen.Generator) then exit; //workaround for VB
  var lServerAddress := ParseAddParams(&params,ServerAddress);
  // ignore "file" server address
  if lServerAddress.ToLowerInvariant.StartsWith('file:///') then lServerAddress := '';
  if not String.IsNullOrEmpty(lServerAddress) then sa.serverAddress := lServerAddress;
  var lunit := sa.generateCodeUnit;
  var lunitname := rodl.Name+'_ServerAccess.'+fileext;
  Res.Add(new Codegen4Record(lunitname, codegen.Generator.GenerateUnit(lunit), Codegen4FileType.Unit));
  if sa is DelphiServerAccessCodeGen then begin
    lunitname := Path.ChangeExtension(lunitname,'dfm');
    Res.Add(new Codegen4Record(lunitname, DelphiServerAccessCodeGen(sa).generateDFM, Codegen4FileType.Form));    
  end;
  if codegen.Generator is CGObjectiveCMCodeGenerator then begin
    var gen := new CGObjectiveCHCodeGenerator;
    gen.splitLinesLongerThan := codegen.Generator.splitLinesLongerThan;
    lunitname := Path.ChangeExtension(lunitname,gen.defaultFileExtension);
    Res.Add(new Codegen4Record(lunitname, gen.GenerateUnit(lunit), Codegen4FileType.Header));
  end;
  if codegen.Generator is CGCPlusPlusCPPCodeGenerator then begin
    var gen := new CGCPlusPlusHCodeGenerator(Dialect:=CGCPlusPlusCPPCodeGenerator(codegen.Generator).Dialect, splitLinesLongerThan := codegen.Generator.splitLinesLongerThan);
    lunitname := Path.ChangeExtension(lunitname,gen.defaultFileExtension);
    Res.Add(new Codegen4Record(lunitname, gen.GenerateUnit(lunit), Codegen4FileType.Header));
  end;
end;

method Codegen4Wrapper.GenerateAsyncFiles(Res: Codegen4Records; codegen: RodlCodeGen; rodl: RodlLibrary; &namespace: String; fileext: String);
begin
  var lunitname := rodl.Name + '_Async.'+fileext;
  if codegen.CodeUnitSupport then begin
    if (codegen is DelphiRodlCodeGen) then begin
      // generate unit for backward compatibility, Delphi/C++Builder only

      var ltargetNamespace := &namespace;
      if String.IsNullOrEmpty(ltargetNamespace) then ltargetNamespace := rodl.Namespace;
      if String.IsNullOrEmpty(ltargetNamespace) then ltargetNamespace := rodl.Name;
      var lUnit := new CGCodeUnit();
      lUnit.Namespace := new CGNamespaceReference(ltargetNamespace);
      lUnit.FileName := lunitname;

      Res.Add(new Codegen4Record(lunitname, codegen.Generator.GenerateUnit(lUnit), Codegen4FileType.Unit));
      if codegen.Generator is CGCPlusPlusCPPCodeGenerator then begin
        var gen := new CGCPlusPlusHCodeGenerator(Dialect:=CGCPlusPlusCodeGenerator(codegen.Generator).Dialect);
        lunitname := Path.ChangeExtension(lunitname,gen.defaultFileExtension);
        Res.Add(new Codegen4Record(lunitname, gen.GenerateUnit(lUnit), Codegen4FileType.Header));
      end;
    end;
  end;
end;

constructor Codegen4Record(aFileName: String; aContent: String; aType: Codegen4FileType);
begin
  Filename := aFileName;
  Content := aContent;
  &Type := aType;
end;

method Codegen4Records.Add(anItem: Codegen4Record);
begin
  fList.Add(anItem);
end;

method Codegen4Records.Count: Integer;
begin
 exit fList.Count;
end;

method Codegen4Records.Item(anIndex: Integer): Codegen4Record;
begin
  exit fList[anIndex];
end;

end.