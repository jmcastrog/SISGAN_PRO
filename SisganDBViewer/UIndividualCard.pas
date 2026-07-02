unit UIndividualCard;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.StdCtrls, Vcl.ExtCtrls, Vcl.Mask, Data.DB,
  FireDAC.Stan.Intf, FireDAC.Stan.Option, FireDAC.Stan.Error, FireDAC.UI.Intf, FireDAC.Phys.Intf,
  FireDAC.Stan.Def, FireDAC.Stan.Pool, FireDAC.Stan.Async, FireDAC.Phys, FireDAC.VCLUI.Wait,
  FireDAC.Stan.ExprFuncs, FireDAC.Phys.SQLiteWrapper.Stat, FireDAC.Phys.SQLiteDef, FireDAC.Phys.SQLite,
  FireDAC.Comp.UI, FireDAC.Stan.Param, FireDAC.DatS, FireDAC.DApt.Intf, FireDAC.DApt,
  FireDAC.Comp.DataSet, FireDAC.Comp.Client;

type
  TIndividualCard = class(TForm)
    PanelTop: TPanel;
    lblTitle: TLabel;
    btnClose: TButton;
    btnSave: TButton;
    PanelFields: TPanel;
    ScrollBox1: TScrollBox;
    procedure btnCloseClick(Sender: TObject);
    procedure btnSaveClick(Sender: TObject);
    procedure FormKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
  private
    FConnection: TFDConnection;
    FAnimalId: Integer;
    FQuery: TFDQuery;
    FEdits: TList;
    FFields: TStringList;
    procedure LoadData;
  public
    constructor Create(AOwner: TComponent; AConnection: TFDConnection; AAnimalId: Integer); reintroduce;
    destructor Destroy; override;
  end;

implementation

{$R *.dfm}

uses
  System.UITypes;

constructor TIndividualCard.Create(AOwner: TComponent; AConnection: TFDConnection; AAnimalId: Integer);
begin
  inherited Create(AOwner);
  FConnection := AConnection;
  FAnimalId := AAnimalId;
  FEdits := TList.Create;
  FFields := TStringList.Create;
  LoadData;
end;

destructor TIndividualCard.Destroy;
var
  I: Integer;
begin
  for I := 0 to FEdits.Count - 1 do
    TObject(FEdits[I]).Free;
  FEdits.Free;
  FFields.Free;
  FQuery.Free;
  inherited;
end;

procedure TIndividualCard.LoadData;
var
  I, TopPos: Integer;
  Field: TField;
  lbl: TLabel;
  edt: TEdit;
begin
  FQuery := TFDQuery.Create(Self);
  FQuery.Connection := FConnection;
  FQuery.SQL.Text := 'SELECT * FROM animales WHERE id = :ID';
  FQuery.ParamByName('ID').AsInteger := FAnimalId;
  FQuery.Open;

  if FQuery.IsEmpty then
  begin
    lblTitle.Caption := 'Animal #' + FAnimalId.ToString + ' (no encontrado)';
    Exit;
  end;

  lblTitle.Caption := 'Animal: ' + FQuery.FieldByName('numero').AsString +
    ' - ' + FQuery.FieldByName('rp_sag').AsString;

  TopPos := 8;
  for I := 0 to FQuery.FieldCount - 1 do
  begin
    Field := FQuery.Fields[I];
    if SameText(Field.FieldName, 'rowid') or SameText(Field.FieldName, 'id') then Continue;

    lbl := TLabel.Create(ScrollBox1);
    lbl.Parent := ScrollBox1;
    lbl.Left := 8;
    lbl.Top := TopPos;
    lbl.Caption := Field.FieldName;
    lbl.Font.Style := [fsBold];

    edt := TEdit.Create(ScrollBox1);
    edt.Parent := ScrollBox1;
    edt.Left := 120;
    edt.Top := TopPos - 2;
    edt.Width := 300;
    edt.Text := Field.AsString;
    edt.Tag := I;

    FEdits.Add(edt);
    FFields.Add(Field.FieldName);

    Inc(TopPos, 28);
  end;
end;

procedure TIndividualCard.btnCloseClick(Sender: TObject);
begin
  Close;
end;

procedure TIndividualCard.btnSaveClick(Sender: TObject);
var
  I: Integer;
  SQL: string;
  Q: TFDQuery;
begin
  SQL := 'UPDATE animales SET ';
  for I := 0 to FEdits.Count - 1 do
  begin
    if I > 0 then SQL := SQL + ', ';
    SQL := SQL + '"' + FFields[I] + '" = :Val' + I.ToString;
  end;
  SQL := SQL + ' WHERE id = :ID';

  Q := TFDQuery.Create(nil);
  try
    Q.Connection := FConnection;
    Q.SQL.Text := SQL;
    for I := 0 to FEdits.Count - 1 do
      Q.ParamByName('Val' + I.ToString).AsString := TEdit(FEdits[I]).Text;
    Q.ParamByName('ID').AsInteger := FAnimalId;
    Q.ExecSQL;
    ShowMessage('Datos guardados correctamente.');
    Close;
  except
    on E: Exception do
      ShowMessage('Error al guardar: ' + E.Message);
  end;
  Q.Free;
end;

procedure TIndividualCard.FormKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
begin
  if Key = VK_ESCAPE then Close;
end;

end.
