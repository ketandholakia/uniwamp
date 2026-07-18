object AppSettingsForm: TAppSettingsForm
  Left = 0
  Top = 0
  Caption = 'Application Settings'
  ClientHeight = 620
  ClientWidth = 880
  Color = clWhite
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -12
  Font.Name = 'Segoe UI'
  Font.Style = []
  KeyPreview = True
  Position = poScreenCenter
  TextHeight = 15
  object FHeaderPanel: TPanel
    Left = 0
    Top = 0
    Width = 880
    Height = 92
    Align = alTop
    BevelOuter = bvNone
    Color = 6229470
    ParentBackground = False
    TabOrder = 0
    object FTitleLabel: TLabel
      Left = 18
      Top = 13
      Width = 185
      Height = 25
      Caption = 'Application Settings'
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clWhite
      Font.Height = -17
      Font.Name = 'Segoe UI'
      Font.Style = [fsBold]
      ParentFont = False
    end
    object FHintLabel: TLabel
      Left = 18
      Top = 42
      Width = 640
      Height = 14
      Caption = 'Edit the core UniWamp configuration that drives the dashboard and generated runtime files.'
      Font.Charset = DEFAULT_CHARSET
      Font.Color = 13689820
      Font.Height = -10
      Font.Name = 'Segoe UI'
      Font.Style = []
      ParentFont = False
    end
  end
  object FPageControl: TPageControl
    Left = 0
    Top = 92
    Width = 880
    Height = 464
    ActivePage = FGeneralTab
    Align = alClient
    TabOrder = 1
    object FGeneralTab: TTabSheet
      Caption = 'General'
      object FGeneralCard: TPanel
        Left = 16
        Top = 16
        Width = 520
        Height = 340
        BevelKind = bkTile
        BevelOuter = bvNone
        Color = clWhite
        ParentBackground = False
        TabOrder = 0
        object FGeneralTitle: TLabel
          Left = 18
          Top = 16
          Width = 93
          Height = 15
          Caption = 'Application info'
          Font.Height = -11
          Font.Style = [fsBold]
          ParentFont = False
        end
        object FHostNameLabel: TLabel
          Left = 18
          Top = 50
          Width = 59
          Height = 15
          Caption = 'Host name'
          Font.Height = -11
          Font.Style = [fsBold]
          ParentFont = False
        end
        object FHostNameEdit: TEdit
          Left = 18
          Top = 70
          Width = 464
          Height = 23
          TabOrder = 0
        end
        object FDocumentRootLabel: TLabel
          Left = 18
          Top = 112
          Width = 78
          Height = 15
          Caption = 'Document root'
          Font.Height = -11
          Font.Style = [fsBold]
          ParentFont = False
        end
        object FDocumentRootEdit: TEdit
          Left = 18
          Top = 132
          Width = 464
          Height = 23
          TabOrder = 1
        end
        object FTerminalPathLabel: TLabel
          Left = 18
          Top = 172
          Width = 148
          Height = 15
          Caption = 'Terminal executable path'
          Font.Height = -11
          Font.Style = [fsBold]
          ParentFont = False
        end
        object FTerminalPathEdit: TEdit
          Left = 18
          Top = 192
          Width = 464
          Height = 23
          TabOrder = 2
        end
        object FEnableSslCheck: TCheckBox
          Left = 18
          Top = 236
          Width = 250
          Height = 19
          Caption = 'Enable SSL for the local Apache site'
          TabOrder = 3
        end
        object FStartAllOnLaunchCheck: TCheckBox
          Left = 18
          Top = 260
          Width = 290
          Height = 19
          Caption = 'Start all services when UniWamp launches'
          TabOrder = 4
        end
        object FOpenDashboardAfterStartCheck: TCheckBox
          Left = 18
          Top = 284
          Width = 320
          Height = 19
          Caption = 'Open dashboard after services start'
          TabOrder = 5
        end
        object FConfirmVHostDeleteCheck: TCheckBox
          Left = 18
          Top = 308
          Width = 380
          Height = 19
          Caption = 'Ask for confirmation before deleting a vHost/project'
          TabOrder = 6
        end
        object FThemeStyleLabel: TLabel
          Left = 18
          Top = 344
          Width = 66
          Height = 15
          Caption = 'Theme style'
          Font.Height = -11
          Font.Style = [fsBold]
          ParentFont = False
        end
        object FThemeStyleCombo: TComboBox
          Left = 18
          Top = 364
          Width = 210
          Height = 23
          Style = csDropDownList
          TabOrder = 7
        end
      end
      object FPortCard: TPanel
        Left = 550
        Top = 16
        Width = 290
        Height = 340
        BevelKind = bkTile
        BevelOuter = bvNone
        Color = clWhite
        ParentBackground = False
        TabOrder = 1
        object FPortTitle: TLabel
          Left = 18
          Top = 16
          Width = 55
          Height = 15
          Caption = 'Ports'
          Font.Height = -11
          Font.Style = [fsBold]
          ParentFont = False
        end
        object FHttpPortLabel: TLabel
          Left = 18
          Top = 50
          Width = 57
          Height = 15
          Caption = 'HTTP port'
          Font.Height = -11
          Font.Style = [fsBold]
          ParentFont = False
        end
        object FHttpPortEdit: TEdit
          Left = 18
          Top = 70
          Width = 122
          Height = 23
          TabOrder = 0
        end
        object FHttpsPortLabel: TLabel
          Left = 18
          Top = 112
          Width = 64
          Height = 15
          Caption = 'HTTPS port'
          Font.Height = -11
          Font.Style = [fsBold]
          ParentFont = False
        end
        object FHttpsPortEdit: TEdit
          Left = 18
          Top = 132
          Width = 122
          Height = 23
          TabOrder = 1
        end
        object FDatabasePortLabel: TLabel
          Left = 18
          Top = 172
          Width = 82
          Height = 15
          Caption = 'Database port'
          Font.Height = -11
          Font.Style = [fsBold]
          ParentFont = False
        end
        object FDatabasePortEdit: TEdit
          Left = 18
          Top = 192
          Width = 122
          Height = 23
          TabOrder = 2
        end
        object FPortHintLabel: TLabel
          Left = 18
          Top = 244
          Width = 245
          Height = 31
          AutoSize = False
          Caption = 'Use unique ports if Apache, HTTPS, or MySQL are already used by another local stack.'
          Font.Color = clGrayText
          WordWrap = True
          ParentFont = False
        end
      end
    end
    object FRuntimeTab: TTabSheet
      Caption = 'Runtime'
      object FRuntimePhpCard: TPanel
        Left = 16
        Top = 16
        Width = 252
        Height = 236
        BevelKind = bkTile
        BevelOuter = bvNone
        Color = clWhite
        ParentBackground = False
        TabOrder = 0
        object FPhpVersionTitle: TLabel
          Left = 18
          Top = 16
          Width = 72
          Height = 15
          Caption = 'PHP version'
          Font.Height = -11
          Font.Style = [fsBold]
          ParentFont = False
        end
        object FPhpVersionLabel: TLabel
          Left = 18
          Top = 50
          Width = 72
          Height = 15
          Caption = 'Select runtime'
          Font.Height = -11
          Font.Color = clGrayText
          ParentFont = False
        end
        object FPhpVersionCombo: TComboBox
          Left = 18
          Top = 70
          Width = 208
          Height = 23
          Style = csDropDownList
          TabOrder = 0
        end
        object FPhpVersionHint: TLabel
          Left = 18
          Top = 110
          Width = 208
          Height = 31
          AutoSize = False
          Caption = 'Select the PHP runtime used by the dashboard and generated configs.'
          Font.Color = clGrayText
          WordWrap = True
          ParentFont = False
        end
      end
      object FRuntimeNodeCard: TPanel
        Left = 292
        Top = 16
        Width = 252
        Height = 236
        BevelKind = bkTile
        BevelOuter = bvNone
        Color = clWhite
        ParentBackground = False
        TabOrder = 1
        object FNodeVersionTitle: TLabel
          Left = 18
          Top = 16
          Width = 79
          Height = 15
          Caption = 'Node version'
          Font.Height = -11
          Font.Style = [fsBold]
          ParentFont = False
        end
        object FNodeVersionLabel: TLabel
          Left = 18
          Top = 50
          Width = 64
          Height = 15
          Caption = 'Optional'
          Font.Height = -11
          Font.Color = clGrayText
          ParentFont = False
        end
        object FNodeVersionCombo: TComboBox
          Left = 18
          Top = 70
          Width = 208
          Height = 23
          Style = csDropDownList
          TabOrder = 0
        end
        object FNodeVersionHint: TLabel
          Left = 18
          Top = 110
          Width = 208
          Height = 31
          AutoSize = False
          Caption = 'Choose a Node runtime when you want Node-based tooling available.'
          Font.Color = clGrayText
          WordWrap = True
          ParentFont = False
        end
      end
      object FRuntimeProfileCard: TPanel
        Left = 568
        Top = 16
        Width = 252
        Height = 236
        BevelKind = bkTile
        BevelOuter = bvNone
        Color = clWhite
        ParentBackground = False
        TabOrder = 2
        object FPhpProfileTitle: TLabel
          Left = 18
          Top = 16
          Width = 70
          Height = 15
          Caption = 'PHP profile'
          Font.Height = -11
          Font.Style = [fsBold]
          ParentFont = False
        end
        object FPhpProfileLabel: TLabel
          Left = 18
          Top = 50
          Width = 104
          Height = 15
          Caption = 'Development or production'
          Font.Height = -11
          Font.Color = clGrayText
          ParentFont = False
        end
        object FPhpProfileCombo: TComboBox
          Left = 18
          Top = 70
          Width = 208
          Height = 23
          Style = csDropDownList
          TabOrder = 0
        end
        object FPhpProfileHint: TLabel
          Left = 18
          Top = 110
          Width = 208
          Height = 31
          AutoSize = False
          Caption = 'Development shows verbose errors. Production uses safer defaults.'
          Font.Color = clGrayText
          WordWrap = True
          ParentFont = False
        end
      end
      object FRuntimeHintLabel: TLabel
        Left = 18
        Top = 272
        Width = 393
        Height = 15
        Caption = 'Changing versions updates the generated config files after Save.'
        Font.Color = clGrayText
        ParentFont = False
      end
    end
  end
  object FFooterPanel: TPanel
    Left = 0
    Top = 556
    Width = 880
    Height = 64
    Align = alBottom
    BevelOuter = bvNone
    Color = 15921906
    ParentBackground = False
    TabOrder = 2
    object FSaveButton: TButton
      Left = 692
      Top = 16
      Width = 84
      Height = 28
      Caption = 'Save'
      Default = True
      TabOrder = 0
    end
    object FCancelButton: TButton
      Left = 786
      Top = 16
      Width = 84
      Height = 28
      Cancel = True
      Caption = 'Cancel'
      ModalResult = 2
      TabOrder = 1
    end
  end
end
