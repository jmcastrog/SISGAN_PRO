unit UConsultarAnimal;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes,
   Vcl.Graphics, Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.StdCtrls, Vcl.ExtCtrls,
   Vcl.Grids, Vcl.ComCtrls, Data.DB, FireDAC.Comp.Client, FireDAC.Stan.Def,
   FireDAC.Stan.Pool, FireDAC.Stan.Async, FireDAC.Phys.SQLite, FireDAC.Phys.SQLiteDef,
   FireDAC.Stan.Intf, FireDAC.Phys.Intf, FireDAC.Comp.UI;


type
  TFormConsultarAnimal = class(TForm)
    pnlTop: TPanel;
    lblTitulo: TLabel;
    pnlSearch: TPanel;
    lblBuscar: TLabel;
    edtBuscar: TEdit;
    lbSugerencias: TListBox;
    TimerSugerir: TTimer;
    pnlDetails: TPanel;
    PageControl1: TPageControl;
    TabGeneral: TTabSheet;
    TabProduccion: TTabSheet;
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
    lblEstatusReproEst: TLabel;
    lblFotoAnimal: TLabel;
    edtFotoAnimal: TEdit;
    btnFotoAnimal: TButton;
    lblFotoHierro: TLabel;
    edtFotoHierro: TEdit;
    btnFotoHierro: TButton;
    lblEdad: TLabel;
    edtEdad: TEdit;
    lblParto: TLabel;
    cmbSeleccionParto: TComboBox;
    sgResumenPartos: TStringGrid;
    sgTablaTIM: TStringGrid;
    sgPalpaciones: TStringGrid;
    TabServicios: TTabSheet;
    sgServicios: TStringGrid;
    pnlBottom: TPanel;
    btnEditar: TButton;
    btnCerrar: TButton;
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure OnBuscarChange(Sender: TObject);
    procedure OnBuscarKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
    procedure OnSugerirTimer(Sender: TObject);
    procedure OnSugerenciaClick(Sender: TObject);
    procedure OnSugerenciaDblClick(Sender: TObject);
    procedure cmbSeleccionPartoChange(Sender: TObject);
    procedure sgResumenPartosClick(Sender: TObject);
    procedure CargarResumenPartos(const Numero: string);
    procedure CargarPalpaciones(const Numero: string);
    procedure CargarServicios(const Numero: string);
    function CalcularProdTotalLactancia(const Numero, FechaParto, SiguienteParto: string;
      out UltimaFecha: TDateTime; out TotalKg: Double): Integer;
    procedure btnEditarClick(Sender: TObject);
    procedure btnCerrarClick(Sender: TObject);
  private
    FConnection: TFDConnection;
    FAnimales: TStringList;
    FPartos: TStringList;
    FEditando: Boolean;
    function EstimarEstatusRepro(const Numero: string): string;
    procedure CargarAnimal(const Numero: string);
    procedure CargarListaPartos(const Numero: string);
    procedure CargarTablaTIM(const Numero: string; const PartoFecha: string);
    procedure LimpiarCampos;
    procedure SetEditMode(const Editando: Boolean);
  public
    procedure CargarAnimales;
    property DBConnection: TFDConnection read FConnection write FConnection;
  public
    procedure CargarPorNumero(const Numero: string);
  end;

var
  FormConsultarAnimal: TFormConsultarAnimal;

implementation

{$R *.dfm}

uses System.DateUtils;

procedure TFormConsultarAnimal.FormCreate(Sender: TObject);
begin
  FEditando := False;
  FAnimales := TStringList.Create;
  FAnimales.Sorted := True;
  FAnimales.Duplicates := dupIgnore;
  FPartos := TStringList.Create;
  cmbSexo.ItemIndex := 0;
  cmbTipo.ItemIndex := 0;
  cmbEstatusRepro.ItemIndex := 0;
  cmbEstatus.ItemIndex := 0;
  dtpFechaNac.DateTime := Date;
  dtpFechaPartoEst.DateTime := Date;

  sgTablaTIM.DefaultColWidth := 48;
  sgTablaTIM.DefaultRowHeight := 16;
  sgTablaTIM.ColWidths[0] := 35;
  sgTablaTIM.Font.Size := 7;
  sgTablaTIM.Height := (sgTablaTIM.RowCount * sgTablaTIM.DefaultRowHeight) + 22;
  sgTablaTIM.Cells[0, 0] := 'Fecha';
  sgTablaTIM.Cells[0, 1] := 'D'#237'as';
  sgTablaTIM.Cells[0, 2] := 'Int.';
  sgTablaTIM.Cells[0, 3] := 'Kg/d'#237'a';
  sgTablaTIM.Cells[0, 4] := 'Acum.';
end;

procedure TFormConsultarAnimal.FormDestroy(Sender: TObject);
begin
  FAnimales.Free;
  FPartos.Free;
end;

procedure TFormConsultarAnimal.CargarAnimales;
var
  Q: TFDQuery;
begin
  FAnimales.Clear;
  Q := TFDQuery.Create(nil);
  try
    Q.Connection := FConnection;
    Q.SQL.Text := 'SELECT numero, nombre FROM animales ORDER BY numero';
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

procedure TFormConsultarAnimal.OnBuscarChange(Sender: TObject);
begin
  TimerSugerir.Enabled := False;
  TimerSugerir.Enabled := True;
end;

