object MainForm: TMainForm
  Left = 0
  Top = 0
  BorderStyle = bsSizeable
  Caption = 'UniWamp'
  ClientHeight = 655
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
      Width = 103
      Height = 25
      BevelOuter = bvNone
      Caption = 'UniWamp'
      Color = 6229470
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clWhite
      Font.Height = -19
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
    Height = 600
    Align = alClient
    BevelOuter = bvNone
    ParentBackground = False
    TabOrder = 1
    object LeftPanel: TPanel
      Left = 0
      Top = 0
      Width = 297
      Height = 580
      Align = alLeft
      BevelOuter = bvNone
      Color = 15066597
      ParentBackground = False
      TabOrder = 0
      object ActionsCard: TPanel
        Left = 10
        Top = 11
        Width = 284
        Height = 548
        BevelKind = bkTile
        BevelOuter = bvNone
        Color = clWhite
        ParentBackground = False
        TabOrder = 0
        object LabelEditors: TPanel
          Left = 4
          Top = 484
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
          Left = 10
          Top = 509
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
          Left = 103
          Top = 510
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
          Left = 193
          Top = 509
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
          Left = 9
          Top = 7
          Width = 251
          Height = 89
          Caption = 'Apache'
          TabOrder = 4
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
            Left = 11
            Top = 58
            Width = 59
            Height = 15
            Alignment = taLeftJustify
            BevelOuter = bvNone
            Caption = 'Port  HTTP'
            Color = clWhite
            ParentBackground = False
            TabOrder = 3
          end
          object HttpPortEdit: TEdit
            Left = 76
            Top = 56
            Width = 54
            Height = 21
            TabOrder = 4
            Text = '8080'
          end
          object Label8: TPanel
            Left = 141
            Top = 58
            Width = 45
            Height = 15
            Alignment = taLeftJustify
            BevelOuter = bvNone
            Caption = 'HTTPS'
            Color = clWhite
            ParentBackground = False
            TabOrder = 5
          end
          object HttpsPortEdit: TEdit
            Left = 185
            Top = 56
            Width = 53
            Height = 21
            TabOrder = 6
            Text = '8443'
          end
        end
        object GroupBox2: TGroupBox
          Left = 10
          Top = 104
          Width = 250
          Height = 88
          Caption = 'MariaDB'
          TabOrder = 5
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
            Left = 9
            Top = 61
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
            Left = 83
            Top = 58
            Width = 74
            Height = 21
            TabOrder = 4
            Text = '3307'
          end
        end
        object Panel3: TPanel
          Left = 10
          Top = 307
          Width = 248
          Height = 165
          BevelKind = bkTile
          BevelOuter = bvNone
          Color = clWhite
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
            Top = 28
            Width = 227
            Height = 21
            TabOrder = 1
            Text = 'uniwamp.local'
          end
          object Label5: TPanel
            Left = 8
            Top = 56
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
            Top = 75
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
            Top = 102
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
            Top = 123
            Width = 226
            Height = 21
            TabOrder = 5
            Text = 'runtime\www'
          end
        end
        object Panel1: TPanel
          Left = 10
          Top = 204
          Width = 250
          Height = 94
          BevelKind = bkTile
          BevelOuter = bvNone
          Color = clWhite
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
            Top = 32
            Width = 143
            Height = 21
            Style = csDropDownList
            TabOrder = 3
          end
          object EnableSslCheck: TCheckBox
            Left = 7
            Top = 63
            Width = 169
            Height = 17
            Caption = 'Enable SSL for localhost'
            TabOrder = 4
          end
        end
      end
    end
    object RightPanel: TPanel
      Left = 297
      Top = 0
      Width = 756
      Height = 580
      Align = alClient
      BevelOuter = bvNone
      Color = 15066597
      ParentBackground = False
      TabOrder = 1
      object VHostCard: TPanel
        Left = 6
        Top = 11
        Width = 743
        Height = 418
        BevelKind = bkTile
        BevelOuter = bvNone
        Color = clWhite
        ParentBackground = False
        TabOrder = 0
        object Label11: TPanel
          Left = 16
          Top = 12
          Width = 709
          Height = 15
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
          Left = 16
          Top = 34
          Width = 709
          Height = 336
          ColCount = 4
          DefaultRowHeight = 28
          FixedCols = 0
          RowCount = 2
          Options = [goFixedVertLine, goFixedHorzLine, goVertLine, goHorzLine, goRangeSelect, goRowSelect]
          TabOrder = 0
        end
        object AddVHostButton: TPanel
          Left = 17
          Top = 381
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
          TabOrder = 2
        end
        object OpenVHostButton: TPanel
          Left = 129
          Top = 381
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
          TabOrder = 3
        end
        object OpenVHostFolderButton: TPanel
          Left = 232
          Top = 381
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
          TabOrder = 4
        end
        object CopyVHostUrlButton: TPanel
          Left = 330
          Top = 381
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
          TabOrder = 5
        end
        object DeleteVHostButton: TPanel
          Left = 430
          Top = 381
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
          TabOrder = 6
        end
      end
      object Panel5: TPanel
        Left = 6
        Top = 505
        Width = 743
        Height = 56
        Alignment = taLeftJustify
        BevelKind = bkTile
        BevelOuter = bvNone
        Color = clWhite
        ParentBackground = False
        TabOrder = 1
        object exitbutton: TPanel
          Left = 624
          Top = 9
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
          TabOrder = 0
        end
        object startbutton: TPanel
          Left = 12
          Top = 8
          Width = 98
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
          TabOrder = 1
        end
        object stopbutton: TPanel
          Left = 120
          Top = 8
          Width = 98
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
          TabOrder = 2
        end
      end
      object Panel4: TPanel
        Left = 6
        Top = 439
        Width = 743
        Height = 56
        BevelKind = bkTile
        BevelOuter = bvNone
        Color = clWhite
        ParentBackground = False
        TabOrder = 2
        object OpenApacheLogButton: TPanel
          Left = 400
          Top = 14
          Width = 95
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
          Left = 507
          Top = 15
          Width = 96
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
          Left = 400
          Top = 39
          Width = 95
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
          Left = 507
          Top = 39
          Width = 96
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
          Left = 626
          Top = 18
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
          Left = 626
          Top = 39
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
          Left = 294
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
          TabOrder = 7
        end
        object LaunchSiteButton: TPanel
          Left = 132
          Top = 14
          Width = 88
          Height = 24
          Cursor = crHandPoint
          BevelOuter = bvNone
          Caption = 'Home'
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
          TabOrder = 9
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
          TabOrder = 10
        end
      end
    end
    object StatusBar: TStatusBar
      Left = 0
      Top = 580
      Width = 1053
      Height = 20
      Panels = <>
      SimplePanel = True
    end
  end
end
