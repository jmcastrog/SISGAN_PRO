unit UControlLeche;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes,
  Vcl.Graphics, Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.StdCtrls, Vcl.ExtCtrls, System.UITypes,
  Vcl.Grids, Vcl.ComCtrls, Data.DB, FireDAC.Comp.Client, FireDAC.Stan.Def,
  FireDAC.Stan.Pool, FireDAC.Stan.Async, FireDAC.Phys.SQLite, FireDAC.Phys.SQLiteDef,
  FireDAC.Stan.Intf, FireDAC.Phys.Intf, FireDAC.Comp.UI;

type
  TStringGridHack = class(TStringGrid);

  TPesada = record
    Id: Integer;       // 0 = nueva, >0 = existente en BD
    Numero: string;
    Nombre: string;
    Ref: Double;       // peso anterior como referencia
    PesoBruto: Double;
    Neto: Double;
  end;

  TFormControlLeche = class(TForm)
    pnlTop: TPanel;
    lblFecha: TLabel;
    dtpFecha: TDateTimePicker;
    lblTurno: TLabel;
    rbManiana: TRadioButton;
    rbTarde: TRadioButton;
    lblTobo: TLabel;
    edtTobo: TEdit;
    lbFechas: TListBox;
    pnlSearch: TPanel;
    lblBuscar: TLabel;
    edtBuscar: TEdit;
    lblPeso: TLabel;
    edtPeso: TEdit;
    lblNeto: TLabel;
    btnAgregar: TButton;
    lbSugerencias: TListBox;
    pnlClient: TPanel;
    lblCount: TLabel;
    lblTotal: TLabel;
    sgLista: TStringGrid;
    pnlBottom: TPanel;
    btnGrabar: TButton;
    btnConsultar: TButton;
    btnEliminar: TButton;
    btnLimpiar: TButton;
    btnCerrar: TButton;
    btnCargarRef: TButton;
    lblSumNeto: TLabel;
    lblPromNeto: TLabel;
    TimerSugerir: TTimer;
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure FormShow(Sender: TObject);
    procedure OnBuscarChange(Sender: TObject);
    procedure OnBuscarKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
    procedure OnSugerirTimer(Sender: TObject);
    procedure OnSugerenciaClick(Sender: TObject);
    procedure OnSugerenciaDblClick(Sender: TObject);
    procedure OnPesoChange(Sender: TObject);
    procedure OnPesoKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
    procedure OnAgregarClick(Sender: TObject);
    procedure OnGrabarClick(Sender: TObject);
    procedure OnConsultarClick(Sender: TObject);
    procedure OnEliminarClick(Sender: TObject);
    procedure OnLimpiarClick(Sender: TObject);
    procedure OnCerrarClick(Sender: TObject);
    procedure OnGridKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
    procedure OnGridSetEditText(Sender: TObject; ACol, ARow: Integer; const Value: string);
    procedure OnFechaClick(Sender: TObject);
    procedure OnCargarRefClick(Sender: TObject);
  private
    FConnection: TFDConnection;
    FAnimales: TStringList; // "numero|nombre"
    FPesadas: array of TPesada;
    FPesoTobo: Double;
    FEditando: Boolean;     // True cuando se cargan registros existentes

    procedure CarregarAnimales;
    procedure ActualizarNeto;
    function ActualizarExistente(const P: TPesada): Boolean;
    procedure RenderLista;
    function ConectarBD: Boolean;
    procedure SalvarTemporal;
    function CargarTemporal: Boolean;
    procedure EliminarTemporal;
  public
  end;

var
  FormControlLeche: TFormControlLeche;

implementation

{$R *.dfm}

procedure TFormControlLeche.FormCreate(Sender: TObject);
begin
  FPesoTobo := 0.865;
  FEditando := False;
  FAnimales := TStringList.Create;
  FAnimales.Sorted := True;
  FAnimales.Duplicates := dupIgnore;

  sgLista.Cells[0, 0] := 'N'#$00FA'mero';
  sgLista.Cells[1, 0] := 'Nombre';
  sgLista.Cells[2, 0] := 'Ref';
  sgLista.Cells[3, 0] := 'Bruto';
  sgLista.Cells[4, 0] := 'Neto';
  TStringGridHack(sgLista).DefaultRowHeight := 16;

  dtpFecha.Date := Date;
  edtTobo.Text := FloatToStr(FPesoTobo);
