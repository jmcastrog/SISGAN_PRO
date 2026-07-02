unit URutasSisgan;

interface

uses
  System.SysUtils,
  System.JSON,
  System.Classes,
  Data.DB,
  System.IOUtils,
  System.StrUtils,
  System.Generics.Collections,
  Winapi.Windows,
  System.Win.Registry,
  Horse,
  Horse.Jhonson,
  FireDAC.Stan.Intf,
  FireDAC.Stan.Option,
  FireDAC.Stan.Error,
  FireDAC.UI.Intf,
  FireDAC.Phys.Intf,
  FireDAC.Stan.Def,
  FireDAC.Stan.Pool,
  FireDAC.Stan.Async,
  FireDAC.Phys,
  FireDAC.VCLUI.Wait,
  FireDAC.Stan.ExprFuncs,
  FireDAC.Phys.SQLiteWrapper.Stat,
  FireDAC.Phys.SQLiteDef,
  FireDAC.Phys.SQLite,
  FireDAC.Comp.UI,
  FireDAC.Stan.Param,
  FireDAC.DatS,
  FireDAC.DApt.Intf,
  FireDAC.DApt,
  FireDAC.Comp.DataSet,
  FireDAC.Comp.Client;

const
  PUERTO_SISGAN = 5001;

var
  GDbPath: string;
  GLogFile: string;
  GConnection: TFDConnection;

procedure IniciarServidorSisgan;
procedure DetenerServidorSisgan;
procedure LogSisgan(const Msg: string);

implementation

{ --- HELPERS (replicados de MainUnit) --- }

function GetMimeType(const Archivo: string): string;
begin
  if Archivo.EndsWith('.png') then Result := 'image/png'
  else if Archivo.EndsWith('.jpg') or Archivo.EndsWith('.jpeg') then Result := 'image/jpeg'
  else if Archivo.EndsWith('.ico') then Result := 'image/x-icon'
  else if Archivo.EndsWith('.svg') then Result := 'image/svg+xml'
  else if Archivo.EndsWith('.css') then Result := 'text/css'
  else if Archivo.EndsWith('.js') then Result := 'application/javascript'
  else if Archivo.EndsWith('.json') then Result := 'application/json'
  else if Archivo.EndsWith('.woff2') then Result := 'font/woff2'
  else if Archivo.EndsWith('.woff') then Result := 'font/woff'
  else if Archivo.EndsWith('.ttf') then Result := 'font/ttf'
  else Result := 'application/octet-stream';
end;

function GetCATTable(const FieldName: string): string;
begin
  if SameText(FieldName, 'tipo') then Result := 'CAT_TIPO'
  else if SameText(FieldName, 'lote') then Result := 'CAT_LOTE'
  else if SameText(FieldName, 'estatus') then Result := 'CAT_ESTATUS'
  else if SameText(FieldName, 'propietario') then Result := 'CAT_Propietario'
  else Result := '';
end;

function GetCATAnimalesField(const TableName: string): string;
begin
  if SameText(TableName, 'CAT_TIPO') then Result := 'tipo'
  else if SameText(TableName, 'CAT_LOTE') then Result := 'lote'
  else if SameText(TableName, 'CAT_ESTATUS') then Result := 'estatus'
  else if SameText(TableName, 'CAT_Propietario') then Result := 'propietario'
  else Result := '';
end;

function GetFKField(const TableName: string): string;
begin
  if SameText(TableName, 'partos') then Result := 'num_madre'
  else if SameText(TableName, 'servicios') then Result := 'numero'
  else if SameText(TableName, 'palpaciones') then Result := 'numero'
  else if SameText(TableName, 'control_leche') then Result := 'numero_animal'
  else if SameText(TableName, 'bajas') then Result := 'numero_animal'
  else Result := '';
end;

function GetFilterField(const TableName: string; Slot: Integer): string;
begin
  Result := '';
  if SameText(TableName, 'animales') then
    case Slot of
      0: Result := 'estatus';
      1: Result := 'tipo';
      2: Result := 'lote';
      3: Result := 'propietario';
    end
  else if SameText(TableName, 'partos') then
    case Slot of
      0: Result := 'estado';
      1: Result := 'propietario';
      2: Result := 'estatus';
      3: Result := 'sexo';
    end
  else if SameText(TableName, 'servicios') then
    case Slot of
      0: Result := 'tipo';
      1: Result := 'toro';
      2: Result := 'propietario';
      3: Result := 'estatus';
    end
  else if SameText(TableName, 'bajas') then
    case Slot of
      0: Result := 'tipo_baja';
      1: Result := 'propietario';
      2: Result := 'estatus';
      3: Result := 'causa';
    end
  else if SameText(TableName, 'palpaciones') then
    case Slot of
      0: Result := 'diagnostico';
      1: Result := 'propietario';
      2: Result := 'estatus';
      3: Result := 'tecnico';
    end
  else if SameText(TableName, 'control_leche') then
    case Slot of
      0: Result := 'turno';
      1: Result := 'propietario';
      2: Result := 'estatus';
    end
  else if SameText(TableName, 'queso') then
    case Slot of
      0: Result := 'equipo';
    end;
