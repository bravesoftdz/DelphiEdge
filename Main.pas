unit Main;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, SynEdit, SynMemo, Vcl.OleCtrls, SHDocVw,
  Vcl.ComCtrls, Vcl.StdCtrls, Vcl.ExtCtrls, ActiveX, SynHighlighterJScript,
  SynHighlighterMulti, SynEditCodeFolding, SynHighlighterPas,
  SynEditHighlighter, SynHighlighterHtml, mshtml, uPSComponent,
  uPSComponent_COM, uPSComponent_StdCtrls, uPSComponent_Forms,
  uPSComponent_Default, uPSComponent_Controls, uPSRuntime, uPSPreProcessor,
  System.SyncObjs, System.Math,Vcl.AppEvnts,
  System.Generics.Collections, SynHighlighterCSS, uPSComponent_DB;

const
  CEF_SHOWKEYBOARD     = WM_APP + $B01;
  CEF_HIDEKEYBOARD     = WM_APP + $B02;
  MINIBROWSER_VISITDOM_FULL               = WM_APP + $102;

type
  TForm1 = class(TForm)
    PnlCenter: TPanel;
    PnlBottom: TPanel;
    BtnOpen: TButton;
    OpenDialog: TOpenDialog;
    PageControl1: TPageControl;
    TabSheetBrowser: TTabSheet;
    TabSheetCode: TTabSheet;
    MemoCode: TSynMemo;
    SynHTMLSyn1: TSynHTMLSyn;
    SynPasSyn1: TSynPasSyn;
    SynMultiSyn1: TSynMultiSyn;
    SynJScriptSyn1: TSynJScriptSyn;
    IFPS3CE_Controls1: TPSImport_Controls;
    IFPS3CE_DateUtils1: TPSImport_DateUtils;
    IFPS3CE_Std1: TPSImport_Classes;
    IFPS3CE_ComObj1: TPSImport_ComObj;
    IFPS3DllPlugin1: TPSDllPlugin;
    BtnSave: TButton;
    SaveDialog: TSaveDialog;
    ApplicationEvents: TApplicationEvents;
    Button1: TButton;
    Browser: TWebBrowser;
    ce: TPSScriptDebugger;
    SynCssSyn1: TSynCssSyn;
    PSImport_Classes1: TPSImport_Classes;
    PSImport_Forms1: TPSImport_Forms;
    PSImport_StdCtrls1: TPSImport_StdCtrls;
    procedure TabSheetBrowserShow(Sender: TObject);
    procedure BtnOpenClick(Sender: TObject);
    procedure ceCompile(Sender: TPSScript);
    procedure ceExecute(Sender: TPSScript);
    procedure ceIdle(Sender: TObject);
    procedure BtnSaveClick(Sender: TObject);
    procedure BrowserDocumentComplete(ASender: TObject; const pDisp: IDispatch;
      const URL: OleVariant);
  private

    function Compile: Boolean;
    function Execute: Boolean;
    procedure WB_LoadHTML(HTMLCode: string);
    function GetPascalScripts(doc : IHTMLDocument3; var RunTimeConstants: TDictionary<string, Variant>; RunTimeVariables: TDictionary<string, string>): string;
    function GetJavascriptVariable(variable: string): Variant;
    function ParseIncludeJSVariables(line: string; RunTimeVariables: TDictionary<string, Variant>): string;

  protected
    __sPascalCodes: string;
  public
    { Public declarations }
  end;

var
  Form1: TForm1;


implementation


{$R *.dfm}



//------------------------------------------------------------------------------

var
  Doc: IHTMLDocument2;
  TempFile: string;
  xBody   : IHTMLElement;
  xLoaded : Boolean;
  onlyOnce: Boolean;

procedure TForm1.WB_LoadHTML(HTMLCode: string);
var
  sl: TStringList;
  ms: TMemoryStream;
begin
  xLoaded := False;
  Browser.Navigate('about:blank');
  while Browser.ReadyState < READYSTATE_INTERACTIVE do
   Application.ProcessMessages;

  if Assigned(Browser.Document) then
  begin
    sl := TStringList.Create;
    try
      ms := TMemoryStream.Create;
      try
        sl.Text := HTMLCode;
        sl.SaveToStream(ms);
        ms.Seek(0, 0);
        (Browser.Document as IPersistStreamInit).Load(TStreamAdapter.Create(ms));
      finally
        ms.Free;
      end;
    finally
      sl.Free;
      Doc :=  Browser.Document as IHTMLDocument2;
    end;
  end;
end;

function TForm1.Compile: Boolean;
begin
  ce.Script.Text := __sPascalCodes;
  Result := ce.Compile;