end;

procedure TFormControlLeche.FormDestroy(Sender: TObject);
begin
  SalvarTemporal;
  FAnimales.Free;
  FConnection.Free;
end;

procedure TFormControlLeche.FormShow(Sender: TObject);
begin
  if ConectarBD then
  begin
    CarregarAnimales;
    if CargarTemporal then
      if MessageDlg('Se encontr'#243'un borrador guardado. '#191'Cargarlo?', mtConfirmation, [mbYes, mbNo], 0) <> mrYes then
      begin
        SetLength(FPesadas, 0);
        RenderLista;
      end;
  end;
end;

function TFormControlLeche.ConectarBD: Boolean;
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

procedure TFormControlLeche.CarregarAnimales;
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

procedure TFormControlLeche.OnBuscarChange(Sender: TObject);
begin
  TimerSugerir.Enabled := False;
  TimerSugerir.Enabled := True;
end;

procedure TFormControlLeche.OnBuscarKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
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

procedure TFormControlLeche.OnSugerirTimer(Sender: TObject);
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
    if (Pos(Filtro, LowerCase(FAnimales[I])) > 0) then
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

procedure TFormControlLeche.OnSugerenciaClick(Sender: TObject);
begin
  if lbSugerencias.ItemIndex >= 0 then
  begin
    edtBuscar.Text := lbSugerencias.Items[lbSugerencias.ItemIndex];
    lbSugerencias.Visible := False;
    edtPeso.SetFocus;
  end;
end;

procedure TFormControlLeche.OnSugerenciaDblClick(Sender: TObject);
begin
  OnSugerenciaClick(Sender);
end;

procedure TFormControlLeche.OnPesoChange(Sender: TObject);
begin
  ActualizarNeto;
end;

procedure TFormControlLeche.OnPesoKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
begin
  if Key = VK_RETURN then
  begin
    OnAgregarClick(nil);
    Key := 0;
  end;
end;

procedure TFormControlLeche.ActualizarNeto;
var
  Bruto: Double;
  Tobo: Double;
begin
  Bruto := StrToFloatDef(edtPeso.Text, 0);
  Tobo := StrToFloatDef(edtTobo.Text, FPesoTobo);
  if Bruto > 0 then
    lblNeto.Caption := Format('Neto: %.3f kg', [Bruto - Tobo])
  else
    lblNeto.Caption := 'Neto: -- kg';
end;

procedure TFormControlLeche.OnAgregarClick(Sender: TObject);
var
  P: TPesada;
  PosBar: Integer;
  Bruto: Double;
begin
  if (edtBuscar.Text = '') or (Pos('|', edtBuscar.Text) = 0) then
  begin
    if lbSugerencias.Visible and (lbSugerencias.ItemIndex >= 0) then
      OnSugerenciaClick(nil)
    else
    begin
      ShowMessage('Selecciona una vaca de la lista de sugerencias.');
      edtBuscar.SetFocus;
      Exit;
    end;
  end;

  Bruto := StrToFloatDef(edtPeso.Text, 0);
  if Bruto <= 0 then
  begin
    ShowMessage('Ingresa un peso v'#$00E1'lido mayor a 0.');
    edtPeso.SetFocus;
    Exit;
  end;

  PosBar := Pos('|', edtBuscar.Text);
  P.Id := 0;
  P.Ref := 0;
  P.Numero := Copy(edtBuscar.Text, 1, PosBar - 1);
  P.Nombre := Copy(edtBuscar.Text, PosBar + 1, MaxInt);
  P.PesoBruto := Bruto;
  P.Neto := Bruto - StrToFloatDef(edtTobo.Text, FPesoTobo);
  if P.Neto < 0 then P.Neto := 0;

  // Si la vaca ya existe en la lista, actualizar sus valores
  if not ActualizarExistente(P) then
  begin
    SetLength(FPesadas, Length(FPesadas) + 1);
    FPesadas[High(FPesadas)] := P;
  end;

  edtBuscar.Text := '';
  edtPeso.Text := '';
  lblNeto.Caption := 'Neto: -- kg';
  edtBuscar.SetFocus;
  RenderLista;
end;

function TFormControlLeche.ActualizarExistente(const P: TPesada): Boolean;
var
  I: Integer;
begin
  Result := False;
  for I := 0 to High(FPesadas) do
    if FPesadas[I].Numero = P.Numero then
    begin
      FPesadas[I].PesoBruto := P.PesoBruto;
      FPesadas[I].Neto := P.Neto;
      Result := True;
      Break;
    end;
end;

procedure TFormControlLeche.RenderLista;
var
  I: Integer;
  Total: Double;
begin
  Total := 0;
  sgLista.RowCount := Length(FPesadas) + 1;
  for I := 0 to High(FPesadas) do
  begin
    sgLista.Cells[0, I + 1] := FPesadas[I].Numero;
    sgLista.Cells[1, I + 1] := FPesadas[I].Nombre;
    sgLista.Cells[2, I + 1] := Format('%.1f', [FPesadas[I].Ref]);
    sgLista.Cells[3, I + 1] := Format('%.1f', [FPesadas[I].PesoBruto]);
    sgLista.Cells[4, I + 1] := Format('%.3f', [FPesadas[I].Neto]);
    Total := Total + FPesadas[I].Neto;
  end;

  lblCount.Caption := Format('%d vacas', [Length(FPesadas)]);
  lblTotal.Caption := Format('Total: %.1f kg', [Total]);
  if Length(FPesadas) > 0 then
  begin
    lblSumNeto.Caption := Format('Neto: %.1f kg', [Total]);
    lblPromNeto.Caption := Format('Prom: %.2f kg', [Total / Length(FPesadas)]);
  end
  else
  begin
    lblSumNeto.Caption := 'Neto: 0 kg';
    lblPromNeto.Caption := 'Prom: 0 kg';
  end;
  btnGrabar.Enabled := Length(FPesadas) > 0;
  btnEliminar.Enabled := Length(FPesadas) > 0;
end;

const
  TempFile = '.control_leche_temp';

procedure TFormControlLeche.SalvarTemporal;
var
  SL: TStringList;
  I: Integer;
  Y, M, D: Word;
  TurnoStr, EditandoStr: string;
begin
  if Length(FPesadas) = 0 then Exit;
  SL := TStringList.Create;
  try
    DecodeDate(dtpFecha.Date, Y, M, D);
    if rbManiana.Checked then TurnoStr := 'M' else TurnoStr := 'T';
    if FEditando then EditandoStr := '1' else EditandoStr := '0';
    SL.Add(Format('%.4d-%.2d-%.2d', [Y, M, D]) + #9 + TurnoStr + #9 +
      edtTobo.Text + #9 + EditandoStr);
    for I := 0 to High(FPesadas) do
      SL.Add(FPesadas[I].Numero + #9 + FPesadas[I].Nombre + #9 +
        FloatToStr(FPesadas[I].Ref) + #9 +
        FloatToStr(FPesadas[I].PesoBruto) + #9 + FloatToStr(FPesadas[I].Neto));
    SL.SaveToFile(ExtractFilePath(ParamStr(0)) + TempFile);
  finally
    SL.Free;
  end;
end;

function TFormControlLeche.CargarTemporal: Boolean;
var
  SL:   TStringList;
  I: Integer;
  Flds: TStringList;
  Y, M, D: Word;
begin
  Result := False;
  if not FileExists(ExtractFilePath(ParamStr(0)) + TempFile) then Exit;
  SL := TStringList.Create;
  Flds := TStringList.Create;
  try
    Flds.Delimiter := #9;
    Flds.StrictDelimiter := True;
    SL.LoadFromFile(ExtractFilePath(ParamStr(0)) + TempFile);
    if SL.Count < 2 then Exit;
    // Primera línea: fecha, turno, tobo, FEditando
    Flds.DelimitedText := SL[0];
    if Flds.Count >= 3 then
    begin
      if Length(Flds[0]) >= 10 then
      begin
        Y := StrToIntDef(Copy(Flds[0], 1, 4), 0);
        M := StrToIntDef(Copy(Flds[0], 6, 2), 0);
        D := StrToIntDef(Copy(Flds[0], 9, 2), 0);
        if (Y > 1900) and (M in [1..12]) and (D in [1..31]) then
          dtpFecha.Date := EncodeDate(Y, M, D);
      end;
      rbManiana.Checked := Flds[1] = 'M';
      rbTarde.Checked := Flds[1] = 'T';
      edtTobo.Text := Flds[2];
      FEditando := (Flds.Count >= 4) and (Flds[3] = '1');
    end;
    SetLength(FPesadas, SL.Count - 1);
    for I := 1 to SL.Count - 1 do
    begin
      Flds.DelimitedText := SL[I];
      if Flds.Count >= 5 then
      begin
        FPesadas[I - 1].Id := 0;
        FPesadas[I - 1].Numero := Flds[0];
        FPesadas[I - 1].Nombre := Flds[1];
        FPesadas[I - 1].Ref := StrToFloatDef(Flds[2], 0);
        FPesadas[I - 1].PesoBruto := StrToFloatDef(Flds[3], 0);
        FPesadas[I - 1].Neto := StrToFloatDef(Flds[4], 0);
      end;
    end;
    RenderLista;
    Result := True;
  finally
    Flds.Free;
    SL.Free;
  end;
end;

procedure TFormControlLeche.EliminarTemporal;
var
  Fn: string;
begin
  Fn := ExtractFilePath(ParamStr(0)) + TempFile;
  if FileExists(Fn) then DeleteFile(Fn);
end;

procedure TFormControlLeche.OnLimpiarClick(Sender: TObject);
begin
  if (Length(FPesadas) > 0) and
     (MessageDlg('Seguro de descartar la lista actual?', mtConfirmation, [mbYes, mbNo], 0) <> mrYes) then Exit;
  SetLength(FPesadas, 0);
  FEditando := False;
  edtBuscar.Text := '';
  edtPeso.Text := '';
  lblNeto.Caption := 'Neto: -- kg';
  RenderLista;
  edtBuscar.SetFocus;
end;

procedure TFormControlLeche.OnFechaClick(Sender: TObject);
var
  Q: TFDQuery;
  Idx: Integer;
  FechaStr, Turno: string;
begin
  if lbFechas.ItemIndex < 0 then Exit;
  Idx := lbFechas.ItemIndex;

  FechaStr := Copy(lbFechas.Items[Idx], 1, 10);
  dtpFecha.Date := EncodeDate(
    StrToInt(Copy(FechaStr, 7, 4)),
    StrToInt(Copy(FechaStr, 4, 2)),
    StrToInt(Copy(FechaStr, 1, 2)));
  // Convertir dd-mm-yyyy a yyyy-mm-dd para la consulta SQL
  FechaStr := Copy(FechaStr, 7, 4) + '-' + Copy(FechaStr, 4, 2) + '-' + Copy(FechaStr, 1, 2);

  lbFechas.Visible := False;
  if rbManiana.Checked then Turno := 'M' else Turno := 'T';

  Q := TFDQuery.Create(nil);
  try
    Q.Connection := FConnection;
    Q.SQL.Text := 'SELECT c.id, c.numero_animal, ' +
                  '(SELECT a.nombre FROM animales a WHERE a.numero = c.numero_animal) as nombre_animal, ' +
                  'c.kg FROM control_leche c WHERE c.fecha = :f AND c.turno = :t ORDER BY c.id';
    Q.ParamByName('f').AsString := FechaStr;
    Q.ParamByName('t').AsString := Turno;
    Q.Open;

    SetLength(FPesadas, 0);
    while not Q.Eof do
    begin
      SetLength(FPesadas, Length(FPesadas) + 1);
      FPesadas[High(FPesadas)].Id := Q.FieldByName('id').AsInteger;
      FPesadas[High(FPesadas)].Numero := Q.FieldByName('numero_animal').AsString;
      FPesadas[High(FPesadas)].Nombre := Q.FieldByName('nombre_animal').AsString;
      FPesadas[High(FPesadas)].Neto := Q.FieldByName('kg').AsFloat;
      FPesadas[High(FPesadas)].PesoBruto := 0;
      FPesadas[High(FPesadas)].Ref := 0;
      Q.Next;
    end;

    if Length(FPesadas) = 0 then
      ShowMessage('No hay registros para ' + FechaStr + ' (' + Turno + ').')
    else
      ShowMessage(Format('Cargados %d registros.', [Length(FPesadas)]));

    FEditando := True;
    RenderLista;
  finally
    Q.Free;
  end;
end;

procedure TFormControlLeche.OnConsultarClick(Sender: TObject);
var
  Q: TFDQuery;
  Turno: string;
begin
  if Length(FPesadas) > 0 then
  begin
    OnGrabarClick(nil);
    if Length(FPesadas) > 0 then Exit; // user cancelled save
  end;

  if rbManiana.Checked then Turno := 'M' else Turno := 'T';

  Q := TFDQuery.Create(nil);
  try
    Q.Connection := FConnection;
    Q.SQL.Text := 'SELECT fecha, COUNT(*) as cnt FROM control_leche ' +
                  'WHERE turno = :t GROUP BY fecha ORDER BY fecha DESC';
    Q.ParamByName('t').AsString := Turno;
    Q.Open;

    lbFechas.Items.BeginUpdate;
    lbFechas.Clear;
    while not Q.Eof do
    begin
      with Q do
        lbFechas.Items.Add(
          Copy(FieldByName('fecha').AsString, 9, 2) + '-' +
          Copy(FieldByName('fecha').AsString, 6, 2) + '-' +
          Copy(FieldByName('fecha').AsString, 1, 4) +
          ' (' + FieldByName('cnt').AsString + ')');
      Q.Next;
    end;
    lbFechas.Items.EndUpdate;

    if lbFechas.Items.Count > 0 then
    begin
      lbFechas.Visible := True;
      lbFechas.BringToFront;
    end
    else
      ShowMessage('No hay registros para el turno seleccionado.');
  finally
    Q.Free;
  end;
end;

procedure TFormControlLeche.OnEliminarClick(Sender: TObject);
var
  Row: Integer;
  IdEliminar: Integer;
begin
  Row := sgLista.Row;
  if (Row < 1) or (Row > Length(FPesadas)) then Exit;

  IdEliminar := FPesadas[Row - 1].Id;

  if IdEliminar > 0 then
  begin
    if MessageDlg('Eliminar esta pesada de la BD?', mtConfirmation, [mbYes, mbNo], 0) <> mrYes then Exit;
    try
      FConnection.ExecSQL('DELETE FROM control_leche WHERE id = :id', [IdEliminar]);
    except
      on E: Exception do
      begin
        ShowMessage('Error al eliminar: ' + E.Message);
        Exit;
      end;
    end;
  end;

  // Remove from array
  if Row - 1 < High(FPesadas) then
    Move(FPesadas[Row], FPesadas[Row - 1], (High(FPesadas) - Row + 1) * SizeOf(TPesada));
  SetLength(FPesadas, Length(FPesadas) - 1);

  RenderLista;
end;

procedure TFormControlLeche.OnGridKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
begin
  if Key = VK_DELETE then
  begin
    Key := 0;
    OnEliminarClick(nil);
  end
  else if Key = VK_ESCAPE then
  begin
    // Deseleccionar
  end;
end;

procedure TFormControlLeche.OnGridSetEditText(Sender: TObject; ACol, ARow: Integer; const Value: string);
var
  Idx: Integer;
begin
  Idx := ARow - 1;
  if (Idx < 0) or (Idx >= Length(FPesadas)) then Exit;

  if ACol = 3 then // Bruto editado
  begin
    FPesadas[Idx].PesoBruto := StrToFloatDef(Value, 0);
    FPesadas[Idx].Neto := FPesadas[Idx].PesoBruto - StrToFloatDef(edtTobo.Text, FPesoTobo);
    sgLista.Cells[4, ARow] := Format('%.3f', [FPesadas[Idx].Neto]);
  end;
  if ACol = 4 then // Neto editado directamente
    FPesadas[Idx].Neto := StrToFloatDef(Value, 0);
end;

procedure TFormControlLeche.OnCerrarClick(Sender: TObject);
begin
  if (Length(FPesadas) > 0) and (MessageDlg('Hay datos sin grabar. Cerrar de todas formas?', mtConfirmation, [mbYes, mbNo], 0) <> mrYes) then Exit;
  Close;
end;

procedure TFormControlLeche.OnCargarRefClick(Sender: TObject);
var
  Q: TFDQuery;
  Turno: string;
  FechaRef: string;
  P: TPesada;
  I, Agregados: Integer;
  YaExiste: Boolean;
begin
  if not ConectarBD then Exit;
  if rbManiana.Checked then Turno := 'M' else Turno := 'T';
  Q := TFDQuery.Create(nil);
  try
    Q.Connection := FConnection;
    Q.SQL.Text := 'SELECT MAX(fecha) FROM control_leche WHERE turno = :t AND fecha < :f';
    Q.Params[0].AsString := Turno;
    Q.Params[1].AsString := FormatDateTime('yyyy-mm-dd', dtpFecha.Date);
    Q.Open;
    FechaRef := Q.Fields[0].AsString;
    if FechaRef = '' then
    begin
      ShowMessage('No hay turno anterior disponible.');
      Exit;
    end;
    Q.Close;
    Q.SQL.Text := 'SELECT c.numero_animal, ' +
                  '(SELECT a.nombre FROM animales a WHERE a.numero = c.numero_animal) as nombre_animal, ' +
                  'c.kg FROM control_leche c WHERE c.turno = :t AND c.fecha = :f ORDER BY c.id';
    Q.Params[0].AsString := Turno;
    Q.Params[1].AsString := FechaRef;
    Q.Open;
    Agregados := 0;
    while not Q.Eof do
    begin
      YaExiste := False;
      for I := 0 to High(FPesadas) do
        if FPesadas[I].Numero = Q.FieldByName('numero_animal').AsString then
        begin
          FPesadas[I].Ref := Q.FieldByName('kg').AsFloat;
          YaExiste := True;
          Break;
        end;
      if not YaExiste then
      begin
        P.Id := 0;
        P.Numero := Q.FieldByName('numero_animal').AsString;
        P.Nombre := Q.FieldByName('nombre_animal').AsString;
        P.Ref := Q.FieldByName('kg').AsFloat;
        P.PesoBruto := 0;
        P.Neto := 0;
        SetLength(FPesadas, Length(FPesadas) + 1);
        FPesadas[High(FPesadas)] := P;
        Inc(Agregados);
      end;
      Q.Next;
    end;
  finally
    Q.Free;
  end;
  FEditando := False;
  RenderLista;
  ShowMessage(Format('Agregados %d registros de referencia del %s.', [Agregados, FechaRef]));
end;

procedure TFormControlLeche.OnGrabarClick(Sender: TObject);
var
  I, Grabadas: Integer;
  Fecha, Turno: string;
begin
  if Length(FPesadas) = 0 then Exit;

  Fecha := FormatDateTime('yyyy-mm-dd', dtpFecha.Date);
  if rbManiana.Checked then Turno := 'M' else Turno := 'T';

  if MessageDlg(Format('%s %d pesadas del %s (%s)?',
    ['Grabar', Length(FPesadas), Fecha, Turno]),
    mtConfirmation, [mbYes, mbNo], 0) <> mrYes then Exit;

  btnGrabar.Enabled := False;
  btnGrabar.Caption := 'GRABANDO...';
  Grabadas := 0;

  for I := 0 to High(FPesadas) do
  begin
    try
      if FPesadas[I].Id > 0 then
        FConnection.ExecSQL(
          'UPDATE control_leche SET kg = :kg WHERE id = :id',
          [FPesadas[I].Neto, FPesadas[I].Id])
      else
        FConnection.ExecSQL(
          'INSERT OR REPLACE INTO control_leche (fecha, numero_animal, kg, turno, creado_por, creado_en) ' +
          'VALUES (:f, :n, :kg, :t, :cp, :ce)',
          [Fecha, FPesadas[I].Numero, FPesadas[I].Neto,
           Turno, 'VCL', FormatDateTime('yyyy-mm-dd hh:nn:ss', Now)]);
      Inc(Grabadas);
    except
      on E: Exception do
        ShowMessage(Format('Error en pesada #%d (%s): %s', [I + 1, FPesadas[I].Numero, E.Message]));
    end;
  end;

  if Grabadas > 0 then
  begin
    EliminarTemporal;
    ShowMessage(Format('%d pesadas grabadas correctamente.', [Grabadas]));
    SetLength(FPesadas, 0);
    OnConsultarClick(nil);
  end;

  btnGrabar.Caption := 'GRABAR';
end;


end.
