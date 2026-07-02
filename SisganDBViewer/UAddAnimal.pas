unit UAddAnimal;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes,
  Vcl.Graphics, Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.StdCtrls, Vcl.ExtCtrls, Vcl.Mask,
  Vcl.Grids, Vcl.ComCtrls, Vcl.FileCtrl, Data.DB, FireDAC.Comp.Client, FireDAC.Stan.Def,
  FireDAC.Stan.Pool, FireDAC.Stan.Async, FireDAC.Phys.SQLite, FireDAC.Phys.SQLiteDef,
  FireDAC.Stan.Intf, FireDAC.Phys.Intf, FireDAC.Comp.UI;

type
  TFormAddAnimal = class(TForm)
    pnlTop: TPanel;
    lblTitulo: TLabel;
    pnlFields: TPanel;
    ScrollBox1: TScrollBox;
    lblNumero: TLabel;
    edtNumero: TEdit;
    lblNombre: TLabel;
    edtNombre: TEdit;
    lblFechaNac: TLabel;
    dtpFechaNac: TDateTimePicker;
    lblSexo: TLabel;
    cmbSexo: TComboBox;
    lblRaza: TLabel;
    edtRaza: TEdit;
    lblTipo: TLabel;
    cmbTipo: TComboBox;
    lblLote: TLabel;
    edtLote: TEdit;
    lblPropietario: TLabel;
    edtPropietario: TEdit;
    lblNumMadre: TLabel;
    edtNumMadre: TEdit;
    lblNomMadre: TLabel;
    edtNomMadre: TEdit;
    lblPadre: TLabel;
    edtPadre: TEdit;
    lblPesoNacer: TLabel;
    edtPesoNacer: TEdit;
    lblEstatusRepro: TLabel;
    cmbEstatusRepro: TComboBox;
    lblFechaPartoEst: TLabel;
    dtpFechaPartoEst: TDateTimePicker;
    lblComentarios: TLabel;
    memComentarios: TMemo;
    lblEstatus: TLabel;
    cmbEstatus: TComboBox;
    lblFotoAnimal: TLabel;
    edtFotoAnimal: TEdit;
    btnFotoAnimal: TButton;
    lblFotoHierro: TLabel;
    edtFotoHierro: TEdit;
    btnFotoHierro: TButton;
    pnlBottom: TPanel;
    btnGuardar: TButton;
    btnLimpiar: TButton;
    btnCerrar: TButton;
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure btnGuardarClick(Sender: TObject);
    procedure btnLimpiarClick(Sender: TObject);
    procedure btnCerrarClick(Sender: TObject);
    procedure FormShow(Sender: TObject);
    procedure btnFotoAnimalClick(Sender: TObject);
    procedure btnFotoHierroClick(Sender: TObject);
  private
    FConnection: TFDConnection;
    function ConectarBD: Boolean;
  public
  end;

var
  FormAddAnimal: TFormAddAnimal;

implementation

{$R *.dfm}

procedure TFormAddAnimal.FormCreate(Sender: TObject);
begin
  cmbSexo.ItemIndex := 0;
  cmbTipo.ItemIndex := 0;
  cmbEstatusRepro.ItemIndex := 0;
  cmbEstatus.ItemIndex := 0;
  dtpFechaNac.DateTime := Date;
  dtpFechaPartoEst.DateTime := Date;
end;

procedure TFormAddAnimal.FormDestroy(Sender: TObject);
begin
  FConnection.Free;
end;

procedure TFormAddAnimal.FormShow(Sender: TObject);
begin
  ConectarBD;
end;

function TFormAddAnimal.ConectarBD: Boolean;
var
  DbPath: string;
begin
  Result := False;
  try
    DbPath := ExtractFilePath(ParamStr(0)) + 'sisgan_pro.db';
    if not FileExists(DbPath) then
      DbPath := 'D:\Proyectos\SISGAN_PRO\data\sisgan_pro.db';
    if not FileExists(DbPath) then
    begin
      ShowMessage('Base de datos no encontrada: ' + DbPath);
      Exit;
    end;
    FConnection := TFDConnection.Create(Self);
    FConnection.Params.Add('DriverID=SQLite');
    FConnection.Params.Add('Database=' + DbPath);
    FConnection.Params.Add('LockingMode=Normal');
    FConnection.Params.Add('JournalMode=WAL');
    FConnection.Params.Add('BusyTimeout=10000');
    FConnection.Open;
    FConnection.ExecSQL('PRAGMA journal_mode=WAL');
    Result := True;
  except
    on E: Exception do
      ShowMessage('Error al conectar: ' + E.Message);
  end;
