unit UDashboard;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.StdCtrls, Vcl.ExtCtrls, Vcl.Grids, Vcl.DBGrids, Data.DB,
  FireDAC.Stan.Intf, FireDAC.Stan.Option, FireDAC.Stan.Error, FireDAC.UI.Intf, FireDAC.Phys.Intf,
  FireDAC.Stan.Def, FireDAC.Stan.Pool, FireDAC.Stan.Async, FireDAC.Phys, FireDAC.VCLUI.Wait,
  FireDAC.Stan.ExprFuncs, FireDAC.Phys.SQLiteWrapper.Stat, FireDAC.Phys.SQLiteDef, FireDAC.Phys.SQLite,
  FireDAC.Comp.UI, FireDAC.Stan.Param, FireDAC.DatS, FireDAC.DApt.Intf, FireDAC.DApt,
  FireDAC.Comp.DataSet, FireDAC.Comp.Client;

type
  TFormDashboard = class(TForm)
    DBGrid1: TDBGrid;
    DataSource1: TDataSource;
    QryDashboard: TFDQuery;
    PanelTop: TPanel;
    Label1: TLabel;
    lblTitle: TLabel;
    btnClose: TButton;
    procedure btnCloseClick(Sender: TObject);
    procedure FormKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
  private
    FConnection: TFDConnection;
  public
    class procedure ShowDashboard(AOwner: TComponent; AConnection: TFDConnection; const Tipo: string);
  end;

implementation

{$R *.dfm}

procedure TFormDashboard.btnCloseClick(Sender: TObject);
begin
  Close;
end;

procedure TFormDashboard.FormKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
begin
  if Key = VK_ESCAPE then Close;
end;

class procedure TFormDashboard.ShowDashboard(AOwner: TComponent; AConnection: TFDConnection; const Tipo: string);
var
  Form: TFormDashboard;
begin
  Form := TFormDashboard.Create(AOwner);
  try
    Form.FConnection := AConnection;
    Form.QryDashboard.Connection := AConnection;

    if Tipo = 'general' then
    begin
      Form.Caption := 'Dashboard General';
      Form.lblTitle.Caption := 'Resumen General del Hato';
      Form.QryDashboard.SQL.Text :=
        'SELECT e.valor as Estatus, COUNT(*) as Cantidad ' +
        'FROM animales a JOIN CAT_ESTATUS e ON a.estatus = e.valor ' +
        'GROUP BY a.estatus ORDER BY Cantidad DESC';
    end
    else if Tipo = 'leche' then
    begin
      Form.Caption := 'Dashboard de Leche';
      Form.lblTitle.Caption := 'Producci'#243'n de Leche '#218'ltimos 7 d'#237'as';
      Form.QryDashboard.SQL.Text :=
        'SELECT fecha, SUM(produccion) as Total ' +
        'FROM control_leche ' +
        'WHERE fecha >= DATE(''now'', ''-7 days'') ' +
        'GROUP BY fecha ORDER BY fecha DESC';
    end
    else if Tipo = 'partos' then
    begin
      Form.Caption := 'Dashboard de Partos';
      Form.lblTitle.Caption := 'Partos '#218'ltimos 30 d'#237'as';
      Form.QryDashboard.SQL.Text :=
        'SELECT fecha, COUNT(*) as Cantidad ' +
        'FROM partos ' +
        'WHERE fecha >= DATE(''now'', ''-30 days'') ' +
        'GROUP BY fecha ORDER BY fecha DESC';
    end
    else if Tipo = 'queso' then
    begin
      Form.Caption := 'Dashboard de Queso';
      Form.lblTitle.Caption := 'Producci'#243'n de Queso '#218'ltimos 7 d'#237'as';
      Form.QryDashboard.SQL.Text :=
        'SELECT fecha, SUM(cantidad_elaborada) as Total ' +
        'FROM queso ' +
        'WHERE fecha >= DATE(''now'', ''-7 days'') ' +
        'GROUP BY fecha ORDER BY fecha DESC';
    end;

    Form.QryDashboard.Open;
    Form.ShowModal;
  finally
    Form.Free;
  end;
end;

end.
