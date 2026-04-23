unit model.con;

interface

uses
  System.SysUtils, System.Classes, FireDAC.Stan.Intf, FireDAC.Stan.Option,
  FireDAC.Stan.Error, FireDAC.UI.Intf, FireDAC.Phys.Intf, FireDAC.Stan.Def,
  FireDAC.Stan.Pool, FireDAC.Stan.Async, FireDAC.Phys, FireDAC.FMXUI.Wait,
  Data.DB, FireDAC.Comp.Client, FireDAC.Stan.Param, FireDAC.DatS,
  FireDAC.DApt.Intf, FireDAC.DApt, FireDAC.Comp.DataSet, models,
  System.IOUtils, FireDAC.Stan.ExprFuncs, FireDAC.Phys.SQLiteWrapper.Stat,
  FireDAC.Phys.SQLiteDef, FireDAC.Phys.SQLite;

type
  TdmCon = class(TDataModule)
    Conn: TFDConnection;
    FQuery: TFDQuery;
    FDPhysSQLiteDriverLink1: TFDPhysSQLiteDriverLink;
    procedure DataModuleCreate(Sender: TObject);
  private
    { Private declarations }
  public
    { Public declarations }
    function AtualizarTalhao(ATalhao: TTalhao): Boolean;
    function BuscarTalhaoPorId(AId: Integer): TTalhao;
    procedure CriarTabelas;
    function ExcluirTalhao(AId: Integer): Boolean;
    function ListarGrupos: TStringList;
    function ListarTalhoes: TTalhaoList;
    function SalvarTalhao(ATalhao: TTalhao): Boolean;
  end;

var
  dmCon: TdmCon;

implementation

{%CLASSGROUP 'FMX.Controls.TControl'}

{$R *.dfm}

procedure TdmCon.DataModuleCreate(Sender: TObject);
begin
   with Conn do
  begin
    Params.Values['DriverID'] := 'SQLite';

{$IFDEF IOS}
    Params.Values['Database'] := TPath.Combine(TPath.GetDocumentsPath,'talhoes.db');
{$ENDIF}
{$IFDEF ANDROID}
    Params.Values['Database'] := TPath.Combine(TPath.GetDocumentsPath,'talhoes.db');
{$ENDIF}
{$IFDEF MSWINDOWS}
    Params.Values['Database'] := '..\..\db\talhoes.db';
{$ENDIF}
  end;

  CriarTabelas;
end;

procedure TdmCon.CriarTabelas;
begin
  FQuery.SQL.Text :=
    'CREATE TABLE IF NOT EXISTS grupos (' +
    '  id   INTEGER PRIMARY KEY AUTOINCREMENT,' +
    '  nome TEXT    NOT NULL UNIQUE' +
    ')';
  FQuery.ExecSQL;

  FQuery.SQL.Text :=
    'CREATE TABLE IF NOT EXISTS talhoes (' +
    '  id            INTEGER PRIMARY KEY AUTOINCREMENT,' +
    '  nome          TEXT    NOT NULL,' +
    '  descricao     TEXT    DEFAULT '''',' +
    '  area          REAL    DEFAULT 0,' +
    '  perimetro     REAL    DEFAULT 0,' +
    '  grupo         TEXT    DEFAULT '''',' +
    '  data_cadastro TEXT    NOT NULL,' +
    '  pontos_json   TEXT    NOT NULL' +
    ')';
  FQuery.ExecSQL;
end;

function TdmCon.SalvarTalhao(ATalhao: TTalhao): Boolean;
begin
  Result := False;
  try
    ATalhao.CalcularAreaEPerimetro;

    FQuery.SQL.Text :=
      'INSERT INTO talhoes (nome, descricao, area, perimetro, grupo, data_cadastro, pontos_json) ' +
      'VALUES (:nome, :descricao, :area, :perimetro, :grupo, :data_cadastro, :pontos_json)';
    FQuery.ParamByName('nome').AsString          := ATalhao.Nome;
    FQuery.ParamByName('descricao').AsString     := ATalhao.Descricao;
    FQuery.ParamByName('area').AsFloat           := ATalhao.Area;
    FQuery.ParamByName('perimetro').AsFloat      := ATalhao.Perimetro;
    FQuery.ParamByName('grupo').AsString         := ATalhao.Grupo;
    FQuery.ParamByName('data_cadastro').AsString := DateTimeToStr(ATalhao.DataCadastro);
    FQuery.ParamByName('pontos_json').AsString   := ATalhao.PontosJSON;
    FQuery.ExecSQL;

    FQuery.SQL.Text := 'SELECT last_insert_rowid() AS novo_id';
    FQuery.Open;
    ATalhao.Id := FQuery.FieldByName('novo_id').AsInteger;
    FQuery.Close;

    Result := True;
  except
    on E: Exception do
      raise Exception.CreateFmt('Erro ao salvar talhão: %s', [E.Message]);
  end;
