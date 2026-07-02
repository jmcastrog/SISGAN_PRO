unit uFrmInstalador;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.StdCtrls, Vcl.ExtCtrls, System.Win.Registry,
  Winapi.ShellAPI, System.IOUtils, Vcl.FileCtrl, System.UITypes, Winapi.WinSvc;

const
  PUERTO_SISGAN = 5001;
  NOMBRE_SERVICIO = 'ServicioSisgan';

type
  TFrmInstalador = class(TForm)
    pnlHeader: TPanel;
    lblTitle: TLabel;
    lblSubtitle: TLabel;
    pnlContent: TPanel;
    lblPath: TLabel;
    edtPath: TEdit;
    btnBrowse: TButton;
    btnInstall: TButton;
    btnUninstall: TButton;
    memLog: TMemo;
    lblInfo: TLabel;
    procedure btnBrowseClick(Sender: TObject);
    procedure btnInstallClick(Sender: TObject);
    procedure btnUninstallClick(Sender: TObject);
    procedure FormCreate(Sender: TObject);
  private
    procedure Log(const Msg: string);
    function RunCommand(const Cmd, Params: string; out ExitCode: DWORD): Boolean;
    function RunAndLog(const Cmd, Params, FailMsg: string; const IgnoreFailure: Boolean = False): Boolean;
    function FindServiceExe: string;
    function ServicioExiste: Boolean;
  public
  end;

var
  FrmInstalador: TFrmInstalador;

implementation

{$R *.dfm}

procedure TFrmInstalador.FormCreate(Sender: TObject);
begin
  edtPath.Text := 'D:\Proyectos\SISGAN_PRO\data';
end;

procedure TFrmInstalador.Log(const Msg: string);
begin
  memLog.Lines.Add(Format('[%s] %s', [FormatDateTime('hh:nn:ss', Now), Msg]));
end;

function TFrmInstalador.RunCommand(const Cmd, Params: string; out ExitCode: DWORD): Boolean;
var
  SEInfo: TShellExecuteInfo;
begin
  FillChar(SEInfo, SizeOf(SEInfo), 0);
  SEInfo.cbSize := SizeOf(TShellExecuteInfo);
  SEInfo.fMask := SEE_MASK_NOCLOSEPROCESS;
  SEInfo.lpVerb := 'runas';
  SEInfo.lpFile := PChar(Cmd);
  SEInfo.lpParameters := PChar(Params);
  SEInfo.nShow := SW_HIDE;

  if ShellExecuteEx(@SEInfo) then
  begin
    WaitForSingleObject(SEInfo.hProcess, 30000);
    GetExitCodeProcess(SEInfo.hProcess, ExitCode);
    CloseHandle(SEInfo.hProcess);
    Result := (ExitCode = 0);
  end
  else
  begin
    ExitCode := GetLastError;
    Result := False;
  end;
end;

function TFrmInstalador.RunAndLog(const Cmd, Params, FailMsg: string; const IgnoreFailure: Boolean = False): Boolean;
var
  ExitCode: DWORD;
begin
  Result := RunCommand(Cmd, Params, ExitCode);
  if not Result and not IgnoreFailure then
    Log('ADVERTENCIA: ' + FailMsg + ' (ExitCode: ' + IntToStr(ExitCode) + ')');
end;

function TFrmInstalador.FindServiceExe: string;
begin
  Result := ExtractFilePath(ParamStr(0)) + 'ServicioSisganViewer.exe';
  if FileExists(Result) then Exit;
  Result := ExtractFilePath(ParamStr(0)) + '..\ServicioSisganViewer.exe';
  if FileExists(Result) then Exit;
  Result := ExtractFilePath(ParamStr(0)) + '..\SisganDBViewer\ServicioSisganViewer.exe';
  if FileExists(Result) then Exit;
  Result := '';
end;

function TFrmInstalador.ServicioExiste: Boolean;
var
  SCM, Service: SC_HANDLE;
begin
  SCM := OpenSCManager(nil, nil, SC_MANAGER_CONNECT);
  if SCM = 0 then Exit(False);
  try
    Service := OpenService(SCM, PChar(NOMBRE_SERVICIO), SERVICE_QUERY_STATUS);
    Result := Service <> 0;
    if Service <> 0 then CloseServiceHandle(Service);
  finally
    CloseServiceHandle(SCM);
  end;
