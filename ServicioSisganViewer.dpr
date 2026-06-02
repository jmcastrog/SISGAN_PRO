program ServicioSisganViewer;

uses
  Vcl.SvcMgr,
  uServicioSisgan in 'uServicioSisgan.pas' {ServicioSisganGlobal: TService},
  URutasSisgan in 'URutasSisgan.pas';

{$R *.RES}

begin
  if not Application.DelayInitialize or Application.Installing then
    Application.Initialize;

  Application.CreateForm(TuServicioSisgan, ServicioSisganGlobal);

  Application.Run;
end.
