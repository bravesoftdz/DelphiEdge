unit Lib;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants,
  System.Classes, Vcl.Dialogs, JavascriptObject,
  Soap.InvokeRegistry, Soap.SOAPHTTPClient, System.Types, Soap.XSBuiltIns, TypInfo;


type
  ISoapInvokable = interface(IInvokable)
  ['{AF0D7A8E-A819-458B-82E0-29B289DAAC34}']
  function GetDeneme(s: string): string;
  end;

  TLib = class
    class procedure ShowMessage(Value: string);
    class function JSDecode(Value: Variant): TJSObject;
    class function SoapCall(GuidStr: string; Addr: string): ISoapInvokable;
  end;

implementation

uses System.RTTI, Main, uPSRuntime, uPSCompiler;

class procedure TLib.ShowMessage(Value: string);
begin
  Vcl.Dialogs.ShowMessage(Value);
end;

class function TLib.JSDecode(Value: Variant): TJSObject;
var
  JS: TJSObject;
begin
  JS:= TJSObject.Create();
  JS.ActualJSPoint := Value;
  Result := JS;
end;

class function TLib.SoapCall(GuidStr: string; Addr: string): ISoapInvokable;
var
  RIO: THTTPRIO;
  I: Integer;
  P: TPSTypeRec;
  Guid: TGuid;
  A: Integer;
  V: PIFVariant;
  Intf: IUnknown;
begin
 { Guid := StringToGUID(GuidStr);

  for I := 0 to MainForm.ce.Exec.GetTypeCount -1 do
  begin
    P := MainForm.ce.Exec.GetTypeNo(I);
    if TPSTypeRec_Interface(P).Guid = Guid then
    begin
      for A := 0 to MainForm.ce.Exec.GetVarCount -1 do
      begin
        V := MainForm.ce.Exec.GetVarNo(A);
        if TPSTypeRec_Interface(V.FType).Guid = Guid then
        begin
          Intf := PPSVariantInterface(V).Data ;
          break;
        end;
      end;

      break;

    end;
  end;  }
  Result := nil;
  if Addr = '' then
    exit();

  RIO := THTTPRIO.Create(nil);
  try
    Result := RIO as ISoapInvokable;
    RIO.URL := Addr;
  finally
    if (Result = nil) then
      RIO.Free;
  end;
end;

initialization
InvRegistry.RegisterInterface(TypeInfo(ISoapInvokable), 'urn:DenemeIntf-IDeneme', '');
InvRegistry.RegisterDefaultSOAPAction(TypeInfo(ISoapInvokable), 'GetDeneme');


end.
