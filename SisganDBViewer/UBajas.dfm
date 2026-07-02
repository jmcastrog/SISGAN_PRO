object FormBajas: TFormBajas
  Left = 0
  Top = 0
  Caption = 'Registrar Baja'
  ClientHeight = 500
  ClientWidth = 500
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'Tahoma'
  Font.Style = []
  OldCreateOrder = False
  Position = poScreenCenter
  BorderStyle = bsDialog
  OnCreate = FormCreate
  OnDestroy = FormDestroy
  OnShow = FormShow
  PixelsPerInch = 96
  TextHeight = 13
  object pnlTop: TPanel
    Left = 0
    Top = 0
    Width = 500
    Height = 40
    Align = alTop
    TabOrder = 0
    ExplicitLeft = 152
    ExplicitTop = 144
    ExplicitWidth = 185
    object lblTitulo: TLabel
      Left = 1
      Top = 1
      Width = 498
      Height = 38
      Align = alClient
      Alignment = taCenter
      Caption = 'Registrar Baja de Animal'
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clWindowText
      Font.Height = -12
      Font.Name = 'Tahoma'
      Font.Style = [fsBold]
      Layout = tlCenter
      ParentFont = False
      ExplicitWidth = 142
      ExplicitHeight = 14
    end
  end
  object pnlCampos: TPanel
    Left = 0
    Top = 40
    Width = 500
    Height = 410
    Align = alClient
    BevelOuter = bvNone
    ParentColor = True
    TabOrder = 1
    ExplicitLeft = 152
    ExplicitTop = 144
    ExplicitWidth = 185
    ExplicitHeight = 41
    object lblFecha: TLabel
      Left = 20
      Top = 12
      Width = 37
      Height = 13
      Caption = 'Fecha:'
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clWindowText
      Font.Height = -11
      Font.Name = 'Tahoma'
      Font.Style = [fsBold]
      ParentFont = False
    end
    object dtpFecha: TDateTimePicker
      Left = 20
      Top = 30
      Width = 120
      Height = 21
      Date = 45699.000000000000000000
      Time = 45699.000000000000000000
      Format = 'dd-MM-yyyy'
      TabOrder = 0
    end
    object lblAnimal: TLabel
      Left = 180
      Top = 12
      Width = 40
      Height = 13
      Caption = 'Animal:'
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clWindowText
      Font.Height = -11
      Font.Name = 'Tahoma'
      Font.Style = [fsBold]
      ParentFont = False
    end
    object edtBuscar: TEdit
      Left = 180
      Top = 30
      Width = 280
      Height = 21
      TabOrder = 1
      TextHint = 'Buscar animal...'
      OnChange = OnBuscarChange
      OnKeyDown = OnBuscarKeyDown
    end
    object lbSugerencias: TListBox
      Left = 180
      Top = 52
      Width = 280
      Height = 130
      ItemHeight = 13
      TabOrder = 2
      Visible = False
      OnClick = OnSugerenciaClick
    end
    object lblTipoBaja: TLabel
      Left = 20
      Top = 70
      Width = 65
      Height = 13
      Caption = 'Tipo de baja:'
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clWindowText
      Font.Height = -11
      Font.Name = 'Tahoma'
      Font.Style = [fsBold]
      ParentFont = False
    end
    object cmbTipoBaja: TComboBox
      Left = 20
      Top = 88
      Width = 130
      Height = 21
      Style = csDropDownList
      TabOrder = 3
      OnChange = cmbTipoBajaChange
    end
    object lblCausa: TLabel
      Left = 180
      Top = 70
      Width = 37
      Height = 13
      Caption = 'Causa:'
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clWindowText
      Font.Height = -11
      Font.Name = 'Tahoma'
      Font.Style = [fsBold]
      ParentFont = False
    end
    object memCausa: TMemo
      Left = 180
      Top = 88
      Width = 280
      Height = 60
      ScrollBars = ssVertical
      TabOrder = 4
    end
    object lblComprador: TLabel
      Left = 20
      Top = 120
      Width = 61
      Height = 13
      Caption = 'Comprador:'
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clWindowText
      Font.Height = -11
      Font.Name = 'Tahoma'
      Font.Style = [fsBold]
      ParentFont = False
    end
    object edtComprador: TEdit
      Left = 20
      Top = 138
      Width = 200
      Height = 21
      Enabled = False
      TabOrder = 5
    end
    object lblPrecio: TLabel
      Left = 240
      Top = 120
      Width = 68
      Height = 13
      Caption = 'Precio total:'
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clWindowText
      Font.Height = -11
      Font.Name = 'Tahoma'
      Font.Style = [fsBold]
      ParentFont = False
    end
    object edtPrecio: TEdit
      Left = 240
      Top = 138
      Width = 100
      Height = 21
      Enabled = False
      TabOrder = 6
    end
    object lblPesoVenta: TLabel
      Left = 20
      Top = 170
      Width = 86
      Height = 13
      Caption = 'Peso venta (kg):'
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clWindowText
      Font.Height = -11
      Font.Name = 'Tahoma'
      Font.Style = [fsBold]
      ParentFont = False
    end
    object edtPesoVenta: TEdit
      Left = 120
      Top = 168
      Width = 100
      Height = 21
      Enabled = False
      TabOrder = 7
    end
    object lblGuia: TLabel
      Left = 240
      Top = 170
      Width = 102
      Height = 13
      Caption = 'Gu'#237'a movilizaci'#243'n:'
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clWindowText
      Font.Height = -11
      Font.Name = 'Tahoma'
      Font.Style = [fsBold]
      ParentFont = False
    end
    object edtGuia: TEdit
      Left = 360
      Top = 168
      Width = 100
      Height = 21
      Enabled = False
      TabOrder = 8
    end
    object lblSeguro: TLabel
      Left = 20
      Top = 200
      Width = 74
      Height = 13
      Caption = 'Tiene seguro:'
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clWindowText
      Font.Height = -11
      Font.Name = 'Tahoma'
      Font.Style = [fsBold]
      ParentFont = False
    end
    object cmbSeguro: TComboBox
      Left = 20
      Top = 218
      Width = 80
      Height = 21
      Style = csDropDownList
      TabOrder = 9
    end
    object lblObservaciones: TLabel
      Left = 20
      Top = 250
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
    object memObservaciones: TMemo
      Left = 20
      Top = 268
      Width = 440
      Height = 80
      ScrollBars = ssVertical
      TabOrder = 10
    end
  end
  object pnlBottom: TPanel
    Left = 0
    Top = 450
    Width = 500
    Height = 50
    Align = alBottom
    BevelOuter = bvNone
    ParentColor = True
    TabOrder = 2
    ExplicitLeft = 152
    ExplicitTop = 144
    ExplicitWidth = 185
    object btnGuardar: TButton
      Left = 20
      Top = 10
      Width = 120
      Height = 30
      Caption = 'GUARDAR'
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clWindowText
      Font.Height = -11
      Font.Name = 'Tahoma'
      Font.Style = [fsBold]
      ParentFont = False
      TabOrder = 0
      OnClick = btnGuardarClick
    end
    object btnCerrar: TButton
      Left = 360
      Top = 10
      Width = 100
      Height = 30
      Caption = 'Cerrar'
      TabOrder = 1
      OnClick = btnCerrarClick
    end
  end
end