end;

function GetFilterLabel(const FieldName: string): string;
begin
  if SameText(FieldName, 'estado') then Result := 'Estado (Cria)'
  else if SameText(FieldName, 'estatus_cria') then Result := 'Estatus Cria'
  else if SameText(FieldName, 'tipo_baja') then Result := 'Tipo Baja'
  else if SameText(FieldName, 'raza_toro') then Result := 'Raza Toro'
  else if FieldName <> '' then Result := FieldName
  else Result := '';
end;

function GetTableSQL(const TableName: string): string;
begin
  if SameText(TableName, 'partos') then
    Result := 'SELECT partos.rowid, partos.*, ' +
      '(SELECT a.propietario FROM animales a WHERE a.numero = partos.num_madre) as propietario, ' +
      '(SELECT a.estatus FROM animales a WHERE a.numero = partos.num_madre) as estatus FROM partos'
  else if SameText(TableName, 'servicios') then
    Result := 'SELECT servicios.rowid, servicios.*, ' +
      '(SELECT a.propietario FROM animales a WHERE a.numero = servicios.numero) as propietario, ' +
      '(SELECT a.estatus FROM animales a WHERE a.numero = servicios.numero) as estatus FROM servicios'
  else if SameText(TableName, 'control_leche') then
    Result := 'SELECT control_leche.rowid, control_leche.*, ' +
      '(SELECT a.propietario FROM animales a WHERE a.numero = control_leche.numero_animal) as propietario, ' +
      '(SELECT a.estatus FROM animales a WHERE a.numero = control_leche.numero_animal) as estatus FROM control_leche'
  else if SameText(TableName, 'bajas') then
    Result := 'SELECT bajas.rowid, bajas.*, ' +
      '(SELECT a.propietario FROM animales a WHERE a.numero = bajas.numero_animal) as propietario, ' +
      '(SELECT a.estatus FROM animales a WHERE a.numero = bajas.numero_animal) as estatus FROM bajas'
  else if SameText(TableName, 'palpaciones') then
    Result := 'SELECT palpaciones.rowid, palpaciones.*, ' +
      '(SELECT a.propietario FROM animales a WHERE a.numero = palpaciones.numero) as propietario, ' +
      '(SELECT a.estatus FROM animales a WHERE a.numero = palpaciones.numero) as estatus FROM palpaciones'
  else if SameText(TableName, 'CAT_TIPO') then
    Result := 'SELECT rowid, *, ' +
      '(SELECT COUNT(*) FROM animales WHERE tipo = CAT_TIPO.valor) as cantidad FROM CAT_TIPO'
  else if SameText(TableName, 'CAT_LOTE') then
    Result := 'SELECT rowid, *, ' +
      '(SELECT COUNT(*) FROM animales WHERE lote = CAT_LOTE.valor) as cantidad FROM CAT_LOTE'
  else if SameText(TableName, 'CAT_ESTATUS') then
    Result := 'SELECT rowid, *, ' +
      '(SELECT COUNT(*) FROM animales WHERE estatus = CAT_ESTATUS.valor) as cantidad FROM CAT_ESTATUS'
  else if SameText(TableName, 'CAT_Propietario') then
    Result := 'SELECT rowid, *, ' +
      '(SELECT COUNT(*) FROM animales WHERE propietario = CAT_Propietario.valor) as cantidad FROM CAT_Propietario'
  else
    Result := 'SELECT rowid, * FROM ' + TableName;
end;

{ --- LOGS --- }
procedure LogSisgan(const Msg: string);
var
  Linea: string;
begin
  Linea := Format('[%s] %s', [DateTimeToStr(Now), Msg]);
  try
    if GLogFile = '' then
      GLogFile := TPath.Combine(ExtractFilePath(ParamStr(0)), 'SisganViewer.log');
    TFile.AppendAllText(GLogFile, Linea + sLineBreak);
  except
  end;
end;

{ --- CONFIG --- }
procedure CargarConfiguracion;
var
  Reg: TRegistry;
