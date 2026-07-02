unit UPalpaciones;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes,
  Vcl.Graphics, Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.StdCtrls, Vcl.ExtCtrls,
  Vcl.Grids, Vcl.ComCtrls, Data.DB, FireDAC.Comp.Client, FireDAC.Stan.Def,
  FireDAC.Stan.Pool, FireDAC.Stan.Async, FireDAC.Phys.SQLite, FireDAC.Phys.SQLiteDef,
  FireDAC.Stan.Intf, FireDAC.Phys.Intf, FireDAC.Comp.UI, System.UITypes;

type
  TPalpacion = record
    Id: Integer;
    Numero: string;
    Nombre: string;
    Diagnostico: string;
    DiasPrenez: Integer;
    Observaciones: string;
  end;

  TFormPalpaciones = class(TForm)
    pnlTop: TPanel;
    lblTitulo: TLabel;
    dtpFecha: TDateTimePicker;
    lblFecha: TLabel;
    lblTecnico: TLabel;
    edtTecnico: TEdit;
    pnlSearch: TPanel;
    lblBuscar: TLabel;
    edtBuscar: TEdit;
    lbSugerencias: TListBox;
    lblDiagnostico: TLabel;
    cmbDiagnostico: TComboBox;
    btnAgregar: TButton;
    pnlList: TPanel;
    sgLista: TStringGrid;
    lblCount: TLabel;
    pnlBottom: TPanel;
    btnGrabar: TButton;
    btnLimpiar: TButton;
    btnCerrar: TButton;
    btnConsultar: TButton;
    edtDiasPrenez: TEdit;
    edtObservaciones: TEdit;
    TimerSugerir: TTimer;
    lbFechas: TListBox;
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure FormShow(Sender: TObject);
    procedure OnBuscarChange(Sender: TObject);
    procedure OnBuscarKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
    procedure OnSugerirTimer(Sender: TObject);
    procedure OnSugerenciaClick(Sender: TObject);
    procedure OnAgregarClick(Sender: TObject);
    procedure OnGrabarClick(Sender: TObject);
    procedure OnLimpiarClick(Sender: TObject);
    procedure OnCerrarClick(Sender: TObject);
    procedure OnConsultarClick(Sender: TObject);
    procedure OnFechaClick(Sender: TObject);
    procedure sgListaSetEditText(Sender: TObject; ACol, ARow: Integer; const Value: string);
  private
    FConnection: TFDConnection;
    FAnimales: TStringList;
    FPending: array of TPalpacion;
    function ConectarBD: Boolean;
    procedure CarregarAnimales;
    procedure RenderLista;
    procedure SalvarTemporal;
    function CargarTemporal: Boolean;
    procedure EliminarTemporal;
  public
  end;

var
  FormPalpaciones: TFormPalpaciones;

implementation

{$R *.dfm}

