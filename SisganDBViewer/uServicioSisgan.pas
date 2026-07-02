unit uServicioSisgan;

interface

uses
  Winapi.Windows,
  Winapi.Messages,
  System.SysUtils,
  System.Classes,
  Vcl.SvcMgr,
  URutasSisgan;

type
  TuServicioSisgan = class(TService)
    procedure ServiceStart(Sender: TService; var Started: Boolean);
    procedure ServiceExecute(Sender: TService);
    procedure ServiceStop(Sender: TService; var Stopped: Boolean);
  private
    { Private declarations }
  public
    function GetServiceController: TServiceController; override;
  end;

var
  ServicioSisganGlobal: TuServicioSisgan;

implementation

{$R *.dfm}

procedure ServiceController(CtrlCode: DWord); stdcall;
begin
  ServicioSisganGlobal.Controller(CtrlCode);
end;

function TuServicioSisgan.GetServiceController: TServiceController;
begin
  Result := ServiceController;
end;

procedure TuServicioSisgan.ServiceStart(Sender: TService; var Started: Boolean);
begin
  Started := True;
end;

procedure TuServicioSisgan.ServiceExecute(Sender: TService);
begin
  try
    IniciarServidorSisgan;
    while not Terminated do
      ServiceThread.ProcessRequests(True);
  except
    on E: Exception do
      LogSisgan('EXCEPTION EN EXECUTE: ' + E.Message);
  end;
end;

procedure TuServicioSisgan.ServiceStop(Sender: TService; var Stopped: Boolean);
begin
  DetenerServidorSisgan;
  Stopped := True;
end;

end.
