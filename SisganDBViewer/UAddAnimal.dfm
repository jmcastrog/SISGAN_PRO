object FormAddAnimal: TFormAddAnimal
  Left = 0
  Top = 0
  BorderStyle = bsDialog
  Caption = 'Agregar Animal'
  ClientHeight = 550
  ClientWidth = 500
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
    Width = 500
    Height = 40
    Align = alTop
    TabOrder = 0
    object lblTitulo: TLabel
      Left = 1
      Top = 1
      Width = 498
      Height = 38
      Align = alClient
      Alignment = taCenter
      Caption = 'Agregar Nuevo Animal'
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clWindowText
      Font.Height = -12
      Font.Name = 'Tahoma'
      Font.Style = [fsBold]
      ParentFont = False
      Layout = tlCenter
      ExplicitLeft = 0
      ExplicitTop = 0
      ExplicitWidth = 136
      ExplicitHeight = 14
    end
  end
  object pnlFields: TPanel
    Left = 0
    Top = 40
    Width = 500
    Height = 460
    Align = alClient
    BevelOuter = bvNone
    ParentColor = True
    TabOrder = 1
    object ScrollBox1: TScrollBox
      Left = 0
      Top = 0
      Width = 500
      Height = 410
      Align = alClient
      TabOrder = 0
      object lblNumero: TLabel
        Left = 20
        Top = 10
        Width = 41
        Height = 13
        Caption = 'N'#250'mero:'
        FocusControl = edtNumero
      end
      object lblNombre: TLabel
        Left = 253
        Top = 10
        Width = 41
        Height = 13
        Caption = 'Nombre:'
        FocusControl = edtNombre
      end
      object lblFechaNac: TLabel
        Left = 20
        Top = 40
        Width = 58
        Height = 13
        Caption = 'Fecha Nac.:'
        FocusControl = dtpFechaNac
      end
      object lblSexo: TLabel
        Left = 253
        Top = 49
        Width = 28
        Height = 13
        Caption = 'Sexo:'
        FocusControl = cmbSexo
      end
      object lblRaza: TLabel
        Left = 20
        Top = 70
        Width = 28
        Height = 13
        Caption = 'Raza:'
        FocusControl = edtRaza
      end
      object lblTipo: TLabel
        Left = 256
        Top = 79
        Width = 24
        Height = 13
        Caption = 'Tipo:'
        FocusControl = cmbTipo
      end
      object lblLote: TLabel
        Left = 20
        Top = 100
        Width = 25
        Height = 13
        Caption = 'Lote:'
        FocusControl = edtLote
      end
      object lblPropietario: TLabel
        Left = 256
        Top = 100
        Width = 56
        Height = 13
        Caption = 'Propietario:'
        FocusControl = edtPropietario
      end
      object lblNumMadre: TLabel
        Left = 20
        Top = 130
        Width = 62
        Height = 13
        Caption = 'N'#250'm. Madre:'
        FocusControl = edtNumMadre
      end
      object lblNomMadre: TLabel
        Left = 256
        Top = 125
        Width = 62
        Height = 13
        Caption = 'Nom. Madre:'
        FocusControl = edtNomMadre
      end
      object lblPadre: TLabel
        Left = 20
        Top = 160
        Width = 32
        Height = 13
        Caption = 'Padre:'
        FocusControl = edtPadre
      end
      object lblPesoNacer: TLabel
        Left = 20
        Top = 190
        Width = 79
        Height = 13
        Caption = 'Peso nacer (kg):'
        FocusControl = edtPesoNacer
      end
      object lblEstatusRepro: TLabel
        Left = 20
        Top = 220
        Width = 55
        Height = 13
        Caption = 'Est. Repro:'
        FocusControl = cmbEstatusRepro
      end
      object lblFechaPartoEst: TLabel
        Left = 240
        Top = 220
        Width = 65
        Height = 13
        Caption = 'F. Parto Est.:'
        FocusControl = dtpFechaPartoEst
      end
      object lblComentarios: TLabel
        Left = 20
        Top = 250
        Width = 64
        Height = 13
        Caption = 'Comentarios:'
        FocusControl = memComentarios
      end
      object edtNumero: TEdit
        Left = 100
        Top = 8
        Width = 100
        Height = 21
        TabOrder = 0
      end
      object edtNombre: TEdit
        Left = 338
        Top = 8
        Width = 142
        Height = 21
        TabOrder = 1
      end
      object dtpFechaNac: TDateTimePicker
        Left = 100
        Top = 38
        Width = 120
        Height = 21
        Date = 45658.000000000000000000
        Format = 'dd-MM-yyyy'
        Time = 45658.000000000000000000
        TabOrder = 2
      end
      object cmbSexo: TComboBox
        Left = 340
        Top = 35
        Width = 100
        Height = 21
        Style = csDropDownList
        ItemIndex = 0
        TabOrder = 3
        Text = 'Hembra'
        Items.Strings = (
          'Hembra'
          'Macho')
      end
      object edtRaza: TEdit
        Left = 100
        Top = 68
        Width = 150
        Height = 21
        TabOrder = 4
      end
      object cmbTipo: TComboBox
        Left = 340
        Top = 71
        Width = 138
        Height = 21
        Style = csDropDownList
        ItemIndex = 0
        TabOrder = 5
        Text = 'Vaca'
        Items.Strings = (
          'Vaca'
          'Becerra'
          'Becerro'
          'Toro'
          'Novilla'
          'Novillo'
          'Buey')
      end
      object edtLote: TEdit
        Left = 100
        Top = 98
        Width = 150
        Height = 21
        TabOrder = 6
      end
      object edtPropietario: TEdit
        Left = 338
        Top = 98
        Width = 140
        Height = 21
        TabOrder = 7
      end
      object edtNumMadre: TEdit
        Left = 100
        Top = 125
        Width = 100
        Height = 21
        TabOrder = 8
      end
      object edtNomMadre: TEdit
        Left = 338
        Top = 125
        Width = 140
        Height = 21
        TabOrder = 9
      end
      object edtPadre: TEdit
        Left = 100
        Top = 158
        Width = 200
        Height = 21
        TabOrder = 10
      end
      object edtPesoNacer: TEdit
        Left = 120
        Top = 188
        Width = 80
        Height = 21
        TabOrder = 11
      end
      object cmbEstatusRepro: TComboBox
        Left = 100
        Top = 218
        Width = 120
        Height = 21
        Style = csDropDownList
        ItemIndex = 0
        TabOrder = 12
        Text = 'Vac'#237'a'
        Items.Strings = (
          'Vac'#237'a'
          'Pre'#241'ada'
          'Gestante')
      end
      object dtpFechaPartoEst: TDateTimePicker
        Left = 340
        Top = 218
        Width = 120
        Height = 21
        Date = 45658.000000000000000000
        Format = 'dd-MM-yyyy'
        Time = 45658.000000000000000000
        TabOrder = 13
      end
      object memComentarios: TMemo
        Left = 20
        Top = 268
        Width = 440
        Height = 80
        ScrollBars = ssVertical
        TabOrder = 14
      end
      object lblEstatus: TLabel
        Left = 20
        Top = 358
        Width = 41
        Height = 13
        Caption = 'Estatus:'
        FocusControl = cmbEstatus
      end
      object cmbEstatus: TComboBox
        Left = 100
        Top = 355
        Width = 120
        Height = 21
        Style = csDropDownList
        ItemIndex = 0
        TabOrder = 15
        Text = 'Vivos'
        Items.Strings = (
          'Vivos'
          'Muertos'
          'Vendidos'
          'Desaparecido')
      end
      object lblFotoAnimal: TLabel
        Left = 20
        Top = 388
        Width = 65
        Height = 13
        Caption = 'Foto Animal:'
        FocusControl = edtFotoAnimal
      end
      object edtFotoAnimal: TEdit
        Left = 100
        Top = 385
        Width = 300
        Height = 21
        TabOrder = 16
      end
      object btnFotoAnimal: TButton
        Left = 406
        Top = 385
        Width = 75
        Height = 21
        Caption = 'Examinar...'
        TabOrder = 17
        OnClick = btnFotoAnimalClick
      end
      object lblFotoHierro: TLabel
        Left = 20
        Top = 418
        Width = 64
        Height = 13
        Caption = 'Foto Hierro:'
        FocusControl = edtFotoHierro
      end
      object edtFotoHierro: TEdit
        Left = 100
        Top = 415
        Width = 300
        Height = 21
        TabOrder = 18
      end
      object btnFotoHierro: TButton
        Left = 406
        Top = 415
        Width = 75
        Height = 21
        Caption = 'Examinar...'
        TabOrder = 19
        OnClick = btnFotoHierroClick
      end
    end
  end
  object pnlBottom: TPanel
    Left = 0
    Top = 500
    Width = 500
    Height = 50
    Align = alBottom
    TabOrder = 2
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
    object btnLimpiar: TButton
      Left = 160
      Top = 10
      Width = 100
      Height = 30
      Caption = 'Limpiar'
      TabOrder = 1
      OnClick = btnLimpiarClick
    end
    object btnCerrar: TButton
      Left = 380
      Top = 10
      Width = 100
      Height = 30
      Caption = 'Cerrar'
      TabOrder = 2
      OnClick = btnCerrarClick
    end
  end
end
