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
    ActivePage = FSyncPage
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
    object FSyncPage: TTabSheet
      Caption = 'Sync'
      object FSyncProfilesCard: TPanel
        Left = 16
        Top = 16
        Width = 248
        Height = 561
        BevelKind = bkTile
        BevelOuter = bvNone
        Color = clWhite
        Padding.Left = 5
        Padding.Top = 5
        Padding.Right = 5
        Padding.Bottom = 5
        ParentBackground = False
        TabOrder = 0
        object FSyncProfilesTitle: TLabel
          Left = 5
          Top = 5
          Width = 234
          Height = 17
          Align = alTop
          Caption = 'Profiles'
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clWindowText
          Font.Height = -11
          Font.Name = 'Segoe UI'
          Font.Style = [fsBold]
          ParentFont = False
          ExplicitLeft = 0
          ExplicitTop = 0
          ExplicitWidth = 244
        end
        object FSyncProfilesHint: TLabel
          Left = 5
          Top = 22
          Width = 234
          Height = 55
          Align = alTop
          AutoSize = False
          Caption = 
            'Reusable sync profiles for upload and download. Pick one on the ' +
            'left, then edit its remote, local path, and safety options.'
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clGrayText
          Font.Height = -12
          Font.Name = 'Segoe UI'
          Font.Style = []
          ParentFont = False
          WordWrap = True
        end
        object FSyncProfilesFooter: TPanel
          Left = 5
          Top = 462
          Width = 234
          Height = 90
          Align = alBottom
          BevelOuter = bvNone
          Color = clWhite
          ParentBackground = False
          TabOrder = 0
          ExplicitLeft = 0
          ExplicitTop = 424
          ExplicitWidth = 244
          object FSyncAddButton: TButton
            Left = 16
            Top = 14
            Width = 98
            Height = 28
            Caption = 'Add'
            TabOrder = 0
          end
          object FSyncDeleteButton: TButton
            Left = 124
            Top = 15
            Width = 98
            Height = 28
            Caption = 'Delete'
            TabOrder = 1
          end
          object FSyncImportButton: TButton
            Left = 16
            Top = 51
            Width = 98
            Height = 28
            Caption = 'Import'
            TabOrder = 2
          end
          object FSyncExportButton: TButton
            Left = 124
            Top = 51
            Width = 98
            Height = 28
            Caption = 'Export'
            TabOrder = 3
          end
        end
        object FSyncListBox: TListBox
          Left = 5
          Top = 77
          Width = 234
          Height = 385
          Align = alClient
          ItemHeight = 15
          TabOrder = 1
          ExplicitLeft = 26
          ExplicitTop = 104
          ExplicitWidth = 206
          ExplicitHeight = 273
        end
      end
      object FSyncEditorCard: TPanel
        Left = 280
        Top = 16
        Width = 552
        Height = 561
        BevelKind = bkTile
        BevelOuter = bvNone
        Color = clWhite
        ParentBackground = False
        TabOrder = 1
        object FSyncEditorTitle: TLabel
          Left = 18
          Top = 8
          Width = 68
          Height = 13
          Caption = 'Profile editor'
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clWindowText
          Font.Height = -11
          Font.Name = 'Segoe UI'
          Font.Style = [fsBold]
          ParentFont = False
        end
        object FSyncEditorHint: TLabel
          Left = 18
          Top = 30
          Width = 228
          Height = 30
          AutoSize = False
          Caption = 
            'Use rclone remotes. Leave Executable path empty to auto-find rcl' +
            'one.exe.'
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clGrayText
          Font.Height = -12
          Font.Name = 'Segoe UI'
          Font.Style = []
          ParentFont = False
          WordWrap = True
        end
        object FSyncIdentityTitle: TLabel
          Left = 18
          Top = 74
          Width = 88
          Height = 15
          Caption = 'Identity - Name'
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clWindowText
          Font.Height = -12
          Font.Name = 'Segoe UI'
          Font.Style = [fsBold]
          ParentFont = False
        end
        object FSyncBackendLabel: TLabel
          Left = 270
          Top = 79
          Width = 44
          Height = 13
          Caption = 'Backend'
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clWindowText
          Font.Height = -11
          Font.Name = 'Segoe UI'
          Font.Style = [fsBold]
          ParentFont = False
        end
        object FSyncDirectionLabel: TLabel
          Left = 410
          Top = 79
          Width = 47
          Height = 13
          Caption = 'Direction'
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clWindowText
          Font.Height = -11
          Font.Name = 'Segoe UI'
          Font.Style = [fsBold]
          ParentFont = False
        end
        object FSyncExecutableLabel: TLabel
          Left = 18
          Top = 135
          Width = 83
          Height = 13
          Caption = 'Executable path'
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clWindowText
          Font.Height = -11
          Font.Name = 'Segoe UI'
          Font.Style = [fsBold]
          ParentFont = False
        end
        object FSyncRemoteTitle: TLabel
          Left = 18
          Top = 171
          Width = 83
          Height = 15
          Caption = 'Remote target'
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clWindowText
          Font.Height = -12
          Font.Name = 'Segoe UI'
          Font.Style = [fsBold]
          ParentFont = False
        end
        object FSyncRemoteNameLabel: TLabel
          Left = 18
          Top = 189
          Width = 72
          Height = 13
          Caption = 'Remote name'
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clWindowText
          Font.Height = -11
          Font.Name = 'Segoe UI'
          Font.Style = [fsBold]
          ParentFont = False
        end
        object FSyncRemotePathLabel: TLabel
          Left = 194
          Top = 189
          Width = 67
          Height = 13
          Caption = 'Remote path'
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clWindowText
          Font.Height = -11
          Font.Name = 'Segoe UI'
          Font.Style = [fsBold]
          ParentFont = False
        end
        object FSyncRemoteHint: TLabel
          Left = 18
          Top = 236
          Width = 510
          Height = 16
          AutoSize = False
          Caption = 
            'Remote name is the rclone remote only, such as myserver. Put the' +
            ' folder in Remote path.'
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clGrayText
          Font.Height = -12
          Font.Name = 'Segoe UI'
          Font.Style = []
          ParentFont = False
        end
        object FSyncLocalTitle: TLabel
          Left = 18
          Top = 257
          Width = 138
          Height = 15
          Caption = 'Local source and context'
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clWindowText
          Font.Height = -12
          Font.Name = 'Segoe UI'
          Font.Style = [fsBold]
          ParentFont = False
        end
        object FSyncVHostLabel: TLabel
          Left = 18
          Top = 274
          Width = 53
          Height = 13
          Caption = 'Test vHost'
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clWindowText
          Font.Height = -11
          Font.Name = 'Segoe UI'
          Font.Style = [fsBold]
          ParentFont = False
        end
        object FSyncLocalPathLabel: TLabel
          Left = 270
          Top = 274
          Width = 54
          Height = 13
          Caption = 'Local path'
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clWindowText
          Font.Height = -11
          Font.Name = 'Segoe UI'
          Font.Style = [fsBold]
          ParentFont = False
        end
        object FSyncWorkingDirLabel: TLabel
          Left = 18
          Top = 336
          Width = 94
          Height = 13
          Caption = 'Working directory'
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clWindowText
          Font.Height = -11
          Font.Name = 'Segoe UI'
          Font.Style = [fsBold]
          ParentFont = False
        end
        object FSyncPreCommandLabel: TLabel
          Left = 18
          Top = 363
          Width = 99
          Height = 13
          Caption = 'Pre-sync command'
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clWindowText
          Font.Height = -11
          Font.Name = 'Segoe UI'
          Font.Style = [fsBold]
          ParentFont = False
        end
        object FSyncPostCommandLabel: TLabel
          Left = 282
          Top = 363
          Width = 105
          Height = 13
          Caption = 'Post-sync command'
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clWindowText
          Font.Height = -11
          Font.Name = 'Segoe UI'
          Font.Style = [fsBold]
          ParentFont = False
        end
        object FSyncExcludesLabel: TLabel
          Left = 18
          Top = 443
          Width = 86
          Height = 13
          Caption = 'Exclude patterns'
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clWindowText
          Font.Height = -11
          Font.Name = 'Segoe UI'
          Font.Style = [fsBold]
          ParentFont = False
        end
        object FSyncExcludesHint: TLabel
          Left = 18
          Top = 520
          Width = 510
          Height = 28
          AutoSize = False
          Caption = 
            'One pattern per line. Supported tokens in local paths and hooks:' +
            ' {documentRoot}, {projectRoot}, {serverName}.'
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clGrayText
          Font.Height = -11
          Font.Name = 'Segoe UI'
          Font.Style = []
          ParentFont = False
          WordWrap = True
        end
        object FSyncActionPanel: TPanel
          Left = 312
          Top = 9
          Width = 220
          Height = 57
          BevelOuter = bvNone
          Color = clWhite
          ParentBackground = False
          TabOrder = 0
          object FSyncTestButton: TButton
            Left = 21
            Top = 2
            Width = 86
            Height = 26
            Caption = 'Test Remote'
            TabOrder = 0
          end
          object FSyncTestPathButton: TButton
            Left = 130
            Top = 0
            Width = 86
            Height = 26
            Caption = 'Test Path'
            TabOrder = 1
          end
          object FSyncPreviewButton: TButton
            Left = 130
            Top = 33
            Width = 86
            Height = 26
            Caption = 'Preview Cmd'
            TabOrder = 2
          end
        end
        object FSyncNameEdit: TEdit
          Left = 18
          Top = 97
          Width = 228
          Height = 23
          TabOrder = 1
        end
        object FSyncBackendCombo: TComboBox
          Left = 270
          Top = 97
          Width = 118
          Height = 23
          Style = csDropDownList
          TabOrder = 2
          Items.Strings = (
            'rclone')
        end
        object FSyncDirectionCombo: TComboBox
          Left = 410
          Top = 97
          Width = 118
          Height = 23
          Style = csDropDownList
          TabOrder = 3
          Items.Strings = (
            'upload'
            'download')
        end
        object FSyncExecutableEdit: TEdit
          Left = 107
          Top = 132
          Width = 421
          Height = 23
          TabOrder = 4
        end
        object FSyncRemoteNameEdit: TEdit
          Left = 18
          Top = 207
          Width = 160
          Height = 23
          TabOrder = 5
        end
        object FSyncRemotePathEdit: TEdit
          Left = 194
          Top = 207
          Width = 334
          Height = 23
          TabOrder = 6
        end
        object FSyncVHostCombo: TComboBox
          Left = 18
          Top = 292
          Width = 228
          Height = 23
          Style = csDropDownList
          TabOrder = 7
        end
        object FSyncLocalPathEdit: TEdit
          Left = 270
          Top = 292
          Width = 258
          Height = 23
          TabOrder = 8
        end
        object FSyncWorkingDirEdit: TEdit
          Left = 123
          Top = 331
          Width = 405
          Height = 23
          TabOrder = 9
        end
        object FSyncPreCommandEdit: TEdit
          Left = 18
          Top = 381
          Width = 246
          Height = 23
          TabOrder = 10
        end
        object FSyncPostCommandEdit: TEdit
          Left = 282
          Top = 381
          Width = 246
          Height = 23
          TabOrder = 11
        end
        object FSyncDeleteCheck: TCheckBox
          Left = 18
          Top = 414
          Width = 220
          Height = 19
          Caption = 'Delete extra files on target'
          TabOrder = 12
        end
        object FSyncDryRunCheck: TCheckBox
          Left = 246
          Top = 414
          Width = 180
          Height = 19
          Caption = 'Dry run by default'
          TabOrder = 13
        end
        object FSyncExcludesMemo: TMemo
          Left = 18
          Top = 466
          Width = 510
          Height = 46
          ScrollBars = ssVertical
          TabOrder = 14
          WordWrap = False
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
