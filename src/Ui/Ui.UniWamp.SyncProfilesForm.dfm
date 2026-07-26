object SyncProfilesForm: TSyncProfilesForm
  Left = 0
  Top = 0
  Caption = 'Sync Profiles'
  ClientHeight = 754
  ClientWidth = 1160
  Color = clWhite
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -12
  Font.Name = 'Segoe UI'
  Font.Style = []
  KeyPreview = True
  Position = poScreenCenter
  TextHeight = 15
  object HeaderPanel: TPanel
    Left = 0
    Top = 0
    Width = 1160
    Height = 68
    Align = alTop
    BevelOuter = bvNone
    Color = 6240798
    ParentBackground = False
    TabOrder = 0
    ExplicitTop = 1
    object HeaderTitle: TLabel
      Left = 18
      Top = 13
      Width = 102
      Height = 23
      Caption = 'Sync Profiles'
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clWhite
      Font.Height = -17
      Font.Name = 'Segoe UI'
      Font.Style = [fsBold]
      ParentFont = False
    end
    object HeaderHint: TLabel
      Left = 18
      Top = 42
      Width = 1035
      Height = 17
      Caption = 
        'Manage FTP, FTPS, and SFTP profiles for the native sync engine. ' +
        'SFTP supports passwords, ssh-agent, and unencrypted private keys' +
        '. Connection profiles are managed separately.'
      Font.Charset = DEFAULT_CHARSET
      Font.Color = 15722452
      Font.Height = -13
      Font.Name = 'Segoe UI'
      Font.Style = []
      ParentFont = False
    end
  end
  object BodyPanel: TPanel
    Left = 0
    Top = 68
    Width = 1160
    Height = 630
    Align = alClient
    BevelOuter = bvNone
    Color = clWhite
    ParentBackground = False
    TabOrder = 1
    ExplicitHeight = 636
    object LeftPanel: TPanel
      Left = 0
      Top = 0
      Width = 249
      Height = 630
      Align = alLeft
      BevelOuter = bvNone
      Color = clWhite
      ParentBackground = False
      TabOrder = 0
      ExplicitHeight = 691
      object LeftCard: TPanel
        Left = 0
        Top = 0
        Width = 249
        Height = 630
        Align = alClient
        BevelKind = bkTile
        BevelOuter = bvNone
        Color = clWhite
        Padding.Left = 5
        Padding.Top = 5
        Padding.Right = 5
        Padding.Bottom = 5
        ParentBackground = False
        TabOrder = 0
        ExplicitWidth = 300
        ExplicitHeight = 691
        object LeftTitle: TLabel
          Left = 5
          Top = 5
          Width = 235
          Height = 20
          Align = alTop
          Caption = 'Profiles'
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clWindowText
          Font.Height = -15
          Font.Name = 'Segoe UI'
          Font.Style = [fsBold]
          ParentFont = False
          ExplicitWidth = 53
        end
        object LeftHint: TLabel
          Left = 5
          Top = 25
          Width = 235
          Height = 44
          Align = alTop
          AutoSize = False
          Caption = 'Pick a profile, then edit connection details and paths.'
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clGrayText
          Font.Height = -16
          Font.Name = 'Segoe UI'
          Font.Style = []
          ParentFont = False
          WordWrap = True
          ExplicitWidth = 236
        end
        object FProfilesList: TListBox
          Left = 5
          Top = 69
          Width = 235
          Height = 359
          Align = alClient
          Color = clWhite
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clWindowText
          Font.Height = -12
          Font.Name = 'Segoe UI'
          Font.Style = []
          ItemHeight = 15
          ParentFont = False
          TabOrder = 0
          OnClick = ProfileSelectionChanged
          ExplicitHeight = 216
        end
        object LeftFooter: TPanel
          Left = 5
          Top = 428
          Width = 235
          Height = 193
          Align = alBottom
          BevelOuter = bvNone
          Color = clWhite
          ParentBackground = False
          TabOrder = 1
          ExplicitLeft = 6
          ExplicitTop = 502
          object FAddButton: TButton
            Left = 10
            Top = 12
            Width = 89
            Height = 28
            Caption = 'Add'
            Font.Charset = DEFAULT_CHARSET
            Font.Color = clWindowText
            Font.Height = -12
            Font.Name = 'Segoe UI'
            Font.Style = []
            ParentFont = False
            TabOrder = 0
            OnClick = AddProfileClicked
          end
          object FDeleteButton: TButton
            Left = 130
            Top = 12
            Width = 89
            Height = 28
            Caption = 'Delete'
            Font.Charset = DEFAULT_CHARSET
            Font.Color = clWindowText
            Font.Height = -12
            Font.Name = 'Segoe UI'
            Font.Style = []
            ParentFont = False
            TabOrder = 1
            OnClick = DeleteProfileClicked
          end
          object FImportButton: TButton
            Left = 10
            Top = 52
            Width = 89
            Height = 28
            Caption = 'Import'
            Font.Charset = DEFAULT_CHARSET
            Font.Color = clWindowText
            Font.Height = -12
            Font.Name = 'Segoe UI'
            Font.Style = []
            ParentFont = False
            TabOrder = 2
            OnClick = ImportProfilesClicked
          end
          object FExportButton: TButton
            Left = 130
            Top = 52
            Width = 89
            Height = 28
            Caption = 'Export'
            Font.Charset = DEFAULT_CHARSET
            Font.Color = clWindowText
            Font.Height = -12
            Font.Name = 'Segoe UI'
            Font.Style = []
            ParentFont = False
            TabOrder = 3
            OnClick = ExportProfilesClicked
          end
          object FTestButton: TButton
            Left = 15
            Top = 162
            Width = 207
            Height = 28
            Caption = 'Test connection'
            Font.Charset = DEFAULT_CHARSET
            Font.Color = clWindowText
            Font.Height = -12
            Font.Name = 'Segoe UI'
            Font.Style = []
            ParentFont = False
            TabOrder = 4
            OnClick = TestProfileClicked
          end
          object FPreviewButton: TButton
            Left = 15
            Top = 127
            Width = 208
            Height = 28
            Caption = 'Preview'
            Font.Charset = DEFAULT_CHARSET
            Font.Color = clWindowText
            Font.Height = -12
            Font.Name = 'Segoe UI'
            Font.Style = []
            ParentFont = False
            TabOrder = 5
            OnClick = PreviewProfileClicked
          end
          object FTestPathButton: TButton
            Left = 15
            Top = 90
            Width = 208
            Height = 28
            Caption = 'Test path'
            Font.Charset = DEFAULT_CHARSET
            Font.Color = clWindowText
            Font.Height = -12
            Font.Name = 'Segoe UI'
            Font.Style = []
            ParentFont = False
            TabOrder = 6
            OnClick = TestTargetPathClicked
          end
        end
      end
    end
    object RightPanel: TPanel
      Left = 249
      Top = 0
      Width = 911
      Height = 630
      Align = alClient
      BevelOuter = bvNone
      Color = clWhite
      ParentBackground = False
      TabOrder = 1
      ExplicitLeft = 300
      ExplicitWidth = 860
      ExplicitHeight = 636
      object RightScroll: TScrollBox
        Left = 0
        Top = 0
        Width = 911
        Height = 630
        Align = alClient
        BorderStyle = bsNone
        TabOrder = 0
        ExplicitWidth = 860
        ExplicitHeight = 636
        object RightInner: TPanel
          Left = 0
          Top = 0
          Width = 894
          Height = 880
          Align = alTop
          BevelOuter = bvNone
          Color = clWhite
          ParentBackground = False
          TabOrder = 0
          object Label3: TLabel
            Left = 20
            Top = 18
            Width = 55
            Height = 20
            Caption = 'Identity'
            Font.Charset = DEFAULT_CHARSET
            Font.Color = clWindowText
            Font.Height = -15
            Font.Name = 'Segoe UI'
            Font.Style = [fsBold]
            ParentFont = False
          end
          object Label4: TLabel
            Left = 20
            Top = 42
            Width = 42
            Height = 20
            Caption = 'Name'
            Font.Charset = DEFAULT_CHARSET
            Font.Color = clWindowText
            Font.Height = -15
            Font.Name = 'Segoe UI'
            Font.Style = [fsBold]
            ParentFont = False
          end
          object Label5: TLabel
            Left = 272
            Top = 42
            Width = 129
            Height = 20
            Caption = 'Connection profile'
            Font.Charset = DEFAULT_CHARSET
            Font.Color = clWindowText
            Font.Height = -15
            Font.Name = 'Segoe UI'
            Font.Style = [fsBold]
            ParentFont = False
          end
          object Label6: TLabel
            Left = 542
            Top = 42
            Width = 59
            Height = 20
            Caption = 'Protocol'
            Font.Charset = DEFAULT_CHARSET
            Font.Color = clWindowText
            Font.Height = -15
            Font.Name = 'Segoe UI'
            Font.Style = [fsBold]
            ParentFont = False
          end
          object Label7: TLabel
            Left = 702
            Top = 42
            Width = 64
            Height = 20
            Caption = 'Direction'
            Font.Charset = DEFAULT_CHARSET
            Font.Color = clWindowText
            Font.Height = -15
            Font.Name = 'Segoe UI'
            Font.Style = [fsBold]
            ParentFont = False
          end
          object Label8: TLabel
            Left = 20
            Top = 99
            Width = 79
            Height = 20
            Caption = 'Connection'
            Font.Charset = DEFAULT_CHARSET
            Font.Color = clWindowText
            Font.Height = -15
            Font.Name = 'Segoe UI'
            Font.Style = [fsBold]
            ParentFont = False
          end
          object Label9: TLabel
            Left = 20
            Top = 126
            Width = 33
            Height = 20
            Caption = 'Host'
            Font.Charset = DEFAULT_CHARSET
            Font.Color = clWindowText
            Font.Height = -15
            Font.Name = 'Segoe UI'
            Font.Style = [fsBold]
            ParentFont = False
          end
          object Label10: TLabel
            Left = 431
            Top = 126
            Width = 30
            Height = 20
            Caption = 'Port'
            Font.Charset = DEFAULT_CHARSET
            Font.Color = clWindowText
            Font.Height = -15
            Font.Name = 'Segoe UI'
            Font.Style = [fsBold]
            ParentFont = False
          end
          object Label11: TLabel
            Left = 589
            Top = 126
            Width = 78
            Height = 27
            Caption = 'Username'
            Font.Charset = DEFAULT_CHARSET
            Font.Color = clWindowText
            Font.Height = -15
            Font.Name = 'Segoe UI'
            Font.Style = [fsBold]
            ParentFont = False
          end
          object Label12: TLabel
            Left = 20
            Top = 168
            Width = 67
            Height = 20
            Caption = 'Password'
            Font.Charset = DEFAULT_CHARSET
            Font.Color = clWindowText
            Font.Height = -15
            Font.Name = 'Segoe UI'
            Font.Style = [fsBold]
            ParentFont = False
          end
          object Label13: TLabel
            Left = 384
            Top = 171
            Width = 108
            Height = 20
            Caption = 'Key passphrase'
            Font.Charset = DEFAULT_CHARSET
            Font.Color = clWindowText
            Font.Height = -15
            Font.Name = 'Segoe UI'
            Font.Style = [fsBold]
            ParentFont = False
          end
          object Label14: TLabel
            Left = 20
            Top = 212
            Width = 103
            Height = 20
            Caption = 'Private key file'
            Font.Charset = DEFAULT_CHARSET
            Font.Color = clWindowText
            Font.Height = -15
            Font.Name = 'Segoe UI'
            Font.Style = [fsBold]
            ParentFont = False
          end
          object Label15: TLabel
            Left = 14
            Top = 260
            Width = 170
            Height = 37
            Caption = 'SSH host key fingerprint'
            Font.Charset = DEFAULT_CHARSET
            Font.Color = clWindowText
            Font.Height = -15
            Font.Name = 'Segoe UI'
            Font.Style = [fsBold]
            ParentFont = False
          end
          object Label16: TLabel
            Left = 368
            Top = 260
            Width = 179
            Height = 20
            Caption = 'TLS certificate fingerprint'
            Font.Charset = DEFAULT_CHARSET
            Font.Color = clWindowText
            Font.Height = -15
            Font.Name = 'Segoe UI'
            Font.Style = [fsBold]
            ParentFont = False
          end
          object Label17: TLabel
            Left = 19
            Top = 357
            Width = 128
            Height = 20
            Caption = 'Context and paths'
            Font.Charset = DEFAULT_CHARSET
            Font.Color = clWindowText
            Font.Height = -15
            Font.Name = 'Segoe UI'
            Font.Style = [fsBold]
            ParentFont = False
          end
          object Label18: TLabel
            Left = 19
            Top = 381
            Width = 74
            Height = 20
            Caption = 'Test vHost'
            Font.Charset = DEFAULT_CHARSET
            Font.Color = clWindowText
            Font.Height = -15
            Font.Name = 'Segoe UI'
            Font.Style = [fsBold]
            ParentFont = False
          end
          object Label19: TLabel
            Left = 257
            Top = 381
            Width = 91
            Height = 20
            Caption = 'Remote path'
            Font.Charset = DEFAULT_CHARSET
            Font.Color = clWindowText
            Font.Height = -15
            Font.Name = 'Segoe UI'
            Font.Style = [fsBold]
            ParentFont = False
          end
          object Label20: TLabel
            Left = 19
            Top = 440
            Width = 72
            Height = 20
            Caption = 'Local path'
            Font.Charset = DEFAULT_CHARSET
            Font.Color = clWindowText
            Font.Height = -15
            Font.Name = 'Segoe UI'
            Font.Style = [fsBold]
            ParentFont = False
          end
          object Label21: TLabel
            Left = 368
            Top = 446
            Width = 128
            Height = 20
            Caption = 'Working directory'
            Font.Charset = DEFAULT_CHARSET
            Font.Color = clWindowText
            Font.Height = -15
            Font.Name = 'Segoe UI'
            Font.Style = [fsBold]
            ParentFont = False
          end
          object Label22: TLabel
            Left = 16
            Top = 503
            Width = 121
            Height = 20
            Caption = 'Hooks and safety'
            Font.Charset = DEFAULT_CHARSET
            Font.Color = clWindowText
            Font.Height = -15
            Font.Name = 'Segoe UI'
            Font.Style = [fsBold]
            ParentFont = False
          end
          object Label23: TLabel
            Left = 18
            Top = 532
            Width = 134
            Height = 20
            Caption = 'Pre-sync command'
            Font.Charset = DEFAULT_CHARSET
            Font.Color = clWindowText
            Font.Height = -15
            Font.Name = 'Segoe UI'
            Font.Style = [fsBold]
            ParentFont = False
          end
          object Label24: TLabel
            Left = 367
            Top = 532
            Width = 141
            Height = 20
            Caption = 'Post-sync command'
            Font.Charset = DEFAULT_CHARSET
            Font.Color = clWindowText
            Font.Height = -15
            Font.Name = 'Segoe UI'
            Font.Style = [fsBold]
            ParentFont = False
          end
          object Label25: TLabel
            Left = 695
            Top = 286
            Width = 116
            Height = 20
            Caption = 'Exclude patterns'
            Font.Charset = DEFAULT_CHARSET
            Font.Color = clWindowText
            Font.Height = -15
            Font.Name = 'Segoe UI'
            Font.Style = [fsBold]
            ParentFont = False
          end
          object FValidationLabel: TLabel
            Left = 18
            Top = 814
            Width = 690
            Height = 24
            AutoSize = False
            Font.Charset = DEFAULT_CHARSET
            Font.Color = clGrayText
            Font.Height = -15
            Font.Name = 'Segoe UI'
            Font.Style = []
            ParentFont = False
          end
          object FNameEdit: TEdit
            Left = 20
            Top = 62
            Width = 232
            Height = 23
            Font.Charset = DEFAULT_CHARSET
            Font.Color = clWindowText
            Font.Height = -12
            Font.Name = 'Segoe UI'
            Font.Style = []
            ParentFont = False
            TabOrder = 0
            OnChange = EditorChanged
          end
          object FConnectionProfileCombo: TComboBox
            Left = 272
            Top = 62
            Width = 252
            Height = 23
            Style = csDropDownList
            Font.Charset = DEFAULT_CHARSET
            Font.Color = clWindowText
            Font.Height = -12
            Font.Name = 'Segoe UI'
            Font.Style = []
            ParentFont = False
            TabOrder = 1
            OnChange = EditorChanged
          end
          object FProtocolCombo: TComboBox
            Left = 542
            Top = 62
            Width = 140
            Height = 23
            Style = csDropDownList
            Font.Charset = DEFAULT_CHARSET
            Font.Color = clWindowText
            Font.Height = -12
            Font.Name = 'Segoe UI'
            Font.Style = []
            ParentFont = False
            TabOrder = 2
            OnChange = ProtocolChanged
          end
          object FDirectionCombo: TComboBox
            Left = 702
            Top = 62
            Width = 102
            Height = 23
            Style = csDropDownList
            Font.Charset = DEFAULT_CHARSET
            Font.Color = clWindowText
            Font.Height = -12
            Font.Name = 'Segoe UI'
            Font.Style = []
            ParentFont = False
            TabOrder = 3
            OnChange = EditorChanged
          end
          object FHostEdit: TEdit
            Left = 70
            Top = 125
            Width = 294
            Height = 23
            Font.Charset = DEFAULT_CHARSET
            Font.Color = clWindowText
            Font.Height = -12
            Font.Name = 'Segoe UI'
            Font.Style = []
            ParentFont = False
            TabOrder = 4
            OnChange = EditorChanged
          end
          object FPortEdit: TEdit
            Left = 472
            Top = 125
            Width = 84
            Height = 23
            Font.Charset = DEFAULT_CHARSET
            Font.Color = clWindowText
            Font.Height = -12
            Font.Name = 'Segoe UI'
            Font.Style = []
            ParentFont = False
            TabOrder = 5
            OnChange = EditorChanged
          end
          object FUsernameEdit: TEdit
            Left = 675
            Top = 125
            Width = 175
            Height = 23
            Font.Charset = DEFAULT_CHARSET
            Font.Color = clWindowText
            Font.Height = -12
            Font.Name = 'Segoe UI'
            Font.Style = []
            ParentFont = False
            TabOrder = 6
            OnChange = EditorChanged
          end
          object FPasswordEdit: TEdit
            Left = 103
            Top = 169
            Width = 261
            Height = 23
            Font.Charset = DEFAULT_CHARSET
            Font.Color = clWindowText
            Font.Height = -12
            Font.Name = 'Segoe UI'
            Font.Style = []
            ParentFont = False
            PasswordChar = '*'
            TabOrder = 7
            OnChange = EditorChanged
          end
          object FKeyPassphraseEdit: TEdit
            Left = 498
            Top = 168
            Width = 350
            Height = 23
            Font.Charset = DEFAULT_CHARSET
            Font.Color = clWindowText
            Font.Height = -12
            Font.Name = 'Segoe UI'
            Font.Style = []
            ParentFont = False
            PasswordChar = '*'
            TabOrder = 8
            OnChange = EditorChanged
          end
          object FPrivateKeyEdit: TEdit
            Left = 140
            Top = 212
            Width = 565
            Height = 23
            Font.Charset = DEFAULT_CHARSET
            Font.Color = clWindowText
            Font.Height = -12
            Font.Name = 'Segoe UI'
            Font.Style = []
            ParentFont = False
            TabOrder = 9
            OnChange = EditorChanged
          end
          object FPrivateKeyBrowseButton: TButton
            Left = 717
            Top = 208
            Width = 132
            Height = 28
            Caption = 'Browse'
            Font.Charset = DEFAULT_CHARSET
            Font.Color = clWindowText
            Font.Height = -12
            Font.Name = 'Segoe UI'
            Font.Style = []
            ParentFont = False
            TabOrder = 10
            OnClick = BrowsePrivateKeyClicked
          end
          object FHostKeyEdit: TEdit
            Left = 16
            Top = 287
            Width = 329
            Height = 23
            Font.Charset = DEFAULT_CHARSET
            Font.Color = clWindowText
            Font.Height = -12
            Font.Name = 'Segoe UI'
            Font.Style = []
            ParentFont = False
            TabOrder = 11
            OnChange = EditorChanged
          end
          object FTlsCertEdit: TEdit
            Left = 368
            Top = 287
            Width = 273
            Height = 23
            Font.Charset = DEFAULT_CHARSET
            Font.Color = clWindowText
            Font.Height = -12
            Font.Name = 'Segoe UI'
            Font.Style = []
            ParentFont = False
            TabOrder = 12
            OnChange = EditorChanged
          end
          object FPassiveCheck: TCheckBox
            Left = 17
            Top = 324
            Width = 136
            Height = 17
            Caption = 'Passive mode'
            Font.Charset = DEFAULT_CHARSET
            Font.Color = clWindowText
            Font.Height = -12
            Font.Name = 'Segoe UI'
            Font.Style = []
            ParentFont = False
            TabOrder = 13
            OnClick = EditorChanged
          end
          object FIgnoreCertCheck: TCheckBox
            Left = 159
            Top = 324
            Width = 225
            Height = 17
            Hint = 
              'Disables FTPS certificate validation and hostname checks for thi' +
              's profile.'
            Caption = 'Ignore cert errors (insecure)'
            Font.Charset = DEFAULT_CHARSET
            Font.Color = clWindowText
            Font.Height = -12
            Font.Name = 'Segoe UI'
            Font.Style = []
            ParentFont = False
            ParentShowHint = False
            ShowHint = True
            TabOrder = 14
            OnClick = EditorChanged
          end
          object FVHostCombo: TComboBox
            Left = 19
            Top = 401
            Width = 222
            Height = 23
            Style = csDropDownList
            Font.Charset = DEFAULT_CHARSET
            Font.Color = clWindowText
            Font.Height = -12
            Font.Name = 'Segoe UI'
            Font.Style = []
            ParentFont = False
            TabOrder = 15
            OnChange = EditorChanged
          end
          object FRemotePathEdit: TEdit
            Left = 257
            Top = 401
            Width = 390
            Height = 23
            Font.Charset = DEFAULT_CHARSET
            Font.Color = clWindowText
            Font.Height = -12
            Font.Name = 'Segoe UI'
            Font.Style = []
            ParentFont = False
            TabOrder = 16
            OnChange = EditorChanged
          end
          object FLocalPathEdit: TEdit
            Left = 20
            Top = 466
            Width = 325
            Height = 23
            Font.Charset = DEFAULT_CHARSET
            Font.Color = clWindowText
            Font.Height = -12
            Font.Name = 'Segoe UI'
            Font.Style = []
            ParentFont = False
            TabOrder = 17
            OnChange = EditorChanged
          end
          object FWorkingDirEdit: TEdit
            Left = 368
            Top = 466
            Width = 278
            Height = 23
            Font.Charset = DEFAULT_CHARSET
            Font.Color = clWindowText
            Font.Height = -12
            Font.Name = 'Segoe UI'
            Font.Style = []
            ParentFont = False
            TabOrder = 18
            OnChange = EditorChanged
          end
          object FPreCommandEdit: TEdit
            Left = 18
            Top = 552
            Width = 327
            Height = 23
            Font.Charset = DEFAULT_CHARSET
            Font.Color = clWindowText
            Font.Height = -12
            Font.Name = 'Segoe UI'
            Font.Style = []
            ParentFont = False
            TabOrder = 19
            OnChange = EditorChanged
          end
          object FPostCommandEdit: TEdit
            Left = 367
            Top = 552
            Width = 278
            Height = 23
            Font.Charset = DEFAULT_CHARSET
            Font.Color = clWindowText
            Font.Height = -12
            Font.Name = 'Segoe UI'
            Font.Style = []
            ParentFont = False
            TabOrder = 20
            OnChange = EditorChanged
          end
          object FDeleteCheck: TCheckBox
            Left = 21
            Top = 589
            Width = 248
            Height = 17
            Caption = 'Delete extra files on target'
            Font.Charset = DEFAULT_CHARSET
            Font.Color = clWindowText
            Font.Height = -12
            Font.Name = 'Segoe UI'
            Font.Style = []
            ParentFont = False
            TabOrder = 21
            OnClick = EditorChanged
          end
          object FDryRunCheck: TCheckBox
            Left = 275
            Top = 589
            Width = 209
            Height = 17
            Caption = 'Dry run by default'
            Font.Charset = DEFAULT_CHARSET
            Font.Color = clWindowText
            Font.Height = -12
            Font.Name = 'Segoe UI'
            Font.Style = []
            ParentFont = False
            TabOrder = 22
            OnClick = EditorChanged
          end
          object FExcludesMemo: TMemo
            Left = 672
            Top = 316
            Width = 203
            Height = 290
            Font.Charset = DEFAULT_CHARSET
            Font.Color = clWindowText
            Font.Height = -12
            Font.Name = 'Segoe UI'
            Font.Style = []
            ParentFont = False
            ScrollBars = ssVertical
            TabOrder = 23
            WordWrap = False
            OnChange = EditorChanged
          end
        end
      end
    end
  end
  object FooterPanel: TPanel
    Left = 0
    Top = 698
    Width = 1160
    Height = 56
    Align = alBottom
    BevelOuter = bvNone
    Color = 15921906
    ParentBackground = False
    TabOrder = 2
    ExplicitTop = 704
    object FSaveButton: TButton
      Left = 948
      Top = 14
      Width = 84
      Height = 28
      Caption = 'Save'
      Default = True
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clWindowText
      Font.Height = -12
      Font.Name = 'Segoe UI'
      Font.Style = []
      ParentFont = False
      TabOrder = 0
      OnClick = SaveClicked
    end
    object FCloseButton: TButton
      Left = 1042
      Top = 14
      Width = 84
      Height = 28
      Cancel = True
      Caption = 'Close'
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clWindowText
      Font.Height = -12
      Font.Name = 'Segoe UI'
      Font.Style = []
      ParentFont = False
      TabOrder = 1
      OnClick = CloseClicked
    end
  end
end