procedure TFormConsultarAnimal.OnBuscarKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
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
    lbSugerencias.Visible := False
  else if Key = VK_RETURN then
  begin
    if lbSugerencias.Visible and (lbSugerencias.ItemIndex >= 0) then
      OnSugerenciaClick(nil);
  end;
end;

procedure TFormConsultarAnimal.OnSugerirTimer(Sender: TObject);
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

procedure TFormConsultarAnimal.OnSugerenciaClick(Sender: TObject);
var
  Numero: string;
  PosBar: Integer;
begin
  if lbSugerencias.ItemIndex < 0 then Exit;
  PosBar := Pos('|', lbSugerencias.Items[lbSugerencias.ItemIndex]);
  Numero := Copy(lbSugerencias.Items[lbSugerencias.ItemIndex], 1, PosBar - 1);
  lbSugerencias.Visible := False;
  CargarAnimal(Numero);
end;

procedure TFormConsultarAnimal.OnSugerenciaDblClick(Sender: TObject);
begin
  OnSugerenciaClick(Sender);
end;

procedure TFormConsultarAnimal.LimpiarCampos;
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
  lblEstatusRepro.Caption := 'Est. Repro:';
  lblEstatusReproEst.Caption := '';
  edtFotoAnimal.Text := '';
  edtFotoHierro.Text := '';
  edtEdad.Text := '';
  cmbSeleccionParto.Clear;
  FPartos.Clear;
  lblParto.Caption := 'Parto:';
  sgTablaTIM.ColCount := 2;
  sgTablaTIM.RowCount := 5;
  sgTablaTIM.Cells[1, 0] := '';
  sgTablaTIM.Cells[1, 1] := '';
  sgTablaTIM.Cells[1, 2] := '';
  sgTablaTIM.Cells[1, 3] := '';
  sgTablaTIM.Cells[1, 4] := '';
  sgResumenPartos.RowCount := 2;
  sgResumenPartos.Cells[0, 1] := '';
  sgResumenPartos.Cells[1, 1] := '';
  sgResumenPartos.Cells[2, 1] := '';
  sgResumenPartos.Cells[3, 1] := '';
  sgResumenPartos.Cells[4, 1] := '';
  sgResumenPartos.Cells[5, 1] := '';
  sgResumenPartos.Cells[6, 1] := '';
  sgPalpaciones.RowCount := 2;
  sgPalpaciones.Cells[0, 1] := '';
  sgPalpaciones.Cells[1, 1] := '';
  sgPalpaciones.Cells[2, 1] := '';
  sgPalpaciones.Cells[3, 1] := '';
  sgPalpaciones.Cells[4, 1] := '';
  sgServicios.RowCount := 2;
  sgServicios.Cells[0, 1] := '';
  sgServicios.Cells[1, 1] := '';
  sgServicios.Cells[2, 1] := '';
  sgServicios.Cells[3, 1] := '';
  sgServicios.Cells[4, 1] := '';
end;

procedure TFormConsultarAnimal.SetEditMode(const Editando: Boolean);
begin
  FEditando := Editando;
  edtNombre.ReadOnly := not Editando;
  edtRaza.ReadOnly := not Editando;
  cmbSexo.Enabled := Editando;
  cmbTipo.Enabled := Editando;
  edtLote.ReadOnly := not Editando;
  edtPropietario.ReadOnly := not Editando;
  edtNumMadre.ReadOnly := not Editando;
  edtNomMadre.ReadOnly := not Editando;
  edtPadre.ReadOnly := not Editando;
  edtPesoNacer.ReadOnly := not Editando;
  cmbEstatusRepro.Enabled := Editando;
  dtpFechaNac.Enabled := Editando;
  dtpFechaPartoEst.Enabled := Editando;
  cmbEstatus.Enabled := Editando;
  memComentarios.ReadOnly := not Editando;
  edtFotoAnimal.ReadOnly := not Editando;
  edtFotoHierro.ReadOnly := not Editando;
  btnFotoAnimal.Enabled := Editando;
  btnFotoHierro.Enabled := Editando;

  if Editando then
  begin
    btnEditar.Caption := 'GUARDAR';
    btnEditar.Font.Style := [fsBold];
  end
  else
  begin
    btnEditar.Caption := 'EDITAR';
    btnEditar.Font.Style := [fsBold];
  end;
end;

procedure TFormConsultarAnimal.CargarAnimal(const Numero: string);
var
  Q: TFDQuery;
