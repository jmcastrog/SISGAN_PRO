object Form1: TForm1
  Left = 0
  Top = 0
  Caption = 'SISGAN DB Viewer'
  ClientHeight = 520
  ClientWidth = 784
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'Tahoma'
  Font.Style = []
  Menu = MainMenu1
  OldCreateOrder = True
  Position = poScreenCenter
  OnCloseQuery = FormCloseQuery
  OnCreate = FormCreate
  OnDestroy = FormDestroy
  PixelsPerInch = 96
  TextHeight = 13
  object Splitter1: TSplitter
    Left = 150
    Top = 120
    Height = 321
    ExplicitLeft = 200
  end
  object PanelTop: TPanel
    Left = 0
    Top = 0
    Width = 784
    Height = 120
    Align = alTop
    Color = 4535328
    ParentBackground = False
    TabOrder = 0
    object Label1: TLabel
      Left = 16
      Top = 13
      Width = 102
      Height = 13
      Caption = 'Seleccionar Tabla:'
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clWhite
      Font.Height = -11
      Font.Name = 'Tahoma'
      Font.Style = [fsBold]
      ParentFont = False
    end
    object Label2: TLabel
      Left = 16
      Top = 65
      Width = 103
      Height = 13
      Caption = 'Filtrar Resultados:'
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clWhite
      Font.Height = -11
      Font.Name = 'Tahoma'
      Font.Style = [fsBold]
      ParentFont = False
    end
    object lblFilterEstatus: TLabel
      Left = 16
      Top = 93
      Width = 45
      Height = 13
      Caption = 'Estatus:'
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clWhite
      Font.Height = -11
      Font.Name = 'Tahoma'
      Font.Style = [fsBold]
      ParentFont = False
    end
    object lblFilterTipo: TLabel
      Left = 200
      Top = 93
      Width = 27
      Height = 13
      Caption = 'Tipo:'
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clWhite
      Font.Height = -11
      Font.Name = 'Tahoma'
      Font.Style = [fsBold]
      ParentFont = False
    end
    object lblFilterLote: TLabel
      Left = 368
      Top = 93
      Width = 28
      Height = 13
      Caption = 'Lote:'
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clWhite
      Font.Height = -11
      Font.Name = 'Tahoma'
      Font.Style = [fsBold]
      ParentFont = False
    end
    object lblFilterPropietario: TLabel
      Left = 528
      Top = 93
      Width = 66
      Height = 13
      Caption = 'Propietario:'
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clWhite
      Font.Height = -11
      Font.Name = 'Tahoma'
      Font.Style = [fsBold]
      ParentFont = False
    end
    object cbTables: TComboBox
      Left = 16
      Top = 32
      Width = 140
      Height = 21
      Style = csDropDownList
      TabOrder = 0
      OnChange = cbTablesChange
    end
    object btnRefresh: TButton
      Left = 162
      Top = 31
      Width = 87
      Height = 25
      Caption = 'Aplicar Cambios'
      TabOrder = 1
      OnClick = btnRefreshClick
    end
    object btnDelete: TButton
      Left = 339
      Top = 30
      Width = 80
      Height = 25
      Caption = 'Eliminar'
      TabOrder = 5
      OnClick = btnDeleteClick
    end
    object btnAdd: TButton
      Left = 253
      Top = 30
      Width = 80
      Height = 25
      Caption = 'Agregar'
      TabOrder = 12
      OnClick = btnAddClick
    end
    object btnUndo: TButton
      Left = 425
      Top = 30
      Width = 80
      Height = 25
      Caption = 'Deshacer'
      Enabled = False
      TabOrder = 11
      OnClick = btnUndoClick
    end
    object btnExportPDF: TButton
      Left = 510
      Top = 30
      Width = 140
      Height = 25
      Caption = 'Imprimir / Exportar a PDF'
      TabOrder = 2
      OnClick = btnExportPDFClick
    end
    object btnTogglePanel: TButton
      Left = 655
      Top = 30
      Width = 95
      Height = 25
      Caption = 'Mostrar Panel'
      TabOrder = 3
      OnClick = btnTogglePanelClick
    end
    object btnCloseApp: TButton
      Left = 655
      Top = 62
      Width = 115
      Height = 35
      Caption = 'CERRAR SERVIDOR'
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clRed
      Font.Height = -11
      Font.Name = 'Tahoma'
      Font.Style = [fsBold]
      ParentFont = False
      TabOrder = 10
      OnClick = btnCloseAppClick
    end
    object edtFilter: TEdit
      Left = 125
      Top = 61
      Width = 379
      Height = 21
      TabOrder = 4
      TextHint = 'Escribe aqu'#237' para buscar o filtrar en la tabla...'
      OnChange = edtFilterChange
    end
    object btnFilterEstatus: TButton
      Left = 16
      Top = 89
      Width = 140
      Height = 25
      Caption = 'Estatus...'
      TabOrder = 6
      OnClick = btnFilterClick
    end
    object btnFilterTipo: TButton
      Left = 170
      Top = 89
      Width = 140
      Height = 25
      Caption = 'Tipo...'
      TabOrder = 7
      OnClick = btnFilterClick
    end
    object btnFilterLote: TButton
      Left = 325
      Top = 89
      Width = 140
      Height = 25
      Caption = 'Lote...'
      TabOrder = 8
      OnClick = btnFilterClick
    end
    object btnFilterPropietario: TButton
      Left = 480
      Top = 89
      Width = 140
      Height = 25
      Caption = 'Propietario...'
      TabOrder = 9
      OnClick = btnFilterClick
    end
  end
  object cklFilterEstatus: TCheckListBox
    Left = 16
    Top = 114
    Width = 140
    Height = 150
    OnClickCheck = FilterComboChange
    ItemHeight = 13
    TabOrder = 3
    Visible = False
  end
  object cklFilterTipo: TCheckListBox
    Left = 170
    Top = 114
    Width = 140
    Height = 150
    OnClickCheck = FilterComboChange
    ItemHeight = 13
    TabOrder = 4
    Visible = False
  end
  object cklFilterLote: TCheckListBox
    Left = 325
    Top = 114
    Width = 140
    Height = 150
    OnClickCheck = FilterComboChange
    ItemHeight = 13
    TabOrder = 5
    Visible = False
  end
  object cklFilterPropietario: TCheckListBox
    Left = 480
    Top = 114
    Width = 140
    Height = 150
    OnClickCheck = FilterComboChange
    ItemHeight = 13
    TabOrder = 6
    Visible = False
  end
  object PanelLeft: TPanel
    Left = 0
    Top = 120
    Width = 150
    Height = 321
    Align = alLeft
    TabOrder = 1
    object chkColumns: TCheckListBox
      Left = 1
      Top = 1
      Width = 148
      Height = 319
      OnClickCheck = chkColumnsClickCheck
      Align = alClient
      DragMode = dmAutomatic
      ItemHeight = 13
      TabOrder = 0
      OnDragDrop = chkColumnsDragDrop
      OnDragOver = chkColumnsDragOver
    end
  end
  object DBGrid1: TDBGrid
    Left = 153
    Top = 120
    Width = 631
    Height = 321
    Align = alClient
    DataSource = DataSource1
    TabOrder = 2
    TitleFont.Charset = DEFAULT_CHARSET
    TitleFont.Color = clWindowText
    TitleFont.Height = -11
    TitleFont.Name = 'Tahoma'
    TitleFont.Style = []
    OnDblClick = DBGrid1DblClick
    OnTitleClick = DBGrid1TitleClick
  end
  object DataSource1: TDataSource
    Left = 360
    Top = 208
  end
  object MainMenu1: TMainMenu
    Left = 424
    Top = 208
    object MenuArchivo: TMenuItem
      Caption = 'Archivo'
      object Salir1: TMenuItem
        Caption = 'Salir'
        OnClick = btnCloseAppClick
      end
    end
    object IniciarDetenerServicio1: TMenuItem
      Caption = 'Iniciar/Detener Servicio'
      Visible = False
      OnClick = nil
    end
    object MenuHerramientas: TMenuItem
      Caption = 'Herramientas'
    end
    object MenuEstilo: TMenuItem
      Caption = 'Estilo'
    end
  end
  object pnlSummary: TPanel
    Left = 0
    Top = 441
    Width = 784
    Height = 79
    Align = alBottom
    TabOrder = 7
    object pnlSumAnimales: TPanel
      Left = 8
      Top = 6
      Width = 185
      Height = 67
      BevelOuter = bvNone
      TabOrder = 0
      object lblSumAnimalesTit: TLabel
        Left = 8
        Top = 4
        Width = 169
        Height = 13
        Caption = 'Total Animales'
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clWindowText
        Font.Height = -11
        Font.Name = 'Tahoma'
        Font.Style = [fsBold]
        ParentFont = False
      end
      object lblAnimalTotal: TLabel
        Left = 8
        Top = 23
        Width = 50
        Height = 27
        Caption = '0'
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clWindowText
        Font.Height = -24
        Font.Name = 'Tahoma'
        Font.Style = [fsBold]
        ParentFont = False
      end
      object lblSumAnimalDet: TLabel
        Left = 64
        Top = 30
        Width = 110
        Height = 13
        Caption = 'Hembras: 0'
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clWindowText
        Font.Height = -11
        Font.Name = 'Tahoma'
        Font.Style = []
        ParentFont = False
      end
    end
    object pnlSumLeche: TPanel
      Left = 199
      Top = 6
      Width = 185
      Height = 67
      BevelOuter = bvNone
      TabOrder = 1
      object lblSumLecheTit: TLabel
        Left = 8
        Top = 4
        Width = 74
        Height = 13
        Caption = 'Producci'#243'n'
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clWindowText
        Font.Height = -11
        Font.Name = 'Tahoma'
        Font.Style = [fsBold]
        ParentFont = False
      end
      object lblLecheVal: TLabel
        Left = 8
        Top = 20
        Width = 36
        Height = 23
        Caption = '0 lt'
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clWindowText
        Font.Height = -19
        Font.Name = 'Tahoma'
        Font.Style = [fsBold]
        ParentFont = False
      end
      object lblQuesoVal: TLabel
        Left = 8
        Top = 46
        Width = 37
        Height = 16
        Caption = '0 kg'
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clWindowText
        Font.Height = -13
        Font.Name = 'Tahoma'
        Font.Style = []
        ParentFont = False
      end
    end
    object pnlSumPartos: TPanel
      Left = 390
      Top = 6
      Width = 185
      Height = 67
      BevelOuter = bvNone
      TabOrder = 2
      object lblSumPartosTit: TLabel
        Left = 8
        Top = 4
        Width = 37
        Height = 13
        Caption = 'Partos'
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clWindowText
        Font.Height = -11
        Font.Name = 'Tahoma'
        Font.Style = [fsBold]
        ParentFont = False
      end
      object lblPartosTotal: TLabel
        Left = 8
        Top = 20
        Width = 27
        Height = 23
        Caption = '0'
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clWindowText
        Font.Height = -19
        Font.Name = 'Tahoma'
        Font.Style = [fsBold]
        ParentFont = False
      end
      object lblPartosDet: TLabel
        Left = 8
        Top = 46
        Width = 94
        Height = 13
        Caption = '7 d'#237'as: 0'
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clWindowText
        Font.Height = -11
        Font.Name = 'Tahoma'
        Font.Style = []
        ParentFont = False
      end
    end
  end
  object TimerUndo: TTimer
    Enabled = False
    Interval = 15000
    OnTimer = TimerUndoTimer
    Left = 496
    Top = 208
  end
end