begin
  GDbPath := ''; // Se requiere conexion manual o config
  Reg := TRegistry.Create(KEY_READ OR KEY_WOW64_64KEY);
  try
    Reg.RootKey := HKEY_LOCAL_MACHINE;
    if Reg.OpenKeyReadOnly('SOFTWARE\ServicioSisganViewer') then
    begin
      if Reg.ValueExists('DbPath') then
        GDbPath := Reg.ReadString('DbPath');
    end;
  finally
    Reg.Free;
  end;
  LogSisgan('DbPath: ' + GDbPath);
end;

{ --- CONEXION --- }
function ConectarBD: Boolean;
begin
  Result := False;
  if GDbPath = '' then
  begin
    LogSisgan('ERROR: DbPath no configurado');
    Exit;
  end;
  if DirectoryExists(GDbPath) then
    GDbPath := IncludeTrailingPathDelimiter(GDbPath) + 'sisgan_pro.db';

  if not FileExists(GDbPath) then
  begin
    LogSisgan('ERROR: BD no encontrada: ' + GDbPath);
    Exit;
  end;
  try
    if not Assigned(GConnection) then
    begin
      GConnection := TFDConnection.Create(nil);
      GConnection.DriverName := 'SQLite';
      GConnection.Params.Values['Database'] := GDbPath;
      GConnection.Params.Values['LockingMode'] := 'Normal';
      GConnection.Params.Values['Synchronous'] := 'Normal';
      GConnection.Params.Values['JournalMode'] := 'WAL';
      GConnection.LoginPrompt := False;
    end;
    GConnection.Connected := True;
    LogSisgan('BD conectada: ' + GDbPath);
    Result := True;
  except
    on E: Exception do
    begin
      LogSisgan('ERROR conexion BD: ' + E.Message);
      Result := False;
    end;
  end;
end;

{ --- LISTA DE TABLAS --- }
function GetTablas: TStringList;
var
  Q: TFDQuery;
begin
  Result := TStringList.Create;
  if not Assigned(GConnection) or not GConnection.Connected then Exit;
  Q := TFDQuery.Create(nil);
  try
    Q.Connection := GConnection;
    Q.SQL.Text := 'SELECT name FROM sqlite_master WHERE type=''table'' AND name NOT LIKE ''sqlite_%'' ORDER BY name';
    Q.Open;
    while not Q.Eof do
    begin
      Result.Add(Q.Fields[0].AsString);
      Q.Next;
    end;
  finally
    Q.Free;
  end;
end;

