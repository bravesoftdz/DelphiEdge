unit DialogList;

interface

uses
  System.Classes, Vcl.Dialogs;

type
  TDialogOpen = class(TObject)
  private
    FOpenDialog: TOpenDialog;
    function GetFiles: TStrings;
    function GetFileName: string;
    procedure SetFileName(Value: string);
    function GetInitialDir: string;
    procedure SetInitialDir(Value: string);
    function GetTitle: string;
    procedure SetTitle(Value: string);

  public
    constructor Create;
    destructor Destroy; override;
    function Execute(): Boolean;
    property Files: TStrings read GetFiles;
    property FileName: string read GetFileName write SetFileName;
    property InitialDir: string read GetInitialDir write SetInitialDir;
    property Title: string read GetTitle write SetTitle;
  end;

  TDialogSave = class(TObject)
  private
    FSaveDialog: TSaveDialog;
    function GetFiles: TStrings;
    function GetFileName: string;
    procedure SetFileName(Value: string);
    function GetInitialDir: string;
    procedure SetInitialDir(Value: string);
    function GetTitle: string;
    procedure SetTitle(Value: string);

  public
    constructor Create;
    destructor Destroy; override;
    function Execute(): Boolean;
    property Files: TStrings read GetFiles;
    property FileName: string read GetFileName write SetFileName;
    property InitialDir: string read GetInitialDir write SetInitialDir;
    property Title: string read GetTitle write SetTitle;
  end;

implementation

{ TDialogOpen }

constructor TDialogOpen.Create;
begin
  FOpenDialog := TOpenDialog.Create(nil);
end;

destructor TDialogOpen.Destroy;
begin
  FOpenDialog.Free;
  inherited;
end;

function TDialogOpen.Execute: Boolean;
begin
  Result := FOpenDialog.Execute();
end;

function TDialogOpen.GetFileName: string;
begin
  Result := FOpenDialog.FileName;
end;

function TDialogOpen.GetFiles: TStrings;
begin
  Result := FOpenDialog.Files;
end;

function TDialogOpen.GetInitialDir: string;
begin
  Result := FOpenDialog.InitialDir;
end;

function TDialogOpen.GetTitle: string;
begin
  Result := FOpenDialog.Title;
end;

procedure TDialogOpen.SetFileName(Value: string);
begin
  FOpenDialog.FileName := Value;
end;

procedure TDialogOpen.SetInitialDir(Value: string);
begin
  FOpenDialog.InitialDir := Value;
end;

procedure TDialogOpen.SetTitle(Value: string);
begin
  FOpenDialog.Title := Value;
end;


{ TDialogSave }

constructor TDialogSave.Create;
begin
  FSaveDialog := TSaveDialog.Create(nil);
end;

destructor TDialogSave.Destroy;
begin
  FSaveDialog.Free;
  inherited;
end;

function TDialogSave.Execute: Boolean;
begin
  Result := FSaveDialog.Execute();
end;

function TDialogSave.GetFileName: string;
begin
  Result := FSaveDialog.FileName;
end;

function TDialogSave.GetFiles: TStrings;
begin
  Result := FSaveDialog.Files;
end;

function TDialogSave.GetInitialDir: string;
begin
  Result := FSaveDialog.InitialDir;
end;

function TDialogSave.GetTitle: string;
begin
  Result := FSaveDialog.Title;
end;

procedure TDialogSave.SetFileName(Value: string);
begin
  FSaveDialog.FileName := Value;
end;

procedure TDialogSave.SetInitialDir(Value: string);
begin
  FSaveDialog.InitialDir := Value;
end;

procedure TDialogSave.SetTitle(Value: string);
begin
  FSaveDialog.Title := Value;
end;

end.
