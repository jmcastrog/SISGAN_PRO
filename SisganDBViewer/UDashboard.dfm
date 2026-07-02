object FormDashboard: TFormDashboard
  Left = 0
  Top = 0
  Caption = 'Dashboard'
  ClientHeight = 400
  ClientWidth = 600
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'Tahoma'
  Font.Style = []
  OldCreateOrder = False
  Position = poScreenCenter
  OnKeyDown = FormKeyDown
  KeyPreview = True
  PixelsPerInch = 96
  TextHeight = 13
  object PanelTop: TPanel
    Left = 0
    Top = 0
    Width = 600
    Height = 50
    Align = alTop
    TabOrder = 0
    object Label1: TLabel
      Left = 16
      Top = 6
      Width = 87
      Height = 13
      Caption = 'Dashboard:'
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clWindowText
      Font.Height = -11
      Font.Name = 'Tahoma'
      Font.Style = [fsBold]
      ParentFont = False
    end
    object lblTitle: TLabel
      Left = 16
      Top = 25
      Width = 43
      Height = 13
      Caption = 'Resumen'
    end
    object btnClose: TButton
      Left = 510
      Top = 12
      Width = 75
      Height = 25
      Caption = 'Cerrar'
      TabOrder = 0
      OnClick = btnCloseClick
    end
  end
  object DBGrid1: TDBGrid
    Left = 0
    Top = 50
    Width = 600
    Height = 350
    Align = alClient
    DataSource = DataSource1
    TabOrder = 1
    TitleFont.Charset = DEFAULT_CHARSET
    TitleFont.Color = clWindowText
    TitleFont.Height = -11
    TitleFont.Name = 'Tahoma'
    TitleFont.Style = []
  end
  object DataSource1: TDataSource
    DataSet = QryDashboard
    Left = 304
    Top = 216
  end
  object QryDashboard: TFDQuery
    Left = 368
    Top = 216
  end
end