end;

function TForm1.Execute: Boolean;
begin
  if CE.Execute then
  begin
    Result := True;
  end else
  begin
    Result := False;
  end;
end;

function TForm1.GetJavascriptVariable(variable: string): Variant;
var
  Window: IHTMLWindow2;
  DispatchIdOfProperty: Integer;
  MyPropertyValue: OleVariant;
  Temp: TExcepInfo;
  Res: Integer;
  Params:TDispParams;
begin
  // get window interface
  Window:= (Browser.ControlInterface.Document as IHTMLDocument2).parentWindow;
  Assert(Assigned(Window));
  // get dispatch ID of our variable
  if (Window as IDispatchEx).GetDispID(PWideChar(variable), fdexNameCaseSensitive, DispatchIdOfProperty) = S_OK then
  begin
    // no parameters
    ZeroMemory(@Params, SizeOf(Params));
    // get value of our variable
    Res:=(Window as IDispatchEx).InvokeEx(DispatchIdOfProperty, LOCALE_USER_DEFAULT, DISPATCH_PROPERTYGET, @Params, MyPropertyValue, Temp, nil);
    if Res=S_OK then
    begin
      // voila - this should display the value
      result := MyPropertyValue;
    end else
      ShowMessage('Error reading property value');
  end
  else
    ShowMessage('Property not found');
end;

function TForm1.ParseIncludeJSVariables(line: string; RunTimeVariables: TDictionary<string, Variant>): string;
var
  strLine, varStr, name, types: string;
  sNames: TStringList;
  I: Integer;
  JSValue: Variant;
