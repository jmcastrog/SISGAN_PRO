unit UBajas;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes,
  Vcl.Graphics, Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.StdCtrls, Vcl.ExtCtrls,
  Vcl.Grids, Vcl.ComCtrls, Data.DB, FireDAC.Comp.Client, FireDAC.Stan.Def,
  FireDAC.Stan.Pool, FireDAC.Stan.Async, FireDAC.Phys.SQLite, FireDAC.Phys.SQLiteDef,
  FireDAC.Stan.Intf, FireDAC.Phys.Intf, FireDAC.Comp.UI, System.UITypes;

type
  TFormBajas = class(TForm)
    pnlTop: TPanel;
    lblTitulo: TLabel;
    pnlCampos: TPanel;
    lblFecha: TLabel;
    dtpFecha: TDateTimePicker;
    lblAnimal: TLabel;
    edtBuscar: TEdit;
    lbSugerencias: TListBox;
    lblTipoBaja: TLabel;
    cmbTipoBaja: TComboBox;
    lblCausa: TLabel;
    memCausa: TMemo;
    lblComprador: TLabel;
    edtComprador: TEdit;
    lblPrecio: TLabel;
    edtPrecio: TEdit;
    lblPesoVenta: TLabel;
    edtPesoVenta: TEdit;
    lblGuia: TLabel;
    edtGuia: TEdit;
    lblSeguro: TLabel;
    cmbSeguro: TComboBox;
    lblObservaciones: TLabel;
    memObservaciones: TMemo;
    pnlBottom: TPanel;
    btnGuardar: TButton;
    btnCerrar: TButton;
    TimerSugerir: TTimer;
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure FormShow(Sender: TObject);
    procedure btnGuardarClick(Sender: TObject);
    procedure btnCerrarClick(Sender: TObject);
    procedure OnBuscarChange(Sender: TObject);
    procedure OnBuscarKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
    procedure OnSugerirTimer(Sender: TObject);
    procedure OnSugerenciaClick(Sender: TObject);
    procedure cmbTipoBajaChange(Sender: TObject);
  private
    FConnection: TFDConnection;
    FAnimales: TStringList;
    function ConectarBD: Boolean;
    procedure CarregarAnimales;
  public
  end;

var
  FormBajas: TFormBajas;

implementation

{$R *.dfm}