end;

procedure TFrmInstalador.btnBrowseClick(Sender: TObject);
var
  SelectedDir: string;
begin
  if SelectDirectory('Seleccione la carpeta de la base de datos SQLite', '', SelectedDir, [sdNewUI, sdNewFolder]) then
    edtPath.Text := SelectedDir;
end;

procedure TFrmInstalador.btnInstallClick(Sender: TObject);
var
  Reg: TRegistry;
  ExePath: string;
begin
  memLog.Clear;
  Log('Iniciando instalacion...');

  if Trim(edtPath.Text) = '' then
  begin
    Log('ERROR: Debe seleccionar la ruta de la base de datos.');
    Exit;
  end;

  if not System.SysUtils.DirectoryExists(edtPath.Text) then
  begin
    Log('ERROR: La ruta especificada no existe.');
    Exit;
  end;

  ExePath := FindServiceExe;
  if ExePath = '' then
  begin
    Log('ERROR: No se encontro ServicioSisganViewer.exe.');
    Exit;
  end;

  if ServicioExiste then
  begin
    Log('El servicio ya esta registrado. Deteniendo y reinstalando...');
    RunAndLog('net', 'stop ' + NOMBRE_SERVICIO, 'No se pudo detener el servicio.', True);
    RunAndLog(ExePath, '/uninstall /silent', 'No se pudo desinstalar.', True);
    Sleep(1000);
  end;

  Log('Guardando ruta en el Registro...');
  Reg := TRegistry.Create(KEY_WRITE OR KEY_WOW64_64KEY);
  try
    Reg.RootKey := HKEY_LOCAL_MACHINE;
    if Reg.OpenKey('SOFTWARE\ServicioSisganViewer', True) then
    begin
      Reg.WriteString('DbPath', edtPath.Text);
      Log('Ruta guardada: ' + edtPath.Text);
    end
    else
      Log('Error al abrir clave de registro.');
  finally
    Reg.Free;
  end;

  RunAndLog(ExePath, '/install /silent', 'No se pudo registrar el servicio.');
  RunAndLog('sc', 'config ' + NOMBRE_SERVICIO + ' start= auto', 'No se pudo configurar inicio automatico.');
  RunAndLog('netsh', 'advfirewall firewall delete rule name="Servicio Sisgan Viewer (Puerto ' + IntToStr(PUERTO_SISGAN) + ')"', 'No se pudo eliminar regla de firewall existente.', True);
  RunAndLog('netsh', 'advfirewall firewall add rule name="Servicio Sisgan Viewer (Puerto ' + IntToStr(PUERTO_SISGAN) + ')" dir=in action=allow protocol=TCP localport=' + IntToStr(PUERTO_SISGAN), 'No se pudo agregar regla de firewall.', True);
  if not RunAndLog('net', 'start ' + NOMBRE_SERVICIO, 'No se pudo iniciar el servicio.') then
    Log('ERROR: El servicio no se inicio. Revise el log del sistema para mas detalles.');

  Log('INSTALACION FINALIZADA.');
  ShowMessage('Servicio instalado correctamente.');
end;

procedure TFrmInstalador.btnUninstallClick(Sender: TObject);
var
  ExePath: string;
begin
  if MessageDlg('Esta seguro de que desea desinstalar el servicio?', mtConfirmation, [mbYes, mbNo], 0) <> mrYes then
    Exit;

  memLog.Clear;
  Log('Iniciando desinstalacion...');

  RunAndLog('net', 'stop ' + NOMBRE_SERVICIO, 'No se pudo detener el servicio.', True);

  ExePath := FindServiceExe;
  if ExePath <> '' then
    RunAndLog(ExePath, '/uninstall /silent', 'El /uninstall puede haber fallado.', True);

  RunAndLog('netsh', 'advfirewall firewall delete rule name="Servicio Sisgan Viewer (Puerto ' + IntToStr(PUERTO_SISGAN) + ')"', 'No se pudo eliminar regla de firewall.', True);
  Log('Registro limpiado correctamente.');

  Log('DESINSTALACION COMPLETADA.');
  ShowMessage('Servicio desinstalado correctamente.');
end;

end.
