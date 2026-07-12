object MainForm: TMainForm
  Left = 0
  Top = 0
  Caption = 'UniWamp'
  ClientHeight = 789
  ClientWidth = 1053
  Color = 15066597
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'Segoe UI'
  Font.Style = []
  Position = poScreenCenter
  TextHeight = 13
  object HeaderPanel: TPanel
    Left = 0
    Top = 0
    Width = 1053
    Height = 55
    Align = alTop
    BevelOuter = bvNone
    Color = 6229470
    ParentBackground = False
    TabOrder = 0
    object Label18: TPanel
      Left = 17
      Top = 4
      Width = 200
      Height = 34
      BevelOuter = bvNone
      Caption = 'UNIWAMP'
      Color = 6229470
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clWhite
      Font.Height = -24
      Font.Name = 'Segoe UI'
      Font.Style = [fsBold]
      ParentBackground = False
      ParentFont = False
      TabOrder = 0
    end
    object Label19: TPanel
      Left = 21
      Top = 30
      Width = 262
      Height = 15
      BevelOuter = bvNone
      Caption = 'Portable WAMP dashboard for local development'
      Color = 6229470
      Font.Charset = DEFAULT_CHARSET
      Font.Color = 16053492
      Font.Height = -11
      Font.Name = 'Segoe UI'
      Font.Style = []
      ParentBackground = False
      ParentFont = False
      TabOrder = 1
    end
  end
  object MainPanel: TPanel
    Left = 0
    Top = 55
    Width = 1053
    Height = 734
    Align = alClient
    BevelOuter = bvNone
    ParentBackground = False
    TabOrder = 1
    object LeftPanel: TPanel
      Left = 0
      Top = 0
      Width = 297
      Height = 714
      Align = alLeft
      BevelOuter = bvNone
      Color = 15066597
      ParentBackground = False
      TabOrder = 0
      object ActionsCard: TPanel
        Left = 0
        Top = 0
        Width = 284
        Height = 714
        Align = alLeft
        Alignment = taLeftJustify
        BevelKind = bkTile
        BevelOuter = bvNone
        Color = clCream
        ParentBackground = False
        TabOrder = 0
        ExplicitLeft = 10
        ExplicitTop = 11
        ExplicitHeight = 697
        object LabelEditors: TPanel
          Left = 17
          Top = 550
          Width = 80
          Height = 15
          BevelOuter = bvNone
          Caption = 'Config Editors'
          Color = clWhite
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clWindowText
          Font.Height = -11
          Font.Name = 'Segoe UI'
          Font.Style = [fsBold]
          ParentBackground = False
          ParentFont = False
          TabOrder = 0
        end
        object EditPhpIniButton: TPanel
          Left = 17
          Top = 579
          Width = 80
          Height = 24
          Cursor = crHandPoint
          BevelOuter = bvNone
          Caption = 'php.ini'
          Color = 16053492
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clWindowText
          Font.Height = -11
          Font.Name = 'Segoe UI'
          Font.Style = [fsBold]
          ParentBackground = False
          ParentFont = False
          TabOrder = 1
        end
        object EditHttpdConfButton: TPanel
          Left = 99
          Top = 579
          Width = 80
          Height = 24
          Cursor = crHandPoint
          BevelOuter = bvNone
          Caption = 'httpd.conf'
          Color = 16053492
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clWindowText
          Font.Height = -11
          Font.Name = 'Segoe UI'
          Font.Style = [fsBold]
          ParentBackground = False
          ParentFont = False
          TabOrder = 2
        end
        object EditMariaDbIniButton: TPanel
          Left = 187
          Top = 579
          Width = 80
          Height = 24
          Cursor = crHandPoint
          BevelOuter = bvNone
          Caption = 'mariadb.ini'
          Color = 16053492
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clWindowText
          Font.Height = -11
          Font.Name = 'Segoe UI'
          Font.Style = [fsBold]
          ParentBackground = False
          ParentFont = False
          TabOrder = 3
        end
        object GroupBox1: TGroupBox
          Left = 17
          Top = 11
          Width = 250
          Height = 160
          Caption = 'Apache'
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clWindowText
          Font.Height = -13
          Font.Name = 'Segoe UI'
          Font.Style = [fsBold]
          ParentFont = False
          TabOrder = 4
          object FHttpPortOwnerLabel: TLabel
            Left = 104
            Top = 85
            Width = 128
            Height = 12
            AutoSize = False
            Caption = 'HTTP 8080: available'
            Font.Charset = DEFAULT_CHARSET
            Font.Color = clGrayText
            Font.Height = -11
            Font.Name = 'Segoe UI'
            Font.Style = []
            ParentFont = False
            ParentShowHint = False
            ShowHint = True
          end
          object FHttpsPortOwnerLabel: TLabel
            Left = 104
            Top = 118
            Width = 128
            Height = 12
            AutoSize = False
            Caption = 'HTTPS 8443: available'
            Font.Charset = DEFAULT_CHARSET
            Font.Color = clGrayText
            Font.Height = -11
            Font.Name = 'Segoe UI'
            Font.Style = []
            ParentFont = False
            ParentShowHint = False
            ShowHint = True
          end
          object ApacheStartButton: TPanel
            Left = 6
            Top = 25
            Width = 71
            Height = 24
            Cursor = crHandPoint
            BevelOuter = bvNone
            Caption = 'Start'
            Color = 16053492
            Font.Charset = DEFAULT_CHARSET
            Font.Color = clWindowText
            Font.Height = -11
            Font.Name = 'Segoe UI'
            Font.Style = [fsBold]
            ParentBackground = False
            ParentFont = False
            TabOrder = 0
          end
          object ApacheStopButton: TPanel
            Left = 84
            Top = 25
            Width = 74
            Height = 24
            Cursor = crHandPoint
            BevelOuter = bvNone
            Caption = 'Stop'
            Color = 16053492
            Font.Charset = DEFAULT_CHARSET
            Font.Color = clWindowText
            Font.Height = -11
            Font.Name = 'Segoe UI'
            Font.Style = [fsBold]
            ParentBackground = False
            ParentFont = False
            TabOrder = 1
          end
          object ApacheRestartButton: TPanel
            Left = 168
            Top = 25
            Width = 74
            Height = 24
            Cursor = crHandPoint
            BevelOuter = bvNone
            Caption = 'Restart'
            Color = 16053492
            Font.Charset = DEFAULT_CHARSET
            Font.Color = clWindowText
            Font.Height = -11
            Font.Name = 'Segoe UI'
            Font.Style = [fsBold]
            ParentBackground = False
            ParentFont = False
            TabOrder = 2
          end
          object Label7: TPanel
            Left = 10
            Top = 59
            Width = 59
            Height = 15
            Alignment = taLeftJustify
            BevelOuter = bvNone
            Caption = 'Port '
            Color = clWhite
            Font.Charset = DEFAULT_CHARSET
            Font.Color = clWindowText
            Font.Height = -12
            Font.Name = 'Segoe UI'
            Font.Style = [fsBold]
            ParentBackground = False
            ParentFont = False
            TabOrder = 3
          end
          object HttpPortEdit: TEdit
            Left = 57
            Top = 77
            Width = 41
            Height = 23
            Font.Charset = DEFAULT_CHARSET
            Font.Color = clWindowText
            Font.Height = -12
            Font.Name = 'Segoe UI'
            Font.Style = []
            ParentFont = False
            TabOrder = 4
            Text = '8080'
          end
          object Label8: TPanel
            Left = 11
            Top = 115
            Width = 45
            Height = 15
            Alignment = taLeftJustify
            BevelOuter = bvNone
            Caption = 'HTTPS'
            Color = clCream
            Font.Charset = DEFAULT_CHARSET
            Font.Color = clWindowText
            Font.Height = -12
            Font.Name = 'Segoe UI'
            Font.Style = []
            ParentBackground = False
            ParentFont = False
            TabOrder = 5
          end
          object HttpsPortEdit: TEdit
            Left = 57
            Top = 110
            Width = 41
            Height = 23
            Font.Charset = DEFAULT_CHARSET
            Font.Color = clWindowText
            Font.Height = -12
            Font.Name = 'Segoe UI'
            Font.Style = []
            ParentFont = False
            TabOrder = 6
            Text = '8443'
          end
          object Panel2: TPanel
            Left = 10
            Top = 82
            Width = 40
            Height = 15
            Alignment = taLeftJustify
            BevelOuter = bvNone
            Caption = 'HTTP'
            Color = clCream
            Font.Charset = DEFAULT_CHARSET
            Font.Color = clWindowText
            Font.Height = -12
            Font.Name = 'Segoe UI'
            Font.Style = []
            ParentBackground = False
            ParentFont = False
            TabOrder = 7
          end
        end
        object GroupBox2: TGroupBox
          Left = 17
          Top = 161
          Width = 249
          Height = 125
          Caption = 'MariaDB'
          TabOrder = 5
          object FDbPortOwnerLabel: TLabel
            Left = 9
            Top = 108
            Width = 226
            Height = 12
            AutoSize = False
            Caption = 'DB 3309: available'
            Font.Charset = DEFAULT_CHARSET
            Font.Color = clGrayText
            Font.Height = -11
            Font.Name = 'Segoe UI'
            Font.Style = []
            ParentFont = False
            ParentShowHint = False
            ShowHint = True
          end
          object MariaStartButton: TPanel
            Left = 5
            Top = 25
            Width = 71
            Height = 24
            Cursor = crHandPoint
            BevelOuter = bvNone
            Caption = 'Start'
            Color = 16053492
            Font.Charset = DEFAULT_CHARSET
            Font.Color = clWindowText
            Font.Height = -11
            Font.Name = 'Segoe UI'
            Font.Style = [fsBold]
            ParentBackground = False
            ParentFont = False
            TabOrder = 0
          end
          object MariaStopButton: TPanel
            Left = 83
            Top = 25
            Width = 74
            Height = 24
            Cursor = crHandPoint
            BevelOuter = bvNone
            Caption = 'Stop'
            Color = 16053492
            Font.Charset = DEFAULT_CHARSET
            Font.Color = clWindowText
            Font.Height = -11
            Font.Name = 'Segoe UI'
            Font.Style = [fsBold]
            ParentBackground = False
            ParentFont = False
            TabOrder = 1
          end
          object MariaRestartButton: TPanel
            Left = 167
            Top = 25
            Width = 69
            Height = 24
            Cursor = crHandPoint
            BevelOuter = bvNone
            Caption = 'Restart'
            Color = 16053492
            Font.Charset = DEFAULT_CHARSET
            Font.Color = clWindowText
            Font.Height = -11
            Font.Name = 'Segoe UI'
            Font.Style = [fsBold]
            ParentBackground = False
            ParentFont = False
            TabOrder = 2
          end
          object Label9: TPanel
            Left = 17
            Top = 59
            Width = 50
            Height = 15
            Alignment = taLeftJustify
            BevelOuter = bvNone
            Caption = 'DB Port'
            Color = clWhite
            ParentBackground = False
            TabOrder = 3
          end
          object DbPortEdit: TEdit
            Left = 17
            Top = 83
            Width = 74
            Height = 21
            TabOrder = 4
            Text = '3307'
          end
        end
        object Panel3: TPanel
          Left = 16
          Top = 391
          Width = 248
          Height = 152
          BevelKind = bkTile
          BevelOuter = bvNone
          Color = clCream
          ParentBackground = False
          TabOrder = 6
          object Label3: TPanel
            Left = 8
            Top = 8
            Width = 55
            Height = 15
            BevelOuter = bvNone
            Caption = 'Host name'
            Color = clWhite
            ParentBackground = False
            TabOrder = 0
          end
          object HostNameEdit: TEdit
            Left = 9
            Top = 26
            Width = 227
            Height = 21
            TabOrder = 1
            Text = 'uniwamp.local'
          end
          object Label5: TPanel
            Left = 8
            Top = 50
            Width = 74
            Height = 15
            Alignment = taLeftJustify
            BevelOuter = bvNone
            Caption = 'PHP profile'
            Color = clWhite
            ParentBackground = False
            TabOrder = 2
          end
          object PhpProfileCombo: TComboBox
            Left = 8
            Top = 68
            Width = 229
            Height = 21
            Style = csDropDownList
            TabOrder = 3
            Items.Strings = (
              'development'
              'production')
          end
          object Label10: TPanel
            Left = 8
            Top = 92
            Width = 81
            Height = 15
            BevelOuter = bvNone
            Caption = 'Document root'
            Color = clWhite
            ParentBackground = False
            TabOrder = 4
          end
          object DocumentRootEdit: TEdit
            Left = 8
            Top = 111
            Width = 226
            Height = 21
            TabOrder = 5
            Text = 'runtime\www'
          end
        end
        object Panel1: TPanel
          Left = 17
          Top = 290
          Width = 249
          Height = 86
          BevelKind = bkTile
          BevelOuter = bvNone
          Color = clCream
          ParentBackground = False
          TabOrder = 7
          object Label4: TPanel
            Left = 8
            Top = 9
            Width = 111
            Height = 12
            Alignment = taLeftJustify
            AutoSize = True
            BevelOuter = bvNone
            Caption = 'PHP version'
            Color = clWhite
            ParentBackground = False
            TabOrder = 0
          end
          object PhpVersionCombo: TComboBox
            Left = 87
            Top = 5
            Width = 143
            Height = 21
            Style = csDropDownList
            TabOrder = 1
          end
          object LabelNode: TPanel
            Left = 8
            Top = 34
            Width = 125
            Height = 15
            Alignment = taLeftJustify
            BevelOuter = bvNone
            Caption = 'Node version'
            Color = clWhite
            ParentBackground = False
            TabOrder = 2
          end
          object NodeVersionCombo: TComboBox
            Left = 87
            Top = 30
            Width = 143
            Height = 21
            Style = csDropDownList
            TabOrder = 3
          end
          object EnableSslCheck: TCheckBox
            Left = 7
            Top = 57
            Width = 169
            Height = 17
            Caption = 'Enable SSL for localhost'
            TabOrder = 4
          end
        end
        object BottomActionsPanel: TPanel
          Left = 15
          Top = 635
          Width = 251
          Height = 52
          BevelKind = bkTile
          BevelOuter = bvNone
          Color = clWhite
          ParentBackground = False
          TabOrder = 8
          object StartAllButton: TPanel
            Left = 8
            Top = 8
            Width = 108
            Height = 34
            Cursor = crHandPoint
            BevelOuter = bvNone
            Caption = 'Start All'
            Color = clSilver
            Font.Charset = DEFAULT_CHARSET
            Font.Color = clWindowText
            Font.Height = -15
            Font.Name = 'Segoe UI'
            Font.Style = [fsBold]
            ParentBackground = False
            ParentFont = False
            TabOrder = 0
          end
          object StopAllButton: TPanel
            Left = 131
            Top = 8
            Width = 108
            Height = 34
            Cursor = crHandPoint
            BevelOuter = bvNone
            Caption = 'Stop All'
            Color = clSilver
            Font.Charset = DEFAULT_CHARSET
            Font.Color = clWindowText
            Font.Height = -15
            Font.Name = 'Segoe UI'
            Font.Style = [fsBold]
            ParentBackground = False
            ParentFont = False
            TabOrder = 1
          end
          object exitbutton: TPanel
            Left = 82
            Top = 48
            Width = 98
            Height = 34
            Cursor = crHandPoint
            BevelOuter = bvNone
            Caption = 'Exit '
            Color = clSilver
            Font.Charset = DEFAULT_CHARSET
            Font.Color = clWindowText
            Font.Height = -15
            Font.Name = 'Segoe UI'
            Font.Style = [fsBold]
            ParentBackground = False
            ParentFont = False
            TabOrder = 2
          end
        end
      end
    end
    object RightPanel: TPanel
      Left = 297
      Top = 0
      Width = 756
      Height = 714
      Align = alClient
      BevelOuter = bvNone
      Color = 15066597
      ParentBackground = False
      TabOrder = 1
      object VHostCard: TPanel
        Left = 0
        Top = 0
        Width = 756
        Height = 714
        Align = alClient
        BevelKind = bkTile
        BevelOuter = bvNone
        Color = clWhite
        ParentBackground = False
        TabOrder = 0
        ExplicitLeft = 6
        ExplicitTop = 6
        ExplicitWidth = 743
        ExplicitHeight = 702
        object Label11: TPanel
          Left = 0
          Top = 0
          Width = 752
          Height = 28
          Align = alTop
          BevelOuter = bvNone
          Caption = 'Virtual hosts'
          Color = clWhite
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clWindowText
          Font.Height = -11
          Font.Name = 'Segoe UI'
          Font.Style = [fsBold]
          ParentBackground = False
          ParentFont = False
          TabOrder = 1
        end
        object VHostGrid: TStringGrid
          Left = 0
          Top = 28
          Width = 752
          Height = 433
          Align = alClient
          ColCount = 4
          DefaultRowHeight = 28
          FixedCols = 0
          RowCount = 2
          Options = [goFixedVertLine, goFixedHorzLine, goVertLine, goHorzLine, goRangeSelect, goRowSelect]
          TabOrder = 0
          ExplicitLeft = 16
          ExplicitTop = 34
          ExplicitWidth = 709
          ExplicitHeight = 183
        end
        object Panel5: TPanel
          Left = 0
          Top = 654
          Width = 752
          Height = 56
          Align = alBottom
          Alignment = taLeftJustify
          BevelKind = bkTile
          BevelOuter = bvNone
          Color = clWhite
          ParentBackground = False
          TabOrder = 2
          ExplicitLeft = 4
          ExplicitTop = 650
          object GenerateSslButton: TPanel
            Left = 16
            Top = 14
            Width = 100
            Height = 24
            Cursor = crHandPoint
            BevelOuter = bvNone
            Caption = 'Generate SSL'
            Color = 16053492
            Font.Charset = DEFAULT_CHARSET
            Font.Color = clWindowText
            Font.Height = -11
            Font.Name = 'Segoe UI'
            Font.Style = [fsBold]
            ParentBackground = False
            ParentFont = False
            TabOrder = 0
          end
          object Panel8: TPanel
            Left = 132
            Top = 14
            Width = 141
            Height = 24
            Cursor = crHandPoint
            BevelOuter = bvNone
            Caption = 'Web Dashboard'
            Color = 16053492
            Font.Charset = DEFAULT_CHARSET
            Font.Color = clWindowText
            Font.Height = -11
            Font.Name = 'Segoe UI'
            Font.Style = [fsBold]
            ParentBackground = False
            ParentFont = False
            TabOrder = 1
          end
          object Panel9: TPanel
            Left = 298
            Top = 14
            Width = 92
            Height = 24
            Cursor = crHandPoint
            BevelOuter = bvNone
            Caption = 'Adminer'
            Color = 16053492
            Font.Charset = DEFAULT_CHARSET
            Font.Color = clWindowText
            Font.Height = -11
            Font.Name = 'Segoe UI'
            Font.Style = [fsBold]
            ParentBackground = False
            ParentFont = False
            TabOrder = 2
          end
        end
        object Panel6: TPanel
          Left = 0
          Top = 461
          Width = 752
          Height = 56
          Align = alBottom
          Alignment = taLeftJustify
          BevelKind = bkTile
          BevelOuter = bvNone
          Color = clWhite
          ParentBackground = False
          TabOrder = 3
          ExplicitLeft = -16
          ExplicitTop = 360
          object AddVHostButton: TPanel
            Left = 17
            Top = 15
            Width = 100
            Height = 24
            Cursor = crHandPoint
            BevelOuter = bvNone
            Caption = 'Add'
            Color = 16053492
            Font.Charset = DEFAULT_CHARSET
            Font.Color = clWindowText
            Font.Height = -11
            Font.Name = 'Segoe UI'
            Font.Style = [fsBold]
            ParentBackground = False
            ParentFont = False
            TabOrder = 0
          end
          object OpenVHostButton: TPanel
            Left = 121
            Top = 15
            Width = 93
            Height = 24
            Cursor = crHandPoint
            BevelOuter = bvNone
            Caption = 'Open Selected'
            Color = 16053492
            Font.Charset = DEFAULT_CHARSET
            Font.Color = clWindowText
            Font.Height = -11
            Font.Name = 'Segoe UI'
            Font.Style = [fsBold]
            ParentBackground = False
            ParentFont = False
            TabOrder = 1
          end
          object OpenVHostFolderButton: TPanel
            Left = 225
            Top = 15
            Width = 84
            Height = 24
            Cursor = crHandPoint
            BevelOuter = bvNone
            Caption = 'Open Root'
            Color = 16053492
            Font.Charset = DEFAULT_CHARSET
            Font.Color = clWindowText
            Font.Height = -11
            Font.Name = 'Segoe UI'
            Font.Style = [fsBold]
            ParentBackground = False
            ParentFont = False
            TabOrder = 2
          end
          object CopyVHostUrlButton: TPanel
            Left = 329
            Top = 15
            Width = 89
            Height = 24
            Cursor = crHandPoint
            BevelOuter = bvNone
            Caption = 'Copy URL'
            Color = 16053492
            Font.Charset = DEFAULT_CHARSET
            Font.Color = clWindowText
            Font.Height = -11
            Font.Name = 'Segoe UI'
            Font.Style = [fsBold]
            ParentBackground = False
            ParentFont = False
            TabOrder = 3
          end
          object DeleteVHostButton: TPanel
            Left = 434
            Top = 15
            Width = 116
            Height = 24
            Cursor = crHandPoint
            BevelOuter = bvNone
            Caption = 'Delete Selected'
            Color = 16053492
            Font.Charset = DEFAULT_CHARSET
            Font.Color = clWindowText
            Font.Height = -11
            Font.Name = 'Segoe UI'
            Font.Style = [fsBold]
            ParentBackground = False
            ParentFont = False
            TabOrder = 4
          end
        end
        object Panel7: TPanel
          Left = 0
          Top = 517
          Width = 752
          Height = 137
          Align = alBottom
          Alignment = taLeftJustify
          BevelKind = bkTile
          BevelOuter = bvNone
          Color = clWhite
          ParentBackground = False
          TabOrder = 4
          ExplicitTop = 461
          object Panel4: TPanel
            Left = 0
            Top = 0
            Width = 220
            Height = 133
            Align = alLeft
            BevelKind = bkTile
            BevelOuter = bvNone
            Color = clWhite
            ParentBackground = False
            TabOrder = 0
            ExplicitLeft = 6
            ExplicitTop = -18
            ExplicitHeight = 132
            object OpenApacheLogButton: TPanel
              Left = 17
              Top = 18
              Width = 92
              Height = 24
              Cursor = crHandPoint
              BevelOuter = bvNone
              Caption = 'Apache Log'
              Color = 16053492
              Font.Charset = DEFAULT_CHARSET
              Font.Color = clWindowText
              Font.Height = -11
              Font.Name = 'Segoe UI'
              Font.Style = [fsBold]
              ParentBackground = False
              ParentFont = False
              TabOrder = 0
            end
            object OpenMariaLogButton: TPanel
              Left = 19
              Top = 55
              Width = 92
              Height = 24
              Cursor = crHandPoint
              BevelOuter = bvNone
              Caption = 'MariaDB Log'
              Color = 16053492
              Font.Charset = DEFAULT_CHARSET
              Font.Color = clWindowText
              Font.Height = -11
              Font.Name = 'Segoe UI'
              Font.Style = [fsBold]
              ParentBackground = False
              ParentFont = False
              TabOrder = 1
            end
            object ClearApacheLogButton: TPanel
              Left = 119
              Top = 21
              Width = 92
              Height = 16
              Cursor = crHandPoint
              BevelOuter = bvNone
              Caption = 'Clear Apache'
              Color = clWhite
              Font.Charset = DEFAULT_CHARSET
              Font.Color = clBlue
              Font.Height = -11
              Font.Name = 'Segoe UI'
              Font.Style = [fsUnderline]
              ParentBackground = False
              ParentFont = False
              TabOrder = 2
            end
            object ClearMariaLogButton: TPanel
              Left = 118
              Top = 59
              Width = 92
              Height = 16
              Cursor = crHandPoint
              BevelOuter = bvNone
              Caption = 'Clear MariaDB'
              Color = clWhite
              Font.Charset = DEFAULT_CHARSET
              Font.Color = clBlue
              Font.Height = -11
              Font.Name = 'Segoe UI'
              Font.Style = [fsUnderline]
              ParentBackground = False
              ParentFont = False
              TabOrder = 3
            end
            object Label20: TPanel
              Left = 26
              Top = 94
              Width = 103
              Height = 15
              Alignment = taLeftJustify
              BevelOuter = bvNone
              Caption = 'View activity log'
              Color = clWhite
              Font.Charset = DEFAULT_CHARSET
              Font.Color = clBlue
              Font.Height = -11
              Font.Name = 'Segoe UI'
              Font.Style = [fsUnderline]
              ParentBackground = False
              ParentFont = False
              TabOrder = 4
            end
            object ClearActivityLogButton: TPanel
              Left = 111
              Top = 93
              Width = 103
              Height = 16
              Cursor = crHandPoint
              BevelOuter = bvNone
              Caption = 'Clear activity'
              Color = clWhite
              Font.Charset = DEFAULT_CHARSET
              Font.Color = clBlue
              Font.Height = -11
              Font.Name = 'Segoe UI'
              Font.Style = [fsUnderline]
              ParentBackground = False
              ParentFont = False
              TabOrder = 5
            end
            object SaveConfigButton: TPanel
              Left = 410
              Top = 13
              Width = 100
              Height = 24
              Cursor = crHandPoint
              BevelOuter = bvNone
              Caption = 'Save Config'
              Color = 16053492
              Font.Charset = DEFAULT_CHARSET
              Font.Color = clWindowText
              Font.Height = -11
              Font.Name = 'Segoe UI'
              Font.Style = [fsBold]
              ParentBackground = False
              ParentFont = False
              TabOrder = 6
            end
            object LaunchDashboardButton: TPanel
              Left = 228
              Top = 14
              Width = 101
              Height = 24
              Cursor = crHandPoint
              BevelOuter = bvNone
              Caption = 'Dashboard'
              Color = 16053492
              Font.Charset = DEFAULT_CHARSET
              Font.Color = clWindowText
              Font.Height = -11
              Font.Name = 'Segoe UI'
              Font.Style = [fsBold]
              ParentBackground = False
              ParentFont = False
              TabOrder = 7
            end
            object LaunchTerminalButton: TPanel
              Left = 340
              Top = 12
              Width = 97
              Height = 24
              Cursor = crHandPoint
              BevelOuter = bvNone
              Caption = 'Terminal'
              Color = 16053492
              Font.Charset = DEFAULT_CHARSET
              Font.Color = clWindowText
              Font.Height = -11
              Font.Name = 'Segoe UI'
              Font.Style = [fsBold]
              ParentBackground = False
              ParentFont = False
              TabOrder = 8
            end
          end
          object FActivityCard: TPanel
            Left = 220
            Top = 0
            Width = 528
            Height = 133
            Align = alClient
            BevelKind = bkTile
            BevelOuter = bvNone
            Color = clWhite
            ParentBackground = False
            TabOrder = 1
            ExplicitLeft = 226
            ExplicitTop = -18
            ExplicitWidth = 513
            ExplicitHeight = 132
            object FActivityLabel: TPanel
              Left = 10
              Top = 5
              Width = 108
              Height = 15
              Alignment = taLeftJustify
              BevelOuter = bvNone
              Caption = 'Activity log'
              Color = clWhite
              Font.Charset = DEFAULT_CHARSET
              Font.Color = clWindowText
              Font.Height = -11
              Font.Name = 'Segoe UI'
              Font.Style = [fsBold]
              ParentBackground = False
              ParentFont = False
              TabOrder = 0
            end
          end
        end
      end
    end
    object StatusBar: TStatusBar
      Left = 0
      Top = 714
      Width = 1053
      Height = 20
      Panels = <>
      SimplePanel = True
    end
  end
end