begin
  strLine := trim(line);
  while (Pos('import ', LowerCase(strLine)) > 0) do
  begin
    varStr := copy(strLine, Pos('import ', LowerCase(strLine)), Pos(';', strLine)- 1);
    Delete(varStr, 1,Pos('import ', LowerCase(varStr)) + 6);
    name := varStr;
    name := trim(name);

    sNames:= TStringList.Create;
    sNames.Text := StringReplace(name, ',',#13,[rfReplaceAll]);
    for I := 0 to sNames.Count -1 do
    begin
      JSValue := GetJavascriptVariable(Trim(sNames[I]));
      RunTimeVariables.Add(Trim(sNames[I]), JSValue);
    end;
    sNames.Free;
    Delete(strLine, Pos('import ', LowerCase(strLine)), Pos(';', strLine) + 1);
  end;
  Result := strLine;
end;


function ParseCheckVariables(line: string; RunTimeVariables: TDictionary<string, string>): string;
var
  strLine, varStr, name, types: string;
  sNames: TStringList;
  I: Integer;
begin
  strLine := line;
  while (Pos('var ', LowerCase(strLine)) > 0) do
  begin
    varStr := copy(strLine, Pos('var ', LowerCase(strLine)), Pos(';', strLine)+ 1);
    Delete(varStr, 1,Pos('var ', LowerCase(varStr)) + 3);
    name := copy(varStr, 0, Pos(':', varStr) -1);
    name := trim(name);
    Delete(varStr, 1, Pos(':', varStr));
    types := copy(varStr, 0, Pos(';', varStr) - 1);
    types := trim(types);

    sNames:= TStringList.Create;
    sNames.Text := StringReplace(name, ',',#13,[rfReplaceAll]);
    for I := 0 to sNames.Count -1 do
      RunTimeVariables.Add(Trim(sNames[I]), types);
    sNames.Free;
    Delete(strLine, Pos('var ', LowerCase(strLine)), Pos(';', strLine) + 1);
  end;
  Result := strLine;
end;




function TForm1.GetPascalScripts(doc : IHTMLDocument3; var RunTimeConstants: TDictionary<string, Variant>; RunTimeVariables: TDictionary<string, string>): string;
var
  scripts: IHTMLElementCollection;
  I: Integer;
  Code: string;
  sList: TStringList;

begin

  sList:= TStringList.Create;
  try
    scripts := doc.getElementsByTagName('script');
    for I := 0 to scripts.length -1 do
    begin
      if (scripts.item(I, EmptyParam) as IHTMLScriptElement).type_ = 'text/pascal' then
      begin
        Code := Code + (scripts.item(I, EmptyParam) as IHTMLScriptElement).text + chr(13);
      end;
    end;


    sList.Text := UTF8ToString( Code);

    I := 0;
    while I < sList.Count do
    begin
      sList[I] := ParseIncludeJSVariables(sList[I], RunTimeConstants);
      sList[I] := ParseCheckVariables(sList[I], RunTimeVariables);
      Inc(I);
    end;

    Result := sList.Text;

  finally
    sList.Free;
  end;
end;

function VarTypeValue(V: Variant; name, value: string ): string;
var
  typeString : string;
  basicType  : Integer;

begin
  // Get the Variant basic type :
  // this means excluding array or indirection modifiers
  basicType := VarType(V) and VarTypeMask;

  // Set a string to match the type
  case basicType of
    vtInteger   : typeString := 'var ' + name +': integer;';
    vtExtended    : typeString := 'var ' + name +': double;';
    vtBoolean   : typeString := 'var ' + name +': boolean;';
    vtString    : typeString := 'var ' + name +': string;';
    vtClass      : typeString := 'var ' + name +': string;';
  end;

  Result := typeString;

end;

function VarTypeSetValues(V: Variant; name, value: string ): string;
var
  typeString : string;
  basicType  : Integer;

begin
  // Get the Variant basic type :
  // this means excluding array or indirection modifiers
  basicType := VarType(V) and VarTypeMask;

  // Set a string to match the type
  case basicType of
    vtInteger   : typeString := name +':=' + value + ';';
    vtExtended    : typeString := name +':=' + value + ';';
    vtBoolean   : typeString := name +':=' + value + ';';
    vtString    : typeString := name +':=' + #39+ value + #39 + ';';
    vtClass      : typeString := name +':=' + #39+ value + #39 + ';';
  end;

  Result := typeString;

end;



procedure TForm1.BrowserDocumentComplete(ASender: TObject;
  const pDisp: IDispatch; const URL: OleVariant);
var
  pascalCodes, sVariables, sConstants, VName, sConstantSetter: string;
  RunTimeConstants: TDictionary<string, variant>;
  RunTimeVariables: TDictionary<string, string>;
  RTVariableKeys: TArray<string>;
  I: Integer;
begin

  if Assigned((Browser.Document as IHTMLDocument2).body) then
  begin
    RunTimeConstants := TDictionary<string, variant>.Create();
    RunTimeVariables := TDictionary<string, string>.Create();
    try
      pascalCodes := GetPascalScripts(Browser.Document as IHTMLDocument3, RunTimeConstants, RunTimeVariables);
      if trim(pascalCodes) <> '' then
      begin
        RTVariableKeys := RunTimeVariables.Keys.ToArray();
        for VName in RTVariableKeys do
        begin
          sVariables := sVariables + ' var ' + VName + ':' +  RunTimeVariables[VName] +'; '+ chr(13);
        end;

        RTVariableKeys := RunTimeConstants.Keys.ToArray();
        for VName in RTVariableKeys do
        begin
          sConstants := sConstants + ' ' +VarTypeValue(RunTimeConstants[VName], VName, RunTimeConstants[VName]) + chr(13);
          sConstantSetter := sConstantSetter + ' ' +VarTypeSetValues(RunTimeConstants[VName], VName, RunTimeConstants[VName]) + chr(13);
        end;
        __sPascalCodes := 'program pascaldhtml; '+ chr(13) +
                          sVariables + chr(13) + sConstants +
                          ' begin ' + sConstantSetter + chr(13) + pascalCodes + ' end.';
        if Compile then
          Execute;
      end;
    finally
      RunTimeConstants.Free;
      RunTimeVariables.Free;
    end;
  end;

end;

procedure TForm1.BtnOpenClick(Sender: TObject);
begin
  if OpenDialog.Execute() then
  begin
    MemoCode.Lines.LoadFromFile(OpenDialog.FileName);
  end;
end;

procedure TForm1.BtnSaveClick(Sender: TObject);
begin
  if SaveDialog.Execute then
  begin
    MemoCode.Lines.SaveToFile(SaveDialog.FileName);
  end;
end;


procedure TForm1.ceCompile(Sender: TPSScript);
begin
  Sender.AddMethod(Self, @ShowMessage, 'procedure ShowMessage(const s: AnsiString);');
  Sender.AddFunction(@IntToStr, 'function IntToStr(Value: Integer): AnsiString;');
  Sender.AddRegisteredVariable('Self', 'TForm');
  Sender.AddRegisteredVariable('Application', 'TApplication');
end;

procedure TForm1.ceExecute(Sender: TPSScript);
begin

  ce.SetVarToInstance('SELF', Self);
  ce.SetVarToInstance('APPLICATION', Application);
  //ce.SetPointerToData('document', @Browser.Document, ce.FindNamedType('IHTMLDocument2'));
end;

procedure TForm1.ceIdle(Sender: TObject);
begin
  Application.ProcessMessages;
end;

procedure TForm1.TabSheetBrowserShow(Sender: TObject);
begin
  WB_LoadHTML(MemoCode.Lines.Text);
end;

end.