end;

procedure TFormAddAnimal.btnGuardarClick(Sender: TObject);
var
  Numero, Nombre: string;
begin
  Numero := Trim(edtNumero.Text);
  Nombre := Trim(edtNombre.Text);
  if Numero = '' then
  begin
    ShowMessage('El n'#250'mero es obligatorio.');
    edtNumero.SetFocus;
    Exit;
  end;
  if Nombre = '' then
  begin
    ShowMessage('El nombre es obligatorio.');
    edtNombre.SetFocus;
    Exit;
  end;

  btnGuardar.Enabled := False;
  btnGuardar.Caption := 'GUARDANDO...';
  try
    FConnection.ExecSQL(
      'INSERT INTO animales (numero, nombre, fecha_nac, sexo, raza, tipo, lote, estatus, ' +
      'propietario, num_madre, nom_madre, padre, peso_nacer, estatus_repro, fecha_parto_est, comentarios, ' +
      'foto_animal, foto_hierro) ' +
      'VALUES (:num, :nom, :fnac, :sex, :raz, :tip, :lot, :est, :prop, :nmad, :nommad, :pad, :peso, :estrepro, :fecparto, :com, :fotoani, :fotohie)',
      [Numero, Nombre,
       FormatDateTime('yyyy-mm-dd', dtpFechaNac.Date),
       cmbSexo.Text,
       Trim(edtRaza.Text),
       cmbTipo.Text,
       Trim(edtLote.Text),
       cmbEstatus.Text,
       Trim(edtPropietario.Text),
       Trim(edtNumMadre.Text),
       Trim(edtNomMadre.Text),
       Trim(edtPadre.Text),
       StrToFloatDef(Trim(edtPesoNacer.Text), 0),
       cmbEstatusRepro.Text,
       FormatDateTime('yyyy-mm-dd', dtpFechaPartoEst.Date),
       Trim(memComentarios.Text),
       Trim(edtFotoAnimal.Text),
       Trim(edtFotoHierro.Text)]);
    ShowMessage('Animal ' + Numero + ' - ' + Nombre + ' agregado correctamente.');
    btnLimpiarClick(nil);
  except
    on E: Exception do
      ShowMessage('Error al guardar: ' + E.Message);
  end;
  btnGuardar.Caption := 'GUARDAR';
  btnGuardar.Enabled := True;
end;

procedure TFormAddAnimal.btnLimpiarClick(Sender: TObject);
begin
  edtNumero.Text := '';
  edtNombre.Text := '';
  dtpFechaNac.Date := Date;
  cmbSexo.ItemIndex := 0;
  edtRaza.Text := '';
  cmbTipo.ItemIndex := 0;
  edtLote.Text := '';
  edtPropietario.Text := '';
  edtNumMadre.Text := '';
  edtNomMadre.Text := '';
  edtPadre.Text := '';
  edtPesoNacer.Text := '';
  cmbEstatusRepro.ItemIndex := 0;
  dtpFechaPartoEst.Date := Date;
  memComentarios.Text := '';
  cmbEstatus.ItemIndex := 0;
  edtFotoAnimal.Text := '';
  edtFotoHierro.Text := '';
  edtNumero.SetFocus;
end;

procedure TFormAddAnimal.btnFotoAnimalClick(Sender: TObject);
var
  Dlg: TOpenDialog;
begin
  Dlg := TOpenDialog.Create(Self);
  try
    Dlg.Title := 'Seleccionar foto del animal';
    Dlg.Filter := 'Imágenes (*.jpg;*.jpeg;*.png;*.bmp)|*.jpg;*.jpeg;*.png;*.bmp|Todos (*.*)|*.*';
    if Dlg.Execute then
      edtFotoAnimal.Text := Dlg.FileName;
  finally
    Dlg.Free;
  end;
end;

procedure TFormAddAnimal.btnFotoHierroClick(Sender: TObject);
var
  Dlg: TOpenDialog;
begin
  Dlg := TOpenDialog.Create(Self);
  try
    Dlg.Title := 'Seleccionar foto del hierro';
    Dlg.Filter := 'Imágenes (*.jpg;*.jpeg;*.png;*.bmp)|*.jpg;*.jpeg;*.png;*.bmp|Todos (*.*)|*.*';
    if Dlg.Execute then
      edtFotoHierro.Text := Dlg.FileName;
  finally
    Dlg.Free;
  end;
end;

procedure TFormAddAnimal.btnCerrarClick(Sender: TObject);
begin
  Close;
end;

end.