begin
  Q := TFDQuery.Create(nil);
  try
    Q.Connection := FConnection;
    Q.SQL.Text := 'SELECT * FROM animales WHERE numero = :num';
    Q.ParamByName('num').AsString := Numero;
    Q.Open;

    if Q.IsEmpty then
    begin
      ShowMessage('Animal no encontrado: ' + Numero);
      Exit;
    end;

    LimpiarCampos;

    edtNumero.Text := Q.FieldByName('numero').AsString;
    edtNombre.Text := Q.FieldByName('nombre').AsString;
    edtRaza.Text := Q.FieldByName('raza').AsString;
    edtLote.Text := Q.FieldByName('lote').AsString;
    edtPropietario.Text := Q.FieldByName('propietario').AsString;
    edtNumMadre.Text := Q.FieldByName('num_madre').AsString;
    edtNomMadre.Text := Q.FieldByName('nom_madre').AsString;
    edtPadre.Text := Q.FieldByName('padre').AsString;
    edtPesoNacer.Text := Q.FieldByName('peso_nacer').AsString;
    edtFotoAnimal.Text := Q.FieldByName('foto_animal').AsString;
    edtFotoHierro.Text := Q.FieldByName('foto_hierro').AsString;
    memComentarios.Text := Q.FieldByName('comentarios').AsString;

    if Q.FieldByName('fecha_nac').AsString <> '' then
      dtpFechaNac.Date := StrToDateDef(Q.FieldByName('fecha_nac').AsString, Date);

    if Q.FieldByName('fecha_parto_est').AsString <> '' then
      dtpFechaPartoEst.Date := StrToDateDef(Q.FieldByName('fecha_parto_est').AsString, Date);

    cmbSexo.ItemIndex := cmbSexo.Items.IndexOf(Q.FieldByName('sexo').AsString);
    if cmbSexo.ItemIndex < 0 then cmbSexo.ItemIndex := 0;

    cmbTipo.ItemIndex := cmbTipo.Items.IndexOf(Q.FieldByName('tipo').AsString);
    if cmbTipo.ItemIndex < 0 then cmbTipo.ItemIndex := 0;

    cmbEstatusRepro.ItemIndex := cmbEstatusRepro.Items.IndexOf(Q.FieldByName('estatus_repro').AsString);
    if cmbEstatusRepro.ItemIndex < 0 then cmbEstatusRepro.ItemIndex := 0;

    cmbEstatus.ItemIndex := cmbEstatus.Items.IndexOf(Q.FieldByName('estatus').AsString);
    if cmbEstatus.ItemIndex < 0 then cmbEstatus.ItemIndex := 0;

    EstimarEstatusRepro(Numero);

    // Calcular edad
    if Q.FieldByName('fecha_nac').AsString <> '' then
    begin
      try
        var FecNac: TDateTime := StrToDate(Q.FieldByName('fecha_nac').AsString);
        var Dias := Trunc(Date - FecNac);
        var Anios := Dias div 365;
        var Meses := (Dias mod 365) div 30;
        edtEdad.Text := IntToStr(Anios) + ' a' + #164 + 'o(s), ' + IntToStr(Meses) + ' mes(es)';
      except
        edtEdad.Text := '';
      end;
    end;

    lblTitulo.Caption := 'Animal: ' + edtNumero.Text + ' - ' + edtNombre.Text;
    edtBuscar.Text := edtNumero.Text + ' - ' + edtNombre.Text;
    SetEditMode(False);
    CargarListaPartos(Numero);
    CargarResumenPartos(Numero);
    CargarPalpaciones(Numero);
    CargarServicios(Numero);
    if cmbSeleccionParto.Items.Count > 0 then
    begin
      cmbSeleccionParto.ItemIndex := 0;
      CargarTablaTIM(Numero, FPartos[0]);
    end;
  finally
    Q.Free;
  end;
end;

function TFormConsultarAnimal.EstimarEstatusRepro(const Numero: string): string;
var
  Q: TFDQuery;
  UltParto, Diag, ServFecha: string;
  DiasUltParto, DiasPrenez: Integer;
  FechaP, FecDiag, FecServ: TDateTime;
  Gestacion: Integer;
