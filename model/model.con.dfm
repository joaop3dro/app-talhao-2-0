object dmCon: TdmCon
  OnCreate = DataModuleCreate
  Height = 304
  Width = 517
  PixelsPerInch = 120
  object Conn: TFDConnection
    Left = 56
    Top = 40
  end
  object FQuery: TFDQuery
    Connection = Conn
    Left = 56
    Top = 128
  end
  object FDPhysSQLiteDriverLink1: TFDPhysSQLiteDriverLink
    Left = 184
    Top = 40
  end
end
