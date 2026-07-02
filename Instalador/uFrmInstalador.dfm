object FrmInstalador: TFrmInstalador
  Left = 0
  Top = 0
  BorderIcons = [biSystemMenu, biMinimize]
  BorderStyle = bsSingle
  Caption = 'Instalador Sisgan DB Viewer'
  ClientHeight = 450
  ClientWidth = 480
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -12
  Font.Name = 'Segoe UI'
  Font.Style = []
  OldCreateOrder = True
  Position = poScreenCenter
  OnCreate = FormCreate
  PixelsPerInch = 96
  TextHeight = 15
  object pnlHeader: TPanel
    Left = 0
    Top = 0
    Width = 480
    Height = 80
    Align = alTop
    BevelOuter = bvNone
    Color = 1793568
    ParentBackground = False
    TabOrder = 0
    object lblTitle: TLabel
      Left = 20
      Top = 15
      Width = 240
      Height = 25
      Caption = 'INSTALADOR SISGAN VIEWER'
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clWhite
      Font.Height = -19
      Font.Name = 'Segoe UI'
      Font.Style = [fsBold]
      ParentFont = False
    end
    object lblSubtitle: TLabel
      Left = 20
      Top = 46
      Width = 231
      Height = 15
      Caption = 'Configuracion Automatica del Servicio API'
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clWhite
      Font.Height = -12
      Font.Name = 'Segoe UI'
      Font.Style = []
      ParentFont = False
    end
  end
  object pnlContent: TPanel
    Left = 0
    Top = 80
    Width = 480
    Height = 370
    Align = alClient
    BevelOuter = bvNone
    Color = 15790320
    ParentBackground = False
    TabOrder = 1
    object lblPath: TLabel
      Left = 20
      Top = 20
      Width = 159
      Height = 15
      Caption = 'Ruta Base de Datos SQLite:'
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clWindowText
      Font.Height = -12
      Font.Name = 'Segoe UI'
      Font.Style = [fsBold]
      ParentFont = False
    end
    object lblInfo: TLabel
      Left = 20
      Top = 80
      Width = 138
      Height = 15
      Caption = 'Progreso de la Instalacion:'
    end
    object edtPath: TEdit
      Left = 20
      Top = 41
      Width = 350
      Height = 23
      TabOrder = 0
    end
    object btnBrowse: TButton
      Left = 380
      Top = 40
      Width = 80
      Height = 25
      Caption = 'Buscar...'
      TabOrder = 1
      OnClick = btnBrowseClick
    end
    object btnInstall: TButton
      Left = 20
      Top = 100
      Width = 280
      Height = 45
      Caption = 'INSTALAR Y ACTIVAR SERVICIO'
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clWindowText
      Font.Height = -13
      Font.Name = 'Segoe UI'
      Font.Style = [fsBold]
      ParentFont = False
      TabOrder = 2
      OnClick = btnInstallClick
    end
    object btnUninstall: TButton
      Left = 310
      Top = 100
      Width = 150
      Height = 45
      Caption = 'DESINSTALAR'
      TabOrder = 4
      OnClick = btnUninstallClick
    end
    object memLog: TMemo
      Left = 20
      Top = 160
      Width = 440
      Height = 190
      Color = clBlack
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clLime
      Font.Height = -11
      Font.Name = 'Consolas'
      Font.Style = []
      ParentFont = False
      ReadOnly = True
      ScrollBars = ssVertical
      TabOrder = 3
    end
  end
end
