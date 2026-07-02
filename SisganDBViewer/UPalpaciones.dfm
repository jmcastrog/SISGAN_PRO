object FormPalpaciones: TFormPalpaciones
  Left = 0
  Top = 0
  BorderStyle = bsDialog
  Caption = 'Palpaciones'
  ClientHeight = 540
  ClientWidth = 650
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'Tahoma'
  Font.Style = []
  OldCreateOrder = False
  Position = poScreenCenter
  OnCreate = FormCreate
  OnDestroy = FormDestroy
  OnShow = FormShow
  PixelsPerInch = 96
  TextHeight = 13
  object pnlTop: TPanel
    Left = 0
    Top = 0
    Width = 650
    Height = 90
    Align = alTop
    BevelOuter = bvNone
    ParentColor = True
    TabOrder = 0
    object lblTitulo: TLabel
      Left = 12
      Top = 8
      Width = 188
      Height = 14
      Caption = 'Registrar Palpaciones por Lote'
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clWindowText
      Font.Height = -12
      Font.Name = 'Tahoma'
      Font.Style = [fsBold]
      ParentFont = False
    end
    object lblFecha: TLabel
      Left = 12
      Top = 32
      Width = 36
      Height = 13
      Caption = 'Fecha:'
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clWindowText
      Font.Height = -11
      Font.Name = 'Tahoma'
      Font.Style = [fsBold]
      ParentFont = False
    end
    object lblTecnico: TLabel
      Left = 160
      Top = 32
      Width = 46
      Height = 13
      Caption = 'T'#233'cnico:'
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clWindowText
      Font.Height = -11
      Font.Name = 'Tahoma'
      Font.Style = [fsBold]
      ParentFont = False
    end
    object dtpFecha: TDateTimePicker
      Left = 12
      Top = 50
      Width = 120
      Height = 21
      Date = 46180.000000000000000000
      Format = 'dd-MM-yyyy'
      Time = 0.799174884261447000
      TabOrder = 0
    end
    object edtTecnico: TEdit
      Left = 160
      Top = 50
      Width = 150
      Height = 21
      TabOrder = 1
    end
  end
  object pnlSearch: TPanel
    Left = 0
    Top = 90
    Width = 650
    Height = 110
    Align = alTop
    BevelOuter = bvNone
    ParentColor = True
    TabOrder = 1
    object lblBuscar: TLabel
      Left = 12
      Top = 6
      Width = 42
      Height = 13
      Caption = 'Animal:'
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clWindowText
      Font.Height = -11
      Font.Name = 'Tahoma'
      Font.Style = [fsBold]
      ParentFont = False
    end
    object lblDiagnostico: TLabel
      Left = 250
      Top = 6
      Width = 69
      Height = 13
      Caption = 'Diagn'#243'stico:'
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clWindowText
      Font.Height = -11
      Font.Name = 'Tahoma'
      Font.Style = [fsBold]
      ParentFont = False
    end
    object lblDiasPrenez: TLabel
      Left = 12
      Top = 60
      Width = 69
      Height = 13
      Caption = 'D'#237'as Pre'#241'ez:'
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clWindowText
      Font.Height = -11
      Font.Name = 'Tahoma'
      Font.Style = [fsBold]
      ParentFont = False
    end
    object lblObservaciones: TLabel
      Left = 180
      Top = 60
      Width = 86
      Height = 13
      Caption = 'Observaciones:'
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clWindowText
      Font.Height = -11
      Font.Name = 'Tahoma'
      Font.Style = [fsBold]
      ParentFont = False
    end
    object edtBuscar: TEdit
      Left = 12
      Top = 24
      Width = 220
      Height = 21
      TabOrder = 1
      OnChange = OnBuscarChange
      OnKeyDown = OnBuscarKeyDown
    end
    object cmbDiagnostico: TComboBox
      Left = 250
      Top = 24
      Width = 130
      Height = 21
      Style = csDropDownList
      TabOrder = 2
    end
    object btnAgregar: TButton
      Left = 400
      Top = 22
      Width = 100
      Height = 28
      Caption = 'Agregar'
      TabOrder = 3
      OnClick = OnAgregarClick
    end
    object lbSugerencias: TListBox
      Left = 12
      Top = 48
      Width = 220
      Height = 130
      ItemHeight = 13
      TabOrder = 0
      Visible = False
      OnClick = OnSugerenciaClick
    end
    object edtDiasPrenez: TEdit
      Left = 100
      Top = 58
      Width = 60
      Height = 21
      TabOrder = 4
      Text = '0'
    end
    object edtObservaciones: TEdit
      Left = 290
      Top = 58
      Width = 240
      Height = 21
      TabOrder = 5
    end
  end
  object pnlList: TPanel
    Left = 0
    Top = 200
    Width = 650
    Height = 290
    Align = alClient
    BevelOuter = bvNone
    ParentColor = True
    TabOrder = 2
    object lblCount: TLabel
      Left = 12
      Top = 8
      Width = 77
      Height = 13
      Caption = '0 palpaciones'
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clWindowText
      Font.Height = -11
      Font.Name = 'Tahoma'
      Font.Style = [fsBold]
      ParentFont = False
    end
    object sgLista: TStringGrid
      Left = 12
      Top = 30
      Width = 618
      Height = 250
      FixedCols = 0
      RowCount = 2
      Options = [goFixedVertLine, goFixedHorzLine, goVertLine, goHorzLine, goRangeSelect, goEditing]
      ScrollBars = ssVertical
      TabOrder = 0
      OnSetEditText = sgListaSetEditText
      ColWidths = (
        70
        140
        100
        50
        200)
    end
  end
  object pnlBottom: TPanel
    Left = 0
    Top = 490
    Width = 650
    Height = 50
    Align = alBottom
    BevelOuter = bvNone
    ParentColor = True
    TabOrder = 3
    object btnGrabar: TButton
      Left = 12
      Top = 10
      Width = 130
      Height = 30
      Caption = 'GRABAR EN BD'
      Enabled = False
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clWindowText
      Font.Height = -11
      Font.Name = 'Tahoma'
      Font.Style = [fsBold]
      ParentFont = False
      TabOrder = 0
      OnClick = OnGrabarClick
    end
    object btnLimpiar: TButton
      Left = 160
      Top = 10
      Width = 100
      Height = 30
      Caption = 'Limpiar'
      TabOrder = 1
      OnClick = OnLimpiarClick
    end
    object btnConsultar: TButton
      Left = 280
      Top = 10
      Width = 100
      Height = 30
      Caption = 'Consultar'
      TabOrder = 2
      OnClick = OnConsultarClick
    end
    object btnCerrar: TButton
      Left = 530
      Top = 10
      Width = 100
      Height = 30
      Caption = 'Cerrar'
      TabOrder = 3
      OnClick = OnCerrarClick
    end
  end
  object lbFechas: TListBox
    Left = 12
    Top = 74
    Width = 120
    Height = 150
    ItemHeight = 13
    TabOrder = 4
    Visible = False
    OnClick = OnFechaClick
  end
  object TimerSugerir: TTimer
    Enabled = False
    Interval = 250
    OnTimer = OnSugerirTimer
  end
end
