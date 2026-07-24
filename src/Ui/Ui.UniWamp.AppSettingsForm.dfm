object AppSettingsForm: TAppSettingsForm
  Left = 0
  Top = 0
  Caption = 'Application Settings'
  ClientHeight = 736
  ClientWidth = 863
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
    Width = 863
    Height = 68
    Align = alTop
    BevelOuter = bvNone
    Color = 6240798
    ParentBackground = False
    TabOrder = 0
    ExplicitWidth = 880
    object FTitleLabel: TLabel
      Left = 18
      Top = 13
      Width = 164
      Height = 23
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
      Width = 404
      Height = 12
      Caption = 
        'Edit the core UniWamp configuration that drives the dashboard an' +
        'd generated runtime files.'
      Font.Charset = DEFAULT_CHARSET
      Font.Color = 15722452
      Font.Height = -10
      Font.Name = 'Segoe UI'
      Font.Style = []
      ParentFont = False
    end
  end
  object FPageControl: TPageControl
    Left = 0
    Top = 68
    Width = 863
    Height = 620
    ActivePage = FGeneralTab
    Align = alClient
    TabOrder = 1
    ExplicitLeft = -8
    ExplicitTop = 108
    ExplicitWidth = 880
    ExplicitHeight = 644
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
          Width = 84
          Height = 13
          Caption = 'Application info'
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clWindowText
          Font.Height = -11
          Font.Name = 'Segoe UI'
          Font.Style = [fsBold]
          ParentFont = False
        end
        object FHostNameLabel: TLabel
          Left = 18
          Top = 50
          Width = 56
          Height = 13
          Caption = 'Host name'
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clWindowText
          Font.Height = -11
          Font.Name = 'Segoe UI'
          Font.Style = [fsBold]
          ParentFont = False
        end
        object FDocumentRootLabel: TLabel
          Left = 18
          Top = 112
          Width = 79
          Height = 13
          Caption = 'Document root'
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clWindowText
          Font.Height = -11
          Font.Name = 'Segoe UI'
          Font.Style = [fsBold]
          ParentFont = False
        end
        object FTerminalPathLabel: TLabel
          Left = 18
          Top = 172
          Width = 130
          Height = 13
          Caption = 'Terminal executable path'
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clWindowText
          Font.Height = -11
          Font.Name = 'Segoe UI'
          Font.Style = [fsBold]
          ParentFont = False
        end
        object FThemeStyleLabel: TLabel
          Left = 18
          Top = 344
          Width = 62
          Height = 13
          Caption = 'Theme style'
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clWindowText
          Font.Height = -11
          Font.Name = 'Segoe UI'
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
        object FDocumentRootEdit: TEdit
          Left = 18
          Top = 132
          Width = 464
          Height = 23
          TabOrder = 1
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
          Width = 27
          Height = 13
          Caption = 'Ports'
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clWindowText
          Font.Height = -11
          Font.Name = 'Segoe UI'
          Font.Style = [fsBold]
          ParentFont = False
        end
        object FHttpPortLabel: TLabel
          Left = 18
          Top = 50
          Width = 52
          Height = 13
          Caption = 'HTTP port'
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clWindowText
          Font.Height = -11
          Font.Name = 'Segoe UI'
          Font.Style = [fsBold]
          ParentFont = False
        end
        object FHttpsPortLabel: TLabel
          Left = 18
          Top = 112
          Width = 58
          Height = 13
          Caption = 'HTTPS port'
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clWindowText
          Font.Height = -11
          Font.Name = 'Segoe UI'
          Font.Style = [fsBold]
          ParentFont = False
        end
        object FDatabasePortLabel: TLabel
          Left = 18
          Top = 172
          Width = 73
          Height = 13
          Caption = 'Database port'
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clWindowText
          Font.Height = -11
          Font.Name = 'Segoe UI'
          Font.Style = [fsBold]
          ParentFont = False
        end
        object FPortHintLabel: TLabel
          Left = 18
          Top = 244
          Width = 245
          Height = 31
          AutoSize = False
          Caption = 
            'Use unique ports if Apache, HTTPS, or MySQL are already used by ' +
            'another local stack.'
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clGrayText
          Font.Height = -12
          Font.Name = 'Segoe UI'
          Font.Style = []
          ParentFont = False
          WordWrap = True
        end
        object FHttpPortEdit: TEdit
          Left = 18
          Top = 70
          Width = 122
          Height = 23
          TabOrder = 0
        end
        object FHttpsPortEdit: TEdit
          Left = 18
          Top = 132
          Width = 122
          Height = 23
          TabOrder = 1
        end
        object FDatabasePortEdit: TEdit
          Left = 18
          Top = 192
          Width = 122
          Height = 23
          TabOrder = 2
        end
      end
    end
    object FRuntimeTab: TTabSheet
      Caption = 'Runtime'
      object FRuntimeHintLabel: TLabel
        Left = 18
        Top = 272
        Width = 337
        Height = 15
        Caption = 'Changing versions updates the generated config files after Save.'
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clGrayText
        Font.Height = -12
        Font.Name = 'Segoe UI'
        Font.Style = []
        ParentFont = False
      end
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
          Width = 63
          Height = 13
          Caption = 'PHP version'
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clWindowText
          Font.Height = -11
          Font.Name = 'Segoe UI'
          Font.Style = [fsBold]
          ParentFont = False
        end
        object FPhpVersionLabel: TLabel
          Left = 18
          Top = 50
          Width = 73
          Height = 13
          Caption = 'Select runtime'
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clGrayText
          Font.Height = -11
          Font.Name = 'Segoe UI'
          Font.Style = []
          ParentFont = False
        end
        object FPhpVersionHint: TLabel
          Left = 18
          Top = 110
          Width = 208
          Height = 31
          AutoSize = False
          Caption = 
            'Select the PHP runtime used by the dashboard and generated confi' +
            'gs.'
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clGrayText
          Font.Height = -12
          Font.Name = 'Segoe UI'
          Font.Style = []
          ParentFont = False
          WordWrap = True
        end
        object FPhpVersionCombo: TComboBox
          Left = 18
          Top = 70
          Width = 208
          Height = 23
          Style = csDropDownList
          TabOrder = 0
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
          Width = 70
          Height = 13
          Caption = 'Node version'
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clWindowText
          Font.Height = -11
          Font.Name = 'Segoe UI'
          Font.Style = [fsBold]
          ParentFont = False
        end
        object FNodeVersionLabel: TLabel
          Left = 18
          Top = 50
          Width = 46
          Height = 13
          Caption = 'Optional'
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clGrayText
          Font.Height = -11
          Font.Name = 'Segoe UI'
          Font.Style = []
          ParentFont = False
        end
        object FNodeVersionHint: TLabel
          Left = 18
          Top = 110
          Width = 208
          Height = 31
          AutoSize = False
          Caption = 
            'Choose a Node runtime when you want Node-based tooling available' +
            '.'
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clGrayText
          Font.Height = -12
          Font.Name = 'Segoe UI'
          Font.Style = []
          ParentFont = False
          WordWrap = True
        end
        object FNodeVersionCombo: TComboBox
          Left = 18
          Top = 70
          Width = 208
          Height = 23
          Style = csDropDownList
          TabOrder = 0
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
          Width = 59
          Height = 13
          Caption = 'PHP profile'
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clWindowText
          Font.Height = -11
          Font.Name = 'Segoe UI'
          Font.Style = [fsBold]
          ParentFont = False
        end
        object FPhpProfileLabel: TLabel
          Left = 18
          Top = 50
          Width = 143
          Height = 13
          Caption = 'Development or production'
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clGrayText
          Font.Height = -11
          Font.Name = 'Segoe UI'
          Font.Style = []
          ParentFont = False
        end
        object FPhpProfileHint: TLabel
          Left = 18
          Top = 110
          Width = 208
          Height = 31
          AutoSize = False
          Caption = 
            'Development shows verbose errors. Production uses safer defaults' +
            '.'
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clGrayText
          Font.Height = -12
          Font.Name = 'Segoe UI'
          Font.Style = []
          ParentFont = False
          WordWrap = True
        end
      object FPhpProfileCombo: TComboBox
          Left = 18
          Top = 70
          Width = 208
          Height = 23
          Style = csDropDownList
          TabOrder = 0
        end
      end
    end
  end
  object FFooterPanel: TPanel
    Left = 0
    Top = 688
    Width = 863
    Height = 48
    Align = alBottom
    BevelOuter = bvNone
    Color = 15921906
    ParentBackground = False
    TabOrder = 2
    ExplicitTop = 711
    ExplicitWidth = 880
    object FSaveButton: TButton
      Left = 658
      Top = 16
      Width = 84
      Height = 28
      Caption = 'Save'
      Default = True
      TabOrder = 0
    end
    object FCancelButton: TButton
      Left = 752
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
