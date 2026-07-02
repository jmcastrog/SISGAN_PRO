object IndividualCard: TIndividualCard
  Left = 0
  Top = 0
  Caption = 'Ficha Individual'
  ClientHeight = 500
  ClientWidth = 450
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
    Width = 450
    Height = 50
    Align = alTop
    TabOrder = 0
    object lblTitle: TLabel
      Left = 16
      Top = 16
      Width = 68
      Height = 16
      Caption = 'Animal #'
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clWindowText
      Font.Height = -13
      Font.Name = 'Tahoma'
      Font.Style = [fsBold]
      ParentFont = False
    end
    object btnClose: TButton
      Left = 280
      Top = 12
      Width = 75
      Height = 25
      Caption = 'Cerrar'
      TabOrder = 0
      OnClick = btnCloseClick
    end
    object btnSave: TButton
      Left = 361
      Top = 12
      Width = 75
      Height = 25
      Caption = 'Guardar'
      TabOrder = 1
      OnClick = btnSaveClick
    end
  end
  object PanelFields: TPanel
    Left = 0
    Top = 50
    Width = 450
    Height = 450
    Align = alClient
    TabOrder = 1
    object ScrollBox1: TScrollBox
      Left = 1
      Top = 1
      Width = 448
      Height = 448
      Align = alClient
      TabOrder = 0
    end
  end
end