end;

function TdmCon.AtualizarTalhao(ATalhao: TTalhao): Boolean;
begin
  Result := False;
  try
    ATalhao.CalcularAreaEPerimetro;

    FQuery.SQL.Text :=
      'UPDATE talhoes SET ' +
      '  nome          = :nome,' +
      '  descricao     = :descricao,' +
      '  area          = :area,' +
      '  perimetro     = :perimetro,' +
      '  grupo         = :grupo,' +
      '  pontos_json   = :pontos_json ' +
      'WHERE id = :id';
    FQuery.ParamByName('id').AsInteger           := ATalhao.Id;
    FQuery.ParamByName('nome').AsString          := ATalhao.Nome;
    FQuery.ParamByName('descricao').AsString     := ATalhao.Descricao;
    FQuery.ParamByName('area').AsFloat           := ATalhao.Area;
    FQuery.ParamByName('perimetro').AsFloat      := ATalhao.Perimetro;
    FQuery.ParamByName('grupo').AsString         := ATalhao.Grupo;
    FQuery.ParamByName('pontos_json').AsString   := ATalhao.PontosJSON;
    FQuery.ExecSQL;

    Result := True;
  except
    on E: Exception do
      raise Exception.CreateFmt('Erro ao atualizar talhão: %s', [E.Message]);
  end;
end;

function TdmCon.ExcluirTalhao(AId: Integer): Boolean;
begin
  Result := False;
  try
    FQuery.SQL.Text := 'DELETE FROM talhoes WHERE id = :id';
    FQuery.ParamByName('id').AsInteger := AId;
    FQuery.ExecSQL;
    Result := True;
  except
    on E: Exception do
      raise Exception.CreateFmt('Erro ao excluir talhão: %s', [E.Message]);
  end;
end;

function TdmCon.ListarTalhoes: TTalhaoList;
var
  LTalhao: TTalhao;
begin
  Result := TTalhaoList.Create(True);
  try
    FQuery.SQL.Text := 'SELECT * FROM talhoes ORDER BY nome';
    FQuery.Open;
    while not FQuery.Eof do
    begin
      LTalhao := TTalhao.Create;
      LTalhao.Id           := FQuery.FieldByName('id').AsInteger;
      LTalhao.Nome         := FQuery.FieldByName('nome').AsString;
      LTalhao.Descricao    := FQuery.FieldByName('descricao').AsString;
      LTalhao.Area         := FQuery.FieldByName('area').AsFloat;
      LTalhao.Perimetro    := FQuery.FieldByName('perimetro').AsFloat;
      LTalhao.Grupo        := FQuery.FieldByName('grupo').AsString;
      LTalhao.DataCadastro := StrToDateTimeDef(FQuery.FieldByName('data_cadastro').AsString, Now);
      LTalhao.PontosJSON   := FQuery.FieldByName('pontos_json').AsString;

      Result.Add(LTalhao);

      FQuery.Next;
    end;
    FQuery.Close;
  except
    Result.Free;
    raise;
  end;
end;

function TdmCon.BuscarTalhaoPorId(AId: Integer): TTalhao;
begin
  Result := nil;
  FQuery.SQL.Text := 'SELECT * FROM talhoes WHERE id = :id';
  FQuery.ParamByName('id').AsInteger := AId;
  FQuery.Open;

  if not FQuery.Eof then
  begin
    Result := TTalhao.Create;
    Result.Id           := FQuery.FieldByName('id').AsInteger;
    Result.Nome         := FQuery.FieldByName('nome').AsString;
    Result.Descricao    := FQuery.FieldByName('descricao').AsString;
    Result.Area         := FQuery.FieldByName('area').AsFloat;
    Result.Perimetro    := FQuery.FieldByName('perimetro').AsFloat;
    Result.Grupo        := FQuery.FieldByName('grupo').AsString;
    Result.DataCadastro := StrToDateTimeDef(FQuery.FieldByName('data_cadastro').AsString, Now);
    Result.PontosJSON   := FQuery.FieldByName('pontos_json').AsString;
  end;
  FQuery.Close;
end;

function TdmCon.ListarGrupos: TStringList;
begin
  Result := TStringList.Create;
  try
    FQuery.SQL.Text := 'SELECT DISTINCT grupo FROM talhoes WHERE grupo <> '''' ORDER BY grupo';
    FQuery.Open;
    while not FQuery.Eof do
    begin
      Result.Add(FQuery.Fields[0].AsString);
      FQuery.Next;
    end;
    FQuery.Close;
  except
    Result.Free;
    raise;
  end;
end;

end.
