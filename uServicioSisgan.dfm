object ServicioSisgan: TuServicioSisgan
  OldCreateOrder = False
  DisplayName = 'Servicio Sisgan DB Viewer'
  OnExecute = ServiceExecute
  OnStart = ServiceStart
  OnStop = ServiceStop
  Height = 150
  Width = 215
end
