object FormControlLeche: TFormControlLeche
  Left = 0
  Top = 0
  BorderStyle = bsDialog
  Caption = 'Control Lechero - Pesadas'
  ClientHeight = 598
  ClientWidth = 538
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
    Width = 538
    Height = 49
    Align = alTop
    BevelOuter = bvNone
    ParentColor = True
    TabOrder = 0
    ExplicitTop = 8
    object lblFecha: TLabel
      Left = 12
      Top = 12
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
    object lblTurno: TLabel
      Left = 170
      Top = 12
      Width = 36
      Height = 13
      Caption = 'Turno:'
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clWindowText
      Font.Height = -11
      Font.Name = 'Tahoma'
      Font.Style = [fsBold]
      ParentFont = False
    end
    object lblTobo: TLabel
      Left = 350
      Top = 12
      Width = 106
      Height = 13
      Caption = 'Peso del tobo (kg):'
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clWindowText
      Font.Height = -11
      Font.Name = 'Tahoma'
      Font.Style = [fsBold]
      ParentFont = False
    end
    object dtpFecha: TDateTimePicker
      Left = 12
      Top = 32
      Width = 140
      Height = 21
      Date = 46180.000000000000000000
      Format = 'dd-MM-yyyy'
      Time = 0.748077939817449100
      TabOrder = 2
    end
    object rbManiana: TRadioButton
      Left = 170
      Top = 28
      Width = 73
      Height = 17
      Caption = 'Ma'#241'ana'
      Checked = True
      TabOrder = 0
      TabStop = True
    end
    object rbTarde: TRadioButton
      Left = 250
      Top = 28
      Width = 73
      Height = 17
      Caption = 'Tarde'
      TabOrder = 1
    end
    object edtTobo: TEdit
      Left = 350
      Top = 28
      Width = 80
      Height = 21
      TabOrder = 3
      OnChange = OnPesoChange
    end
  end
  object pnlSearch: TPanel
    Left = 0
    Top = 49
    Width = 538
    Height = 64
    Align = alTop
    BevelOuter = bvNone
    ParentColor = True
    TabOrder = 1
    object lblBuscar: TLabel
      Left = 12
      Top = 8
      Width = 185
      Height = 13
      Caption = 'Buscar vaca (n'#250'mero o nombre):'
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clWindowText
      Font.Height = -11
      Font.Name = 'Tahoma'
      Font.Style = [fsBold]
      ParentFont = False
    end
    object lblPeso: TLabel
      Left = 280
      Top = 8
      Width = 126
      Height = 13
      Caption = 'Peso bruto (con tobo):'
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clWindowText
      Font.Height = -11
      Font.Name = 'Tahoma'
      Font.Style = [fsBold]
      ParentFont = False
    end
    object lblNeto: TLabel
      Left = 280
      Top = 52
      Width = 59
      Height = 13
      Caption = 'Neto: -- kg'
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clBlue
      Font.Height = -11
      Font.Name = 'Tahoma'
      Font.Style = [fsBold]
      ParentFont = False
    end
    object edtBuscar: TEdit
      Left = 12
      Top = 26
      Width = 250
      Height = 21
      TabOrder = 1
      OnChange = OnBuscarChange
      OnKeyDown = OnBuscarKeyDown
    end
    object edtPeso: TEdit
      Left = 280
      Top = 26
      Width = 100
      Height = 21
      TabOrder = 2
      OnChange = OnPesoChange
      OnKeyDown = OnPesoKeyDown
    end
    object btnAgregar: TButton
      Left = 400
      Top = 24
      Width = 100
      Height = 28
      Caption = 'Agregar'
      TabOrder = 0
      OnClick = OnAgregarClick
    end
  end
  object lbFechas: TListBox
    Left = 8
    Top = 51
    Width = 144
    Height = 200
    ItemHeight = 13
    TabOrder = 2
    Visible = False
    OnClick = OnFechaClick
  end
  object lbSugerencias: TListBox
    Left = 8
    Top = 153
    Width = 254
    Height = 120
    ItemHeight = 13
    TabOrder = 3
    Visible = False
    OnClick = OnSugerenciaClick
    OnDblClick = OnSugerenciaDblClick
  end
  object pnlClient: TPanel
    Left = 0
    Top = 113
    Width = 538
    Height = 435
    Align = alClient
    BevelOuter = bvNone
    ParentColor = True
    TabOrder = 4
    ExplicitTop = 127
    ExplicitWidth = 577
    ExplicitHeight = 400
    object lblCount: TLabel
      Left = 12
      Top = 0
      Width = 43
      Height = 13
      Caption = '0 vacas'
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clWindowText
      Font.Height = -11
      Font.Name = 'Tahoma'
      Font.Style = [fsBold]
      ParentFont = False
    end
    object lblTotal: TLabel
      Left = 120
      Top = 0
      Width = 59
      Height = 13
      Caption = 'Total: 0 kg'
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clWindowText
      Font.Height = -11
      Font.Name = 'Tahoma'
      Font.Style = [fsBold]
      ParentFont = False
    end
    object sgLista: TStringGrid
      Left = 12
      Top = 17
      Width = 513
      Height = 404
      ColCount = 5
      FixedCols = 0
      RowCount = 2
      Options = [goFixedVertLine, goFixedHorzLine, goVertLine, goHorzLine, goRangeSelect, goDrawFocusSelected, goEditing, goAlwaysShowEditor]
      ScrollBars = ssVertical
      TabOrder = 0
      OnKeyDown = OnGridKeyDown
      OnSetEditText = OnGridSetEditText
      ColWidths = (
        80
        180
        80
        100
        100)
    end
  end
  object pnlBottom: TPanel
    Left = 0
    Top = 548
    Width = 538
    Height = 50
    Align = alBottom
    BevelOuter = bvNone
    ParentColor = True
    TabOrder = 5
    ExplicitTop = 470
    ExplicitWidth = 634
    object btnGrabar: TButton
      Left = 6
      Top = 6
      Width = 75
      Height = 30
      Caption = 'GRABAR'
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
    object btnConsultar: TButton
      Left = 87
      Top = 6
      Width = 65
      Height = 30
      Caption = 'Consultar'
      TabOrder = 1
      OnClick = OnConsultarClick
    end
    object btnEliminar: TButton
      Left = 158
      Top = 6
      Width = 65
      Height = 30
      Caption = 'Eliminar'
      Enabled = False
      TabOrder = 2
      OnClick = OnEliminarClick
    end
    object btnCargarRef: TButton
      Left = 229
      Top = 6
      Width = 75
      Height = 30
      Caption = 'Cargar ref.'
      TabOrder = 3
      OnClick = OnCargarRefClick
    end
    object btnLimpiar: TButton
      Left = 310
      Top = 6
      Width = 65
      Height = 30
      Caption = 'Limpiar'
      TabOrder = 4
      OnClick = OnLimpiarClick
    end
    object btnCerrar: TButton
      Left = 381
      Top = 6
      Width = 65
      Height = 30
      Caption = 'Cerrar'
      TabOrder = 5
      OnClick = OnCerrarClick
    end
    object lblSumNeto: TLabel
      Left = 458
      Top = 2
      Width = 74
      Height = 13
      Caption = 'Neto: 0 kg'
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clNavy
      Font.Height = -12
      Font.Name = 'Tahoma'
      Font.Style = [fsBold]
      ParentFont = False
    end
    object lblPromNeto: TLabel
      Left = 458
      Top = 18
      Width = 74
      Height = 13
      Caption = 'Prom: 0 kg'
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clNavy
      Font.Height = -12
      Font.Name = 'Tahoma'
      Font.Style = [fsBold]
      ParentFont = False
    end
  end
  object TimerSugerir: TTimer
    Enabled = False
    Interval = 250
    OnTimer = OnSugerirTimer
  end
end
