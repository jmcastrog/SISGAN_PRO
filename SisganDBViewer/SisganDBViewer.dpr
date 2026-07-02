program SisganDBViewer;

uses
  Vcl.Forms,
  Vcl.Themes,
  Vcl.Styles,
  System.SysUtils,
  Winapi.Windows,
  MainUnit in 'MainUnit.pas' {Form1},
  UControlLeche in 'UControlLeche.pas' {FormControlLeche},
  UAddAnimal in 'UAddAnimal.pas' {FormAddAnimal},
  UPalpaciones in 'UPalpaciones.pas' {FormPalpaciones},
  UBajas in 'UBajas.pas' {FormBajas},
  UConsultarAnimal in 'UConsultarAnimal.pas' {FormConsultarAnimal},
  UDashboard in 'UDashboard.pas' {FormDashboard},
  UIndividualCard in 'UIndividualCard.pas' {IndividualCard};

{$R *.res}

var
  hMutex: THandle;
begin
  hMutex := CreateMutex(nil, True, 'Global\SisganDBViewer_Unique_Mutex_v1');
  if (hMutex <> 0) and (GetLastError = ERROR_ALREADY_EXISTS) then
  begin
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
