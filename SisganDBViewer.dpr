program SisganDBViewer;

uses
  Vcl.Forms,
  Winapi.Windows,
  MainUnit in 'MainUnit.pas' {Form1};

{$R *.res}

var
  hMutex: THandle;
begin
  // Crear un Mutex global para identificar si la app ya esta abierta
  hMutex := CreateMutex(nil, True, 'Global\SisganDBViewer_Unique_Mutex_v1');
  if (hMutex <> 0) and (GetLastError = ERROR_ALREADY_EXISTS) then
  begin
    // Ya hay una instancia corriendo, cerramos esta silenciosamente
    ReleaseMutex(hMutex);
    Exit;
  end;

  try
    Application.Initialize;
    Application.MainFormOnTaskbar := True;
    Application.CreateForm(TForm1, Form1);
    Application.Run;
  finally
    if hMutex <> 0 then
      ReleaseMutex(hMutex);
  end;
end.