{ --- ESCAPE --- }
function EscapeJSON(const S: string): string;
begin
  Result := StringReplace(S, '\', '\\', [rfReplaceAll]);
  Result := StringReplace(Result, '"', '\"', [rfReplaceAll]);
  Result := StringReplace(Result, #13, '\r', [rfReplaceAll]);
  Result := StringReplace(Result, #10, '\n', [rfReplaceAll]);
  Result := StringReplace(Result, #9, '\t', [rfReplaceAll]);
end;

{ --- HTML INTERFACE --- }
{ Devuelve la ruta a la carpeta public, buscando primero al lado del EXE,
  luego un nivel arriba (modo desarrollo). }
function GetPublicPath: string;
var
  Base: string;
begin
  Base := ExtractFilePath(ParamStr(0));
  Result := IncludeTrailingPathDelimiter(Base) + 'public';
  if not DirectoryExists(Result) then
    Result := IncludeTrailingPathDelimiter(Base) + '..' + PathDelim + 'public';
  Result := IncludeTrailingPathDelimiter(Result);
end;

{ Lee un archivo de la carpeta public y retorna su contenido como string.
  Retorna '' si el archivo no existe. }
function LeerArchivoPublic(const NombreArchivo: string): string;
var
  Ruta: string;
  SL: TStringList;
begin
  Result := '';
  Ruta := GetPublicPath + NombreArchivo;
  if FileExists(Ruta) then
  begin
    SL := TStringList.Create;
    try
      SL.LoadFromFile(Ruta, TEncoding.UTF8);
      Result := SL.Text;
    finally
      SL.Free;
    end;
  end;
end;

{ --- ENDPOINTS --- }
procedure ConfigurarEndpoints;
begin
  THorse.Use(Jhonson);

  THorse.Get('/',
    procedure(Req: THorseRequest; Res: THorseResponse; Next: TNextProc)
    begin
      Res.RedirectTo('/viewer.html');
    end);

  { viewer.html - interfaz PWA para el tlf }
  THorse.Get('/viewer.html',
    procedure(Req: THorseRequest; Res: THorseResponse; Next: TNextProc)
    var
      Html: string;
    begin
      Html := LeerArchivoPublic('viewer.html');
      if Html = '' then
        Html := '<html><body><h2>Error: viewer.html no encontrado.</h2></body></html>';
      Res.ContentType('text/html; charset=utf-8').Send(Html);
    end);

  { Archivos estáticos de la carpeta public }
  THorse.Get('/public/:archivo',
    procedure(Req: THorseRequest; Res: THorseResponse; Next: TNextProc)
    var
      Archivo: string;
      Ruta: string;
      Stream: TFileStream;
    begin
      Archivo := Req.Params.Items['archivo'];
      if (Archivo = '') or (Pos('..', Archivo) > 0) then
      begin
        Res.Status(400).Send('Bad request');
        Exit;
      end;
      Ruta := GetPublicPath + Archivo;
      if not FileExists(Ruta) then
      begin
        Res.Status(404).Send('Not found: ' + Ruta);
        Exit;
      end;
      Stream := TFileStream.Create(Ruta, fmOpenRead or fmShareDenyWrite);
      Res.ContentType(GetMimeType(Archivo)).Send(Stream);
    end);

  { manifest.json para el PWA }
  THorse.Get('/manifest.json',
    procedure(Req: THorseRequest; Res: THorseResponse; Next: TNextProc)
    var
      Json: string;
    begin
      Json := LeerArchivoPublic('manifest.json');
      if Json = '' then
        Json := '{"error":"manifest not found"}';
      Res.ContentType('application/json; charset=utf-8').Send(Json);
    end);

  THorse.Get('/api/tablas',
    procedure(Req: THorseRequest; Res: THorseResponse; Next: TNextProc)
    var
      Tablas: TStringList;
      Arr: TJSONArray;
      I: Integer;
    begin
      try
        Tablas := GetTablas;
        try
          Arr := TJSONArray.Create;
          for I := 0 to Tablas.Count - 1 do
            Arr.Add(Tablas[I]);
          Res.Send(Arr);
        finally
          Tablas.Free;
        end;
      except
        on E: Exception do
          Res.Send(TJSONObject.Create.AddPair('error', E.Message)).Status(500);
      end;
    end);

  THorse.Get('/api/datos/:tabla',
    procedure(Req: THorseRequest; Res: THorseResponse; Next: TNextProc)
    var
      Tabla, SQL: string;
      Q: TFDQuery;
      Arr, ColArr: TJSONArray;
      Filtros, FObj: TJSONObject;
      I, J: Integer;
      Row: TJSONObject;
      FName: string;
      FiltroCampos: TStringList;
    begin
      Tabla := Req.Params['tabla'];
      try
        Q := TFDQuery.Create(nil);
        try
          Q.Connection := GConnection;

          // Construir SQL
          SQL := 'SELECT * FROM ' + Tabla + ' LIMIT 1000';

          // Intentar usar GetTableSQL para tablas conocidas
          try
            SQL := GetTableSQL(Tabla);
          except
            SQL := 'SELECT rowid, * FROM ' + Tabla + ' LIMIT 1000';
          end;

          Q.SQL.Text := SQL;
          Q.Open;

          // Columnas
          ColArr := TJSONArray.Create;
          for I := 0 to Q.FieldCount - 1 do
          begin
            FName := Q.Fields[I].FieldName;
            if not SameText(FName, 'rowid') then
              ColArr.Add(FName);
          end;

          // Datos
          Arr := TJSONArray.Create;
          while not Q.Eof do
          begin
            Row := TJSONObject.Create;
            try
              Row.AddPair('rowid', TJSONNumber.Create(Q.FieldByName('rowid').AsLargeInt));
            except
              try
                Row.AddPair('rowid', TJSONNumber.Create(Q.FieldByName('id').AsLargeInt));
              except
              end;
            end;
            for I := 0 to Q.FieldCount - 1 do
            begin
              FName := Q.Fields[I].FieldName;
              if SameText(FName, 'rowid') then Continue;
              if Q.Fields[I].IsNull then
                Row.AddPair(FName, TJSONNull.Create)
              else
                Row.AddPair(FName, Q.Fields[I].AsString);
            end;
            Arr.AddElement(Row);
            Q.Next;
          end;
          Q.Close;

          // Filtros disponibles
          Filtros := TJSONObject.Create;
          FiltroCampos := TStringList.Create;
          try
            for I := 0 to 3 do
            begin
              FName := GetFilterField(Tabla, I);
              if FName <> '' then
                FiltroCampos.Add(FName);
            end;
            // Si no hay filtros definidos, auto-detectar campos comunes
            if FiltroCampos.Count = 0 then
            begin
              Q.SQL.Text := 'SELECT * FROM ' + Tabla + ' LIMIT 0';
              Q.Open;
              for I := 0 to Q.FieldCount - 1 do
              begin
                FName := Q.Fields[I].FieldName;
                if SameText(FName, 'rowid') or SameText(FName, 'id') or
                   SameText(FName, 'id_1') then Continue;
                FiltroCampos.Add(FName);
              end;
              Q.Close;
            end;

            for I := 0 to FiltroCampos.Count - 1 do
            begin
              FName := FiltroCampos[I];
              Q.SQL.Text := 'SELECT DISTINCT "' + FName + '" FROM ' + Tabla +
                ' WHERE "' + FName + '" IS NOT NULL AND "' + FName + '" != '''' ORDER BY 1';
              Q.Open;
              ColArr := TJSONArray.Create;
              while not Q.Eof do
              begin
                ColArr.Add(Q.Fields[0].AsString);
                Q.Next;
              end;
              Q.Close;
              Filtros.AddPair(AnsiUpperCase(Copy(FName, 1, 1)) + Copy(FName, 2, Length(FName)), ColArr);
            end;
          finally
            FiltroCampos.Free;
          end;

          Q.Free;

          Res.Send(TJSONObject.Create
            .AddPair('columnas', ColArr)
            .AddPair('datos', Arr)
            .AddPair('filtros', Filtros));
        except
          on E: Exception do
          begin
            Q.Free;
            Res.Send(TJSONObject.Create.AddPair('error', E.Message)).Status(500);
          end;
        end;
      except
        on E: Exception do
          Res.Send(TJSONObject.Create.AddPair('error', E.Message)).Status(500);
      end;
    end);

  THorse.Post('/api/actualizar',
    procedure(Req: THorseRequest; Res: THorseResponse; Next: TNextProc)
    var
      Data: TJSONObject;
      Tabla: string;
      RowId: Int64;
      Q: TFDQuery;
      I: Integer;
      FName, FVal: string;
      Campos, Valores: TStringList;
      SQL: string;
    begin
      try
        Data := Req.Body<TJSONObject>;
        if not Assigned(Data) then
          raise Exception.Create('Datos JSON no recibidos');

        Tabla := Data.GetValue('tabla').Value;
        RowId := StrToInt64(Data.GetValue('rowid').Value);

        Campos := TStringList.Create;
        Valores := TStringList.Create;
        Q := TFDQuery.Create(nil);
        try
          Q.Connection := GConnection;

          // Obtener esquema de la tabla
          Q.SQL.Text := 'SELECT * FROM ' + Tabla + ' LIMIT 0';
          Q.Open;

          for I := 0 to Q.FieldCount - 1 do
          begin
            FName := Q.Fields[I].FieldName;
            if SameText(FName, 'rowid') then Continue;
            if SameText(FName, 'id') then Continue;
            if SameText(FName, 'id_1') then Continue;
            if Data.Values[FName] <> nil then
            begin
              if Data.Values[FName] is TJSONNull then
              begin
                Campos.Add('"' + FName + '" = NULL');
              end
              else
              begin
                FVal := Data.Values[FName].Value;
                Campos.Add('"' + FName + '" = ' + QuotedStr(FVal));
              end;
            end;
          end;
          Q.Close;

          if Campos.Count = 0 then
          begin
            Res.Send(TJSONObject.Create.AddPair('error', 'Sin campos para actualizar'));
            Exit;
          end;

          SQL := 'UPDATE ' + Tabla + ' SET ' + Campos.CommaText + ' WHERE rowid = ' + IntToStr(RowId);
          Campos.Free;
          Q.SQL.Text := SQL;
          Q.ExecSQL;

          // Propagacion CAT_XXX
          if (Pos('CAT_', UpperCase(Tabla)) = 1) and (GetCATAnimalesField(Tabla) <> '') then
          begin
            // Nota: la propagacion se maneja via la API directamente
            LogSisgan('CAT actualizado: ' + Tabla + ' rowid=' + IntToStr(RowId));
          end;

          Res.Send(TJSONObject.Create.AddPair('mensaje', 'Registro actualizado'));
        finally
          Q.Free;
          Campos.Free;
          Valores.Free;
        end;
      except
        on E: Exception do
        begin
          LogSisgan('ERROR actualizar: ' + E.Message);
          Res.Send(TJSONObject.Create.AddPair('error', E.Message)).Status(500);
        end;
      end;
    end);

  THorse.Post('/api/eliminar',
    procedure(Req: THorseRequest; Res: THorseResponse; Next: TNextProc)
    var
      Data: TJSONObject;
      Tabla: string;
      RowId: Int64;
      Q: TFDQuery;
    begin
      try
        Data := Req.Body<TJSONObject>;
        if not Assigned(Data) then
          raise Exception.Create('Datos JSON no recibidos');

        Tabla := Data.GetValue('tabla').Value;
        RowId := StrToInt64(Data.GetValue('rowid').Value);

        Q := TFDQuery.Create(nil);
        try
          Q.Connection := GConnection;
          Q.SQL.Text := 'DELETE FROM ' + Tabla + ' WHERE rowid = ' + IntToStr(RowId);
          LogSisgan('DELETE: ' + Q.SQL.Text);
          Q.ExecSQL;
          Res.Send(TJSONObject.Create.AddPair('mensaje', 'Registro eliminado'));
        finally
          Q.Free;
        end;
      except
        on E: Exception do
        begin
          LogSisgan('ERROR eliminar: ' + E.Message);
          Res.Send(TJSONObject.Create.AddPair('error', E.Message)).Status(500);
        end;
      end;
    end);

  THorse.Get('/api/exportar/:tabla',
    procedure(Req: THorseRequest; Res: THorseResponse; Next: TNextProc)
    var
      Tabla, SQL: string;
      Q: TFDQuery;
      Arr: TJSONArray;
      I: Integer;
      Row: TJSONObject;
    begin
      Tabla := Req.Params['tabla'];
      try
        Q := TFDQuery.Create(nil);
        try
          Q.Connection := GConnection;
          try
            SQL := GetTableSQL(Tabla);
          except
            SQL := 'SELECT rowid, * FROM ' + Tabla;
          end;
          Q.SQL.Text := SQL;
          Q.Open;
          Arr := TJSONArray.Create;
          while not Q.Eof do
          begin
            Row := TJSONObject.Create;
            for I := 0 to Q.FieldCount - 1 do
            begin
              if SameText(Q.Fields[I].FieldName, 'rowid') then
                Row.AddPair('rowid', TJSONNumber.Create(Q.Fields[I].AsLargeInt))
              else if Q.Fields[I].IsNull then
                Row.AddPair(Q.Fields[I].FieldName, TJSONNull.Create)
              else
                Row.AddPair(Q.Fields[I].FieldName, Q.Fields[I].AsString);
            end;
            Arr.AddElement(Row);
            Q.Next;
          end;
          Res.ContentType('application/json; charset=utf-8')
            .Send(TJSONObject.Create
              .AddPair('tabla', Tabla)
              .AddPair('registros', TJSONNumber.Create(Arr.Count))
              .AddPair('datos', Arr));
        finally
          Q.Free;
        end;
      except
        on E: Exception do
          Res.Send(TJSONObject.Create.AddPair('error', E.Message)).Status(500);
      end;
    end);

  THorse.Get('/api/esquema/:tabla',
    procedure(Req: THorseRequest; Res: THorseResponse; Next: TNextProc)
    var
      Tabla: string;
      Q: TFDQuery;
      Arr: TJSONArray;
      I: Integer;
      Col: TJSONObject;
    begin
      Tabla := Req.Params['tabla'];
      try
        Q := TFDQuery.Create(nil);
        try
          Q.Connection := GConnection;
          Q.SQL.Text := 'SELECT * FROM ' + Tabla + ' LIMIT 0';
          Q.Open;
          Arr := TJSONArray.Create;
          for I := 0 to Q.FieldCount - 1 do
          begin
            Col := TJSONObject.Create;
            Col.AddPair('nombre', Q.Fields[I].FieldName);
            Col.AddPair('tipo', Q.Fields[I].ClassName);
            Arr.Add(Col);
          end;
          Res.Send(Arr);
        finally
          Q.Free;
        end;
      except
        on E: Exception do
          Res.Send(TJSONObject.Create.AddPair('error', E.Message)).Status(500);
      end;
    end);

  // ENDPOINTS PARA viewer.html

  // GET /api/catalogs -> {estatus, tipos, lotes, propietarios}
  THorse.Get('/api/catalogs',
    procedure(Req: THorseRequest; Res: THorseResponse; Next: TNextProc)
    var
      Q: TFDQuery;
      R: TJSONObject;
    begin
      try
        R := TJSONObject.Create;
        Q := TFDQuery.Create(nil);
        try
          Q.Connection := GConnection;
          Q.SQL.Text := 'SELECT DISTINCT valor FROM CAT_ESTATUS WHERE valor IS NOT NULL AND valor != '''' ORDER BY 1';
          Q.Open;
          R.AddPair('estatus', TJSONArray.Create);
          while not Q.Eof do
          begin
            TJSONArray(R.GetValue('estatus')).Add(Q.Fields[0].AsString);
            Q.Next;
          end;
          Q.Close;
          Q.SQL.Text := 'SELECT DISTINCT valor FROM CAT_TIPO WHERE valor IS NOT NULL AND valor != '''' ORDER BY 1';
          Q.Open;
          R.AddPair('tipos', TJSONArray.Create);
          while not Q.Eof do
          begin
            TJSONArray(R.GetValue('tipos')).Add(Q.Fields[0].AsString);
            Q.Next;
          end;
          Q.Close;
          Q.SQL.Text := 'SELECT DISTINCT valor FROM CAT_LOTE WHERE valor IS NOT NULL AND valor != '''' ORDER BY 1';
          Q.Open;
          R.AddPair('lotes', TJSONArray.Create);
          while not Q.Eof do
          begin
            TJSONArray(R.GetValue('lotes')).Add(Q.Fields[0].AsString);
            Q.Next;
          end;
          Q.Close;
          Q.SQL.Text := 'SELECT DISTINCT valor FROM CAT_Propietario WHERE valor IS NOT NULL AND valor != '''' ORDER BY 1';
          Q.Open;
          R.AddPair('propietarios', TJSONArray.Create);
          while not Q.Eof do
          begin
            TJSONArray(R.GetValue('propietarios')).Add(Q.Fields[0].AsString);
            Q.Next;
          end;
        finally
          Q.Free;
        end;
        Res.Send(R);
      except
        on E: Exception do
          Res.Send(TJSONObject.Create.AddPair('error', E.Message)).Status(500);
      end;
    end);

  // GET /api/config?table=X -> columnas visibles
  THorse.Get('/api/config',
    procedure(Req: THorseRequest; Res: THorseResponse; Next: TNextProc)
    var
      Tabla: string;
      Q: TFDQuery;
      I: Integer;
      R: TJSONObject;
    begin
      Tabla := Req.Query['table'];
      if Tabla = '' then
      begin
        Res.Send(TJSONObject.Create.AddPair('error', 'Falta parametro table')).Status(400);
        Exit;
      end;
      try
        Q := TFDQuery.Create(nil);
        try
          Q.Connection := GConnection;
          Q.SQL.Text := 'SELECT * FROM ' + Tabla + ' LIMIT 0';
          Q.Open;
          R := TJSONObject.Create;
          for I := 0 to Q.FieldCount - 1 do
            R.AddPair(Q.Fields[I].FieldName, TJSONBool.Create(True));
          Res.Send(R);
        finally
          Q.Free;
        end;
      except
        on E: Exception do
          Res.Send(TJSONObject.Create.AddPair('error', E.Message)).Status(500);
      end;
    end);

  // GET /api/data?table=X -> array de objetos con rowid_internal
  THorse.Get('/api/data',
    procedure(Req: THorseRequest; Res: THorseResponse; Next: TNextProc)
    var
      Tabla, SQL: string;
      Q: TFDQuery;
      I, PK: Int64;
      Arr: TJSONArray;
      Row: TJSONObject;
      FName: string;
    begin
      Tabla := Req.Query['table'];
      if Tabla = '' then
      begin
        Res.Send(TJSONObject.Create.AddPair('error', 'Falta parametro table')).Status(400);
        Exit;
      end;
      try
        Q := TFDQuery.Create(nil);
        try
          Q.Connection := GConnection;
          SQL := 'SELECT * FROM ' + Tabla + ' LIMIT 5000';
          Q.SQL.Text := SQL;
          Q.Open;
          Arr := TJSONArray.Create;
          while not Q.Eof do
          begin
            Row := TJSONObject.Create;
            PK := 0;
            for I := 0 to Q.FieldCount - 1 do
            begin
              FName := Q.Fields[I].FieldName;
              if SameText(FName, 'rowid') or SameText(FName, 'id') then
                PK := Q.Fields[I].AsLargeInt;
              if Q.Fields[I].IsNull then
                Row.AddPair(FName, TJSONNull.Create)
              else
                Row.AddPair(FName, Q.Fields[I].AsString);
            end;
            Row.AddPair('rowid_internal', TJSONNumber.Create(PK));
            Arr.AddElement(Row);
            Q.Next;
          end;
          Res.Send(Arr);
        finally
          Q.Free;
        end;
      except
        on E: Exception do
          Res.Send(TJSONObject.Create.AddPair('error', E.Message)).Status(500);
      end;
    end);

  // POST /api/insert -> {success:true}
  THorse.Post('/api/insert',
    procedure(Req: THorseRequest; Res: THorseResponse; Next: TNextProc)
    var
      Tabla: string;
      Datos: TJSONObject;
      Campos, Valores: TStringBuilder;
      I: Integer;
      V: TJSONValue;
    begin
      Datos := Req.Body<TJSONObject>;
      if not Assigned(Datos) then
      begin
        Res.Send(TJSONObject.Create.AddPair('error', 'JSON invalido')).Status(400);
        Exit;
      end;
      Tabla := Datos.GetValue('table', '');
      if Tabla = '' then
      begin
        Res.Send(TJSONObject.Create.AddPair('error', 'Falta parametro table')).Status(400);
        Exit;
      end;
      try
        Campos := TStringBuilder.Create;
        Valores := TStringBuilder.Create;
        try
          for I := 0 to Datos.Count - 1 do
          begin
            if SameText(Datos.Pairs[I].JsonString.Value, 'table') then Continue;
            if Campos.Length > 0 then Campos.Append(', ');
            Campos.Append('"' + Datos.Pairs[I].JsonString.Value + '"');
            if Valores.Length > 0 then Valores.Append(', ');
            V := Datos.Pairs[I].JsonValue;
            if V is TJSONNull then
              Valores.Append('NULL')
            else
              Valores.Append(QuotedStr(V.Value));
          end;
          if Campos.Length = 0 then
          begin
            Res.Send(TJSONObject.Create.AddPair('error', 'No hay campos para insertar')).Status(400);
            Exit;
          end;
          GConnection.ExecSQL(
            'INSERT INTO "' + Tabla + '" (' + Campos.ToString + ') VALUES (' + Valores.ToString + ')');
          Res.Send(TJSONObject.Create.AddPair('success', TJSONBool.Create(True)));
        finally
          Campos.Free;
          Valores.Free;
        end;
      except
        on E: Exception do
        begin
          LogSisgan('ERROR viewer insert: ' + E.Message);
          Res.Send(TJSONObject.Create.AddPair('error', E.Message)).Status(500);
        end;
      end;
    end);

  // GET /api/update?table=X&field=F&value=V&id=N -> {success:true}
  THorse.Get('/api/update',
    procedure(Req: THorseRequest; Res: THorseResponse; Next: TNextProc)
    var
      Tabla, Campo, Valor: string;
      Id: Int64;
    begin
      Tabla := Req.Query['table'];
      Campo := Req.Query['field'];
      Valor := Req.Query['value'];
      Id := StrToInt64Def(Req.Query['id'], 0);
      if (Tabla = '') or (Campo = '') or (Id = 0) then
      begin
        Res.Send(TJSONObject.Create.AddPair('success', TJSONBool.Create(False)));
        Exit;
      end;
      try
        GConnection.ExecSQL(
          'UPDATE "' + Tabla + '" SET "' + Campo + '" = ' + QuotedStr(Valor) +
          ' WHERE rowid = ' + IntToStr(Id));
        Res.Send(TJSONObject.Create.AddPair('success', TJSONBool.Create(True)));
      except
        on E: Exception do
        begin
          LogSisgan('ERROR viewer update: ' + E.Message);
          Res.Send(TJSONObject.Create.AddPair('success', TJSONBool.Create(False)));
        end;
      end;
    end);

  // GET /api/delete?table=X&id=N -> {success:true}
  THorse.Get('/api/delete',
    procedure(Req: THorseRequest; Res: THorseResponse; Next: TNextProc)
    var
      Tabla: string;
      Id: Int64;
    begin
      Tabla := Req.Query['table'];
      Id := StrToInt64Def(Req.Query['id'], 0);
      if (Tabla = '') or (Id = 0) then
      begin
        Res.Send(TJSONObject.Create.AddPair('success', TJSONBool.Create(False)));
        Exit;
      end;
      try
        GConnection.ExecSQL(
          'DELETE FROM "' + Tabla + '" WHERE rowid = ' + IntToStr(Id));
        Res.Send(TJSONObject.Create.AddPair('success', TJSONBool.Create(True)));
      except
        on E: Exception do
        begin
          LogSisgan('ERROR viewer delete: ' + E.Message);
          Res.Send(TJSONObject.Create.AddPair('success', TJSONBool.Create(False)));
        end;
      end;
    end);
end;

{ --- SERVER LIFECYCLE --- }
procedure IniciarServidorSisgan;
begin
  LogSisgan('=== INICIANDO SERVIDOR SISGAN VIEWER ===');
  GLogFile := TPath.Combine(ExtractFilePath(ParamStr(0)), 'SisganViewer.log');
  CargarConfiguracion;
  ConectarBD;
  ConfigurarEndpoints;
  LogSisgan(Format('Escuchando en puerto %d...', [PUERTO_SISGAN]));
  try
    THorse.Listen(PUERTO_SISGAN);
  except
    on E: Exception do
      LogSisgan('ERROR CRITICO HORSE: ' + E.Message);
  end;
end;

procedure DetenerServidorSisgan;
begin
  try
    THorse.StopListen;
    if Assigned(GConnection) then
    begin
      GConnection.Connected := False;
      GConnection.Free;
      GConnection := nil;
    end;
    LogSisgan('=== SERVIDOR SISGAN VIEWER DETENIDO ===');
  except
  end;
end;

end.