procedure TFormPalpaciones.FormCreate(Sender: TObject);
begin
  dtpFecha.Date := Date;
  cmbDiagnostico.Items.Add('Pre'#241'ada');
  cmbDiagnostico.Items.Add('Vacia');
  cmbDiagnostico.Items.Add('Pr'#243'xima Revisi'#243'n');
  cmbDiagnostico.ItemIndex := 0;
  edtDiasPrenez.Text := '0';
  FAnimales := TStringList.Create;
  FAnimales.Sorted := True;
  FAnimales.Duplicates := dupIgnore;
  TimerSugerir := TTimer.Create(Self);
  TimerSugerir.Interval := 250;
  TimerSugerir.Enabled := False;
  TimerSugerir.OnTimer := OnSugerirTimer;

  sgLista.Cells[0, 0] := 'N'#250'mero';
  sgLista.Cells[1, 0] := 'Nombre';
  sgLista.Cells[2, 0] := 'Diagn'#243'stico';
  sgLista.Cells[3, 0] := 'D'#237'as';
  sgLista.Cells[4, 0] := 'Observaciones';
end;

procedure TFormPalpaciones.FormDestroy(Sender: TObject);
begin
  SalvarTemporal;
  FAnimales.Free;
  FConnection.Free;
end;

procedure TFormPalpaciones.FormShow(Sender: TObject);
begin
  if ConectarBD then
  begin
    CarregarAnimales;
    if CargarTemporal then
      if MessageDlg('Se encontr'#243'un borrador guardado. '#191'Cargarlo?', mtConfirmation, [mbYes, mbNo], 0) <> mrYes then
      begin
        SetLength(FPending, 0);
        RenderLista;
      end;
  end;
end;

function TFormPalpaciones.ConectarBD: Boolean;
var
  DbPath: string;
begin
  if (FConnection <> nil) and FConnection.Connected then
    Exit(True);
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
    try FConnection.ExecSQL('ALTER TABLE palpaciones ADD COLUMN dias_prenez INTEGER DEFAULT 0'); except end;
    try FConnection.ExecSQL('ALTER TABLE palpaciones ADD COLUMN observaciones TEXT DEFAULT '''''); except end;
    Result := True;
  except
    on E: Exception do
      ShowMessage('Error al conectar: ' + E.Message);
  end;
end;

procedure TFormPalpaciones.CarregarAnimales;
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

procedure TFormPalpaciones.OnBuscarChange(Sender: TObject);
begin
  TimerSugerir.Enabled := False;
  TimerSugerir.Enabled := True;
end;

procedure TFormPalpaciones.OnBuscarKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
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

procedure TFormPalpaciones.OnSugerirTimer(Sender: TObject);
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

procedure TFormPalpaciones.OnSugerenciaClick(Sender: TObject);
begin
  if lbSugerencias.ItemIndex >= 0 then
  begin
    edtBuscar.Text := lbSugerencias.Items[lbSugerencias.ItemIndex];
    lbSugerencias.Visible := False;
  end;
end;

procedure TFormPalpaciones.OnAgregarClick(Sender: TObject);
var
  P: TPalpacion;
  I: Integer;
  PosBar: Integer;
begin
  if Pos('|', edtBuscar.Text) = 0 then
  begin
    if lbSugerencias.Visible and (lbSugerencias.ItemIndex >= 0) then
      OnSugerenciaClick(nil)
    else
    begin
      ShowMessage('Selecciona un animal de la lista de sugerencias.');
      edtBuscar.SetFocus;
      Exit;
    end;
  end;

  PosBar := Pos('|', edtBuscar.Text);
  P.Id := 0;
  P.Numero := Copy(edtBuscar.Text, 1, PosBar - 1);
  P.Nombre := Copy(edtBuscar.Text, PosBar + 1, MaxInt);
  P.Diagnostico := cmbDiagnostico.Text;
  P.DiasPrenez := StrToIntDef(edtDiasPrenez.Text, 0);
  P.Observaciones := Trim(edtObservaciones.Text);

  SetLength(FPending, Length(FPending) + 1);
  for I := High(FPending) downto 1 do
    FPending[I] := FPending[I - 1];
  FPending[0] := P;

  edtBuscar.Text := '';
  edtObservaciones.Text := '';
  edtDiasPrenez.Text := '0';
  edtBuscar.SetFocus;
  RenderLista;
end;

procedure TFormPalpaciones.RenderLista;
var
  I: Integer;
begin
  sgLista.RowCount := Length(FPending) + 1;
  for I := 0 to High(FPending) do
  begin
    sgLista.Cells[0, I + 1] := FPending[I].Numero;
    sgLista.Cells[1, I + 1] := FPending[I].Nombre;
    sgLista.Cells[2, I + 1] := FPending[I].Diagnostico;
    sgLista.Cells[3, I + 1] := IntToStr(FPending[I].DiasPrenez);
    sgLista.Cells[4, I + 1] := FPending[I].Observaciones;
  end;
  lblCount.Caption := Format('%d palpaciones', [Length(FPending)]);
  btnGrabar.Enabled := Length(FPending) > 0;
end;

const
  PalpTempFile = '.palpaciones_temp';

procedure TFormPalpaciones.SalvarTemporal;
var
  SL: TStringList;
  I: Integer;
begin
  if Length(FPending) = 0 then Exit;
  SL := TStringList.Create;
  try
    for I := 0 to High(FPending) do
      SL.Add(FPending[I].Numero + #9 + FPending[I].Nombre + #9 +
        FPending[I].Diagnostico + #9 + IntToStr(FPending[I].DiasPrenez) + #9 +
        FPending[I].Observaciones);
    SL.SaveToFile(ExtractFilePath(ParamStr(0)) + PalpTempFile);
  finally
    SL.Free;
  end;
end;

function TFormPalpaciones.CargarTemporal: Boolean;
var
  SL:   TStringList;
  I: Integer;
  Flds: TStringList;
begin
  Result := False;
  if not FileExists(ExtractFilePath(ParamStr(0)) + PalpTempFile) then Exit;
  SL := TStringList.Create;
  Flds := TStringList.Create;
  try
    Flds.Delimiter := #9;
    Flds.StrictDelimiter := True;
    SL.LoadFromFile(ExtractFilePath(ParamStr(0)) + PalpTempFile);
    if SL.Count = 0 then Exit;
    SetLength(FPending, SL.Count);
    for I := 0 to SL.Count - 1 do
    begin
      Flds.DelimitedText := SL[I];
      if Flds.Count >= 5 then
      begin
        FPending[I].Id := 0;
        FPending[I].Numero := Flds[0];
        FPending[I].Nombre := Flds[1];
        FPending[I].Diagnostico := Flds[2];
        FPending[I].DiasPrenez := StrToIntDef(Flds[3], 0);
        FPending[I].Observaciones := Flds[4];
      end;
    end;
    RenderLista;
    Result := True;
  finally
    Flds.Free;
    SL.Free;
  end;
end;

procedure TFormPalpaciones.EliminarTemporal;
var
  Fn: string;
begin
  Fn := ExtractFilePath(ParamStr(0)) + PalpTempFile;
  if FileExists(Fn) then DeleteFile(Fn);
end;

procedure TFormPalpaciones.sgListaSetEditText(Sender: TObject; ACol, ARow: Integer; const Value: string);
begin
  if ARow < 1 then Exit;
  case ACol of
    2: FPending[ARow - 1].Diagnostico := Value;
    3: FPending[ARow - 1].DiasPrenez := StrToIntDef(Value, 0);
    4: FPending[ARow - 1].Observaciones := Value;
  end;
end;

procedure TFormPalpaciones.OnGrabarClick(Sender: TObject);
var
  I, Grabadas: Integer;
  Fecha, Tecnico: string;
begin
  if Length(FPending) = 0 then Exit;
  Fecha := FormatDateTime('yyyy-mm-dd', dtpFecha.Date);
  Tecnico := Trim(edtTecnico.Text);

  if Length(FPending) = 0 then
  begin
    ShowMessage('No hay cambios para guardar.');
    Exit;
  end;

  if MessageDlg(Format('Guardar cambios de %d palpaci'#243'n(es) del %s?', [Length(FPending), Fecha]),
    mtConfirmation, [mbYes, mbNo], 0) <> mrYes then Exit;

  btnGrabar.Enabled := False;
  btnGrabar.Caption := 'GRABANDO...';
  Grabadas := 0;
  for I := 0 to High(FPending) do
  begin
    try
      if FPending[I].Id > 0 then
        FConnection.ExecSQL(
          'UPDATE palpaciones SET diagnostico = :d, dias_prenez = :dp, observaciones = :obs WHERE id = :id',
          [FPending[I].Diagnostico, FPending[I].DiasPrenez, FPending[I].Observaciones, FPending[I].Id])
      else
        FConnection.ExecSQL(
          'INSERT INTO palpaciones (fecha, numero, diagnostico, dias_prenez, observaciones, tecnico, creado_por, creado_en) ' +
          'VALUES (:f, :n, :d, :dp, :obs, :tec, :cp, :ce)',
          [Fecha, FPending[I].Numero, FPending[I].Diagnostico,
           FPending[I].DiasPrenez, FPending[I].Observaciones, Tecnico, 'VCL',
           FormatDateTime('yyyy-mm-dd hh:nn:ss', Now)]);
      Inc(Grabadas);
    except
      on E: Exception do
        ShowMessage(Format('Error en registro #%d (%s): %s', [I + 1, FPending[I].Numero, E.Message]));
    end;
  end;
  if Grabadas > 0 then
  begin
    EliminarTemporal;
    ShowMessage(Format('%d palpaci'#243'n(es) guardada(s) correctamente.', [Grabadas]));
    SetLength(FPending, 0);
    RenderLista;
  end;
  btnGrabar.Caption := 'GRABAR EN BD';
  btnGrabar.Enabled := True;
end;

procedure TFormPalpaciones.OnLimpiarClick(Sender: TObject);
begin
  if (Length(FPending) > 0) and
     (MessageDlg('Seguro de descartar la lista actual?', mtConfirmation, [mbYes, mbNo], 0) <> mrYes) then Exit;
  SetLength(FPending, 0);
  edtBuscar.Text := '';
  edtDiasPrenez.Text := '0';
  edtObservaciones.Text := '';
  RenderLista;
  edtBuscar.SetFocus;
end;

procedure TFormPalpaciones.OnCerrarClick(Sender: TObject);
begin
  if (Length(FPending) > 0) and
     (MessageDlg('Hay datos sin grabar. Cerrar de todas formas?', mtConfirmation, [mbYes, mbNo], 0) <> mrYes) then Exit;
  Close;
end;

procedure TFormPalpaciones.OnConsultarClick(Sender: TObject);
var
  Q: TFDQuery;
begin
  lbFechas.Items.Clear;
  if not ConectarBD then Exit;
  Q := TFDQuery.Create(nil);
  try
    Q.Connection := FConnection;
    Q.SQL.Text := 'SELECT fecha, COUNT(*) as cnt FROM palpaciones GROUP BY fecha ORDER BY fecha DESC';
    Q.Open;
    while not Q.Eof do
    begin
      with Q do
        lbFechas.Items.AddObject(
          Copy(FieldByName('fecha').AsString, 9, 2) + '-' +
          Copy(FieldByName('fecha').AsString, 6, 2) + '-' +
          Copy(FieldByName('fecha').AsString, 1, 4),
          TObject(FieldByName('cnt').AsInteger));
      Q.Next;
    end;
  finally
    Q.Free;
  end;
  if lbFechas.Items.Count > 0 then
    ShowMessage(Format('Se encontraron %d fechas con palpaciones.', [lbFechas.Items.Count]))
  else
    ShowMessage('No hay palpaciones registradas.');
  lbFechas.Visible := lbFechas.Items.Count > 0;
  if lbFechas.Visible then
    lbFechas.BringToFront;
end;

procedure TFormPalpaciones.OnFechaClick(Sender: TObject);
var
  FechaStr, SqlFecha: string;
  Anio, Mes, Dia: Integer;
  Q: TFDQuery;
  P: TPalpacion;
begin
  if lbFechas.ItemIndex < 0 then Exit;
  if (Length(FPending) > 0) and
     (MessageDlg('Hay datos sin guardar. Cargar esta fecha reemplazar'#225' la lista actual?',
       mtConfirmation, [mbYes, mbNo], 0) <> mrYes) then Exit;
  FechaStr := lbFechas.Items[lbFechas.ItemIndex];
  if Length(FechaStr) < 10 then Exit;
  SqlFecha := Copy(FechaStr, 7, 4) + '-' + Copy(FechaStr, 4, 2) + '-' + Copy(FechaStr, 1, 2);
  lbFechas.Visible := False;
  SetLength(FPending, 0);
  Q := TFDQuery.Create(nil);
  try
    Q.Connection := FConnection;
    Q.SQL.Text := 'SELECT id, numero, nombre, diagnostico, dias_prenez, observaciones FROM palpaciones WHERE fecha = :f ORDER BY id';
    Q.Params[0].AsString := SqlFecha;
    Q.Open;
    while not Q.Eof do
    begin
      P.Id := Q.FieldByName('id').AsInteger;
      P.Numero := Q.FieldByName('numero').AsString;
      P.Nombre := Q.FieldByName('nombre').AsString;
      P.Diagnostico := Q.FieldByName('diagnostico').AsString;
      P.DiasPrenez := StrToIntDef(Q.FieldByName('dias_prenez').AsString, 0);
      P.Observaciones := Q.FieldByName('observaciones').AsString;
      SetLength(FPending, Length(FPending) + 1);
      FPending[High(FPending)] := P;
      Q.Next;
    end;
  finally
    Q.Free;
  end;
  RenderLista;
  Anio := StrToIntDef(Copy(FechaStr, 7, 4), 0);
  Mes := StrToIntDef(Copy(FechaStr, 4, 2), 0);
  Dia := StrToIntDef(Copy(FechaStr, 1, 2), 0);
  if (Anio > 0) and (Mes in [1..12]) and (Dia in [1..31]) then
    dtpFecha.Date := EncodeDate(Anio, Mes, Dia);
end;

end.