begin
  Gestacion := 283; // días gestación bovino
  Result := '';
  DiasPrenez := 0;

  // Último parto
  Q := TFDQuery.Create(nil);
  try
    Q.Connection := FConnection;
    Q.SQL.Text := 'SELECT MAX(fecha) as fp FROM partos WHERE num_madre = :num';
    Q.ParamByName('num').AsString := Numero;
    Q.Open;
    if not (Q.IsEmpty or Q.FieldByName('fp').IsNull) then
      UltParto := Q.FieldByName('fp').AsString;
  finally
    Q.Free;
  end;

  if UltParto <> '' then
    DiasUltParto := Trunc(Date - StrToDateDef(UltParto, Date))
  else
    DiasUltParto := 9999;

  // Último servicio
  Q := TFDQuery.Create(nil);
  try
    Q.Connection := FConnection;
    Q.SQL.Text := 'SELECT fecha FROM servicios WHERE numero = :num ORDER BY fecha DESC LIMIT 1';
    Q.ParamByName('num').AsString := Numero;
    Q.Open;
    if not (Q.IsEmpty or Q.FieldByName('fecha').IsNull) then
      ServFecha := Q.FieldByName('fecha').AsString;
  finally
    Q.Free;
  end;

  // Última palpación
  Q := TFDQuery.Create(nil);
  try
    Q.Connection := FConnection;
    Q.SQL.Text := 'SELECT fecha, diagnostico, dias_prenez FROM palpaciones WHERE numero = :num ORDER BY fecha DESC LIMIT 1';
    Q.ParamByName('num').AsString := Numero;
    Q.Open;
    if not (Q.IsEmpty or Q.FieldByName('diagnostico').IsNull) then
    begin
      Diag := Q.FieldByName('diagnostico').AsString;
      DiasPrenez := Q.FieldByName('dias_prenez').AsInteger;
    end;
  finally
    Q.Free;
  end;

  // Guardar fecha_palp antes de que se libere Q
  var FechaPalp := '';
  if Diag <> '' then
  begin
    Q := TFDQuery.Create(nil);
    try
      Q.Connection := FConnection;
      Q.SQL.Text := 'SELECT fecha FROM palpaciones WHERE numero = :num ORDER BY fecha DESC LIMIT 1';
      Q.ParamByName('num').AsString := Numero;
      Q.Open;
      if not (Q.IsEmpty or Q.FieldByName('fecha').IsNull) then
        FechaPalp := Q.FieldByName('fecha').AsString;
    finally
      Q.Free;
    end;
  end;

  // ---- Lógica de estimación ----
  if Pos('Pre'#241'ada', Diag) > 0 then
  begin
    // 1. Con días de preñez → fecha_palp + (283 - dias_prenez)
    if (DiasPrenez > 0) and TryStrToDate(FechaPalp, FecDiag) then
    begin
      FechaP := FecDiag + (Gestacion - DiasPrenez);
      dtpFechaPartoEst.DateTime := FechaP;
      lblEstatusReproEst.Caption := 'Pre'#241'ada, Parto: ' +
          FormatDateTime('dd/mm/yy', FechaP);
    end
    else
      // 2. Sin días de preñez, usar último servicio si existe
      if (ServFecha <> '') and TryStrToDate(ServFecha, FecServ) then
      begin
        FechaP := FecServ + Gestacion;
        dtpFechaPartoEst.DateTime := FechaP;
        lblEstatusReproEst.Caption := 'Pre'#241'ada, Parto: ' +
          FormatDateTime('dd/mm/yy', FechaP);
      end
      else
        lblEstatusReproEst.Caption := 'Pre'#241'ada';
    Exit('Pre'#241'ada');
  end;

  // Vacía según palpación
  if (Pos('VACIA', UpperCase(Diag)) > 0) or (Pos('VOL', UpperCase(Diag)) > 0)
    or (Pos('VCLOD', UpperCase(Diag)) > 0) then
  begin
    if DiasUltParto > 60 then
    begin
      lblEstatusReproEst.Caption := 'Vac'#237'a';
      Exit('Vac'#237'a');
    end
    else
    begin
      lblEstatusReproEst.Caption := 'En Lactancia';
      Exit('En Lactancia');
    end;
  end;

  // Servida: hay servicio reciente sin palpación o sin diagnóstico claro
  if (ServFecha <> '') and TryStrToDate(ServFecha, FecServ) then
  begin
    var DiasServ := Trunc(Date - FecServ);
    if (DiasServ > 21) and (DiasUltParto > 60) then
    begin
      FechaP := FecServ + Gestacion;
      dtpFechaPartoEst.DateTime := FechaP;
      lblEstatusReproEst.Caption := 'Servida, Parto: ' +
        FormatDateTime('dd/mm/yy', FechaP);
      Exit('Servida');
    end;
  end;

  // Por defecto según días desde último parto
  if DiasUltParto > 305 then
  begin
    lblEstatusReproEst.Caption := 'Vac'#237'a';
    Exit('Vac'#237'a');
  end;
  if DiasUltParto > 60 then
  begin
    lblEstatusReproEst.Caption := 'Vac'#237'a';
    Exit('Vac'#237'a');
  end;
  lblEstatusReproEst.Caption := 'En Lactancia';
  Result := 'En Lactancia';
end;

procedure TFormConsultarAnimal.CargarListaPartos(const Numero: string);
var
  Q: TFDQuery;
  FechaISO, FechaFmt: string;
begin
  cmbSeleccionParto.Clear;
  FPartos.Clear;
  Q := TFDQuery.Create(nil);
  try
    Q.Connection := FConnection;
    Q.SQL.Text := 'SELECT fecha FROM partos WHERE num_madre = :num ORDER BY fecha DESC';
    Q.ParamByName('num').AsString := Numero;
    Q.Open;
    while not Q.Eof do
    begin
      FechaISO := Q.FieldByName('fecha').AsString;
      FPartos.Add(FechaISO);
      if Length(FechaISO) >= 10 then
        FechaFmt := Copy(FechaISO, 9, 2) + '/' + Copy(FechaISO, 6, 2) + '/' + Copy(FechaISO, 3, 2)
      else
        FechaFmt := FechaISO;
      cmbSeleccionParto.Items.Add(FechaFmt);
      Q.Next;
    end;
  finally
    Q.Free;
  end;
  if cmbSeleccionParto.Items.Count > 0 then
    lblParto.Caption := 'Parto:'
  else
    lblParto.Caption := 'Sin partos registrados';
end;

procedure TFormConsultarAnimal.CargarTablaTIM(const Numero: string; const PartoFecha: string);
var
  Q: TFDQuery;
  FechParto, FecPesada, FechaAntDT: TDateTime;
  DiasLact, Intervalo, Col: Integer;
  Acumulado, KgDia: Double;
begin
  sgTablaTIM.ColCount := 2;
  sgTablaTIM.RowCount := 5;

  if PartoFecha = '' then
  begin
    sgTablaTIM.Cells[1, 0] := 'Sin parto';
    Exit;
  end;
  FechParto := StrToDateDef(PartoFecha, 0);
  if FechParto = 0 then
  begin
    // Manual parse yyyy-MM-dd
    var a, m, d: Word;
    a := StrToIntDef(Copy(PartoFecha, 1, 4), 0);
    m := StrToIntDef(Copy(PartoFecha, 6, 2), 0);
    d := StrToIntDef(Copy(PartoFecha, 9, 2), 0);
    if (a > 0) and (m in [1..12]) and (d in [1..31]) then
      FechParto := EncodeDate(a, m, d)
    else
    begin
      sgTablaTIM.Cells[1, 0] := 'Fecha inv'#225'lida';
      Exit;
    end;
  end;

  // Find next parto date (to limit the lactation period)
  var FecPartoStr := FormatDateTime('yyyy-mm-dd', FechParto);
  var SiguienteParto := '';
  Q := TFDQuery.Create(nil);
  try
    Q.Connection := FConnection;
    Q.SQL.Text := 'SELECT MIN(fecha) as sig FROM partos WHERE num_madre = :num AND fecha > :parto';
    Q.ParamByName('num').AsString := Numero;
    Q.ParamByName('parto').AsString := FecPartoStr;
    Q.Open;
    if not (Q.IsEmpty or Q.FieldByName('sig').IsNull) then
      SiguienteParto := Q.FieldByName('sig').AsString;
  finally
    Q.Free;
  end;

  Col := 1;
  Acumulado := 0;
  FechaAntDT := FechParto;
  Q := TFDQuery.Create(nil);
  try
    Q.Connection := FConnection;
    if SiguienteParto <> '' then
      Q.SQL.Text := 'SELECT fecha, SUM(kg) as total FROM control_leche WHERE numero_animal = :num AND fecha >= :p AND fecha < :sig GROUP BY fecha ORDER BY fecha'
    else
      Q.SQL.Text := 'SELECT fecha, SUM(kg) as total FROM control_leche WHERE numero_animal = :num AND fecha >= :p GROUP BY fecha ORDER BY fecha';
    Q.ParamByName('num').AsString := Numero;
    Q.ParamByName('p').AsString := FecPartoStr;
    if SiguienteParto <> '' then
      Q.ParamByName('sig').AsString := SiguienteParto;
    Q.Open;
    while not Q.Eof do
    begin
      var sFecha := Q.FieldByName('fecha').AsString;
      if Length(sFecha) >= 10 then
        FecPesada := EncodeDate(StrToIntDef(Copy(sFecha, 1, 4), 0),
                                StrToIntDef(Copy(sFecha, 6, 2), 0),
                                StrToIntDef(Copy(sFecha, 9, 2), 0))
      else
        FecPesada := 0;
      if FecPesada > 0 then
      begin
        DiasLact := Trunc(FecPesada - FechParto);
        if DiasLact >= 0 then
        begin
          if Col >= sgTablaTIM.ColCount then
            sgTablaTIM.ColCount := Col + 1;
          var sFechaFmt := sFecha;
          if Length(sFechaFmt) >= 10 then
            sFechaFmt := Copy(sFechaFmt, 9, 2) + '/' + Copy(sFechaFmt, 6, 2) + '/' + Copy(sFechaFmt, 3, 2);
          sgTablaTIM.Cells[Col, 0] := sFechaFmt;
          sgTablaTIM.Cells[Col, 1] := IntToStr(DiasLact);
          Intervalo := Trunc(FecPesada - FechaAntDT);
          sgTablaTIM.Cells[Col, 2] := IntToStr(Intervalo);
          KgDia := Q.FieldByName('total').AsFloat;
          sgTablaTIM.Cells[Col, 3] := FormatFloat('#,##0.000', KgDia);
          Acumulado := Acumulado + (KgDia * Intervalo);
          sgTablaTIM.Cells[Col, 4] := FormatFloat('#,##0.0', Acumulado);
          FechaAntDT := FecPesada;
          Inc(Col);
        end;
      end;
      Q.Next;
    end;
  finally
    Q.Free;
  end;
end;

function TFormConsultarAnimal.CalcularProdTotalLactancia(const Numero, FechaParto, SiguienteParto: string;
  out UltimaFecha: TDateTime; out TotalKg: Double): Integer;
var
  Q: TFDQuery;
  FecParto, FecPesada, FechaAntDT: TDateTime;
  DiasLact, Intervalo: Integer;
  KgDia: Double;
begin
  TotalKg := 0;
  UltimaFecha := 0;
  Result := 0;
  FecParto := EncodeDate(StrToIntDef(Copy(FechaParto, 1, 4), 0),
                         StrToIntDef(Copy(FechaParto, 6, 2), 0),
                         StrToIntDef(Copy(FechaParto, 9, 2), 0));
  if FecParto <= 0 then Exit;
  FechaAntDT := FecParto;
  Q := TFDQuery.Create(nil);
  try
    Q.Connection := FConnection;
    if SiguienteParto <> '' then
      Q.SQL.Text := 'SELECT fecha, SUM(kg) as total FROM control_leche WHERE numero_animal = :num AND fecha >= :p AND fecha < :sig GROUP BY fecha ORDER BY fecha'
    else
      Q.SQL.Text := 'SELECT fecha, SUM(kg) as total FROM control_leche WHERE numero_animal = :num AND fecha >= :p GROUP BY fecha ORDER BY fecha';
    Q.ParamByName('num').AsString := Numero;
    Q.ParamByName('p').AsString := FechaParto;
    if SiguienteParto <> '' then
      Q.ParamByName('sig').AsString := SiguienteParto;
    Q.Open;
    while not Q.Eof do
    begin
      var sFecha := Q.FieldByName('fecha').AsString;
      if Length(sFecha) >= 10 then
        FecPesada := EncodeDate(StrToIntDef(Copy(sFecha, 1, 4), 0),
                                StrToIntDef(Copy(sFecha, 6, 2), 0),
                                StrToIntDef(Copy(sFecha, 9, 2), 0))
      else
        FecPesada := 0;
      if FecPesada > 0 then
      begin
        DiasLact := Trunc(FecPesada - FecParto);
        if DiasLact >= 0 then
        begin
          Intervalo := Trunc(FecPesada - FechaAntDT);
          KgDia := Q.FieldByName('total').AsFloat;
          TotalKg := TotalKg + (KgDia * Intervalo);
          FechaAntDT := FecPesada;
          UltimaFecha := FecPesada;
        end;
      end;
      Q.Next;
    end;
  finally
    Q.Free;
  end;
  if UltimaFecha > FecParto then
    Result := Trunc(UltimaFecha - FecParto);
end;

procedure TFormConsultarAnimal.CargarResumenPartos(const Numero: string);
var
  Q: TFDQuery;
  FechaISO, FechaFmt, Sexo, Siguiente, sCelo: string;
  I: Integer;
  TotalKg: Double;
  UltimaFecha: TDateTime;
  DurLact: Integer;
begin
  sgResumenPartos.RowCount := 2;
  sgResumenPartos.FixedRows := 1;
  sgResumenPartos.ColCount := 7;
  sgResumenPartos.Cells[0, 0] := '#';
  sgResumenPartos.Cells[1, 0] := 'Fecha';
  sgResumenPartos.Cells[2, 0] := 'Sexo';
  sgResumenPartos.Cells[3, 0] := 'Dur. Lact.';
  sgResumenPartos.Cells[4, 0] := '1er Celo (d)';
  sgResumenPartos.Cells[5, 0] := 'Int. Partos';
  sgResumenPartos.Cells[6, 0] := 'Prod. Total';
  sgResumenPartos.ColWidths[0] := 25;
  sgResumenPartos.ColWidths[1] := 80;
  sgResumenPartos.ColWidths[2] := 60;
  sgResumenPartos.ColWidths[3] := 70;
  sgResumenPartos.ColWidths[4] := 75;
  sgResumenPartos.ColWidths[5] := 75;
  sgResumenPartos.ColWidths[6] := 110;

  if FPartos.Count = 0 then
  begin
    sgResumenPartos.RowCount := 2;
    sgResumenPartos.Cells[0, 1] := '';
    Exit;
  end;

  sgResumenPartos.RowCount := FPartos.Count + 1;
  for I := 0 to FPartos.Count - 1 do
  begin
    FechaISO := FPartos[I];
    if Length(FechaISO) >= 10 then
      FechaFmt := Copy(FechaISO, 9, 2) + '/' + Copy(FechaISO, 6, 2) + '/' + Copy(FechaISO, 3, 2)
    else
      FechaFmt := FechaISO;

    sgResumenPartos.Cells[0, I + 1] := IntToStr(I + 1);
    sgResumenPartos.Cells[1, I + 1] := FechaFmt;

    // Query sexo
    Q := TFDQuery.Create(nil);
    try
      Q.Connection := FConnection;
      Q.SQL.Text := 'SELECT sexo FROM partos WHERE num_madre = :num AND fecha = :fec';
      Q.ParamByName('num').AsString := Numero;
      Q.ParamByName('fec').AsString := FechaISO;
      Q.Open;
      if not (Q.IsEmpty or Q.FieldByName('sexo').IsNull) then
      begin
        Sexo := Q.FieldByName('sexo').AsString;
        if Sexo = 'M' then sgResumenPartos.Cells[2, I + 1] := 'Macho'
        else if Sexo = 'H' then sgResumenPartos.Cells[2, I + 1] := 'Hembra'
        else sgResumenPartos.Cells[2, I + 1] := Sexo;
      end
      else
        sgResumenPartos.Cells[2, I + 1] := '--';
    finally
      Q.Free;
    end;

    // Find next parto
    Siguiente := '';
    Q := TFDQuery.Create(nil);
    try
      Q.Connection := FConnection;
      Q.SQL.Text := 'SELECT MIN(fecha) as sig FROM partos WHERE num_madre = :num AND fecha > :fec';
      Q.ParamByName('num').AsString := Numero;
      Q.ParamByName('fec').AsString := FechaISO;
      Q.Open;
      if not (Q.IsEmpty or Q.FieldByName('sig').IsNull) then
        Siguiente := Q.FieldByName('sig').AsString;
    finally
      Q.Free;
    end;

    // Lactation duration and total production
    DurLact := CalcularProdTotalLactancia(Numero, FechaISO, Siguiente, UltimaFecha, TotalKg);
    if DurLact > 0 then
      sgResumenPartos.Cells[3, I + 1] := IntToStr(DurLact) + ' d'
    else
      sgResumenPartos.Cells[3, I + 1] := '--';

    sgResumenPartos.Cells[6, I + 1] := FormatFloat('#,##0.0', TotalKg);

    // First post-partum service (days from parto)
    Q := TFDQuery.Create(nil);
    try
      Q.Connection := FConnection;
      Q.SQL.Text := 'SELECT MIN(fecha) as celo FROM servicios WHERE numero = :num AND fecha > :fec';
      Q.ParamByName('num').AsString := Numero;
      Q.ParamByName('fec').AsString := FechaISO;
      Q.Open;
      if not (Q.IsEmpty or Q.FieldByName('celo').IsNull) then
      begin
        sCelo := Q.FieldByName('celo').AsString;
        if Length(sCelo) >= 10 then
        begin
          var a, m, d, a2, m2, d2: Word;
          a := StrToIntDef(Copy(FechaISO, 1, 4), 0);
          m := StrToIntDef(Copy(FechaISO, 6, 2), 0);
          d := StrToIntDef(Copy(FechaISO, 9, 2), 0);
          a2 := StrToIntDef(Copy(sCelo, 1, 4), 0);
          m2 := StrToIntDef(Copy(sCelo, 6, 2), 0);
          d2 := StrToIntDef(Copy(sCelo, 9, 2), 0);
          var FecPartoDT := EncodeDate(a, m, d);
          var FecCeloDT := EncodeDate(a2, m2, d2);
          var DiasCelo := Trunc(FecCeloDT - FecPartoDT);
          sgResumenPartos.Cells[4, I + 1] := IntToStr(DiasCelo) + ' d';
        end
        else
          sgResumenPartos.Cells[4, I + 1] := sCelo;
      end
      else
        sgResumenPartos.Cells[4, I + 1] := '--';
    finally
      Q.Free;
    end;

    // Interval between partos (days to previous/older parto)
    if I + 1 < FPartos.Count then
    begin
      var FechaAnt := FPartos[I + 1];
      if (Length(FechaISO) >= 10) and (Length(FechaAnt) >= 10) then
      begin
        var a1, m1, d1, a2, m2, d2: Word;
        a1 := StrToIntDef(Copy(FechaISO, 1, 4), 0);
        m1 := StrToIntDef(Copy(FechaISO, 6, 2), 0);
        d1 := StrToIntDef(Copy(FechaISO, 9, 2), 0);
        a2 := StrToIntDef(Copy(FechaAnt, 1, 4), 0);
        m2 := StrToIntDef(Copy(FechaAnt, 6, 2), 0);
        d2 := StrToIntDef(Copy(FechaAnt, 9, 2), 0);
        var FecActual := EncodeDate(a1, m1, d1);
        var FecAnterior := EncodeDate(a2, m2, d2);
        var DiasInt := Trunc(FecActual - FecAnterior);
        sgResumenPartos.Cells[5, I + 1] := IntToStr(DiasInt) + ' d';
      end
      else
        sgResumenPartos.Cells[5, I + 1] := '--';
    end
    else
      sgResumenPartos.Cells[5, I + 1] := '--';
  end;
  sgResumenPartos.Height := (sgResumenPartos.RowCount * sgResumenPartos.DefaultRowHeight) + 22;
end;

procedure TFormConsultarAnimal.CargarPalpaciones(const Numero: string);
var
  Q: TFDQuery;
  FechaFmt: string;
  Row: Integer;
begin
  sgPalpaciones.RowCount := 2;
  sgPalpaciones.FixedRows := 1;
  sgPalpaciones.ColCount := 5;
  sgPalpaciones.Cells[0, 0] := 'Fecha';
  sgPalpaciones.Cells[1, 0] := 'Diagn'#243'stico';
  sgPalpaciones.Cells[2, 0] := 'D'#237'as Pre'#241'ez';
  sgPalpaciones.Cells[3, 0] := 'Observaciones';
  sgPalpaciones.Cells[4, 0] := 'T'#233'cnico';
  sgPalpaciones.ColWidths[0] := 90;
  sgPalpaciones.ColWidths[1] := 120;
  sgPalpaciones.ColWidths[2] := 90;
  sgPalpaciones.ColWidths[3] := 200;
  sgPalpaciones.ColWidths[4] := 100;

  Q := TFDQuery.Create(nil);
  try
    Q.Connection := FConnection;
    Q.SQL.Text := 'SELECT fecha, diagnostico, dias_prenez, observaciones, tecnico ' +
      'FROM palpaciones WHERE numero = :num ORDER BY fecha DESC';
    Q.ParamByName('num').AsString := Numero;
    Q.Open;
    if Q.IsEmpty then
    begin
      sgPalpaciones.RowCount := 2;
      sgPalpaciones.Cells[0, 1] := 'Sin registros';
      Exit;
    end;
    sgPalpaciones.RowCount := Q.RecordCount + 1;
    Row := 1;
    while not Q.Eof do
    begin
      var sFecha := Q.FieldByName('fecha').AsString;
      if Length(sFecha) >= 10 then
        FechaFmt := Copy(sFecha, 9, 2) + '/' + Copy(sFecha, 6, 2) + '/' + Copy(sFecha, 3, 2)
      else
        FechaFmt := sFecha;
      sgPalpaciones.Cells[0, Row] := FechaFmt;
      sgPalpaciones.Cells[1, Row] := Q.FieldByName('diagnostico').AsString;
      sgPalpaciones.Cells[2, Row] := Q.FieldByName('dias_prenez').AsString;
      sgPalpaciones.Cells[3, Row] := Q.FieldByName('observaciones').AsString;
      sgPalpaciones.Cells[4, Row] := Q.FieldByName('tecnico').AsString;
      Inc(Row);
      Q.Next;
    end;
  finally
    Q.Free;
  end;
  sgPalpaciones.Height := (sgPalpaciones.RowCount * sgPalpaciones.DefaultRowHeight) + 22;
end;

procedure TFormConsultarAnimal.CargarServicios(const Numero: string);
var
  Q: TFDQuery;
  FechaFmt: string;
  Row: Integer;
begin
  sgServicios.RowCount := 2;
  sgServicios.FixedRows := 1;
  sgServicios.ColCount := 5;
  sgServicios.Cells[0, 0] := 'Fecha';
  sgServicios.Cells[1, 0] := 'Tipo';
  sgServicios.Cells[2, 0] := 'Toro';
  sgServicios.Cells[3, 0] := 'Raza Toro';
  sgServicios.Cells[4, 0] := 'Creado Por';
  sgServicios.ColWidths[0] := 90;
  sgServicios.ColWidths[1] := 100;
  sgServicios.ColWidths[2] := 120;
  sgServicios.ColWidths[3] := 120;
  sgServicios.ColWidths[4] := 100;

  Q := TFDQuery.Create(nil);
  try
    Q.Connection := FConnection;
    Q.SQL.Text := 'SELECT fecha, tipo, toro, raza_toro, creado_por ' +
      'FROM servicios WHERE numero = :num ORDER BY fecha DESC';
    Q.ParamByName('num').AsString := Numero;
    Q.Open;
    if Q.IsEmpty then
    begin
      sgServicios.RowCount := 2;
      sgServicios.Cells[0, 1] := 'Sin registros';
      Exit;
    end;
    sgServicios.RowCount := Q.RecordCount + 1;
    Row := 1;
    while not Q.Eof do
    begin
      var sFecha := Q.FieldByName('fecha').AsString;
      if Length(sFecha) >= 10 then
        FechaFmt := Copy(sFecha, 9, 2) + '/' + Copy(sFecha, 6, 2) + '/' + Copy(sFecha, 3, 2)
      else
        FechaFmt := sFecha;
      sgServicios.Cells[0, Row] := FechaFmt;
      sgServicios.Cells[1, Row] := Q.FieldByName('tipo').AsString;
      sgServicios.Cells[2, Row] := Q.FieldByName('toro').AsString;
      sgServicios.Cells[3, Row] := Q.FieldByName('raza_toro').AsString;
      sgServicios.Cells[4, Row] := Q.FieldByName('creado_por').AsString;
      Inc(Row);
      Q.Next;
    end;
  finally
    Q.Free;
  end;
end;

procedure TFormConsultarAnimal.sgResumenPartosClick(Sender: TObject);
var
  Idx: Integer;
begin
  Idx := sgResumenPartos.Row - 1; // Row 0 = header
  if (Idx >= 0) and (Idx < cmbSeleccionParto.Items.Count) then
  begin
    cmbSeleccionParto.ItemIndex := Idx;
    CargarTablaTIM(Trim(edtNumero.Text), FPartos[Idx]);
  end;
end;

procedure TFormConsultarAnimal.cmbSeleccionPartoChange(Sender: TObject);
var
  Numero: string;
  Idx: Integer;
begin
  Idx := cmbSeleccionParto.ItemIndex;
  Numero := Trim(edtNumero.Text);
  if (Numero <> '') and (Idx >= 0) and (Idx < FPartos.Count) then
  begin
    CargarResumenPartos(Numero);
    CargarTablaTIM(Numero, FPartos[Idx]);
  end;
end;

procedure TFormConsultarAnimal.CargarPorNumero(const Numero: string);
begin
  if FAnimales.Count = 0 then
    CargarAnimales;
  CargarAnimal(Numero);
end;

procedure TFormConsultarAnimal.btnEditarClick(Sender: TObject);
var
  Numero: string;
begin
  Numero := Trim(edtNumero.Text);
  if Numero = '' then
  begin
    ShowMessage('Primero seleccione un animal.');
    Exit;
  end;

  if not FEditando then
  begin
    SetEditMode(True);
    edtNombre.SetFocus;
    Exit;
  end;

  // Estamos en modo edición → guardar
  btnEditar.Enabled := False;
  btnEditar.Caption := 'GUARDANDO...';
  try
    FConnection.ExecSQL('BEGIN IMMEDIATE');
    try
      FConnection.ExecSQL(
        'UPDATE animales SET nombre = :nom, fecha_nac = :fnac, sexo = :sex, raza = :raz, ' +
        'tipo = :tip, lote = :lot, estatus = :est, propietario = :prop, ' +
        'num_madre = :nmad, nom_madre = :nommad, padre = :pad, peso_nacer = :peso, ' +
        'estatus_repro = :estrepro, fecha_parto_est = :fecparto, comentarios = :com, ' +
        'foto_animal = :fotoani, foto_hierro = :fotohie ' +
        'WHERE numero = :num',
        [Trim(edtNombre.Text),
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
         Trim(edtFotoHierro.Text),
         Numero]);
      FConnection.ExecSQL('COMMIT');
    except
      FConnection.ExecSQL('ROLLBACK');
      raise;
    end;
    ShowMessage('Animal ' + Numero + ' actualizado correctamente.');
    SetEditMode(False);
  except
    on E: Exception do
      ShowMessage('Error al guardar: ' + E.Message + #13#10 +
        'Intente cerrar la ventana y abrirla de nuevo.');
  end;
  btnEditar.Enabled := True;
end;

procedure TFormConsultarAnimal.btnCerrarClick(Sender: TObject);
begin
  Close;
end;

end.