procedure TFormBajas.FormCreate(Sender: TObject);
begin
  cmbTipoBaja.Items.Add('Muerte');
  cmbTipoBaja.Items.Add('Venta');
  cmbTipoBaja.Items.Add('Robo');
  cmbTipoBaja.Items.Add('Sacrificio');
  cmbTipoBaja.Items.Add('Transferencia');
  cmbTipoBaja.Items.Add('Descarte');
  cmbTipoBaja.ItemIndex := 0;
  cmbSeguro.Items.Add('No');
  cmbSeguro.Items.Add('S'#237);
  cmbSeguro.ItemIndex := 0;
  dtpFecha.Date := Date;
  FAnimales := TStringList.Create;
  FAnimales.Sorted := True;
  FAnimales.Duplicates := dupIgnore;
  TimerSugerir := TTimer.Create(Self);
  TimerSugerir.Interval := 250;
  TimerSugerir.Enabled := False;
  TimerSugerir.OnTimer := OnSugerirTimer;
  cmbTipoBajaChange(nil);
end;

procedure TFormBajas.FormDestroy(Sender: TObject);
begin
  FAnimales.Free;
  FConnection.Free;
end;

procedure TFormBajas.FormShow(Sender: TObject);
begin
  if ConectarBD then
    CarregarAnimales;
end;

function TFormBajas.ConectarBD: Boolean;
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

procedure TFormBajas.CarregarAnimales;
var
  Q: TFDQuery;
begin
  FAnimales.Clear;
  Q := TFDQuery.Create(nil);
  try
    Q.Connection := FConnection;
    Q.SQL.Text := 'SELECT numero, nombre FROM animales WHERE estatus = ''Vivos'' ORDER BY numero';
    Q.Open;
    while not Q.Eof do
    begin
      FAnimales.Add(Q.FieldByName('numero').AsString + '|' + Q.FieldByName('nombre').AsString);
      Q.Next;
    end;
  finally
    Q.Free;
  end;
end;

procedure TFormBajas.OnBuscarChange(Sender: TObject);
begin
  TimerSugerir.Enabled := False;
  TimerSugerir.Enabled := True;
end;

procedure TFormBajas.OnBuscarKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
begin
  if Key = VK_DOWN then
  begin
    if lbSugerencias.Visible and (lbSugerencias.Items.Count > 0) then
    begin
      lbSugerencias.SetFocus;
      lbSugerencias.ItemIndex := 0;
    end;
  end
  else if Key = VK_ESCAPE then
    lbSugerencias.Visible := False;
end;

procedure TFormBajas.OnSugerirTimer(Sender: TObject);
var
  Filtro: string;
  I: Integer;
begin
  TimerSugerir.Enabled := False;
  Filtro := LowerCase(Trim(edtBuscar.Text));
  if Filtro = '' then
  begin
    lbSugerencias.Visible := False;
    Exit;
  end;
  lbSugerencias.Items.BeginUpdate;
  lbSugerencias.Clear;
  for I := 0 to FAnimales.Count - 1 do
  begin
    if Pos(Filtro, LowerCase(FAnimales[I])) > 0 then
    begin
      lbSugerencias.Items.Add(FAnimales[I]);
      if lbSugerencias.Items.Count >= 10 then Break;
    end;
  end;
  lbSugerencias.Items.EndUpdate;
  if lbSugerencias.Items.Count > 0 then
  begin
    lbSugerencias.Visible := True;
    lbSugerencias.BringToFront;
  end
  else
    lbSugerencias.Visible := False;
end;

procedure TFormBajas.OnSugerenciaClick(Sender: TObject);
begin
  if lbSugerencias.ItemIndex >= 0 then
  begin
    edtBuscar.Text := lbSugerencias.Items[lbSugerencias.ItemIndex];
    lbSugerencias.Visible := False;
  end;
end;

procedure TFormBajas.cmbTipoBajaChange(Sender: TObject);
var
  EsVenta: Boolean;
begin
  EsVenta := cmbTipoBaja.Text = 'Venta';
  edtComprador.Enabled := EsVenta;
  edtPrecio.Enabled := EsVenta;
  edtPesoVenta.Enabled := EsVenta;
  edtGuia.Enabled := EsVenta;
  if not EsVenta then
  begin
    edtComprador.Text := '';
    edtPrecio.Text := '';
    edtPesoVenta.Text := '';
    edtGuia.Text := '';
  end;
end;

procedure TFormBajas.btnGuardarClick(Sender: TObject);
var
  Fecha, Numero, Nombre, Tipo: string;
  PosBar: Integer;
begin
  Fecha := FormatDateTime('yyyy-mm-dd', dtpFecha.Date);
  if Pos('|', edtBuscar.Text) = 0 then
  begin
    ShowMessage('Selecciona un animal de la lista de sugerencias.');
    edtBuscar.SetFocus;
    Exit;
  end;
  PosBar := Pos('|', edtBuscar.Text);
  Numero := Copy(edtBuscar.Text, 1, PosBar - 1);
  Nombre := Copy(edtBuscar.Text, PosBar + 1, MaxInt);
  Tipo := cmbTipoBaja.Text;

  btnGuardar.Enabled := False;
  btnGuardar.Caption := 'GUARDANDO...';
  try
    FConnection.StartTransaction;
    try
      // Insert into bajas
      FConnection.ExecSQL(
        'INSERT INTO bajas (fecha, numero_animal, tipo_baja, causa, ' +
        'comprador, precio_total, peso_venta, guia_movilizacion, tiene_seguro, observaciones, ' +
        'creado_por, creado_en) ' +
        'VALUES (:f, :na, :tb, :cau, :comp, :pre, :pv, :guia, :seg, :obs, :cp, :ce)',
        [Fecha, Numero, Tipo, Trim(memCausa.Text),
         Trim(edtComprador.Text), StrToFloatDef(Trim(edtPrecio.Text), 0),
         StrToFloatDef(Trim(edtPesoVenta.Text), 0), Trim(edtGuia.Text),
         cmbSeguro.Text, Trim(memObservaciones.Text),
         'VCL', FormatDateTime('yyyy-mm-dd hh:nn:ss', Now)]);

      // Update animal estatus
      FConnection.ExecSQL('UPDATE animales SET estatus = :est WHERE numero = :num',
        [Tipo, Numero]);

      FConnection.Commit;
      ShowMessage('Baja registrada: ' + Numero + ' - ' + Nombre + ' (' + Tipo + ')');
      edtBuscar.Text := '';
      memCausa.Text := '';
      memObservaciones.Text := '';
      edtComprador.Text := '';
      edtPrecio.Text := '';
      edtPesoVenta.Text := '';
      edtGuia.Text := '';
      cmbSeguro.ItemIndex := 0;
      edtBuscar.SetFocus;
    except
      FConnection.Rollback;
      raise;
    end;
  except
    on E: Exception do
      ShowMessage('Error al guardar: ' + E.Message);
  end;
  btnGuardar.Caption := 'GUARDAR';
  btnGuardar.Enabled := True;
end;

procedure TFormBajas.btnCerrarClick(Sender: TObject);
begin
  Close;
end;

end.
