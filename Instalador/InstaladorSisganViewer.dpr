program InstaladorSisganViewer;

uses
  Vcl.Forms,
  uFrmInstalador in 'uFrmInstalador.pas' {FrmInstalador};

{$R *.res}

begin
  Application.Initialize;
  Application.MainFormOnTaskbar := True;
  Application.CreateForm(TFrmInstalador, FrmInstalador);
  Application.Run;
end.
